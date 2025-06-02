#!/usr/bin/env python3
"""
Menu Widget Module
Dedicated module for menu system functionality
"""

try:
    from .mid_level_wrappers import get_wrappers
except ImportError:
    from mid_level_wrappers import get_wrappers

class MenuWidget:
    """Menu widget implementation"""
    
    def __init__(self, x=0, y=0, width=200, height=30):
        self.wrappers = get_wrappers()
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.widget_id = -1
        self.items = []
        self.selected_item = -1
        self.open = False
        self.on_item_click = None
        
        # Create the menu
        self.create()
    
    def create(self):
        """Create the menu widget"""
        # Menu creation function would be called here
        # For now using a placeholder since MenuCreate isn't in current bindings
        self.widget_id = len(MenuWidget._instances)
        MenuWidget._instances.append(self)
        return self.widget_id >= 0
    
    def add_item(self, text, shortcut="", enabled=True):
        """Add item to menu"""
        item = {
            'text': text,
            'shortcut': shortcut,
            'enabled': enabled,
            'separator': False
        }
        self.items.append(item)
        return len(self.items) - 1
    
    def add_separator(self):
        """Add separator to menu"""
        item = {
            'text': '',
            'shortcut': '',
            'enabled': True,
            'separator': True
        }
        self.items.append(item)
        return len(self.items) - 1
    
    def handle_click(self, x, y):
        """Handle menu click"""
        if self.x <= x <= self.x + self.width and self.y <= y <= self.y + self.height:
            self.open = not self.open
            return True
        
        if self.open:
            # Check if clicked on menu item
            item_y = self.y + self.height
            for i, item in enumerate(self.items):
                if item['separator']:
                    item_y += 5
                    continue
                
                if (self.x <= x <= self.x + self.width and 
                    item_y <= y <= item_y + 25):
                    if item['enabled'] and self.on_item_click:
                        self.on_item_click(self, i, item)
                    self.open = False
                    return True
                
                item_y += 25
        
        return False
    
    def set_item_click_handler(self, handler):
        """Set item click event handler"""
        self.on_item_click = handler

# Class variable to track instances
MenuWidget._instances = []

class ContextMenuWidget:
    """Context menu widget implementation"""
    
    def __init__(self):
        self.wrappers = get_wrappers()
        self.widget_id = -1
        self.x = 0
        self.y = 0
        self.width = 150
        self.items = []
        self.visible = False
        self.selected_item = -1
        self.on_item_click = None
        
        # Create the context menu
        self.create()
    
    def create(self):
        """Create the context menu widget"""
        # Context menu creation would be called here
        self.widget_id = len(ContextMenuWidget._instances)
        ContextMenuWidget._instances.append(self)
        return self.widget_id >= 0
    
    def add_item(self, text, shortcut="", icon="", enabled=True):
        """Add item to context menu"""
        item = {
            'text': text,
            'shortcut': shortcut,
            'icon': icon,
            'enabled': enabled,
            'checked': False,
            'separator': False
        }
        self.items.append(item)
        return len(self.items) - 1
    
    def add_separator(self):
        """Add separator to context menu"""
        item = {
            'text': '',
            'shortcut': '',
            'icon': '',
            'enabled': True,
            'checked': False,
            'separator': True
        }
        self.items.append(item)
        return len(self.items) - 1
    
    def show(self, x, y):
        """Show context menu at position"""
        self.x = x
        self.y = y
        self.visible = True
        self.selected_item = -1
    
    def hide(self):
        """Hide context menu"""
        self.visible = False
        self.selected_item = -1
    
    def handle_click(self, x, y):
        """Handle context menu click"""
        if not self.visible:
            return False
        
        # Check if clicked on menu item
        item_y = self.y
        for i, item in enumerate(self.items):
            if item['separator']:
                item_y += 5
                continue
            
            if (self.x <= x <= self.x + self.width and 
                item_y <= y <= item_y + 25):
                if item['enabled'] and self.on_item_click:
                    self.on_item_click(self, i, item)
                self.hide()
                return True
            
            item_y += 25
        
        # Clicked outside menu, hide it
        self.hide()
        return False
    
    def set_item_click_handler(self, handler):
        """Set item click event handler"""
        self.on_item_click = handler

# Class variable to track instances
ContextMenuWidget._instances = []

class MenuBarWidget:
    """Menu bar widget implementation"""
    
    def __init__(self, x=0, y=0, width=800, height=30):
        self.wrappers = get_wrappers()
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.menus = []
        self.active_menu = -1
        self.on_menu_click = None
    
    def add_menu(self, title):
        """Add menu to menu bar"""
        menu = MenuWidget(0, 0, 100, self.height)
        menu.title = title
        self.menus.append(menu)
        return menu
    
    def handle_click(self, x, y):
        """Handle menu bar click"""
        if not (self.y <= y <= self.y + self.height):
            return False
        
        # Calculate menu positions
        menu_x = self.x
        for i, menu in enumerate(self.menus):
            menu_width = len(menu.title) * 8 + 20  # Approximate width
            
            if menu_x <= x <= menu_x + menu_width:
                self.active_menu = i
                if self.on_menu_click:
                    self.on_menu_click(self, i, menu)
                return True
            
            menu_x += menu_width
        
        return False
    
    def set_menu_click_handler(self, handler):
        """Set menu click event handler"""
        self.on_menu_click = handler

# Convenience functions for menu creation
def MenuCreate(x=0, y=0, width=200, height=30):
    """Create menu (middleman to wrapper)"""
    return MenuWidget(x, y, width, height)

def ContextMenuCreate():
    """Create context menu (middleman to wrapper)"""
    return ContextMenuWidget()

def MenuBarCreate(x=0, y=0, width=800, height=30):
    """Create menu bar (middleman to wrapper)"""
    return MenuBarWidget(x, y, width, height)

def MenuAddItem(menu, text, shortcut="", enabled=True):
    """Add item to menu (middleman to wrapper)"""
    if isinstance(menu, MenuWidget):
        return menu.add_item(text, shortcut, enabled)
    return -1

def ContextMenuAddItem(context_menu, text, shortcut="", icon="", enabled=True):
    """Add item to context menu (middleman to wrapper)"""
    if isinstance(context_menu, ContextMenuWidget):
        return context_menu.add_item(text, shortcut, icon, enabled)
    return -1

def ContextMenuShow(context_menu, x, y):
    """Show context menu (middleman to wrapper)"""
    if isinstance(context_menu, ContextMenuWidget):
        context_menu.show(x, y)
        return True
    return False

def ContextMenuHide(context_menu):
    """Hide context menu (middleman to wrapper)"""
    if isinstance(context_menu, ContextMenuWidget):
        context_menu.hide()
        return True
    return False

def MenuHandleClick(menu, x, y):
    """Handle menu click (middleman to wrapper)"""
    if isinstance(menu, MenuWidget):
        return menu.handle_click(x, y)
    return False

def ContextMenuHandleClick(context_menu, x, y):
    """Handle context menu click (middleman to wrapper)"""
    if isinstance(context_menu, ContextMenuWidget):
        return context_menu.handle_click(x, y)
    return False

# Example usage and demo
if __name__ == "__main__":
    print("📋 Menu Widget Module")
    print("====================")
    
    # Test menu creation
    print("\n🧪 Testing menu creation:")
    
    # Create menu bar
    menubar = MenuBarCreate(0, 0, 800, 30)
    print(f"   MenuBar created: {len(menubar.menus) == 0}")
    
    # Add File menu
    file_menu = menubar.add_menu("File")
    MenuAddItem(file_menu, "New", "Ctrl+N")
    MenuAddItem(file_menu, "Open", "Ctrl+O")
    MenuAddItem(file_menu, "Save", "Ctrl+S")
    file_menu.add_separator()
    MenuAddItem(file_menu, "Exit", "Alt+F4")
    print(f"   File menu items: {len(file_menu.items)}")
    
    # Add Edit menu
    edit_menu = menubar.add_menu("Edit")
    MenuAddItem(edit_menu, "Undo", "Ctrl+Z")
    MenuAddItem(edit_menu, "Redo", "Ctrl+Y")
    edit_menu.add_separator()
    MenuAddItem(edit_menu, "Cut", "Ctrl+X")
    MenuAddItem(edit_menu, "Copy", "Ctrl+C")
    MenuAddItem(edit_menu, "Paste", "Ctrl+V")
    print(f"   Edit menu items: {len(edit_menu.items)}")
    
    # Create context menu
    context_menu = ContextMenuCreate()
    ContextMenuAddItem(context_menu, "Cut", "Ctrl+X", "cut_icon")
    ContextMenuAddItem(context_menu, "Copy", "Ctrl+C", "copy_icon")
    ContextMenuAddItem(context_menu, "Paste", "Ctrl+V", "paste_icon")
    context_menu.add_separator()
    ContextMenuAddItem(context_menu, "Properties", "", "props_icon")
    print(f"   Context menu items: {len(context_menu.items)}")
    
    # Set up event handlers
    print("\n🎯 Testing event handlers:")
    file_menu.set_item_click_handler(
        lambda menu, index, item: print(f"File menu: '{item['text']}' clicked")
    )
    edit_menu.set_item_click_handler(
        lambda menu, index, item: print(f"Edit menu: '{item['text']}' clicked")
    )
    context_menu.set_item_click_handler(
        lambda menu, index, item: print(f"Context menu: '{item['text']}' clicked")
    )
    
    print(f"   Event handlers set: ✅")
    
    print(f"\n💡 Usage:")
    print(f"   menubar = MenuBarCreate(0, 0, 800, 30)")
    print(f"   file_menu = menubar.add_menu('File')")
    print(f"   MenuAddItem(file_menu, 'New', 'Ctrl+N')")
    print(f"   context_menu = ContextMenuCreate()")
    print(f"   ContextMenuAddItem(context_menu, 'Cut', 'Ctrl+X')")
    print(f"   ContextMenuShow(context_menu, mouse_x, mouse_y)")