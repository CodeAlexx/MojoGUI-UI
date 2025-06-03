"""
Integer-Only ListBox Widget Implementation
Scrollable list selection widget using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from ..theme_state_integration import get_theme

struct ListItemInt:
    """Individual list item."""
    var text: String
    var data: Int32  # Optional data associated with item
    var enabled: Bool
    
    fn __init__(inout self, text: String, data: Int32 = 0):
        self.text = text
        self.data = data
        self.enabled = True

struct ListBoxInt(BaseWidgetInt):
    """Scrollable list box widget using integer coordinates."""
    
    var items: List[ListItemInt]
    var selected_index: Int32
    var scroll_offset: Int32
    var item_height: Int32
    var visible_items: Int32
    var text_color: ColorInt
    var selected_color: ColorInt
    var selected_text_color: ColorInt
    var hover_color: ColorInt
    var font_size: Int32
    var padding: Int32
    var hover_index: Int32
    var allow_multiple_selection: Bool
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        """Initialize list box."""
        self.super().__init__(x, y, width, height)
        self.items = List[ListItemInt]()
        self.selected_index = -1
        self.scroll_offset = 0
        self.item_height = 20
        self.visible_items = (height - 4) // self.item_height  # Account for borders
        
        let theme = get_theme()
        self.text_color = theme.primary_text
        self.selected_color = theme.selection_background
        self.selected_text_color = theme.selection_text
        self.hover_color = theme.selection_hover
        self.font_size = 12
        self.padding = 4
        self.hover_index = -1
        self.allow_multiple_selection = False
        
        # Set appearance
        self.background_color = theme.widget_background
        self.border_color = theme.primary_border
        self.border_width = 2
    
    fn add_item(inout self, text: String, data: Int32 = 0):
        """Add item to list."""
        self.items.append(ListItemInt(text, data))
    
    fn remove_item(inout self, index: Int32):
        """Remove item at index."""
        if index >= 0 and index < len(self.items):
            # Note: List.remove() might not exist yet, so we'd need to implement
            # For now, we'll mark as disabled or implement a custom removal
            if index < len(self.items):
                self.items[index].enabled = False
                self.items[index].text = ""
    
    fn clear_items(inout self):
        """Clear all items."""
        self.items.clear()
        self.selected_index = -1
        self.scroll_offset = 0
        self.hover_index = -1
    
    fn get_item_count(self) -> Int32:
        """Get number of items."""
        return len(self.items)
    
    fn get_selected_index(self) -> Int32:
        """Get selected item index."""
        return self.selected_index
    
    fn set_selected_index(inout self, index: Int32):
        """Set selected item index."""
        if index >= -1 and index < len(self.items):
            self.selected_index = index
            # Ensure selected item is visible
            self.ensure_visible(index)
    
    fn get_selected_text(self) -> String:
        """Get selected item text."""
        if self.selected_index >= 0 and self.selected_index < len(self.items):
            return self.items[self.selected_index].text
        return ""
    
    fn get_selected_data(self) -> Int32:
        """Get selected item data."""
        if self.selected_index >= 0 and self.selected_index < len(self.items):
            return self.items[self.selected_index].data
        return 0
    
    fn ensure_visible(inout self, index: Int32):
        """Ensure item at index is visible."""
        if index < 0 or index >= len(self.items):
            return
        
        if index < self.scroll_offset:
            self.scroll_offset = index
        elif index >= self.scroll_offset + self.visible_items:
            self.scroll_offset = index - self.visible_items + 1
            
        # Clamp scroll offset
        let max_scroll = len(self.items) - self.visible_items
        if self.scroll_offset > max_scroll:
            self.scroll_offset = max_scroll
        if self.scroll_offset < 0:
            self.scroll_offset = 0
    
    fn scroll_up(inout self):
        """Scroll up by one item."""
        if self.scroll_offset > 0:
            self.scroll_offset -= 1
    
    fn scroll_down(inout self):
        """Scroll down by one item."""
        let max_scroll = len(self.items) - self.visible_items
        if self.scroll_offset < max_scroll:
            self.scroll_offset += 1
    
    fn get_item_rect(self, item_index: Int32) -> RectInt:
        """Get rectangle for item at given index."""
        let relative_index = item_index - self.scroll_offset
        let item_y = self.bounds.y + self.border_width + relative_index * self.item_height
        return RectInt(self.bounds.x + self.border_width, item_y,
                      self.bounds.width - 2 * self.border_width, self.item_height)
    
    fn get_content_rect(self) -> RectInt:
        """Get the content area rectangle."""
        return RectInt(self.bounds.x + self.border_width, self.bounds.y + self.border_width,
                      self.bounds.width - 2 * self.border_width, self.bounds.height - 2 * self.border_width)
    
    fn item_index_from_point(self, point: PointInt) -> Int32:
        """Get item index from point coordinates."""
        let content = self.get_content_rect()
        if not content.contains(point):
            return -1
        
        let relative_y = point.y - content.y
        let item_index = self.scroll_offset + relative_y // self.item_height
        
        if item_index >= 0 and item_index < len(self.items):
            return item_index
        return -1
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        let inside = self.contains_point(point)
        
        if inside:
            let item_index = self.item_index_from_point(point)
            
            if event.pressed and item_index >= 0:
                # Select item
                if self.items[item_index].enabled:
                    self.set_selected_index(item_index)
                return True
            else:
                # Update hover
                self.hover_index = item_index
        else:
            self.hover_index = -1
        
        return inside
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle key events (arrow keys, page up/down)."""
        if not self.visible or not self.enabled:
            return False
        
        if event.pressed:
            if event.key_code == 265:  # Up arrow
                if self.selected_index > 0:
                    self.set_selected_index(self.selected_index - 1)
                return True
            elif event.key_code == 264:  # Down arrow
                if self.selected_index < len(self.items) - 1:
                    self.set_selected_index(self.selected_index + 1)
                return True
            elif event.key_code == 266:  # Page Up
                let new_index = max(0, self.selected_index - self.visible_items)
                self.set_selected_index(new_index)
                return True
            elif event.key_code == 267:  # Page Down
                let new_index = min(len(self.items) - 1, self.selected_index + self.visible_items)
                self.set_selected_index(new_index)
                return True
            elif event.key_code == 268:  # Home
                self.set_selected_index(0)
                return True
            elif event.key_code == 269:  # End
                self.set_selected_index(len(self.items) - 1)
                return True
        
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render the list box."""
        if not self.visible:
            return
        
        # Draw background and border
        self.render_background(ctx)
        
        let content = self.get_content_rect()
        
        # Set clipping to content area (simplified - just be careful with drawing)
        let end_index = min(len(self.items), self.scroll_offset + self.visible_items)
        
        # Draw visible items
        for i in range(self.scroll_offset, end_index):
            if i >= len(self.items) or not self.items[i].enabled:
                continue
                
            let item_rect = self.get_item_rect(i)
            let is_selected = (i == self.selected_index)
            let is_hover = (i == self.hover_index) and not is_selected
            
            # Draw item background
            if is_selected:
                _ = ctx.set_color(self.selected_color.r, self.selected_color.g, 
                                 self.selected_color.b, self.selected_color.a)
                _ = ctx.draw_filled_rectangle(item_rect.x, item_rect.y, item_rect.width, item_rect.height)
            elif is_hover:
                _ = ctx.set_color(self.hover_color.r, self.hover_color.g, 
                                 self.hover_color.b, self.hover_color.a)
                _ = ctx.draw_filled_rectangle(item_rect.x, item_rect.y, item_rect.width, item_rect.height)
            
            # Draw item text
            let text_color = self.selected_text_color if is_selected else self.text_color
            _ = ctx.set_color(text_color.r, text_color.g, text_color.b, text_color.a)
            
            let text_x = item_rect.x + self.padding
            let text_y = item_rect.y + (item_rect.height - self.font_size) // 2
            _ = ctx.draw_text(self.items[i].text, text_x, text_y, self.font_size)
        
        # Draw scrollbar if needed
        if len(self.items) > self.visible_items:
            self.render_scrollbar(ctx)
    
    fn render_scrollbar(self, ctx: RenderingContextInt):
        """Render scrollbar when needed."""
        let scrollbar_width = 12
        let scrollbar_x = self.bounds.x + self.bounds.width - scrollbar_width - 1
        let content = self.get_content_rect()
        
        # Draw scrollbar track
        let theme = get_theme()
        _ = ctx.set_color(theme.widget_background.r, theme.widget_background.g, theme.widget_background.b, theme.widget_background.a)
        _ = ctx.draw_filled_rectangle(scrollbar_x, content.y, scrollbar_width, content.height)
        
        # Calculate thumb size and position
        let total_items = len(self.items)
        let thumb_height = max(20, content.height * self.visible_items // total_items)
        let thumb_y = content.y + content.height * self.scroll_offset // total_items
        
        # Draw scrollbar thumb
        _ = ctx.set_color(theme.secondary_border.r, theme.secondary_border.g, theme.secondary_border.b, theme.secondary_border.a)
        _ = ctx.draw_filled_rectangle(scrollbar_x + 1, thumb_y, scrollbar_width - 2, thumb_height)
        
        # Draw scrollbar border
        _ = ctx.set_color(theme.primary_border.r, theme.primary_border.g, theme.primary_border.b, theme.primary_border.a)
        _ = ctx.draw_rectangle(scrollbar_x, content.y, scrollbar_width, content.height)
    
    fn update(inout self):
        """Update list box state."""
        # Nothing special to update for basic list box
        pass

# Convenience constructor functions
fn create_listbox_int(x: Int32, y: Int32, width: Int32, height: Int32) -> ListBoxInt:
    """Create a standard list box."""
    return ListBoxInt(x, y, width, height)

fn create_simple_list_int(x: Int32, y: Int32, width: Int32, items: List[String]) -> ListBoxInt:
    """Create a list box with predefined items."""
    var listbox = ListBoxInt(x, y, width, len(items) * 20 + 4)  # Auto-size height
    for i in range(len(items)):
        listbox.add_item(items[i], i)
    return listbox