"""
DockPanel, Accordion, and Toolbar Widgets
Professional docking, collapsible panels, and toolbar functionality
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .button_int import ButtonInt

# Dock positions
alias DOCK_LEFT: Int32 = 0
alias DOCK_RIGHT: Int32 = 1
alias DOCK_TOP: Int32 = 2
alias DOCK_BOTTOM: Int32 = 3
alias DOCK_CENTER: Int32 = 4
alias DOCK_FLOAT: Int32 = 5

# Auto-hide states
alias AUTOHIDE_NONE: Int32 = 0
alias AUTOHIDE_PINNED: Int32 = 1
alias AUTOHIDE_HIDDEN: Int32 = 2
alias AUTOHIDE_SHOWING: Int32 = 3

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
    
    fn add_panel(inout self, title: String, dock_position: Int32 = DOCK_LEFT) -> Int32:
        """Add a dockable panel."""
        let panel = DockablePanel(title, dock_position)
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
            let p = self.panels[i]
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
        # Simplified for demo
        pass
    
    fn update_layout(inout self):
        """Recalculate panel positions."""
        # Calculate center content area
        var left = self.bounds.x
        var right = self.bounds.x + self.bounds.width
        var top = self.bounds.y
        var bottom = self.bounds.y + self.bounds.height
        
        # Account for docked panels
        for i in range(len(self.panels)):
            let panel = self.panels[i]
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
        
        let panel = self.panels[panel_index]
        if panel.is_floating:
            return panel.float_rect
        
        # Calculate docked position
        if panel.dock_position == DOCK_LEFT:
            return RectInt(self.bounds.x, self.bounds.y, 
                          self.dock_sizes[0], self.bounds.height)
        elif panel.dock_position == DOCK_RIGHT:
            return RectInt(self.bounds.x + self.bounds.width - self.dock_sizes[1],
                          self.bounds.y, self.dock_sizes[1], self.bounds.height)
        elif panel.dock_position == DOCK_TOP:
            return RectInt(self.bounds.x, self.bounds.y,
                          self.bounds.width, self.dock_sizes[2])
        elif panel.dock_position == DOCK_BOTTOM:
            return RectInt(self.bounds.x, 
                          self.bounds.y + self.bounds.height - self.dock_sizes[3],
                          self.bounds.width, self.dock_sizes[3])
        else:
            return self.center_content
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events for docking and dragging."""
        let point = PointInt(event.x, event.y)
        
        # Check floating panels first (on top)
        for i in range(len(self.panels) - 1, -1, -1):
            if self.panels[i].is_floating and self.panels[i].is_visible:
                let rect = self.panels[i].float_rect
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
                let tab_rect = self.get_auto_hide_tab_rect(i)
                if tab_rect.contains(point):
                    self.hover_auto_hide_tab = i
                    if event.pressed:
                        self.panels[i].auto_hide_state = AUTOHIDE_SHOWING
                        self.auto_hide_timer = 0
                    return True
        
        return False
    
    fn get_auto_hide_tab_rect(self, panel_index: Int32) -> RectInt:
        """Get auto-hide tab rectangle."""
        let panel = self.panels[panel_index]
        var tab_y = self.bounds.y + panel_index * (self.auto_hide_tab_width + 2)
        
        if panel.dock_position == DOCK_LEFT:
            return RectInt(self.bounds.x, tab_y, self.auto_hide_tab_width, 
                          self.auto_hide_tab_width)
        elif panel.dock_position == DOCK_RIGHT:
            return RectInt(self.bounds.x + self.bounds.width - self.auto_hide_tab_width,
                          tab_y, self.auto_hide_tab_width, self.auto_hide_tab_width)
        
        return RectInt(0, 0, 0, 0)
    
    fn render(self, ctx: RenderingContextInt):
        """Render dock panel system."""
        # Render docked panels
        for i in range(len(self.panels)):
            if not self.panels[i].is_floating and self.panels[i].is_visible:
                self.render_docked_panel(ctx, i)
        
        # Render center content area
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.center_content.x, self.center_content.y,
                                     self.center_content.width, self.center_content.height)
        
        # Render floating panels (on top)
        for i in range(len(self.panels)):
            if self.panels[i].is_floating and self.panels[i].is_visible:
                self.render_floating_panel(ctx, i)
        
        # Render auto-hide tabs
        for i in range(len(self.panels)):
            if self.panels[i].auto_hide_state != AUTOHIDE_NONE:
                self.render_auto_hide_tab(ctx, i)
    
    fn render_docked_panel(self, ctx: RenderingContextInt, panel_index: Int32):
        """Render a docked panel."""
        let rect = self.get_panel_rect(panel_index)
        let panel = self.panels[panel_index]
        
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
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(rect.x, rect.y, rect.width, rect.height)
    
    fn render_floating_panel(self, ctx: RenderingContextInt, panel_index: Int32):
        """Render a floating panel."""
        let panel = self.panels[panel_index]
        let rect = panel.float_rect
        
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
        let close_x = rect.x + rect.width - 20
        let close_y = rect.y + 5
        _ = ctx.draw_line(close_x, close_y, close_x + 10, close_y + 10, 2)
        _ = ctx.draw_line(close_x + 10, close_y, close_x, close_y + 10, 2)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(rect.x, rect.y, rect.width, rect.height)
    
    fn render_auto_hide_tab(self, ctx: RenderingContextInt, panel_index: Int32):
        """Render auto-hide tab."""
        let tab_rect = self.get_auto_hide_tab_rect(panel_index)
        let is_hover = (panel_index == self.hover_auto_hide_tab)
        
        # Tab background
        let color = self.tab_active_color if is_hover else self.auto_hide_tab_color
        _ = ctx.set_color(color.r, color.g, color.b, color.a)
        _ = ctx.draw_filled_rectangle(tab_rect.x, tab_rect.y, 
                                     tab_rect.width, tab_rect.height)
        
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
                self.panels[self.hover_auto_hide_tab].auto_hide_state = AUTOHIDE_HIDDEN
                self.hover_auto_hide_tab = -1
        


# Accordion expansion modes
alias ACCORDION_SINGLE: Int32 = 0
alias ACCORDION_MULTIPLE: Int32 = 1

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
        var y = self.bounds.y
        
        for i in range(index + 1):
            if i == index:
                let header = RectInt(self.bounds.x, y, self.bounds.width, self.header_height)
                let content_h = Int32(self.sections[i].content_height * 
                                     self.sections[i].animation_progress)
                let content = RectInt(self.bounds.x, y + self.header_height,
                                     self.bounds.width, content_h)
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
        
        let point = PointInt(event.x, event.y)
        
        # Check which section header was clicked
        for i in range(len(self.sections)):
            let (header_rect, _) = self.get_section_rect(i)
            if header_rect.contains(point):
                self.hover_section = i
                if event.pressed and self.sections[i].enabled:
                    self.toggle_section(i)
                    return True
                return True
        
        self.hover_section = -1
        return self.contains_point(point)
    
    fn render(self, ctx: RenderingContextInt):
        """Render accordion."""
        if not self.visible:
            return
        
        for i in range(len(self.sections)):
            self.render_section(ctx, i)
    
    fn render_section(self, ctx: RenderingContextInt, index: Int32):
        """Render individual section."""
        let section = self.sections[index]
        let (header_rect, content_rect) = self.get_section_rect(index)
        
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
        let icon_x = header_rect.x + 10
        let icon_y = header_rect.y + self.header_height // 2
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


# Toolbar button types
alias TOOLBAR_BUTTON: Int32 = 0
alias TOOLBAR_TOGGLE: Int32 = 1
alias TOOLBAR_DROPDOWN: Int32 = 2
alias TOOLBAR_SEPARATOR: Int32 = 3

struct ToolbarItem:
    """Individual toolbar item."""
    var item_type: Int32
    var text: String
    var icon: String  # Icon name/path
    var tooltip: String
    var width: Int32
    var enabled: Bool
    var toggled: Bool
    var dropdown_items: List[String]
    var data: Int32
    
    fn __init__(inout self, item_type: Int32, text: String, tooltip: String = ""):
        self.item_type = item_type
        self.text = text
        self.icon = ""
        self.tooltip = tooltip
        self.width = 0  # Auto-calculated
        self.enabled = True
        self.toggled = False
        self.dropdown_items = List[String]()
        self.data = 0

struct ToolBarInt(BaseWidgetInt):
    """Toolbar with button groups, separators, and overflow handling."""
    
    var items: List[ToolbarItem]
    var button_height: Int32
    var button_padding: Int32
    var icon_size: Int32
    var separator_width: Int32
    var show_text: Bool
    var show_icons: Bool
    var hover_item: Int32
    var pressed_item: Int32
    var dropdown_open: Int32
    var overflow_start: Int32  # First item in overflow menu
    
    # Colors
    var button_color: ColorInt
    var button_hover_color: ColorInt
    var button_pressed_color: ColorInt
    var button_toggled_color: ColorInt
    var separator_color: ColorInt
    var text_color: ColorInt
    var disabled_color: ColorInt
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.super().__init__(x, y, width, height)
        self.items = List[ToolbarItem]()
        self.button_height = height - 4
        self.button_padding = 8
        self.icon_size = 16
        self.separator_width = 8
        self.show_text = True
        self.show_icons = True
        self.hover_item = -1
        self.pressed_item = -1
        self.dropdown_open = -1
        self.overflow_start = -1
        
        # Set colors
        self.button_color = ColorInt(240, 240, 240, 255)
        self.button_hover_color = ColorInt(220, 220, 240, 255)
        self.button_pressed_color = ColorInt(200, 200, 220, 255)
        self.button_toggled_color = ColorInt(180, 200, 220, 255)
        self.separator_color = ColorInt(200, 200, 200, 255)
        self.text_color = ColorInt(0, 0, 0, 255)
        self.disabled_color = ColorInt(150, 150, 150, 255)
        
        self.background_color = ColorInt(245, 245, 245, 255)
    
    fn add_button(inout self, text: String, tooltip: String = ""):
        """Add a regular button."""
        var item = ToolbarItem(TOOLBAR_BUTTON, text, tooltip)
        self.calculate_item_width(item)
        self.items.append(item)
    
    fn add_toggle(inout self, text: String, tooltip: String = "", toggled: Bool = False):
        """Add a toggle button."""
        var item = ToolbarItem(TOOLBAR_TOGGLE, text, tooltip)
        item.toggled = toggled
        self.calculate_item_width(item)
        self.items.append(item)
    
    fn add_dropdown(inout self, text: String, items: List[String], tooltip: String = ""):
        """Add a dropdown button."""
        var item = ToolbarItem(TOOLBAR_DROPDOWN, text, tooltip)
        item.dropdown_items = items
        self.calculate_item_width(item)
        self.items.append(item)
    
    fn add_separator(inout self):
        """Add a separator."""
        var item = ToolbarItem(TOOLBAR_SEPARATOR, "", "")
        item.width = self.separator_width
        self.items.append(item)
    
    fn calculate_item_width(inout self, item: ToolbarItem):
        """Calculate width for a toolbar item."""
        if item.item_type == TOOLBAR_SEPARATOR:
            item.width = self.separator_width
            return
        
        var width = 2 * self.button_padding
        
        if self.show_icons:
            width += self.icon_size
            if self.show_text and len(item.text) > 0:
                width += self.button_padding
        
        if self.show_text:
            let text_width = len(item.text) * 7  # Approximate
            width += text_width
        
        if item.item_type == TOOLBAR_DROPDOWN:
            width += 15  # Space for dropdown arrow
        
        item.width = width
    
    fn calculate_overflow(inout self):
        """Calculate which items go into overflow menu."""
        var x = self.bounds.x + 2
        let max_x = self.bounds.x + self.bounds.width - 30  # Space for overflow button
        
        self.overflow_start = -1
        
        for i in range(len(self.items)):
            if x + self.items[i].width > max_x:
                self.overflow_start = i
                break
            x += self.items[i].width + 2
    
    fn get_item_rect(self, index: Int32) -> RectInt:
        """Get rectangle for toolbar item."""
        if index < 0 or index >= len(self.items):
            return RectInt(0, 0, 0, 0)
        
        if self.overflow_start >= 0 and index >= self.overflow_start:
            return RectInt(0, 0, 0, 0)  # In overflow menu
        
        var x = self.bounds.x + 2
        for i in range(index):
            x += self.items[i].width + 2
        
        return RectInt(x, self.bounds.y + 2, self.items[index].width, self.button_height)
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        if not self.contains_point(point):
            self.hover_item = -1
            return False
        
        # Find which item was clicked
        for i in range(len(self.items)):
            if self.overflow_start >= 0 and i >= self.overflow_start:
                break
            
            let rect = self.get_item_rect(i)
            if rect.contains(point):
                self.hover_item = i
                
                if event.pressed and self.items[i].enabled:
                    if self.items[i].item_type == TOOLBAR_TOGGLE:
                        self.items[i].toggled = not self.items[i].toggled
                    elif self.items[i].item_type == TOOLBAR_DROPDOWN:
                        self.dropdown_open = i if self.dropdown_open != i else -1
                    
                    self.pressed_item = i
                    return True
                
                return True
        
        self.hover_item = -1
        return True
    
    fn render(self, ctx: RenderingContextInt):
        """Render toolbar."""
        if not self.visible:
            return
        
        # Background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                     self.bounds.width, self.bounds.height)
        
        # Calculate overflow
        self.calculate_overflow()
        
        # Render items
        for i in range(len(self.items)):
            if self.overflow_start >= 0 and i >= self.overflow_start:
                break
            self.render_item(ctx, i)
        
        # Render overflow button if needed
        if self.overflow_start >= 0:
            self.render_overflow_button(ctx)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y,
                              self.bounds.width, self.bounds.height)
        
        # Render open dropdown
        if self.dropdown_open >= 0:
            self.render_dropdown(ctx, self.dropdown_open)
    
    fn render_item(self, ctx: RenderingContextInt, index: Int32):
        """Render individual toolbar item."""
        let item = self.items[index]
        let rect = self.get_item_rect(index)
        
        if item.item_type == TOOLBAR_SEPARATOR:
            # Draw separator line
            let x = rect.x + rect.width // 2
            _ = ctx.set_color(self.separator_color.r, self.separator_color.g,
                             self.separator_color.b, self.separator_color.a)
            _ = ctx.draw_line(x, rect.y, x, rect.y + rect.height, 1)
            return
        
        # Button background
        var bg_color = self.button_color
        if not item.enabled:
            bg_color = self.background_color
        elif item.toggled:
            bg_color = self.button_toggled_color
        elif index == self.pressed_item:
            bg_color = self.button_pressed_color
        elif index == self.hover_item:
            bg_color = self.button_hover_color
        
        if bg_color.a > 0:
            _ = ctx.set_color(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
            _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        # Content position
        var content_x = rect.x + self.button_padding
        let content_y = rect.y + (rect.height - self.icon_size) // 2
        
        # Icon (placeholder - draw small square)
        if self.show_icons:
            let icon_color = self.text_color if item.enabled else self.disabled_color
            _ = ctx.set_color(icon_color.r, icon_color.g, 
                             icon_color.b, icon_color.a)
            _ = ctx.draw_filled_rectangle(content_x, content_y, 
                                         self.icon_size, self.icon_size)
            content_x += self.icon_size + self.button_padding
        
        # Text
        if self.show_text and len(item.text) > 0:
            let text_color = self.text_color if item.enabled else self.disabled_color
            _ = ctx.set_color(text_color.r, text_color.g, 
                             text_color.b, text_color.a)
            _ = ctx.draw_text(item.text, content_x, rect.y + 8, 11)
        
        # Dropdown arrow
        if item.item_type == TOOLBAR_DROPDOWN:
            let arrow_x = rect.x + rect.width - 10
            let arrow_y = rect.y + rect.height // 2
            _ = ctx.draw_line(arrow_x - 3, arrow_y - 2, arrow_x, arrow_y + 1, 1)
            _ = ctx.draw_line(arrow_x, arrow_y + 1, arrow_x + 3, arrow_y - 2, 1)
        
        # Button border on hover/press
        if index == self.hover_item or index == self.pressed_item:
            _ = ctx.set_color(self.border_color.r, self.border_color.g,
                             self.border_color.b, self.border_color.a)
            _ = ctx.draw_rectangle(rect.x, rect.y, rect.width, rect.height)
    
    fn render_overflow_button(self, ctx: RenderingContextInt):
        """Render overflow menu button."""
        let x = self.bounds.x + self.bounds.width - 25
        let y = self.bounds.y + 2
        let w = 20
        let h = self.button_height
        
        # Button background
        _ = ctx.set_color(self.button_hover_color.r, self.button_hover_color.g,
                         self.button_hover_color.b, self.button_hover_color.a)
        _ = ctx.draw_filled_rectangle(x, y, w, h)
        
        // Draw >> symbol
        _ = ctx.set_color(self.text_color.r, self.text_color.g,
                         self.text_color.b, self.text_color.a)
        _ = ctx.draw_text("»", x + 5, y + 8, 12)
        
        // Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(x, y, w, h)
    
    fn render_dropdown(self, ctx: RenderingContextInt, index: Int32):
        """Render dropdown menu."""
        let item = self.items[index]
        let button_rect = self.get_item_rect(index)
        
        let menu_x = button_rect.x
        let menu_y = button_rect.y + button_rect.height + 2
        let menu_width = 150
        let item_height = 20
        let menu_height = len(item.dropdown_items) * item_height + 4
        
        // Shadow
        _ = ctx.set_color(0, 0, 0, 30)
        _ = ctx.draw_filled_rectangle(menu_x + 2, menu_y + 2, menu_width, menu_height)
        
        // Background
        _ = ctx.set_color(255, 255, 255, 255)
        _ = ctx.draw_filled_rectangle(menu_x, menu_y, menu_width, menu_height)
        
        // Items
        for i in range(len(item.dropdown_items)):
            let item_y = menu_y + 2 + i * item_height
            
            // Hover effect (simplified)
            if i == 0:  // Demo hover on first item
                _ = ctx.set_color(self.button_hover_color.r, self.button_hover_color.g,
                                 self.button_hover_color.b, self.button_hover_color.a)
                _ = ctx.draw_filled_rectangle(menu_x + 2, item_y, 
                                             menu_width - 4, item_height)
            
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
            _ = ctx.draw_text(item.dropdown_items[i], menu_x + 8, item_y + 4, 11)
        
        // Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(menu_x, menu_y, menu_width, menu_height)
    
    fn update(inout self):
        """Update toolbar state."""
        # Reset pressed state after release
        if self.pressed_item >= 0:
            # In real implementation, check mouse button state
            self.pressed_item = -1


# Convenience functions
fn create_dock_panel_int(x: Int32, y: Int32, width: Int32, height: Int32) -> DockPanelInt:
    """Create a dock panel system."""
    return DockPanelInt(x, y, width, height)

fn create_accordion_int(x: Int32, y: Int32, width: Int32, height: Int32,
                       mode: Int32 = ACCORDION_SINGLE) -> AccordionInt:
    """Create an accordion widget."""
    return AccordionInt(x, y, width, height, mode)

fn create_toolbar_int(x: Int32, y: Int32, width: Int32, height: Int32 = 32) -> ToolBarInt:
    """Create a toolbar."""
    return ToolBarInt(x, y, width, height)

# Demo function
fn demo_advanced_widgets():
    """Demo showing dock panel, accordion, and toolbar."""
    # This would be integrated into your main application
    pass