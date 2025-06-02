#!/usr/bin/env python3
"""
Advanced Widget Module
ListView, TabControl, Dialog, Editor, and other advanced controls
"""

try:
    from .mid_level_wrappers import get_wrappers
except ImportError:
    from mid_level_wrappers import get_wrappers

class ListViewWidget:
    """ListView widget implementation"""
    
    def __init__(self, x=0, y=0, width=200, height=150):
        self.wrappers = get_wrappers()
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.widget_id = -1
        self.items = []
        self.selected_items = []
        self.selection_mode = 0  # 0=single, 1=multiple
        self.scroll_offset = 0
        self.item_height = 20
        self.on_selection_change = None
        self.on_item_click = None
        
        # Create the listview
        self.create()
    
    def create(self):
        """Create the listview widget"""
        self.widget_id = len(ListViewWidget._instances)
        ListViewWidget._instances.append(self)
        return self.widget_id >= 0
    
    def add_item(self, text, data=None):
        """Add item to listview"""
        item = {
            'text': text,
            'data': data,
            'selected': False
        }
        self.items.append(item)
        return len(self.items) - 1
    
    def remove_item(self, index):
        """Remove item from listview"""
        if 0 <= index < len(self.items):
            del self.items[index]
            self._update_selection()
            return True
        return False
    
    def clear(self):
        """Clear all items"""
        self.items.clear()
        self.selected_items.clear()
    
    def set_selection(self, index, selected=True):
        """Set item selection state"""
        if 0 <= index < len(self.items):
            old_selection = self.items[index]['selected']
            
            if self.selection_mode == 0:  # Single selection
                self._clear_selection()
            
            self.items[index]['selected'] = selected
            
            if selected and index not in self.selected_items:
                self.selected_items.append(index)
            elif not selected and index in self.selected_items:
                self.selected_items.remove(index)
            
            if old_selection != selected and self.on_selection_change:
                self.on_selection_change(self, self.selected_items)
            
            return True
        return False
    
    def get_selected_items(self):
        """Get list of selected item indices"""
        return self.selected_items.copy()
    
    def get_selected_count(self):
        """Get number of selected items"""
        return len(self.selected_items)
    
    def handle_click(self, x, y):
        """Handle listview click"""
        if not (self.x <= x <= self.x + self.width and 
                self.y <= y <= self.y + self.height):
            return False
        
        # Calculate which item was clicked
        click_y = y - self.y
        item_index = self.scroll_offset + (click_y // self.item_height)
        
        if 0 <= item_index < len(self.items):
            self.set_selection(item_index, not self.items[item_index]['selected'])
            
            if self.on_item_click:
                self.on_item_click(self, item_index, self.items[item_index])
            
            return True
        
        return False
    
    def scroll(self, delta):
        """Scroll the listview"""
        old_offset = self.scroll_offset
        self.scroll_offset = max(0, min(self.scroll_offset + delta, 
                                      max(0, len(self.items) - self._visible_items())))
        return self.scroll_offset != old_offset
    
    def _visible_items(self):
        """Calculate number of visible items"""
        return self.height // self.item_height
    
    def _clear_selection(self):
        """Clear all selections"""
        for item in self.items:
            item['selected'] = False
        self.selected_items.clear()
    
    def _update_selection(self):
        """Update selection list after item removal"""
        self.selected_items = [i for i, item in enumerate(self.items) if item['selected']]
    
    def set_selection_change_handler(self, handler):
        """Set selection change event handler"""
        self.on_selection_change = handler
    
    def set_item_click_handler(self, handler):
        """Set item click event handler"""
        self.on_item_click = handler

# Class variable to track instances
ListViewWidget._instances = []

class TabControlWidget:
    """TabControl widget implementation"""
    
    def __init__(self, x=0, y=0, width=400, height=300):
        self.wrappers = get_wrappers()
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.widget_id = -1
        self.tabs = []
        self.active_tab = 0
        self.tab_height = 30
        self.on_tab_change = None
        
        # Create the tabcontrol
        self.create()
    
    def create(self):
        """Create the tabcontrol widget"""
        self.widget_id = len(TabControlWidget._instances)
        TabControlWidget._instances.append(self)
        return self.widget_id >= 0
    
    def add_tab(self, label, content=None):
        """Add tab to tabcontrol"""
        tab = {
            'label': label,
            'content': content,
            'enabled': True
        }
        self.tabs.append(tab)
        return len(self.tabs) - 1
    
    def remove_tab(self, index):
        """Remove tab from tabcontrol"""
        if 0 <= index < len(self.tabs):
            del self.tabs[index]
            if self.active_tab >= len(self.tabs):
                self.active_tab = max(0, len(self.tabs) - 1)
            return True
        return False
    
    def set_active_tab(self, index):
        """Set active tab"""
        if 0 <= index < len(self.tabs):
            old_tab = self.active_tab
            self.active_tab = index
            
            if old_tab != index and self.on_tab_change:
                self.on_tab_change(self, index, self.tabs[index])
            
            return True
        return False
    
    def get_active_tab(self):
        """Get active tab index"""
        return self.active_tab
    
    def get_content_area(self):
        """Get content area rectangle"""
        return {
            'x': self.x,
            'y': self.y + self.tab_height,
            'width': self.width,
            'height': self.height - self.tab_height
        }
    
    def handle_click(self, x, y):
        """Handle tabcontrol click"""
        # Check if click is in tab area
        if (self.x <= x <= self.x + self.width and 
            self.y <= y <= self.y + self.tab_height):
            
            # Calculate which tab was clicked
            tab_width = self.width // max(1, len(self.tabs))
            tab_index = (x - self.x) // tab_width
            
            if 0 <= tab_index < len(self.tabs):
                self.set_active_tab(tab_index)
                return True
        
        return False
    
    def set_tab_change_handler(self, handler):
        """Set tab change event handler"""
        self.on_tab_change = handler

# Class variable to track instances
TabControlWidget._instances = []

class DialogWidget:
    """Dialog widget implementation"""
    
    def __init__(self, title="Dialog", width=300, height=200):
        self.wrappers = get_wrappers()
        self.title = title
        self.width = width
        self.height = height
        self.x = 100  # Will be centered
        self.y = 100
        self.widget_id = -1
        self.visible = False
        self.modal = True
        self.buttons = []
        self.result = None
        self.on_button_click = None
        self.on_close = None
        
        # Create the dialog
        self.create()
    
    def create(self):
        """Create the dialog widget"""
        self.widget_id = len(DialogWidget._instances)
        DialogWidget._instances.append(self)
        return self.widget_id >= 0
    
    def add_button(self, text, result_value=None):
        """Add button to dialog"""
        button = {
            'text': text,
            'result': result_value,
            'x': 0,
            'y': 0,
            'width': 80,
            'height': 25
        }
        self.buttons.append(button)
        self._layout_buttons()
        return len(self.buttons) - 1
    
    def show(self, center=True):
        """Show the dialog"""
        if center:
            # Center on screen (assuming 800x600 screen)
            self.x = (800 - self.width) // 2
            self.y = (600 - self.height) // 2
        
        self.visible = True
        self.result = None
    
    def hide(self):
        """Hide the dialog"""
        self.visible = False
    
    def close(self, result=None):
        """Close the dialog with result"""
        self.result = result
        self.visible = False
        
        if self.on_close:
            self.on_close(self, result)
    
    def handle_click(self, x, y):
        """Handle dialog click"""
        if not self.visible:
            return False
        
        # Check button clicks
        for i, button in enumerate(self.buttons):
            if (button['x'] <= x <= button['x'] + button['width'] and
                button['y'] <= y <= button['y'] + button['height']):
                
                if self.on_button_click:
                    self.on_button_click(self, i, button)
                
                self.close(button['result'])
                return True
        
        # Check if clicked in dialog area
        return (self.x <= x <= self.x + self.width and 
                self.y <= y <= self.y + self.height)
    
    def _layout_buttons(self):
        """Layout buttons at bottom of dialog"""
        if not self.buttons:
            return
        
        button_area_width = len(self.buttons) * 80 + (len(self.buttons) - 1) * 10
        start_x = self.x + (self.width - button_area_width) // 2
        button_y = self.y + self.height - 35
        
        for i, button in enumerate(self.buttons):
            button['x'] = start_x + i * 90
            button['y'] = button_y
    
    def set_button_click_handler(self, handler):
        """Set button click event handler"""
        self.on_button_click = handler
    
    def set_close_handler(self, handler):
        """Set close event handler"""
        self.on_close = handler

# Class variable to track instances
DialogWidget._instances = []

class EditorWidget:
    """Editor widget implementation - simplified version"""
    
    def __init__(self, x=0, y=0, width=600, height=400):
        self.wrappers = get_wrappers()
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.widget_id = -1
        self.lines = [""]
        self.cursor_line = 0
        self.cursor_column = 0
        self.scroll_x = 0
        self.scroll_y = 0
        self.selection_start = None
        self.selection_end = None
        self.modified = False
        self.language = "plain"
        self.on_text_change = None
        
        # Create the editor
        self.create()
    
    def create(self):
        """Create the editor widget"""
        self.widget_id = len(EditorWidget._instances)
        EditorWidget._instances.append(self)
        return self.widget_id >= 0
    
    def load_text(self, text):
        """Load text into editor"""
        self.lines = text.split('\n')
        self.cursor_line = 0
        self.cursor_column = 0
        self.selection_start = None
        self.selection_end = None
        self.modified = False
        
        if self.on_text_change:
            self.on_text_change(self, text)
    
    def get_text(self):
        """Get all text from editor"""
        return '\n'.join(self.lines)
    
    def insert_char(self, char):
        """Insert character at cursor"""
        if self.cursor_line < len(self.lines):
            line = self.lines[self.cursor_line]
            self.lines[self.cursor_line] = (line[:self.cursor_column] + 
                                          char + 
                                          line[self.cursor_column:])
            self.cursor_column += 1
            self.modified = True
            
            if self.on_text_change:
                self.on_text_change(self, self.get_text())
    
    def insert_text(self, text):
        """Insert text at cursor"""
        for char in text:
            if char == '\n':
                self.insert_newline()
            else:
                self.insert_char(char)
    
    def insert_newline(self):
        """Insert newline at cursor"""
        if self.cursor_line < len(self.lines):
            line = self.lines[self.cursor_line]
            before = line[:self.cursor_column]
            after = line[self.cursor_column:]
            
            self.lines[self.cursor_line] = before
            self.lines.insert(self.cursor_line + 1, after)
            
            self.cursor_line += 1
            self.cursor_column = 0
            self.modified = True
            
            if self.on_text_change:
                self.on_text_change(self, self.get_text())
    
    def backspace(self):
        """Handle backspace"""
        if self.cursor_column > 0:
            line = self.lines[self.cursor_line]
            self.lines[self.cursor_line] = (line[:self.cursor_column-1] + 
                                          line[self.cursor_column:])
            self.cursor_column -= 1
            self.modified = True
        elif self.cursor_line > 0:
            # Join with previous line
            current_line = self.lines[self.cursor_line]
            prev_line = self.lines[self.cursor_line - 1]
            
            self.cursor_column = len(prev_line)
            self.lines[self.cursor_line - 1] = prev_line + current_line
            del self.lines[self.cursor_line]
            self.cursor_line -= 1
            self.modified = True
        
        if self.modified and self.on_text_change:
            self.on_text_change(self, self.get_text())
    
    def move_cursor(self, line_delta, column_delta):
        """Move cursor by delta"""
        new_line = max(0, min(len(self.lines) - 1, self.cursor_line + line_delta))
        
        if new_line != self.cursor_line:
            self.cursor_line = new_line
            self.cursor_column = min(self.cursor_column, len(self.lines[self.cursor_line]))
        else:
            self.cursor_column = max(0, min(len(self.lines[self.cursor_line]), 
                                          self.cursor_column + column_delta))
    
    def set_language(self, language):
        """Set syntax highlighting language"""
        self.language = language
    
    def handle_key(self, key, char=None):
        """Handle key press"""
        # Simplified key handling
        if char and ord(char) >= 32:  # Printable character
            self.insert_char(char)
        elif key == 8:  # Backspace
            self.backspace()
        elif key == 13:  # Enter
            self.insert_newline()
        elif key == 37:  # Left arrow
            self.move_cursor(0, -1)
        elif key == 39:  # Right arrow
            self.move_cursor(0, 1)
        elif key == 38:  # Up arrow
            self.move_cursor(-1, 0)
        elif key == 40:  # Down arrow
            self.move_cursor(1, 0)
        
        return True
    
    def set_text_change_handler(self, handler):
        """Set text change event handler"""
        self.on_text_change = handler

# Class variable to track instances
EditorWidget._instances = []

# Convenience functions for advanced widgets
def ListViewCreate(x, y, width, height):
    """Create listview (middleman to wrapper)"""
    return ListViewWidget(x, y, width, height)

def TabControlCreate(x, y, width, height):
    """Create tabcontrol (middleman to wrapper)"""
    return TabControlWidget(x, y, width, height)

def DialogCreate(title="Dialog", width=300, height=200):
    """Create dialog (middleman to wrapper)"""
    return DialogWidget(title, width, height)

def EditorCreate(x, y, width, height):
    """Create editor (middleman to wrapper)"""
    return EditorWidget(x, y, width, height)

def ListViewAddItem(listview, text, data=None):
    """Add item to listview (middleman to wrapper)"""
    if isinstance(listview, ListViewWidget):
        return listview.add_item(text, data)
    return -1

def TabControlAddTab(tabcontrol, label, content=None):
    """Add tab to tabcontrol (middleman to wrapper)"""
    if isinstance(tabcontrol, TabControlWidget):
        return tabcontrol.add_tab(label, content)
    return -1

def DialogAddButton(dialog, text, result=None):
    """Add button to dialog (middleman to wrapper)"""
    if isinstance(dialog, DialogWidget):
        return dialog.add_button(text, result)
    return -1

def DialogShow(dialog, center=True):
    """Show dialog (middleman to wrapper)"""
    if isinstance(dialog, DialogWidget):
        dialog.show(center)
        return True
    return False

def EditorLoadText(editor, text):
    """Load text into editor (middleman to wrapper)"""
    if isinstance(editor, EditorWidget):
        editor.load_text(text)
        return True
    return False

# Example usage and demo
if __name__ == "__main__":
    print("🔧 Advanced Widget Module")
    print("=========================")
    
    # Test advanced widget creation
    print("\n🧪 Testing advanced widget creation:")
    
    # ListView
    listview = ListViewCreate(50, 50, 200, 150)
    ListViewAddItem(listview, "Item 1", "data1")
    ListViewAddItem(listview, "Item 2", "data2")
    ListViewAddItem(listview, "Item 3", "data3")
    print(f"   ListView created with {len(listview.items)} items")
    
    # TabControl
    tabcontrol = TabControlCreate(300, 50, 400, 300)
    TabControlAddTab(tabcontrol, "Tab 1", "Content 1")
    TabControlAddTab(tabcontrol, "Tab 2", "Content 2")
    TabControlAddTab(tabcontrol, "Tab 3", "Content 3")
    print(f"   TabControl created with {len(tabcontrol.tabs)} tabs")
    
    # Dialog
    dialog = DialogCreate("Confirm Action", 300, 150)
    DialogAddButton(dialog, "OK", "ok")
    DialogAddButton(dialog, "Cancel", "cancel")
    print(f"   Dialog created with {len(dialog.buttons)} buttons")
    
    # Editor
    editor = EditorCreate(50, 400, 600, 300)
    EditorLoadText(editor, "# Sample Code\nprint('Hello, World!')\n\n# More code here...")
    print(f"   Editor created with {len(editor.lines)} lines")
    
    print(f"\n💡 Usage:")
    print(f"   listview = ListViewCreate(x, y, width, height)")
    print(f"   ListViewAddItem(listview, 'Item Text', data)")
    print(f"   tabcontrol = TabControlCreate(x, y, width, height)")
    print(f"   TabControlAddTab(tabcontrol, 'Tab Label')")
    print(f"   dialog = DialogCreate('Title', width, height)")
    print(f"   DialogShow(dialog)")
    print(f"   editor = EditorCreate(x, y, width, height)")
    print(f"   EditorLoadText(editor, 'code content')")