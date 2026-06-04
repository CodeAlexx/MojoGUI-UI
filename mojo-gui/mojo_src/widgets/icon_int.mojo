"""
Integer-Only Icon/Image Widget Implementation
Display icons and images with theme support and multiple sizes.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .widget_constants import *

# Icon sizes
comptime ICON_SIZE_SMALL = 16
comptime ICON_SIZE_MEDIUM = 24
comptime ICON_SIZE_LARGE = 32
comptime ICON_SIZE_XLARGE = 48

# Icon types (built-in icon library)
comptime ICON_FILE = 0
comptime ICON_FOLDER = 1
comptime ICON_FOLDER_OPEN = 2
comptime ICON_DOCUMENT = 3
comptime ICON_IMAGE = 4
comptime ICON_VIDEO = 5
comptime ICON_AUDIO = 6
comptime ICON_ARCHIVE = 7
comptime ICON_CODE = 8
comptime ICON_EXECUTABLE = 9
comptime ICON_SETTINGS = 10
comptime ICON_HOME = 11
comptime ICON_STAR = 12
comptime ICON_HEART = 13
comptime ICON_SEARCH = 14
comptime ICON_PLUS = 15
comptime ICON_MINUS = 16
comptime ICON_CLOSE = 17
comptime ICON_CHECK = 18
comptime ICON_ARROW_UP = 19
comptime ICON_ARROW_DOWN = 20
comptime ICON_ARROW_LEFT = 21
comptime ICON_ARROW_RIGHT = 22
comptime ICON_REFRESH = 23
comptime ICON_SAVE = 24
comptime ICON_OPEN = 25
comptime ICON_COPY = 26
comptime ICON_CUT = 27
comptime ICON_PASTE = 28
comptime ICON_DELETE = 29
comptime ICON_UNDO = 30
comptime ICON_REDO = 31
comptime ICON_PRINT = 32
comptime ICON_INFO = 33
comptime ICON_WARNING = 34
comptime ICON_ERROR = 35
comptime ICON_QUESTION = 36

struct IconTheme(Copyable, Movable):
    """Icon theme configuration."""
    var name: String
    var is_dark: Bool
    var default_color: ColorInt
    var folder_color: ColorInt
    var file_color: ColorInt
    var accent_color: ColorInt

    fn __init__(out self, name: String, is_dark: Bool = False):
        self.name = name
        self.is_dark = is_dark
        
        if is_dark:
            self.default_color = ColorInt(200, 200, 200, 255)
            self.folder_color = ColorInt(150, 150, 255, 255)
            self.file_color = ColorInt(180, 180, 180, 255)
            self.accent_color = ColorInt(100, 200, 255, 255)
        else:
            self.default_color = ColorInt(60, 60, 60, 255)
            self.folder_color = ColorInt(80, 120, 200, 255)
            self.file_color = ColorInt(100, 100, 100, 255)
            self.accent_color = ColorInt(0, 120, 215, 255)

struct IconInt(WidgetInt, Copyable, Movable):
    """Icon display widget."""

    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var background_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32
    var icon_type: Int32
    var icon_size: Int32
    var custom_path: String
    var theme: IconTheme
    var clickable: Bool
    var hover_effect: Bool
    var is_hovered: Bool
    var is_pressed: Bool
    var badge_text: String
    var badge_color: ColorInt
    var rotation: Int32  # 0, 90, 180, 270 degrees
    var flip_horizontal: Bool
    var flip_vertical: Bool
    var opacity: Float32
    
    fn __init__(out self, x: Int32, y: Int32, icon_type: Int32,
                size: Int32 = ICON_SIZE_MEDIUM):
        self.bounds = RectInt(x, y, size, size)
        self.visible = True
        self.enabled = True
        self.background_color = ColorInt(230, 230, 230, 255)
        self.border_color = ColorInt(128, 128, 128, 255)
        self.border_width = 1
        self.icon_type = icon_type
        self.icon_size = size
        self.custom_path = ""
        self.theme = IconTheme("default", False)
        self.clickable = False
        self.hover_effect = True
        self.is_hovered = False
        self.is_pressed = False
        self.badge_text = ""
        self.badge_color = ColorInt(255, 0, 0, 255)
        self.rotation = 0
        self.flip_horizontal = False
        self.flip_vertical = False
        self.opacity = 1.0
        
        # Transparent background by default
        self.background_color = ColorInt(0, 0, 0, 0)
        self.border_width = 0

    fn get_bounds(self) -> RectInt: return self.bounds
    fn set_bounds(mut self, bounds: RectInt): self.bounds = bounds
    fn is_visible(self) -> Bool: return self.visible
    fn set_visible(mut self, visible: Bool): self.visible = visible
    fn is_enabled(self) -> Bool: return self.enabled
    fn set_enabled(mut self, enabled: Bool): self.enabled = enabled
    fn contains_point(self, point: PointInt) -> Bool: return self.bounds.contains(point)
    fn render_background(self, ctx: RenderingContextInt):
        if not self.visible: return
        _ = ctx.set_color(self.background_color.r, self.background_color.g, self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
        if self.border_width > 0:
            _ = ctx.set_color(self.border_color.r, self.border_color.g, self.border_color.b, self.border_color.a)
            _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)

    fn handle_key_event(mut self, event: KeyEventInt) -> Bool:
        return False

    fn set_icon(mut self, icon_type: Int32):
        """Change the icon type."""
        self.icon_type = icon_type
    
    fn set_size(mut self, size: Int32):
        """Change icon size."""
        self.icon_size = size
        self.bounds.width = size
        self.bounds.height = size
    
    fn set_theme(mut self, theme: IconTheme):
        """Set icon theme."""
        self.theme = theme
    
    fn set_badge(mut self, text: String, color: ColorInt = ColorInt(255, 0, 0, 255)):
        """Set badge text and color."""
        self.badge_text = text
        self.badge_color = color
    
    fn set_rotation(mut self, degrees: Int32):
        """Set icon rotation (0, 90, 180, 270)."""
        self.rotation = degrees % 360
    
    fn get_icon_color(self) -> ColorInt:
        """Get color for current icon type."""
        if self.icon_type == ICON_FOLDER or self.icon_type == ICON_FOLDER_OPEN:
            return self.theme.folder_color
        elif (self.icon_type == ICON_FILE or self.icon_type == ICON_DOCUMENT
              or self.icon_type == ICON_IMAGE or self.icon_type == ICON_VIDEO
              or self.icon_type == ICON_AUDIO or self.icon_type == ICON_ARCHIVE
              or self.icon_type == ICON_CODE):
            return self.theme.file_color
        elif (self.icon_type == ICON_STAR or self.icon_type == ICON_HEART):
            return self.theme.accent_color
        elif (self.icon_type == ICON_WARNING or self.icon_type == ICON_ERROR):
            return ColorInt(255, 200, 0, 255) if self.icon_type == ICON_WARNING else ColorInt(255, 0, 0, 255)
        else:
            return self.theme.default_color
    
    fn handle_mouse_event(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        var point = PointInt(event.x, event.y)
        var inside = self.contains_point(point)
        
        if inside:
            self.is_hovered = True
            
            if event.pressed and self.clickable:
                self.is_pressed = True
                return True
            elif not event.pressed and self.is_pressed:
                self.is_pressed = False
                return True
        else:
            self.is_hovered = False
            self.is_pressed = False
        
        return inside
    
    fn render(self, ctx: RenderingContextInt):
        """Render the icon."""
        if not self.visible:
            return
        
        # Apply hover effect
        var render_bounds = self.bounds
        if self.hover_effect and self.is_hovered:
            # Slightly enlarge on hover
            var growth = 2
            render_bounds.x -= growth
            render_bounds.y -= growth
            render_bounds.width += growth * 2
            render_bounds.height += growth * 2
        
        # Get icon color
        var color = self.get_icon_color()
        
        # Apply opacity
        if self.opacity < 1.0:
            color.a = Int32(Float32(color.a) * self.opacity)
        
        # Apply pressed effect
        if self.is_pressed:
            color.r = color.r * 3 // 4
            color.g = color.g * 3 // 4
            color.b = color.b * 3 // 4
        
        _ = ctx.set_color(color.r, color.g, color.b, color.a)
        
        # Render icon based on type
        self.render_icon_shape(ctx, render_bounds)
        
        # Render badge if present
        if len(self.badge_text) > 0:
            self.render_badge(ctx)
    
    fn render_icon_shape(self, ctx: RenderingContextInt, bounds: RectInt):
        """Render the actual icon shape."""
        var cx = bounds.x + bounds.width // 2
        var cy = bounds.y + bounds.height // 2
        var size = min(bounds.width, bounds.height)
        
        # Apply transformations (simplified - rotation only affects some icons)
        
        if self.icon_type == ICON_FILE:
            self.draw_file_icon(ctx, bounds)
        elif self.icon_type == ICON_FOLDER or self.icon_type == ICON_FOLDER_OPEN:
            self.draw_folder_icon(ctx, bounds, self.icon_type == ICON_FOLDER_OPEN)
        elif self.icon_type == ICON_DOCUMENT:
            self.draw_document_icon(ctx, bounds)
        elif self.icon_type == ICON_IMAGE:
            self.draw_image_icon(ctx, bounds)
        elif self.icon_type == ICON_STAR:
            self.draw_star_icon(ctx, cx, cy, size // 2)
        elif self.icon_type == ICON_HEART:
            self.draw_heart_icon(ctx, cx, cy, size // 2)
        elif self.icon_type == ICON_SEARCH:
            self.draw_search_icon(ctx, cx, cy, size // 2)
        elif self.icon_type == ICON_SETTINGS:
            self.draw_settings_icon(ctx, cx, cy, size // 2)
        elif self.icon_type == ICON_HOME:
            self.draw_home_icon(ctx, bounds)
        elif self.icon_type == ICON_PLUS:
            self.draw_plus_icon(ctx, cx, cy, size // 3)
        elif self.icon_type == ICON_MINUS:
            self.draw_minus_icon(ctx, cx, cy, size // 3)
        elif self.icon_type == ICON_CLOSE:
            self.draw_close_icon(ctx, cx, cy, size // 3)
        elif self.icon_type == ICON_CHECK:
            self.draw_check_icon(ctx, cx, cy, size // 3)
        elif (self.icon_type == ICON_ARROW_UP or self.icon_type == ICON_ARROW_DOWN
              or self.icon_type == ICON_ARROW_LEFT or self.icon_type == ICON_ARROW_RIGHT):
            self.draw_arrow_icon(ctx, cx, cy, size // 3, self.icon_type)
        elif self.icon_type == ICON_REFRESH:
            self.draw_refresh_icon(ctx, cx, cy, size // 2)
        elif self.icon_type == ICON_INFO:
            self.draw_info_icon(ctx, cx, cy, size // 2)
        elif self.icon_type == ICON_WARNING:
            self.draw_warning_icon(ctx, cx, cy, size // 2)
        elif self.icon_type == ICON_ERROR:
            self.draw_error_icon(ctx, cx, cy, size // 2)
        else:
            # Default: simple square
            _ = ctx.draw_filled_rectangle(bounds.x + size // 4, bounds.y + size // 4,
                                         size // 2, size // 2)
    
    fn draw_file_icon(self, ctx: RenderingContextInt, bounds: RectInt):
        """Draw file icon."""
        var x = bounds.x + bounds.width // 4
        var y = bounds.y + bounds.height // 6
        var w = bounds.width // 2
        var h = bounds.height * 2 // 3
        var corner = min(w, h) // 6
        
        # File body
        _ = ctx.draw_filled_rectangle(x, y, w - corner, h)
        _ = ctx.draw_filled_rectangle(x, y, w, h - corner)
        
        # Corner fold
        _ = ctx.draw_line(x + w - corner, y, x + w, y + corner, 1)
        _ = ctx.draw_line(x + w - corner, y, x + w - corner, y + corner, 1)
        _ = ctx.draw_line(x + w - corner, y + corner, x + w, y + corner, 1)
    
    fn draw_folder_icon(self, ctx: RenderingContextInt, bounds: RectInt, is_open: Bool):
        """Draw folder icon."""
        var x = bounds.x + bounds.width // 6
        var y = bounds.y + bounds.height // 3
        var w = bounds.width * 2 // 3
        var h = bounds.height // 2
        var tab_w = w // 3
        var tab_h = h // 5
        
        if is_open:
            # Open folder - shifted back panel
            _ = ctx.draw_filled_rectangle(x + 2, y - tab_h + 2, w - 4, h - 2)
        
        # Folder tab
        _ = ctx.draw_filled_rectangle(x, y - tab_h, tab_w, tab_h)
        
        # Folder body
        _ = ctx.draw_filled_rectangle(x, y, w, h - (h // 4 if is_open else 0))
    
    fn draw_document_icon(self, ctx: RenderingContextInt, bounds: RectInt):
        """Draw document icon with lines."""
        self.draw_file_icon(ctx, bounds)
        
        # Add text lines
        var x = bounds.x + bounds.width // 3
        var y = bounds.y + bounds.height // 3
        var line_w = bounds.width // 3
        var spacing = bounds.height // 10
        
        for i in range(3):
            _ = ctx.draw_filled_rectangle(x, y + i * spacing, line_w, 1)
    
    fn draw_image_icon(self, ctx: RenderingContextInt, bounds: RectInt):
        """Draw image/photo icon."""
        var x = bounds.x + bounds.width // 4
        var y = bounds.y + bounds.height // 4
        var w = bounds.width // 2
        var h = bounds.height // 2
        
        # Frame
        _ = ctx.draw_rectangle(x, y, w, h)
        
        # Mountain
        _ = ctx.draw_line(x + w // 4, y + h * 3 // 4, 
                         x + w // 2, y + h // 2, 2)
        _ = ctx.draw_line(x + w // 2, y + h // 2,
                         x + w * 3 // 4, y + h * 3 // 4, 2)
        
        # Sun
        _ = ctx.draw_filled_circle(x + w * 3 // 4, y + h // 4, w // 8, 8)
    
    fn draw_star_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, radius: Int32):
        """Draw star icon."""
        # Simplified 5-point star using lines
        var outer = radius
        var inner = radius // 2
        
        # Draw star shape with lines (simplified)
        _ = ctx.draw_line(cx, cy - outer, cx - inner//2, cy - inner//3, 2)
        _ = ctx.draw_line(cx - inner//2, cy - inner//3, cx - outer, cy, 2)
        _ = ctx.draw_line(cx - outer, cy, cx - inner//2, cy + inner//2, 2)
        _ = ctx.draw_line(cx - inner//2, cy + inner//2, cx, cy + outer, 2)
        _ = ctx.draw_line(cx, cy + outer, cx + inner//2, cy + inner//2, 2)
        _ = ctx.draw_line(cx + inner//2, cy + inner//2, cx + outer, cy, 2)
        _ = ctx.draw_line(cx + outer, cy, cx + inner//2, cy - inner//3, 2)
        _ = ctx.draw_line(cx + inner//2, cy - inner//3, cx, cy - outer, 2)
    
    fn draw_heart_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32):
        """Draw heart icon."""
        # Simplified heart using circles and triangle
        var r = size // 3
        
        # Two circles for top
        _ = ctx.draw_filled_circle(cx - r // 2, cy - r // 2, r // 2, 12)
        _ = ctx.draw_filled_circle(cx + r // 2, cy - r // 2, r // 2, 12)
        
        # Triangle for bottom
        _ = ctx.draw_line(cx - r, cy, cx, cy + r, 2)
        _ = ctx.draw_line(cx, cy + r, cx + r, cy, 2)
        _ = ctx.draw_line(cx - r, cy, cx + r, cy, 2)
    
    fn draw_search_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32):
        """Draw search/magnifying glass icon."""
        var r = size * 2 // 3
        _ = ctx.draw_circle(cx - size // 4, cy - size // 4, r, 16)
        _ = ctx.draw_line(cx + r // 2, cy + r // 2, cx + size, cy + size, 3)
    
    fn draw_settings_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32):
        """Draw settings/gear icon."""
        # Simplified gear - circle with teeth
        var r = size * 2 // 3
        _ = ctx.draw_circle(cx, cy, r, 16)
        
        # Inner circle
        _ = ctx.draw_circle(cx, cy, r // 2, 12)
        
        # Teeth (simplified)
        for i in range(6):
            var angle_deg = i * 60
            # Simplified positioning without trigonometry
            var dx = (angle_deg // 90) % 2 * (r if angle_deg < 180 else -r)
            var dy = ((angle_deg + 90) // 90) % 2 * (r if (angle_deg + 90) < 180 else -r)
            _ = ctx.draw_filled_rectangle(cx + dx - 2, cy + dy - 2, 4, 4)
    
    fn draw_home_icon(self, ctx: RenderingContextInt, bounds: RectInt):
        """Draw home/house icon."""
        var cx = bounds.x + bounds.width // 2
        var cy = bounds.y + bounds.height // 2
        var size = min(bounds.width, bounds.height) * 3 // 4
        
        # Roof
        _ = ctx.draw_line(cx - size // 2, cy, cx, cy - size // 2, 2)
        _ = ctx.draw_line(cx, cy - size // 2, cx + size // 2, cy, 2)
        
        # Walls
        _ = ctx.draw_filled_rectangle(cx - size // 3, cy, size * 2 // 3, size // 2)
        
        # Door
        _ = ctx.draw_filled_rectangle(cx - size // 8, cy + size // 4, size // 4, size // 4)
    
    fn draw_plus_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32):
        """Draw plus icon."""
        _ = ctx.draw_line(cx - size, cy, cx + size, cy, 3)
        _ = ctx.draw_line(cx, cy - size, cx, cy + size, 3)
    
    fn draw_minus_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32):
        """Draw minus icon."""
        _ = ctx.draw_line(cx - size, cy, cx + size, cy, 3)
    
    fn draw_close_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32):
        """Draw close/X icon."""
        _ = ctx.draw_line(cx - size, cy - size, cx + size, cy + size, 3)
        _ = ctx.draw_line(cx - size, cy + size, cx + size, cy - size, 3)
    
    fn draw_check_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32):
        """Draw checkmark icon."""
        _ = ctx.draw_line(cx - size, cy, cx - size // 3, cy + size, 3)
        _ = ctx.draw_line(cx - size // 3, cy + size, cx + size, cy - size, 3)
    
    fn draw_arrow_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32, direction: Int32):
        """Draw arrow icon."""
        if direction == ICON_ARROW_UP:
            _ = ctx.draw_line(cx - size, cy + size // 2, cx, cy - size // 2, 3)
            _ = ctx.draw_line(cx, cy - size // 2, cx + size, cy + size // 2, 3)
        elif direction == ICON_ARROW_DOWN:
            _ = ctx.draw_line(cx - size, cy - size // 2, cx, cy + size // 2, 3)
            _ = ctx.draw_line(cx, cy + size // 2, cx + size, cy - size // 2, 3)
        elif direction == ICON_ARROW_LEFT:
            _ = ctx.draw_line(cx + size // 2, cy - size, cx - size // 2, cy, 3)
            _ = ctx.draw_line(cx - size // 2, cy, cx + size // 2, cy + size, 3)
        elif direction == ICON_ARROW_RIGHT:
            _ = ctx.draw_line(cx - size // 2, cy - size, cx + size // 2, cy, 3)
            _ = ctx.draw_line(cx + size // 2, cy, cx - size // 2, cy + size, 3)
    
    fn draw_refresh_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32):
        """Draw refresh/reload icon."""
        # Circular arrow (simplified)
        var r = size * 3 // 4
        
        # Arc using small rectangles
        for i in range(0, 270, 15):
            var angle_approx = i // 45  # Simplified angle calculation
            var dx = Int32(0)
            var dy = -r
            
            if angle_approx == 1:
                dx = r // 2; dy = -r // 2
            elif angle_approx == 2:
                dx = r; dy = 0
            elif angle_approx == 3:
                dx = r // 2; dy = r // 2
            elif angle_approx == 4:
                dx = 0; dy = r
            elif angle_approx == 5:
                dx = -r // 2; dy = r // 2
            elif angle_approx == 6:
                dx = -r; dy = 0
            
            _ = ctx.draw_filled_rectangle(cx + dx - 1, cy + dy - 1, 2, 2)
        
        # Arrow head
        _ = ctx.draw_line(cx + r, cy, cx + r - size // 4, cy - size // 4, 2)
        _ = ctx.draw_line(cx + r, cy, cx + r - size // 4, cy + size // 4, 2)
    
    fn draw_info_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32):
        """Draw info icon."""
        # Circle
        _ = ctx.draw_circle(cx, cy, size, 16)
        
        # i
        _ = ctx.draw_filled_circle(cx, cy - size // 2, 2, 8)
        _ = ctx.draw_filled_rectangle(cx - 1, cy - size // 4, 2, size // 2)
    
    fn draw_warning_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32):
        """Draw warning triangle icon."""
        # Triangle
        _ = ctx.draw_line(cx, cy - size, cx - size, cy + size, 3)
        _ = ctx.draw_line(cx - size, cy + size, cx + size, cy + size, 3)
        _ = ctx.draw_line(cx + size, cy + size, cx, cy - size, 3)
        
        # Exclamation mark
        _ = ctx.draw_filled_rectangle(cx - 1, cy - size // 2, 2, size // 2)
        _ = ctx.draw_filled_circle(cx, cy + size // 3, 2, 8)
    
    fn draw_error_icon(self, ctx: RenderingContextInt, cx: Int32, cy: Int32, size: Int32):
        """Draw error icon."""
        # Circle with X
        _ = ctx.draw_circle(cx, cy, size, 16)
        _ = ctx.draw_line(cx - size // 2, cy - size // 2, cx + size // 2, cy + size // 2, 3)
        _ = ctx.draw_line(cx - size // 2, cy + size // 2, cx + size // 2, cy - size // 2, 3)
    
    fn render_badge(self, ctx: RenderingContextInt):
        """Render badge on icon."""
        var badge_size = self.icon_size // 3
        var x = self.bounds.x + self.bounds.width - badge_size
        var y = self.bounds.y
        
        # Badge background
        _ = ctx.set_color(self.badge_color.r, self.badge_color.g,
                         self.badge_color.b, self.badge_color.a)
        _ = ctx.draw_filled_circle(x + badge_size // 2, y + badge_size // 2, 
                                  badge_size // 2, 12)
        
        # Badge text
        _ = ctx.set_color(255, 255, 255, 255)
        var text_size = 8
        var text_x = x + (badge_size - len(self.badge_text) * text_size // 2) // 2
        var text_y = y + (badge_size - text_size) // 2
        _ = ctx.draw_text(self.badge_text, text_x, text_y, text_size)
    
    fn update(mut self):
        """Update icon state."""
        pass

# Convenience functions
fn create_icon_int(x: Int32, y: Int32, icon_type: Int32, size: Int32 = ICON_SIZE_MEDIUM) -> IconInt:
    """Create an icon widget."""
    return IconInt(x, y, icon_type, size)

fn create_file_icon_int(x: Int32, y: Int32, file_extension: String, size: Int32 = ICON_SIZE_MEDIUM) -> IconInt:
    """Create appropriate file icon based on extension."""
    var icon_type = ICON_FILE
    
    var ext = file_extension
    if (ext == ".jpg" or ext == ".jpeg" or ext == ".png" or ext == ".gif"
            or ext == ".bmp" or ext == ".svg"):
        icon_type = ICON_IMAGE
    elif (ext == ".mp4" or ext == ".avi" or ext == ".mov" or ext == ".mkv"
            or ext == ".webm"):
        icon_type = ICON_VIDEO
    elif (ext == ".mp3" or ext == ".wav" or ext == ".ogg" or ext == ".flac"
            or ext == ".aac"):
        icon_type = ICON_AUDIO
    elif (ext == ".zip" or ext == ".rar" or ext == ".7z" or ext == ".tar"
            or ext == ".gz"):
        icon_type = ICON_ARCHIVE
    elif (ext == ".py" or ext == ".mojo" or ext == ".c" or ext == ".cpp"
            or ext == ".js" or ext == ".html" or ext == ".css"):
        icon_type = ICON_CODE
    elif (ext == ".exe" or ext == ".app" or ext == ".deb" or ext == ".rpm"):
        icon_type = ICON_EXECUTABLE
    elif (ext == ".txt" or ext == ".doc" or ext == ".pdf" or ext == ".odt"):
        icon_type = ICON_DOCUMENT
    
    return IconInt(x, y, icon_type, size)

fn get_file_extension(filename: String) -> String:
    """Extract file extension from filename."""
    # Find last dot position by scanning bytes (String indexing/`in` use slices).
    var dot_pos = -1
    var dot = Int(ord("."))
    var bytes = filename.as_bytes()
    for i in range(len(filename)):
        if Int(bytes[i]) == dot:
            dot_pos = i

    if dot_pos >= 0:
        return String(filename[dot_pos:])

    return ""