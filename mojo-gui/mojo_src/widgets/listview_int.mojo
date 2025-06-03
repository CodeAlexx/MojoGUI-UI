"""
Integer-Only ListView Widget Implementation
Advanced list widget with columns, sorting, and selection using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from ..theme_system import get_theme

# ListView styles
alias LISTVIEW_STYLE_LIST = 0
alias LISTVIEW_STYLE_REPORT = 1  # With columns
alias LISTVIEW_STYLE_ICONS = 2

# Selection modes
alias SELECTION_NONE = 0
alias SELECTION_SINGLE = 1
alias SELECTION_MULTIPLE = 2

# Sort orders
alias SORT_NONE = 0
alias SORT_ASCENDING = 1
alias SORT_DESCENDING = 2

struct ListColumn:
    """Column definition for report view."""
    var title: String
    var width: Int32
    var min_width: Int32
    var alignment: Int32
    var sortable: Bool
    var sort_order: Int32
    
    fn __init__(inout self, title: String, width: Int32):
        self.title = title
        self.width = width
        self.min_width = 50
        self.alignment = ALIGN_START
        self.sortable = True
        self.sort_order = SORT_NONE

struct ListItem:
    """List item with multiple column values."""
    var item_id: Int32
    var text: String
    var sub_items: List[String]  # Additional column text
    var selected: Bool
    var data: Int32  # User data
    var icon_id: Int32
    var height: Int32
    
    fn __init__(inout self, id: Int32, text: String):
        self.item_id = id
        self.text = text
        self.sub_items = List[String]()
        self.selected = False
        self.data = 0
        self.icon_id = -1
        self.height = 24

struct ListViewInt(BaseWidgetInt):
    """Advanced ListView widget with columns and sorting."""
    
    var style: Int32
    var selection_mode: Int32
    var item_height: Int32
    var header_height: Int32
    var show_header: Bool
    var show_grid_lines: Bool
    var alternate_row_colors: Bool
    var font_size: Int32
    
    var items: List[ListItem]
    var columns: List[ListColumn]
    var item_count: Int32
    var column_count: Int32
    var selected_count: Int32
    var focused_item: Int32
    var first_visible_item: Int32
    var visible_item_count: Int32
    
    # Colors
    var item_color: ColorInt
    var alternate_color: ColorInt
    var selected_color: ColorInt
    var focused_color: ColorInt
    var header_color: ColorInt
    var grid_color: ColorInt
    var text_color: ColorInt
    var selected_text_color: ColorInt
    
    # Scrolling
    var vertical_scroll: Int32
    var horizontal_scroll: Int32
    var scroll_width: Int32
    var scroll_height: Int32
    
    # Interaction
    var last_click_item: Int32
    var last_click_time: Int32
    var drag_start_x: Int32
    var drag_start_y: Int32
    var is_dragging: Bool
    var column_resize_index: Int32
    var is_resizing_column: Bool
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, 
               style: Int32 = LISTVIEW_STYLE_REPORT):
        """Initialize ListView."""
        self.super().__init__(x, y, width, height)
        
        self.style = style
        self.selection_mode = SELECTION_SINGLE
        self.item_height = 24
        self.header_height = 26
        self.show_header = (style == LISTVIEW_STYLE_REPORT)
        self.show_grid_lines = True
        self.alternate_row_colors = True
        self.font_size = 12
        
        self.items = List[ListItem]()
        self.columns = List[ListColumn]()
        self.item_count = 0
        self.column_count = 0
        self.selected_count = 0
        self.focused_item = -1
        self.first_visible_item = 0
        
        # Calculate visible items
        let content_height = height - (self.header_height if self.show_header else 0)
        self.visible_item_count = content_height // self.item_height
        
        # Set colors using theme system
        let theme = get_theme()
        self.item_color = theme.primary_bg
        self.alternate_color = theme.secondary_bg
        self.selected_color = theme.selection_bg
        self.focused_color = theme.highlight_bg
        self.header_color = theme.tertiary_bg
        self.grid_color = theme.divider_color
        self.text_color = theme.primary_text
        self.selected_text_color = theme.selection_text
        
        # Set widget appearance using theme
        self.background_color = theme.surface_bg
        self.border_color = theme.primary_border
        self.border_width = 1
        
        # Initialize scroll and interaction
        self.vertical_scroll = 0
        self.horizontal_scroll = 0
        self.scroll_width = 0
        self.scroll_height = 0
        self.last_click_item = -1
        self.last_click_time = 0
        self.drag_start_x = 0
        self.drag_start_y = 0
        self.is_dragging = False
        self.column_resize_index = -1
        self.is_resizing_column = False
    
    fn add_column(inout self, title: String, width: Int32) -> Int32:
        """Add a column to the ListView."""
        var column = ListColumn(title, width)
        self.columns.append(column)
        self.column_count += 1
        return self.column_count - 1
    
    fn set_column_width(inout self, column_index: Int32, width: Int32):
        """Set the width of a specific column."""
        if column_index >= 0 and column_index < self.column_count:
            if width >= self.columns[column_index].min_width:
                self.columns[column_index].width = width
    
    fn add_item(inout self, text: String, data: Int32 = 0) -> Int32:
        """Add an item to the ListView."""
        var item = ListItem(self.item_count, text)
        item.data = data
        self.items.append(item)
        self.item_count += 1
        return self.item_count - 1
    
    fn set_item_text(inout self, item_index: Int32, column_index: Int32, text: String):
        """Set text for a specific item and column."""
        if item_index >= 0 and item_index < self.item_count:
            if column_index == 0:
                self.items[item_index].text = text
            else:
                # Ensure sub_items list is large enough
                while len(self.items[item_index].sub_items) <= column_index - 1:
                    self.items[item_index].sub_items.append("")
                self.items[item_index].sub_items[column_index - 1] = text
    
    fn get_item_text(self, item_index: Int32, column_index: Int32) -> String:
        """Get text for a specific item and column."""
        if item_index >= 0 and item_index < self.item_count:
            if column_index == 0:
                return self.items[item_index].text
            elif column_index - 1 < len(self.items[item_index].sub_items):
                return self.items[item_index].sub_items[column_index - 1]
        return ""
    
    fn select_item(inout self, item_index: Int32, selected: Bool = True):
        """Select or deselect an item."""
        if item_index >= 0 and item_index < self.item_count:
            if self.selection_mode == SELECTION_NONE:
                return
            
            # Clear other selections if single selection mode
            if self.selection_mode == SELECTION_SINGLE and selected:
                self.clear_selection()
            
            let was_selected = self.items[item_index].selected
            self.items[item_index].selected = selected
            
            # Update selection count
            if selected and not was_selected:
                self.selected_count += 1
            elif not selected and was_selected:
                self.selected_count -= 1
            
            # Set focused item
            if selected:
                self.focused_item = item_index
    
    fn clear_selection(inout self):
        """Clear all selections."""
        for i in range(self.item_count):
            self.items[i].selected = False
        self.selected_count = 0
        self.focused_item = -1
    
    fn get_selected_items(self) -> List[Int32]:
        """Get list of selected item indices."""
        var selected = List[Int32]()
        for i in range(self.item_count):
            if self.items[i].selected:
                selected.append(i)
        return selected
    
    fn get_first_selected_item(self) -> Int32:
        """Get the first selected item index."""
        for i in range(self.item_count):
            if self.items[i].selected:
                return i
        return -1
    
    fn remove_item(inout self, item_index: Int32):
        """Remove an item from the ListView."""
        if item_index >= 0 and item_index < self.item_count:
            if self.items[item_index].selected:
                self.selected_count -= 1
            # Simplified removal - just mark as invisible
            # In a full implementation, would shift items
            self.items[item_index].height = 0
    
    fn sort_items(inout self, column_index: Int32, ascending: Bool = True):
        """Sort items by the specified column."""
        if column_index >= 0 and column_index < self.column_count:
            # Update column sort indicators
            for i in range(self.column_count):
                if i == column_index:
                    self.columns[i].sort_order = SORT_ASCENDING if ascending else SORT_DESCENDING
                else:
                    self.columns[i].sort_order = SORT_NONE
            
            # Simplified sort - in a full implementation would actually sort the items list
            # This would require a proper sorting algorithm implementation
    
    fn ensure_visible(inout self, item_index: Int32):
        """Ensure the specified item is visible by scrolling if necessary."""
        if item_index < 0 or item_index >= self.item_count:
            return
        
        if item_index < self.first_visible_item:
            self.first_visible_item = item_index
        elif item_index >= self.first_visible_item + self.visible_item_count:
            self.first_visible_item = item_index - self.visible_item_count + 1
        
        # Ensure we don't scroll past the end
        let max_first = self.item_count - self.visible_item_count
        if self.first_visible_item > max_first:
            self.first_visible_item = max_first
        if self.first_visible_item < 0:
            self.first_visible_item = 0
    
    fn hit_test_item(self, x: Int32, y: Int32) -> Int32:
        """Get the item index at the specified coordinates."""
        if not self._point_in_bounds(PointInt(x, y)):
            return -1
        
        let content_y = self.y + (self.header_height if self.show_header else 0)
        if y < content_y:
            return -1  # Clicked in header
        
        let relative_y = y - content_y
        let item_index = self.first_visible_item + (relative_y // self.item_height)
        
        if item_index >= 0 and item_index < self.item_count:
            return item_index
        return -1
    
    fn hit_test_column(self, x: Int32, y: Int32) -> Int32:
        """Get the column index at the specified coordinates."""
        if not self.show_header or y > self.y + self.header_height:
            return -1
        
        let relative_x = x - self.x
        var current_x = 0
        
        for i in range(self.column_count):
            current_x += self.columns[i].width
            if relative_x <= current_x:
                return i
        
        return -1
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events for the ListView."""
        if not self._point_in_bounds(PointInt(event.x, event.y)):
            return False
        
        if event.pressed:
            if self.show_header and event.y <= self.y + self.header_height:
                # Header click - handle column sorting or resizing
                let column_index = self.hit_test_column(event.x, event.y)
                if column_index >= 0:
                    # Toggle sort order for this column
                    let ascending = self.columns[column_index].sort_order != SORT_ASCENDING
                    self.sort_items(column_index, ascending)
                    return True
            else:
                # Item click
                let item_index = self.hit_test_item(event.x, event.y)
                if item_index >= 0:
                    # Handle selection based on mode
                    if self.selection_mode == SELECTION_SINGLE:
                        self.clear_selection()
                        self.select_item(item_index, True)
                    elif self.selection_mode == SELECTION_MULTIPLE:
                        # Toggle selection
                        self.select_item(item_index, not self.items[item_index].selected)
                    
                    self.ensure_visible(item_index)
                    return True
        
        return False
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle keyboard events for the ListView."""
        if not event.pressed or self.focused_item < 0:
            return False
        
        var new_focus = self.focused_item
        
        if event.key_code == 264:  # Down arrow
            new_focus = self.focused_item + 1
        elif event.key_code == 265:  # Up arrow
            new_focus = self.focused_item - 1
        elif event.key_code == 266:  # Page Down
            new_focus = self.focused_item + self.visible_item_count
        elif event.key_code == 267:  # Page Up
            new_focus = self.focused_item - self.visible_item_count
        elif event.key_code == 268:  # Home
            new_focus = 0
        elif event.key_code == 269:  # End
            new_focus = self.item_count - 1
        elif event.key_code == 32:  # Space - toggle selection
            if self.selection_mode == SELECTION_MULTIPLE:
                self.select_item(self.focused_item, not self.items[self.focused_item].selected)
            return True
        else:
            return False
        
        # Clamp to valid range
        if new_focus < 0:
            new_focus = 0
        elif new_focus >= self.item_count:
            new_focus = self.item_count - 1
        
        if new_focus != self.focused_item:
            if self.selection_mode == SELECTION_SINGLE:
                self.clear_selection()
                self.select_item(new_focus, True)
            else:
                self.focused_item = new_focus
            
            self.ensure_visible(new_focus)
            return True
        
        return False
    
    fn draw(self, ctx: RenderingContextInt):
        """Draw the ListView."""
        # Draw background
        self._draw_background(ctx)
        
        # Draw header
        if self.show_header:
            self._draw_header(ctx)
        
        # Draw items
        self._draw_items(ctx)
        
        # Draw border
        self._draw_border(ctx)
    
    fn _draw_header(self, ctx: RenderingContextInt):
        """Draw the column headers."""
        let header_y = self.y
        var current_x = self.x
        
        # Header background
        _ = ctx.set_color(self.header_color.r, self.header_color.g, self.header_color.b, self.header_color.a)
        _ = ctx.draw_filled_rectangle(self.x, header_y, self.width, self.header_height)
        
        # Draw column headers
        for i in range(self.column_count):
            # Column background (if selected for sorting)
            if self.columns[i].sort_order != SORT_NONE:
                _ = ctx.set_color(220, 220, 240, 255)  # Light blue tint
                _ = ctx.draw_filled_rectangle(current_x, header_y, self.columns[i].width, self.header_height)
            
            # Column text
            _ = ctx.set_color(self.text_color.r, self.text_color.g, self.text_color.b, self.text_color.a)
            _ = ctx.draw_text(self.columns[i].title, current_x + 4, header_y + 6, self.font_size)
            
            # Sort indicator
            if self.columns[i].sort_order == SORT_ASCENDING:
                _ = ctx.draw_text("↑", current_x + self.columns[i].width - 16, header_y + 6, self.font_size)
            elif self.columns[i].sort_order == SORT_DESCENDING:
                _ = ctx.draw_text("↓", current_x + self.columns[i].width - 16, header_y + 6, self.font_size)
            
            # Column separator
            if i < self.column_count - 1:
                _ = ctx.set_color(self.grid_color.r, self.grid_color.g, self.grid_color.b, self.grid_color.a)
                _ = ctx.draw_filled_rectangle(current_x + self.columns[i].width - 1, header_y, 1, self.header_height)
            
            current_x += self.columns[i].width
    
    fn _draw_items(self, ctx: RenderingContextInt):
        """Draw the list items."""
        let content_y = self.y + (self.header_height if self.show_header else 0)
        let content_height = self.height - (self.header_height if self.show_header else 0)
        
        # Set clipping region (simplified - actual implementation would use OpenGL clipping)
        let start_item = self.first_visible_item
        let end_item = min(start_item + self.visible_item_count, self.item_count)
        
        for i in range(start_item, end_item):
            let item_y = content_y + (i - start_item) * self.item_height
            
            # Item background
            var bg_color = self.item_color
            if self.alternate_row_colors and i % 2 == 1:
                bg_color = self.alternate_color
            if self.items[i].selected:
                bg_color = self.selected_color
            elif i == self.focused_item:
                bg_color = self.focused_color
            
            _ = ctx.set_color(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
            _ = ctx.draw_filled_rectangle(self.x, item_y, self.width, self.item_height)
            
            # Item text
            let text_color = self.selected_text_color if self.items[i].selected else self.text_color
            _ = ctx.set_color(text_color.r, text_color.g, text_color.b, text_color.a)
            
            var current_x = self.x + 4
            
            if self.style == LISTVIEW_STYLE_REPORT and self.column_count > 0:
                # Draw text in columns
                for col in range(self.column_count):
                    let text = self.get_item_text(i, col)
                    _ = ctx.draw_text(text, current_x, item_y + 4, self.font_size)
                    
                    # Column separator
                    if col < self.column_count - 1 and self.show_grid_lines:
                        _ = ctx.set_color(self.grid_color.r, self.grid_color.g, self.grid_color.b, self.grid_color.a)
                        _ = ctx.draw_filled_rectangle(current_x + self.columns[col].width - 1, item_y, 1, self.item_height)
                    
                    current_x += self.columns[col].width
            else:
                # Simple list style
                _ = ctx.draw_text(self.items[i].text, current_x, item_y + 4, self.font_size)
            
            # Grid lines
            if self.show_grid_lines:
                _ = ctx.set_color(self.grid_color.r, self.grid_color.g, self.grid_color.b, self.grid_color.a)
                _ = ctx.draw_filled_rectangle(self.x, item_y + self.item_height - 1, self.width, 1)
    
    fn get_item_count(self) -> Int32:
        """Get the total number of items."""
        return self.item_count
    
    fn get_selected_count(self) -> Int32:
        """Get the number of selected items."""
        return self.selected_count

# Convenience functions
fn create_simple_listview(x: Int32, y: Int32, width: Int32, height: Int32) -> ListViewInt:
    """Create a simple ListView without columns."""
    return ListViewInt(x, y, width, height, LISTVIEW_STYLE_LIST)

fn create_report_listview(x: Int32, y: Int32, width: Int32, height: Int32) -> ListViewInt:
    """Create a ListView with column headers."""
    return ListViewInt(x, y, width, height, LISTVIEW_STYLE_REPORT)