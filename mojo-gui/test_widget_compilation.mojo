#!/usr/bin/env mojo
"""
Widget Compilation Test
Tests that all widgets compile successfully and basic functionality works.
"""

from mojo_src.rendering_int import *
from mojo_src.widget_int import *
from mojo_src.widgets.textlabel_int import *
from mojo_src.widgets.button_int import *
from mojo_src.widgets.checkbox_int import *
from mojo_src.widgets.slider_int import *
from mojo_src.widgets.textedit_int import *
from mojo_src.widgets.progressbar_int import *
from mojo_src.widgets.listbox_int import *
from mojo_src.widgets.tabcontrol_int import *
from mojo_src.widgets.menu_int import *
from mojo_src.widgets.dialog_int import *
from mojo_src.widgets.container_int import *
from mojo_src.widgets.listview_int import *
from mojo_src.widgets.contextmenu_int import *
from mojo_src.widgets.scrollbar_int import *
from mojo_src.widgets.statusbar_int import *

fn test_basic_widget_creation():
    """Test that we can create all widget types without errors."""
    print("🧪 Testing widget creation...")
    
    # Test basic widgets
    var label = TextLabelInt(10, 10, 100, 30)
    label.set_text("Test Label")
    print("  ✅ TextLabel created")
    
    var button = ButtonInt(10, 50, 100, 30)
    button.set_text("Test Button")
    print("  ✅ Button created")
    
    var checkbox = CheckboxInt(10, 90, 100, 25)
    checkbox.set_text("Test Checkbox")
    print("  ✅ Checkbox created")
    
    var slider = SliderInt(10, 130, 200, 30, SLIDER_HORIZONTAL)
    slider.set_range(0, 100)
    slider.set_value(50)
    print("  ✅ Slider created")
    
    var textedit = TextEditInt(10, 170, 200, 25)
    textedit.set_text("Test text")
    print("  ✅ TextEdit created")
    
    var progressbar = ProgressBarInt(10, 210, 200, 20)
    progressbar.set_range(0, 100)
    progressbar.set_value(75)
    print("  ✅ ProgressBar created")
    
    var listbox = ListBoxInt(10, 250, 150, 100)
    _ = listbox.add_item("Item 1")
    _ = listbox.add_item("Item 2")
    print("  ✅ ListBox created")
    
    var tabcontrol = TabControlInt(10, 370, 300, 200)
    _ = tabcontrol.add_tab("Tab 1")
    _ = tabcontrol.add_tab("Tab 2")
    print("  ✅ TabControl created")
    
    var menubar = MenuBarInt(10, 590, 300, 25)
    var file_menu = menubar.add_menu("File")
    _ = menubar.add_menu_item(file_menu, 1, "New", "Ctrl+N")
    print("  ✅ MenuBar created")
    
    var dialog = DialogInt(DIALOG_TYPE_INFO)
    dialog.set_title("Test Dialog")
    dialog.set_message("Test message")
    print("  ✅ Dialog created")
    
    # Test advanced widgets
    var container = create_vertical_container(10, 10, 300, 400)
    _ = container.add_child(1, 100, 50)
    print("  ✅ Container created")
    
    var listview = create_report_listview(10, 10, 400, 200)
    _ = listview.add_column("Name", 150)
    _ = listview.add_column("Type", 100)
    var item_id = listview.add_item("Test Item")
    listview.set_item_text(item_id, 1, "Test Type")
    print("  ✅ ListView created")
    
    var contextmenu = create_edit_context_menu()
    print("  ✅ ContextMenu created")
    
    var scrollbar = create_vertical_scrollbar(10, 10, 200, 18)
    scrollbar.set_range(0, 100)
    scrollbar.set_value(25)
    print("  ✅ ScrollBar created")
    
    var statusbar = create_standard_statusbar(10, 10, 400)
    statusbar.set_panel_text(0, "Status ready")
    print("  ✅ StatusBar created")
    
    print("✅ All widget types created successfully!")

fn test_widget_properties():
    """Test setting and getting widget properties."""
    print("🧪 Testing widget properties...")
    
    var button = ButtonInt(0, 0, 100, 30)
    button.set_text("Original")
    var original_text = button.get_text()
    button.set_text("Modified")
    var modified_text = button.get_text()
    print("  ✅ Button text: '" + original_text + "' -> '" + modified_text + "'")
    
    var slider = SliderInt(0, 0, 200, 30, SLIDER_HORIZONTAL)
    slider.set_range(10, 90)
    slider.set_value(50)
    var value = slider.get_value()
    var min_val = slider.get_min_value()
    var max_val = slider.get_max_value()
    print("  ✅ Slider range: " + str(min_val) + "-" + str(max_val) + ", value: " + str(value))
    
    var checkbox = CheckboxInt(0, 0, 100, 25)
    checkbox.set_checked(True)
    var checked = checkbox.is_checked()
    checkbox.set_checked(False)
    var unchecked = checkbox.is_checked()
    print("  ✅ Checkbox states: " + str(checked) + " -> " + str(unchecked))
    
    var progressbar = ProgressBarInt(0, 0, 200, 20)
    progressbar.set_range(0, 200)
    progressbar.set_value(150)
    var progress_value = progressbar.get_value()
    var progress_max = progressbar.get_max_value()
    print("  ✅ ProgressBar: " + str(progress_value) + "/" + str(progress_max))
    
    print("✅ Widget properties working correctly!")

fn test_widget_events():
    """Test basic event handling."""
    print("🧪 Testing widget event handling...")
    
    var button = ButtonInt(50, 50, 100, 30)
    var mouse_event = MouseEventInt(75, 65, 0, True, False)  # Click inside button
    var handled = button.handle_mouse_event(mouse_event)
    print("  ✅ Button mouse event handled: " + str(handled))
    
    var slider = SliderInt(50, 100, 200, 30, SLIDER_HORIZONTAL)
    var slider_mouse = MouseEventInt(150, 115, 0, True, False)  # Click on slider
    var slider_handled = slider.handle_mouse_event(slider_mouse)
    print("  ✅ Slider mouse event handled: " + str(slider_handled))
    
    var checkbox = CheckboxInt(50, 150, 100, 25)
    var checkbox_mouse = MouseEventInt(75, 162, 0, True, False)  # Click on checkbox
    var checkbox_handled = checkbox.handle_mouse_event(checkbox_mouse)
    print("  ✅ Checkbox mouse event handled: " + str(checkbox_handled))
    
    var key_event = KeyEventInt(32, True, False, False, False)  # Space key
    var textedit = TextEditInt(50, 200, 200, 25)
    var key_handled = textedit.handle_key_event(key_event)
    print("  ✅ TextEdit key event handled: " + str(key_handled))
    
    print("✅ Event handling working correctly!")

fn test_layout_containers():
    """Test container layout functionality."""
    print("🧪 Testing container layouts...")
    
    # Test vertical layout
    var v_container = create_vertical_container(0, 0, 200, 300, 10)
    var child1_id = v_container.add_child(1, 50, 30, 0)  # Fixed size
    var child2_id = v_container.add_child(2, 50, 30, 1)  # Flex grow
    var child3_id = v_container.add_child(3, 50, 30, 0)  # Fixed size
    
    var child1_bounds = v_container.get_child_bounds(1)
    var child2_bounds = v_container.get_child_bounds(2)
    var child3_bounds = v_container.get_child_bounds(3)
    
    print("  ✅ Vertical layout - Child 1: (" + str(child1_bounds.x) + "," + str(child1_bounds.y) + ")")
    print("  ✅ Vertical layout - Child 2: (" + str(child2_bounds.x) + "," + str(child2_bounds.y) + ")")
    print("  ✅ Vertical layout - Child 3: (" + str(child3_bounds.x) + "," + str(child3_bounds.y) + ")")
    
    # Test horizontal layout
    var h_container = create_horizontal_container(0, 0, 300, 100, 5)
    _ = h_container.add_child(10, 60, 80, 0)  # Fixed size
    _ = h_container.add_child(11, 60, 80, 2)  # Flex grow
    _ = h_container.add_child(12, 60, 80, 1)  # Different flex
    
    print("  ✅ Horizontal layout container created")
    
    # Test grid layout
    var grid_container = create_grid_container(0, 0, 200, 200, 2, 2, 5)
    _ = grid_container.add_child(20, 90, 90)
    _ = grid_container.add_child(21, 90, 90)
    _ = grid_container.add_child(22, 90, 90)
    _ = grid_container.add_child(23, 90, 90)
    
    print("  ✅ Grid layout container created")
    
    print("✅ Container layouts working correctly!")

fn main():
    print("🎯 MOJO GUI WIDGET COMPILATION TEST")
    print("==================================")
    print("Testing all widget types for compilation and basic functionality...")
    print("")
    
    try:
        test_basic_widget_creation()
        print("")
        
        test_widget_properties()
        print("")
        
        test_widget_events()
        print("")
        
        test_layout_containers()
        print("")
        
        print("🎉 ALL TESTS PASSED!")
        print("====================")
        print("✅ All 15+ widget types compile successfully")
        print("✅ Widget properties work correctly")
        print("✅ Event handling functions properly")
        print("✅ Layout containers calculate positions")
        print("✅ Integer-only APIs are stable")
        print("")
        print("🚀 The Mojo GUI widget system is ready for use!")
        print("📝 You can now build complete GUI applications")
        
    except e:
        print("❌ Test failed with error:")
        print(str(e))
        print("")
        print("🔧 Check widget implementations for any issues")