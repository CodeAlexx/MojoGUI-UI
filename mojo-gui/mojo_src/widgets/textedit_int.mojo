"""
Integer-Only TextEdit Widget Implementation
Interactive text input field using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from ..theme_system import get_theme

struct TextEditInt(WidgetInt, Copyable, Movable):
    """Interactive text input widget using integer coordinates."""

    # Inlined BaseWidgetInt fields (struct inheritance is not supported).
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var background_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32

    var text: String
    var placeholder: String
    var text_color: ColorInt
    var placeholder_color: ColorInt
    var selection_color: ColorInt
    var cursor_color: ColorInt
    var font_size: Int32
    var cursor_position: Int32
    var selection_start: Int32
    var selection_end: Int32
    var is_focused: Bool
    var cursor_blink_time: Int32
    var max_length: Int32
    var is_readonly: Bool
    var padding: Int32
    
    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32, placeholder: String = ""):
        """Initialize text edit field."""
        # Inlined BaseWidgetInt.__init__
        self.bounds = RectInt(x, y, width, height)
        self.visible = True
        self.enabled = True
        self.background_color = ColorInt(230, 230, 230, 255)
        self.border_color = ColorInt(128, 128, 128, 255)
        self.border_width = 1
        self.text = ""
        self.placeholder = placeholder
        var theme = get_theme()
        self.text_color = theme.primary_text
        self.placeholder_color = theme.secondary_text
        self.selection_color = theme.selection_background
        self.cursor_color = theme.primary_text
        self.font_size = 14
        self.cursor_position = 0
        self.selection_start = -1
        self.selection_end = -1
        self.is_focused = False
        self.cursor_blink_time = 0
        self.max_length = 256
        self.is_readonly = False
        self.padding = 4
        
        # Set text field appearance
        self.background_color = theme.text_field_background
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

    fn get_text(self) -> String:
        """Get current text."""
        return self.text
    
    fn set_text(mut self, text: String):
        """Set text content."""
        if len(text) <= Int(self.max_length):
            self.text = text
            self.cursor_position = Int32(len(text))
            self.clear_selection()
        else:
            # Truncate if too long
            self.text = String(text[:Int(self.max_length)])
            self.cursor_position = self.max_length
            self.clear_selection()
    
    fn set_placeholder(mut self, placeholder: String):
        """Set placeholder text."""
        self.placeholder = placeholder
    
    fn set_readonly(mut self, readonly: Bool):
        """Set readonly state."""
        self.is_readonly = readonly
    
    fn set_focus(mut self, focused: Bool):
        """Set focus state."""
        self.is_focused = focused
        if not focused:
            self.clear_selection()
    
    fn clear_selection(mut self):
        """Clear text selection."""
        self.selection_start = -1
        self.selection_end = -1
    
    fn has_selection(self) -> Bool:
        """Check if there's a text selection."""
        return self.selection_start >= 0 and self.selection_end >= 0 and self.selection_start != self.selection_end
    
    fn get_selection_bounds(self) -> Tuple[Int32, Int32]:
        """Get selection start and end (ordered)."""
        if not self.has_selection():
            return Tuple[Int32, Int32](self.cursor_position, self.cursor_position)

        var start = self.selection_start if self.selection_start < self.selection_end else self.selection_end
        var end = self.selection_end if self.selection_end > self.selection_start else self.selection_start
        return Tuple[Int32, Int32](start, end)
    
    fn insert_text_at_cursor(mut self, insert_text: String):
        """Insert text at cursor position."""
        if self.is_readonly:
            return
        
        # Delete selection if exists
        if self.has_selection():
            self.delete_selection()
        
        # Check length limit
        if len(self.text) + len(insert_text) > Int(self.max_length):
            return
        
        # Insert text
        var before = self.text[:Int(self.cursor_position)]
        var after = self.text[Int(self.cursor_position):]
        self.text = before + insert_text + after
        self.cursor_position += len(insert_text)
        self.clear_selection()
    
    fn delete_selection(mut self):
        """Delete selected text."""
        if not self.has_selection() or self.is_readonly:
            return
        
        var bounds = self.get_selection_bounds()
        var start = bounds[0]
        var end = bounds[1]

        var before = self.text[:Int(start)]
        var after = self.text[Int(end):]
        self.text = before + after
        self.cursor_position = start
        self.clear_selection()
    
    fn delete_char_before_cursor(mut self):
        """Delete character before cursor (Backspace)."""
        if self.is_readonly:
            return
        
        if self.has_selection():
            self.delete_selection()
        elif self.cursor_position > 0:
            var before = self.text[:Int(self.cursor_position) - 1]
            var after = self.text[Int(self.cursor_position):]
            self.text = before + after
            self.cursor_position -= 1
    
    fn delete_char_after_cursor(mut self):
        """Delete character after cursor (Delete)."""
        if self.is_readonly:
            return
        
        if self.has_selection():
            self.delete_selection()
        elif self.cursor_position < len(self.text):
            var before = self.text[:Int(self.cursor_position)]
            var after = self.text[Int(self.cursor_position) + 1:]
            self.text = before + after
    
    fn move_cursor(mut self, delta: Int32, extend_selection: Bool = False):
        """Move cursor position."""
        var new_pos = self.cursor_position + delta
        
        # Clamp position
        if new_pos < 0:
            self.cursor_position = 0
        elif new_pos > len(self.text):
            self.cursor_position = len(self.text)
        else:
            self.cursor_position = new_pos
        
        # Handle selection
        if extend_selection:
            if self.selection_start < 0:
                self.selection_start = self.cursor_position - delta
            self.selection_end = self.cursor_position
        else:
            self.clear_selection()
    
    fn get_text_rect(self) -> RectInt:
        """Get the text area rectangle."""
        return RectInt(self.bounds.x + self.padding, self.bounds.y + self.padding,
                      self.bounds.width - 2 * self.padding, self.bounds.height - 2 * self.padding)
    
    fn handle_mouse_event(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        var point = PointInt(event.x, event.y)
        var inside = self.contains_point(point)
        
        if event.pressed and inside:
            # Set focus and position cursor
            self.set_focus(True)
            
            # Simple cursor positioning (would need text metrics for accuracy)
            var text_rect = self.get_text_rect()
            var char_width = self.font_size * 6 / 10  # Rough approximation
            var relative_x = point.x - text_rect.x
            self.cursor_position = relative_x / char_width
            
            # Clamp cursor position
            if self.cursor_position < 0:
                self.cursor_position = 0
            elif self.cursor_position > len(self.text):
                self.cursor_position = len(self.text)
            
            self.clear_selection()
            return True
        elif event.pressed and not inside:
            # Lose focus when clicking outside
            self.set_focus(False)
        
        return inside
    
    fn handle_key_event(mut self, event: KeyEventInt) -> Bool:
        """Handle keyboard input."""
        if not self.visible or not self.enabled or not self.is_focused:
            return False
        
        if event.pressed:
            var key = event.key_code
            
            # Special keys
            if key == 259:  # Backspace
                self.delete_char_before_cursor()
                return True
            elif key == 261:  # Delete
                self.delete_char_after_cursor()
                return True
            elif key == 262:  # Right arrow
                self.move_cursor(1)
                return True
            elif key == 263:  # Left arrow
                self.move_cursor(-1)
                return True
            elif key == 268:  # Home
                self.cursor_position = 0
                self.clear_selection()
                return True
            elif key == 269:  # End
                self.cursor_position = len(self.text)
                self.clear_selection()
                return True
            elif key == 257:  # Enter
                # Could trigger validation or move to next field
                return True
            elif key >= 32 and key <= 126:  # Printable ASCII
                # Insert character
                var char_text = chr(Int(key))
                self.insert_text_at_cursor(char_text)
                return True
        
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render the text edit field."""
        if not self.visible:
            return
        
        # Draw background and border
        self.render_background(ctx)
        
        # Update focus appearance
        if self.is_focused:
            var theme = get_theme()
            _ = ctx.set_color(theme.accent_primary.r, theme.accent_primary.g, theme.accent_primary.b, theme.accent_primary.a)
            _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
        
        var text_rect = self.get_text_rect()
        
        # Draw selection background
        if self.has_selection():
            var bounds = self.get_selection_bounds()
            var char_width = self.font_size * 6 / 10  # Rough approximation
            var sel_x = text_rect.x + bounds[0] * char_width
            var sel_width = (bounds[1] - bounds[0]) * char_width
            
            _ = ctx.set_color(self.selection_color.r, self.selection_color.g, 
                             self.selection_color.b, self.selection_color.a)
            _ = ctx.draw_filled_rectangle(sel_x, text_rect.y, sel_width, text_rect.height)
        
        # Draw text or placeholder
        if len(self.text) > 0:
            _ = ctx.set_color(self.text_color.r, self.text_color.g, 
                             self.text_color.b, self.text_color.a)
            _ = ctx.draw_text(self.text, text_rect.x, text_rect.y + (text_rect.height - self.font_size) // 2, self.font_size)
        elif len(self.placeholder) > 0:
            _ = ctx.set_color(self.placeholder_color.r, self.placeholder_color.g, 
                             self.placeholder_color.b, self.placeholder_color.a)
            _ = ctx.draw_text(self.placeholder, text_rect.x, text_rect.y + (text_rect.height - self.font_size) // 2, self.font_size)
        
        # Draw cursor
        if self.is_focused and (self.cursor_blink_time // 30) % 2 == 0:  # Blink every 30 frames
            var char_width = self.font_size * 6 / 10  # Rough approximation
            var cursor_x = text_rect.x + self.cursor_position * char_width
            
            _ = ctx.set_color(self.cursor_color.r, self.cursor_color.g, 
                             self.cursor_color.b, self.cursor_color.a)
            _ = ctx.draw_line(cursor_x, text_rect.y, cursor_x, text_rect.y + text_rect.height, 1)
    
    fn update(mut self):
        """Update text edit state."""
        if self.is_focused:
            self.cursor_blink_time += 1

# Convenience constructor functions
fn create_textedit_int(x: Int32, y: Int32, width: Int32, height: Int32, placeholder: String = "") -> TextEditInt:
    """Create a standard text edit field."""
    return TextEditInt(x, y, width, height, placeholder)

fn create_password_field_int(x: Int32, y: Int32, width: Int32, height: Int32) -> TextEditInt:
    """Create a password input field."""
    var field = TextEditInt(x, y, width, height, "Enter password...")
    # Note: For a real password field, we'd need to mask the display
    return field