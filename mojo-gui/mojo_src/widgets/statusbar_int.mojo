"""
Integer-Only StatusBar Widget Implementation
Status bar widget for displaying application status using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

# Status panel types
alias STATUS_PANEL_TEXT = 0
alias STATUS_PANEL_PROGRESS = 1
alias STATUS_PANEL_ICON = 2
alias STATUS_PANEL_CLOCK = 3

# Status panel styles
alias STATUS_STYLE_FLAT = 0
alias STATUS_STYLE_SUNKEN = 1
alias STATUS_STYLE_RAISED = 2

struct StatusPanel:
    """Individual panel within the status bar."""
    var id: Int32
    var text: String
    var width: Int32
    var min_width: Int32
    var max_width: Int32
    var auto_size: Bool
    var alignment: Int32
    var panel_type: Int32
    var style: Int32
    var icon_id: Int32
    var progress_value: Int32
    var progress_max: Int32
    var font_size: Int32
    var tooltip: String
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    
    fn __init__(inout self, id: Int32, text: String = "", width: Int32 = 100):
        self.id = id
        self.text = text
        self.width = width
        self.min_width = 50
        self.max_width = 500
        self.auto_size = True
        self.alignment = ALIGN_START
        self.panel_type = STATUS_PANEL_TEXT
        self.style = STATUS_STYLE_SUNKEN
        self.icon_id = -1
        self.progress_value = 0
        self.progress_max = 100
        self.font_size = 11
        self.tooltip = ""
        self.bounds = RectInt(0, 0, 0, 0)
        self.visible = True
        self.enabled = True

struct StatusBarInt(BaseWidgetInt):
    """Status bar widget for displaying application status."""
    
    var panels: List[StatusPanel]
    var panel_count: Int32
    var height: Int32
    var panel_spacing: Int32
    var border_width: Int32
    var grip_size: Int32
    var show_size_grip: Bool
    var font_size: Int32
    
    # Colors
    var panel_color: ColorInt
    var text_color: ColorInt
    var border_color: ColorInt
    var sunken_light_color: ColorInt
    var sunken_dark_color: ColorInt
    var raised_light_color: ColorInt
    var raised_dark_color: ColorInt
    var progress_color: ColorInt
    var progress_bg_color: ColorInt
    
    # Layout
    var content_width: Int32
    var available_width: Int32
    var auto_size_panels: List[Int32]
    
    # Interaction
    var hovered_panel: Int32
    var pressed_panel: Int32
    var resizing_panel: Int32
    var resize_start_x: Int32
    var resize_start_width: Int32
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32 = 24):
        """Initialize status bar."""
        self.super().__init__(x, y, width, height)
        
        self.panels = List[StatusPanel]()
        self.panel_count = 0
        self.height = height
        self.panel_spacing = 2
        self.border_width = 1
        self.grip_size = 16
        self.show_size_grip = True
        self.font_size = 11
        
        # Set colors
        self.panel_color = ColorInt(240, 240, 240, 255)        # Light gray
        self.text_color = ColorInt(0, 0, 0, 255)               # Black
        self.border_color = ColorInt(160, 160, 160, 255)       # Gray
        self.sunken_light_color = ColorInt(128, 128, 128, 255) # Dark gray
        self.sunken_dark_color = ColorInt(255, 255, 255, 255)  # White
        self.raised_light_color = ColorInt(255, 255, 255, 255) # White
        self.raised_dark_color = ColorInt(128, 128, 128, 255)  # Dark gray
        self.progress_color = ColorInt(0, 150, 0, 255)         # Green
        self.progress_bg_color = ColorInt(220, 220, 220, 255)  # Light gray
        
        # Layout
        self.content_width = 0
        self.available_width = width - (self.grip_size if self.show_size_grip else 0)
        self.auto_size_panels = List[Int32]()
        
        # Interaction
        self.hovered_panel = -1
        self.pressed_panel = -1
        self.resizing_panel = -1
        self.resize_start_x = 0
        self.resize_start_width = 0
        
        # Set appearance
        self.background_color = self.panel_color
        self.border_color = ColorInt(160, 160, 160, 255)
        self.border_width = 1
    
    fn add_panel(inout self, text: String, width: Int32 = 100, auto_size: Bool = True) -> Int32:
        """Add a text panel to the status bar."""
        var panel = StatusPanel(self.panel_count, text, width)
        panel.auto_size = auto_size
        panel.panel_type = STATUS_PANEL_TEXT
        
        self.panels.append(panel)
        self.panel_count += 1
        
        if auto_size:
            self.auto_size_panels.append(self.panel_count - 1)
        
        self._recalculate_layout()
        return self.panel_count - 1
    
    fn add_progress_panel(inout self, width: Int32 = 150, max_value: Int32 = 100) -> Int32:
        """Add a progress panel to the status bar."""
        var panel = StatusPanel(self.panel_count, "", width)
        panel.auto_size = False
        panel.panel_type = STATUS_PANEL_PROGRESS
        panel.progress_max = max_value
        
        self.panels.append(panel)
        self.panel_count += 1
        
        self._recalculate_layout()
        return self.panel_count - 1
    
    fn add_clock_panel(inout self, width: Int32 = 80) -> Int32:
        """Add a clock panel to the status bar."""
        var panel = StatusPanel(self.panel_count, "00:00:00", width)
        panel.auto_size = False
        panel.panel_type = STATUS_PANEL_CLOCK
        panel.alignment = ALIGN_CENTER
        
        self.panels.append(panel)
        self.panel_count += 1
        
        self._recalculate_layout()
        return self.panel_count - 1
    
    fn set_panel_text(inout self, panel_index: Int32, text: String):
        """Set text for a specific panel."""
        if panel_index >= 0 and panel_index < self.panel_count:
            self.panels[panel_index].text = text
            if self.panels[panel_index].auto_size:
                self._recalculate_layout()
    
    fn get_panel_text(self, panel_index: Int32) -> String:
        """Get text from a specific panel."""
        if panel_index >= 0 and panel_index < self.panel_count:
            return self.panels[panel_index].text
        return ""
    
    fn set_panel_progress(inout self, panel_index: Int32, value: Int32, max_value: Int32 = -1):
        """Set progress for a progress panel."""
        if panel_index >= 0 and panel_index < self.panel_count:
            if self.panels[panel_index].panel_type == STATUS_PANEL_PROGRESS:
                self.panels[panel_index].progress_value = value
                if max_value >= 0:
                    self.panels[panel_index].progress_max = max_value
    
    fn set_panel_width(inout self, panel_index: Int32, width: Int32):
        """Set width for a specific panel."""
        if panel_index >= 0 and panel_index < self.panel_count:
            self.panels[panel_index].width = width
            self.panels[panel_index].auto_size = False
            self._recalculate_layout()
    
    fn set_panel_style(inout self, panel_index: Int32, style: Int32):
        """Set visual style for a specific panel."""
        if panel_index >= 0 and panel_index < self.panel_count:
            self.panels[panel_index].style = style
    
    fn set_panel_visible(inout self, panel_index: Int32, visible: Bool):
        """Show or hide a specific panel."""
        if panel_index >= 0 and panel_index < self.panel_count:
            self.panels[panel_index].visible = visible
            self._recalculate_layout()
    
    fn remove_panel(inout self, panel_index: Int32):
        """Remove a panel from the status bar."""
        if panel_index >= 0 and panel_index < self.panel_count:
            # Simplified removal - just mark as invisible
            self.panels[panel_index].visible = False
            self._recalculate_layout()
    
    fn _recalculate_layout(inout self):
        """Recalculate panel positions and sizes."""
        self.available_width = self.width - (self.grip_size if self.show_size_grip else 0)
        
        # First pass: calculate fixed widths and count auto-size panels
        var used_width = 0
        var auto_size_count = 0
        
        for i in range(self.panel_count):
            if not self.panels[i].visible:
                continue
            
            if self.panels[i].auto_size:
                auto_size_count += 1
                # Calculate minimum width based on text
                let min_text_width = len(self.panels[i].text) * (self.font_size * 6 // 10) + 16
                used_width += max(self.panels[i].min_width, min_text_width)
            else:
                used_width += self.panels[i].width
            
            if i > 0:
                used_width += self.panel_spacing
        
        # Second pass: distribute remaining space to auto-size panels
        let remaining_width = self.available_width - used_width
        let auto_size_extra = remaining_width // max(1, auto_size_count) if auto_size_count > 0 else 0
        
        # Third pass: set panel bounds
        var current_x = self.x + self.border_width
        
        for i in range(self.panel_count):
            if not self.panels[i].visible:
                self.panels[i].bounds = RectInt(0, 0, 0, 0)
                continue
            
            var panel_width = self.panels[i].width
            if self.panels[i].auto_size:
                let min_text_width = len(self.panels[i].text) * (self.font_size * 6 // 10) + 16
                panel_width = max(self.panels[i].min_width, min_text_width) + auto_size_extra
                panel_width = min(panel_width, self.panels[i].max_width)
            
            let panel_height = self.height - (self.border_width * 2)
            self.panels[i].bounds = RectInt(current_x, self.y + self.border_width, 
                                          panel_width, panel_height)
            
            current_x += panel_width + self.panel_spacing
        
        self.content_width = current_x - self.x
    
    fn hit_test_panel(self, x: Int32, y: Int32) -> Int32:
        """Get the panel index at the specified coordinates."""
        if not self._point_in_bounds(PointInt(x, y)):
            return -1
        
        for i in range(self.panel_count):
            if self.panels[i].visible and self.panels[i].bounds.contains(PointInt(x, y)):
                return i
        
        return -1
    
    fn hit_test_grip(self, x: Int32, y: Int32) -> Bool:
        """Check if coordinates are over the size grip."""
        if not self.show_size_grip:
            return False
        
        let grip_x = self.x + self.width - self.grip_size
        return (x >= grip_x and x <= self.x + self.width and 
                y >= self.y and y <= self.y + self.height)
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events for the status bar."""
        if not self._point_in_bounds(PointInt(event.x, event.y)):
            return False
        
        if self.hit_test_grip(event.x, event.y):
            # Size grip area - could be used for window resizing
            return True
        
        let panel_index = self.hit_test_panel(event.x, event.y)
        
        if event.pressed:
            self.pressed_panel = panel_index
            if panel_index >= 0:
                # Panel clicked - could trigger custom actions
                return True
        else:
            self.pressed_panel = -1
        
        self.hovered_panel = panel_index
        return panel_index >= 0
    
    fn update_clock(inout self):
        """Update clock panels with current time."""
        # This would be called periodically to update clock displays
        # For now, just set a placeholder time
        for i in range(self.panel_count):
            if (self.panels[i].panel_type == STATUS_PANEL_CLOCK and 
                self.panels[i].visible):
                # In a real implementation, would get actual time
                self.panels[i].text = "12:34:56"
    
    fn draw(self, ctx: RenderingContextInt):
        """Draw the status bar."""
        # Draw background
        _ = ctx.set_color(self.panel_color.r, self.panel_color.g, self.panel_color.b, self.panel_color.a)
        _ = ctx.draw_filled_rectangle(self.x, self.y, self.width, self.height)
        
        # Draw top border
        _ = ctx.set_color(self.border_color.r, self.border_color.g, self.border_color.b, self.border_color.a)
        _ = ctx.draw_filled_rectangle(self.x, self.y, self.width, 1)
        
        # Draw panels
        for i in range(self.panel_count):
            if self.panels[i].visible:
                self._draw_panel(ctx, i)
        
        # Draw size grip
        if self.show_size_grip:
            self._draw_size_grip(ctx)
    
    fn _draw_panel(self, ctx: RenderingContextInt, panel_index: Int32):
        """Draw a specific panel."""
        let panel = self.panels[panel_index]
        let bounds = panel.bounds
        
        if bounds.width <= 0 or bounds.height <= 0:
            return
        
        # Draw panel background
        _ = ctx.set_color(self.panel_color.r, self.panel_color.g, self.panel_color.b, self.panel_color.a)
        _ = ctx.draw_filled_rectangle(bounds.x, bounds.y, bounds.width, bounds.height)
        
        # Draw panel border based on style
        if panel.style == STATUS_STYLE_SUNKEN:
            # Sunken effect
            _ = ctx.set_color(self.sunken_light_color.r, self.sunken_light_color.g, 
                            self.sunken_light_color.b, self.sunken_light_color.a)
            _ = ctx.draw_filled_rectangle(bounds.x, bounds.y, bounds.width, 1)  # Top
            _ = ctx.draw_filled_rectangle(bounds.x, bounds.y, 1, bounds.height)  # Left
            
            _ = ctx.set_color(self.sunken_dark_color.r, self.sunken_dark_color.g, 
                            self.sunken_dark_color.b, self.sunken_dark_color.a)
            _ = ctx.draw_filled_rectangle(bounds.x, bounds.y + bounds.height - 1, bounds.width, 1)  # Bottom
            _ = ctx.draw_filled_rectangle(bounds.x + bounds.width - 1, bounds.y, 1, bounds.height)  # Right
        elif panel.style == STATUS_STYLE_RAISED:
            # Raised effect
            _ = ctx.set_color(self.raised_light_color.r, self.raised_light_color.g, 
                            self.raised_light_color.b, self.raised_light_color.a)
            _ = ctx.draw_filled_rectangle(bounds.x, bounds.y, bounds.width, 1)  # Top
            _ = ctx.draw_filled_rectangle(bounds.x, bounds.y, 1, bounds.height)  # Left
            
            _ = ctx.set_color(self.raised_dark_color.r, self.raised_dark_color.g, 
                            self.raised_dark_color.b, self.raised_dark_color.a)
            _ = ctx.draw_filled_rectangle(bounds.x, bounds.y + bounds.height - 1, bounds.width, 1)  # Bottom
            _ = ctx.draw_filled_rectangle(bounds.x + bounds.width - 1, bounds.y, 1, bounds.height)  # Right
        
        # Draw panel content based on type
        if panel.panel_type == STATUS_PANEL_TEXT or panel.panel_type == STATUS_PANEL_CLOCK:
            self._draw_panel_text(ctx, panel_index)
        elif panel.panel_type == STATUS_PANEL_PROGRESS:
            self._draw_panel_progress(ctx, panel_index)
    
    fn _draw_panel_text(self, ctx: RenderingContextInt, panel_index: Int32):
        """Draw text content for a panel."""
        let panel = self.panels[panel_index]
        let bounds = panel.bounds
        
        if len(panel.text) == 0:
            return
        
        # Calculate text position based on alignment
        var text_x = bounds.x + 6  # Default left padding
        let text_y = bounds.y + (bounds.height - panel.font_size) // 2
        
        if panel.alignment == ALIGN_CENTER:
            let text_width = len(panel.text) * (panel.font_size * 6 // 10)
            text_x = bounds.x + (bounds.width - text_width) // 2
        elif panel.alignment == ALIGN_END:
            let text_width = len(panel.text) * (panel.font_size * 6 // 10)
            text_x = bounds.x + bounds.width - text_width - 6
        
        # Draw text
        _ = ctx.set_color(self.text_color.r, self.text_color.g, self.text_color.b, self.text_color.a)
        _ = ctx.draw_text(panel.text, text_x, text_y, panel.font_size)
    
    fn _draw_panel_progress(self, ctx: RenderingContextInt, panel_index: Int32):
        """Draw progress bar content for a panel."""
        let panel = self.panels[panel_index]
        let bounds = panel.bounds
        let margin = 3
        
        # Progress bar background
        _ = ctx.set_color(self.progress_bg_color.r, self.progress_bg_color.g, 
                        self.progress_bg_color.b, self.progress_bg_color.a)
        _ = ctx.draw_filled_rectangle(bounds.x + margin, bounds.y + margin, 
                                    bounds.width - margin * 2, bounds.height - margin * 2)
        
        # Progress bar fill
        if panel.progress_value > 0 and panel.progress_max > 0:
            let progress_width = (bounds.width - margin * 2) * panel.progress_value // panel.progress_max
            _ = ctx.set_color(self.progress_color.r, self.progress_color.g, 
                            self.progress_color.b, self.progress_color.a)
            _ = ctx.draw_filled_rectangle(bounds.x + margin, bounds.y + margin, 
                                        progress_width, bounds.height - margin * 2)
        
        # Progress text
        let percent = panel.progress_value * 100 // panel.progress_max if panel.progress_max > 0 else 0
        let progress_text = str(percent) + "%"
        let text_width = len(progress_text) * (panel.font_size * 6 // 10)
        let text_x = bounds.x + (bounds.width - text_width) // 2
        let text_y = bounds.y + (bounds.height - panel.font_size) // 2
        
        _ = ctx.set_color(self.text_color.r, self.text_color.g, self.text_color.b, self.text_color.a)
        _ = ctx.draw_text(progress_text, text_x, text_y, panel.font_size)
    
    fn _draw_size_grip(self, ctx: RenderingContextInt):
        """Draw the size grip."""
        let grip_x = self.x + self.width - self.grip_size
        let grip_y = self.y
        
        # Draw grip pattern (diagonal lines)
        _ = ctx.set_color(self.border_color.r, self.border_color.g, self.border_color.b, self.border_color.a)
        
        for i in range(3):
            let offset = i * 4 + 4
            let line_x = grip_x + offset
            let line_y = grip_y + self.height - offset
            
            # Draw diagonal line
            for j in range(min(offset, self.grip_size - offset)):
                _ = ctx.draw_filled_rectangle(line_x + j, line_y + j, 1, 1)
    
    fn get_panel_count(self) -> Int32:
        """Get the number of panels."""
        return self.panel_count
    
    fn get_total_width(self) -> Int32:
        """Get the total content width."""
        return self.content_width

# Convenience functions
fn create_simple_statusbar(x: Int32, y: Int32, width: Int32) -> StatusBarInt:
    """Create a simple status bar with one text panel."""
    var statusbar = StatusBarInt(x, y, width)
    _ = statusbar.add_panel("Ready", 0, True)
    return statusbar

fn create_standard_statusbar(x: Int32, y: Int32, width: Int32) -> StatusBarInt:
    """Create a standard status bar with text, progress, and clock panels."""
    var statusbar = StatusBarInt(x, y, width)
    _ = statusbar.add_panel("Ready", 0, True)  # Main status text
    _ = statusbar.add_progress_panel(120, 100)  # Progress bar
    _ = statusbar.add_clock_panel(80)  # Clock
    return statusbar