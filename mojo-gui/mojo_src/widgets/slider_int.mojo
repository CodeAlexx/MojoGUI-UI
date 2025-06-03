"""
Integer-Only Slider Widget Implementation
Interactive slider for numeric value selection using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from ..theme_state_integration import get_theme

struct SliderInt(BaseWidgetInt):
    """Interactive slider widget using integer coordinates."""
    
    var min_value: Int32
    var max_value: Int32
    var current_value: Int32
    var track_color: ColorInt
    var thumb_color: ColorInt
    var thumb_hover_color: ColorInt
    var thumb_size: Int32
    var track_height: Int32
    var is_dragging: Bool
    var drag_offset: Int32
    var orientation: Int32  # 0 = horizontal, 1 = vertical
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, 
               min_val: Int32, max_val: Int32, initial_val: Int32):
        """Initialize slider."""
        self.super().__init__(x, y, width, height)
        self.min_value = min_val
        self.max_value = max_val
        self.current_value = initial_val
        
        # Clamp initial value
        if self.current_value < self.min_value:
            self.current_value = self.min_value
        elif self.current_value > self.max_value:
            self.current_value = self.max_value
        
        let theme = get_theme()
        self.track_color = theme.widget_background
        self.thumb_color = theme.accent_primary
        self.thumb_hover_color = theme.accent_hover
        self.thumb_size = 20
        self.track_height = 6
        self.is_dragging = False
        self.drag_offset = 0
        
        # Determine orientation based on dimensions
        self.orientation = 0 if width > height else 1  # 0 = horizontal, 1 = vertical
        
        # Set default appearance
        self.background_color = theme.widget_background
        self.border_color = theme.secondary_border
        self.border_width = 1
    
    fn get_value(self) -> Int32:
        """Get current slider value."""
        return self.current_value
    
    fn set_value(inout self, value: Int32):
        """Set slider value (clamped to range)."""
        if value < self.min_value:
            self.current_value = self.min_value
        elif value > self.max_value:
            self.current_value = self.max_value
        else:
            self.current_value = value
    
    fn get_range(self) -> Int32:
        """Get the value range."""
        return self.max_value - self.min_value
    
    fn get_normalized_value(self) -> Float32:
        """Get value as 0.0-1.0 ratio."""
        let range = self.get_range()
        if range == 0:
            return 0.0
        return Float32(self.current_value - self.min_value) / Float32(range)
    
    fn get_track_rect(self) -> RectInt:
        """Get the track rectangle."""
        if self.orientation == 0:  # Horizontal
            let track_y = self.bounds.y + (self.bounds.height - self.track_height) // 2
            return RectInt(self.bounds.x + self.thumb_size // 2, track_y, 
                          self.bounds.width - self.thumb_size, self.track_height)
        else:  # Vertical
            let track_x = self.bounds.x + (self.bounds.width - self.track_height) // 2
            return RectInt(track_x, self.bounds.y + self.thumb_size // 2,
                          self.track_height, self.bounds.height - self.thumb_size)
    
    fn get_thumb_rect(self) -> RectInt:
        """Get the thumb rectangle."""
        let track = self.get_track_rect()
        let normalized = self.get_normalized_value()
        
        if self.orientation == 0:  # Horizontal
            let thumb_x = track.x + Int32(Float32(track.width) * normalized) - self.thumb_size // 2
            let thumb_y = self.bounds.y + (self.bounds.height - self.thumb_size) // 2
            return RectInt(thumb_x, thumb_y, self.thumb_size, self.thumb_size)
        else:  # Vertical  
            let thumb_x = self.bounds.x + (self.bounds.width - self.thumb_size) // 2
            # For vertical, 0 should be at bottom, so invert the calculation
            let thumb_y = track.y + track.height - Int32(Float32(track.height) * normalized) - self.thumb_size // 2
            return RectInt(thumb_x, thumb_y, self.thumb_size, self.thumb_size)
    
    fn is_point_in_thumb(self, point: PointInt) -> Bool:
        """Check if point is inside thumb."""
        let thumb = self.get_thumb_rect()
        return thumb.contains(point)
    
    fn value_from_position(self, pos: PointInt) -> Int32:
        """Calculate value from mouse position."""
        let track = self.get_track_rect()
        var ratio: Float32 = 0.0
        
        if self.orientation == 0:  # Horizontal
            if track.width > 0:
                ratio = Float32(pos.x - track.x) / Float32(track.width)
        else:  # Vertical
            if track.height > 0:
                # For vertical, invert so bottom = 0, top = max
                ratio = Float32(track.y + track.height - pos.y) / Float32(track.height)
        
        # Clamp ratio
        if ratio < 0.0:
            ratio = 0.0
        elif ratio > 1.0:
            ratio = 1.0
        
        # Convert to value
        let range = self.get_range()
        return self.min_value + Int32(Float32(range) * ratio)
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        let inside = self.contains_point(point)
        
        if event.pressed and inside:
            if self.is_point_in_thumb(point):
                # Start dragging thumb
                self.is_dragging = True
                let thumb = self.get_thumb_rect()
                if self.orientation == 0:
                    self.drag_offset = point.x - (thumb.x + thumb.width // 2)
                else:
                    self.drag_offset = point.y - (thumb.y + thumb.height // 2)
            else:
                # Click on track - jump to position
                self.set_value(self.value_from_position(point))
            return True
        elif not event.pressed:
            self.is_dragging = False
            return inside
        elif self.is_dragging:
            # Update value while dragging
            var adjusted_point = point
            if self.orientation == 0:
                adjusted_point.x -= self.drag_offset
            else:
                adjusted_point.y -= self.drag_offset
            self.set_value(self.value_from_position(adjusted_point))
            return True
        
        return inside
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle key events (arrow keys to adjust value)."""
        if not self.visible or not self.enabled:
            return False
        
        if event.pressed:
            let step = 1
            
            if self.orientation == 0:  # Horizontal
                if event.key_code == 262:  # Right arrow
                    self.set_value(self.current_value + step)
                    return True
                elif event.key_code == 263:  # Left arrow
                    self.set_value(self.current_value - step)
                    return True
            else:  # Vertical
                if event.key_code == 265:  # Up arrow
                    self.set_value(self.current_value + step)
                    return True
                elif event.key_code == 264:  # Down arrow
                    self.set_value(self.current_value - step)
                    return True
        
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render the slider."""
        if not self.visible:
            return
        
        # Draw background
        if self.background_color.a > 0:
            self.render_background(ctx)
        
        # Draw track
        let track = self.get_track_rect()
        _ = ctx.set_color(self.track_color.r, self.track_color.g, 
                         self.track_color.b, self.track_color.a)
        _ = ctx.draw_filled_rectangle(track.x, track.y, track.width, track.height)
        
        # Draw track border
        let theme = get_theme()
        _ = ctx.set_color(theme.primary_border.r, theme.primary_border.g, theme.primary_border.b, theme.primary_border.a)
        _ = ctx.draw_rectangle(track.x, track.y, track.width, track.height)
        
        # Draw thumb
        let thumb = self.get_thumb_rect()
        let mouse_pos = PointInt(0, 0)  # Would need mouse position for hover effect
        let is_hover = False  # Simplified - would check mouse position
        
        let thumb_color = self.thumb_hover_color if is_hover else self.thumb_color
        _ = ctx.set_color(thumb_color.r, thumb_color.g, thumb_color.b, thumb_color.a)
        _ = ctx.draw_filled_circle(thumb.x + thumb.width // 2, thumb.y + thumb.height // 2, 
                                  self.thumb_size // 2, 16)
        
        # Draw thumb border
        _ = ctx.set_color(theme.primary_border.r, theme.primary_border.g, theme.primary_border.b, theme.primary_border.a)
        _ = ctx.draw_rectangle(thumb.x, thumb.y, thumb.width, thumb.height)
    
    fn update(inout self):
        """Update slider state."""
        # Nothing special to update for basic slider
        pass

# Convenience constructor functions
fn create_slider_int(x: Int32, y: Int32, width: Int32, height: Int32, 
                    min_val: Int32, max_val: Int32, initial_val: Int32) -> SliderInt:
    """Create a standard slider."""
    return SliderInt(x, y, width, height, min_val, max_val, initial_val)

fn create_horizontal_slider_int(x: Int32, y: Int32, width: Int32, 
                               min_val: Int32, max_val: Int32, initial_val: Int32) -> SliderInt:
    """Create a horizontal slider with standard height."""
    return SliderInt(x, y, width, 30, min_val, max_val, initial_val)

fn create_vertical_slider_int(x: Int32, y: Int32, height: Int32,
                             min_val: Int32, max_val: Int32, initial_val: Int32) -> SliderInt:
    """Create a vertical slider with standard width."""
    return SliderInt(x, y, 30, height, min_val, max_val, initial_val)