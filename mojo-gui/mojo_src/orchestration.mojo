"""
GUI Orchestration Layer - The GLUE that makes everything work together
This is the missing integration layer that coordinates widgets, events, and rendering.
"""

from .rendering_int import RenderingContextInt, ColorInt, PointInt, RectInt
from .widget_int import WidgetInt, MouseEventInt, KeyEventInt, EventManagerInt

# Widget type enumeration
alias WIDGET_UNKNOWN = 0
alias WIDGET_PANEL = 1
alias WIDGET_BUTTON = 2
alias WIDGET_LABEL = 3
alias WIDGET_TEXTBOX = 4
alias WIDGET_CHECKBOX = 5
alias WIDGET_RADIO = 6
alias WIDGET_SLIDER = 7
alias WIDGET_SCROLLBAR = 8
alias WIDGET_LISTBOX = 9
alias WIDGET_COMBOBOX = 10
alias WIDGET_WINDOW = 11
alias WIDGET_MENU = 12

# Layout types
alias LAYOUT_NONE = 0      # Absolute positioning
alias LAYOUT_VERTICAL = 1   # Stack vertically
alias LAYOUT_HORIZONTAL = 2 # Stack horizontally
alias LAYOUT_GRID = 3      # Grid layout
alias LAYOUT_FLOW = 4      # Flow layout (wrap)

# Widget registry entry
struct WidgetEntry:
    """Registry entry for a widget."""
    var id: Int32
    var widget_type: Int32
    var parent_id: Int32
    var children: DynamicVector[Int32]
    var bounds: RectInt
    var visible: Bool
    var enabled: Bool
    var focused: Bool
    var z_order: Int32
    
    # Layout properties
    var layout_type: Int32
    var padding: Int32
    var spacing: Int32
    
    # Event handlers (callback IDs)
    var on_click: Int32
    var on_hover: Int32
    var on_focus: Int32
    var on_key: Int32
    var on_resize: Int32
    
    fn __init__(inout self, id: Int32, widget_type: Int32):
        self.id = id
        self.widget_type = widget_type
        self.parent_id = -1
        self.children = DynamicVector[Int32]()
        self.bounds = RectInt(0, 0, 100, 30)
        self.visible = True
        self.enabled = True
        self.focused = False
        self.z_order = 0
        self.layout_type = LAYOUT_NONE
        self.padding = 4
        self.spacing = 4
        self.on_click = -1
        self.on_hover = -1
        self.on_focus = -1
        self.on_key = -1
        self.on_resize = -1

# The main orchestrator
struct GUIOrchestrator:
    """The main GUI orchestration system - the GLUE that makes everything work."""
    
    var ctx: RenderingContextInt
    var event_manager: EventManagerInt
    var widgets: DynamicVector[WidgetEntry]
    var widget_count: Int32
    var root_widget_id: Int32
    var focused_widget_id: Int32
    var hovered_widget_id: Int32
    var dragging_widget_id: Int32
    var drag_offset_x: Int32
    var drag_offset_y: Int32
    
    # Callback management
    var next_callback_id: Int32
    var callbacks: DynamicVector[fn() -> None]  # Simplified - would be more complex
    
    # Dirty tracking for efficient updates
    var needs_layout: Bool
    var dirty_widgets: DynamicVector[Int32]
    
    fn __init__(inout self, width: Int32, height: Int32, title: String):
        """Initialize the orchestrator with a window."""
        self.ctx = RenderingContextInt()
        self.event_manager = EventManagerInt()
        self.widgets = DynamicVector[WidgetEntry]()
        self.widget_count = 0
        self.root_widget_id = -1
        self.focused_widget_id = -1
        self.hovered_widget_id = -1
        self.dragging_widget_id = -1
        self.drag_offset_x = 0
        self.drag_offset_y = 0
        self.next_callback_id = 0
        self.callbacks = DynamicVector[fn() -> None]()
        self.needs_layout = True
        self.dirty_widgets = DynamicVector[Int32]()
        
        # Initialize the rendering context
        if not self.ctx.initialize(width, height, title):
            print("Failed to initialize rendering context!")
        
        # Create root panel
        self.root_widget_id = self.create_widget(WIDGET_PANEL)
        if self.root_widget_id >= 0:
            self.widgets[self.root_widget_id].bounds = RectInt(0, 0, width, height)
            self.widgets[self.root_widget_id].layout_type = LAYOUT_NONE
    
    fn create_widget(inout self, widget_type: Int32) -> Int32:
        """Create a new widget and return its ID."""
        let widget_id = self.widget_count
        self.widgets.append(WidgetEntry(widget_id, widget_type))
        self.widget_count += 1
        self.mark_dirty(widget_id)
        return widget_id
    
    fn destroy_widget(inout self, widget_id: Int32):
        """Destroy a widget and all its children."""
        if widget_id < 0 or widget_id >= self.widget_count:
            return
        
        # Recursively destroy children
        let children = self.widgets[widget_id].children
        for i in range(len(children)):
            self.destroy_widget(children[i])
        
        # Remove from parent
        let parent_id = self.widgets[widget_id].parent_id
        if parent_id >= 0:
            self.remove_child_from_parent(parent_id, widget_id)
        
        # Clear the widget (mark as destroyed)
        self.widgets[widget_id].widget_type = WIDGET_UNKNOWN
        self.widgets[widget_id].visible = False
    
    fn add_widget_to_parent(inout self, widget_id: Int32, parent_id: Int32):
        """Add a widget as a child of another widget."""
        if widget_id < 0 or widget_id >= self.widget_count:
            return
        if parent_id < 0 or parent_id >= self.widget_count:
            return
        
        # Remove from current parent if any
        let current_parent = self.widgets[widget_id].parent_id
        if current_parent >= 0:
            self.remove_child_from_parent(current_parent, widget_id)
        
        # Add to new parent
        self.widgets[widget_id].parent_id = parent_id
        self.widgets[parent_id].children.append(widget_id)
        self.mark_needs_layout()
    
    fn remove_child_from_parent(inout self, parent_id: Int32, child_id: Int32):
        """Remove a child from its parent's children list."""
        # TODO: Implement proper vector removal
        pass
    
    fn set_widget_bounds(inout self, widget_id: Int32, x: Int32, y: Int32, width: Int32, height: Int32):
        """Set widget position and size."""
        if widget_id < 0 or widget_id >= self.widget_count:
            return
        
        self.widgets[widget_id].bounds = RectInt(x, y, width, height)
        self.mark_dirty(widget_id)
        self.mark_needs_layout()
    
    fn set_widget_layout(inout self, widget_id: Int32, layout_type: Int32, padding: Int32 = 4, spacing: Int32 = 4):
        """Set widget layout type for child arrangement."""
        if widget_id < 0 or widget_id >= self.widget_count:
            return
        
        self.widgets[widget_id].layout_type = layout_type
        self.widgets[widget_id].padding = padding
        self.widgets[widget_id].spacing = spacing
        self.mark_needs_layout()
    
    fn set_widget_visible(inout self, widget_id: Int32, visible: Bool):
        """Set widget visibility."""
        if widget_id < 0 or widget_id >= self.widget_count:
            return
        
        self.widgets[widget_id].visible = visible
        self.mark_dirty(widget_id)
        self.mark_needs_layout()
    
    fn set_widget_enabled(inout self, widget_id: Int32, enabled: Bool):
        """Set widget enabled state."""
        if widget_id < 0 or widget_id >= self.widget_count:
            return
        
        self.widgets[widget_id].enabled = enabled
        self.mark_dirty(widget_id)
    
    fn mark_dirty(inout self, widget_id: Int32):
        """Mark a widget as needing redraw."""
        if widget_id < 0 or widget_id >= self.widget_count:
            return
        
        # Add to dirty list if not already there
        var found = False
        for i in range(len(self.dirty_widgets)):
            if self.dirty_widgets[i] == widget_id:
                found = True
                break
        
        if not found:
            self.dirty_widgets.append(widget_id)
    
    fn mark_needs_layout(inout self):
        """Mark that layout recalculation is needed."""
        self.needs_layout = True
    
    fn perform_layout(inout self):
        """Recalculate layout for all widgets."""
        if not self.needs_layout:
            return
        
        # Start with root widget
        if self.root_widget_id >= 0:
            self.layout_widget(self.root_widget_id)
        
        self.needs_layout = False
    
    fn layout_widget(inout self, widget_id: Int32):
        """Layout a widget and its children."""
        if widget_id < 0 or widget_id >= self.widget_count:
            return
        
        let widget = self.widgets[widget_id]
        let children = widget.children
        
        if len(children) == 0:
            return  # No children to layout
        
        let padding = widget.padding
        let spacing = widget.spacing
        let content_x = widget.bounds.x + padding
        let content_y = widget.bounds.y + padding
        let content_width = widget.bounds.width - 2 * padding
        let content_height = widget.bounds.height - 2 * padding
        
        if widget.layout_type == LAYOUT_VERTICAL:
            # Stack children vertically
            var y = content_y
            for i in range(len(children)):
                let child_id = children[i]
                if child_id >= 0 and child_id < self.widget_count and self.widgets[child_id].visible:
                    let child_height = self.widgets[child_id].bounds.height
                    self.widgets[child_id].bounds.x = content_x
                    self.widgets[child_id].bounds.y = y
                    self.widgets[child_id].bounds.width = content_width
                    y += child_height + spacing
                    
                    # Recursively layout children
                    self.layout_widget(child_id)
        
        elif widget.layout_type == LAYOUT_HORIZONTAL:
            # Stack children horizontally
            var x = content_x
            for i in range(len(children)):
                let child_id = children[i]
                if child_id >= 0 and child_id < self.widget_count and self.widgets[child_id].visible:
                    let child_width = self.widgets[child_id].bounds.width
                    self.widgets[child_id].bounds.x = x
                    self.widgets[child_id].bounds.y = content_y
                    self.widgets[child_id].bounds.height = content_height
                    x += child_width + spacing
                    
                    # Recursively layout children
                    self.layout_widget(child_id)
        
        elif widget.layout_type == LAYOUT_NONE:
            # Absolute positioning - just recurse
            for i in range(len(children)):
                let child_id = children[i]
                if child_id >= 0 and child_id < self.widget_count:
                    self.layout_widget(child_id)
    
    fn find_widget_at_point(self, x: Int32, y: Int32, parent_id: Int32 = -1) -> Int32:
        """Find the topmost widget at the given point."""
        let start_id = parent_id if parent_id >= 0 else self.root_widget_id
        
        if start_id < 0 or start_id >= self.widget_count:
            return -1
        
        let widget = self.widgets[start_id]
        if not widget.visible or not widget.enabled:
            return -1
        
        let point = PointInt(x, y)
        if not widget.bounds.contains(point):
            return -1
        
        # Check children first (reverse order for z-order)
        for i in range(len(widget.children) - 1, -1, -1):
            let child_id = widget.children[i]
            let found = self.find_widget_at_point(x, y, child_id)
            if found >= 0:
                return found
        
        # If no child contains the point, return this widget
        return start_id
    
    fn handle_mouse_move(inout self, x: Int32, y: Int32):
        """Handle mouse movement."""
        # Handle dragging
        if self.dragging_widget_id >= 0:
            # Update dragged widget position
            self.widgets[self.dragging_widget_id].bounds.x = x - self.drag_offset_x
            self.widgets[self.dragging_widget_id].bounds.y = y - self.drag_offset_y
            self.mark_dirty(self.dragging_widget_id)
            return
        
        # Find widget under mouse
        let widget_id = self.find_widget_at_point(x, y)
        
        # Handle hover changes
        if widget_id != self.hovered_widget_id:
            # Leave previous widget
            if self.hovered_widget_id >= 0:
                # Trigger hover leave event
                self.mark_dirty(self.hovered_widget_id)
            
            # Enter new widget
            self.hovered_widget_id = widget_id
            if widget_id >= 0:
                # Trigger hover enter event
                self.mark_dirty(widget_id)
    
    fn handle_mouse_button(inout self, button: Int32, pressed: Bool, x: Int32, y: Int32):
        """Handle mouse button events."""
        let widget_id = self.find_widget_at_point(x, y)
        
        # CREATE AND DISPATCH MOUSE EVENT TO WIDGET
        if widget_id >= 0:
            # Create MouseEventInt object for the widget
            var mouse_event = MouseEventInt(x, y, button, pressed)
            
            # TODO: Dispatch to actual widget object's handle_mouse_event method
            # This requires access to the actual widget instances, not just registry entries
            # For now, we'll handle the core logic here
            
            if pressed:
                # Mark widget as receiving mouse press
                self.widgets[widget_id].focused = True
                print("🖱️  Widget " + String(widget_id) + " received mouse press at (" + String(x) + "," + String(y) + ")")
            else:
                # Handle mouse release - this could be a click
                print("🖱️  Widget " + String(widget_id) + " received mouse release - CLICK completed!")
        
        if pressed:
            # Set focus to clicked widget
            self.set_focus(widget_id)
            
            # Handle specific widget types
            if widget_id >= 0:
                let widget = self.widgets[widget_id]
                
                # Start dragging if it's a window title bar
                if widget.widget_type == WIDGET_WINDOW:
                    self.dragging_widget_id = widget_id
                    self.drag_offset_x = x - widget.bounds.x
                    self.drag_offset_y = y - widget.bounds.y
                
                # Trigger click callback
                if widget.on_click >= 0:
                    # Execute callback
                    pass
        else:
            # Stop dragging
            self.dragging_widget_id = -1
    
    fn handle_keyboard_input(inout self):
        """Handle keyboard input and dispatch to focused widget."""
        if self.focused_widget_id < 0:
            return
        
        # Check common keys using the event manager
        var keys_to_check = DynamicVector[Int32]()
        keys_to_check.append(32)   # Space
        keys_to_check.append(257)  # Enter
        keys_to_check.append(259)  # Backspace
        keys_to_check.append(261)  # Delete
        keys_to_check.append(265)  # Up arrow
        keys_to_check.append(264)  # Down arrow
        keys_to_check.append(263)  # Left arrow
        keys_to_check.append(262)  # Right arrow
        
        # Check A-Z keys (65-90)
        for i in range(26):
            keys_to_check.append(65 + i)
        
        # Check for key presses
        for i in range(len(keys_to_check)):
            let key_code = keys_to_check[i]
            if self.event_manager.is_key_pressed(self.ctx, key_code):
                # Create KeyEventInt and dispatch to focused widget
                var key_event = KeyEventInt(key_code, True)
                
                # TODO: Dispatch to actual widget object's handle_key_event method
                print("⌨️  Widget " + String(self.focused_widget_id) + " received key press: " + String(key_code))
                
                # For now, just mark the widget as receiving input
                self.mark_dirty(self.focused_widget_id)
    
    fn set_focus(inout self, widget_id: Int32):
        """Set keyboard focus to a widget."""
        if self.focused_widget_id == widget_id:
            return
        
        # Remove focus from previous widget
        if self.focused_widget_id >= 0:
            self.widgets[self.focused_widget_id].focused = False
            self.mark_dirty(self.focused_widget_id)
        
        # Set focus to new widget
        self.focused_widget_id = widget_id
        if widget_id >= 0:
            self.widgets[widget_id].focused = True
            self.mark_dirty(widget_id)
    
    fn handle_key(inout self, key_code: Int32, pressed: Bool):
        """Handle keyboard input."""
        # Send to focused widget
        if self.focused_widget_id >= 0:
            let widget = self.widgets[self.focused_widget_id]
            if widget.on_key >= 0:
                # Execute key callback
                pass
        
        # Handle tab navigation
        if pressed and key_code == 258:  # Tab key
            self.focus_next_widget()
    
    fn focus_next_widget(inout self):
        """Move focus to next widget in tab order."""
        # Simple implementation - just find next visible, enabled widget
        var start_id = self.focused_widget_id + 1 if self.focused_widget_id >= 0 else 0
        var found = False
        
        for i in range(self.widget_count):
            let widget_id = (start_id + i) % self.widget_count
            let widget = self.widgets[widget_id]
            
            if widget.visible and widget.enabled and widget.widget_type != WIDGET_PANEL:
                self.set_focus(widget_id)
                found = True
                break
        
        if not found:
            self.set_focus(-1)
    
    fn render_widget(self, widget_id: Int32):
        """Render a widget and its children."""
        if widget_id < 0 or widget_id >= self.widget_count:
            return
        
        let widget = self.widgets[widget_id]
        if not widget.visible:
            return
        
        # Render based on widget type
        if widget.widget_type == WIDGET_PANEL:
            self.render_panel(widget_id)
        elif widget.widget_type == WIDGET_BUTTON:
            self.render_button(widget_id)
        elif widget.widget_type == WIDGET_LABEL:
            self.render_label(widget_id)
        elif widget.widget_type == WIDGET_TEXTBOX:
            self.render_textbox(widget_id)
        # Add more widget types...
        
        # Render children
        for i in range(len(widget.children)):
            self.render_widget(widget.children[i])
    
    fn render_panel(self, widget_id: Int32):
        """Render a panel widget."""
        let widget = self.widgets[widget_id]
        
        # Background
        _ = self.ctx.set_color(240, 240, 240, 255)
        _ = self.ctx.draw_filled_rectangle(widget.bounds.x, widget.bounds.y,
                                          widget.bounds.width, widget.bounds.height)
        
        # Border
        _ = self.ctx.set_color(200, 200, 200, 255)
        _ = self.ctx.draw_rectangle(widget.bounds.x, widget.bounds.y,
                                   widget.bounds.width, widget.bounds.height)
    
    fn render_button(self, widget_id: Int32):
        """Render a button widget."""
        let widget = self.widgets[widget_id]
        
        # Determine button state
        var color_offset = 0
        if not widget.enabled:
            color_offset = -50
        elif widget_id == self.hovered_widget_id:
            color_offset = 20
        
        # Background
        _ = self.ctx.set_color(200 + color_offset, 200 + color_offset, 200 + color_offset, 255)
        _ = self.ctx.draw_filled_rectangle(widget.bounds.x, widget.bounds.y,
                                          widget.bounds.width, widget.bounds.height)
        
        # Border
        _ = self.ctx.set_color(100, 100, 100, 255)
        _ = self.ctx.draw_rectangle(widget.bounds.x, widget.bounds.y,
                                   widget.bounds.width, widget.bounds.height)
        
        # Focus indicator
        if widget.focused:
            _ = self.ctx.set_color(100, 150, 255, 255)
            _ = self.ctx.draw_rectangle(widget.bounds.x + 2, widget.bounds.y + 2,
                                       widget.bounds.width - 4, widget.bounds.height - 4)
    
    fn render_label(self, widget_id: Int32):
        """Render a label widget."""
        let widget = self.widgets[widget_id]
        
        # Just render text for now
        _ = self.ctx.set_color(0, 0, 0, 255)
        # Would call draw_text here with actual label text
    
    fn render_textbox(self, widget_id: Int32):
        """Render a textbox widget."""
        let widget = self.widgets[widget_id]
        
        # Background
        _ = self.ctx.set_color(255, 255, 255, 255)
        _ = self.ctx.draw_filled_rectangle(widget.bounds.x, widget.bounds.y,
                                          widget.bounds.width, widget.bounds.height)
        
        # Border
        let border_color = 100 if widget.focused else 200
        _ = self.ctx.set_color(border_color, border_color, border_color, 255)
        _ = self.ctx.draw_rectangle(widget.bounds.x, widget.bounds.y,
                                   widget.bounds.width, widget.bounds.height)
    
    fn update(inout self):
        """Update the GUI state."""
        # Poll events
        self.event_manager.update(self.ctx)
        
        # Handle mouse movement
        let mouse_pos = self.event_manager.get_mouse_position()
        if self.event_manager.mouse_moved():
            self.handle_mouse_move(mouse_pos.x, mouse_pos.y)
        
        # Handle mouse buttons (both press AND release with proper edge detection)
        if self.event_manager.is_mouse_button_just_pressed(0):
            self.handle_mouse_button(0, True, mouse_pos.x, mouse_pos.y)
        elif self.event_manager.is_mouse_button_just_released(0):
            self.handle_mouse_button(0, False, mouse_pos.x, mouse_pos.y)
        
        # Handle keyboard input
        if self.focused_widget_id >= 0:
            # Check common keys and dispatch to focused widget
            self.handle_keyboard_input()
        
        # Perform layout if needed
        self.perform_layout()
    
    fn render(self):
        """Render the entire GUI."""
        _ = self.ctx.frame_begin()
        
        # Clear background
        _ = self.ctx.set_color(30, 30, 30, 255)
        _ = self.ctx.draw_filled_rectangle(0, 0, self.ctx.width, self.ctx.height)
        
        # Render from root widget
        if self.root_widget_id >= 0:
            self.render_widget(self.root_widget_id)
        
        _ = self.ctx.frame_end()
    
    fn run(inout self):
        """Run the GUI main loop."""
        while not self.ctx.should_close_window():
            self.update()
            self.render()
    
    fn cleanup(inout self):
        """Clean up resources."""
        _ = self.ctx.cleanup()

# High-level widget creation helpers
fn create_window(inout gui: GUIOrchestrator, title: String, x: Int32, y: Int32, width: Int32, height: Int32) -> Int32:
    """Create a window widget."""
    let window_id = gui.create_widget(WIDGET_WINDOW)
    gui.set_widget_bounds(window_id, x, y, width, height)
    gui.set_widget_layout(window_id, LAYOUT_VERTICAL, 10, 5)
    gui.add_widget_to_parent(window_id, gui.root_widget_id)
    return window_id

fn create_button(inout gui: GUIOrchestrator, parent_id: Int32, text: String, x: Int32, y: Int32, width: Int32 = 100, height: Int32 = 30) -> Int32:
    """Create a button widget."""
    let button_id = gui.create_widget(WIDGET_BUTTON)
    gui.set_widget_bounds(button_id, x, y, width, height)
    gui.add_widget_to_parent(button_id, parent_id)
    return button_id

fn create_label(inout gui: GUIOrchestrator, parent_id: Int32, text: String, x: Int32, y: Int32) -> Int32:
    """Create a label widget."""
    let label_id = gui.create_widget(WIDGET_LABEL)
    gui.set_widget_bounds(label_id, x, y, 100, 20)
    gui.add_widget_to_parent(label_id, parent_id)
    return label_id

fn create_textbox(inout gui: GUIOrchestrator, parent_id: Int32, x: Int32, y: Int32, width: Int32 = 200, height: Int32 = 25) -> Int32:
    """Create a textbox widget."""
    let textbox_id = gui.create_widget(WIDGET_TEXTBOX)
    gui.set_widget_bounds(textbox_id, x, y, width, height)
    gui.add_widget_to_parent(textbox_id, parent_id)
    return textbox_id

# Example usage
fn main():
    """Example of using the orchestrator."""
    # Create the main GUI orchestrator
    var gui = GUIOrchestrator(800, 600, "MojoGUI Example")
    
    # Create a window
    let window = create_window(gui, "My Window", 50, 50, 400, 300)
    
    # Add some widgets
    let label = create_label(gui, window, "Name:", 10, 10)
    let textbox = create_textbox(gui, window, 60, 10)
    let button = create_button(gui, window, "Submit", 10, 50)
    
    # Run the GUI
    gui.run()
    
    # Cleanup
    gui.cleanup()