"""
Theme System for MojoGUI
Provides theme colors and styling for widgets.
"""

# Color struct for theme system (self-contained)
@register_passable("trivial")
struct ThemeColor:
    """RGBA color representation using integers (0-255)."""
    var r: Int32
    var g: Int32
    var b: Int32
    var a: Int32

    fn __init__(out self, r: Int32, g: Int32, b: Int32, a: Int32 = 255):
        self.r = r
        self.g = g
        self.b = b
        self.a = a

# Theme color palette
struct ThemeColors(Copyable, Movable):
    """Color palette for the current theme."""
    # Button states
    var button_normal: ThemeColor
    var button_hover: ThemeColor
    var button_pressed: ThemeColor
    var button_disabled: ThemeColor

    # Text colors
    var primary_text: ThemeColor
    var secondary_text: ThemeColor
    var disabled_text: ThemeColor

    # Border colors
    var primary_border: ThemeColor
    var focus_border: ThemeColor

    # Background colors
    var background: ThemeColor
    var surface: ThemeColor
    var panel: ThemeColor

    # Accent colors
    var accent: ThemeColor
    var accent_hover: ThemeColor

    # State colors
    var success: ThemeColor
    var warning: ThemeColor
    var error: ThemeColor

    fn __init__(out self):
        """Initialize with default dark theme colors."""
        # Button states
        self.button_normal = ThemeColor(60, 65, 75, 255)
        self.button_hover = ThemeColor(75, 80, 95, 255)
        self.button_pressed = ThemeColor(50, 55, 65, 255)
        self.button_disabled = ThemeColor(45, 48, 55, 255)

        # Text colors
        self.primary_text = ThemeColor(220, 220, 230, 255)
        self.secondary_text = ThemeColor(160, 160, 170, 255)
        self.disabled_text = ThemeColor(100, 100, 110, 255)

        # Border colors
        self.primary_border = ThemeColor(70, 75, 85, 255)
        self.focus_border = ThemeColor(100, 150, 220, 255)

        # Background colors
        self.background = ThemeColor(30, 32, 40, 255)
        self.surface = ThemeColor(40, 42, 52, 255)
        self.panel = ThemeColor(45, 48, 58, 255)

        # Accent colors
        self.accent = ThemeColor(70, 130, 200, 255)
        self.accent_hover = ThemeColor(90, 150, 220, 255)

        # State colors
        self.success = ThemeColor(80, 180, 100, 255)
        self.warning = ThemeColor(220, 180, 60, 255)
        self.error = ThemeColor(200, 80, 80, 255)

    fn __copyinit__(out self, existing: Self):
        self.button_normal = existing.button_normal
        self.button_hover = existing.button_hover
        self.button_pressed = existing.button_pressed
        self.button_disabled = existing.button_disabled
        self.primary_text = existing.primary_text
        self.secondary_text = existing.secondary_text
        self.disabled_text = existing.disabled_text
        self.primary_border = existing.primary_border
        self.focus_border = existing.focus_border
        self.background = existing.background
        self.surface = existing.surface
        self.panel = existing.panel
        self.accent = existing.accent
        self.accent_hover = existing.accent_hover
        self.success = existing.success
        self.warning = existing.warning
        self.error = existing.error

    fn __moveinit__(out self, deinit existing: Self):
        self.button_normal = existing.button_normal
        self.button_hover = existing.button_hover
        self.button_pressed = existing.button_pressed
        self.button_disabled = existing.button_disabled
        self.primary_text = existing.primary_text
        self.secondary_text = existing.secondary_text
        self.disabled_text = existing.disabled_text
        self.primary_border = existing.primary_border
        self.focus_border = existing.focus_border
        self.background = existing.background
        self.surface = existing.surface
        self.panel = existing.panel
        self.accent = existing.accent
        self.accent_hover = existing.accent_hover
        self.success = existing.success
        self.warning = existing.warning
        self.error = existing.error

    fn copy(self) -> Self:
        """Create an explicit copy."""
        var result = Self()
        result.button_normal = self.button_normal
        result.button_hover = self.button_hover
        result.button_pressed = self.button_pressed
        result.button_disabled = self.button_disabled
        result.primary_text = self.primary_text
        result.secondary_text = self.secondary_text
        result.disabled_text = self.disabled_text
        result.primary_border = self.primary_border
        result.focus_border = self.focus_border
        result.background = self.background
        result.surface = self.surface
        result.panel = self.panel
        result.accent = self.accent
        result.accent_hover = self.accent_hover
        result.success = self.success
        result.warning = self.warning
        result.error = self.error
        return result^

struct Theme(Copyable, Movable):
    """Complete theme definition."""
    var colors: ThemeColors
    var font_size: Int32
    var font_size_small: Int32
    var font_size_large: Int32
    var border_radius: Int32
    var padding: Int32
    var spacing: Int32

    fn __init__(out self):
        """Initialize with default theme settings."""
        self.colors = ThemeColors()
        self.font_size = 12
        self.font_size_small = 10
        self.font_size_large = 16
        self.border_radius = 4
        self.padding = 8
        self.spacing = 4

    fn __copyinit__(out self, existing: Self):
        self.colors = existing.colors.copy()
        self.font_size = existing.font_size
        self.font_size_small = existing.font_size_small
        self.font_size_large = existing.font_size_large
        self.border_radius = existing.border_radius
        self.padding = existing.padding
        self.spacing = existing.spacing

    fn __moveinit__(out self, deinit existing: Self):
        self.colors = existing.colors^
        self.font_size = existing.font_size
        self.font_size_small = existing.font_size_small
        self.font_size_large = existing.font_size_large
        self.border_radius = existing.border_radius
        self.padding = existing.padding
        self.spacing = existing.spacing

fn create_dark_theme() -> Theme:
    """Create a dark theme (default)."""
    return Theme()

fn create_light_theme() -> Theme:
    """Create a light theme."""
    var theme = Theme()
    theme.colors.button_normal = ThemeColor(230, 232, 235, 255)
    theme.colors.button_hover = ThemeColor(220, 222, 228, 255)
    theme.colors.button_pressed = ThemeColor(200, 205, 215, 255)
    theme.colors.button_disabled = ThemeColor(240, 242, 245, 255)
    theme.colors.primary_text = ThemeColor(30, 30, 40, 255)
    theme.colors.secondary_text = ThemeColor(80, 80, 90, 255)
    theme.colors.disabled_text = ThemeColor(150, 150, 160, 255)
    theme.colors.primary_border = ThemeColor(180, 185, 195, 255)
    theme.colors.focus_border = ThemeColor(60, 120, 200, 255)
    theme.colors.background = ThemeColor(245, 247, 250, 255)
    theme.colors.surface = ThemeColor(255, 255, 255, 255)
    theme.colors.panel = ThemeColor(240, 242, 245, 255)
    theme.colors.accent = ThemeColor(50, 120, 200, 255)
    theme.colors.accent_hover = ThemeColor(70, 140, 220, 255)
    return theme^
