"""
Simple Mojo GUI Demo
Demonstrates the minimal FFI approach with pure Mojo widgets.
"""

import sys
from mojo_src.rendering import RenderingContext, Color
from mojo_src.widget import WidgetContainer, EventManager
from mojo_src.widgets.textlabel import TextLabel, create_label, create_title_label

fn main():
    """Main demo application."""
    print("🚀 Starting Mojo GUI Demo")
    
    # Initialize rendering context
    var ctx = RenderingContext()
    
    if not ctx.initialize(800, 600, "Mojo GUI Demo"):
        print("❌ Failed to initialize rendering context")
        return
    
    print("✅ Rendering context initialized")
    
    # Load default font
    if not ctx.load_default_font():
        print("⚠️  Warning: Failed to load default font")
    
    # Create root container
    var root = WidgetContainer(0.0, 0.0, 800.0, 600.0)
    root.set_visible(True)
    root.background_color = Color(0.15, 0.15, 0.25, 1.0)  # Dark blue background
    
    # Create title label
    var title = create_title_label(50.0, 50.0, 700.0, 40.0, "Welcome to Mojo GUI!")
    title.text_color = Color(1.0, 1.0, 1.0, 1.0)  # White text
    
    # Create some demo labels
    var label1 = create_label(50.0, 120.0, 300.0, 30.0, "This is a text label")
    label1.text_color = Color(0.9, 0.9, 0.9, 1.0)
    
    var label2 = create_label(50.0, 160.0, 300.0, 30.0, "Pure Mojo widget system")
    label2.text_color = Color(0.7, 0.9, 0.7, 1.0)  # Light green
    
    var label3 = create_label(50.0, 200.0, 400.0, 30.0, "Minimal C FFI for OpenGL only")
    label3.text_color = Color(0.9, 0.7, 0.7, 1.0)  # Light red
    
    # Add widgets to container
    root.add_child(title)
    root.add_child(label1)
    root.add_child(label2)
    root.add_child(label3)
    
    # Create event manager
    var events = EventManager(root)
    
    print("🎯 Starting render loop")
    
    # Main render loop
    var frame_count = 0
    while not ctx.should_close_window():
        # Update events
        events.update(ctx)
        
        # Begin frame
        if not ctx.frame_begin():
            print("❌ Failed to begin frame")
            break
        
        # Update and render widgets
        root.update()
        root.render(ctx)
        
        # End frame
        if not ctx.frame_end():
            print("❌ Failed to end frame")
            break
        
        frame_count += 1
        
        # Print status every 60 frames
        if frame_count % 60 == 0:
            print("📊 Frame", frame_count, "- Widgets rendering successfully")
    
    print("🏁 Demo completed after", frame_count, "frames")
    
    # Cleanup
    if not ctx.cleanup():
        print("⚠️  Warning: Failed to cleanup rendering context")
    else:
        print("✅ Cleanup completed")

if __name__ == "__main__":
    main()