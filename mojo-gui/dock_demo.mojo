"""
DOCK DEMO — egui_dock MojoGUI port (phase 1, in-window docking)

Builds a `DockState` (via the dock model API) with 4 named tabs split into 3
leaves, wraps it in a `DockAreaInt` that fills the window, and runs a
node_graph_demo-style window loop.  Each frame the dock handles mouse input and
draws its own chrome (tab strips, splitters, active highlight, drag/drop
preview); then the HOST draws tab *content* itself by querying the dock's
content API per visible leaf — filling each leaf body rect with a distinct
ColorInt and the active tab's title.

This split (dock owns layout, host owns content) is the retained/integer
adaptation of egui_dock's immediate-mode `TabViewer::ui` — see DOCK_PORT_SPEC.md
"Key adaptation".

Build (compile-only check from repo root; do NOT open the window here):
    pixi run mojo build mojo-gui/dock_demo.mojo -o /tmp/dock_demo_check

Uses the real DockAreaInt API (dock/area.mojo): create_dock_area_int(x,y,w,h) +
set_state(state^), set_style, layout, handle_mouse_event, render, and the
ordinal host content API leaf_count() / leaf_body_rect(i) /
leaf_active_tab_id(i).
"""

from mojo_src.rendering_int import RenderingContextInt, ColorInt
from mojo_src.widget_int import MouseEventInt
from mojo_src.widgets.dock.model import (
    DockTab, DockState, node_root,
)
from mojo_src.widgets.dock.style import DockStyle
from mojo_src.widgets.dock.area import DockAreaInt, create_dock_area_int


comptime WINDOW_WIDTH: Int32 = 1000
comptime WINDOW_HEIGHT: Int32 = 700

# Dock area fills the window below a header strip.
comptime HEADER_HEIGHT: Int32 = 36
comptime DOCK_X: Int32 = 0
comptime DOCK_Y: Int32 = HEADER_HEIGHT
comptime DOCK_W: Int32 = WINDOW_WIDTH
comptime DOCK_H: Int32 = WINDOW_HEIGHT - HEADER_HEIGHT

# GLFW mouse-button constant (left) — matches the other demos.
comptime GLFW_MOUSE_BUTTON_LEFT: Int32 = 0

# Tab ids (host-stable identifiers, matched to titles + body colors below).
comptime TAB_EXPLORER: Int32 = 1
comptime TAB_EDITOR: Int32 = 2
comptime TAB_CONSOLE: Int32 = 3
comptime TAB_PROPERTIES: Int32 = 4


fn tab_title_for(id: Int32) -> String:
    """Host-side id -> title lookup (the dock returns ids; the host owns content)."""
    if id == TAB_EXPLORER:   return String("Explorer")
    if id == TAB_EDITOR:     return String("Editor")
    if id == TAB_CONSOLE:    return String("Console")
    if id == TAB_PROPERTIES: return String("Properties")
    return String("Tab " + String(id))


fn leaf_body_color(i: Int) -> ColorInt:
    """A distinct body fill per leaf so the docked layout is visually obvious."""
    var palette = List[ColorInt]()
    palette.append(ColorInt(34, 44, 60, 255))    # slate blue
    palette.append(ColorInt(40, 54, 44, 255))    # forest green
    palette.append(ColorInt(58, 44, 40, 255))    # warm brown
    palette.append(ColorInt(48, 40, 58, 255))    # muted purple
    palette.append(ColorInt(40, 40, 40, 255))    # neutral grey (overflow)
    if i < 0:
        return palette[len(palette) - 1]
    return palette[i % len(palette)]


fn build_demo_state() -> DockState:
    """Build a DockState with 4 tabs across 3 leaves.

    Layout: root leaf [Explorer] -> split_right 60/40 adds [Editor] ->
    split_below on the right leaf adds [Console] -> Properties is pushed onto
    the focused leaf.  Result: a left leaf and two stacked right leaves (3
    leaves total, 4 tabs).
    """
    # Root leaf starts with Explorer.
    var root_tabs = List[DockTab]()
    root_tabs.append(DockTab(TAB_EXPLORER, String("Explorer")))
    var state = DockState(root_tabs^)

    # Split the root to the right (60% to the left/original) with Editor.
    var editor_tabs = List[DockTab]()
    editor_tabs.append(DockTab(TAB_EDITOR, String("Editor")))
    var right = state.main.split_right(node_root(), 0.6, editor_tabs^)
    var right_leaf = right[1]  # (parent_index, new_leaf_index)

    # Split the new right leaf below (70% to the top Editor) with Console.
    var console_tabs = List[DockTab]()
    console_tabs.append(DockTab(TAB_CONSOLE, String("Console")))
    _ = state.main.split_below(right_leaf, 0.7, console_tabs^)

    # Properties rides along on the focused leaf (an extra tab in some leaf).
    state.push_to_focused_leaf(DockTab(TAB_PROPERTIES, String("Properties")))

    return state^


fn main() raises:
    print("DOCK DEMO — egui_dock MojoGUI port")
    print("=" * 50)
    print("4 tabs across 3 docked leaves; drag tabs, drag splitters.")
    print("")

    # --- Build the dock state + area ---------------------------------------
    var state = build_demo_state()
    var area = create_dock_area_int(DOCK_X, DOCK_Y, DOCK_W, DOCK_H)
    area.set_state(state^)
    area.set_style(DockStyle.dark())

    # --- Open the window (high-level Int32 rendering context) --------------
    var ctx = RenderingContextInt(String("./c_src/librendering_with_fonts.so"))

    if not ctx.initialize(WINDOW_WIDTH, WINDOW_HEIGHT, String("MojoGUI Dock Demo")):
        print("Failed to initialize window")
        return

    print("Window opened!")
    _ = ctx.load_default_font()
    print("Font loaded")
    print("")
    print("Controls:")
    print("  - Click a tab to activate it")
    print("  - Drag a tab onto a leaf edge/center to move or split")
    print("  - Drag a splitter to resize")
    print("  - Close window to exit")

    # Edge-detect for the left mouse button (node_graph_demo latch pattern).
    var was_pressed: Bool = False
    var frame_count: Int32 = 0

    while True:
        _ = ctx.poll_events()

        if ctx.should_close_window():
            break

        # --- Input: forward mouse to the dock (press + release edges) -------
        var mx = ctx.get_mouse_x()
        var my = ctx.get_mouse_y()
        var pressed = ctx.get_mouse_button_state(GLFW_MOUSE_BUTTON_LEFT)

        if pressed != was_pressed:
            # Send a discrete press/release event on each transition.
            _ = area.handle_mouse_event(
                MouseEventInt(mx, my, GLFW_MOUSE_BUTTON_LEFT, pressed))

        # Feed the continuous pointer position EVERY frame: this is what drives
        # the splitter drag, the drop-target tracking, and the press->drag
        # promotion inside the dock (handle_mouse_event only sees press/release).
        area.on_mouse_move(mx, my)

        was_pressed = pressed

        # Recompute node rects after any input that changed the layout.
        area.layout()

        # --- Render ---------------------------------------------------------
        _ = ctx.frame_begin()

        # Window background.
        _ = ctx.set_color(18, 18, 18, 255)
        _ = ctx.draw_filled_rectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

        # HOST content pass FIRST: fill each visible leaf body + active tab
        # title, then let the dock paint its chrome on top (tab strips,
        # splitters, drag preview) so the strips aren't overdrawn.
        var n = area.leaf_count()
        for i in range(n):
            var body = area.leaf_body_rect(i)
            var active_id = area.leaf_active_tab_id(i)

            var col = leaf_body_color(i)
            _ = ctx.set_color(col.r, col.g, col.b, col.a)
            _ = ctx.draw_filled_rectangle(body.x, body.y, body.width, body.height)

            # Active tab title, drawn into the body.
            _ = ctx.set_color(235, 235, 240, 255)
            var title = tab_title_for(active_id)
            _ = ctx.draw_text(title + String(" content"),
                              body.x + 12, body.y + 12, 14)

        # Dock chrome on top of the host content: tab strips, splitters,
        # active highlight, and the drag/drop preview overlay.
        area.render(ctx)

        # Header strip + instructions (drawn last, on top).
        _ = ctx.set_color(0, 0, 0, 180)
        _ = ctx.draw_filled_rectangle(0, 0, WINDOW_WIDTH, HEADER_HEIGHT)
        _ = ctx.set_color(235, 235, 240, 255)
        _ = ctx.draw_text(
            String("Dock Demo  |  drag tabs to dock/split  |  drag splitters to resize"),
            10, 10, 14)

        _ = ctx.frame_end()
        frame_count += 1

    _ = ctx.cleanup()
    print("")
    print("Demo finished!")
