"""
Working Integer-Only Mojo GUI Demo
Demonstrates the minimal FFI approach with pure integer coordinates.
This follows the proven pattern from the successful MojoGUI system.
"""

from mojo_src.rendering_int import RenderingContextInt, ColorInt
from mojo_src.widget_int import EventManagerInt
from mojo_src.widgets.textlabel_int import TextLabelInt, create_label_int, create_title_label_int
from mojo_src.widgets.button_int import ButtonInt, create_button_int, create_primary_button_int, create_success_button_int

fn main():
    """Working demo application using integer-only FFI."""
    print("🚀 Starting Working Integer-Only Mojo GUI Demo")
    print("Following proven patterns from successful MojoGUI system")
    
    # Initialize rendering context
    var ctx = RenderingContextInt()
    
    if not ctx.initialize(800, 600, "Working Integer-Only Demo"):
        print("❌ Failed to initialize rendering context")
        return
    
    print("✅ Integer-only rendering context initialized")
    
    # Load default font
    if not ctx.load_default_font():
        print("⚠️  Warning: Failed to load default font")
    else:
        print("✅ Font system ready")
    
    # Create widgets using integer coordinates
    var title = create_title_label_int(50, 30, 700, 40, "Integer-Only Mojo GUI Working!")
    title.text_color = ColorInt(255, 255, 255, 255)  # White text
    
    var desc1 = create_label_int(50, 90, 500, 25, "All coordinates and colors use Int32")
    desc1.text_color = ColorInt(180, 255, 180, 255)  # Light green
    
    var desc2 = create_label_int(50, 120, 500, 25, "No FFI type conversion issues")
    desc2.text_color = ColorInt(180, 255, 180, 255)
    
    var desc3 = create_label_int(50, 150, 500, 25, "Click buttons to test interaction:")
    desc3.text_color = ColorInt(255, 255, 180, 255)  # Light yellow
    
    # Create interactive buttons
    var normal_button = create_button_int(50, 190, 120, 35, "Click Me")
    var primary_button = create_primary_button_int(180, 190, 120, 35, "Primary")
    var success_button = create_success_button_int(310, 190, 120, 35, "Success")
    
    # Create status labels
    var status_label = create_label_int(50, 250, 200, 25, "Status:")
    status_label.text_color = ColorInt(255, 255, 180, 255)
    
    var click_status = create_label_int(50, 280, 600, 25, "Ready - Click buttons to test!")
    click_status.text_color = ColorInt(200, 200, 255, 255)  # Light blue
    
    # Mouse position display
    var mouse_label = create_label_int(50, 320, 200, 25, "Mouse Position:")
    mouse_label.text_color = ColorInt(255, 255, 180, 255)
    
    var mouse_coords = create_label_int(50, 350, 300, 25, "X: 0, Y: 0")
    mouse_coords.text_color = ColorInt(255, 180, 255, 255)  # Light magenta
    
    # Feature demonstration
    var features_label = create_label_int(50, 400, 300, 25, "Demonstrated Features:")
    features_label.text_color = ColorInt(255, 255, 180, 255)
    
    var feature1 = create_label_int(70, 430, 400, 20, "✓ Integer-only FFI (no conversion bugs)")
    feature1.text_color = ColorInt(180, 180, 180, 255)
    
    var feature2 = create_label_int(70, 455, 400, 20, "✓ Interactive buttons with state tracking")
    feature2.text_color = ColorInt(180, 180, 180, 255)
    
    var feature3 = create_label_int(70, 480, 400, 20, "✓ Real-time mouse position tracking")
    feature3.text_color = ColorInt(180, 180, 180, 255)
    
    var feature4 = create_label_int(70, 505, 400, 20, "✓ Multiple widget types working together")
    feature4.text_color = ColorInt(180, 180, 180, 255)
    
    # Create event manager
    var events = EventManagerInt()
    
    print("🎯 Starting integer-only render loop")
    print("💡 Click buttons and move mouse to test!")
    
    # Main render loop
    var frame_count: Int32 = 0
    var last_click_total: Int32 = 0
    
    while not ctx.should_close_window():
        # Update events
        events.update(ctx)
        
        # Handle mouse interaction with buttons
        let mouse_pos = events.get_mouse_position()
        let left_click = events.is_mouse_button_pressed(ctx, 0)
        
        # Create mouse event
        let mouse_event = MouseEventInt(mouse_pos.x, mouse_pos.y, 0, left_click)
        
        # Update button states
        _ = normal_button.handle_mouse_event(mouse_event)
        _ = primary_button.handle_mouse_event(mouse_event)
        _ = success_button.handle_mouse_event(mouse_event)
        
        # Update status display
        let total_clicks = normal_button.get_click_count() + primary_button.get_click_count() + success_button.get_click_count()
        if total_clicks != last_click_total:
            let status_text = "Clicks: Normal=" + str(normal_button.get_click_count()) + " Primary=" + str(primary_button.get_click_count()) + " Success=" + str(success_button.get_click_count())
            click_status.set_text(status_text)
            last_click_total = total_clicks
        
        # Update mouse coordinates display
        let coord_text = "X: " + str(mouse_pos.x) + ", Y: " + str(mouse_pos.y)
        mouse_coords.set_text(coord_text)
        
        # Begin frame
        if not ctx.frame_begin():
            print("❌ Failed to begin frame")
            break
        
        # Clear with dark blue background
        _ = ctx.set_color(25, 35, 50, 255)
        _ = ctx.draw_filled_rectangle(0, 0, 800, 600)
        
        # Render all widgets
        title.render(ctx)
        desc1.render(ctx)
        desc2.render(ctx)
        desc3.render(ctx)
        normal_button.render(ctx)
        primary_button.render(ctx)
        success_button.render(ctx)
        status_label.render(ctx)
        click_status.render(ctx)
        mouse_label.render(ctx)
        mouse_coords.render(ctx)
        features_label.render(ctx)
        feature1.render(ctx)
        feature2.render(ctx)
        feature3.render(ctx)
        feature4.render(ctx)
        
        # Draw mouse cursor indicator
        _ = ctx.set_color(255, 100, 100, 255)  # Red
        _ = ctx.draw_filled_circle(mouse_pos.x, mouse_pos.y, 3, 8)
        
        # Update widgets
        normal_button.update()
        primary_button.update()
        success_button.update()
        
        # End frame
        if not ctx.frame_end():
            print("❌ Failed to end frame")
            break
        
        frame_count += 1
        
        # Print status every 5 seconds
        if frame_count % 300 == 0:
            print("📊 Frame " + str(frame_count) + " - Integer GUI working! Clicks: " + str(total_clicks))
    
    print("🏁 Working demo completed after " + str(frame_count) + " frames")
    print("📊 Total button clicks: " + str(total_clicks))
    
    # Cleanup
    if not ctx.cleanup():
        print("⚠️  Warning: Failed to cleanup rendering context")
    else:
        print("✅ Cleanup completed")

if __name__ == "__main__":
    main()