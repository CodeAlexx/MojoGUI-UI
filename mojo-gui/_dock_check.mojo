"""
_dock_check.mojo — root compile/link harness for the dock package.

NOT a demo and NOT meant to run (it would need a GPU/window for `render`). Its
sole job is to ELABORATE every model + area method body so latent List move/copy
bugs surface at compile time, per DOCK_PORT_SPEC.md's "root harness with absolute
imports that CONSTRUCTS + CALLS the code".

Build (compile + link only, from repo root — do NOT run):
    pixi run mojo build mojo-gui/_dock_check.mojo -o /tmp/dock_check

Exercises:
  - DockState built from several tabs; main-surface splits (split_right /
    split_below) and a push_to_focused_leaf.
  - Model reads: leaf/leaf_count/find_active/find_tab_by_id/root_node/num_tabs.
  - DockAreaInt via create_dock_area_int(x,y,w,h) + set_state + set_style; layout,
    handle_mouse_event (synthesized press + release MouseEventInt), the ordinal
    host API leaf_count()/leaf_body_rect(i)/leaf_active_tab_id(i), update().
  - A tab removal through the model (remove_tab) to drive remove_leaf bodies.
  - render(ctx) is elaborated under a never-taken branch so the window path is
    compiled+linked without opening a window.
"""

from mojo_src.rendering_int import RenderingContextInt, RectInt
from mojo_src.widget_int import MouseEventInt, KeyEventInt
from mojo_src.widgets.dock.model import (
    DockTab, DockState, Tree, Node, LeafNode,
    NodeIndex, TabIndex, node_root,
)
from mojo_src.widgets.dock.style import DockStyle
from mojo_src.widgets.dock.area import DockAreaInt, create_dock_area_int


comptime MB_LEFT: Int32 = 0


fn build_state() -> DockState:
    """Build a DockState: root [A,B] -> split_right adds [C] -> split_below
    adds [D] on the right leaf; then push another tab onto the focused leaf."""
    var root_tabs = List[DockTab]()
    root_tabs.append(DockTab(1, String("Alpha")))
    root_tabs.append(DockTab(2, String("Bravo")))
    var state = DockState(root_tabs^)

    var c_tabs = List[DockTab]()
    c_tabs.append(DockTab(3, String("Charlie")))
    var right = state.main.split_right(node_root(), 0.6, c_tabs^)
    var right_leaf = right[1]

    var d_tabs = List[DockTab]()
    d_tabs.append(DockTab(4, String("Delta")))
    _ = state.main.split_below(right_leaf, 0.7, d_tabs^)

    state.push_to_focused_leaf(DockTab(5, String("Echo")))
    return state^


fn main() raises:
    # --- Model construction + reads -----------------------------------------
    var state = build_state()

    var tree_copy = state.main_surface()          # main_surface() -> Tree copy
    var num_nodes = tree_copy.len()
    var num_tabs = tree_copy.num_tabs()
    var active = tree_copy.find_active()           # first-leaf index
    var root = tree_copy.root_node()               # Node copy
    _ = root.is_parent()
    var found = state.main.find_tab_by_id(3)       # Tuple[NodeIndex, TabIndex]
    var found_node = found[0]
    var found_tab = found[1]
    print("nodes=", num_nodes, " tabs=", num_tabs, " active=", active,
          " found_node=", found_node, " found_tab=", found_tab)

    # Drive leaf-level reads on a copied leaf (elaborates LeafNode bodies).
    if active >= 0 and tree_copy.is_leaf(active):
        var lf = tree_copy.leaf(active)            # LeafNode copy
        print("active leaf tabs=", lf.len(), " empty=", lf.is_empty())

    # --- DockAreaInt: factory + set_state + set_style + layout --------------
    var area = create_dock_area_int(0, 36, 1000, 664)
    area.set_state(state^)
    area.set_style(DockStyle.dark())
    area.set_style(DockStyle.light())
    area.layout()
    area.update()

    # Host ordinal API (no node indices — i in 0..leaf_count).
    var lc = area.leaf_count()
    print("leaf_count=", lc)
    for i in range(lc):
        var body: RectInt = area.leaf_body_rect(i)
        var tid = area.leaf_active_tab_id(i)
        print("leaf ", i, " body=(", body.x, body.y, body.width, body.height,
              ") active_id=", tid)

    # --- Synthesized mouse events (press then move then release) ------------
    # A press inside a tab strip arms a possible drag; a move promotes it to a
    # tab-drag; a release commits the drop. These drive _on_press/_on_release/
    # on_mouse_move/_commit_drop bodies (and through them split/append/remove).
    var press = MouseEventInt(20, 40, MB_LEFT, True)
    _ = area.handle_mouse_event(press)
    area.on_mouse_move(120, 300)                   # promote + track drop target
    area.on_mouse_move(700, 500)
    var release = MouseEventInt(700, 500, MB_LEFT, False)
    _ = area.handle_mouse_event(release)

    # A second press on a splitter region then release (splitter-drag bodies).
    var sp_press = MouseEventInt(600, 400, MB_LEFT, True)
    _ = area.handle_mouse_event(sp_press)
    area.on_mouse_move(620, 400)
    var sp_release = MouseEventInt(620, 400, MB_LEFT, False)
    _ = area.handle_mouse_event(sp_release)

    # Key event path (no-op in phase 1, but elaborate the body).
    _ = area.handle_key_event(KeyEventInt(0, True))

    print("leaf_count after interaction=", area.leaf_count())

    # --- Direct model removal to drive remove_tab/remove_leaf ----------------
    # Re-find a tab by id and remove it from its leaf (may empty the leaf and
    # trigger remove_leaf's sibling pull-up + trailing-Empty trim).
    var loc = state_after_removal(area)
    print("post-removal node=", loc[0], " tab=", loc[1])

    # --- render(ctx): elaborate the window draw path WITHOUT opening a window.
    # Guarded by a runtime flag the compiler can't fold away, so the body is
    # type-checked AND linked while the branch is never taken. (The harness is
    # compile-only — never executed; nothing here opens a window.)
    var draw_path: Bool = num_nodes < 0
    if draw_path:
        var ctx = RenderingContextInt(String("./c_src/librendering_with_fonts.so"))
        area.render(ctx)

    print("dock check elaborated OK")


fn state_after_removal(mut area: DockAreaInt) -> Tuple[NodeIndex, TabIndex]:
    """Remove a tab via the model on the area's state, returning where a
    remaining tab now lives. Drives Tree.remove_tab / remove_leaf."""
    var loc = area.state.main.find_tab_by_id(4)
    var node = loc[0]
    var tab = loc[1]
    if node >= 0 and tab >= 0:
        _ = area.state.main.remove_tab(node, tab)
        area.layout()
    # Report where Alpha (id 1) ended up after the structural change.
    return area.state.main.find_tab_by_id(1)
