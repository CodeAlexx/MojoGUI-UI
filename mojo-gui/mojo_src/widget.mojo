"""
Base Widget System for Mojo GUI
Defines the core widget trait and common functionality.
"""

from .rendering import RenderingContext, Color, Point, Size, Rect

# Event types
struct MouseEvent:
    """Mouse event data."""
    var x: Int
    var y: Int
    var button: Int
    var pressed: Bool
    
    fn __init__(inout self, x: Int, y: Int, button: Int, pressed: Bool):
        self.x = x
        self.y = y
        self.button = button
        self.pressed = pressed

struct KeyEvent:
    """Keyboard event data."""
    var key_code: Int
    var pressed: Bool
    
    fn __init__(inout self, key_code: Int, pressed: Bool):
        self.key_code = key_code
        self.pressed = pressed

# Base widget trait
trait Widget:
    """Base trait for all GUI widgets."""
    
    fn get_bounds(self) -> Rect:
        """Get the widget's bounding rectangle."""
        ...
    
    fn set_bounds(inout self, bounds: Rect):
        """Set the widget's bounding rectangle."""
        ...
    
    fn is_visible(self) -> Bool:
        """Check if widget is visible."""
        ...
    
    fn set_visible(inout self, visible: Bool):
        """Set widget visibility."""
        ...
    
    fn contains_point(self, point: Point) -> Bool:
        """Check if point is inside widget."""
        ...
    
    fn handle_mouse_event(inout self, event: MouseEvent) -> Bool:
        """Handle mouse event. Returns True if handled."""
        ...
    
    fn handle_key_event(inout self, event: KeyEvent) -> Bool:
        """Handle key event. Returns True if handled."""
        ...
    
    fn render(self, ctx: RenderingContext):
        """Render the widget."""
        ...
    
    fn update(inout self):
        """Update widget state (called each frame)."""
        ...

# Base widget implementation with common functionality
struct BaseWidget:
    """Base widget with common functionality."""
    
    var bounds: Rect
    var visible: Bool
    var enabled: Bool
    var background_color: Color
    var border_color: Color
    var border_width: Float32
    
    fn __init__(inout self, x: Float32, y: Float32, width: Float32, height: Float32):
        self.bounds = Rect(x, y, width, height)
        self.visible = True
        self.enabled = True
        self.background_color = Color(0.9, 0.9, 0.9, 1.0)  # Light gray
        self.border_color = Color(0.5, 0.5, 0.5, 1.0)      # Gray
        self.border_width = 1.0
    
    fn get_bounds(self) -> Rect:
        return self.bounds
    
    fn set_bounds(inout self, bounds: Rect):
        self.bounds = bounds
    
    fn is_visible(self) -> Bool:
        return self.visible
    
    fn set_visible(inout self, visible: Bool):
        self.visible = visible
    
    fn is_enabled(self) -> Bool:
        return self.enabled
    
    fn set_enabled(inout self, enabled: Bool):
        self.enabled = enabled
    
    fn contains_point(self, point: Point) -> Bool:
        return self.bounds.contains(point)
    
    fn render_background(self, ctx: RenderingContext):
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

# Widget container for managing child widgets
struct WidgetContainer(BaseWidget):
    """Container widget that can hold child widgets."""
    
    var children: List[Widget]
    
    fn __init__(inout self, x: Float32, y: Float32, width: Float32, height: Float32):
        self.super().__init__(x, y, width, height)
        self.children = List[Widget]()
    
    fn add_child(inout self, widget: Widget):
        """Add a child widget."""
        self.children.append(widget)
    
    fn remove_child(inout self, widget: Widget):
        """Remove a child widget."""
        # TODO: Implement removal logic
        pass
    
    fn handle_mouse_event(inout self, event: MouseEvent) -> Bool:
        """Handle mouse event by propagating to children."""
        if not self.visible or not self.enabled:
            return False
        
        let point = Point(event.x, event.y)
        if not self.contains_point(point):
            return False
        
        # Propagate to children (in reverse order for top-to-bottom handling)
        for i in range(len(self.children) - 1, -1, -1):
            if self.children[i].handle_mouse_event(event):
                return True
        
        return False
    
    fn handle_key_event(inout self, event: KeyEvent) -> Bool:
        """Handle key event by propagating to children."""
        if not self.visible or not self.enabled:
            return False
        
        for i in range(len(self.children)):
            if self.children[i].handle_key_event(event):
                return True
        
        return False
    
    fn render(self, ctx: RenderingContext):
        """Render container and all children."""
        if not self.visible:
            return
        
        # Render background
        self.render_background(ctx)
        
        # Render children
        for i in range(len(self.children)):
            self.children[i].render(ctx)
    
    fn update(inout self):
        """Update container and all children."""
        for i in range(len(self.children)):
            self.children[i].update()

# Event manager for handling input
struct EventManager:
    """Manages input events and distributes them to widgets."""
    
    var root_widget: WidgetContainer
    var mouse_x: Int
    var mouse_y: Int
    var last_mouse_x: Int
    var last_mouse_y: Int
    
    fn __init__(inout self, root: WidgetContainer):
        self.root_widget = root
        self.mouse_x = 0
        self.mouse_y = 0
        self.last_mouse_x = 0
        self.last_mouse_y = 0
    
    fn update(inout self, ctx: RenderingContext):
        """Update events from rendering context."""
        # Poll events
        _ = ctx.poll_events()
        
        # Update mouse position
        self.last_mouse_x = self.mouse_x
        self.last_mouse_y = self.mouse_y
        let (mx, my) = ctx.get_mouse_position()
        self.mouse_x = mx
        self.mouse_y = my
        
        # Check for mouse events
        if ctx.get_mouse_button_state(0):  # Left click
            let event = MouseEvent(self.mouse_x, self.mouse_y, 0, True)
            _ = self.root_widget.handle_mouse_event(event)
        
        # Check for key events (simplified)
        if ctx.get_key_state(27):  # ESC key
            let event = KeyEvent(27, True)
            _ = self.root_widget.handle_key_event(event)
    
    fn get_mouse_position(self) -> (Int, Int):
        """Get current mouse position."""
        return (self.mouse_x, self.mouse_y)
    
    fn mouse_moved(self) -> Bool:
        """Check if mouse moved since last frame."""
        return self.mouse_x != self.last_mouse_x or self.mouse_y != self.last_mouse_y