"""
Integer-Only TextLabel Widget Implementation
Text display widget using only integer coordinates and colors.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from ..theme_system import get_theme

# Text alignment options
comptime ALIGN_LEFT = 0
comptime ALIGN_CENTER = 1
comptime ALIGN_RIGHT = 2

struct TextLabelInt(WidgetInt, Copyable, Movable):
    """Text label widget using integer coordinates."""

    # Inlined BaseWidgetInt fields (struct inheritance is not supported).
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var background_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32

    var text: String
    var text_color: ColorInt
    var font_size: Int32
    var alignment: Int32
    var padding: Int32

    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32, text: String):
        """Initialize text label."""
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
        self.font_size = 14
        self.alignment = ALIGN_LEFT
        self.padding = 4

        # Set transparent background by default
        self.background_color = theme.transparent
        self.border_width = 0

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
        """Set the label text."""
        self.text = text

    fn get_text(self) -> String:
        """Get the label text."""
        return self.text

    fn set_text_color(mut self, color: ColorInt):
        """Set the text color."""
        self.text_color = color

    fn set_font_size(mut self, size: Int32):
        """Set the font size."""
        self.font_size = size

    fn set_alignment(mut self, alignment: Int32):
        """Set text alignment (ALIGN_LEFT, ALIGN_CENTER, ALIGN_RIGHT)."""
        self.alignment = alignment

    fn calculate_text_position(self, ctx: RenderingContextInt) -> PointInt:
        """Calculate the position where text should be drawn based on alignment."""
        var text_width = ctx.get_text_width(self.text, self.font_size)
        var text_height = ctx.get_text_height(self.text, self.font_size)

        var text_x: Int32 = self.bounds.x + self.padding
        var text_y: Int32 = self.bounds.y + (self.bounds.height - text_height) // 2

        if self.alignment == ALIGN_CENTER:
            text_x = self.bounds.x + (self.bounds.width - text_width) // 2
        elif self.alignment == ALIGN_RIGHT:
            text_x = self.bounds.x + self.bounds.width - text_width - self.padding

        return PointInt(text_x, text_y)

    fn handle_mouse_event(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse events (labels don't typically handle mouse events)."""
        if not self.visible or not self.enabled:
            return False

        var point = PointInt(event.x, event.y)
        return self.contains_point(point)  # Just return if point is inside

    fn handle_key_event(mut self, event: KeyEventInt) -> Bool:
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

            var text_pos = self.calculate_text_position(ctx)
            _ = ctx.draw_text(self.text, text_pos.x, text_pos.y, self.font_size)

    fn update(mut self):
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
    var theme = get_theme()
    label.set_text_color(theme.title_text)
    return label^

fn create_subtitle_label_int(x: Int32, y: Int32, width: Int32, height: Int32, text: String) -> TextLabelInt:
    """Create a subtitle label with medium font."""
    var label = TextLabelInt(x, y, width, height, text)
    label.set_font_size(16)
    var theme = get_theme()
    label.set_text_color(theme.subtitle_text)
    return label^
