"""
DndListInt — drag-to-reorder list widget (egui_dnd port).

Port of the Rust crate `egui_dnd`
(/tmp/hello_egui-ref/crates/egui_dnd/src/):
  - utils.rs::shift_vec          -> `shift_vec` (the reorder primitive)
  - state.rs DragUpdate          -> `DragUpdate`
  - state.rs DragDropResponse    -> `DragDropResponse`
  - lib.rs Dnd::show_vec         -> `DndListInt` (retained-mode adaptation)

egui_dnd renders + reorders in one immediate-mode call (`Dnd::show_vec`).  MojoGUI
is retained + integer, so `DndListInt` OWNS a `List[DndItem]`, draws them as
vertical draggable rows, tracks the drag, and reorders its own list on drop; the
host reads the new order back plus a `DragDropResponse`.

Phase 1: instant reorder on drop.  Return/swap ANIMATIONS are DEFERRED (see the
TODO in `_on_release`).

Conventions (Mojo 0.26.2 nightly, per DND_PORT_SPEC.md):
  - `out self` (init) / `mut self` (mutators) / `self` (readonly).  NO `inout`.
  - NO struct inheritance; compose.  `comptime` not `alias`.  No libm.
  - List-stored value structs derive `(ImplicitlyCopyable, Movable)`; a struct
    owning a `List` derives `(Copyable, Movable)`.
  - Multi-value return via an explicit `Tuple[...]` ctor (bare `(a, b)` is a hard
    error) — not needed here, all returns are single values.
  - Every `RenderingContextInt` draw call returns `Bool`; discarded with `_ =`.
"""

from ...rendering_int import RenderingContextInt, ColorInt, RectInt
from ...widget_int import MouseEventInt

comptime MB_LEFT: Int32 = 0
comptime DEFAULT_ROW_HEIGHT: Int32 = 26


# =============================================================================
# DndItem — concrete replacement for egui_dnd's generic `DragDropItem`
# =============================================================================

struct DndItem(ImplicitlyCopyable, Movable):
    """A single reorderable row.  `id` is the host's stable identifier (egui_dnd
    `DragDropItem::id()`); `label` is the displayed text."""

    var id: Int32
    """Stable host-assigned identifier."""
    var label: String
    """Row display text."""

    fn __init__(out self, id: Int32, label: String):
        self.id = id
        self.label = label


# =============================================================================
# DragUpdate / DragDropResponse — port of state.rs
# =============================================================================

struct DragUpdate(ImplicitlyCopyable, Movable):
    """An instruction in what order to update the source list (port of
    `DragUpdate` in state.rs): move the item at `from_` to `to`."""

    var from_: Int
    """Source index."""
    var to: Int
    """Target index (insertion gap)."""

    fn __init__(out self, from_: Int, to: Int):
        self.from_ = from_
        self.to = to


struct DragDropResponse(ImplicitlyCopyable, Movable):
    """State of the drag-and-drop list plus a potential update (port of
    `DragDropResponse` in state.rs).

    `has_update` mirrors Rust's `update: Option<DragUpdate>` being `Some`;
    `finished` mirrors `is_drag_finished()`; `is_dragging` mirrors
    `is_dragging()`; `dragged_id` mirrors `dragged_item_id()` (-1 = none).
    """

    var has_update: Bool
    """True when `(from_, to)` carry a pending/applied reorder."""
    var from_: Int
    """Source index of the update (valid when `has_update`)."""
    var to: Int
    """Target index of the update (valid when `has_update`)."""
    var is_dragging: Bool
    """True while a drag is in progress."""
    var finished: Bool
    """True on the frame the drop completed (update should be applied)."""
    var dragged_id: Int32
    """Id of the dragged item, or -1 when not dragging."""

    fn __init__(out self):
        """An idle response (no update, not dragging)."""
        self.has_update = False
        self.from_ = -1
        self.to = -1
        self.is_dragging = False
        self.finished = False
        self.dragged_id = -1


# =============================================================================
# shift_vec — faithful port of utils.rs::shift_vec
# =============================================================================

fn shift_vec(mut items: List[DndItem], from_: Int, to: Int):
    """Move the item at `from_` to `to` (port of `egui_dnd::utils::shift_vec`).

    Rust rotates the sub-slice between source and target:
      - `from_ < to`: rotate_left the slice `[from_ .. to)` by 1, so the source
        item lands at `to - 1`.
      - else: rotate_right the slice `[to ..= from_]` by 1, so the source item
        lands at `to`.
    The `1.min(len)` guard makes an empty/degenerate slice a no-op.

    Implemented here as the equivalent remove-then-insert with the from<to index
    adjustment (bit-identical to the rotation; verified against the utils.rs
    doctests, e.g. [1,2,3,4] --0->2--> [2,1,3,4], --2->0--> [3,2,1,4]).

    Caller must ensure `from_ < len` and `to <= len` (Rust panics otherwise).
    """
    var n = len(items)
    if from_ < 0 or from_ >= n or to < 0 or to > n:
        return
    if from_ == to:
        return
    var moved = items[from_]
    _ = items.pop(from_)
    # After removal, indices > from_ shifted down by one.  rotate_left over
    # [from_..to) leaves the source at to-1; remove+insert reproduces that:
    var insert_at: Int
    if from_ < to:
        insert_at = to - 1
    else:
        insert_at = to
    items.insert(insert_at, moved)


# =============================================================================
# DndStyle — small local palette (no separate style.mojo for dnd)
# =============================================================================

struct DndStyle(ImplicitlyCopyable, Movable):
    """Row colors for the dnd list."""

    var row_bg: ColorInt
    var row_alt: ColorInt
    var row_hover: ColorInt
    var text: ColorInt
    var drag_bg: ColorInt
    var insert_line: ColorInt

    fn __init__(out self):
        """Default dark palette."""
        self.row_bg = ColorInt(38, 42, 52, 255)
        self.row_alt = ColorInt(44, 49, 60, 255)
        self.row_hover = ColorInt(56, 64, 80, 255)
        self.text = ColorInt(214, 220, 230, 255)
        self.drag_bg = ColorInt(70, 96, 140, 235)
        self.insert_line = ColorInt(120, 170, 240, 255)


# =============================================================================
# DndListInt — the retained drag-to-reorder list widget
# =============================================================================

struct DndListInt(Copyable, Movable):
    """Vertical drag-to-reorder list (retained-mode port of `Dnd::show_vec`).

    Composes its own bounds (no inheritance).  Owns the `List[DndItem]`, so it is
    `(Copyable, Movable)`.
    """

    # ----- Bounds (replacing BaseWidgetInt inheritance) --------------------
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
    var visible: Bool

    # ----- Data + geometry -------------------------------------------------
    var items: List[DndItem]
    """The reorderable rows (the source list)."""
    var row_height: Int32
    """Pixel height of one row."""
    var style: DndStyle
    """Row colors."""

    # ----- Drag state ------------------------------------------------------
    var dragging: Bool
    """True while a row is being dragged."""
    var drag_from: Int
    """Index the drag started from, or -1."""
    var grab_dy: Int32
    """Cursor offset within the grabbed row (cursor_y - row_top)."""
    var hover_to: Int
    """Current insertion-gap index under the cursor (0..len)."""
    var cursor_y: Int32
    """Last cursor Y (for drawing the floating row)."""

    var last: DragDropResponse
    """Most recent drag-drop response (host reads this)."""

    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.visible = True

        self.items = List[DndItem]()
        self.row_height = DEFAULT_ROW_HEIGHT
        self.style = DndStyle()

        self.dragging = False
        self.drag_from = -1
        self.grab_dy = 0
        self.hover_to = -1
        self.cursor_y = 0

        self.last = DragDropResponse()

    # ----- Configuration ---------------------------------------------------

    fn add_item(mut self, id: Int32, label: String):
        """Append a row."""
        self.items.append(DndItem(id, label))

    fn set_items(mut self, var items: List[DndItem]):
        """Replace all rows (takes ownership)."""
        self.items = items^
        self.dragging = False
        self.drag_from = -1
        self.hover_to = -1

    fn set_style(mut self, style: DndStyle):
        """Apply a row palette."""
        self.style = style

    fn set_row_height(mut self, h: Int32):
        """Set the per-row pixel height."""
        if h > 1:
            self.row_height = h

    # ----- Read-back API ---------------------------------------------------

    fn item_count(self) -> Int:
        """Number of rows."""
        return len(self.items)

    fn item_id(self, i: Int) -> Int32:
        """`id` of row `i`, or -1 if out of range."""
        if i >= 0 and i < len(self.items):
            return self.items[i].id
        return -1

    fn item_label(self, i: Int) -> String:
        """Label of row `i`, or "" if out of range."""
        if i >= 0 and i < len(self.items):
            return self.items[i].label
        return String("")

    fn order(self) -> List[Int32]:
        """Current row ids, top to bottom (the live order)."""
        var ids = List[Int32]()
        for i in range(len(self.items)):
            ids.append(self.items[i].id)
        return ids^

    fn last_response(self) -> DragDropResponse:
        """The most recent drag-drop response."""
        return self.last

    # ----- Geometry helpers ------------------------------------------------

    fn _row_top(self, i: Int) -> Int32:
        """Y of the top edge of row `i`."""
        return self.y + Int32(i) * self.row_height

    fn _row_at(self, py: Int32) -> Int:
        """Row index under pixel `py`, or -1 if outside the rows."""
        if py < self.y:
            return -1
        var i = Int(py - self.y) // Int(self.row_height)
        if i < 0 or i >= len(self.items):
            return -1
        return i

    fn _gap_at(self, py: Int32) -> Int:
        """Insertion-gap index (0..len) for cursor `py`, by row midpoints.

        A cursor in the top half of row `i` targets gap `i`; the bottom half
        targets gap `i + 1`.  Clamped to `[0, len]`.
        """
        var n = len(self.items)
        if n == 0:
            return 0
        if py < self.y:
            return 0
        var rel = Int(py - self.y)
        var i = rel // Int(self.row_height)
        if i >= n:
            return n
        var within = rel - i * Int(self.row_height)
        var gap = i
        if within * 2 >= Int(self.row_height):
            gap = i + 1
        if gap < 0:
            gap = 0
        if gap > n:
            gap = n
        return gap

    # ----- Events ----------------------------------------------------------

    fn contains_point(self, px: Int32, py: Int32) -> Bool:
        return (px >= self.x and px < self.x + self.width
                and py >= self.y and py < self.y + self.height)

    fn handle_mouse_event(mut self, e: MouseEventInt) -> Bool:
        """Press a row -> arm a drag.  Release -> apply the reorder."""
        if not self.visible:
            return False
        if e.button != MB_LEFT:
            return False
        if e.pressed:
            return self._on_press(e.x, e.y)
        return self._on_release(e.x, e.y)

    fn _on_press(mut self, px: Int32, py: Int32) -> Bool:
        """Begin a drag from the pressed row."""
        if not self.contains_point(px, py):
            return False
        var row = self._row_at(py)
        if row == -1:
            return False
        self.dragging = True
        self.drag_from = row
        self.grab_dy = py - self._row_top(row)
        self.hover_to = row
        self.cursor_y = py
        # Reset the response; mark dragging.
        self.last = DragDropResponse()
        self.last.is_dragging = True
        self.last.dragged_id = self.items[row].id
        return True

    fn on_mouse_move(mut self, px: Int32, py: Int32):
        """Track the cursor while dragging: update the insertion gap."""
        if not self.dragging:
            return
        self.cursor_y = py
        self.hover_to = self._gap_at(py)
        # Keep the live response in sync (egui_dnd updates `update` during drag).
        self.last.is_dragging = True
        self.last.from_ = self.drag_from
        self.last.to = self.hover_to
        self.last.has_update = (self.hover_to != self.drag_from
                                and self.hover_to != self.drag_from + 1)

    fn _on_release(mut self, px: Int32, py: Int32) -> Bool:
        """Drop: apply `shift_vec(drag_from, hover_to)` and finalize.

        TODO(phase 2): return/swap animations (egui_dnd animates the dropped row
        sliding into place); phase 1 reorders instantly.
        """
        if not self.dragging:
            return False

        var from_ = self.drag_from
        var to = self.hover_to
        if to < 0:
            to = from_

        # Build the finished response BEFORE mutating (records the requested move).
        var resp = DragDropResponse()
        resp.is_dragging = False
        resp.finished = True
        resp.dragged_id = self.item_id(from_)
        resp.from_ = from_
        resp.to = to
        # An update is only meaningful when the target differs from the source's
        # own position (to == from_ or from_+1 leaves the item where it is).
        resp.has_update = (to != from_ and to != from_ + 1)

        if resp.has_update:
            shift_vec(self.items, from_, to)

        self.last = resp
        self.dragging = False
        self.drag_from = -1
        self.hover_to = -1
        return True

    fn update(mut self):
        """Per-frame update hook (no animation in phase 1)."""
        pass

    # ----- Rendering -------------------------------------------------------

    fn render(self, ctx: RenderingContextInt):
        """Alias for `draw`."""
        self.draw(ctx)

    fn draw(self, ctx: RenderingContextInt):
        """Draw static rows, the insertion indicator, and the floating row."""
        if not self.visible:
            return

        var n = len(self.items)
        for i in range(n):
            # The dragged row is drawn floating later; keep its slot as a gap.
            if self.dragging and i == self.drag_from:
                self._draw_row_bg(ctx, i)
                continue
            self._draw_row(ctx, i, self._row_top(i))

        # Insertion-gap indicator + floating row while dragging.
        if self.dragging and self.hover_to >= 0:
            var gy = self._row_top(self.hover_to)
            _ = ctx.set_color(self.style.insert_line.r, self.style.insert_line.g,
                              self.style.insert_line.b, self.style.insert_line.a)
            _ = ctx.draw_filled_rectangle(self.x, gy - 1, self.width, 2)

            if self.drag_from >= 0 and self.drag_from < n:
                var fy = self.cursor_y - self.grab_dy
                _ = ctx.set_color(self.style.drag_bg.r, self.style.drag_bg.g,
                                  self.style.drag_bg.b, self.style.drag_bg.a)
                _ = ctx.draw_filled_rectangle(self.x, fy, self.width, self.row_height)
                _ = ctx.set_color(self.style.text.r, self.style.text.g,
                                  self.style.text.b, self.style.text.a)
                _ = ctx.draw_text(self.items[self.drag_from].label,
                                  self.x + 8, fy + 6, 12)

    fn _draw_row_bg(self, ctx: RenderingContextInt, i: Int):
        """Draw just the background slot for row `i` (the dragged row's gap)."""
        var top = self._row_top(i)
        var bg = self.style.row_alt if (i % 2 == 1) else self.style.row_bg
        _ = ctx.set_color(bg.r, bg.g, bg.b, bg.a)
        _ = ctx.draw_filled_rectangle(self.x, top, self.width, self.row_height)

    fn _draw_row(self, ctx: RenderingContextInt, i: Int, top: Int32):
        """Draw row `i` (alternating background + label) at pixel `top`."""
        var bg = self.style.row_alt if (i % 2 == 1) else self.style.row_bg
        _ = ctx.set_color(bg.r, bg.g, bg.b, bg.a)
        _ = ctx.draw_filled_rectangle(self.x, top, self.width, self.row_height)

        _ = ctx.set_color(self.style.text.r, self.style.text.g,
                          self.style.text.b, self.style.text.a)
        _ = ctx.draw_text(self.items[i].label, self.x + 8, top + 6, 12)


fn create_dnd_list_int(x: Int32, y: Int32, width: Int32, height: Int32) -> DndListInt:
    """Factory: create an empty DndListInt with the given bounds."""
    return DndListInt(x, y, width, height)
