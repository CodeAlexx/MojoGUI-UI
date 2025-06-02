# Contributing to MojoGUI

Thank you for your interest in contributing to MojoGUI! This document provides guidelines for contributing to the project.

## 🚀 **Quick Start for Contributors**

### **Development Environment Setup**

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
   ```bash
   git clone https://github.com/your-username/mojogui.git
   cd mojogui
   ```
3. **Build the project**
   ```bash
   cd mojo-gui/c_src
   make
   ```
4. **Test the installation**
   ```bash
   cd ../..
   mojo adaptive_file_manager.mojo
   ```

## 📋 **How to Contribute**

### **Types of Contributions**

We welcome all types of contributions:
- 🐛 **Bug fixes**
- ✨ **New features**
- 📖 **Documentation improvements**
- 🧪 **Test additions**
- 🎨 **UI/UX enhancements**
- 🔧 **Performance optimizations**

### **Development Workflow**

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the coding standards (see below)
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   # Build the C libraries
   cd mojo-gui/c_src && make

   # Test main applications
   mojo adaptive_file_manager.mojo
   mojo system_colors_demo.mojo
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new widget functionality"
   ```

5. **Push and create a pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

## 🔧 **Technical Guidelines**

### **Project Structure**
```
mojogui/
├── mojo-gui/
│   ├── c_src/          # C backend - graphics and input
│   ├── mojo_src/       # Mojo frontend - widgets and API
│   └── examples/       # Basic usage examples
├── adaptive_file_manager.mojo    # Main demo application
├── system_colors_demo.mojo       # Color system demo
├── python_bindings/             # Python wrapper system
└── tests_and_demos/             # Test programs
```

### **Coding Standards**

#### **Mojo Code**
- Use clear, descriptive variable names
- Follow existing code style and patterns
- Add comments for complex logic
- Use integer-only FFI interface pattern

#### **C Code**
- Follow existing naming conventions (`function_name`)
- Use proper error handling
- Add documentation comments for public functions
- Maintain cross-platform compatibility

#### **Documentation**
- Update README.md for new features
- Add inline code comments
- Create examples for new widgets
- Update API documentation

### **Testing Requirements**

#### **Before Submitting**
1. **Build successfully** on your platform
2. **Test main applications** run without errors
3. **Verify new features** work as expected
4. **Check cross-platform compatibility** if possible

#### **Test Commands**
```bash
# Build system
cd mojo-gui/c_src && make

# Test core functionality
mojo adaptive_file_manager.mojo

# Test system integration
mojo system_colors_demo.mojo

# Test widget showcase
mojo mojo-gui/complete_widget_showcase.mojo
```

## 🎯 **Areas for Contribution**

### **High Priority**
- 📱 **Mobile platform support** (iOS/Android)
- 🎮 **Game controller input** support
- 🔤 **Enhanced text editing** (multi-line, syntax highlighting)
- 🖼️ **Image loading and display** widgets
- 📊 **Chart and graph** components

### **Medium Priority**
- 🎨 **Theme system** improvements
- ⚡ **Performance optimizations**
- 🧪 **Additional test coverage**
- 📖 **Documentation improvements**
- 🌐 **Internationalization** support

### **Widget Requests**
- DatePicker improvements
- TreeView enhancements
- Table/Grid widgets
- Rich text editor
- Media player controls

## 🐛 **Reporting Issues**

### **Bug Reports**
When reporting bugs, please include:
- **OS and version** (Linux/macOS/Windows)
- **Mojo version** 
- **Reproduction steps**
- **Expected vs actual behavior**
- **Error messages** (if any)
- **Minimal code example** (if possible)

### **Feature Requests**
For new features, please describe:
- **Use case** and motivation
- **Proposed API** or interface
- **Implementation ideas** (if you have them)
- **Mockups or examples** (if applicable)

## 📝 **Commit Message Format**

Use conventional commit format:
```
type(scope): brief description

Optional longer description

Fixes #issue-number
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions
- `chore`: Maintenance tasks

**Examples:**
```
feat(widgets): add DatePicker widget with system integration
fix(search): resolve text input buffer overflow issue
docs(api): update widget reference documentation
```

## 🤝 **Code Review Process**

### **Pull Request Guidelines**
- Keep PRs focused and reasonably sized
- Include tests for new functionality
- Update documentation as needed
- Respond promptly to review feedback

### **Review Criteria**
- Code quality and style
- Functionality and correctness
- Test coverage
- Documentation completeness
- Cross-platform compatibility

## 🌟 **Recognition**

Contributors will be:
- Listed in the project README
- Credited in release notes
- Invited to join the core team (for significant contributions)

## 📞 **Getting Help**

- **Questions**: Open a GitHub issue with the "question" label
- **Discussions**: Use GitHub Discussions for general topics
- **Chat**: Join our development discussions (coming soon)

## 📄 **License**

By contributing to MojoGUI, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for helping make MojoGUI better! 🎉**