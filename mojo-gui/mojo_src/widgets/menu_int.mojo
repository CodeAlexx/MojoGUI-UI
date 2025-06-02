"""
Integer-Only Menu Widget Implementation
Menu bar and dropdown menu system using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

struct MenuItemInt:
    """Individual menu item."""
    var text: String
    var shortcut: String
    var enabled: Bool
    var is_separator: Bool
    var submenu_items: List[MenuItemInt]
    var data: Int32
    
    fn __init__(inout self, text: String, shortcut: String = "", data: Int32 = 0):
        self.text = text
        self.shortcut = shortcut
        self.enabled = True
        self.is_separator = False
        self.submenu_items = List[MenuItemInt]()
        self.data = data

struct MenuBarInt(BaseWidgetInt):
    """Menu bar widget using integer coordinates."""
    
    var menu_items: List[MenuItemInt]
    var item_widths: List[Int32]
    var active_menu: Int32
    var hover_item: Int32
    var dropdown_visible: Bool
    var dropdown_hover: Int32
    var text_color: ColorInt
    var hover_color: ColorInt
    var active_color: ColorInt
    var disabled_color: ColorInt
    var font_size: Int32
    var padding: Int32
    var dropdown_width: Int32
    var dropdown_height: Int32
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        """Initialize menu bar."""
        self.super().__init__(x, y, width, height)
        self.menu_items = List[MenuItemInt]()
        self.item_widths = List[Int32]()
        self.active_menu = -1
        self.hover_item = -1
        self.dropdown_visible = False
        self.dropdown_hover = -1
        
        self.text_color = ColorInt(0, 0, 0, 255)           # Black text
        self.hover_color = ColorInt(200, 220, 255, 255)    # Light blue hover
        self.active_color = ColorInt(100, 150, 255, 255)   # Blue active
        self.disabled_color = ColorInt(128, 128, 128, 255) # Gray disabled
        self.font_size = 12
        self.padding = 8
        self.dropdown_width = 150
        self.dropdown_height = 25
        
        # Set appearance
        self.background_color = ColorInt(240, 240, 240, 255)  # Light gray
        self.border_color = ColorInt(180, 180, 180, 255)      # Gray border
        self.border_width = 1
    
    fn add_menu(inout self, text: String, items: List[MenuItemInt]):
        """Add a menu to the menu bar."""
        var menu = MenuItemInt(text)
        menu.submenu_items = items
        self.menu_items.append(menu)
        
        # Calculate width (rough approximation)
        let text_width = len(text) * (self.font_size * 6 // 10) + 2 * self.padding
        self.item_widths.append(text_width)
    
    fn get_menu_rect(self, menu_index: Int32) -> RectInt:
        """Get rectangle for menu item at index."""
        if menu_index < 0 or menu_index >= len(self.menu_items):
            return RectInt(0, 0, 0, 0)
        
        var x = self.bounds.x
        for i in range(menu_index):
            x += self.item_widths[i]
        
        return RectInt(x, self.bounds.y, self.item_widths[menu_index], self.bounds.height)
    
    fn get_dropdown_rect(self, menu_index: Int32) -> RectInt:
        """Get dropdown rectangle for menu."""
        let menu_rect = self.get_menu_rect(menu_index)
        let item_count = len(self.menu_items[menu_index].submenu_items)
        let dropdown_height = item_count * self.dropdown_height
        
        return RectInt(menu_rect.x, menu_rect.y + menu_rect.height,
                      self.dropdown_width, dropdown_height)
    
    fn menu_index_from_point(self, point: PointInt) -> Int32:
        """Get menu index from point."""
        if not self.contains_point(point):
            return -1
        
        var x = self.bounds.x
        for i in range(len(self.menu_items)):
            if point.x >= x and point.x < x + self.item_widths[i]:
                return i
            x += self.item_widths[i]
        return -1
    
    fn dropdown_item_from_point(self, point: PointInt, menu_index: Int32) -> Int32:
        """Get dropdown item index from point."""
        if menu_index < 0 or menu_index >= len(self.menu_items):
            return -1
        
        let dropdown_rect = self.get_dropdown_rect(menu_index)
        if not dropdown_rect.contains(point):
            return -1
        
        let relative_y = point.y - dropdown_rect.y
        let item_index = relative_y // self.dropdown_height
        
        if item_index >= 0 and item_index < len(self.menu_items[menu_index].submenu_items):
            return item_index
        return -1
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        
        if event.pressed:
            # Check menu bar clicks
            let menu_index = self.menu_index_from_point(point)
            if menu_index >= 0:
                if self.active_menu == menu_index:
                    # Close dropdown
                    self.active_menu = -1
                    self.dropdown_visible = False
                else:
                    # Open dropdown
                    self.active_menu = menu_index
                    self.dropdown_visible = True
                return True
            
            # Check dropdown clicks
            if self.dropdown_visible and self.active_menu >= 0:
                let dropdown_item = self.dropdown_item_from_point(point, self.active_menu)
                if dropdown_item >= 0:
                    # Item clicked - would trigger action
                    print("Menu item clicked:", self.menu_items[self.active_menu].submenu_items[dropdown_item].text)
                    self.dropdown_visible = False
                    self.active_menu = -1
                    return True
                else:
                    # Click outside dropdown - close it
                    self.dropdown_visible = False
                    self.active_menu = -1
            
        else:
            # Update hover states
            self.hover_item = self.menu_index_from_point(point)
            
            if self.dropdown_visible and self.active_menu >= 0:
                self.dropdown_hover = self.dropdown_item_from_point(point, self.active_menu)
        
        return self.contains_point(point) or (self.dropdown_visible and self.active_menu >= 0)
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle key events (Alt key for menu access)."""
        if not self.visible or not self.enabled:
            return False
        
        if event.pressed and event.key_code == 342:  # Alt key
            # Toggle first menu
            if len(self.menu_items) > 0:
                self.active_menu = 0 if self.active_menu != 0 else -1
                self.dropdown_visible = self.active_menu >= 0
                return True
        
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render the menu bar."""
        if not self.visible:
            return
        
        # Draw background
        self.render_background(ctx)
        
        # Draw menu items
        for i in range(len(self.menu_items)):
            let menu_rect = self.get_menu_rect(i)
            let is_active = (i == self.active_menu)
            let is_hover = (i == self.hover_item) and not is_active
            
            # Draw item background
            if is_active:
                _ = ctx.set_color(self.active_color.r, self.active_color.g,
                                 self.active_color.b, self.active_color.a)
                _ = ctx.draw_filled_rectangle(menu_rect.x, menu_rect.y, menu_rect.width, menu_rect.height)
            elif is_hover:
                _ = ctx.set_color(self.hover_color.r, self.hover_color.g,
                                 self.hover_color.b, self.hover_color.a)
                _ = ctx.draw_filled_rectangle(menu_rect.x, menu_rect.y, menu_rect.width, menu_rect.height)
            
            # Draw item text
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
            let text_x = menu_rect.x + self.padding
            let text_y = menu_rect.y + (menu_rect.height - self.font_size) // 2
            _ = ctx.draw_text(self.menu_items[i].text, text_x, text_y, self.font_size)
        
        # Draw dropdown if visible
        if self.dropdown_visible and self.active_menu >= 0:
            self.render_dropdown(ctx, self.active_menu)
    
    fn render_dropdown(self, ctx: RenderingContextInt, menu_index: Int32):
        """Render dropdown menu."""
        let dropdown_rect = self.get_dropdown_rect(menu_index)
        
        # Draw dropdown background
        _ = ctx.set_color(255, 255, 255, 255)
        _ = ctx.draw_filled_rectangle(dropdown_rect.x, dropdown_rect.y, dropdown_rect.width, dropdown_rect.height)
        
        # Draw dropdown border
        _ = ctx.set_color(128, 128, 128, 255)
        _ = ctx.draw_rectangle(dropdown_rect.x, dropdown_rect.y, dropdown_rect.width, dropdown_rect.height)
        
        # Draw dropdown items
        let items = self.menu_items[menu_index].submenu_items
        for i in range(len(items)):
            let item_y = dropdown_rect.y + i * self.dropdown_height
            let is_hover = (i == self.dropdown_hover)
            
            # Draw item background
            if is_hover and items[i].enabled:
                _ = ctx.set_color(self.hover_color.r, self.hover_color.g,
                                 self.hover_color.b, self.hover_color.a)
                _ = ctx.draw_filled_rectangle(dropdown_rect.x, item_y, dropdown_rect.width, self.dropdown_height)
            
            # Draw item text
            let text_color = self.disabled_color if not items[i].enabled else self.text_color
            _ = ctx.set_color(text_color.r, text_color.g, text_color.b, text_color.a)
            
            if items[i].is_separator:
                # Draw separator line
                _ = ctx.draw_line(dropdown_rect.x + 5, item_y + self.dropdown_height // 2,
                                 dropdown_rect.x + dropdown_rect.width - 5, item_y + self.dropdown_height // 2, 1)
            else:
                # Draw text
                let text_x = dropdown_rect.x + self.padding
                let text_y = item_y + (self.dropdown_height - self.font_size) // 2
                _ = ctx.draw_text(items[i].text, text_x, text_y, self.font_size)
                
                # Draw shortcut if present
                if len(items[i].shortcut) > 0:
                    let shortcut_x = dropdown_rect.x + dropdown_rect.width - self.padding - len(items[i].shortcut) * 6
                    _ = ctx.draw_text(items[i].shortcut, shortcut_x, text_y, self.font_size)
    
    fn update(inout self):
        """Update menu state."""
        # Nothing special to update for basic menu
        pass

# Convenience functions
fn create_menu_bar_int(x: Int32, y: Int32, width: Int32, height: Int32 = 25) -> MenuBarInt:
    """Create a standard menu bar."""
    return MenuBarInt(x, y, width, height)

fn create_menu_item_int(text: String, shortcut: String = "") -> MenuItemInt:
    """Create a menu item."""
    return MenuItemInt(text, shortcut)

fn create_separator_int() -> MenuItemInt:
    """Create a menu separator."""
    var separator = MenuItemInt("")
    separator.is_separator = True
    return separator