"""
Mojo FFI bindings for minimal rendering primitives.
Provides safe access to C OpenGL rendering functions.
"""

from sys.ffi import external_call
from sys import DLHandle
from memory import DTypePointer
from utils import Variant

# Load the C library
alias LIB_PATH = "./c_src/librendering_primitives.so"

struct RenderingContext:
    """Manages the OpenGL rendering context and provides safe access to primitives."""
    
    var lib: DLHandle
    var initialized: Bool
    var width: Int
    var height: Int
    
    fn __init__(inout self):
        """Initialize the rendering context."""
        self.lib = DLHandle(LIB_PATH)
        self.initialized = False
        self.width = 0
        self.height = 0
    
    fn initialize(inout self, width: Int, height: Int, title: String) -> Bool:
        """Initialize OpenGL context with window."""
        try:
            # Convert string to C-compatible format
            let title_ptr = title.unsafe_ptr()
            
            # Call C function: int initialize_gl_context(int width, int height, const char* title)
            let result = external_call["initialize_gl_context", Int](
                self.lib, width, height, title_ptr
            )
            
            if result == 0:
                self.initialized = True
                self.width = width
                self.height = height
                return True
            else:
                return False
        except:
            return False
    
    fn cleanup(inout self) -> Bool:
        """Clean up OpenGL context."""
        if not self.initialized:
            return True
            
        try:
            let result = external_call["cleanup_gl", Int](self.lib)
            self.initialized = False
            return result == 0
        except:
            return False
    
    fn frame_begin(self) -> Bool:
        """Begin a new frame."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["frame_begin", Int](self.lib)
            return result == 0
        except:
            return False
    
    fn frame_end(self) -> Bool:
        """End the current frame and present."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["frame_end", Int](self.lib)
            return result == 0
        except:
            return False
    
    fn set_color(self, r: Float32, g: Float32, b: Float32, a: Float32) -> Bool:
        """Set the current drawing color."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["set_color", Int](self.lib, r, g, b, a)
            return result == 0
        except:
            return False
    
    fn draw_rectangle(self, x: Float32, y: Float32, width: Float32, height: Float32) -> Bool:
        """Draw a rectangle outline."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_rectangle", Int](self.lib, x, y, width, height)
            return result == 0
        except:
            return False
    
    fn draw_filled_rectangle(self, x: Float32, y: Float32, width: Float32, height: Float32) -> Bool:
        """Draw a filled rectangle."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_filled_rectangle", Int](self.lib, x, y, width, height)
            return result == 0
        except:
            return False
    
    fn draw_circle(self, x: Float32, y: Float32, radius: Float32, segments: Int = 16) -> Bool:
        """Draw a circle outline."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_circle", Int](self.lib, x, y, radius, segments)
            return result == 0
        except:
            return False
    
    fn draw_filled_circle(self, x: Float32, y: Float32, radius: Float32, segments: Int = 16) -> Bool:
        """Draw a filled circle."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_filled_circle", Int](self.lib, x, y, radius, segments)
            return result == 0
        except:
            return False
    
    fn draw_line(self, x1: Float32, y1: Float32, x2: Float32, y2: Float32, thickness: Float32 = 1.0) -> Bool:
        """Draw a line."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_line", Int](self.lib, x1, y1, x2, y2, thickness)
            return result == 0
        except:
            return False
    
    fn load_default_font(self) -> Bool:
        """Load the default font for text rendering."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["load_default_font", Int](self.lib)
            return result == 0
        except:
            return False
    
    fn draw_text(self, text: String, x: Float32, y: Float32, size: Float32) -> Bool:
        """Draw text at the specified position."""
        if not self.initialized:
            return False
            
        try:
            let text_ptr = text.unsafe_ptr()
            let result = external_call["draw_text", Int](self.lib, text_ptr, x, y, size)
            return result == 0
        except:
            return False
    
    fn get_text_size(self, text: String, size: Float32) -> (Float32, Float32):
        """Get the width and height of text when rendered."""
        if not self.initialized:
            return (0.0, 0.0)
            
        try:
            let text_ptr = text.unsafe_ptr()
            var width: Float32 = 0.0
            var height: Float32 = 0.0
            
            # For now, return estimated size (would need proper FFI for output params)
            let char_width = size * 0.6
            let estimated_width = len(text) * char_width
            return (estimated_width, size)
        except:
            return (0.0, 0.0)
    
    fn poll_events(self) -> Bool:
        """Poll for window events."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["poll_events", Int](self.lib)
            return result == 0
        except:
            return False
    
    fn get_mouse_position(self) -> (Int, Int):
        """Get current mouse position."""
        if not self.initialized:
            return (0, 0)
            
        try:
            # For now, return default (would need proper FFI for output params)
            # In a complete implementation, would call the C function
            return (0, 0)
        except:
            return (0, 0)
    
    fn get_mouse_button_state(self, button: Int) -> Bool:
        """Get mouse button state."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["get_mouse_button_state", Int](self.lib, button)
            return result == 1
        except:
            return False
    
    fn get_key_state(self, key_code: Int) -> Bool:
        """Get key state."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["get_key_state", Int](self.lib, key_code)
            return result == 1
        except:
            return False
    
    fn should_close_window(self) -> Bool:
        """Check if window should close."""
        if not self.initialized:
            return True
            
        try:
            let result = external_call["should_close_window", Int](self.lib)
            return result == 1
        except:
            return True

# Convenience types for Mojo GUI
struct Color:
    """RGBA color representation."""
    var r: Float32
    var g: Float32
    var b: Float32
    var a: Float32
    
    fn __init__(inout self, r: Float32, g: Float32, b: Float32, a: Float32 = 1.0):
        self.r = r
        self.g = g  
        self.b = b
        self.a = a

struct Point:
    """2D point representation."""
    var x: Float32
    var y: Float32
    
    fn __init__(inout self, x: Float32, y: Float32):
        self.x = x
        self.y = y

struct Size:
    """2D size representation."""
    var width: Float32
    var height: Float32
    
    fn __init__(inout self, width: Float32, height: Float32):
        self.width = width
        self.height = height

struct Rect:
    """Rectangle representation."""
    var x: Float32
    var y: Float32
    var width: Float32
    var height: Float32
    
    fn __init__(inout self, x: Float32, y: Float32, width: Float32, height: Float32):
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    
    fn contains(self, point: Point) -> Bool:
        """Check if point is inside rectangle."""
        return (point.x >= self.x and point.x <= self.x + self.width and
                point.y >= self.y and point.y <= self.y + self.height)