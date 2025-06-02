"""
Integer-Only Dialog Widget Implementation
Modal dialog window using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

# Dialog types
alias DIALOG_INFO = 0
alias DIALOG_WARNING = 1
alias DIALOG_ERROR = 2
alias DIALOG_QUESTION = 3
alias DIALOG_CUSTOM = 4

# Dialog buttons
alias DIALOG_OK = 0
alias DIALOG_CANCEL = 1
alias DIALOG_YES = 2
alias DIALOG_NO = 3
alias DIALOG_CLOSE = 4

struct DialogButtonInt:
    """Dialog button definition."""
    var text: String
    var button_type: Int32
    var rect: RectInt
    var enabled: Bool
    
    fn __init__(inout self, text: String, button_type: Int32):
        self.text = text
        self.button_type = button_type
        self.rect = RectInt(0, 0, 0, 0)
        self.enabled = True

struct DialogInt(BaseWidgetInt):
    """Modal dialog widget using integer coordinates."""
    
    var title: String
    var message: String
    var dialog_type: Int32
    var buttons: List[DialogButtonInt]
    var result: Int32
    var is_modal: Bool
    var is_open: Bool
    var is_dragging: Bool
    var drag_offset: PointInt
    
    # Visual properties
    var title_color: ColorInt
    var message_color: ColorInt
    var title_background: ColorInt
    var button_color: ColorInt
    var button_hover_color: ColorInt
    var button_text_color: ColorInt
    var overlay_color: ColorInt
    var shadow_color: ColorInt
    
    var title_height: Int32
    var button_height: Int32
    var button_width: Int32
    var margin: Int32
    var font_size: Int32
    var title_font_size: Int32
    var hover_button: Int32
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, 
               title: String, message: String, dialog_type: Int32 = DIALOG_INFO):
        """Initialize dialog."""
        self.super().__init__(x, y, width, height)
        self.title = title
        self.message = message
        self.dialog_type = dialog_type
        self.buttons = List[DialogButtonInt]()
        self.result = -1
        self.is_modal = True
        self.is_open = False
        self.is_dragging = False
        self.drag_offset = PointInt(0, 0)
        
        # Colors based on dialog type
        self.title_color = ColorInt(255, 255, 255, 255)       # White title text
        self.message_color = ColorInt(0, 0, 0, 255)           # Black message text
        self.button_color = ColorInt(220, 220, 220, 255)      # Light gray buttons
        self.button_hover_color = ColorInt(200, 220, 255, 255) # Light blue hover
        self.button_text_color = ColorInt(0, 0, 0, 255)       # Black button text
        self.overlay_color = ColorInt(0, 0, 0, 128)           # Semi-transparent overlay
        self.shadow_color = ColorInt(0, 0, 0, 64)             # Shadow
        
        # Set title background based on type
        if dialog_type == DIALOG_INFO:
            self.title_background = ColorInt(60, 120, 200, 255)  # Blue
        elif dialog_type == DIALOG_WARNING:
            self.title_background = ColorInt(255, 165, 0, 255)   # Orange
        elif dialog_type == DIALOG_ERROR:
            self.title_background = ColorInt(200, 60, 60, 255)   # Red
        elif dialog_type == DIALOG_QUESTION:
            self.title_background = ColorInt(100, 150, 100, 255) # Green
        else:
            self.title_background = ColorInt(120, 120, 120, 255) # Gray
        
        self.title_height = 30
        self.button_height = 35
        self.button_width = 80
        self.margin = 15
        self.font_size = 12
        self.title_font_size = 14
        self.hover_button = -1
        
        # Set appearance
        self.background_color = ColorInt(240, 240, 240, 255)  # Light gray dialog
        self.border_color = ColorInt(100, 100, 100, 255)      # Dark gray border
        self.border_width = 2
    
    fn add_button(inout self, text: String, button_type: Int32):
        """Add button to dialog."""
        self.buttons.append(DialogButtonInt(text, button_type))
        self.layout_buttons()
    
    fn add_ok_button(inout self):
        """Add OK button."""
        self.add_button("OK", DIALOG_OK)
    
    fn add_cancel_button(inout self):
        """Add Cancel button."""
        self.add_button("Cancel", DIALOG_CANCEL)
    
    fn add_yes_no_buttons(inout self):
        """Add Yes and No buttons."""
        self.add_button("Yes", DIALOG_YES)
        self.add_button("No", DIALOG_NO)
    
    fn add_ok_cancel_buttons(inout self):
        """Add OK and Cancel buttons."""
        self.add_ok_button()
        self.add_cancel_button()
    
    fn layout_buttons(inout self):
        """Layout buttons at bottom of dialog."""
        let button_count = len(self.buttons)
        if button_count == 0:
            return
        
        let total_width = button_count * self.button_width + (button_count - 1) * 10
        let start_x = self.bounds.x + (self.bounds.width - total_width) // 2
        let button_y = self.bounds.y + self.bounds.height - self.margin - self.button_height
        
        for i in range(button_count):
            let button_x = start_x + i * (self.button_width + 10)
            self.buttons[i].rect = RectInt(button_x, button_y, self.button_width, self.button_height)
    
    fn show(inout self):
        """Show the dialog."""
        self.is_open = True
        self.result = -1
    
    fn hide(inout self):
        """Hide the dialog."""
        self.is_open = False
    
    fn get_result(self) -> Int32:
        """Get dialog result."""
        return self.result
    
    fn is_visible(self) -> Bool:
        """Check if dialog is visible."""
        return self.is_open and self.visible
    
    fn get_title_rect(self) -> RectInt:
        """Get title bar rectangle."""
        return RectInt(self.bounds.x, self.bounds.y, self.bounds.width, self.title_height)
    
    fn get_content_rect(self) -> RectInt:
        """Get content area rectangle."""
        return RectInt(self.bounds.x + self.margin, 
                      self.bounds.y + self.title_height + self.margin,
                      self.bounds.width - 2 * self.margin,
                      self.bounds.height - self.title_height - 2 * self.margin - self.button_height - 10)
    
    fn button_from_point(self, point: PointInt) -> Int32:
        """Get button index from point."""
        for i in range(len(self.buttons)):
            if self.buttons[i].rect.contains(point):
                return i
        return -1
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.is_visible():
            return False
        
        let point = PointInt(event.x, event.y)
        
        if event.pressed:
            # Check title bar for dragging
            let title_rect = self.get_title_rect()
            if title_rect.contains(point):
                self.is_dragging = True
                self.drag_offset = PointInt(point.x - self.bounds.x, point.y - self.bounds.y)
                return True
            
            # Check buttons
            let button_index = self.button_from_point(point)
            if button_index >= 0 and self.buttons[button_index].enabled:
                self.result = self.buttons[button_index].button_type
                self.hide()
                return True
            
            # Consume all clicks when modal
            return self.is_modal
        
        elif not event.pressed and self.is_dragging:
            self.is_dragging = False
            return True
        
        elif self.is_dragging:
            # Update dialog position
            self.bounds.x = point.x - self.drag_offset.x
            self.bounds.y = point.y - self.drag_offset.y
            self.layout_buttons()  # Recalculate button positions
            return True
        
        # Update hover state
        self.hover_button = self.button_from_point(point)
        
        return self.is_modal and self.contains_point(point)
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle key events."""
        if not self.is_visible():
            return False
        
        if event.pressed:
            if event.key_code == 256:  # Escape
                # Close dialog with cancel/no result
                for i in range(len(self.buttons)):
                    if self.buttons[i].button_type == DIALOG_CANCEL or self.buttons[i].button_type == DIALOG_NO:
                        self.result = self.buttons[i].button_type
                        self.hide()
                        return True
                # No cancel button, just close
                self.result = -1
                self.hide()
                return True
            elif event.key_code == 257:  # Enter
                # Activate first button (usually OK/Yes)
                if len(self.buttons) > 0:
                    self.result = self.buttons[0].button_type
                    self.hide()
                    return True
        
        return self.is_modal
    
    fn render(self, ctx: RenderingContextInt):
        """Render the dialog."""
        if not self.is_visible():
            return
        
        # Draw overlay if modal
        if self.is_modal:
            _ = ctx.set_color(self.overlay_color.r, self.overlay_color.g,
                             self.overlay_color.b, self.overlay_color.a)
            _ = ctx.draw_filled_rectangle(0, 0, 1200, 800)  # Full screen overlay
        
        # Draw shadow
        _ = ctx.set_color(self.shadow_color.r, self.shadow_color.g,
                         self.shadow_color.b, self.shadow_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x + 5, self.bounds.y + 5,
                                     self.bounds.width, self.bounds.height)
        
        # Draw dialog background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
        
        # Draw border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
        
        # Draw title bar
        let title_rect = self.get_title_rect()
        _ = ctx.set_color(self.title_background.r, self.title_background.g,
                         self.title_background.b, self.title_background.a)
        _ = ctx.draw_filled_rectangle(title_rect.x, title_rect.y, title_rect.width, title_rect.height)
        
        # Draw title text
        _ = ctx.set_color(self.title_color.r, self.title_color.g,
                         self.title_color.b, self.title_color.a)
        let title_x = title_rect.x + 10
        let title_y = title_rect.y + (title_rect.height - self.title_font_size) // 2
        _ = ctx.draw_text(self.title, title_x, title_y, self.title_font_size)
        
        # Draw message
        let content_rect = self.get_content_rect()
        _ = ctx.set_color(self.message_color.r, self.message_color.g,
                         self.message_color.b, self.message_color.a)
        
        # Simple word wrapping (basic implementation)
        let lines = self.wrap_text(self.message, content_rect.width)
        for i in range(len(lines)):
            let line_y = content_rect.y + i * (self.font_size + 4)
            _ = ctx.draw_text(lines[i], content_rect.x, line_y, self.font_size)
        
        # Draw buttons
        for i in range(len(self.buttons)):
            self.render_button(ctx, i)
    
    fn render_button(self, ctx: RenderingContextInt, button_index: Int32):
        """Render individual button."""
        let button = self.buttons[button_index]
        let is_hover = (button_index == self.hover_button)
        
        # Draw button background
        let button_color = self.button_hover_color if is_hover else self.button_color
        _ = ctx.set_color(button_color.r, button_color.g, button_color.b, button_color.a)
        _ = ctx.draw_filled_rectangle(button.rect.x, button.rect.y, button.rect.width, button.rect.height)
        
        # Draw button border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(button.rect.x, button.rect.y, button.rect.width, button.rect.height)
        
        # Draw button text
        let text_color = self.button_text_color if button.enabled else ColorInt(128, 128, 128, 255)
        _ = ctx.set_color(text_color.r, text_color.g, text_color.b, text_color.a)
        
        let text_x = button.rect.x + (button.rect.width - len(button.text) * 6) // 2
        let text_y = button.rect.y + (button.rect.height - self.font_size) // 2
        _ = ctx.draw_text(button.text, text_x, text_y, self.font_size)
    
    fn wrap_text(self, text: String, max_width: Int32) -> List[String]:
        """Simple text wrapping."""
        var lines = List[String]()
        
        # Simple implementation - just split on spaces and create lines
        # In a real implementation, this would be more sophisticated
        let char_width = 6  # Rough character width
        let chars_per_line = max_width // char_width
        
        if len(text) <= chars_per_line:
            lines.append(text)
        else:
            # Simple word wrapping
            var current_line = ""
            let words = text.split(" ")
            
            for i in range(len(words)):
                if len(current_line) + len(words[i]) + 1 <= chars_per_line:
                    if len(current_line) > 0:
                        current_line += " "
                    current_line += words[i]
                else:
                    if len(current_line) > 0:
                        lines.append(current_line)
                    current_line = words[i]
            
            if len(current_line) > 0:
                lines.append(current_line)
        
        return lines
    
    fn update(inout self):
        """Update dialog state."""
        # Nothing special to update for basic dialog
        pass

# Convenience functions
fn create_info_dialog_int(x: Int32, y: Int32, width: Int32, height: Int32,
                         title: String, message: String) -> DialogInt:
    """Create an info dialog with OK button."""
    var dialog = DialogInt(x, y, width, height, title, message, DIALOG_INFO)
    dialog.add_ok_button()
    return dialog

fn create_warning_dialog_int(x: Int32, y: Int32, width: Int32, height: Int32,
                            title: String, message: String) -> DialogInt:
    """Create a warning dialog with OK button."""
    var dialog = DialogInt(x, y, width, height, title, message, DIALOG_WARNING)
    dialog.add_ok_button()
    return dialog

fn create_error_dialog_int(x: Int32, y: Int32, width: Int32, height: Int32,
                          title: String, message: String) -> DialogInt:
    """Create an error dialog with OK button."""
    var dialog = DialogInt(x, y, width, height, title, message, DIALOG_ERROR)
    dialog.add_ok_button()
    return dialog

fn create_question_dialog_int(x: Int32, y: Int32, width: Int32, height: Int32,
                             title: String, message: String) -> DialogInt:
    """Create a question dialog with Yes/No buttons."""
    var dialog = DialogInt(x, y, width, height, title, message, DIALOG_QUESTION)
    dialog.add_yes_no_buttons()
    return dialog