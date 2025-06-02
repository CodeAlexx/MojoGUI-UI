#!/usr/bin/env mojo
"""
SpinBox/NumericUpDown Widget - Integer-Only API
Professional numeric input with up/down buttons, constraints, and precision control
"""

from sys.ffi import DLHandle, DLSymbol
from memory import UnsafePointer
from ..widget_int import BaseWidgetInt

# SpinBox types
alias SPINBOX_INTEGER: Int32 = 0
alias SPINBOX_FLOAT: Int32 = 1

# Events
alias EVENT_SPINBOX_VALUE_CHANGED: Int32 = 1001

struct SpinBoxInt(BaseWidgetInt):
    """
    Professional SpinBox widget with up/down buttons for numeric input
    Supports both integer and floating-point values with precision control
    """
    var spinbox_type: Int32
    var value: Int32           # Value * 1000 for float precision
    var min_value: Int32       # Min * 1000 for float precision  
    var max_value: Int32       # Max * 1000 for float precision
    var step: Int32            # Step * 1000 for float precision
    var precision: Int32       # Decimal places for float display
    var button_width: Int32
    var editing: Bool
    var cursor_pos: Int32
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, 
               spinbox_type: Int32 = SPINBOX_INTEGER):
        """Initialize SpinBox with position, size and type"""
        self.spinbox_type = spinbox_type
        self.value = 0
        self.min_value = -2147483000  # Large negative for range
        self.max_value = 2147483000   # Large positive for range
        self.step = 1000 if spinbox_type == SPINBOX_FLOAT else 1
        self.precision = 3 if spinbox_type == SPINBOX_FLOAT else 0
        self.button_width = 20
        self.editing = False
        self.cursor_pos = 0
        super().__init__(x, y, width, height, "spinbox")

    fn set_value(inout self, value: Int32):
        """Set spinbox value (for integers) or value*1000 (for floats)"""
        var clamped_value = value
        if clamped_value < self.min_value:
            clamped_value = self.min_value
        if clamped_value > self.max_value:
            clamped_value = self.max_value
            
        # Round to step
        if self.step > 0:
            var steps = clamped_value // self.step
            clamped_value = steps * self.step
            
        self.value = clamped_value
        self.trigger_event(EVENT_SPINBOX_VALUE_CHANGED, clamped_value)

    fn get_value(self) -> Int32:
        """Get current spinbox value"""
        return self.value

    fn set_range(inout self, min_val: Int32, max_val: Int32):
        """Set min/max range for the spinbox"""
        self.min_value = min_val
        self.max_value = max_val
        # Re-clamp current value
        self.set_value(self.value)

    fn set_step(inout self, step: Int32):
        """Set increment/decrement step"""
        self.step = step

    fn set_precision(inout self, precision: Int32):
        """Set decimal precision for float type"""
        self.precision = precision

    fn increment(inout self):
        """Increment value by step"""
        self.set_value(self.value + self.step)

    fn decrement(inout self):
        """Decrement value by step"""
        self.set_value(self.value - self.step)

    fn handle_mouse_down(inout self, mouse_x: Int32, mouse_y: Int32) -> Bool:
        """Handle mouse down events"""
        if not self.is_point_inside(mouse_x, mouse_y):
            return False
            
        if not self.enabled:
            return False

        # Check up button (right side, top half)
        var button_x = self.x + self.width - self.button_width
        if (mouse_x >= button_x and mouse_x <= self.x + self.width and
            mouse_y >= self.y and mouse_y <= self.y + self.height // 2):
            self.increment()
            self.trigger_event(1002, 1)  # Up button pressed
            return True

        # Check down button (right side, bottom half)  
        if (mouse_x >= button_x and mouse_x <= self.x + self.width and
            mouse_y >= self.y + self.height // 2 and mouse_y <= self.y + self.height):
            self.decrement()
            self.trigger_event(1002, 2)  # Down button pressed
            return True

        # Check text area (left side)
        if (mouse_x >= self.x and mouse_x < button_x and
            mouse_y >= self.y and mouse_y <= self.y + self.height):
            self.editing = True
            self.focused = True
            self.trigger_event(1003, 1)  # Text area clicked
            return True

        return False

    fn handle_key_input(inout self, key_code: Int32) -> Bool:
        """Handle keyboard input when editing"""
        if not self.editing or not self.focused:
            return False

        if key_code == 13:  # Enter key
            self.editing = False
            return True
        elif key_code == 27:  # Escape key
            self.editing = False
            return True
        elif key_code == 38:  # Up arrow
            self.increment()
            return True
        elif key_code == 40:  # Down arrow
            self.decrement()
            return True

        return False

    fn draw(self, lib: DLHandle):
        """Draw the spinbox widget"""
        if not self.visible:
            return

        # Get drawing functions
        var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
        var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
        var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
        var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
        var draw_line = lib.get_function[fn(Int32, Int32, Int32, Int32, Int32) -> Int32]("draw_line")

        # Text field area (left side)
        var text_width = self.width - self.button_width

        # Draw text field background
        if self.editing:
            _ = set_color(255, 255, 255, 255)  # White when editing
        else:
            _ = set_color(250, 250, 250, 255)  # Light gray
        _ = draw_filled_rectangle(self.x, self.y, text_width, self.height)

        # Draw text field border
        if self.focused:
            _ = set_color(100, 150, 255, 255)  # Blue when focused
        else:
            _ = set_color(180, 180, 180, 255)  # Gray border
        _ = draw_rectangle(self.x, self.y, text_width, self.height)

        # Draw value text
        _ = set_color(0, 0, 0, 255)  # Black text
        var value_str: String
        
        if self.spinbox_type == SPINBOX_FLOAT:
            # Convert back from internal representation (value/1000)
            var float_val = self.value
            var integer_part = float_val // 1000
            var decimal_part = abs(float_val % 1000)
            
            if self.precision == 0:
                value_str = str(integer_part)
            elif self.precision == 1:
                value_str = str(integer_part) + "." + str(decimal_part // 100)
            elif self.precision == 2:
                value_str = str(integer_part) + "." + str(decimal_part // 10).zfill(2)
            else:
                value_str = str(integer_part) + "." + str(decimal_part).zfill(3)
        else:
            value_str = str(self.value)

        var value_bytes = value_str.as_bytes()
        var value_ptr = value_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(value_ptr, self.x + 5, self.y + self.height // 2 - 6, 12)

        # Draw cursor if editing
        if self.editing and self.focused:
            _ = set_color(0, 0, 0, 255)
            var cursor_x = self.x + 5 + len(value_str) * 6  # Approximate text width
            _ = draw_filled_rectangle(cursor_x, self.y + 3, 1, self.height - 6)

        # Button area (right side)
        var button_x = self.x + text_width
        var button_height = self.height // 2

        # Draw up button
        _ = set_color(240, 240, 240, 255)  # Light gray
        _ = draw_filled_rectangle(button_x, self.y, self.button_width, button_height)
        _ = set_color(160, 160, 160, 255)  # Border
        _ = draw_rectangle(button_x, self.y, self.button_width, button_height)

        # Draw up arrow
        _ = set_color(80, 80, 80, 255)  # Dark gray
        var arrow_x = button_x + self.button_width // 2
        var arrow_y = self.y + button_height // 2
        # Simple up arrow using lines
        _ = draw_line(arrow_x, arrow_y - 3, arrow_x - 3, arrow_y + 2, 2)
        _ = draw_line(arrow_x, arrow_y - 3, arrow_x + 3, arrow_y + 2, 2)

        # Draw down button
        _ = set_color(240, 240, 240, 255)  # Light gray
        _ = draw_filled_rectangle(button_x, self.y + button_height, self.button_width, button_height)
        _ = set_color(160, 160, 160, 255)  # Border
        _ = draw_rectangle(button_x, self.y + button_height, self.button_width, button_height)

        # Draw down arrow
        _ = set_color(80, 80, 80, 255)  # Dark gray
        arrow_y = self.y + button_height + button_height // 2
        # Simple down arrow using lines
        _ = draw_line(arrow_x, arrow_y + 3, arrow_x - 3, arrow_y - 2, 2)
        _ = draw_line(arrow_x, arrow_y + 3, arrow_x + 3, arrow_y - 2, 2)

        # Draw middle separator line
        _ = set_color(160, 160, 160, 255)
        _ = draw_line(button_x, self.y + button_height, button_x + self.button_width, self.y + button_height, 1)

        # Draw disabled overlay if not enabled
        if not self.enabled:
            _ = set_color(255, 255, 255, 128)  # Semi-transparent white
            _ = draw_filled_rectangle(self.x, self.y, self.width, self.height)

# Convenience functions for creating SpinBox widgets
fn create_integer_spinbox(x: Int32, y: Int32, width: Int32, height: Int32, 
                         initial_value: Int32 = 0, min_val: Int32 = -1000000, 
                         max_val: Int32 = 1000000, step: Int32 = 1) -> SpinBoxInt:
    """Create an integer spinbox with range and step"""
    var spinbox = SpinBoxInt(x, y, width, height, SPINBOX_INTEGER)
    spinbox.set_range(min_val, max_val)
    spinbox.set_step(step)
    spinbox.set_value(initial_value)
    return spinbox

fn create_float_spinbox(x: Int32, y: Int32, width: Int32, height: Int32,
                       initial_value_x1000: Int32 = 0, min_val_x1000: Int32 = -1000000, 
                       max_val_x1000: Int32 = 1000000, step_x1000: Int32 = 100,
                       precision: Int32 = 2) -> SpinBoxInt:
    """Create a float spinbox (values multiplied by 1000 for precision)"""
    var spinbox = SpinBoxInt(x, y, width, height, SPINBOX_FLOAT)
    spinbox.set_range(min_val_x1000, max_val_x1000)
    spinbox.set_step(step_x1000)
    spinbox.set_precision(precision)
    spinbox.set_value(initial_value_x1000)
    return spinbox

fn create_coordinate_spinbox(x: Int32, y: Int32, width: Int32, height: Int32) -> SpinBoxInt:
    """Create a spinbox optimized for coordinate input (0-10000 range)"""
    var spinbox = SpinBoxInt(x, y, width, height, SPINBOX_INTEGER)
    spinbox.set_range(0, 10000)
    spinbox.set_step(1)
    spinbox.set_value(0)
    return spinbox

fn create_percentage_spinbox(x: Int32, y: Int32, width: Int32, height: Int32) -> SpinBoxInt:
    """Create a spinbox for percentage values (0.0-100.0%)"""
    var spinbox = SpinBoxInt(x, y, width, height, SPINBOX_FLOAT)
    spinbox.set_range(0, 100000)  # 0.000 to 100.000
    spinbox.set_step(1000)        # 1.000 step
    spinbox.set_precision(3)
    spinbox.set_value(0)
    return spinbox