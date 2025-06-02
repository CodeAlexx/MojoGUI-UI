"""
Button Widget Implementation
Interactive button widget with click handling and visual states.
"""

from ..rendering import RenderingContext, Color, Point, Size, Rect
from ..widget import Widget, BaseWidget, MouseEvent, KeyEvent

# Button states
alias BUTTON_NORMAL = 0
alias BUTTON_HOVER = 1
alias BUTTON_PRESSED = 2
alias BUTTON_DISABLED = 3

struct Button(BaseWidget):
    """Interactive button widget."""
    
    var text: String
    var text_color: Color
    var hover_color: Color
    var pressed_color: Color
    var disabled_color: Color
    var font_size: Float32
    var state: Int
    var was_pressed: Bool
    var click_callback: Optional[fn() -> None]
    
    fn __init__(inout self, x: Float32, y: Float32, width: Float32, height: Float32, text: String):
        """Initialize button."""
        self.super().__init__(x, y, width, height)
        self.text = text
        self.text_color = Color(0.0, 0.0, 0.0, 1.0)  # Black text
        self.hover_color = Color(0.8, 0.8, 1.0, 1.0)  # Light blue
        self.pressed_color = Color(0.6, 0.6, 0.9, 1.0)  # Darker blue
        self.disabled_color = Color(0.7, 0.7, 0.7, 1.0)  # Gray
        self.font_size = 14.0
        self.state = BUTTON_NORMAL
        self.was_pressed = False
        self.click_callback = None
        
        # Set default button appearance
        self.background_color = Color(0.9, 0.9, 0.9, 1.0)  # Light gray
        self.border_color = Color(0.5, 0.5, 0.5, 1.0)      # Gray border
        self.border_width = 2.0
    
    fn set_text(inout self, text: String):
        """Set button text."""
        self.text = text
    
    fn set_click_callback(inout self, callback: fn() -> None):
        """Set callback function for click events."""
        self.click_callback = callback
    
    fn set_state(inout self, state: Int):
        """Set button state."""
        if not self.enabled and state != BUTTON_DISABLED:
            return
        self.state = state
    
    fn get_current_background_color(self) -> Color:
        """Get background color based on current state."""
        if not self.enabled:
            return self.disabled_color
        elif self.state == BUTTON_PRESSED:
            return self.pressed_color
        elif self.state == BUTTON_HOVER:
            return self.hover_color
        else:
            return self.background_color
    
    fn handle_mouse_event(inout self, event: MouseEvent) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = Point(event.x, event.y)
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
                if self.click_callback:
                    self.click_callback.value()()
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
    
    fn handle_key_event(inout self, event: KeyEvent) -> Bool:
        """Handle key events (e.g., Enter to activate button)."""
        if not self.visible or not self.enabled:
            return False
        
        # Handle Enter key (key code 13) or Space (key code 32)
        if event.pressed and (event.key_code == 13 or event.key_code == 32):
            if self.click_callback:
                self.click_callback.value()()
            return True
        
        return False
    
    fn render(self, ctx: RenderingContext):
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
            let border_intensity = 1.0 if self.state == BUTTON_PRESSED else 0.8
            _ = ctx.set_color(self.border_color.r * border_intensity, 
                             self.border_color.g * border_intensity, 
                             self.border_color.b * border_intensity, 
                             self.border_color.a)
            _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y, 
                                  self.bounds.width, self.bounds.height)
        
        # Draw text
        if len(self.text) > 0:
            let text_alpha = 0.5 if not self.enabled else 1.0
            _ = ctx.set_color(self.text_color.r, self.text_color.g, 
                             self.text_color.b, self.text_color.a * text_alpha)
            
            # Center text
            let (text_width, text_height) = ctx.get_text_size(self.text, self.font_size)
            let text_x = self.bounds.x + (self.bounds.width - text_width) / 2.0
            let text_y = self.bounds.y + (self.bounds.height - text_height) / 2.0
            
            # Offset text slightly when pressed for visual feedback
            let offset = 1.0 if self.state == BUTTON_PRESSED else 0.0
            _ = ctx.draw_text(self.text, text_x + offset, text_y + offset, self.font_size)
    
    fn update(inout self):
        """Update button state."""
        # Reset to disabled state if not enabled
        if not self.enabled and self.state != BUTTON_DISABLED:
            self.state = BUTTON_DISABLED

# Convenience constructor functions
fn create_button(x: Float32, y: Float32, width: Float32, height: Float32, text: String) -> Button:
    """Create a standard button."""
    return Button(x, y, width, height, text)

fn create_primary_button(x: Float32, y: Float32, width: Float32, height: Float32, text: String) -> Button:
    """Create a primary (blue) button."""
    var button = Button(x, y, width, height, text)
    button.background_color = Color(0.2, 0.4, 0.9, 1.0)  # Blue
    button.hover_color = Color(0.3, 0.5, 1.0, 1.0)       # Lighter blue
    button.pressed_color = Color(0.1, 0.3, 0.8, 1.0)     # Darker blue
    button.text_color = Color(1.0, 1.0, 1.0, 1.0)        # White text
    button.border_color = Color(0.1, 0.2, 0.6, 1.0)      # Dark blue border
    return button

fn create_success_button(x: Float32, y: Float32, width: Float32, height: Float32, text: String) -> Button:
    """Create a success (green) button."""
    var button = Button(x, y, width, height, text)
    button.background_color = Color(0.2, 0.8, 0.3, 1.0)  # Green
    button.hover_color = Color(0.3, 0.9, 0.4, 1.0)       # Lighter green
    button.pressed_color = Color(0.1, 0.7, 0.2, 1.0)     # Darker green
    button.text_color = Color(1.0, 1.0, 1.0, 1.0)        # White text
    button.border_color = Color(0.1, 0.5, 0.2, 1.0)      # Dark green border
    return button

fn create_danger_button(x: Float32, y: Float32, width: Float32, height: Float32, text: String) -> Button:
    """Create a danger (red) button."""
    var button = Button(x, y, width, height, text)
    button.background_color = Color(0.9, 0.2, 0.2, 1.0)  # Red
    button.hover_color = Color(1.0, 0.3, 0.3, 1.0)       # Lighter red
    button.pressed_color = Color(0.8, 0.1, 0.1, 1.0)     # Darker red
    button.text_color = Color(1.0, 1.0, 1.0, 1.0)        # White text
    button.border_color = Color(0.6, 0.1, 0.1, 1.0)      # Dark red border
    return button