# egui_dock → MojoGUI port spec (dock addon)

Porting the Rust crate `egui_dock` 0.19.1 (7,425 LOC, read-only reference at
`/tmp/egui_dock-ref/src/`) into a native MojoGUI widget package at
`mojo-gui/mojo_src/widgets/dock/`.

Phase 1 = **in-window docking**: a dockable tab/split layout inside ONE MojoGUI
window. DEFERRED (no MojoGUI equivalent yet): separate-OS-window tab tearing
(`window_surface.rs`, `WindowState` — the C backend has a single GLFW window),
serde save/load, context menus, add-popups, collapse animations, scroll bars.

## Conventions — SAME as the chart port (Mojo 0.26.2 nightly, verified)
- `out self` (init) / `mut self` (mutators) / `self` (readonly). **NO `inout`** — hard error.
- **NO struct inheritance** — `struct X(BaseWidgetInt)` is a HARD ERROR. COMPOSE
  (own `x/y/width/height/visible` fields), implement WidgetInt methods directly.
- Use `comptime` not `alias`.
- List-stored value structs derive `(ImplicitlyCopyable, Movable)`; structs owning a
  `List` derive `(Copyable, Movable)` + explicit `.copy()`/`^`.
- Imports inside `dock/`: `from .model import ...`; from outside-package:
  `from ...rendering_int import RenderingContextInt, ColorInt, RectInt, PointInt`
  and `from ...widget_int import MouseEventInt, KeyEventInt` (THREE dots — one level
  below `widgets/`, exactly like the chart package).
- **No libm**: never `from math import cos/sin/log10`; if needed, reuse the chart's
  `from ..chart.mathx import ...` or add pure-Mojo helpers. (Dock likely needs none.)
- Build/verify from repo ROOT, compile-only (NO run — GPU shared):
  `pixi run mojo build mojo-gui/<root_harness_or_demo>.mojo -o /tmp/x`.
  Package-internal files with relative imports CANNOT build standalone — verify via a
  root harness with absolute imports that CONSTRUCTS + CALLS the code.

## Rendering primitives (mojo_src/rendering_int.mojo)
`set_color`, `draw_(filled_)rectangle`, `draw_line`, `draw_(filled_)circle`,
`draw_text` / `get_text_width` / `get_text_height`, mouse/key polling.
Reference template: `mojo_src/widgets/node_graph_int.mojo` (pan/zoom/drag pattern) and
the chart `engine.mojo` (composed BaseWidgetInt, handle_mouse_event, draw).

## Key adaptation: TabViewer (immediate-mode) → content-rect callback (retained)
egui_dock is generic `<Tab>` and renders tab bodies via `TabViewer::ui(ui, tab)`.
MojoGUI is retained + integer. So:
- `Tab` becomes a concrete `DockTab { id: Int32, title: String }`.
- The dock OWNS the layout (tab strips, splitters, drag). It does NOT draw tab
  *content*. After `layout()`/`draw()`, the HOST renders content itself by querying
  the dock: per visible leaf, its body `RectInt` + active tab `id`. Provide
  `leaf_count()`, `leaf_body_rect(i)->RectInt`, `leaf_active_tab_id(i)->Int32`,
  `visible_leaves()` so the demo/host fills each body.

## File layout (each agent owns its file)
```
dock/
  model.mojo   DockTab, NodeIndex/TabIndex, LeafNode, SplitNode, Node(kind+data),
               Tree (binary-heap vec; split_left/right/above/below, remove_tab,
               remove_leaf, set_active_tab, push_to_focused_leaf, find_active),
               DockState (main surface only). Faithful to dock_state/**.    [FOUNDATION]
  style.mojo   DockStyle: ColorInt fields (tab_bg, tab_active, tab_text, border,
               splitter, drop_zone, body_bg) + sizes (tab_height, splitter_width).
  area.mojo    DockAreaInt (composes bounds): recursively compute each node's RectInt
               from SplitNode.fraction; draw splitters + per-leaf tab strips + active
               highlight; handle_mouse_event = tab click (activate), tab close (X),
               splitter drag (adjust fraction), and DRAG-AND-DROP a tab: track grab,
               compute hovered leaf + drop zone (center/left/right/top/bottom), draw
               the drop-zone preview overlay, and on release mutate the Tree
               (move_tab / split). Ports widgets/dock_area/{mod,show/leaf,
               show/main_surface,drag_and_drop,allowed_splits}.rs. Exposes the host
               content-rect API above. Factory create_dock_area_int(x,y,w,h).
dock_demo.mojo (root) build a DockState with ~4 named tabs across 2-3 leaves, a
               DockAreaInt filling the window; host loop draws a distinct colour +
               title in each leaf body rect; tabs are draggable/dockable/splittable.
DOCK_STATUS.md  ported vs deferred ledger (like the chart's PORT_STATUS.md).
```

## Faithful model details (read the .rs)
- `Node<Tab>` = Leaf | Vertical | Horizontal. LeafNode: rect, viewport(body), tabs,
  active(TabIndex), scroll, collapsed. SplitNode: rect, fraction(f32 → Float64,
  fraction of the FIRST/top/left child), fully_collapsed, collapsed_leaf_count.
- `Tree` stores nodes in a Vec indexed by `NodeIndex` using the **binary-heap scheme**
  (children of node i are 2i+1 and 2i+2) — port this exactly (tree/mod.rs). Vertical
  split = top/bottom children; Horizontal = left/right.
- `split_left/right/above/below(parent, fraction, new_tabs)` and the generic `split`
  (tree/mod.rs:476) — port the index math faithfully.
- Coords: egui `Rect` (f32) → `RectInt` (Int32 px); fractions stay Float64; convert to
  px only when laying out.

## Definition of done (phase 1)
`pixi run mojo build mojo-gui/dock_demo.mojo` → EXIT 0 (compile+link, 0 libm undefined).
Demo opens a window with multiple docked tabs; tabs can be clicked, dragged to a drop
zone to move/split, and splitters dragged to resize. Host draws content per leaf.

## VERIFIED — model.mojo (builder-foundation)

`model.mojo` compiles clean (zero errors/warnings) — verified by a root harness
`pixi run mojo build mojo-gui/<harness>.mojo -o /tmp/dock_model` → EXIT 0, on
Mojo 0.26.2.0.dev2026012806. The package marker `dock/__init__.mojo` exists (do not
delete). Build runs from the repo root via pixi; no `-I` needed.

### Import line area.mojo must use (sibling, relative)
```mojo
from .model import (
    DockTab, LeafNode, SplitNode, Node, Tree, DockState,
    NodeIndex, TabIndex,
    NODE_EMPTY, NODE_LEAF, NODE_VERTICAL, NODE_HORIZONTAL,
    SPLIT_LEFT, SPLIT_RIGHT, SPLIT_ABOVE, SPLIT_BELOW,
    node_root, node_left, node_right, node_parent,
    split_is_top_bottom, split_is_left_right,
)
```
From the root demo use the absolute form `from mojo_src.widgets.dock.model import ...`.

### Public API (names are final — match these)
- `NodeIndex` / `TabIndex` are `comptime ... = Int` aliases. "None" is `-1`.
- `DockTab(id: Int32, title: String)` — fields `.id`, `.title`. `(ImplicitlyCopyable, Movable)`.
- `LeafNode` (`Copyable, Movable`): fields `rect`, `viewport`, `tabs: List[DockTab]`,
  `active: Int`, `collapsed: Bool`. Methods `len/is_empty/rect_/set_rect(RectInt)/
  set_active_tab(i)->Bool/append_tab/insert_tab/remove_tab(i)->DockTab`.
- `SplitNode` (`ImplicitlyCopyable, Movable`): `rect`, `fraction: Float64`,
  `fully_collapsed: Bool`, `collapsed_leaf_count: Int32`; `rect_/set_rect`.
- `Node` (`Copyable, Movable`): `kind: Int32` (`NODE_*`), `leaf: LeafNode`, `split: SplitNode`.
  Ctors `Node.empty()/leaf_one(tab)/leaf_with(tabs^)/vertical(sn)/horizontal(sn)`.
  Preds `is_empty/is_leaf/is_parent/is_vertical/is_horizontal/is_collapsed`.
  `rect()->RectInt`, `set_rect`, `tabs_count`, `append_tab`, `remove_tab`,
  `collapsed_leaf_count`, `set_collapsed`, `set_collapsed_leaf_count`,
  `split_in_place(split, fraction)->Node` (returns OLD node).
- `Tree` (`Copyable, Movable`): fields `nodes: List[Node]`, `focused_node: Int`,
  `collapsed`, `collapsed_leaf_count`.
  - `Tree(tabs^)`, `Tree.empty()`.
  - read: `len/is_empty/num_tabs/root_node()->Node/is_leaf(i)/leaf(i)->LeafNode/
    focused_leaf()->Int/find_active()->Int/first_leaf(i)->Int/find_tab_by_id(id)->Tuple`.
  - mutate: `set_focused_node(i)`, `set_active_tab(node,tab)->Bool`,
    `split(parent,split,fraction,new^)->Tuple`, `split_tabs/_left/_right/_above/_below
    (parent,fraction,tabs^)->Tuple`, `remove_leaf(node)`, `remove_tab(node,tab)->DockTab`,
    `push_to_first_leaf(tab)`, `push_to_focused_leaf(tab)`, `node_update_collapsed(i)`.
- `DockState` (`Copyable, Movable`): field `main: Tree`.
  `DockState(tabs^)`, `main_surface()->Tree` (returns a COPY), `push_to_focused_leaf(tab)`.
  **To mutate the layout, call methods on `state.main` directly** (e.g.
  `state.main.split_right(...)`) — `main_surface()` hands back a copy, like the chart's
  model accessors; Mojo can't return `&mut Tree`.

### NEW gotcha for area.mojo (beyond the chart conventions)
- **A multi-value return must be `Tuple[T, U]`, not a bare `(a, b)` literal.** The bare
  tuple syntax `return (x, y)` from `-> (Int, Int)` is a HARD ERROR on this nightly
  ("missing required keyword-only argument 'storage'"). Declare `-> Tuple[NodeIndex,
  NodeIndex]` and `return Tuple[NodeIndex, NodeIndex](a, b)`. Index the result as
  `pair[0]` / `pair[1]` (that part works).
- `RectInt` from `...rendering_int` is implicitly copyable — return/store it freely.
- Reading a `Node`/`LeafNode`/`Tree` out of a `List` or field needs `.copy()` (they own
  a `List`). `DockTab`/`SplitNode`/`RectInt` copy implicitly.

### Faithfulness notes / divergences from egui_dock
- Heap indexing (`node_left/right/parent`, `children_at/left/right`) ported verbatim
  from `node_index.rs`; `Tree.split` subtree-relocation ported verbatim from
  `tree/mod.rs:476` (level loop + element swaps), `remove_leaf` from `tree/mod.rs:612`
  (sibling pull-up + trailing-Empty trim), `node_update_collapsed` from `:890`.
- Rust `Option`/`Result` returns become sentinels: node index `-1` = None; rect getters
  return a zero `RectInt(0,0,0,0)` (= egui `Rect::NOTHING`) for Empty — guard with
  `is_empty()`. `set_active_tab` returns `Bool` instead of `Result`.
- DEFERRED (not in model): window surfaces / `SurfaceIndex` (main only), `scroll`,
  `filter_map_tabs`/`map_tabs`/`retain_tabs`/`balance` (tab-type remapping — not needed
  for the concrete `DockTab`), `Translations`. Track in DOCK_STATUS.md.
