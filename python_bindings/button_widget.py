#!/usr/bin/env python3
"""
Button Widget Module
Dedicated module for button widget functionality
"""

try:
    from .mid_level_wrappers import get_wrappers
except ImportError:
    from mid_level_wrappers import get_wrappers

class ButtonWidget:
    """Button widget implementation"""
    
    def __init__(self, x=0, y=0, width=100, height=30, text="Button"):
        self.wrappers = get_wrappers()
        self.x = x
        self.y = y  
        self.width = width
        self.height = height
        self.text = text
        self.widget_id = -1
        self.visible = True
        self.enabled = True
        self.on_click = None
        self.on_hover = None
        
        # Create the button
        self.create()
    
    def create(self):
        """Create the button widget"""
        self.widget_id = self.wrappers.button_create(self.x, self.y, self.width, self.height, self.text)
        return self.widget_id >= 0
    
    def destroy(self):
        """Destroy the button widget"""
        if self.widget_id >= 0:
            result = self.wrappers.button_destroy(self.widget_id)
            self.widget_id = -1
            return result == 0
        return False
    
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
        self.enabled = enabled
        if self.widget_id >= 0:
            return self.wrappers.button_set_enabled(self.widget_id, enabled) == 0
        return False
    
    def set_visible(self, visible):
        """Set button visibility"""
        self.visible = visible
        if self.widget_id >= 0:
            return self.wrappers.button_set_visible(self.widget_id, visible) == 0
        return False
    
    def handle_click(self, x, y):
        """Handle button click"""
        if self.enabled and self.visible and self.widget_id >= 0:
            clicked = self.wrappers.button_handle_click(self.widget_id, x, y) > 0
            if clicked and self.on_click:
                self.on_click(self)
            return clicked
        return False
    
    def handle_hover(self, x, y):
        """Handle button hover"""
        if self.enabled and self.visible and self.widget_id >= 0:
            hovered = self.wrappers.button_handle_hover(self.widget_id, x, y) > 0
            if hovered and self.on_hover:
                self.on_hover(self)
            return hovered
        return False
    
    def set_click_handler(self, handler):
        """Set click event handler"""
        self.on_click = handler
    
    def set_hover_handler(self, handler):
        """Set hover event handler"""
        self.on_hover = handler
    
    def is_point_inside(self, x, y):
        """Check if point is inside button"""
        return (self.x <= x <= self.x + self.width and 
                self.y <= y <= self.y + self.height)
    
    def __del__(self):
        """Destructor"""
        self.destroy()

# Convenience functions that act as "middlemen" to the wrapper
def ButtonCreate(x, y, width, height, text="Button"):
    """Create button (middleman to wrapper)"""
    return ButtonWidget(x, y, width, height, text)

def ButtonDraw(button):
    """Draw button (middleman to wrapper)"""
    if isinstance(button, ButtonWidget):
        return button.draw()
    return False

def ButtonSetText(button, text):
    """Set button text (middleman to wrapper)"""
    if isinstance(button, ButtonWidget):
        return button.set_text(text)
    return False

def ButtonSetEnabled(button, enabled):
    """Set button enabled (middleman to wrapper)"""
    if isinstance(button, ButtonWidget):
        return button.set_enabled(enabled)
    return False

def ButtonSetVisible(button, visible):
    """Set button visible (middleman to wrapper)"""
    if isinstance(button, ButtonWidget):
        return button.set_visible(visible)
    return False

def ButtonHandleClick(button, x, y):
    """Handle button click (middleman to wrapper)"""
    if isinstance(button, ButtonWidget):
        return button.handle_click(x, y)
    return False

def ButtonDestroy(button):
    """Destroy button (middleman to wrapper)"""
    if isinstance(button, ButtonWidget):
        return button.destroy()
    return False

# Direct wrapper access for advanced users
def get_button_wrappers():
    """Get direct access to button wrapper functions"""
    wrappers = get_wrappers()
    return {
        'create': wrappers.button_create,
        'destroy': wrappers.button_destroy,
        'draw': wrappers.draw_button,
        'set_text': wrappers.button_set_text,
        'set_enabled': wrappers.button_set_enabled,
        'set_visible': wrappers.button_set_visible,
        'handle_click': wrappers.button_handle_click,
        'handle_hover': wrappers.button_handle_hover,
    }

if __name__ == "__main__":
    print("🔘 Button Widget Module")
    print("======================")
    
    # Test button creation
    print("\n🧪 Testing button creation:")
    button = ButtonCreate(100, 100, 120, 35, "Test Button")
    print(f"   Button created: {button.widget_id >= 0}")
    print(f"   Position: ({button.x}, {button.y})")
    print(f"   Size: {button.width}x{button.height}")
    print(f"   Text: '{button.text}'")
    
    # Test button operations
    print("\n🔧 Testing button operations:")
    print(f"   Set text: {ButtonSetText(button, 'Updated Text')}")
    print(f"   Set enabled: {ButtonSetEnabled(button, True)}")
    print(f"   Set visible: {ButtonSetVisible(button, True)}")
    
    # Test event handlers
    print("\n🎯 Testing event handlers:")
    button.set_click_handler(lambda btn: print(f"Button '{btn.text}' was clicked!"))
    button.set_hover_handler(lambda btn: print(f"Button '{btn.text}' is hovered!"))
    
    print(f"   Click handler set: {button.on_click is not None}")
    print(f"   Hover handler set: {button.on_hover is not None}")
    
    print(f"\n💡 Usage:")
    print(f"   button = ButtonCreate(x, y, width, height, 'text')")
    print(f"   ButtonDraw(button)")
    print(f"   if ButtonHandleClick(button, mouse_x, mouse_y):")
    print(f"       # Button was clicked")