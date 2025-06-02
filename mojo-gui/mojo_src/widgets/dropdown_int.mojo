"""
Integer-Only Dropdown/ComboBox Widget Implementation
Dropdown selection widget with customizable items.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .widget_constants import *

struct DropdownItem:
    """Individual dropdown item."""
    var text: String
    var icon: String
    var data: Int32
    var enabled: Bool
    
    fn __init__(inout self, text: String, icon: String = "", data: Int32 = 0):
        self.text = text
        self.icon = icon
        self.data = data
        self.enabled = True

struct DropdownInt(BaseWidgetInt):
    """Dropdown/ComboBox widget."""
    
    var items: List[DropdownItem]
    var selected_index: Int32
    var is_open: Bool
    var hover_index: Int32
    var max_visible_items: Int32
    var scroll_offset: Int32
    var editable: Bool
    var edit_text: String
    
    # Visual properties
    var item_height: Int32
    var dropdown_button_width: Int32
    var icon_size: Int32
    var padding: Int32
    var font_size: Int32
    
    # Colors
    var text_color: ColorInt
    var disabled_text_color: ColorInt
    var dropdown_bg_color: ColorInt
    var item_hover_color: ColorInt
    var item_selected_color: ColorInt
    var button_color: ColorInt
    var button_hover_color: ColorInt
    var arrow_color: ColorInt
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32 = 25):
        self.super().__init__(x, y, width, height)
        
        self.items = List[DropdownItem]()
        self.selected_index = -1
        self.is_open = False
        self.hover_index = -1
        self.max_visible_items = 8
        self.scroll_offset = 0
        self.editable = False
        self.edit_text = ""
        
        self.item_height = 24
        self.dropdown_button_width = 20
        self.icon_size = 16
        self.padding = 8
        self.font_size = 12
        
        # Colors
        self.text_color = ColorInt(0, 0, 0, 255)
        self.disabled_text_color = ColorInt(128, 128, 128, 255)
        self.dropdown_bg_color = ColorInt(255, 255, 255, 255)
        self.item_hover_color = ColorInt(229, 243, 255, 255)
        self.item_selected_color = ColorInt(0, 120, 215, 255)
        self.button_color = ColorInt(240, 240, 240, 255)
        self.button_hover_color = ColorInt(220, 220, 220, 255)
        self.arrow_color = ColorInt(60, 60, 60, 255)
        
        # Widget appearance
        self.background_color = ColorInt(255, 255, 255, 255)
        self.border_color = ColorInt(180, 180, 180, 255)
        self.border_width = 1
    
    fn add_item(inout self, text: String, icon: String = "", data: Int32 = 0):
        """Add an item to the dropdown."""
        self.items.append(DropdownItem(text, icon, data))
        
        # Select first item if none selected
        if self.selected_index < 0 and len(self.items) == 1:
            self.selected_index = 0
    
    fn clear(inout self):
        """Clear all items."""
        self.items.clear()
        self.selected_index = -1
        self.hover_index = -1
        self.scroll_offset = 0
        self.edit_text = ""
    
    fn get_selected_index(self) -> Int32:
        """Get selected item index."""
        return self.selected_index
    
    fn get_selected_text(self) -> String:
        """Get selected item text."""
        if self.editable and len(self.edit_text) > 0:
            return self.edit_text
        elif self.selected_index >= 0 and self.selected_index < len(self.items):
            return self.items[self.selected_index].text
        return ""
    
    fn set_selected_index(inout self, index: Int32):
        """Set selected item by index."""
        if index >= -1 and index < len(self.items):
            self.selected_index = index
            if index >= 0:
                self.edit_text = self.items[index].text
            else:
                self.edit_text = ""
    
    fn set_selected_text(inout self, text: String):
        """Set selected item by text."""
        for i in range(len(self.items)):
            if self.items[i].text == text:
                self.set_selected_index(i)
                return
        
        # If not found and editable, set as edit text
        if self.editable:
            self.edit_text = text
            self.selected_index = -1
    
    fn get_dropdown_rect(self) -> RectInt:
        """Get dropdown list rectangle."""
        let visible_items = min(len(self.items), self.max_visible_items)
        let height = visible_items * self.item_height + 4
        
        # Position below or above based on available space
        let below_y = self.bounds.y + self.bounds.height
        # In real implementation, would check screen bounds
        
        return RectInt(self.bounds.x, below_y, self.bounds.width, height)
    
    fn get_item_rect(self, index: Int32) -> RectInt:
        """Get rectangle for dropdown item."""
        let dropdown_rect = self.get_dropdown_rect()
        let visible_index = index - self.scroll_offset
        
        if visible_index < 0 or visible_index >= self.max_visible_items:
            return RectInt(0, 0, 0, 0)
        
        return RectInt(dropdown_rect.x + 2, 
                      dropdown_rect.y + 2 + visible_index * self.item_height,
                      dropdown_rect.width - 4, self.item_height)
    
    fn ensure_selected_visible(inout self):
        """Ensure selected item is visible when dropdown opens."""
        if self.selected_index < 0:
            return
        
        if self.selected_index < self.scroll_offset:
            self.scroll_offset = self.selected_index
        elif self.selected_index >= self.scroll_offset + self.max_visible_items:
            self.scroll_offset = self.selected_index - self.max_visible_items + 1
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        
        # Handle dropdown list if open
        if self.is_open:
            let dropdown_rect = self.get_dropdown_rect()
            if dropdown_rect.contains(point):
                # Find which item
                for i in range(self.scroll_offset, 
                              min(self.scroll_offset + self.max_visible_items, len(self.items))):
                    let item_rect = self.get_item_rect(i)
                    if item_rect.contains(point):
                        self.hover_index = i
                        
                        if event.pressed and self.items[i].enabled:
                            self.set_selected_index(i)
                            self.is_open = False
                            return True
                        
                        return True
                
                return True
            elif event.pressed:
                # Click outside closes dropdown
                self.is_open = False
                return False
        
        # Handle main control
        if self.contains_point(point):
            if event.pressed:
                self.is_open = not self.is_open
                if self.is_open:
                    self.ensure_selected_visible()
                    self.hover_index = self.selected_index
                else:
                    self.hover_index = -1
            
            return True
        
        return False
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle keyboard events."""
        if not self.visible or not self.enabled:
            return False
        
        if not event.pressed:
            return False
        
        let key = event.key_code
        
        if self.is_open:
            if key == KEY_UP:
                if self.hover_index > 0:
                    self.hover_index -= 1
                    # Scroll if needed
                    if self.hover_index < self.scroll_offset:
                        self.scroll_offset = self.hover_index
                return True
            elif key == KEY_DOWN:
                if self.hover_index < len(self.items) - 1:
                    self.hover_index += 1
                    # Scroll if needed
                    if self.hover_index >= self.scroll_offset + self.max_visible_items:
                        self.scroll_offset = self.hover_index - self.max_visible_items + 1
                return True
            elif key == KEY_ENTER:
                if self.hover_index >= 0 and self.hover_index < len(self.items):
                    self.set_selected_index(self.hover_index)
                self.is_open = False
                return True
            elif key == KEY_ESCAPE:
                self.is_open = False
                self.hover_index = -1
                return True
        else:
            if key == KEY_SPACE or key == KEY_ENTER:
                self.is_open = True
                self.ensure_selected_visible()
                self.hover_index = self.selected_index
                return True
            elif self.editable and event.is_printable():
                # Handle text input for editable dropdown
                self.edit_text += chr(event.char_code)
                return True
        
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render dropdown."""
        if not self.visible:
            return
        
        # Main control background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                     self.bounds.width, self.bounds.height)
        
        # Selected item text
        var display_text = self.get_selected_text()
        if len(display_text) > 0:
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
        else:
            _ = ctx.set_color(self.disabled_text_color.r, self.disabled_text_color.g,
                             self.disabled_text_color.b, self.disabled_text_color.a)
            display_text = "Select..."
        
        let text_y = self.bounds.y + (self.bounds.height - self.font_size) // 2
        _ = ctx.draw_text(display_text, self.bounds.x + self.padding, text_y, self.font_size)
        
        # Dropdown button
        let button_x = self.bounds.x + self.bounds.width - self.dropdown_button_width
        let button_color = self.button_hover_color if self.is_open else self.button_color
        
        _ = ctx.set_color(button_color.r, button_color.g, button_color.b, button_color.a)
        _ = ctx.draw_filled_rectangle(button_x, self.bounds.y, 
                                     self.dropdown_button_width, self.bounds.height)
        
        # Arrow
        _ = ctx.set_color(self.arrow_color.r, self.arrow_color.g,
                         self.arrow_color.b, self.arrow_color.a)
        let arrow_x = button_x + self.dropdown_button_width // 2
        let arrow_y = self.bounds.y + self.bounds.height // 2
        
        if self.is_open:
            # Up arrow
            _ = ctx.draw_line(arrow_x - 4, arrow_y + 2, arrow_x, arrow_y - 2, 2)
            _ = ctx.draw_line(arrow_x, arrow_y - 2, arrow_x + 4, arrow_y + 2, 2)
        else:
            # Down arrow
            _ = ctx.draw_line(arrow_x - 4, arrow_y - 2, arrow_x, arrow_y + 2, 2)
            _ = ctx.draw_line(arrow_x, arrow_y + 2, arrow_x + 4, arrow_y - 2, 2)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y,
                              self.bounds.width, self.bounds.height)
        
        # Dropdown list if open
        if self.is_open:
            self.render_dropdown_list(ctx)
    
    fn render_dropdown_list(self, ctx: RenderingContextInt):
        """Render the dropdown list."""
        let rect = self.get_dropdown_rect()
        
        # Shadow
        _ = ctx.set_color(0, 0, 0, 30)
        _ = ctx.draw_filled_rectangle(rect.x + 2, rect.y + 2, rect.width, rect.height)
        
        # Background
        _ = ctx.set_color(self.dropdown_bg_color.r, self.dropdown_bg_color.g,
                         self.dropdown_bg_color.b, self.dropdown_bg_color.a)
        _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        # Items
        let visible_start = self.scroll_offset
        let visible_end = min(visible_start + self.max_visible_items, len(self.items))
        
        for i in range(visible_start, visible_end):
            self.render_dropdown_item(ctx, i)
        
        # Scroll indicators if needed
        if self.scroll_offset > 0:
            # Up scroll indicator
            _ = ctx.set_color(self.arrow_color.r, self.arrow_color.g,
                             self.arrow_color.b, self.arrow_color.a)
            let x = rect.x + rect.width // 2
            _ = ctx.draw_line(x - 4, rect.y + 8, x, rect.y + 4, 2)
            _ = ctx.draw_line(x, rect.y + 4, x + 4, rect.y + 8, 2)
        
        if visible_end < len(self.items):
            # Down scroll indicator
            _ = ctx.set_color(self.arrow_color.r, self.arrow_color.g,
                             self.arrow_color.b, self.arrow_color.a)
            let x = rect.x + rect.width // 2
            let y = rect.y + rect.height - 8
            _ = ctx.draw_line(x - 4, y, x, y + 4, 2)
            _ = ctx.draw_line(x, y + 4, x + 4, y, 2)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(rect.x, rect.y, rect.width, rect.height)
    
    fn render_dropdown_item(self, ctx: RenderingContextInt, index: Int32):
        """Render individual dropdown item."""
        let item = self.items[index]
        let rect = self.get_item_rect(index)
        
        if rect.width <= 0 or rect.height <= 0:
            return
        
        # Background
        if index == self.selected_index:
            _ = ctx.set_color(self.item_selected_color.r, self.item_selected_color.g,
                             self.item_selected_color.b, self.item_selected_color.a)
            _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        elif index == self.hover_index:
            _ = ctx.set_color(self.item_hover_color.r, self.item_hover_color.g,
                             self.item_hover_color.b, self.item_hover_color.a)
            _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        var x = rect.x + self.padding
        
        # Icon if present
        if len(item.icon) > 0:
            # Draw icon placeholder
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
            _ = ctx.draw_filled_rectangle(x, rect.y + (rect.height - self.icon_size) // 2,
                                         self.icon_size, self.icon_size)
            x += self.icon_size + 4
        
        # Text
        let text_color = self.text_color if item.enabled else self.disabled_text_color
        let is_selected_white = index == self.selected_index
        if is_selected_white:
            _ = ctx.set_color(255, 255, 255, 255)
        else:
            _ = ctx.set_color(text_color.r, text_color.g, text_color.b, text_color.a)
        
        let text_y = rect.y + (rect.height - self.font_size) // 2
        _ = ctx.draw_text(item.text, x, text_y, self.font_size)
    
    fn update(inout self):
        """Update dropdown state."""
        pass
    
    fn set_editable(inout self, editable: Bool):
        """Set whether dropdown is editable."""
        self.editable = editable
    
    fn get_item_count(self) -> Int32:
        """Get number of items."""
        return len(self.items)
    
    fn get_item_text(self, index: Int32) -> String:
        """Get item text by index."""
        if index >= 0 and index < len(self.items):
            return self.items[index].text
        return ""
    
    fn set_item_enabled(inout self, index: Int32, enabled: Bool):
        """Enable or disable an item."""
        if index >= 0 and index < len(self.items):
            self.items[index].enabled = enabled

# Convenience functions
fn create_dropdown_int(x: Int32, y: Int32, width: Int32, height: Int32 = 25) -> DropdownInt:
    """Create a dropdown widget."""
    return DropdownInt(x, y, width, height)

fn create_combobox_int(x: Int32, y: Int32, width: Int32, height: Int32 = 25) -> DropdownInt:
    """Create an editable combobox."""
    var combo = DropdownInt(x, y, width, height)
    combo.set_editable(True)
    return combo