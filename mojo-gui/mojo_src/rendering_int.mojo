"""
Integer-Only Mojo FFI bindings for minimal rendering primitives.
Follows the proven pattern from the working MojoGUI system.
Uses only Int32 types to avoid FFI conversion issues.
"""

from sys.ffi import external_call
from sys import DLHandle

# Load the integer-only C library WITH TTF FONT SUPPORT!
alias LIB_PATH = "./c_src/librendering_primitives_int_with_fonts.so"

struct RenderingContextInt:
    """Integer-only rendering context - avoids all FFI conversion issues."""
    
    var lib: DLHandle
    var initialized: Bool
    var width: Int32
    var height: Int32
    
    fn __init__(inout self):
        """Initialize the rendering context."""
        self.lib = DLHandle(LIB_PATH)
        self.initialized = False
        self.width = 0
        self.height = 0
    
    fn initialize(inout self, width: Int32, height: Int32, title: String) -> Bool:
        """Initialize OpenGL context with window."""
        try:
            # Convert string to C-compatible format
            let title_ptr = title.unsafe_ptr()
            
            # Call C function: int initialize_gl_context(int width, int height, const char* title)
            let result = external_call["initialize_gl_context", Int32](
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
            let result = external_call["cleanup_gl", Int32](self.lib)
            self.initialized = False
            return result == 0
        except:
            return False
    
    fn frame_begin(self) -> Bool:
        """Begin a new frame."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["frame_begin", Int32](self.lib)
            return result == 0
        except:
            return False
    
    fn frame_end(self) -> Bool:
        """End the current frame and present."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["frame_end", Int32](self.lib)
            return result == 0
        except:
            return False
    
    fn set_color(self, r: Int32, g: Int32, b: Int32, a: Int32) -> Bool:
        """Set the current drawing color (RGBA 0-255)."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["set_color", Int32](self.lib, r, g, b, a)
            return result == 0
        except:
            return False
    
    fn draw_rectangle(self, x: Int32, y: Int32, width: Int32, height: Int32) -> Bool:
        """Draw a rectangle outline."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_rectangle", Int32](self.lib, x, y, width, height)
            return result == 0
        except:
            return False
    
    fn draw_filled_rectangle(self, x: Int32, y: Int32, width: Int32, height: Int32) -> Bool:
        """Draw a filled rectangle."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_filled_rectangle", Int32](self.lib, x, y, width, height)
            return result == 0
        except:
            return False
    
    fn draw_circle(self, x: Int32, y: Int32, radius: Int32, segments: Int32 = 16) -> Bool:
        """Draw a circle outline."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_circle", Int32](self.lib, x, y, radius, segments)
            return result == 0
        except:
            return False
    
    fn draw_filled_circle(self, x: Int32, y: Int32, radius: Int32, segments: Int32 = 16) -> Bool:
        """Draw a filled circle."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_filled_circle", Int32](self.lib, x, y, radius, segments)
            return result == 0
        except:
            return False
    
    fn draw_line(self, x1: Int32, y1: Int32, x2: Int32, y2: Int32, thickness: Int32 = 1) -> Bool:
        """Draw a line."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_line", Int32](self.lib, x1, y1, x2, y2, thickness)
            return result == 0
        except:
            return False
    
    fn load_default_font(self) -> Bool:
        """Load the default font for text rendering."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["load_default_font", Int32](self.lib)
            return result == 0
        except:
            return False
    
    fn draw_text(self, text: String, x: Int32, y: Int32, size: Int32) -> Bool:
        """Draw text at the specified position."""
        if not self.initialized:
            return False
            
        try:
            let text_ptr = text.unsafe_ptr()
            let result = external_call["draw_text", Int32](self.lib, text_ptr, x, y, size)
            return result == 0
        except:
            return False
    
    fn get_text_width(self, text: String, size: Int32) -> Int32:
        """Get the width of text when rendered."""
        if not self.initialized:
            return 0
            
        try:
            let text_ptr = text.unsafe_ptr()
            let result = external_call["get_text_width", Int32](self.lib, text_ptr, size)
            return result
        except:
            return 0
    
    fn get_text_height(self, text: String, size: Int32) -> Int32:
        """Get the height of text when rendered."""
        if not self.initialized:
            return 0
            
        try:
            let text_ptr = text.unsafe_ptr()
            let result = external_call["get_text_height", Int32](self.lib, text_ptr, size)
            return result
        except:
            return 0
    
    fn poll_events(self) -> Bool:
        """Poll for window events."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["poll_events", Int32](self.lib)
            return result == 0
        except:
            return False
    
    fn get_mouse_x(self) -> Int32:
        """Get current mouse X position."""
        if not self.initialized:
            return 0
            
        try:
            let result = external_call["get_mouse_x", Int32](self.lib)
            return result
        except:
            return 0
    
    fn get_mouse_y(self) -> Int32:
        """Get current mouse Y position."""
        if not self.initialized:
            return 0
            
        try:
            let result = external_call["get_mouse_y", Int32](self.lib)
            return result
        except:
            return 0
    
    fn get_mouse_button_state(self, button: Int32) -> Bool:
        """Get mouse button state."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["get_mouse_button_state", Int32](self.lib, button)
            return result == 1
        except:
            return False
    
    fn get_key_state(self, key_code: Int32) -> Bool:
        """Get key state."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["get_key_state", Int32](self.lib, key_code)
            return result == 1
        except:
            return False
    
    fn should_close_window(self) -> Bool:
        """Check if window should close."""
        if not self.initialized:
            return True
            
        try:
            let result = external_call["should_close_window", Int32](self.lib)
            return result == 1
        except:
            return True

# Integer-based convenience types for Mojo GUI
struct ColorInt:
    """RGBA color representation using integers (0-255)."""
    var r: Int32
    var g: Int32
    var b: Int32
    var a: Int32
    
    fn __init__(inout self, r: Int32, g: Int32, b: Int32, a: Int32 = 255):
        self.r = r
        self.g = g  
        self.b = b
        self.a = a

struct PointInt:
    """2D point representation using integers."""
    var x: Int32
    var y: Int32
    
    fn __init__(inout self, x: Int32, y: Int32):
        self.x = x
        self.y = y

struct SizeInt:
    """2D size representation using integers."""
    var width: Int32
    var height: Int32
    
    fn __init__(inout self, width: Int32, height: Int32):
        self.width = width
        self.height = height

struct RectInt:
    """Rectangle representation using integers."""
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    
    fn contains(self, point: PointInt) -> Bool:
        """Check if point is inside rectangle."""
        return (point.x >= self.x and point.x <= self.x + self.width and
                point.y >= self.y and point.y <= self.y + self.height)

# Common colors (RGB 0-255)
alias COLOR_BLACK = ColorInt(0, 0, 0, 255)
alias COLOR_WHITE = ColorInt(255, 255, 255, 255)
alias COLOR_RED = ColorInt(255, 0, 0, 255)
alias COLOR_GREEN = ColorInt(0, 255, 0, 255)
alias COLOR_BLUE = ColorInt(0, 0, 255, 255)
alias COLOR_YELLOW = ColorInt(255, 255, 0, 255)
alias COLOR_CYAN = ColorInt(0, 255, 255, 255)
alias COLOR_MAGENTA = ColorInt(255, 0, 255, 255)
alias COLOR_GRAY = ColorInt(128, 128, 128, 255)
alias COLOR_LIGHT_GRAY = ColorInt(192, 192, 192, 255)
alias COLOR_DARK_GRAY = ColorInt(64, 64, 64, 255)