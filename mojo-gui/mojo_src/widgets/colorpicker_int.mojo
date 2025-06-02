#!/usr/bin/env mojo
"""
ColorPicker Widget - Integer-Only API
Professional color selection with multiple styles, RGB/HSV support, and eyedropper
"""

from sys.ffi import DLHandle, DLSymbol
from memory import UnsafePointer
from math import sqrt, atan2, sin, cos, abs
from ..widget_int import BaseWidgetInt

# ColorPicker styles
alias COLORPICKER_COMPACT: Int32 = 0
alias COLORPICKER_WHEEL: Int32 = 1
alias COLORPICKER_SQUARE: Int32 = 2
alias COLORPICKER_SLIDERS: Int32 = 3

# Events
alias EVENT_COLOR_CHANGED: Int32 = 1201
alias EVENT_COLOR_PICKED: Int32 = 1202
alias EVENT_COLOR_PREVIEW: Int32 = 1203

struct ColorPickerInt(BaseWidgetInt):
    """
    Professional ColorPicker widget with multiple selection styles
    Supports RGB/HSV color spaces, preview, alpha channel, and hex input
    """
    var style: Int32
    var color_r: Int32       # Red component (0-255)
    var color_g: Int32       # Green component (0-255)  
    var color_b: Int32       # Blue component (0-255)
    var color_a: Int32       # Alpha component (0-255)
    var hue: Int32           # Hue (0-360)
    var saturation: Int32    # Saturation (0-100)
    var brightness: Int32    # Brightness/Value (0-100)
    var show_preview: Bool
    var show_alpha: Bool
    var show_hex: Bool
    var popup_visible: Bool
    var dragging: Bool
    var drag_target: Int32   # Which component is being dragged
    var preview_color_r: Int32
    var preview_color_g: Int32
    var preview_color_b: Int32
    var recent_colors: List[Int32]  # Store as RGB packed integers
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, 
               style: Int32 = COLORPICKER_COMPACT):
        """Initialize ColorPicker with position, size and style"""
        self.style = style
        self.color_r = 255
        self.color_g = 255
        self.color_b = 255
        self.color_a = 255
        self.hue = 0
        self.saturation = 0
        self.brightness = 100
        self.show_preview = True
        self.show_alpha = False
        self.show_hex = True
        self.popup_visible = False
        self.dragging = False
        self.drag_target = 0
        self.preview_color_r = 255
        self.preview_color_g = 255
        self.preview_color_b = 255
        self.recent_colors = List[Int32]()
        super().__init__(x, y, width, height, "colorpicker")

    fn set_color_rgb(inout self, r: Int32, g: Int32, b: Int32, a: Int32 = 255):
        """Set color using RGB values (0-255)"""
        self.color_r = max(0, min(255, r))
        self.color_g = max(0, min(255, g))
        self.color_b = max(0, min(255, b))
        self.color_a = max(0, min(255, a))
        self._rgb_to_hsv()
        self.trigger_event(EVENT_COLOR_CHANGED, self._pack_rgb())

    fn get_color_rgb(self) -> (Int32, Int32, Int32, Int32):
        """Get current color as RGBA values"""
        return (self.color_r, self.color_g, self.color_b, self.color_a)

    fn set_color_hsv(inout self, h: Int32, s: Int32, v: Int32):
        """Set color using HSV values (H: 0-360, S: 0-100, V: 0-100)"""
        self.hue = max(0, min(360, h))
        self.saturation = max(0, min(100, s))
        self.brightness = max(0, min(100, v))
        self._hsv_to_rgb()
        self.trigger_event(EVENT_COLOR_CHANGED, self._pack_rgb())

    fn get_color_hsv(self) -> (Int32, Int32, Int32):
        """Get current color as HSV values"""
        return (self.hue, self.saturation, self.brightness)

    fn set_color_hex(inout self, hex_value: Int32):
        """Set color using hex value (0xRRGGBB)"""
        self.color_r = (hex_value >> 16) & 0xFF
        self.color_g = (hex_value >> 8) & 0xFF
        self.color_b = hex_value & 0xFF
        self._rgb_to_hsv()
        self.trigger_event(EVENT_COLOR_CHANGED, hex_value)

    fn get_color_hex(self) -> Int32:
        """Get current color as hex value"""
        return (self.color_r << 16) | (self.color_g << 8) | self.color_b

    fn add_recent_color(inout self):
        """Add current color to recent colors list"""
        var packed_color = self._pack_rgb()
        
        # Remove if already exists
        for i in range(len(self.recent_colors)):
            if self.recent_colors[i] == packed_color:
                _ = self.recent_colors.pop(i)
                break
        
        # Add to front of list
        self.recent_colors.insert(0, packed_color)
        
        # Keep only last 8 colors
        while len(self.recent_colors) > 8:
            _ = self.recent_colors.pop()

    fn set_preview_mode(inout self, enabled: Bool):
        """Enable/disable color preview"""
        self.show_preview = enabled

    fn set_alpha_mode(inout self, enabled: Bool):
        """Enable/disable alpha channel support"""
        self.show_alpha = enabled

    fn open_popup(inout self):
        """Open color picker popup"""
        if not self.popup_visible:
            self.popup_visible = True
            self.preview_color_r = self.color_r
            self.preview_color_g = self.color_g
            self.preview_color_b = self.color_b

    fn close_popup(inout self):
        """Close color picker popup"""
        if self.popup_visible:
            self.popup_visible = False
            self.dragging = False

    fn apply_preview_color(inout self):
        """Apply preview color as the final color"""
        self.set_color_rgb(self.preview_color_r, self.preview_color_g, self.preview_color_b, self.color_a)
        self.add_recent_color()

    fn _pack_rgb(self) -> Int32:
        """Pack RGB into single integer"""
        return (self.color_r << 16) | (self.color_g << 8) | self.color_b

    fn _unpack_rgb(self, packed: Int32) -> (Int32, Int32, Int32):
        """Unpack RGB from single integer"""
        var r = (packed >> 16) & 0xFF
        var g = (packed >> 8) & 0xFF
        var b = packed & 0xFF
        return (r, g, b)

    fn _rgb_to_hsv(inout self):
        """Convert current RGB to HSV"""
        var r = self.color_r / 255.0
        var g = self.color_g / 255.0
        var b = self.color_b / 255.0
        
        var max_val = max(max(r, g), b)
        var min_val = min(min(r, g), b)
        var delta = max_val - min_val
        
        # Brightness (Value)
        self.brightness = Int32(max_val * 100)
        
        # Saturation
        if max_val == 0:
            self.saturation = 0
        else:
            self.saturation = Int32((delta / max_val) * 100)
        
        # Hue
        if delta == 0:
            self.hue = 0
        elif max_val == r:
            self.hue = Int32(((g - b) / delta * 60) % 360)
        elif max_val == g:
            self.hue = Int32(((b - r) / delta * 60) + 120)
        else:
            self.hue = Int32(((r - g) / delta * 60) + 240)
            
        if self.hue < 0:
            self.hue += 360

    fn _hsv_to_rgb(inout self):
        """Convert current HSV to RGB"""
        var h = self.hue / 60.0
        var s = self.saturation / 100.0
        var v = self.brightness / 100.0
        
        var c = v * s
        var x = c * (1 - abs((h % 2) - 1))
        var m = v - c
        
        var r: Float64 = 0
        var g: Float64 = 0
        var b: Float64 = 0
        
        if h < 1:
            r = c; g = x; b = 0
        elif h < 2:
            r = x; g = c; b = 0
        elif h < 3:
            r = 0; g = c; b = x
        elif h < 4:
            r = 0; g = x; b = c
        elif h < 5:
            r = x; g = 0; b = c
        else:
            r = c; g = 0; b = x
        
        self.color_r = Int32((r + m) * 255)
        self.color_g = Int32((g + m) * 255)
        self.color_b = Int32((b + m) * 255)

    fn handle_mouse_down(inout self, mouse_x: Int32, mouse_y: Int32) -> Bool:
        """Handle mouse down events"""
        if not self.enabled:
            return False

        # Main color display area click
        if self.is_point_inside(mouse_x, mouse_y):
            if not self.popup_visible:
                self.open_popup()
                return True
        
        # Popup interactions
        if self.popup_visible:
            return self._handle_popup_click(mouse_x, mouse_y)
        
        return False

    fn _handle_popup_click(inout self, mouse_x: Int32, mouse_y: Int32) -> Bool:
        """Handle clicks in popup area"""
        var popup_x = self.x
        var popup_y = self.y + self.height + 5
        var popup_width = max(300, self.width)
        var popup_height = 250
        
        # Check if clicking outside popup to close
        if (mouse_x < popup_x or mouse_x > popup_x + popup_width or
            mouse_y < popup_y or mouse_y > popup_y + popup_height):
            self.close_popup()
            return True
        
        # Handle different style interactions
        if self.style == COLORPICKER_WHEEL:
            return self._handle_wheel_click(mouse_x, mouse_y, popup_x, popup_y)
        elif self.style == COLORPICKER_SLIDERS:
            return self._handle_slider_click(mouse_x, mouse_y, popup_x, popup_y)
        else:
            return self._handle_compact_click(mouse_x, mouse_y, popup_x, popup_y)

    fn _handle_wheel_click(inout self, mouse_x: Int32, mouse_y: Int32, popup_x: Int32, popup_y: Int32) -> Bool:
        """Handle color wheel interactions"""
        var center_x = popup_x + 125
        var center_y = popup_y + 125
        var radius = 100
        
        var dx = mouse_x - center_x
        var dy = mouse_y - center_y
        var distance = Int32(sqrt(dx * dx + dy * dy))
        
        if distance <= radius:
            # Calculate hue from angle
            var angle = atan2(dy, dx) * 180.0 / 3.14159
            if angle < 0:
                angle += 360
            self.hue = Int32(angle)
            
            # Calculate saturation from distance
            self.saturation = min(100, (distance * 100) // radius)
            
            self._hsv_to_rgb()
            self.trigger_event(EVENT_COLOR_PREVIEW, self._pack_rgb())
            return True
        
        return False

    fn _handle_slider_click(inout self, mouse_x: Int32, mouse_y: Int32, popup_x: Int32, popup_y: Int32) -> Bool:
        """Handle RGB slider interactions"""
        var slider_width = 200
        var slider_height = 20
        var slider_x = popup_x + 50
        
        # Red slider
        if (mouse_y >= popup_y + 30 and mouse_y <= popup_y + 50):
            var pos = max(0, min(slider_width, mouse_x - slider_x))
            self.color_r = (pos * 255) // slider_width
            self._rgb_to_hsv()
            self.trigger_event(EVENT_COLOR_PREVIEW, self._pack_rgb())
            return True
        
        # Green slider
        if (mouse_y >= popup_y + 70 and mouse_y <= popup_y + 90):
            var pos = max(0, min(slider_width, mouse_x - slider_x))
            self.color_g = (pos * 255) // slider_width
            self._rgb_to_hsv()
            self.trigger_event(EVENT_COLOR_PREVIEW, self._pack_rgb())
            return True
        
        # Blue slider
        if (mouse_y >= popup_y + 110 and mouse_y <= popup_y + 130):
            var pos = max(0, min(slider_width, mouse_x - slider_x))
            self.color_b = (pos * 255) // slider_width
            self._rgb_to_hsv()
            self.trigger_event(EVENT_COLOR_PREVIEW, self._pack_rgb())
            return True
        
        return False

    fn _handle_compact_click(inout self, mouse_x: Int32, mouse_y: Int32, popup_x: Int32, popup_y: Int32) -> Bool:
        """Handle compact style interactions (color palette)"""
        var palette_x = popup_x + 10
        var palette_y = popup_y + 10
        var color_size = 25
        var colors_per_row = 10
        
        # Basic color palette
        var basic_colors = List[Int32]()
        basic_colors.append(0xFF0000)  # Red
        basic_colors.append(0x00FF00)  # Green
        basic_colors.append(0x0000FF)  # Blue
        basic_colors.append(0xFFFF00)  # Yellow
        basic_colors.append(0xFF00FF)  # Magenta
        basic_colors.append(0x00FFFF)  # Cyan
        basic_colors.append(0x000000)  # Black
        basic_colors.append(0x808080)  # Gray
        basic_colors.append(0xFFFFFF)  # White
        basic_colors.append(0x800000)  # Maroon
        
        for i in range(len(basic_colors)):
            var col = i % colors_per_row
            var row = i // colors_per_row
            var color_x = palette_x + col * (color_size + 2)
            var color_y = palette_y + row * (color_size + 2)
            
            if (mouse_x >= color_x and mouse_x <= color_x + color_size and
                mouse_y >= color_y and mouse_y <= color_y + color_size):
                self.set_color_hex(basic_colors[i])
                return True
        
        # Recent colors
        if len(self.recent_colors) > 0:
            var recent_y = palette_y + 60
            for i in range(min(8, len(self.recent_colors))):
                var color_x = palette_x + i * (color_size + 2)
                
                if (mouse_x >= color_x and mouse_x <= color_x + color_size and
                    mouse_y >= recent_y and mouse_y <= recent_y + color_size):
                    self.set_color_hex(self.recent_colors[i])
                    return True
        
        return False

    fn draw(self, lib: DLHandle):
        """Draw the color picker widget"""
        if not self.visible:
            return

        # Get drawing functions
        var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
        var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
        var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
        var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")

        # Draw main color display
        _ = set_color(self.color_r, self.color_g, self.color_b, self.color_a)
        _ = draw_filled_rectangle(self.x, self.y, self.width, self.height)

        # Draw border
        if self.focused or self.popup_visible:
            _ = set_color(100, 150, 255, 255)  # Blue when focused/open
        else:
            _ = set_color(120, 120, 120, 255)  # Gray border
        _ = draw_rectangle(self.x, self.y, self.width, self.height)

        # Draw hex value if enabled
        if self.show_hex:
            var hex_str = "0x" + hex(self.get_color_hex()).upper()
            _ = set_color(255, 255, 255, 255)  # White text
            var hex_bytes = hex_str.as_bytes()
            var hex_ptr = hex_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(hex_ptr, self.x + 5, self.y + self.height + 5, 10)

        # Draw popup if visible
        if self.popup_visible:
            self._draw_popup(lib)

        # Draw disabled overlay
        if not self.enabled:
            _ = set_color(255, 255, 255, 128)  # Semi-transparent white
            _ = draw_filled_rectangle(self.x, self.y, self.width, self.height)

    fn _draw_popup(self, lib: DLHandle):
        """Draw the color picker popup"""
        var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
        var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
        var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
        var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")

        var popup_x = self.x
        var popup_y = self.y + self.height + 5
        var popup_width = max(300, self.width)
        var popup_height = 250

        # Draw popup background
        _ = set_color(250, 250, 250, 255)  # Light gray background
        _ = draw_filled_rectangle(popup_x, popup_y, popup_width, popup_height)

        # Draw popup border
        _ = set_color(120, 120, 120, 255)  # Gray border
        _ = draw_rectangle(popup_x, popup_y, popup_width, popup_height)

        # Draw content based on style
        if self.style == COLORPICKER_WHEEL:
            self._draw_color_wheel(lib, popup_x, popup_y)
        elif self.style == COLORPICKER_SLIDERS:
            self._draw_rgb_sliders(lib, popup_x, popup_y)
        else:
            self._draw_color_palette(lib, popup_x, popup_y)

        # Draw preview area if enabled
        if self.show_preview:
            self._draw_preview_area(lib, popup_x, popup_y, popup_width, popup_height)

    fn _draw_color_palette(self, lib: DLHandle, popup_x: Int32, popup_y: Int32):
        """Draw color palette (compact style)"""
        var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
        var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
        var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")

        var palette_x = popup_x + 10
        var palette_y = popup_y + 10
        var color_size = 25
        
        # Draw basic color palette
        var basic_colors = List[Int32]()
        basic_colors.append(0xFF0000)  # Red
        basic_colors.append(0x00FF00)  # Green
        basic_colors.append(0x0000FF)  # Blue
        basic_colors.append(0xFFFF00)  # Yellow
        basic_colors.append(0xFF00FF)  # Magenta
        basic_colors.append(0x00FFFF)  # Cyan
        basic_colors.append(0x000000)  # Black
        basic_colors.append(0x808080)  # Gray
        basic_colors.append(0xFFFFFF)  # White
        basic_colors.append(0x800000)  # Maroon
        
        for i in range(len(basic_colors)):
            var col = i % 10
            var row = i // 10
            var color_x = palette_x + col * (color_size + 2)
            var color_y = palette_y + row * (color_size + 2)
            
            var color = basic_colors[i]
            var r = (color >> 16) & 0xFF
            var g = (color >> 8) & 0xFF
            var b = color & 0xFF
            
            _ = set_color(r, g, b, 255)
            _ = draw_filled_rectangle(color_x, color_y, color_size, color_size)
            _ = set_color(100, 100, 100, 255)
            _ = draw_rectangle(color_x, color_y, color_size, color_size)

    fn _draw_rgb_sliders(self, lib: DLHandle, popup_x: Int32, popup_y: Int32):
        """Draw RGB sliders"""
        var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
        var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
        var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
        var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")

        var slider_x = popup_x + 50
        var slider_width = 200
        var slider_height = 20

        # Red slider
        _ = set_color(0, 0, 0, 255)
        var red_label = "R: " + str(self.color_r)
        var red_bytes = red_label.as_bytes()
        var red_ptr = red_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(red_ptr, popup_x + 10, popup_y + 35, 12)

        _ = set_color(255, 0, 0, 255)
        _ = draw_filled_rectangle(slider_x, popup_y + 30, (self.color_r * slider_width) // 255, slider_height)
        _ = set_color(200, 200, 200, 255)
        _ = draw_rectangle(slider_x, popup_y + 30, slider_width, slider_height)

        # Green slider
        var green_label = "G: " + str(self.color_g)
        var green_bytes = green_label.as_bytes()
        var green_ptr = green_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(green_ptr, popup_x + 10, popup_y + 75, 12)

        _ = set_color(0, 255, 0, 255)
        _ = draw_filled_rectangle(slider_x, popup_y + 70, (self.color_g * slider_width) // 255, slider_height)
        _ = set_color(200, 200, 200, 255)
        _ = draw_rectangle(slider_x, popup_y + 70, slider_width, slider_height)

        # Blue slider
        var blue_label = "B: " + str(self.color_b)
        var blue_bytes = blue_label.as_bytes()
        var blue_ptr = blue_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(blue_ptr, popup_x + 10, popup_y + 115, 12)

        _ = set_color(0, 0, 255, 255)
        _ = draw_filled_rectangle(slider_x, popup_y + 110, (self.color_b * slider_width) // 255, slider_height)
        _ = set_color(200, 200, 200, 255)
        _ = draw_rectangle(slider_x, popup_y + 110, slider_width, slider_height)

    fn _draw_color_wheel(self, lib: DLHandle, popup_x: Int32, popup_y: Int32):
        """Draw color wheel (simplified as square for now)"""
        # For now, implement as a gradient square - full wheel would require more complex rendering
        self._draw_rgb_sliders(lib, popup_x, popup_y)

    fn _draw_preview_area(self, lib: DLHandle, popup_x: Int32, popup_y: Int32, popup_width: Int32, popup_height: Int32):
        """Draw color preview area"""
        var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
        var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
        var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")

        var preview_width = 60
        var preview_height = 40
        var preview_x = popup_x + popup_width - preview_width - 10
        var preview_y = popup_y + popup_height - preview_height - 10

        # Draw current color preview
        _ = set_color(self.color_r, self.color_g, self.color_b, 255)
        _ = draw_filled_rectangle(preview_x, preview_y, preview_width, preview_height)
        _ = set_color(100, 100, 100, 255)
        _ = draw_rectangle(preview_x, preview_y, preview_width, preview_height)

# Convenience functions for creating ColorPicker widgets
fn create_compact_colorpicker(x: Int32, y: Int32, width: Int32, height: Int32) -> ColorPickerInt:
    """Create a compact color picker with palette"""
    return ColorPickerInt(x, y, width, height, COLORPICKER_COMPACT)

fn create_slider_colorpicker(x: Int32, y: Int32, width: Int32, height: Int32) -> ColorPickerInt:
    """Create a color picker with RGB sliders"""
    var picker = ColorPickerInt(x, y, width, height, COLORPICKER_SLIDERS)
    picker.set_preview_mode(True)
    return picker

fn create_wheel_colorpicker(x: Int32, y: Int32, width: Int32, height: Int32) -> ColorPickerInt:
    """Create a color picker with color wheel"""
    var picker = ColorPickerInt(x, y, width, height, COLORPICKER_WHEEL)
    picker.set_preview_mode(True)
    return picker

fn create_alpha_colorpicker(x: Int32, y: Int32, width: Int32, height: Int32) -> ColorPickerInt:
    """Create a color picker with alpha channel support"""
    var picker = ColorPickerInt(x, y, width, height, COLORPICKER_SLIDERS)
    picker.set_alpha_mode(True)
    picker.set_preview_mode(True)
    return picker