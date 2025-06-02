"""
Integer-Only TextLabel Widget Implementation
Text display widget using only integer coordinates and colors.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

# Text alignment options
alias ALIGN_LEFT = 0
alias ALIGN_CENTER = 1
alias ALIGN_RIGHT = 2

struct TextLabelInt(BaseWidgetInt):
    """Text label widget using integer coordinates."""
    
    var text: String
    var text_color: ColorInt
    var font_size: Int32
    var alignment: Int32
    var padding: Int32
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, text: String):
        """Initialize text label."""
        self.super().__init__(x, y, width, height)
        self.text = text
        self.text_color = ColorInt(0, 0, 0, 255)  # Black text
        self.font_size = 14
        self.alignment = ALIGN_LEFT
        self.padding = 4
        
        # Set transparent background by default
        self.background_color = ColorInt(0, 0, 0, 0)
        self.border_width = 0
    
    fn set_text(inout self, text: String):
        """Set the label text."""
        self.text = text
    
    fn get_text(self) -> String:
        """Get the label text."""
        return self.text
    
    fn set_text_color(inout self, color: ColorInt):
        """Set the text color."""
        self.text_color = color
    
    fn set_font_size(inout self, size: Int32):
        """Set the font size."""
        self.font_size = size
    
    fn set_alignment(inout self, alignment: Int32):
        """Set text alignment (ALIGN_LEFT, ALIGN_CENTER, ALIGN_RIGHT)."""
        self.alignment = alignment
    
    fn calculate_text_position(self, ctx: RenderingContextInt) -> PointInt:
        """Calculate the position where text should be drawn based on alignment."""
        let text_width = ctx.get_text_width(self.text, self.font_size)
        let text_height = ctx.get_text_height(self.text, self.font_size)
        
        var text_x: Int32 = self.bounds.x + self.padding
        let text_y: Int32 = self.bounds.y + (self.bounds.height - text_height) // 2
        
        if self.alignment == ALIGN_CENTER:
            text_x = self.bounds.x + (self.bounds.width - text_width) // 2
        elif self.alignment == ALIGN_RIGHT:
            text_x = self.bounds.x + self.bounds.width - text_width - self.padding
        
        return PointInt(text_x, text_y)
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events (labels don't typically handle mouse events)."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        return self.contains_point(point)  # Just return if point is inside
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle key events (labels don't handle key events)."""
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render the text label."""
        if not self.visible:
            return
        
        # Render background if it has alpha > 0
        if self.background_color.a > 0:
            self.render_background(ctx)
        
        # Render text
        if len(self.text) > 0:
            _ = ctx.set_color(self.text_color.r, self.text_color.g, 
                             self.text_color.b, self.text_color.a)
            
            let text_pos = self.calculate_text_position(ctx)
            _ = ctx.draw_text(self.text, text_pos.x, text_pos.y, self.font_size)
    
    fn update(inout self):
        """Update label (nothing to update for basic label)."""
        pass

# Convenience constructor functions
fn create_label_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> TextLabelInt:
    """Create a new text label."""
    return TextLabelInt(x, y, width, height, text)

fn create_title_label_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> TextLabelInt:
    """Create a title label with larger font and center alignment."""
    var label = TextLabelInt(x, y, width, height, text)
    label.set_font_size(18)
    label.set_alignment(ALIGN_CENTER)
    label.set_text_color(ColorInt(50, 50, 50, 255))  # Dark gray
    return label

fn create_subtitle_label_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> TextLabelInt:
    """Create a subtitle label with medium font."""
    var label = TextLabelInt(x, y, width, height, text)
    label.set_font_size(16)
    label.set_text_color(ColorInt(100, 100, 100, 255))  # Medium gray
    return label