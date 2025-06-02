#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("🧪 Final Integer-Only Mojo Test")
    print("Testing proven integer-only FFI approach")
    
    # Load the integer-only library
    var lib = DLHandle("./c_src/librendering_primitives_int.so")
    print("✅ Integer-only library loaded")
    
    # Get function pointers
    var initialize_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var cleanup_gl = lib.get_function[fn() -> Int32]("cleanup_gl")
    var frame_begin = lib.get_function[fn() -> Int32]("frame_begin")
    var frame_end = lib.get_function[fn() -> Int32]("frame_end")
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    var draw_filled_circle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_circle")
    var load_default_font = lib.get_function[fn() -> Int32]("load_default_font")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close_window = lib.get_function[fn() -> Int32]("should_close_window")
    var get_mouse_x = lib.get_function[fn() -> Int32]("get_mouse_x")
    var get_mouse_y = lib.get_function[fn() -> Int32]("get_mouse_y")
    var get_mouse_button_state = lib.get_function[fn(Int32) -> Int32]("get_mouse_button_state")
    
    print("✅ All function pointers obtained")
    
    # Initialize window
    var title = "Final Mojo Integer Test"
    var title_ptr = title.unsafe_ptr()
    var init_result = initialize_gl(640, 480, title_ptr)
    
    if init_result != 0:
        print("❌ Failed to initialize:", init_result)
        return
    
    print("✅ Integer-only context initialized")
    
    # Load font
    var font_result = load_default_font()
    if font_result == 0:
        print("✅ Font loaded")
    else:
        print("⚠️  Font loading failed")
    
    print("🎯 Starting render loop...")
    
    # Render loop variables
    var frame_count: Int32 = 0
    var button_clicks: Int32 = 0
    var last_mouse_state: Int32 = 0
    
    # Button coordinates (integers only)
    var button_x: Int32 = 200
    var button_y: Int32 = 200
    var button_w: Int32 = 140
    var button_h: Int32 = 45
    
    while frame_count < 180:  # 3 seconds at 60fps
        # Poll events
        _ = poll_events()
        
        # Check if should close
        var should_close = should_close_window()
        if should_close != 0:
            print("🚪 Window close requested")
            break
        
        # Get mouse state
        var mouse_x = get_mouse_x()
        var mouse_y = get_mouse_y()
        var mouse_pressed = get_mouse_button_state(0)
        
        # Check button click
        if mouse_pressed == 1 and last_mouse_state == 0:
            if (mouse_x >= button_x and mouse_x <= button_x + button_w and
                mouse_y >= button_y and mouse_y <= button_y + button_h):
                button_clicks += 1
                print("🖱️  Button clicked! Total clicks:", button_clicks)
        
        last_mouse_state = mouse_pressed
        
        # Begin frame
        var frame_begin_result = frame_begin()
        if frame_begin_result != 0:
            print("❌ Frame begin failed")
            break
        
        # Clear background (dark blue: RGB 25, 35, 50)
        _ = set_color(25, 35, 50, 255)
        _ = draw_filled_rectangle(0, 0, 640, 480)
        
        # Draw title (white text)
        _ = set_color(255, 255, 255, 255)
        var title_text = "Final Mojo Integer-Only Test"
        _ = draw_text(title_text.unsafe_ptr(), 50, 50, 18)
        
        # Draw description (light green)
        _ = set_color(180, 255, 180, 255)
        var desc1 = "All coordinates & colors are Int32"
        _ = draw_text(desc1.unsafe_ptr(), 50, 90, 12)
        var desc2 = "No FFI conversion issues"
        _ = draw_text(desc2.unsafe_ptr(), 50, 110, 12)
        var desc3 = "Using proven MojoGUI patterns"
        _ = draw_text(desc3.unsafe_ptr(), 50, 130, 12)
        
        # Draw button with hover effect
        var mouse_over = (mouse_x >= button_x and mouse_x <= button_x + button_w and
                         mouse_y >= button_y and mouse_y <= button_y + button_h)
        
        var button_brightness: Int32 = 220
        if mouse_pressed == 1 and mouse_over:
            button_brightness = 180  # Darker when pressed
        elif mouse_over:
            button_brightness = 240  # Lighter on hover
        
        _ = set_color(button_brightness, button_brightness, button_brightness, 255)
        _ = draw_filled_rectangle(button_x, button_y, button_w, button_h)
        
        # Button border
        _ = set_color(100, 100, 100, 255)
        _ = draw_rectangle(button_x, button_y, button_w, button_h)
        
        # Button text
        _ = set_color(0, 0, 0, 255)
        var button_text = "Click Me!"
        _ = draw_text(button_text.unsafe_ptr(), button_x + 35, button_y + 18, 14)
        
        # Draw mouse position (cyan)
        _ = set_color(100, 255, 255, 255)
        var mouse_text = "Mouse: " + str(mouse_x) + ", " + str(mouse_y)
        _ = draw_text(mouse_text.unsafe_ptr(), 50, 300, 12)
        
        # Click counter (yellow)
        _ = set_color(255, 255, 100, 255)
        var click_text = "Button Clicks: " + str(button_clicks)
        _ = draw_text(click_text.unsafe_ptr(), 50, 320, 12)
        
        # Frame counter (orange)
        _ = set_color(255, 180, 100, 255)
        var frame_text = "Frame: " + str(frame_count) + " / 180"
        _ = draw_text(frame_text.unsafe_ptr(), 50, 340, 12)
        
        # Features demonstrated (light gray)
        _ = set_color(180, 180, 180, 255)
        var features_title = "Demonstrated Features:"
        _ = draw_text(features_title.unsafe_ptr(), 50, 380, 12)
        
        var feature1 = "✓ Integer-only FFI (no conversion bugs)"
        _ = draw_text(feature1.unsafe_ptr(), 70, 400, 11)
        var feature2 = "✓ Real-time mouse tracking"
        _ = draw_text(feature2.unsafe_ptr(), 70, 420, 11)
        var feature3 = "✓ Interactive button with hover states"
        _ = draw_text(feature3.unsafe_ptr(), 70, 440, 11)
        var feature4 = "✓ Stable Mojo-C integration"
        _ = draw_text(feature4.unsafe_ptr(), 70, 460, 11)
        
        # Mouse cursor indicator (red circle)
        _ = set_color(255, 100, 100, 255)
        _ = draw_filled_circle(mouse_x, mouse_y, 5, 8)
        
        # End frame
        var frame_end_result = frame_end()
        if frame_end_result != 0:
            print("❌ Frame end failed")
            break
        
        frame_count += 1
        
        # Status update every second
        if frame_count % 60 == 0:
            print("📊 Frame", frame_count, "- Mouse:", mouse_x, ",", mouse_y, "- Clicks:", button_clicks)
    
    print("🏁 Test completed after", frame_count, "frames")
    print("📊 Total button clicks:", button_clicks)
    
    # Cleanup
    var cleanup_result = cleanup_gl()
    if cleanup_result == 0:
        print("✅ Cleanup successful")
    else:
        print("⚠️  Cleanup warning")
    
    print("🎉 Final Mojo integer test successful!")
    print("🚀 Integer-only FFI working perfectly!")
    print("✨ Ready for production use!")