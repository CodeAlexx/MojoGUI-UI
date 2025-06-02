# Quick Reference Guide - Mojo GUI System

## TL;DR - What Works Right Now

### Ready-to-Run Applications
```bash
cd /home/alex/A/mojoIDE/testopenGL/mojoGUI_github/mojo-gui/

# BEST OPTION: Python-compatible with working text
./python_style_test

# Alternative: Integer-only stable version  
./gui_test

# Basic: Library test only
./simple_gui_test
```

## Two Systems Available

### 1. Float-Based (RECOMMENDED for GUI apps)
- **Library**: `c_src/librendering_primitives.so`
- **Colors**: 0.0-1.0 range (like OpenGL)
- **Coordinates**: Float precision
- **Text**: ✅ Works perfectly
- **Use when**: You need text rendering and Python compatibility

### 2. Integer-Only (RECOMMENDED for performance)
- **Library**: `c_src/librendering_primitives_int.so` 
- **Colors**: 0-255 range (like RGB)
- **Coordinates**: Pixel precision
- **Text**: ⚠️ May need setup
- **Use when**: You need maximum stability and performance

## Quick Mojo Pattern

```mojo
from sys.ffi import DLHandle
from memory import UnsafePointer

fn main() raises:
    # Load library
    var lib = DLHandle("./c_src/librendering_primitives.so")  # Float version
    # var lib = DLHandle("./c_src/librendering_primitives_int.so")  # Int version
    
    # Get functions
    var init = lib.get_function[fn(Int32, Int32, UnsafePointer[Int8]) -> Int32]("initialize_gl_context")
    var set_color = lib.get_function[fn(Float32, Float32, Float32, Float32) -> Int32]("set_color")  # Float
    # var set_color = lib.get_function[fn(Int32, Int32, Int32, Int32) -> Int32]("set_color")  # Int
    
    # Initialize
    var title = String("My GUI")
    var title_bytes = title.as_bytes()
    var title_ptr = title_bytes.unsafe_ptr().bitcast[Int8]()
    _ = init(800, 600, title_ptr)
    
    # Draw
    _ = set_color(1.0, 0.0, 0.0, 1.0)  # Red (float version)
    # _ = set_color(255, 0, 0, 255)  # Red (int version)
```

## Essential Functions

### Window Management
```c
initialize_gl_context(width, height, title) -> int
cleanup_gl() -> int
frame_begin() -> int
frame_end() -> int
should_close_window() -> int
```

### Drawing (Float Version)
```c
set_color(r, g, b, a)  // 0.0-1.0
draw_filled_rectangle(x, y, w, h)
draw_text(text, x, y, size)
```

### Drawing (Int Version)  
```c
set_color(r, g, b, a)  // 0-255
draw_filled_rectangle(x, y, w, h)
draw_text(text, x, y, size)
```

## Problem Solutions

### No Text Appearing?
→ Use **float-based library** (`librendering_primitives.so`)

### FFI Type Errors?
→ Use **integer-only library** (`librendering_primitives_int.so`)

### Window Won't Open?
→ Set display: `export DISPLAY=:0`

### Library Not Loading?
→ Check path: `ls -la c_src/*.so`

## File Locations

**Libraries**: `/home/alex/A/mojoIDE/testopenGL/mojoGUI_github/mojo-gui/c_src/`
**Executables**: `/home/alex/A/mojoIDE/testopenGL/mojoGUI_github/mojo-gui/`
**Source**: `/home/alex/A/mojoIDE/testopenGL/mojoGUI_github/mojo-gui/mojo_src/`

## Compilation

```bash
# Compile Mojo app
mojo build myapp.mojo

# Rebuild C libraries if needed
cd c_src && make all
```

**Status**: ✅ Complete and ready for production use