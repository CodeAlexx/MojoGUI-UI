"""
Integer-Only Breadcrumb Navigation Widget Implementation
Path navigation with clickable segments and dropdown support.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .widget_constants import *

struct PathSegment:
    """Individual path segment in breadcrumb."""
    var name: String
    var path: String
    var icon: String
    var is_root: Bool
    
    fn __init__(inout self, name: String, path: String, icon: String = "", is_root: Bool = False):
        self.name = name
        self.path = path
        self.icon = icon
        self.is_root = is_root

struct BreadcrumbInt(BaseWidgetInt):
    """Breadcrumb navigation widget for path display."""
    
    var segments: List[PathSegment]
    var separator: String
    var show_icons: Bool
    var max_visible_segments: Int32
    var collapsed_segments: List[PathSegment]
    
    # Visual properties
    var segment_padding: Int32
    var separator_padding: Int32
    var icon_size: Int32
    var font_size: Int32
    var hover_segment: Int32
    var pressed_segment: Int32
    var show_dropdown: Bool
    var dropdown_hover: Int32
    
    # Colors
    var segment_color: ColorInt
    var segment_hover_color: ColorInt
    var segment_pressed_color: ColorInt
    var separator_color: ColorInt
    var icon_color: ColorInt
    var dropdown_bg_color: ColorInt
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.super().__init__(x, y, width, height)
        
        self.segments = List[PathSegment]()
        self.separator = "/"
        self.show_icons = True
        self.max_visible_segments = 5
        self.collapsed_segments = List[PathSegment]()
        
        self.segment_padding = 8
        self.separator_padding = 4
        self.icon_size = 16
        self.font_size = 12
        self.hover_segment = -1
        self.pressed_segment = -1
        self.show_dropdown = False
        self.dropdown_hover = -1
        
        # Colors
        self.segment_color = ColorInt(0, 0, 0, 255)
        self.segment_hover_color = ColorInt(70, 130, 180, 255)
        self.segment_pressed_color = ColorInt(50, 110, 160, 255)
        self.separator_color = ColorInt(128, 128, 128, 255)
        self.icon_color = ColorInt(100, 100, 100, 255)
        self.dropdown_bg_color = ColorInt(255, 255, 255, 255)
        
        # Widget appearance
        self.background_color = ColorInt(245, 245, 245, 255)
        self.border_color = ColorInt(200, 200, 200, 255)
        self.border_width = 1
    
    fn set_path(inout self, path: String):
        """Set the current path and parse segments."""
        self.segments.clear()
        self.collapsed_segments.clear()
        
        # Parse path into segments
        if len(path) == 0:
            return
        
        # Handle root
        if len(path) > 0 and path[0] == '/':
            self.segments.append(PathSegment("/", "/", "folder", True))
        
        # Split path - simplified for demo
        var current_path = ""
        var part = ""
        var i = 1 if len(path) > 0 and path[0] == '/' else 0
        
        while i < len(path):
            if path[i] == '/':
                if len(part) > 0:
                    if current_path == "" or current_path == "/":
                        current_path = "/" + part
                    else:
                        current_path += "/" + part
                    
                    self.segments.append(PathSegment(part, current_path, "folder"))
                    part = ""
            else:
                part += path[i]
            i += 1
        
        # Add final part
        if len(part) > 0:
            if current_path == "" or current_path == "/":
                current_path = "/" + part
            else:
                current_path += "/" + part
            
            self.segments.append(PathSegment(part, current_path, "folder"))
        
        # Handle overflow
        self.update_visible_segments()
    
    fn navigate_to(inout self, path: String):
        """Navigate to a specific path."""
        # Would call navigation callback in real implementation
        self.set_path(path)
    
    fn navigate_up(inout self):
        """Navigate to parent directory."""
        if len(self.segments) > 1:
            let parent_path = self.segments[len(self.segments) - 2].path
            self.navigate_to(parent_path)
    
    fn update_visible_segments(inout self):
        """Update which segments are visible vs collapsed."""
        if len(self.segments) <= self.max_visible_segments:
            self.collapsed_segments.clear()
            return
        
        # Keep first segment (root) and last few segments visible
        let visible_at_end = self.max_visible_segments - 2  # -1 for root, -1 for "..."
        let collapse_start = 1
        let collapse_end = len(self.segments) - visible_at_end
        
        self.collapsed_segments.clear()
        for i in range(collapse_start, collapse_end):
            self.collapsed_segments.append(self.segments[i])
    
    fn get_segment_rect(self, index: Int32) -> RectInt:
        """Get rectangle for a segment."""
        var x = self.bounds.x + self.segment_padding
        var visible_index = 0
        
        for i in range(len(self.segments)):
            if self.is_segment_visible(i):
                if visible_index == index:
                    let width = self.calculate_segment_width(self.segments[i])
                    return RectInt(x, self.bounds.y, width, self.bounds.height)
                
                x += self.calculate_segment_width(self.segments[i])
                x += self.separator_padding * 2 + self.get_separator_width()
                visible_index += 1
            elif i == 1 and len(self.collapsed_segments) > 0:
                # This is where the "..." button would be
                if visible_index == index:
                    return RectInt(x, self.bounds.y, 30, self.bounds.height)
                x += 30 + self.separator_padding * 2 + self.get_separator_width()
                visible_index += 1
        
        return RectInt(0, 0, 0, 0)
    
    fn is_segment_visible(self, index: Int32) -> Bool:
        """Check if segment at index is visible."""
        if len(self.segments) <= self.max_visible_segments:
            return True
        
        # First segment always visible
        if index == 0:
            return True
        
        # Last few segments visible
        let visible_at_end = self.max_visible_segments - 2
        if index >= len(self.segments) - visible_at_end:
            return True
        
        return False
    
    fn calculate_segment_width(self, segment: PathSegment) -> Int32:
        """Calculate width of a segment."""
        var width = len(segment.name) * (self.font_size * 6 // 10)
        if self.show_icons:
            width += self.icon_size + 4
        width += self.segment_padding * 2
        return width
    
    fn get_separator_width(self) -> Int32:
        """Get separator width."""
        return len(self.separator) * (self.font_size * 6 // 10)
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        
        # Check dropdown first if visible
        if self.show_dropdown:
            let dropdown_rect = self.get_dropdown_rect()
            if dropdown_rect.contains(point):
                let item_height = 25
                let relative_y = event.y - dropdown_rect.y
                let item_index = relative_y // item_height
                
                if event.pressed and item_index >= 0 and item_index < len(self.collapsed_segments):
                    self.navigate_to(self.collapsed_segments[item_index].path)
                    self.show_dropdown = False
                    return True
                
                self.dropdown_hover = item_index
                return True
            elif event.pressed:
                self.show_dropdown = False
            return self.show_dropdown
        
        # Check segments
        var visible_index = 0
        for i in range(len(self.segments)):
            if self.is_segment_visible(i):
                let rect = self.get_segment_rect(visible_index)
                if rect.contains(point):
                    self.hover_segment = visible_index
                    if event.pressed:
                        self.pressed_segment = visible_index
                        self.navigate_to(self.segments[i].path)
                    return True
                visible_index += 1
            elif i == 1 and len(self.collapsed_segments) > 0:
                # Check "..." button
                let rect = self.get_segment_rect(visible_index)
                if rect.contains(point):
                    self.hover_segment = visible_index
                    if event.pressed:
                        self.show_dropdown = not self.show_dropdown
                        self.dropdown_hover = -1
                    return True
                visible_index += 1
        
        self.hover_segment = -1
        return self.contains_point(point)
    
    fn get_dropdown_rect(self) -> RectInt:
        """Get dropdown menu rectangle."""
        # Position below the "..." button
        let button_rect = self.get_segment_rect(1)  # "..." is at visible index 1
        let dropdown_width = 200
        let dropdown_height = len(self.collapsed_segments) * 25 + 4
        
        return RectInt(button_rect.x, self.bounds.y + self.bounds.height,
                      dropdown_width, dropdown_height)
    
    fn render(self, ctx: RenderingContextInt):
        """Render breadcrumb navigation."""
        if not self.visible:
            return
        
        # Background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                     self.bounds.width, self.bounds.height)
        
        # Render segments
        var x = self.bounds.x + self.segment_padding
        var visible_index = 0
        
        for i in range(len(self.segments)):
            if self.is_segment_visible(i):
                self.render_segment(ctx, self.segments[i], x, visible_index)
                x += self.calculate_segment_width(self.segments[i])
                
                # Render separator (except after last)
                if i < len(self.segments) - 1:
                    x += self.separator_padding
                    self.render_separator(ctx, x)
                    x += self.get_separator_width() + self.separator_padding
                
                visible_index += 1
            elif i == 1 and len(self.collapsed_segments) > 0:
                # Render "..." button
                self.render_ellipsis_button(ctx, x, visible_index)
                x += 30
                
                # Separator after ellipsis
                x += self.separator_padding
                self.render_separator(ctx, x)
                x += self.get_separator_width() + self.separator_padding
                
                visible_index += 1
        
        # Render dropdown if visible
        if self.show_dropdown:
            self.render_dropdown(ctx)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y,
                              self.bounds.width, self.bounds.height)
    
    fn render_segment(self, ctx: RenderingContextInt, segment: PathSegment, 
                     x: Int32, visible_index: Int32):
        """Render individual segment."""
        let is_hover = (visible_index == self.hover_segment)
        let is_pressed = (visible_index == self.pressed_segment)
        
        # Segment background on hover
        if is_hover or is_pressed:
            let rect = self.get_segment_rect(visible_index)
            let bg_color = self.segment_pressed_color if is_pressed else self.segment_hover_color
            _ = ctx.set_color(bg_color.r, bg_color.g, bg_color.b, 30)
            _ = ctx.draw_filled_rectangle(rect.x, rect.y + 2, rect.width, rect.height - 4)
        
        var current_x = x + self.segment_padding
        
        # Icon
        if self.show_icons:
            _ = ctx.set_color(self.icon_color.r, self.icon_color.g,
                             self.icon_color.b, self.icon_color.a)
            let icon_y = self.bounds.y + (self.bounds.height - self.icon_size) // 2
            
            # Draw folder icon (simplified)
            _ = ctx.draw_filled_rectangle(current_x, icon_y + 3, self.icon_size - 2, self.icon_size - 4)
            _ = ctx.draw_filled_rectangle(current_x, icon_y, 6, 3)
            
            current_x += self.icon_size + 4
        
        # Text
        let text_color = self.segment_hover_color if is_hover else self.segment_color
        _ = ctx.set_color(text_color.r, text_color.g, text_color.b, text_color.a)
        let text_y = self.bounds.y + (self.bounds.height - self.font_size) // 2
        _ = ctx.draw_text(segment.name, current_x, text_y, self.font_size)
    
    fn render_separator(self, ctx: RenderingContextInt, x: Int32):
        """Render path separator."""
        _ = ctx.set_color(self.separator_color.r, self.separator_color.g,
                         self.separator_color.b, self.separator_color.a)
        let text_y = self.bounds.y + (self.bounds.height - self.font_size) // 2
        _ = ctx.draw_text(self.separator, x, text_y, self.font_size)
    
    fn render_ellipsis_button(self, ctx: RenderingContextInt, x: Int32, visible_index: Int32):
        """Render collapsed segments button."""
        let is_hover = (visible_index == self.hover_segment)
        
        # Button background
        if is_hover or self.show_dropdown:
            _ = ctx.set_color(self.segment_hover_color.r, self.segment_hover_color.g,
                             self.segment_hover_color.b, 30)
            _ = ctx.draw_filled_rectangle(x, self.bounds.y + 2, 30, self.bounds.height - 4)
        
        # Ellipsis text
        _ = ctx.set_color(self.segment_color.r, self.segment_color.g,
                         self.segment_color.b, self.segment_color.a)
        let text_y = self.bounds.y + (self.bounds.height - self.font_size) // 2
        _ = ctx.draw_text("...", x + 8, text_y, self.font_size)
    
    fn render_dropdown(self, ctx: RenderingContextInt):
        """Render dropdown menu for collapsed segments."""
        let rect = self.get_dropdown_rect()
        
        # Shadow
        _ = ctx.set_color(0, 0, 0, 30)
        _ = ctx.draw_filled_rectangle(rect.x + 2, rect.y + 2, rect.width, rect.height)
        
        # Background
        _ = ctx.set_color(self.dropdown_bg_color.r, self.dropdown_bg_color.g,
                         self.dropdown_bg_color.b, self.dropdown_bg_color.a)
        _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        # Items
        let item_height = 25
        for i in range(len(self.collapsed_segments)):
            let item_y = rect.y + 2 + i * item_height
            
            # Hover background
            if i == self.dropdown_hover:
                _ = ctx.set_color(self.segment_hover_color.r, self.segment_hover_color.g,
                                 self.segment_hover_color.b, 30)
                _ = ctx.draw_filled_rectangle(rect.x + 2, item_y, rect.width - 4, item_height)
            
            # Text
            _ = ctx.set_color(self.segment_color.r, self.segment_color.g,
                             self.segment_color.b, self.segment_color.a)
            _ = ctx.draw_text(self.collapsed_segments[i].name, rect.x + 10, item_y + 5, self.font_size)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(rect.x, rect.y, rect.width, rect.height)
    
    fn update(inout self):
        """Update widget state."""
        pass

# Convenience functions
fn create_breadcrumb_int(x: Int32, y: Int32, width: Int32, height: Int32 = 30) -> BreadcrumbInt:
    """Create a breadcrumb navigation widget."""
    return BreadcrumbInt(x, y, width, height)