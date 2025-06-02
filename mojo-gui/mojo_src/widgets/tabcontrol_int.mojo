"""
Integer-Only TabControl Widget Implementation
Tabbed interface widget using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

struct TabPageInt:
    """Individual tab page."""
    var title: String
    var content_widgets: List[Int32]  # Would hold widget IDs in a real implementation
    var enabled: Bool
    var visible: Bool
    var data: Int32
    
    fn __init__(inout self, title: String, data: Int32 = 0):
        self.title = title
        self.content_widgets = List[Int32]()
        self.enabled = True
        self.visible = True
        self.data = data

struct TabControlInt(BaseWidgetInt):
    """Tabbed interface widget using integer coordinates."""
    
    var tabs: List[TabPageInt]
    var tab_widths: List[Int32]
    var active_tab: Int32
    var hover_tab: Int32
    var tab_height: Int32
    var tab_text_color: ColorInt
    var tab_active_color: ColorInt
    var tab_inactive_color: ColorInt
    var tab_hover_color: ColorInt
    var tab_disabled_color: ColorInt
    var content_color: ColorInt
    var font_size: Int32
    var tab_padding: Int32
    var min_tab_width: Int32
    var max_tab_width: Int32
    var close_buttons: Bool
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        """Initialize tab control."""
        self.super().__init__(x, y, width, height)
        self.tabs = List[TabPageInt]()
        self.tab_widths = List[Int32]()
        self.active_tab = 0
        self.hover_tab = -1
        self.tab_height = 30
        
        self.tab_text_color = ColorInt(0, 0, 0, 255)           # Black text
        self.tab_active_color = ColorInt(255, 255, 255, 255)   # White active tab
        self.tab_inactive_color = ColorInt(220, 220, 220, 255) # Light gray inactive
        self.tab_hover_color = ColorInt(240, 240, 240, 255)    # Lighter gray hover
        self.tab_disabled_color = ColorInt(180, 180, 180, 255) # Gray disabled
        self.content_color = ColorInt(255, 255, 255, 255)      # White content area
        
        self.font_size = 12
        self.tab_padding = 12
        self.min_tab_width = 80
        self.max_tab_width = 200
        self.close_buttons = False
        
        # Set appearance
        self.background_color = ColorInt(240, 240, 240, 255)
        self.border_color = ColorInt(160, 160, 160, 255)
        self.border_width = 1
    
    fn add_tab(inout self, title: String, data: Int32 = 0):
        """Add a new tab."""
        self.tabs.append(TabPageInt(title, data))
        
        # Calculate tab width
        let text_width = len(title) * (self.font_size * 6 // 10) + 2 * self.tab_padding
        var tab_width = text_width
        
        if tab_width < self.min_tab_width:
            tab_width = self.min_tab_width
        elif tab_width > self.max_tab_width:
            tab_width = self.max_tab_width
            
        self.tab_widths.append(tab_width)
        
        # If this is the first tab, make it active
        if len(self.tabs) == 1:
            self.active_tab = 0
    
    fn remove_tab(inout self, index: Int32):
        """Remove tab at index."""
        if index >= 0 and index < len(self.tabs):
            # Mark as disabled instead of actual removal (List.remove might not exist)
            self.tabs[index].enabled = False
            self.tabs[index].visible = False
            
            # Adjust active tab if needed
            if index == self.active_tab:
                # Find next enabled tab
                self.active_tab = -1
                for i in range(len(self.tabs)):
                    if self.tabs[i].enabled and self.tabs[i].visible:
                        self.active_tab = i
                        break
    
    fn get_active_tab(self) -> Int32:
        """Get active tab index."""
        return self.active_tab
    
    fn set_active_tab(inout self, index: Int32):
        """Set active tab."""
        if index >= 0 and index < len(self.tabs) and self.tabs[index].enabled and self.tabs[index].visible:
            self.active_tab = index
    
    fn get_tab_count(self) -> Int32:
        """Get number of visible tabs."""
        var count: Int32 = 0
        for i in range(len(self.tabs)):
            if self.tabs[i].visible:
                count += 1
        return count
    
    fn get_tab_rect(self, tab_index: Int32) -> RectInt:
        """Get rectangle for tab at index."""
        if tab_index < 0 or tab_index >= len(self.tabs) or not self.tabs[tab_index].visible:
            return RectInt(0, 0, 0, 0)
        
        var x = self.bounds.x
        for i in range(tab_index):
            if self.tabs[i].visible:
                x += self.tab_widths[i]
        
        return RectInt(x, self.bounds.y, self.tab_widths[tab_index], self.tab_height)
    
    fn get_content_rect(self) -> RectInt:
        """Get content area rectangle."""
        return RectInt(self.bounds.x, self.bounds.y + self.tab_height,
                      self.bounds.width, self.bounds.height - self.tab_height)
    
    fn tab_index_from_point(self, point: PointInt) -> Int32:
        """Get tab index from point."""
        if point.y < self.bounds.y or point.y > self.bounds.y + self.tab_height:
            return -1
        
        var x = self.bounds.x
        for i in range(len(self.tabs)):
            if not self.tabs[i].visible:
                continue
                
            if point.x >= x and point.x < x + self.tab_widths[i]:
                return i
            x += self.tab_widths[i]
        return -1
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        let inside = self.contains_point(point)
        
        if event.pressed and inside:
            let tab_index = self.tab_index_from_point(point)
            if tab_index >= 0 and self.tabs[tab_index].enabled:
                self.set_active_tab(tab_index)
                return True
        
        # Update hover state
        if inside:
            self.hover_tab = self.tab_index_from_point(point)
        else:
            self.hover_tab = -1
        
        return inside
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle key events (Ctrl+Tab to switch tabs)."""
        if not self.visible or not self.enabled:
            return False
        
        if event.pressed:
            if event.key_code == 258:  # Tab key
                # Switch to next tab
                var next_tab = self.active_tab + 1
                while next_tab < len(self.tabs):
                    if self.tabs[next_tab].enabled and self.tabs[next_tab].visible:
                        self.set_active_tab(next_tab)
                        return True
                    next_tab += 1
                
                # Wrap to first tab
                for i in range(len(self.tabs)):
                    if self.tabs[i].enabled and self.tabs[i].visible:
                        self.set_active_tab(i)
                        return True
        
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render the tab control."""
        if not self.visible:
            return
        
        # Draw content area background first
        let content_rect = self.get_content_rect()
        _ = ctx.set_color(self.content_color.r, self.content_color.g,
                         self.content_color.b, self.content_color.a)
        _ = ctx.draw_filled_rectangle(content_rect.x, content_rect.y, content_rect.width, content_rect.height)
        
        # Draw content area border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(content_rect.x, content_rect.y, content_rect.width, content_rect.height)
        
        # Draw tabs
        for i in range(len(self.tabs)):
            if not self.tabs[i].visible:
                continue
                
            self.render_tab(ctx, i)
        
        # Draw active tab content
        if self.active_tab >= 0 and self.active_tab < len(self.tabs):
            self.render_tab_content(ctx, self.active_tab)
    
    fn render_tab(self, ctx: RenderingContextInt, tab_index: Int32):
        """Render individual tab."""
        let tab_rect = self.get_tab_rect(tab_index)
        let is_active = (tab_index == self.active_tab)
        let is_hover = (tab_index == self.hover_tab) and not is_active
        let is_enabled = self.tabs[tab_index].enabled
        
        # Choose tab color
        var tab_color = self.tab_inactive_color
        if not is_enabled:
            tab_color = self.tab_disabled_color
        elif is_active:
            tab_color = self.tab_active_color
        elif is_hover:
            tab_color = self.tab_hover_color
        
        # Draw tab background
        _ = ctx.set_color(tab_color.r, tab_color.g, tab_color.b, tab_color.a)
        _ = ctx.draw_filled_rectangle(tab_rect.x, tab_rect.y, tab_rect.width, tab_rect.height)
        
        # Draw tab borders (not bottom for active tab)
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        
        # Top border
        _ = ctx.draw_line(tab_rect.x, tab_rect.y, tab_rect.x + tab_rect.width, tab_rect.y, 1)
        # Left border
        _ = ctx.draw_line(tab_rect.x, tab_rect.y, tab_rect.x, tab_rect.y + tab_rect.height, 1)
        # Right border
        _ = ctx.draw_line(tab_rect.x + tab_rect.width, tab_rect.y, 
                         tab_rect.x + tab_rect.width, tab_rect.y + tab_rect.height, 1)
        
        # Bottom border only for inactive tabs
        if not is_active:
            _ = ctx.draw_line(tab_rect.x, tab_rect.y + tab_rect.height,
                             tab_rect.x + tab_rect.width, tab_rect.y + tab_rect.height, 1)
        
        # Draw tab text
        let text_color = self.tab_text_color if is_enabled else self.tab_disabled_color
        _ = ctx.set_color(text_color.r, text_color.g, text_color.b, text_color.a)
        
        let text_x = tab_rect.x + self.tab_padding
        let text_y = tab_rect.y + (tab_rect.height - self.font_size) // 2
        _ = ctx.draw_text(self.tabs[tab_index].title, text_x, text_y, self.font_size)
        
        # Draw close button if enabled
        if self.close_buttons and is_enabled:
            let close_x = tab_rect.x + tab_rect.width - 20
            let close_y = tab_rect.y + 8
            _ = ctx.set_color(128, 128, 128, 255)
            _ = ctx.draw_line(close_x, close_y, close_x + 8, close_y + 8, 1)
            _ = ctx.draw_line(close_x + 8, close_y, close_x, close_y + 8, 1)
    
    fn render_tab_content(self, ctx: RenderingContextInt, tab_index: Int32):
        """Render content of active tab."""
        let content_rect = self.get_content_rect()
        
        # For demo purposes, just show tab title and info
        _ = ctx.set_color(self.tab_text_color.r, self.tab_text_color.g,
                         self.tab_text_color.b, self.tab_text_color.a)
        
        let content_text = "Content for: " + self.tabs[tab_index].title
        let content_x = content_rect.x + 10
        let content_y = content_rect.y + 20
        _ = ctx.draw_text(content_text, content_x, content_y, self.font_size + 2)
        
        let info_text = "This is the content area for tab " + str(tab_index)
        _ = ctx.draw_text(info_text, content_x, content_y + 30, self.font_size)
    
    fn update(inout self):
        """Update tab control state."""
        # Ensure we have a valid active tab
        if self.active_tab >= len(self.tabs) or 
           (self.active_tab >= 0 and (not self.tabs[self.active_tab].enabled or not self.tabs[self.active_tab].visible)):
            # Find first valid tab
            self.active_tab = -1
            for i in range(len(self.tabs)):
                if self.tabs[i].enabled and self.tabs[i].visible:
                    self.active_tab = i
                    break

# Convenience functions
fn create_tab_control_int(x: Int32, y: Int32, width: Int32, height: Int32) -> TabControlInt:
    """Create a standard tab control."""
    return TabControlInt(x, y, width, height)

fn create_tab_page_int(title: String, data: Int32 = 0) -> TabPageInt:
    """Create a tab page."""
    return TabPageInt(title, data)