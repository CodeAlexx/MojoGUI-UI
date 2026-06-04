"""
Integer-Only ProgressBar Widget Implementation
Progress indicator widget using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from ..theme_system import get_theme

# Progress bar styles
comptime PROGRESS_HORIZONTAL = 0
comptime PROGRESS_VERTICAL = 1
comptime PROGRESS_STYLE_SOLID = 0
comptime PROGRESS_STYLE_STRIPED = 1

struct ProgressBarInt(WidgetInt, Copyable, Movable):
    """Progress bar widget using integer coordinates."""

    # Inlined BaseWidgetInt fields (struct inheritance is not supported).
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var background_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32

    var min_value: Int32
    var max_value: Int32
    var current_value: Int32
    var progress_color: ColorInt
    var track_color: ColorInt
    var text_color: ColorInt
    var orientation: Int32
    var style: Int32
    var show_text: Bool
    var show_percentage: Bool
    var font_size: Int32
    var animation_offset: Int32  # For animated stripes
    
    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32,
               min_val: Int32 = 0, max_val: Int32 = 100):
        """Initialize progress bar."""
        # Inlined BaseWidgetInt.__init__
        self.bounds = RectInt(x, y, width, height)
        self.visible = True
        self.enabled = True
        self.background_color = ColorInt(230, 230, 230, 255)
        self.border_color = ColorInt(128, 128, 128, 255)
        self.border_width = 1
        self.min_value = min_val
        self.max_value = max_val
        self.current_value = min_val
        
        # Set colors using theme system
        var theme = get_theme()
        self.progress_color = theme.progress_fill
        self.track_color = theme.progress_track
        self.text_color = theme.primary_text
        
        # Determine orientation based on dimensions
        self.orientation = PROGRESS_HORIZONTAL if width > height else PROGRESS_VERTICAL
        self.style = PROGRESS_STYLE_SOLID
        self.show_text = True
        self.show_percentage = True
        self.font_size = 12
        self.animation_offset = 0
        
        # Set appearance using theme
        self.background_color = theme.widget_background
        self.border_color = theme.primary_border
        self.border_width = 1

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

    fn get_value(self) -> Int32:
        """Get current progress value."""
        return self.current_value
    
    fn set_value(mut self, value: Int32):
        """Set progress value (clamped to range)."""
        if value < self.min_value:
            self.current_value = self.min_value
        elif value > self.max_value:
            self.current_value = self.max_value
        else:
            self.current_value = value
    
    fn get_percentage(self) -> Int32:
        """Get progress as percentage (0-100)."""
        var range = self.max_value - self.min_value
        if range == 0:
            return 100
        return (self.current_value - self.min_value) * 100 // range
    
    fn get_normalized_value(self) -> Float32:
        """Get progress as 0.0-1.0 ratio."""
        var range = self.max_value - self.min_value
        if range == 0:
            return 1.0
        return Float32(self.current_value - self.min_value) / Float32(range)
    
    fn set_color_scheme(mut self, scheme: Int32):
        """Set predefined color scheme."""
        var theme = get_theme()
        if scheme == 0:  # Default (success)
            self.progress_color = theme.progress_fill
        elif scheme == 1:  # Info (blue)
            self.progress_color = theme.info_color
        elif scheme == 2:  # Warning (orange)
            self.progress_color = theme.warning_color
        elif scheme == 3:  # Danger (red)
            self.progress_color = theme.error_color
        elif scheme == 4:  # Success (bright green)
            self.progress_color = theme.success_color
    
    fn set_style(mut self, style: Int32):
        """Set progress bar style."""
        self.style = style
    
    fn set_show_text(mut self, show: Bool):
        """Set whether to show text."""
        self.show_text = show
    
    fn set_show_percentage(mut self, show: Bool):
        """Set whether to show percentage."""
        self.show_percentage = show
    
    fn get_track_rect(self) -> RectInt:
        """Get the track rectangle."""
        return RectInt(self.bounds.x + 2, self.bounds.y + 2,
                      self.bounds.width - 4, self.bounds.height - 4)
    
    fn get_progress_rect(self) -> RectInt:
        """Get the filled progress rectangle."""
        var track = self.get_track_rect()
        var ratio = self.get_normalized_value()
        
        if self.orientation == PROGRESS_HORIZONTAL:
            var progress_width = Int32(Float32(track.width) * ratio)
            return RectInt(track.x, track.y, progress_width, track.height)
        else:  # Vertical
            var progress_height = Int32(Float32(track.height) * ratio)
            return RectInt(track.x, track.y + track.height - progress_height, 
                          track.width, progress_height)
    
    fn handle_mouse_event(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse events (progress bars are typically non-interactive)."""
        if not self.visible or not self.enabled:
            return False
        
        var point = PointInt(event.x, event.y)
        return self.contains_point(point)
    
    fn handle_key_event(mut self, event: KeyEventInt) -> Bool:
        """Handle key events (not typically used)."""
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render the progress bar."""
        if not self.visible:
            return
        
        # Draw background
        if self.background_color.a > 0:
            self.render_background(ctx)
        
        var track = self.get_track_rect()
        var progress = self.get_progress_rect()
        
        # Draw track background
        _ = ctx.set_color(self.track_color.r, self.track_color.g, 
                         self.track_color.b, self.track_color.a)
        _ = ctx.draw_filled_rectangle(track.x, track.y, track.width, track.height)
        
        # Draw progress fill
        if progress.width > 0 and progress.height > 0:
            if self.style == PROGRESS_STYLE_SOLID:
                # Solid fill
                _ = ctx.set_color(self.progress_color.r, self.progress_color.g, 
                                 self.progress_color.b, self.progress_color.a)
                _ = ctx.draw_filled_rectangle(progress.x, progress.y, progress.width, progress.height)
            else:  # Striped
                # Draw striped pattern
                self.render_striped_progress(ctx, progress)
        
        # Draw border
        if self.border_width > 0:
            _ = ctx.set_color(self.border_color.r, self.border_color.g, 
                             self.border_color.b, self.border_color.a)
            _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
        
        # Draw text
        if self.show_text:
            self.render_text(ctx)
    
    fn render_striped_progress(self, ctx: RenderingContextInt, progress_rect: RectInt):
        """Render striped progress pattern."""
        var stripe_width = 8
        var stripe_offset = self.animation_offset % (stripe_width * 2)
        
        # Draw base color
        _ = ctx.set_color(self.progress_color.r, self.progress_color.g, 
                         self.progress_color.b, self.progress_color.a)
        _ = ctx.draw_filled_rectangle(progress_rect.x, progress_rect.y, 
                                     progress_rect.width, progress_rect.height)
        
        # Draw lighter stripes
        var lighter_r = min(Int32(255), self.progress_color.r + 30)
        var lighter_g = min(Int32(255), self.progress_color.g + 30)
        var lighter_b = min(Int32(255), self.progress_color.b + 30)
        
        _ = ctx.set_color(lighter_r, lighter_g, lighter_b, self.progress_color.a)
        
        if self.orientation == PROGRESS_HORIZONTAL:
            var x = progress_rect.x - stripe_offset
            while x < progress_rect.x + progress_rect.width:
                _ = ctx.draw_filled_rectangle(x, progress_rect.y, stripe_width, progress_rect.height)
                x += stripe_width * 2
        else:  # Vertical
            var y = progress_rect.y - stripe_offset
            while y < progress_rect.y + progress_rect.height:
                _ = ctx.draw_filled_rectangle(progress_rect.x, y, progress_rect.width, stripe_width)
                y += stripe_width * 2
    
    fn render_text(self, ctx: RenderingContextInt):
        """Render progress text."""
        var text: String
        if self.show_percentage:
            text = String(self.get_percentage()) + "%"
        else:
            text = String(self.current_value) + "/" + String(self.max_value)
        
        if len(text) > 0:
            _ = ctx.set_color(self.text_color.r, self.text_color.g, 
                             self.text_color.b, self.text_color.a)
            
            # Center text in progress bar
            var text_width = ctx.get_text_width(text, self.font_size)
            var text_height = ctx.get_text_height(text, self.font_size)
            var text_x = self.bounds.x + (self.bounds.width - text_width) // 2
            var text_y = self.bounds.y + (self.bounds.height - text_height) // 2
            
            _ = ctx.draw_text(text, text_x, text_y, self.font_size)
    
    fn update(mut self):
        """Update progress bar state."""
        # Animate stripes
        if self.style == PROGRESS_STYLE_STRIPED:
            self.animation_offset += 1
            if self.animation_offset > 1000:  # Prevent overflow
                self.animation_offset = 0
    
    fn increment(mut self, amount: Int32 = 1):
        """Increment progress by amount."""
        self.set_value(self.current_value + amount)
    
    fn is_complete(self) -> Bool:
        """Check if progress is complete."""
        return self.current_value >= self.max_value

# Convenience constructor functions
fn create_progressbar_int(x: Int32, y: Int32, width: Int32, height: Int32, 
                         max_val: Int32 = 100) -> ProgressBarInt:
    """Create a standard progress bar."""
    return ProgressBarInt(x, y, width, height, 0, max_val)

fn create_horizontal_progressbar_int(x: Int32, y: Int32, width: Int32, 
                                    max_val: Int32 = 100) -> ProgressBarInt:
    """Create a horizontal progress bar with standard height."""
    return ProgressBarInt(x, y, width, 25, 0, max_val)

fn create_vertical_progressbar_int(x: Int32, y: Int32, height: Int32,
                                  max_val: Int32 = 100) -> ProgressBarInt:
    """Create a vertical progress bar with standard width."""
    return ProgressBarInt(x, y, 25, height, 0, max_val)

fn create_loading_bar_int(x: Int32, y: Int32, width: Int32) -> ProgressBarInt:
    """Create an animated loading bar."""
    var bar = ProgressBarInt(x, y, width, 20, 0, 100)
    bar.set_style(PROGRESS_STYLE_STRIPED)
    bar.set_show_percentage(False)
    return bar^