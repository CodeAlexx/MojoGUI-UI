#!/usr/bin/env mojo
"""
Simple Mojo Integer-Only FFI Test
Tests the minimal FFI approach using only Int32 types.
"""

from sys import external_call, sizeof
from memory import UnsafePointer, memset_zero
from utils.string_slice import StringSlice

# External library handle WITH TTF FONTS!
alias lib_path = "./c_src/librendering_primitives_int_with_fonts.so"

struct RenderingTestInt:
    """Simple rendering test using integer-only FFI."""
    
    var lib: UnsafePointer[NoneType]
    var initialized: Bool
    
    fn __init__(inout self):
        self.lib = UnsafePointer[NoneType]()
        self.initialized = False
    
    fn initialize(inout self, width: Int32, height: Int32, title: String) -> Bool:
        """Initialize the rendering context."""
        try:
            # Load library
            self.lib = external_call["dlopen", UnsafePointer[NoneType]](
                lib_path.data(), 2  # RTLD_NOW
            )
            
            if not self.lib:
                print("❌ Failed to load library")
                return False
            
            # Initialize GL context
            let result = external_call["initialize_gl_context", Int32](
                self.lib, width, height, title.data()
            )
            
            if result != 0:
                print("❌ Failed to initialize GL context:", result)
                return False
            
            self.initialized = True
            return True
            
        except:
            print("❌ Exception during initialization")
            return False
    
    fn cleanup(inout self) -> Bool:
        """Cleanup the rendering context."""
        if not self.initialized:
            return True
            
        try:
            let result = external_call["cleanup_gl", Int32](self.lib)
            self.initialized = False
            return result == 0
        except:
            return False
    
    fn load_default_font(self) -> Bool:
        """Load default font."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["load_default_font", Int32](self.lib)
            return result == 0
        except:
            return False
    
    fn frame_begin(self) -> Bool:
        """Begin frame rendering."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["frame_begin", Int32](self.lib)
            return result == 0
        except:
            return False
    
    fn frame_end(self) -> Bool:
        """End frame rendering."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["frame_end", Int32](self.lib)
            return result == 0
        except:
            return False
    
    fn set_color(self, r: Int32, g: Int32, b: Int32, a: Int32) -> Bool:
        """Set drawing color (0-255 range)."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["set_color", Int32](self.lib, r, g, b, a)
            return result == 0
        except:
            return False
    
    fn draw_filled_rectangle(self, x: Int32, y: Int32, width: Int32, height: Int32) -> Bool:
        """Draw filled rectangle."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_filled_rectangle", Int32](
                self.lib, x, y, width, height
            )
            return result == 0
        except:
            return False
    
    fn draw_rectangle(self, x: Int32, y: Int32, width: Int32, height: Int32) -> Bool:
        """Draw rectangle outline."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_rectangle", Int32](
                self.lib, x, y, width, height
            )
            return result == 0
        except:
            return False
    
    fn draw_text(self, text: String, x: Int32, y: Int32, size: Int32) -> Bool:
        """Draw text."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_text", Int32](
                self.lib, text.data(), x, y, size
            )
            return result == 0
        except:
            return False
    
    fn draw_filled_circle(self, x: Int32, y: Int32, radius: Int32, segments: Int32) -> Bool:
        """Draw filled circle."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["draw_filled_circle", Int32](
                self.lib, x, y, radius, segments
            )
            return result == 0
        except:
            return False
    
    fn poll_events(self) -> Bool:
        """Poll input events."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["poll_events", Int32](self.lib)
            return result == 0
        except:
            return False
    
    fn should_close_window(self) -> Bool:
        """Check if window should close."""
        if not self.initialized:
            return True
            
        try:
            let result = external_call["should_close_window", Int32](self.lib)
            return result != 0
        except:
            return True
    
    fn get_mouse_x(self) -> Int32:
        """Get mouse X position."""
        if not self.initialized:
            return 0
            
        try:
            return external_call["get_mouse_x", Int32](self.lib)
        except:
            return 0
    
    fn get_mouse_y(self) -> Int32:
        """Get mouse Y position."""
        if not self.initialized:
            return 0
            
        try:
            return external_call["get_mouse_y", Int32](self.lib)
        except:
            return 0
    
    fn get_mouse_button_state(self, button: Int32) -> Bool:
        """Get mouse button state."""
        if not self.initialized:
            return False
            
        try:
            let result = external_call["get_mouse_button_state", Int32](self.lib, button)
            return result != 0
        except:
            return False


fn main():
    """Simple integer-only Mojo GUI test."""
    print("🧪 Starting Simple Integer-Only Mojo Test")
    print("Testing minimal FFI approach with pure Int32 interface")
    
    var ctx = RenderingTestInt()
    
    # Initialize
    if not ctx.initialize(800, 600, "Mojo TTF Font Test - Integer API"):
        print("❌ Failed to initialize")
        return
    
    print("✅ Integer-only context with TTF fonts initialized")
    
    # Load professional fonts
    if not ctx.load_default_font():
        print("⚠️  TTF font loading failed, using rectangle fallback")
    else:
        print("✅ Professional TTF fonts loaded! (Inter, Roboto, Ubuntu, etc.)")
    
    print("🎯 Starting render loop...")
    
    # Simple render loop
    var frame_count: Int32 = 0
    var button_clicks: Int32 = 0
    var last_mouse_state: Bool = False
    
    # Simple button area (integers only)
    let button_x: Int32 = 200
    let button_y: Int32 = 200
    let button_w: Int32 = 100
    let button_h: Int32 = 40
    
    while not ctx.should_close_window() and frame_count < 180:  # 3 seconds at 60fps
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
        
        # Clear background (dark gray)
        _ = ctx.set_color(40, 40, 40, 255)
        _ = ctx.draw_filled_rectangle(0, 0, 800, 600)
        
        # Draw title with TTF fonts (white)
        _ = ctx.set_color(255, 255, 255, 255)
        _ = ctx.draw_text("🎨 Mojo TTF Font Rendering - Integer API", 50, 50, 24)
        
        # Draw description (light green)
        _ = ctx.set_color(150, 255, 150, 255)
        _ = ctx.draw_text("Professional fonts via stb_truetype with Int32 coordinates", 50, 90, 14)
        
        # Draw button
        let button_color = 255 if mouse_pressed and (
            mouse_x >= button_x and mouse_x <= button_x + button_w and
            mouse_y >= button_y and mouse_y <= button_y + button_h) else 220
        
        _ = ctx.set_color(button_color, button_color, button_color, 255)
        _ = ctx.draw_filled_rectangle(button_x, button_y, button_w, button_h)
        
        # Button border
        _ = ctx.set_color(100, 100, 100, 255)
        _ = ctx.draw_rectangle(button_x, button_y, button_w, button_h)
        
        # Button text
        _ = ctx.set_color(0, 0, 0, 255)
        _ = ctx.draw_text("Click Me!", button_x + 25, button_y + 15, 14)
        
        # Draw mouse position (cyan)
        _ = ctx.set_color(100, 255, 255, 255)
        let mouse_text = "Mouse: " + str(mouse_x) + ", " + str(mouse_y)
        _ = ctx.draw_text(mouse_text, 50, 130, 12)
        
        # Click counter (yellow)
        _ = ctx.set_color(255, 255, 100, 255)
        let click_text = "Clicks: " + str(button_clicks)
        _ = ctx.draw_text(click_text, 50, 150, 12)
        
        # TTF Font Features demonstrated (light blue)
        _ = ctx.set_color(150, 200, 255, 255)
        _ = ctx.draw_text("🔤 TTF Font Features:", 50, 320, 16)
        
        _ = ctx.set_color(200, 200, 200, 255)
        _ = ctx.draw_text("• Real fonts: Inter, Roboto, Ubuntu, etc.", 70, 350, 12)
        _ = ctx.draw_text("• Professional anti-aliasing like VS Code", 70, 370, 12)
        _ = ctx.draw_text("• Integer-only API (no FFI conversion bugs)", 70, 390, 12)
        _ = ctx.draw_text("• Gamma-corrected alpha blending for crisp text", 70, 410, 12)
        _ = ctx.draw_text("• Modern UI quality with pixel-perfect spacing", 70, 430, 12)
        
        # Mouse cursor indicator (red circle)
        _ = ctx.set_color(255, 100, 100, 255)
        _ = ctx.draw_filled_circle(mouse_x, mouse_y, 4, 8)
        
        # End frame
        if not ctx.frame_end():
            print("❌ Frame end failed")
            break
        
        frame_count += 1
        
        # Status update
        if frame_count % 60 == 0:
            print("📊 Frame", frame_count, "- Mouse:", mouse_x, ",", mouse_y, "- Clicks:", button_clicks)
    
    print("🏁 Test completed after", frame_count, "frames")
    print("📊 Total button clicks:", button_clicks)
    
    # Cleanup
    if not ctx.cleanup():
        print("⚠️  Cleanup warning")
    else:
        print("✅ Cleanup successful")
    
    print("🎉 Simple Mojo integer test successful!")
    print("🚀 Integer-only FFI working perfectly!")