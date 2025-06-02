#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("📷 Mojo GUI Screenshot Test")
    
    # Load the FLOAT-based library (same as Python)
    var lib = DLHandle("./c_src/librendering_primitives.so")
    print("✅ Float-based library loaded")
    
    # Get functions with FLOAT parameters (like Python)
    var initialize_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var cleanup_gl = lib.get_function[fn() -> Int32]("cleanup_gl")
    var frame_begin = lib.get_function[fn() -> Int32]("frame_begin")
    var frame_end = lib.get_function[fn() -> Int32]("frame_end")
    var set_color = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("draw_rectangle")
    var draw_filled_circle = lib.get_function[fn(Float32, Float32, Float32, Int32) -> Int32]("draw_filled_circle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Float32, Float32, Float32) -> Int32]("draw_text")
    var load_default_font = lib.get_function[fn() -> Int32]("load_default_font")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close_window = lib.get_function[fn() -> Int32]("should_close_window")
    
    # Initialize window
    var title = String("Mojo Screenshot Test - Check for Text")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    print("🚀 Opening window for 10 seconds...")
    var init_result = initialize_gl(800, 600, title_ptr)
    
    if init_result != 0:
        print("❌ Failed to initialize:", init_result)
        return
    
    print("✅ Window opened!")
    
    # Load font
    var font_result = load_default_font()
    if font_result != 0:
        print("⚠️  Font loading failed - this explains missing text!")
    else:
        print("✅ Font loaded successfully")
    
    print("📷 GUI will run for 10 seconds - take screenshot now!")
    print("   Look for:")
    print("   - Green background")
    print("   - Moving red rectangle")
    print("   - Blue pulsing circle")
    print("   - Yellow rectangle border")
    print("   - White text (if font works)")
    
    # Extended render loop for screenshot
    var frame_count: Int32 = 0
    
    while frame_count < 600 and should_close_window() == 0:  # 10 seconds at 60fps
        # Poll events
        _ = poll_events()
        
        # Begin frame
        if frame_begin() != 0:
            print("❌ Frame begin failed")
            break
        
        # Clear background (dark green - should be very visible)
        _ = set_color(0.1, 0.4, 0.1, 1.0)
        _ = draw_filled_rectangle(0.0, 0.0, 800.0, 600.0)
        
        # Moving red rectangle (should be visible)
        var time_factor = Float32(frame_count) * 0.02
        var x = 50.0 + 200.0 * time_factor
        if x > 700.0:
            x = 50.0
        _ = set_color(1.0, 0.2, 0.2, 1.0)
        _ = draw_filled_rectangle(x, 100.0, 80.0, 50.0)
        
        # Large pulsing blue circle (should be visible)
        var radius = 30.0 + 20.0 * time_factor
        if radius > 80.0:
            radius = 30.0
        _ = set_color(0.2, 0.2, 1.0, 1.0)
        _ = draw_filled_circle(400.0, 300.0, radius, 16)
        
        # Large yellow border (should be visible)
        _ = set_color(1.0, 1.0, 0.2, 1.0)
        _ = draw_rectangle(100.0, 400.0, 300.0, 100.0)
        
        # BIG WHITE TEXT (this is the test)
        _ = set_color(1.0, 1.0, 1.0, 1.0)
        var text1 = String("BIG TEXT TEST")
        var text1_bytes = text1.as_bytes()
        var text1_ptr = text1_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text1_ptr, 50.0, 50.0, 32.0)
        
        var text2 = String("Can you see this text?")
        var text2_bytes = text2.as_bytes()
        var text2_ptr = text2_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text2_ptr, 50.0, 200.0, 24.0)
        
        var text3 = String("Font status: loaded successfully")
        var text3_bytes = text3.as_bytes()
        var text3_ptr = text3_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text3_ptr, 50.0, 250.0, 18.0)
        
        # End frame
        if frame_end() != 0:
            print("❌ Frame end failed")
            break
        
        frame_count += 1
        
        # Progress updates
        if frame_count % 60 == 0:
            var seconds = frame_count / 60
            print("📊 Running... Second", seconds, "of 10")
    
    print("🏁 Screenshot test completed:", frame_count, "frames")
    
    # Cleanup
    _ = cleanup_gl()
    print("✅ Test complete - did you see the text in the window?")