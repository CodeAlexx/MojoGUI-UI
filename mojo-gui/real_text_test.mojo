#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("📝 REAL Text Test - Using stb_truetype")
    
    # Load the NEW library with real font support
    var lib = DLHandle("./c_src/librendering_with_fonts.so")
    print("✅ Font-enabled library loaded")
    
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
    
    # Initialize window
    var title = String("REAL TEXT TEST")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    print("🚀 Opening window with REAL font support...")
    var init_result = initialize_gl(800, 600, title_ptr)
    
    if init_result != 0:
        print("❌ Failed to initialize")
        return
    
    print("✅ Window opened!")
    
    # Load REAL font
    var font_result = load_default_font()
    if font_result == 0:
        print("✅ REAL FONT LOADED! Text should appear as actual letters!")
    else:
        print("⚠️  Font loading failed - will show rectangles as fallback")
    
    print("📝 Running for 8 seconds - look for REAL TEXT!")
    
    # Test loop
    var frame_count: Int32 = 0
    
    while frame_count < 480 and should_close_window() == 0:  # 8 seconds
        _ = poll_events()
        
        if frame_begin() != 0:
            break
        
        # Dark background
        _ = set_color(0.05, 0.05, 0.2, 1.0)
        _ = draw_filled_rectangle(0.0, 0.0, 800.0, 600.0)
        
        # White text that should be READABLE
        _ = set_color(1.0, 1.0, 1.0, 1.0)
        
        var text1 = String("HELLO WORLD - REAL TEXT!")
        var text1_bytes = text1.as_bytes()
        var text1_ptr = text1_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text1_ptr, 50.0, 80.0, 32.0)
        
        var text2 = String("This should be readable letters, not rectangles")
        var text2_bytes = text2.as_bytes()
        var text2_ptr = text2_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text2_ptr, 50.0, 140.0, 18.0)
        
        var text3 = String("Using stb_truetype for real font rendering")
        var text3_bytes = text3.as_bytes()
        var text3_ptr = text3_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text3_ptr, 50.0, 180.0, 16.0)
        
        # Green text
        _ = set_color(0.2, 1.0, 0.2, 1.0)
        var text4 = String("SUCCESS: Real fonts working!")
        var text4_bytes = text4.as_bytes()
        var text4_ptr = text4_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text4_ptr, 50.0, 220.0, 20.0)
        
        # Yellow text
        _ = set_color(1.0, 1.0, 0.2, 1.0)
        var text5 = String("Mojo + C + stb_truetype = WORKING!")
        var text5_bytes = text5.as_bytes()
        var text5_ptr = text5_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text5_ptr, 50.0, 260.0, 18.0)
        
        # Test different sizes
        _ = set_color(1.0, 0.5, 1.0, 1.0)
        var text6 = String("Size 12")
        var text6_bytes = text6.as_bytes()
        var text6_ptr = text6_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text6_ptr, 50.0, 320.0, 12.0)
        
        var text7 = String("Size 24")
        var text7_bytes = text7.as_bytes()
        var text7_ptr = text7_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text7_ptr, 150.0, 320.0, 24.0)
        
        var text8 = String("Size 36")
        var text8_bytes = text8.as_bytes()
        var text8_ptr = text8_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text8_ptr, 300.0, 320.0, 36.0)
        
        # Instructions
        _ = set_color(0.8, 0.8, 0.8, 1.0)
        var instr = String("If you see actual letters instead of rectangles, FONTS WORK!")
        var instr_bytes = instr.as_bytes()
        var instr_ptr = instr_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(instr_ptr, 50.0, 450.0, 14.0)
        
        if frame_end() != 0:
            break
        
        frame_count += 1
        
        if frame_count % 60 == 0:
            var seconds = frame_count / 60
            print("📝 Second", seconds, "- Do you see readable text?")
    
    _ = cleanup_gl()
    
    print("📝 FONT TEST RESULTS:")
    print("   ✅ If you saw readable letters: REAL FONTS WORKING!")
    print("   ⚠️  If you saw white rectangles: Font loading failed, using fallback")
    print("   🎯 The system automatically falls back to rectangles if no font found")
    print("🎉 Real text test completed!")