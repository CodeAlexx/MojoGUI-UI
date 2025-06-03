"""
TREEVIEW AND LISTVIEW DEMO
Comprehensive demonstration of TreeView and ListView widgets with file manager interface
"""

from sys.ffi import DLHandle
from memory import UnsafePointer

alias WINDOW_WIDTH = 1000
alias WINDOW_HEIGHT = 700

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

fn draw_treeview_mockup(lib: DLHandle, x: Int32, y: Int32, width: Int32, height: Int32, 
                       is_dark_mode: Bool, selected_folder: Int32):
    """Draw a mock TreeView showing file/folder structure."""
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    var draw_line = lib.get_function[fn(Int32, Int32, Int32, Int32, Int32) -> Int32]("draw_line")
    
    # Theme colors
    var bg_color = List[Int](25, 25, 35, 255) if is_dark_mode else List[Int](255, 255, 255, 255)
    var text_color = List[Int](240, 240, 250, 255) if is_dark_mode else List[Int](30, 30, 40, 255)
    var border_color = List[Int](80, 80, 100, 255) if is_dark_mode else List[Int](200, 200, 220, 255)
    var selection_bg = List[Int](70, 130, 180, 255)
    var folder_color = List[Int](255, 200, 0, 255)
    var file_color = List[Int](180, 180, 200, 255)
    
    # Background
    _ = set_color(bg_color[0], bg_color[1], bg_color[2], bg_color[3])
    _ = draw_filled_rectangle(x, y, width, height)
    
    # Border
    _ = set_color(border_color[0], border_color[1], border_color[2], border_color[3])
    _ = draw_rectangle(x, y, width, height)
    
    # Tree structure
    var tree_items = List[String]()
    tree_items.append("📁 Documents")
    tree_items.append("  📁 Projects")
    tree_items.append("    📁 MojoGUI")
    tree_items.append("      📄 main.mojo")
    tree_items.append("      📄 widgets.mojo")
    tree_items.append("    📁 WebApp")
    tree_items.append("      📄 index.html")
    tree_items.append("      📄 style.css")
    tree_items.append("  📁 Images")
    tree_items.append("    📄 screenshot.png")
    tree_items.append("    📄 logo.svg")
    tree_items.append("📁 Downloads")
    tree_items.append("  📄 archive.zip")
    tree_items.append("  📄 readme.txt")
    tree_items.append("📁 Desktop")
    
    var item_height = 24
    var current_y = y + 8
    
    for i in range(len(tree_items)):
        if current_y + item_height > y + height - 8:
            break
        
        # Selection highlight
        if i == Int(selected_folder):
            _ = set_color(selection_bg[0], selection_bg[1], selection_bg[2], selection_bg[3])
            _ = draw_filled_rectangle(x + 2, current_y - 2, width - 4, item_height)
        
        # Text color based on selection
        if i == Int(selected_folder):
            _ = set_color(255, 255, 255, 255)
        else:
            _ = set_color(text_color[0], text_color[1], text_color[2], text_color[3])
        
        # Draw tree item
        var item_ptr = null_terminated_string(tree_items[i])
        _ = draw_text(item_ptr, x + 8, current_y, 12)
        item_ptr.free()
        
        # Draw expand/collapse indicator for folders with children
        var indent_level = 0
        if tree_items[i].startswith("  "):
            indent_level = 1
        if tree_items[i].startswith("    "):
            indent_level = 2
        
        # Draw connection lines (simplified)
        if indent_level > 0:
            _ = set_color(100, 100, 120, 255)
            var line_x = x + 8 + (indent_level - 1) * 16
            _ = draw_line(line_x, current_y + 6, line_x + 12, current_y + 6, 1)
        
        current_y += item_height

fn draw_listview_mockup(lib: DLHandle, x: Int32, y: Int32, width: Int32, height: Int32,
                       is_dark_mode: Bool, selected_item: Int32):
    """Draw a mock ListView showing file details."""
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    
    # Theme colors
    var bg_color = List[Int](25, 25, 35, 255) if is_dark_mode else List[Int](255, 255, 255, 255)
    var header_color = List[Int](45, 45, 55, 255) if is_dark_mode else List[Int](245, 245, 245, 255)
    var text_color = List[Int](240, 240, 250, 255) if is_dark_mode else List[Int](30, 30, 40, 255)
    var border_color = List[Int](80, 80, 100, 255) if is_dark_mode else List[Int](200, 200, 220, 255)
    var selection_bg = List[Int](70, 130, 180, 255)
    var alt_row_color = List[Int](35, 35, 45, 255) if is_dark_mode else List[Int](248, 248, 250, 255)
    var grid_color = List[Int](60, 60, 80, 255) if is_dark_mode else List[Int](220, 220, 230, 255)
    
    # Background
    _ = set_color(bg_color[0], bg_color[1], bg_color[2], bg_color[3])
    _ = draw_filled_rectangle(x, y, width, height)
    
    # Header
    var header_height = 28
    _ = set_color(header_color[0], header_color[1], header_color[2], header_color[3])
    _ = draw_filled_rectangle(x, y, width, header_height)
    
    # Header text
    _ = set_color(text_color[0], text_color[1], text_color[2], text_color[3])
    var name_header = null_terminated_string("Name")
    _ = draw_text(name_header, x + 8, y + 8, 12)
    name_header.free()
    
    var size_header = null_terminated_string("Size")
    _ = draw_text(size_header, x + 180, y + 8, 12)
    size_header.free()
    
    var date_header = null_terminated_string("Modified")
    _ = draw_text(date_header, x + 260, y + 8, 12)
    date_header.free()
    
    var type_header = null_terminated_string("Type")
    _ = draw_text(type_header, x + 380, y + 8, 12)
    type_header.free()
    
    # Header border
    _ = set_color(border_color[0], border_color[1], border_color[2], border_color[3])
    _ = draw_filled_rectangle(x, y + header_height - 1, width, 1)
    
    # Column separators
    _ = draw_filled_rectangle(x + 175, y, 1, header_height)
    _ = draw_filled_rectangle(x + 255, y, 1, header_height)
    _ = draw_filled_rectangle(x + 375, y, 1, header_height)
    
    # File items data
    var file_names = List[String]()
    file_names.append("📄 main.mojo")
    file_names.append("📄 widgets.mojo")
    file_names.append("📄 theme_system.mojo")
    file_names.append("📄 rendering.mojo")
    file_names.append("📁 examples")
    file_names.append("📄 README.md")
    file_names.append("📄 LICENSE")
    file_names.append("📁 build")
    
    var file_sizes = List[String]()
    file_sizes.append("4.2 KB")
    file_sizes.append("12.8 KB")
    file_sizes.append("8.1 KB")
    file_sizes.append("15.3 KB")
    file_sizes.append("--")
    file_sizes.append("1.9 KB")
    file_sizes.append("1.1 KB")
    file_sizes.append("--")
    
    var file_dates = List[String]()
    file_dates.append("2025-06-03 14:30")
    file_dates.append("2025-06-03 13:45")
    file_dates.append("2025-06-03 12:15")
    file_dates.append("2025-06-02 16:20")
    file_dates.append("2025-06-02 15:10")
    file_dates.append("2025-06-01 09:30")
    file_dates.append("2025-05-30 11:45")
    file_dates.append("2025-06-03 14:00")
    
    var file_types = List[String]()
    file_types.append("Mojo File")
    file_types.append("Mojo File")
    file_types.append("Mojo File")
    file_types.append("Mojo File")
    file_types.append("Folder")
    file_types.append("Markdown")
    file_types.append("Text File")
    file_types.append("Folder")
    
    var item_height = 24
    var current_y = y + header_height + 2
    
    for i in range(len(file_names)):
        if current_y + item_height > y + height - 8:
            break
        
        # Alternating row colors
        var row_bg = bg_color
        if i % 2 == 1:
            row_bg = alt_row_color
        
        # Selection highlight
        if i == Int(selected_item):
            row_bg = selection_bg
        
        # Row background
        _ = set_color(row_bg[0], row_bg[1], row_bg[2], row_bg[3])
        _ = draw_filled_rectangle(x, current_y, width, item_height)
        
        # Text color based on selection
        if i == Int(selected_item):
            _ = set_color(255, 255, 255, 255)
        else:
            _ = set_color(text_color[0], text_color[1], text_color[2], text_color[3])
        
        # File name
        var name_ptr = null_terminated_string(file_names[i])
        _ = draw_text(name_ptr, x + 8, current_y + 6, 11)
        name_ptr.free()
        
        # File size
        var size_ptr = null_terminated_string(file_sizes[i])
        _ = draw_text(size_ptr, x + 180, current_y + 6, 11)
        size_ptr.free()
        
        # Modified date
        var date_ptr = null_terminated_string(file_dates[i])
        _ = draw_text(date_ptr, x + 260, current_y + 6, 11)
        date_ptr.free()
        
        # File type
        var type_ptr = null_terminated_string(file_types[i])
        _ = draw_text(type_ptr, x + 380, current_y + 6, 11)
        type_ptr.free()
        
        # Grid lines
        _ = set_color(grid_color[0], grid_color[1], grid_color[2], grid_color[3])
        _ = draw_filled_rectangle(x + 175, current_y, 1, item_height)
        _ = draw_filled_rectangle(x + 255, current_y, 1, item_height)
        _ = draw_filled_rectangle(x + 375, current_y, 1, item_height)
        _ = draw_filled_rectangle(x, current_y + item_height - 1, width, 1)
        
        current_y += item_height
    
    # Border
    _ = set_color(border_color[0], border_color[1], border_color[2], border_color[3])
    _ = draw_rectangle(x, y, width, height)

fn get_treeview_item_at_position(x: Int32, y: Int32, tree_x: Int32, tree_y: Int32, 
                                tree_width: Int32, tree_height: Int32) -> Int32:
    """Get which tree item was clicked."""
    if x < tree_x or x > tree_x + tree_width or y < tree_y or y > tree_y + tree_height:
        return -1
    
    var relative_y = y - tree_y - 8
    var item_index = relative_y / 24
    
    if item_index >= 0 and item_index < 15:  # We have 15 tree items
        return Int32(item_index)
    
    return -1

fn get_listview_item_at_position(x: Int32, y: Int32, list_x: Int32, list_y: Int32,
                                list_width: Int32, list_height: Int32) -> Int32:
    """Get which list item was clicked."""
    if x < list_x or x > list_x + list_width or y < list_y + 28 or y > list_y + list_height:
        return -1
    
    var relative_y = y - list_y - 28 - 2
    var item_index = relative_y / 24
    
    if item_index >= 0 and item_index < 8:  # We have 8 list items
        return Int32(item_index)
    
    return -1

fn main() raises:
    print("🌳 TREEVIEW AND LISTVIEW DEMO")
    print("File manager interface with TreeView (folders) and ListView (files)")
    
    var lib = DLHandle("./c_src/librendering_atlas.so")
    
    var init_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var title_ptr = null_terminated_string("TreeView & ListView Demo")
    
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
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    
    var get_system_dark_mode = lib.get_function[fn() -> Int32]("get_system_dark_mode")
    var get_cursor_pos = lib.get_function[fn(UnsafePointer[Float64], UnsafePointer[Float64]) -> Int32]("get_cursor_position")
    var get_mouse_button = lib.get_function[fn(Int32) -> Int32]("get_mouse_button_state")
    var get_key = lib.get_function[fn(Int32) -> Int32]("get_key_state")
    
    # Theme state
    var is_dark_mode = get_system_dark_mode() == 1
    var prev_key_d: Int32 = GLFW_RELEASE
    var prev_key_l: Int32 = GLFW_RELEASE
    
    # Widget state
    var selected_tree_item = 2  # MojoGUI folder selected by default
    var selected_list_item = 0  # First file selected by default
    var prev_mouse_left: Int32 = GLFW_RELEASE
    
    # Layout
    var tree_x = 20
    var tree_y = 80
    var tree_width = 280
    var tree_height = 550
    
    var list_x = 320
    var list_y = 80
    var list_width = 650
    var list_height = 550
    
    if is_dark_mode:
        print("🌙 Starting in DARK theme")
    else:
        print("☀️  Starting in LIGHT theme")
    
    print("✅ TreeView & ListView demo initialized")
    print("🖱️  Click tree items to navigate folders")
    print("🖱️  Click list items to select files")
    print("⌨️  Press L for light theme, D for dark theme")
    
    var frame_count = 0
    while should_close() == 0 and frame_count < 5400:  # 90 seconds
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
        
        # Handle mouse input
        var current_mouse_left = get_mouse_button(GLFW_MOUSE_BUTTON_LEFT)
        
        if prev_mouse_left == GLFW_RELEASE and current_mouse_left == GLFW_PRESS:
            # Check TreeView clicks
            var tree_item = get_treeview_item_at_position(mouse_x, mouse_y, tree_x, tree_y, tree_width, tree_height)
            if tree_item >= 0:
                selected_tree_item = Int(tree_item)
                print("🌳 Selected tree item: " + String(tree_item))
            
            # Check ListView clicks
            var list_item = get_listview_item_at_position(mouse_x, mouse_y, list_x, list_y, list_width, list_height)
            if list_item >= 0:
                selected_list_item = Int(list_item)
                print("📄 Selected list item: " + String(list_item))
        
        prev_mouse_left = current_mouse_left
        
        # Theme colors
        var bg_primary = List[Int](25, 25, 35, 255) if is_dark_mode else List[Int](240, 243, 246, 255)
        var text_primary = List[Int](240, 240, 250, 255) if is_dark_mode else List[Int](30, 30, 40, 255)
        var text_secondary = List[Int](180, 180, 200, 255) if is_dark_mode else List[Int](100, 100, 120, 255)
        
        # === RENDERING ===
        if frame_begin() != 0:
            break
        
        # Background
        _ = set_color(bg_primary[0], bg_primary[1], bg_primary[2], bg_primary[3])
        _ = draw_filled_rectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        
        # Title
        _ = set_color(text_primary[0], text_primary[1], text_primary[2], text_primary[3])
        var title = null_terminated_string("🌳 TreeView & ListView Demo - File Manager Interface")
        _ = draw_text(title, 20, 20, 24)
        title.free()
        
        # Theme indicator
        _ = set_color(text_secondary[0], text_secondary[1], text_secondary[2], text_secondary[3])
        var theme_name = "DARK THEME" if is_dark_mode else "LIGHT THEME"
        var theme_ptr = null_terminated_string("Current: " + theme_name + " | Press L/D to switch themes")
        _ = draw_text(theme_ptr, 20, 50, 14)
        theme_ptr.free()
        
        # Section labels
        _ = set_color(text_primary[0], text_primary[1], text_primary[2], text_primary[3])
        var tree_label = null_terminated_string("TreeView - Folder Navigation")
        _ = draw_text(tree_label, tree_x, tree_y - 25, 16)
        tree_label.free()
        
        var list_label = null_terminated_string("ListView - File Details")
        _ = draw_text(list_label, list_x, list_y - 25, 16)
        list_label.free()
        
        # Draw TreeView mockup
        draw_treeview_mockup(lib, tree_x, tree_y, tree_width, tree_height, is_dark_mode, Int32(selected_tree_item))
        
        # Draw ListView mockup
        draw_listview_mockup(lib, list_x, list_y, list_width, list_height, is_dark_mode, Int32(selected_list_item))
        
        # Status information
        _ = set_color(text_secondary[0], text_secondary[1], text_secondary[2], text_secondary[3])
        var status_text = "TreeView: Navigate folder structure | ListView: View file details with sorting"
        var status_ptr = null_terminated_string(status_text)
        _ = draw_text(status_ptr, 20, 650, 12)
        status_ptr.free()
        
        # Features list
        var features = List[String]()
        features.append("✅ TreeView: Hierarchical folder navigation with expand/collapse")
        features.append("✅ ListView: Multi-column file details with sortable headers")
        features.append("✅ Theme integration: Both widgets adapt to dark/light themes")
        features.append("✅ Selection handling: Visual feedback for selected items")
        features.append("✅ Grid lines: Professional data presentation")
        features.append("✅ Icons: Visual file type identification")
        
        var feature_y = 650
        for i in range(len(features)):
            if feature_y + 15 < WINDOW_HEIGHT - 10:
                var feature_ptr = null_terminated_string(features[i])
                _ = draw_text(feature_ptr, 20, feature_y + (i + 1) * 15, 11)
                feature_ptr.free()
        
        if frame_end() != 0:
            break
        
        frame_count += 1
    
    print("✅ TreeView & ListView demo completed!")
    _ = cleanup_gl()