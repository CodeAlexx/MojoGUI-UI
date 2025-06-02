#!/usr/bin/env python3
"""
CheckBox Widget Module  
Dedicated module for checkbox widget functionality
"""

try:
    from .mid_level_wrappers import get_wrappers
except ImportError:
    from mid_level_wrappers import get_wrappers

class CheckBoxWidget:
    """CheckBox widget implementation"""
    
    def __init__(self, x=0, y=0, width=20, height=20, enhanced=False):
        self.wrappers = get_wrappers()
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.enhanced = enhanced
        self.widget_id = -1
        self.checked = False
        self.visible = True
        self.enabled = True
        self.on_change = None
        self.label_text = ""
        
        # Create the checkbox
        self.create()
    
    def create(self):
        """Create the checkbox widget"""
        if self.enhanced:
            self.widget_id = self.wrappers.enhanced_checkbox_create(
                self.x, self.y, self.width, self.height, 0)
        else:
            self.widget_id = self.wrappers.checkbox_create(
                self.x, self.y, self.width, self.height)
        return self.widget_id >= 0
    
    def destroy(self):
        """Destroy the checkbox widget"""
        if self.widget_id >= 0:
            result = self.wrappers.checkbox_destroy(self.widget_id)
            self.widget_id = -1
            return result == 0
        return False
    
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
        old_checked = self.checked
        self.checked = checked
        if self.widget_id >= 0:
            if self.enhanced:
                result = self.wrappers.enhanced_checkbox_set_state(self.widget_id, checked) == 0
            else:
                result = self.wrappers.checkbox_set_state(self.widget_id, checked) == 0
            
            if result and self.checked != old_checked and self.on_change:
                self.on_change(self, self.checked)
            return result
        return False
    
    def is_checked(self):
        """Get checkbox checked state"""
        if self.widget_id >= 0:
            if self.enhanced:
                self.checked = self.wrappers.enhanced_checkbox_get_state(self.widget_id)
            else:
                self.checked = self.wrappers.checkbox_get_state(self.widget_id)
        return self.checked
    
    def toggle(self):
        """Toggle checkbox state"""
        return self.set_checked(not self.is_checked())
    
    def set_label(self, text):
        """Set checkbox label text"""
        self.label_text = text
        if self.widget_id >= 0:
            if self.enhanced:
                return self.wrappers.enhanced_checkbox_set_label(self.widget_id, text, 0) == 0
            else:
                return self.wrappers.checkbox_set_label(self.widget_id, text, 0) == 0
        return False
    
    def handle_click(self, x, y):
        """Handle checkbox click"""
        if self.enabled and self.visible and self.widget_id >= 0:
            old_checked = self.is_checked()
            
            if self.enhanced:
                result = self.wrappers.enhanced_checkbox_handle_click(self.widget_id, x, y)
            else:
                result = self.wrappers.checkbox_handle_click(self.widget_id, x, y)
            
            if result > 0:
                new_checked = self.is_checked()
                if new_checked != old_checked and self.on_change:
                    self.on_change(self, new_checked)
                return True
        return False
    
    def handle_key(self, key):
        """Handle checkbox key press"""
        if self.enabled and self.visible and self.widget_id >= 0:
            if self.enhanced:
                return self.wrappers.enhanced_checkbox_handle_key(self.widget_id, key) > 0
            else:
                return self.wrappers.checkbox_handle_key(self.widget_id, key) > 0
        return False
    
    def set_change_handler(self, handler):
        """Set change event handler"""
        self.on_change = handler
    
    def is_point_inside(self, x, y):
        """Check if point is inside checkbox"""
        return (self.x <= x <= self.x + self.width and 
                self.y <= y <= self.y + self.height)
    
    def __del__(self):
        """Destructor"""
        self.destroy()

# Convenience functions that act as "middlemen" to the wrapper
def CheckBoxCreate(x, y, width, height, enhanced=False):
    """Create checkbox (middleman to wrapper)"""
    return CheckBoxWidget(x, y, width, height, enhanced)

def EnhancedCheckBoxCreate(x, y, width, height, style=0):
    """Create enhanced checkbox (middleman to wrapper)"""
    return CheckBoxWidget(x, y, width, height, enhanced=True)

def CheckBoxDraw(checkbox):
    """Draw checkbox (middleman to wrapper)"""
    if isinstance(checkbox, CheckBoxWidget):
        return checkbox.draw()
    return False

def CheckBoxSetState(checkbox, checked):
    """Set checkbox state (middleman to wrapper)"""
    if isinstance(checkbox, CheckBoxWidget):
        return checkbox.set_checked(checked)
    return False

def CheckBoxGetState(checkbox):
    """Get checkbox state (middleman to wrapper)"""
    if isinstance(checkbox, CheckBoxWidget):
        return checkbox.is_checked()
    return False

def CheckBoxToggle(checkbox):
    """Toggle checkbox state (middleman to wrapper)"""
    if isinstance(checkbox, CheckBoxWidget):
        return checkbox.toggle()
    return False

def CheckBoxSetLabel(checkbox, text):
    """Set checkbox label (middleman to wrapper)"""
    if isinstance(checkbox, CheckBoxWidget):
        return checkbox.set_label(text)
    return False

def CheckBoxHandleClick(checkbox, x, y):
    """Handle checkbox click (middleman to wrapper)"""
    if isinstance(checkbox, CheckBoxWidget):
        return checkbox.handle_click(x, y)
    return False

def CheckBoxHandleKey(checkbox, key):
    """Handle checkbox key press (middleman to wrapper)"""
    if isinstance(checkbox, CheckBoxWidget):
        return checkbox.handle_key(key)
    return False

def CheckBoxDestroy(checkbox):
    """Destroy checkbox (middleman to wrapper)"""
    if isinstance(checkbox, CheckBoxWidget):
        return checkbox.destroy()
    return False

# Direct wrapper access for advanced users
def get_checkbox_wrappers():
    """Get direct access to checkbox wrapper functions"""
    wrappers = get_wrappers()
    return {
        'create': wrappers.checkbox_create,
        'enhanced_create': wrappers.enhanced_checkbox_create,
        'destroy': wrappers.checkbox_destroy,
        'draw': wrappers.draw_checkbox,
        'draw_enhanced': wrappers.draw_enhanced_checkbox,
        'set_state': wrappers.checkbox_set_state,
        'get_state': wrappers.checkbox_get_state,
        'enhanced_set_state': wrappers.enhanced_checkbox_set_state,
        'enhanced_get_state': wrappers.enhanced_checkbox_get_state,
        'set_label': wrappers.checkbox_set_label,
        'enhanced_set_label': wrappers.enhanced_checkbox_set_label,
        'handle_click': wrappers.checkbox_handle_click,
        'enhanced_handle_click': wrappers.enhanced_checkbox_handle_click,
        'handle_key': wrappers.checkbox_handle_key,
        'enhanced_handle_key': wrappers.enhanced_checkbox_handle_key,
    }

if __name__ == "__main__":
    print("☑️  CheckBox Widget Module")
    print("=========================")
    
    # Test checkbox creation
    print("\n🧪 Testing checkbox creation:")
    checkbox1 = CheckBoxCreate(100, 100, 20, 20, False)
    checkbox2 = EnhancedCheckBoxCreate(100, 130, 20, 20, 0)
    
    print(f"   Standard checkbox created: {checkbox1.widget_id >= 0}")
    print(f"   Enhanced checkbox created: {checkbox2.widget_id >= 0}")
    print(f"   Position: ({checkbox1.x}, {checkbox1.y})")
    print(f"   Size: {checkbox1.width}x{checkbox1.height}")
    
    # Test checkbox operations
    print("\n🔧 Testing checkbox operations:")
    print(f"   Initial state: {CheckBoxGetState(checkbox1)}")
    print(f"   Set checked: {CheckBoxSetState(checkbox1, True)}")
    print(f"   New state: {CheckBoxGetState(checkbox1)}")
    print(f"   Toggle: {CheckBoxToggle(checkbox1)}")
    print(f"   Final state: {CheckBoxGetState(checkbox1)}")
    
    # Test labels
    print(f"   Set label: {CheckBoxSetLabel(checkbox1, 'Enable feature')}")
    print(f"   Set enhanced label: {CheckBoxSetLabel(checkbox2, 'Advanced option')}")
    
    # Test event handlers
    print("\n🎯 Testing event handlers:")
    checkbox1.set_change_handler(
        lambda cb, checked: print(f"Checkbox state changed to: {checked}")
    )
    checkbox2.set_change_handler(
        lambda cb, checked: print(f"Enhanced checkbox state changed to: {checked}")
    )
    
    print(f"   Change handler set: {checkbox1.on_change is not None}")
    print(f"   Enhanced change handler set: {checkbox2.on_change is not None}")
    
    print(f"\n💡 Usage:")
    print(f"   checkbox = CheckBoxCreate(x, y, width, height)")
    print(f"   CheckBoxDraw(checkbox)")
    print(f"   if CheckBoxHandleClick(checkbox, mouse_x, mouse_y):")
    print(f"       state = CheckBoxGetState(checkbox)")
    print(f"       # Checkbox state changed")