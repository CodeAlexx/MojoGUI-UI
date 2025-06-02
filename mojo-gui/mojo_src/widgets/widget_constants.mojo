"""
Common constants used across Mojo GUI widgets
"""

# Text alignment constants
alias ALIGN_START = 0      # Left for LTR, Right for RTL
alias ALIGN_CENTER = 1     # Center alignment
alias ALIGN_END = 2        # Right for LTR, Left for RTL
alias ALIGN_LEFT = 0       # Always left
alias ALIGN_RIGHT = 2      # Always right
alias ALIGN_TOP = 0        # Top alignment
alias ALIGN_MIDDLE = 1     # Middle/center vertical alignment
alias ALIGN_BOTTOM = 2     # Bottom alignment

# Widget states
alias STATE_NORMAL = 0
alias STATE_HOVER = 1
alias STATE_PRESSED = 2
alias STATE_FOCUSED = 3
alias STATE_DISABLED = 4
alias STATE_SELECTED = 5

# Mouse buttons
alias MOUSE_BUTTON_LEFT = 0
alias MOUSE_BUTTON_RIGHT = 1
alias MOUSE_BUTTON_MIDDLE = 2

# Key codes (common ones)
alias KEY_BACKSPACE = 259
alias KEY_DELETE = 261
alias KEY_RIGHT = 262
alias KEY_LEFT = 263
alias KEY_DOWN = 264
alias KEY_UP = 265
alias KEY_PAGE_UP = 266
alias KEY_PAGE_DOWN = 267
alias KEY_HOME = 268
alias KEY_END = 269
alias KEY_INSERT = 260
alias KEY_ENTER = 257
alias KEY_TAB = 258
alias KEY_ESCAPE = 256
alias KEY_SPACE = 32

# Key modifiers
alias KEY_MOD_SHIFT = 1
alias KEY_MOD_CTRL = 2
alias KEY_MOD_ALT = 4
alias KEY_MOD_SUPER = 8

# Orientation
alias ORIENTATION_HORIZONTAL = 0
alias ORIENTATION_VERTICAL = 1

# Direction
alias DIRECTION_LEFT_TO_RIGHT = 0
alias DIRECTION_RIGHT_TO_LEFT = 1
alias DIRECTION_TOP_TO_BOTTOM = 2
alias DIRECTION_BOTTOM_TO_TOP = 3

# Sizing modes
alias SIZE_FIXED = 0
alias SIZE_EXPAND = 1
alias SIZE_SHRINK = 2
alias SIZE_FILL = 3

# Overflow modes
alias OVERFLOW_VISIBLE = 0
alias OVERFLOW_HIDDEN = 1
alias OVERFLOW_SCROLL = 2
alias OVERFLOW_AUTO = 3

# Selection modes
alias SELECTION_NONE = 0
alias SELECTION_SINGLE = 1
alias SELECTION_MULTIPLE = 2
alias SELECTION_EXTENDED = 3

# Sort order
alias SORT_NONE = 0
alias SORT_ASCENDING = 1
alias SORT_DESCENDING = 2

# Dialog results
alias DIALOG_OK = 1
alias DIALOG_CANCEL = 2
alias DIALOG_YES = 3
alias DIALOG_NO = 4
alias DIALOG_RETRY = 5
alias DIALOG_ABORT = 6

# Message box types
alias MSGBOX_INFO = 0
alias MSGBOX_WARNING = 1
alias MSGBOX_ERROR = 2
alias MSGBOX_QUESTION = 3

# File dialog modes
alias FILE_OPEN = 0
alias FILE_SAVE = 1
alias FILE_SELECT_FOLDER = 2

# Common colors (as ColorInt)
from ..rendering_int import ColorInt

alias COLOR_BLACK = ColorInt(0, 0, 0, 255)
alias COLOR_WHITE = ColorInt(255, 255, 255, 255)
alias COLOR_RED = ColorInt(255, 0, 0, 255)
alias COLOR_GREEN = ColorInt(0, 255, 0, 255)
alias COLOR_BLUE = ColorInt(0, 0, 255, 255)
alias COLOR_GRAY = ColorInt(128, 128, 128, 255)
alias COLOR_LIGHT_GRAY = ColorInt(192, 192, 192, 255)
alias COLOR_DARK_GRAY = ColorInt(64, 64, 64, 255)
alias COLOR_TRANSPARENT = ColorInt(0, 0, 0, 0)

# Theme colors
alias COLOR_PRIMARY = ColorInt(70, 130, 180, 255)      # Steel blue
alias COLOR_SECONDARY = ColorInt(106, 153, 85, 255)    # Green
alias COLOR_ACCENT = ColorInt(220, 220, 170, 255)      # Yellow
alias COLOR_SUCCESS = ColorInt(46, 204, 113, 255)      # Emerald
alias COLOR_WARNING = ColorInt(241, 196, 15, 255)      # Sun flower
alias COLOR_ERROR = ColorInt(231, 76, 60, 255)         # Alizarin
alias COLOR_INFO = ColorInt(52, 152, 219, 255)         # Peter river

# Default sizes
alias DEFAULT_BUTTON_HEIGHT = 30
alias DEFAULT_TEXTBOX_HEIGHT = 28
alias DEFAULT_TOOLBAR_HEIGHT = 32
alias DEFAULT_STATUSBAR_HEIGHT = 24
alias DEFAULT_SCROLLBAR_WIDTH = 15
alias DEFAULT_FONT_SIZE = 12
alias DEFAULT_ICON_SIZE = 16
alias DEFAULT_MARGIN = 8
alias DEFAULT_PADDING = 4
alias DEFAULT_BORDER_WIDTH = 1