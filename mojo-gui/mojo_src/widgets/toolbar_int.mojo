"""
Integer-Only Toolbar Widget Implementation
Professional toolbar with buttons, toggles, dropdowns, and overflow handling.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

# Toolbar button types
alias TOOLBAR_BUTTON = 0
alias TOOLBAR_TOGGLE = 1
alias TOOLBAR_DROPDOWN = 2
alias TOOLBAR_SEPARATOR = 3

struct ToolbarItem:
    """Individual toolbar item."""
    var item_type: Int32
    var text: String
    var icon: String  # Icon name/path
    var tooltip: String
    var width: Int32
    var enabled: Bool
    var toggled: Bool
    var dropdown_items: List[String]
    var data: Int32
    
    fn __init__(inout self, item_type: Int32, text: String, tooltip: String = ""):
        self.item_type = item_type
        self.text = text
        self.icon = ""
        self.tooltip = tooltip
        self.width = 0  # Auto-calculated
        self.enabled = True
        self.toggled = False
        self.dropdown_items = List[String]()
        self.data = 0

struct ToolBarInt(BaseWidgetInt):
    """Toolbar with button groups, separators, and overflow handling."""
    
    var items: List[ToolbarItem]
    var button_height: Int32
    var button_padding: Int32
    var icon_size: Int32
    var separator_width: Int32
    var show_text: Bool
    var show_icons: Bool
    var hover_item: Int32
    var pressed_item: Int32
    var dropdown_open: Int32
    var overflow_start: Int32  # First item in overflow menu
    
    # Colors
    var button_color: ColorInt
    var button_hover_color: ColorInt
    var button_pressed_color: ColorInt
    var button_toggled_color: ColorInt
    var separator_color: ColorInt
    var text_color: ColorInt
    var disabled_color: ColorInt
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.super().__init__(x, y, width, height)
        self.items = List[ToolbarItem]()
        self.button_height = height - 4
        self.button_padding = 8
        self.icon_size = 16
        self.separator_width = 8
        self.show_text = True
        self.show_icons = True
        self.hover_item = -1
        self.pressed_item = -1
        self.dropdown_open = -1
        self.overflow_start = -1
        
        # Set colors
        self.button_color = ColorInt(240, 240, 240, 255)
        self.button_hover_color = ColorInt(220, 220, 240, 255)
        self.button_pressed_color = ColorInt(200, 200, 220, 255)
        self.button_toggled_color = ColorInt(180, 200, 220, 255)
        self.separator_color = ColorInt(200, 200, 200, 255)
        self.text_color = ColorInt(0, 0, 0, 255)
        self.disabled_color = ColorInt(150, 150, 150, 255)
        
        # Set base widget appearance
        self.background_color = ColorInt(245, 245, 245, 255)
        self.border_color = ColorInt(180, 180, 180, 255)
        self.border_width = 1
    
    fn add_button(inout self, text: String, tooltip: String = ""):
        """Add a regular button."""
        var item = ToolbarItem(TOOLBAR_BUTTON, text, tooltip)
        self.calculate_item_width(item)
        self.items.append(item)
    
    fn add_toggle(inout self, text: String, tooltip: String = "", toggled: Bool = False):
        """Add a toggle button."""
        var item = ToolbarItem(TOOLBAR_TOGGLE, text, tooltip)
        item.toggled = toggled
        self.calculate_item_width(item)
        self.items.append(item)
    
    fn add_dropdown(inout self, text: String, dropdown_items: List[String], tooltip: String = ""):
        """Add a dropdown button."""
        var item = ToolbarItem(TOOLBAR_DROPDOWN, text, tooltip)
        item.dropdown_items = dropdown_items
        self.calculate_item_width(item)
        self.items.append(item)
    
    fn add_separator(inout self):
        """Add a separator."""
        var item = ToolbarItem(TOOLBAR_SEPARATOR, "", "")
        item.width = self.separator_width
        self.items.append(item)
    
    fn calculate_item_width(inout self, item: ToolbarItem):
        """Calculate width for a toolbar item."""
        if item.item_type == TOOLBAR_SEPARATOR:
            item.width = self.separator_width
            return
        
        var width = 2 * self.button_padding
        
        if self.show_icons:
            width += self.icon_size
            if self.show_text and len(item.text) > 0:
                width += self.button_padding
        
        if self.show_text:
            var text_width = len(item.text) * 7  # Approximate
            width += text_width
        
        if item.item_type == TOOLBAR_DROPDOWN:
            width += 15  # Space for dropdown arrow
        
        item.width = width
    
    fn calculate_overflow(inout self):
        """Calculate which items go into overflow menu."""
        var x = self.x + 2
        var max_x = self.x + self.width - 30  # Space for overflow button
        
        self.overflow_start = -1
        
        for i in range(len(self.items)):
            if x + self.items[i].width > max_x:
                self.overflow_start = i
                break
            x += self.items[i].width + 2
    
    fn get_item_rect(self, index: Int32) -> RectInt:
        """Get rectangle for toolbar item."""
        if index < 0 or index >= len(self.items):
            return RectInt(0, 0, 0, 0)
        
        if self.overflow_start >= 0 and index >= self.overflow_start:
            return RectInt(0, 0, 0, 0)  # In overflow menu
        
        var x = self.x + 2
        for i in range(index):
            x += self.items[i].width + 2
        
        return RectInt(x, self.y + 2, self.items[index].width, self.button_height)
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        var point = PointInt(event.x, event.y)
        if not self._point_in_bounds(point):
            self.hover_item = -1
            return False
        
        # Find which item was clicked
        for i in range(len(self.items)):
            if self.overflow_start >= 0 and i >= self.overflow_start:
                break
            
            var rect = self.get_item_rect(i)
            if rect.contains(point):
                self.hover_item = i
                
                if event.pressed and self.items[i].enabled:
                    if self.items[i].item_type == TOOLBAR_TOGGLE:
                        self.items[i].toggled = not self.items[i].toggled
                    elif self.items[i].item_type == TOOLBAR_DROPDOWN:
                        self.dropdown_open = i if self.dropdown_open != i else -1
                    
                    self.pressed_item = i
                    return True
                
                return True
        
        self.hover_item = -1
        return True
    
    fn draw(self, ctx: RenderingContextInt):
        """Render toolbar."""
        if not self.visible:
            return
        
        # Background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.x, self.y,
                                     self.width, self.height)
        
        # Calculate overflow
        self.calculate_overflow()
        
        # Render items
        for i in range(len(self.items)):
            if self.overflow_start >= 0 and i >= self.overflow_start:
                break
            self.render_item(ctx, i)
        
        # Render overflow button if needed
        if self.overflow_start >= 0:
            self.render_overflow_button(ctx)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(self.x, self.y,
                              self.width, self.height)
        
        # Render open dropdown
        if self.dropdown_open >= 0:
            self.render_dropdown(ctx, self.dropdown_open)
    
    fn render_item(self, ctx: RenderingContextInt, index: Int32):
        """Render individual toolbar item."""
        var item = self.items[index]
        var rect = self.get_item_rect(index)
        
        if item.item_type == TOOLBAR_SEPARATOR:
            # Draw separator line
            var x = rect.x + rect.width // 2
            _ = ctx.set_color(self.separator_color.r, self.separator_color.g,
                             self.separator_color.b, self.separator_color.a)
            _ = ctx.draw_line(x, rect.y, x, rect.y + rect.height, 1)
            return
        
        # Button background
        var bg_color = self.button_color
        if not item.enabled:
            bg_color = self.background_color
        elif item.toggled:
            bg_color = self.button_toggled_color
        elif index == self.pressed_item:
            bg_color = self.button_pressed_color
        elif index == self.hover_item:
            bg_color = self.button_hover_color
        
        if bg_color.a > 0:
            _ = ctx.set_color(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
            _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        # Content position
        var content_x = rect.x + self.button_padding
        var content_y = rect.y + (rect.height - self.icon_size) // 2
        
        # Icon (placeholder - draw small square)
        if self.show_icons:
            var icon_color = self.text_color if item.enabled else self.disabled_color
            _ = ctx.set_color(icon_color.r, icon_color.g, 
                             icon_color.b, icon_color.a)
            _ = ctx.draw_filled_rectangle(content_x, content_y, 
                                         self.icon_size, self.icon_size)
            content_x += self.icon_size + self.button_padding
        
        # Text
        if self.show_text and len(item.text) > 0:
            var text_color = self.text_color if item.enabled else self.disabled_color
            _ = ctx.set_color(text_color.r, text_color.g, 
                             text_color.b, text_color.a)
            _ = ctx.draw_text(item.text, content_x, rect.y + 8, 11)
        
        # Dropdown arrow
        if item.item_type == TOOLBAR_DROPDOWN:
            var arrow_x = rect.x + rect.width - 10
            var arrow_y = rect.y + rect.height // 2
            _ = ctx.draw_line(arrow_x - 3, arrow_y - 2, arrow_x, arrow_y + 1, 1)
            _ = ctx.draw_line(arrow_x, arrow_y + 1, arrow_x + 3, arrow_y - 2, 1)
        
        # Button border on hover/press
        if index == self.hover_item or index == self.pressed_item:
            _ = ctx.set_color(self.border_color.r, self.border_color.g,
                             self.border_color.b, self.border_color.a)
            _ = ctx.draw_rectangle(rect.x, rect.y, rect.width, rect.height)
    
    fn render_overflow_button(self, ctx: RenderingContextInt):
        """Render overflow menu button."""
        var x = self.x + self.width - 25
        var y = self.y + 2
        var w = 20
        var h = self.button_height
        
        # Button background
        _ = ctx.set_color(self.button_hover_color.r, self.button_hover_color.g,
                         self.button_hover_color.b, self.button_hover_color.a)
        _ = ctx.draw_filled_rectangle(x, y, w, h)
        
        # Draw >> symbol
        _ = ctx.set_color(self.text_color.r, self.text_color.g,
                         self.text_color.b, self.text_color.a)
        _ = ctx.draw_text("»", x + 5, y + 8, 12)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(x, y, w, h)
    
    fn render_dropdown(self, ctx: RenderingContextInt, index: Int32):
        """Render dropdown menu."""
        var item = self.items[index]
        var button_rect = self.get_item_rect(index)
        
        var menu_x = button_rect.x
        var menu_y = button_rect.y + button_rect.height + 2
        var menu_width = 150
        var item_height = 20
        var menu_height = len(item.dropdown_items) * item_height + 4
        
        # Shadow
        _ = ctx.set_color(0, 0, 0, 30)
        _ = ctx.draw_filled_rectangle(menu_x + 2, menu_y + 2, menu_width, menu_height)
        
        # Background
        _ = ctx.set_color(255, 255, 255, 255)
        _ = ctx.draw_filled_rectangle(menu_x, menu_y, menu_width, menu_height)
        
        # Items
        for i in range(len(item.dropdown_items)):
            var item_y = menu_y + 2 + i * item_height
            
            # Hover effect (simplified - demo hover on first item)
            if i == 0:
                _ = ctx.set_color(self.button_hover_color.r, self.button_hover_color.g,
                                 self.button_hover_color.b, self.button_hover_color.a)
                _ = ctx.draw_filled_rectangle(menu_x + 2, item_y, 
                                             menu_width - 4, item_height)
            
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
            _ = ctx.draw_text(item.dropdown_items[i], menu_x + 8, item_y + 4, 11)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(menu_x, menu_y, menu_width, menu_height)
    
    fn update(inout self):
        """Update toolbar state."""
        # Reset pressed state after release
        if self.pressed_item >= 0:
            # In real implementation, check mouse button state
            self.pressed_item = -1
    
    fn get_item_count(self) -> Int32:
        """Get number of toolbar items."""
        return len(self.items)
    
    fn set_item_enabled(inout self, index: Int32, enabled: Bool):
        """Enable or disable a toolbar item."""
        if index >= 0 and index < len(self.items):
            self.items[index].enabled = enabled
    
    fn is_item_toggled(self, index: Int32) -> Bool:
        """Check if toggle item is toggled."""
        if index >= 0 and index < len(self.items):
            return self.items[index].toggled
        return False
    
    fn set_item_toggled(inout self, index: Int32, toggled: Bool):
        """Set toggle state of item."""
        if index >= 0 and index < len(self.items):
            if self.items[index].item_type == TOOLBAR_TOGGLE:
                self.items[index].toggled = toggled
    
    fn set_display_options(inout self, show_icons: Bool, show_text: Bool):
        """Set what to display on toolbar items."""
        self.show_icons = show_icons
        self.show_text = show_text
        
        # Recalculate item widths
        for i in range(len(self.items)):
            self.calculate_item_width(self.items[i])


# Convenience functions
fn create_toolbar_int(x: Int32, y: Int32, width: Int32, height: Int32 = 32) -> ToolBarInt:
    """Create a toolbar."""
    return ToolBarInt(x, y, width, height)