"""
INTERACTIVE TREEVIEW AND LISTVIEW DEMO
Real implementation using actual TreeView and ListView widgets
"""

from sys.ffi import DLHandle
from memory import UnsafePointer
from .mojo_src.rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from .mojo_src.widgets.treeview_int import TreeViewInt, NODE_FOLDER, NODE_FILE
from .mojo_src.widgets.listview_int import ListViewInt, LISTVIEW_STYLE_REPORT, SELECTION_SINGLE
from .mojo_src.orchestration import EventManagerInt, create_event_manager
from .mojo_src.theme_state_integration import get_theme

alias WINDOW_WIDTH = 1200
alias WINDOW_HEIGHT = 800

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

fn populate_tree_with_sample_data(inout tree: TreeViewInt):
    """Populate the tree with sample file/folder structure."""
    
    # Root folders
    var docs_id = tree.add_node("Documents", -1, NODE_FOLDER)
    var downloads_id = tree.add_node("Downloads", -1, NODE_FOLDER)
    var desktop_id = tree.add_node("Desktop", -1, NODE_FOLDER)
    
    # Documents subfolders
    var projects_id = tree.add_node("Projects", docs_id, NODE_FOLDER)
    var images_id = tree.add_node("Images", docs_id, NODE_FOLDER)
    var notes_id = tree.add_node("Notes", docs_id, NODE_FOLDER)
    
    # Projects subfolders
    var mojogui_id = tree.add_node("MojoGUI", projects_id, NODE_FOLDER)
    var webapp_id = tree.add_node("WebApp", projects_id, NODE_FOLDER)
    var tools_id = tree.add_node("Tools", projects_id, NODE_FOLDER)
    
    # MojoGUI files
    _ = tree.add_node("main.mojo", mojogui_id, NODE_FILE)
    _ = tree.add_node("widgets.mojo", mojogui_id, NODE_FILE)
    _ = tree.add_node("theme_system.mojo", mojogui_id, NODE_FILE)
    _ = tree.add_node("rendering.mojo", mojogui_id, NODE_FILE)
    
    # WebApp files
    _ = tree.add_node("index.html", webapp_id, NODE_FILE)
    _ = tree.add_node("style.css", webapp_id, NODE_FILE)
    _ = tree.add_node("script.js", webapp_id, NODE_FILE)
    
    # Images files
    _ = tree.add_node("screenshot.png", images_id, NODE_FILE)
    _ = tree.add_node("logo.svg", images_id, NODE_FILE)
    _ = tree.add_node("banner.jpg", images_id, NODE_FILE)
    
    # Downloads files
    _ = tree.add_node("archive.zip", downloads_id, NODE_FILE)
    _ = tree.add_node("installer.exe", downloads_id, NODE_FILE)
    _ = tree.add_node("readme.txt", downloads_id, NODE_FILE)
    
    # Desktop files
    _ = tree.add_node("shortcuts.lnk", desktop_id, NODE_FILE)
    _ = tree.add_node("temp.txt", desktop_id, NODE_FILE)
    
    # Expand some nodes by default
    tree.expand_node(docs_id, True)
    tree.expand_node(projects_id, True)
    tree.expand_node(mojogui_id, True)

fn populate_listview_with_sample_data(inout listview: ListViewInt):
    """Populate the listview with sample file data."""
    
    # Add columns
    _ = listview.add_column("Name", 200)
    _ = listview.add_column("Size", 80)
    _ = listview.add_column("Type", 100)
    _ = listview.add_column("Modified", 150)
    
    # Add sample files
    var idx = listview.add_item("main.mojo")
    listview.set_item_text(idx, 1, "4.2 KB")
    listview.set_item_text(idx, 2, "Mojo File")
    listview.set_item_text(idx, 3, "2025-06-03 14:30")
    
    idx = listview.add_item("widgets.mojo")
    listview.set_item_text(idx, 1, "12.8 KB")
    listview.set_item_text(idx, 2, "Mojo File") 
    listview.set_item_text(idx, 3, "2025-06-03 13:45")
    
    idx = listview.add_item("theme_system.mojo")
    listview.set_item_text(idx, 1, "8.1 KB")
    listview.set_item_text(idx, 2, "Mojo File")
    listview.set_item_text(idx, 3, "2025-06-03 12:15")
    
    idx = listview.add_item("rendering.mojo")
    listview.set_item_text(idx, 1, "15.3 KB")
    listview.set_item_text(idx, 2, "Mojo File")
    listview.set_item_text(idx, 3, "2025-06-02 16:20")
    
    idx = listview.add_item("README.md")
    listview.set_item_text(idx, 1, "1.9 KB")
    listview.set_item_text(idx, 2, "Markdown")
    listview.set_item_text(idx, 3, "2025-06-01 09:30")

fn main() raises:
    print("🌳📋 INTERACTIVE TREEVIEW & LISTVIEW DEMO")
    print("Real TreeView and ListView widgets working together")
    
    var lib = DLHandle("./c_src/librendering_atlas.so")
    
    var init_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var title_ptr = null_terminated_string("Interactive TreeView & ListView Demo")
    
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
    var draw_line = lib.get_function[fn(Int32, Int32, Int32, Int32, Int32) -> Int32]("draw_line")
    
    var get_system_dark_mode = lib.get_function[fn() -> Int32]("get_system_dark_mode")
    var get_cursor_pos = lib.get_function[fn(UnsafePointer[Float64], UnsafePointer[Float64]) -> Int32]("get_cursor_position")
    var get_mouse_button = lib.get_function[fn(Int32) -> Int32]("get_mouse_button_state")
    var get_key = lib.get_function[fn(Int32) -> Int32]("get_key_state")
    
    # Create rendering context
    var ctx = RenderingContextInt(lib)
    
    # Create widgets
    var treeview = TreeViewInt(20, 80, 350, 600)
    var listview = ListViewInt(390, 80, 780, 600, LISTVIEW_STYLE_REPORT)
    
    # Set up listview
    listview.selection_mode = SELECTION_SINGLE
    listview.show_header = True
    listview.show_grid_lines = True
    listview.alternate_row_colors = True
    
    # Populate with sample data
    populate_tree_with_sample_data(treeview)
    populate_listview_with_sample_data(listview)
    
    # Create event manager
    var event_manager = create_event_manager()
    
    # Theme state
    var is_dark_mode = get_system_dark_mode() == 1
    var prev_key_d: Int32 = GLFW_RELEASE
    var prev_key_l: Int32 = GLFW_RELEASE
    var prev_mouse_left: Int32 = GLFW_RELEASE
    
    if is_dark_mode:
        print("🌙 Starting in DARK theme")
    else:
        print("☀️  Starting in LIGHT theme")
    
    print("✅ Interactive demo initialized")
    print("🌳 Click TreeView nodes to expand/collapse and navigate")
    print("📋 Click ListView items to select files")
    print("⌨️  Press L for light theme, D for dark theme")
    
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
        
        # Handle mouse input
        var current_mouse_left = get_mouse_button(GLFW_MOUSE_BUTTON_LEFT)
        
        if prev_mouse_left == GLFW_RELEASE and current_mouse_left == GLFW_PRESS:
            # Create mouse event
            from .mojo_src.widget_int import MouseEventInt
            var mouse_event = MouseEventInt(mouse_x, mouse_y, 0, True)
            
            # Handle TreeView events
            if treeview.handle_mouse_event(mouse_event):
                print("🌳 TreeView interaction detected")
            
            # Handle ListView events  
            if listview.handle_mouse_event(mouse_event):
                print("📋 ListView interaction detected")
        
        prev_mouse_left = current_mouse_left
        
        # Update widgets
        treeview.update()
        listview.update()
        
        # Get theme for background colors
        let theme = get_theme()
        
        # === RENDERING ===
        if frame_begin() != 0:
            break
        
        # Background
        _ = set_color(theme.primary_bg.r, theme.primary_bg.g, theme.primary_bg.b, theme.primary_bg.a)
        _ = draw_filled_rectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        
        # Title
        _ = set_color(theme.primary_text.r, theme.primary_text.g, theme.primary_text.b, theme.primary_text.a)
        var title = null_terminated_string("🌳📋 Interactive TreeView & ListView Demo")
        _ = draw_text(title, 20, 20, 24)
        title.free()
        
        # Theme indicator
        _ = set_color(theme.secondary_text.r, theme.secondary_text.g, theme.secondary_text.b, theme.secondary_text.a)
        var theme_name = "DARK THEME" if is_dark_mode else "LIGHT THEME"
        var theme_ptr = null_terminated_string("Current: " + theme_name + " | Press L/D to switch")
        _ = draw_text(theme_ptr, 20, 50, 14)
        theme_ptr.free()
        
        # Widget labels
        _ = set_color(theme.primary_text.r, theme.primary_text.g, theme.primary_text.b, theme.primary_text.a)
        var tree_label = null_terminated_string("TreeView Widget - File Navigation")
        _ = draw_text(tree_label, 20, 60, 16)
        tree_label.free()
        
        var list_label = null_terminated_string("ListView Widget - File Details")
        _ = draw_text(list_label, 390, 60, 16)
        list_label.free()
        
        # Render widgets
        treeview.render(ctx)
        listview.draw(ctx)  # Note: ListView uses draw() method
        
        # Status information
        _ = set_color(theme.secondary_text.r, theme.secondary_text.g, theme.secondary_text.b, theme.secondary_text.a)
        var status_text = "Real TreeView and ListView widgets with full interaction support"
        var status_ptr = null_terminated_string(status_text)
        _ = draw_text(status_ptr, 20, 700, 12)
        status_ptr.free()
        
        # Features
        var feature1 = null_terminated_string("✅ TreeView: Hierarchical navigation with expand/collapse functionality")
        _ = draw_text(feature1, 20, 720, 11)
        feature1.free()
        
        var feature2 = null_terminated_string("✅ ListView: Multi-column display with headers and sorting capabilities")
        _ = draw_text(feature2, 20, 735, 11)
        feature2.free()
        
        var feature3 = null_terminated_string("✅ Both widgets: Full theme integration and mouse interaction support")
        _ = draw_text(feature3, 20, 750, 11)
        feature3.free()
        
        if frame_end() != 0:
            break
        
        frame_count += 1
    
    print("✅ Interactive TreeView & ListView demo completed!")
    _ = cleanup_gl()