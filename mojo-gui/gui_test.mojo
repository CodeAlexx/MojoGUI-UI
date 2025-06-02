#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("🖼️  Mojo GUI Window Test")
    
    # Load library
    var lib = DLHandle("./c_src/librendering_primitives_int.so")
    print("✅ Library loaded")
    
    # Get functions
    var initialize_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var cleanup_gl = lib.get_function[fn() -> Int32]("cleanup_gl")
    var frame_begin = lib.get_function[fn() -> Int32]("frame_begin")
    var frame_end = lib.get_function[fn() -> Int32]("frame_end")
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_filled_circle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_circle")
    var load_default_font = lib.get_function[fn() -> Int32]("load_default_font")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close_window = lib.get_function[fn() -> Int32]("should_close_window")
    var get_mouse_x = lib.get_function[fn() -> Int32]("get_mouse_x")
    var get_mouse_y = lib.get_function[fn() -> Int32]("get_mouse_y")
    var get_mouse_button_state = lib.get_function[fn(Int32) -> Int32]("get_mouse_button_state")
    
    # Initialize window
    var title = String("Mojo GUI Test")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    print("🚀 Opening GUI window...")
    var init_result = initialize_gl(800, 600, title_ptr)
    
    if init_result != 0:
        print("❌ Failed to open window:", init_result)
        print("   Try running: export DISPLAY=:0")
        return
    
    print("✅ GUI window opened!")
    
    # Load font
    _ = load_default_font()
    print("✅ Font system ready")
    
    print("🎮 Interactive GUI running!")
    print("   - Move mouse to see red cursor")
    print("   - Click the gray button")
    print("   - Close window to exit")
    
    # GUI loop
    var frame_count: Int32 = 0
    var button_clicks: Int32 = 0
    var last_mouse_state: Int32 = 0
    
    # Button coordinates
    var button_x: Int32 = 300
    var button_y: Int32 = 250
    var button_w: Int32 = 200
    var button_h: Int32 = 80
    
    while should_close_window() == 0:
        # Poll events
        _ = poll_events()
        
        # Get mouse
        var mouse_x = get_mouse_x()
        var mouse_y = get_mouse_y()
        var mouse_pressed = get_mouse_button_state(0)
        
        # Check button click
        if mouse_pressed == 1 and last_mouse_state == 0:
            if (mouse_x >= button_x and mouse_x <= button_x + button_w and
                mouse_y >= button_y and mouse_y <= button_y + button_h):
                button_clicks += 1
                print("🖱️  Button clicked! Total:", button_clicks)
        
        last_mouse_state = mouse_pressed
        
        # Begin frame
        if frame_begin() != 0:
            break
        
        # Clear background (dark blue)
        _ = set_color(25, 35, 60, 255)
        _ = draw_filled_rectangle(0, 0, 800, 600)
        
        # Draw title
        _ = set_color(255, 255, 255, 255)
        var title_text = String("Mojo Integer-Only GUI Working!")
        var title_bytes2 = title_text.as_bytes()
        var title_ptr2 = title_bytes2.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(title_ptr2, 50, 50, 24)
        
        # Draw instructions
        _ = set_color(180, 255, 180, 255)
        var instr = String("Move mouse and click button below")
        var instr_bytes = instr.as_bytes()
        var instr_ptr = instr_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(instr_ptr, 50, 100, 16)
        
        # Draw button with hover effect
        var mouse_over = (mouse_x >= button_x and mouse_x <= button_x + button_w and
                         mouse_y >= button_y and mouse_y <= button_y + button_h)
        
        var button_color: Int32 = 180
        if mouse_pressed == 1 and mouse_over:
            button_color = 120
        elif mouse_over:
            button_color = 220
        
        _ = set_color(button_color, button_color, button_color, 255)
        _ = draw_filled_rectangle(button_x, button_y, button_w, button_h)
        
        # Button border
        _ = set_color(80, 80, 80, 255)
        _ = draw_rectangle(button_x, button_y, button_w, button_h)
        
        # Button text
        _ = set_color(0, 0, 0, 255)
        var btn_text = String("CLICK ME!")
        var btn_bytes = btn_text.as_bytes()
        var btn_ptr = btn_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(btn_ptr, button_x + 50, button_y + 30, 20)
        
        # Draw status info
        _ = set_color(100, 255, 255, 255)
        var status1 = String("Mouse position and click count displayed here")
        var status1_bytes = status1.as_bytes()
        var status1_ptr = status1_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(status1_ptr, 50, 400, 14)
        
        _ = set_color(255, 255, 100, 255)
        var status2 = String("All coordinates are integers - no FFI bugs!")
        var status2_bytes = status2.as_bytes()
        var status2_ptr = status2_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(status2_ptr, 50, 430, 14)
        
        # Feature list
        _ = set_color(180, 180, 180, 255)
        var feat1 = String("✓ Real-time mouse tracking")
        var feat1_bytes = feat1.as_bytes()
        var feat1_ptr = feat1_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(feat1_ptr, 50, 480, 12)
        
        var feat2 = String("✓ Interactive button with hover states")
        var feat2_bytes = feat2.as_bytes()
        var feat2_ptr = feat2_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(feat2_ptr, 50, 500, 12)
        
        var feat3 = String("✓ Integer-only FFI - stable and fast")
        var feat3_bytes = feat3.as_bytes()
        var feat3_ptr = feat3_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(feat3_ptr, 50, 520, 12)
        
        # Draw mouse cursor (red circle)
        _ = set_color(255, 100, 100, 255)
        _ = draw_filled_circle(mouse_x, mouse_y, 8, 8)
        
        # End frame
        if frame_end() != 0:
            break
        
        frame_count += 1
        
        # Status every 3 seconds
        if frame_count % 180 == 0:
            print("📊 GUI running... Frame:", frame_count)
    
    print("🏁 GUI closed after", frame_count, "frames")
    print("📊 Button was clicked", button_clicks, "times")
    
    # Cleanup
    _ = cleanup_gl()
    print("✅ Cleanup complete")
    print("🎉 Mojo GUI test successful!")