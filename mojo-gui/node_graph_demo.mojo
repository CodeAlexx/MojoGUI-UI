"""
NODE GRAPH DEMO
Visual node editor demonstration with draggable nodes and connections
Colors normalized to 0.0-1.0 range for OpenGL glColor4f
"""

from sys.ffi import OwnedDLHandle as DLHandle
from memory import alloc, UnsafePointer
from builtin.type_aliases import MutExternalOrigin

comptime WINDOW_WIDTH: Int32 = 1000
comptime WINDOW_HEIGHT: Int32 = 700

# GLFW constants
comptime GLFW_MOUSE_BUTTON_LEFT: Int32 = 0
comptime GLFW_RELEASE: Int32 = 0
comptime GLFW_PRESS: Int32 = 1

fn null_terminated_string(text: String) -> UnsafePointer[Int8, MutExternalOrigin]:
    var bytes = text.as_bytes()
    var buffer = alloc[Int8](len(bytes) + 1)
    for i in range(len(bytes)):
        buffer[i] = Int8(bytes[i])
    buffer[len(bytes)] = 0
    return buffer

fn draw_node(lib: DLHandle, x: Float32, y: Float32, width: Float32, height: Float32,
             title: String, color_r: Float32, color_g: Float32, color_b: Float32,
             selected: Bool, inputs: Int32, outputs: Int32):
    """Draw a single node. Colors are already normalized 0.0-1.0"""
    var set_color = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8, MutExternalOrigin], Float32, Float32, Float32) -> Int32]("draw_text")
    var draw_filled_circle = lib.get_function[fn(Float32, Float32, Float32, Int32) -> Int32]("draw_filled_circle")

    # Node shadow (black with low alpha)
    _ = set_color(0.0, 0.0, 0.0, 0.24)
    _ = draw_filled_rectangle(x + 3.0, y + 3.0, width, height)

    # Node background (dark gray: 45, 50, 60)
    _ = set_color(0.176, 0.196, 0.235, 1.0)
    _ = draw_filled_rectangle(x, y, width, height)

    # Node header (passed color, already normalized)
    _ = set_color(color_r, color_g, color_b, 1.0)
    _ = draw_filled_rectangle(x, y, width, 28.0)

    # Selection border
    if selected:
        _ = set_color(0.39, 0.71, 1.0, 1.0)  # Light blue
    else:
        _ = set_color(0.275, 0.294, 0.333, 1.0)  # Dark gray border
    _ = draw_rectangle(x, y, width, height)

    # Title (white)
    _ = set_color(1.0, 1.0, 1.0, 1.0)
    var title_ptr = null_terminated_string(title)
    _ = draw_text(title_ptr, x + 10.0, y + 6.0, 12.0)

    # Input ports (green)
    _ = set_color(0.39, 0.78, 0.39, 1.0)
    var port_y = y + 40.0
    for i in range(inputs):
        _ = draw_filled_circle(x, port_y + Float32(i) * 22.0, 6.0, 16)
        var label = null_terminated_string("In " + String(i + 1))
        _ = set_color(0.78, 0.78, 0.82, 1.0)  # Light gray text
        _ = draw_text(label, x + 12.0, port_y + Float32(i) * 22.0 - 6.0, 10.0)
        _ = set_color(0.39, 0.78, 0.39, 1.0)  # Back to green

    # Output ports (red)
    _ = set_color(0.78, 0.39, 0.39, 1.0)
    port_y = y + 40.0
    for i in range(outputs):
        _ = draw_filled_circle(x + width, port_y + Float32(i) * 22.0, 6.0, 16)
        var label = null_terminated_string("Out " + String(i + 1))
        _ = set_color(0.78, 0.78, 0.82, 1.0)  # Light gray text
        _ = draw_text(label, x + width - 45.0, port_y + Float32(i) * 22.0 - 6.0, 10.0)
        _ = set_color(0.78, 0.39, 0.39, 1.0)  # Back to red

fn draw_connection(lib: DLHandle, x1: Float32, y1: Float32, x2: Float32, y2: Float32):
    """Draw a bezier-like connection between ports."""
    var set_color = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("set_color")
    var draw_line = lib.get_function[fn(Float32, Float32, Float32, Float32, Float32) -> Int32]("draw_line")

    # Light blue connection line
    _ = set_color(0.59, 0.78, 1.0, 0.78)

    # Simple bezier approximation
    var dx = (x2 - x1) / 2.0
    if dx < 50.0:
        dx = 50.0

    var segments: Int32 = 20
    var prev_x = x1
    var prev_y = y1

    for i in range(1, Int(segments) + 1):
        var t = Float32(i) * 100.0 / Float32(segments)
        var mt = 100.0 - t

        # Quadratic bezier
        var cx = x1 + dx
        var bx = (mt * mt * x1 + 2.0 * mt * t * cx + t * t * x2) / 10000.0
        var by = (mt * mt * y1 + 2.0 * mt * t * ((y1 + y2) / 2.0) + t * t * y2) / 10000.0

        _ = draw_line(prev_x, prev_y, bx, by, 2.0)
        prev_x = bx
        prev_y = by

fn draw_grid(lib: DLHandle, width: Float32, height: Float32):
    """Draw background grid."""
    var set_color = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("set_color")
    var draw_line = lib.get_function[fn(Float32, Float32, Float32, Float32, Float32) -> Int32]("draw_line")

    # Grid lines (dark gray)
    _ = set_color(0.157, 0.176, 0.216, 1.0)

    var grid_size: Float32 = 30.0
    var x: Float32 = 0.0
    while x < width:
        _ = draw_line(x, 0.0, x, height, 1.0)
        x += grid_size

    var y: Float32 = 0.0
    while y < height:
        _ = draw_line(0.0, y, width, y, 1.0)
        y += grid_size

fn main() raises:
    print("NODE GRAPH DEMO")
    print("=" * 50)
    print("Visual node editor with draggable nodes")
    print("")

    var lib = DLHandle("./c_src/librendering_with_fonts.so")
    print("Graphics library loaded")

    var initialize_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8, MutExternalOrigin]) -> Int32]("initialize_gl_context")
    var cleanup_gl = lib.get_function[fn() -> Int32]("cleanup_gl")
    var frame_begin = lib.get_function[fn() -> Int32]("frame_begin")
    var frame_end = lib.get_function[fn() -> Int32]("frame_end")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close = lib.get_function[fn() -> Int32]("should_close_window")
    var set_color = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("draw_filled_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8, MutExternalOrigin], Float32, Float32, Float32) -> Int32]("draw_text")
    var get_mouse_x = lib.get_function[fn() -> Int32]("get_mouse_x")
    var get_mouse_y = lib.get_function[fn() -> Int32]("get_mouse_y")
    var get_mouse_button = lib.get_function[fn(Int32) -> Int32]("get_mouse_button_state")
    var load_font = lib.get_function[fn() -> Int32]("load_default_font")

    var title = null_terminated_string("MojoGUI Node Graph Demo")
    var result = initialize_gl(WINDOW_WIDTH, WINDOW_HEIGHT, title)

    if result != 0:
        print("Failed to initialize window")
        return

    print("Window opened!")
    _ = load_font()
    print("Font loaded")
    print("")
    print("Controls:")
    print("  - Drag nodes with mouse")
    print("  - Close window to exit")

    # Node positions (mutable)
    var node1_x: Float32 = 100.0
    var node1_y: Float32 = 150.0
    var node2_x: Float32 = 400.0
    var node2_y: Float32 = 100.0
    var node3_x: Float32 = 400.0
    var node3_y: Float32 = 350.0
    var node4_x: Float32 = 700.0
    var node4_y: Float32 = 220.0

    # Node dimensions
    var node_w: Float32 = 160.0
    var node_h: Float32 = 100.0

    # Drag state
    var dragging: Int32 = -1
    var drag_offset_x: Float32 = 0.0
    var drag_offset_y: Float32 = 0.0
    var was_pressed: Bool = False

    var frame_count: Int32 = 0

    while True:
        _ = poll_events()

        if should_close() == 1:
            break

        var mouse_x = get_mouse_x()
        var mouse_y = get_mouse_y()
        var mouse_pressed = get_mouse_button(GLFW_MOUSE_BUTTON_LEFT) == 1

        # Handle dragging
        if mouse_pressed and not was_pressed:
            # Check which node was clicked
            var mx = Float32(mouse_x)
            var my = Float32(mouse_y)

            if mx >= node1_x and mx <= node1_x + node_w and my >= node1_y and my <= node1_y + node_h:
                dragging = 0
                drag_offset_x = mx - node1_x
                drag_offset_y = my - node1_y
            elif mx >= node2_x and mx <= node2_x + node_w and my >= node2_y and my <= node2_y + node_h:
                dragging = 1
                drag_offset_x = mx - node2_x
                drag_offset_y = my - node2_y
            elif mx >= node3_x and mx <= node3_x + node_w and my >= node3_y and my <= node3_y + node_h:
                dragging = 2
                drag_offset_x = mx - node3_x
                drag_offset_y = my - node3_y
            elif mx >= node4_x and mx <= node4_x + node_w and my >= node4_y and my <= node4_y + node_h:
                dragging = 3
                drag_offset_x = mx - node4_x
                drag_offset_y = my - node4_y

        if not mouse_pressed:
            dragging = -1

        if dragging >= 0:
            var new_x = Float32(mouse_x) - drag_offset_x
            var new_y = Float32(mouse_y) - drag_offset_y
            if dragging == 0:
                node1_x = new_x
                node1_y = new_y
            elif dragging == 1:
                node2_x = new_x
                node2_y = new_y
            elif dragging == 2:
                node3_x = new_x
                node3_y = new_y
            elif dragging == 3:
                node4_x = new_x
                node4_y = new_y

        was_pressed = mouse_pressed

        # Render
        _ = frame_begin()

        # Clear background (dark blue-gray: 30, 35, 45)
        _ = set_color(0.118, 0.137, 0.176, 1.0)
        _ = draw_filled_rectangle(0.0, 0.0, Float32(WINDOW_WIDTH), Float32(WINDOW_HEIGHT))

        # Draw grid
        draw_grid(lib, Float32(WINDOW_WIDTH), Float32(WINDOW_HEIGHT))

        # Draw connections (before nodes so they appear behind)
        # Node1 out1 -> Node2 in1
        draw_connection(lib, node1_x + node_w, node1_y + 62.0, node2_x, node2_y + 62.0)
        # Node1 out2 -> Node3 in1
        draw_connection(lib, node1_x + node_w, node1_y + 84.0, node3_x, node3_y + 62.0)
        # Node2 out1 -> Node4 in1
        draw_connection(lib, node2_x + node_w, node2_y + 62.0, node4_x, node4_y + 62.0)
        # Node3 out1 -> Node4 in2
        draw_connection(lib, node3_x + node_w, node3_y + 62.0, node4_x, node4_y + 84.0)

        # Draw nodes (colors normalized: purple, blue, orange, green headers)
        draw_node(lib, node1_x, node1_y, node_w, node_h, "Input Source", 0.43, 0.27, 0.55, dragging == 0, 0, 2)
        draw_node(lib, node2_x, node2_y, node_w, node_h, "Transform A", 0.27, 0.43, 0.55, dragging == 1, 1, 1)
        draw_node(lib, node3_x, node3_y, node_w, node_h, "Transform B", 0.55, 0.35, 0.20, dragging == 2, 1, 1)
        draw_node(lib, node4_x, node4_y, node_w, 120.0, "Output Merge", 0.27, 0.55, 0.35, dragging == 3, 2, 1)

        # Draw title bar (semi-transparent)
        _ = set_color(0.0, 0.0, 0.0, 0.5)
        _ = draw_filled_rectangle(0.0, 0.0, Float32(WINDOW_WIDTH), 30.0)

        # Draw title text
        _ = set_color(1.0, 1.0, 1.0, 1.0)
        var info_text = null_terminated_string("Node Graph Demo - Drag nodes to move them")
        _ = draw_text(info_text, 10.0, 8.0, 12.0)

        # Frame counter
        _ = set_color(0.7, 0.7, 0.7, 1.0)
        var frame_text = null_terminated_string("Frame: " + String(frame_count))
        _ = draw_text(frame_text, 900.0, 8.0, 10.0)

        _ = frame_end()
        frame_count += 1

    _ = cleanup_gl()
    print("")
    print("Demo finished!")
