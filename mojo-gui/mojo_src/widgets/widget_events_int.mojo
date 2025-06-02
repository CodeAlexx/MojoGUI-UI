"""
Enhanced event structures for Mojo GUI widgets with modifier key support
"""

from .widget_constants import *

struct MouseEventInt:
    """Enhanced mouse event data with modifiers."""
    var x: Int32
    var y: Int32
    var button: Int32
    var pressed: Bool
    var clicks: Int32  # For double-click detection
    var wheel_delta: Int32  # For mouse wheel
    var shift_held: Bool
    var ctrl_held: Bool
    var alt_held: Bool
    var super_held: Bool  # Windows/Command key
    
    fn __init__(inout self, x: Int32, y: Int32, button: Int32, pressed: Bool):
        self.x = x
        self.y = y
        self.button = button
        self.pressed = pressed
        self.clicks = 1
        self.wheel_delta = 0
        self.shift_held = False
        self.ctrl_held = False
        self.alt_held = False
        self.super_held = False
    
    fn with_modifiers(inout self, shift: Bool, ctrl: Bool, alt: Bool, super_key: Bool) -> Self:
        """Set modifier keys."""
        self.shift_held = shift
        self.ctrl_held = ctrl
        self.alt_held = alt
        self.super_held = super_key
        return self
    
    fn is_double_click(self) -> Bool:
        """Check if this is a double-click event."""
        return self.clicks == 2 and self.pressed
    
    fn is_right_click(self) -> Bool:
        """Check if this is a right-click event."""
        return self.button == MOUSE_BUTTON_RIGHT and self.pressed
    
    fn has_modifier(self) -> Bool:
        """Check if any modifier key is held."""
        return self.shift_held or self.ctrl_held or self.alt_held or self.super_held

struct KeyEventInt:
    """Enhanced keyboard event data with modifiers."""
    var key_code: Int32
    var char_code: Int32  # Unicode character code
    var pressed: Bool
    var repeated: Bool    # Key auto-repeat
    var shift_held: Bool
    var ctrl_held: Bool
    var alt_held: Bool
    var super_held: Bool
    
    fn __init__(inout self, key_code: Int32, pressed: Bool):
        self.key_code = key_code
        self.char_code = 0
        self.pressed = pressed
        self.repeated = False
        self.shift_held = False
        self.ctrl_held = False
        self.alt_held = False
        self.super_held = False
    
    fn with_modifiers(inout self, shift: Bool, ctrl: Bool, alt: Bool, super_key: Bool) -> Self:
        """Set modifier keys."""
        self.shift_held = shift
        self.ctrl_held = ctrl
        self.alt_held = alt
        self.super_held = super_key
        return self
    
    fn with_char(inout self, char_code: Int32) -> Self:
        """Set character code."""
        self.char_code = char_code
        return self
    
    fn is_printable(self) -> Bool:
        """Check if this key produces a printable character."""
        return self.char_code >= 32 and self.char_code <= 126
    
    fn is_navigation_key(self) -> Bool:
        """Check if this is a navigation key."""
        return self.key_code in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT,
                                KEY_HOME, KEY_END, KEY_PAGE_UP, KEY_PAGE_DOWN]
    
    fn is_editing_key(self) -> Bool:
        """Check if this is an editing key."""
        return self.key_code in [KEY_BACKSPACE, KEY_DELETE, KEY_INSERT,
                                KEY_ENTER, KEY_TAB]
    
    fn get_modifier_mask(self) -> Int32:
        """Get modifier key mask."""
        var mask = 0
        if self.shift_held:
            mask |= KEY_MOD_SHIFT
        if self.ctrl_held:
            mask |= KEY_MOD_CTRL
        if self.alt_held:
            mask |= KEY_MOD_ALT
        if self.super_held:
            mask |= KEY_MOD_SUPER
        return mask

struct FocusEventInt:
    """Focus event data."""
    var gained: Bool  # True if gaining focus, False if losing
    var reason: Int32  # Reason for focus change (tab, click, etc.)
    
    fn __init__(inout self, gained: Bool, reason: Int32 = 0):
        self.gained = gained
        self.reason = reason

struct ResizeEventInt:
    """Window/widget resize event."""
    var old_width: Int32
    var old_height: Int32
    var new_width: Int32
    var new_height: Int32
    
    fn __init__(inout self, old_width: Int32, old_height: Int32,
                new_width: Int32, new_height: Int32):
        self.old_width = old_width
        self.old_height = old_height
        self.new_width = new_width
        self.new_height = new_height
    
    fn width_changed(self) -> Bool:
        return self.old_width != self.new_width
    
    fn height_changed(self) -> Bool:
        return self.old_height != self.new_height

struct DragDropEventInt:
    """Drag and drop event data."""
    var x: Int32
    var y: Int32
    var action: Int32  # Drag start, move, drop, etc.
    var data_type: String
    var data: String  # Simplified - would be more complex in real implementation
    
    fn __init__(inout self, x: Int32, y: Int32, action: Int32):
        self.x = x
        self.y = y
        self.action = action
        self.data_type = ""
        self.data = ""

# Event action types for drag/drop
alias DRAG_START = 0
alias DRAG_MOVE = 1
alias DRAG_DROP = 2
alias DRAG_ENTER = 3
alias DRAG_LEAVE = 4
alias DRAG_CANCEL = 5

# Focus change reasons
alias FOCUS_TAB = 0
alias FOCUS_BACKTAB = 1
alias FOCUS_CLICK = 2
alias FOCUS_WHEEL = 3
alias FOCUS_PROGRAMMATIC = 4

# Helper functions for creating events
fn create_click_event(x: Int32, y: Int32, button: Int32 = MOUSE_BUTTON_LEFT) -> MouseEventInt:
    """Create a mouse click event."""
    return MouseEventInt(x, y, button, True)

fn create_key_press(key_code: Int32) -> KeyEventInt:
    """Create a key press event."""
    return KeyEventInt(key_code, True)

fn create_key_release(key_code: Int32) -> KeyEventInt:
    """Create a key release event."""
    return KeyEventInt(key_code, False)

fn create_char_input(char_code: Int32) -> KeyEventInt:
    """Create a character input event."""
    var event = KeyEventInt(0, True)
    event.char_code = char_code
    return event

# Helper to convert character to key code
fn char_to_keycode(ch: String) -> Int32:
    """Convert character to key code."""
    if len(ch) == 0:
        return 0
    
    let c = ord(ch[0])
    
    # Letters (convert to uppercase key codes)
    if c >= ord('a') and c <= ord('z'):
        return c - ord('a') + ord('A')
    elif c >= ord('A') and c <= ord('Z'):
        return c
    # Numbers and special characters
    else:
        return c