#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("🎯 ENHANCED CHECKBOX DEMO - Round & Square with Colors!")
    print("=====================================================")
    
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
    var title = String("Enhanced Checkbox Demo - Round & Square Styles!")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    print("🚀 Opening enhanced checkbox demo...")
    var init_result = initialize_gl(800, 600, title_ptr)
    
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
    print("🎨 ENHANCED CHECKBOX FEATURES:")
    print("   ☑️  Square checkboxes with colored backgrounds")
    print("   🟢 Round checkboxes (radio-button style)")
    print("   🎯 Different check mark styles")
    print("   ✨ Hover effects")
    print("   🌈 Customizable colors")
    print("")
    print("🖱️  Click the checkboxes to test them!")
    
    # Checkbox states (simulating different checkbox types)
    var checkbox_states = List[Bool]()
    for i in range(8):
        checkbox_states.append(False)
    
    var frame_count: Int32 = 0
    var last_mouse_state: Bool = False
    
    print("🎮 Interactive checkbox demo running!")
    
    while should_close_window() == 0:
        # Poll events
        _ = poll_events()
        
        # Get mouse state
        var mouse_x = get_mouse_x()
        var mouse_y = get_mouse_y()
        var mouse_pressed = get_mouse_button_state(0) == 1
        
        # Handle checkbox interactions
        if mouse_pressed and not last_mouse_state:
            var mx = Float32(mouse_x)
            var my = Float32(mouse_y)
            
            # Check each checkbox area (50x30 each, spaced vertically)
            for i in range(8):
                var checkbox_y = 120.0 + Float32(i) * 50.0
                if mx >= 50.0 and mx <= 300.0 and my >= checkbox_y and my <= checkbox_y + 30.0:
                    checkbox_states[i] = not checkbox_states[i]
                    var checkbox_names = List[String]()
                    checkbox_names.append("Square Green")
                    checkbox_names.append("Square Blue") 
                    checkbox_names.append("Square Red")
                    checkbox_names.append("Square Purple")
                    checkbox_names.append("Round Green")
                    checkbox_names.append("Round Blue")
                    checkbox_names.append("Round Red")
                    checkbox_names.append("Round Orange")
                    print("☑️  Toggled", checkbox_names[i], "- Now:", checkbox_states[i])
        
        last_mouse_state = mouse_pressed
        frame_count += 1
        
        # Begin frame
        if frame_begin() != 0:
            break
        
        # Clear background (dark blue-gray)
        _ = set_color(0.12, 0.16, 0.2, 1.0)
        _ = draw_filled_rectangle(0.0, 0.0, 800.0, 600.0)
        
        # Draw title
        _ = set_color(1.0, 1.0, 1.0, 1.0)
        var main_title = String("ENHANCED CHECKBOX DEMO")
        var title_bytes2 = main_title.as_bytes()
        var title_ptr2 = title_bytes2.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(title_ptr2, 50.0, 30.0, 24.0)
        
        var subtitle = String("Square & Round Checkboxes with Custom Colors!")
        var subtitle_bytes = subtitle.as_bytes()
        var subtitle_ptr = subtitle_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(subtitle_ptr, 50.0, 65.0, 14.0)
        
        # Draw section label
        _ = set_color(0.9, 0.9, 0.6, 1.0)
        var section_label = String("Click to test different checkbox styles:")
        var section_bytes = section_label.as_bytes()
        var section_ptr = section_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(section_ptr, 50.0, 95.0, 14.0)
        
        # Checkbox configurations
        var checkbox_names = List[String]()
        checkbox_names.append("Square Green Filled")
        checkbox_names.append("Square Blue Filled")
        checkbox_names.append("Square Red Filled")
        checkbox_names.append("Square Purple Filled")
        checkbox_names.append("Round Green Filled")
        checkbox_names.append("Round Blue Filled")
        checkbox_names.append("Round Red Filled")
        checkbox_names.append("Round Orange Filled")
        
        var checkbox_x_pos = List[Int32]()
        var checkbox_y_pos = List[Int32]()
        var checkbox_is_round = List[Bool]()
        var checkbox_bg_colors = List[List[Int32]]()
        
        for i in range(8):
            checkbox_x_pos.append(50)
            checkbox_y_pos.append(120 + i * 50)
            checkbox_is_round.append(i >= 4)  # Round for indices 4-7
            
            var bg_color = List[Int32]()
            if i == 0:      # Green
                bg_color.append(50)
                bg_color.append(150)
                bg_color.append(50)
            elif i == 1:    # Blue
                bg_color.append(50)
                bg_color.append(100)
                bg_color.append(200)
            elif i == 2:    # Red
                bg_color.append(200)
                bg_color.append(50)
                bg_color.append(50)
            elif i == 3:    # Purple
                bg_color.append(150)
                bg_color.append(50)
                bg_color.append(150)
            elif i == 4:    # Round Green
                bg_color.append(50)
                bg_color.append(180)
                bg_color.append(50)
            elif i == 5:    # Round Blue
                bg_color.append(50)
                bg_color.append(120)
                bg_color.append(220)
            elif i == 6:    # Round Red
                bg_color.append(220)
                bg_color.append(50)
                bg_color.append(50)
            else:           # Round Orange
                bg_color.append(255)
                bg_color.append(140)
                bg_color.append(50)
            
            checkbox_bg_colors.append(bg_color)
        
        # Draw checkboxes
        for i in range(8):
            var checkbox_x = Float32(checkbox_x_pos[i])
            var checkbox_y = Float32(checkbox_y_pos[i])
            var is_round = checkbox_is_round[i]
            var is_checked = checkbox_states[i]
            
            # Check if mouse is hovering
            var mx = Float32(mouse_x)
            var my = Float32(mouse_y)
            var is_hovering = (mx >= checkbox_x and mx <= checkbox_x + 30.0 and 
                             my >= checkbox_y and my <= checkbox_y + 30.0)
            
            # Choose colors
            var bg_r: Float32
            var bg_g: Float32
            var bg_b: Float32
            
            if is_checked:
                # Use custom color when checked
                var bg_color = checkbox_bg_colors[i]
                bg_r = Float32(bg_color[0]) / 255.0
                bg_g = Float32(bg_color[1]) / 255.0
                bg_b = Float32(bg_color[2]) / 255.0
            elif is_hovering:
                # Light blue hover
                bg_r = 0.86
                bg_g = 0.86
                bg_b = 1.0
            else:
                # White background
                bg_r = 1.0
                bg_g = 1.0
                bg_b = 1.0
            
            # Draw checkbox background
            _ = set_color(bg_r, bg_g, bg_b, 1.0)
            
            if is_round:
                # Draw round checkbox
                _ = draw_filled_circle(checkbox_x + 15.0, checkbox_y + 15.0, 12.0, 16)
            else:
                # Draw square checkbox
                _ = draw_filled_rectangle(checkbox_x + 3.0, checkbox_y + 3.0, 24.0, 24.0)
            
            # Draw border
            _ = set_color(0.5, 0.5, 0.5, 1.0)
            if is_round:
                # Draw round border points
                var center_x = checkbox_x + 15.0
                var center_y = checkbox_y + 15.0
                _ = draw_filled_circle(center_x, center_y - 13.0, 1.0, 4)
                _ = draw_filled_circle(center_x + 13.0, center_y, 1.0, 4)
                _ = draw_filled_circle(center_x, center_y + 13.0, 1.0, 4)
                _ = draw_filled_circle(center_x - 13.0, center_y, 1.0, 4)
                _ = draw_filled_circle(center_x + 9.0, center_y - 9.0, 1.0, 4)
                _ = draw_filled_circle(center_x + 9.0, center_y + 9.0, 1.0, 4)
                _ = draw_filled_circle(center_x - 9.0, center_y + 9.0, 1.0, 4)
                _ = draw_filled_circle(center_x - 9.0, center_y - 9.0, 1.0, 4)
            else:
                _ = draw_rectangle(checkbox_x + 3.0, checkbox_y + 3.0, 24.0, 24.0)
            
            # Draw check mark if checked
            if is_checked:
                _ = set_color(1.0, 1.0, 1.0, 1.0)  # White check mark
                
                if is_round:
                    # Draw dot for round checkboxes
                    _ = draw_filled_circle(checkbox_x + 15.0, checkbox_y + 15.0, 6.0, 8)
                else:
                    # Draw checkmark for square checkboxes
                    # First line of checkmark
                    _ = draw_line(checkbox_x + 8.0, checkbox_y + 15.0, checkbox_x + 12.0, checkbox_y + 19.0, 2.0)
                    # Second line of checkmark
                    _ = draw_line(checkbox_x + 12.0, checkbox_y + 19.0, checkbox_x + 20.0, checkbox_y + 11.0, 2.0)
            
            # Draw label text
            _ = set_color(1.0, 1.0, 1.0, 1.0)
            var label_text = checkbox_names[i]
            var label_bytes = label_text.as_bytes()
            var label_ptr = label_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(label_ptr, checkbox_x + 35.0, checkbox_y + 8.0, 12.0)
        
        # Draw features summary
        _ = set_color(0.8, 0.9, 1.0, 1.0)
        var features_title = String("✨ ENHANCED CHECKBOX FEATURES:")
        var features_title_bytes = features_title.as_bytes()
        var features_title_ptr = features_title_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(features_title_ptr, 450.0, 120.0, 16.0)
        
        var features = List[String]()
        features.append("☑️ Square & Round Shapes")
        features.append("🎨 Custom Background Colors")
        features.append("✨ Hover Effects")
        features.append("🔍 High Visibility Check Marks")
        features.append("⚡ Smooth Interactions")
        features.append("🌈 Multiple Color Schemes")
        
        for i in range(6):
            var feature_bytes = features[i].as_bytes()
            var feature_ptr = feature_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(feature_ptr, 450.0, 150.0 + Float32(i) * 25.0, 12.0)
        
        # Draw live status
        _ = set_color(0.9, 0.9, 0.3, 1.0)
        var status_text = String("Mouse: (" + String(mouse_x) + "," + String(mouse_y) + ") Frame: " + String(frame_count))
        var status_bytes = status_text.as_bytes()
        var status_ptr = status_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(status_ptr, 50.0, 550.0, 10.0)
        
        # Draw mouse cursor
        _ = set_color(1.0, 0.3, 0.3, 1.0)
        _ = draw_filled_circle(Float32(mouse_x), Float32(mouse_y), 3.0, 6)
        
        # End frame
        if frame_end() != 0:
            break
        
        # Status updates
        if frame_count % 180 == 0:
            var seconds = frame_count // 60
            print("🎨 Enhanced checkbox demo running... Second", seconds)
    
    _ = cleanup_gl()
    
    print("")
    print("🎉 ENHANCED CHECKBOX DEMO FINISHED!")
    print("=======================================")
    print("✅ Demonstrated enhanced checkbox features:")
    print("   ☑️  Square checkboxes with filled backgrounds")
    print("   🟢 Round checkboxes (radio-button style)")
    print("   🎨 Custom colors (green, blue, red, purple, orange)")
    print("   ✨ Hover effects with color changes")
    print("   🔍 High-visibility check marks and dots")
    print("   ⚡ Smooth mouse interactions")
    print("")
    print("🚀 Your enhanced checkbox system is ready!")
    print("💡 Use different styles for different UI contexts!")