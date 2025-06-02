"""
Integer-Only Column Header Widget Implementation
Table column headers with sorting, resizing, and column menu support.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .widget_constants import *
from .contextmenu_int import ContextMenuInt

struct ColumnDefinition:
    """Column configuration and state."""
    var id: String
    var title: String
    var width: Int32
    var min_width: Int32
    var max_width: Int32
    var visible: Bool
    var sortable: Bool
    var resizable: Bool
    var movable: Bool
    var alignment: Int32
    var sort_order: Int32  # SORT_NONE, SORT_ASCENDING, SORT_DESCENDING
    var data_type: Int32   # For appropriate sorting
    var user_data: Int32
    
    fn __init__(inout self, id: String, title: String, width: Int32 = 100):
        self.id = id
        self.title = title
        self.width = width
        self.min_width = 50
        self.max_width = 500
        self.visible = True
        self.sortable = True
        self.resizable = True
        self.movable = True
        self.alignment = ALIGN_LEFT
        self.sort_order = SORT_NONE
        self.data_type = 0  # String by default
        self.user_data = 0

struct ColumnHeaderInt(BaseWidgetInt):
    """Column header widget for tables with sorting and resizing."""
    
    var columns: List[ColumnDefinition]
    var header_height: Int32
    var hover_column: Int32
    var pressed_column: Int32
    var resize_column: Int32
    var resize_start_x: Int32
    var resize_start_width: Int32
    var move_column: Int32
    var move_target: Int32
    var sort_column: Int32
    var show_column_menu: Bool
    var menu_column: Int32
    
    # Visual properties
    var resize_handle_width: Int32
    var sort_indicator_size: Int32
    var menu_button_width: Int32
    var padding: Int32
    var font_size: Int32
    
    # Colors
    var header_bg_color: ColorInt
    var header_hover_color: ColorInt
    var header_pressed_color: ColorInt
    var sort_indicator_color: ColorInt
    var resize_handle_color: ColorInt
    var separator_color: ColorInt
    var text_color: ColorInt
    
    # Column menu
    var column_menu: ContextMenuInt
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32 = 28):
        self.super().__init__(x, y, width, height)
        
        self.columns = List[ColumnDefinition]()
        self.header_height = height
        self.hover_column = -1
        self.pressed_column = -1
        self.resize_column = -1
        self.resize_start_x = 0
        self.resize_start_width = 0
        self.move_column = -1
        self.move_target = -1
        self.sort_column = -1
        self.show_column_menu = False
        self.menu_column = -1
        
        self.resize_handle_width = 8
        self.sort_indicator_size = 12
        self.menu_button_width = 16
        self.padding = 8
        self.font_size = 12
        
        # Colors
        self.header_bg_color = ColorInt(240, 240, 240, 255)
        self.header_hover_color = ColorInt(230, 230, 240, 255)
        self.header_pressed_color = ColorInt(220, 220, 230, 255)
        self.sort_indicator_color = ColorInt(100, 100, 100, 255)
        self.resize_handle_color = ColorInt(150, 150, 150, 255)
        self.separator_color = ColorInt(200, 200, 200, 255)
        self.text_color = ColorInt(0, 0, 0, 255)
        
        # Initialize column menu
        self.column_menu = ContextMenuInt()
        self.setup_column_menu()
        
        # Widget appearance
        self.background_color = self.header_bg_color
        self.border_color = ColorInt(180, 180, 180, 255)
        self.border_width = 1
    
    fn add_column(inout self, id: String, title: String, width: Int32 = 100,
                  sortable: Bool = True, resizable: Bool = True) -> Int32:
        """Add a column definition."""
        var column = ColumnDefinition(id, title, width)
        column.sortable = sortable
        column.resizable = resizable
        self.columns.append(column)
        return len(self.columns) - 1
    
    fn remove_column(inout self, column_id: String):
        """Remove a column by ID."""
        for i in range(len(self.columns)):
            if self.columns[i].id == column_id:
                self.columns.remove(i)
                break
    
    fn set_column_width(inout self, column_id: String, width: Int32):
        """Set column width."""
        for i in range(len(self.columns)):
            if self.columns[i].id == column_id:
                self.columns[i].width = max(self.columns[i].min_width,
                                           min(width, self.columns[i].max_width))
                break
    
    fn set_column_sort(inout self, column_id: String, sort_order: Int32):
        """Set column sort order."""
        for i in range(len(self.columns)):
            if self.columns[i].id == column_id:
                self.columns[i].sort_order = sort_order
                self.sort_column = i
            else:
                self.columns[i].sort_order = SORT_NONE
    
    fn get_column_rect(self, index: Int32) -> RectInt:
        """Get rectangle for a column header."""
        if index < 0 or index >= len(self.columns):
            return RectInt(0, 0, 0, 0)
        
        var x = self.bounds.x
        for i in range(index):
            if self.columns[i].visible:
                x += self.columns[i].width
        
        return RectInt(x, self.bounds.y, self.columns[index].width, self.bounds.height)
    
    fn get_resize_handle_rect(self, index: Int32) -> RectInt:
        """Get rectangle for column resize handle."""
        let col_rect = self.get_column_rect(index)
        let handle_x = col_rect.x + col_rect.width - self.resize_handle_width // 2
        return RectInt(handle_x, col_rect.y, self.resize_handle_width, col_rect.height)
    
    fn hit_test_resize_handle(self, x: Int32, y: Int32) -> Int32:
        """Check if position is over a resize handle."""
        for i in range(len(self.columns)):
            if self.columns[i].visible and self.columns[i].resizable:
                let handle_rect = self.get_resize_handle_rect(i)
                if handle_rect.contains(PointInt(x, y)):
                    return i
        return -1
    
    fn setup_column_menu(inout self):
        """Initialize column context menu."""
        _ = self.column_menu.add_item("Sort Ascending", 1, "sort-ascending")
        _ = self.column_menu.add_item("Sort Descending", 2, "sort-descending")
        _ = self.column_menu.add_separator()
        _ = self.column_menu.add_item("Auto-fit Column", 3, "auto-fit")
        _ = self.column_menu.add_item("Hide Column", 4, "hide")
        _ = self.column_menu.add_separator()
        _ = self.column_menu.add_item("Show All Columns", 5, "show-all")
        _ = self.column_menu.add_item("Column Settings...", 6, "settings")
    
    fn handle_menu_selection(inout self, menu_id: Int32):
        """Handle column menu selection."""
        if self.menu_column < 0 or self.menu_column >= len(self.columns):
            return
        
        let column = self.columns[self.menu_column]
        
        if menu_id == 1:  # Sort Ascending
            self.set_column_sort(column.id, SORT_ASCENDING)
        elif menu_id == 2:  # Sort Descending
            self.set_column_sort(column.id, SORT_DESCENDING)
        elif menu_id == 3:  # Auto-fit
            # Would calculate optimal width based on content
            pass
        elif menu_id == 4:  # Hide Column
            self.columns[self.menu_column].visible = False
        elif menu_id == 5:  # Show All
            for i in range(len(self.columns)):
                self.columns[i].visible = True
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        
        # Handle column menu
        if self.column_menu.is_open:
            if self.column_menu.handle_mouse_event(event):
                return True
        
        if not self.contains_point(point):
            return False
        
        # Check for resize handle
        let resize_col = self.hit_test_resize_handle(event.x, event.y)
        
        if event.pressed:
            if resize_col >= 0:
                # Start resizing
                self.resize_column = resize_col
                self.resize_start_x = event.x
                self.resize_start_width = self.columns[resize_col].width
                return True
            else:
                # Check which column was clicked
                for i in range(len(self.columns)):
                    if self.columns[i].visible:
                        let col_rect = self.get_column_rect(i)
                        if col_rect.contains(point):
                            self.pressed_column = i
                            
                            # Right-click shows menu
                            if event.button == MOUSE_BUTTON_RIGHT:
                                self.menu_column = i
                                self.column_menu.show(event.x, event.y, True)
                                return True
                            
                            return True
        else:
            # Mouse release
            if self.resize_column >= 0:
                # Finish resizing
                self.resize_column = -1
                return True
            elif self.pressed_column >= 0:
                # Check if still over same column (click completed)
                let col_rect = self.get_column_rect(self.pressed_column)
                if col_rect.contains(point) and self.columns[self.pressed_column].sortable:
                    # Toggle sort order
                    let column = self.columns[self.pressed_column]
                    var new_sort = SORT_ASCENDING
                    if column.sort_order == SORT_ASCENDING:
                        new_sort = SORT_DESCENDING
                    elif column.sort_order == SORT_DESCENDING:
                        new_sort = SORT_NONE
                    
                    self.set_column_sort(column.id, new_sort)
                
                self.pressed_column = -1
                return True
        
        # Handle dragging
        if self.resize_column >= 0:
            # Resize column
            let delta = event.x - self.resize_start_x
            let new_width = self.resize_start_width + delta
            self.columns[self.resize_column].width = max(self.columns[self.resize_column].min_width,
                                                        min(new_width, self.columns[self.resize_column].max_width))
            return True
        
        # Update hover state
        self.hover_column = -1
        for i in range(len(self.columns)):
            if self.columns[i].visible:
                let col_rect = self.get_column_rect(i)
                if col_rect.contains(point):
                    self.hover_column = i
                    break
        
        return True
    
    fn get_cursor_style(self, x: Int32, y: Int32) -> Int32:
        """Get appropriate cursor style for position."""
        if self.hit_test_resize_handle(x, y) >= 0:
            return 1  # Resize cursor
        return 0  # Default cursor
    
    fn render(self, ctx: RenderingContextInt):
        """Render column headers."""
        if not self.visible:
            return
        
        # Background
        _ = ctx.set_color(self.header_bg_color.r, self.header_bg_color.g,
                         self.header_bg_color.b, self.header_bg_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                     self.bounds.width, self.bounds.height)
        
        # Render each column
        for i in range(len(self.columns)):
            if self.columns[i].visible:
                self.render_column(ctx, i)
        
        # Bottom border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_line(self.bounds.x, self.bounds.y + self.bounds.height - 1,
                         self.bounds.x + self.bounds.width, self.bounds.y + self.bounds.height - 1, 1)
        
        # Render column menu if open
        if self.column_menu.is_open:
            self.column_menu.render(ctx)
    
    fn render_column(self, ctx: RenderingContextInt, index: Int32):
        """Render individual column header."""
        let column = self.columns[index]
        let rect = self.get_column_rect(index)
        
        # Column background
        if index == self.pressed_column:
            _ = ctx.set_color(self.header_pressed_color.r, self.header_pressed_color.g,
                             self.header_pressed_color.b, self.header_pressed_color.a)
            _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        elif index == self.hover_column:
            _ = ctx.set_color(self.header_hover_color.r, self.header_hover_color.g,
                             self.header_hover_color.b, self.header_hover_color.a)
            _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        # Column text
        _ = ctx.set_color(self.text_color.r, self.text_color.g,
                         self.text_color.b, self.text_color.a)
        
        var text_x = rect.x + self.padding
        let text_y = rect.y + (rect.height - self.font_size) // 2
        var max_text_width = rect.width - self.padding * 2
        
        # Account for sort indicator
        if column.sort_order != SORT_NONE:
            max_text_width -= self.sort_indicator_size + 4
        
        # Truncate text if needed
        var display_text = column.title
        let char_width = self.font_size * 6 // 10
        if len(display_text) * char_width > max_text_width:
            # Simple truncation
            while len(display_text) > 0 and 
                  len(display_text) * char_width > max_text_width - 20:
                display_text = display_text[:-1]
            if len(display_text) < len(column.title):
                display_text += "..."
        
        # Apply alignment
        if column.alignment == ALIGN_CENTER:
            let text_width = len(display_text) * char_width
            text_x = rect.x + (rect.width - text_width) // 2
        elif column.alignment == ALIGN_RIGHT:
            let text_width = len(display_text) * char_width
            text_x = rect.x + rect.width - text_width - self.padding
            if column.sort_order != SORT_NONE:
                text_x -= self.sort_indicator_size + 4
        
        _ = ctx.draw_text(display_text, text_x, text_y, self.font_size)
        
        # Sort indicator
        if column.sort_order != SORT_NONE:
            _ = ctx.set_color(self.sort_indicator_color.r, self.sort_indicator_color.g,
                             self.sort_indicator_color.b, self.sort_indicator_color.a)
            
            let arrow_x = rect.x + rect.width - self.padding - self.sort_indicator_size // 2
            let arrow_y = rect.y + rect.height // 2
            
            if column.sort_order == SORT_ASCENDING:
                # Up arrow
                _ = ctx.draw_line(arrow_x - 4, arrow_y + 2, arrow_x, arrow_y - 3, 2)
                _ = ctx.draw_line(arrow_x, arrow_y - 3, arrow_x + 4, arrow_y + 2, 2)
            else:
                # Down arrow
                _ = ctx.draw_line(arrow_x - 4, arrow_y - 2, arrow_x, arrow_y + 3, 2)
                _ = ctx.draw_line(arrow_x, arrow_y + 3, arrow_x + 4, arrow_y - 2, 2)
        
        # Column separator
        if index < len(self.columns) - 1:
            _ = ctx.set_color(self.separator_color.r, self.separator_color.g,
                             self.separator_color.b, self.separator_color.a)
            _ = ctx.draw_line(rect.x + rect.width - 1, rect.y + 4,
                             rect.x + rect.width - 1, rect.y + rect.height - 4, 1)
    
    fn update(inout self):
        """Update column header state."""
        self.column_menu.update()
    
    fn get_total_width(self) -> Int32:
        """Get total width of all visible columns."""
        var total = 0
        for i in range(len(self.columns)):
            if self.columns[i].visible:
                total += self.columns[i].width
        return total
    
    fn get_column_at_x(self, x: Int32) -> Int32:
        """Get column index at x coordinate."""
        var current_x = self.bounds.x
        for i in range(len(self.columns)):
            if self.columns[i].visible:
                if x >= current_x and x < current_x + self.columns[i].width:
                    return i
                current_x += self.columns[i].width
        return -1

# Convenience functions
fn create_column_header_int(x: Int32, y: Int32, width: Int32, height: Int32 = 28) -> ColumnHeaderInt:
    """Create a column header widget."""
    return ColumnHeaderInt(x, y, width, height)

fn create_table_columns() -> ColumnHeaderInt:
    """Create a typical table column header."""
    var header = ColumnHeaderInt(0, 0, 800, 28)
    
    # Add common columns
    _ = header.add_column("name", "Name", 250)
    _ = header.add_column("size", "Size", 100)
    _ = header.add_column("type", "Type", 150)
    _ = header.add_column("modified", "Date Modified", 150)
    
    # Set alignments
    header.columns[1].alignment = ALIGN_RIGHT  # Size
    header.columns[3].alignment = ALIGN_CENTER  # Date
    
    return header