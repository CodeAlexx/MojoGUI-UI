"""
Integer-Only Button Widget Implementation
Interactive button widget using only integer coordinates and colors.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from ..theme_system import get_theme

# Button states
comptime BUTTON_NORMAL = 0
comptime BUTTON_HOVER = 1
comptime BUTTON_PRESSED = 2
comptime BUTTON_DISABLED = 3

struct ButtonInt(WidgetInt, Copyable, Movable):
    """Interactive button widget using integer coordinates."""

    # Inlined BaseWidgetInt fields (struct inheritance is not supported).
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var background_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32

    var text: String
    var text_color: ColorInt
    var hover_color: ColorInt
    var pressed_color: ColorInt
    var disabled_color: ColorInt
    var font_size: Int32
    var state: Int32
    var was_pressed: Bool
    var click_count: Int32  # Simple click tracking
    
    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32, text: String):
        """Initialize button."""
        # Inlined BaseWidgetInt.__init__
        self.bounds = RectInt(x, y, width, height)
        self.visible = True
        self.enabled = True
        self.background_color = ColorInt(230, 230, 230, 255)
        self.border_color = ColorInt(128, 128, 128, 255)
        self.border_width = 1
        self.text = text
        # Set colors using theme system
        var theme = get_theme()
        self.text_color = theme.primary_text
        self.hover_color = theme.button_hover
        self.pressed_color = theme.button_pressed
        self.disabled_color = theme.button_disabled
        self.font_size = 14
        self.state = BUTTON_NORMAL
        self.was_pressed = False
        self.click_count = 0
        
        # Set default button appearance using theme
        self.background_color = theme.button_normal
        self.border_color = theme.primary_border
        self.border_width = 2

    # Inlined BaseWidgetInt methods (struct inheritance is not supported).
    fn get_bounds(self) -> RectInt:
        return self.bounds

    fn set_bounds(mut self, bounds: RectInt):
        self.bounds = bounds

    fn is_visible(self) -> Bool:
        return self.visible

    fn set_visible(mut self, visible: Bool):
        self.visible = visible

    fn is_enabled(self) -> Bool:
        return self.enabled

    fn set_enabled(mut self, enabled: Bool):
        self.enabled = enabled

    fn contains_point(self, point: PointInt) -> Bool:
        return self.bounds.contains(point)

    fn render_background(self, ctx: RenderingContextInt):
        if not self.visible:
            return
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                          self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                      self.bounds.width, self.bounds.height)
        if self.border_width > 0:
            _ = ctx.set_color(self.border_color.r, self.border_color.g,
                              self.border_color.b, self.border_color.a)
            _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y,
                                   self.bounds.width, self.bounds.height)

    fn set_text(mut self, text: String):
        """Set button text."""
        self.text = text
    
    fn get_click_count(self) -> Int32:
        """Get number of times button has been clicked."""
        return self.click_count
    
    fn reset_click_count(mut self):
        """Reset click counter."""
        self.click_count = 0
    
    fn set_state(mut self, state: Int32):
        """Set button state."""
        if not self.enabled and state != BUTTON_DISABLED:
            return
        self.state = state
    
    fn get_current_background_color(self) -> ColorInt:
        """Get background color based on current state."""
        if not self.enabled:
            return self.disabled_color
        elif self.state == BUTTON_PRESSED:
            return self.pressed_color
        elif self.state == BUTTON_HOVER:
            return self.hover_color
        else:
            return self.background_color
    
    fn handle_mouse_event(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        var point = PointInt(event.x, event.y)
        var inside = self.contains_point(point)
        
        if event.pressed and inside:
            # Mouse pressed inside button
            self.set_state(BUTTON_PRESSED)
            self.was_pressed = True
            return True
        elif not event.pressed and self.was_pressed:
            # Mouse released
            if inside and self.state == BUTTON_PRESSED:
                # Click completed inside button
                self.click_count += 1
                self.set_state(BUTTON_HOVER)
            else:
                self.set_state(BUTTON_NORMAL)
            self.was_pressed = False
            return True
        elif inside and self.state == BUTTON_NORMAL:
            # Mouse hover
            self.set_state(BUTTON_HOVER)
            return True
        elif not inside and self.state == BUTTON_HOVER:
            # Mouse left hover area
            self.set_state(BUTTON_NORMAL)
        
        return inside
    
    fn handle_key_event(mut self, event: KeyEventInt) -> Bool:
        """Handle key events (e.g., Enter to activate button)."""
        if not self.visible or not self.enabled:
            return False
        
        # Handle Enter key (key code 257) or Space (key code 32)
        if event.pressed and (event.key_code == 257 or event.key_code == 32):
            self.click_count += 1
            return True
        
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render the button."""
        if not self.visible:
            return
        
        # Get current colors
        var bg_color = self.get_current_background_color()
        
        # Draw background
        _ = ctx.set_color(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y, 
                                     self.bounds.width, self.bounds.height)
        
        # Draw border
        if self.border_width > 0:
            var border_intensity: Int32 = 255 if self.state == BUTTON_PRESSED else 200
            _ = ctx.set_color((self.border_color.r * border_intensity) // 255, 
                             (self.border_color.g * border_intensity) // 255, 
                             (self.border_color.b * border_intensity) // 255, 
                             self.border_color.a)
            _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y, 
                                  self.bounds.width, self.bounds.height)
        
        # Draw text
        if len(self.text) > 0:
            var text_alpha: Int32 = 128 if not self.enabled else 255
            _ = ctx.set_color(self.text_color.r, self.text_color.g, 
                             self.text_color.b, (self.text_color.a * text_alpha) // 255)
            
            # Center text
            var text_width = ctx.get_text_width(self.text, self.font_size)
            var text_height = ctx.get_text_height(self.text, self.font_size)
            var text_x = self.bounds.x + (self.bounds.width - text_width) // 2
            var text_y = self.bounds.y + (self.bounds.height - text_height) // 2
            
            # Offset text slightly when pressed for visual feedback
            var offset: Int32 = 1 if self.state == BUTTON_PRESSED else 0
            _ = ctx.draw_text(self.text, text_x + offset, text_y + offset, self.font_size)
    
    fn update(mut self):
        """Update button state."""
        # Reset to disabled state if not enabled
        if not self.enabled and self.state != BUTTON_DISABLED:
            self.state = BUTTON_DISABLED

# Convenience constructor functions
fn create_button_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> ButtonInt:
    """Create a standard button."""
    return ButtonInt(x, y, width, height, text)

fn create_primary_button_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> ButtonInt:
    """Create a primary button using theme colors."""
    var button = ButtonInt(x, y, width, height, text)
    var theme = get_theme()
    button.background_color = theme.button_primary
    button.hover_color = theme.button_primary_hover
    button.pressed_color = theme.button_primary_pressed
    button.text_color = theme.button_primary_text
    button.border_color = theme.button_primary_border
    return button^

fn create_success_button_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> ButtonInt:
    """Create a success button using theme colors."""
    var button = ButtonInt(x, y, width, height, text)
    var theme = get_theme()
    button.background_color = theme.button_success
    button.hover_color = theme.button_success_hover
    button.pressed_color = theme.button_success_pressed
    button.text_color = theme.button_success_text
    button.border_color = theme.button_success_border
    return button^

fn create_danger_button_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> ButtonInt:
    """Create a danger button using theme colors."""
    var button = ButtonInt(x, y, width, height, text)
    var theme = get_theme()
    button.background_color = theme.button_danger
    button.hover_color = theme.button_danger_hover
    button.pressed_color = theme.button_danger_pressed
    button.text_color = theme.button_danger_text
    button.border_color = theme.button_danger_border
    return button^