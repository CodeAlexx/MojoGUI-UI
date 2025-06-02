"""
Integer-Only Accordion Widget Implementation
Collapsible panel system with smooth animations.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

# Accordion expansion modes
alias ACCORDION_SINGLE = 0
alias ACCORDION_MULTIPLE = 1

struct AccordionSection:
    """Individual accordion section."""
    var title: String
    var content_height: Int32
    var is_expanded: Bool
    var animation_progress: Float32  # 0.0 to 1.0
    var enabled: Bool
    var data: Int32
    
    fn __init__(inout self, title: String, content_height: Int32 = 100):
        self.title = title
        self.content_height = content_height
        self.is_expanded = False
        self.animation_progress = 0.0
        self.enabled = True
        self.data = 0

struct AccordionInt(BaseWidgetInt):
    """Collapsible accordion widget with smooth animations."""
    
    var sections: List[AccordionSection]
    var expansion_mode: Int32
    var header_height: Int32
    var animation_speed: Float32
    var spacing: Int32
    var hover_section: Int32
    
    # Colors
    var header_color: ColorInt
    var header_hover_color: ColorInt
    var header_expanded_color: ColorInt
    var content_color: ColorInt
    var text_color: ColorInt
    var icon_color: ColorInt
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32,
                expansion_mode: Int32 = ACCORDION_SINGLE):
        self.super().__init__(x, y, width, height)
        self.sections = List[AccordionSection]()
        self.expansion_mode = expansion_mode
        self.header_height = 30
        self.animation_speed = 0.15  # Animation step per frame
        self.spacing = 1
        self.hover_section = -1
        
        # Set colors
        self.header_color = ColorInt(230, 230, 230, 255)
        self.header_hover_color = ColorInt(220, 220, 220, 255)
        self.header_expanded_color = ColorInt(200, 220, 240, 255)
        self.content_color = ColorInt(255, 255, 255, 255)
        self.text_color = ColorInt(0, 0, 0, 255)
        self.icon_color = ColorInt(100, 100, 100, 255)
        
        # Set base widget appearance
        self.background_color = ColorInt(245, 245, 245, 255)
        self.border_color = ColorInt(180, 180, 180, 255)
        self.border_width = 1
    
    fn add_section(inout self, title: String, content_height: Int32 = 100):
        """Add a new accordion section."""
        self.sections.append(AccordionSection(title, content_height))
    
    fn expand_section(inout self, index: Int32):
        """Expand a section."""
        if index < 0 or index >= len(self.sections):
            return
        
        if self.expansion_mode == ACCORDION_SINGLE:
            # Collapse all other sections
            for i in range(len(self.sections)):
                if i != index:
                    self.sections[i].is_expanded = False
        
        self.sections[index].is_expanded = True
    
    fn collapse_section(inout self, index: Int32):
        """Collapse a section."""
        if index >= 0 and index < len(self.sections):
            self.sections[index].is_expanded = False
    
    fn toggle_section(inout self, index: Int32):
        """Toggle section expansion."""
        if index >= 0 and index < len(self.sections):
            if self.sections[index].is_expanded:
                self.collapse_section(index)
            else:
                self.expand_section(index)
    
    fn get_section_rect(self, index: Int32) -> (RectInt, RectInt):
        """Get header and content rectangles for a section."""
        var y = self.y
        
        for i in range(index + 1):
            if i == index:
                var header = RectInt(self.x, y, self.width, self.header_height)
                var content_h = Int32(self.sections[i].content_height * 
                                     self.sections[i].animation_progress)
                var content = RectInt(self.x, y + self.header_height,
                                     self.width, content_h)
                return (header, content)
            
            y += self.header_height + self.spacing
            if self.sections[i].is_expanded:
                y += Int32(self.sections[i].content_height * 
                          self.sections[i].animation_progress)
        
        return (RectInt(0, 0, 0, 0), RectInt(0, 0, 0, 0))
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        var point = PointInt(event.x, event.y)
        
        # Check which section header was clicked
        for i in range(len(self.sections)):
            var (header_rect, _) = self.get_section_rect(i)
            if header_rect.contains(point):
                self.hover_section = i
                if event.pressed and self.sections[i].enabled:
                    self.toggle_section(i)
                    return True
                return True
        
        self.hover_section = -1
        return self._point_in_bounds(point)
    
    fn draw(self, ctx: RenderingContextInt):
        """Render accordion."""
        if not self.visible:
            return
        
        # Draw background
        self._draw_background(ctx)
        
        for i in range(len(self.sections)):
            self.render_section(ctx, i)
        
        # Draw border
        self._draw_border(ctx)
    
    fn render_section(self, ctx: RenderingContextInt, index: Int32):
        """Render individual section."""
        var section = self.sections[index]
        var (header_rect, content_rect) = self.get_section_rect(index)
        
        # Render header
        var header_color = self.header_color
        if section.is_expanded:
            header_color = self.header_expanded_color
        elif index == self.hover_section:
            header_color = self.header_hover_color
        
        _ = ctx.set_color(header_color.r, header_color.g, 
                         header_color.b, header_color.a)
        _ = ctx.draw_filled_rectangle(header_rect.x, header_rect.y,
                                     header_rect.width, header_rect.height)
        
        # Draw expand/collapse icon
        var icon_x = header_rect.x + 10
        var icon_y = header_rect.y + self.header_height // 2
        _ = ctx.set_color(self.icon_color.r, self.icon_color.g,
                         self.icon_color.b, self.icon_color.a)
        
        if section.animation_progress > 0.5:
            # Draw down arrow (expanded)
            _ = ctx.draw_line(icon_x, icon_y - 3, icon_x + 6, icon_y + 3, 2)
            _ = ctx.draw_line(icon_x + 6, icon_y + 3, icon_x + 12, icon_y - 3, 2)
        else:
            # Draw right arrow (collapsed)
            _ = ctx.draw_line(icon_x + 3, icon_y - 6, icon_x + 9, icon_y, 2)
            _ = ctx.draw_line(icon_x + 9, icon_y, icon_x + 3, icon_y + 6, 2)
        
        # Draw title
        _ = ctx.set_color(self.text_color.r, self.text_color.g,
                         self.text_color.b, self.text_color.a)
        _ = ctx.draw_text(section.title, header_rect.x + 30, 
                         header_rect.y + 8, 12)
        
        # Draw header border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(header_rect.x, header_rect.y,
                              header_rect.width, header_rect.height)
        
        # Render content if visible
        if content_rect.height > 0:
            _ = ctx.set_color(self.content_color.r, self.content_color.g,
                             self.content_color.b, self.content_color.a)
            _ = ctx.draw_filled_rectangle(content_rect.x, content_rect.y,
                                         content_rect.width, content_rect.height)
            
            # Content border
            _ = ctx.set_color(self.border_color.r, self.border_color.g,
                             self.border_color.b, self.border_color.a)
            _ = ctx.draw_rectangle(content_rect.x, content_rect.y,
                                  content_rect.width, content_rect.height)
            
            # Demo content
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
            _ = ctx.draw_text("Content for " + section.title,
                             content_rect.x + 10, content_rect.y + 10, 11)
            
            # Add some additional demo content
            if content_rect.height > 40:
                _ = ctx.draw_text("• Item 1", content_rect.x + 20, content_rect.y + 30, 10)
            if content_rect.height > 60:
                _ = ctx.draw_text("• Item 2", content_rect.x + 20, content_rect.y + 50, 10)
            if content_rect.height > 80:
                _ = ctx.draw_text("• Item 3", content_rect.x + 20, content_rect.y + 70, 10)
    
    fn update(inout self):
        """Update animations."""
        for i in range(len(self.sections)):
            if self.sections[i].is_expanded:
                if self.sections[i].animation_progress < 1.0:
                    self.sections[i].animation_progress += self.animation_speed
                    if self.sections[i].animation_progress > 1.0:
                        self.sections[i].animation_progress = 1.0
            else:
                if self.sections[i].animation_progress > 0.0:
                    self.sections[i].animation_progress -= self.animation_speed
                    if self.sections[i].animation_progress < 0.0:
                        self.sections[i].animation_progress = 0.0
    
    fn set_expansion_mode(inout self, mode: Int32):
        """Set accordion expansion mode."""
        self.expansion_mode = mode
    
    fn get_section_count(self) -> Int32:
        """Get number of sections."""
        return len(self.sections)
    
    fn is_section_expanded(self, index: Int32) -> Bool:
        """Check if section is expanded."""
        if index >= 0 and index < len(self.sections):
            return self.sections[index].is_expanded
        return False
    
    fn set_section_enabled(inout self, index: Int32, enabled: Bool):
        """Enable or disable a section."""
        if index >= 0 and index < len(self.sections):
            self.sections[index].enabled = enabled


# Convenience functions
fn create_accordion_int(x: Int32, y: Int32, width: Int32, height: Int32,
                       mode: Int32 = ACCORDION_SINGLE) -> AccordionInt:
    """Create an accordion widget."""
    return AccordionInt(x, y, width, height, mode)