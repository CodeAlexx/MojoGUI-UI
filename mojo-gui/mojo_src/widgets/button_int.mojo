"""
Integer-Only Button Widget Implementation
Interactive button widget using only integer coordinates and colors.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

# Button states
alias BUTTON_NORMAL = 0
alias BUTTON_HOVER = 1
alias BUTTON_PRESSED = 2
alias BUTTON_DISABLED = 3

struct ButtonInt(BaseWidgetInt):
    """Interactive button widget using integer coordinates."""
    
    var text: String
    var text_color: ColorInt
    var hover_color: ColorInt
    var pressed_color: ColorInt
    var disabled_color: ColorInt
    var font_size: Int32
    var state: Int32
    var was_pressed: Bool
    var click_count: Int32  # Simple click tracking
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, text: String):
        """Initialize button."""
        self.super().__init__(x, y, width, height)
        self.text = text
        self.text_color = ColorInt(0, 0, 0, 255)  # Black text
        self.hover_color = ColorInt(200, 200, 255, 255)  # Light blue
        self.pressed_color = ColorInt(150, 150, 230, 255)  # Darker blue
        self.disabled_color = ColorInt(180, 180, 180, 255)  # Gray
        self.font_size = 14
        self.state = BUTTON_NORMAL
        self.was_pressed = False
        self.click_count = 0
        
        # Set default button appearance
        self.background_color = ColorInt(230, 230, 230, 255)  # Light gray
        self.border_color = ColorInt(128, 128, 128, 255)      # Gray border
        self.border_width = 2
    
    fn set_text(inout self, text: String):
        """Set button text."""
        self.text = text
    
    fn get_click_count(self) -> Int32:
        """Get number of times button has been clicked."""
        return self.click_count
    
    fn reset_click_count(inout self):
        """Reset click counter."""
        self.click_count = 0
    
    fn set_state(inout self, state: Int32):
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
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        let inside = self.contains_point(point)
        
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
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
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
        let bg_color = self.get_current_background_color()
        
        # Draw background
        _ = ctx.set_color(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y, 
                                     self.bounds.width, self.bounds.height)
        
        # Draw border
        if self.border_width > 0:
            let border_intensity: Int32 = 255 if self.state == BUTTON_PRESSED else 200
            _ = ctx.set_color((self.border_color.r * border_intensity) // 255, 
                             (self.border_color.g * border_intensity) // 255, 
                             (self.border_color.b * border_intensity) // 255, 
                             self.border_color.a)
            _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y, 
                                  self.bounds.width, self.bounds.height)
        
        # Draw text
        if len(self.text) > 0:
            let text_alpha: Int32 = 128 if not self.enabled else 255
            _ = ctx.set_color(self.text_color.r, self.text_color.g, 
                             self.text_color.b, (self.text_color.a * text_alpha) // 255)
            
            # Center text
            let text_width = ctx.get_text_width(self.text, self.font_size)
            let text_height = ctx.get_text_height(self.text, self.font_size)
            let text_x = self.bounds.x + (self.bounds.width - text_width) // 2
            let text_y = self.bounds.y + (self.bounds.height - text_height) // 2
            
            # Offset text slightly when pressed for visual feedback
            let offset: Int32 = 1 if self.state == BUTTON_PRESSED else 0
            _ = ctx.draw_text(self.text, text_x + offset, text_y + offset, self.font_size)
    
    fn update(inout self):
        """Update button state."""
        # Reset to disabled state if not enabled
        if not self.enabled and self.state != BUTTON_DISABLED:
            self.state = BUTTON_DISABLED

# Convenience constructor functions
fn create_button_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> ButtonInt:
    """Create a standard button."""
    return ButtonInt(x, y, width, height, text)

fn create_primary_button_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> ButtonInt:
    """Create a primary (blue) button."""
    var button = ButtonInt(x, y, width, height, text)
    button.background_color = ColorInt(50, 100, 230, 255)  # Blue
    button.hover_color = ColorInt(80, 130, 255, 255)       # Lighter blue
    button.pressed_color = ColorInt(30, 80, 200, 255)      # Darker blue
    button.text_color = ColorInt(255, 255, 255, 255)       # White text
    button.border_color = ColorInt(30, 60, 150, 255)       # Dark blue border
    return button

fn create_success_button_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> ButtonInt:
    """Create a success (green) button."""
    var button = ButtonInt(x, y, width, height, text)
    button.background_color = ColorInt(50, 200, 80, 255)   # Green
    button.hover_color = ColorInt(80, 230, 100, 255)       # Lighter green
    button.pressed_color = ColorInt(30, 180, 60, 255)      # Darker green
    button.text_color = ColorInt(255, 255, 255, 255)       # White text
    button.border_color = ColorInt(30, 130, 50, 255)       # Dark green border
    return button

fn create_danger_button_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> ButtonInt:
    """Create a danger (red) button."""
    var button = ButtonInt(x, y, width, height, text)
    button.background_color = ColorInt(230, 50, 50, 255)   # Red
    button.hover_color = ColorInt(255, 80, 80, 255)        # Lighter red
    button.pressed_color = ColorInt(200, 30, 30, 255)      # Darker red
    button.text_color = ColorInt(255, 255, 255, 255)       # White text
    button.border_color = ColorInt(150, 30, 30, 255)       # Dark red border
    return button