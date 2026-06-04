"""
Integer-Only Navigation Bar Widget Implementation
Navigation controls with history support and quick access buttons.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt
from .widget_events_int import MouseEventInt, KeyEventInt
from .widget_constants import *
from .button_int import ButtonInt
from .icon_int import IconInt, ICON_ARROW_LEFT, ICON_ARROW_RIGHT, ICON_ARROW_UP, ICON_HOME, ICON_REFRESH
from .breadcrumb_int import BreadcrumbInt

struct NavigationHistory(Copyable, Movable):
    """Navigation history management."""
    var entries: List[String]
    var current_index: Int32
    var max_entries: Int32
    
    fn __init__(out self, max_entries: Int32 = 100):
        self.entries = List[String]()
        self.current_index = -1
        self.max_entries = max_entries

    fn add_entry(mut self, path: String):
        """Add new history entry."""
        # Remove forward history if navigating to new location
        if Int(self.current_index) < len(self.entries) - 1:
            # Remove all entries after current
            while len(self.entries) > Int(self.current_index) + 1:
                self.entries.pop()
        
        # Add new entry
        self.entries.append(path)
        self.current_index = Int32(len(self.entries) - 1)
        
        # Limit history size
        if len(self.entries) > Int(self.max_entries):
            _ = self.entries.pop(0)
            self.current_index -= 1
    
    fn can_go_back(self) -> Bool:
        """Check if can navigate back."""
        return self.current_index > 0
    
    fn can_go_forward(self) -> Bool:
        """Check if can navigate forward."""
        return Int(self.current_index) < len(self.entries) - 1
    
    fn go_back(mut self) -> String:
        """Navigate back and return path."""
        if self.can_go_back():
            self.current_index -= 1
            return self.entries[Int(self.current_index)]
        return ""

    fn go_forward(mut self) -> String:
        """Navigate forward and return path."""
        if self.can_go_forward():
            self.current_index += 1
            return self.entries[Int(self.current_index)]
        return ""
    
    fn get_current(self) -> String:
        """Get current path."""
        if self.current_index >= 0 and Int(self.current_index) < len(self.entries):
            return self.entries[Int(self.current_index)]
        return ""
    
    fn get_back_history(self) -> List[String]:
        """Get list of back history entries."""
        var history = List[String]()
        for i in range(max(0, Int(self.current_index) - 10), Int(self.current_index)):
            history.append(String(self.entries[i]))
        return history^

    fn get_forward_history(self) -> List[String]:
        """Get list of forward history entries."""
        var history = List[String]()
        var end = min(len(self.entries), Int(self.current_index) + 11)
        for i in range(Int(self.current_index) + 1, end):
            history.append(String(self.entries[i]))
        return history^

struct NavigationBarInt(WidgetInt, Copyable, Movable):
    """Navigation bar with back/forward, up, home, and integrated breadcrumb."""

    # Inlined BaseWidgetInt fields (struct inheritance is not supported).
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var background_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32

    # Components
    var history: NavigationHistory
    var breadcrumb: BreadcrumbInt
    var current_path: String
    
    # Buttons
    var back_button: IconInt
    var forward_button: IconInt
    var up_button: IconInt
    var home_button: IconInt
    var refresh_button: IconInt
    
    # Layout
    var button_size: Int32
    var button_spacing: Int32
    var breadcrumb_offset: Int32
    
    # State
    var show_back_menu: Bool
    var show_forward_menu: Bool
    var menu_hover_index: Int32
    
    # Colors
    var button_color: ColorInt
    var button_hover_color: ColorInt
    var button_disabled_color: ColorInt
    var menu_bg_color: ColorInt
    var menu_hover_color: ColorInt
    var menu_text_color: ColorInt
    
    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32 = 40):
        # Inlined BaseWidgetInt.__init__
        self.bounds = RectInt(x, y, width, height)
        self.visible = True
        self.enabled = True
        self.background_color = ColorInt(230, 230, 230, 255)
        self.border_color = ColorInt(128, 128, 128, 255)
        self.border_width = 1

        self.history = NavigationHistory()
        self.current_path = "/"
        
        self.button_size = height - 8
        self.button_spacing = 4
        self.breadcrumb_offset = 0
        
        # Initialize buttons
        var button_y = y + (height - self.button_size) // 2
        var button_x = x + self.button_spacing
        
        self.back_button = IconInt(button_x, button_y, ICON_ARROW_LEFT, self.button_size)
        self.back_button.clickable = True
        button_x += self.button_size + self.button_spacing
        
        self.forward_button = IconInt(button_x, button_y, ICON_ARROW_RIGHT, self.button_size)
        self.forward_button.clickable = True
        button_x += self.button_size + self.button_spacing
        
        self.up_button = IconInt(button_x, button_y, ICON_ARROW_UP, self.button_size)
        self.up_button.clickable = True
        button_x += self.button_size + self.button_spacing
        
        self.home_button = IconInt(button_x, button_y, ICON_HOME, self.button_size)
        self.home_button.clickable = True
        button_x += self.button_size + self.button_spacing
        
        self.refresh_button = IconInt(button_x, button_y, ICON_REFRESH, self.button_size)
        self.refresh_button.clickable = True
        button_x += self.button_size + self.button_spacing
        
        self.breadcrumb_offset = button_x + self.button_spacing
        
        # Initialize breadcrumb
        self.breadcrumb = BreadcrumbInt(self.breadcrumb_offset, y, 
                                       width - self.breadcrumb_offset - self.button_spacing, height)
        
        self.show_back_menu = False
        self.show_forward_menu = False
        self.menu_hover_index = -1
        
        # Colors
        self.button_color = ColorInt(240, 240, 240, 255)
        self.button_hover_color = ColorInt(220, 220, 220, 255)
        self.button_disabled_color = ColorInt(200, 200, 200, 255)
        self.menu_bg_color = ColorInt(255, 255, 255, 255)
        self.menu_hover_color = ColorInt(229, 243, 255, 255)
        self.menu_text_color = ColorInt(0, 0, 0, 255)
        
        # Widget appearance
        self.background_color = ColorInt(250, 250, 250, 255)
        self.border_color = ColorInt(200, 200, 200, 255)
        self.border_width = 1

    # Inlined BaseWidgetInt methods (set_bounds is overridden below).
    fn get_bounds(self) -> RectInt: return self.bounds
    fn is_visible(self) -> Bool: return self.visible
    fn set_visible(mut self, visible: Bool): self.visible = visible
    fn is_enabled(self) -> Bool: return self.enabled
    fn set_enabled(mut self, enabled: Bool): self.enabled = enabled
    fn contains_point(self, point: PointInt) -> Bool: return self.bounds.contains(point)
    fn render_background(self, ctx: RenderingContextInt):
        if not self.visible: return
        _ = ctx.set_color(self.background_color.r, self.background_color.g, self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
        if self.border_width > 0:
            _ = ctx.set_color(self.border_color.r, self.border_color.g, self.border_color.b, self.border_color.a)
            _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)

    fn handle_key_event(mut self, event: KeyEventInt) -> Bool:
        return False

    fn navigate_to(mut self, path: String):
        """Navigate to specified path."""
        if path == self.current_path:
            return
        
        self.current_path = path
        self.history.add_entry(path)
        self.breadcrumb.set_path(path)
        
        self.update_button_states()
    
    fn go_back(mut self):
        """Navigate back in history."""
        if self.history.can_go_back():
            var path = self.history.go_back()
            self.current_path = path
            self.breadcrumb.set_path(path)
            
            self.update_button_states()
    
    fn go_forward(mut self):
        """Navigate forward in history."""
        if self.history.can_go_forward():
            var path = self.history.go_forward()
            self.current_path = path
            self.breadcrumb.set_path(path)
            
            self.update_button_states()
    
    fn go_up(mut self):
        """Navigate to parent directory."""
        if len(self.current_path) > 1:
            var parent_path = self.current_path
            # Find last slash position (simplified)
            var last_slash = -1
            for i in range(len(parent_path) - 1, -1, -1):
                if Int(parent_path.as_bytes()[i]) == ord("/"):
                    last_slash = i
                    break
            
            if last_slash > 0:
                parent_path = String(parent_path[:last_slash])
            elif last_slash == 0:
                parent_path = "/"
            else:
                return
            
            self.navigate_to(parent_path)
    
    fn go_home(mut self):
        """Navigate to home directory."""
        self.navigate_to("/home")  # Or user's home directory
    
    fn refresh(mut self):
        """Refresh current location."""
        # Would trigger refresh callback in real implementation
        pass
    
    fn update_button_states(mut self):
        """Update enabled state of navigation buttons."""
        self.back_button.enabled = self.history.can_go_back()
        self.forward_button.enabled = self.history.can_go_forward()
        self.up_button.enabled = len(self.current_path) > 1
    
    fn get_history_menu_rect(self, is_back: Bool) -> RectInt:
        """Get rectangle for history dropdown menu."""
        var button_x = self.back_button.bounds.x if is_back else self.forward_button.bounds.x
        var entries = len(self.history.get_back_history() if is_back else
                          self.history.get_forward_history())
        var item_height = 24
        var menu_width = 250
        var menu_height = min(entries, 10) * item_height + 4

        return RectInt(button_x, self.bounds.y + self.bounds.height,
                      Int32(menu_width), Int32(menu_height))
    
    fn handle_mouse_event(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        var point = PointInt(event.x, event.y)
        
        # Check history menus
        if self.show_back_menu:
            var menu_rect = self.get_history_menu_rect(True)
            if menu_rect.contains(point):
                var item_height: Int32 = 24
                self.menu_hover_index = (event.y - menu_rect.y - 2) // item_height

                if event.pressed:
                    var history = self.history.get_back_history()
                    if self.menu_hover_index >= 0 and Int(self.menu_hover_index) < len(history):
                        # Navigate to selected history entry
                        for i in range(Int(self.menu_hover_index) + 1):
                            _ = self.history.go_back()
                        self.current_path = self.history.get_current()
                        self.breadcrumb.set_path(self.current_path)
                        self.update_button_states()
                        self.show_back_menu = False
                
                return True
            elif event.pressed:
                self.show_back_menu = False
        
        if self.show_forward_menu:
            var menu_rect = self.get_history_menu_rect(False)
            if menu_rect.contains(point):
                var item_height: Int32 = 24
                self.menu_hover_index = (event.y - menu_rect.y - 2) // item_height

                if event.pressed:
                    var history = self.history.get_forward_history()
                    if self.menu_hover_index >= 0 and Int(self.menu_hover_index) < len(history):
                        # Navigate to selected history entry
                        for i in range(Int(self.menu_hover_index) + 1):
                            _ = self.history.go_forward()
                        self.current_path = self.history.get_current()
                        self.breadcrumb.set_path(self.current_path)
                        self.update_button_states()
                        self.show_forward_menu = False
                
                return True
            elif event.pressed:
                self.show_forward_menu = False
        
        # Handle button clicks
        if self.back_button.handle_mouse_event(event) and event.pressed:
            self.go_back()
            return True
        if self.forward_button.handle_mouse_event(event) and event.pressed:
            self.go_forward()
            return True
        if self.up_button.handle_mouse_event(event) and event.pressed:
            self.go_up()
            return True
        if self.home_button.handle_mouse_event(event) and event.pressed:
            self.go_home()
            return True
        if self.refresh_button.handle_mouse_event(event) and event.pressed:
            self.refresh()
            return True
        
        # Handle breadcrumb
        if self.breadcrumb.handle_mouse_event(event):
            return True
        
        return self.contains_point(point)
    
    fn render(self, ctx: RenderingContextInt):
        """Render navigation bar."""
        if not self.visible:
            return
        
        # Background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                     self.bounds.width, self.bounds.height)
        
        # Render buttons (appearance updated in update())
        self.back_button.render(ctx)
        self.forward_button.render(ctx)
        
        # Separator after navigation buttons
        var sep_x = self.up_button.bounds.x - self.button_spacing // 2
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_line(sep_x, self.bounds.y + 8, sep_x, self.bounds.y + self.bounds.height - 8, 1)
        
        self.up_button.render(ctx)
        self.home_button.render(ctx)
        
        # Separator before refresh
        var sep2_x = self.refresh_button.bounds.x - self.button_spacing // 2
        _ = ctx.draw_line(sep2_x, self.bounds.y + 8, sep2_x, self.bounds.y + self.bounds.height - 8, 1)
        
        self.refresh_button.render(ctx)
        
        # Separator before breadcrumb
        var sep3_x = self.breadcrumb_offset - self.button_spacing
        _ = ctx.draw_line(sep3_x, self.bounds.y + 8, sep3_x, self.bounds.y + self.bounds.height - 8, 1)
        
        # Render breadcrumb
        self.breadcrumb.render(ctx)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y,
                              self.bounds.width, self.bounds.height)
        
        # Render history menus
        if self.show_back_menu:
            self.render_history_menu(ctx, True)
        elif self.show_forward_menu:
            self.render_history_menu(ctx, False)
    
    fn update_button_appearance(mut self):
        """Update button visual states."""
        # Set theme for all buttons - simplified without theme system
        var normal_color = ColorInt(60, 60, 60, 255) if self.enabled else ColorInt(180, 180, 180, 255)
        var disabled_color = self.button_disabled_color
        
        # Update button opacities based on enabled state
        self.back_button.opacity = Float32(1.0) if self.back_button.enabled else Float32(0.5)
        self.forward_button.opacity = Float32(1.0) if self.forward_button.enabled else Float32(0.5)
        self.up_button.opacity = Float32(1.0) if self.up_button.enabled else Float32(0.5)
    
    fn render_history_menu(self, ctx: RenderingContextInt, is_back: Bool):
        """Render history dropdown menu."""
        var rect = self.get_history_menu_rect(is_back)
        var history = (self.history.get_back_history() if is_back
                       else self.history.get_forward_history())
        
        if len(history) == 0:
            return
        
        # Shadow
        _ = ctx.set_color(0, 0, 0, 30)
        _ = ctx.draw_filled_rectangle(rect.x + 2, rect.y + 2, rect.width, rect.height)
        
        # Background
        _ = ctx.set_color(self.menu_bg_color.r, self.menu_bg_color.g,
                         self.menu_bg_color.b, self.menu_bg_color.a)
        _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        # Items
        var item_height: Int32 = 24
        for i in range(min(len(history), 10)):
            var item_y = rect.y + 2 + Int32(i) * item_height

            # Hover background
            if Int32(i) == self.menu_hover_index:
                _ = ctx.set_color(self.menu_hover_color.r, self.menu_hover_color.g,
                                 self.menu_hover_color.b, self.menu_hover_color.a)
                _ = ctx.draw_filled_rectangle(rect.x + 2, item_y, rect.width - 4, item_height)
            
            # Text
            _ = ctx.set_color(self.menu_text_color.r, self.menu_text_color.g,
                             self.menu_text_color.b, self.menu_text_color.a)
            
            # Truncate long paths
            var display_path = history[i]
            var max_chars = 30
            if len(display_path) > max_chars:
                display_path = String("...") + String(display_path[len(display_path) - max_chars + 3:])
            
            _ = ctx.draw_text(display_path, rect.x + 8, item_y + 6, 11)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(rect.x, rect.y, rect.width, rect.height)
    
    fn update(mut self):
        """Update navigation bar state."""
        self.back_button.update()
        self.forward_button.update()
        self.up_button.update()
        self.home_button.update()
        self.refresh_button.update()
        self.breadcrumb.update()
        self.update_button_appearance()
    
    fn get_current_path(self) -> String:
        """Get current navigation path."""
        return self.current_path
    
    fn set_bounds(mut self, bounds: RectInt):
        """Override to update component positions."""
        self.bounds = bounds
        
        # Update button positions
        var button_y = bounds.y + (bounds.height - self.button_size) // 2
        var button_x = bounds.x + self.button_spacing
        
        self.back_button.bounds = RectInt(button_x, button_y, self.button_size, self.button_size)
        button_x += self.button_size + self.button_spacing
        
        self.forward_button.bounds = RectInt(button_x, button_y, self.button_size, self.button_size)
        button_x += self.button_size + self.button_spacing
        
        self.up_button.bounds = RectInt(button_x, button_y, self.button_size, self.button_size)
        button_x += self.button_size + self.button_spacing
        
        self.home_button.bounds = RectInt(button_x, button_y, self.button_size, self.button_size)
        button_x += self.button_size + self.button_spacing
        
        self.refresh_button.bounds = RectInt(button_x, button_y, self.button_size, self.button_size)
        button_x += self.button_size + self.button_spacing
        
        self.breadcrumb_offset = button_x + self.button_spacing
        
        # Update breadcrumb
        self.breadcrumb.bounds = RectInt(self.breadcrumb_offset, bounds.y,
                                        bounds.width - self.breadcrumb_offset - self.button_spacing,
                                        bounds.height)

# Convenience functions
fn create_navigation_bar_int(x: Int32, y: Int32, width: Int32, height: Int32 = 40) -> NavigationBarInt:
    """Create a navigation bar."""
    return NavigationBarInt(x, y, width, height)