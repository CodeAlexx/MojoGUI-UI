#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("🧪 Mojo Test - Python Style (Float-based)")
    
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
    var draw_line = lib.get_function[fn(Float32, Float32, Float32, Float32, Float32) -> Int32]("draw_line")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Float32, Float32, Float32) -> Int32]("draw_text")
    var load_default_font = lib.get_function[fn() -> Int32]("load_default_font")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close_window = lib.get_function[fn() -> Int32]("should_close_window")
    
    # Initialize window (same as Python)
    var title = String("Mojo Float-based Test")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    print("🚀 Opening window...")
    var init_result = initialize_gl(700, 500, title_ptr)
    
    if init_result != 0:
        print("❌ Failed to initialize:", init_result)
        return
    
    print("✅ Window opened!")
    
    # Load font
    var font_result = load_default_font()
    if font_result != 0:
        print("⚠️  Font loading failed")
    else:
        print("✅ Font loaded")
    
    print("🎮 Starting render loop (same as Python)...")
    
    # Render loop (exactly like Python)
    var frame_count: Int32 = 0
    
    while frame_count < 180:  # 3 seconds
        # Poll events
        _ = poll_events()
        
        # Check for close
        if should_close_window() != 0:
            print("🚪 Window close requested")
            break
        
        # Begin frame
        if frame_begin() != 0:
            print("❌ Frame begin failed")
            break
        
        # Clear background (dark green - same as Python)
        _ = set_color(0.1, 0.3, 0.1, 1.0)
        _ = draw_filled_rectangle(0.0, 0.0, 700.0, 500.0)
        
        # Moving red rectangle (same as Python)
        var time_factor = Float32(frame_count) * 0.05
        var x = 50.0 + 100.0 * (0.5 + 0.5 * time_factor)
        _ = set_color(1.0, 0.2, 0.2, 1.0)
        _ = draw_filled_rectangle(x, 100.0, 80.0, 50.0)
        
        # Pulsing blue circle (same as Python)
        var radius = 20.0 + 15.0 * time_factor
        _ = set_color(0.2, 0.2, 1.0, 1.0)
        _ = draw_filled_circle(350.0, 200.0, radius, 16)
        
        # Static yellow border (same as Python)
        _ = set_color(1.0, 1.0, 0.2, 1.0)
        _ = draw_rectangle(450.0, 150.0, 200.0, 100.0)
        
        # Dynamic white line (same as Python)
        var x2 = 600.0 + 50.0 * time_factor
        _ = set_color(1.0, 1.0, 1.0, 1.0)
        _ = draw_line(50.0, 300.0, x2, 300.0, 2.0)
        
        # Text (same as Python)
        _ = set_color(1.0, 1.0, 1.0, 1.0)
        var text = String("Mojo -> C FFI Working!")
        var text_bytes = text.as_bytes()
        var text_ptr = text_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text_ptr, 50.0, 350.0, 18.0)
        
        # End frame
        if frame_end() != 0:
            print("❌ Frame end failed")
            break
        
        frame_count += 1
        
        if frame_count % 60 == 0:
            print("📊 Mojo Frame", frame_count)
    
    print("🏁 Render loop completed:", frame_count, "frames")
    
    # Cleanup
    var cleanup_result = cleanup_gl()
    if cleanup_result != 0:
        print("⚠️  Cleanup warning")
    else:
        print("✅ Cleanup successful")
    
    print("🎉 Mojo float-based test completed!")