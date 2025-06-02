"""
Integer-Only ContextMenu Widget Implementation
Right-click context menu widget using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

# Menu item types
alias MENU_ITEM_NORMAL = 0
alias MENU_ITEM_SEPARATOR = 1
alias MENU_ITEM_SUBMENU = 2
alias MENU_ITEM_CHECKBOX = 3

# Menu states
alias MENU_ITEM_ENABLED = 1
alias MENU_ITEM_DISABLED = 2
alias MENU_ITEM_CHECKED = 4

struct MenuItem:
    """Context menu item."""
    var id: Int32
    var text: String
    var shortcut: String
    var item_type: Int32
    var state: Int32
    var height: Int32
    var icon_id: Int32
    var submenu_id: Int32
    var user_data: Int32
    
    fn __init__(inout self, id: Int32, text: String, item_type: Int32 = MENU_ITEM_NORMAL):
        self.id = id
        self.text = text
        self.shortcut = ""
        self.item_type = item_type
        self.state = MENU_ITEM_ENABLED
        self.height = 24 if item_type == MENU_ITEM_SEPARATOR else 22
        self.icon_id = -1
        self.submenu_id = -1
        self.user_data = 0

struct ContextMenuInt(BaseWidgetInt):
    """Context menu widget for right-click menus."""
    
    var is_visible: Bool
    var is_modal: Bool
    var auto_hide: Bool
    var items: List[MenuItem]
    var item_count: Int32
    var hovered_item: Int32
    var selected_item: Int32
    var font_size: Int32
    var item_padding: Int32
    var separator_height: Int32
    var min_width: Int32
    var max_width: Int32
    var calculated_width: Int32
    var calculated_height: Int32
    
    # Animation and timing
    var show_time: Int32
    var fade_duration: Int32
    var alpha: Int32
    
    # Colors
    var menu_color: ColorInt
    var hover_color: ColorInt
    var text_color: ColorInt
    var disabled_color: ColorInt
    var separator_color: ColorInt
    var border_color: ColorInt
    var shadow_color: ColorInt
    
    # Parent information
    var parent_widget_id: Int32
    var trigger_x: Int32
    var trigger_y: Int32
    
    fn __init__(inout self):
        """Initialize context menu (initially hidden)."""
        self.super().__init__(0, 0, 0, 0)
        
        self.is_visible = False
        self.is_modal = True
        self.auto_hide = True
        self.items = List[MenuItem]()
        self.item_count = 0
        self.hovered_item = -1
        self.selected_item = -1
        self.font_size = 12
        self.item_padding = 8
        self.separator_height = 6
        self.min_width = 120
        self.max_width = 300
        self.calculated_width = 0
        self.calculated_height = 0
        
        # Animation
        self.show_time = 0
        self.fade_duration = 150  # milliseconds
        self.alpha = 255
        
        # Set colors
        self.menu_color = ColorInt(250, 250, 250, 255)        # Very light gray
        self.hover_color = ColorInt(230, 240, 255, 255)       # Light blue
        self.text_color = ColorInt(0, 0, 0, 255)              # Black
        self.disabled_color = ColorInt(150, 150, 150, 255)    # Gray
        self.separator_color = ColorInt(200, 200, 200, 255)   # Light gray
        self.border_color = ColorInt(160, 160, 160, 255)      # Gray
        self.shadow_color = ColorInt(0, 0, 0, 80)             # Semi-transparent black
        
        # No parent initially
        self.parent_widget_id = -1
        self.trigger_x = 0
        self.trigger_y = 0
        
        # Set base appearance
        self.background_color = self.menu_color
        self.border_width = 1
    
    fn add_item(inout self, id: Int32, text: String, shortcut: String = "") -> Int32:
        """Add a normal menu item."""
        var item = MenuItem(id, text, MENU_ITEM_NORMAL)
        item.shortcut = shortcut
        self.items.append(item)
        self.item_count += 1
        self._recalculate_size()
        return self.item_count - 1
    
    fn add_separator(inout self) -> Int32:
        """Add a separator line."""
        var item = MenuItem(-1, "", MENU_ITEM_SEPARATOR)
        self.items.append(item)
        self.item_count += 1
        self._recalculate_size()
        return self.item_count - 1
    
    fn add_checkbox_item(inout self, id: Int32, text: String, checked: Bool = False) -> Int32:
        """Add a checkbox menu item."""
        var item = MenuItem(id, text, MENU_ITEM_CHECKBOX)
        if checked:
            item.state |= MENU_ITEM_CHECKED
        self.items.append(item)
        self.item_count += 1
        self._recalculate_size()
        return self.item_count - 1
    
    fn set_item_enabled(inout self, item_index: Int32, enabled: Bool):
        """Enable or disable a menu item."""
        if item_index >= 0 and item_index < self.item_count:
            if enabled:
                self.items[item_index].state |= MENU_ITEM_ENABLED
                self.items[item_index].state &= ~MENU_ITEM_DISABLED
            else:
                self.items[item_index].state |= MENU_ITEM_DISABLED
                self.items[item_index].state &= ~MENU_ITEM_ENABLED
    
    fn set_item_checked(inout self, item_index: Int32, checked: Bool):
        """Check or uncheck a checkbox menu item."""
        if item_index >= 0 and item_index < self.item_count:
            if self.items[item_index].item_type == MENU_ITEM_CHECKBOX:
                if checked:
                    self.items[item_index].state |= MENU_ITEM_CHECKED
                else:
                    self.items[item_index].state &= ~MENU_ITEM_CHECKED
    
    fn is_item_checked(self, item_index: Int32) -> Bool:
        """Check if a checkbox item is checked."""
        if item_index >= 0 and item_index < self.item_count:
            return (self.items[item_index].state & MENU_ITEM_CHECKED) != 0
        return False
    
    fn clear_items(inout self):
        """Remove all menu items."""
        self.items.clear()
        self.item_count = 0
        self.hovered_item = -1
        self.selected_item = -1
        self._recalculate_size()
    
    fn show_at(inout self, x: Int32, y: Int32, parent_id: Int32 = -1):
        """Show the context menu at the specified position."""
        self.trigger_x = x
        self.trigger_y = y
        self.parent_widget_id = parent_id
        
        # Recalculate size in case items changed
        self._recalculate_size()
        
        # Position the menu
        self.x = x
        self.y = y
        self.width = self.calculated_width
        self.height = self.calculated_height
        
        # TODO: Adjust position if menu would go off screen
        # This would require knowing screen dimensions
        
        self.is_visible = True
        self.hovered_item = -1
        self.selected_item = -1
        self.show_time = 0  # Would be current time in real implementation
    
    fn hide(inout self):
        """Hide the context menu."""
        self.is_visible = False
        self.hovered_item = -1
        self.selected_item = -1
    
    fn _recalculate_size(inout self):
        """Recalculate menu dimensions based on items."""
        if self.item_count == 0:
            self.calculated_width = self.min_width
            self.calculated_height = self.item_padding * 2
            return
        
        # Calculate required width based on text
        var max_text_width = 0
        var max_shortcut_width = 0
        
        for i in range(self.item_count):
            if self.items[i].item_type != MENU_ITEM_SEPARATOR:
                # Simplified width calculation (would use actual text measurement)
                let text_width = len(self.items[i].text) * (self.font_size * 6 // 10)
                let shortcut_width = len(self.items[i].shortcut) * (self.font_size * 6 // 10)
                
                if text_width > max_text_width:
                    max_text_width = text_width
                if shortcut_width > max_shortcut_width:
                    max_shortcut_width = shortcut_width
        
        # Calculate width with padding and shortcut space
        self.calculated_width = self.item_padding * 2 + max_text_width
        if max_shortcut_width > 0:
            self.calculated_width += max_shortcut_width + 20  # Space between text and shortcut
        
        # Clamp to min/max width
        if self.calculated_width < self.min_width:
            self.calculated_width = self.min_width
        elif self.calculated_width > self.max_width:
            self.calculated_width = self.max_width
        
        # Calculate height
        self.calculated_height = self.item_padding * 2
        for i in range(self.item_count):
            self.calculated_height += self.items[i].height
    
    fn hit_test_item(self, x: Int32, y: Int32) -> Int32:
        """Get the menu item at the specified coordinates."""
        if not self.is_visible or not self._point_in_bounds(PointInt(x, y)):
            return -1
        
        let relative_y = y - self.y - self.item_padding
        var current_y = 0
        
        for i in range(self.item_count):
            if relative_y >= current_y and relative_y < current_y + self.items[i].height:
                if self.items[i].item_type != MENU_ITEM_SEPARATOR:
                    return i
                else:
                    return -1  # Can't select separators
            current_y += self.items[i].height
        
        return -1
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events for the context menu."""
        if not self.is_visible:
            return False
        
        let item_index = self.hit_test_item(event.x, event.y)
        
        if item_index >= 0:
            # Mouse over a valid item
            self.hovered_item = item_index
            
            if event.pressed:
                # Item clicked
                if (self.items[item_index].state & MENU_ITEM_ENABLED) != 0:
                    self.selected_item = item_index
                    
                    # Handle checkbox toggle
                    if self.items[item_index].item_type == MENU_ITEM_CHECKBOX:
                        let checked = (self.items[item_index].state & MENU_ITEM_CHECKED) != 0
                        self.set_item_checked(item_index, not checked)
                    
                    # Hide menu after selection (if auto_hide enabled)
                    if self.auto_hide:
                        self.hide()
                    
                    return True
            
            return True
        else:
            # Mouse outside menu or over separator
            self.hovered_item = -1
            
            if event.pressed and self.auto_hide:
                # Clicked outside menu - hide it
                self.hide()
                return False  # Don't consume the click
        
        return False
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle keyboard events for the context menu."""
        if not self.is_visible or not event.pressed:
            return False
        
        if event.key_code == 256:  # Escape key
            self.hide()
            return True
        elif event.key_code == 264:  # Down arrow
            self._navigate_next()
            return True
        elif event.key_code == 265:  # Up arrow
            self._navigate_previous()
            return True
        elif event.key_code == 257:  # Enter
            if self.hovered_item >= 0:
                self.selected_item = self.hovered_item
                
                # Handle checkbox toggle
                if self.items[self.hovered_item].item_type == MENU_ITEM_CHECKBOX:
                    let checked = (self.items[self.hovered_item].state & MENU_ITEM_CHECKED) != 0
                    self.set_item_checked(self.hovered_item, not checked)
                
                if self.auto_hide:
                    self.hide()
                return True
        
        return False
    
    fn _navigate_next(inout self):
        """Navigate to the next enabled menu item."""
        var start = self.hovered_item + 1
        if start >= self.item_count:
            start = 0
        
        for i in range(self.item_count):
            let index = (start + i) % self.item_count
            if (self.items[index].item_type != MENU_ITEM_SEPARATOR and 
                (self.items[index].state & MENU_ITEM_ENABLED) != 0):
                self.hovered_item = index
                return
    
    fn _navigate_previous(inout self):
        """Navigate to the previous enabled menu item."""
        var start = self.hovered_item - 1
        if start < 0:
            start = self.item_count - 1
        
        for i in range(self.item_count):
            let index = (start - i + self.item_count) % self.item_count
            if (self.items[index].item_type != MENU_ITEM_SEPARATOR and 
                (self.items[index].state & MENU_ITEM_ENABLED) != 0):
                self.hovered_item = index
                return
    
    fn draw(self, ctx: RenderingContextInt):
        """Draw the context menu."""
        if not self.is_visible:
            return
        
        # Draw shadow (offset by 2 pixels)
        _ = ctx.set_color(self.shadow_color.r, self.shadow_color.g, self.shadow_color.b, self.shadow_color.a)
        _ = ctx.draw_filled_rectangle(self.x + 2, self.y + 2, self.width, self.height)
        
        # Draw menu background
        _ = ctx.set_color(self.menu_color.r, self.menu_color.g, self.menu_color.b, self.menu_color.a)
        _ = ctx.draw_filled_rectangle(self.x, self.y, self.width, self.height)
        
        # Draw border
        _ = ctx.set_color(self.border_color.r, self.border_color.g, self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(self.x, self.y, self.width, self.height)
        
        # Draw menu items
        self._draw_items(ctx)
    
    fn _draw_items(self, ctx: RenderingContextInt):
        """Draw all menu items."""
        var current_y = self.y + self.item_padding
        
        for i in range(self.item_count):
            let item_y = current_y
            
            if self.items[i].item_type == MENU_ITEM_SEPARATOR:
                # Draw separator line
                let sep_y = item_y + self.separator_height // 2
                _ = ctx.set_color(self.separator_color.r, self.separator_color.g, 
                                self.separator_color.b, self.separator_color.a)
                _ = ctx.draw_filled_rectangle(self.x + 8, sep_y, self.width - 16, 1)
            else:
                # Draw item background if hovered
                if i == self.hovered_item:
                    _ = ctx.set_color(self.hover_color.r, self.hover_color.g, 
                                    self.hover_color.b, self.hover_color.a)
                    _ = ctx.draw_filled_rectangle(self.x + 1, item_y, self.width - 2, self.items[i].height)
                
                # Draw checkbox indicator
                if self.items[i].item_type == MENU_ITEM_CHECKBOX:
                    let check_x = self.x + 6
                    let check_y = item_y + 3
                    let check_size = 12
                    
                    # Checkbox background
                    _ = ctx.set_color(255, 255, 255, 255)  # White
                    _ = ctx.draw_filled_rectangle(check_x, check_y, check_size, check_size)
                    
                    # Checkbox border
                    _ = ctx.set_color(128, 128, 128, 255)  # Gray
                    _ = ctx.draw_rectangle(check_x, check_y, check_size, check_size)
                    
                    # Checkmark
                    if (self.items[i].state & MENU_ITEM_CHECKED) != 0:
                        _ = ctx.set_color(0, 128, 0, 255)  # Green
                        _ = ctx.draw_text("✓", check_x + 2, check_y + 1, 10)
                
                # Draw item text
                let text_x = self.x + (30 if self.items[i].item_type == MENU_ITEM_CHECKBOX else 12)
                let text_y = item_y + 4
                
                # Set text color based on state
                if (self.items[i].state & MENU_ITEM_ENABLED) != 0:
                    _ = ctx.set_color(self.text_color.r, self.text_color.g, 
                                    self.text_color.b, self.text_color.a)
                else:
                    _ = ctx.set_color(self.disabled_color.r, self.disabled_color.g, 
                                    self.disabled_color.b, self.disabled_color.a)
                
                _ = ctx.draw_text(self.items[i].text, text_x, text_y, self.font_size)
                
                # Draw shortcut text (right-aligned)
                if len(self.items[i].shortcut) > 0:
                    let shortcut_x = self.x + self.width - 12 - (len(self.items[i].shortcut) * self.font_size * 6 // 10)
                    _ = ctx.set_color(100, 100, 100, 255)  # Dark gray
                    _ = ctx.draw_text(self.items[i].shortcut, shortcut_x, text_y, self.font_size)
            
            current_y += self.items[i].height
    
    fn get_selected_item_id(self) -> Int32:
        """Get the ID of the last selected item."""
        if self.selected_item >= 0 and self.selected_item < self.item_count:
            return self.items[self.selected_item].id
        return -1
    
    fn reset_selection(inout self):
        """Clear the selected item."""
        self.selected_item = -1

# Global context menu manager (simplified)
struct ContextMenuManager:
    """Manages global context menu state."""
    var active_menu: ContextMenuInt
    var menu_active: Bool
    
    fn __init__(inout self):
        self.active_menu = ContextMenuInt()
        self.menu_active = False
    
    fn show_menu(inout self, menu: ContextMenuInt, x: Int32, y: Int32):
        """Show a context menu."""
        self.active_menu = menu
        self.active_menu.show_at(x, y)
        self.menu_active = True
    
    fn hide_active_menu(inout self):
        """Hide the currently active menu."""
        if self.menu_active:
            self.active_menu.hide()
            self.menu_active = False
    
    fn handle_global_mouse(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events for active context menu."""
        if self.menu_active:
            return self.active_menu.handle_mouse_event(event)
        return False
    
    fn handle_global_key(inout self, event: KeyEventInt) -> Bool:
        """Handle key events for active context menu."""
        if self.menu_active:
            return self.active_menu.handle_key_event(event)
        return False
    
    fn draw_active_menu(self, ctx: RenderingContextInt):
        """Draw the active context menu."""
        if self.menu_active:
            self.active_menu.draw(ctx)

# Convenience functions
fn create_simple_context_menu() -> ContextMenuInt:
    """Create a basic context menu."""
    return ContextMenuInt()

fn create_edit_context_menu() -> ContextMenuInt:
    """Create a standard edit context menu."""
    var menu = ContextMenuInt()
    _ = menu.add_item(1, "Cut", "Ctrl+X")
    _ = menu.add_item(2, "Copy", "Ctrl+C")
    _ = menu.add_item(3, "Paste", "Ctrl+V")
    _ = menu.add_separator()
    _ = menu.add_item(4, "Select All", "Ctrl+A")
    return menu