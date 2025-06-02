#!/usr/bin/env python3
"""
Mid-Level MojoGUI Wrappers
Clean Python functions that call the low-level ctypes bindings
"""

import ctypes
try:
    from .low_level_bindings import get_bindings
except ImportError:
    from low_level_bindings import get_bindings

class MojoGUIWrappers:
    """Mid-level wrapper functions for MojoGUI"""
    
    def __init__(self):
        self.bindings = get_bindings()
    
    # =================================================================
    # CORE WINDOW SYSTEM
    # =================================================================
    
    def win_init(self):
        """Initialize the window system"""
        func = self.bindings.get_function('WinInit_impl')
        if func:
            return func()
        return -1
    
    def win_set_size(self, width, height):
        """Set window size"""
        func = self.bindings.get_function('WinSetSize_impl')
        if func:
            return func(int(width), int(height))
        return -1
    
    def win_create(self):
        """Create a window"""
        func = self.bindings.get_function('WinCreate_impl')
        if func:
            return func()
        return -1
    
    def win_destroy(self, window_id=0):
        """Destroy a window"""
        func = self.bindings.get_function('WinDestroy_impl')
        if func:
            return func(int(window_id))
        return -1
    
    def win_set_title(self, title_string_id):
        """Set window title using string ID"""
        func = self.bindings.get_function('WinSetTitle_impl')
        if func:
            return func(int(title_string_id))
        return -1
    
    def frame_begin(self):
        """Begin frame rendering"""
        func = self.bindings.get_function('FrameBegin_impl')
        if func:
            return func()
        return -1
    
    def frame_end(self):
        """End frame rendering"""
        func = self.bindings.get_function('FrameEnd_impl')
        if func:
            return func()
        return -1
    
    def event_poll(self):
        """Poll for events"""
        func = self.bindings.get_function('EventPoll_impl')
        if func:
            return func()
        return -1
    
    # =================================================================
    # STRING SYSTEM
    # =================================================================
    
    def string_set(self, string_id, text):
        """Set string content"""
        func = self.bindings.get_function('StringSet_impl')
        if func:
            text_bytes = text.encode('utf-8') if isinstance(text, str) else text
            return func(int(string_id), text_bytes)
        return -1
    
    def alloc_temp_string(self):
        """Allocate temporary string"""
        func = self.bindings.get_function('AllocTempString')
        if func:
            return func()
        return -1
    
    def str_clear(self, string_id):
        """Clear string"""
        func = self.bindings.get_function('StrClear')
        if func:
            return func(int(string_id))
        return -1
    
    def str_from_int(self, value, string_id):
        """Convert integer to string"""
        func = self.bindings.get_function('StrFromInt')
        if func:
            return func(int(value), int(string_id))
        return -1
    
    def str_from_float(self, value, decimals, string_id):
        """Convert float to string"""
        func = self.bindings.get_function('StrFromFloat')
        if func:
            return func(float(value), int(decimals), int(string_id))
        return -1
    
    # =================================================================
    # DRAWING SYSTEM
    # =================================================================
    
    def draw_set_color(self, r, g, b, a=1.0):
        """Set drawing color (RGBA values 0.0-1.0)"""
        func = self.bindings.get_function('DrawSetColor_impl')
        if func:
            return func(float(r), float(g), float(b), float(a))
        return -1
    
    def draw_set_color_int(self, r, g, b, a=255):
        """Set drawing color (RGBA values 0-255)"""
        func = self.bindings.get_function('DrawSetColor')
        if func:
            return func(int(r), int(g), int(b), int(a))
        return -1
    
    def draw_set_pos(self, x, y):
        """Set drawing position"""
        func = self.bindings.get_function('DrawSetPos_impl')
        if func:
            return func(float(x), float(y))
        return -1
    
    def draw_rect(self, width, height):
        """Draw rectangle at current position"""
        func = self.bindings.get_function('DrawRect_impl')
        if func:
            return func(float(width), float(height))
        return -1
    
    def draw_rounded_rect(self, width, height, radius):
        """Draw rounded rectangle"""
        func = self.bindings.get_function('DrawRoundedRect_impl')
        if func:
            return func(float(width), float(height), float(radius))
        return -1
    
    def draw_circle(self, radius, segments=32):
        """Draw circle at current position"""
        func = self.bindings.get_function('DrawCircle_impl')
        if func:
            return func(float(radius), int(segments))
        return -1
    
    def draw_gradient_rect(self, width, height, r1, g1, b1, a1, r2, g2, b2, a2):
        """Draw gradient rectangle"""
        func = self.bindings.get_function('DrawGradientRect_impl')
        if func:
            return func(float(width), float(height), 
                       float(r1), float(g1), float(b1), float(a1),
                       float(r2), float(g2), float(b2), float(a2))
        return -1
    
    def draw_line(self, x1, y1, x2, y2):
        """Draw line from (x1,y1) to (x2,y2)"""
        func = self.bindings.get_function('DrawLine_impl')
        if func:
            return func(float(x1), float(y1), float(x2), float(y2))
        return -1
    
    def draw_shadow(self, width, height, blur, offset_x, offset_y):
        """Draw shadow effect"""
        func = self.bindings.get_function('DrawShadow_impl')
        if func:
            return func(float(width), float(height), float(blur), 
                       float(offset_x), float(offset_y))
        return -1
    
    def draw_triangle(self, x1, y1, x2, y2, x3, y3):
        """Draw triangle"""
        func = self.bindings.get_function('DrawTriangle_impl')
        if func:
            return func(float(x1), float(y1), float(x2), float(y2), float(x3), float(y3))
        return -1
    
    def draw_rect_outline(self, width, height, thickness):
        """Draw rectangle outline"""
        func = self.bindings.get_function('DrawRectOutline_impl')
        if func:
            return func(float(width), float(height), float(thickness))
        return -1
    
    # =================================================================
    # TEXT AND FONT SYSTEM
    # =================================================================
    
    def font_load_ttf(self, font_data_id, font_size, scale=1.0):
        """Load TrueType font"""
        func = self.bindings.get_function('FontLoadTTF_impl')
        if func:
            return func(int(font_data_id), int(font_size), float(scale))
        return -1
    
    def font_set_active(self, font_id):
        """Set active font"""
        func = self.bindings.get_function('FontSetActive_impl')
        if func:
            return func(int(font_id))
        return -1
    
    def font_set_colors(self, text_r, text_g, text_b, text_a, shadow_r, shadow_g, shadow_b, shadow_a):
        """Set font colors (text and shadow)"""
        func = self.bindings.get_function('FontSetColors_impl')
        if func:
            return func(float(text_r), float(text_g), float(text_b), float(text_a),
                       float(shadow_r), float(shadow_g), float(shadow_b), float(shadow_a))
        return -1
    
    def text_draw(self, string_id):
        """Draw text at current position"""
        func = self.bindings.get_function('TextDraw_impl')
        if func:
            return func(int(string_id))
        return -1
    
    def text_draw_scaled(self, string_id, scale):
        """Draw scaled text"""
        func = self.bindings.get_function('TextDrawScaled_impl')
        if func:
            return func(int(string_id), float(scale))
        return -1
    
    def text_get_width(self, string_id, font_id, size):
        """Get text width"""
        func = self.bindings.get_function('TextGetWidth_impl')
        if func:
            return func(int(string_id), int(font_id), int(size))
        return 0
    
    def text_get_height(self, font_id):
        """Get text height"""
        func = self.bindings.get_function('TextGetHeight_impl')
        if func:
            return func(int(font_id))
        return 0
    
    def load_default_font(self):
        """Load default system font"""
        func = self.bindings.get_function('LoadDefaultFont')
        if func:
            return func()
        return -1
    
    def load_truetype_font(self, font_path, size):
        """Load TrueType font from file"""
        func = self.bindings.get_function('LoadTrueTypeFont')
        if func:
            path_bytes = font_path.encode('utf-8') if isinstance(font_path, str) else font_path
            return func(path_bytes, float(size))
        return -1
    
    # =================================================================
    # BUTTON WIDGET SYSTEM
    # =================================================================
    
    def button_create(self, x, y, width, height, text=""):
        """Create a button widget"""
        func = self.bindings.get_function('ButtonCreate')
        if func:
            text_bytes = text.encode('utf-8') if isinstance(text, str) else text
            return func(int(x), int(y), int(width), int(height), text_bytes)
        return -1
    
    def button_destroy(self, button_id):
        """Destroy a button widget"""
        func = self.bindings.get_function('ButtonDestroy')
        if func:
            return func(int(button_id))
        return -1
    
    def draw_button(self, button_id):
        """Draw a button widget"""
        func = self.bindings.get_function('DrawButton')
        if func:
            return func(int(button_id))
        return -1
    
    def button_set_text(self, button_id, text):
        """Set button text"""
        func = self.bindings.get_function('ButtonSetText')
        if func:
            text_bytes = text.encode('utf-8') if isinstance(text, str) else text
            return func(int(button_id), text_bytes)
        return -1
    
    def button_set_enabled(self, button_id, enabled):
        """Enable/disable button"""
        func = self.bindings.get_function('ButtonSetEnabled')
        if func:
            return func(int(button_id), int(bool(enabled)))
        return -1
    
    def button_set_visible(self, button_id, visible):
        """Show/hide button"""
        func = self.bindings.get_function('ButtonSetVisible')
        if func:
            return func(int(button_id), int(bool(visible)))
        return -1
    
    def button_handle_click(self, button_id, x, y):
        """Handle button click"""
        func = self.bindings.get_function('ButtonHandleClick')
        if func:
            return func(int(button_id), int(x), int(y))
        return -1
    
    def button_is_clicked(self, button_id, x, y):
        """Check if button was clicked at position"""
        return self.button_handle_click(button_id, x, y) > 0
    
    # =================================================================
    # CHECKBOX WIDGET SYSTEM
    # =================================================================
    
    def checkbox_create(self, x, y, width, height):
        """Create a checkbox widget"""
        func = self.bindings.get_function('CheckBoxCreate')
        if func:
            return func(int(x), int(y), int(width), int(height))
        return -1
    
    def enhanced_checkbox_create(self, x, y, width, height, style=0):
        """Create an enhanced checkbox widget"""
        func = self.bindings.get_function('EnhancedCheckBoxCreate')
        if func:
            return func(int(x), int(y), int(width), int(height), int(style))
        return -1
    
    def draw_checkbox(self, checkbox_id):
        """Draw a checkbox widget"""
        func = self.bindings.get_function('DrawCheckBox')
        if func:
            return func(int(checkbox_id))
        return -1
    
    def draw_enhanced_checkbox(self, checkbox_id):
        """Draw an enhanced checkbox widget"""
        func = self.bindings.get_function('DrawEnhancedCheckBox')
        if func:
            return func(int(checkbox_id))
        return -1
    
    def checkbox_set_state(self, checkbox_id, checked):
        """Set checkbox state"""
        func = self.bindings.get_function('CheckBoxSetState')
        if func:
            return func(int(checkbox_id), int(bool(checked)))
        return -1
    
    def checkbox_get_state(self, checkbox_id):
        """Get checkbox state"""
        func = self.bindings.get_function('CheckBoxGetState')
        if func:
            return bool(func(int(checkbox_id)))
        return False
    
    def checkbox_handle_click(self, checkbox_id, x, y):
        """Handle checkbox click"""
        func = self.bindings.get_function('CheckBoxHandleClick')
        if func:
            return func(int(checkbox_id), int(x), int(y))
        return -1
    
    # =================================================================
    # SLIDER WIDGET SYSTEM
    # =================================================================
    
    def slider_create(self, x, y, width, height, orientation=0):
        """Create a slider widget (0=horizontal, 1=vertical)"""
        func = self.bindings.get_function('SliderCreate')
        if func:
            return func(int(x), int(y), int(width), int(height), int(orientation))
        return -1
    
    def draw_slider(self, slider_id):
        """Draw a slider widget"""
        func = self.bindings.get_function('DrawSlider')
        if func:
            return func(int(slider_id))
        return -1
    
    def slider_destroy(self, slider_id):
        """Destroy a slider widget"""
        func = self.bindings.get_function('SliderDestroy')
        if func:
            return func(int(slider_id))
        return -1
    
    def slider_set_range(self, slider_id, min_val, max_val):
        """Set slider range"""
        func = self.bindings.get_function('SliderSetRange')
        if func:
            return func(int(slider_id), int(min_val), int(max_val))
        return -1
    
    def slider_set_value(self, slider_id, value):
        """Set slider value"""
        func = self.bindings.get_function('SliderSetValue')
        if func:
            return func(int(slider_id), int(value))
        return -1
    
    def slider_get_value(self, slider_id):
        """Get slider value"""
        func = self.bindings.get_function('SliderGetValue')
        if func:
            return func(int(slider_id))
        return 0
    
    def slider_handle_click(self, slider_id, x, y):
        """Handle slider click"""
        func = self.bindings.get_function('SliderHandleClick')
        if func:
            return func(int(slider_id), int(x), int(y))
        return -1
    
    def slider_handle_drag(self, slider_id, x, y):
        """Handle slider drag"""
        func = self.bindings.get_function('SliderHandleDrag')
        if func:
            return func(int(slider_id), int(x), int(y))
        return -1
    
    # =================================================================
    # PROGRESS BAR SYSTEM
    # =================================================================
    
    def progressbar_create(self, x, y, width, height, style=0):
        """Create a progress bar widget"""
        func = self.bindings.get_function('ProgressBarCreate')
        if func:
            return func(int(x), int(y), int(width), int(height), int(style))
        return -1
    
    def draw_progressbar(self, progressbar_id):
        """Draw a progress bar widget"""
        func = self.bindings.get_function('DrawProgressBar')
        if func:
            return func(int(progressbar_id))
        return -1
    
    def progressbar_destroy(self, progressbar_id):
        """Destroy a progress bar widget"""
        func = self.bindings.get_function('ProgressBarDestroy')
        if func:
            return func(int(progressbar_id))
        return -1
    
    def progressbar_set_value(self, progressbar_id, value):
        """Set progress bar value (0-100)"""
        func = self.bindings.get_function('ProgressBarSetValue')
        if func:
            return func(int(progressbar_id), int(value))
        return -1
    
    def progressbar_get_value(self, progressbar_id):
        """Get progress bar value"""
        func = self.bindings.get_function('ProgressBarGetValue')
        if func:
            return func(int(progressbar_id))
        return 0.0
    
    def progressbar_set_label(self, progressbar_id, text):
        """Set progress bar label text"""
        func = self.bindings.get_function('ProgressBarSetLabel')
        if func:
            text_bytes = text.encode('utf-8') if isinstance(text, str) else text
            return func(int(progressbar_id), text_bytes)
        return -1
    
    # =================================================================
    # LABEL WIDGET SYSTEM
    # =================================================================
    
    def label_create(self, x, y, width, height, text=""):
        """Create a label widget"""
        func = self.bindings.get_function('LabelCreate')
        if func:
            text_bytes = text.encode('utf-8') if isinstance(text, str) else text
            return func(int(x), int(y), int(width), int(height), text_bytes)
        return -1
    
    def draw_label(self, label_id):
        """Draw a label widget"""
        func = self.bindings.get_function('DrawLabel')
        if func:
            return func(int(label_id))
        return -1
    
    def label_destroy(self, label_id):
        """Destroy a label widget"""
        func = self.bindings.get_function('LabelDestroy')
        if func:
            return func(int(label_id))
        return -1
    
    def label_set_text(self, label_id, text):
        """Set label text"""
        func = self.bindings.get_function('LabelSetText')
        if func:
            text_bytes = text.encode('utf-8') if isinstance(text, str) else text
            return func(int(label_id), text_bytes)
        return -1
    
    def label_set_visible(self, label_id, visible):
        """Show/hide label"""
        func = self.bindings.get_function('LabelSetVisible')
        if func:
            return func(int(label_id), int(bool(visible)))
        return -1
    
    # =================================================================
    # UTILITY FUNCTIONS
    # =================================================================
    
    def is_function_available(self, func_name):
        """Check if a function is available"""
        return self.bindings.has_function(func_name)
    
    def get_available_functions(self):
        """Get list of all available functions"""
        return self.bindings.list_available_functions()
    
    def print_status(self):
        """Print current status of available functions"""
        available = self.get_available_functions()
        print(f"📊 MojoGUI Wrapper Status:")
        print(f"   Available functions: {len(available)}")
        
        # Group by category
        categories = {
            'Core': [f for f in available if any(f.startswith(p) for p in ['Win', 'Frame', 'Event', 'String'])],
            'Drawing': [f for f in available if f.startswith('Draw')],
            'Text': [f for f in available if any(f.startswith(p) for p in ['Font', 'Text', 'Load'])],
            'Button': [f for f in available if f.startswith('Button')],
            'CheckBox': [f for f in available if 'CheckBox' in f],
            'Slider': [f for f in available if f.startswith('Slider')],
            'Progress': [f for f in available if f.startswith('Progress')],
            'Label': [f for f in available if f.startswith('Label')],
            'Other': [f for f in available if not any(f.startswith(p) for p in 
                     ['Win', 'Frame', 'Event', 'String', 'Draw', 'Font', 'Text', 'Load', 
                      'Button', 'Slider', 'Progress', 'Label']) and 'CheckBox' not in f]
        }
        
        for category, funcs in categories.items():
            if funcs:
                print(f"   {category}: {len(funcs)} functions")

# Global instance
_wrappers = None

def get_wrappers():
    """Get the global wrappers instance"""
    global _wrappers
    if _wrappers is None:
        _wrappers = MojoGUIWrappers()
    return _wrappers

def reload_wrappers():
    """Reload the wrappers (useful after library recompilation)"""
    global _wrappers
    _wrappers = None
    return get_wrappers()

if __name__ == "__main__":
    print("🎯 MojoGUI Mid-Level Wrappers")
    print("============================")
    
    wrappers = get_wrappers()
    wrappers.print_status()
    
    print(f"\n💡 Usage:")
    print(f"   from python_bindings.mid_level_wrappers import get_wrappers")
    print(f"   gui = get_wrappers()")
    print(f"   gui.win_init()")
    print(f"   gui.win_set_size(800, 600)")
    print(f"   gui.draw_set_color(1.0, 0.0, 0.0, 1.0)  # Red")