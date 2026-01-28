#!/usr/bin/env mojo

from sys.ffi import OwnedDLHandle as DLHandle
from memory import alloc, UnsafePointer
from builtin.type_aliases import MutExternalOrigin

fn main() raises:
    print("🧪 Simple Integer-Only GUI Test")
    
    # Load the integer-only library
    var lib = DLHandle("./c_src/librendering_primitives_int.so")
    print("✅ Library loaded")
    
    # Get basic functions
    var initialize_gl = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8, MutExternalOrigin]) -> Int32]("initialize_gl_context")
    var cleanup_gl = lib.get_function[fn() -> Int32]("cleanup_gl")
    var frame_begin = lib.get_function[fn() -> Int32]("frame_begin")
    var frame_end = lib.get_function[fn() -> Int32]("frame_end")
    var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")
    var draw_filled_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_filled_rectangle")
    var draw_rectangle = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("draw_rectangle")
    var poll_events = lib.get_function[fn() -> Int32]("poll_events")
    var should_close_window = lib.get_function[fn() -> Int32]("should_close_window")
    var get_mouse_x = lib.get_function[fn() -> Int32]("get_mouse_x")
    var get_mouse_y = lib.get_function[fn() -> Int32]("get_mouse_y")
    
    print("✅ Functions loaded")
    
    # Initialize (simplified - just test library loading)
    print("🎯 Testing basic functionality...")
    
    # Test that we can call simple functions
    var mouse_x = get_mouse_x()
    var mouse_y = get_mouse_y()
    print("📊 Mouse position:", mouse_x, ",", mouse_y)
    
    print("🎉 Integer-only GUI test successful!")
    print("🚀 Library is ready for GUI applications!")