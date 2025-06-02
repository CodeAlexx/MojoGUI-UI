"""
TextLabel Widget Implementation
Simple text display widget with alignment and styling options.
"""

from ..rendering import RenderingContext, Color, Point, Size, Rect
from ..widget import Widget, BaseWidget, MouseEvent, KeyEvent

# Text alignment options
alias ALIGN_LEFT = 0
alias ALIGN_CENTER = 1
alias ALIGN_RIGHT = 2

struct TextLabel(BaseWidget):
    """Text label widget for displaying text."""
    
    var text: String
    var text_color: Color
    var font_size: Float32
    var alignment: Int
    var padding: Float32
    
    fn __init__(inout self, x: Float32, y: Float32, width: Float32, height: Float32, text: String):
        """Initialize text label."""
        self.super().__init__(x, y, width, height)
        self.text = text
        self.text_color = Color(0.0, 0.0, 0.0, 1.0)  # Black text
        self.font_size = 14.0
        self.alignment = ALIGN_LEFT
        self.padding = 4.0
        
        # Set transparent background by default
        self.background_color = Color(0.0, 0.0, 0.0, 0.0)
        self.border_width = 0.0
    
    fn set_text(inout self, text: String):
        """Set the label text."""
        self.text = text
    
    fn get_text(self) -> String:
        """Get the label text."""
        return self.text
    
    fn set_text_color(inout self, color: Color):
        """Set the text color."""
        self.text_color = color
    
    fn set_font_size(inout self, size: Float32):
        """Set the font size."""
        self.font_size = size
    
    fn set_alignment(inout self, alignment: Int):
        """Set text alignment (ALIGN_LEFT, ALIGN_CENTER, ALIGN_RIGHT)."""
        self.alignment = alignment
    
    fn calculate_text_position(self, ctx: RenderingContext) -> (Float32, Float32):
        """Calculate the position where text should be drawn based on alignment."""
        let (text_width, text_height) = ctx.get_text_size(self.text, self.font_size)
        
        var text_x: Float32 = self.bounds.x + self.padding
        let text_y: Float32 = self.bounds.y + (self.bounds.height - text_height) / 2.0
        
        if self.alignment == ALIGN_CENTER:
            text_x = self.bounds.x + (self.bounds.width - text_width) / 2.0
        elif self.alignment == ALIGN_RIGHT:
            text_x = self.bounds.x + self.bounds.width - text_width - self.padding
        
        return (text_x, text_y)
    
    fn handle_mouse_event(inout self, event: MouseEvent) -> Bool:
        """Handle mouse events (labels don't typically handle mouse events)."""
        if not self.visible or not self.enabled:
            return False
        
        let point = Point(event.x, event.y)
        return self.contains_point(point)  # Just return if point is inside
    
    fn handle_key_event(inout self, event: KeyEvent) -> Bool:
        """Handle key events (labels don't handle key events)."""
        return False
    
    fn render(self, ctx: RenderingContext):
        """Render the text label."""
        if not self.visible:
            return
        
        # Render background if it has alpha > 0
        if self.background_color.a > 0.0:
            self.render_background(ctx)
        
        # Render text
        if len(self.text) > 0:
            _ = ctx.set_color(self.text_color.r, self.text_color.g, 
                             self.text_color.b, self.text_color.a)
            
            let (text_x, text_y) = self.calculate_text_position(ctx)
            _ = ctx.draw_text(self.text, text_x, text_y, self.font_size)
    
    fn update(inout self):
        """Update label (nothing to update for basic label)."""
        pass

# Convenience constructor functions
fn create_label(x: Float32, y: Float32, width: Float32, height: Float32, text: String) -> TextLabel:
    """Create a new text label."""
    return TextLabel(x, y, width, height, text)

fn create_title_label(x: Float32, y: Float32, width: Float32, height: Float32, text: String) -> TextLabel:
    """Create a title label with larger font and center alignment."""
    var label = TextLabel(x, y, width, height, text)
    label.set_font_size(18.0)
    label.set_alignment(ALIGN_CENTER)
    label.set_text_color(Color(0.2, 0.2, 0.2, 1.0))  # Dark gray
    return label

fn create_subtitle_label(x: Float32, y: Float32, width: Float32, height: Float32, text: String) -> TextLabel:
    """Create a subtitle label with medium font."""
    var label = TextLabel(x, y, width, height, text)
    label.set_font_size(16.0)
    label.set_text_color(Color(0.4, 0.4, 0.4, 1.0))  # Medium gray
    return label