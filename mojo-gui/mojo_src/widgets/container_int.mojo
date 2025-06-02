"""
Integer-Only Container Widget Implementation
Layout container for organizing child widgets using integer coordinates.
"""

from ..rendering_int import RenderingContextInt, ColorInt, PointInt, SizeInt, RectInt
from ..widget_int import WidgetInt, BaseWidgetInt, MouseEventInt, KeyEventInt

# Layout types
alias LAYOUT_NONE = 0
alias LAYOUT_VERTICAL = 1
alias LAYOUT_HORIZONTAL = 2
alias LAYOUT_GRID = 3

# Alignment types
alias ALIGN_START = 0
alias ALIGN_CENTER = 1
alias ALIGN_END = 2
alias ALIGN_STRETCH = 3

struct ChildWidget:
    """Child widget info for container."""
    var widget_id: Int32
    var x: Int32
    var y: Int32
    var width: Int32
    var height: Int32
    var visible: Bool
    var flex_grow: Int32
    var margin_left: Int32
    var margin_top: Int32
    var margin_right: Int32
    var margin_bottom: Int32
    
    fn __init__(inout self, id: Int32):
        self.widget_id = id
        self.x = 0
        self.y = 0
        self.width = 0
        self.height = 0
        self.visible = True
        self.flex_grow = 0
        self.margin_left = 0
        self.margin_top = 0
        self.margin_right = 0
        self.margin_bottom = 0

struct ContainerInt(BaseWidgetInt):
    """Container widget for organizing child widgets."""
    
    var layout_type: Int32
    var alignment: Int32
    var padding_left: Int32
    var padding_top: Int32
    var padding_right: Int32
    var padding_bottom: Int32
    var spacing: Int32
    var grid_columns: Int32
    var grid_rows: Int32
    var child_count: Int32
    var children: List[ChildWidget]
    var auto_size: Bool
    var scroll_x: Int32
    var scroll_y: Int32
    var content_width: Int32
    var content_height: Int32
    
    fn __init__(inout self, x: Int32, y: Int32, width: Int32, height: Int32, 
               layout: Int32 = LAYOUT_NONE):
        """Initialize container."""
        self.super().__init__(x, y, width, height)
        self.layout_type = layout
        self.alignment = ALIGN_START
        self.padding_left = 5
        self.padding_top = 5
        self.padding_right = 5
        self.padding_bottom = 5
        self.spacing = 5
        self.grid_columns = 2
        self.grid_rows = 2
        self.child_count = 0
        self.children = List[ChildWidget]()
        self.auto_size = False
        self.scroll_x = 0
        self.scroll_y = 0
        self.content_width = 0
        self.content_height = 0
        
        # Set container appearance
        self.background_color = ColorInt(250, 250, 250, 255)  # Very light gray
        self.border_color = ColorInt(200, 200, 200, 255)      # Light gray border
        self.border_width = 1
    
    fn add_child(inout self, widget_id: Int32, w: Int32, h: Int32, flex_grow: Int32 = 0) -> Int32:
        """Add a child widget to the container."""
        if self.child_count >= 32:  # Max children limit
            return -1
        
        var child = ChildWidget(widget_id)
        child.width = w
        child.height = h
        child.flex_grow = flex_grow
        
        self.children.append(child)
        self.child_count += 1
        
        # Trigger layout recalculation
        self.calculate_layout()
        
        return self.child_count - 1  # Return child index
    
    fn remove_child(inout self, widget_id: Int32) -> Bool:
        """Remove a child widget from the container."""
        for i in range(self.child_count):
            if self.children[i].widget_id == widget_id:
                # Remove child (simplified - just mark as invisible)
                self.children[i].visible = False
                self.calculate_layout()
                return True
        return False
    
    fn set_child_margin(inout self, widget_id: Int32, left: Int32, top: Int32, right: Int32, bottom: Int32):
        """Set margins for a child widget."""
        for i in range(self.child_count):
            if self.children[i].widget_id == widget_id:
                self.children[i].margin_left = left
                self.children[i].margin_top = top
                self.children[i].margin_right = right
                self.children[i].margin_bottom = bottom
                self.calculate_layout()
                break
    
    fn set_padding(inout self, left: Int32, top: Int32, right: Int32, bottom: Int32):
        """Set container padding."""
        self.padding_left = left
        self.padding_top = top
        self.padding_right = right
        self.padding_bottom = bottom
        self.calculate_layout()
    
    fn set_spacing(inout self, spacing: Int32):
        """Set spacing between child widgets."""
        self.spacing = spacing
        self.calculate_layout()
    
    fn set_grid_size(inout self, columns: Int32, rows: Int32):
        """Set grid dimensions for grid layout."""
        self.grid_columns = columns
        self.grid_rows = rows
        if self.layout_type == LAYOUT_GRID:
            self.calculate_layout()
    
    fn calculate_layout(inout self):
        """Calculate positions and sizes for all child widgets."""
        if self.child_count == 0:
            return
        
        let content_x = self.x + self.padding_left
        let content_y = self.y + self.padding_top
        let content_w = self.width - self.padding_left - self.padding_right
        let content_h = self.height - self.padding_top - self.padding_bottom
        
        if self.layout_type == LAYOUT_VERTICAL:
            self._layout_vertical(content_x, content_y, content_w, content_h)
        elif self.layout_type == LAYOUT_HORIZONTAL:
            self._layout_horizontal(content_x, content_y, content_w, content_h)
        elif self.layout_type == LAYOUT_GRID:
            self._layout_grid(content_x, content_y, content_w, content_h)
        # LAYOUT_NONE: children keep their manual positions
    
    fn _layout_vertical(inout self, start_x: Int32, start_y: Int32, width: Int32, height: Int32):
        """Arrange children vertically."""
        var current_y = start_y
        var total_flex = 0
        var used_height = 0
        
        # First pass: calculate fixed heights and total flex
        for i in range(self.child_count):
            if not self.children[i].visible:
                continue
            total_flex += self.children[i].flex_grow
            if self.children[i].flex_grow == 0:
                used_height += self.children[i].height + self.children[i].margin_top + self.children[i].margin_bottom
            if i > 0:
                used_height += self.spacing
        
        # Calculate available space for flex items
        var available_height = height - used_height
        
        # Second pass: position children
        for i in range(self.child_count):
            if not self.children[i].visible:
                continue
            
            var child_height = self.children[i].height
            if self.children[i].flex_grow > 0 and total_flex > 0:
                child_height = available_height * self.children[i].flex_grow // total_flex
            
            current_y += self.children[i].margin_top
            
            self.children[i].x = start_x + self.children[i].margin_left
            self.children[i].y = current_y
            self.children[i].width = width - self.children[i].margin_left - self.children[i].margin_right
            self.children[i].height = child_height
            
            current_y += child_height + self.children[i].margin_bottom + self.spacing
    
    fn _layout_horizontal(inout self, start_x: Int32, start_y: Int32, width: Int32, height: Int32):
        """Arrange children horizontally."""
        var current_x = start_x
        var total_flex = 0
        var used_width = 0
        
        # First pass: calculate fixed widths and total flex
        for i in range(self.child_count):
            if not self.children[i].visible:
                continue
            total_flex += self.children[i].flex_grow
            if self.children[i].flex_grow == 0:
                used_width += self.children[i].width + self.children[i].margin_left + self.children[i].margin_right
            if i > 0:
                used_width += self.spacing
        
        # Calculate available space for flex items
        var available_width = width - used_width
        
        # Second pass: position children
        for i in range(self.child_count):
            if not self.children[i].visible:
                continue
            
            var child_width = self.children[i].width
            if self.children[i].flex_grow > 0 and total_flex > 0:
                child_width = available_width * self.children[i].flex_grow // total_flex
            
            current_x += self.children[i].margin_left
            
            self.children[i].x = current_x
            self.children[i].y = start_y + self.children[i].margin_top
            self.children[i].width = child_width
            self.children[i].height = height - self.children[i].margin_top - self.children[i].margin_bottom
            
            current_x += child_width + self.children[i].margin_right + self.spacing
    
    fn _layout_grid(inout self, start_x: Int32, start_y: Int32, width: Int32, height: Int32):
        """Arrange children in a grid."""
        if self.grid_columns <= 0 or self.grid_rows <= 0:
            return
        
        let cell_width = (width - (self.grid_columns - 1) * self.spacing) // self.grid_columns
        let cell_height = (height - (self.grid_rows - 1) * self.spacing) // self.grid_rows
        
        var visible_count = 0
        for i in range(self.child_count):
            if not self.children[i].visible:
                continue
            
            let row = visible_count // self.grid_columns
            let col = visible_count % self.grid_columns
            
            if row >= self.grid_rows:
                break  # Exceeded grid capacity
            
            self.children[i].x = start_x + col * (cell_width + self.spacing) + self.children[i].margin_left
            self.children[i].y = start_y + row * (cell_height + self.spacing) + self.children[i].margin_top
            self.children[i].width = cell_width - self.children[i].margin_left - self.children[i].margin_right
            self.children[i].height = cell_height - self.children[i].margin_top - self.children[i].margin_bottom
            
            visible_count += 1
    
    fn get_child_bounds(self, widget_id: Int32) -> RectInt:
        """Get the calculated bounds for a child widget."""
        for i in range(self.child_count):
            if self.children[i].widget_id == widget_id:
                return RectInt(self.children[i].x, self.children[i].y, 
                              self.children[i].width, self.children[i].height)
        return RectInt(0, 0, 0, 0)
    
    fn handle_mouse_event(inout self, event: MouseEventInt) -> Bool:
        """Handle mouse events for the container."""
        # First check if we're inside the container
        if not self._point_in_bounds(PointInt(event.x, event.y)):
            return False
        
        # Check each child widget (reverse order for top-to-bottom hit testing)
        for i in range(self.child_count - 1, -1, -1):
            if not self.children[i].visible:
                continue
            
            let child_bounds = RectInt(self.children[i].x, self.children[i].y,
                                      self.children[i].width, self.children[i].height)
            if child_bounds.contains(PointInt(event.x, event.y)):
                # Child widget should handle this event
                return True
        
        return False  # Container itself doesn't handle clicks
    
    fn draw(self, ctx: RenderingContextInt):
        """Draw the container and manage child rendering."""
        # Draw container background
        self._draw_background(ctx)
        
        # Draw container border
        self._draw_border(ctx)
        
        # Note: Child widgets should be drawn by the application after layout calculation
        # This container just manages positioning, not actual rendering of children
    
    fn get_content_size(self) -> SizeInt:
        """Get the total content size (for scrolling)."""
        return SizeInt(self.content_width, self.content_height)
    
    fn set_scroll_offset(inout self, x: Int32, y: Int32):
        """Set scroll offset for scrollable containers."""
        self.scroll_x = x
        self.scroll_y = y
        # Recalculate layout with scroll offset
        self.calculate_layout()

# Convenience functions for creating common layouts
fn create_vertical_container(x: Int32, y: Int32, width: Int32, height: Int32, spacing: Int32 = 5) -> ContainerInt:
    """Create a vertical layout container."""
    var container = ContainerInt(x, y, width, height, LAYOUT_VERTICAL)
    container.set_spacing(spacing)
    return container

fn create_horizontal_container(x: Int32, y: Int32, width: Int32, height: Int32, spacing: Int32 = 5) -> ContainerInt:
    """Create a horizontal layout container."""
    var container = ContainerInt(x, y, width, height, LAYOUT_HORIZONTAL)
    container.set_spacing(spacing)
    return container

fn create_grid_container(x: Int32, y: Int32, width: Int32, height: Int32, 
                        columns: Int32, rows: Int32, spacing: Int32 = 5) -> ContainerInt:
    """Create a grid layout container."""
    var container = ContainerInt(x, y, width, height, LAYOUT_GRID)
    container.set_grid_size(columns, rows)
    container.set_spacing(spacing)
    return container