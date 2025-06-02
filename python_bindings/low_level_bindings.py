#!/usr/bin/env python3
"""
Low-Level MojoGUI Bindings
Direct ctypes bindings to C library functions
"""

import ctypes
import os
import sys

class MojoGUIBindings:
    """Low-level ctypes bindings to MojoGUI C library"""
    
    def __init__(self):
        self.lib = None
        self.functions = {}
        self._load_library()
        self._setup_all_bindings()
    
    def _load_library(self):
        """Load the MojoGUI library"""
        lib_names = [
            './libmojoguiglfw.so',
            './libmojoguiglfw.dylib', 
            './mojoguiglfw.dll'
        ]
        
        for name in lib_names:
            if os.path.exists(name):
                try:
                    self.lib = ctypes.CDLL(name)
                    print(f"✅ Loaded MojoGUI library: {name}")
                    return
                except Exception as e:
                    print(f"⚠️  Failed to load {name}: {e}")
                    continue
        
        raise RuntimeError("❌ Could not load MojoGUI library!")
    
    def _setup_function(self, name, argtypes, restype):
        """Set up a single function binding"""
        if hasattr(self.lib, name):
            func = getattr(self.lib, name)
            func.argtypes = argtypes
            func.restype = restype
            self.functions[name] = func
            return True
        return False
    
    def _setup_all_bindings(self):
        """Set up all function bindings"""
        
        # =================================================================
        # CORE WINDOW SYSTEM
        # =================================================================
        core_functions = {
            'WinInit_impl': ([], ctypes.c_int),
            'WinInit': ([], ctypes.c_int),
            'WinSetSize_impl': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'WinSetSize': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'WinCreate_impl': ([], ctypes.c_int),
            'WinCreate': ([], ctypes.c_int),
            'WinDestroy_impl': ([ctypes.c_int], ctypes.c_int),
            'WinDestroy': ([ctypes.c_int], ctypes.c_int),
            'WinSetTitle_impl': ([ctypes.c_int], ctypes.c_int),
            'WinSetTitle': ([ctypes.c_int], ctypes.c_int),
            'FrameBegin_impl': ([], ctypes.c_int),
            'FrameBegin': ([], ctypes.c_int),
            'FrameEnd_impl': ([], ctypes.c_int),
            'FrameEnd': ([], ctypes.c_int),
            'EventPoll_impl': ([], ctypes.c_int),
            'EventPoll': ([], ctypes.c_int),
        }
        
        # =================================================================
        # STRING SYSTEM
        # =================================================================
        string_functions = {
            'StringSet_impl': ([ctypes.c_int, ctypes.c_char_p], ctypes.c_int),
            'StringSet': ([ctypes.c_int, ctypes.c_char_p], ctypes.c_int),
            'AllocTempString': ([], ctypes.c_int),
            'StrClear': ([ctypes.c_int], ctypes.c_int),
            'StrRegister': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'StrFromInt': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'StrFromFloat': ([ctypes.c_float, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'StrConcat': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
        }
        
        # =================================================================
        # DRAWING SYSTEM
        # =================================================================
        drawing_functions = {
            'DrawSetColor_impl': ([ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float], ctypes.c_int),
            'DrawSetColor': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'DrawSetPos_impl': ([ctypes.c_float, ctypes.c_float], ctypes.c_int),
            'DrawSetPos': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'DrawRect_impl': ([ctypes.c_float, ctypes.c_float], ctypes.c_int),
            'DrawRect': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'DrawRoundedRect_impl': ([ctypes.c_float, ctypes.c_float, ctypes.c_float], ctypes.c_int),
            'DrawRoundedRect': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'DrawCircle_impl': ([ctypes.c_float, ctypes.c_int], ctypes.c_int),
            'DrawCircle': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'DrawGradientRect_impl': ([
                ctypes.c_float, ctypes.c_float,  # width, height
                ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float,  # color1
                ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float   # color2
            ], ctypes.c_int),
            'DrawGradientRect': ([
                ctypes.c_int, ctypes.c_int,  # width, height
                ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int,  # color1
                ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int   # color2
            ], ctypes.c_int),
            'DrawLine_impl': ([ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float], ctypes.c_int),
            'DrawLine': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'DrawShadow_impl': ([ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float], ctypes.c_int),
            'DrawTriangle_impl': ([ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float], ctypes.c_int),
            'DrawRectOutline_impl': ([ctypes.c_float, ctypes.c_float, ctypes.c_float], ctypes.c_int),
        }
        
        # =================================================================
        # TEXT AND FONT SYSTEM
        # =================================================================
        text_functions = {
            'FontLoadTTF_impl': ([ctypes.c_int, ctypes.c_int, ctypes.c_float], ctypes.c_int),
            'FontLoadTTF': ([ctypes.c_int, ctypes.c_int, ctypes.c_float], ctypes.c_int),
            'FontSetActive_impl': ([ctypes.c_int], ctypes.c_int),
            'FontSetActive': ([ctypes.c_int], ctypes.c_int),
            'FontSetColors_impl': ([ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float,
                                   ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float], ctypes.c_int),
            'TextDraw_impl': ([ctypes.c_int], ctypes.c_int),
            'TextDraw': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'TextDrawScaled_impl': ([ctypes.c_int, ctypes.c_float], ctypes.c_int),
            'TextGetWidth_impl': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'TextGetHeight_impl': ([ctypes.c_int], ctypes.c_int),
            'GetTextWidth_impl': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'LoadDefaultFont': ([], ctypes.c_int),
            'LoadTrueTypeFont': ([ctypes.c_char_p, ctypes.c_float], ctypes.c_int),
            'TextGetLineHeight': ([], ctypes.c_int),
            'TextGetCharWidth': ([ctypes.c_int], ctypes.c_int),
        }
        
        # =================================================================
        # BUTTON WIDGET SYSTEM
        # =================================================================
        button_functions = {
            'ButtonCreate': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_char_p], ctypes.c_int),
            'ButtonDestroy': ([ctypes.c_int], ctypes.c_int),
            'DrawButton': ([ctypes.c_int], ctypes.c_int),
            'ButtonSetText': ([ctypes.c_int, ctypes.c_char_p], ctypes.c_int),
            'ButtonSetTextStringId': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonSetIcon': ([ctypes.c_int, ctypes.c_char_p, ctypes.c_int], ctypes.c_int),
            'ButtonSetStyle': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonSetSize': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonSetEnabled': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonSetVisible': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonSetToggleMode': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonSetToggled': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonGetToggled': ([ctypes.c_int], ctypes.c_int),
            'ButtonSetCornerRadius': ([ctypes.c_int, ctypes.c_float], ctypes.c_int),
            'ButtonSetColors': ([ctypes.c_int] + [ctypes.c_int] * 8, ctypes.c_int),
            'ButtonSetHoverColors': ([ctypes.c_int] + [ctypes.c_int] * 8, ctypes.c_int),
            'ButtonSetPressedColors': ([ctypes.c_int] + [ctypes.c_int] * 8, ctypes.c_int),
            'ButtonSetBorderColors': ([ctypes.c_int] + [ctypes.c_int] * 8, ctypes.c_int),
            'ButtonSetPosition': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonSetDimensions': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonHandleClick': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonHandleHover': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonHandleMouseDown': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonHandleMouseUp': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonHandleKey': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonSetFocus': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ButtonGetFocused': ([], ctypes.c_int),
            'ButtonIsEnabled': ([ctypes.c_int], ctypes.c_int),
            'ButtonIsVisible': ([ctypes.c_int], ctypes.c_int),
            'ButtonIsHovered': ([ctypes.c_int], ctypes.c_int),
            'ButtonIsPressed': ([ctypes.c_int], ctypes.c_int),
            'ButtonUpdateAll': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
        }
        
        # =================================================================
        # CHECKBOX WIDGET SYSTEM
        # =================================================================
        checkbox_functions = {
            'CheckBoxCreate': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'EnhancedCheckBoxCreate': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'DrawCheckBox': ([ctypes.c_int], ctypes.c_int),
            'DrawEnhancedCheckBox': ([ctypes.c_int], ctypes.c_int),
            'CheckBoxDestroy': ([ctypes.c_int], ctypes.c_int),
            'CheckBoxSetState': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'CheckBoxGetState': ([ctypes.c_int], ctypes.c_int),
            'EnhancedCheckBoxSetState': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'EnhancedCheckBoxGetState': ([ctypes.c_int], ctypes.c_int),
            'CheckBoxSetLabel': ([ctypes.c_int, ctypes.c_char_p, ctypes.c_int], ctypes.c_int),
            'EnhancedCheckBoxSetLabel': ([ctypes.c_int, ctypes.c_char_p, ctypes.c_int], ctypes.c_int),
            'CheckBoxHandleClick': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'EnhancedCheckBoxHandleClick': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'CheckBoxHandleKey': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'EnhancedCheckBoxHandleKey': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'CheckBoxSetColors': ([ctypes.c_int] + [ctypes.c_int] * 9, ctypes.c_int),
            'EnhancedCheckBoxSetColors': ([ctypes.c_int] + [ctypes.c_int] * 9, ctypes.c_int),
            'CheckBoxSetSwitchColors': ([ctypes.c_int] + [ctypes.c_int] * 9, ctypes.c_int),
            'EnhancedCheckBoxSetSwitchColors': ([ctypes.c_int] + [ctypes.c_int] * 9, ctypes.c_int),
            'CheckBoxSetTriState': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'EnhancedCheckBoxSetTriState': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'CheckBoxToggle': ([ctypes.c_int], ctypes.c_int),
            'EnhancedCheckBoxToggle': ([ctypes.c_int], ctypes.c_int),
        }
        
        # =================================================================
        # SLIDER WIDGET SYSTEM
        # =================================================================
        slider_functions = {
            'SliderCreate': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'DrawSlider': ([ctypes.c_int], ctypes.c_int),
            'SliderDestroy': ([ctypes.c_int], ctypes.c_int),
            'SliderSetRange': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'SliderSetValue': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'SliderGetValue': ([ctypes.c_int], ctypes.c_int),
            'SliderSetStep': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'SliderSetColors': ([ctypes.c_int] + [ctypes.c_int] * 9, ctypes.c_int),
            'SliderSetProperties': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'SliderHandleClick': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'SliderHandleHover': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'SliderHandleDrag': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'SliderHandleRelease': ([ctypes.c_int], ctypes.c_int),
            'SliderSetFocus': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'SliderGetFocused': ([], ctypes.c_int),
            'SliderHandleKey': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
        }
        
        # =================================================================
        # PROGRESS BAR SYSTEM
        # =================================================================
        progressbar_functions = {
            'ProgressBarCreate': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'DrawProgressBar': ([ctypes.c_int], ctypes.c_int),
            'ProgressBarDestroy': ([ctypes.c_int], ctypes.c_int),
            'ProgressBarSetValue': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ProgressBarGetValue': ([ctypes.c_int], ctypes.c_float),
            'ProgressBarSetStyle': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ProgressBarSetLabel': ([ctypes.c_int, ctypes.c_char_p], ctypes.c_int),
            'ProgressBarSetColors': ([ctypes.c_int] + [ctypes.c_int] * 8, ctypes.c_int),
        }
        
        # =================================================================
        # LABEL WIDGET SYSTEM
        # =================================================================
        label_functions = {
            'LabelCreate': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_char_p], ctypes.c_int),
            'DrawLabel': ([ctypes.c_int], ctypes.c_int),
            'LabelDestroy': ([ctypes.c_int], ctypes.c_int),
            'LabelSetText': ([ctypes.c_int, ctypes.c_char_p], ctypes.c_int),
            'LabelSetTextStringId': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'LabelSetStyle': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'LabelSetVisible': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'LabelIsVisible': ([ctypes.c_int], ctypes.c_int),
        }
        
        # =================================================================
        # ADDITIONAL WIDGET SYSTEMS
        # =================================================================
        additional_functions = {
            # StatusBar
            'StatusBarCreate': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'StatusBarAddPanel': ([ctypes.c_int, ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'StatusBarSetPanelText': ([ctypes.c_int, ctypes.c_int, ctypes.c_char_p], ctypes.c_int),
            'DrawStatusBar': ([ctypes.c_int], ctypes.c_int),
            
            # ListView
            'ListViewCreate': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'ListViewAddItem': ([ctypes.c_int, ctypes.c_char_p, ctypes.c_int], ctypes.c_int),
            'ListViewClear': ([ctypes.c_int], ctypes.c_int),
            'DrawListView': ([ctypes.c_int], ctypes.c_int),
            
            # ContextMenu
            'ContextMenuCreate': ([], ctypes.c_int),
            'ContextMenuAddItem': ([ctypes.c_int, ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p], ctypes.c_int),
            'ContextMenuShow': ([ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'DrawContextMenu': ([ctypes.c_int], ctypes.c_int),
            
            # Editor
            'EditorCreate': ([ctypes.c_float, ctypes.c_float, ctypes.c_float, ctypes.c_float], ctypes.c_int),
            'EditorLoadText': ([ctypes.c_int, ctypes.c_char_p], ctypes.c_int),
            'EditorSetLanguage': ([ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'DrawEditor': ([ctypes.c_int], ctypes.c_int),
            
            # TabControl
            'TabControlCreate': ([ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int], ctypes.c_int),
            'TabControlAddTab': ([ctypes.c_int, ctypes.c_char_p], ctypes.c_int),
            'DrawTabControl': ([ctypes.c_int], ctypes.c_int),
        }
        
        # Combine all function dictionaries
        all_functions = {}
        all_functions.update(core_functions)
        all_functions.update(string_functions)
        all_functions.update(drawing_functions)
        all_functions.update(text_functions)
        all_functions.update(button_functions)
        all_functions.update(checkbox_functions)
        all_functions.update(slider_functions)
        all_functions.update(progressbar_functions)
        all_functions.update(label_functions)
        all_functions.update(additional_functions)
        
        # Set up all bindings
        bound_count = 0
        missing_count = 0
        
        for func_name, (argtypes, restype) in all_functions.items():
            if self._setup_function(func_name, argtypes, restype):
                bound_count += 1
            else:
                missing_count += 1
        
        print(f"✅ Bound {bound_count} functions")
        print(f"⚠️  Missing {missing_count} functions")
        print(f"📊 Total function signatures: {len(all_functions)}")
    
    def get_function(self, name):
        """Get a bound function by name"""
        return self.functions.get(name)
    
    def has_function(self, name):
        """Check if a function is available"""
        return name in self.functions
    
    def list_available_functions(self):
        """List all available functions"""
        return list(self.functions.keys())
    
    def list_missing_functions(self, category=None):
        """List functions that are defined but not available in library"""
        # This would compare against the full function list
        pass

# Global instance
_bindings = None

def get_bindings():
    """Get the global bindings instance"""
    global _bindings
    if _bindings is None:
        _bindings = MojoGUIBindings()
    return _bindings

def reload_bindings():
    """Reload the bindings (useful after library recompilation)"""
    global _bindings
    _bindings = None
    return get_bindings()

if __name__ == "__main__":
    print("🔗 MojoGUI Low-Level Bindings")
    print("============================")
    
    bindings = get_bindings()
    
    available = bindings.list_available_functions()
    print(f"\n📋 Available functions: {len(available)}")
    
    # Group by category
    categories = {
        'Core': [f for f in available if f.startswith(('Win', 'Frame', 'Event'))],
        'Drawing': [f for f in available if f.startswith('Draw')],
        'Text': [f for f in available if f.startswith(('Font', 'Text', 'Load'))],
        'Button': [f for f in available if f.startswith('Button')],
        'CheckBox': [f for f in available if 'CheckBox' in f],
        'Slider': [f for f in available if f.startswith('Slider')],
        'Other': [f for f in available if not any(f.startswith(prefix) for prefix in 
                 ['Win', 'Frame', 'Event', 'Draw', 'Font', 'Text', 'Load', 'Button', 'Slider']) and 'CheckBox' not in f]
    }
    
    for category, funcs in categories.items():
        if funcs:
            print(f"\n{category} ({len(funcs)} functions):")
            for func in sorted(funcs)[:5]:  # Show first 5
                print(f"  ✓ {func}")
            if len(funcs) > 5:
                print(f"  ... and {len(funcs) - 5} more")