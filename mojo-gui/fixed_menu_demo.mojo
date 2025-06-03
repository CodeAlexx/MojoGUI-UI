"""
FIXED MENU DEMO
Menu system with SOLID opaque dropdown backgrounds that completely cover content underneath
"""

from sys.ffi import DLHandle
from memory import UnsafePointer

alias WINDOW_WIDTH = 800
alias WINDOW_HEIGHT = 600

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

fn draw_menu_bar(lib: DLHandle, x: Int32, y: Int32, width: Int32, height: Int32, 
                menu_items: List[String], selected_menu: Int, is_dark_mode: Bool):
    """Draw the menu bar."""
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    
    # Menu bar colors
    var bg_color = List[Int](50, 50, 70, 255) if is_dark_mode else List[Int](245, 245, 245, 255)
    var text_color = List[Int](240, 240, 250, 255) if is_dark_mode else List[Int](30, 30, 40, 255)
    var selected_bg = List[Int](70, 130, 180, 255)
    var selected_text = List[Int](255, 255, 255, 255)
    var border_color = List[Int](80, 80, 100, 255) if is_dark_mode else List[Int](200, 200, 220, 255)
    
    # Draw menu bar background - COMPLETELY OPAQUE
    _ = set_color(bg_color[0], bg_color[1], bg_color[2], 255)
    _ = draw_filled_rectangle(x, y, width, height)
    
    # Draw bottom border
    _ = set_color(border_color[0], border_color[1], border_color[2], 255)
    _ = draw_filled_rectangle(x, y + height - 1, width, 1)
    
    # Draw menu items
    var current_x = x + 10
    for i in range(len(menu_items)):
        var item_width = len(menu_items[i]) * 8 + 20
        
        # Highlight selected menu
        if i == selected_menu:
            _ = set_color(selected_bg[0], selected_bg[1], selected_bg[2], 255)
            _ = draw_filled_rectangle(current_x - 5, y + 2, item_width, height - 4)
            _ = set_color(selected_text[0], selected_text[1], selected_text[2], 255)
        else:
            _ = set_color(text_color[0], text_color[1], text_color[2], 255)
        
        var item_ptr = null_terminated_string(menu_items[i])
        _ = draw_text(item_ptr, current_x + 5, y + 8, 12)
        item_ptr.free()
        
        current_x += item_width + 5

fn draw_solid_dropdown_menu(lib: DLHandle, x: Int32, y: Int32, width: Int32, 
                           menu_items: List[String], selected_item: Int, is_dark_mode: Bool):
    """Draw a dropdown menu with COMPLETELY SOLID background that covers everything underneath."""
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    
    # SOLID, OPAQUE colors - NO transparency anywhere!
    var bg_color = List[Int](60, 60, 80, 255) if is_dark_mode else List[Int](255, 255, 255, 255)
    var text_color = List[Int](240, 240, 250, 255) if is_dark_mode else List[Int](30, 30, 40, 255)
    var border_color = List[Int](100, 100, 120, 255) if is_dark_mode else List[Int](120, 120, 140, 255)
    var hover_bg = List[Int](90, 120, 180, 255) if is_dark_mode else List[Int](220, 235, 255, 255)
    var hover_text = List[Int](255, 255, 255, 255) if is_dark_mode else List[Int](20, 20, 30, 255)
    var separator_color = List[Int](120, 120, 140, 255) if is_dark_mode else List[Int](200, 200, 210, 255)
    
    var menu_height = len(menu_items) * 22 + 8
    
    # Step 1: CLEAR THE BACKGROUND AREA FIRST with solid color
    # This ensures we completely overwrite anything that was there before
    _ = set_color(bg_color[0], bg_color[1], bg_color[2], 255)
    _ = draw_filled_rectangle(x - 2, y - 2, width + 4, menu_height + 4)
    
    # Step 2: Draw shadow BEFORE main menu (so menu appears on top)
    _ = set_color(0, 0, 0, 100)
    _ = draw_filled_rectangle(x + 3, y + 3, width, menu_height)
    
    # Step 3: Draw SOLID menu background - MULTIPLE layers for complete coverage
    _ = set_color(bg_color[0], bg_color[1], bg_color[2], 255)
    _ = draw_filled_rectangle(x - 1, y - 1, width + 2, menu_height + 2)  # Slightly larger
    _ = draw_filled_rectangle(x, y, width, menu_height)                   # Exact size
    _ = draw_filled_rectangle(x + 1, y + 1, width - 2, menu_height - 2)  # Slightly smaller
    
    # Step 4: Strong border for definition
    _ = set_color(border_color[0], border_color[1], border_color[2], 255)
    _ = draw_rectangle(x, y, width, menu_height)
    _ = draw_rectangle(x - 1, y - 1, width + 2, menu_height + 2)
    
    # Step 5: Draw menu items with SOLID backgrounds
    for i in range(len(menu_items)):
        var item_y = y + 4 + i * 22
        
        # Check if this is a separator
        if menu_items[i] == "----":
            # Draw separator line
            _ = set_color(separator_color[0], separator_color[1], separator_color[2], 255)
            _ = draw_filled_rectangle(x + 8, item_y + 10, width - 16, 1)
        else:
            # Highlight hovered item with SOLID background
            if i == selected_item:
                _ = set_color(hover_bg[0], hover_bg[1], hover_bg[2], 255)  # COMPLETELY OPAQUE
                _ = draw_filled_rectangle(x + 2, item_y - 1, width - 4, 22)
                _ = set_color(hover_text[0], hover_text[1], hover_text[2], 255)
            else:
                # Ensure background is solid even for non-hovered items
                _ = set_color(bg_color[0], bg_color[1], bg_color[2], 255)
                _ = draw_filled_rectangle(x + 2, item_y - 1, width - 4, 22)
                _ = set_color(text_color[0], text_color[1], text_color[2], 255)
            
            # Draw menu item text
            var item_ptr = null_terminated_string(menu_items[i])
            _ = draw_text(item_ptr, x + 12, item_y + 4, 11)
            item_ptr.free()

fn get_menu_item_at_position(menu_items: List[String], menu_x: Int32, menu_y: Int32, 
                            mouse_x: Int32, mouse_y: Int32) -> Int:
    """Get which menu item is at the mouse position (-1 if none)."""
    var current_x = menu_x + 10
    for i in range(len(menu_items)):
        var item_width = len(menu_items[i]) * 8 + 20
        if mouse_x >= current_x - 5 and mouse_x < current_x + item_width and 
           mouse_y >= menu_y and mouse_y < menu_y + 30:
            return i
        current_x += item_width + 5
    return -1

fn get_dropdown_item_at_position(menu_items: List[String], dropdown_x: Int32, dropdown_y: Int32, 
                                dropdown_width: Int32, mouse_x: Int32, mouse_y: Int32) -> Int:
    """Get which dropdown item is at the mouse position (-1 if none)."""
    var menu_height = len(menu_items) * 22 + 8
    if mouse_x >= dropdown_x and mouse_x < dropdown_x + dropdown_width and 
       mouse_y >= dropdown_y and mouse_y < dropdown_y + menu_height:
        var item_index = (mouse_y - dropdown_y - 4) / 22
        if item_index >= 0 and item_index < len(menu_items):
            return Int(item_index)
    return -1

fn main() raises:
    print("📋 FIXED MENU DEMO")
    print("Menu system with SOLID opaque dropdown backgrounds")
    
    var lib = DLHandle("./c_src/librendering_atlas.so")
    
    var init_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var title_ptr = null_terminated_string("Fixed Menu Demo")
    
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
    
    # Menu structure
    var menu_names = List[String]()
    menu_names.append("File")
    menu_names.append("Edit")
    menu_names.append("View")
    menu_names.append("Tools")
    menu_names.append("Help")
    
    # Define menu items for each menu
    var file_items = List[String]()
    file_items.append("New File")
    file_items.append("Open File...")
    file_items.append("Save")
    file_items.append("Save As...")
    file_items.append("----")
    file_items.append("Recent Files")
    file_items.append("----")
    file_items.append("Exit")
    
    var edit_items = List[String]()
    edit_items.append("Undo")
    edit_items.append("Redo")
    edit_items.append("----")
    edit_items.append("Cut")
    edit_items.append("Copy")
    edit_items.append("Paste")
    edit_items.append("----")
    edit_items.append("Find...")
    edit_items.append("Replace...")
    edit_items.append("Go to Line...")
    
    var view_items = List[String]()
    view_items.append("Zoom In")
    view_items.append("Zoom Out")
    view_items.append("Actual Size")
    view_items.append("----")
    view_items.append("Full Screen")
    view_items.append("Show Sidebar")
    view_items.append("Show Toolbar")
    view_items.append("Show Status Bar")
    
    var tools_items = List[String]()
    tools_items.append("Preferences...")
    tools_items.append("Extensions")
    tools_items.append("----")
    tools_items.append("Color Picker")
    tools_items.append("Calculator")
    tools_items.append("Terminal")
    tools_items.append("File Manager")
    
    var help_items = List[String]()
    help_items.append("Documentation")
    help_items.append("Keyboard Shortcuts")
    help_items.append("----")
    help_items.append("Check for Updates")
    help_items.append("Report Bug")
    help_items.append("----")
    help_items.append("About")
    
    # Menu state
    var selected_menu = -1  # Which menu is currently selected
    var menu_open = False   # Is a dropdown menu open
    var hover_item = -1     # Which dropdown item is being hovered
    var last_selected_item: String = "Welcome! Click a menu item to see it here."
    
    # Input state
    var prev_mouse_left: Int32 = GLFW_RELEASE
    
    if is_dark_mode:
        print("🌙 Starting in DARK theme")
    else:
        print("☀️  Starting in LIGHT theme")
    
    print("✅ Fixed menu demo initialized")
    print("📋 Dropdown menus now have SOLID backgrounds that cover content")
    
    var frame_count = 0
    while should_close() == 0 and frame_count < 3600:  # 60 seconds
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
            # Check menu bar clicks
            if mouse_y >= 0 and mouse_y <= 30:
                var clicked_menu = get_menu_item_at_position(menu_names, 0, 0, mouse_x, mouse_y)
                if clicked_menu >= 0:
                    if selected_menu == clicked_menu and menu_open:
                        # Clicking same menu closes it
                        menu_open = False
                        selected_menu = -1
                    else:
                        # Open new menu
                        selected_menu = clicked_menu
                        menu_open = True
                        hover_item = -1
                    print("📋 Menu clicked: " + menu_names[clicked_menu])
                else:
                    # Clicked outside menu
                    menu_open = False
                    selected_menu = -1
            
            # Check dropdown clicks
            elif menu_open and selected_menu >= 0:
                var dropdown_x = 15 + selected_menu * 75  # Approximate menu position
                var dropdown_y = 30
                var dropdown_width = 200
                
                # Get the appropriate menu items
                var current_items: List[String]
                if selected_menu == 0:
                    current_items = file_items
                elif selected_menu == 1:
                    current_items = edit_items
                elif selected_menu == 2:
                    current_items = view_items
                elif selected_menu == 3:
                    current_items = tools_items
                else:
                    current_items = help_items
                
                var clicked_item = get_dropdown_item_at_position(current_items, dropdown_x, dropdown_y, dropdown_width, mouse_x, mouse_y)
                if clicked_item >= 0 and current_items[clicked_item] != "----":
                    # Menu item clicked
                    last_selected_item = "You selected: " + menu_names[selected_menu] + " → " + current_items[clicked_item]
                    print("✅ Selected: " + menu_names[selected_menu] + " → " + current_items[clicked_item])
                    menu_open = False
                    selected_menu = -1
                elif mouse_x < dropdown_x - 10 or mouse_x > dropdown_x + dropdown_width + 10 or 
                     mouse_y < dropdown_y - 10 or mouse_y > dropdown_y + len(current_items) * 22 + 18:
                    # Clicked outside dropdown (with some margin)
                    menu_open = False
                    selected_menu = -1
            else:
                # Clicked in main area
                menu_open = False
                selected_menu = -1
        
        prev_mouse_left = current_mouse_left
        
        # Update hover state for dropdown items
        if menu_open and selected_menu >= 0:
            var dropdown_x = 15 + selected_menu * 75
            var dropdown_y = 30
            var dropdown_width = 200
            
            # Get the appropriate menu items
            var current_items: List[String]
            if selected_menu == 0:
                current_items = file_items
            elif selected_menu == 1:
                current_items = edit_items
            elif selected_menu == 2:
                current_items = view_items
            elif selected_menu == 3:
                current_items = tools_items
            else:
                current_items = help_items
            
            hover_item = get_dropdown_item_at_position(current_items, dropdown_x, dropdown_y, dropdown_width, mouse_x, mouse_y)
        else:
            hover_item = -1
        
        # Theme colors
        var bg_primary = List[Int](25, 25, 35, 255) if is_dark_mode else List[Int](240, 243, 246, 255)
        var text_primary = List[Int](240, 240, 250, 255) if is_dark_mode else List[Int](30, 30, 40, 255)
        var text_secondary = List[Int](180, 180, 200, 255) if is_dark_mode else List[Int](100, 100, 120, 255)
        
        # === RENDERING ===
        if frame_begin() != 0:
            break
        
        # Background - ALWAYS draw this first
        _ = set_color(bg_primary[0], bg_primary[1], bg_primary[2], 255)
        _ = draw_filled_rectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        
        # Main content - this should be COMPLETELY covered by dropdown menu when open
        _ = set_color(text_primary[0], text_primary[1], text_primary[2], 255)
        var title = null_terminated_string("📋 Menu System Demo")
        _ = draw_text(title, 50, 80, 24)
        title.free()
        
        # Instructions
        _ = set_color(text_secondary[0], text_secondary[1], text_secondary[2], 255)
        var instructions = null_terminated_string("Click on the menu items above to interact with them")
        _ = draw_text(instructions, 50, 120, 14)
        instructions.free()
        
        # More content that should be covered
        _ = set_color(text_primary[0], text_primary[1], text_primary[2], 255)
        var content1 = null_terminated_string("This content should be COMPLETELY HIDDEN when dropdown menus are open!")
        _ = draw_text(content1, 50, 160, 12)
        content1.free()
        
        var content2 = null_terminated_string("If you can see this text when a menu is open, the background is not solid.")
        _ = draw_text(content2, 50, 180, 12)
        content2.free()
        
        # Selected item display
        _ = set_color(text_primary[0], text_primary[1], text_primary[2], 255)
        var selected_label = null_terminated_string("Last Selection:")
        _ = draw_text(selected_label, 50, 220, 16)
        selected_label.free()
        
        # Display the selected menu item in a different color
        var accent_color = List[Int](70, 130, 180, 255)
        _ = set_color(accent_color[0], accent_color[1], accent_color[2], 255)
        var selected_ptr = null_terminated_string(last_selected_item)
        _ = draw_text(selected_ptr, 50, 250, 18)
        selected_ptr.free()
        
        # Menu status
        if menu_open:
            _ = set_color(text_secondary[0], text_secondary[1], text_secondary[2], 255)
            var menu_status = null_terminated_string("Menu: " + menu_names[selected_menu] + " (open)")
            var status_ptr = menu_status
            _ = draw_text(status_ptr, 50, 290, 12)
            status_ptr.free()
        else:
            _ = set_color(text_secondary[0], text_secondary[1], text_secondary[2], 255)
            var closed_status = null_terminated_string("No menu open - click a menu to open it")
            _ = draw_text(closed_status, 50, 290, 12)
            closed_status.free()
        
        # Theme info
        _ = set_color(text_secondary[0], text_secondary[1], text_secondary[2], 255)
        var theme_info = null_terminated_string("Press L for Light theme, D for Dark theme")
        _ = draw_text(theme_info, 50, 500, 12)
        theme_info.free()
        
        # IMPORTANT: Draw menu bar AFTER main content but BEFORE dropdown
        draw_menu_bar(lib, 0, 0, WINDOW_WIDTH, 30, menu_names, selected_menu, is_dark_mode)
        
        # CRITICAL: Draw dropdown menu LAST so it appears on top with solid background
        if menu_open and selected_menu >= 0:
            var dropdown_x = 15 + selected_menu * 75
            var dropdown_y = 30
            var dropdown_width = 200
            
            # Get the appropriate menu items
            var current_items: List[String]
            if selected_menu == 0:
                current_items = file_items
            elif selected_menu == 1:
                current_items = edit_items
            elif selected_menu == 2:
                current_items = view_items
            elif selected_menu == 3:
                current_items = tools_items
            else:
                current_items = help_items
            
            # This should COMPLETELY cover the background content
            draw_solid_dropdown_menu(lib, dropdown_x, dropdown_y, dropdown_width, current_items, hover_item, is_dark_mode)
        
        if frame_end() != 0:
            break
        
        frame_count += 1
    
    print("✅ Fixed menu demo completed!")
    _ = cleanup_gl()