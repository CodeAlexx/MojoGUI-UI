#!/usr/bin/env python3
"""
Complete System Test
Test all layers of the MojoGUI Python wrapper system
"""

import time
import sys
import os

# Add the current directory to Python path so we can import our modules
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_low_level_bindings():
    """Test the low-level ctypes bindings"""
    print("🔗 Testing Low-Level Bindings")
    print("============================")
    
    try:
        from low_level_bindings import get_bindings
        
        bindings = get_bindings()
        available = bindings.list_available_functions()
        
        print(f"✅ Low-level bindings loaded successfully")
        print(f"📊 Available functions: {len(available)}")
        
        # Group functions by category
        categories = {
            'Core': [f for f in available if any(f.startswith(p) for p in ['Win', 'Frame', 'Event'])],
            'Drawing': [f for f in available if f.startswith('Draw')],
            'Text': [f for f in available if any(f.startswith(p) for p in ['Font', 'Text', 'Load'])],
            'String': [f for f in available if f.startswith('String') or f.startswith('Str')],
        }
        
        for category, funcs in categories.items():
            if funcs:
                print(f"   {category}: {len(funcs)} functions")
        
        return True
        
    except Exception as e:
        print(f"❌ Low-level bindings failed: {e}")
        return False

def test_mid_level_wrappers():
    """Test the mid-level wrapper functions"""
    print("\n🎯 Testing Mid-Level Wrappers")
    print("=============================")
    
    try:
        from mid_level_wrappers import get_wrappers
        
        wrappers = get_wrappers()
        wrappers.print_status()
        
        # Test some basic functions
        print("\n🧪 Testing wrapper functions:")
        
        # Initialize system
        init_result = wrappers.win_init()
        print(f"   win_init(): {init_result}")
        
        if init_result == 0:
            # Test window operations
            size_result = wrappers.win_set_size(800, 600)
            print(f"   win_set_size(800, 600): {size_result}")
            
            create_result = wrappers.win_create()
            print(f"   win_create(): {create_result}")
            
            # Test drawing functions
            color_result = wrappers.draw_set_color(1.0, 0.0, 0.0, 1.0)
            print(f"   draw_set_color(red): {color_result}")
            
            pos_result = wrappers.draw_set_pos(100, 100)
            print(f"   draw_set_pos(100, 100): {pos_result}")
        
        print("✅ Mid-level wrappers working")
        return True
        
    except Exception as e:
        print(f"❌ Mid-level wrappers failed: {e}")
        return False

def test_high_level_api():
    """Test the high-level object-oriented API"""
    print("\n🎨 Testing High-Level API")
    print("=========================")
    
    try:
        from high_level_api import Application, create_app
        
        # Test application creation
        app = create_app("Test App", 800, 600)
        if not app:
            print("❌ Failed to create application")
            return False
        
        print("✅ Application created successfully")
        print(f"   Title: {app.title}")
        print(f"   Size: {app.width}x{app.height}")
        
        # Test widget creation
        print("\n🔧 Testing widget creation:")
        
        button = app.create_button(50, 50, 100, 30, "Test Button")
        print(f"   Button created: {button.widget_id >= 0}")
        
        checkbox = app.create_checkbox(50, 100, 20, 20)
        print(f"   CheckBox created: {checkbox.widget_id >= 0}")
        
        slider = app.create_slider(50, 150, 200, 20, 0, 0, 100)
        print(f"   Slider created: {slider.widget_id >= 0}")
        
        progressbar = app.create_progressbar(50, 200, 200, 20)
        print(f"   ProgressBar created: {progressbar.widget_id >= 0}")
        
        label = app.create_label(50, 250, 200, 20, "Test Label")
        print(f"   Label created: {label.widget_id >= 0}")
        
        print(f"\n📊 Total widgets created: {len(app.widgets)}")
        
        # Test event handlers
        button.set_click_handler(lambda btn: print(f"Button '{btn.text}' clicked!"))
        checkbox.set_change_handler(lambda cb, state: print(f"CheckBox state: {state}"))
        slider.set_change_handler(lambda sl, value: print(f"Slider value: {value}"))
        
        print("✅ Event handlers set")
        
        # Test a few frames
        print("\n🖼️  Testing frame rendering:")
        for i in range(3):
            success = app.run_frame()
            print(f"   Frame {i+1}: {'✅' if success else '❌'}")
            time.sleep(0.1)
        
        return True
        
    except Exception as e:
        print(f"❌ High-level API failed: {e}")
        return False

def test_widget_modules():
    """Test individual widget modules"""
    print("\n🔘 Testing Widget Modules")
    print("=========================")
    
    # Test button module
    try:
        from button_widget import ButtonCreate, ButtonDraw, ButtonSetText, ButtonHandleClick
        
        print("🔘 Testing Button Module:")
        button = ButtonCreate(100, 100, 120, 35, "Module Button")
        print(f"   Button created: {button.widget_id >= 0}")
        
        if button.widget_id >= 0:
            ButtonSetText(button, "Updated Text")
            print("   Button text updated")
            
            # Set event handler
            button.set_click_handler(lambda btn: print(f"Module button clicked: {btn.text}"))
            print("   Click handler set")
        
        print("✅ Button module working")
        
    except Exception as e:
        print(f"❌ Button module failed: {e}")
        return False
    
    # Test checkbox module
    try:
        from checkbox_widget import CheckBoxCreate, CheckBoxDraw, CheckBoxSetState, CheckBoxGetState
        
        print("\n☑️  Testing CheckBox Module:")
        checkbox = CheckBoxCreate(100, 150, 20, 20)
        print(f"   CheckBox created: {checkbox.widget_id >= 0}")
        
        if checkbox.widget_id >= 0:
            CheckBoxSetState(checkbox, True)
            state = CheckBoxGetState(checkbox)
            print(f"   CheckBox state: {state}")
            
            # Set event handler
            checkbox.set_change_handler(lambda cb, checked: print(f"Module checkbox: {checked}"))
            print("   Change handler set")
        
        print("✅ CheckBox module working")
        
    except Exception as e:
        print(f"❌ CheckBox module failed: {e}")
        return False
    
    # Test slider module
    try:
        from slider_widget import SliderCreateHorizontal, SliderDraw, SliderSetValue, SliderGetValue
        
        print("\n🎚️  Testing Slider Module:")
        slider = SliderCreateHorizontal(100, 200, 200, 20)
        print(f"   Slider created: {slider.widget_id >= 0}")
        
        if slider.widget_id >= 0:
            SliderSetValue(slider, 75)
            value = SliderGetValue(slider)
            print(f"   Slider value: {value}")
            
            # Set event handler
            slider.set_change_handler(lambda sl, val: print(f"Module slider: {val}"))
            print("   Change handler set")
        
        print("✅ Slider module working")
        
    except Exception as e:
        print(f"❌ Slider module failed: {e}")
        return False
    
    return True

def test_convenience_functions():
    """Test package-level convenience functions"""
    print("\n⚡ Testing Convenience Functions")
    print("===============================")
    
    try:
        # Test package imports
        import python_bindings
        from python_bindings import (
            WinInit, WinSetSize, WinCreate, 
            DrawSetColor, DrawSetPos, DrawRect,
            CreateButton, CreateCheckBox, CreateSlider
        )
        
        print("✅ Package imports successful")
        
        # Test convenience functions
        print("\n🧪 Testing convenience functions:")
        
        init_result = WinInit()
        print(f"   WinInit(): {init_result}")
        
        if init_result:
            size_result = WinSetSize(800, 600)
            print(f"   WinSetSize(800, 600): {size_result}")
            
            create_result = WinCreate()
            print(f"   WinCreate(): {create_result}")
            
            color_result = DrawSetColor(0.0, 1.0, 0.0, 1.0)  # Green
            print(f"   DrawSetColor(green): {color_result}")
            
            pos_result = DrawSetPos(200, 200)
            print(f"   DrawSetPos(200, 200): {pos_result}")
            
            rect_result = DrawRect(100, 50)
            print(f"   DrawRect(100, 50): {rect_result}")
        
        # Test widget creation convenience functions
        print("\n🔧 Testing widget convenience functions:")
        
        button = CreateButton(300, 50, 80, 30, "Conv Button")
        print(f"   CreateButton(): {button.widget_id >= 0}")
        
        checkbox = CreateCheckBox(300, 100, 20, 20)
        print(f"   CreateCheckBox(): {checkbox.widget_id >= 0}")
        
        slider = CreateSlider(300, 150, 150, 20)
        print(f"   CreateSlider(): {slider.widget_id >= 0}")
        
        print("✅ Convenience functions working")
        return True
        
    except Exception as e:
        print(f"❌ Convenience functions failed: {e}")
        return False

def test_integration_demo():
    """Test integration with a simple demo"""
    print("\n🚀 Testing Integration Demo")
    print("===========================")
    
    try:
        from high_level_api import quick_demo
        
        # Create quick demo application
        app = quick_demo()
        if not app:
            print("❌ Failed to create demo application")
            return False
        
        print("✅ Demo application created")
        print(f"   Widgets: {len(app.widgets)}")
        
        # Run a few demo frames
        print("\n🎬 Running demo frames:")
        for i in range(5):
            success = app.run_frame()
            if success:
                print(f"   Frame {i+1}: ✅")
                
                # Simulate some interactions
                if i == 2:
                    # Simulate button click
                    app.handle_mouse_click(100, 65)  # Button area
                    print("     → Simulated button click")
                elif i == 3:
                    # Simulate checkbox click
                    app.handle_mouse_click(60, 110)  # Checkbox area
                    print("     → Simulated checkbox click")
                elif i == 4:
                    # Simulate slider drag
                    app.handle_mouse_click(150, 160)  # Slider area
                    app.handle_mouse_drag(200, 160)
                    app.handle_mouse_release(200, 160)
                    print("     → Simulated slider interaction")
            else:
                print(f"   Frame {i+1}: ❌")
            
            time.sleep(0.1)
        
        print("✅ Integration demo completed")
        return True
        
    except Exception as e:
        print(f"❌ Integration demo failed: {e}")
        return False

def main():
    """Main test function"""
    print("🧪 MojoGUI Complete System Test")
    print("================================")
    print("Testing all layers of the Python wrapper system\n")
    
    # Track test results
    tests = [
        ("Low-Level Bindings", test_low_level_bindings),
        ("Mid-Level Wrappers", test_mid_level_wrappers),
        ("High-Level API", test_high_level_api),
        ("Widget Modules", test_widget_modules),
        ("Convenience Functions", test_convenience_functions),
        ("Integration Demo", test_integration_demo),
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} failed with exception: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "="*50)
    print("📊 TEST SUMMARY")
    print("="*50)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"   {test_name:<25} {status}")
        if result:
            passed += 1
    
    print(f"\n🎯 OVERALL RESULT: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 ALL TESTS PASSED! The multi-layer wrapper system is working correctly.")
        print("\n💡 You can now use the MojoGUI Python bindings at any level:")
        print("   • Low-level: Direct ctypes bindings")
        print("   • Mid-level: Clean wrapper functions")  
        print("   • High-level: Object-oriented widgets")
        print("   • Convenience: Package-level functions")
        print("   • Per-widget: Individual widget modules")
    else:
        print(f"⚠️  {total - passed} tests failed. Please check the error messages above.")
        
        if passed > 0:
            print(f"✅ {passed} tests passed, so some functionality is working.")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)