"""
Integer-Only File Dialog Widget Implementation
Complete file picker dialog combining navigation, tree view, list view, and filters.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .widget_constants import *
from .button_int import ButtonInt
from .textedit_int import TextEditInt
from .dropdown_int import DropdownInt
from .navbar_int import NavigationBarInt
from .searchbox_int import SearchBoxInt
from .columnheader_int import ColumnHeaderInt
from .icon_int import IconInt, get_file_extension, create_file_icon_int

# Dialog modes
alias FILE_DIALOG_OPEN = 0
alias FILE_DIALOG_SAVE = 1
alias FILE_DIALOG_SELECT_FOLDER = 2
alias FILE_DIALOG_OPEN_MULTIPLE = 3

# View modes
alias VIEW_LIST = 0
alias VIEW_DETAILS = 1
alias VIEW_THUMBNAILS = 2
alias VIEW_ICONS = 3

struct FileFilter:
    """File type filter."""
    var name: String
    var extensions: List[String]
    
    fn __init__(inout self, name: String, extensions: List[String]):
        self.name = name
        self.extensions = extensions
    
    fn matches(self, filename: String) -> Bool:
        """Check if filename matches filter."""
        if len(self.extensions) == 0:
            return True
        
        let ext = get_file_extension(filename).lower()
        for filter_ext in self.extensions:
            if ext == filter_ext.lower():
                return True
        return False

struct FileEntry:
    """File or directory entry."""
    var name: String
    var path: String
    var is_directory: Bool
    var size: Int64
    var modified_time: Int64
    var icon_type: Int32
    var is_hidden: Bool
    
    fn __init__(inout self, name: String, path: String, is_directory: Bool):
        self.name = name
        self.path = path
        self.is_directory = is_directory
        self.size = 0
        self.modified_time = 0
        self.icon_type = ICON_FOLDER if is_directory else ICON_FILE
        self.is_hidden = name.startswith('.')

struct FileDialogInt(BaseWidgetInt):
    """Complete file dialog widget."""
    
    # Dialog properties
    var dialog_mode: Int32
    var title: String
    var current_path: String
    var selected_files: List[String]
    var filters: List[FileFilter]
    var current_filter: Int32
    var show_hidden_files: Bool
    var view_mode: Int32
    
    # Components
    var navbar: NavigationBarInt
    var search_box: SearchBoxInt
    var file_name_edit: TextEditInt
    var filter_dropdown: DropdownInt
    var ok_button: ButtonInt
    var cancel_button: ButtonInt
    var column_header: ColumnHeaderInt
    
    # File listing
    var file_entries: List[FileEntry]
    var filtered_entries: List[Int32]  # Indices into file_entries
    var selected_indices: List[Int32]
    var hover_index: Int32
    var anchor_index: Int32  # For range selection
    
    # Places/bookmarks (left sidebar)
    var places: List[FileEntry]
    var selected_place: Int32
    
    # Layout
    var sidebar_width: Int32
    var toolbar_height: Int32
    var bottom_panel_height: Int32
    var list_item_height: Int32
    var icon_size: Int32
    var thumbnail_size: Int32
    var grid_item_width: Int32
    var grid_item_height: Int32
    
    # Scrolling
    var scroll_offset: Int32
    var max_scroll: Int32
    
    # State
    var is_loading: Bool
    var error_message: String
    var last_click_time: Int32
    var last_click_index: Int32
    
    # Colors
    var sidebar_bg_color: ColorInt
    var list_bg_color: ColorInt
    var selection_color: ColorInt
    var hover_color: ColorInt
    var place_selected_color: ColorInt
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32 = 800, height: Int32 = 600,
                mode: Int32 = FILE_DIALOG_OPEN):
        self.super().__init__(x, y, width, height)
        
        self.dialog_mode = mode
        self.title = self.get_title_for_mode()
        self.current_path = "/home"  # Default path
        self.selected_files = List[String]()
        self.filters = List[FileFilter]()
        self.current_filter = 0
        self.show_hidden_files = False
        self.view_mode = VIEW_DETAILS
        
        # Layout dimensions
        self.sidebar_width = 200
        self.toolbar_height = 40
        self.bottom_panel_height = 80
        self.list_item_height = 24
        self.icon_size = 16
        self.thumbnail_size = 64
        self.grid_item_width = 100
        self.grid_item_height = 120
        
        # Initialize components
        self.setup_components()
        
        # File listing
        self.file_entries = List[FileEntry]()
        self.filtered_entries = List[Int32]()
        self.selected_indices = List[Int32]()
        self.hover_index = -1
        self.anchor_index = -1
        
        # Places
        self.setup_places()
        self.selected_place = -1
        
        # Scrolling
        self.scroll_offset = 0
        self.max_scroll = 0
        
        # State
        self.is_loading = False
        self.error_message = ""
        self.last_click_time = 0
        self.last_click_index = -1
        
        # Colors
        self.sidebar_bg_color = ColorInt(240, 240, 240, 255)
        self.list_bg_color = ColorInt(255, 255, 255, 255)
        self.selection_color = ColorInt(0, 120, 215, 255)
        self.hover_color = ColorInt(229, 243, 255, 255)
        self.place_selected_color = ColorInt(204, 232, 255, 255)
        
        # Widget appearance
        self.background_color = ColorInt(250, 250, 250, 255)
        self.border_color = ColorInt(180, 180, 180, 255)
        self.border_width = 1
        
        # Add default filters
        self.add_default_filters()
        
        # Load initial directory
        self.load_directory(self.current_path)
    
    fn setup_components(inout self):
        """Initialize dialog components."""
        # Navigation bar
        self.navbar = NavigationBarInt(self.bounds.x, self.bounds.y + 30, 
                                      self.bounds.width, self.toolbar_height)
        
        # Search box
        let search_x = self.bounds.x + self.bounds.width - 200
        let search_y = self.bounds.y + 35
        self.search_box = SearchBoxInt(search_x, search_y, 180, 30, "Search files...")
        
        # Column header for details view
        let header_y = self.bounds.y + 30 + self.toolbar_height
        self.column_header = ColumnHeaderInt(self.bounds.x + self.sidebar_width, 
                                           header_y, 
                                           self.bounds.width - self.sidebar_width, 28)
        _ = self.column_header.add_column("name", "Name", 300)
        _ = self.column_header.add_column("size", "Size", 100)
        _ = self.column_header.add_column("type", "Type", 100)
        _ = self.column_header.add_column("modified", "Modified", 150)
        
        # Bottom panel components
        let bottom_y = self.bounds.y + self.bounds.height - self.bottom_panel_height
        
        # File name edit
        self.file_name_edit = TextEditInt(self.bounds.x + 100, bottom_y + 15, 
                                         self.bounds.width - 300, 30, "File name...")
        
        # Filter dropdown
        self.filter_dropdown = DropdownInt(self.bounds.x + 100, bottom_y + 50,
                                         self.bounds.width - 300, 25)
        
        # Buttons
        let button_width = 80
        let button_height = 30
        let button_spacing = 10
        let buttons_x = self.bounds.x + self.bounds.width - 2 * button_width - button_spacing - 20
        
        self.ok_button = ButtonInt(buttons_x, bottom_y + 25, 
                                  button_width, button_height, "Open")
        
        self.cancel_button = ButtonInt(buttons_x + button_width + button_spacing, bottom_y + 25,
                                      button_width, button_height, "Cancel")
    
    fn setup_places(inout self):
        """Set up standard places/bookmarks."""
        self.places = List[FileEntry]()
        
        # Standard places
        self.places.append(FileEntry("Home", "/home", True))
        self.places.append(FileEntry("Desktop", "/home/Desktop", True))
        self.places.append(FileEntry("Documents", "/home/Documents", True))
        self.places.append(FileEntry("Downloads", "/home/Downloads", True))
        self.places.append(FileEntry("Pictures", "/home/Pictures", True))
        self.places.append(FileEntry("Music", "/home/Music", True))
        self.places.append(FileEntry("Videos", "/home/Videos", True))
        
        # Set icons
        self.places[0].icon_type = ICON_HOME
        self.places[1].icon_type = ICON_FOLDER
        self.places[2].icon_type = ICON_DOCUMENT
        self.places[3].icon_type = ICON_FOLDER
        self.places[4].icon_type = ICON_IMAGE
        self.places[5].icon_type = ICON_AUDIO
        self.places[6].icon_type = ICON_VIDEO
    
    fn add_default_filters(inout self):
        """Add default file filters based on dialog mode."""
        if self.dialog_mode == FILE_DIALOG_SELECT_FOLDER:
            return  # No filters for folder selection
        
        # All files filter
        var all_filter = FileFilter("All Files (*.*)", List[String]())
        self.filters.append(all_filter)
        
        # Common filters
        var image_exts = List[String]()
        image_exts.append(".jpg")
        image_exts.append(".jpeg")
        image_exts.append(".png")
        image_exts.append(".gif")
        image_exts.append(".bmp")
        self.filters.append(FileFilter("Images", image_exts))
        
        var doc_exts = List[String]()
        doc_exts.append(".txt")
        doc_exts.append(".doc")
        doc_exts.append(".docx")
        doc_exts.append(".pdf")
        self.filters.append(FileFilter("Documents", doc_exts))
        
        # Update dropdown
        for filter in self.filters:
            self.filter_dropdown.add_item(filter.name)
    
    fn get_title_for_mode(self) -> String:
        """Get dialog title based on mode."""
        if self.dialog_mode == FILE_DIALOG_OPEN:
            return "Open File"
        elif self.dialog_mode == FILE_DIALOG_SAVE:
            return "Save File"
        elif self.dialog_mode == FILE_DIALOG_SELECT_FOLDER:
            return "Select Folder"
        elif self.dialog_mode == FILE_DIALOG_OPEN_MULTIPLE:
            return "Open Files"
        return "File Dialog"
    
    fn navigate_to(inout self, path: String):
        """Navigate to a directory."""
        self.current_path = path
        self.navbar.navigate_to(path)
        self.load_directory(path)
    
    fn refresh_current_directory(inout self):
        """Refresh the current directory listing."""
        self.load_directory(self.current_path)
    
    fn load_directory(inout self, path: String):
        """Load directory contents."""
        self.is_loading = True
        self.error_message = ""
        
        # Clear current entries
        self.file_entries.clear()
        self.filtered_entries.clear()
        self.selected_indices.clear()
        
        # In real implementation, would read actual directory
        # For demo, create sample entries
        if path == "/home":
            self.file_entries.append(FileEntry("Desktop", path + "/Desktop", True))
            self.file_entries.append(FileEntry("Documents", path + "/Documents", True))
            self.file_entries.append(FileEntry("Downloads", path + "/Downloads", True))
            self.file_entries.append(FileEntry("Pictures", path + "/Pictures", True))
            self.file_entries.append(FileEntry("readme.txt", path + "/readme.txt", False))
            self.file_entries.append(FileEntry("photo.jpg", path + "/photo.jpg", False))
            self.file_entries.append(FileEntry("document.pdf", path + "/document.pdf", False))
        elif path.endswith("/Documents"):
            self.file_entries.append(FileEntry("report.doc", path + "/report.doc", False))
            self.file_entries.append(FileEntry("notes.txt", path + "/notes.txt", False))
            self.file_entries.append(FileEntry("presentation.ppt", path + "/presentation.ppt", False))
        
        # Set file metadata
        for i in range(len(self.file_entries)):
            if not self.file_entries[i].is_directory:
                self.file_entries[i].size = 1024 * (i + 1)  # Dummy sizes
                self.file_entries[i].icon_type = create_file_icon_int(0, 0, 
                    get_file_extension(self.file_entries[i].name)).icon_type
        
        # Apply current filter
        self.apply_filter()
        
        self.is_loading = False
        self.scroll_offset = 0
    
    fn apply_filter(inout self):
        """Apply current file filter."""
        self.filtered_entries.clear()
        
        for i in range(len(self.file_entries)):
            let entry = self.file_entries[i]
            
            # Check hidden files
            if not self.show_hidden_files and entry.is_hidden:
                continue
            
            # Folders always shown
            if entry.is_directory:
                self.filtered_entries.append(i)
                continue
            
            # Check filter
            if self.current_filter < len(self.filters):
                let current_filter = self.filters[self.current_filter]
                if current_filter.matches(entry.name):
                    self.filtered_entries.append(i)
            else:
                self.filtered_entries.append(i)
    
    fn filter_files(inout self, search_text: String):
        """Filter files by search text."""
        if len(search_text) == 0:
            self.apply_filter()
            return
        
        self.filtered_entries.clear()
        let search_lower = search_text.lower()
        
        for i in range(len(self.file_entries)):
            let entry = self.file_entries[i]
            
            if not self.show_hidden_files and entry.is_hidden:
                continue
            
            if search_lower in entry.name.lower():
                self.filtered_entries.append(i)
    
    fn sort_files(inout self, column: String, order: Int32):
        """Sort files by column."""
        # Simplified sorting - would implement proper comparison
        if order == SORT_NONE:
            self.apply_filter()  # Reset to original order
        # Real implementation would sort filtered_entries based on column and order
    
    fn get_file_list_rect(self) -> RectInt:
        """Get rectangle for file list area."""
        let x = self.bounds.x + self.sidebar_width
        let y = self.bounds.y + 30 + self.toolbar_height + 
               (28 if self.view_mode == VIEW_DETAILS else 0)
        let width = self.bounds.width - self.sidebar_width
        let height = self.bounds.height - 30 - self.toolbar_height - 
                    self.bottom_panel_height - 
                    (28 if self.view_mode == VIEW_DETAILS else 0)
        return RectInt(x, y, width, height)
    
    fn get_visible_item_count(self) -> Int32:
        """Get number of visible items in current view."""
        let list_rect = self.get_file_list_rect()
        
        if self.view_mode == VIEW_LIST or self.view_mode == VIEW_DETAILS:
            return list_rect.height // self.list_item_height
        else:  # Grid views
            let cols = list_rect.width // self.grid_item_width
            let rows = list_rect.height // self.grid_item_height
            return cols * rows
    
    fn get_item_rect(self, index: Int32) -> RectInt:
        """Get rectangle for a file list item."""
        if index < 0 or index >= len(self.filtered_entries):
            return RectInt(0, 0, 0, 0)
        
        let list_rect = self.get_file_list_rect()
        let visible_index = index - self.scroll_offset
        
        if self.view_mode == VIEW_LIST or self.view_mode == VIEW_DETAILS:
            return RectInt(list_rect.x, list_rect.y + visible_index * self.list_item_height,
                          list_rect.width, self.list_item_height)
        else:  # Grid views
            let cols = list_rect.width // self.grid_item_width
            let row = visible_index // cols
            let col = visible_index % cols
            return RectInt(list_rect.x + col * self.grid_item_width,
                          list_rect.y + row * self.grid_item_height,
                          self.grid_item_width, self.grid_item_height)
    
    fn select_file(inout self, index: Int32, extend: Bool = False, range: Bool = False):
        """Select a file entry."""
        if index < 0 or index >= len(self.filtered_entries):
            return
        
        if self.dialog_mode != FILE_DIALOG_OPEN_MULTIPLE and not extend and not range:
            # Single selection mode
            self.selected_indices.clear()
        
        if range and self.anchor_index >= 0:
            # Range selection
            self.selected_indices.clear()
            let start = min(self.anchor_index, index)
            let end = max(self.anchor_index, index)
            for i in range(start, end + 1):
                self.selected_indices.append(i)
        elif extend:
            # Toggle selection
            var found = False
            for i in range(len(self.selected_indices)):
                if self.selected_indices[i] == index:
                    self.selected_indices.remove(i)
                    found = True
                    break
            if not found:
                self.selected_indices.append(index)
        else:
            # Single selection
            var found = False
            for idx in self.selected_indices:
                if idx == index:
                    found = True
                    break
            if not found:
                self.selected_indices.append(index)
        
        # Update file name edit
        if len(self.selected_indices) == 1:
            let entry_idx = self.filtered_entries[self.selected_indices[0]]
            let entry = self.file_entries[entry_idx]
            if not entry.is_directory:
                self.file_name_edit.set_text(entry.name)
        
        if not range:
            self.anchor_index = index
    
    fn on_ok_clicked(inout self):
        """Handle OK button click."""
        self.selected_files.clear()
        
        if self.dialog_mode == FILE_DIALOG_SAVE:
            # Get filename from edit box
            let filename = self.file_name_edit.get_text()
            if len(filename) > 0:
                self.selected_files.append(self.current_path + "/" + filename)
        else:
            # Get selected files
            for idx in self.selected_indices:
                let entry_idx = self.filtered_entries[idx]
                let entry = self.file_entries[entry_idx]
                if self.dialog_mode == FILE_DIALOG_SELECT_FOLDER:
                    if entry.is_directory:
                        self.selected_files.append(entry.path)
                else:
                    if not entry.is_directory:
                        self.selected_files.append(entry.path)
    
    fn on_cancel_clicked(inout self):
        """Handle Cancel button click."""
        # Would trigger callback in real implementation
        pass
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        
        # Handle components
        if self.navbar.handle_mouse_event(event):
            return True
        if self.search_box.handle_mouse_event(event):
            return True
        if self.column_header.handle_mouse_event(event):
            return True
        if self.file_name_edit.handle_mouse_event(event):
            return True
        if self.filter_dropdown.handle_mouse_event(event):
            if self.current_filter != self.filter_dropdown.get_selected_index():
                self.current_filter = self.filter_dropdown.get_selected_index()
                self.apply_filter()
            return True
        if self.ok_button.handle_mouse_event(event) and event.pressed:
            self.on_ok_clicked()
            return True
        if self.cancel_button.handle_mouse_event(event) and event.pressed:
            self.on_cancel_clicked()
            return True
        
        # Handle file list
        let list_rect = self.get_file_list_rect()
        if list_rect.contains(point):
            return self.handle_file_list_mouse(event)
        
        # Handle sidebar
        let sidebar_rect = RectInt(self.bounds.x, self.bounds.y + 30 + self.toolbar_height,
                                   self.sidebar_width, 
                                   self.bounds.height - 30 - self.toolbar_height - self.bottom_panel_height)
        if sidebar_rect.contains(point):
            return self.handle_sidebar_mouse(event)
        
        return self.contains_point(point)
    
    fn handle_file_list_mouse(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse in file list."""
        # Find which item was clicked
        for i in range(len(self.filtered_entries)):
            let rect = self.get_item_rect(i)
            if rect.y < self.get_file_list_rect().y:
                continue  # Above visible area
            if rect.y >= self.get_file_list_rect().y + self.get_file_list_rect().height:
                break  # Below visible area
            
            if rect.contains(PointInt(event.x, event.y)):
                self.hover_index = i
                
                if event.pressed:
                    # Check for double-click
                    let current_time = 0  # Would use actual time
                    if i == self.last_click_index and current_time - self.last_click_time < 500:
                        # Double-click
                        let entry_idx = self.filtered_entries[i]
                        let entry = self.file_entries[entry_idx]
                        if entry.is_directory:
                            self.navigate_to(entry.path)
                        else:
                            self.select_file(i)
                            self.on_ok_clicked()
                    else:
                        # Single click
                        self.select_file(i, event.ctrl_held, event.shift_held)
                    
                    self.last_click_index = i
                    self.last_click_time = current_time
                
                return True
        
        self.hover_index = -1
        return True
    
    fn handle_sidebar_mouse(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse in sidebar."""
        let item_height = 30
        let y_start = self.bounds.y + 30 + self.toolbar_height + 10
        
        for i in range(len(self.places)):
            let item_y = y_start + i * item_height
            let item_rect = RectInt(self.bounds.x, item_y, self.sidebar_width, item_height)
            
            if item_rect.contains(PointInt(event.x, event.y)):
                if event.pressed:
                    self.selected_place = i
                    self.navigate_to(self.places[i].path)
                return True
        
        return True
    
    fn render(self, ctx: RenderingContextInt):
        """Render file dialog."""
        if not self.visible:
            return
        
        # Background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                     self.bounds.width, self.bounds.height)
        
        # Title bar
        self.render_title_bar(ctx)
        
        # Components
        self.navbar.render(ctx)
        self.search_box.render(ctx)
        
        # Main areas
        self.render_sidebar(ctx)
        self.render_file_list(ctx)
        self.render_bottom_panel(ctx)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y,
                              self.bounds.width, self.bounds.height)
    
    fn render_title_bar(self, ctx: RenderingContextInt):
        """Render dialog title bar."""
        _ = ctx.set_color(240, 240, 240, 255)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, 30)
        
        _ = ctx.set_color(0, 0, 0, 255)
        _ = ctx.draw_text(self.title, self.bounds.x + 10, self.bounds.y + 8, 12)
        
        # Close button
        let close_x = self.bounds.x + self.bounds.width - 25
        _ = ctx.set_color(200, 0, 0, 255)
        _ = ctx.draw_line(close_x, self.bounds.y + 10, close_x + 10, self.bounds.y + 20, 2)
        _ = ctx.draw_line(close_x, self.bounds.y + 20, close_x + 10, self.bounds.y + 10, 2)
        
        # Separator
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_line(self.bounds.x, self.bounds.y + 30, 
                         self.bounds.x + self.bounds.width, self.bounds.y + 30, 1)
    
    fn render_sidebar(self, ctx: RenderingContextInt):
        """Render sidebar with places."""
        let sidebar_rect = RectInt(self.bounds.x, self.bounds.y + 30 + self.toolbar_height,
                                  self.sidebar_width, 
                                  self.bounds.height - 30 - self.toolbar_height - self.bottom_panel_height)
        
        _ = ctx.set_color(self.sidebar_bg_color.r, self.sidebar_bg_color.g,
                         self.sidebar_bg_color.b, self.sidebar_bg_color.a)
        _ = ctx.draw_filled_rectangle(sidebar_rect.x, sidebar_rect.y,
                                     sidebar_rect.width, sidebar_rect.height)
        
        # Places title
        _ = ctx.set_color(100, 100, 100, 255)
        _ = ctx.draw_text("PLACES", sidebar_rect.x + 10, sidebar_rect.y + 10, 11)
        
        # Place items
        let item_height = 30
        let y_start = sidebar_rect.y + 30
        
        for i in range(len(self.places)):
            let item_y = y_start + i * item_height
            let item_rect = RectInt(sidebar_rect.x, item_y, sidebar_rect.width, item_height)
            
            # Selection/hover background
            if i == self.selected_place:
                _ = ctx.set_color(self.place_selected_color.r, self.place_selected_color.g,
                                 self.place_selected_color.b, self.place_selected_color.a)
                _ = ctx.draw_filled_rectangle(item_rect.x, item_rect.y,
                                             item_rect.width, item_rect.height)
            
            # Icon
            let icon = IconInt(item_rect.x + 10, item_rect.y + 7, 
                              self.places[i].icon_type, ICON_SIZE_SMALL)
            icon.render(ctx)
            
            # Text
            _ = ctx.set_color(0, 0, 0, 255)
            _ = ctx.draw_text(self.places[i].name, item_rect.x + 35, item_rect.y + 9, 12)
        
        # Separator
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_line(sidebar_rect.x + sidebar_rect.width - 1, sidebar_rect.y,
                         sidebar_rect.x + sidebar_rect.width - 1, 
                         sidebar_rect.y + sidebar_rect.height, 1)
    
    fn render_file_list(self, ctx: RenderingContextInt):
        """Render file list area."""
        let list_rect = self.get_file_list_rect()
        
        _ = ctx.set_color(self.list_bg_color.r, self.list_bg_color.g,
                         self.list_bg_color.b, self.list_bg_color.a)
        _ = ctx.draw_filled_rectangle(list_rect.x, list_rect.y,
                                     list_rect.width, list_rect.height)
        
        # Column header for details view
        if self.view_mode == VIEW_DETAILS:
            self.column_header.render(ctx)
        
        # Render visible items
        let visible_count = self.get_visible_item_count()
        let start_index = self.scroll_offset
        let end_index = min(start_index + visible_count, len(self.filtered_entries))
        
        for i in range(start_index, end_index):
            self.render_file_item(ctx, i)
        
        # Loading indicator
        if self.is_loading:
            _ = ctx.set_color(100, 100, 100, 255)
            _ = ctx.draw_text("Loading...", list_rect.x + list_rect.width // 2 - 30,
                             list_rect.y + list_rect.height // 2, 12)
        elif len(self.filtered_entries) == 0:
            _ = ctx.set_color(150, 150, 150, 255)
            _ = ctx.draw_text("No files to display", list_rect.x + list_rect.width // 2 - 50,
                             list_rect.y + list_rect.height // 2, 12)
    
    fn render_file_item(self, ctx: RenderingContextInt, index: Int32):
        """Render a single file item."""
        let rect = self.get_item_rect(index)
        let entry_idx = self.filtered_entries[index]
        let entry = self.file_entries[entry_idx]
        
        # Background for selection/hover
        var is_selected = False
        for idx in self.selected_indices:
            if idx == index:
                is_selected = True
                break
        
        if is_selected:
            _ = ctx.set_color(self.selection_color.r, self.selection_color.g,
                             self.selection_color.b, self.selection_color.a)
            _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        elif index == self.hover_index:
            _ = ctx.set_color(self.hover_color.r, self.hover_color.g,
                             self.hover_color.b, self.hover_color.a)
            _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        if self.view_mode == VIEW_LIST or self.view_mode == VIEW_DETAILS:
            # Icon
            let icon = IconInt(rect.x + 4, rect.y + 4, entry.icon_type, ICON_SIZE_SMALL)
            icon.render(ctx)
            
            # Name
            let text_color = ColorInt(255, 255, 255, 255) if is_selected 
                           else ColorInt(0, 0, 0, 255)
            _ = ctx.set_color(text_color.r, text_color.g, text_color.b, text_color.a)
            _ = ctx.draw_text(entry.name, rect.x + 24, rect.y + 6, 12)
            
            # Additional columns for details view
            if self.view_mode == VIEW_DETAILS:
                # Size
                if not entry.is_directory:
                    let size_text = self.format_file_size(entry.size)
                    _ = ctx.draw_text(size_text, rect.x + 324, rect.y + 6, 12)
                
                # Type
                let type_text = "Folder" if entry.is_directory else 
                               get_file_extension(entry.name)
                _ = ctx.draw_text(type_text, rect.x + 424, rect.y + 6, 12)
                
                # Modified (placeholder)
                _ = ctx.draw_text("2024-01-15", rect.x + 524, rect.y + 6, 12)
        else:
            # Grid view - render as tiles
            # Icon (larger)
            let icon_x = rect.x + (rect.width - self.thumbnail_size) // 2
            let icon_y = rect.y + 10
            let icon = IconInt(icon_x, icon_y, entry.icon_type, self.thumbnail_size)
            icon.render(ctx)
            
            # Name (centered, possibly wrapped)
            let text_color = ColorInt(255, 255, 255, 255) if is_selected 
                           else ColorInt(0, 0, 0, 255)
            _ = ctx.set_color(text_color.r, text_color.g, text_color.b, text_color.a)
            
            let text_width = len(entry.name) * 6
            let text_x = rect.x + (rect.width - text_width) // 2
            let text_y = rect.y + self.thumbnail_size + 20
            _ = ctx.draw_text(entry.name, text_x, text_y, 11)
    
    fn render_bottom_panel(self, ctx: RenderingContextInt):
        """Render bottom panel with controls."""
        let panel_y = self.bounds.y + self.bounds.height - self.bottom_panel_height
        
        _ = ctx.set_color(240, 240, 240, 255)
        _ = ctx.draw_filled_rectangle(self.bounds.x, panel_y,
                                     self.bounds.width, self.bottom_panel_height)
        
        # Separator
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_line(self.bounds.x, panel_y, 
                         self.bounds.x + self.bounds.width, panel_y, 1)
        
        # Labels
        _ = ctx.set_color(0, 0, 0, 255)
        _ = ctx.draw_text("File name:", self.bounds.x + 15, panel_y + 22, 12)
        _ = ctx.draw_text("File type:", self.bounds.x + 15, panel_y + 57, 12)
        
        # Components
        self.file_name_edit.render(ctx)
        self.filter_dropdown.render(ctx)
        self.ok_button.render(ctx)
        self.cancel_button.render(ctx)
    
    fn format_file_size(self, size: Int64) -> String:
        """Format file size for display."""
        if size < 1024:
            return str(size) + " B"
        elif size < 1024 * 1024:
            return str(size // 1024) + " KB"
        elif size < 1024 * 1024 * 1024:
            return str(size // (1024 * 1024)) + " MB"
        else:
            return str(size // (1024 * 1024 * 1024)) + " GB"
    
    fn update(inout self):
        """Update file dialog state."""
        self.navbar.update()
        self.search_box.update()
        self.file_name_edit.update()
        self.filter_dropdown.update()
        self.column_header.update()
        self.ok_button.update()
        self.cancel_button.update()
    
    fn set_filters(inout self, filters: List[FileFilter]):
        """Set file type filters."""
        self.filters = filters
        self.filter_dropdown.clear()
        for filter in filters:
            self.filter_dropdown.add_item(filter.name)
        self.current_filter = 0
        self.apply_filter()
    
    fn get_selected_files(self) -> List[String]:
        """Get list of selected file paths."""
        return self.selected_files

# Convenience functions
fn create_open_file_dialog(x: Int32 = 100, y: Int32 = 100) -> FileDialogInt:
    """Create an open file dialog."""
    return FileDialogInt(x, y, 800, 600, FILE_DIALOG_OPEN)

fn create_save_file_dialog(x: Int32 = 100, y: Int32 = 100) -> FileDialogInt:
    """Create a save file dialog."""
    var dialog = FileDialogInt(x, y, 800, 600, FILE_DIALOG_SAVE)
    dialog.ok_button.set_text("Save")
    return dialog

fn create_folder_dialog(x: Int32 = 100, y: Int32 = 100) -> FileDialogInt:
    """Create a folder selection dialog."""
    var dialog = FileDialogInt(x, y, 800, 600, FILE_DIALOG_SELECT_FOLDER)
    dialog.ok_button.set_text("Select")
    return dialog