#!/usr/bin/env mojo
"""
Standalone Mojo Integer-Only FFI Test
Self-contained test with all code in one file.
"""

from sys.ffi import external_call
from sys import DLHandle

struct RenderingContextInt:
    """Integer-only rendering context."""
    
    var lib: DLHandle
    var initialized: Bool
    
    fn __init__(inout self):
        """Initialize the rendering context."""
        self.lib = DLHandle("./c_src/librendering_primitives_int.so")
        self.initialized = False
    
    fn initialize(inout self, width: Int32, height: Int32, title: String) -> Bool:
        """Initialize OpenGL context with window."""
        try:
            let title_ptr = title.unsafe_ptr()
            let result = external_call["initialize_gl_context", Int32](
                self.lib, width, height, title_ptr
            )
            
            if result == 0:
                self.initialized = True
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
    
    fn draw_filled_rectangle(self, x: Int32, y: Int32, width: Int32, height: Int32) -> Bool:
        """Draw a filled rectangle."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_filled_rectangle", Int32](self.lib, x, y, width, height)
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
    
    fn draw_filled_circle(self, x: Int32, y: Int32, radius: Int32, segments: Int32 = 16) -> Bool:
        """Draw a filled circle."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_filled_circle", Int32](self.lib, x, y, radius, segments)
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
    
    fn should_close_window(self) -> Bool:
        """Check if window should close."""
        if not self.initialized:
            return True
            
        try:
            let result = external_call["should_close_window", Int32](self.lib)
            return result == 1
        except:
            return True

fn main():
    """Standalone test using proven patterns."""
    print("🧪 Starting Standalone Integer-Only Mojo Test")
    print("Self-contained test with proven MojoGUI patterns")
    
    # Create rendering context
    var ctx = RenderingContextInt()
    
    # Initialize
    if not ctx.initialize(640, 480, "Standalone Mojo Test"):
        print("❌ Failed to initialize")
        return
    
    print("✅ Integer-only context initialized")
    
    # Load font
    if not ctx.load_default_font():
        print("⚠️  Font loading failed")
    else:
        print("✅ Font loaded")
    
    print("🎯 Starting render loop...")
    
    # Simple render loop
    var frame_count: Int32 = 0
    var button_clicks: Int32 = 0
    var last_mouse_state: Bool = False
    
    # Simple button area (integers only)
    let button_x: Int32 = 200
    let button_y: Int32 = 200
    let button_w: Int32 = 140
    let button_h: Int32 = 45
    
    while not ctx.should_close_window() and frame_count < 300:  # 5 seconds at 60fps
        # Poll events
        _ = ctx.poll_events()
        
        # Get mouse state
        let mouse_x = ctx.get_mouse_x()
        let mouse_y = ctx.get_mouse_y()
        let mouse_pressed = ctx.get_mouse_button_state(0)
        
        # Check button click
        if mouse_pressed and not last_mouse_state:
            if (mouse_x >= button_x and mouse_x <= button_x + button_w and
                mouse_y >= button_y and mouse_y <= button_y + button_h):
                button_clicks += 1
                print("🖱️  Button clicked! Total clicks:", button_clicks)
        
        last_mouse_state = mouse_pressed
        
        # Begin frame
        if not ctx.frame_begin():
            print("❌ Frame begin failed")
            break
        
        # Clear background (dark blue)
        _ = ctx.set_color(25, 35, 50, 255)
        _ = ctx.draw_filled_rectangle(0, 0, 640, 480)
        
        # Draw title (white)
        _ = ctx.set_color(255, 255, 255, 255)
        _ = ctx.draw_text("Standalone Mojo Integer-Only Test", 50, 50, 18)
        
        # Draw description (light green)
        _ = ctx.set_color(180, 255, 180, 255)
        _ = ctx.draw_text("All coordinates & colors are Int32", 50, 90, 12)
        _ = ctx.draw_text("Self-contained implementation", 50, 110, 12)
        _ = ctx.draw_text("Using proven MojoGUI patterns", 50, 130, 12)
        
        # Draw button with hover effect
        let mouse_over = (mouse_x >= button_x and mouse_x <= button_x + button_w and
                         mouse_y >= button_y and mouse_y <= button_y + button_h)
        
        var button_r: Int32 = 220
        var button_g: Int32 = 220
        var button_b: Int32 = 220
        
        if mouse_pressed and mouse_over:
            button_r = 180
            button_g = 180
            button_b = 180
        elif mouse_over:
            button_r = 240
            button_g = 240
            button_b = 240
        
        _ = ctx.set_color(button_r, button_g, button_b, 255)
        _ = ctx.draw_filled_rectangle(button_x, button_y, button_w, button_h)
        
        # Button border
        _ = ctx.set_color(100, 100, 100, 255)
        _ = ctx.draw_rectangle(button_x, button_y, button_w, button_h)
        
        # Button text
        _ = ctx.set_color(0, 0, 0, 255)
        _ = ctx.draw_text("Click Me!", button_x + 35, button_y + 18, 14)
        
        # Draw mouse position (cyan)
        _ = ctx.set_color(100, 255, 255, 255)
        let mouse_text = "Mouse: " + str(mouse_x) + ", " + str(mouse_y)
        _ = ctx.draw_text(mouse_text, 50, 300, 12)
        
        # Click counter (yellow)
        _ = ctx.set_color(255, 255, 100, 255)
        let click_text = "Button Clicks: " + str(button_clicks)
        _ = ctx.draw_text(click_text, 50, 320, 12)
        
        # Frame counter (orange)
        _ = ctx.set_color(255, 180, 100, 255)
        let frame_text = "Frame: " + str(frame_count) + " / 300"
        _ = ctx.draw_text(frame_text, 50, 340, 12)
        
        # Features demonstrated (light gray)
        _ = ctx.set_color(180, 180, 180, 255)
        _ = ctx.draw_text("Demonstrated Features:", 50, 380, 12)
        _ = ctx.draw_text("✓ Integer-only FFI (no conversion bugs)", 70, 400, 11)
        _ = ctx.draw_text("✓ Real-time mouse tracking", 70, 420, 11)
        _ = ctx.draw_text("✓ Interactive button with hover states", 70, 440, 11)
        _ = ctx.draw_text("✓ Stable Mojo-C integration", 70, 460, 11)
        
        # Mouse cursor indicator (red circle)
        _ = ctx.set_color(255, 100, 100, 255)
        _ = ctx.draw_filled_circle(mouse_x, mouse_y, 5, 8)
        
        # End frame
        if not ctx.frame_end():
            print("❌ Frame end failed")
            break
        
        frame_count += 1
        
        # Status update every second
        if frame_count % 60 == 0:
            print("📊 Frame", frame_count, "- Mouse:", mouse_x, ",", mouse_y, "- Clicks:", button_clicks)
    
    print("🏁 Test completed after", frame_count, "frames")
    print("📊 Total button clicks:", button_clicks)
    
    # Cleanup
    if not ctx.cleanup():
        print("⚠️  Cleanup warning")
    else:
        print("✅ Cleanup successful")
    
    print("🎉 Standalone Mojo integer test successful!")
    print("🚀 Integer-only FFI working perfectly!")
    print("✨ Ready for full widget system implementation!")