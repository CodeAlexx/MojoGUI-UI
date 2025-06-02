#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("🖼️  Opening GUI Window Test")
    
    # Load the integer-only library
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
    
    print("✅ Functions loaded")
    
    # Initialize window
    var title = String("Mojo GUI Test Window")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    print("🚀 Creating window...")
    var init_result = initialize_gl(800, 600, title_ptr)
    
    if init_result != 0:
        print("❌ Failed to create window:", init_result)
        print("   Make sure you have a display available")
        return
    
    print("✅ GUI window created!")
    
    # Load font
    var font_result = load_default_font()
    if font_result == 0:
        print("✅ Font loaded")
    else:
        print("⚠️  Font loading failed")
    
    print("🎮 GUI is running! Move mouse and click to test.")
    print("   Close the window to exit.")
    
    # Main GUI loop
    var frame_count: Int32 = 0
    var button_clicks: Int32 = 0
    var last_mouse_state: Int32 = 0
    
    # Button area
    var button_x: Int32 = 300
    var button_y: Int32 = 250
    var button_w: Int32 = 200
    var button_h: Int32 = 80
    
    while should_close_window() == 0:
        # Poll events
        _ = poll_events()
        
        # Get mouse state
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
            print("❌ Frame begin failed")
            break
        
        # Clear background (dark blue)
        _ = set_color(30, 40, 80, 255)
        _ = draw_filled_rectangle(0, 0, 800, 600)
        
        # Draw title
        _ = set_color(255, 255, 255, 255)
        var title_text = String("Mojo Integer-Only GUI Test")
        var title_text_bytes = title_text.as_bytes()
        var title_text_ptr = title_text_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(title_text_ptr, 50, 50, 24)
        
        # Draw instructions
        _ = set_color(180, 255, 180, 255)
        var instr1 = String("Move mouse around and click the button!")
        var instr1_bytes = instr1.as_bytes()
        var instr1_ptr = instr1_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(instr1_ptr, 50, 100, 16)
        
        # Draw button with hover effect
        var mouse_over = (mouse_x >= button_x and mouse_x <= button_x + button_w and
                         mouse_y >= button_y and mouse_y <= button_y + button_h)
        
        var button_color: Int32 = 180
        if mouse_pressed == 1 and mouse_over:
            button_color = 120  # Dark when pressed
        elif mouse_over:
            button_color = 220  # Light when hovering
        
        _ = set_color(button_color, button_color, button_color, 255)
        _ = draw_filled_rectangle(button_x, button_y, button_w, button_h)
        
        # Button border
        _ = set_color(100, 100, 100, 255)
        _ = draw_rectangle(button_x, button_y, button_w, button_h)
        
        # Button text
        _ = set_color(0, 0, 0, 255)
        var btn_text = String("CLICK ME!")
        var btn_text_bytes = btn_text.as_bytes()
        var btn_text_ptr = btn_text_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(btn_text_ptr, button_x + 50, button_y + 30, 20)
        
        # Draw mouse position
        _ = set_color(100, 255, 255, 255)
        var mouse_text = String("Mouse: " + str(mouse_x) + ", " + str(mouse_y))
        var mouse_text_bytes = mouse_text.as_bytes()
        var mouse_text_ptr = mouse_text_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(mouse_text_ptr, 50, 400, 14)
        
        # Draw click counter
        _ = set_color(255, 255, 100, 255)
        var click_text = String("Button Clicks: " + str(button_clicks))
        var click_text_bytes = click_text.as_bytes()
        var click_text_ptr = click_text_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(click_text_ptr, 50, 430, 14)
        
        # Draw mouse cursor (red dot)
        _ = set_color(255, 100, 100, 255)
        _ = draw_filled_circle(mouse_x, mouse_y, 8, 8)
        
        # End frame and display
        if frame_end() != 0:
            print("❌ Frame end failed")
            break
        
        frame_count += 1
        
        # Status update every 3 seconds
        if frame_count % 180 == 0:
            print("📊 Running... Frame:", frame_count, "Clicks:", button_clicks)
    
    print("🏁 GUI window closed")
    print("📊 Total frames:", frame_count, "Total clicks:", button_clicks)
    
    # Cleanup
    var cleanup_result = cleanup_gl()
    if cleanup_result == 0:
        print("✅ Cleanup successful")
    else:
        print("⚠️  Cleanup warning")
    
    print("🎉 GUI test completed!")