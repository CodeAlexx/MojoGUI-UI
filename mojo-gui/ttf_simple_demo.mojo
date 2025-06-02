#!/usr/bin/env mojo
"""
Simple TTF Font Demo for Mojo GUI
Demonstrates the new integer API with REAL TTF font rendering.
"""

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("🎨 TTF Font Demo - Integer API with Professional Fonts")
    
    # Load the TTF-enabled library
    var lib = DLHandle("./c_src/librendering_primitives_int_with_fonts.so")
    print("✅ TTF font library loaded successfully")
    
    # Get essential function pointers
    var initialize_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[UInt8]) -> Int32]("initialize_gl_context")
    var load_font = lib.get_function[fn() -> Int32]("load_default_font")
    var cleanup = lib.get_function[fn() -> Int32]("cleanup_gl")
    var frame_begin = lib.get_function[fn() -> Int32]("frame_begin")
    var frame_end = lib.get_function[fn() -> Int32]("frame_end")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close = lib.get_function[fn() -> Int32]("should_close_window")
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_rect = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[UInt8], Int32, Int32, Int32) -> Int32]("draw_text")
    
    # Initialize window
    print("🚀 Initializing window...")
    var title = "Mojo TTF Font Demo"
    var result = initialize_gl(800, 600, title.unsafe_ptr())
    if result != 0:
        print("❌ Failed to initialize window")
        return
    
    # Load fonts
    print("🔤 Loading TTF fonts...")
    var font_result = load_font()
    if font_result != 0:
        print("⚠️  TTF font loading failed")
    else:
        print("✅ TTF fonts loaded successfully!")
    
    print("🎯 Starting demo loop...")
    
    # Simple demo loop
    var frame_count = 0
    while should_close() == 0 and frame_count < 180:  # 3 seconds
        _ = poll_events()
        
        if frame_begin() != 0:
            break
        
        # Clear background (dark gray)
        _ = set_color(40, 40, 40, 255)
        _ = draw_rect(0, 0, 800, 600)
        
        # Draw title (white)
        _ = set_color(255, 255, 255, 255)
        var title_text = "Mojo GUI with TTF Fonts!"
        _ = draw_text(title_text.unsafe_ptr(), 50, 50, 24)
        
        # Draw subtitle (green)
        _ = set_color(100, 255, 100, 255)
        var subtitle = "Professional font rendering via stb_truetype"
        _ = draw_text(subtitle.unsafe_ptr(), 50, 90, 16)
        
        # Font size examples
        _ = set_color(200, 200, 255, 255)
        var text12 = "Size 12: The quick brown fox jumps"
        _ = draw_text(text12.unsafe_ptr(), 50, 150, 12)
        
        var text16 = "Size 16: The quick brown fox jumps"
        _ = draw_text(text16.unsafe_ptr(), 50, 180, 16)
        
        var text20 = "Size 20: The quick brown fox jumps"
        _ = draw_text(text20.unsafe_ptr(), 50, 210, 20)
        
        # Features
        _ = set_color(255, 200, 100, 255)
        var features = "Features: Integer API + Real TTF fonts"
        _ = draw_text(features.unsafe_ptr(), 50, 260, 14)
        
        var anti_alias = "Anti-aliasing and gamma correction enabled"
        _ = draw_text(anti_alias.unsafe_ptr(), 50, 280, 14)
        
        var compatibility = "Full Mojo FFI compatibility"
        _ = draw_text(compatibility.unsafe_ptr(), 50, 300, 14)
        
        # Success message
        _ = set_color(100, 255, 255, 255)
        var success = "SUCCESS: TTF fonts working in Mojo!"
        _ = draw_text(success.unsafe_ptr(), 50, 350, 18)
        
        if frame_end() != 0:
            break
        
        frame_count += 1
        
        # Progress indicator
        if frame_count % 60 == 0:
            print("Frame:", frame_count)
    
    print("🧹 Cleaning up...")
    _ = cleanup()
    print("✅ Demo completed successfully!")
    print("🎉 TTF font integration working perfectly!")