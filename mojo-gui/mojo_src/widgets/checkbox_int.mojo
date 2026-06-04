"""
Integer-Only Checkbox Widget Implementation
Interactive checkbox for boolean selections using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from ..theme_system import get_theme

# Checkbox styles
comptime CHECKBOX_SQUARE = 0
comptime CHECKBOX_ROUND = 1

# Check mark styles
comptime CHECK_MARK = 0
comptime CHECK_FILLED = 1
comptime CHECK_DOT = 2

struct CheckboxInt(WidgetInt, Copyable, Movable):
    """Interactive checkbox widget using integer coordinates."""

    # Inlined BaseWidgetInt fields (struct inheritance is not supported).
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var background_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32

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
    
    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32, text: String,
                style: Int32 = CHECKBOX_SQUARE, check_style: Int32 = CHECK_FILLED):
        """Initialize checkbox."""
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
        self.check_color = theme.checkbox_mark
        self.check_background_color = theme.checkbox_checked_bg
        self.hover_color = theme.checkbox_hover
        self.font_size = 14
        self.checked = False
        self.was_pressed = False
        self.is_hovering = False
        self.box_size = height - 4  # Box slightly smaller than height
        self.text_offset = self.box_size + 8  # Space between box and text
        self.style = style
        self.check_style = check_style
        self.use_check_background = True
        
        # Set checkbox appearance using theme
        self.background_color = theme.checkbox_background
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
        """Set checkbox text."""
        self.text = text
    
    fn is_checked(self) -> Bool:
        """Get checkbox state."""
        return self.checked
    
    fn set_checked(mut self, checked: Bool):
        """Set checkbox state."""
        self.checked = checked
    
    fn toggle(mut self):
        """Toggle checkbox state."""
        self.checked = not self.checked
    
    fn get_box_rect(self) -> RectInt:
        """Get the checkbox box rectangle."""
        var center_y = self.bounds.y + (self.bounds.height - self.box_size) // 2
        return RectInt(self.bounds.x, center_y, self.box_size, self.box_size)
    
    fn handle_mouse_event(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        var point = PointInt(event.x, event.y)
        var inside = self.contains_point(point)
        
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
    
    fn handle_key_event(mut self, event: KeyEventInt) -> Bool:
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
        
        var box_rect = self.get_box_rect()
        var center_x = box_rect.x + box_rect.width // 2
        var center_y = box_rect.y + box_rect.height // 2
        var radius = self.box_size // 2
        
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
            var border_intensity: Int32 = 200 if self.enabled else 128
            var border_r = (self.border_color.r * border_intensity) // 255
            var border_g = (self.border_color.g * border_intensity) // 255
            var border_b = (self.border_color.b * border_intensity) // 255
            _ = ctx.set_color(border_r, border_g, border_b, self.border_color.a)
            
            if self.style == CHECKBOX_ROUND:
                # Draw round border (simple approximation)
                var border_radius = radius + 1
                # Draw border as multiple circles for rounded effect
                _ = ctx.draw_filled_circle(center_x, center_y - border_radius, 1, 4)
                _ = ctx.draw_filled_circle(center_x + border_radius, center_y, 1, 4)
                _ = ctx.draw_filled_circle(center_x, center_y + border_radius, 1, 4)
                _ = ctx.draw_filled_circle(center_x - border_radius, center_y, 1, 4)
                # Diagonal points
                var diag_offset = (border_radius * 7) // 10
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
                var dot_radius = self.box_size // 4
                _ = ctx.draw_filled_circle(center_x, center_y, dot_radius, 8)
            else:
                # Draw traditional checkmark
                var check_margin = self.box_size // 4
                var check_x1 = box_rect.x + check_margin
                var check_y1 = box_rect.y + self.box_size // 2
                var check_x2 = box_rect.x + self.box_size // 2
                var check_y2 = box_rect.y + self.box_size - check_margin
                var check_x3 = box_rect.x + self.box_size - check_margin
                var check_y3 = box_rect.y + check_margin
                
                # Draw checkmark as thick lines
                for i in range(3):
                    _ = ctx.draw_line(check_x1, check_y1 + i, check_x2, check_y2 + i, 1)
                    _ = ctx.draw_line(check_x2, check_y2 + i, check_x3, check_y3 + i, 1)
        
        # Draw text
        if len(self.text) > 0:
            var text_alpha: Int32 = 255 if self.enabled else 128
            _ = ctx.set_color(self.text_color.r, self.text_color.g, 
                             self.text_color.b, (self.text_color.a * text_alpha) // 255)
            
            var text_x = self.bounds.x + self.text_offset
            var text_y = self.bounds.y + (self.bounds.height - self.font_size) // 2
            _ = ctx.draw_text(self.text, text_x, text_y, self.font_size)
    
    fn set_style(mut self, style: Int32):
        """Set checkbox style (CHECKBOX_SQUARE or CHECKBOX_ROUND)."""
        self.style = style
    
    fn set_check_style(mut self, check_style: Int32):
        """Set check mark style (CHECK_MARK, CHECK_FILLED, or CHECK_DOT)."""
        self.check_style = check_style
    
    fn set_check_background_color(mut self, color: ColorInt):
        """Set the background color when checked."""
        self.check_background_color = color
    
    fn set_use_check_background(mut self, use_background: Bool):
        """Enable/disable colored background when checked."""
        self.use_check_background = use_background
    
    fn set_check_color(mut self, color: ColorInt):
        """Set the check mark color."""
        self.check_color = color
    
    fn update(mut self):
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
    var style = CHECKBOX_ROUND if round else CHECKBOX_SQUARE
    var checkbox = CheckboxInt(x, y, width, height, text, style, CHECK_MARK)
    checkbox.set_use_check_background(False)
    var theme = get_theme()
    checkbox.set_check_color(theme.checkbox_mark_color)
    return checkbox^

fn create_checkbox_int_checked(x: Int32, y: Int32, width: Int32, height: Int32, text: String, round: Bool = False) -> CheckboxInt:
    """Create a checkbox that starts checked."""
    var style = CHECKBOX_ROUND if round else CHECKBOX_SQUARE
    var checkbox = CheckboxInt(x, y, width, height, text, style, CHECK_FILLED)
    checkbox.set_checked(True)
    return checkbox^