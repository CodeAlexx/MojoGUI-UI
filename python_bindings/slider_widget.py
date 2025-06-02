#!/usr/bin/env python3
"""
Slider Widget Module
Dedicated module for slider widget functionality
"""

try:
    from .mid_level_wrappers import get_wrappers
except ImportError:
    from mid_level_wrappers import get_wrappers

class SliderWidget:
    """Slider widget implementation"""
    
    def __init__(self, x=0, y=0, width=200, height=20, orientation=0, min_val=0, max_val=100):
        self.wrappers = get_wrappers()
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.orientation = orientation  # 0=horizontal, 1=vertical
        self.min_value = min_val
        self.max_value = max_val
        self.value = min_val
        self.widget_id = -1
        self.visible = True
        self.enabled = True
        self.dragging = False
        self.on_change = None
        self.on_drag = None
        self.on_release = None
        
        # Create the slider
        self.create()
    
    def create(self):
        """Create the slider widget"""
        self.widget_id = self.wrappers.slider_create(
            self.x, self.y, self.width, self.height, self.orientation)
        
        if self.widget_id >= 0:
            self.set_range(self.min_value, self.max_value)
            self.set_value(self.value)
        
        return self.widget_id >= 0
    
    def destroy(self):
        """Destroy the slider widget"""
        if self.widget_id >= 0:
            result = self.wrappers.slider_destroy(self.widget_id)
            self.widget_id = -1
            return result == 0
        return False
    
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
        # Clamp value to range
        value = max(self.min_value, min(self.max_value, value))
        old_value = self.value
        self.value = value
        
        if self.widget_id >= 0:
            result = self.wrappers.slider_set_value(self.widget_id, value) == 0
            if result and value != old_value and self.on_change:
                self.on_change(self, value)
            return result
        return False
    
    def get_value(self):
        """Get slider value"""
        if self.widget_id >= 0:
            self.value = self.wrappers.slider_get_value(self.widget_id)
        return self.value
    
    def set_step(self, step):
        """Set slider step size"""
        if self.widget_id >= 0:
            return self.wrappers.slider_set_step(self.widget_id, step) == 0
        return False
    
    def handle_click(self, x, y):
        """Handle slider click"""
        if self.enabled and self.visible and self.widget_id >= 0:
            old_value = self.get_value()
            result = self.wrappers.slider_handle_click(self.widget_id, x, y)
            
            if result > 0:
                self.dragging = True
                new_value = self.get_value()
                if new_value != old_value and self.on_change:
                    self.on_change(self, new_value)
                return True
        return False
    
    def handle_drag(self, x, y):
        """Handle slider drag"""
        if self.dragging and self.enabled and self.visible and self.widget_id >= 0:
            old_value = self.get_value()
            result = self.wrappers.slider_handle_drag(self.widget_id, x, y)
            
            if result >= 0:
                new_value = self.get_value()
                if new_value != old_value:
                    if self.on_change:
                        self.on_change(self, new_value)
                    if self.on_drag:
                        self.on_drag(self, new_value)
                return True
        return False
    
    def handle_release(self):
        """Handle slider release"""
        if self.dragging:
            self.dragging = False
            if self.on_release:
                self.on_release(self, self.get_value())
            return True
        return False
    
    def handle_hover(self, x, y):
        """Handle slider hover"""
        if self.enabled and self.visible and self.widget_id >= 0:
            return self.wrappers.slider_handle_hover(self.widget_id, x, y) > 0
        return False
    
    def handle_key(self, key):
        """Handle slider key press"""
        if self.enabled and self.visible and self.widget_id >= 0:
            old_value = self.get_value()
            result = self.wrappers.slider_handle_key(self.widget_id, key)
            
            if result > 0:
                new_value = self.get_value()
                if new_value != old_value and self.on_change:
                    self.on_change(self, new_value)
                return True
        return False
    
    def set_focus(self, focused):
        """Set slider focus"""
        if self.widget_id >= 0:
            return self.wrappers.slider_set_focus(self.widget_id, focused) == 0
        return False
    
    def is_focused(self):
        """Check if slider is focused"""
        return self.wrappers.slider_get_focused() == self.widget_id
    
    def set_change_handler(self, handler):
        """Set change event handler"""
        self.on_change = handler
    
    def set_drag_handler(self, handler):
        """Set drag event handler"""
        self.on_drag = handler
    
    def set_release_handler(self, handler):
        """Set release event handler"""
        self.on_release = handler
    
    def is_point_inside(self, x, y):
        """Check if point is inside slider"""
        return (self.x <= x <= self.x + self.width and 
                self.y <= y <= self.y + self.height)
    
    def get_percentage(self):
        """Get slider value as percentage (0.0-1.0)"""
        if self.max_value == self.min_value:
            return 0.0
        return (self.value - self.min_value) / (self.max_value - self.min_value)
    
    def set_percentage(self, percentage):
        """Set slider value from percentage (0.0-1.0)"""
        percentage = max(0.0, min(1.0, percentage))
        value = self.min_value + percentage * (self.max_value - self.min_value)
        return self.set_value(int(value))
    
    def __del__(self):
        """Destructor"""
        self.destroy()

# Convenience functions that act as "middlemen" to the wrapper
def SliderCreate(x, y, width, height, orientation=0):
    """Create slider (middleman to wrapper)"""
    return SliderWidget(x, y, width, height, orientation)

def SliderCreateHorizontal(x, y, width, height=20):
    """Create horizontal slider (middleman to wrapper)"""
    return SliderWidget(x, y, width, height, 0)

def SliderCreateVertical(x, y, width=20, height=200):
    """Create vertical slider (middleman to wrapper)"""
    return SliderWidget(x, y, width, height, 1)

def SliderDraw(slider):
    """Draw slider (middleman to wrapper)"""
    if isinstance(slider, SliderWidget):
        return slider.draw()
    return False

def SliderSetRange(slider, min_val, max_val):
    """Set slider range (middleman to wrapper)"""
    if isinstance(slider, SliderWidget):
        return slider.set_range(min_val, max_val)
    return False

def SliderSetValue(slider, value):
    """Set slider value (middleman to wrapper)"""
    if isinstance(slider, SliderWidget):
        return slider.set_value(value)
    return False

def SliderGetValue(slider):
    """Get slider value (middleman to wrapper)"""
    if isinstance(slider, SliderWidget):
        return slider.get_value()
    return 0

def SliderSetStep(slider, step):
    """Set slider step (middleman to wrapper)"""
    if isinstance(slider, SliderWidget):
        return slider.set_step(step)
    return False

def SliderHandleClick(slider, x, y):
    """Handle slider click (middleman to wrapper)"""
    if isinstance(slider, SliderWidget):
        return slider.handle_click(x, y)
    return False

def SliderHandleDrag(slider, x, y):
    """Handle slider drag (middleman to wrapper)"""
    if isinstance(slider, SliderWidget):
        return slider.handle_drag(x, y)
    return False

def SliderHandleRelease(slider):
    """Handle slider release (middleman to wrapper)"""
    if isinstance(slider, SliderWidget):
        return slider.handle_release()
    return False

def SliderHandleKey(slider, key):
    """Handle slider key press (middleman to wrapper)"""
    if isinstance(slider, SliderWidget):
        return slider.handle_key(key)
    return False

def SliderDestroy(slider):
    """Destroy slider (middleman to wrapper)"""
    if isinstance(slider, SliderWidget):
        return slider.destroy()
    return False

# Direct wrapper access for advanced users
def get_slider_wrappers():
    """Get direct access to slider wrapper functions"""
    wrappers = get_wrappers()
    return {
        'create': wrappers.slider_create,
        'destroy': wrappers.slider_destroy,
        'draw': wrappers.draw_slider,
        'set_range': wrappers.slider_set_range,
        'set_value': wrappers.slider_set_value,
        'get_value': wrappers.slider_get_value,
        'set_step': wrappers.slider_set_step,
        'handle_click': wrappers.slider_handle_click,
        'handle_drag': wrappers.slider_handle_drag,
        'handle_hover': wrappers.slider_handle_hover,
        'handle_key': wrappers.slider_handle_key,
        'set_focus': wrappers.slider_set_focus,
        'get_focused': wrappers.slider_get_focused,
    }

if __name__ == "__main__":
    print("🎚️  Slider Widget Module")
    print("========================")
    
    # Test slider creation
    print("\n🧪 Testing slider creation:")
    h_slider = SliderCreateHorizontal(100, 100, 200, 20)
    v_slider = SliderCreateVertical(350, 100, 20, 200)
    
    print(f"   Horizontal slider created: {h_slider.widget_id >= 0}")
    print(f"   Vertical slider created: {v_slider.widget_id >= 0}")
    print(f"   H-Slider position: ({h_slider.x}, {h_slider.y})")
    print(f"   H-Slider size: {h_slider.width}x{h_slider.height}")
    print(f"   V-Slider orientation: {v_slider.orientation}")
    
    # Test slider operations
    print("\n🔧 Testing slider operations:")
    print(f"   Set range: {SliderSetRange(h_slider, 0, 100)}")
    print(f"   Initial value: {SliderGetValue(h_slider)}")
    print(f"   Set value 50: {SliderSetValue(h_slider, 50)}")
    print(f"   New value: {SliderGetValue(h_slider)}")
    print(f"   Set step: {SliderSetStep(h_slider, 5)}")
    
    # Test percentages
    print(f"   Current percentage: {h_slider.get_percentage():.2f}")
    print(f"   Set 75%: {h_slider.set_percentage(0.75)}")
    print(f"   New value: {SliderGetValue(h_slider)}")
    
    # Test event handlers
    print("\n🎯 Testing event handlers:")
    h_slider.set_change_handler(
        lambda slider, value: print(f"Slider value changed to: {value}")
    )
    h_slider.set_drag_handler(
        lambda slider, value: print(f"Dragging slider: {value}")
    )
    h_slider.set_release_handler(
        lambda slider, value: print(f"Released slider at: {value}")
    )
    
    print(f"   Change handler set: {h_slider.on_change is not None}")
    print(f"   Drag handler set: {h_slider.on_drag is not None}")
    print(f"   Release handler set: {h_slider.on_release is not None}")
    
    print(f"\n💡 Usage:")
    print(f"   slider = SliderCreateHorizontal(x, y, width)")
    print(f"   SliderSetRange(slider, 0, 100)")
    print(f"   SliderDraw(slider)")
    print(f"   if SliderHandleClick(slider, mouse_x, mouse_y):")
    print(f"       # Handle slider interaction")
    print(f"   while dragging:")
    print(f"       SliderHandleDrag(slider, mouse_x, mouse_y)")
    print(f"   SliderHandleRelease(slider)")