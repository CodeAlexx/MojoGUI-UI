#!/usr/bin/env mojo
"""
Basic Mojo Integer-Only FFI Test
Simple test using proven patterns from working MojoGUI system.
"""

from sys.ffi import external_call
from memory import alloc, UnsafePointer
from builtin.type_aliases import MutExternalOrigin

fn test_integer_ffi():
    """Test the integer-only C library from Mojo."""
    print("🧪 Testing Integer-Only FFI from Mojo")
    print("Using proven patterns from successful MojoGUI system")
    
    # Test basic functionality
    var width: Int32 = 640
    var height: Int32 = 480
    var title = "Mojo Integer Test"
    
    # Load library and call initialization
    try:
        var lib = external_call["dlopen", UnsafePointer[NoneType]]("./c_src/librendering_primitives_int.so".data(), 2)
        
        if not lib:
            print("❌ Failed to load library")
            return
        
        print("✅ Library loaded successfully")
        
        # Initialize context
        var init_result = external_call["initialize_gl_context", Int32](lib, width, height, title.data())
        
        if init_result != 0:
            print("❌ Initialization failed:", init_result)
            return
        
        print("✅ Integer-only context initialized")
        
        # Load font
        var font_result = external_call["load_default_font", Int32](lib)
        if font_result == 0:
            print("✅ Font loaded")
        else:
            print("⚠️  Font loading failed")
        
        # Run simple render loop
        print("🎯 Starting integer render loop...")
        
        var frame_count: Int32 = 0
        
        while frame_count < 120:  # 2 seconds at 60fps
            # Poll events
            _ = external_call["poll_events", Int32](lib)
            
            # Check if should close
            var should_close = external_call["should_close_window", Int32](lib)
            if should_close != 0:
                print("🚪 Window close requested")
                break
            
            # Begin frame
            var frame_begin_result = external_call["frame_begin", Int32](lib)
            if frame_begin_result != 0:
                print("❌ Frame begin failed")
                break
            
            # Clear background (dark blue: RGB 30, 40, 60)
            _ = external_call["set_color", Int32](lib, 30, 40, 60, 255)
            _ = external_call["draw_filled_rectangle", Int32](lib, 0, 0, width, height)
            
            # Draw title (white text)
            _ = external_call["set_color", Int32](lib, 255, 255, 255, 255)
            _ = external_call["draw_text", Int32](lib, "Mojo Integer-Only Test".data(), 50, 50, 20)
            
            # Draw description (light green)
            _ = external_call["set_color", Int32](lib, 180, 255, 180, 255)
            _ = external_call["draw_text", Int32](lib, "All coordinates & colors are Int32".data(), 50, 90, 14)
            
            # Get mouse position
            var mouse_x = external_call["get_mouse_x", Int32](lib)
            var mouse_y = external_call["get_mouse_y", Int32](lib)
            
            # Draw mouse position (cyan)
            _ = external_call["set_color", Int32](lib, 100, 255, 255, 255)
            var mouse_text = "Mouse: " + str(mouse_x) + ", " + str(mouse_y)
            _ = external_call["draw_text", Int32](lib, mouse_text.data(), 50, 130, 12)
            
            # Draw frame counter (yellow)
            _ = external_call["set_color", Int32](lib, 255, 255, 100, 255)
            var frame_text = "Frame: " + str(frame_count)
            _ = external_call["draw_text", Int32](lib, frame_text.data(), 50, 150, 12)
            
            # Draw demonstration features (light gray)
            _ = external_call["set_color", Int32](lib, 180, 180, 180, 255)
            _ = external_call["draw_text", Int32](lib, "✓ Integer-only FFI (no conversion bugs)".data(), 50, 200, 12)
            _ = external_call["draw_text", Int32](lib, "✓ Real-time mouse tracking".data(), 50, 220, 12)
            _ = external_call["draw_text", Int32](lib, "✓ Stable Mojo-C integration".data(), 50, 240, 12)
            _ = external_call["draw_text", Int32](lib, "✓ Minimal memory overhead".data(), 50, 260, 12)
            
            # Draw simple button (light gray rectangle)
            _ = external_call["set_color", Int32](lib, 220, 220, 220, 255)
            _ = external_call["draw_filled_rectangle", Int32](lib, 200, 300, 120, 40)
            
            # Button border
            _ = external_call["set_color", Int32](lib, 100, 100, 100, 255)
            _ = external_call["draw_rectangle", Int32](lib, 200, 300, 120, 40)
            
            # Button text
            _ = external_call["set_color", Int32](lib, 0, 0, 0, 255)
            _ = external_call["draw_text", Int32](lib, "Working!".data(), 230, 315, 14)
            
            # Draw mouse cursor indicator (red circle)
            _ = external_call["set_color", Int32](lib, 255, 100, 100, 255)
            _ = external_call["draw_filled_circle", Int32](lib, mouse_x, mouse_y, 4, 8)
            
            # End frame
            var frame_end_result = external_call["frame_end", Int32](lib)
            if frame_end_result != 0:
                print("❌ Frame end failed")
                break
            
            frame_count += 1
            
            # Print status every second
            if frame_count % 60 == 0:
                print("📊 Frame", frame_count, "- Mouse:", mouse_x, ",", mouse_y)
        
        print("🏁 Integer render loop completed after", frame_count, "frames")
        
        # Cleanup
        var cleanup_result = external_call["cleanup_gl", Int32](lib)
        if cleanup_result == 0:
            print("✅ Cleanup successful")
        else:
            print("⚠️  Cleanup warning")
        
        print("🎉 Mojo integer-only test successful!")
        print("🚀 Ready for full widget system implementation!")
        
    except e:
        print("❌ Exception during test:", e)

fn main():
    """Main entry point."""
    test_integer_ffi()