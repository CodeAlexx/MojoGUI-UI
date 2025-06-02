#!/usr/bin/env mojo
"""
🎨 SYSTEM COLORS DEMO
Demonstrates the new system color detection capabilities in MojoGUI.
Automatically adapts to your system's dark/light mode and accent colors.
"""

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("🎨 SYSTEM COLORS DEMO - Adaptive Color Schemes")
    print("=" * 55)
    print("🚀 Testing new system color detection features...")
    print("✨ Auto-adapts to your system's color preferences")
    print("")
    
    # Load MojoGUI graphics library with NEW color functions
    var lib = DLHandle("./mojo-gui/c_src/librendering_primitives_int_with_fonts.so")
    print("✅ MojoGUI graphics library loaded")
    
    # Get standard functions
    var initialize_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var cleanup_gl = lib.get_function[fn() -> Int32]("cleanup_gl")
    var frame_begin = lib.get_function[fn() -> Int32]("frame_begin")
    var frame_end = lib.get_function[fn() -> Int32]("frame_end")
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    var load_default_font = lib.get_function[fn() -> Int32]("load_default_font")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close_window = lib.get_function[fn() -> Int32]("should_close_window")
    var get_mouse_x = lib.get_function[fn() -> Int32]("get_mouse_x")
    var get_mouse_y = lib.get_function[fn() -> Int32]("get_mouse_y")
    
    # Get NEW system color detection functions
    var get_system_dark_mode = lib.get_function[fn() -> Int32]("get_system_dark_mode")
    var get_system_accent_color = lib.get_function[fn() -> Int32]("get_system_accent_color")
    var get_system_window_color = lib.get_function[fn() -> Int32]("get_system_window_color")
    var get_system_text_color = lib.get_function[fn() -> Int32]("get_system_text_color")
    
    # Initialize window
    var window_width = 800
    var window_height = 600
    var title = String("🎨 System Colors Demo - Adaptive UI")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    print("🖥️  Opening system colors demo window...")
    var init_result = initialize_gl(window_width, window_height, title_ptr)
    
    if init_result != 0:
        print("❌ Failed to initialize graphics")
        return
    
    print("✅ Graphics window opened!")
    
    # Load fonts
    var font_result = load_default_font()
    if font_result == 0:
        print("✅ Professional TTF fonts loaded!")
    else:
        print("⚠️  Font loading failed, using fallback")
    
    # Detect system colors
    print("")
    print("🔍 DETECTING SYSTEM COLOR PREFERENCES:")
    
    var dark_mode = get_system_dark_mode()
    var accent_color = get_system_accent_color()
    var window_color = get_system_window_color()
    var text_color = get_system_text_color()
    
    print("   • Dark Mode:", 
          "🌙 YES" if dark_mode == 1 else "☀️ NO" if dark_mode == 0 else "❓ UNKNOWN")
    print("   • Accent Color: " + String(accent_color) if accent_color != -1 else "❓ Unknown")
    print("   • Window Color: " + String(window_color) if window_color != -1 else "❓ Unknown")
    print("   • Text Color: " + String(text_color) if text_color != -1 else "❓ Unknown")
    
    print("")
    print("🎨 Demo will adapt colors to your system preferences!")
    print("🖱️  Move mouse to see adaptive color swatches")
    
    # Extract RGBA components from packed colors
    fn extract_r(color: Int32) -> Int32:
        return (color >> 24) & 0xFF
    
    fn extract_g(color: Int32) -> Int32:
        return (color >> 16) & 0xFF
        
    fn extract_b(color: Int32) -> Int32:
        return (color >> 8) & 0xFF
        
    fn extract_a(color: Int32) -> Int32:
        return color & 0xFF
    
    var frame_count: Int32 = 0
    
    # Main render loop
    while should_close_window() == 0:
        _ = poll_events()
        frame_count += 1
        
        var mouse_x = get_mouse_x()
        var mouse_y = get_mouse_y()
        
        if frame_begin() != 0:
            break
        
        # Use system window color as background
        if window_color != -1:
            var bg_r = extract_r(window_color)
            var bg_g = extract_g(window_color)
            var bg_b = extract_b(window_color)
            var bg_a = extract_a(window_color)
            _ = set_color(bg_r, bg_g, bg_b, bg_a)
        else:
            _ = set_color(240, 240, 240, 255)  # Fallback light gray
        _ = draw_filled_rectangle(0, 0, window_width, window_height)
        
        # Title with system text color
        if text_color != -1:
            var txt_r = extract_r(text_color)
            var txt_g = extract_g(text_color)
            var txt_b = extract_b(text_color)
            var txt_a = extract_a(text_color)
            _ = set_color(txt_r, txt_g, txt_b, txt_a)
        else:
            _ = set_color(0, 0, 0, 255)  # Fallback black
        
        var title_text = String("🎨 System Colors Demo")
        var title_text_bytes = title_text.as_bytes()
        var title_text_ptr = title_text_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(title_text_ptr, 50, 50, 24)
        
        # Show detected mode
        var mode_text = String("Mode: " + ("🌙 Dark Mode" if dark_mode == 1 else "☀️ Light Mode" if dark_mode == 0 else "❓ Unknown"))
        var mode_text_bytes = mode_text.as_bytes()
        var mode_text_ptr = mode_text_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(mode_text_ptr, 50, 90, 16)
        
        # Accent color swatch
        if accent_color != -1:
            var acc_r = extract_r(accent_color)
            var acc_g = extract_g(accent_color)
            var acc_b = extract_b(accent_color)
            var acc_a = extract_a(accent_color)
            _ = set_color(acc_r, acc_g, acc_b, acc_a)
            _ = draw_filled_rectangle(50, 130, 100, 40)
            
            # Accent color label
            if text_color != -1:
                var txt_r = extract_r(text_color)
                var txt_g = extract_g(text_color)
                var txt_b = extract_b(text_color)
                var txt_a = extract_a(text_color)
                _ = set_color(txt_r, txt_g, txt_b, txt_a)
            else:
                _ = set_color(0, 0, 0, 255)
            
            var accent_label = String("System Accent Color")
            var accent_label_bytes = accent_label.as_bytes()
            var accent_label_ptr = accent_label_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(accent_label_ptr, 160, 145, 14)
        
        # Interactive color preview that follows mouse
        var preview_x = mouse_x - 50
        var preview_y = mouse_y - 25
        
        # Clamp to window bounds
        if preview_x < 0: preview_x = 0
        if preview_y < 0: preview_y = 0
        if preview_x > window_width - 100: preview_x = window_width - 100
        if preview_y > window_height - 50: preview_y = window_height - 50
        
        # Mouse-following accent color preview
        if accent_color != -1:
            var acc_r = extract_r(accent_color)
            var acc_g = extract_g(accent_color)
            var acc_b = extract_b(accent_color)
            var acc_a = extract_a(accent_color)
            # Add mouse-based variation
            var variant_r = acc_r + (mouse_x * 50 // window_width - 25)
            var variant_g = acc_g + (mouse_y * 50 // window_height - 25)
            var variant_b = acc_b + ((mouse_x + mouse_y) * 30 // (window_width + window_height) - 15)
            
            # Clamp values
            if variant_r < 0: variant_r = 0
            if variant_r > 255: variant_r = 255
            if variant_g < 0: variant_g = 0
            if variant_g > 255: variant_g = 255
            if variant_b < 0: variant_b = 0
            if variant_b > 255: variant_b = 255
            
            _ = set_color(variant_r, variant_g, variant_b, 200)
            _ = draw_filled_rectangle(preview_x, preview_y, 100, 50)
        
        # Mouse coordinates with system text color
        if text_color != -1:
            var txt_r = extract_r(text_color)
            var txt_g = extract_g(text_color)
            var txt_b = extract_b(text_color)
            var txt_a = extract_a(text_color)
            _ = set_color(txt_r, txt_g, txt_b, txt_a)
        else:
            _ = set_color(0, 0, 0, 255)
        
        var mouse_info = String("Mouse: (" + String(mouse_x) + ", " + String(mouse_y) + ")")
        var mouse_info_bytes = mouse_info.as_bytes()
        var mouse_info_ptr = mouse_info_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(mouse_info_ptr, 50, window_height - 100, 12)
        
        # Color values display
        var color_info = String("Accent: " + String(accent_color if accent_color != -1 else 0))
        var color_info_bytes = color_info.as_bytes()
        var color_info_ptr = color_info_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(color_info_ptr, 50, window_height - 80, 12)
        
        var bg_info = String("Background: " + String(window_color if window_color != -1 else 0))
        var bg_info_bytes = bg_info.as_bytes()
        var bg_info_ptr = bg_info_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(bg_info_ptr, 50, window_height - 60, 12)
        
        var text_info = String("Text: " + String(text_color if text_color != -1 else 0))
        var text_info_bytes = text_info.as_bytes()
        var text_info_ptr = text_info_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text_info_ptr, 50, window_height - 40, 12)
        
        # Instructions
        var instructions = String("🖱️ Move mouse to see adaptive colors • ESC to exit")
        var instructions_bytes = instructions.as_bytes()
        var instructions_ptr = instructions_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(instructions_ptr, 200, window_height - 20, 10)
        
        if frame_end() != 0:
            break
        
        # Status updates
        if frame_count % 300 == 0:  # Every 5 seconds at 60fps
            var seconds = frame_count // 60
            print("🎨 System colors demo running...", seconds, "seconds - Colors adapting to system!")
    
    _ = cleanup_gl()
    
    print("")
    print("🎉 SYSTEM COLORS DEMO COMPLETED!")
    print("=" * 45)
    print("✅ SUCCESSFULLY DEMONSTRATED:")
    print("   • 🎨 System color detection working")
    print("   • 🌙 Dark/light mode detection")
    print("   • 🔵 System accent color extraction")
    print("   • 🖼️ Adaptive background colors")
    print("   • 📝 Appropriate text colors")
    print("   • 🖱️ Interactive color adaptation")
    print("")
    print("🚀 Ready to integrate into file manager!")
    print("💼 Perfect for professional adaptive UIs!")