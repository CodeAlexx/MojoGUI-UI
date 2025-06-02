"""
Integer-Only ScrollBar Widget Implementation
Scrollbar widget for scrolling content using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

# ScrollBar parts
alias SCROLLBAR_TRACK = 0
alias SCROLLBAR_THUMB = 1
alias SCROLLBAR_BUTTON_UP = 2
alias SCROLLBAR_BUTTON_DOWN = 3

struct ScrollBarInt(BaseWidgetInt):
    """Scrollbar widget using integer coordinates."""
    
    var is_horizontal: Bool
    var min_value: Int32
    var max_value: Int32
    var value: Int32
    var page_size: Int32
    var thumb_size: Int32
    var min_thumb_size: Int32
    
    # Visual state
    var hover_part: Int32
    var pressed_part: Int32
    var drag_offset: Int32
    var is_dragging: Bool
    
    # Auto-hide
    var auto_hide: Bool
    var hide_timer: Int32
    var is_visible: Bool
    
    # Colors
    var track_color: ColorInt
    var thumb_color: ColorInt
    var thumb_hover_color: ColorInt
    var thumb_pressed_color: ColorInt
    var button_color: ColorInt
    var button_hover_color: ColorInt
    var button_pressed_color: ColorInt
    var arrow_color: ColorInt
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, 
                is_horizontal: Bool = False):
        """Initialize scrollbar."""
        self.super().__init__(x, y, width, height)
        self.is_horizontal = is_horizontal
        self.min_value = 0
        self.max_value = 100
        self.value = 0
        self.page_size = 10
        self.thumb_size = 30
        self.min_thumb_size = 20
        
        self.hover_part = -1
        self.pressed_part = -1
        self.drag_offset = 0
        self.is_dragging = False
        
        self.auto_hide = False
        self.hide_timer = 0
        self.is_visible = True
        
        # Set colors
        self.track_color = ColorInt(60, 60, 60, 255)
        self.thumb_color = ColorInt(100, 100, 100, 255)
        self.thumb_hover_color = ColorInt(120, 120, 120, 255)
        self.thumb_pressed_color = ColorInt(140, 140, 140, 255)
        self.button_color = ColorInt(80, 80, 80, 255)
        self.button_hover_color = ColorInt(100, 100, 100, 255)
        self.button_pressed_color = ColorInt(120, 120, 120, 255)
        self.arrow_color = ColorInt(200, 200, 200, 255)
        
        # Override base appearance
        self.background_color = self.track_color
        self.border_width = 0
    
    fn set_range(inout self, min_val: Int32, max_val: Int32):
        """Set the value range."""
        self.min_value = min_val
        self.max_value = max_val
        self.value = max(min_val, min(self.value, max_val))
        self.update_thumb_size()
    
    fn set_value(inout self, val: Int32):
        """Set current value."""
        self.value = max(self.min_value, min(val, self.max_value))
    
    fn get_value(self) -> Int32:
        """Get current value."""
        return self.value
    
    fn set_page_size(inout self, size: Int32):
        """Set page size for page up/down."""
        self.page_size = max(1, size)
        self.update_thumb_size()
    
    fn scroll_by(inout self, delta: Int32):
        """Scroll by delta amount."""
        self.set_value(self.value + delta)
    
    fn scroll_to_percent(inout self, percent: Float32):
        """Scroll to percentage position (0.0 to 1.0)."""
        let range = self.max_value - self.min_value
        self.set_value(self.min_value + Int32(range * percent))
    
    fn get_scroll_percent(self) -> Float32:
        """Get current scroll position as percentage."""
        let range = self.max_value - self.min_value
        if range <= 0:
            return 0.0
        return Float32(self.value - self.min_value) / Float32(range)
    
    fn update_thumb_size(inout self):
        """Calculate thumb size based on page size and range."""
        let track_size = self.get_track_size()
        let range = self.max_value - self.min_value + self.page_size
        
        if range > 0:
            self.thumb_size = max(self.min_thumb_size, 
                                 track_size * self.page_size // range)
        else:
            self.thumb_size = track_size
    
    fn get_track_size(self) -> Int32:
        """Get the size of the scrollbar track."""
        let button_size = self.get_button_size()
        if self.is_horizontal:
            return self.width - 2 * button_size
        else:
            return self.height - 2 * button_size
    
    fn get_button_size(self) -> Int32:
        """Get the size of scroll buttons."""
        if self.is_horizontal:
            return min(self.height, 16)
        else:
            return min(self.width, 16)
    
    fn get_thumb_rect(self) -> RectInt:
        """Get the thumb rectangle."""
        let button_size = self.get_button_size()
        let track_size = self.get_track_size()
        let range = self.max_value - self.min_value
        
        if range <= 0:
            return RectInt(0, 0, 0, 0)
        
        let thumb_pos = (track_size - self.thumb_size) * 
                       (self.value - self.min_value) // range
        
        if self.is_horizontal:
            return RectInt(self.bounds.x + button_size + thumb_pos, self.bounds.y,
                          self.thumb_size, self.bounds.height)
        else:
            return RectInt(self.bounds.x, self.bounds.y + button_size + thumb_pos,
                          self.bounds.width, self.thumb_size)
    
    fn get_button_up_rect(self) -> RectInt:
        """Get the up/left button rectangle."""
        let button_size = self.get_button_size()
        if self.is_horizontal:
            return RectInt(self.bounds.x, self.bounds.y, button_size, self.bounds.height)
        else:
            return RectInt(self.bounds.x, self.bounds.y, self.bounds.width, button_size)
    
    fn get_button_down_rect(self) -> RectInt:
        """Get the down/right button rectangle."""
        let button_size = self.get_button_size()
        if self.is_horizontal:
            return RectInt(self.bounds.x + self.bounds.width - button_size, self.bounds.y,
                          button_size, self.bounds.height)
        else:
            return RectInt(self.bounds.x, self.bounds.y + self.bounds.height - button_size,
                          self.bounds.width, button_size)
    
    fn hit_test(self, point: PointInt) -> Int32:
        """Determine which part of scrollbar was hit."""
        if not self.contains_point(point):
            return -1
        
        if self.get_button_up_rect().contains(point):
            return SCROLLBAR_BUTTON_UP
        elif self.get_button_down_rect().contains(point):
            return SCROLLBAR_BUTTON_DOWN
        elif self.get_thumb_rect().contains(point):
            return SCROLLBAR_THUMB
        else:
            return SCROLLBAR_TRACK
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        if self.auto_hide and not self.is_visible:
            return False
        
        let point = PointInt(event.x, event.y)
        let hit_part = self.hit_test(point)
        
        if event.pressed:
            if hit_part >= 0:
                self.pressed_part = hit_part
                
                if hit_part == SCROLLBAR_THUMB:
                    # Start dragging
                    self.is_dragging = True
                    let thumb_rect = self.get_thumb_rect()
                    if self.is_horizontal:
                        self.drag_offset = event.x - thumb_rect.x
                    else:
                        self.drag_offset = event.y - thumb_rect.y
                elif hit_part == SCROLLBAR_BUTTON_UP:
                    self.scroll_by(-1)
                elif hit_part == SCROLLBAR_BUTTON_DOWN:
                    self.scroll_by(1)
                elif hit_part == SCROLLBAR_TRACK:
                    # Page up/down
                    let thumb_rect = self.get_thumb_rect()
                    if self.is_horizontal:
                        if event.x < thumb_rect.x:
                            self.scroll_by(-self.page_size)
                        else:
                            self.scroll_by(self.page_size)
                    else:
                        if event.y < thumb_rect.y:
                            self.scroll_by(-self.page_size)
                        else:
                            self.scroll_by(self.page_size)
                
                return True
        else:
            self.pressed_part = -1
            self.is_dragging = False
        
        # Handle dragging
        if self.is_dragging:
            let button_size = self.get_button_size()
            let track_size = self.get_track_size()
            let range = self.max_value - self.min_value
            
            if range > 0:
                var new_pos: Int32
                if self.is_horizontal:
                    new_pos = event.x - self.bounds.x - button_size - self.drag_offset
                else:
                    new_pos = event.y - self.bounds.y - button_size - self.drag_offset
                
                new_pos = max(0, min(new_pos, track_size - self.thumb_size))
                let new_value = self.min_value + (new_pos * range) // (track_size - self.thumb_size)
                self.set_value(new_value)
            
            return True
        
        # Update hover state
        self.hover_part = hit_part
        
        # Reset auto-hide timer
        if self.auto_hide:
            self.hide_timer = 0
            self.is_visible = True
        
        return hit_part >= 0
    
    fn handle_mouse_wheel(inout self, delta: Int32) -> Bool:
        """Handle mouse wheel scrolling."""
        if not self.visible or not self.enabled:
            return False
        
        self.scroll_by(-delta * 3)  # Scroll 3 units per wheel notch
        
        if self.auto_hide:
            self.hide_timer = 0
            self.is_visible = True
        
        return True
    
    fn render(self, ctx: RenderingContextInt):
        """Render the scrollbar."""
        if not self.visible:
            return
        
        if self.auto_hide and not self.is_visible:
            return
        
        # Track background
        _ = ctx.set_color(self.track_color.r, self.track_color.g,
                         self.track_color.b, self.track_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                     self.bounds.width, self.bounds.height)
        
        # Buttons
        self.render_button(ctx, SCROLLBAR_BUTTON_UP)
        self.render_button(ctx, SCROLLBAR_BUTTON_DOWN)
        
        # Thumb
        if self.max_value > self.min_value:
            self.render_thumb(ctx)
    
    fn render_button(self, ctx: RenderingContextInt, button_type: Int32):
        """Render a scroll button."""
        let rect = self.get_button_up_rect() if button_type == SCROLLBAR_BUTTON_UP 
                  else self.get_button_down_rect()
        
        # Button background
        var color = self.button_color
        if self.pressed_part == button_type:
            color = self.button_pressed_color
        elif self.hover_part == button_type:
            color = self.button_hover_color
        
        _ = ctx.set_color(color.r, color.g, color.b, color.a)
        _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        # Arrow
        _ = ctx.set_color(self.arrow_color.r, self.arrow_color.g,
                         self.arrow_color.b, self.arrow_color.a)
        
        let cx = rect.x + rect.width // 2
        let cy = rect.y + rect.height // 2
        let arrow_size = 4
        
        if self.is_horizontal:
            if button_type == SCROLLBAR_BUTTON_UP:
                # Left arrow
                _ = ctx.draw_line(cx + arrow_size, cy - arrow_size,
                                 cx - arrow_size, cy, 2)
                _ = ctx.draw_line(cx - arrow_size, cy,
                                 cx + arrow_size, cy + arrow_size, 2)
            else:
                # Right arrow
                _ = ctx.draw_line(cx - arrow_size, cy - arrow_size,
                                 cx + arrow_size, cy, 2)
                _ = ctx.draw_line(cx + arrow_size, cy,
                                 cx - arrow_size, cy + arrow_size, 2)
        else:
            if button_type == SCROLLBAR_BUTTON_UP:
                # Up arrow
                _ = ctx.draw_line(cx - arrow_size, cy + arrow_size,
                                 cx, cy - arrow_size, 2)
                _ = ctx.draw_line(cx, cy - arrow_size,
                                 cx + arrow_size, cy + arrow_size, 2)
            else:
                # Down arrow
                _ = ctx.draw_line(cx - arrow_size, cy - arrow_size,
                                 cx, cy + arrow_size, 2)
                _ = ctx.draw_line(cx, cy + arrow_size,
                                 cx + arrow_size, cy - arrow_size, 2)
    
    fn render_thumb(self, ctx: RenderingContextInt):
        """Render the scrollbar thumb."""
        let rect = self.get_thumb_rect()
        
        var color = self.thumb_color
        if self.pressed_part == SCROLLBAR_THUMB:
            color = self.thumb_pressed_color
        elif self.hover_part == SCROLLBAR_THUMB:
            color = self.thumb_hover_color
        
        _ = ctx.set_color(color.r, color.g, color.b, color.a)
        _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        # Grip lines
        _ = ctx.set_color(self.track_color.r, self.track_color.g,
                         self.track_color.b, self.track_color.a)
        
        let cx = rect.x + rect.width // 2
        let cy = rect.y + rect.height // 2
        
        if self.is_horizontal:
            for i in range(-4, 5, 4):
                _ = ctx.draw_line(cx + i, cy - 6, cx + i, cy + 6, 1)
        else:
            for i in range(-4, 5, 4):
                _ = ctx.draw_line(cx - 6, cy + i, cx + 6, cy + i, 1)
    
    fn update(inout self):
        """Update scrollbar state."""
        if self.auto_hide and self.is_visible:
            self.hide_timer += 1
            if self.hide_timer > 180:  # Hide after 3 seconds
                self.is_visible = False

# Convenience functions
fn create_vertical_scrollbar(x: Int32, y: Int32, width: Int32, height: Int32) -> ScrollBarInt:
    """Create a vertical scrollbar."""
    return ScrollBarInt(x, y, width, height, False)

fn create_horizontal_scrollbar(x: Int32, y: Int32, width: Int32, height: Int32) -> ScrollBarInt:
    """Create a horizontal scrollbar."""
    return ScrollBarInt(x, y, width, height, True)