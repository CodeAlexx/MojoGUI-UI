"""
Integer-Only Search Box Widget Implementation
Enhanced search field with icon, clear button, and search history.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .widget_constants import *

struct SearchBoxInt(BaseWidgetInt):
    """Enhanced search box widget with features."""
    
    # Text content
    var text: String
    var placeholder: String
    var cursor_position: Int32
    var selection_start: Int32
    var selection_end: Int32
    var scroll_offset: Int32
    
    # Search features
    var search_history: List[String]
    var history_index: Int32
    var max_history_items: Int32
    var show_history: Bool
    var live_search: Bool
    var search_delay: Int32
    var last_search_time: Int32
    var case_sensitive: Bool
    var regex_search: Bool
    var whole_word: Bool
    
    # Visual properties
    var padding: Int32
    var icon_size: Int32
    var button_width: Int32
    var font_size: Int32
    var cursor_blink_time: Int32
    var is_focused: Bool
    var hover_clear: Bool
    var hover_options: Bool
    
    # Colors
    var text_color: ColorInt
    var placeholder_color: ColorInt
    var cursor_color: ColorInt
    var selection_color: ColorInt
    var icon_color: ColorInt
    var button_color: ColorInt
    var button_hover_color: ColorInt
    var history_bg_color: ColorInt
    var history_hover_color: ColorInt
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32 = 30,
                placeholder: String = "Search..."):
        self.super().__init__(x, y, width, height)
        
        self.text = ""
        self.placeholder = placeholder
        self.cursor_position = 0
        self.selection_start = -1
        self.selection_end = -1
        self.scroll_offset = 0
        
        self.search_history = List[String]()
        self.history_index = -1
        self.max_history_items = 10
        self.show_history = False
        self.live_search = True
        self.search_delay = 300  # milliseconds
        self.last_search_time = 0
        self.case_sensitive = False
        self.regex_search = False
        self.whole_word = False
        
        self.padding = 8
        self.icon_size = 16
        self.button_width = 24
        self.font_size = 12
        self.cursor_blink_time = 0
        self.is_focused = False
        self.hover_clear = False
        self.hover_options = False
        
        # Colors
        self.text_color = ColorInt(0, 0, 0, 255)
        self.placeholder_color = ColorInt(128, 128, 128, 255)
        self.cursor_color = ColorInt(0, 0, 0, 255)
        self.selection_color = ColorInt(100, 150, 255, 128)
        self.icon_color = ColorInt(100, 100, 100, 255)
        self.button_color = ColorInt(180, 180, 180, 255)
        self.button_hover_color = ColorInt(100, 100, 100, 255)
        self.history_bg_color = ColorInt(255, 255, 255, 255)
        self.history_hover_color = ColorInt(229, 243, 255, 255)
        
        # Widget appearance
        self.background_color = ColorInt(255, 255, 255, 255)
        self.border_color = ColorInt(180, 180, 180, 255)
        self.border_width = 1
    
    fn get_text(self) -> String:
        """Get current search text."""
        return self.text
    
    fn set_text(inout self, text: String):
        """Set search text."""
        self.text = text
        self.cursor_position = len(text)
        self.clear_selection()
        self.scroll_to_cursor()
    
    fn clear(inout self):
        """Clear search text."""
        self.text = ""
        self.cursor_position = 0
        self.clear_selection()
        self.scroll_offset = 0
    
    fn perform_search(inout self):
        """Execute search with current text."""
        if len(self.text) > 0:
            # Add to history
            self.add_to_history(self.text)
    
    fn add_to_history(inout self, search_text: String):
        """Add search text to history."""
        # Remove if already exists
        for i in range(len(self.search_history)):
            if self.search_history[i] == search_text:
                self.search_history.remove(i)
                break
        
        # Add to front
        self.search_history.insert(0, search_text)
        
        # Limit history size
        while len(self.search_history) > self.max_history_items:
            self.search_history.pop()
    
    fn show_search_history(inout self):
        """Show search history dropdown."""
        self.show_history = True
        self.history_index = -1
    
    fn hide_search_history(inout self):
        """Hide search history dropdown."""
        self.show_history = False
        self.history_index = -1
    
    fn navigate_history(inout self, direction: Int32):
        """Navigate through search history."""
        if len(self.search_history) == 0:
            return
        
        if direction > 0:  # Down
            if self.history_index < len(self.search_history) - 1:
                self.history_index += 1
            else:
                self.history_index = -1
        else:  # Up
            if self.history_index >= 0:
                self.history_index -= 1
            else:
                self.history_index = len(self.search_history) - 1
        
        if self.history_index >= 0:
            self.set_text(self.search_history[self.history_index])
        else:
            self.set_text("")
    
    fn clear_selection(inout self):
        """Clear text selection."""
        self.selection_start = -1
        self.selection_end = -1
    
    fn has_selection(self) -> Bool:
        """Check if there's a selection."""
        return self.selection_start >= 0 and self.selection_end >= 0 and 
               self.selection_start != self.selection_end
    
    fn delete_selection(inout self):
        """Delete selected text."""
        if not self.has_selection():
            return
        
        let start = min(self.selection_start, self.selection_end)
        let end = max(self.selection_start, self.selection_end)
        
        self.text = self.text[:start] + self.text[end:]
        self.cursor_position = start
        self.clear_selection()
    
    fn insert_at_cursor(inout self, insert_text: String):
        """Insert text at cursor position."""
        if self.has_selection():
            self.delete_selection()
        
        let before = self.text[:self.cursor_position]
        let after = self.text[self.cursor_position:]
        self.text = before + insert_text + after
        self.cursor_position += len(insert_text)
        self.scroll_to_cursor()
    
    fn move_cursor(inout self, delta: Int32, extend_selection: Bool = False):
        """Move cursor by delta characters."""
        let new_pos = max(0, min(self.cursor_position + delta, len(self.text)))
        
        if extend_selection:
            if self.selection_start < 0:
                self.selection_start = self.cursor_position
            self.selection_end = new_pos
        else:
            self.clear_selection()
        
        self.cursor_position = new_pos
        self.scroll_to_cursor()
    
    fn scroll_to_cursor(inout self):
        """Ensure cursor is visible."""
        let text_area_width = self.bounds.width - self.padding * 2 - self.icon_size - 
                             self.button_width - 8
        let char_width = self.font_size * 6 // 10
        let cursor_x = self.cursor_position * char_width - self.scroll_offset
        
        if cursor_x < 0:
            self.scroll_offset = self.cursor_position * char_width
        elif cursor_x > text_area_width:
            self.scroll_offset = self.cursor_position * char_width - text_area_width
    
    fn get_text_area_rect(self) -> RectInt:
        """Get the text input area rectangle."""
        let x = self.bounds.x + self.padding + self.icon_size + 4
        let width = self.bounds.width - self.padding * 2 - self.icon_size - 
                   self.button_width - 8
        return RectInt(x, self.bounds.y, width, self.bounds.height)
    
    fn get_clear_button_rect(self) -> RectInt:
        """Get clear button rectangle."""
        let x = self.bounds.x + self.bounds.width - self.button_width - self.padding
        return RectInt(x, self.bounds.y + (self.bounds.height - self.button_width) // 2,
                      self.button_width, self.button_width)
    
    fn get_history_rect(self) -> RectInt:
        """Get history dropdown rectangle."""
        let item_height = 24
        let height = min(len(self.search_history), 8) * item_height + 4
        return RectInt(self.bounds.x, self.bounds.y + self.bounds.height,
                      self.bounds.width, height)
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        let point = PointInt(event.x, event.y)
        
        # Check history dropdown
        if self.show_history:
            let history_rect = self.get_history_rect()
            if history_rect.contains(point):
                let item_height = 24
                let item_index = (event.y - history_rect.y - 2) // item_height
                
                if event.pressed and item_index >= 0 and item_index < len(self.search_history):
                    self.set_text(self.search_history[item_index])
                    self.hide_search_history()
                    self.perform_search()
                
                return True
            elif event.pressed:
                self.hide_search_history()
        
        if not self.contains_point(point):
            return False
        
        # Check clear button
        let clear_rect = self.get_clear_button_rect()
        if clear_rect.contains(point) and len(self.text) > 0:
            self.hover_clear = True
            if event.pressed:
                self.clear()
            return True
        else:
            self.hover_clear = False
        
        # Check text area
        let text_rect = self.get_text_area_rect()
        if text_rect.contains(point):
            if event.pressed:
                self.is_focused = True
                
                # Calculate cursor position
                let char_width = self.font_size * 6 // 10
                let relative_x = event.x - text_rect.x + self.scroll_offset
                self.cursor_position = max(0, min(relative_x // char_width, len(self.text)))
                self.clear_selection()
            
            return True
        
        # Search icon click
        if event.x < self.bounds.x + self.padding + self.icon_size + 4:
            if event.pressed:
                self.perform_search()
            return True
        
        return True
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle keyboard input."""
        if not self.visible or not self.enabled or not self.is_focused:
            return False
        
        if not event.pressed:
            return False
        
        let key = event.key_code
        let shift = event.shift_held
        let ctrl = event.ctrl_held
        
        # Navigation
        if key == KEY_LEFT:
            self.move_cursor(-1, shift)
            return True
        elif key == KEY_RIGHT:
            self.move_cursor(1, shift)
            return True
        elif key == KEY_HOME:
            self.cursor_position = 0
            if not shift:
                self.clear_selection()
            return True
        elif key == KEY_END:
            self.cursor_position = len(self.text)
            if not shift:
                self.clear_selection()
            return True
        elif key == KEY_UP:
            if not self.show_history:
                self.show_search_history()
            else:
                self.navigate_history(-1)
            return True
        elif key == KEY_DOWN:
            if self.show_history:
                self.navigate_history(1)
            return True
        
        # Editing
        elif key == KEY_BACKSPACE:
            if self.has_selection():
                self.delete_selection()
            elif self.cursor_position > 0:
                self.text = self.text[:self.cursor_position-1] + self.text[self.cursor_position:]
                self.cursor_position -= 1
            return True
        elif key == KEY_DELETE:
            if self.has_selection():
                self.delete_selection()
            elif self.cursor_position < len(self.text):
                self.text = self.text[:self.cursor_position] + self.text[self.cursor_position+1:]
            return True
        elif key == KEY_ENTER:
            self.hide_search_history()
            self.perform_search()
            return True
        elif key == KEY_ESCAPE:
            if self.show_history:
                self.hide_search_history()
            else:
                self.clear()
            return True
        
        # Ctrl shortcuts
        elif ctrl:
            if key == ord('A'):
                self.selection_start = 0
                self.selection_end = len(self.text)
                return True
            elif key == ord('C'):
                # Copy (would implement clipboard)
                return True
            elif key == ord('V'):
                # Paste (would implement clipboard)
                return True
            elif key == ord('X'):
                # Cut (would implement clipboard)
                return True
        
        # Character input
        elif event.is_printable():
            self.insert_at_cursor(chr(event.char_code))
            
            # Trigger live search
            if self.live_search:
                self.last_search_time = 0  # Would use actual time
                # In real implementation, would set timer for delayed search
            
            return True
        
        return False
    
    fn render(self, ctx: RenderingContextInt):
        """Render search box."""
        if not self.visible:
            return
        
        # Background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                     self.bounds.width, self.bounds.height)
        
        # Search icon
        let icon_x = self.bounds.x + self.padding
        let icon_y = self.bounds.y + (self.bounds.height - self.icon_size) // 2
        _ = ctx.set_color(self.icon_color.r, self.icon_color.g,
                         self.icon_color.b, self.icon_color.a)
        
        # Draw magnifying glass icon
        _ = ctx.draw_circle(icon_x + 6, icon_y + 6, 5, 16)
        _ = ctx.draw_line(icon_x + 10, icon_y + 10, icon_x + 14, icon_y + 14, 2)
        
        # Text area
        let text_rect = self.get_text_area_rect()
        
        # Selection
        if self.has_selection():
            let char_width = self.font_size * 6 // 10
            let start = min(self.selection_start, self.selection_end)
            let end = max(self.selection_start, self.selection_end)
            let sel_x = text_rect.x + (start * char_width - self.scroll_offset)
            let sel_width = (end - start) * char_width
            
            _ = ctx.set_color(self.selection_color.r, self.selection_color.g,
                             self.selection_color.b, self.selection_color.a)
            _ = ctx.draw_filled_rectangle(sel_x, text_rect.y + 4, sel_width, text_rect.height - 8)
        
        # Text or placeholder
        if len(self.text) > 0:
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
            
            # Clip text to visible area (simplified)
            let visible_text = self.text  # Would implement proper clipping
            let text_x = text_rect.x - self.scroll_offset
            let text_y = text_rect.y + (text_rect.height - self.font_size) // 2
            _ = ctx.draw_text(visible_text, text_x, text_y, self.font_size)
        else:
            _ = ctx.set_color(self.placeholder_color.r, self.placeholder_color.g,
                             self.placeholder_color.b, self.placeholder_color.a)
            let text_y = text_rect.y + (text_rect.height - self.font_size) // 2
            _ = ctx.draw_text(self.placeholder, text_rect.x, text_y, self.font_size)
        
        # Cursor
        if self.is_focused and (self.cursor_blink_time // 30) % 2 == 0:
            let char_width = self.font_size * 6 // 10
            let cursor_x = text_rect.x + (self.cursor_position * char_width - self.scroll_offset)
            
            _ = ctx.set_color(self.cursor_color.r, self.cursor_color.g,
                             self.cursor_color.b, self.cursor_color.a)
            _ = ctx.draw_line(cursor_x, text_rect.y + 4, cursor_x, text_rect.y + text_rect.height - 4, 1)
        
        # Clear button
        if len(self.text) > 0:
            let clear_rect = self.get_clear_button_rect()
            let color = self.button_hover_color if self.hover_clear else self.button_color
            _ = ctx.set_color(color.r, color.g, color.b, color.a)
            
            # Draw X
            let cx = clear_rect.x + clear_rect.width // 2
            let cy = clear_rect.y + clear_rect.height // 2
            _ = ctx.draw_line(cx - 5, cy - 5, cx + 5, cy + 5, 2)
            _ = ctx.draw_line(cx - 5, cy + 5, cx + 5, cy - 5, 2)
        
        # Border
        let border_color = self.icon_color if self.is_focused else self.border_color
        _ = ctx.set_color(border_color.r, border_color.g,
                         border_color.b, border_color.a)
        _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y,
                              self.bounds.width, self.bounds.height)
        
        # History dropdown
        if self.show_history and len(self.search_history) > 0:
            self.render_history_dropdown(ctx)
    
    fn render_history_dropdown(self, ctx: RenderingContextInt):
        """Render search history dropdown."""
        let rect = self.get_history_rect()
        
        # Shadow
        _ = ctx.set_color(0, 0, 0, 30)
        _ = ctx.draw_filled_rectangle(rect.x + 2, rect.y + 2, rect.width, rect.height)
        
        # Background
        _ = ctx.set_color(self.history_bg_color.r, self.history_bg_color.g,
                         self.history_bg_color.b, self.history_bg_color.a)
        _ = ctx.draw_filled_rectangle(rect.x, rect.y, rect.width, rect.height)
        
        # Items
        let item_height = 24
        let visible_items = min(len(self.search_history), 8)
        
        for i in range(visible_items):
            let item_y = rect.y + 2 + i * item_height
            
            # Hover background
            if i == self.history_index:
                _ = ctx.set_color(self.history_hover_color.r, self.history_hover_color.g,
                                 self.history_hover_color.b, self.history_hover_color.a)
                _ = ctx.draw_filled_rectangle(rect.x + 2, item_y, rect.width - 4, item_height)
            
            # Clock icon
            _ = ctx.set_color(self.icon_color.r, self.icon_color.g,
                             self.icon_color.b, self.icon_color.a)
            let icon_x = rect.x + 8
            let icon_y_center = item_y + item_height // 2
            _ = ctx.draw_circle(icon_x + 6, icon_y_center, 5, 12)
            _ = ctx.draw_line(icon_x + 6, icon_y_center, icon_x + 6, icon_y_center - 3, 1)
            _ = ctx.draw_line(icon_x + 6, icon_y_center, icon_x + 9, icon_y_center, 1)
            
            # Text
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
            _ = ctx.draw_text(self.search_history[i], rect.x + 30, item_y + 6, self.font_size)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(rect.x, rect.y, rect.width, rect.height)
    
    fn update(inout self):
        """Update search box state."""
        if self.is_focused:
            self.cursor_blink_time += 1
        
        # Handle live search delay
        if self.live_search and self.last_search_time > 0:
            # Would check actual time elapsed
            # For now, just increment counter
            self.last_search_time += 16  # ~60fps
            if self.last_search_time >= self.search_delay:
                self.perform_search()
                self.last_search_time = 0
    
    fn set_focus(inout self, focused: Bool):
        """Set focus state."""
        self.is_focused = focused
        if not focused:
            self.hide_search_history()

# Convenience functions
fn create_search_box_int(x: Int32, y: Int32, width: Int32, placeholder: String = "Search...") -> SearchBoxInt:
    """Create a search box."""
    return SearchBoxInt(x, y, width, 30, placeholder)

fn create_filter_box_int(x: Int32, y: Int32, width: Int32) -> SearchBoxInt:
    """Create a filter box for live filtering."""
    var box = SearchBoxInt(x, y, width, 30, "Filter...")
    box.live_search = True
    box.search_delay = 100  # Faster response for filtering
    return box