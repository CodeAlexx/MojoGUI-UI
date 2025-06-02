#!/usr/bin/env python3
"""
High-Level MojoGUI API
Clean object-oriented interface for MojoGUI widgets
"""

try:
    from .mid_level_wrappers import get_wrappers
except ImportError:
    from mid_level_wrappers import get_wrappers

class MojoGUI:
    """Main MojoGUI application class"""
    
    def __init__(self):
        self.wrappers = get_wrappers()
        self.initialized = False
        self.widgets = []
    
    def init(self):
        """Initialize the GUI system"""
        result = self.wrappers.win_init()
        self.initialized = (result == 0)
        return self.initialized
    
    def set_window_size(self, width, height):
        """Set window size"""
        return self.wrappers.win_set_size(width, height) == 0
    
    def create_window(self):
        """Create the main window"""
        return self.wrappers.win_create() == 0
    
    def begin_frame(self):
        """Begin frame rendering"""
        return self.wrappers.frame_begin() == 0
    
    def end_frame(self):
        """End frame rendering"""
        return self.wrappers.frame_end() == 0
    
    def poll_events(self):
        """Poll for events"""
        return self.wrappers.event_poll() == 0
    
    def set_draw_color(self, r, g, b, a=1.0):
        """Set drawing color (0.0-1.0)"""
        return self.wrappers.draw_set_color(r, g, b, a) == 0
    
    def set_draw_position(self, x, y):
        """Set drawing position"""
        return self.wrappers.draw_set_pos(x, y) == 0
    
    def load_default_font(self):
        """Load default system font"""
        return self.wrappers.load_default_font()

class Widget:
    """Base widget class"""
    
    def __init__(self, x, y, width, height):
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.wrappers = get_wrappers()
        self.widget_id = -1
        self.visible = True
        self.enabled = True
    
    def set_position(self, x, y):
        """Set widget position"""
        self.x = x
        self.y = y
    
    def set_size(self, width, height):
        """Set widget size"""
        self.width = width
        self.height = height
    
    def set_visible(self, visible):
        """Set widget visibility"""
        self.visible = visible
    
    def set_enabled(self, enabled):
        """Set widget enabled state"""
        self.enabled = enabled
    
    def is_point_inside(self, x, y):
        """Check if point is inside widget bounds"""
        return (self.x <= x <= self.x + self.width and 
                self.y <= y <= self.y + self.height)

class Button(Widget):
    """Button widget class"""
    
    def __init__(self, x, y, width, height, text="Button"):
        super().__init__(x, y, width, height)
        self.text = text
        self.widget_id = self.wrappers.button_create(x, y, width, height, text)
        self.clicked = False
        self.on_click = None
    
    def __del__(self):
        """Destructor"""
        if self.widget_id >= 0:
            self.wrappers.button_destroy(self.widget_id)
    
    def draw(self):
        """Draw the button"""
        if self.visible and self.widget_id >= 0:
            return self.wrappers.draw_button(self.widget_id) == 0
        return False
    
    def set_text(self, text):
        """Set button text"""
        self.text = text
        if self.widget_id >= 0:
            return self.wrappers.button_set_text(self.widget_id, text) == 0
        return False
    
    def set_enabled(self, enabled):
        """Set button enabled state"""
        super().set_enabled(enabled)
        if self.widget_id >= 0:
            return self.wrappers.button_set_enabled(self.widget_id, enabled) == 0
        return False
    
    def set_visible(self, visible):
        """Set button visibility"""
        super().set_visible(visible)
        if self.widget_id >= 0:
            return self.wrappers.button_set_visible(self.widget_id, visible) == 0
        return False
    
    def handle_click(self, x, y):
        """Handle button click"""
        if self.enabled and self.visible and self.widget_id >= 0:
            clicked = self.wrappers.button_is_clicked(self.widget_id, x, y)
            if clicked and self.on_click:
                self.on_click(self)
            return clicked
        return False
    
    def set_click_handler(self, handler):
        """Set click event handler"""
        self.on_click = handler

class CheckBox(Widget):
    """CheckBox widget class"""
    
    def __init__(self, x, y, width, height, enhanced=False):
        super().__init__(x, y, width, height)
        self.checked = False
        self.enhanced = enhanced
        self.on_change = None
        
        if enhanced:
            self.widget_id = self.wrappers.enhanced_checkbox_create(x, y, width, height)
        else:
            self.widget_id = self.wrappers.checkbox_create(x, y, width, height)
    
    def __del__(self):
        """Destructor"""
        if self.widget_id >= 0:
            self.wrappers.checkbox_destroy(self.widget_id)
    
    def draw(self):
        """Draw the checkbox"""
        if self.visible and self.widget_id >= 0:
            if self.enhanced:
                return self.wrappers.draw_enhanced_checkbox(self.widget_id) == 0
            else:
                return self.wrappers.draw_checkbox(self.widget_id) == 0
        return False
    
    def set_checked(self, checked):
        """Set checkbox checked state"""
        self.checked = checked
        if self.widget_id >= 0:
            return self.wrappers.checkbox_set_state(self.widget_id, checked) == 0
        return False
    
    def is_checked(self):
        """Get checkbox checked state"""
        if self.widget_id >= 0:
            self.checked = self.wrappers.checkbox_get_state(self.widget_id)
        return self.checked
    
    def toggle(self):
        """Toggle checkbox state"""
        return self.set_checked(not self.is_checked())
    
    def handle_click(self, x, y):
        """Handle checkbox click"""
        if self.enabled and self.visible and self.widget_id >= 0:
            result = self.wrappers.checkbox_handle_click(self.widget_id, x, y)
            if result > 0:
                old_state = self.checked
                self.checked = self.is_checked()
                if self.checked != old_state and self.on_change:
                    self.on_change(self, self.checked)
                return True
        return False
    
    def set_change_handler(self, handler):
        """Set change event handler"""
        self.on_change = handler

class Slider(Widget):
    """Slider widget class"""
    
    def __init__(self, x, y, width, height, orientation=0, min_val=0, max_val=100):
        super().__init__(x, y, width, height)
        self.orientation = orientation  # 0=horizontal, 1=vertical
        self.min_value = min_val
        self.max_value = max_val
        self.value = min_val
        self.on_change = None
        self.dragging = False
        
        self.widget_id = self.wrappers.slider_create(x, y, width, height, orientation)
        if self.widget_id >= 0:
            self.wrappers.slider_set_range(self.widget_id, min_val, max_val)
            self.wrappers.slider_set_value(self.widget_id, min_val)
    
    def __del__(self):
        """Destructor"""
        if self.widget_id >= 0:
            self.wrappers.slider_destroy(self.widget_id)
    
    def draw(self):
        """Draw the slider"""
        if self.visible and self.widget_id >= 0:
            return self.wrappers.draw_slider(self.widget_id) == 0
        return False
    
    def set_range(self, min_val, max_val):
        """Set slider range"""
        self.min_value = min_val
        self.max_value = max_val
        if self.widget_id >= 0:
            return self.wrappers.slider_set_range(self.widget_id, min_val, max_val) == 0
        return False
    
    def set_value(self, value):
        """Set slider value"""
        value = max(self.min_value, min(self.max_value, value))
        self.value = value
        if self.widget_id >= 0:
            return self.wrappers.slider_set_value(self.widget_id, value) == 0
        return False
    
    def get_value(self):
        """Get slider value"""
        if self.widget_id >= 0:
            self.value = self.wrappers.slider_get_value(self.widget_id)
        return self.value
    
    def handle_click(self, x, y):
        """Handle slider click"""
        if self.enabled and self.visible and self.widget_id >= 0:
            result = self.wrappers.slider_handle_click(self.widget_id, x, y)
            if result > 0:
                self.dragging = True
                old_value = self.value
                self.value = self.get_value()
                if self.value != old_value and self.on_change:
                    self.on_change(self, self.value)
                return True
        return False
    
    def handle_drag(self, x, y):
        """Handle slider drag"""
        if self.dragging and self.enabled and self.visible and self.widget_id >= 0:
            result = self.wrappers.slider_handle_drag(self.widget_id, x, y)
            if result >= 0:
                old_value = self.value
                self.value = self.get_value()
                if self.value != old_value and self.on_change:
                    self.on_change(self, self.value)
                return True
        return False
    
    def handle_release(self):
        """Handle slider release"""
        self.dragging = False
    
    def set_change_handler(self, handler):
        """Set change event handler"""
        self.on_change = handler

class ProgressBar(Widget):
    """ProgressBar widget class"""
    
    def __init__(self, x, y, width, height, style=0):
        super().__init__(x, y, width, height)
        self.value = 0.0
        self.min_value = 0.0
        self.max_value = 100.0
        self.label_text = ""
        
        self.widget_id = self.wrappers.progressbar_create(x, y, width, height, style)
    
    def __del__(self):
        """Destructor"""
        if self.widget_id >= 0:
            self.wrappers.progressbar_destroy(self.widget_id)
    
    def draw(self):
        """Draw the progress bar"""
        if self.visible and self.widget_id >= 0:
            return self.wrappers.draw_progressbar(self.widget_id) == 0
        return False
    
    def set_value(self, value):
        """Set progress bar value (0-100)"""
        self.value = max(0, min(100, value))
        if self.widget_id >= 0:
            return self.wrappers.progressbar_set_value(self.widget_id, self.value) == 0
        return False
    
    def get_value(self):
        """Get progress bar value"""
        if self.widget_id >= 0:
            self.value = self.wrappers.progressbar_get_value(self.widget_id)
        return self.value
    
    def set_label(self, text):
        """Set progress bar label"""
        self.label_text = text
        if self.widget_id >= 0:
            return self.wrappers.progressbar_set_label(self.widget_id, text) == 0
        return False
    
    def increment(self, amount=1):
        """Increment progress bar value"""
        return self.set_value(self.value + amount)

class Label(Widget):
    """Label widget class"""
    
    def __init__(self, x, y, width, height, text="Label"):
        super().__init__(x, y, width, height)
        self.text = text
        
        self.widget_id = self.wrappers.label_create(x, y, width, height, text)
    
    def __del__(self):
        """Destructor"""
        if self.widget_id >= 0:
            self.wrappers.label_destroy(self.widget_id)
    
    def draw(self):
        """Draw the label"""
        if self.visible and self.widget_id >= 0:
            return self.wrappers.draw_label(self.widget_id) == 0
        return False
    
    def set_text(self, text):
        """Set label text"""
        self.text = text
        if self.widget_id >= 0:
            return self.wrappers.label_set_text(self.widget_id, text) == 0
        return False
    
    def set_visible(self, visible):
        """Set label visibility"""
        super().set_visible(visible)
        if self.widget_id >= 0:
            return self.wrappers.label_set_visible(self.widget_id, visible) == 0
        return False

class Canvas:
    """Drawing canvas for custom graphics"""
    
    def __init__(self, gui):
        self.gui = gui
        self.wrappers = gui.wrappers
    
    def set_color(self, r, g, b, a=1.0):
        """Set drawing color"""
        return self.wrappers.draw_set_color(r, g, b, a) == 0
    
    def set_position(self, x, y):
        """Set drawing position"""
        return self.wrappers.draw_set_pos(x, y) == 0
    
    def draw_rect(self, x, y, width, height):
        """Draw rectangle"""
        self.set_position(x, y)
        return self.wrappers.draw_rect(width, height) == 0
    
    def draw_rounded_rect(self, x, y, width, height, radius):
        """Draw rounded rectangle"""
        self.set_position(x, y)
        return self.wrappers.draw_rounded_rect(width, height, radius) == 0
    
    def draw_circle(self, x, y, radius, segments=32):
        """Draw circle"""
        self.set_position(x, y)
        return self.wrappers.draw_circle(radius, segments) == 0
    
    def draw_line(self, x1, y1, x2, y2):
        """Draw line"""
        return self.wrappers.draw_line(x1, y1, x2, y2) == 0
    
    def draw_gradient_rect(self, x, y, width, height, color1, color2):
        """Draw gradient rectangle"""
        self.set_position(x, y)
        r1, g1, b1, a1 = color1
        r2, g2, b2, a2 = color2
        return self.wrappers.draw_gradient_rect(width, height, r1, g1, b1, a1, r2, g2, b2, a2) == 0

class Application:
    """Main application class - the highest level interface"""
    
    def __init__(self, title="MojoGUI App", width=800, height=600):
        self.title = title
        self.width = width
        self.height = height
        self.gui = MojoGUI()
        self.canvas = Canvas(self.gui)
        self.widgets = []
        self.running = False
        self.mouse_x = 0
        self.mouse_y = 0
        self.mouse_pressed = False
    
    def init(self):
        """Initialize the application"""
        if not self.gui.init():
            return False
        
        if not self.gui.set_window_size(self.width, self.height):
            return False
        
        if not self.gui.create_window():
            return False
        
        # Load default font
        font_id = self.gui.load_default_font()
        
        self.running = True
        return True
    
    def add_widget(self, widget):
        """Add a widget to the application"""
        self.widgets.append(widget)
        return widget
    
    def create_button(self, x, y, width, height, text="Button"):
        """Create and add a button"""
        button = Button(x, y, width, height, text)
        return self.add_widget(button)
    
    def create_checkbox(self, x, y, width, height, enhanced=False):
        """Create and add a checkbox"""
        checkbox = CheckBox(x, y, width, height, enhanced)
        return self.add_widget(checkbox)
    
    def create_slider(self, x, y, width, height, orientation=0, min_val=0, max_val=100):
        """Create and add a slider"""
        slider = Slider(x, y, width, height, orientation, min_val, max_val)
        return self.add_widget(slider)
    
    def create_progressbar(self, x, y, width, height, style=0):
        """Create and add a progress bar"""
        progressbar = ProgressBar(x, y, width, height, style)
        return self.add_widget(progressbar)
    
    def create_label(self, x, y, width, height, text="Label"):
        """Create and add a label"""
        label = Label(x, y, width, height, text)
        return self.add_widget(label)
    
    def handle_mouse_click(self, x, y):
        """Handle mouse click events"""
        self.mouse_x = x
        self.mouse_y = y
        self.mouse_pressed = True
        
        # Process widgets in reverse order (top to bottom)
        for widget in reversed(self.widgets):
            if hasattr(widget, 'handle_click'):
                if widget.handle_click(x, y):
                    break  # Stop after first widget handles the click
    
    def handle_mouse_drag(self, x, y):
        """Handle mouse drag events"""
        self.mouse_x = x
        self.mouse_y = y
        
        if self.mouse_pressed:
            for widget in self.widgets:
                if hasattr(widget, 'handle_drag'):
                    widget.handle_drag(x, y)
    
    def handle_mouse_release(self, x, y):
        """Handle mouse release events"""
        self.mouse_x = x
        self.mouse_y = y
        self.mouse_pressed = False
        
        for widget in self.widgets:
            if hasattr(widget, 'handle_release'):
                widget.handle_release()
    
    def update(self):
        """Update application state"""
        # Poll events
        self.gui.poll_events()
        
        # Update widgets
        for widget in self.widgets:
            if hasattr(widget, 'update'):
                widget.update()
    
    def render(self):
        """Render the application"""
        if not self.gui.begin_frame():
            return False
        
        # Draw all widgets
        for widget in self.widgets:
            widget.draw()
        
        if not self.gui.end_frame():
            return False
        
        return True
    
    def run_frame(self):
        """Run a single frame"""
        self.update()
        return self.render()
    
    def quit(self):
        """Quit the application"""
        self.running = False

# Convenience functions for quick setup
def create_app(title="MojoGUI App", width=800, height=600):
    """Create and initialize a new application"""
    app = Application(title, width, height)
    if app.init():
        return app
    return None

def quick_demo():
    """Create a quick demo application"""
    app = create_app("MojoGUI Demo", 800, 600)
    if not app:
        print("Failed to create application")
        return None
    
    # Add some widgets
    button1 = app.create_button(50, 50, 100, 30, "Click Me")
    button1.set_click_handler(lambda btn: print(f"Button '{btn.text}' clicked!"))
    
    checkbox1 = app.create_checkbox(50, 100, 20, 20)
    checkbox1.set_change_handler(lambda cb, checked: print(f"Checkbox state: {checked}"))
    
    slider1 = app.create_slider(50, 150, 200, 20, 0, 0, 100)
    slider1.set_change_handler(lambda sl, value: print(f"Slider value: {value}"))
    
    progress1 = app.create_progressbar(50, 200, 200, 20)
    progress1.set_value(50)
    
    label1 = app.create_label(50, 250, 200, 20, "Hello MojoGUI!")
    
    return app

if __name__ == "__main__":
    print("🎨 MojoGUI High-Level API")
    print("========================")
    
    print("\n💡 Usage Examples:")
    print("   # Simple approach:")
    print("   app = create_app('My App', 800, 600)")
    print("   button = app.create_button(100, 100, 80, 30, 'Click')")
    print("   # Run frames...")
    print()
    print("   # Or use quick demo:")
    print("   app = quick_demo()")
    print("   # Run frames...")
    print()
    print("   # Manual approach:")
    print("   gui = MojoGUI()")
    print("   gui.init()")
    print("   button = Button(100, 100, 80, 30, 'Click')")
    print("   # Manage manually...")