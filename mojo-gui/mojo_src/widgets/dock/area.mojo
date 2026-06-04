"""
DockAreaInt — the dock layout/render/interaction widget (egui_dock port).

Port of egui_dock `src/widgets/dock_area/` for phase-1 in-window docking:
  - /tmp/egui_dock-ref/src/widgets/dock_area/show/main_surface.rs -> recursive layout
  - /tmp/egui_dock-ref/src/widgets/dock_area/show/leaf.rs          -> tab strip draw
  - /tmp/egui_dock-ref/src/widgets/dock_area/drag_and_drop.rs      -> drop-zone math
  - /tmp/egui_dock-ref/src/widgets/dock_area/allowed_splits.rs     -> AllowedSplits
  - /tmp/egui_dock-ref/src/widgets/dock_area/mod.rs                 -> DockArea shell

DockAreaInt COMPOSES its own bounds (never inherits `BaseWidgetInt`, a hard error
on this nightly), owns a `DockState`, a `DockStyle`, and interaction state.  The
HOST draws tab *content* itself (the retained-mode replacement for egui_dock's
immediate-mode `TabViewer::ui`): after `layout()`/`draw()` the host queries
`leaf_count()` / `leaf_body_rect(i)` / `leaf_active_tab_id(i)` (ordinal `i` over
the visible leaves) and fills each leaf body.

Mojo 0.26.2 nightly conventions (DOCK_PORT_SPEC.md):
  - `out self` (init) / `mut self` (mutators) / `self` (readonly). NO `inout`.
  - NO struct inheritance; compose.  `comptime` not `alias`.  No libm.
  - List-stored value structs derive `(ImplicitlyCopyable, Movable)`; a struct
    owning a `List` (DockState owns Tree owns List) derives `(Copyable, Movable)`.
  - Every `RenderingContextInt` draw call returns `Bool`; discarded with `_ =`.
"""

from ...rendering_int import RenderingContextInt, ColorInt, RectInt, PointInt
from ...widget_int import MouseEventInt, KeyEventInt
from .model import (
    DockTab, LeafNode, SplitNode, Node, Tree, DockState,
    NodeIndex, TabIndex,
    node_left, node_right, node_parent,
    NODE_EMPTY, NODE_LEAF, NODE_VERTICAL, NODE_HORIZONTAL,
    SPLIT_LEFT, SPLIT_RIGHT, SPLIT_ABOVE, SPLIT_BELOW,
)
from .style import DockStyle

comptime MB_LEFT: Int32 = 0
comptime MB_RIGHT: Int32 = 1

# Drop zones for a tab dragged over a leaf (port of the egui_dock overlay buttons:
# center = move/append into the leaf; the four edges = split the leaf that way).
comptime ZONE_NONE: Int32 = 0
comptime ZONE_CENTER: Int32 = 1
comptime ZONE_LEFT: Int32 = 2
comptime ZONE_RIGHT: Int32 = 3
comptime ZONE_TOP: Int32 = 4
comptime ZONE_BOTTOM: Int32 = 5

# Fraction of the leaf's half-extent within which an edge zone is active; the
# central remainder is the "move into leaf" zone (drag_and_drop.rs uses overlay
# buttons; here we derive the zone from cursor position, per the team-lead spec).
comptime EDGE_ZONE_FRAC: Float64 = 0.30

# Splitter fraction clamp (egui_dock clamps to keep both children visible).
comptime MIN_FRACTION: Float64 = 0.05
comptime MAX_FRACTION: Float64 = 0.95

# Pixel slop for grabbing a splitter line.
comptime SPLITTER_GRAB: Int32 = 4

# Fixed width of a tab button in the strip (egui_dock sizes tabs to their label;
# the integer/retained port uses a uniform button width for simple hit-testing).
comptime TAB_BUTTON_WIDTH: Int32 = 110


fn _tab_strip_width() -> Int32:
    """Uniform pixel width of one tab button in a leaf's tab strip."""
    return TAB_BUTTON_WIDTH


struct DockAreaInt(Copyable, Movable):
    """In-window dock area: layout, draw, tab/splitter/drag interaction.

    Composes its own bounds (no inheritance).  Owns the `DockState`; `(Copyable,
    Movable)` because `DockState` owns a `Tree` (a `List`), which is not
    implicitly copyable.
    """

    # ----- Bounds (replacing BaseWidgetInt inheritance) --------------------
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
    var visible: Bool

    # ----- State + style ---------------------------------------------------
    var state: DockState
    """The dock layout state (main surface tree)."""
    var style: DockStyle
    """Colors + sizes."""

    # ----- Interaction state ----------------------------------------------
    var dragging_tab: Bool
    """True while a tab is being dragged for docking."""
    var drag_src_node: NodeIndex
    """Leaf node the dragged tab came from."""
    var drag_src_tab: TabIndex
    """Index of the dragged tab within its source leaf."""
    var drag_tab_id: Int32
    """Stable id of the dragged tab (survives tree mutation)."""
    var drag_cursor_x: Int32
    var drag_cursor_y: Int32
    var hovered_leaf: NodeIndex
    """Leaf under the cursor while dragging (drop target), or -1."""
    var hovered_zone: Int32
    """Drop zone within `hovered_leaf` (ZONE_*)."""

    var dragging_splitter: Bool
    """True while a splitter is being dragged."""
    var drag_split_node: NodeIndex
    """Split node whose fraction is being adjusted."""

    var press_armed: Bool
    """A left-press landed on a tab; a drag may start if the cursor moves."""
    var press_node: NodeIndex
    var press_tab: TabIndex
    var press_x: Int32
    var press_y: Int32

    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.visible = True
        self.state = DockState(List[DockTab]())   # empty until set_state
        self.style = DockStyle.dark()

        self.dragging_tab = False
        self.drag_src_node = -1
        self.drag_src_tab = -1
        self.drag_tab_id = -1
        self.drag_cursor_x = 0
        self.drag_cursor_y = 0
        self.hovered_leaf = -1
        self.hovered_zone = ZONE_NONE

        self.dragging_splitter = False
        self.drag_split_node = -1

        self.press_armed = False
        self.press_node = -1
        self.press_tab = -1
        self.press_x = 0
        self.press_y = 0

    fn set_state(mut self, var state: DockState):
        """Replace the dock state (takes ownership) and re-layout."""
        self.state = state^
        self.layout()

    fn set_style(mut self, style: DockStyle):
        """Apply a dock style (called by builder/theme)."""
        self.style = style

    # =====================================================================
    # Layout — recursive walk assigning a RectInt to every node
    # (port of show/main_surface.rs render_nodes + node rect division)
    # =====================================================================

    fn layout(mut self):
        """Assign each node its `RectInt` (and each leaf its body viewport).

        Divides a split node's rect by `fraction` (minus the splitter width):
        Vertical = top/bottom (first child = top), Horizontal = left/right
        (first child = left).  Leaf body = rect minus the top tab strip.
        """
        var root_rect = RectInt(self.x, self.y, self.width, self.height)
        if self.state.main.is_empty():
            return
        self._layout_node(0, root_rect)

    fn _layout_node(mut self, node: NodeIndex, rect: RectInt):
        """Recursively assign `rect` to `node` and its descendants."""
        var n = len(self.state.main.nodes)
        if node < 0 or node >= n:
            return
        var kind = self.state.main.nodes[node].kind
        if kind == NODE_EMPTY:
            return

        self.state.main.nodes[node].set_rect(rect)

        if kind == NODE_LEAF:
            # Body viewport = rect minus the tab strip across the top.
            var th = self.style.tab_height
            var body_h = rect.height - th
            if body_h < 0:
                body_h = 0
            var body = RectInt(rect.x, rect.y + th, rect.width, body_h)
            self.state.main.nodes[node].leaf.viewport = body
            return

        # Split node: divide the rect by fraction along the split axis.
        var frac = self.state.main.nodes[node].split.fraction
        var sw = self.style.splitter_width
        var first_rect: RectInt
        var second_rect: RectInt

        if kind == NODE_VERTICAL:
            # Top/bottom: first child = top.
            var avail = rect.height - sw
            if avail < 0:
                avail = 0
            var top_h = Int32(Float64(avail) * frac)
            var bot_h = avail - top_h
            first_rect = RectInt(rect.x, rect.y, rect.width, top_h)
            second_rect = RectInt(rect.x, rect.y + top_h + sw, rect.width, bot_h)
        else:
            # Horizontal left/right: first child = left.
            var avail = rect.width - sw
            if avail < 0:
                avail = 0
            var left_w = Int32(Float64(avail) * frac)
            var right_w = avail - left_w
            first_rect = RectInt(rect.x, rect.y, left_w, rect.height)
            second_rect = RectInt(rect.x + left_w + sw, rect.y, right_w, rect.height)

        self._layout_node(node_left(node), first_rect)
        self._layout_node(node_right(node), second_rect)

    # =====================================================================
    # Host content-rect API (the TabViewer replacement)
    # =====================================================================

    fn leaf_count(self) -> Int:
        """Number of leaf nodes currently in the tree."""
        var c = 0
        for i in range(len(self.state.main.nodes)):
            if self.state.main.nodes[i].kind == NODE_LEAF:
                c += 1
        return c

    fn _node_for_leaf(self, i: Int) -> NodeIndex:
        """Internal: node index of the `i`-th VISIBLE leaf (heap order), or -1."""
        var seen = 0
        for ni in range(len(self.state.main.nodes)):
            if self.state.main.nodes[ni].kind == NODE_LEAF:
                if seen == i:
                    return ni
                seen += 1
        return -1

    fn leaf_body_rect(self, i: Int) -> RectInt:
        """Body (content) rect for the `i`-th visible leaf; zero rect if absent.

        `i` is `0..leaf_count` over the VISIBLE leaves (the host iterates with
        this index — it does not deal in node indices).
        """
        var node = self._node_for_leaf(i)
        if node >= 0:
            return self.state.main.nodes[node].leaf.viewport
        return RectInt(0, 0, 0, 0)

    fn leaf_active_tab_id(self, i: Int) -> Int32:
        """`id` of the active tab in the `i`-th visible leaf, or -1.

        `i` is `0..leaf_count` over the VISIBLE leaves.  The host maps the
        returned id to its own content.
        """
        var node = self._node_for_leaf(i)
        if node >= 0:
            var active = self.state.main.nodes[node].leaf.active
            var ntabs = len(self.state.main.nodes[node].leaf.tabs)
            if active >= 0 and active < ntabs:
                return self.state.main.nodes[node].leaf.tabs[active].id
        return -1

    # =====================================================================
    # Tab-strip geometry helpers
    # =====================================================================

    fn _tab_rect(self, leaf_rect: RectInt, tab_i: Int) -> RectInt:
        """Pixel rect of tab button `tab_i` in a leaf's tab strip."""
        var tw = _tab_strip_width()
        var th = self.style.tab_height
        return RectInt(leaf_rect.x + Int32(tab_i) * tw, leaf_rect.y, tw, th)

    fn _close_rect(self, tab_rect: RectInt) -> RectInt:
        """Pixel rect of the close 'x' inside a tab button."""
        var sz: Int32 = 12
        var cx = tab_rect.x + tab_rect.width - sz - 2
        var cy = tab_rect.y + (tab_rect.height - sz) // 2
        return RectInt(cx, cy, sz, sz)

    # =====================================================================
    # Drop-zone math (port/adaptation of drag_and_drop.rs)
    # =====================================================================

    fn _zone_at(self, leaf_rect: RectInt, px: Int32, py: Int32) -> Int32:
        """Drop zone for a cursor inside `leaf_rect` (ZONE_* constants).

        Edge bands (EDGE_ZONE_FRAC of each half-extent) map to a split in that
        direction; the central region is ZONE_CENTER (move into the leaf).  This
        replaces egui_dock's overlay drop buttons with positional zones, per the
        team-lead's adaptation.  Left/right take precedence over top/bottom only
        when the cursor is closer to a vertical edge.
        """
        if leaf_rect.width <= 0 or leaf_rect.height <= 0:
            return ZONE_NONE
        var rx = Float64(px - leaf_rect.x) / Float64(leaf_rect.width)
        var ry = Float64(py - leaf_rect.y) / Float64(leaf_rect.height)
        if rx < 0.0 or rx > 1.0 or ry < 0.0 or ry > 1.0:
            return ZONE_NONE

        var edge = EDGE_ZONE_FRAC
        # Distance to each edge (0 = on the edge).
        var dl = rx
        var dr = 1.0 - rx
        var dt = ry
        var db = 1.0 - ry

        # Pick the closest edge if within its band; else center.
        var min_d = dl
        var zone = ZONE_LEFT
        if dr < min_d:
            min_d = dr
            zone = ZONE_RIGHT
        if dt < min_d:
            min_d = dt
            zone = ZONE_TOP
        if db < min_d:
            min_d = db
            zone = ZONE_BOTTOM

        if min_d <= edge:
            return zone
        return ZONE_CENTER

    fn _zone_preview_rect(self, leaf_rect: RectInt, zone: Int32) -> RectInt:
        """Half/quadrant rect to highlight for a drop zone preview."""
        var w = leaf_rect.width
        var h = leaf_rect.height
        if zone == ZONE_LEFT:
            return RectInt(leaf_rect.x, leaf_rect.y, w // 2, h)
        if zone == ZONE_RIGHT:
            return RectInt(leaf_rect.x + w - w // 2, leaf_rect.y, w // 2, h)
        if zone == ZONE_TOP:
            return RectInt(leaf_rect.x, leaf_rect.y, w, h // 2)
        if zone == ZONE_BOTTOM:
            return RectInt(leaf_rect.x, leaf_rect.y + h - h // 2, w, h // 2)
        # Center: whole leaf.
        return leaf_rect

    fn _leaf_at(self, px: Int32, py: Int32) -> NodeIndex:
        """Leaf node whose rect contains the pixel, or -1."""
        for ni in range(len(self.state.main.nodes)):
            if self.state.main.nodes[ni].kind == NODE_LEAF:
                var r = self.state.main.nodes[ni].leaf.rect
                if (px >= r.x and px < r.x + r.width
                        and py >= r.y and py < r.y + r.height):
                    return ni
        return -1

    # =====================================================================
    # Splitter hit-testing
    # =====================================================================

    fn _splitter_at(self, px: Int32, py: Int32) -> NodeIndex:
        """Split node whose splitter bar is under the cursor, or -1.

        The splitter sits between the two children: a vertical split's bar is the
        horizontal strip of `splitter_width` below the first (top) child; a
        horizontal split's bar is the vertical strip right of the first (left)
        child.
        """
        var sw = self.style.splitter_width
        for ni in range(len(self.state.main.nodes)):
            var kind = self.state.main.nodes[ni].kind
            if kind != NODE_VERTICAL and kind != NODE_HORIZONTAL:
                continue
            var r = self.state.main.nodes[ni].split.rect
            var frac = self.state.main.nodes[ni].split.fraction
            if kind == NODE_VERTICAL:
                var avail = r.height - sw
                if avail < 0:
                    avail = 0
                var top_h = Int32(Float64(avail) * frac)
                var bar_y = r.y + top_h
                if (py >= bar_y - SPLITTER_GRAB and py <= bar_y + sw + SPLITTER_GRAB
                        and px >= r.x and px < r.x + r.width):
                    return ni
            else:
                var avail = r.width - sw
                if avail < 0:
                    avail = 0
                var left_w = Int32(Float64(avail) * frac)
                var bar_x = r.x + left_w
                if (px >= bar_x - SPLITTER_GRAB and px <= bar_x + sw + SPLITTER_GRAB
                        and py >= r.y and py < r.y + r.height):
                    return ni
        return -1

    # =====================================================================
    # Event handling
    # =====================================================================

    fn contains_point(self, px: Int32, py: Int32) -> Bool:
        return (px >= self.x and px < self.x + self.width
                and py >= self.y and py < self.y + self.height)

    fn on_mouse_move(mut self, px: Int32, py: Int32):
        """Continuous pointer-move hook (demo polls the mouse each frame).

        Drives the splitter drag, the drop-target tracking while dragging a tab,
        and promotes an armed tab press into a drag once the cursor moves.
        """
        if self.dragging_splitter:
            self._drag_splitter_to(px, py)
            return

        if self.dragging_tab:
            self.drag_cursor_x = px
            self.drag_cursor_y = py
            var leaf = self._leaf_at(px, py)
            self.hovered_leaf = leaf
            if leaf != -1:
                var r = self.state.main.nodes[leaf].leaf.rect
                self.hovered_zone = self._zone_at(r, px, py)
            else:
                self.hovered_zone = ZONE_NONE
            return

        if self.press_armed:
            var dx = px - self.press_x
            var dy = py - self.press_y
            # Promote to a drag once the cursor moves a few pixels.
            if dx * dx + dy * dy > 16:
                self.dragging_tab = True
                self.drag_src_node = self.press_node
                self.drag_src_tab = self.press_tab
                self.drag_tab_id = self._tab_id_at(self.press_node, self.press_tab)
                self.drag_cursor_x = px
                self.drag_cursor_y = py
                self.press_armed = False

    fn _tab_id_at(self, node: NodeIndex, tab: TabIndex) -> Int32:
        """`id` of tab `tab` in leaf `node`, or -1."""
        if node >= 0 and node < len(self.state.main.nodes):
            if self.state.main.nodes[node].kind == NODE_LEAF:
                var ntabs = len(self.state.main.nodes[node].leaf.tabs)
                if tab >= 0 and tab < ntabs:
                    return self.state.main.nodes[node].leaf.tabs[tab].id
        return -1

    fn _drag_splitter_to(mut self, px: Int32, py: Int32):
        """Adjust the dragged split node's fraction to the cursor."""
        var ni = self.drag_split_node
        if ni < 0 or ni >= len(self.state.main.nodes):
            return
        var kind = self.state.main.nodes[ni].kind
        var r = self.state.main.nodes[ni].split.rect
        var sw = self.style.splitter_width
        var frac: Float64
        if kind == NODE_VERTICAL:
            var avail = r.height - sw
            if avail <= 0:
                return
            frac = Float64(py - r.y) / Float64(avail)
        elif kind == NODE_HORIZONTAL:
            var avail = r.width - sw
            if avail <= 0:
                return
            frac = Float64(px - r.x) / Float64(avail)
        else:
            return
        if frac < MIN_FRACTION:
            frac = MIN_FRACTION
        if frac > MAX_FRACTION:
            frac = MAX_FRACTION
        self.state.main.nodes[ni].split.fraction = frac
        # Re-layout so child rects + viewports follow the splitter.
        self.layout()

    fn handle_mouse_event(mut self, e: MouseEventInt) -> Bool:
        """Press: start splitter/tab-drag or activate/close a tab.  Release:
        commit a tab drop or end a splitter drag.
        """
        if not self.visible:
            return False

        if e.pressed and e.button == MB_LEFT:
            return self._on_press(e.x, e.y)
        if (not e.pressed) and e.button == MB_LEFT:
            return self._on_release(e.x, e.y)
        return False

    fn _on_press(mut self, px: Int32, py: Int32) -> Bool:
        """Left-button press: splitter grab, tab activate/close, or arm a drag."""
        if not self.contains_point(px, py):
            return False

        # 1) Splitter?
        var sp = self._splitter_at(px, py)
        if sp != -1:
            self.dragging_splitter = True
            self.drag_split_node = sp
            return True

        # 2) Tab strip of some leaf?
        var leaf = self._leaf_at(px, py)
        if leaf == -1:
            return False
        var lr = self.state.main.nodes[leaf].leaf.rect
        var th = self.style.tab_height
        if py >= lr.y and py < lr.y + th:
            var ntabs = len(self.state.main.nodes[leaf].leaf.tabs)
            for ti in range(ntabs):
                var tr = self._tab_rect(lr, ti)
                if (px >= tr.x and px < tr.x + tr.width
                        and py >= tr.y and py < tr.y + tr.height):
                    # Close 'x' hit?
                    var cr = self._close_rect(tr)
                    if (px >= cr.x and px < cr.x + cr.width
                            and py >= cr.y and py < cr.y + cr.height):
                        _ = self.state.main.remove_tab(leaf, ti)
                        self.layout()
                        return True
                    # Otherwise activate + arm a possible drag.
                    _ = self.state.main.set_active_tab(leaf, ti)
                    self.state.main.set_focused_node(leaf)
                    self.press_armed = True
                    self.press_node = leaf
                    self.press_tab = ti
                    self.press_x = px
                    self.press_y = py
                    return True
        return False

    fn _on_release(mut self, px: Int32, py: Int32) -> Bool:
        """Left-button release: commit a tab drop, or end a splitter drag."""
        if self.dragging_splitter:
            self.dragging_splitter = False
            self.drag_split_node = -1
            return True

        var handled = False
        if self.dragging_tab:
            handled = self._commit_drop(px, py)

        # Always clear transient state on release.
        self.dragging_tab = False
        self.press_armed = False
        self.drag_src_node = -1
        self.drag_src_tab = -1
        self.drag_tab_id = -1
        self.hovered_leaf = -1
        self.hovered_zone = ZONE_NONE
        return handled

    fn _commit_drop(mut self, px: Int32, py: Int32) -> Bool:
        """Move/split using the dragged tab and the hovered leaf + zone.

        Center -> move tab into the target leaf.  Edge -> split the target leaf in
        that direction with the dragged tab in the new leaf.  No-op if dropping
        onto the source leaf's own center (nothing to do).
        """
        var target = self._leaf_at(px, py)
        if target == -1:
            return False
        var zone = self._zone_at(self.state.main.nodes[target].leaf.rect, px, py)
        if zone == ZONE_NONE:
            return False

        var src_node = self.drag_src_node
        var src_tab = self.drag_src_tab
        if src_node < 0 or src_node >= len(self.state.main.nodes):
            return False
        if self.state.main.nodes[src_node].kind != NODE_LEAF:
            return False
        if src_tab < 0 or src_tab >= len(self.state.main.nodes[src_node].leaf.tabs):
            return False

        # Dropping into the same leaf's center: nothing meaningful to do.
        if zone == ZONE_CENTER and target == src_node:
            return False

        # Pull the tab out of its source leaf.  Removing may delete the source
        # leaf (when it empties) and re-home the heap, so capture the tab's id and
        # re-find the target by id-stable means afterward.
        var moved = self.state.main.remove_tab(src_node, src_tab)

        # After remove_tab the tree may have collapsed; re-find the target leaf.
        # The target node index can shift, so locate a leaf still containing the
        # rect under the cursor.
        var new_target = self._leaf_at(px, py)
        if new_target == -1:
            # Target leaf vanished (it was the source and got removed): push to a
            # focused/first leaf so the tab is never lost.
            self.state.main.push_to_focused_leaf(moved)
            self.layout()
            return True

        if zone == ZONE_CENTER:
            self.state.main.nodes[new_target].leaf.append_tab(moved)
        else:
            var tabs = List[DockTab]()
            tabs.append(moved)
            var split: Int32
            if zone == ZONE_LEFT:
                split = SPLIT_LEFT
            elif zone == ZONE_RIGHT:
                split = SPLIT_RIGHT
            elif zone == ZONE_TOP:
                split = SPLIT_ABOVE
            else:
                split = SPLIT_BELOW
            _ = self.state.main.split(new_target, split, 0.5, Node.leaf_with(tabs^))

        self.layout()
        return True

    fn handle_key_event(mut self, e: KeyEventInt) -> Bool:
        """No keyboard bindings in phase 1 (tabs/splitters are mouse-driven)."""
        return False

    fn update(mut self):
        """Per-frame update: keep the layout in sync with the current bounds."""
        self.layout()

    # =====================================================================
    # Rendering
    # =====================================================================

    fn render(self, ctx: RenderingContextInt):
        """Alias for `draw` (WidgetInt-style name)."""
        self.draw(ctx)

    fn draw(self, ctx: RenderingContextInt):
        """Draw every leaf (tab strip + body bg) + splitters + drop preview."""
        if not self.visible:
            return

        for ni in range(len(self.state.main.nodes)):
            var kind = self.state.main.nodes[ni].kind
            if kind == NODE_LEAF:
                self._draw_leaf(ctx, ni)
            elif kind == NODE_VERTICAL or kind == NODE_HORIZONTAL:
                self._draw_splitter(ctx, ni)

        if self.dragging_tab and self.hovered_leaf != -1 and self.hovered_zone != ZONE_NONE:
            self._draw_drop_preview(ctx)

    fn _draw_leaf(self, ctx: RenderingContextInt, node: NodeIndex):
        """Draw a leaf: body background, border, and the tab strip."""
        var r = self.state.main.nodes[node].leaf.rect

        # Body background.
        _ = ctx.set_color(self.style.body_bg.r, self.style.body_bg.g,
                          self.style.body_bg.b, self.style.body_bg.a)
        _ = ctx.draw_filled_rectangle(r.x, r.y + self.style.tab_height, r.width,
                                      r.height - self.style.tab_height)

        # Leaf border.
        _ = ctx.set_color(self.style.border.r, self.style.border.g,
                          self.style.border.b, self.style.border.a)
        _ = ctx.draw_rectangle(r.x, r.y, r.width, r.height)

        # Tab strip.
        var active = self.state.main.nodes[node].leaf.active
        var ntabs = len(self.state.main.nodes[node].leaf.tabs)
        for ti in range(ntabs):
            var tr = self._tab_rect(r, ti)
            var is_active = (ti == active)
            var bg = self.style.tab_active_bg if is_active else self.style.tab_bg
            _ = ctx.set_color(bg.r, bg.g, bg.b, bg.a)
            _ = ctx.draw_filled_rectangle(tr.x, tr.y, tr.width, tr.height)
            _ = ctx.set_color(self.style.border.r, self.style.border.g,
                              self.style.border.b, self.style.border.a)
            _ = ctx.draw_rectangle(tr.x, tr.y, tr.width, tr.height)

            # Title.
            _ = ctx.set_color(self.style.tab_text.r, self.style.tab_text.g,
                              self.style.tab_text.b, self.style.tab_text.a)
            _ = ctx.draw_text(self.state.main.nodes[node].leaf.tabs[ti].title,
                              tr.x + 6, tr.y + 5, 11)

            # Close 'x'.
            var cr = self._close_rect(tr)
            _ = ctx.set_color(self.style.close_btn.r, self.style.close_btn.g,
                              self.style.close_btn.b, self.style.close_btn.a)
            _ = ctx.draw_line(cr.x, cr.y, cr.x + cr.width, cr.y + cr.height, 1)
            _ = ctx.draw_line(cr.x + cr.width, cr.y, cr.x, cr.y + cr.height, 1)

    fn _draw_splitter(self, ctx: RenderingContextInt, node: NodeIndex):
        """Draw the splitter bar between a split node's two children."""
        var sn = self.state.main.nodes[node].split
        var r = sn.rect
        var sw = self.style.splitter_width
        var frac = sn.fraction
        _ = ctx.set_color(self.style.splitter.r, self.style.splitter.g,
                          self.style.splitter.b, self.style.splitter.a)
        if self.state.main.nodes[node].kind == NODE_VERTICAL:
            var avail = r.height - sw
            if avail < 0:
                avail = 0
            var top_h = Int32(Float64(avail) * frac)
            _ = ctx.draw_filled_rectangle(r.x, r.y + top_h, r.width, sw)
        else:
            var avail = r.width - sw
            if avail < 0:
                avail = 0
            var left_w = Int32(Float64(avail) * frac)
            _ = ctx.draw_filled_rectangle(r.x + left_w, r.y, sw, r.height)

    fn _draw_drop_preview(self, ctx: RenderingContextInt):
        """Draw the translucent drop-zone preview over the hovered leaf."""
        var lr = self.state.main.nodes[self.hovered_leaf].leaf.rect
        var pr = self._zone_preview_rect(lr, self.hovered_zone)
        _ = ctx.set_color(self.style.drop_zone.r, self.style.drop_zone.g,
                          self.style.drop_zone.b, self.style.drop_zone.a)
        _ = ctx.draw_filled_rectangle(pr.x, pr.y, pr.width, pr.height)


fn create_dock_area_int(x: Int32, y: Int32, width: Int32, height: Int32) -> DockAreaInt:
    """Factory: create a DockAreaInt with the given bounds and an empty state.

    Assign the layout with `set_state(...)` and colors with `set_style(...)`.
    """
    return DockAreaInt(x, y, width, height)
