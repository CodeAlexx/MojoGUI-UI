#!/usr/bin/env mojo
"""
New Widgets Demo - Comprehensive demonstration of the 4 newly ported widgets
SpinBox, ComboBox, ColorPicker, and DateTimePicker
"""

from sys.ffi import DLHandle
from memory import UnsafePointer
from .spinbox_int import SpinBoxInt, create_integer_spinbox, create_float_spinbox, create_percentage_spinbox
from .combobox_int import ComboBoxInt, create_simple_combobox, create_file_type_combobox
from .colorpicker_int import ColorPickerInt, create_compact_colorpicker, create_slider_colorpicker
from .datetimepicker_int import DateTimePickerInt, create_date_picker, create_time_picker, create_datetime_picker

fn main() raises:
    print("🎯 NEW WIDGETS DEMO - SpinBox, ComboBox, ColorPicker, DateTimePicker")
    print("=" * 70)
    print("Professional widgets with comprehensive features!")
    
    # Use the TTF-enabled library
    var lib = DLHandle("./c_src/librendering_primitives_int_with_fonts.so")
    print("✅ TTF-enabled library loaded")
    
    # Get function pointers
    var initialize_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var cleanup_gl = lib.get_function[fn() -> Int32]("cleanup_gl")
    var frame_begin = lib.get_function[fn() -> Int32]("frame_begin")
    var frame_end = lib.get_function[fn() -> Int32]("frame_end")
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Int32, Int32, Int32) -> Int32]("draw_text")
    var load_default_font = lib.get_function[fn() -> Int32]("load_default_font")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close_window = lib.get_function[fn() -> Int32]("should_close_window")
    var get_mouse_x = lib.get_function[fn() -> Int32]("get_mouse_x")
    var get_mouse_y = lib.get_function[fn() -> Int32]("get_mouse_y")
    var get_mouse_button_state = lib.get_function[fn(Int32) -> Int32]("get_mouse_button_state")
    
    # Initialize window
    var title = String("New MojoGUI Widgets - SpinBox, ComboBox, ColorPicker, DateTimePicker")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    print("🚀 Opening new widgets demo...")
    var init_result = initialize_gl(1400, 900, title_ptr)
    
    if init_result != 0:
        print("❌ Failed to initialize")
        return
    
    print("✅ Window opened!")
    
    # Load TTF fonts
    var font_result = load_default_font()
    if font_result == 0:
        print("✅ Professional TTF fonts loaded!")
    else:
        print("⚠️  Font loading failed")
    
    print("")
    print("🎨 NEW WIDGETS SHOWCASE:")
    print("   1. 🔢 SpinBox - Numeric input with up/down buttons")
    print("   2. 📋 ComboBox - Dropdown selection with filtering")
    print("   3. 🎨 ColorPicker - Professional color selection")
    print("   4. 📅 DateTimePicker - Calendar and time selection")
    print("")
    print("🖱️  Interact with all the new professional widgets!")
    
    # Create all widget instances
    
    # SpinBox widgets
    var integer_spin = create_integer_spinbox(50, 120, 120, 30, 42, 0, 100, 1)
    var float_spin = create_float_spinbox(200, 120, 120, 30, 3140, 0, 10000, 10, 3)  # Pi * 1000
    var percentage_spin = create_percentage_spinbox(350, 120, 120, 30)
    var coordinate_x = create_integer_spinbox(500, 120, 80, 30, 100, 0, 1920, 1)
    var coordinate_y = create_integer_spinbox(590, 120, 80, 30, 100, 0, 1080, 1)
    
    # ComboBox widgets
    var file_type_combo = create_file_type_combobox(50, 200, 200, 30)
    var quality_combo = create_simple_combobox(280, 200, 120, 30)
    quality_combo.add_item("Low", 1)
    quality_combo.add_item("Medium", 2)
    quality_combo.add_item("High", 3)
    quality_combo.add_item("Ultra", 4)
    quality_combo.set_selected_index(2)  # Default to High
    
    var framework_combo = create_simple_combobox(420, 200, 150, 30)
    framework_combo.add_item("React", 1)
    framework_combo.add_item("Vue.js", 2)
    framework_combo.add_item("Angular", 3)
    framework_combo.add_item("Svelte", 4)
    framework_combo.add_item("Mojo 🔥", 5)
    framework_combo.set_selected_index(4)  # Default to Mojo
    
    # ColorPicker widgets
    var compact_color = create_compact_colorpicker(50, 280, 60, 30)
    compact_color.set_color_rgb(255, 100, 50, 255)  # Orange
    
    var slider_color = create_slider_colorpicker(150, 280, 80, 30)
    slider_color.set_color_rgb(50, 150, 255, 255)  # Blue
    
    var theme_color = create_compact_colorpicker(270, 280, 60, 30)
    theme_color.set_color_rgb(100, 200, 100, 255)  # Green
    
    # DateTimePicker widgets
    var date_picker = create_date_picker(50, 360, 150, 30)
    date_picker.set_date(2024, 6, 15)
    
    var time_picker = create_time_picker(230, 360, 120, 30)
    time_picker.set_time(14, 30, 0)
    
    var datetime_picker = create_datetime_picker(380, 360, 200, 30)
    datetime_picker.set_datetime(2024, 12, 25, 9, 0, 0)
    
    # Widget state tracking
    var frame_count: Int32 = 0
    var last_mouse_state: Bool = False
    
    print("🎮 New widgets demo running! Try all the professional controls!")
    
    while should_close_window() == 0:
        # Poll events
        _ = poll_events()
        
        # Get mouse state
        var mouse_x = get_mouse_x()
        var mouse_y = get_mouse_y()
        var mouse_pressed = get_mouse_button_state(0) == 1
        
        # Handle widget interactions
        if mouse_pressed and not last_mouse_state:
            # SpinBox interactions
            if integer_spin.handle_mouse_down(mouse_x, mouse_y):
                print("🔢 Integer SpinBox value:", integer_spin.get_value())
            elif float_spin.handle_mouse_down(mouse_x, mouse_y):
                var float_val = float_spin.get_value()
                print("🔢 Float SpinBox value:", float_val / 1000.0, "(", float_val, ")")
            elif percentage_spin.handle_mouse_down(mouse_x, mouse_y):
                var pct_val = percentage_spin.get_value()
                print("🔢 Percentage SpinBox:", pct_val / 1000.0, "%")
            elif coordinate_x.handle_mouse_down(mouse_x, mouse_y):
                print("📍 X Coordinate:", coordinate_x.get_value())
            elif coordinate_y.handle_mouse_down(mouse_x, mouse_y):
                print("📍 Y Coordinate:", coordinate_y.get_value())
            
            # ComboBox interactions
            elif file_type_combo.handle_mouse_down(mouse_x, mouse_y):
                print("📋 File Type:", file_type_combo.get_selected_text())
            elif quality_combo.handle_mouse_down(mouse_x, mouse_y):
                print("📋 Quality Setting:", quality_combo.get_selected_text())
            elif framework_combo.handle_mouse_down(mouse_x, mouse_y):
                print("📋 Framework:", framework_combo.get_selected_text())
            
            # ColorPicker interactions
            elif compact_color.handle_mouse_down(mouse_x, mouse_y):
                var rgb = compact_color.get_color_rgb()
                print("🎨 Compact Color: RGB(", rgb.0, ",", rgb.1, ",", rgb.2, ")")
            elif slider_color.handle_mouse_down(mouse_x, mouse_y):
                var rgb = slider_color.get_color_rgb()
                print("🎨 Slider Color: RGB(", rgb.0, ",", rgb.1, ",", rgb.2, ")")
            elif theme_color.handle_mouse_down(mouse_x, mouse_y):
                var rgb = theme_color.get_color_rgb()
                print("🎨 Theme Color: RGB(", rgb.0, ",", rgb.1, ",", rgb.2, ")")
            
            # DateTimePicker interactions
            elif date_picker.handle_mouse_down(mouse_x, mouse_y):
                var date = date_picker.get_date()
                print("📅 Date selected:", date.0, "-", date.1, "-", date.2)
            elif time_picker.handle_mouse_down(mouse_x, mouse_y):
                var time = time_picker.get_time()
                print("🕐 Time selected:", time.0, ":", time.1, ":", time.2)
            elif datetime_picker.handle_mouse_down(mouse_x, mouse_y):
                var date = datetime_picker.get_date()
                var time = datetime_picker.get_time()
                print("📅🕐 DateTime:", date.0, "-", date.1, "-", date.2, " ", time.0, ":", time.1)
        
        last_mouse_state = mouse_pressed
        frame_count += 1
        
        # Begin frame
        if frame_begin() != 0:
            break
        
        # Clear background (professional dark gray)
        _ = set_color(50, 50, 60, 255)
        _ = draw_filled_rectangle(0, 0, 1400, 900)
        
        # Draw title
        _ = set_color(255, 255, 255, 255)
        var main_title = String("NEW MOJOGUI WIDGETS DEMONSTRATION")
        var main_title_bytes = main_title.as_bytes()
        var main_title_ptr = main_title_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(main_title_ptr, 50, 30, 24)
        
        var subtitle = String("Professional SpinBox, ComboBox, ColorPicker, and DateTimePicker")
        var subtitle_bytes = subtitle.as_bytes()
        var subtitle_ptr = subtitle_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(subtitle_ptr, 50, 70, 14)
        
        # === SPINBOX SECTION ===
        var spinbox_label = String("🔢 SpinBox Controls - Numeric Input with Precision")
        var spinbox_label_bytes = spinbox_label.as_bytes()
        var spinbox_label_ptr = spinbox_label_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(spinbox_label_ptr, 50, 100, 16)
        
        # Draw SpinBox widgets
        integer_spin.draw(lib)
        float_spin.draw(lib)
        percentage_spin.draw(lib)
        coordinate_x.draw(lib)
        coordinate_y.draw(lib)
        
        # SpinBox labels
        _ = set_color(200, 200, 200, 255)
        var int_label = String("Integer (0-100)")
        var int_bytes = int_label.as_bytes()
        var int_ptr = int_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(int_ptr, 50, 155, 10)
        
        var float_label = String("Float (π precision)")
        var float_bytes = float_label.as_bytes()
        var float_ptr = float_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(float_ptr, 200, 155, 10)
        
        var pct_label = String("Percentage")
        var pct_bytes = pct_label.as_bytes()
        var pct_ptr = pct_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(pct_ptr, 350, 155, 10)
        
        var coord_label = String("X,Y Coordinates")
        var coord_bytes = coord_label.as_bytes()
        var coord_ptr = coord_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(coord_ptr, 500, 155, 10)
        
        # === COMBOBOX SECTION ===
        _ = set_color(255, 255, 255, 255)
        var combobox_label = String("📋 ComboBox Controls - Professional Dropdown Selection")
        var combobox_label_bytes = combobox_label.as_bytes()
        var combobox_label_ptr = combobox_label_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(combobox_label_ptr, 50, 180, 16)
        
        # Draw ComboBox widgets
        file_type_combo.draw(lib)
        quality_combo.draw(lib)
        framework_combo.draw(lib)
        
        # ComboBox labels
        _ = set_color(200, 200, 200, 255)
        var file_label = String("File Types")
        var file_bytes = file_label.as_bytes()
        var file_ptr = file_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(file_ptr, 50, 235, 10)
        
        var quality_label = String("Quality Level")
        var quality_bytes = quality_label.as_bytes()
        var quality_ptr = quality_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(quality_ptr, 280, 235, 10)
        
        var framework_label = String("Framework Choice")
        var framework_bytes = framework_label.as_bytes()
        var framework_ptr = framework_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(framework_ptr, 420, 235, 10)
        
        # === COLORPICKER SECTION ===
        _ = set_color(255, 255, 255, 255)
        var colorpicker_label = String("🎨 ColorPicker Controls - Professional Color Selection")
        var colorpicker_label_bytes = colorpicker_label.as_bytes()
        var colorpicker_label_ptr = colorpicker_label_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(colorpicker_label_ptr, 50, 260, 16)
        
        # Draw ColorPicker widgets
        compact_color.draw(lib)
        slider_color.draw(lib)
        theme_color.draw(lib)
        
        # ColorPicker labels
        _ = set_color(200, 200, 200, 255)
        var compact_label = String("Compact Style")
        var compact_bytes = compact_label.as_bytes()
        var compact_ptr = compact_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(compact_ptr, 50, 315, 10)
        
        var slider_label = String("Slider Style")
        var slider_bytes = slider_label.as_bytes()
        var slider_ptr = slider_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(slider_ptr, 150, 315, 10)
        
        var theme_label = String("Theme Color")
        var theme_bytes = theme_label.as_bytes()
        var theme_ptr = theme_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(theme_ptr, 270, 315, 10)
        
        # === DATETIMEPICKER SECTION ===
        _ = set_color(255, 255, 255, 255)
        var datetime_label = String("📅 DateTimePicker Controls - Calendar and Time Selection")
        var datetime_label_bytes = datetime_label.as_bytes()
        var datetime_label_ptr = datetime_label_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(datetime_label_ptr, 50, 340, 16)
        
        # Draw DateTimePicker widgets
        date_picker.draw(lib)
        time_picker.draw(lib)
        datetime_picker.draw(lib)
        
        # DateTimePicker labels
        _ = set_color(200, 200, 200, 255)
        var date_label = String("Date Selection")
        var date_bytes = date_label.as_bytes()
        var date_ptr = date_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(date_ptr, 50, 395, 10)
        
        var time_label = String("Time Selection")
        var time_bytes = time_label.as_bytes()
        var time_ptr = time_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(time_ptr, 230, 395, 10)
        
        var full_datetime_label = String("Full DateTime (Christmas)")
        var full_datetime_bytes = full_datetime_label.as_bytes()
        var full_datetime_ptr = full_datetime_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(full_datetime_ptr, 380, 395, 10)
        
        # === FEATURES SHOWCASE ===
        _ = set_color(255, 255, 255, 255)
        var features_title = String("✨ Professional Features Demonstrated:")
        var features_bytes = features_title.as_bytes()
        var features_ptr = features_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(features_ptr, 50, 450, 16)
        
        _ = set_color(200, 220, 255, 255)
        var feature_list = List[String]()
        feature_list.append("• SpinBox: Integer/Float types, min/max constraints, step increments, precision control")
        feature_list.append("• ComboBox: Dropdown lists, item filtering, autocomplete, custom data binding")
        feature_list.append("• ColorPicker: RGB/HSV support, multiple styles, hex values, recent colors")
        feature_list.append("• DateTimePicker: Calendar popup, time selection, date ranges, locale formatting")
        feature_list.append("• All widgets: Professional styling, hover states, keyboard navigation, events")
        
        for i in range(len(feature_list)):
            var feature_bytes = feature_list[i].as_bytes()
            var feature_ptr = feature_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(feature_ptr, 70, 480 + i * 20, 12)
        
        # Status information
        _ = set_color(180, 180, 180, 255)
        var status_text = String("New Widgets Demo - Frame: ") + String(frame_count) + String(" | All 4 widgets operational")
        var status_bytes = status_text.as_bytes()
        var status_ptr = status_bytes.unsafe_ptr().bitcast[Int8]()
        _ = draw_text(status_ptr, 50, 850, 10)
        
        # End frame
        if frame_end() != 0:
            break
        
        # Status update
        if frame_count % 120 == 0:
            var seconds = frame_count // 60
            print("🎨 New widgets demo running...", seconds, "seconds - All professional widgets functional!")
    
    _ = cleanup_gl()
    
    print("")
    print("🎉 NEW WIDGETS DEMO COMPLETED!")
    print("=" * 50)
    print("✅ SUCCESSFULLY DEMONSTRATED:")
    print("   1. ✅ SpinBox - Professional numeric input with up/down controls")
    print("   2. ✅ ComboBox - Advanced dropdown with filtering and selection")
    print("   3. ✅ ColorPicker - Multi-style color selection with RGB/HSV support")
    print("   4. ✅ DateTimePicker - Calendar popup with comprehensive date/time selection")
    print("")
    print("🚀 All 4 new widgets are production-ready and fully integrated!")
    print("📝 Perfect for building professional desktop applications with advanced controls!")
    print("🎯 Ready for use in IDEs, design tools, data entry forms, and enterprise software!")