"""
Integer-Only Checkbox Widget Implementation
Interactive checkbox for boolean selections using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

# Checkbox styles
alias CHECKBOX_SQUARE = 0
alias CHECKBOX_ROUND = 1

# Check mark styles
alias CHECK_MARK = 0
alias CHECK_FILLED = 1
alias CHECK_DOT = 2

struct CheckboxInt(BaseWidgetInt):
    """Interactive checkbox widget using integer coordinates."""
    
    var text: String
    var text_color: ColorInt
    var check_color: ColorInt
    var check_background_color: ColorInt
    var hover_color: ColorInt
    var font_size: Int32
    var checked: Bool
    var was_pressed: Bool
    var is_hovering: Bool
    var box_size: Int32
    var text_offset: Int32
    var style: Int32  # CHECKBOX_SQUARE or CHECKBOX_ROUND
    var check_style: Int32  # CHECK_MARK, CHECK_FILLED, or CHECK_DOT
    var use_check_background: Bool
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, text: String, 
                style: Int32 = CHECKBOX_SQUARE, check_style: Int32 = CHECK_FILLED):
        """Initialize checkbox."""
        self.super().__init__(x, y, width, height)
        self.text = text
        self.text_color = ColorInt(0, 0, 0, 255)  # Black text
        self.check_color = ColorInt(255, 255, 255, 255)  # White checkmark for better visibility
        self.check_background_color = ColorInt(50, 150, 50, 255)  # Green background when checked
        self.hover_color = ColorInt(220, 220, 255, 255)  # Light blue hover
        self.font_size = 14
        self.checked = False
        self.was_pressed = False
        self.is_hovering = False
        self.box_size = height - 4  # Box slightly smaller than height
        self.text_offset = self.box_size + 8  # Space between box and text
        self.style = style
        self.check_style = check_style
        self.use_check_background = True
        
        # Set checkbox appearance
        self.background_color = ColorInt(255, 255, 255, 255)  # White background
        self.border_color = ColorInt(128, 128, 128, 255)      # Gray border
        self.border_width = 2
    
    fn set_text(inout self, text: String):
        """Set checkbox text."""
        self.text = text
    
    fn is_checked(self) -> Bool:
        """Get checkbox state."""
        return self.checked
    
    fn set_checked(inout self, checked: Bool):
        """Set checkbox state."""
        self.checked = checked
    
    fn toggle(inout self):
        """Toggle checkbox state."""
        self.checked = not self.checked
    
    fn get_box_rect(self) -> RectInt:
        """Get the checkbox box rectangle."""
        let center_y = self.bounds.y + (self.bounds.height - self.box_size) // 2
        return RectInt(self.bounds.x, center_y, self.box_size, self.box_size)
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        let inside = self.contains_point(point)
        
        # Update hover state
        self.is_hovering = inside
        
        if event.pressed and inside:
            # Mouse pressed inside checkbox
            self.was_pressed = True
            return True
        elif not event.pressed and self.was_pressed:
            # Mouse released
            if inside:
                # Click completed inside checkbox - toggle state
                self.toggle()
            self.was_pressed = False
            return True
        
        return inside
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle key events (Space to toggle)."""
        if not self.visible or not self.enabled:
            return False
        
        # Handle Space key (key code 32)
        if event.pressed and event.key_code == 32:
            self.toggle()
            return True
        
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render the checkbox."""
        if not self.visible:
            return
        
        let box_rect = self.get_box_rect()
        let center_x = box_rect.x + box_rect.width // 2
        let center_y = box_rect.y + box_rect.height // 2
        let radius = self.box_size // 2
        
        # Choose background color based on state
        var bg_color = self.background_color
        if self.checked and self.use_check_background:
            bg_color = self.check_background_color
        elif self.is_hovering:
            bg_color = self.hover_color
        
        # Draw checkbox background
        _ = ctx.set_color(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
        
        if self.style == CHECKBOX_ROUND:
            # Draw round checkbox
            _ = ctx.draw_filled_circle(center_x, center_y, radius, 16)
        else:
            # Draw square checkbox
            _ = ctx.draw_filled_rectangle(box_rect.x, box_rect.y, box_rect.width, box_rect.height)
        
        # Draw border
        if self.border_width > 0:
            let border_intensity: Int32 = 200 if self.enabled else 128
            let border_r = (self.border_color.r * border_intensity) // 255
            let border_g = (self.border_color.g * border_intensity) // 255
            let border_b = (self.border_color.b * border_intensity) // 255
            _ = ctx.set_color(border_r, border_g, border_b, self.border_color.a)
            
            if self.style == CHECKBOX_ROUND:
                # Draw round border (simple approximation)
                let border_radius = radius + 1
                # Draw border as multiple circles for rounded effect
                _ = ctx.draw_filled_circle(center_x, center_y - border_radius, 1, 4)
                _ = ctx.draw_filled_circle(center_x + border_radius, center_y, 1, 4)
                _ = ctx.draw_filled_circle(center_x, center_y + border_radius, 1, 4)
                _ = ctx.draw_filled_circle(center_x - border_radius, center_y, 1, 4)
                # Diagonal points
                let diag_offset = (border_radius * 7) // 10
                _ = ctx.draw_filled_circle(center_x + diag_offset, center_y - diag_offset, 1, 4)
                _ = ctx.draw_filled_circle(center_x + diag_offset, center_y + diag_offset, 1, 4)
                _ = ctx.draw_filled_circle(center_x - diag_offset, center_y + diag_offset, 1, 4)
                _ = ctx.draw_filled_circle(center_x - diag_offset, center_y - diag_offset, 1, 4)
            else:
                _ = ctx.draw_rectangle(box_rect.x, box_rect.y, box_rect.width, box_rect.height)
        
        # Draw check mark if checked
        if self.checked:
            _ = ctx.set_color(self.check_color.r, self.check_color.g, 
                             self.check_color.b, self.check_color.a)
            
            if self.check_style == CHECK_FILLED:
                # Fill entire area with check color (already done with background)
                pass
            elif self.check_style == CHECK_DOT:
                # Draw a dot in the center
                let dot_radius = self.box_size // 4
                _ = ctx.draw_filled_circle(center_x, center_y, dot_radius, 8)
            else:
                # Draw traditional checkmark
                let check_margin = self.box_size // 4
                let check_x1 = box_rect.x + check_margin
                let check_y1 = box_rect.y + self.box_size // 2
                let check_x2 = box_rect.x + self.box_size // 2
                let check_y2 = box_rect.y + self.box_size - check_margin
                let check_x3 = box_rect.x + self.box_size - check_margin
                let check_y3 = box_rect.y + check_margin
                
                # Draw checkmark as thick lines
                for i in range(3):
                    _ = ctx.draw_line(check_x1, check_y1 + i, check_x2, check_y2 + i, 1)
                    _ = ctx.draw_line(check_x2, check_y2 + i, check_x3, check_y3 + i, 1)
        
        # Draw text
        if len(self.text) > 0:
            let text_alpha: Int32 = 255 if self.enabled else 128
            _ = ctx.set_color(self.text_color.r, self.text_color.g, 
                             self.text_color.b, (self.text_color.a * text_alpha) // 255)
            
            let text_x = self.bounds.x + self.text_offset
            let text_y = self.bounds.y + (self.bounds.height - self.font_size) // 2
            _ = ctx.draw_text(self.text, text_x, text_y, self.font_size)
    
    fn set_style(inout self, style: Int32):
        """Set checkbox style (CHECKBOX_SQUARE or CHECKBOX_ROUND)."""
        self.style = style
    
    fn set_check_style(inout self, check_style: Int32):
        """Set check mark style (CHECK_MARK, CHECK_FILLED, or CHECK_DOT)."""
        self.check_style = check_style
    
    fn set_check_background_color(inout self, color: ColorInt):
        """Set the background color when checked."""
        self.check_background_color = color
    
    fn set_use_check_background(inout self, use_background: Bool):
        """Enable/disable colored background when checked."""
        self.use_check_background = use_background
    
    fn set_check_color(inout self, color: ColorInt):
        """Set the check mark color."""
        self.check_color = color
    
    fn update(inout self):
        """Update checkbox state."""
        # Nothing to update for basic checkbox
        pass

# Convenience constructor functions
fn create_checkbox_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> CheckboxInt:
    """Create a standard square checkbox with filled background when checked."""
    return CheckboxInt(x, y, width, height, text, CHECKBOX_SQUARE, CHECK_FILLED)

fn create_round_checkbox_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> CheckboxInt:
    """Create a round checkbox with filled background when checked."""
    return CheckboxInt(x, y, width, height, text, CHECKBOX_ROUND, CHECK_FILLED)

fn create_checkbox_int_with_mark(x: Int32, y: Int32, width: Int32, height: Int32, text: String, round: Bool = False) -> CheckboxInt:
    """Create a checkbox with traditional check mark (no background fill)."""
    let style = CHECKBOX_ROUND if round else CHECKBOX_SQUARE
    var checkbox = CheckboxInt(x, y, width, height, text, style, CHECK_MARK)
    checkbox.set_use_check_background(False)
    checkbox.set_check_color(ColorInt(0, 150, 0, 255))  # Green check mark
    return checkbox

fn create_checkbox_int_checked(x: Int32, y: Int32, width: Int32, height: Int32, text: String, round: Bool = False) -> CheckboxInt:
    """Create a checkbox that starts checked."""
    let style = CHECKBOX_ROUND if round else CHECKBOX_SQUARE
    var checkbox = CheckboxInt(x, y, width, height, text, style, CHECK_FILLED)
    checkbox.set_checked(True)
    return checkbox