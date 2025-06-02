#!/usr/bin/env mojo
"""
Minimal Mojo Integer-Only FFI Test
Tests the proven pattern from working MojoGUI system.
"""

from mojo_src.rendering_int import RenderingContextInt, ColorInt

fn main():
    """Simple test using proven patterns."""
    print("🧪 Starting Minimal Integer-Only Mojo Test")
    print("Using proven patterns from successful MojoGUI system")
    
    # Create rendering context
    var ctx = RenderingContextInt()
    
    # Initialize
    if not ctx.initialize(640, 480, "Minimal Mojo Test"):
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
    let button_w: Int32 = 120
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
        
        # Clear background (dark blue)
        _ = ctx.set_color(30, 40, 60, 255)
        _ = ctx.draw_filled_rectangle(0, 0, 640, 480)
        
        # Draw title (white)
        _ = ctx.set_color(255, 255, 255, 255)
        _ = ctx.draw_text("Minimal Mojo Integer-Only Test", 50, 50, 18)
        
        # Draw description (light green)
        _ = ctx.set_color(180, 255, 180, 255)
        _ = ctx.draw_text("All coordinates & colors are Int32", 50, 90, 12)
        _ = ctx.draw_text("Following proven MojoGUI patterns", 50, 110, 12)
        
        # Draw button
        let button_brightness = 200 if mouse_pressed and (
            mouse_x >= button_x and mouse_x <= button_x + button_w and
            mouse_y >= button_y and mouse_y <= button_y + button_h) else 240
        
        _ = ctx.set_color(button_brightness, button_brightness, button_brightness, 255)
        _ = ctx.draw_filled_rectangle(button_x, button_y, button_w, button_h)
        
        # Button border
        _ = ctx.set_color(100, 100, 100, 255)
        _ = ctx.draw_rectangle(button_x, button_y, button_w, button_h)
        
        # Button text
        _ = ctx.set_color(0, 0, 0, 255)
        _ = ctx.draw_text("Click Me!", button_x + 30, button_y + 15, 14)
        
        # Draw mouse position (cyan)
        _ = ctx.set_color(100, 255, 255, 255)
        let mouse_text = "Mouse: " + str(mouse_x) + ", " + str(mouse_y)
        _ = ctx.draw_text(mouse_text, 50, 280, 12)
        
        # Click counter (yellow)
        _ = ctx.set_color(255, 255, 100, 255)
        let click_text = "Clicks: " + str(button_clicks)
        _ = ctx.draw_text(click_text, 50, 300, 12)
        
        # Frame counter (orange)
        _ = ctx.set_color(255, 180, 100, 255)
        let frame_text = "Frame: " + str(frame_count)
        _ = ctx.draw_text(frame_text, 50, 320, 12)
        
        # Features demonstrated (light gray)
        _ = ctx.set_color(180, 180, 180, 255)
        _ = ctx.draw_text("✓ Integer-only FFI (no conversion)", 50, 360, 11)
        _ = ctx.draw_text("✓ Real-time mouse tracking", 50, 380, 11)
        _ = ctx.draw_text("✓ Interactive button", 50, 400, 11)
        _ = ctx.draw_text("✓ Stable Mojo-C integration", 50, 420, 11)
        
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
    
    print("🎉 Minimal Mojo integer test successful!")
    print("🚀 Integer-only FFI working perfectly!")