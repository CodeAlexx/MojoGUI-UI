"""
Integer-Only TreeView Widget Implementation
Hierarchical tree view widget for navigation and data display.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt
from .widget_constants import *
from .scrollbar_int import ScrollBarInt

# Tree node states
alias NODE_COLLAPSED = 0
alias NODE_EXPANDED = 1
alias NODE_EXPANDING = 2  # For animation

# Tree node types
alias NODE_FOLDER = 0
alias NODE_FILE = 1
alias NODE_CATEGORY = 2

struct TreeNode:
    """Individual tree node."""
    var id: Int32
    var parent_id: Int32
    var text: String
    var icon: String
    var node_type: Int32
    var state: Int32
    var level: Int32
    var children: List[Int32]  # Child node IDs
    var is_selected: Bool
    var is_visible: Bool
    var data: Int32  # User data
    var icon_color: ColorInt
    
    fn __init__(inout self, id: Int32, text: String, node_type: Int32 = NODE_FOLDER):
        self.id = id
        self.parent_id = -1
        self.text = text
        self.icon = ""
        self.node_type = node_type
        self.state = NODE_COLLAPSED
        self.level = 0
        self.children = List[Int32]()
        self.is_selected = False
        self.is_visible = True
        self.data = 0
        self.icon_color = ColorInt(255, 255, 255, 255)
    
    fn add_child(inout self, child_id: Int32):
        """Add a child node ID."""
        self.children.append(child_id)
    
    fn remove_child(inout self, child_id: Int32):
        """Remove a child node ID."""
        # Find and remove child
        for i in range(len(self.children)):
            if self.children[i] == child_id:
                self.children.remove(i)
                break
    
    fn has_children(self) -> Bool:
        """Check if node has children."""
        return len(self.children) > 0
    
    fn is_expanded(self) -> Bool:
        """Check if node is expanded."""
        return self.state == NODE_EXPANDED

struct TreeViewInt(BaseWidgetInt):
    """Hierarchical tree view widget."""
    
    var nodes: List[TreeNode]
    var root_nodes: List[Int32]  # Root level node IDs
    var next_node_id: Int32
    var selected_node: Int32
    var hover_node: Int32
    var focused_node: Int32
    
    # Display settings
    var row_height: Int32
    var indent_width: Int32
    var icon_size: Int32
    var expand_icon_size: Int32
    var font_size: Int32
    var show_icons: Bool
    var show_lines: Bool
    var show_root_lines: Bool
    var animate_expand: Bool
    
    # Scrolling
    var scroll_offset: Int32
    var visible_nodes: List[Int32]  # Currently visible node IDs
    var v_scrollbar: ScrollBarInt
    var h_scrollbar: ScrollBarInt
    var content_height: Int32
    var max_width: Int32
    
    # Colors
    var text_color: ColorInt
    var selected_bg_color: ColorInt
    var selected_text_color: ColorInt
    var hover_bg_color: ColorInt
    var line_color: ColorInt
    var expand_icon_color: ColorInt
    
    # Interaction
    var is_dragging: Bool
    var drag_node: Int32
    var drop_target_node: Int32
    var multi_select: Bool
    var selected_nodes: List[Int32]
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32):
        self.super().__init__(x, y, width, height)
        
        self.nodes = List[TreeNode]()
        self.root_nodes = List[Int32]()
        self.next_node_id = 0
        self.selected_node = -1
        self.hover_node = -1
        self.focused_node = -1
        
        # Display settings
        self.row_height = 24
        self.indent_width = 20
        self.icon_size = 16
        self.expand_icon_size = 12
        self.font_size = 12
        self.show_icons = True
        self.show_lines = True
        self.show_root_lines = False
        self.animate_expand = True
        
        # Scrolling
        self.scroll_offset = 0
        self.visible_nodes = List[Int32]()
        self.v_scrollbar = ScrollBarInt(x + width - 15, y, 15, height, False)
        self.h_scrollbar = ScrollBarInt(x, y + height - 15, width - 15, 15, True)
        self.content_height = 0
        self.max_width = 0
        
        # Colors
        self.text_color = ColorInt(0, 0, 0, 255)
        self.selected_bg_color = ColorInt(51, 153, 255, 255)
        self.selected_text_color = ColorInt(255, 255, 255, 255)
        self.hover_bg_color = ColorInt(230, 240, 250, 255)
        self.line_color = ColorInt(200, 200, 200, 255)
        self.expand_icon_color = ColorInt(100, 100, 100, 255)
        
        # Interaction
        self.is_dragging = False
        self.drag_node = -1
        self.drop_target_node = -1
        self.multi_select = False
        self.selected_nodes = List[Int32]()
        
        # Set appearance
        self.background_color = ColorInt(255, 255, 255, 255)
        self.border_color = ColorInt(200, 200, 200, 255)
        self.border_width = 1
    
    fn add_node(inout self, text: String, parent_id: Int32 = -1, 
                node_type: Int32 = NODE_FOLDER) -> Int32:
        """Add a new node to the tree."""
        var node = TreeNode(self.next_node_id, text, node_type)
        node.parent_id = parent_id
        
        # Set level based on parent
        if parent_id >= 0:
            let parent_idx = self.find_node_index(parent_id)
            if parent_idx >= 0:
                node.level = self.nodes[parent_idx].level + 1
                self.nodes[parent_idx].add_child(node.id)
        else:
            self.root_nodes.append(node.id)
        
        # Set default icon based on type
        if node_type == NODE_FOLDER:
            node.icon = "folder"
            node.icon_color = ColorInt(255, 200, 0, 255)  # Yellow folder
        elif node_type == NODE_FILE:
            node.icon = "file"
            node.icon_color = ColorInt(200, 200, 200, 255)  # Gray file
        elif node_type == NODE_CATEGORY:
            node.icon = "category"
            node.icon_color = ColorInt(100, 100, 100, 255)
        
        self.nodes.append(node)
        self.next_node_id += 1
        
        self.update_visible_nodes()
        return node.id
    
    fn remove_node(inout self, node_id: Int32):
        """Remove a node and all its children."""
        let node_idx = self.find_node_index(node_id)
        if node_idx < 0:
            return
        
        let node = self.nodes[node_idx]
        
        # Remove from parent's children
        if node.parent_id >= 0:
            let parent_idx = self.find_node_index(node.parent_id)
            if parent_idx >= 0:
                self.nodes[parent_idx].remove_child(node_id)
        else:
            # Remove from root nodes
            for i in range(len(self.root_nodes)):
                if self.root_nodes[i] == node_id:
                    self.root_nodes.remove(i)
                    break
        
        # Remove all children recursively
        let children = node.children.copy()  # Copy to avoid modification during iteration
        for child_id in children:
            self.remove_node(child_id)
        
        # Remove the node itself
        self.nodes.remove(node_idx)
        
        # Update selection if needed
        if self.selected_node == node_id:
            self.selected_node = -1
        
        self.update_visible_nodes()
    
    fn expand_node(inout self, node_id: Int32, expand: Bool = True):
        """Expand or collapse a node."""
        let node_idx = self.find_node_index(node_id)
        if node_idx < 0:
            return
        
        if expand:
            self.nodes[node_idx].state = NODE_EXPANDED
        else:
            self.nodes[node_idx].state = NODE_COLLAPSED
        
        self.update_visible_nodes()
    
    fn expand_all(inout self):
        """Expand all nodes."""
        for i in range(len(self.nodes)):
            if self.nodes[i].has_children():
                self.nodes[i].state = NODE_EXPANDED
        self.update_visible_nodes()
    
    fn collapse_all(inout self):
        """Collapse all nodes."""
        for i in range(len(self.nodes)):
            if self.nodes[i].has_children():
                self.nodes[i].state = NODE_COLLAPSED
        self.update_visible_nodes()
    
    fn select_node(inout self, node_id: Int32):
        """Select a node."""
        if self.multi_select:
            # Toggle selection in multi-select mode
            var found = False
            for i in range(len(self.selected_nodes)):
                if self.selected_nodes[i] == node_id:
                    self.selected_nodes.remove(i)
                    found = True
                    break
            
            if not found:
                self.selected_nodes.append(node_id)
        else:
            # Single selection
            self.selected_node = node_id
            self.selected_nodes.clear()
            if node_id >= 0:
                self.selected_nodes.append(node_id)
        
        # Update node selection states
        for i in range(len(self.nodes)):
            self.nodes[i].is_selected = False
            for selected_id in self.selected_nodes:
                if self.nodes[i].id == selected_id:
                    self.nodes[i].is_selected = True
                    break
    
    fn find_node_index(self, node_id: Int32) -> Int32:
        """Find node index by ID."""
        for i in range(len(self.nodes)):
            if self.nodes[i].id == node_id:
                return i
        return -1
    
    fn get_node_at_point(self, point: PointInt) -> Int32:
        """Get node ID at given point."""
        if not self.contains_point(point):
            return -1
        
        let y_offset = point.y - self.bounds.y - self.scroll_offset
        let row = y_offset // self.row_height
        
        if row >= 0 and row < len(self.visible_nodes):
            return self.visible_nodes[row]
        
        return -1
    
    fn update_visible_nodes(inout self):
        """Update list of visible nodes based on expansion state."""
        self.visible_nodes.clear()
        self.content_height = 0
        self.max_width = 0
        
        # Add root nodes
        for root_id in self.root_nodes:
            self.add_visible_node_recursive(root_id)
        
        # Update scrollbar
        let visible_height = self.bounds.height - 15  # Minus scrollbar
        self.v_scrollbar.set_range(0, max(0, self.content_height - visible_height))
        self.v_scrollbar.set_page_size(visible_height // self.row_height)
    
    fn add_visible_node_recursive(inout self, node_id: Int32):
        """Recursively add visible nodes."""
        let node_idx = self.find_node_index(node_id)
        if node_idx < 0:
            return
        
        let node = self.nodes[node_idx]
        if not node.is_visible:
            return
        
        # Add to visible list
        self.visible_nodes.append(node_id)
        self.content_height += self.row_height
        
        # Calculate width
        let node_width = node.level * self.indent_width + 
                        self.expand_icon_size + 8 +
                        (self.icon_size + 4 if self.show_icons else 0) +
                        len(node.text) * 7  # Approximate text width
        self.max_width = max(self.max_width, node_width)
        
        # Add children if expanded
        if node.is_expanded() and node.has_children():
            for child_id in node.children:
                self.add_visible_node_recursive(child_id)
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events."""
        if not self.visible or not self.enabled:
            return False
        
        # Check scrollbars first
        if self.v_scrollbar.handle_mouse_event(event):
            self.scroll_offset = self.v_scrollbar.get_value() * self.row_height
            return True
        
        if self.h_scrollbar.handle_mouse_event(event):
            return True
        
        let point = PointInt(event.x, event.y)
        if not self.contains_point(point):
            return False
        
        let node_id = self.get_node_at_point(point)
        
        if event.pressed:
            if node_id >= 0:
                let node_idx = self.find_node_index(node_id)
                if node_idx >= 0:
                    let node = self.nodes[node_idx]
                    
                    # Check if clicking on expand/collapse icon
                    let icon_x = self.bounds.x + node.level * self.indent_width + 4
                    let icon_rect = RectInt(icon_x, 
                                           self.bounds.y + self.get_node_y(node_id) - self.scroll_offset,
                                           self.expand_icon_size, self.row_height)
                    
                    if node.has_children() and icon_rect.contains(point):
                        # Toggle expansion
                        self.expand_node(node_id, not node.is_expanded())
                    else:
                        # Select node
                        self.select_node(node_id)
                        
                        # Start drag if enabled
                        if self.is_dragging_enabled():
                            self.is_dragging = True
                            self.drag_node = node_id
                
                return True
        else:
            # Handle drag and drop
            if self.is_dragging:
                if node_id >= 0 and node_id != self.drag_node:
                    # Drop on target
                    self.handle_drop(self.drag_node, node_id)
                
                self.is_dragging = False
                self.drag_node = -1
                self.drop_target_node = -1
        
        # Update hover
        self.hover_node = node_id
        
        # Update drop target during drag
        if self.is_dragging:
            self.drop_target_node = node_id
        
        return True
    
    fn handle_drop(inout self, source_id: Int32, target_id: Int32):
        """Handle drop operation."""
        # Implementation would move source node to target
        # This is simplified - real implementation would validate the move
        let source_idx = self.find_node_index(source_id)
        let target_idx = self.find_node_index(target_id)
        
        if source_idx >= 0 and target_idx >= 0:
            # Remove from old parent
            let source_node = self.nodes[source_idx]
            if source_node.parent_id >= 0:
                let old_parent_idx = self.find_node_index(source_node.parent_id)
                if old_parent_idx >= 0:
                    self.nodes[old_parent_idx].remove_child(source_id)
            else:
                # Remove from root
                for i in range(len(self.root_nodes)):
                    if self.root_nodes[i] == source_id:
                        self.root_nodes.remove(i)
                        break
            
            # Add to new parent
            self.nodes[source_idx].parent_id = target_id
            self.nodes[source_idx].level = self.nodes[target_idx].level + 1
            self.nodes[target_idx].add_child(source_id)
            
            # Update children levels recursively
            self.update_node_levels_recursive(source_id)
            
            self.update_visible_nodes()
    
    fn update_node_levels_recursive(inout self, node_id: Int32):
        """Update node levels recursively."""
        let node_idx = self.find_node_index(node_id)
        if node_idx < 0:
            return
        
        let node = self.nodes[node_idx]
        
        # Update children
        for child_id in node.children:
            let child_idx = self.find_node_index(child_id)
            if child_idx >= 0:
                self.nodes[child_idx].level = node.level + 1
                self.update_node_levels_recursive(child_id)
    
    fn get_node_y(self, node_id: Int32) -> Int32:
        """Get Y position of node."""
        for i in range(len(self.visible_nodes)):
            if self.visible_nodes[i] == node_id:
                return i * self.row_height
        return 0
    
    fn is_dragging_enabled(self) -> Bool:
        """Check if drag and drop is enabled."""
        return True  # Could be made configurable
    
    fn handle_key_event(inout self, event: KeyEventInt) -> Bool:
        """Handle keyboard navigation."""
        if not self.visible or not self.enabled or not self.is_focused:
            return False
        
        if not event.pressed:
            return False
        
        if self.selected_node < 0 and len(self.visible_nodes) > 0:
            # Select first node if none selected
            self.select_node(self.visible_nodes[0])
            return True
        
        let selected_idx = -1
        for i in range(len(self.visible_nodes)):
            if self.visible_nodes[i] == self.selected_node:
                selected_idx = i
                break
        
        if selected_idx < 0:
            return False
        
        if event.key_code == KEY_UP:
            # Move selection up
            if selected_idx > 0:
                self.select_node(self.visible_nodes[selected_idx - 1])
                self.ensure_node_visible(self.selected_node)
            return True
        elif event.key_code == KEY_DOWN:
            # Move selection down
            if selected_idx < len(self.visible_nodes) - 1:
                self.select_node(self.visible_nodes[selected_idx + 1])
                self.ensure_node_visible(self.selected_node)
            return True
        elif event.key_code == KEY_LEFT:
            # Collapse node or move to parent
            let node_idx = self.find_node_index(self.selected_node)
            if node_idx >= 0:
                let node = self.nodes[node_idx]
                if node.is_expanded() and node.has_children():
                    self.expand_node(self.selected_node, False)
                elif node.parent_id >= 0:
                    self.select_node(node.parent_id)
                    self.ensure_node_visible(self.selected_node)
            return True
        elif event.key_code == KEY_RIGHT:
            # Expand node or move to first child
            let node_idx = self.find_node_index(self.selected_node)
            if node_idx >= 0:
                let node = self.nodes[node_idx]
                if not node.is_expanded() and node.has_children():
                    self.expand_node(self.selected_node, True)
                elif node.is_expanded() and len(node.children) > 0:
                    self.select_node(node.children[0])
                    self.ensure_node_visible(self.selected_node)
            return True
        elif event.key_code == KEY_ENTER or event.key_code == KEY_SPACE:
            # Toggle expansion
            let node_idx = self.find_node_index(self.selected_node)
            if node_idx >= 0:
                let node = self.nodes[node_idx]
                if node.has_children():
                    self.expand_node(self.selected_node, not node.is_expanded())
            return True
        
        return False
    
    fn ensure_node_visible(inout self, node_id: Int32):
        """Ensure node is visible by scrolling if needed."""
        let y = self.get_node_y(node_id)
        let visible_start = self.scroll_offset
        let visible_end = self.scroll_offset + self.bounds.height - 15
        
        if y < visible_start:
            self.scroll_offset = y
            self.v_scrollbar.set_value(y // self.row_height)
        elif y + self.row_height > visible_end:
            self.scroll_offset = y + self.row_height - (self.bounds.height - 15)
            self.v_scrollbar.set_value(self.scroll_offset // self.row_height)
    
    fn render(self, ctx: RenderingContextInt):
        """Render the tree view."""
        if not self.visible:
            return
        
        # Background
        _ = ctx.set_color(self.background_color.r, self.background_color.g,
                         self.background_color.b, self.background_color.a)
        _ = ctx.draw_filled_rectangle(self.bounds.x, self.bounds.y,
                                     self.bounds.width, self.bounds.height)
        
        # Set clipping area (would need proper clipping support)
        let content_width = self.bounds.width - 15
        let content_height = self.bounds.height - 15
        
        # Render visible nodes
        let start_row = self.scroll_offset // self.row_height
        let end_row = min(start_row + content_height // self.row_height + 1, 
                         len(self.visible_nodes))
        
        for i in range(start_row, end_row):
            if i < len(self.visible_nodes):
                self.render_node(ctx, self.visible_nodes[i], i - start_row)
        
        # Render drop indicator during drag
        if self.is_dragging and self.drop_target_node >= 0:
            self.render_drop_indicator(ctx, self.drop_target_node)
        
        # Scrollbars
        self.v_scrollbar.render(ctx)
        if self.max_width > content_width:
            self.h_scrollbar.render(ctx)
        
        # Border
        _ = ctx.set_color(self.border_color.r, self.border_color.g,
                         self.border_color.b, self.border_color.a)
        _ = ctx.draw_rectangle(self.bounds.x, self.bounds.y,
                              self.bounds.width, self.bounds.height)
    
    fn render_node(self, ctx: RenderingContextInt, node_id: Int32, row: Int32):
        """Render a single node."""
        let node_idx = self.find_node_index(node_id)
        if node_idx < 0:
            return
        
        let node = self.nodes[node_idx]
        let y = self.bounds.y + row * self.row_height
        let x = self.bounds.x + node.level * self.indent_width
        
        # Selection/hover background
        if node.is_selected:
            _ = ctx.set_color(self.selected_bg_color.r, self.selected_bg_color.g,
                             self.selected_bg_color.b, self.selected_bg_color.a)
            _ = ctx.draw_filled_rectangle(self.bounds.x, y, self.bounds.width - 15, self.row_height)
        elif node_id == self.hover_node:
            _ = ctx.set_color(self.hover_bg_color.r, self.hover_bg_color.g,
                             self.hover_bg_color.b, self.hover_bg_color.a)
            _ = ctx.draw_filled_rectangle(self.bounds.x, y, self.bounds.width - 15, self.row_height)
        
        # Tree lines
        if self.show_lines:
            self.render_tree_lines(ctx, node, x, y)
        
        # Expand/collapse icon
        if node.has_children():
            self.render_expand_icon(ctx, node, x + 4, y + self.row_height // 2)
        
        var content_x = x + self.expand_icon_size + 8
        
        # Node icon
        if self.show_icons:
            self.render_node_icon(ctx, node, content_x, y + (self.row_height - self.icon_size) // 2)
            content_x += self.icon_size + 4
        
        # Node text
        let text_color = self.selected_text_color if node.is_selected else self.text_color
        _ = ctx.set_color(text_color.r, text_color.g, text_color.b, text_color.a)
        _ = ctx.draw_text(node.text, content_x, y + (self.row_height - self.font_size) // 2, self.font_size)
    
    fn render_expand_icon(self, ctx: RenderingContextInt, node: TreeNode, x: Int32, y: Int32):
        """Render expand/collapse icon."""
        _ = ctx.set_color(self.expand_icon_color.r, self.expand_icon_color.g,
                         self.expand_icon_color.b, self.expand_icon_color.a)
        
        if node.is_expanded():
            # Down arrow
            _ = ctx.draw_line(x, y - 3, x + 6, y + 3, 2)
            _ = ctx.draw_line(x + 6, y + 3, x + 12, y - 3, 2)
        else:
            # Right arrow
            _ = ctx.draw_line(x + 3, y - 6, x + 9, y, 2)
            _ = ctx.draw_line(x + 9, y, x + 3, y + 6, 2)
    
    fn render_node_icon(self, ctx: RenderingContextInt, node: TreeNode, x: Int32, y: Int32):
        """Render node icon."""
        _ = ctx.set_color(node.icon_color.r, node.icon_color.g,
                         node.icon_color.b, node.icon_color.a)
        
        if node.node_type == NODE_FOLDER:
            # Simple folder icon
            _ = ctx.draw_filled_rectangle(x, y + 3, self.icon_size, self.icon_size - 3)
            _ = ctx.draw_filled_rectangle(x, y, self.icon_size // 2, 3)
        elif node.node_type == NODE_FILE:
            # Simple file icon
            _ = ctx.draw_filled_rectangle(x + 2, y, self.icon_size - 4, self.icon_size)
            _ = ctx.set_color(255, 255, 255, 255)
            _ = ctx.draw_filled_rectangle(x + self.icon_size - 6, y, 4, 4)
            _ = ctx.set_color(node.icon_color.r, node.icon_color.g,
                             node.icon_color.b, node.icon_color.a)
            _ = ctx.draw_line(x + self.icon_size - 6, y + 4, x + self.icon_size - 2, y + 4, 1)
            _ = ctx.draw_line(x + self.icon_size - 2, y, x + self.icon_size - 2, y + 4, 1)
        else:
            # Generic icon
            _ = ctx.draw_filled_circle(x + self.icon_size // 2, y + self.icon_size // 2, 
                                      self.icon_size // 2, 12)
    
    fn render_tree_lines(self, ctx: RenderingContextInt, node: TreeNode, x: Int32, y: Int32):
        """Render tree connection lines."""
        _ = ctx.set_color(self.line_color.r, self.line_color.g,
                         self.line_color.b, self.line_color.a)
        
        # Simplified - would need more complex logic for proper tree lines
        if node.level > 0 or self.show_root_lines:
            # Horizontal line to node
            _ = ctx.draw_line(x - self.indent_width + 10, y + self.row_height // 2,
                             x + 4, y + self.row_height // 2, 1)
    
    fn render_drop_indicator(self, ctx: RenderingContextInt, target_node_id: Int32):
        """Render drop indicator during drag operation."""
        let y = self.bounds.y + self.get_node_y(target_node_id) - self.scroll_offset
        
        _ = ctx.set_color(51, 153, 255, 128)  # Semi-transparent blue
        _ = ctx.draw_filled_rectangle(self.bounds.x, y - 1, self.bounds.width - 15, 3)
    
    fn update(inout self):
        """Update tree view state."""
        self.v_scrollbar.update()
        self.h_scrollbar.update()

# Icon types for common use
alias ICON_FOLDER = "folder"
alias ICON_FOLDER_OPEN = "folder_open"
alias ICON_FILE = "file"
alias ICON_FILE_TEXT = "file_text"
alias ICON_FILE_IMAGE = "file_image"
alias ICON_FILE_CODE = "file_code"
alias ICON_HOME = "home"
alias ICON_STAR = "star"
alias ICON_TRASH = "trash"
alias ICON_DESKTOP = "desktop"
alias ICON_DOWNLOAD = "download"
alias ICON_MUSIC = "music"
alias ICON_VIDEO = "video"
alias ICON_PICTURE = "picture"

# Convenience functions
fn create_tree_view_int(x: Int32, y: Int32, width: Int32, height: Int32) -> TreeViewInt:
    """Create a tree view widget."""
    return TreeViewInt(x, y, width, height)

fn create_file_tree_int(x: Int32, y: Int32, width: Int32, height: Int32) -> TreeViewInt:
    """Create a tree view configured for file browsing."""
    var tree = TreeViewInt(x, y, width, height)
    tree.show_icons = True
    tree.show_lines = False
    tree.indent_width = 16
    return tree