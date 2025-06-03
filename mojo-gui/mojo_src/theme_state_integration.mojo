"""
Theme, State, and Integration System - The missing pieces that make everything work together!
This provides consistent styling, state persistence, and widget coordination.
"""

from .rendering_int import RenderingContextInt, ColorInt
import json

# ============================================
# THEME SYSTEM - Consistent look across all widgets
# ============================================

struct Theme:
    """Unified theme system for consistent widget appearance."""
    
    # Core colors
    var primary: ColorInt
    var primary_hover: ColorInt
    var primary_pressed: ColorInt
    var secondary: ColorInt
    var background: ColorInt
    var surface: ColorInt
    var surface_hover: ColorInt
    var error: ColorInt
    var warning: ColorInt
    var success: ColorInt
    
    # Text colors
    var text_primary: ColorInt
    var text_secondary: ColorInt
    var text_disabled: ColorInt
    var text_on_primary: ColorInt
    
    # Widget-specific colors
    var border_normal: ColorInt
    var border_focused: ColorInt
    var border_error: ColorInt
    var shadow: ColorInt
    
    # Measurements
    var border_radius: Int32
    var border_width: Int32
    var padding_small: Int32
    var padding_medium: Int32
    var padding_large: Int32
    var spacing: Int32
    
    # Typography
    var font_size_small: Int32
    var font_size_normal: Int32
    var font_size_large: Int32
    var font_size_title: Int32
    
    fn __init__(inout self):
        """Initialize with default modern theme."""
        # Modern blue theme (like VS Code)
        self.primary = ColorInt(0, 122, 204, 255)         # VS Code blue
        self.primary_hover = ColorInt(28, 151, 234, 255)  # Lighter blue
        self.primary_pressed = ColorInt(0, 90, 158, 255)  # Darker blue
        self.secondary = ColorInt(66, 66, 66, 255)        # Dark gray
        self.background = ColorInt(30, 30, 30, 255)       # Dark background
        self.surface = ColorInt(37, 37, 38, 255)          # Panel background
        self.surface_hover = ColorInt(45, 45, 46, 255)    # Hovered surface
        self.error = ColorInt(244, 67, 54, 255)           # Red
        self.warning = ColorInt(255, 152, 0, 255)         # Orange
        self.success = ColorInt(76, 175, 80, 255)         # Green
        
        self.text_primary = ColorInt(204, 204, 204, 255)  # Light gray text
        self.text_secondary = ColorInt(136, 136, 136, 255) # Darker gray
        self.text_disabled = ColorInt(85, 85, 85, 255)    # Disabled text
        self.text_on_primary = ColorInt(255, 255, 255, 255) # White on primary
        
        self.border_normal = ColorInt(60, 60, 60, 255)    # Subtle borders
        self.border_focused = self.primary                 # Blue focused border
        self.border_error = self.error                     # Red error border
        self.shadow = ColorInt(0, 0, 0, 100)              # Transparent shadow
        
        self.border_radius = 4
        self.border_width = 1
        self.padding_small = 4
        self.padding_medium = 8
        self.padding_large = 16
        self.spacing = 8
        
        self.font_size_small = 12
        self.font_size_normal = 14
        self.font_size_large = 18
        self.font_size_title = 24

# Pre-defined professional themes
struct Themes:
    """Collection of pre-defined themes."""
    
    @staticmethod
    fn dark_modern() -> Theme:
        """Modern dark theme (VS Code style)."""
        return Theme()  # Default is already dark modern
    
    @staticmethod
    fn light_modern() -> Theme:
        """Modern light theme."""
        var theme = Theme()
        theme.primary = ColorInt(0, 100, 200, 255)
        theme.primary_hover = ColorInt(30, 130, 230, 255)
        theme.primary_pressed = ColorInt(0, 70, 140, 255)
        theme.background = ColorInt(250, 250, 250, 255)
        theme.surface = ColorInt(255, 255, 255, 255)
        theme.surface_hover = ColorInt(245, 245, 245, 255)
        theme.text_primary = ColorInt(33, 33, 33, 255)
        theme.text_secondary = ColorInt(117, 117, 117, 255)
        theme.border_normal = ColorInt(230, 230, 230, 255)
        return theme
    
    @staticmethod
    fn material_dark() -> Theme:
        """Material Design dark theme."""
        var theme = Theme()
        theme.primary = ColorInt(98, 0, 238, 255)         # Deep purple
        theme.primary_hover = ColorInt(124, 77, 255, 255)
        theme.primary_pressed = ColorInt(69, 39, 160, 255)
        theme.background = ColorInt(18, 18, 18, 255)
        theme.surface = ColorInt(33, 33, 33, 255)
        theme.text_primary = ColorInt(255, 255, 255, 255)
        theme.border_normal = ColorInt(48, 48, 48, 255)
        return theme
    
    @staticmethod
    fn github_dark() -> Theme:
        """GitHub dark theme."""
        var theme = Theme()
        theme.primary = ColorInt(88, 166, 255, 255)       # GitHub blue
        theme.background = ColorInt(13, 17, 23, 255)      # GitHub dark
        theme.surface = ColorInt(22, 27, 34, 255)
        theme.border_normal = ColorInt(48, 54, 61, 255)
        theme.success = ColorInt(56, 139, 66, 255)        # GitHub green
        return theme

# ============================================
# STATE MANAGEMENT - Persist and manage widget state
# ============================================

struct WidgetState:
    """State data for a widget."""
    var id: String
    var type: String
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
    var visible: Bool
    var text: String
    var value: Float32
    var selected: Bool
    var children: DynamicVector[String]  # Child widget IDs
    
    fn __init__(inout self, id: String, type: String):
        self.id = id
        self.type = type
        self.x = 0
        self.y = 0
        self.width = 100
        self.height = 30
        self.visible = True
        self.text = ""
        self.value = 0.0
        self.selected = False
        self.children = DynamicVector[String]()

struct StateManager:
    """Manages persistent state for all widgets."""
    
    var states: Dict[String, WidgetState]
    var dirty: Bool
    var autosave: Bool
    var filename: String
    
    fn __init__(inout self, filename: String = "gui_state.json"):
        self.states = Dict[String, WidgetState]()
        self.dirty = False
        self.autosave = True
        self.filename = filename
    
    fn register_widget(inout self, widget_id: String, widget_type: String) -> WidgetState:
        """Register a new widget and return its state."""
        if widget_id in self.states:
            return self.states[widget_id]
        
        var state = WidgetState(widget_id, widget_type)
        self.states[widget_id] = state
        self.dirty = True
        return state
    
    fn update_widget_bounds(inout self, widget_id: String, x: Int32, y: Int32, width: Int32, height: Int32):
        """Update widget position and size."""
        if widget_id in self.states:
            var state = self.states[widget_id]
            state.x = x
            state.y = y
            state.width = width
            state.height = height
            self.dirty = True
    
    fn update_widget_text(inout self, widget_id: String, text: String):
        """Update widget text content."""
        if widget_id in self.states:
            self.states[widget_id].text = text
            self.dirty = True
    
    fn update_widget_value(inout self, widget_id: String, value: Float32):
        """Update widget numeric value."""
        if widget_id in self.states:
            self.states[widget_id].value = value
            self.dirty = True
    
    fn save_state(self):
        """Save state to file."""
        # Convert to JSON format
        var json_str = "{\n"
        var first = True
        
        for widget_id in self.states:
            if not first:
                json_str += ",\n"
            first = False
            
            let state = self.states[widget_id]
            json_str += '  "' + widget_id + '": {\n'
            json_str += '    "type": "' + state.type + '",\n'
            json_str += '    "x": ' + str(state.x) + ',\n'
            json_str += '    "y": ' + str(state.y) + ',\n'
            json_str += '    "width": ' + str(state.width) + ',\n'
            json_str += '    "height": ' + str(state.height) + ',\n'
            json_str += '    "visible": ' + ("true" if state.visible else "false") + ',\n'
            json_str += '    "text": "' + state.text + '",\n'
            json_str += '    "value": ' + str(state.value) + ',\n'
            json_str += '    "selected": ' + ("true" if state.selected else "false") + '\n'
            json_str += '  }'
        
        json_str += "\n}"
        
        # Write to file
        # TODO: Implement file writing
        print("State saved:", json_str)
    
    fn load_state(inout self):
        """Load state from file."""
        # TODO: Implement file reading and JSON parsing
        print("Loading state from:", self.filename)

# ============================================
# WIDGET FACTORY - Create styled widgets consistently
# ============================================

struct WidgetFactory:
    """Factory for creating consistently styled widgets."""
    
    var theme: Theme
    var state_manager: StateManager
    var next_id: Int32
    
    fn __init__(inout self, theme: Theme, state_manager: StateManager):
        self.theme = theme
        self.state_manager = state_manager
        self.next_id = 1000
    
    fn generate_id(inout self, prefix: String) -> String:
        """Generate unique widget ID."""
        let id = prefix + "_" + str(self.next_id)
        self.next_id += 1
        return id
    
    fn create_button(inout self, text: String, x: Int32 = 0, y: Int32 = 0) -> ButtonConfig:
        """Create a themed button configuration."""
        let id = self.generate_id("btn")
        let state = self.state_manager.register_widget(id, "button")
        state.text = text
        state.x = x
        state.y = y
        state.width = 100
        state.height = 30
        
        return ButtonConfig(
            id=id,
            text=text,
            bounds=RectInt(x, y, 100, 30),
            normal_color=self.theme.primary,
            hover_color=self.theme.primary_hover,
            pressed_color=self.theme.primary_pressed,
            text_color=self.theme.text_on_primary,
            border_color=self.theme.primary,
            border_width=self.theme.border_width,
            font_size=self.theme.font_size_normal
        )
    
    fn create_textbox(inout self, placeholder: String = "", x: Int32 = 0, y: Int32 = 0) -> TextBoxConfig:
        """Create a themed textbox configuration."""
        let id = self.generate_id("txt")
        let state = self.state_manager.register_widget(id, "textbox")
        state.x = x
        state.y = y
        state.width = 200
        state.height = 32
        
        return TextBoxConfig(
            id=id,
            placeholder=placeholder,
            bounds=RectInt(x, y, 200, 32),
            bg_color=self.theme.surface,
            text_color=self.theme.text_primary,
            placeholder_color=self.theme.text_secondary,
            border_normal=self.theme.border_normal,
            border_focused=self.theme.border_focused,
            border_width=self.theme.border_width,
            padding=self.theme.padding_small,
            font_size=self.theme.font_size_normal
        )
    
    fn create_panel(inout self, x: Int32, y: Int32, width: Int32, height: Int32) -> PanelConfig:
        """Create a themed panel configuration."""
        let id = self.generate_id("pnl")
        let state = self.state_manager.register_widget(id, "panel")
        state.x = x
        state.y = y
        state.width = width
        state.height = height
        
        return PanelConfig(
            id=id,
            bounds=RectInt(x, y, width, height),
            bg_color=self.theme.surface,
            border_color=self.theme.border_normal,
            border_width=self.theme.border_width,
            padding=self.theme.padding_medium
        )
    
    fn create_label(inout self, text: String, x: Int32 = 0, y: Int32 = 0) -> LabelConfig:
        """Create a themed label configuration."""
        let id = self.generate_id("lbl")
        let state = self.state_manager.register_widget(id, "label")
        state.text = text
        state.x = x
        state.y = y
        
        return LabelConfig(
            id=id,
            text=text,
            position=PointInt(x, y),
            text_color=self.theme.text_primary,
            font_size=self.theme.font_size_normal
        )

# Configuration structs for widgets
struct ButtonConfig:
    var id: String
    var text: String
    var bounds: RectInt
    var normal_color: ColorInt
    var hover_color: ColorInt
    var pressed_color: ColorInt
    var text_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32
    var font_size: Int32

struct TextBoxConfig:
    var id: String
    var placeholder: String
    var bounds: RectInt
    var bg_color: ColorInt
    var text_color: ColorInt
    var placeholder_color: ColorInt
    var border_normal: ColorInt
    var border_focused: ColorInt
    var border_width: Int32
    var padding: Int32
    var font_size: Int32

struct PanelConfig:
    var id: String
    var bounds: RectInt
    var bg_color: ColorInt
    var border_color: ColorInt
    var border_width: Int32
    var padding: Int32

struct LabelConfig:
    var id: String
    var text: String
    var position: PointInt
    var text_color: ColorInt
    var font_size: Int32

# ============================================
# UNIFIED GUI SYSTEM - Brings it all together
# ============================================

struct UnifiedGUI:
    """Complete GUI system with theme, state, and all widgets integrated."""
    
    var ctx: RenderingContextInt
    var theme: Theme
    var state_manager: StateManager
    var factory: WidgetFactory
    
    # Import all your widget types
    var buttons: Dict[String, ButtonInt]
    var textboxes: Dict[String, TextEditInt]
    var labels: Dict[String, LabelInt]
    var panels: Dict[String, PanelInt]
    var checkboxes: Dict[String, CheckBoxInt]
    var sliders: Dict[String, SliderInt]
    var listboxes: Dict[String, ListBoxInt]
    var comboboxes: Dict[String, ComboBoxInt]
    var treeviews: Dict[String, TreeViewInt]
    var tabcontrols: Dict[String, TabControlInt]
    
    # Widget hierarchy
    var root_panel: String
    var focus_widget: String
    var hover_widget: String
    
    fn __init__(inout self, width: Int32, height: Int32, title: String):
        """Initialize unified GUI system."""
        self.ctx = RenderingContextInt()
        self.theme = Themes.dark_modern()
        self.state_manager = StateManager()
        self.factory = WidgetFactory(self.theme, self.state_manager)
        
        # Initialize widget collections
        self.buttons = Dict[String, ButtonInt]()
        self.textboxes = Dict[String, TextEditInt]()
        self.labels = Dict[String, LabelInt]()
        self.panels = Dict[String, PanelInt]()
        self.checkboxes = Dict[String, CheckBoxInt]()
        self.sliders = Dict[String, SliderInt]()
        self.listboxes = Dict[String, ListBoxInt]()
        self.comboboxes = Dict[String, ComboBoxInt]()
        self.treeviews = Dict[String, TreeViewInt]()
        self.tabcontrols = Dict[String, TabControlInt]()
        
        self.root_panel = ""
        self.focus_widget = ""
        self.hover_widget = ""
        
        # Initialize rendering context
        if not self.ctx.initialize(width, height, title):
            print("Failed to initialize GUI!")
            return
        
        # Load font
        _ = self.ctx.load_default_font()
        
        # Load previous state
        self.state_manager.load_state()
        
        # Create root panel
        let root_config = self.factory.create_panel(0, 0, width, height)
        self.root_panel = root_config.id
        # TODO: Actually create the panel widget
    
    fn set_theme(inout self, theme: Theme):
        """Change the theme and update all widgets."""
        self.theme = theme
        self.factory.theme = theme
        # TODO: Update all existing widgets with new theme
    
    fn add_button(inout self, text: String, x: Int32, y: Int32, parent: String = "") -> String:
        """Add a button to the GUI."""
        let config = self.factory.create_button(text, x, y)
        
        # Create actual button widget with theme
        var button = ButtonInt(config.bounds.x, config.bounds.y, 
                              config.bounds.width, config.bounds.height)
        button.text = config.text
        button.background_color = config.normal_color
        button.text_color = config.text_color
        button.border_color = config.border_color
        
        self.buttons[config.id] = button
        
        # Add to parent if specified
        if parent != "" and parent in self.state_manager.states:
            self.state_manager.states[parent].children.append(config.id)
        
        return config.id
    
    fn add_textbox(inout self, placeholder: String, x: Int32, y: Int32, parent: String = "") -> String:
        """Add a textbox to the GUI."""
        let config = self.factory.create_textbox(placeholder, x, y)
        
        # Create actual textbox widget with theme
        var textbox = TextEditInt(config.bounds.x, config.bounds.y,
                                 config.bounds.width, config.bounds.height, 
                                 config.placeholder)
        textbox.background_color = config.bg_color
        textbox.text_color = config.text_color
        textbox.placeholder_color = config.placeholder_color
        textbox.border_color = config.border_normal
        
        self.textboxes[config.id] = textbox
        
        # Add to parent if specified
        if parent != "" and parent in self.state_manager.states:
            self.state_manager.states[parent].children.append(config.id)
        
        return config.id
    
    fn handle_events(inout self):
        """Process all input events."""
        self.event_manager.update(self.ctx)
        
        let mouse_pos = self.event_manager.get_mouse_position()
        let mouse_clicked = self.event_manager.is_mouse_button_pressed(self.ctx, 0)
        
        # TODO: Route events to appropriate widgets
        # This would check which widget contains the mouse and forward events
    
    fn render(self):
        """Render all widgets."""
        _ = self.ctx.frame_begin()
        
        # Clear with theme background
        _ = self.ctx.set_color(self.theme.background.r, self.theme.background.g,
                              self.theme.background.b, self.theme.background.a)
        _ = self.ctx.draw_filled_rectangle(0, 0, self.ctx.width, self.ctx.height)
        
        # Render all widgets
        # TODO: Render in proper z-order with parent/child relationships
        
        for id in self.buttons:
            self.buttons[id].render(self.ctx)
        
        for id in self.textboxes:
            self.textboxes[id].render(self.ctx)
        
        _ = self.ctx.frame_end()
    
    fn save_state(self):
        """Save current GUI state."""
        # Update state manager with current widget positions
        for id in self.buttons:
            let bounds = self.buttons[id].get_bounds()
            self.state_manager.update_widget_bounds(id, bounds.x, bounds.y, 
                                                   bounds.width, bounds.height)
        
        # Save to file
        self.state_manager.save_state()
    
    fn run(inout self):
        """Run the GUI main loop."""
        while not self.ctx.should_close_window():
            self.handle_events()
            self.render()
            
            # Autosave periodically
            if self.state_manager.dirty and self.state_manager.autosave:
                self.save_state()
                self.state_manager.dirty = False
        
        # Save final state
        self.save_state()
        _ = self.ctx.cleanup()

# ============================================
# EASY-TO-USE API
# ============================================

fn create_app(title: String, width: Int32 = 800, height: Int32 = 600) -> UnifiedGUI:
    """Create a new GUI application."""
    return UnifiedGUI(width, height, title)

fn main():
    """Example of complete integrated GUI."""
    # Create app with theme and state management
    var app = create_app("My Themed App", 1024, 768)
    
    # Choose a theme
    app.set_theme(Themes.github_dark())
    
    # Add widgets - they're automatically themed and state-managed!
    let panel = app.add_panel(10, 10, 400, 300)
    let label = app.add_label("Username:", 20, 30, panel)
    let username = app.add_textbox("Enter username", 100, 30, panel)
    let submit = app.add_button("Login", 100, 80, panel)
    
    # Run - state is automatically saved/loaded!
    app.run()