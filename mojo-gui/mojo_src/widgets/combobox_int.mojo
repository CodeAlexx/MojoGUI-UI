#!/usr/bin/env mojo
"""
ComboBox/DropDown Widget - Integer-Only API
Professional dropdown list with autocomplete, filtering, and custom item rendering
"""

from sys.ffi import DLHandle, DLSymbol
from memory import UnsafePointer
from ..widget_int import BaseWidgetInt

# Constants
alias MAX_COMBO_ITEMS: Int32 = 256
alias MAX_VISIBLE_ITEMS: Int32 = 8
alias ITEM_HEIGHT: Int32 = 25
alias ARROW_WIDTH: Int32 = 20

# Events
alias EVENT_COMBO_SELECTION_CHANGED: Int32 = 1101
alias EVENT_COMBO_DROPDOWN_OPENED: Int32 = 1102
alias EVENT_COMBO_DROPDOWN_CLOSED: Int32 = 1103

struct ComboItem:
    """Individual item in a ComboBox"""
    var text: String
    var data_id: Int32
    var enabled: Bool
    
    fn __init__(inout self, text: String, data_id: Int32 = 0, enabled: Bool = True):
        self.text = text
        self.data_id = data_id
        self.enabled = enabled

struct ComboBoxInt(BaseWidgetInt):
    """
    Professional ComboBox widget with dropdown list, autocomplete, and filtering
    Supports custom item rendering and extensive user interaction
    """
    var items: List[ComboItem]
    var selected_index: Int32
    var dropdown_visible: Bool
    var editable: Bool
    var max_visible_items: Int32
    var scroll_position: Int32
    var hover_item: Int32
    var dropdown_height: Int32
    var filter_text: String
    var show_filter: Bool
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, 
               editable: Bool = False):
        """Initialize ComboBox with position, size and editability"""
        self.items = List[ComboItem]()
        self.selected_index = -1
        self.dropdown_visible = False
        self.editable = editable
        self.max_visible_items = MAX_VISIBLE_ITEMS
        self.scroll_position = 0
        self.hover_item = -1
        self.dropdown_height = 0
        self.filter_text = ""
        self.show_filter = False
        super().__init__(x, y, width, height, "combobox")

    fn add_item(inout self, text: String, data_id: Int32 = 0, enabled: Bool = True):
        """Add an item to the combobox"""
        self.items.append(ComboItem(text, data_id, enabled))
        self._update_dropdown_height()

    fn insert_item(inout self, index: Int32, text: String, data_id: Int32 = 0, enabled: Bool = True):
        """Insert an item at specific index"""
        if index >= 0 and index <= len(self.items):
            self.items.insert(index, ComboItem(text, data_id, enabled))
            self._update_dropdown_height()
            # Adjust selected index if needed
            if self.selected_index >= index:
                self.selected_index += 1

    fn remove_item(inout self, index: Int32):
        """Remove item at index"""
        if index >= 0 and index < len(self.items):
            _ = self.items.pop(index)
            self._update_dropdown_height()
            # Adjust selected index
            if self.selected_index == index:
                self.selected_index = -1
            elif self.selected_index > index:
                self.selected_index -= 1

    fn clear_items(inout self):
        """Remove all items"""
        self.items.clear()
        self.selected_index = -1
        self.dropdown_height = 0

    fn set_selected_index(inout self, index: Int32):
        """Set selected item by index"""
        if index >= -1 and index < len(self.items):
            var old_index = self.selected_index
            self.selected_index = index
            if old_index != index:
                self.trigger_event(EVENT_COMBO_SELECTION_CHANGED, index)

    fn get_selected_index(self) -> Int32:
        """Get currently selected index (-1 if none)"""
        return self.selected_index

    fn get_selected_text(self) -> String:
        """Get text of selected item"""
        if self.selected_index >= 0 and self.selected_index < len(self.items):
            return self.items[self.selected_index].text
        return ""

    fn get_selected_data_id(self) -> Int32:
        """Get data ID of selected item"""
        if self.selected_index >= 0 and self.selected_index < len(self.items):
            return self.items[self.selected_index].data_id
        return 0

    fn find_item_by_text(self, text: String) -> Int32:
        """Find item index by text (returns -1 if not found)"""
        for i in range(len(self.items)):
            if self.items[i].text == text:
                return i
        return -1

    fn set_filter(inout self, filter_text: String):
        """Set filter text for autocomplete/filtering"""
        self.filter_text = filter_text
        self.show_filter = len(filter_text) > 0

    fn _update_dropdown_height(inout self):
        """Update dropdown height based on items"""
        var visible_items = min(len(self.items), self.max_visible_items)
        self.dropdown_height = visible_items * ITEM_HEIGHT

    fn _get_filtered_items(self) -> List[Int32]:
        """Get list of item indices that match current filter"""
        var filtered_indices = List[Int32]()
        
        if not self.show_filter or len(self.filter_text) == 0:
            # No filter - show all items
            for i in range(len(self.items)):
                filtered_indices.append(i)
        else:
            # Filter items by text
            var filter_lower = self.filter_text.lower()
            for i in range(len(self.items)):
                if filter_lower in self.items[i].text.lower():
                    filtered_indices.append(i)
        
        return filtered_indices

    fn open_dropdown(inout self):
        """Open the dropdown list"""
        if not self.dropdown_visible:
            self.dropdown_visible = True
            self.hover_item = -1
            self.scroll_position = 0
            self._update_dropdown_height()
            self.trigger_event(EVENT_COMBO_DROPDOWN_OPENED, 0)

    fn close_dropdown(inout self):
        """Close the dropdown list"""
        if self.dropdown_visible:
            self.dropdown_visible = False
            self.hover_item = -1
            self.trigger_event(EVENT_COMBO_DROPDOWN_CLOSED, 0)

    fn handle_mouse_down(inout self, mouse_x: Int32, mouse_y: Int32) -> Bool:
        """Handle mouse down events"""
        # Check if clicking on dropdown arrow or main area
        if self.is_point_inside(mouse_x, mouse_y) and self.enabled:
            if not self.dropdown_visible:
                self.open_dropdown()
            else:
                self.close_dropdown()
            return True
        
        # Check if clicking in dropdown area
        if self.dropdown_visible:
            var dropdown_y = self.y + self.height
            if (mouse_x >= self.x and mouse_x <= self.x + self.width and
                mouse_y >= dropdown_y and mouse_y <= dropdown_y + self.dropdown_height):
                
                # Calculate which item was clicked
                var item_offset = (mouse_y - dropdown_y) // ITEM_HEIGHT + self.scroll_position
                var filtered_indices = self._get_filtered_items()
                
                if item_offset >= 0 and item_offset < len(filtered_indices):
                    var actual_index = filtered_indices[item_offset]
                    if self.items[actual_index].enabled:
                        self.set_selected_index(actual_index)
                        self.close_dropdown()
                        return True
            else:
                # Clicked outside dropdown - close it
                self.close_dropdown()
        
        return False

    fn handle_mouse_move(inout self, mouse_x: Int32, mouse_y: Int32):
        """Handle mouse movement for hover effects"""
        if not self.dropdown_visible:
            return
            
        var dropdown_y = self.y + self.height
        if (mouse_x >= self.x and mouse_x <= self.x + self.width and
            mouse_y >= dropdown_y and mouse_y <= dropdown_y + self.dropdown_height):
            
            var item_offset = (mouse_y - dropdown_y) // ITEM_HEIGHT + self.scroll_position
            var filtered_indices = self._get_filtered_items()
            
            if item_offset >= 0 and item_offset < len(filtered_indices):
                self.hover_item = filtered_indices[item_offset]
            else:
                self.hover_item = -1
        else:
            self.hover_item = -1

    fn handle_scroll(inout self, delta: Int32):
        """Handle mouse wheel scrolling in dropdown"""
        if not self.dropdown_visible:
            return
            
        var filtered_indices = self._get_filtered_items()
        var max_scroll = max(0, len(filtered_indices) - self.max_visible_items)
        
        self.scroll_position = max(0, min(max_scroll, self.scroll_position + delta))

    fn handle_key_input(inout self, key_code: Int32) -> Bool:
        """Handle keyboard input"""
        if not self.focused:
            return False

        if key_code == 13:  # Enter
            if self.dropdown_visible:
                self.close_dropdown()
            else:
                self.open_dropdown()
            return True
        elif key_code == 27:  # Escape
            self.close_dropdown()
            return True
        elif key_code == 38:  # Up arrow
            if self.dropdown_visible:
                var filtered_indices = self._get_filtered_items()
                if len(filtered_indices) > 0:
                    var current_pos = -1
                    for i in range(len(filtered_indices)):
                        if filtered_indices[i] == self.selected_index:
                            current_pos = i
                            break
                    if current_pos > 0:
                        self.set_selected_index(filtered_indices[current_pos - 1])
            else:
                self.open_dropdown()
            return True
        elif key_code == 40:  # Down arrow
            if self.dropdown_visible:
                var filtered_indices = self._get_filtered_items()
                if len(filtered_indices) > 0:
                    var current_pos = -1
                    for i in range(len(filtered_indices)):
                        if filtered_indices[i] == self.selected_index:
                            current_pos = i
                            break
                    if current_pos < len(filtered_indices) - 1:
                        self.set_selected_index(filtered_indices[current_pos + 1])
                    elif current_pos == -1:
                        self.set_selected_index(filtered_indices[0])
            else:
                self.open_dropdown()
            return True

        return False

    fn draw(self, lib: DLHandle):
        """Draw the combobox widget"""
        if not self.visible:
            return

        # Get drawing functions
        var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
        var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
        var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
        var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
        var draw_line = lib.get_function[fn(Int32, Int32, Int32, Int32, Int32) -> Int32]("draw_line")

        # Draw main combobox background
        if self.enabled:
            _ = set_color(255, 255, 255, 255)  # White background
        else:
            _ = set_color(240, 240, 240, 255)  # Gray when disabled
        _ = draw_filled_rectangle(self.x, self.y, self.width, self.height)

        # Draw border
        if self.focused:
            _ = set_color(100, 150, 255, 255)  # Blue when focused
        elif self.dropdown_visible:
            _ = set_color(100, 150, 255, 255)  # Blue when open
        else:
            _ = set_color(180, 180, 180, 255)  # Gray border
        _ = draw_rectangle(self.x, self.y, self.width, self.height)

        # Draw selected text
        var display_text = self.get_selected_text()
        if len(display_text) == 0:
            display_text = "Select..."
            _ = set_color(150, 150, 150, 255)  # Gray placeholder
        else:
            _ = set_color(0, 0, 0, 255)  # Black text

        var text_bytes = display_text.as_bytes()
        var text_ptr = text_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(text_ptr, self.x + 8, self.y + self.height // 2 - 6, 12)

        # Draw dropdown arrow
        var arrow_x = self.x + self.width - ARROW_WIDTH + ARROW_WIDTH // 2
        var arrow_y = self.y + self.height // 2

        _ = set_color(100, 100, 100, 255)  # Dark gray arrow
        if self.dropdown_visible:
            # Up arrow when open
            _ = draw_line(arrow_x, arrow_y - 2, arrow_x - 4, arrow_y + 3, 2)
            _ = draw_line(arrow_x, arrow_y - 2, arrow_x + 4, arrow_y + 3, 2)
        else:
            # Down arrow when closed
            _ = draw_line(arrow_x, arrow_y + 2, arrow_x - 4, arrow_y - 3, 2)
            _ = draw_line(arrow_x, arrow_y + 2, arrow_x + 4, arrow_y - 3, 2)

        # Draw dropdown separator line
        _ = set_color(200, 200, 200, 255)
        var sep_x = self.x + self.width - ARROW_WIDTH
        _ = draw_line(sep_x, self.y + 2, sep_x, self.y + self.height - 2, 1)

        # Draw dropdown list if visible
        if self.dropdown_visible:
            self._draw_dropdown(lib)

        # Draw disabled overlay
        if not self.enabled:
            _ = set_color(255, 255, 255, 128)  # Semi-transparent white
            _ = draw_filled_rectangle(self.x, self.y, self.width, self.height)

    fn _draw_dropdown(self, lib: DLHandle):
        """Draw the dropdown list"""
        var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
        var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
        var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
        var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")

        var dropdown_y = self.y + self.height
        var filtered_indices = self._get_filtered_items()
        
        if len(filtered_indices) == 0:
            return

        # Draw dropdown background
        _ = set_color(255, 255, 255, 255)  # White background
        _ = draw_filled_rectangle(self.x, dropdown_y, self.width, self.dropdown_height)

        # Draw dropdown border
        _ = set_color(180, 180, 180, 255)  # Gray border
        _ = draw_rectangle(self.x, dropdown_y, self.width, self.dropdown_height)

        # Draw visible items
        var visible_count = min(len(filtered_indices) - self.scroll_position, self.max_visible_items)
        
        for i in range(visible_count):
            var item_index = filtered_indices[self.scroll_position + i]
            var item_y = dropdown_y + i * ITEM_HEIGHT
            
            # Draw item background
            if item_index == self.hover_item:
                _ = set_color(230, 240, 255, 255)  # Light blue hover
                _ = draw_filled_rectangle(self.x + 1, item_y + 1, self.width - 2, ITEM_HEIGHT - 1)
            elif item_index == self.selected_index:
                _ = set_color(200, 220, 255, 255)  # Blue selected
                _ = draw_filled_rectangle(self.x + 1, item_y + 1, self.width - 2, ITEM_HEIGHT - 1)

            # Draw item text
            if self.items[item_index].enabled:
                _ = set_color(0, 0, 0, 255)  # Black text
            else:
                _ = set_color(150, 150, 150, 255)  # Gray disabled text

            var item_text = self.items[item_index].text
            var item_bytes = item_text.as_bytes()
            var item_ptr = item_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(item_ptr, self.x + 8, item_y + ITEM_HEIGHT // 2 - 6, 12)

        # Draw scrollbar if needed
        if len(filtered_indices) > self.max_visible_items:
            self._draw_scrollbar(lib, dropdown_y, filtered_indices)

    fn _draw_scrollbar(self, lib: DLHandle, dropdown_y: Int32, filtered_indices: List[Int32]):
        """Draw scrollbar for dropdown"""
        var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
        var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
        
        var scrollbar_width: Int32 = 12
        var scrollbar_x = self.x + self.width - scrollbar_width
        
        # Draw scrollbar track
        _ = set_color(230, 230, 230, 255)  # Light gray track
        _ = draw_filled_rectangle(scrollbar_x, dropdown_y, scrollbar_width, self.dropdown_height)
        
        # Calculate thumb size and position
        var total_items = len(filtered_indices)
        var thumb_height = max(20, (self.max_visible_items * self.dropdown_height) // total_items)
        var thumb_y = dropdown_y + (self.scroll_position * (self.dropdown_height - thumb_height)) // (total_items - self.max_visible_items)
        
        # Draw scrollbar thumb
        _ = set_color(180, 180, 180, 255)  # Gray thumb
        _ = draw_filled_rectangle(scrollbar_x + 2, thumb_y, scrollbar_width - 4, thumb_height)

# Convenience functions for creating ComboBox widgets
fn create_simple_combobox(x: Int32, y: Int32, width: Int32, height: Int32) -> ComboBoxInt:
    """Create a simple non-editable combobox"""
    return ComboBoxInt(x, y, width, height, False)

fn create_editable_combobox(x: Int32, y: Int32, width: Int32, height: Int32) -> ComboBoxInt:
    """Create an editable combobox with autocomplete"""
    return ComboBoxInt(x, y, width, height, True)

fn create_enum_combobox(x: Int32, y: Int32, width: Int32, height: Int32, options: List[String]) -> ComboBoxInt:
    """Create a combobox from a list of enum options"""
    var combo = ComboBoxInt(x, y, width, height, False)
    for i in range(len(options)):
        combo.add_item(options[i], i)
    return combo

fn create_file_type_combobox(x: Int32, y: Int32, width: Int32, height: Int32) -> ComboBoxInt:
    """Create a combobox for common file types"""
    var combo = ComboBoxInt(x, y, width, height, False)
    combo.add_item("All Files (*.*)", 0)
    combo.add_item("Text Files (*.txt)", 1)
    combo.add_item("Mojo Files (*.mojo)", 2)
    combo.add_item("Python Files (*.py)", 3)
    combo.add_item("C/C++ Files (*.c, *.cpp)", 4)
    combo.add_item("Header Files (*.h)", 5)
    return combo