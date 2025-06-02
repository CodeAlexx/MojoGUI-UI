#!/usr/bin/env python3
"""
Python test for the rendering primitives library
Simulates what Mojo FFI will do
"""

import ctypes
import time

def test_rendering_primitives():
    print("🐍 Testing Rendering Primitives from Python")
    
    # Load the library
    lib = ctypes.CDLL('./librendering_primitives.so')
    
    # Define function signatures
    lib.initialize_gl_context.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_char_p]
    lib.initialize_gl_context.restype = ctypes.c_int
    
    lib.cleanup_gl.argtypes = []
    lib.cleanup_gl.restype = ctypes.c_int
    
    lib.frame_begin.argtypes = []
    lib.frame_begin.restype = ctypes.c_int
    
    lib.frame_end.argtypes = []
    lib.frame_end.restype = ctypes.c_int
    
    lib.set_color.argtypes = [ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float]
    lib.set_color.restype = ctypes.c_int
    
    lib.draw_filled_rectangle.argtypes = [ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float]
    lib.draw_filled_rectangle.restype = ctypes.c_int
    
    lib.draw_rectangle.argtypes = [ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float]
    lib.draw_rectangle.restype = ctypes.c_int
    
    lib.draw_filled_circle.argtypes = [ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_int]
    lib.draw_filled_circle.restype = ctypes.c_int
    
    lib.draw_line.argtypes = [ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float]
    lib.draw_line.restype = ctypes.c_int
    
    lib.draw_text.argtypes = [ctypes.c_char_p, ctypes.c_float, ctypes.c_float, ctypes.c_float]
    lib.draw_text.restype = ctypes.c_int
    
    lib.load_default_font.argtypes = []
    lib.load_default_font.restype = ctypes.c_int
    
    lib.poll_events.argtypes = []
    lib.poll_events.restype = ctypes.c_int
    
    lib.should_close_window.argtypes = []
    lib.should_close_window.restype = ctypes.c_int
    
    # Initialize
    print("1. Initializing from Python...")
    result = lib.initialize_gl_context(700, 500, b"Python FFI Test")
    if result != 0:
        print(f"❌ Failed to initialize: {result}")
        return False
    print("✅ Initialized from Python")
    
    # Load font
    result = lib.load_default_font()
    if result != 0:
        print("⚠️  Font loading failed")
    else:
        print("✅ Font loaded")
    
    print("2. Starting Python render loop...")
    
    frame_count = 0
    while frame_count < 180:  # ~3 seconds
        # Poll events
        lib.poll_events()
        
        # Check for close
        if lib.should_close_window():
            print("🚪 Window close requested")
            break
        
        # Begin frame
        if lib.frame_begin() != 0:
            print("❌ Frame begin failed")
            break
        
        # Clear background (dark green)
        lib.set_color(0.1, 0.3, 0.1, 1.0)
        lib.draw_filled_rectangle(0.0, 0.0, 700.0, 500.0)
        
        # Draw animated shapes
        time_factor = frame_count * 0.05
        
        # Moving red rectangle
        x = 50.0 + 100.0 * (0.5 + 0.5 * ctypes.c_float(time_factor % 6.28).value)
        lib.set_color(1.0, 0.2, 0.2, 1.0)
        lib.draw_filled_rectangle(x, 100.0, 80.0, 50.0)
        
        # Pulsing blue circle
        radius = 20.0 + 15.0 * abs(ctypes.c_float(time_factor % 3.14).value)
        lib.set_color(0.2, 0.2, 1.0, 1.0)
        lib.draw_filled_circle(350.0, 200.0, radius, 16)
        
        # Static yellow border
        lib.set_color(1.0, 1.0, 0.2, 1.0)
        lib.draw_rectangle(450.0, 150.0, 200.0, 100.0)
        
        # Dynamic white line
        x2 = 600.0 + 50.0 * ctypes.c_float(time_factor % 3.14).value
        lib.set_color(1.0, 1.0, 1.0, 1.0)
        lib.draw_line(50.0, 300.0, x2, 300.0, 2.0)
        
        # Text
        lib.set_color(1.0, 1.0, 1.0, 1.0)
        lib.draw_text(b"Python -> C FFI Working!", 50.0, 350.0, 18.0)
        
        # End frame
        if lib.frame_end() != 0:
            print("❌ Frame end failed")
            break
        
        frame_count += 1
        
        if frame_count % 60 == 0:
            print(f"📊 Python Frame {frame_count}")
        
        time.sleep(1.0/60.0)  # 60 FPS
    
    print(f"🏁 Python render loop completed: {frame_count} frames")
    
    # Cleanup
    result = lib.cleanup_gl()
    if result != 0:
        print("⚠️  Cleanup warning")
    else:
        print("✅ Cleanup successful")
    
    print("🎉 Python FFI test completed successfully!")
    return True

if __name__ == "__main__":
    test_rendering_primitives()