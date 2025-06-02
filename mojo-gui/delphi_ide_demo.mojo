#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("🏗️  DELPHI-STYLE IDE DEMO - Split Tabs with Tooltips!")
    print("===================================================")
    
    # Use the font-enabled library
    var lib = DLHandle("./c_src/librendering_with_fonts.so")
    print("✅ Font-enabled library loaded")
    
    # Get functions
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
    var get_mouse_x = lib.get_function[fn() -> Int32]("get_mouse_x")
    var get_mouse_y = lib.get_function[fn() -> Int32]("get_mouse_y")
    var get_mouse_button_state = lib.get_function[fn(Int32) -> Int32]("get_mouse_button_state")
    
    # Initialize window
    var title = String("Delphi-Style IDE Demo - Split Tabs with Tooltips!")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    print("🚀 Opening Delphi-style IDE demo...")
    var init_result = initialize_gl(1200, 800, title_ptr)
    
    if init_result != 0:
        print("❌ Failed to initialize")
        return
    
    print("✅ Window opened!")
    
    # Load font
    var font_result = load_default_font()
    if font_result == 0:
        print("✅ Real fonts loaded!")
    else:
        print("⚠️  Font loading failed")
    
    print("")
    print("🏗️  IDE DEMO FEATURES:")
    print("   📂 Project Explorer with file tree")
    print("   📝 Code Editor with syntax highlighting")
    print("   🎨 Form Designer for visual layout")
    print("   🔍 Structure View showing code outline")
    print("   📋 Resizable split panels")
    print("   💬 Tooltips on hover")
    print("   🖱️  Drag splitters to resize")
    print("")
    print("🖱️  Hover over tabs for tooltips! Drag the splitter to resize!")
    
    # Splitter state
    var splitter_x: Float32 = 300.0  # Initial position
    var dragging_splitter: Bool = False
    var drag_start_x: Float32 = 0.0
    var drag_start_splitter: Float32 = 0.0
    var hovering_splitter: Bool = False
    var splitter_width: Float32 = 6.0
    var min_pane_size: Float32 = 150.0
    
    # Tab states
    var left_active_tab: Int32 = 0
    var right_active_tab: Int32 = 0
    var left_hover_tab: Int32 = -1
    var right_hover_tab: Int32 = -1
    
    # Tooltip state
    var tooltip_visible: Bool = False
    var tooltip_text: String = ""
    var tooltip_x: Float32 = 0.0
    var tooltip_y: Float32 = 0.0
    var tooltip_width: Float32 = 0.0
    var tooltip_height: Float32 = 20.0
    var hover_start_time: Int32 = 0
    var current_hover_tab: Int32 = -1
    var hover_delay: Int32 = 30  # frames to wait before showing tooltip
    
    # Tab definitions
    var left_tab_names = List[String]()
    left_tab_names.append("Project")
    left_tab_names.append("Structure")
    left_tab_names.append("Model")
    
    var left_tab_tooltips = List[String]()
    left_tab_tooltips.append("Project Explorer - Shows all files in your project")
    left_tab_tooltips.append("Structure View - Shows code structure of current file")
    left_tab_tooltips.append("Model View - UML diagram of classes")
    
    var right_tab_names = List[String]()
    right_tab_names.append("Unit1.pas")
    right_tab_names.append("Form1")
    right_tab_names.append("Unit2.pas")
    
    var right_tab_tooltips = List[String]()
    right_tab_tooltips.append("Pascal source code for Unit1")
    right_tab_tooltips.append("Visual form designer for Form1")
    right_tab_tooltips.append("Pascal source code for Unit2")
    
    var frame_count: Int32 = 0
    var last_mouse_state: Bool = False
    
    print("🎮 Delphi-style IDE demo running!")
    
    while should_close_window() == 0:
        # Poll events
        _ = poll_events()
        
        # Get mouse state
        var mouse_x = get_mouse_x()
        var mouse_y = get_mouse_y()
        var mouse_pressed = get_mouse_button_state(0) == 1
        
        var mx = Float32(mouse_x)
        var my = Float32(mouse_y)
        
        # Handle splitter dragging
        var splitter_rect_x = splitter_x
        var splitter_rect_y = 80.0  # Below title bar
        var splitter_rect_w = splitter_width
        var splitter_rect_h = 720.0  # Window height - title bar
        
        var on_splitter = (mx >= splitter_rect_x and mx <= splitter_rect_x + splitter_rect_w and
                          my >= Float32(splitter_rect_y) and my <= Float32(splitter_rect_y) + Float32(splitter_rect_h))
        
        hovering_splitter = on_splitter
        
        if mouse_pressed and not last_mouse_state and on_splitter:
            # Start dragging
            dragging_splitter = True
            drag_start_x = mx
            drag_start_splitter = splitter_x
        elif not mouse_pressed:
            # Stop dragging
            dragging_splitter = False
        
        if dragging_splitter:
            # Update splitter position
            var delta = mx - drag_start_x
            var new_splitter = drag_start_splitter + delta
            
            if new_splitter < min_pane_size:
                new_splitter = min_pane_size
            elif new_splitter > 1200.0 - min_pane_size - splitter_width:
                new_splitter = 1200.0 - min_pane_size - splitter_width
            
            splitter_x = new_splitter
        
        # Handle tab interactions
        if mouse_pressed and not last_mouse_state and not on_splitter:
            # Left tabs
            if my >= 80.0 and my <= 110.0:  # Tab bar height
                for i in range(3):
                    var tab_x = 10.0 + Float32(i) * 80.0
                    if mx >= tab_x and mx <= tab_x + 80.0 and mx < splitter_x:
                        left_active_tab = Int32(i)
                        print("🔵 Selected left tab:", left_tab_names[i])
            
            # Right tabs
            if my >= 80.0 and my <= 110.0:  # Tab bar height
                for i in range(3):
                    var tab_x = splitter_x + splitter_width + 10.0 + Float32(i) * 90.0
                    if mx >= tab_x and mx <= tab_x + 90.0:
                        right_active_tab = Int32(i)
                        print("🔴 Selected right tab:", right_tab_names[i])
        
        # Handle tooltip hover
        var new_hover_tab = -1
        var new_tooltip_text = String("")
        
        # Check left tabs
        if my >= 80.0 and my <= 110.0 and mx < splitter_x:
            for i in range(3):
                var tab_x = 10.0 + Float32(i) * 80.0
                if mx >= tab_x and mx <= tab_x + 80.0:
                    new_hover_tab = i
                    new_tooltip_text = left_tab_tooltips[i]
                    break
        
        # Check right tabs
        if my >= 80.0 and my <= 110.0 and mx > splitter_x + splitter_width:
            for i in range(3):
                var tab_x = splitter_x + splitter_width + 10.0 + Float32(i) * 90.0
                if mx >= tab_x and mx <= tab_x + 90.0:
                    new_hover_tab = i + 10  # Offset for right tabs
                    new_tooltip_text = right_tab_tooltips[i]
                    break
        
        # Update tooltip state
        if Int32(new_hover_tab) != current_hover_tab:
            current_hover_tab = new_hover_tab
            hover_start_time = 0
            tooltip_visible = False
        elif new_hover_tab >= 0:
            hover_start_time += 1
            if hover_start_time >= hover_delay and not tooltip_visible:
                tooltip_visible = True
                tooltip_text = new_tooltip_text
                tooltip_x = mx + 10.0
                tooltip_y = my + 10.0
                # Calculate tooltip width
                tooltip_width = Float32(len(tooltip_text)) * 6.0 + 12.0
        else:
            tooltip_visible = False
            hover_start_time = 0
        
        last_mouse_state = mouse_pressed
        frame_count += 1
        
        # Begin frame
        if frame_begin() != 0:
            break
        
        # Clear background (IDE dark theme)
        _ = set_color(0.15, 0.15, 0.15, 1.0)
        _ = draw_filled_rectangle(0.0, 0.0, 1200.0, 800.0)
        
        # Draw title bar
        _ = set_color(0.2, 0.3, 0.4, 1.0)
        _ = draw_filled_rectangle(0.0, 0.0, 1200.0, 80.0)
        
        _ = set_color(1.0, 1.0, 1.0, 1.0)
        var main_title = String("Delphi-Style IDE Demo")
        var title_bytes2 = main_title.as_bytes()
        var title_ptr2 = title_bytes2.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(title_ptr2, 50.0, 20.0, 20.0)
        
        var subtitle = String("Split Tabs with Tooltips & Resizable Panes")
        var subtitle_bytes = subtitle.as_bytes()
        var subtitle_ptr = subtitle_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(subtitle_ptr, 50.0, 50.0, 12.0)
        
        # Draw left pane background
        _ = set_color(0.25, 0.25, 0.25, 1.0)
        _ = draw_filled_rectangle(0.0, 80.0, splitter_x, 720.0)
        
        # Draw right pane background
        _ = set_color(0.28, 0.28, 0.28, 1.0)
        _ = draw_filled_rectangle(splitter_x + splitter_width, 80.0, 
                                 1200.0 - splitter_x - splitter_width, 720.0)
        
        # Draw left tabs
        for i in range(3):
            var tab_x = 10.0 + Float32(i) * 80.0
            var is_active = (Int32(i) == left_active_tab)
            
            # Tab background
            if is_active:
                _ = set_color(0.4, 0.4, 0.4, 1.0)
            else:
                _ = set_color(0.3, 0.3, 0.3, 1.0)
            _ = draw_filled_rectangle(tab_x, 80.0, 78.0, 30.0)
            
            # Tab border
            _ = set_color(0.5, 0.5, 0.5, 1.0)
            _ = draw_rectangle(tab_x, 80.0, 78.0, 30.0)
            
            # Tab text
            _ = set_color(1.0, 1.0, 1.0, 1.0)
            var tab_text_bytes = left_tab_names[i].as_bytes()
            var tab_text_ptr = tab_text_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(tab_text_ptr, tab_x + 8.0, 88.0, 10.0)
        
        # Draw right tabs
        for i in range(3):
            var tab_x = splitter_x + splitter_width + 10.0 + Float32(i) * 90.0
            var is_active = (Int32(i) == right_active_tab)
            
            # Tab background
            if is_active:
                _ = set_color(0.4, 0.4, 0.4, 1.0)
            else:
                _ = set_color(0.3, 0.3, 0.3, 1.0)
            _ = draw_filled_rectangle(tab_x, 80.0, 88.0, 30.0)
            
            # Tab border
            _ = set_color(0.5, 0.5, 0.5, 1.0)
            _ = draw_rectangle(tab_x, 80.0, 88.0, 30.0)
            
            # Tab text
            _ = set_color(1.0, 1.0, 1.0, 1.0)
            var tab_text_bytes = right_tab_names[i].as_bytes()
            var tab_text_ptr = tab_text_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(tab_text_ptr, tab_x + 5.0, 88.0, 10.0)
        
        # Draw splitter
        var splitter_color_r: Float32 = 0.4
        var splitter_color_g: Float32 = 0.6
        var splitter_color_b: Float32 = 0.8
        if hovering_splitter or dragging_splitter:
            splitter_color_r = 0.5
            splitter_color_g = 0.7
            splitter_color_b = 0.9
        
        _ = set_color(splitter_color_r, splitter_color_g, splitter_color_b, 1.0)
        _ = draw_filled_rectangle(splitter_x, 80.0, splitter_width, 720.0)
        
        # Draw splitter grip lines
        _ = set_color(0.6, 0.6, 0.6, 1.0)
        var center_x = splitter_x + splitter_width / 2.0
        var center_y = Float32(80.0 + 360.0)  # Middle of splitter
        for i in range(-20, 21, 8):
            _ = draw_line(center_x, center_y + Float32(i), center_x, center_y + Float32(i) + Float32(4.0), 1.0)
        
        # Draw pane content
        _ = set_color(0.9, 0.9, 0.9, 1.0)
        
        # Left pane content
        if left_active_tab == 0:
            var project_text = String("📂 Project Explorer")
            var project_bytes = project_text.as_bytes()
            var project_ptr = project_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(project_ptr, 20.0, 130.0, 14.0)
            
            var file_items = List[String]()
            file_items.append("├ Unit1.pas")
            file_items.append("├ Unit2.pas")
            file_items.append("├ Form1.dfm")
            file_items.append("├ Project1.dpr")
            file_items.append("└ Resources")
            
            for i in range(5):
                var item_bytes = file_items[i].as_bytes()
                var item_ptr = item_bytes.unsafe_ptr().bitcast[Int8]()
                _ = draw_text(item_ptr, 30.0, 160.0 + Float32(i) * 20.0, 10.0)
                
        elif left_active_tab == 1:
            var struct_text = String("📋 Structure View")
            var struct_bytes = struct_text.as_bytes()
            var struct_ptr = struct_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(struct_ptr, 20.0, 130.0, 14.0)
            
            var struct_items = List[String]()
            struct_items.append("🔧 Functions")
            struct_items.append("  ├ main()")
            struct_items.append("  └ helper()")
            struct_items.append("📦 Variables")
            struct_items.append("  └ counter: Int")
            
            for i in range(5):
                var item_bytes = struct_items[i].as_bytes()
                var item_ptr = item_bytes.unsafe_ptr().bitcast[Int8]()
                _ = draw_text(item_ptr, 30.0, 160.0 + Float32(i) * 20.0, 10.0)
                
        else:  # Model tab
            var model_text = String("📊 Model View")
            var model_bytes = model_text.as_bytes()
            var model_ptr = model_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(model_ptr, 20.0, 130.0, 14.0)
            
            var model_items = List[String]()
            model_items.append("🏗️  Class Diagram")
            model_items.append("├ TForm1")
            model_items.append("├ TDataModule")
            model_items.append("└ TCustomWidget")
            
            for i in range(4):
                var item_bytes = model_items[i].as_bytes()
                var item_ptr = item_bytes.unsafe_ptr().bitcast[Int8]()
                _ = draw_text(item_ptr, 30.0, 160.0 + Float32(i) * 20.0, 10.0)
        
        # Right pane content
        var right_start_x = splitter_x + splitter_width + 20.0
        
        if right_active_tab == 0:  # Unit1.pas
            var code_text = String("📝 Unit1.pas - Pascal Source Code")
            var code_bytes = code_text.as_bytes()
            var code_ptr = code_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(code_ptr, right_start_x, 130.0, 14.0)
            
            var code_lines = List[String]()
            code_lines.append("unit Unit1;")
            code_lines.append("")
            code_lines.append("interface")
            code_lines.append("")
            code_lines.append("uses")
            code_lines.append("  Windows, Forms, Controls;")
            code_lines.append("")
            code_lines.append("type")
            code_lines.append("  TForm1 = class(TForm)")
            code_lines.append("  private")
            code_lines.append("  public")
            code_lines.append("  end;")
            
            for i in range(12):
                var line_bytes = code_lines[i].as_bytes()
                var line_ptr = line_bytes.unsafe_ptr().bitcast[Int8]()
                _ = draw_text(line_ptr, right_start_x + 10.0, 160.0 + Float32(i) * 16.0, 9.0)
                
        elif right_active_tab == 1:  # Form1
            var form_text = String("🎨 Form1 - Visual Designer")
            var form_bytes = form_text.as_bytes()
            var form_ptr = form_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(form_ptr, right_start_x, 130.0, 14.0)
            
            # Draw a mock form
            _ = set_color(0.9, 0.9, 0.9, 1.0)
            _ = draw_filled_rectangle(right_start_x + 20.0, 160.0, 200.0, 150.0)
            _ = set_color(0.5, 0.5, 0.5, 1.0)
            _ = draw_rectangle(right_start_x + 20.0, 160.0, 200.0, 150.0)
            
            # Mock controls
            _ = set_color(0.8, 0.8, 0.8, 1.0)
            _ = draw_filled_rectangle(right_start_x + 30.0, 180.0, 80.0, 25.0)
            _ = draw_filled_rectangle(right_start_x + 30.0, 220.0, 80.0, 25.0)
            
            _ = set_color(0.2, 0.2, 0.2, 1.0)
            var btn1_text = String("Button1")
            var btn1_bytes = btn1_text.as_bytes()
            var btn1_ptr = btn1_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(btn1_ptr, right_start_x + 40.0, 188.0, 8.0)
            
            var btn2_text = String("Button2")
            var btn2_bytes = btn2_text.as_bytes()
            var btn2_ptr = btn2_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(btn2_ptr, right_start_x + 40.0, 228.0, 8.0)
            
        else:  # Unit2.pas
            var unit2_text = String("📝 Unit2.pas - Pascal Source Code")
            var unit2_bytes = unit2_text.as_bytes()
            var unit2_ptr = unit2_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(unit2_ptr, right_start_x, 130.0, 14.0)
            
            var unit2_lines = List[String]()
            unit2_lines.append("unit Unit2;")
            unit2_lines.append("")
            unit2_lines.append("interface")
            unit2_lines.append("")
            unit2_lines.append("function Calculate(x, y: Integer): Integer;")
            unit2_lines.append("")
            unit2_lines.append("implementation")
            unit2_lines.append("")
            unit2_lines.append("function Calculate(x, y: Integer): Integer;")
            unit2_lines.append("begin")
            unit2_lines.append("  Result := x + y;")
            unit2_lines.append("end;")
            
            for i in range(12):
                var line_bytes = unit2_lines[i].as_bytes()
                var line_ptr = line_bytes.unsafe_ptr().bitcast[Int8]()
                _ = draw_text(line_ptr, right_start_x + 10.0, 160.0 + Float32(i) * 16.0, 9.0)
        
        # Draw tooltip
        if tooltip_visible:
            # Adjust tooltip position to stay within bounds
            var final_tooltip_x = tooltip_x
            var final_tooltip_y = tooltip_y
            if final_tooltip_x + tooltip_width > 1180.0:
                final_tooltip_x = 1180.0 - tooltip_width
            if final_tooltip_y + tooltip_height > 780.0:
                final_tooltip_y = tooltip_y - tooltip_height - 20.0
            
            # Draw tooltip background
            _ = set_color(1.0, 1.0, 0.88, 1.0)  # Light yellow
            _ = draw_filled_rectangle(final_tooltip_x, final_tooltip_y, tooltip_width, tooltip_height)
            
            # Draw tooltip border
            _ = set_color(0.5, 0.5, 0.5, 1.0)
            _ = draw_rectangle(final_tooltip_x, final_tooltip_y, tooltip_width, tooltip_height)
            
            # Draw tooltip text
            _ = set_color(0.0, 0.0, 0.0, 1.0)
            var tooltip_bytes = tooltip_text.as_bytes()
            var tooltip_ptr = tooltip_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(tooltip_ptr, final_tooltip_x + 6.0, final_tooltip_y + 5.0, 9.0)
        
        # Draw status bar
        _ = set_color(0.2, 0.2, 0.2, 1.0)
        _ = draw_filled_rectangle(0.0, 770.0, 1200.0, 30.0)
        
        _ = set_color(0.9, 0.9, 0.3, 1.0)
        var status_text = String("Ready | Mouse: (" + String(mouse_x) + "," + String(mouse_y) + ") | Splitter: " + String(Int32(splitter_x)))
        var status_bytes = status_text.as_bytes()
        var status_ptr = status_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(status_ptr, 10.0, 778.0, 10.0)
        
        # Draw cursor
        _ = set_color(1.0, 0.3, 0.3, 1.0)
        if hovering_splitter or dragging_splitter:
            # Resize cursor (horizontal)
            _ = draw_line(Float32(mouse_x) - 8.0, Float32(mouse_y), Float32(mouse_x) + 8.0, Float32(mouse_y), 2.0)
            _ = draw_line(Float32(mouse_x) - 8.0, Float32(mouse_y) - 2.0, Float32(mouse_x) - 5.0, Float32(mouse_y), 1.0)
            _ = draw_line(Float32(mouse_x) - 8.0, Float32(mouse_y) + 2.0, Float32(mouse_x) - 5.0, Float32(mouse_y), 1.0)
            _ = draw_line(Float32(mouse_x) + 8.0, Float32(mouse_y) - 2.0, Float32(mouse_x) + 5.0, Float32(mouse_y), 1.0)
            _ = draw_line(Float32(mouse_x) + 8.0, Float32(mouse_y) + 2.0, Float32(mouse_x) + 5.0, Float32(mouse_y), 1.0)
        else:
            # Normal cursor
            _ = draw_filled_circle(Float32(mouse_x), Float32(mouse_y), 3.0, 6)
        
        # End frame
        if frame_end() != 0:
            break
        
        # Status updates
        if frame_count % 180 == 0:
            var seconds = frame_count // 60
            print("🏗️  IDE demo running... Second", seconds)
    
    _ = cleanup_gl()
    
    print("")
    print("🎉 DELPHI-STYLE IDE DEMO FINISHED!")
    print("=====================================")
    print("✅ Demonstrated IDE features:")
    print("   📂 Split pane layout (resizable)")
    print("   📝 Multiple tab panels")
    print("   💬 Tooltips on tab hover") 
    print("   🖱️  Interactive splitter dragging")
    print("   🎨 Dark IDE theme")
    print("   📋 Project explorer simulation")
    print("   🔧 Code editor simulation")
    print("   🏗️  Form designer simulation")
    print("")
    print("🚀 Your IDE-style split tab widget is ready!")
    print("💡 Perfect for building development environments!")