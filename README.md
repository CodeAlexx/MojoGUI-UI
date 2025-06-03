# 🗂️ MojoGUI - Experimental GUI Framework for Mojo

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-blue.svg)](https://github.com/your-username/mojogui)
[![Status](https://img.shields.io/badge/Status-Alpha%20v0.24.0001-orange.svg)](https://github.com/your-username/mojogui)

⚠️ **EXPERIMENTAL ALPHA SOFTWARE** - Not suitable for production use.

An experimental GUI framework for the [Mojo programming language](https://www.modular.com/mojo) featuring professional font rendering and basic UI components. This is a proof-of-concept demonstrating advanced text rendering with JetBrains Mono font integration.

## 🚀 **Key Features**

### 🧪 **Experimental Text Rendering**
- **Professional glyph atlas system** using stb_truetype
- **JetBrains Mono font integration** (when available)
- **Smooth anti-aliased text** (proof-of-concept)
- **High-resolution font baking** (512x512 atlas)

### 🧪 **Experimental File Manager Demo**
- **Basic dual-pane file browser** (prototype)
- **Simple search functionality** (demonstration only)
- **Mouse interaction** (limited implementation)
- **System color detection** (proof-of-concept)

### 🧪 **Experimental Components**
- **Font rendering**: TTF support via `stb_truetype` (alpha quality)
- **System colors**: Basic detection (proof-of-concept)
- **Widget prototypes**: Individual components (not integrated)
- **Demo applications**: Show technical concepts only

### 🧪 **Platform Support**
- **Linux**: Primary development platform
- **macOS**: Basic compatibility (untested)
- **Windows**: Theoretical support (unverified)

## 📸 **Screenshots**

### Adaptive File Manager with Working Search
![File Manager](docs/file_manager_demo.png)
*Professional dual-pane file manager with functional search box*

### System Color Integration
![System Colors](docs/system_colors_demo.png)
*Automatic adaptation to system dark/light mode and accent colors*

## ⚠️ **ALPHA SOFTWARE WARNING**

This is **EXPERIMENTAL ALPHA SOFTWARE v0.24.0001**:
- **NOT suitable for production use**
- **Frequent breaking changes expected**
- **Limited documentation and support**
- **Use for research/experimentation only**

## 🔧 **Quick Start (For Developers/Researchers)**

### **Prerequisites**
- [Mojo programming language](https://www.modular.com/mojo) (required)
- [Pixi package manager](https://pixi.sh) (recommended) 
- OpenGL and GLFW development libraries
- GCC or compatible C compiler

### **Installation**

#### **Option 1: Using Pixi (Recommended)**
```bash
git clone https://github.com/your-username/mojogui.git
cd mojogui
pixi install
pixi run build
pixi run test-font  # Requires mojo in PATH
```

#### **Option 2: Manual Build**
```bash
git clone https://github.com/your-username/mojogui.git
cd mojogui
# Install system dependencies
sudo apt-get install build-essential pkg-config libglfw3-dev libgl1-mesa-dev
# Build the font library
cd mojo-gui/c_src
gcc -Wall -Wextra -fPIC -O2 -std=c99 -c rendering_with_fonts.c -o rendering_with_fonts.o
gcc -shared -o librendering_with_fonts.so rendering_with_fonts.o -lglfw -lGL -lm
cp librendering_with_fonts.so ../..
cd ../..
# Test the professional font rendering
mojo jetbrains_final_working.mojo
```

## 🎯 **Main Applications**

### **Adaptive File Manager** (`adaptive_file_manager.mojo`)
Professional file manager with:
- Working search box with real-time text input
- System color adaptation (dark/light mode)
- Dual-pane file browsing
- Interactive mouse navigation
- Status bar with live updates

### **System Colors Demo** (`system_colors_demo.mojo`)
Demonstrates:
- System dark/light mode detection
- Accent color extraction
- Real-time color adaptation
- Cross-platform compatibility

## 📖 **Documentation**

### **API Reference**
- [Complete API Documentation](MOJOGUI_API_REFERENCE.md)
- [Search Functionality Guide](SEARCH_FUNCTIONALITY_IMPLEMENTATION.md)
- [Widget Reference](mojo-gui/WIDGET_FUNCTION_REFERENCE.md)

### **Technical Guides**
- [Build System Documentation](BUILD_GUIDE.md)
- [Cross-Platform Setup](PLATFORM_SETUP.md)
- [Contributing Guidelines](CONTRIBUTING.md)

## 🏗️ **Architecture**

### **Technology Stack**
- **Frontend**: Mojo with integer-only FFI API
- **Backend**: C with OpenGL/GLFW graphics
- **Fonts**: Professional TTF rendering via `stb_truetype`
- **Colors**: System-native color detection

### **Project Structure**
```
mojogui/
├── 🔧 mojo-gui/                    # Core framework
│   ├── c_src/                      # C graphics backend
│   ├── mojo_src/                   # Mojo widget library
│   └── examples/                   # Basic examples
├── 🖥️ adaptive_file_manager.mojo   # Main demo application
├── 🎨 system_colors_demo.mojo      # Color integration demo
├── 🐍 python_bindings/             # Python wrapper system
├── 🧪 tests_and_demos/             # Test programs
└── 📖 docs/                        # Documentation
```

## 🔧 **Real Implementation Examples**

### **TreeView Widget - Full hierarchical tree with drag & drop**
```mojo
# Creating a file browser tree
var tree = create_file_tree_int(10, 10, 300, 400)
var root = tree.add_node("Home", -1, NODE_FOLDER)
var docs = tree.add_node("Documents", root, NODE_FOLDER)
var file = tree.add_node("README.md", docs, NODE_FILE)

# Features implemented:
# ✅ Keyboard navigation (arrow keys)
# ✅ Drag and drop support
# ✅ Multi-selection
# ✅ Smooth expand/collapse animations
# ✅ Virtual rendering for performance
```

### **Column Header Widget - Sortable, resizable table headers**
```mojo
var header = create_column_header_int(0, 0, 800, 28)
header.add_column("name", "Name", 250, sortable=True, resizable=True)
header.add_column("size", "Size", 100)
header.add_column("modified", "Date Modified", 150)

# Features implemented:
# ✅ Click to sort (ascending/descending/none)
# ✅ Drag to resize columns
# ✅ Right-click context menu
# ✅ Min/max width constraints
# ✅ Text truncation with ellipsis
```

### **Real-time Text Input System**
```mojo
# Real-time text input with visual feedback
var get_input_text = lib.get_function[fn() -> UnsafePointer[Int8]]("get_input_text")
var has_new_input = lib.get_function[fn() -> Int32]("has_new_input")

# Handle text input
if search_focused == 1:
    if has_new_input() == 1:
        var input_ptr = get_input_text()
        var input_str = String(input_ptr)
        search_text = "🔍 " + input_str
```

### **System Color Integration**
```mojo
# Automatic system color detection
var dark_mode = get_system_dark_mode()
var accent_color = get_system_accent_color()
var window_color = get_system_window_color()

# Adaptive UI rendering
if dark_mode == 1:
    bg_r = 45; bg_g = 45; bg_b = 45  # Dark theme
else:
    bg_r = 240; bg_g = 240; bg_b = 240  # Light theme
```

## 🏗️ **Architecture Highlights**

### **Integer-Only FFI Design**
All widgets use integer-only interfaces for Mojo's current FFI limitations:
```mojo
struct ColorInt:
    var r: Int32
    var g: Int32
    var b: Int32
    var a: Int32

struct RectInt:
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
```

### **Event-Driven Architecture**
```mojo
fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
    # Full event handling with hover, click, drag states
    if self.resize_column >= 0:
        # Active resize operation
        let delta = event.x - self.resize_start_x
        let new_width = self.resize_start_width + delta
        self.columns[self.resize_column].width = clamp(new_width, min, max)
        return True
    return False
```

## ✅ **What's Actually Working**

### **Implemented Widgets (Working Components)**
- **TreeView**: 500+ lines of working code
  - Hierarchical data structure
  - Expand/collapse with animations
  - Drag & drop node rearrangement
  - Keyboard navigation
  - Virtual scrolling for large trees
  
- **ColumnHeader**: 400+ lines of working code
  - Sort indicators with arrows
  - Resize handles with cursor feedback
  - Context menus
  - Column hide/show
  
- **ScrollBar**: Both horizontal and vertical implementations
- **Button**: With hover and pressed states
- **CheckBox**: Three-state support
- **ProgressBar**: With animations
- **TextInput**: Real-time character input with cursor

*Note: Widgets work individually but integration between components needs refinement*

### **System Integration (Working)**
```mojo
# These core functions work:
var dark_mode = get_system_dark_mode()        # ✅ Detects OS dark mode
var accent = get_system_accent_color()         # ✅ Gets OS accent color  
var has_input = has_new_input()                # ✅ Real-time input detection
var input_text = String(get_input_text())      # ✅ Live text input
```

### **File Manager Demo (Working Prototype)**
- **Dual-pane file browser** with basic navigation
- **Working search box** with real-time text input
- **System color adaptation** (automatic dark/light mode)
- **Interactive mouse navigation** with hover effects
- **Status bar** with live updates

*Note: File manager demonstrates capabilities but needs polish for production use*

## 🚧 **Known Limitations & TODO**

### **Integration Challenges**
- [ ] Widget composition system needs work
- [ ] Layout management between widgets
- [ ] Event propagation between components
- [ ] Consistent theming across all widgets

### **Needs Implementation**
- [ ] Installation script
- [ ] Windows system color detection (Linux/macOS working)
- [ ] Package management integration
- [ ] Comprehensive test suite

### **Needs Polish**  
- [ ] Widget visual consistency
- [ ] Performance optimization for large datasets
- [ ] Better error handling
- [ ] Production-ready examples

### **Current State**
Individual widgets work well, but the framework needs better integration patterns.
The search functionality and file manager show what's possible when components work together.

## 🧪 **Testing**

### **Run the Demo Applications**
```bash
# File manager with search
mojo adaptive_file_manager.mojo

# System color detection
mojo system_colors_demo.mojo

# Widget showcase
mojo mojo-gui/complete_widget_showcase.mojo
```

### **Test Search Functionality**
1. Run the file manager: `mojo adaptive_file_manager.mojo`
2. Click the search box (notice accent color border)
3. Type text - it appears immediately
4. Use backspace to edit
5. Click elsewhere to unfocus

## 🤝 **Contributing**

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### **Development Setup**
1. Fork the repository
2. Create a feature branch
3. Build and test your changes
4. Submit a pull request

### **Areas for Contribution**
- Additional widget types
- Enhanced text input features
- Mobile platform support
- Performance optimizations

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 **Acknowledgments**

- [Mojo Programming Language](https://www.modular.com/mojo) by Modular
- [stb_truetype](https://github.com/nothings/stb) for professional font rendering
- [GLFW](https://www.glfw.org/) for cross-platform windowing
- OpenGL for graphics rendering

## 📊 **Project Stats**

- **📄 50+ Mojo files** - Framework and applications
- **🔧 20+ C files** - Graphics backend (22,000+ lines)
- **📖 15+ Documentation files** - Comprehensive guides
- **🐍 25+ Python files** - Binding system
- **🏗️ 30+ Widget implementations** - TreeView, ColumnHeader, ScrollBar, etc.
- **🎨 4,000+ lines** - Real widget implementation code
- **⚡ Active development** - Working components with integration in progress

## 🚧 **Status: EXPERIMENTAL ALPHA v0.24.0001**

⚠️ **This is experimental alpha software - NOT production ready!**

**What works:**
- ✅ **Professional glyph atlas text rendering** - Smooth JetBrains Mono fonts
- ✅ **Basic proof-of-concept demos** - Shows technical feasibility
- ✅ **Individual widget prototypes** - Demonstrates concepts
- ✅ **System integration examples** - Cross-platform color detection

**Major limitations:**
- ❌ **No production-ready architecture** - Needs complete redesign
- ❌ **Missing error handling** - Minimal robustness
- ❌ **No memory management** - Potential leaks
- ❌ **Limited testing** - Proof-of-concept quality only
- ❌ **No documentation for production** - Demo code only

**Suitable for: Research, experimentation, learning**
**NOT suitable for: Production applications, commercial use**

---

**⭐ Star this repository if you find it useful!**