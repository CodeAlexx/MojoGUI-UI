"""
Integer-Only Widget System for Mojo GUI
All coordinates and dimensions use Int32 to avoid FFI issues.
"""

from .rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt

# Event types
struct MouseEventInt:
    """Mouse event data using integers."""
    var x: Int32
    var y: Int32
    var button: Int32
    var pressed: Bool
    
    fn __init__(inout self, x: Int32, y: Int32, button: Int32, pressed: Bool):
        self.x = x
        self.y = y
        self.button = button
        self.pressed = pressed

struct KeyEventInt:
    """Keyboard event data."""
    var key_code: Int32
    var pressed: Bool
    
    fn __init__(inout self, key_code: Int32, pressed: Bool):
        self.key_code = key_code
        self.pressed = pressed

# Base widget trait
trait WidgetInt:
    """Base trait for all GUI widgets using integer coordinates."""
    
    fn get_bounds(self) -> RectInt:
        """Get the widget's bounding rectangle."""
        ...
    
    fn set_bounds(inout self, bounds: RectInt):
        """Set the widget's bounding rectangle."""
        ...
    
    fn is_visible(self) -> Bool:
        """Check if widget is visible."""
        ...
    
    fn set_visible(inout self, visible: Bool):
        """Set widget visibility."""
        ...
    
    fn contains_point(self, point: PointInt) -> Bool:
        """Check if point is inside widget."""
        ...
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse event. Returns True if handled."""
        ...
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle key event. Returns True if handled."""
        ...
    
    fn render(self, ctx: RenderingContextInt):
        """Render the widget."""
        ...
    
    fn update(inout self):
        """Update widget state (called each frame)."""
        ...

# Base widget implementation with common functionality
struct BaseWidgetInt:
    """Base widget with common functionality using integers."""
    
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var background_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.bounds = RectInt(x, y, width, height)
        self.visible = True
        self.enabled = True
        self.background_color = ColorInt(230, 230, 230, 255)  # Light gray
        self.border_color = ColorInt(128, 128, 128, 255)      # Gray
        self.border_width = 1
    
    fn get_bounds(self) -> RectInt:
        return self.bounds
    
    fn set_bounds(inout self, bounds: RectInt):
        self.bounds = bounds
    
    fn is_visible(self) -> Bool:
        return self.visible
    
    fn set_visible(inout self, visible: Bool):
        self.visible = visible
    
    fn is_enabled(self) -> Bool:
        return self.enabled
    
    fn set_enabled(inout self, enabled: Bool):
        self.enabled = enabled
    
    fn contains_point(self, point: PointInt) -> Bool:
        return self.bounds.contains(point)
    
    fn render_background(self, ctx: RenderingContextInt):
        """Render the widget's background."""
        if not self.visible:
            return
            
        # Draw background
        _ = ctx.set_color(self.background_color.r, self.background_color.g, 
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y, 
                                     self.bounds.width, self.bounds.height)
        
        # Draw border
        if self.border_width > 0:
            _ = ctx.set_color(self.border_color.r, self.border_color.g, 
                             self.border_color.b, self.border_color.a)
            _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y, 
                                  self.bounds.width, self.bounds.height)

# Event manager for handling input
struct EventManagerInt:
    """Manages input events using integer coordinates."""
    
    var mouse_x: Int32
    var mouse_y: Int32
    var last_mouse_x: Int32
    var last_mouse_y: Int32
    
    fn __init__(inout self):
        self.mouse_x = 0
        self.mouse_y = 0
        self.last_mouse_x = 0
        self.last_mouse_y = 0
    
    fn update(inout self, ctx: RenderingContextInt):
        """Update events from rendering context."""
        # Poll events
        _ = ctx.poll_events()
        
        # Update mouse position
        self.last_mouse_x = self.mouse_x
        self.last_mouse_y = self.mouse_y
        self.mouse_x = ctx.get_mouse_x()
        self.mouse_y = ctx.get_mouse_y()
    
    fn get_mouse_position(self) -> PointInt:
        """Get current mouse position."""
        return PointInt(self.mouse_x, self.mouse_y)
    
    fn mouse_moved(self) -> Bool:
        """Check if mouse moved since last frame."""
        return self.mouse_x != self.last_mouse_x or self.mouse_y != self.last_mouse_y
    
    fn is_mouse_button_pressed(self, ctx: RenderingContextInt, button: Int32) -> Bool:
        """Check if mouse button is currently pressed."""
        return ctx.get_mouse_button_state(button)
    
    fn is_key_pressed(self, ctx: RenderingContextInt, key_code: Int32) -> Bool:
        """Check if key is currently pressed."""
        return ctx.get_key_state(key_code)