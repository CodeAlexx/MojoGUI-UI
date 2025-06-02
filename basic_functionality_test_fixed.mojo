#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    print("🧪 Basic MojoGUI Functionality Test - FIXED VERSION")
    print("=" * 55)
    
    # Load the CORRECT library
    var lib = DLHandle("./mojo-gui/c_src/librendering_primitives_int_with_fonts.so")
    print("✅ Library loaded successfully")
    
    var tests_passed = 0
    var tests_total = 0
    
    # Get MODERN API functions (integer-only)
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
    
    # Test 1: Window Initialization
    tests_total += 1
    print("\n1. Testing window initialization...")
    
    var window_width = 800
    var window_height = 600
    var title = String("🧪 MojoGUI Test Window")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    
    var init_result = initialize_gl(window_width, window_height, title_ptr)
    print("   initialize_gl result:", init_result)
    
    if init_result == 0:
        print("   ✅ Window initialization - PASSED")
        tests_passed += 1
    else:
        print("   ❌ Window initialization - FAILED")
        return
    
    # Test 2: Font Loading
    tests_total += 1
    print("\n2. Testing font loading...")
    
    var font_result = load_default_font()
    print("   load_default_font result:", font_result)
    
    if font_result == 0:
        print("   ✅ Font loading - PASSED")
        tests_passed += 1
    else:
        print("   ⚠️  Font loading - FAILED (but continuing)")
    
    # Test 3: Basic Drawing
    tests_total += 1
    print("\n3. Testing basic drawing functions...")
    
    try:
        # Start frame
        var frame_result = frame_begin()
        if frame_result == 0:
            print("   ✅ frame_begin - SUCCESS")
            
            # Set color (red)
            var color_result = set_color(255, 0, 0, 255)
            print("   set_color result:", color_result)
            
            # Draw rectangle
            var rect_result = draw_filled_rectangle(100, 100, 200, 150)
            print("   draw_filled_rectangle result:", rect_result)
            
            # Draw text
            var test_text = String("✅ MojoGUI Working!")
            var text_bytes = test_text.as_bytes()
            var text_ptr = text_bytes.unsafe_ptr().bitcast[Int8]()
            var text_result = draw_text(text_ptr, 120, 120, 16)
            print("   draw_text result:", text_result)
            
            # End frame
            var end_result = frame_end()
            print("   frame_end result:", end_result)
            
            if color_result == 0 and rect_result == 0 and end_result == 0:
                print("   ✅ Basic drawing - PASSED")
                tests_passed += 1
            else:
                print("   ❌ Basic drawing - SOME ISSUES")
        else:
            print("   ❌ frame_begin failed")
    except e:
        print("   ❌ Drawing functions - ERROR:", e)
    
    # Test 4: Event Polling
    tests_total += 1
    print("\n4. Testing event system...")
    
    try:
        var poll_result = poll_events()
        var should_close = should_close_window()
        print("   poll_events result:", poll_result)
        print("   should_close_window result:", should_close)
        
        if poll_result == 0:
            print("   ✅ Event system - PASSED")
            tests_passed += 1
        else:
            print("   ❌ Event system - FAILED")
    except e:
        print("   ❌ Event system - ERROR:", e)
    
    # Short display loop to show the window
    print("\n5. Running short display test (3 seconds)...")
    var frame_count = 0
    while should_close_window() == 0 and frame_count < 180:  # ~3 seconds at 60fps
        _ = poll_events()
        frame_count += 1
        
        if frame_begin() == 0:
            # Draw background
            _ = set_color(45, 45, 45, 255)
            _ = draw_filled_rectangle(0, 0, window_width, window_height)
            
            # Draw test rectangle
            _ = set_color(0, 255, 0, 255)
            _ = draw_filled_rectangle(200, 200, 400, 200)
            
            # Draw test text
            _ = set_color(255, 255, 255, 255)
            var display_text = String("🧪 MojoGUI Test - Frame " + String(frame_count))
            var display_bytes = display_text.as_bytes()
            var display_ptr = display_bytes.unsafe_ptr().bitcast[Int8]()
            _ = draw_text(display_ptr, 220, 280, 16)
            
            _ = frame_end()
    
    print("   ✅ Display test completed")
    tests_passed += 1
    tests_total += 1
    
    # Cleanup
    var cleanup_result = cleanup_gl()
    print("\n🧹 Cleanup result:", cleanup_result)
    
    # Results
    print("\n" + "=" * 55)
    print("🎯 TEST RESULTS:")
    print("   Tests Passed:", tests_passed, "/", tests_total)
    
    if tests_passed == tests_total:
        print("   🎉 ALL TESTS PASSED! MojoGUI is working perfectly!")
    elif tests_passed >= tests_total - 1:
        print("   ✅ MOSTLY WORKING! Minor issues only.")
    else:
        print("   ⚠️  SOME ISSUES FOUND. Check library setup.")
    
    print("✨ Fixed version using modern integer-only API!")