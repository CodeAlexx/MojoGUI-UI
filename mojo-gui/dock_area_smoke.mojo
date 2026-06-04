"""
Compile + API smoke harness for dock/area.mojo (DockAreaInt).

Build only (do NOT run — GPU/display shared):
    pixi run mojo build mojo-gui/dock_area_smoke.mojo -o /tmp/dock_area

Uses absolute package imports so area.mojo's relative sibling imports resolve.
Constructs a DockState (split into 2 leaves), a DockAreaInt, runs layout + the
host content-rect API + event handlers (press/move/release => tab drag-dock and
splitter drag).  It does NOT call render (no GL context).
"""

from mojo_src.widgets.dock.model import DockTab, DockState, SPLIT_RIGHT, Node
from mojo_src.widgets.dock.area import DockAreaInt, create_dock_area_int
from mojo_src.widget_int import MouseEventInt, KeyEventInt


fn main():
    # Build a dock state: root leaf with 2 tabs, then split right with a 3rd.
    var tabs = List[DockTab]()
    tabs.append(DockTab(1, String("Chart")))
    tabs.append(DockTab(2, String("Orders")))
    var state = DockState(tabs^)

    var right = List[DockTab]()
    right.append(DockTab(3, String("Depth")))
    _ = state.main.split(0, SPLIT_RIGHT, 0.5, Node.leaf_with(right^))

    var dock = create_dock_area_int(0, 0, 1000, 700)
    dock.set_state(state^)            # set_state runs layout

    # Host content-rect API (index-based trio).
    var lc = dock.leaf_count()
    print("leaf_count:", lc)
    for i in range(lc):
        var body = dock.leaf_body_rect(i)
        var active_id = dock.leaf_active_tab_id(i)
        print("leaf", i, "body", body.x, body.y, body.width,
              body.height, "active_id", active_id)

    # Tab click (activate) on the first leaf's second tab strip area.
    _ = dock.handle_mouse_event(MouseEventInt(120, 10, 0, True))
    _ = dock.handle_mouse_event(MouseEventInt(120, 10, 0, False))

    # Splitter drag: press near the middle vertical splitter, move, release.
    _ = dock.handle_mouse_event(MouseEventInt(500, 350, 0, True))
    dock.on_mouse_move(560, 350)
    _ = dock.handle_mouse_event(MouseEventInt(560, 350, 0, False))

    # Tab drag-dock: press a tab, move into the other leaf (right side), release
    # in its top zone (=> split above).
    _ = dock.handle_mouse_event(MouseEventInt(20, 10, 0, True))
    dock.on_mouse_move(60, 40)        # promote to drag
    dock.on_mouse_move(800, 60)       # hover the right leaf, top zone
    _ = dock.handle_mouse_event(MouseEventInt(800, 60, 0, False))
    dock.update()

    print("after drag leaf_count:", dock.leaf_count())
    print("OK")
