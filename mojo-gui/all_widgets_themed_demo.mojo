"""
ALL WIDGETS THEMED DEMO
Comprehensive demonstration showing all major widgets using theme-based colors
"""

from sys.ffi import DLHandle
from memory import UnsafePointer

alias WINDOW_WIDTH = 1200
alias WINDOW_HEIGHT = 900

# GLFW constants
alias GLFW_MOUSE_BUTTON_LEFT = 0
alias GLFW_RELEASE = 0
alias GLFW_PRESS = 1

# Key codes
alias KEY_D = 68
alias KEY_L = 76
alias KEY_ESCAPE = 256

fn null_terminated_string(text: String) -> UnsafePointer[Int8]:
    var bytes = text.as_bytes()
    var buffer = UnsafePointer[Int8].alloc(len(bytes) + 1)
    for i in range(len(bytes)):
        buffer[i] = Int8(bytes[i])
    buffer[len(bytes)] = 0
    return buffer

fn draw_rounded_rect(lib: DLHandle, x: Int32, y: Int32, width: Int32, height: Int32, radius: Int32):
    """Draw a rounded rectangle using drawing primitives."""
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_filled_circle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_circle")
    
    # Main rectangle (without corners)
    _ = draw_filled_rectangle(x + radius, y, width - 2 * radius, height)
    _ = draw_filled_rectangle(x, y + radius, width, height - 2 * radius)
    
    # Corner circles
    _ = draw_filled_circle(x + radius, y + radius, radius, 12)
    _ = draw_filled_circle(x + width - radius, y + radius, radius, 12)
    _ = draw_filled_circle(x + radius, y + height - radius, radius, 12)
    _ = draw_filled_circle(x + width - radius, y + height - radius, radius, 12)

fn draw_widget_section(lib: DLHandle, x: Int32, y: Int32, width: Int32, height: Int32, 
                      bg_color: List[Int], border_color: List[Int], title: String, 
                      is_dark_mode: Bool):
    """Draw a widget section background."""
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    
    # Section background
    _ = set_color(bg_color[0], bg_color[1], bg_color[2], bg_color[3])
    draw_rounded_rect(lib, x, y, width, height, 8)
    
    # Section border
    _ = set_color(border_color[0], border_color[1], border_color[2], border_color[3])
    _ = draw_rectangle(x, y, width, height)
    
    # Section title
    var text_color = List[Int](30, 30, 40, 255) if not is_dark_mode else List[Int](240, 240, 250, 255)
    _ = set_color(text_color[0], text_color[1], text_color[2], text_color[3])
    var title_ptr = null_terminated_string(title)
    _ = draw_text(title_ptr, x + 10, y + 10, 14)
    title_ptr.free()

fn draw_button_widget(lib: DLHandle, x: Int32, y: Int32, width: Int32, height: Int32, 
                     text: String, button_type: Int, is_dark_mode: Bool, is_hover: Bool):
    """Draw a themed button widget."""
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    
    # Theme colors based on button type
    var bg_color: List[Int]
    var text_color: List[Int]
    var border_color: List[Int]
    
    if button_type == 0:  # Normal button
        if is_dark_mode:
            bg_color = List[Int](60, 60, 80, 255) if not is_hover else List[Int](80, 80, 100, 255)
            text_color = List[Int](240, 240, 250, 255)
            border_color = List[Int](100, 100, 120, 255)
        else:
            bg_color = List[Int](240, 240, 240, 255) if not is_hover else List[Int](230, 230, 230, 255)
            text_color = List[Int](30, 30, 40, 255)
            border_color = List[Int](180, 180, 200, 255)
    elif button_type == 1:  # Primary button
        bg_color = List[Int](70, 130, 180, 255) if not is_hover else List[Int](90, 145, 195, 255)
        text_color = List[Int](255, 255, 255, 255)
        border_color = List[Int](50, 110, 160, 255)
    elif button_type == 2:  # Success button
        bg_color = List[Int](50, 200, 80, 255) if not is_hover else List[Int](70, 220, 100, 255)
        text_color = List[Int](255, 255, 255, 255)
        border_color = List[Int](30, 180, 60, 255)
    else:  # Danger button
        bg_color = List[Int](230, 50, 50, 255) if not is_hover else List[Int](250, 70, 70, 255)
        text_color = List[Int](255, 255, 255, 255)
        border_color = List[Int](200, 30, 30, 255)
    
    # Draw button
    _ = set_color(bg_color[0], bg_color[1], bg_color[2], bg_color[3])
    _ = draw_filled_rectangle(x, y, width, height)
    
    _ = set_color(border_color[0], border_color[1], border_color[2], border_color[3])
    _ = draw_rectangle(x, y, width, height)
    
    # Draw text centered
    _ = set_color(text_color[0], text_color[1], text_color[2], text_color[3])
    var text_ptr = null_terminated_string(text)
    var text_x = x + (width - Int(len(text) * 7)) / 2  # Approximate centering
    var text_y = y + (height - 12) / 2
    _ = draw_text(text_ptr, text_x, text_y, 12)
    text_ptr.free()

fn draw_checkbox_widget(lib: DLHandle, x: Int32, y: Int32, text: String, checked: Bool, is_dark_mode: Bool):
    """Draw a themed checkbox widget."""
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    var draw_line = lib.get_function[fn(Int32, Int32, Int32, Int32, Int32) -> Int32]("draw_line")
    
    var box_size = 18
    var text_color = List[Int](30, 30, 40, 255) if not is_dark_mode else List[Int](240, 240, 250, 255)
    var bg_color = List[Int](255, 255, 255, 255) if not is_dark_mode else List[Int](60, 60, 80, 255)
    var border_color = List[Int](180, 180, 200, 255) if not is_dark_mode else List[Int](100, 100, 120, 255)
    var check_bg_color = List[Int](70, 130, 180, 255)
    var check_color = List[Int](255, 255, 255, 255)
    
    # Draw checkbox background
    if checked:
        _ = set_color(check_bg_color[0], check_bg_color[1], check_bg_color[2], check_bg_color[3])
    else:
        _ = set_color(bg_color[0], bg_color[1], bg_color[2], bg_color[3])
    _ = draw_filled_rectangle(x, y, box_size, box_size)
    
    # Draw border
    _ = set_color(border_color[0], border_color[1], border_color[2], border_color[3])
    _ = draw_rectangle(x, y, box_size, box_size)
    
    # Draw checkmark if checked
    if checked:
        _ = set_color(check_color[0], check_color[1], check_color[2], check_color[3])
        _ = draw_line(x + 4, y + 9, x + 8, y + 13, 2)
        _ = draw_line(x + 8, y + 13, x + 14, y + 5, 2)
    
    # Draw text
    _ = set_color(text_color[0], text_color[1], text_color[2], text_color[3])
    var text_ptr = null_terminated_string(text)
    _ = draw_text(text_ptr, x + box_size + 8, y + 2, 12)
    text_ptr.free()

fn draw_progress_bar(lib: DLHandle, x: Int32, y: Int32, width: Int32, height: Int32, 
                    progress: Int, is_dark_mode: Bool):
    """Draw a themed progress bar."""
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    
    var track_color = List[Int](220, 220, 220, 255) if not is_dark_mode else List[Int](60, 60, 80, 255)
    var fill_color = List[Int](50, 200, 80, 255)
    var border_color = List[Int](180, 180, 200, 255) if not is_dark_mode else List[Int](100, 100, 120, 255)
    var text_color = List[Int](30, 30, 40, 255) if not is_dark_mode else List[Int](240, 240, 250, 255)
    
    # Draw track
    _ = set_color(track_color[0], track_color[1], track_color[2], track_color[3])
    _ = draw_filled_rectangle(x, y, width, height)
    
    # Draw progress fill
    var fill_width = (width * progress) / 100
    _ = set_color(fill_color[0], fill_color[1], fill_color[2], fill_color[3])
    _ = draw_filled_rectangle(x, y, fill_width, height)
    
    # Draw border
    _ = set_color(border_color[0], border_color[1], border_color[2], border_color[3])
    _ = draw_rectangle(x, y, width, height)
    
    # Draw percentage text
    _ = set_color(text_color[0], text_color[1], text_color[2], text_color[3])
    var percent_text = String(progress) + "%"
    var percent_ptr = null_terminated_string(percent_text)
    var text_x = x + (width - Int(len(percent_text) * 7)) / 2
    var text_y = y + (height - 12) / 2
    _ = draw_text(percent_ptr, text_x, text_y, 11)
    percent_ptr.free()

fn draw_text_field(lib: DLHandle, x: Int32, y: Int32, width: Int32, height: Int32, 
                  text: String, placeholder: String, has_focus: Bool, is_dark_mode: Bool):
    """Draw a themed text field."""
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    var draw_line = lib.get_function[fn(Int32, Int32, Int32, Int32, Int32) -> Int32]("draw_line")
    
    var bg_color = List[Int](255, 255, 255, 255) if not is_dark_mode else List[Int](50, 50, 70, 255)
    var text_color = List[Int](30, 30, 40, 255) if not is_dark_mode else List[Int](240, 240, 250, 255)
    var placeholder_color = List[Int](150, 150, 170, 255) if not is_dark_mode else List[Int](120, 120, 140, 255)
    var border_color = List[Int](70, 130, 180, 255) if has_focus else (List[Int](180, 180, 200, 255) if not is_dark_mode else List[Int](100, 100, 120, 255))
    
    # Draw background
    _ = set_color(bg_color[0], bg_color[1], bg_color[2], bg_color[3])
    _ = draw_filled_rectangle(x, y, width, height)
    
    # Draw border (thicker if focused)
    var border_width = 2 if has_focus else 1
    _ = set_color(border_color[0], border_color[1], border_color[2], border_color[3])
    for i in range(border_width):
        _ = draw_rectangle(x - i, y - i, width + 2*i, height + 2*i)
    
    # Draw text or placeholder
    var display_text = text if len(text) > 0 else placeholder
    var color_to_use = text_color if len(text) > 0 else placeholder_color
    _ = set_color(color_to_use[0], color_to_use[1], color_to_use[2], color_to_use[3])
    var display_ptr = null_terminated_string(display_text)
    _ = draw_text(display_ptr, x + 8, y + (height - 12) / 2, 12)
    display_ptr.free()
    
    # Draw cursor if focused and has text
    if has_focus and len(text) > 0:
        var cursor_x = x + 8 + Int(len(text) * 7)  # Approximate text width
        _ = set_color(text_color[0], text_color[1], text_color[2], text_color[3])
        _ = draw_line(cursor_x, y + 4, cursor_x, y + height - 4, 1)

fn main() raises:
    print("🎨 ALL WIDGETS THEMED DEMO")
    print("Comprehensive demonstration of all themed widgets")
    
    var lib = DLHandle("./c_src/librendering_atlas.so")
    
    var init_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var title_ptr = null_terminated_string("All Widgets Themed Demo")
    
    if init_gl(WINDOW_WIDTH, WINDOW_HEIGHT, title_ptr) != 0:
        print("❌ Failed to initialize")
        title_ptr.free()
        return
    title_ptr.free()
    
    var load_font = lib.get_function[fn() -> Int32]("load_default_font")
    _ = load_font()
    
    var frame_begin = lib.get_function[fn() -> Int32]("frame_begin")
    var frame_end = lib.get_function[fn() -> Int32]("frame_end")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close = lib.get_function[fn() -> Int32]("should_close_window")
    var cleanup_gl = lib.get_function[fn() -> Int32]("cleanup_gl")
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    
    # Check for system theme preference
    var get_system_dark_mode = lib.get_function[fn() -> Int32]("get_system_dark_mode")
    var get_cursor_pos = lib.get_function[fn(UnsafePointer[Float64], UnsafePointer[Float64]) -> Int32]("get_cursor_position")
    var get_mouse_button = lib.get_function[fn(Int32) -> Int32]("get_mouse_button_state")
    var get_key = lib.get_function[fn(Int32) -> Int32]("get_key_state")
    
    # Theme state
    var is_dark_mode = get_system_dark_mode() == 1
    var prev_key_d: Int32 = GLFW_RELEASE
    var prev_key_l: Int32 = GLFW_RELEASE
    
    # Demo state
    var checkbox_states = List[Bool]()
    checkbox_states.append(True)
    checkbox_states.append(False)
    checkbox_states.append(True)
    
    var progress_values = List[Int]()
    progress_values.append(75)
    progress_values.append(45)
    progress_values.append(90)
    
    var button_hover_states = List[Bool]()
    for i in range(8):
        button_hover_states.append(False)
    
    var text_field_focus = 0  # Which text field has focus (-1 = none)
    var text_field_values = List[String]()
    text_field_values.append("Sample text")
    text_field_values.append("")
    text_field_values.append("username@example.com")
    
    if is_dark_mode:
        print("🌙 Starting in DARK theme (system preference)")
    else:
        print("☀️  Starting in LIGHT theme (system preference)")
    
    print("✅ All widgets demo initialized")
    print("🎨 Press L for light theme, D for dark theme")
    
    var frame_count = 0
    while should_close() == 0 and frame_count < 7200:  # 2 minutes
        _ = poll_events()
        
        # Get mouse position
        var mx_ptr = UnsafePointer[Float64].alloc(1)
        var my_ptr = UnsafePointer[Float64].alloc(1)
        _ = get_cursor_pos(mx_ptr, my_ptr)
        var mouse_x = Int32(mx_ptr[0])
        var mouse_y = Int32(my_ptr[0])
        mx_ptr.free()
        my_ptr.free()
        
        # Theme switching
        var current_key_l = get_key(KEY_L)
        var current_key_d = get_key(KEY_D)
        
        if prev_key_l == GLFW_RELEASE and current_key_l == GLFW_PRESS:
            is_dark_mode = False
            print("☀️  Switched to LIGHT theme")
        prev_key_l = current_key_l
        
        if prev_key_d == GLFW_RELEASE and current_key_d == GLFW_PRESS:
            is_dark_mode = True
            print("🌙 Switched to DARK theme")
        prev_key_d = current_key_d
        
        # Update button hover states
        for i in range(len(button_hover_states)):
            button_hover_states[i] = False
        
        # Check button hovers (simplified)
        if mouse_x >= 40 and mouse_x <= 140 and mouse_y >= 80 and mouse_y <= 110:
            button_hover_states[0] = True
        elif mouse_x >= 160 and mouse_x <= 260 and mouse_y >= 80 and mouse_y <= 110:
            button_hover_states[1] = True
        # Add more button hover checks as needed...
        
        # Update progress bars (animate them)
        for i in range(len(progress_values)):
            progress_values[i] = (progress_values[i] + 1) % 101
        
        # Theme colors
        var bg_primary: List[Int]
        var bg_surface: List[Int]
        var border_primary: List[Int]
        var text_primary: List[Int]
        var text_secondary: List[Int]
        
        if is_dark_mode:
            bg_primary = List[Int](25, 25, 35, 255)
            bg_surface = List[Int](45, 45, 55, 255)
            border_primary = List[Int](80, 80, 100, 255)
            text_primary = List[Int](240, 240, 250, 255)
            text_secondary = List[Int](180, 180, 200, 255)
        else:
            bg_primary = List[Int](240, 243, 246, 255)
            bg_surface = List[Int](255, 255, 255, 255)
            border_primary = List[Int](200, 200, 220, 255)
            text_primary = List[Int](30, 30, 40, 255)
            text_secondary = List[Int](100, 100, 120, 255)
        
        # === RENDERING ===
        if frame_begin() != 0:
            break
        
        # Background
        _ = set_color(bg_primary[0], bg_primary[1], bg_primary[2], bg_primary[3])
        _ = draw_filled_rectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        
        # Title
        _ = set_color(text_primary[0], text_primary[1], text_primary[2], text_primary[3])
        var title = null_terminated_string("🎨 All Widgets Themed Demo")
        _ = draw_text(title, 40, 20, 24)
        title.free()
        
        # Theme indicator
        _ = set_color(text_secondary[0], text_secondary[1], text_secondary[2], text_secondary[3])
        var theme_name = "DARK THEME" if is_dark_mode else "LIGHT THEME"
        var theme_ptr = null_terminated_string("Current: " + theme_name + " (Press L/D to switch)")
        _ = draw_text(theme_ptr, 40, 50, 14)
        theme_ptr.free()
        
        # BUTTONS SECTION
        draw_widget_section(lib, 30, 70, 320, 160, bg_surface, border_primary, "Buttons", is_dark_mode)
        
        # Different button types
        draw_button_widget(lib, 40, 100, 100, 30, "Normal", 0, is_dark_mode, button_hover_states[0])
        draw_button_widget(lib, 160, 100, 100, 30, "Primary", 1, is_dark_mode, button_hover_states[1])
        draw_button_widget(lib, 280, 100, 60, 30, "Small", 0, is_dark_mode, button_hover_states[2])
        draw_button_widget(lib, 40, 140, 100, 30, "Success", 2, is_dark_mode, button_hover_states[3])
        draw_button_widget(lib, 160, 140, 100, 30, "Danger", 3, is_dark_mode, button_hover_states[4])
        draw_button_widget(lib, 280, 140, 60, 30, "Mini", 0, is_dark_mode, button_hover_states[5])
        
        # Add more buttons
        draw_button_widget(lib, 40, 180, 80, 25, "Compact", 0, is_dark_mode, button_hover_states[6])
        draw_button_widget(lib, 140, 180, 120, 25, "Wide Button", 1, is_dark_mode, button_hover_states[7])
        
        # CHECKBOXES SECTION
        draw_widget_section(lib, 370, 70, 200, 160, bg_surface, border_primary, "Checkboxes", is_dark_mode)
        
        draw_checkbox_widget(lib, 380, 100, "Enable notifications", checkbox_states[0], is_dark_mode)
        draw_checkbox_widget(lib, 380, 130, "Dark mode", checkbox_states[1], is_dark_mode)
        draw_checkbox_widget(lib, 380, 160, "Auto-save", checkbox_states[2], is_dark_mode)
        draw_checkbox_widget(lib, 380, 190, "Show tooltips", True, is_dark_mode)
        
        # PROGRESS BARS SECTION
        draw_widget_section(lib, 590, 70, 280, 160, bg_surface, border_primary, "Progress Bars", is_dark_mode)
        
        # Different progress bars
        draw_progress_bar(lib, 600, 100, 200, 20, progress_values[0], is_dark_mode)
        draw_progress_bar(lib, 600, 130, 150, 15, progress_values[1], is_dark_mode)
        draw_progress_bar(lib, 600, 155, 250, 25, progress_values[2], is_dark_mode)
        
        # Add labels for progress bars
        _ = set_color(text_secondary[0], text_secondary[1], text_secondary[2], text_secondary[3])
        var pb1_label = null_terminated_string("Download Progress")
        _ = draw_text(pb1_label, 810, 105, 11)
        pb1_label.free()
        
        var pb2_label = null_terminated_string("Loading")
        _ = draw_text(pb2_label, 760, 133, 11)
        pb2_label.free()
        
        var pb3_label = null_terminated_string("Installation")
        _ = draw_text(pb3_label, 860, 163, 11)
        pb3_label.free()
        
        # TEXT FIELDS SECTION
        draw_widget_section(lib, 30, 250, 400, 180, bg_surface, border_primary, "Text Fields", is_dark_mode)
        
        draw_text_field(lib, 40, 280, 200, 30, text_field_values[0], "Enter text...", text_field_focus == 0, is_dark_mode)
        draw_text_field(lib, 40, 320, 300, 35, text_field_values[1], "Search...", text_field_focus == 1, is_dark_mode)
        draw_text_field(lib, 40, 365, 250, 30, text_field_values[2], "Email address", text_field_focus == 2, is_dark_mode)
        draw_text_field(lib, 40, 400, 150, 25, "", "Password", text_field_focus == 3, is_dark_mode)
        
        # SLIDERS & LISTS SECTION
        draw_widget_section(lib, 450, 250, 350, 180, bg_surface, border_primary, "Sliders & Lists", is_dark_mode)
        
        # Simulate sliders
        var slider_bg = List[Int](220, 220, 220, 255) if not is_dark_mode else List[Int](60, 60, 80, 255)
        var slider_fill = List[Int](70, 130, 180, 255)
        var slider_thumb = List[Int](70, 130, 180, 255)
        
        # Horizontal slider
        _ = set_color(slider_bg[0], slider_bg[1], slider_bg[2], slider_bg[3])
        _ = draw_filled_rectangle(460, 285, 200, 8)
        
        var slider1_pos = Int32((frame_count / 2) % 200)
        _ = set_color(slider_fill[0], slider_fill[1], slider_fill[2], slider_fill[3])
        _ = draw_filled_rectangle(460, 285, slider1_pos, 8)
        _ = draw_filled_rectangle(460 + slider1_pos - 6, 280, 12, 18)
        
        # Volume slider
        _ = set_color(slider_bg[0], slider_bg[1], slider_bg[2], slider_bg[3])
        _ = draw_filled_rectangle(460, 320, 150, 6)
        
        var slider2_pos = Int32((frame_count / 3) % 150)
        _ = set_color(slider_fill[0], slider_fill[1], slider_fill[2], slider_fill[3])
        _ = draw_filled_rectangle(460, 320, slider2_pos, 6)
        _ = draw_filled_rectangle(460 + slider2_pos - 5, 317, 10, 12)
        
        # List box simulation
        var list_bg = bg_surface
        var list_border = border_primary
        var selection_bg = List[Int](70, 130, 180, 255)
        var selection_text = List[Int](255, 255, 255, 255)
        
        _ = set_color(list_bg[0], list_bg[1], list_bg[2], list_bg[3])
        _ = draw_filled_rectangle(460, 350, 200, 70)
        _ = set_color(list_border[0], list_border[1], list_border[2], list_border[3])
        _ = draw_rectangle(460, 350, 200, 70)
        
        # List items
        var list_items = List[String]()
        list_items.append("Item 1")
        list_items.append("Item 2 (selected)")
        list_items.append("Item 3")
        list_items.append("Item 4")
        
        for i in range(len(list_items)):
            var item_y = 355 + i * 16
            if i == 1:  # Selected item
                _ = set_color(selection_bg[0], selection_bg[1], selection_bg[2], selection_bg[3])
                _ = draw_filled_rectangle(462, item_y - 1, 196, 16)
                _ = set_color(selection_text[0], selection_text[1], selection_text[2], selection_text[3])
            else:
                _ = set_color(text_primary[0], text_primary[1], text_primary[2], text_primary[3])
            
            var item_ptr = null_terminated_string(list_items[i])
            _ = draw_text(item_ptr, 468, item_y, 11)
            item_ptr.free()
        
        # MENU SIMULATION SECTION
        draw_widget_section(lib, 30, 450, 840, 120, bg_surface, border_primary, "Menus & Navigation", is_dark_mode)
        
        # Menu bar
        var menu_bg = List[Int](50, 50, 70, 255) if is_dark_mode else List[Int](245, 245, 245, 255)
        _ = set_color(menu_bg[0], menu_bg[1], menu_bg[2], menu_bg[3])
        _ = draw_filled_rectangle(40, 480, 780, 30)
        
        # Menu items
        var menu_items = List[String]()
        menu_items.append("File")
        menu_items.append("Edit")
        menu_items.append("View")
        menu_items.append("Tools")
        menu_items.append("Help")
        
        var menu_x = 50
        for i in range(len(menu_items)):
            var item_width = len(menu_items[i]) * 8 + 20
            
            if i == 1:  # Highlight "Edit" menu
                var highlight_bg = List[Int](70, 130, 180, 255)
                _ = set_color(highlight_bg[0], highlight_bg[1], highlight_bg[2], highlight_bg[3])
                _ = draw_filled_rectangle(menu_x, 480, item_width, 30)
                _ = set_color(255, 255, 255, 255)
            else:
                _ = set_color(text_primary[0], text_primary[1], text_primary[2], text_primary[3])
            
            var menu_item_ptr = null_terminated_string(menu_items[i])
            _ = draw_text(menu_item_ptr, menu_x + 10, 488, 12)
            menu_item_ptr.free()
            menu_x += item_width
        
        # Dropdown menu for "Edit"
        var dropdown_bg = List[Int](60, 60, 80, 255) if is_dark_mode else List[Int](255, 255, 255, 255)
        var dropdown_border = List[Int](100, 100, 120, 255) if is_dark_mode else List[Int](180, 180, 200, 255)
        
        _ = set_color(dropdown_bg[0], dropdown_bg[1], dropdown_bg[2], dropdown_bg[3])
        _ = draw_filled_rectangle(90, 510, 120, 80)
        _ = set_color(dropdown_border[0], dropdown_border[1], dropdown_border[2], dropdown_border[3])
        _ = draw_rectangle(90, 510, 120, 80)
        
        var dropdown_items = List[String]()
        dropdown_items.append("Undo")
        dropdown_items.append("Redo")
        dropdown_items.append("Cut")
        dropdown_items.append("Copy")
        dropdown_items.append("Paste")
        
        for i in range(len(dropdown_items)):
            var item_y = 518 + i * 14
            if i == 2:  # Highlight "Cut"
                var item_highlight = List[Int](70, 130, 180, 255)
                _ = set_color(item_highlight[0], item_highlight[1], item_highlight[2], item_highlight[3])
                _ = draw_filled_rectangle(92, item_y - 1, 116, 14)
                _ = set_color(255, 255, 255, 255)
            else:
                _ = set_color(text_primary[0], text_primary[1], text_primary[2], text_primary[3])
            
            var dropdown_item_ptr = null_terminated_string(dropdown_items[i])
            _ = draw_text(dropdown_item_ptr, 98, item_y, 11)
            dropdown_item_ptr.free()
        
        # STATUS & INFO SECTION
        draw_widget_section(lib, 30, 590, 840, 80, bg_surface, border_primary, "Status & Information", is_dark_mode)
        
        # Status bar
        var status_bg = List[Int](40, 40, 60, 255) if is_dark_mode else List[Int](250, 250, 250, 255)
        _ = set_color(status_bg[0], status_bg[1], status_bg[2], status_bg[3])
        _ = draw_filled_rectangle(40, 620, 820, 25)
        _ = set_color(border_primary[0], border_primary[1], border_primary[2], border_primary[3])
        _ = draw_rectangle(40, 620, 820, 25)
        
        # Status text
        _ = set_color(text_primary[0], text_primary[1], text_primary[2], text_primary[3])
        var status_text = null_terminated_string("Ready | 23 widgets loaded | Theme: " + theme_name)
        _ = draw_text(status_text, 50, 628, 11)
        status_text.free()
        
        # Info badges
        var info_bg = List[Int](70, 130, 180, 255)
        var success_bg = List[Int](50, 200, 80, 255)
        var warning_bg = List[Int](255, 150, 50, 255)
        
        _ = set_color(info_bg[0], info_bg[1], info_bg[2], info_bg[3])
        _ = draw_filled_rectangle(600, 625, 60, 15)
        _ = set_color(255, 255, 255, 255)
        var info_label = null_terminated_string("INFO")
        _ = draw_text(info_label, 618, 628, 9)
        info_label.free()
        
        _ = set_color(success_bg[0], success_bg[1], success_bg[2], success_bg[3])
        _ = draw_filled_rectangle(670, 625, 80, 15)
        _ = set_color(255, 255, 255, 255)
        var success_label = null_terminated_string("SUCCESS")
        _ = draw_text(success_label, 683, 628, 9)
        success_label.free()
        
        _ = set_color(warning_bg[0], warning_bg[1], warning_bg[2], warning_bg[3])
        _ = draw_filled_rectangle(760, 625, 80, 15)
        _ = set_color(255, 255, 255, 255)
        var warning_label = null_terminated_string("WARNING")
        _ = draw_text(warning_label, 770, 628, 9)
        warning_label.free()
        
        # Instructions
        _ = set_color(text_secondary[0], text_secondary[1], text_secondary[2], text_secondary[3])
        var instructions = null_terminated_string("Press L for Light theme, D for Dark theme • All widgets now use theme-based colors!")
        _ = draw_text(instructions, 40, 680, 12)
        instructions.free()
        
        # Demo stats
        var stats = null_terminated_string("Frames: " + String(frame_count) + " | Animated Progress Bars | Hover Effects Simulated")
        _ = draw_text(stats, 40, 700, 10)
        stats.free()
        
        if frame_end() != 0:
            break
        
        frame_count += 1
    
    print("✅ All widgets themed demo completed!")
    _ = cleanup_gl()