"""
Integer-Only Mojo FFI bindings for minimal rendering primitives.
Wraps the Float32 C library with Int32 API for widget convenience.
Uses DLHandle.get_function for dynamic library loading.
"""

from sys.ffi import OwnedDLHandle as DLHandle
from memory import alloc, UnsafePointer
from builtin.type_aliases import MutExternalOrigin

# Path to the actual working C library (uses Float32 internally)
# Library path constant (relative to execution directory)
comptime LIB_PATH = "./mojo-gui/c_src/librendering_with_fonts.so"

fn _to_c_string(text: String) -> UnsafePointer[Int8, MutExternalOrigin]:
    """Convert a Mojo string to a null-terminated C string."""
    var bytes = text.as_bytes()
    var buffer = alloc[Int8](len(bytes) + 1)
    for i in range(len(bytes)):
        buffer[i] = Int8(bytes[i])
    buffer[len(bytes)] = 0
    return buffer

struct RenderingContextInt:
    """Integer-only rendering context - converts to Float32 for C library."""

    var lib: DLHandle
    var initialized: Bool
    var width: Int32
    var height: Int32

    fn __init__(out self) raises:
        """Initialize the rendering context."""
        self.lib = DLHandle(LIB_PATH)
        self.initialized = False
        self.width = 0
        self.height = 0

    fn __init__(out self, lib_path: String) raises:
        """Initialize with custom library path."""
        self.lib = DLHandle(lib_path)
        self.initialized = False
        self.width = 0
        self.height = 0

    fn initialize(mut self, width: Int32, height: Int32, title: String) -> Bool:
        """Initialize OpenGL context with window."""
        var init_fn = self.lib.get_function[fn(Int32, Int32, UnsafePointer[Int8, MutExternalOrigin]) -> Int32]("initialize_gl_context")
        var title_ptr = _to_c_string(title)
        var result = init_fn(width, height, title_ptr)

        if result == 0:
            self.initialized = True
            self.width = width
            self.height = height
            return True
        return False

    fn cleanup(mut self) -> Bool:
        """Clean up OpenGL context."""
        if not self.initialized:
            return True
        var cleanup_fn = self.lib.get_function[fn() -> Int32]("cleanup_gl")
        var result = cleanup_fn()
        self.initialized = False
        return result == 0

    fn frame_begin(self) -> Bool:
        """Begin a new frame."""
        if not self.initialized:
            return False
        var frame_begin_fn = self.lib.get_function[fn() -> Int32]("frame_begin")
        return frame_begin_fn() == 0

    fn frame_end(self) -> Bool:
        """End the current frame and present."""
        if not self.initialized:
            return False
        var frame_end_fn = self.lib.get_function[fn() -> Int32]("frame_end")
        return frame_end_fn() == 0

    fn set_color(self, r: Int32, g: Int32, b: Int32, a: Int32) -> Bool:
        """Set the current drawing color (RGBA 0-255). Normalizes to 0.0-1.0 for OpenGL."""
        if not self.initialized:
            return False
        # C library uses Float32 in 0.0-1.0 range, so convert and normalize
        var set_color_fn = self.lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("set_color")
        return set_color_fn(Float32(r) / 255.0, Float32(g) / 255.0, Float32(b) / 255.0, Float32(a) / 255.0) == 0

    fn draw_rectangle(self, x: Int32, y: Int32, width: Int32, height: Int32) -> Bool:
        """Draw a rectangle outline."""
        if not self.initialized:
            return False
        var draw_rect_fn = self.lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("draw_rectangle")
        return draw_rect_fn(Float32(x), Float32(y), Float32(width), Float32(height)) == 0

    fn draw_filled_rectangle(self, x: Int32, y: Int32, width: Int32, height: Int32) -> Bool:
        """Draw a filled rectangle."""
        if not self.initialized:
            return False
        var draw_filled_rect_fn = self.lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("draw_filled_rectangle")
        return draw_filled_rect_fn(Float32(x), Float32(y), Float32(width), Float32(height)) == 0

    fn draw_circle(self, x: Int32, y: Int32, radius: Int32, segments: Int32 = 16) -> Bool:
        """Draw a circle outline."""
        if not self.initialized:
            return False
        var draw_circle_fn = self.lib.get_function[fn(Float32, Float32, Float32, Int32) -> Int32]("draw_circle")
        return draw_circle_fn(Float32(x), Float32(y), Float32(radius), segments) == 0

    fn draw_filled_circle(self, x: Int32, y: Int32, radius: Int32, segments: Int32 = 16) -> Bool:
        """Draw a filled circle."""
        if not self.initialized:
            return False
        var draw_filled_circle_fn = self.lib.get_function[fn(Float32, Float32, Float32, Int32) -> Int32]("draw_filled_circle")
        return draw_filled_circle_fn(Float32(x), Float32(y), Float32(radius), segments) == 0

    fn draw_line(self, x1: Int32, y1: Int32, x2: Int32, y2: Int32, thickness: Int32 = 1) -> Bool:
        """Draw a line."""
        if not self.initialized:
            return False
        var draw_line_fn = self.lib.get_function[fn(Float32, Float32, Float32, Float32, Float32) -> Int32]("draw_line")
        return draw_line_fn(Float32(x1), Float32(y1), Float32(x2), Float32(y2), Float32(thickness)) == 0

    fn load_default_font(self) -> Bool:
        """Load the default font for text rendering."""
        if not self.initialized:
            return False
        var load_font_fn = self.lib.get_function[fn() -> Int32]("load_default_font")
        return load_font_fn() == 0

    fn draw_text(self, text: String, x: Int32, y: Int32, size: Int32) -> Bool:
        """Draw text at the specified position."""
        if not self.initialized:
            return False
        var draw_text_fn = self.lib.get_function[fn(UnsafePointer[Int8, MutExternalOrigin], Float32, Float32, Float32) -> Int32]("draw_text")
        var text_ptr = _to_c_string(text)
        return draw_text_fn(text_ptr, Float32(x), Float32(y), Float32(size)) == 0

    fn get_text_width(self, text: String, size: Int32) -> Int32:
        """Get the width of text when rendered."""
        if not self.initialized:
            return 0
        var get_width_fn = self.lib.get_function[fn(UnsafePointer[Int8, MutExternalOrigin], Float32) -> Int32]("get_text_width")
        var text_ptr = _to_c_string(text)
        return get_width_fn(text_ptr, Float32(size))

    fn get_text_height(self, text: String, size: Int32) -> Int32:
        """Get the height of text when rendered."""
        if not self.initialized:
            return 0
        var get_height_fn = self.lib.get_function[fn(UnsafePointer[Int8, MutExternalOrigin], Float32) -> Int32]("get_text_height")
        var text_ptr = _to_c_string(text)
        return get_height_fn(text_ptr, Float32(size))

    fn poll_events(self) -> Bool:
        """Poll for window events."""
        if not self.initialized:
            return False
        var poll_fn = self.lib.get_function[fn() -> Int32]("poll_events")
        return poll_fn() == 0

    fn get_mouse_x(self) -> Int32:
        """Get current mouse X position."""
        if not self.initialized:
            return 0
        var get_x_fn = self.lib.get_function[fn() -> Int32]("get_mouse_x")
        return get_x_fn()

    fn get_mouse_y(self) -> Int32:
        """Get current mouse Y position."""
        if not self.initialized:
            return 0
        var get_y_fn = self.lib.get_function[fn() -> Int32]("get_mouse_y")
        return get_y_fn()

    fn get_mouse_button_state(self, button: Int32) -> Bool:
        """Get mouse button state."""
        if not self.initialized:
            return False
        var get_btn_fn = self.lib.get_function[fn(Int32) -> Int32]("get_mouse_button_state")
        return get_btn_fn(button) == 1

    fn get_key_state(self, key_code: Int32) -> Bool:
        """Get key state."""
        if not self.initialized:
            return False
        var get_key_fn = self.lib.get_function[fn(Int32) -> Int32]("get_key_state")
        return get_key_fn(key_code) == 1

    fn should_close_window(self) -> Bool:
        """Check if window should close."""
        if not self.initialized:
            return True
        var should_close_fn = self.lib.get_function[fn() -> Int32]("should_close_window")
        return should_close_fn() == 1

# Integer-based convenience types for Mojo GUI
struct ColorInt(ImplicitlyCopyable, Movable):
    """RGBA color representation using integers (0-255)."""
    var r: Int32
    var g: Int32
    var b: Int32
    var a: Int32

    fn __init__(out self, r: Int32, g: Int32, b: Int32, a: Int32 = 255):
        self.r = r
        self.g = g
        self.b = b
        self.a = a

struct PointInt(ImplicitlyCopyable, Movable):
    """2D point representation using integers."""
    var x: Int32
    var y: Int32

    fn __init__(out self, x: Int32, y: Int32):
        self.x = x
        self.y = y

struct SizeInt(ImplicitlyCopyable, Movable):
    """2D size representation using integers."""
    var width: Int32
    var height: Int32

    fn __init__(out self, width: Int32, height: Int32):
        self.width = width
        self.height = height

struct RectInt(ImplicitlyCopyable, Movable):
    """Rectangle representation using integers."""
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32

    fn __init__(out self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.x = x
        self.y = y
        self.width = width
        self.height = height

    fn contains(self, point: PointInt) -> Bool:
        """Check if point is inside rectangle."""
        return (point.x >= self.x and point.x <= self.x + self.width and
                point.y >= self.y and point.y <= self.y + self.height)

# Common colors (RGB 0-255) - using fn instead of alias for struct initialization
fn color_black() -> ColorInt:
    return ColorInt(0, 0, 0, 255)

fn color_white() -> ColorInt:
    return ColorInt(255, 255, 255, 255)

fn color_red() -> ColorInt:
    return ColorInt(255, 0, 0, 255)

fn color_green() -> ColorInt:
    return ColorInt(0, 255, 0, 255)

fn color_blue() -> ColorInt:
    return ColorInt(0, 0, 255, 255)

fn color_gray() -> ColorInt:
    return ColorInt(128, 128, 128, 255)

fn color_light_gray() -> ColorInt:
    return ColorInt(192, 192, 192, 255)

fn color_dark_gray() -> ColorInt:
    return ColorInt(64, 64, 64, 255)
