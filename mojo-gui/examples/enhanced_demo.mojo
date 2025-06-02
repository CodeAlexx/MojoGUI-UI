"""
Enhanced Mojo GUI Demo
Demonstrates multiple widget types working together with the minimal FFI approach.
"""

import sys
from mojo_src.rendering import RenderingContext, Color
from mojo_src.widget import WidgetContainer, EventManager
from mojo_src.widgets.textlabel import TextLabel, create_label, create_title_label, create_subtitle_label
from mojo_src.widgets.button import Button, create_button, create_primary_button, create_success_button, create_danger_button

# Global state for demo
var click_count: Int = 0
var status_message: String = "Ready"

fn button_clicked():
    """Callback for button clicks."""
    global click_count, status_message
    click_count += 1
    status_message = "Button clicked " + str(click_count) + " times"

fn reset_clicked():
    """Callback for reset button."""
    global click_count, status_message
    click_count = 0
    status_message = "Counter reset"

fn success_clicked():
    """Callback for success button."""
    global status_message
    status_message = "Success action completed!"

fn danger_clicked():
    """Callback for danger button."""
    global status_message
    status_message = "Warning: Danger action executed!"

fn main():
    """Enhanced demo application."""
    print("🚀 Starting Enhanced Mojo GUI Demo")
    
    # Initialize rendering context
    var ctx = RenderingContext()
    
    if not ctx.initialize(900, 700, "Enhanced Mojo GUI Demo"):
        print("❌ Failed to initialize rendering context")
        return
    
    print("✅ Rendering context initialized")
    
    # Load default font
    if not ctx.load_default_font():
        print("⚠️  Warning: Failed to load default font")
    
    # Create root container
    var root = WidgetContainer(0.0, 0.0, 900.0, 700.0)
    root.set_visible(True)
    root.background_color = Color(0.12, 0.12, 0.18, 1.0)  # Dark theme
    
    # Create title
    var title = create_title_label(50.0, 30.0, 800.0, 50.0, "Enhanced Mojo GUI System")
    title.text_color = Color(1.0, 1.0, 1.0, 1.0)  # White
    title.font_size = 24.0
    
    # Create subtitle
    var subtitle = create_subtitle_label(50.0, 80.0, 800.0, 30.0, "Pure Mojo widgets with minimal C FFI")
    subtitle.text_color = Color(0.8, 0.8, 0.9, 1.0)  # Light purple
    
    # Create description labels
    var desc1 = create_label(50.0, 130.0, 700.0, 25.0, "• All widget logic implemented in pure Mojo")
    desc1.text_color = Color(0.7, 0.9, 0.7, 1.0)  # Light green
    
    var desc2 = create_label(50.0, 160.0, 700.0, 25.0, "• C library provides only OpenGL rendering primitives")
    desc2.text_color = Color(0.7, 0.9, 0.7, 1.0)
    
    var desc3 = create_label(50.0, 190.0, 700.0, 25.0, "• Minimal FFI reduces segfault risks")
    desc3.text_color = Color(0.7, 0.9, 0.7, 1.0)
    
    # Create interactive buttons section
    var button_label = create_subtitle_label(50.0, 240.0, 300.0, 30.0, "Interactive Buttons:")
    button_label.text_color = Color(1.0, 0.9, 0.5, 1.0)  # Yellow
    
    # Create different button styles
    var normal_button = create_button(50.0, 280.0, 120.0, 40.0, "Click Me")
    normal_button.set_click_callback(button_clicked)
    
    var primary_button = create_primary_button(180.0, 280.0, 120.0, 40.0, "Primary")
    primary_button.set_click_callback(button_clicked)
    
    var success_button = create_success_button(310.0, 280.0, 120.0, 40.0, "Success")
    success_button.set_click_callback(success_clicked)
    
    var danger_button = create_danger_button(440.0, 280.0, 120.0, 40.0, "Danger")
    danger_button.set_click_callback(danger_clicked)
    
    var reset_button = create_button(570.0, 280.0, 100.0, 40.0, "Reset")
    reset_button.set_click_callback(reset_clicked)
    reset_button.background_color = Color(0.6, 0.6, 0.6, 1.0)
    
    # Create status display
    var status_label = create_subtitle_label(50.0, 350.0, 200.0, 30.0, "Status:")
    status_label.text_color = Color(1.0, 0.9, 0.5, 1.0)  # Yellow
    
    var status_display = create_label(50.0, 380.0, 700.0, 30.0, status_message)
    status_display.text_color = Color(0.9, 0.9, 1.0, 1.0)  # Light blue
    status_display.font_size = 16.0
    
    # Create feature showcase section
    var features_label = create_subtitle_label(50.0, 430.0, 300.0, 30.0, "System Features:")
    features_label.text_color = Color(1.0, 0.9, 0.5, 1.0)  # Yellow
    
    var feature1 = create_label(70.0, 470.0, 600.0, 25.0, "✓ Event handling with mouse and keyboard support")
    feature1.text_color = Color(0.8, 0.8, 0.8, 1.0)
    
    var feature2 = create_label(70.0, 500.0, 600.0, 25.0, "✓ Widget hierarchies and containers")
    feature2.text_color = Color(0.8, 0.8, 0.8, 1.0)
    
    var feature3 = create_label(70.0, 530.0, 600.0, 25.0, "✓ Multiple widget types (Labels, Buttons, etc.)")
    feature3.text_color = Color(0.8, 0.8, 0.8, 1.0)
    
    var feature4 = create_label(70.0, 560.0, 600.0, 25.0, "✓ Type-safe Mojo implementation")
    feature4.text_color = Color(0.8, 0.8, 0.8, 1.0)
    
    var feature5 = create_label(70.0, 590.0, 600.0, 25.0, "✓ Customizable colors and styling")
    feature5.text_color = Color(0.8, 0.8, 0.8, 1.0)
    
    # Create footer
    var footer = create_label(50.0, 640.0, 700.0, 25.0, "Press ESC to exit | Move mouse over buttons to see hover effects")
    footer.text_color = Color(0.6, 0.6, 0.7, 1.0)
    footer.font_size = 12.0
    
    # Add all widgets to container
    root.add_child(title)
    root.add_child(subtitle)
    root.add_child(desc1)
    root.add_child(desc2)
    root.add_child(desc3)
    root.add_child(button_label)
    root.add_child(normal_button)
    root.add_child(primary_button)
    root.add_child(success_button)
    root.add_child(danger_button)
    root.add_child(reset_button)
    root.add_child(status_label)
    root.add_child(status_display)
    root.add_child(features_label)
    root.add_child(feature1)
    root.add_child(feature2)
    root.add_child(feature3)
    root.add_child(feature4)
    root.add_child(feature5)
    root.add_child(footer)
    
    # Create event manager
    var events = EventManager(root)
    
    print("🎯 Starting enhanced render loop")
    print("💡 Click buttons to test interactivity")
    
    # Main render loop
    var frame_count = 0
    while not ctx.should_close_window():
        # Update events
        events.update(ctx)
        
        # Update status display with current message
        status_display.set_text(status_message)
        
        # Begin frame
        if not ctx.frame_begin():
            print("❌ Failed to begin frame")
            break
        
        # Update and render widgets
        root.update()
        root.render(ctx)
        
        # Draw some background decorative elements
        # Animated corner accent
        let time_factor = frame_count * 0.02
        let accent_alpha = 0.1 + 0.05 * sin(time_factor)
        _ = ctx.set_color(0.3, 0.5, 0.9, accent_alpha)
        _ = ctx.draw_filled_circle(850.0, 650.0, 30.0, 16)
        
        # End frame
        if not ctx.frame_end():
            print("❌ Failed to end frame")
            break
        
        frame_count += 1
        
        # Print status every 5 seconds
        if frame_count % 300 == 0:
            print(f"📊 Frame {frame_count} - Enhanced widgets active | Clicks: {click_count}")
    
    print(f"🏁 Enhanced demo completed after {frame_count} frames")
    print(f"📊 Total button clicks: {click_count}")
    
    # Cleanup
    if not ctx.cleanup():
        print("⚠️  Warning: Failed to cleanup rendering context")
    else:
        print("✅ Cleanup completed")

if __name__ == "__main__":
    main()