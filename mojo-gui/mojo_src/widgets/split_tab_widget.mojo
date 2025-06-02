"""
Split Tab/View Widget with Tooltip Support
Delphi IDE-like functionality for Mojo GUI
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .tabcontrol_int import TabControlInt, TabPageInt

# Tooltip support
struct TooltipInt:
    """Tooltip for displaying hover information."""
    var text: String
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
    var visible: Bool
    var background_color: ColorInt
    var text_color: ColorInt
    var border_color: ColorInt
    var font_size: Int32
    var padding: Int32
    var show_delay_ms: Int32
    var hover_start_time: Int32
    
    fn __init__(inout self):
        self.text = ""
        self.x = 0
        self.y = 0
        self.width = 0
        self.height = 0
        self.visible = False
        self.background_color = ColorInt(255, 255, 225, 255)  # Light yellow
        self.text_color = ColorInt(0, 0, 0, 255)             # Black
        self.border_color = ColorInt(64, 64, 64, 255)        # Dark gray
        self.font_size = 10
        self.padding = 6
        self.show_delay_ms = 500
        self.hover_start_time = 0
    
    fn set_text(inout self, text: String, x: Int32, y: Int32):
        """Set tooltip text and position."""
        self.text = text
        self.x = x
        self.y = y
        
        # Calculate size based on text
        let char_width = (self.font_size * 6) // 10
        self.width = len(text) * char_width + 2 * self.padding
        self.height = self.font_size + 2 * self.padding
    
    fn show(inout self):
        """Show the tooltip."""
        self.visible = True
    
    fn hide(inout self):
        """Hide the tooltip."""
        self.visible = False
        self.text = ""
    
    fn render(self, ctx: RenderingContextInt):
        """Render the tooltip."""
        if not self.visible or len(self.text) == 0:
            return
        
        # Draw background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.x, self.y, self.width, self.height)
        
        # Draw border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(self.x, self.y, self.width, self.height)
        
        # Draw text
        _ = ctx.set_color(self.text_color.r, self.text_color.g,
                         self.text_color.b, self.text_color.a)
        _ = ctx.draw_text(self.text, self.x + self.padding, 
                         self.y + self.padding, self.font_size)

# Enhanced TabControl with tooltip support
struct TabControlWithTooltipsInt(TabControlInt):
    """Tab control with tooltip support."""
    var tab_tooltips: List[String]
    var tooltip: TooltipInt
    var last_hover_tab: Int32
    var hover_time: Int32
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.super().__init__(x, y, width, height)
        self.tab_tooltips = List[String]()
        self.tooltip = TooltipInt()
        self.last_hover_tab = -1
        self.hover_time = 0
    
    fn add_tab_with_tooltip(inout self, title: String, tooltip: String, data: Int32 = 0):
        """Add a tab with tooltip."""
        self.add_tab(title, data)
        self.tab_tooltips.append(tooltip)
    
    fn update_tooltip(inout self):
        """Update tooltip based on hover state."""
        if self.hover_tab >= 0 and self.hover_tab < len(self.tabs):
            if self.hover_tab != self.last_hover_tab:
                # Reset hover time on tab change
                self.hover_time = 0
                self.last_hover_tab = self.hover_tab
                self.tooltip.hide()
            else:
                # Increment hover time
                self.hover_time += 16  # Assume 60 FPS, ~16ms per frame
                
                if self.hover_time >= self.tooltip.show_delay_ms and not self.tooltip.visible:
                    # Show tooltip
                    if self.hover_tab < len(self.tab_tooltips):
                        let tab_rect = self.get_tab_rect(self.hover_tab)
                        let tooltip_text = self.tab_tooltips[self.hover_tab]
                        self.tooltip.set_text(tooltip_text, 
                                            tab_rect.x + 10,
                                            tab_rect.y + tab_rect.height + 2)
                        self.tooltip.show()
        else:
            # No hover, hide tooltip
            self.tooltip.hide()
            self.hover_time = 0
            self.last_hover_tab = -1
    
    fn render(self, ctx: RenderingContextInt):
        """Render tab control and tooltip."""
        # Render base tab control
        self.super().render(ctx)
        
        # Render tooltip on top
        self.tooltip.render(ctx)
    
    fn update(inout self):
        """Update tab control."""
        self.super().update()
        self.update_tooltip()

# Splitter orientation
alias SPLIT_HORIZONTAL = 0
alias SPLIT_VERTICAL = 1

# Split container widget
struct SplitContainerInt(BaseWidgetInt):
    """Split container that divides area into two resizable panes."""
    var orientation: Int32  # SPLIT_HORIZONTAL or SPLIT_VERTICAL
    var split_position: Int32
    var splitter_width: Int32
    var min_pane_size: Int32
    var pane1_widget: TabControlWithTooltipsInt
    var pane2_widget: TabControlWithTooltipsInt
    var dragging: Bool
    var drag_start_pos: Int32
    var drag_start_split: Int32
    var splitter_color: ColorInt
    var splitter_hover_color: ColorInt
    var hovering_splitter: Bool
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, 
                orientation: Int32 = SPLIT_HORIZONTAL):
        self.super().__init__(x, y, width, height)
        self.orientation = orientation
        self.splitter_width = 6
        self.min_pane_size = 100
        
        # Initialize split position to middle
        if orientation == SPLIT_HORIZONTAL:
            self.split_position = width // 2
        else:
            self.split_position = height // 2
        
        # Create tab controls for each pane
        let (rect1, rect2) = self.calculate_pane_rects()
        self.pane1_widget = TabControlWithTooltipsInt(rect1.x, rect1.y, rect1.width, rect1.height)
        self.pane2_widget = TabControlWithTooltipsInt(rect2.x, rect2.y, rect2.width, rect2.height)
        
        self.dragging = False
        self.drag_start_pos = 0
        self.drag_start_split = 0
        self.splitter_color = ColorInt(200, 200, 200, 255)
        self.splitter_hover_color = ColorInt(100, 150, 200, 255)
        self.hovering_splitter = False
        
        # Remove container background
        self.background_color = ColorInt(240, 240, 240, 0)
    
    fn calculate_pane_rects(self) -> (RectInt, RectInt):
        """Calculate rectangles for both panes."""
        var rect1 = RectInt(0, 0, 0, 0)
        var rect2 = RectInt(0, 0, 0, 0)
        
        if self.orientation == SPLIT_HORIZONTAL:
            # Horizontal split (side by side)
            rect1 = RectInt(self.bounds.x, self.bounds.y, 
                           self.split_position, self.bounds.height)
            rect2 = RectInt(self.bounds.x + self.split_position + self.splitter_width,
                           self.bounds.y,
                           self.bounds.width - self.split_position - self.splitter_width,
                           self.bounds.height)
        else:
            # Vertical split (top and bottom)
            rect1 = RectInt(self.bounds.x, self.bounds.y,
                           self.bounds.width, self.split_position)
            rect2 = RectInt(self.bounds.x, 
                           self.bounds.y + self.split_position + self.splitter_width,
                           self.bounds.width,
                           self.bounds.height - self.split_position - self.splitter_width)
        
        return (rect1, rect2)
    
    fn get_splitter_rect(self) -> RectInt:
        """Get splitter bar rectangle."""
        if self.orientation == SPLIT_HORIZONTAL:
            return RectInt(self.bounds.x + self.split_position,
                          self.bounds.y,
                          self.splitter_width,
                          self.bounds.height)
        else:
            return RectInt(self.bounds.x,
                          self.bounds.y + self.split_position,
                          self.bounds.width,
                          self.splitter_width)
    
    fn update_pane_sizes(inout self):
        """Update pane sizes based on split position."""
        let (rect1, rect2) = self.calculate_pane_rects()
        self.pane1_widget.set_bounds(rect1)
        self.pane2_widget.set_bounds(rect2)
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events for splitter dragging."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        let splitter_rect = self.get_splitter_rect()
        let on_splitter = splitter_rect.contains(point)
        
        # Update hover state
        self.hovering_splitter = on_splitter
        
        if event.pressed and on_splitter:
            # Start dragging
            self.dragging = True
            if self.orientation == SPLIT_HORIZONTAL:
                self.drag_start_pos = event.x
            else:
                self.drag_start_pos = event.y
            self.drag_start_split = self.split_position
            return True
        elif not event.pressed:
            # Stop dragging
            self.dragging = False
        
        if self.dragging:
            # Update split position
            var delta: Int32 = 0
            if self.orientation == SPLIT_HORIZONTAL:
                delta = event.x - self.drag_start_pos
            else:
                delta = event.y - self.drag_start_pos
            
            var new_split = self.drag_start_split + delta
            
            # Enforce minimum pane sizes
            let max_split = (self.bounds.width if self.orientation == SPLIT_HORIZONTAL 
                            else self.bounds.height) - self.min_pane_size - self.splitter_width
            
            if new_split < self.min_pane_size:
                new_split = self.min_pane_size
            elif new_split > max_split:
                new_split = max_split
            
            self.split_position = new_split
            self.update_pane_sizes()
            return True
        
        # Pass to panes if not handled
        if self.pane1_widget.handle_mouse_event(event):
            return True
        if self.pane2_widget.handle_mouse_event(event):
            return True
        
        return self.contains_point(point)
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle key events."""
        if not self.visible or not self.enabled:
            return False
        
        # Try pane 1 first, then pane 2
        if self.pane1_widget.handle_key_event(event):
            return True
        if self.pane2_widget.handle_key_event(event):
            return True
        
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render split container."""
        if not self.visible:
            return
        
        # Render panes
        self.pane1_widget.render(ctx)
        self.pane2_widget.render(ctx)
        
        # Render splitter
        let splitter_rect = self.get_splitter_rect()
        let color = self.splitter_hover_color if (self.hovering_splitter or self.dragging) 
                    else self.splitter_color
        
        _ = ctx.set_color(color.r, color.g, color.b, color.a)
        _ = ctx.draw_filled_rectangle(splitter_rect.x, splitter_rect.y,
                                     splitter_rect.width, splitter_rect.height)
        
        # Draw grip lines on splitter
        _ = ctx.set_color(100, 100, 100, 255)
        if self.orientation == SPLIT_HORIZONTAL:
            # Vertical grip lines
            let center_x = splitter_rect.x + splitter_rect.width // 2
            let center_y = splitter_rect.y + splitter_rect.height // 2
            for i in range(-10, 11, 4):
                _ = ctx.draw_line(center_x, center_y + i, center_x, center_y + i + 2, 1)
        else:
            # Horizontal grip lines
            let center_x = splitter_rect.x + splitter_rect.width // 2
            let center_y = splitter_rect.y + splitter_rect.height // 2
            for i in range(-10, 11, 4):
                _ = ctx.draw_line(center_x + i, center_y, center_x + i + 2, center_y, 1)
    
    fn update(inout self):
        """Update split container."""
        self.pane1_widget.update()
        self.pane2_widget.update()
    
    fn get_pane1(inout self) -> TabControlWithTooltipsInt:
        """Get first pane widget."""
        return self.pane1_widget
    
    fn get_pane2(inout self) -> TabControlWithTooltipsInt:
        """Get second pane widget."""
        return self.pane2_widget

# Nested split container for complex layouts
struct NestedSplitContainerInt(BaseWidgetInt):
    """Container that can hold multiple split containers."""
    var root_split: SplitContainerInt
    var sub_splits: List[SplitContainerInt]
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.super().__init__(x, y, width, height)
        self.root_split = SplitContainerInt(x, y, width, height, SPLIT_HORIZONTAL)
        self.sub_splits = List[SplitContainerInt]()
    
    fn split_pane(inout self, pane_index: Int32, orientation: Int32):
        """Split a pane into two."""
        # This would require more complex logic to replace a pane with a split container
        # For now, just a placeholder
        pass
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        return self.root_split.handle_mouse_event(event)
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle key events."""
        return self.root_split.handle_key_event(event)
    
    fn render(self, ctx: RenderingContextInt):
        """Render nested splits."""
        self.root_split.render(ctx)
    
    fn update(inout self):
        """Update nested splits."""
        self.root_split.update()

# Convenience constructor functions
fn create_delphi_style_ide_layout(x: Int32, y: Int32, width: Int32, height: Int32) -> NestedSplitContainerInt:
    """Create a Delphi IDE-style layout with splits and tabs."""
    var layout = NestedSplitContainerInt(x, y, width, height)
    
    # Add tabs to left pane (project explorer, structure view)
    var left_tabs = layout.root_split.get_pane1()
    left_tabs.add_tab_with_tooltip("Project", "Project Explorer - Shows all files in your project", 1)
    left_tabs.add_tab_with_tooltip("Structure", "Structure View - Shows code structure of current file", 2)
    left_tabs.add_tab_with_tooltip("Model", "Model View - UML diagram of classes", 3)
    
    # Add tabs to right pane (code editor, form designer)
    var right_tabs = layout.root_split.get_pane2()
    right_tabs.add_tab_with_tooltip("Unit1.pas", "Pascal source code for Unit1", 10)
    right_tabs.add_tab_with_tooltip("Form1", "Visual form designer for Form1", 11)
    right_tabs.add_tab_with_tooltip("Unit2.pas", "Pascal source code for Unit2", 12)
    
    return layout

fn create_split_container_horizontal(x: Int32, y: Int32, width: Int32, height: Int32) -> SplitContainerInt:
    """Create a horizontal split container."""
    return SplitContainerInt(x, y, width, height, SPLIT_HORIZONTAL)

fn create_split_container_vertical(x: Int32, y: Int32, width: Int32, height: Int32) -> SplitContainerInt:
    """Create a vertical split container."""
    return SplitContainerInt(x, y, width, height, SPLIT_VERTICAL)