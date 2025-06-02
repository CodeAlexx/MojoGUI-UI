#!/usr/bin/env python3
"""
MojoGUI Python Bindings Package
Multi-layer wrapper system for MojoGUI C library
"""

from .low_level_bindings import get_bindings, reload_bindings
from .mid_level_wrappers import get_wrappers, reload_wrappers
from .high_level_api import (
    Application, MojoGUI, Widget, Button, CheckBox, Slider, 
    ProgressBar, Label, Canvas, create_app, quick_demo
)
from .menu_widgets import (
    MenuWidget, ContextMenuWidget, MenuBarWidget,
    MenuCreate, ContextMenuCreate, MenuBarCreate,
    MenuAddItem, ContextMenuAddItem, ContextMenuShow, ContextMenuHide
)
from .advanced_widgets import (
    ListViewWidget, TabControlWidget, DialogWidget, EditorWidget,
    ListViewCreate, TabControlCreate, DialogCreate, EditorCreate,
    ListViewAddItem, TabControlAddTab, DialogAddButton, DialogShow, EditorLoadText
)

# Convenience functions for different abstraction levels
def WinInit():
    """Initialize window system (high-level convenience)"""
    wrappers = get_wrappers()
    return wrappers.win_init() == 0

def WinSetSize(width, height):
    """Set window size (high-level convenience)"""
    wrappers = get_wrappers()
    return wrappers.win_set_size(width, height) == 0

def WinCreate():
    """Create window (high-level convenience)"""
    wrappers = get_wrappers()
    return wrappers.win_create() == 0

def FrameBegin():
    """Begin frame (high-level convenience)"""
    wrappers = get_wrappers()
    return wrappers.frame_begin() == 0

def FrameEnd():
    """End frame (high-level convenience)"""
    wrappers = get_wrappers()
    return wrappers.frame_end() == 0

def EventPoll():
    """Poll events (high-level convenience)"""
    wrappers = get_wrappers()
    return wrappers.event_poll() == 0

def DrawSetColor(r, g, b, a=1.0):
    """Set drawing color (high-level convenience)"""
    wrappers = get_wrappers()
    return wrappers.draw_set_color(r, g, b, a) == 0

def DrawSetPos(x, y):
    """Set drawing position (high-level convenience)"""
    wrappers = get_wrappers()
    return wrappers.draw_set_pos(x, y) == 0

def DrawRect(width, height):
    """Draw rectangle (high-level convenience)"""
    wrappers = get_wrappers()
    return wrappers.draw_rect(width, height) == 0

def DrawCircle(radius, segments=32):
    """Draw circle (high-level convenience)"""
    wrappers = get_wrappers()
    return wrappers.draw_circle(radius, segments) == 0

# Widget creation convenience functions
def CreateButton(x, y, width, height, text="Button"):
    """Create button widget (middleman function)"""
    return Button(x, y, width, height, text)

def CreateCheckBox(x, y, width, height, enhanced=False):
    """Create checkbox widget (middleman function)"""
    return CheckBox(x, y, width, height, enhanced)

def CreateSlider(x, y, width, height, orientation=0, min_val=0, max_val=100):
    """Create slider widget (middleman function)"""
    return Slider(x, y, width, height, orientation, min_val, max_val)

def CreateProgressBar(x, y, width, height, style=0):
    """Create progress bar widget (middleman function)"""
    return ProgressBar(x, y, width, height, style)

def CreateLabel(x, y, width, height, text="Label"):
    """Create label widget (middleman function)"""
    return Label(x, y, width, height, text)

# Advanced widget creation convenience functions
def CreateMenu(x=0, y=0, width=200, height=30):
    """Create menu widget (middleman function)"""
    return MenuCreate(x, y, width, height)

def CreateContextMenu():
    """Create context menu widget (middleman function)"""
    return ContextMenuCreate()

def CreateMenuBar(x=0, y=0, width=800, height=30):
    """Create menu bar widget (middleman function)"""
    return MenuBarCreate(x, y, width, height)

def CreateListView(x, y, width, height):
    """Create listview widget (middleman function)"""
    return ListViewCreate(x, y, width, height)

def CreateTabControl(x, y, width, height):
    """Create tabcontrol widget (middleman function)"""
    return TabControlCreate(x, y, width, height)

def CreateDialog(title="Dialog", width=300, height=200):
    """Create dialog widget (middleman function)"""
    return DialogCreate(title, width, height)

def CreateEditor(x, y, width, height):
    """Create editor widget (middleman function)"""
    return EditorCreate(x, y, width, height)

# Package information
__version__ = "1.0.0"
__author__ = "MojoGUI Python Bindings"
__description__ = "Multi-layer Python wrapper for MojoGUI C library"

# Export main interfaces
__all__ = [
    # Low-level
    'get_bindings', 'reload_bindings',
    
    # Mid-level
    'get_wrappers', 'reload_wrappers',
    
    # High-level classes
    'Application', 'MojoGUI', 'Widget', 'Button', 'CheckBox', 
    'Slider', 'ProgressBar', 'Label', 'Canvas',
    
    # Application helpers
    'create_app', 'quick_demo',
    
    # Convenience functions (middleman layer)
    'WinInit', 'WinSetSize', 'WinCreate', 'FrameBegin', 'FrameEnd', 'EventPoll',
    'DrawSetColor', 'DrawSetPos', 'DrawRect', 'DrawCircle',
    'CreateButton', 'CreateCheckBox', 'CreateSlider', 'CreateProgressBar', 'CreateLabel',
    
    # Menu and advanced widget functions
    'CreateMenu', 'CreateContextMenu', 'CreateMenuBar', 'CreateListView',
    'CreateTabControl', 'CreateDialog', 'CreateEditor',
    
    # Menu and advanced widget classes
    'MenuWidget', 'ContextMenuWidget', 'MenuBarWidget', 'ListViewWidget',
    'TabControlWidget', 'DialogWidget', 'EditorWidget'
]