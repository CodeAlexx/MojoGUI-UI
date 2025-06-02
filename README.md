# 🗂️ MojoGUI - Professional GUI Framework for Mojo

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-blue.svg)](https://github.com/your-username/mojogui)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-green.svg)](https://github.com/your-username/mojogui)

A complete, professional GUI framework for the [Mojo programming language](https://www.modular.com/mojo) featuring modern UI components, system color integration, and real-time text input capabilities.

## 🚀 **Key Features**

### ✅ **Working Text Input System**
- **Real-time character input** with professional text rendering
- **Visual focus management** with system accent colors
- **Backspace support** and cursor management
- **Click-to-focus/unfocus** behavior

### ✅ **Professional File Manager**
- **Dual-pane file browser** with adaptive system colors
- **Interactive search functionality** with working text input
- **Real-time mouse interaction** and hover effects
- **System color integration** (automatic dark/light mode)

### ✅ **Modern UI Components**
- Professional TTF font rendering via `stb_truetype`
- Cross-platform system color detection
- Adaptive color schemes
- Real-time visual feedback

### ✅ **Cross-Platform Support**
- **Linux**: Full support with GNOME/GTK integration
- **macOS**: Native color scheme detection
- **Windows**: System integration ready

## 📸 **Screenshots**

### Adaptive File Manager with Working Search
![File Manager](docs/file_manager_demo.png)
*Professional dual-pane file manager with functional search box*

### System Color Integration
![System Colors](docs/system_colors_demo.png)
*Automatic adaptation to system dark/light mode and accent colors*

## 🔧 **Quick Start**

### **Prerequisites**
- [Mojo programming language](https://www.modular.com/mojo)
- OpenGL and GLFW development libraries
- GCC or compatible C compiler

### **Installation**

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/mojogui.git
   cd mojogui
   ```

2. **Build the C libraries**
   ```bash
   cd mojo-gui/c_src
   make
   ```

3. **Run the file manager demo**
   ```bash
   cd ../..
   mojo adaptive_file_manager.mojo
   ```

4. **Test the search functionality**
   - Click the search box (top-right corner)
   - Start typing - text appears immediately!
   - Use backspace to edit

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

## 🎨 **Features Deep Dive**

### **Text Input System**
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
- **🔧 20+ C files** - Graphics backend
- **📖 15+ Documentation files** - Comprehensive guides
- **🐍 25+ Python files** - Binding system
- **✅ Production ready** - Complete working system

## 🎉 **Status: Production Ready**

This is a **complete, working GUI framework** featuring:
- ✅ **Real text input functionality**
- ✅ **Professional file manager**
- ✅ **System color integration**  
- ✅ **Cross-platform compatibility**
- ✅ **Comprehensive documentation**

**Ready for immediate use and further development!**

---

**⭐ Star this repository if you find it useful!**