#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("🔍 AI Vision Test Demo")
    print("=====================")
    print("Creating text on screen for AI vision analysis...")
    
    # Use the TTF-enabled library
    var lib = DLHandle("./c_src/librendering_primitives_int_with_fonts.so")
    print("✅ TTF library loaded")
    
    # Get function pointers
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
    
    # Initialize window
    var title = String("AI Vision Test - Mojo GUI Text Rendering")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    var init_result = initialize_gl(800, 600, title_ptr)
    if init_result != 0:
        print("❌ Failed to initialize")
        return
    
    print("✅ Window opened for AI vision test")
    
    # Load TTF fonts
    var font_result = load_default_font()
    if font_result == 0:
        print("✅ TTF fonts loaded - ready for vision analysis")
    
    var frame_count: Int32 = 0
    
    # Render for a few frames to ensure stable display
    while should_close_window() == 0 and frame_count < 180:  # 3 seconds at 60fps
        _ = poll_events()
        
        if frame_begin() != 0:
            break
        
        # Clear background to white for better vision analysis
        _ = set_color(255, 255, 255, 255)
        _ = draw_filled_rectangle(0, 0, 800, 600)
        
        # Title
        _ = set_color(0, 0, 0, 255)
        var main_title = String("MOJO GUI SYSTEM")
        var main_title_bytes = main_title.as_bytes()
        var main_title_ptr = main_title_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(main_title_ptr, 50, 50, 32)
        
        # Subtitle
        var subtitle = String("Advanced Widgets with TTF Fonts")
        var subtitle_bytes = subtitle.as_bytes()
        var subtitle_ptr = subtitle_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(subtitle_ptr, 50, 100, 16)
        
        # Widget list
        _ = set_color(50, 50, 150, 255)
        var widget_title = String("Available Widgets:")
        var widget_title_bytes = widget_title.as_bytes()
        var widget_title_ptr = widget_title_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(widget_title_ptr, 50, 150, 18)
        
        # Widget items
        _ = set_color(0, 0, 0, 255)
        var widgets = List[String]()
        widgets.append("1. DockPanel - Professional docking system")
        widgets.append("2. Accordion - Collapsible sections")
        widgets.append("3. Toolbar - Button toolbar with dropdowns")
        widgets.append("4. Button - Interactive buttons")
        widgets.append("5. Checkbox - Toggle controls")
        widgets.append("6. Slider - Value adjustment")
        widgets.append("7. TextEdit - Text input fields")
        widgets.append("8. ProgressBar - Progress indicators")
        widgets.append("9. ListView - Advanced data grid")
        widgets.append("10. ContextMenu - Right-click menus")
        
        for i in range(10):
            var item_bytes = widgets[i].as_bytes()
            var item_ptr = item_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(item_ptr, 70, 190 + i * 25, 12)
        
        # Draw some sample UI elements
        _ = set_color(200, 200, 200, 255)
        _ = draw_filled_rectangle(500, 150, 120, 35)
        _ = set_color(100, 100, 100, 255)
        _ = draw_rectangle(500, 150, 120, 35)
        _ = set_color(0, 0, 0, 255)
        var button_text = String("Sample Button")
        var button_bytes = button_text.as_bytes()
        var button_ptr = button_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(button_ptr, 515, 162, 11)
        
        # Checkbox
        _ = set_color(255, 255, 255, 255)
        _ = draw_filled_rectangle(500, 200, 20, 20)
        _ = set_color(100, 100, 100, 255)
        _ = draw_rectangle(500, 200, 20, 20)
        _ = set_color(0, 150, 0, 255)
        var check_text = String("✓")
        var check_bytes = check_text.as_bytes()
        var check_ptr = check_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(check_ptr, 505, 205, 12)
        
        _ = set_color(0, 0, 0, 255)
        var checkbox_label = String("Enabled")
        var checkbox_bytes = checkbox_label.as_bytes()
        var checkbox_ptr = checkbox_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(checkbox_ptr, 530, 208, 12)
        
        # Footer
        _ = set_color(100, 100, 100, 255)
        var footer = String("Ready for AI Vision Analysis")
        var footer_bytes = footer.as_bytes()
        var footer_ptr = footer_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(footer_ptr, 50, 520, 14)
        
        if frame_end() != 0:
            break
        
        frame_count += 1
        
        # Take screenshot after a few frames to ensure everything is rendered
        if frame_count == 60:
            print("📸 GUI is stable - ready for screenshot and AI vision analysis")
    
    _ = cleanup_gl()
    print("✅ Vision test demo completed")