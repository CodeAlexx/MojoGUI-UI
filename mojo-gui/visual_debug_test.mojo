#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("🔍 Visual Debug Test - What Should You See?")
    
    # Load library
    var lib = DLHandle("./c_src/librendering_primitives.so")
    print("✅ Library loaded")
    
    # Get functions
    var initialize_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var cleanup_gl = lib.get_function[fn() -> Int32]("cleanup_gl")
    var frame_begin = lib.get_function[fn() -> Int32]("frame_begin")
    var frame_end = lib.get_function[fn() -> Int32]("frame_end")
    var set_color = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("draw_filled_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Float32, Float32, Float32) -> Int32]("draw_text")
    var load_default_font = lib.get_function[fn() -> Int32]("load_default_font")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close_window = lib.get_function[fn() -> Int32]("should_close_window")
    
    # Initialize
    var title = String("Visual Debug - Look for Text as White Rectangles")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    print("🚀 Opening visual debug window...")
    var init_result = initialize_gl(800, 600, title_ptr)
    
    if init_result != 0:
        print("❌ Failed to initialize")
        return
    
    print("✅ Window opened!")
    print("🔍 WHAT YOU SHOULD SEE:")
    print("   1. Dark blue background")
    print("   2. Large red rectangle (top)")
    print("   3. Small white rectangles where text should be")
    print("   4. Text is rendered as WHITE RECTANGLES (placeholder)")
    print("   5. This proves the text function is called but shows rectangles instead of letters")
    
    # Load font
    _ = load_default_font()
    
    # Show for 8 seconds
    var frame_count: Int32 = 0
    
    while frame_count < 480 and should_close_window() == 0:  # 8 seconds
        _ = poll_events()
        
        if frame_begin() != 0:
            break
        
        # Dark blue background
        _ = set_color(0.1, 0.1, 0.3, 1.0)
        _ = draw_filled_rectangle(0.0, 0.0, 800.0, 600.0)
        
        # Large red rectangle to prove graphics work
        _ = set_color(1.0, 0.2, 0.2, 1.0)
        _ = draw_filled_rectangle(50.0, 50.0, 300.0, 100.0)
        
        # White color for "text" (will show as rectangles)
        _ = set_color(1.0, 1.0, 1.0, 1.0)
        
        # Try to draw text - should appear as WHITE RECTANGLES
        var text1 = String("HELLO WORLD")  # Should show as 11 white rectangles
        var text1_bytes = text1.as_bytes()
        var text1_ptr = text1_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text1_ptr, 50.0, 200.0, 24.0)
        
        var text2 = String("TEXT AS RECTANGLES")  # Should show as 18 white rectangles
        var text2_bytes = text2.as_bytes()
        var text2_ptr = text2_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text2_ptr, 50.0, 250.0, 20.0)
        
        var text3 = String("EACH LETTER = 1 WHITE BOX")  # Should show as 25 white rectangles
        var text3_bytes = text3.as_bytes()
        var text3_ptr = text3_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text3_ptr, 50.0, 300.0, 18.0)
        
        # Green rectangle to show more graphics work
        _ = set_color(0.2, 1.0, 0.2, 1.0)
        _ = draw_filled_rectangle(50.0, 400.0, 200.0, 80.0)
        
        # Yellow border
        _ = set_color(1.0, 1.0, 0.2, 1.0)
        _ = draw_filled_rectangle(300.0, 400.0, 5.0, 80.0)  # Left line
        _ = draw_filled_rectangle(300.0, 400.0, 200.0, 5.0)  # Top line
        _ = draw_filled_rectangle(495.0, 400.0, 5.0, 80.0)  # Right line
        _ = draw_filled_rectangle(300.0, 475.0, 200.0, 5.0)  # Bottom line
        
        if frame_end() != 0:
            break
        
        frame_count += 1
        
        if frame_count % 60 == 0:
            var seconds = frame_count / 60
            print("📊", seconds, "seconds - Do you see white rectangles where text should be?")
    
    _ = cleanup_gl()
    
    print("🔍 ANALYSIS:")
    print("   ✅ If you saw colored rectangles: Graphics work!")
    print("   ✅ If you saw white small rectangles: Text function is called!")
    print("   📝 The 'text' appears as white rectangles because:")
    print("      C function draw_text() is a placeholder")
    print("      It draws rectangles instead of actual letters")
    print("   🎯 This is why no readable text appears!")
    print("   💡 Solution: Either accept rectangle 'text' or implement real font rendering")