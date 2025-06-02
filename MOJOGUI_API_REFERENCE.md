# MojoGUI Complete API Reference (CORRECTED)

**IMPORTANT**: This document contains the **ACTUAL** function signatures from the MojoGUI implementation. The previous version had incorrect Float32 parameters - this version shows the correct Int32-based interface.

## Table of Contents
- [Window Management](#window-management)
- [Event System](#event-system)
- [Drawing System](#drawing-system)
- [Font & Text System](#font--text-system)
- [Menu System](#menu-system)
- [Dialog System](#dialog-system)
- [ListView Widget](#listview-widget)
- [Slider Widget](#slider-widget)
- [CheckBox Widget](#checkbox-widget)
- [TextArea Widget](#textarea-widget)
- [ProgressBar Widget](#progressbar-widget)
- [TabControl Widget](#tabcontrol-widget)
- [StatusBar Widget](#statusbar-widget)
- [TreeView Widget](#treeview-widget)
- [Tooltip System](#tooltip-system)
- [Context Menu System](#context-menu-system)
- [Helper Functions](#helper-functions)

## Window Management

### Core Window Functions
```mojo
WinInit() -> Int32                                    # Initialize GLFW
WinSetSize(width: Int32, height: Int32) -> Int32     # Set window dimensions
WinSetTitle(string_id: Int32) -> Int32               # Set window title from string ID
WinCreate() -> Int32                                  # Create window with OpenGL context
WinDestroy(window_id: Int32) -> Int32                # Destroy window and cleanup
```

### Frame Management
```mojo
FrameBegin() -> Int32                                 # Begin frame rendering (clear buffers)
FrameEnd() -> Int32                                   # End frame rendering (swap buffers)
```

## Event System

### Event Constants
```mojo
EVENT_NONE = 0
EVENT_CLOSE = 10
EVENT_KEY_PRESS = 2
EVENT_KEY_RELEASE = 3
EVENT_MOUSE_PRESS = 4
EVENT_MOUSE_RELEASE = 5
EVENT_MOUSE_MOVE = 6
```

### Event Functions
```mojo
EventPoll() -> Int32                                  # Poll for events
EventGetKey() -> Int32                                # Get key code from last key event
EventGetChar() -> Int32                               # Get character from last key event
EventGetMouseX() -> Int32                             # Get mouse X position
EventGetMouseY() -> Int32                             # Get mouse Y position
EventGetMouseButton() -> Int32                        # Get mouse button from last event

# Float32 workaround functions for FFI bugs
EventGetMouseXf() -> Float32                          # Get mouse X as Float32
EventGetMouseYf() -> Float32                          # Get mouse Y as Float32
```

## Drawing System

### Basic Drawing (All parameters are Int32)
```mojo
DrawSetColor(r: Int32, g: Int32, b: Int32, a: Int32) -> Int32  # Colors 0-255 range
DrawSetPos(x: Int32, y: Int32) -> Int32                       # Integer coordinates
DrawRect(width: Int32, height: Int32) -> Int32                # Integer dimensions
DrawRoundedRect(width: Int32, height: Int32, radius: Int32) -> Int32
DrawCircle(radius: Int32, segments: Int32) -> Int32
```

### Advanced Drawing (All parameters are Int32)
```mojo
DrawGradientRect(width: Int32, height: Int32, 
                r1: Int32, g1: Int32, b1: Int32, a1: Int32,
                r2: Int32, g2: Int32, b2: Int32, a2: Int32) -> Int32
DrawShadow(width: Int32, height: Int32, 
          offset_x: Int32, offset_y: Int32, blur: Int32) -> Int32
```

## Font & Text System

### Font Style Constants
```mojo
FONT_STYLE_NORMAL = 0
FONT_STYLE_BOLD = 1
FONT_STYLE_ITALIC = 2
FONT_STYLE_BOLD_ITALIC = 3
FONT_STYLE_UNDERLINE = 4
FONT_STYLE_STRIKETHROUGH = 5
FONT_STYLE_OUTLINE = 6
FONT_STYLE_SHADOW = 7
```

### Font Management
```mojo
FontLoad(font_id: Int32, font_name: String, size: Float32) -> Int32  # Size is Float32
FontSetCurrent(font_id: Int32) -> Int32
FontGetCurrent() -> Int32
FontGetLineHeight(font_id: Int32) -> Float32
FontGetAscender(font_id: Int32) -> Float32
FontGetDescender(font_id: Int32) -> Float32
```

### Text Rendering (Font sizes are Int32)
```mojo
DrawText(string_id: Int32, font_size: Int32) -> Int32
DrawTextDirect(text: String, font_size: Int32) -> Int32
DrawTextWithCursor(string_id: Int32, font_size: Int32, 
                  cursor_pos: Int32, focused: Int32) -> Int32
TextGetWidth(string_id: Int32, font_size: Int32, char_count: Int32) -> Float32
```

### Text Editing
```mojo
TextEditInit(edit_id: Int32, max_length: Int32) -> Int32
TextEditSetText(edit_id: Int32, string_id: Int32) -> Int32
TextEditGetText(edit_id: Int32, string_id: Int32) -> Int32
TextEditInsertChar(edit_id: Int32, ch: Int32) -> Int32
TextEditBackspace(edit_id: Int32) -> Int32
TextEditDelete(edit_id: Int32) -> Int32
TextEditMoveCursor(edit_id: Int32, direction: Int32) -> Int32
TextEditGetCursor(edit_id: Int32) -> Int32
```

### String Management
```mojo
StrClear(string_id: Int32) -> Int32
StrRegister(ch: Int32, position: Int32, string_id: Int32) -> Int32
```

## Menu System

### Menu Functions
```mojo
MenuSystemInit() -> Int32
MenuCreate(label: String) -> Int32
MenuAddItem(menu_id: Int32, label: String, shortcut: String, enabled: Int32) -> Int32
MenuAddSeparator(menu_id: Int32) -> Int32
DrawMenuBar(x: Float32, y: Float32, width: Float32) -> Int32      # Menu uses Float32
MenuHandleMouseClick(mouse_x: Int32, mouse_y: Int32) -> Int32    # Mouse coords Int32
MenuUpdateHover(mouse_x: Int32, mouse_y: Int32) -> Int32
MenuIsActive() -> Int32
MenuCloseAll() -> Int32
```

## Dialog System

### Dialog Functions
```mojo
DialogShow(message: String, duration: Float32) -> Int32
DialogHide() -> Int32
DrawDialog() -> Int32
DialogHandleClick(mouse_x: Int32, mouse_y: Int32) -> Int32
DialogHandleKey(key_code: Int32) -> Int32
```

## ListView Widget

### ListView Functions (Positions/sizes are Int32)
```mojo
ListViewCreate(x: Int32, y: Int32, width: Int32, height: Int32) -> Int32
ListViewAddItem(listview_id: Int32, text: String, data_id: Int32) -> Int32
ListViewClear(listview_id: Int32) -> Int32
ListViewSetSelection(listview_id: Int32, selection_mode: Int32) -> Int32
ListViewSelectItem(listview_id: Int32, item_index: Int32, add_to_selection: Int32) -> Int32
ListViewGetSelectedCount(listview_id: Int32) -> Int32
ListViewHandleClick(listview_id: Int32, mouse_x: Int32, mouse_y: Int32) -> Int32
ListViewHandleKey(listview_id: Int32, key_code: Int32) -> Int32
ListViewScroll(listview_id: Int32, delta: Float32) -> Int32
DrawListView(listview_id: Int32) -> Int32
```

## Slider Widget

### Slider Functions (Positions are Int32, values are Float32)
```mojo
SliderCreate(x: Int32, y: Int32, width: Int32, height: Int32, 
            orientation: Int32) -> Int32  # orientation: 0=horizontal, 1=vertical
SliderSetRange(slider_id: Int32, min_value: Float32, max_value: Float32) -> Int32
SliderSetValue(slider_id: Int32, value: Float32) -> Int32
SliderGetValue(slider_id: Int32) -> Float32
SliderSetStep(slider_id: Int32, step: Float32) -> Int32
SliderSetColors(slider_id: Int32, 
               track_r: Float32, track_g: Float32, track_b: Float32,
               active_r: Float32, active_g: Float32, active_b: Float32,
               thumb_r: Float32, thumb_g: Float32, thumb_b: Float32) -> Int32
SliderSetProperties(slider_id: Int32, show_ticks: Int32, tick_interval: Float32,
                   show_value_label: Int32, show_min_max_labels: Int32) -> Int32
SliderHandleClick(slider_id: Int32, mouse_x: Int32, mouse_y: Int32) -> Int32
SliderHandleHover(slider_id: Int32, mouse_x: Int32, mouse_y: Int32) -> Int32
SliderHandleDrag(slider_id: Int32, mouse_x: Int32, mouse_y: Int32) -> Int32
SliderHandleRelease(slider_id: Int32) -> Int32
SliderSetFocus(slider_id: Int32, focused: Int32) -> Int32
SliderGetFocused() -> Int32
SliderHandleKey(slider_id: Int32, key_code: Int32) -> Int32
DrawSlider(slider_id: Int32) -> Int32
```

## CheckBox Widget

### CheckBox Functions (Positions are Int32, colors are Float32)
```mojo
CheckBoxCreate(x: Int32, y: Int32, width: Int32, height: Int32, 
              checkbox_type: Int32) -> Int32  # type: 0=standard, 1=switch
CheckBoxSetState(checkbox_id: Int32, state: Int32) -> Int32  # 0=unchecked, 1=checked, 2=indeterminate
CheckBoxGetState(checkbox_id: Int32) -> Int32
CheckBoxToggle(checkbox_id: Int32) -> Int32
CheckBoxSetTriState(checkbox_id: Int32, enabled: Int32) -> Int32
CheckBoxSetLabel(checkbox_id: Int32, label: String, position: Int32) -> Int32
CheckBoxSetColors(checkbox_id: Int32,
                 border_r: Float32, border_g: Float32, border_b: Float32,
                 fill_r: Float32, fill_g: Float32, fill_b: Float32,
                 check_r: Float32, check_g: Float32, check_b: Float32) -> Int32
CheckBoxSetSwitchColors(checkbox_id: Int32,
                       track_off_r: Float32, track_off_g: Float32, track_off_b: Float32,
                       track_on_r: Float32, track_on_g: Float32, track_on_b: Float32,
                       thumb_r: Float32, thumb_g: Float32, thumb_b: Float32) -> Int32
CheckBoxHandleClick(checkbox_id: Int32, mouse_x: Int32, mouse_y: Int32) -> Int32
CheckBoxHandleKey(checkbox_id: Int32, key_code: Int32) -> Int32
DrawCheckBox(checkbox_id: Int32) -> Int32
```

## TextArea Widget

### TextArea Functions (Positions are Int32)
```mojo
TextAreaCreate(x: Int32, y: Int32, width: Int32, height: Int32) -> Int32
TextAreaSetText(textarea_id: Int32, text: String) -> Int32
TextAreaGetText(textarea_id: Int32, buffer_size: Int32) -> String
TextAreaInsertText(textarea_id: Int32, text: String) -> Int32
TextAreaDeleteSelection(textarea_id: Int32) -> Int32
TextAreaMoveCursor(textarea_id: Int32, line_delta: Int32, column_delta: Int32) -> Int32
TextAreaEnsureCursorVisible(textarea_id: Int32) -> Int32
TextAreaHandleClick(textarea_id: Int32, mouse_x: Int32, mouse_y: Int32) -> Int32
TextAreaHandleMouseDown(textarea_id: Int32, mouse_x: Int32, mouse_y: Int32) -> Int32
TextAreaHandleMouseDrag(textarea_id: Int32, mouse_x: Int32, mouse_y: Int32) -> Int32
TextAreaHandleMouseUp(textarea_id: Int32, mouse_x: Int32, mouse_y: Int32) -> Int32
TextAreaHandleKey(textarea_id: Int32, key_code: Int32) -> Int32
TextAreaHandleChar(textarea_id: Int32, codepoint: UInt32) -> Int32
DrawTextArea(textarea_id: Int32) -> Int32
```

## Scrollbar System (Mixed Int32/Float32)

### Scrollbar Functions
```mojo
ScrollbarInit(scrollbar_id: Int32, content_size: Float32, view_size: Float32) -> Int32
ScrollbarSetPosition(scrollbar_id: Int32, position: Float32) -> Int32
ScrollbarGetPosition(scrollbar_id: Int32) -> Float32
ScrollbarGetContentOffset(scrollbar_id: Int32) -> Float32
ScrollbarHandleMouseDown(scrollbar_id: Int32, mouse_x: Float32, mouse_y: Float32,
                        track_x: Float32, track_y: Float32, 
                        track_width: Float32, track_height: Float32, vertical: Int32) -> Int32
ScrollbarHandleMouseDrag(scrollbar_id: Int32, mouse_x: Float32, mouse_y: Float32,
                        track_x: Float32, track_y: Float32,
                        track_width: Float32, track_height: Float32, vertical: Int32) -> Int32
ScrollbarHandleMouseUp(scrollbar_id: Int32) -> Int32
ScrollbarHandleWheel(scrollbar_id: Int32, delta: Float32) -> Int32
DrawScrollbarVertical(x: Float32, y: Float32, width: Float32, height: Float32, 
                     scrollbar_id: Int32) -> Int32
DrawScrollbarHorizontal(x: Float32, y: Float32, width: Float32, height: Float32,
                       scrollbar_id: Int32) -> Int32

# Int32 wrapper functions for Mojo compatibility
UIScrollbarHandleMouseDown(scrollbar_id: Int32, mouse_x: Int32, mouse_y: Int32,
                          track_x: Float32, track_y: Float32, 
                          track_width: Float32, track_height: Float32, vertical: Int32) -> Int32
UIScrollbarHandleMouseDrag(scrollbar_id: Int32, mouse_x: Int32, mouse_y: Int32,
                          track_x: Float32, track_y: Float32,
                          track_width: Float32, track_height: Float32, vertical: Int32) -> Int32
```

## Helper Functions

### UI Hit Detection (Mouse coords Int32, bounds Float32)
```mojo
UICheckButtonHit(mouse_x: Int32, mouse_y: Int32, 
                btn_x: Float32, btn_y: Float32, btn_w: Float32, btn_h: Float32) -> Int32
UICheckInputFieldHit(mouse_x: Int32, mouse_y: Int32,
                    field_x: Float32, field_y: Float32, field_w: Float32, field_h: Float32) -> Int32
UICheckScrollbarHit(mouse_x: Int32, mouse_y: Int32,
                   v_x: Float32, v_y: Float32, v_w: Float32, v_h: Float32,
                   h_x: Float32, h_y: Float32, h_w: Float32, h_h: Float32) -> Int32
UICheckRectHit(mouse_x: Int32, mouse_y: Int32,
              x: Float32, y: Float32, width: Float32, height: Float32) -> Int32
UICheckCircleHit(mouse_x: Int32, mouse_y: Int32,
                center_x: Float32, center_y: Float32, radius: Float32) -> Int32
```

### Matrix Operations
```mojo
MatrixClear(matrix_id: Int32) -> Int32
MatrixSetValue(matrix_id: Int32, row: Int32, col: Int32, value: Float32) -> Int32
MatrixApply(matrix_id: Int32) -> Int32
```

### Shader System
```mojo
ShaderCompileDefault() -> Int32
```

## Key Parameter Type Rules

### Int32 Parameters:
- **All drawing coordinates** (x, y positions)
- **All drawing dimensions** (width, height, radius)
- **All color values** (0-255 range for r, g, b, a)
- **All mouse coordinates** (mouse_x, mouse_y)
- **All font sizes** (for text rendering)
- **All widget positions and sizes**
- **All IDs** (widget_id, string_id, font_id, etc.)
- **All state values** (checked, enabled, focused, etc.)

### Float32 Parameters:
- **Font loading size** (FontLoad size parameter)
- **Slider values** (min_value, max_value, current value)
- **Scrollbar positions** (0.0 to 1.0 range)
- **Color components for some color functions** (0.0 to 1.0 range)
- **Hit detection bounds** (widget boundaries)
- **Matrix values**
- **Menu bar coordinates**
- **Dialog duration**

### String Parameters:
- **Text content** (labels, messages, etc.)
- **Font names**
- **File paths**

## Usage Example (Corrected)

```mojo
from mojo_gui_glfw import MojoGUIGLFW, register_string_glfw
from mojo_gui_glfw import EVENT_CLOSE, EVENT_KEY_PRESS, EVENT_MOUSE_PRESS

fn main() raises:
    var gui = MojoGUIGLFW()
    
    # Initialize window
    _ = gui.WinInit()
    _ = gui.WinSetSize(1200, 800)  # Int32 coordinates
    register_string_glfw(gui, "Complete GUI Demo", 0)
    _ = gui.WinSetTitle(0)
    _ = gui.WinCreate()
    
    # Initialize fonts
    _ = gui.FontLoad(0, "Normal", 16.0)  # Float32 size for loading
    _ = gui.FontLoad(1, "Bold", 16.0)
    
    # Create widgets with Int32 coordinates
    var slider_id = gui.SliderCreate(100, 100, 200, 30, 0)  # All Int32
    _ = gui.SliderSetRange(slider_id, 0.0, 100.0)  # Float32 values
    
    var checkbox_id = gui.CheckBoxCreate(100, 150, 20, 20, 0)  # All Int32
    _ = gui.CheckBoxSetLabel(checkbox_id, "Enable feature", 0)
    
    # Main loop
    while True:
        var event = gui.EventPoll()
        if event == EVENT_CLOSE:
            break
            
        _ = gui.FrameBegin()
        
        # Drawing with Int32 coordinates and colors
        _ = gui.DrawSetColor(255, 255, 255, 255)  # Int32 colors 0-255
        _ = gui.DrawSetPos(0, 0)  # Int32 coordinates
        _ = gui.DrawRect(1200, 800)  # Int32 dimensions
        
        # Text with Int32 font size
        _ = gui.DrawSetColor(0, 0, 0, 255)  # Black text
        _ = gui.DrawSetPos(50, 50)
        _ = gui.DrawText(0, 24)  # Int32 font size
        
        # Draw widgets
        _ = gui.DrawSlider(slider_id)
        _ = gui.DrawCheckBox(checkbox_id)
        
        _ = gui.FrameEnd()
    
    _ = gui.WinDestroy(0)
```

## Important Notes

1. **Color Values**: Use 0-255 Int32 range, not 0.0-1.0 Float32
2. **Coordinates**: All positions and sizes are Int32
3. **Font Sizes**: Text rendering uses Int32 font sizes
4. **Mouse Coordinates**: Always Int32 from event system
5. **Mixed Types**: Some functions mix Int32 and Float32 (especially sliders and scrollbars)
6. **Hit Detection**: Mouse coords are Int32, but widget bounds can be Float32

This corrected reference accurately reflects the actual MojoGUI implementation!