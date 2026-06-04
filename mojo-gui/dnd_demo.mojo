"""
DND DEMO — egui_dnd MojoGUI port (phase 1, drag-to-reorder list)

Builds a `DndListInt` filling most of the window, adds 6 labeled items, and runs
a node_graph_demo-style window loop.  Drag a row up/down to reorder the list; the
header shows the live order (via order()/item_label) and the last move from
`last_response()` ("moved X -> Y").

Return/swap animations are DEFERRED in phase 1 — the reorder is instant on drop
(see DND_PORT_SPEC.md "Done").

Build (compile-only check from repo root; do NOT open the window here):
    pixi run mojo build mojo-gui/dnd_demo.mojo -o /tmp/dnd_demo_check

Input pattern mirrors dock_demo.mojo: a discrete press/release goes through
`handle_mouse_event` on each button transition, and `on_mouse_move(mx, my)` is
fed EVERY frame so an in-progress drag tracks the cursor.

IMPORT-TODO bug-fixer: `DndListInt` + free fns live in dnd/dnd.mojo (owned by
builder-engine) and may not be finalized.  This demo codes to the DND_PORT_SPEC
API (create_dnd_list_int / add_item / handle_mouse_event / on_mouse_move / draw /
update / item_count / item_id / item_label / order / last_response).  Reconcile
names/signatures against the real dnd.mojo when integrating.
"""

from mojo_src.rendering_int import RenderingContextInt
from mojo_src.widget_int import MouseEventInt
from mojo_src.widgets.dnd.dnd import (
    DndListInt, create_dnd_list_int,  # IMPORT-TODO bug-fixer
)


comptime WINDOW_WIDTH: Int32 = 1000
comptime WINDOW_HEIGHT: Int32 = 700

# The list fills most of the window, below a header strip.
comptime HEADER_HEIGHT: Int32 = 56
comptime LIST_X: Int32 = 40
comptime LIST_Y: Int32 = HEADER_HEIGHT + 16
comptime LIST_W: Int32 = WINDOW_WIDTH - 80
comptime LIST_H: Int32 = WINDOW_HEIGHT - LIST_Y - 24

# GLFW left mouse button (matches the other demos).
comptime GLFW_MOUSE_BUTTON_LEFT: Int32 = 0


fn main() raises:
    print("DND DEMO — egui_dnd MojoGUI port")
    print("=" * 50)
    print("Drag a row to reorder the list; header shows the live order.")
    print("")

    # --- Build the drag-and-drop list ---------------------------------------
    var dnd = create_dnd_list_int(LIST_X, LIST_Y, LIST_W, LIST_H)  # IMPORT-TODO bug-fixer
    dnd.add_item(1, String("Apple"))        # IMPORT-TODO bug-fixer
    dnd.add_item(2, String("Banana"))
    dnd.add_item(3, String("Cherry"))
    dnd.add_item(4, String("Date"))
    dnd.add_item(5, String("Elderberry"))
    dnd.add_item(6, String("Fig"))

    # --- Open the window (high-level Int32 rendering context) --------------
    var ctx = RenderingContextInt(String("./c_src/librendering_with_fonts.so"))

    if not ctx.initialize(WINDOW_WIDTH, WINDOW_HEIGHT, String("MojoGUI DnD Demo")):
        print("Failed to initialize window")
        return

    print("Window opened!")
    _ = ctx.load_default_font()
    print("Font loaded")
    print("")
    print("Controls:")
    print("  - Press on a row and drag up/down to reorder")
    print("  - Release to drop")
    print("  - Close window to exit")

    # Edge-detect for the left mouse button (node_graph_demo latch pattern).
    var was_pressed: Bool = False
    var frame_count: Int32 = 0

    while True:
        _ = ctx.poll_events()

        if ctx.should_close_window():
            break

        var mx = ctx.get_mouse_x()
        var my = ctx.get_mouse_y()
        var pressed = ctx.get_mouse_button_state(GLFW_MOUSE_BUTTON_LEFT)

        # Discrete press/release on each transition (arms / commits a drag).
        if pressed != was_pressed:
            _ = dnd.handle_mouse_event(
                MouseEventInt(mx, my, GLFW_MOUSE_BUTTON_LEFT, pressed))  # IMPORT-TODO bug-fixer
        was_pressed = pressed

        # Feed the cursor every frame so an in-progress drag tracks it.
        dnd.on_mouse_move(mx, my)  # IMPORT-TODO bug-fixer
        dnd.update()               # IMPORT-TODO bug-fixer

        # --- Render ---------------------------------------------------------
        _ = ctx.frame_begin()

        # Window background.
        _ = ctx.set_color(22, 24, 30, 255)
        _ = ctx.draw_filled_rectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

        # The list draws its rows, the insertion gap, and the floating row.
        dnd.draw(ctx)  # IMPORT-TODO bug-fixer

        # --- Header: title + live order + last move -------------------------
        _ = ctx.set_color(0, 0, 0, 180)
        _ = ctx.draw_filled_rectangle(0, 0, WINDOW_WIDTH, HEADER_HEIGHT)
        _ = ctx.set_color(235, 235, 240, 255)
        _ = ctx.draw_text(String("DnD Demo  |  drag rows to reorder"), 10, 8, 14)

        # Live order: walk item_count()/item_label(i) and join with arrows.
        var order_text = String("Order: ")
        var n = dnd.item_count()  # IMPORT-TODO bug-fixer
        for i in range(n):
            if i > 0:
                order_text += String(" > ")
            order_text += dnd.item_label(i)  # IMPORT-TODO bug-fixer
        _ = ctx.set_color(150, 200, 150, 255)
        _ = ctx.draw_text(order_text, 10, 30, 12)

        # Last move from the response (from_ -> to), shown only after an update.
        var resp = dnd.last_response()  # IMPORT-TODO bug-fixer
        if resp.has_update:
            _ = ctx.set_color(200, 200, 140, 255)
            var move_text = String("moved ") + String(resp.from_) \
                + String(" -> ") + String(resp.to)
            _ = ctx.draw_text(move_text, 600, 30, 12)

        _ = ctx.frame_end()
        frame_count += 1

    _ = ctx.cleanup()
    print("")
    print("Demo finished!")
