# Mojo GUI with Minimal FFI

A GUI library implementation that minimizes FFI usage by keeping only essential OpenGL rendering primitives in C and implementing all widget logic in pure Mojo.

## Architecture

```
┌─────────────────────────────────────────┐
│               Mojo Layer                │
├─────────────────────────────────────────┤
│  • Widget System (Pure Mojo)           │
│  • Event Handling (Pure Mojo)          │
│  • Layout Management (Pure Mojo)       │
│  • Application Logic (Pure Mojo)       │
├─────────────────────────────────────────┤
│            FFI Boundary                 │
├─────────────────────────────────────────┤
│  • Minimal C Interface                  │
│  • OpenGL Rendering Primitives Only    │
│  • Simple Function Signatures          │
│  • No Complex Structs in FFI           │
└─────────────────────────────────────────┘
```

## Key Benefits

- **Minimal FFI Surface**: Only basic rendering primitives cross the FFI boundary
- **Reduced Segfault Risk**: Complex widget logic stays in memory-safe Mojo
- **Type Safety**: All widget interactions are type-checked by Mojo
- **Maintainability**: Widget behavior is implemented in high-level Mojo code
- **Performance**: Direct OpenGL calls for rendering primitives

## Project Structure

```
mojo-gui/
├── c_src/                          # Minimal C library
│   ├── rendering_primitives.h      # C header with simple interface
│   ├── rendering_primitives.c      # OpenGL rendering implementation
│   ├── Makefile                    # Build system for C library
│   ├── test_primitives.c           # C test program
│   └── test_python_ffi.py          # Python FFI test
├── mojo_src/                       # Pure Mojo implementation
│   ├── rendering.mojo              # FFI bindings and safe wrappers
│   ├── widget.mojo                 # Base widget system
│   └── widgets/
│       ├── textlabel.mojo          # Text display widget
│       └── button.mojo             # Interactive button widget
└── examples/
    ├── simple_demo.mojo            # Basic demo
    └── enhanced_demo.mojo          # Full-featured demo
```

## C Interface (Minimal)

The C library provides only essential rendering primitives:

```c
// Initialization and cleanup
int initialize_gl_context(int width, int height, const char* title);
int cleanup_gl(void);

// Frame management
int frame_begin(void);
int frame_end(void);

// Basic drawing primitives
int set_color(float r, float g, float b, float a);
int draw_rectangle(float x, float y, float width, float height);
int draw_filled_rectangle(float x, float y, float width, float height);
int draw_circle(float x, float y, float radius, int segments);
int draw_filled_circle(float x, float y, float radius, int segments);
int draw_line(float x1, float y1, float x2, float y2, float thickness);
int draw_text(const char* text, float x, float y, float size);

// Event polling (simple interface)
int poll_events(void);
int get_mouse_button_state(int button);
int get_key_state(int key_code);
int should_close_window(void);
```

## Mojo Widget System

All widget logic is implemented in pure Mojo:

### Base Widget Trait
```mojo
trait Widget:
    fn render(self, ctx: RenderingContext)
    fn handle_mouse_event(inout self, event: MouseEvent) -> Bool
    fn handle_key_event(inout self, event: KeyEvent) -> Bool
    fn update(inout self)
```

### Available Widgets
- **TextLabel**: Text display with alignment and styling
- **Button**: Interactive buttons with hover/press states and callbacks
- **Container**: Widget hierarchies and layout management

### Event System
- Mouse events (click, hover, drag)
- Keyboard events
- Event propagation through widget hierarchies
- Type-safe event handling

## Building and Running

### 1. Build C Library
```bash
cd c_src
make
```

### 2. Test C Library
```bash
# Test with C
make test_run

# Test with Python FFI
python3 test_python_ffi.py
```

### 3. Run Mojo Demos (when Mojo supports FFI)
```bash
# Simple demo
mojo examples/simple_demo.mojo

# Enhanced demo with multiple widgets
mojo examples/enhanced_demo.mojo
```

## Current Status

✅ **Completed:**
- Minimal C rendering interface
- C library with OpenGL primitives
- FFI-friendly function signatures
- Mojo widget system design
- TextLabel widget implementation
- Button widget with interactions
- Event handling system
- Container/hierarchy system
- Demo applications

🚧 **Pending Mojo FFI Support:**
- The Mojo code is ready but waiting for stable FFI support
- All designs are tested with Python FFI simulation
- C library is fully functional and tested

## Design Principles

1. **Minimal FFI**: Only basic types (int, float, char*) cross FFI boundary
2. **Safe Boundaries**: No complex structs or memory management in FFI
3. **Pure Mojo Logic**: All widget behavior implemented in Mojo
4. **Simple C Interface**: C code only handles OpenGL rendering
5. **Type Safety**: Mojo's type system catches errors early
6. **Extensibility**: Easy to add new widgets in pure Mojo

## Example Usage

```mojo
from mojo_src.rendering import RenderingContext
from mojo_src.widget import WidgetContainer
from mojo_src.widgets.button import create_primary_button

fn button_clicked():
    print("Button was clicked!")

fn main():
    # Initialize rendering
    var ctx = RenderingContext()
    ctx.initialize(800, 600, "My App")
    
    # Create widgets
    var root = WidgetContainer(0, 0, 800, 600)
    var button = create_primary_button(100, 100, 120, 40, "Click Me")
    button.set_click_callback(button_clicked)
    root.add_child(button)
    
    # Render loop
    while not ctx.should_close_window():
        ctx.frame_begin()
        root.render(ctx)
        ctx.frame_end()
    
    ctx.cleanup()
```

## Advantages Over Full FFI Approach

1. **Stability**: Fewer FFI calls = fewer potential segfaults
2. **Debuggability**: Widget logic in Mojo is easier to debug
3. **Type Safety**: Mojo catches type errors at compile time
4. **Memory Safety**: Mojo handles memory management for widgets
5. **Performance**: Direct OpenGL calls for hot rendering paths
6. **Maintainability**: High-level widget code in readable Mojo

This architecture provides the best of both worlds: the performance of OpenGL rendering with the safety and expressiveness of Mojo for application logic.