#!/usr/bin/env mojo

from sys.ffi import DLHandle
from memory import UnsafePointer

fn create_null_terminated_string(s: String) -> UnsafePointer[UInt8]:
    """Create a properly null-terminated string for C FFI."""
    var length = len(s)
    var buffer = UnsafePointer[UInt8].alloc(length + 1)
    
    # Copy string bytes
    var s_bytes = s.as_bytes()
    for i in range(length):
        buffer[i] = s_bytes[i]
    
    # Add null terminator
    buffer[length] = 0
    
    return buffer

fn main() raises:
    print("🎉 FINAL WORKING JETBRAINS MONO DEMO!")
    print("===================================")
    print("Using working approach: Float32 API + String fix + Correct library")
    
    # Use the WORKING font library (Float32 API)
    var lib = DLHandle("./mojo-gui/c_src/librendering_with_fonts.so")
    print("✅ Working font library loaded")
    
    # Get functions with FLOAT32 API (the working approach)
    var initialize_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var cleanup_gl = lib.get_function[fn() -> Int32]("cleanup_gl")
    var frame_begin = lib.get_function[fn() -> Int32]("frame_begin")
    var frame_end = lib.get_function[fn() -> Int32]("frame_end")
    var set_color = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("draw_filled_rectangle")
    var draw_text = lib.get_function[fn(UnsafePointer[Int8], Float32, Float32, Float32) -> Int32]("draw_text")
    var load_default_font = lib.get_function[fn() -> Int32]("load_default_font")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close_window = lib.get_function[fn() -> Int32]("should_close_window")
    
    var title = String("FINAL WORKING JetBrains Mono Demo!")
    var title_ptr = create_null_terminated_string(title).bitcast[Int8]()
    
    print("🚀 Opening window...")
    var init_result = initialize_gl(800, 600, title_ptr)
    
    if init_result != 0:
        print("❌ Failed to initialize")
        return
    
    print("✅ Window opened!")
    
    var font_result = load_default_font()
    if font_result == 0:
        print("✅ JetBrains Mono font loaded with working approach!")
    else:
        print("❌ Font loading failed")
    
    print("🎮 Running final working demo...")
    
    var frame_count: Int32 = 0
    var max_frames: Int32 = 150  # 2.5 seconds
    
    while should_close_window() == 0 and frame_count < max_frames:
        _ = poll_events()
        
        if frame_begin() != 0:
            break
        
        # Dark background
        _ = set_color(0.1, 0.1, 0.2, 1.0)
        _ = draw_filled_rectangle(0.0, 0.0, 800.0, 600.0)
        
        # White text with WORKING APPROACH
        _ = set_color(1.0, 1.0, 1.0, 1.0)
        
        # Working Float32 API + Fixed strings
        var text1 = String("🎉 JETBRAINS MONO WORKING!")
        var text1_ptr = create_null_terminated_string(text1).bitcast[Int8]()
        _ = draw_text(text1_ptr, 50.0, 50.0, 24.0)
        
        var text2 = String("Character clarity: 0 O o | 1 l I | {}[]()<>")
        var text2_ptr = create_null_terminated_string(text2).bitcast[Int8]()
        _ = draw_text(text2_ptr, 50.0, 100.0, 16.0)
        
        var text3 = String("fn calculate(x: Int, y: Int) -> Int {")
        var text3_ptr = create_null_terminated_string(text3).bitcast[Int8]()
        _ = draw_text(text3_ptr, 70.0, 150.0, 14.0)
        
        var text4 = String("    return x + y  // Perfect distinction!")
        var text4_ptr = create_null_terminated_string(text4).bitcast[Int8]()
        _ = draw_text(text4_ptr, 70.0, 180.0, 14.0)
        
        var text5 = String("}")
        var text5_ptr = create_null_terminated_string(text5).bitcast[Int8]()
        _ = draw_text(text5_ptr, 70.0, 210.0, 14.0)
        
        # Success message
        _ = set_color(0.0, 1.0, 0.3, 1.0)
        var success = String("✅ SUCCESS: Float32 API + String Fix + Working Library!")
        var success_ptr = create_null_terminated_string(success).bitcast[Int8]()
        _ = draw_text(success_ptr, 50.0, 300.0, 16.0)
        
        # Technical details
        _ = set_color(0.8, 0.8, 0.8, 1.0)
        var tech1 = String("• Library: librendering_with_fonts.so")
        var tech1_ptr = create_null_terminated_string(tech1).bitcast[Int8]()
        _ = draw_text(tech1_ptr, 50.0, 350.0, 12.0)
        
        var tech2 = String("• API: Float32 coordinates (working approach)")
        var tech2_ptr = create_null_terminated_string(tech2).bitcast[Int8]()
        _ = draw_text(tech2_ptr, 50.0, 375.0, 12.0)
        
        var tech3 = String("• Strings: Null-terminated (bug fixed)")
        var tech3_ptr = create_null_terminated_string(tech3).bitcast[Int8]()
        _ = draw_text(tech3_ptr, 50.0, 400.0, 12.0)
        
        var tech4 = String("• Font: JetBrains Mono TTF with stb_truetype")
        var tech4_ptr = create_null_terminated_string(tech4).bitcast[Int8]()
        _ = draw_text(tech4_ptr, 50.0, 425.0, 12.0)
        
        # Status
        _ = set_color(1.0, 1.0, 0.0, 1.0)
        var status = String("Frame: " + String(frame_count) + " / " + String(max_frames))
        var status_ptr = create_null_terminated_string(status).bitcast[Int8]()
        _ = draw_text(status_ptr, 50.0, 500.0, 12.0)
        
        if frame_end() != 0:
            break
            
        frame_count += 1
        
        if frame_count % 60 == 0:
            print("⏱️  Frame", frame_count, "- Text should be VISIBLE now!")
    
    _ = cleanup_gl()
    
    print("")
    print("🎉 FINAL WORKING DEMO COMPLETED!")
    print("================================")
    print("✅ Used working approach:")
    print("   📚 Library: librendering_with_fonts.so")
    print("   🔢 API: Float32 coordinates")
    print("   🔤 Strings: Null-terminated")
    print("   🔤 Font: JetBrains Mono TTF")
    print("")
    print("🚀 This combination should show VISIBLE text!")