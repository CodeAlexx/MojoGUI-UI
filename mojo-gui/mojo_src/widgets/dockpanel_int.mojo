"""
Integer-Only DockPanel Widget Implementation
Professional docking system with floating panels and auto-hide functionality.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

# Dock positions
alias DOCK_LEFT = 0
alias DOCK_RIGHT = 1
alias DOCK_TOP = 2
alias DOCK_BOTTOM = 3
alias DOCK_CENTER = 4
alias DOCK_FLOAT = 5

# Auto-hide states
alias AUTOHIDE_NONE = 0
alias AUTOHIDE_PINNED = 1
alias AUTOHIDE_HIDDEN = 2
alias AUTOHIDE_SHOWING = 3

struct DockablePanel:
    """Individual dockable panel."""
    var title: String
    var dock_position: Int32
    var float_rect: RectInt
    var is_floating: Bool
    var is_visible: Bool
    var auto_hide_state: Int32
    var min_size: SizeInt
    var content_widget_id: Int32  # Would reference actual widget in real implementation
    
    fn __init__(inout self, title: String, dock_position: Int32 = DOCK_LEFT):
        self.title = title
        self.dock_position = dock_position
        self.float_rect = RectInt(100, 100, 300, 200)
        self.is_floating = False
        self.is_visible = True
        self.auto_hide_state = AUTOHIDE_NONE
        self.min_size = SizeInt(150, 100)
        self.content_widget_id = 0

struct DockPanelInt(BaseWidgetInt):
    """Docking panel system with floating windows and auto-hide."""
    
    var panels: List[DockablePanel]
    var center_content: RectInt
    var dock_sizes: List[Int32]  # Size of each dock area
    var splitter_width: Int32
    var tab_height: Int32
    var auto_hide_tab_width: Int32
    var dragging_panel: Int32
    var dragging_splitter: Int32
    var drag_offset: PointInt
    var hover_auto_hide_tab: Int32
    var auto_hide_timer: Int32
    var title_bar_height: Int32
    var layout_name: String
    
    # Colors
    var dock_bg_color: ColorInt
    var splitter_color: ColorInt
    var tab_active_color: ColorInt
    var tab_inactive_color: ColorInt
    var title_bar_color: ColorInt
    var auto_hide_tab_color: ColorInt
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.super().__init__(x, y, width, height)
        self.panels = List[DockablePanel]()
        self.center_content = RectInt(x, y, width, height)
        self.dock_sizes = List[Int32]()
        self.dock_sizes.append(200)  # Left
        self.dock_sizes.append(200)  # Right
        self.dock_sizes.append(150)  # Top
        self.dock_sizes.append(150)  # Bottom
        
        self.splitter_width = 4
        self.tab_height = 25
        self.auto_hide_tab_width = 25
        self.dragging_panel = -1
        self.dragging_splitter = -1
        self.drag_offset = PointInt(0, 0)
        self.hover_auto_hide_tab = -1
        self.auto_hide_timer = 0
        self.title_bar_height = 22
        self.layout_name = "default"
        
        # Set colors
        self.dock_bg_color = ColorInt(240, 240, 240, 255)
        self.splitter_color = ColorInt(200, 200, 200, 255)
        self.tab_active_color = ColorInt(255, 255, 255, 255)
        self.tab_inactive_color = ColorInt(225, 225, 225, 255)
        self.title_bar_color = ColorInt(70, 130, 180, 255)  # Steel blue
        self.auto_hide_tab_color = ColorInt(200, 200, 200, 255)
        
        # Set base widget appearance
        self.background_color = ColorInt(245, 245, 245, 255)
        self.border_color = ColorInt(180, 180, 180, 255)
        self.border_width = 1
    
    fn add_panel(inout self, title: String, dock_position: Int32 = DOCK_LEFT) -> Int32:
        """Add a dockable panel."""
        var panel = DockablePanel(title, dock_position)
        self.panels.append(panel)
        self.update_layout()
        return len(self.panels) - 1
    
    fn dock_panel(inout self, panel_index: Int32, dock_position: Int32):
        """Dock a panel to specified position."""
        if panel_index >= 0 and panel_index < len(self.panels):
            self.panels[panel_index].dock_position = dock_position
            self.panels[panel_index].is_floating = (dock_position == DOCK_FLOAT)
            self.update_layout()
    
    fn float_panel(inout self, panel_index: Int32, x: Int32, y: Int32):
        """Float a panel at specified position."""
        if panel_index >= 0 and panel_index < len(self.panels):
            self.panels[panel_index].is_floating = True
            self.panels[panel_index].dock_position = DOCK_FLOAT
            self.panels[panel_index].float_rect.x = x
            self.panels[panel_index].float_rect.y = y
    
    fn set_auto_hide(inout self, panel_index: Int32, enabled: Bool):
        """Enable/disable auto-hide for a panel."""
        if panel_index >= 0 and panel_index < len(self.panels):
            if enabled:
                self.panels[panel_index].auto_hide_state = AUTOHIDE_HIDDEN
            else:
                self.panels[panel_index].auto_hide_state = AUTOHIDE_NONE
    
    fn save_layout(self) -> String:
        """Save current layout to string."""
        var layout = "DOCKLAYOUT:1.0\n"
        for i in range(len(self.panels)):
            var p = self.panels[i]
            layout += p.title + "|"
            layout += str(p.dock_position) + "|"
            layout += str(p.is_floating) + "|"
            layout += str(p.float_rect.x) + "," + str(p.float_rect.y) + ","
            layout += str(p.float_rect.width) + "," + str(p.float_rect.height) + "|"
            layout += str(p.auto_hide_state) + "\n"
        return layout
    
    fn restore_layout(inout self, layout: String):
        """Restore layout from string."""
        # Parse layout string and restore panel positions
        # Simplified for demo - would implement full parsing in production
        pass
    
    fn update_layout(inout self):
        """Recalculate panel positions."""
        # Calculate center content area
        var left = self.x
        var right = self.x + self.width
        var top = self.y
        var bottom = self.y + self.height
        
        # Account for docked panels
        for i in range(len(self.panels)):
            var panel = self.panels[i]
            if not panel.is_floating and panel.is_visible:
                if panel.dock_position == DOCK_LEFT:
                    left += self.dock_sizes[0] + self.splitter_width
                elif panel.dock_position == DOCK_RIGHT:
                    right -= self.dock_sizes[1] + self.splitter_width
                elif panel.dock_position == DOCK_TOP:
                    top += self.dock_sizes[2] + self.splitter_width
                elif panel.dock_position == DOCK_BOTTOM:
                    bottom -= self.dock_sizes[3] + self.splitter_width
        
        self.center_content = RectInt(left, top, right - left, bottom - top)
    
    fn get_panel_rect(self, panel_index: Int32) -> RectInt:
        """Get rectangle for a docked panel."""
        if panel_index < 0 or panel_index >= len(self.panels):
            return RectInt(0, 0, 0, 0)
        
        var panel = self.panels[panel_index]
        if panel.is_floating:
            return panel.float_rect
        
        # Calculate docked position
        if panel.dock_position == DOCK_LEFT:
            return RectInt(self.x, self.y, 
                          self.dock_sizes[0], self.height)
        elif panel.dock_position == DOCK_RIGHT:
            return RectInt(self.x + self.width - self.dock_sizes[1],
                          self.y, self.dock_sizes[1], self.height)
        elif panel.dock_position == DOCK_TOP:
            return RectInt(self.x, self.y,
                          self.width, self.dock_sizes[2])
        elif panel.dock_position == DOCK_BOTTOM:
            return RectInt(self.x, 
                          self.y + self.height - self.dock_sizes[3],
                          self.width, self.dock_sizes[3])
        else:
            return self.center_content
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events for docking and dragging."""
        var point = PointInt(event.x, event.y)
        
        # Check floating panels first (on top)
        for i in range(len(self.panels) - 1, -1, -1):
            if self.panels[i].is_floating and self.panels[i].is_visible:
                var rect = self.panels[i].float_rect
                if rect.contains(point):
                    if event.pressed:
                        # Check if clicking title bar
                        if event.y < rect.y + self.title_bar_height:
                            self.dragging_panel = i
                            self.drag_offset = PointInt(event.x - rect.x, 
                                                       event.y - rect.y)
                            return True
                    return True
        
        # Handle panel dragging
        if self.dragging_panel >= 0:
            if event.pressed:
                self.panels[self.dragging_panel].float_rect.x = event.x - self.drag_offset.x
                self.panels[self.dragging_panel].float_rect.y = event.y - self.drag_offset.y
            else:
                self.dragging_panel = -1
            return True
        
        # Check auto-hide tabs
        for i in range(len(self.panels)):
            if self.panels[i].auto_hide_state == AUTOHIDE_HIDDEN:
                var tab_rect = self.get_auto_hide_tab_rect(i)
                if tab_rect.contains(point):
                    self.hover_auto_hide_tab = i
                    if event.pressed:
                        self.panels[i].auto_hide_state = AUTOHIDE_SHOWING
                        self.auto_hide_timer = 0
                    return True
        
        return self._point_in_bounds(point)
    
    fn get_auto_hide_tab_rect(self, panel_index: Int32) -> RectInt:
        """Get auto-hide tab rectangle."""
        var panel = self.panels[panel_index]
        var tab_y = self.y + panel_index * (self.auto_hide_tab_width + 2)
        
        if panel.dock_position == DOCK_LEFT:
            return RectInt(self.x, tab_y, self.auto_hide_tab_width, 
                          self.auto_hide_tab_width)
        elif panel.dock_position == DOCK_RIGHT:
            return RectInt(self.x + self.width - self.auto_hide_tab_width,
                          tab_y, self.auto_hide_tab_width, self.auto_hide_tab_width)
        
        return RectInt(0, 0, 0, 0)
    
    fn draw(self, ctx: RenderingContextInt):
        """Render dock panel system."""
        # Draw main background
        self._draw_background(ctx)
        
        # Render docked panels
        for i in range(len(self.panels)):
            if not self.panels[i].is_floating and self.panels[i].is_visible:
                self.render_docked_panel(ctx, i)
        
        # Render center content area
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.center_content.x, self.center_content.y,
                                     self.center_content.width, self.center_content.height)
        
        # Draw center content label
        _ = ctx.set_color(100, 100, 100, 255)
        _ = ctx.draw_text("Center Content Area", 
                         self.center_content.x + 10, self.center_content.y + 10, 12)
        
        # Render floating panels (on top)
        for i in range(len(self.panels)):
            if self.panels[i].is_floating and self.panels[i].is_visible:
                self.render_floating_panel(ctx, i)
        
        # Render auto-hide tabs
        for i in range(len(self.panels)):
            if self.panels[i].auto_hide_state != AUTOHIDE_NONE:
                self.render_auto_hide_tab(ctx, i)
        
        # Draw border
        self._draw_border(ctx)
    
    fn render_docked_panel(self, ctx: RenderingContextInt, panel_index: Int32):
        """Render a docked panel."""
        var rect = self.get_panel_rect(panel_index)
        var panel = self.panels[panel_index]
        
        # Panel background
        _ = ctx.set_color(self.dock_bg_color.r, self.dock_bg_color.g,
                         self.dock_bg_color.b, self.dock_bg_color.a)
        _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        # Panel title bar
        _ = ctx.set_color(self.tab_active_color.r, self.tab_active_color.g,
                         self.tab_active_color.b, self.tab_active_color.a)
        _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, self.tab_height)
        
        # Title text
        _ = ctx.set_color(0, 0, 0, 255)
        _ = ctx.draw_text(panel.title, rect.x + 5, rect.y + 5, 12)
        
        # Panel content area
        _ = ctx.set_color(255, 255, 255, 255)
        _ = ctx.draw_filled_rectangle(rect.x + 2, rect.y + self.tab_height + 2,
                                     rect.width - 4, rect.height - self.tab_height - 4)
        
        # Demo content
        _ = ctx.set_color(80, 80, 80, 255)
        _ = ctx.draw_text("Panel Content", rect.x + 10, rect.y + self.tab_height + 15, 11)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(rect.x, rect.y, rect.width, rect.height)
    
    fn render_floating_panel(self, ctx: RenderingContextInt, panel_index: Int32):
        """Render a floating panel."""
        var panel = self.panels[panel_index]
        var rect = panel.float_rect
        
        # Shadow
        _ = ctx.set_color(0, 0, 0, 50)
        _ = ctx.draw_filled_rectangle(rect.x + 3, rect.y + 3, rect.width, rect.height)
        
        # Window background
        _ = ctx.set_color(self.dock_bg_color.r, self.dock_bg_color.g,
                         self.dock_bg_color.b, self.dock_bg_color.a)
        _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        # Title bar
        _ = ctx.set_color(self.title_bar_color.r, self.title_bar_color.g,
                         self.title_bar_color.b, self.title_bar_color.a)
        _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, self.title_bar_height)
        
        # Title text
        _ = ctx.set_color(255, 255, 255, 255)
        _ = ctx.draw_text(panel.title, rect.x + 5, rect.y + 3, 12)
        
        # Close button
        var close_x = rect.x + rect.width - 20
        var close_y = rect.y + 5
        _ = ctx.draw_line(close_x, close_y, close_x + 10, close_y + 10, 2)
        _ = ctx.draw_line(close_x + 10, close_y, close_x, close_y + 10, 2)
        
        # Content area
        _ = ctx.set_color(255, 255, 255, 255)
        _ = ctx.draw_filled_rectangle(rect.x + 2, rect.y + self.title_bar_height + 2,
                                     rect.width - 4, rect.height - self.title_bar_height - 4)
        
        # Demo content
        _ = ctx.set_color(80, 80, 80, 255)
        _ = ctx.draw_text("Floating Panel Content", rect.x + 10, rect.y + self.title_bar_height + 15, 11)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(rect.x, rect.y, rect.width, rect.height)
    
    fn render_auto_hide_tab(self, ctx: RenderingContextInt, panel_index: Int32):
        """Render auto-hide tab."""
        var tab_rect = self.get_auto_hide_tab_rect(panel_index)
        var is_hover = (panel_index == self.hover_auto_hide_tab)
        
        # Tab background
        var color = self.tab_active_color if is_hover else self.auto_hide_tab_color
        _ = ctx.set_color(color.r, color.g, color.b, color.a)
        _ = ctx.draw_filled_rectangle(tab_rect.x, tab_rect.y, 
                                     tab_rect.width, tab_rect.height)
        
        # Tab indicator
        _ = ctx.set_color(self.title_bar_color.r, self.title_bar_color.g,
                         self.title_bar_color.b, self.title_bar_color.a)
        _ = ctx.draw_filled_rectangle(tab_rect.x + 2, tab_rect.y + 2, 4, tab_rect.height - 4)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(tab_rect.x, tab_rect.y, 
                              tab_rect.width, tab_rect.height)
    
    fn update(inout self):
        """Update auto-hide animations."""
        # Update auto-hide timer
        if self.hover_auto_hide_tab >= 0:
            self.auto_hide_timer += 16  # ~60fps
            if self.auto_hide_timer > 3000:  # 3 seconds
                if self.hover_auto_hide_tab < len(self.panels):
                    self.panels[self.hover_auto_hide_tab].auto_hide_state = AUTOHIDE_HIDDEN
                self.hover_auto_hide_tab = -1
    
    fn get_center_content_rect(self) -> RectInt:
        """Get the center content area rectangle."""
        return self.center_content
    
    fn get_panel_count(self) -> Int32:
        """Get number of panels."""
        return len(self.panels)


# Convenience functions
fn create_dock_panel_int(x: Int32, y: Int32, width: Int32, height: Int32) -> DockPanelInt:
    """Create a dock panel system."""
    return DockPanelInt(x, y, width, height)