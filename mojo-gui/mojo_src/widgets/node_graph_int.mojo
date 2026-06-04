"""
Integer-Only NodeGraph Widget Implementation
Visual node-based editor for workflows and pipelines using integer coordinates.
Ported from EriGui Rust implementation.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .widget_constants import *

# Port types
comptime PORT_INPUT = 0
comptime PORT_OUTPUT = 1

# Field types
comptime FIELD_TEXT = 0
comptime FIELD_NUMBER = 1
comptime FIELD_SELECT = 2
comptime FIELD_FILEPATH = 3

# Interaction modes
comptime INTERACT_NONE = 0
comptime INTERACT_NODE_DRAG = 1
comptime INTERACT_NODE_RESIZE = 2
comptime INTERACT_LINK_DRAG = 3
comptime INTERACT_PAN = 4
comptime INTERACT_MARQUEE = 5

struct PortInt(Copyable, Movable):
    """Node port for connections."""
    var id: Int32
    var label: String
    var is_input: Bool
    var port_type: Int32  # For type validation

    fn __init__(out self, id: Int32, label: String, is_input: Bool):
        self.id = id
        self.label = label
        self.is_input = is_input
        self.port_type = 0

struct FieldInt(Copyable, Movable):
    """Editable field within a node."""
    var id: Int32
    var label: String
    var kind: Int32
    var value_text: String
    var value_number: Int32
    var value_select: Int32
    var options: List[String]
    var min_val: Int32
    var max_val: Int32
    var step: Int32

    fn __init__(out self, id: Int32, label: String, kind: Int32 = FIELD_TEXT):
        self.id = id
        self.label = label
        self.kind = kind
        self.value_text = ""
        self.value_number = 0
        self.value_select = 0
        self.options = List[String]()
        self.min_val = 0
        self.max_val = 100
        self.step = 1

struct NodeInt(Copyable, Movable):
    """A node in the graph."""
    var id: Int32
    var title: String
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
    var inputs: List[PortInt]
    var outputs: List[PortInt]
    var fields: List[FieldInt]
    var selected: Bool
    var collapsed: Bool
    var color: ColorInt

    fn __init__(out self, id: Int32, title: String, x: Int32, y: Int32):
        self.id = id
        self.title = title
        self.x = x
        self.y = y
        self.width = 180
        self.height = 100
        self.inputs = List[PortInt]()
        self.outputs = List[PortInt]()
        self.fields = List[FieldInt]()
        self.selected = False
        self.collapsed = False
        self.color = ColorInt(80, 100, 140, 255)

    fn add_input(mut self, id: Int32, label: String):
        self.inputs.append(PortInt(id, label, True))
        self._recalculate_height()

    fn add_output(mut self, id: Int32, label: String):
        self.outputs.append(PortInt(id, label, False))
        self._recalculate_height()

    fn add_field(mut self, field: FieldInt):
        self.fields.append(field)
        self._recalculate_height()

    fn _recalculate_height(mut self):
        """Recalculate node height based on content."""
        var header_height = 28
        var port_height = 20
        var field_height = 24
        var padding = 8

        var ports_height = max(len(self.inputs), len(self.outputs)) * port_height
        var fields_height = len(self.fields) * field_height

        self.height = Int32(header_height + ports_height + fields_height + padding * 2)

struct EdgeInt(Copyable, Movable):
    """Connection between two ports."""
    var from_node: Int32
    var from_port: Int32
    var to_node: Int32
    var to_port: Int32

    fn __init__(out self, from_node: Int32, from_port: Int32,
                to_node: Int32, to_port: Int32):
        self.from_node = from_node
        self.from_port = from_port
        self.to_node = to_node
        self.to_port = to_port

struct PortRef(Copyable, Movable):
    """Reference to a specific port."""
    var node_id: Int32
    var port_id: Int32
    var is_input: Bool

    fn __init__(out self, node_id: Int32, port_id: Int32, is_input: Bool):
        self.node_id = node_id
        self.port_id = port_id
        self.is_input = is_input

struct NodeGraphInt(Copyable, Movable):
    """Visual node graph editor widget."""

    # Widget identity / geometry (this widget uses x/y/width/height directly,
    # not BaseWidgetInt's RectInt bounds, so the base fields are inlined here).
    var id: Int32
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
    var visible: Bool
    var enabled: Bool

    # Graph data
    var nodes: List[NodeInt]
    var edges: List[EdgeInt]
    var next_node_id: Int32
    var next_port_id: Int32

    # View state
    var pan_x: Int32
    var pan_y: Int32
    var zoom: Int32  # Percentage (100 = 1.0)
    var show_grid: Bool

    # Interaction state
    var interaction_mode: Int32
    var drag_node_id: Int32
    var drag_start_x: Int32
    var drag_start_y: Int32
    var link_from_node: Int32
    var link_from_port: Int32
    var link_from_is_input: Bool
    var link_cursor_x: Int32
    var link_cursor_y: Int32

    # Selection
    var selected_nodes: List[Int32]
    var hovered_node: Int32
    var hovered_port_node: Int32
    var hovered_port_id: Int32
    var hovered_edge: Int32

    # Field editing
    var active_field_node: Int32
    var active_field_id: Int32
    var field_edit_text: String

    # Colors
    var background_color: ColorInt
    var grid_color: ColorInt
    var node_color: ColorInt
    var node_selected_color: ColorInt
    var port_color: ColorInt
    var port_hover_color: ColorInt
    var edge_color: ColorInt
    var text_color: ColorInt

    fn __init__(out self):
        self.id = 0
        self.x = 0
        self.y = 0
        self.width = 800
        self.height = 600
        self.visible = True
        self.enabled = True

        self.nodes = List[NodeInt]()
        self.edges = List[EdgeInt]()
        self.next_node_id = 1
        self.next_port_id = 1

        self.pan_x = 0
        self.pan_y = 0
        self.zoom = 100
        self.show_grid = True

        self.interaction_mode = INTERACT_NONE
        self.drag_node_id = -1
        self.drag_start_x = 0
        self.drag_start_y = 0
        self.link_from_node = -1
        self.link_from_port = -1
        self.link_from_is_input = False
        self.link_cursor_x = 0
        self.link_cursor_y = 0

        self.selected_nodes = List[Int32]()
        self.hovered_node = -1
        self.hovered_port_node = -1
        self.hovered_port_id = -1
        self.hovered_edge = -1

        self.active_field_node = -1
        self.active_field_id = -1
        self.field_edit_text = ""

        # Default dark theme colors
        self.background_color = ColorInt(30, 30, 35, 255)
        self.grid_color = ColorInt(50, 50, 55, 255)
        self.node_color = ColorInt(60, 65, 80, 255)
        self.node_selected_color = ColorInt(80, 120, 180, 255)
        self.port_color = ColorInt(120, 140, 180, 255)
        self.port_hover_color = ColorInt(180, 200, 255, 255)
        self.edge_color = ColorInt(140, 160, 200, 255)
        self.text_color = ColorInt(220, 225, 235, 255)

    fn add_node(mut self, title: String, x: Int32, y: Int32) -> Int32:
        """Add a new node and return its ID."""
        var node = NodeInt(self.next_node_id, title, x, y)
        var node_id = self.next_node_id
        self.next_node_id += 1
        self.nodes.append(node)
        return node_id

    fn add_node_input(mut self, node_id: Int32, label: String) -> Int32:
        """Add an input port to a node."""
        for i in range(len(self.nodes)):
            if self.nodes[i].id == node_id:
                var port_id = self.next_port_id
                self.next_port_id += 1
                self.nodes[i].add_input(port_id, label)
                return port_id
        return -1

    fn add_node_output(mut self, node_id: Int32, label: String) -> Int32:
        """Add an output port to a node."""
        for i in range(len(self.nodes)):
            if self.nodes[i].id == node_id:
                var port_id = self.next_port_id
                self.next_port_id += 1
                self.nodes[i].add_output(port_id, label)
                return port_id
        return -1

    fn add_node_field(mut self, node_id: Int32, label: String,
                      kind: Int32 = FIELD_TEXT) -> Int32:
        """Add a field to a node."""
        for i in range(len(self.nodes)):
            if self.nodes[i].id == node_id:
                var field_id = self.next_port_id
                self.next_port_id += 1
                var field = FieldInt(field_id, label, kind)
                self.nodes[i].add_field(field)
                return field_id
        return -1

    fn connect(mut self, from_node: Int32, from_port: Int32,
               to_node: Int32, to_port: Int32) -> Bool:
        """Connect two ports with an edge."""
        # Validate connection
        if from_node == to_node:
            return False

        # Check for duplicate
        for i in range(len(self.edges)):
            var edge = self.edges[i]
            if edge.from_node == from_node and edge.from_port == from_port:
                if edge.to_node == to_node and edge.to_port == to_port:
                    return False

        self.edges.append(EdgeInt(from_node, from_port, to_node, to_port))
        return True

    fn disconnect(mut self, edge_index: Int32):
        """Remove an edge by index."""
        if edge_index >= 0 and edge_index < len(self.edges):
            # Remove edge at index (swap with last and pop)
            var last = len(self.edges) - 1
            if edge_index != last:
                self.edges[edge_index] = self.edges[last]
            _ = self.edges.pop()

    fn delete_selected_nodes(mut self):
        """Delete all selected nodes and their edges."""
        # Remove edges connected to selected nodes
        var i = len(self.edges) - 1
        while i >= 0:
            var edge = self.edges[i]
            var should_remove = False
            for j in range(len(self.selected_nodes)):
                if edge.from_node == self.selected_nodes[j]:
                    should_remove = True
                    break
                if edge.to_node == self.selected_nodes[j]:
                    should_remove = True
                    break
            if should_remove:
                self.disconnect(i)
            i -= 1

        # Remove selected nodes
        i = len(self.nodes) - 1
        while i >= 0:
            var should_remove = False
            for j in range(len(self.selected_nodes)):
                if self.nodes[i].id == self.selected_nodes[j]:
                    should_remove = True
                    break
            if should_remove:
                # Swap with last and pop
                var last = len(self.nodes) - 1
                if i != last:
                    self.nodes[i] = self.nodes[last]
                _ = self.nodes.pop()
            i -= 1

        self.selected_nodes.clear()

    fn screen_to_world(self, screen_x: Int32, screen_y: Int32) -> Tuple[Int32, Int32]:
        """Convert screen coordinates to world coordinates."""
        var world_x = (screen_x - self.x - self.pan_x) * 100 // self.zoom
        var world_y = (screen_y - self.y - self.pan_y) * 100 // self.zoom
        return Tuple[Int32, Int32](world_x, world_y)

    fn world_to_screen(self, world_x: Int32, world_y: Int32) -> Tuple[Int32, Int32]:
        """Convert world coordinates to screen coordinates."""
        var screen_x = world_x * self.zoom // 100 + self.pan_x + self.x
        var screen_y = world_y * self.zoom // 100 + self.pan_y + self.y
        return Tuple[Int32, Int32](screen_x, screen_y)

    fn node_at(self, world_x: Int32, world_y: Int32) -> Int32:
        """Find node at world position. Returns node ID or -1."""
        # Check in reverse order (top nodes first)
        var i = len(self.nodes) - 1
        while i >= 0:
            var node = self.nodes[i]
            if world_x >= node.x and world_x < node.x + node.width:
                if world_y >= node.y and world_y < node.y + node.height:
                    return node.id
            i -= 1
        return -1

    fn get_port_position(self, node_id: Int32, port_id: Int32,
                         is_input: Bool) -> Tuple[Int32, Int32]:
        """Get the screen position of a port."""
        for i in range(len(self.nodes)):
            var node = self.nodes[i]
            if node.id == node_id:
                var port_y = node.y + 28 + 10  # Header + padding

                if is_input:
                    for j in range(len(node.inputs)):
                        if node.inputs[j].id == port_id:
                            port_y += Int32(j * 20)
                            return self.world_to_screen(node.x, port_y)
                else:
                    for j in range(len(node.outputs)):
                        if node.outputs[j].id == port_id:
                            port_y += Int32(j * 20)
                            return self.world_to_screen(node.x + node.width, port_y)
        return Tuple[Int32, Int32](0, 0)

    fn select_node(mut self, node_id: Int32, add_to_selection: Bool = False):
        """Select a node."""
        if not add_to_selection:
            self.selected_nodes.clear()
            # Deselect all
            for i in range(len(self.nodes)):
                self.nodes[i].selected = False

        # Select the node
        for i in range(len(self.nodes)):
            if self.nodes[i].id == node_id:
                self.nodes[i].selected = True
                # Add to selection list if not already there
                var found = False
                for j in range(len(self.selected_nodes)):
                    if self.selected_nodes[j] == node_id:
                        found = True
                        break
                if not found:
                    self.selected_nodes.append(node_id)
                break

    fn clear_selection(mut self):
        """Clear all selection."""
        for i in range(len(self.nodes)):
            self.nodes[i].selected = False
        self.selected_nodes.clear()

    fn handle_mouse_event(mut self, event: MouseEventInt) -> Bool:
        """Handle mouse input."""
        var world = self.screen_to_world(event.x, event.y)
        var world_x = world[0]
        var world_y = world[1]

        if event.event_type == 1:  # Mouse down
            if event.button == 0:  # Left button
                var node_id = self.node_at(world_x, world_y)
                if node_id >= 0:
                    # Start dragging node
                    self.select_node(node_id, event.shift_held)
                    self.interaction_mode = INTERACT_NODE_DRAG
                    self.drag_node_id = node_id
                    self.drag_start_x = world_x
                    self.drag_start_y = world_y
                    return True
                else:
                    # Start panning
                    self.clear_selection()
                    self.interaction_mode = INTERACT_PAN
                    self.drag_start_x = event.x
                    self.drag_start_y = event.y
                    return True

            elif event.button == 2:  # Right button
                # Could show context menu here
                return True

        elif event.event_type == 2:  # Mouse up
            if self.interaction_mode == INTERACT_LINK_DRAG:
                # Try to complete connection
                if self.hovered_port_node >= 0:
                    if self.link_from_is_input:
                        _ = self.connect(self.hovered_port_node, self.hovered_port_id,
                                    self.link_from_node, self.link_from_port)
                    else:
                        _ = self.connect(self.link_from_node, self.link_from_port,
                                    self.hovered_port_node, self.hovered_port_id)

            self.interaction_mode = INTERACT_NONE
            self.drag_node_id = -1
            return True

        elif event.event_type == 3:  # Mouse move
            self.hovered_node = self.node_at(world_x, world_y)

            if self.interaction_mode == INTERACT_NODE_DRAG:
                # Move selected nodes
                var dx = world_x - self.drag_start_x
                var dy = world_y - self.drag_start_y
                for i in range(len(self.nodes)):
                    if self.nodes[i].selected:
                        self.nodes[i].x += dx
                        self.nodes[i].y += dy
                self.drag_start_x = world_x
                self.drag_start_y = world_y
                return True

            elif self.interaction_mode == INTERACT_PAN:
                var dx = event.x - self.drag_start_x
                var dy = event.y - self.drag_start_y
                self.pan_x += dx
                self.pan_y += dy
                self.drag_start_x = event.x
                self.drag_start_y = event.y
                return True

            elif self.interaction_mode == INTERACT_LINK_DRAG:
                self.link_cursor_x = event.x
                self.link_cursor_y = event.y
                return True

        return False

    fn handle_key_event(mut self, event: KeyEventInt) -> Bool:
        """Handle keyboard input."""
        if event.event_type == 1:  # Key down
            if event.key_code == 127 or event.key_code == 8:  # Delete/Backspace
                self.delete_selected_nodes()
                return True
            elif event.key_code == Int32(ord("G")) or event.key_code == Int32(ord("g")):
                self.show_grid = not self.show_grid
                return True
        return False

    fn draw(self, ctx: RenderingContextInt):
        """Draw the node graph."""
        # Draw background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.x, self.y, self.width, self.height)

        # Draw grid
        if self.show_grid:
            self._draw_grid(ctx)

        # Draw edges
        for i in range(len(self.edges)):
            self._draw_edge(ctx, self.edges[i])

        # Draw dragging link
        if self.interaction_mode == INTERACT_LINK_DRAG:
            var start = self.get_port_position(self.link_from_node,
                                               self.link_from_port,
                                               self.link_from_is_input)
            self._draw_bezier(ctx, start[0], start[1],
                             self.link_cursor_x, self.link_cursor_y,
                             self.edge_color)

        # Draw nodes
        for i in range(len(self.nodes)):
            self._draw_node(ctx, self.nodes[i])

    fn _draw_grid(self, ctx: RenderingContextInt):
        """Draw background grid."""
        var grid_size = 20 * self.zoom // 100
        if grid_size < 10:
            grid_size = 10

        var start_x = self.x + (self.pan_x % grid_size)
        var start_y = self.y + (self.pan_y % grid_size)

        _ = ctx.set_color(self.grid_color.r, self.grid_color.g,
                         self.grid_color.b, self.grid_color.a)

        var x = start_x
        while x < self.x + self.width:
            _ = ctx.draw_line(x, self.y, x, self.y + self.height)
            x += grid_size

        var y = start_y
        while y < self.y + self.height:
            _ = ctx.draw_line(self.x, y, self.x + self.width, y)
            y += grid_size

    fn _draw_node(self, ctx: RenderingContextInt, node: NodeInt):
        """Draw a single node."""
        var screen = self.world_to_screen(node.x, node.y)
        var sx = screen[0]
        var sy = screen[1]
        var sw = node.width * self.zoom // 100
        var sh = node.height * self.zoom // 100

        # Node background
        var bg_color = self.node_selected_color if node.selected else self.node_color
        _ = ctx.set_color(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
        _ = ctx.draw_filled_rectangle(sx, sy, sw, sh)

        # Node border
        if node.selected:
            _ = ctx.set_color(100, 120, 160, 255)
        else:
            _ = ctx.set_color(80, 90, 110, 255)
        _ = ctx.draw_rectangle(sx, sy, sw, sh)

        # Header
        var header_height = 24 * self.zoom // 100
        _ = ctx.set_color(node.color.r, node.color.g, node.color.b, node.color.a)
        _ = ctx.draw_filled_rectangle(sx, sy, sw, header_height)

        # Title
        _ = ctx.set_color(self.text_color.r, self.text_color.g,
                         self.text_color.b, self.text_color.a)
        _ = ctx.draw_text(node.title, sx + 8, sy + 4, 12)

        # Draw ports
        var port_y = sy + header_height + 8
        var port_radius = 6 * self.zoom // 100

        # Input ports
        for i in range(len(node.inputs)):
            var port = node.inputs[i]
            var py = port_y + i * 20 * self.zoom // 100
            _ = ctx.set_color(self.port_color.r, self.port_color.g,
                             self.port_color.b, self.port_color.a)
            _ = ctx.draw_filled_circle(sx, py, port_radius)
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
            _ = ctx.draw_text(port.label, sx + port_radius + 4, py - 6, 10)

        # Output ports
        for i in range(len(node.outputs)):
            var port = node.outputs[i]
            var py = port_y + i * 20 * self.zoom // 100
            _ = ctx.set_color(self.port_color.r, self.port_color.g,
                             self.port_color.b, self.port_color.a)
            _ = ctx.draw_filled_circle(sx + sw, py, port_radius)
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
            var text_width = len(port.label) * 6
            _ = ctx.draw_text(port.label, sx + sw - text_width - port_radius - 4, py - 6, 10)

        # Draw fields
        var field_y = port_y + max(len(node.inputs), len(node.outputs)) * 20 * self.zoom // 100
        for i in range(len(node.fields)):
            var field = node.fields[i]
            var fy = field_y + i * 24 * self.zoom // 100

            # Field label
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
            _ = ctx.draw_text(field.label, sx + 8, fy, 10)

            # Field value box
            var box_x = sx + 8
            var box_y = fy + 12
            var box_w = sw - 16
            var box_h = 18 * self.zoom // 100
            _ = ctx.set_color(40, 45, 55, 255)
            _ = ctx.draw_filled_rectangle(box_x, box_y, box_w, box_h)
            _ = ctx.set_color(70, 80, 100, 255)
            _ = ctx.draw_rectangle(box_x, box_y, box_w, box_h)

            # Field value text
            _ = ctx.set_color(self.text_color.r, self.text_color.g,
                             self.text_color.b, self.text_color.a)
            _ = ctx.draw_text(field.value_text, box_x + 4, box_y + 2, 10)

    fn _draw_edge(self, ctx: RenderingContextInt, edge: EdgeInt):
        """Draw a connection edge."""
        var start = self.get_port_position(edge.from_node, edge.from_port, False)
        var end = self.get_port_position(edge.to_node, edge.to_port, True)
        self._draw_bezier(ctx, start[0], start[1], end[0], end[1], self.edge_color)

    fn _draw_bezier(self, ctx: RenderingContextInt,
                    x1: Int32, y1: Int32, x2: Int32, y2: Int32,
                    color: ColorInt):
        """Draw a bezier curve between two points."""
        # Set the color for all line segments
        _ = ctx.set_color(color.r, color.g, color.b, color.a)

        # Simple bezier approximation with line segments
        var dx = abs(x2 - x1) // 2
        if dx < 50:
            dx = 50

        var cx1 = x1 + dx
        var cy1 = y1
        var cx2 = x2 - dx
        var cy2 = y2

        var segments = 20
        var prev_x = x1
        var prev_y = y1

        for i in range(1, segments + 1):
            var t = i * 100 // segments
            var t2 = t * t // 100
            var t3 = t2 * t // 100
            var mt = 100 - t
            var mt2 = mt * mt // 100
            var mt3 = mt2 * mt // 100

            # Cubic bezier formula (scaled for integer math)
            var bx = (mt3 * x1 + 3 * mt2 * t * cx1 // 100 +
                     3 * mt * t2 * cx2 // 100 + t3 * x2) // 100
            var by = (mt3 * y1 + 3 * mt2 * t * cy1 // 100 +
                     3 * mt * t2 * cy2 // 100 + t3 * y2) // 100

            _ = ctx.draw_line(prev_x, prev_y, bx, by)
            prev_x = bx
            prev_y = by


fn create_node_graph_int(x: Int32, y: Int32, width: Int32, height: Int32) -> NodeGraphInt:
    """Factory function to create a NodeGraph widget."""
    var graph = NodeGraphInt()
    graph.x = x
    graph.y = y
    graph.width = width
    graph.height = height
    return graph
