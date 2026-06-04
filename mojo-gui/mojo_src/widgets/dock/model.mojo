"""
Dock layout model — faithful port of egui_dock `src/dock_state/`.

Ported from (read-only reference at /tmp/egui_dock-ref/src/dock_state/):
  - tree/tab_index.rs     -> TabIndex (alias) + DockTab (the concrete <Tab>)
  - tree/node_index.rs    -> NodeIndex helpers (binary-heap indexing)
  - tree/node/leaf.rs      -> LeafNode
  - tree/node/split.rs     -> SplitNode
  - tree/node/mod.rs       -> Node (tagged: Empty/Leaf/Vertical/Horizontal)
  - tree/mod.rs            -> Tree (binary-heap Vec; split/remove/focus)
  - mod.rs                 -> DockState (main surface only)

Phase-1 scope (DOCK_PORT_SPEC.md): in-window docking, main surface only.
DEFERRED: window surfaces, serde, scroll, collapse animation.

Conventions (verified, Mojo 0.26.2 nightly):
  - `out self` (init) / `mut self` (mutators) / `self` (readonly). NO `inout`.
  - NO struct inheritance; compose instead.
  - `comptime` not `alias`.
  - Value structs stored in a `List` derive `(ImplicitlyCopyable, Movable)`;
    a struct owning a `List` derives `(Copyable, Movable)` and is copied with
    `.copy()` / moved with `^`.
  - egui `Rect` (f32) -> `RectInt` (Int32 px); split fraction stays Float64.

Import (from a root harness/demo):
    from mojo_src.widgets.dock.model import DockTab, Tree, DockState, ...
Import (from a sibling file inside dock/):
    from .model import DockTab, Tree, DockState, ...
"""

from ...rendering_int import RectInt


# =============================================================================
# Index types — port of tree/node_index.rs and tree/tab_index.rs
# =============================================================================
# Rust wraps these in newtype structs `NodeIndex(usize)` / `TabIndex(usize)`.
# In Mojo they are plain `Int` values; the heap-index math lives in free
# functions below so callers can read `node_left(i)` etc.

comptime NodeIndex = Int
"""Index into `Tree.nodes` (binary-heap layout)."""

comptime TabIndex = Int
"""Index into a leaf's `tabs` list."""


fn node_root() -> NodeIndex:
    """Index of the root node (port of `NodeIndex::root`)."""
    return 0


fn node_left(n: NodeIndex) -> NodeIndex:
    """Left child of `n` (port of `NodeIndex::left`): n*2 + 1."""
    return n * 2 + 1


fn node_right(n: NodeIndex) -> NodeIndex:
    """Right child of `n` (port of `NodeIndex::right`): n*2 + 2."""
    return n * 2 + 2


fn node_parent(n: NodeIndex) -> NodeIndex:
    """Parent of `n` (port of `NodeIndex::parent`), or -1 for the root.

    Rust returns `Option<NodeIndex>`; here -1 stands in for `None`.
    """
    if n > 0:
        return (n - 1) // 2
    return -1


fn node_is_left(n: NodeIndex) -> Bool:
    """True if `n` is the left child of its parent (odd index)."""
    return n % 2 != 0


fn node_is_right(n: NodeIndex) -> Bool:
    """True if `n` is the right child of its parent (even index)."""
    return n % 2 == 0


fn node_level(n: NodeIndex) -> Int:
    """Number of nodes from root to `n` inclusive (port of `NodeIndex::level`).

    Rust: `usize::BITS - (self.0 + 1).leading_zeros()`, i.e. floor(log2(n+1))+1.
    Computed here without intrinsics.
    """
    var x = n + 1
    var level = 0
    while x > 0:
        x = x >> 1
        level += 1
    return level


fn node_children_at_start(n: NodeIndex, level: Int) -> Int:
    """Start of the descendant range of `n` at `level`
    (port of `NodeIndex::children_at`): (n+1) * 2^level - 1."""
    var base = 1 << level
    return (n + 1) * base - 1


fn node_children_at_end(n: NodeIndex, level: Int) -> Int:
    """End (exclusive) of the descendant range of `n` at `level`:
    (n+2) * 2^level - 1."""
    var base = 1 << level
    return (n + 2) * base - 1


fn node_children_left_start(n: NodeIndex, level: Int) -> Int:
    """Start of the left-descendant range (port of `children_left`)."""
    var base = 1 << level
    return (n + 1) * base - 1


fn node_children_left_end(n: NodeIndex, level: Int) -> Int:
    """End (exclusive) of the left-descendant range:
    (n+1) * 2^level + (2^level / 2) - 1."""
    var base = 1 << level
    return (n + 1) * base + (base // 2) - 1


fn node_children_right_start(n: NodeIndex, level: Int) -> Int:
    """Start of the right-descendant range (port of `children_right`)."""
    var base = 1 << level
    return (n + 1) * base + (base // 2) - 1


fn node_children_right_end(n: NodeIndex, level: Int) -> Int:
    """End (exclusive) of the right-descendant range: (n+2) * 2^level - 1."""
    var base = 1 << level
    return (n + 2) * base - 1


# =============================================================================
# Split direction — port of tree/mod.rs `enum Split`
# =============================================================================

comptime SPLIT_LEFT: Int32 = 0
comptime SPLIT_RIGHT: Int32 = 1
comptime SPLIT_ABOVE: Int32 = 2
comptime SPLIT_BELOW: Int32 = 3


fn split_is_top_bottom(split: Int32) -> Bool:
    """True for Above/Below (vertical split, port of `Split::is_top_bottom`)."""
    return split == SPLIT_ABOVE or split == SPLIT_BELOW


fn split_is_left_right(split: Int32) -> Bool:
    """True for Left/Right (horizontal split, port of `Split::is_left_right`)."""
    return split == SPLIT_LEFT or split == SPLIT_RIGHT


# =============================================================================
# DockTab — the concrete `<Tab>` (egui_dock is generic; we pin it).
# =============================================================================

struct DockTab(ImplicitlyCopyable, Movable):
    """A single dockable tab.  Replaces egui_dock's generic `Tab` type param.

    The host identifies its content by `id`; `title` is the tab-strip label.
    """

    var id: Int32
    """Stable host-assigned identifier for this tab's content."""
    var title: String
    """Display label shown in the tab strip."""

    fn __init__(out self, id: Int32, title: String):
        self.id = id
        self.title = title


fn _nothing_rect() -> RectInt:
    """Equivalent of egui `Rect::NOTHING` for an unlaid-out node (zero rect)."""
    return RectInt(0, 0, 0, 0)


# =============================================================================
# LeafNode — port of tree/node/leaf.rs
# =============================================================================

struct LeafNode(Copyable, Movable):
    """Inner data of a `Node::Leaf`: a stack of tabs with one active.

    Port of `LeafNode<Tab>` in tree/node/leaf.rs.  `scroll` is deferred.
    Owns a `List[DockTab]`, hence `(Copyable, Movable)`.
    """

    var rect: RectInt
    """Full rectangle: tab bar plus tab body."""
    var viewport: RectInt
    """The tab body rectangle (host draws content here)."""
    var tabs: List[DockTab]
    """All tabs in this leaf."""
    var active: TabIndex
    """Index of the open/active tab."""
    var collapsed: Bool
    """Whether the leaf is collapsed."""

    fn __init__(out self, var tabs: List[DockTab]):
        """Create a leaf with `tabs`; everything else defaults (port of
        `LeafNode::new`)."""
        self.rect = _nothing_rect()
        self.viewport = _nothing_rect()
        self.tabs = tabs^
        self.active = 0
        self.collapsed = False

    fn len(self) -> Int:
        """Number of tabs in this leaf."""
        return len(self.tabs)

    fn is_empty(self) -> Bool:
        """True when the leaf has no tabs."""
        return len(self.tabs) == 0

    fn rect_(self) -> RectInt:
        """The full rectangle of this leaf (port of `LeafNode::rect`)."""
        return self.rect

    fn set_rect(mut self, new_rect: RectInt):
        """Set the area this leaf occupies (port of `LeafNode::set_rect`)."""
        self.rect = new_rect

    fn set_active_tab(mut self, index: TabIndex) -> Bool:
        """Set the active tab; returns False (and leaves it unchanged) if the
        index is out of bounds (port of `LeafNode::set_active_tab`, which
        returns `Result`)."""
        if index >= 0 and index < self.len():
            self.active = index
            return True
        return False

    fn append_tab(mut self, tab: DockTab):
        """Append a tab and focus it (port of `LeafNode::append_tab`)."""
        self.active = len(self.tabs)
        self.tabs.append(tab)

    fn insert_tab(mut self, index: TabIndex, tab: DockTab):
        """Insert `tab` at `index` and focus it (port of `LeafNode::insert_tab`).

        Caller must ensure `0 <= index <= len`."""
        self.tabs.insert(index, tab)
        self.active = index

    fn remove_tab(mut self, index: TabIndex) -> DockTab:
        """Remove and return the tab at `index`, adjusting `active`
        (port of `LeafNode::remove_tab`).

        Faithful to Rust: if `index <= active`, active is decremented with a
        saturating subtraction (never below 0).  Caller must ensure the index
        is in bounds.
        """
        if index <= self.active:
            if self.active > 0:
                self.active = self.active - 1
            else:
                self.active = 0
        var removed = self.tabs[index]
        _ = self.tabs.pop(index)
        return removed


# =============================================================================
# SplitNode — port of tree/node/split.rs
# =============================================================================

struct SplitNode(ImplicitlyCopyable, Movable):
    """Inner data of a `Node::Vertical`/`Node::Horizontal` split.

    Port of `SplitNode` in tree/node/split.rs.  `fraction` is the share taken
    by the FIRST child (top for Vertical, left for Horizontal).
    """

    var rect: RectInt
    """Rectangle in which all children of this split are drawn."""
    var fraction: Float64
    """Fraction (0..=1) taken by the first (top/left) child."""
    var fully_collapsed: Bool
    """Whether all subnodes are collapsed."""
    var collapsed_leaf_count: Int32
    """Number of collapsed leaf subnodes."""

    fn __init__(out self, rect: RectInt, fraction: Float64,
                fully_collapsed: Bool, collapsed_leaf_count: Int32):
        """Port of `SplitNode::new`."""
        self.rect = rect
        self.fraction = fraction
        self.fully_collapsed = fully_collapsed
        self.collapsed_leaf_count = collapsed_leaf_count

    fn rect_(self) -> RectInt:
        """The rectangle this split occupies (port of `SplitNode::rect`)."""
        return self.rect

    fn set_rect(mut self, new_rect: RectInt):
        """Set the area this split occupies (port of `SplitNode::set_rect`)."""
        self.rect = new_rect


# =============================================================================
# Node — port of tree/node/mod.rs `enum Node`
# =============================================================================
# Rust's payload enum becomes a `kind` tag plus owned LeafNode + SplitNode.
# Only the field matching `kind` is meaningful; the other is a placeholder.

comptime NODE_EMPTY: Int32 = 0
comptime NODE_LEAF: Int32 = 1
comptime NODE_VERTICAL: Int32 = 2
comptime NODE_HORIZONTAL: Int32 = 3


struct Node(Copyable, Movable):
    """An abstract node of a `Tree` (port of `Node<Tab>` in tree/node/mod.rs).

    `kind` is one of `NODE_EMPTY/LEAF/VERTICAL/HORIZONTAL`.  `leaf` is valid
    when `kind == NODE_LEAF`; `split` is valid for VERTICAL/HORIZONTAL.  Owns a
    `LeafNode` (which owns a `List`), hence `(Copyable, Movable)`.
    """

    var kind: Int32
    """One of the `NODE_*` constants."""
    var leaf: LeafNode
    """Leaf payload (meaningful only when `kind == NODE_LEAF`)."""
    var split: SplitNode
    """Split payload (meaningful for VERTICAL/HORIZONTAL)."""

    fn __init__(out self):
        """Creates an Empty node (port of `Node::Empty`)."""
        self.kind = NODE_EMPTY
        self.leaf = LeafNode(List[DockTab]())
        self.split = SplitNode(_nothing_rect(), 0.5, False, 0)

    @staticmethod
    fn empty() -> Node:
        """An Empty node."""
        return Node()

    @staticmethod
    fn leaf_one(tab: DockTab) -> Node:
        """Leaf node with a single tab (port of `Node::leaf`)."""
        var tabs = List[DockTab]()
        tabs.append(tab)
        return Node.leaf_with(tabs^)

    @staticmethod
    fn leaf_with(var tabs: List[DockTab]) -> Node:
        """Leaf node with the given tabs (port of `Node::leaf_with`)."""
        var n = Node()
        n.kind = NODE_LEAF
        n.leaf = LeafNode(tabs^)
        return n^

    @staticmethod
    fn vertical(split: SplitNode) -> Node:
        """Vertical (top/bottom) split node (port of `Node::Vertical`)."""
        var n = Node()
        n.kind = NODE_VERTICAL
        n.split = split
        return n^

    @staticmethod
    fn horizontal(split: SplitNode) -> Node:
        """Horizontal (left/right) split node (port of `Node::Horizontal`)."""
        var n = Node()
        n.kind = NODE_HORIZONTAL
        n.split = split
        return n^

    # ----- kind predicates (node/mod.rs) -----------------------------------

    fn is_empty(self) -> Bool:
        """True for an Empty node (port of `Node::is_empty`)."""
        return self.kind == NODE_EMPTY

    fn is_leaf(self) -> Bool:
        """True for a Leaf node (port of `Node::is_leaf`)."""
        return self.kind == NODE_LEAF

    fn is_horizontal(self) -> Bool:
        """True for a Horizontal split (port of `Node::is_horizontal`)."""
        return self.kind == NODE_HORIZONTAL

    fn is_vertical(self) -> Bool:
        """True for a Vertical split (port of `Node::is_vertical`)."""
        return self.kind == NODE_VERTICAL

    fn is_parent(self) -> Bool:
        """True for a Horizontal or Vertical split (port of `Node::is_parent`)."""
        return self.is_horizontal() or self.is_vertical()

    fn is_collapsed(self) -> Bool:
        """Collapsed state across kinds (port of `Node::is_collapsed`)."""
        if self.kind == NODE_LEAF:
            return self.leaf.collapsed
        if self.is_parent():
            return self.split.fully_collapsed
        return False

    fn collapsed_leaf_count(self) -> Int32:
        """Layers of collapsed leaf subnodes (port of `collapsed_leaf_count`)."""
        if self.is_parent():
            return self.split.collapsed_leaf_count
        if self.kind == NODE_LEAF:
            return 1 if self.leaf.collapsed else 0
        return 0

    fn rect(self) -> RectInt:
        """Rectangle occupied by this node (port of `Node::rect`).

        Rust returns `Option<Rect>` (None for Empty); here an Empty node yields
        a zero rect — guard with `is_empty()` if the distinction matters.
        """
        if self.kind == NODE_LEAF:
            return self.leaf.rect
        if self.is_parent():
            return self.split.rect
        return _nothing_rect()

    fn set_rect(mut self, new_rect: RectInt):
        """Assign the node's rectangle; no-op for Empty (port of `set_rect`)."""
        if self.kind == NODE_LEAF:
            self.leaf.set_rect(new_rect)
        elif self.is_parent():
            self.split.set_rect(new_rect)

    fn set_collapsed(mut self, collapsed: Bool):
        """Set the collapsing state (port of `Node::set_collapsed`).

        Rust panics on an Empty node; here it is a no-op.
        """
        if self.kind == NODE_LEAF:
            self.leaf.collapsed = collapsed
        elif self.is_parent():
            self.split.fully_collapsed = collapsed

    fn set_collapsed_leaf_count(mut self, count: Int32):
        """Set the collapsed-leaf count on a split (port of
        `set_collapsed_leaf_count`).  No-op for non-split nodes."""
        if self.is_parent():
            self.split.collapsed_leaf_count = count

    fn tabs_count(self) -> Int:
        """Number of tabs (0 for non-leaf) (port of `Node::tabs_count`)."""
        if self.kind == NODE_LEAF:
            return len(self.leaf.tabs)
        return 0

    fn append_tab(mut self, tab: DockTab):
        """Append a tab to a leaf node (port of `Node::append_tab`).

        No-op for non-leaf nodes (Rust panics)."""
        if self.kind == NODE_LEAF:
            self.leaf.append_tab(tab)

    fn remove_tab(mut self, index: TabIndex) -> DockTab:
        """Remove a tab from a leaf (port of `Node::remove_tab`).

        Caller must ensure this is a leaf and the index is in bounds.
        """
        return self.leaf.remove_tab(index)

    fn split_in_place(mut self, split: Int32, fraction: Float64) -> Node:
        """Replace this node with a split and return the OLD node
        (port of `Node::split`, which uses `std::mem::replace`).

        `split` selects orientation: Left/Right -> Horizontal, Above/Below ->
        Vertical.  Caller must ensure `0 <= fraction <= 1`.
        """
        var sn = SplitNode(_nothing_rect(), fraction, self.is_collapsed(),
                           self.collapsed_leaf_count())
        # mem::replace(self, src): capture the old node, then overwrite self's
        # fields with the new split node's fields.
        var old = self.copy()
        if split_is_left_right(split):
            self.kind = NODE_HORIZONTAL
        else:
            self.kind = NODE_VERTICAL
        self.split = sn
        self.leaf = LeafNode(List[DockTab]())
        return old^


# =============================================================================
# Tree — port of tree/mod.rs `struct Tree`
# =============================================================================

struct Tree(Copyable, Movable):
    """Binary tree of `Node`s in a heap-indexed `List` (port of `Tree<Tab>`).

    For node `i`: left child `2i+1`, right child `2i+2`, root `0`.  Horizontal
    splits put Left at the left child, Right at the right child; Vertical splits
    put Top at the left child, Bottom at the right child.
    """

    var nodes: List[Node]
    """The heap-indexed node collection (may contain Empty nodes)."""
    var focused_node: NodeIndex
    """Index of the focused leaf, or -1 for none (Rust `Option<NodeIndex>`)."""
    var collapsed: Bool
    """Whether the whole tree is collapsed."""
    var collapsed_leaf_count: Int32
    """Collapsed leaf-subnode layer count for the tree."""

    fn __init__(out self, var tabs: List[DockTab]):
        """Create a tree with `tabs` in its root leaf (port of `Tree::new`)."""
        var nodes = List[Node]()
        nodes.append(Node.leaf_with(tabs^))
        self.nodes = nodes^
        self.focused_node = -1
        self.collapsed = False
        self.collapsed_leaf_count = 0

    @staticmethod
    fn empty() -> Tree:
        """An empty tree with no nodes (port of `Tree::default`)."""
        var t = Tree(List[DockTab]())
        t.nodes.clear()
        t.focused_node = -1
        return t^

    fn len(self) -> Int:
        """Number of nodes (including Empty) (port of `Tree::len`)."""
        return len(self.nodes)

    fn is_empty(self) -> Bool:
        """True when there are zero nodes (port of `Tree::is_empty`)."""
        return len(self.nodes) == 0

    fn num_tabs(self) -> Int:
        """Total tabs across all leaves (port of `Tree::num_tabs`)."""
        var count = 0
        for i in range(len(self.nodes)):
            if self.nodes[i].kind == NODE_LEAF:
                count += len(self.nodes[i].leaf.tabs)
        return count

    # ----- root access (tree/mod.rs) ---------------------------------------

    fn root_node(self) -> Node:
        """Copy of the root node; Empty tree yields an Empty node
        (Rust returns `Option<&Node>` — guard with `is_empty()`)."""
        if len(self.nodes) == 0:
            return Node.empty()
        return self.nodes[0].copy()

    fn set_focused_node(mut self, node_index: NodeIndex):
        """Focus `node_index` if it is a leaf, else clear focus
        (port of `Tree::set_focused_node`)."""
        if (node_index >= 0 and node_index < len(self.nodes)
                and self.nodes[node_index].is_leaf()):
            self.focused_node = node_index
        else:
            self.focused_node = -1

    fn focused_leaf(self) -> NodeIndex:
        """Index of the focused leaf, or -1 (port of `Tree::focused_leaf`)."""
        return self.focused_node

    # ----- leaf access (tree/mod.rs) ---------------------------------------

    fn is_leaf(self, node: NodeIndex) -> Bool:
        """True if `node` is in bounds and is a leaf."""
        return (node >= 0 and node < len(self.nodes)
                and self.nodes[node].is_leaf())

    fn leaf(self, node: NodeIndex) -> LeafNode:
        """Copy of the leaf at `node` (port of `Tree::leaf`).

        Caller must check `is_leaf(node)` first; an invalid/non-leaf index
        returns an empty leaf rather than erroring.
        """
        if self.is_leaf(node):
            return self.nodes[node].leaf.copy()
        return LeafNode(List[DockTab]())

    fn set_active_tab(mut self, node_index: NodeIndex,
                      tab_index: TabIndex) -> Bool:
        """Set the active tab within a leaf (port of `Tree::set_active_tab`).

        Returns False if the node is invalid/non-leaf or the tab is out of
        bounds (Rust returns `Result`).
        """
        if not self.is_leaf(node_index):
            return False
        return self.nodes[node_index].leaf.set_active_tab(tab_index)

    fn find_active(self) -> NodeIndex:
        """Index of the first leaf node, or -1 (adapted from `Tree::find_active`).

        Rust returns the viewport + active tab; for the retained model we return
        the node index so the caller can read `leaf(idx)`.
        """
        for i in range(len(self.nodes)):
            if self.nodes[i].kind == NODE_LEAF:
                return i
        return -1

    # ----- split (tree/mod.rs:476) -----------------------------------------

    fn _ensure_len(mut self, new_len: Int):
        """Grow `nodes` to `new_len`, padding with Empty nodes."""
        while len(self.nodes) < new_len:
            self.nodes.append(Node.empty())

    fn _last_non_empty_index(self) -> Int:
        """Index of the last non-Empty node (rposition), or 0 (port of the
        `rposition` step inside `Tree::split`)."""
        var i = len(self.nodes) - 1
        while i >= 0:
            if not self.nodes[i].is_empty():
                return i
            i -= 1
        return 0

    fn split(mut self, parent: NodeIndex, split: Int32, fraction: Float64,
             var new: Node) -> Tuple[NodeIndex, NodeIndex]:
        """Split `parent`, keeping its old content in one child and putting
        `new` in the other.  Returns `(old_index, new_index)`.

        Faithful port of `Tree::split` (tree/mod.rs:476): replace `parent`
        with a split node (capturing the old node), grow the heap vector to the
        next full level, choose child slots by direction, relocate the old
        node's whole subtree when it was itself a parent, then place old and
        new.  Caller must ensure `0 <= fraction <= 1` and `new` has tabs.
        """
        var old = self.nodes[parent].split_in_place(split, fraction)
        var old_is_parent = old.is_parent()

        # Resize vector to fit the new size of the binary tree.
        var idx = self._last_non_empty_index()
        var level = node_level(idx)
        self._ensure_len((1 << (level + 1)) - 1)

        # Choose [old_slot, new_slot] by split direction.
        var old_slot: NodeIndex
        var new_slot: NodeIndex
        if split == SPLIT_LEFT or split == SPLIT_ABOVE:
            old_slot = node_right(parent)
            new_slot = node_left(parent)
        else:
            old_slot = node_left(parent)
            new_slot = node_right(parent)

        # If the node we are splitting was a parent, relocate its children.
        if old_is_parent:
            var levels_to_move = node_level(len(self.nodes)) - node_level(old_slot)
            # Level 0 is the node itself (assigned below); start at 1.
            var lvl = levels_to_move - 1
            while lvl >= 1:
                var old_start = node_children_at_start(parent, lvl)
                var new_start = node_children_at_start(old_slot, lvl)
                var move_len = 1 << lvl
                for k in range(move_len):
                    var src = old_start + k
                    var dst = new_start + k
                    if src < len(self.nodes) and dst < len(self.nodes):
                        # swap_with_slice: new range holds only Empty entries.
                        var tmp = self.nodes[dst].copy()
                        self.nodes[dst] = self.nodes[src].copy()
                        self.nodes[src] = tmp^
                lvl -= 1

        self.nodes[old_slot] = old^
        self.nodes[new_slot] = new^

        self.focused_node = new_slot
        self.node_update_collapsed(new_slot)

        return Tuple[NodeIndex, NodeIndex](old_slot, new_slot)

    fn split_tabs(mut self, parent: NodeIndex, split: Int32, fraction: Float64,
                  var tabs: List[DockTab]) -> Tuple[NodeIndex, NodeIndex]:
        """Split `parent`, putting `tabs` in the new leaf
        (port of `Tree::split_tabs`)."""
        return self.split(parent, split, fraction, Node.leaf_with(tabs^))

    fn split_left(mut self, parent: NodeIndex, fraction: Float64,
                  var tabs: List[DockTab]) -> Tuple[NodeIndex, NodeIndex]:
        """New leaf to the LEFT of `parent` (port of `Tree::split_left`)."""
        return self.split(parent, SPLIT_LEFT, fraction, Node.leaf_with(tabs^))

    fn split_right(mut self, parent: NodeIndex, fraction: Float64,
                   var tabs: List[DockTab]) -> Tuple[NodeIndex, NodeIndex]:
        """New leaf to the RIGHT of `parent` (port of `Tree::split_right`)."""
        return self.split(parent, SPLIT_RIGHT, fraction, Node.leaf_with(tabs^))

    fn split_above(mut self, parent: NodeIndex, fraction: Float64,
                   var tabs: List[DockTab]) -> Tuple[NodeIndex, NodeIndex]:
        """New leaf ABOVE `parent` (port of `Tree::split_above`)."""
        return self.split(parent, SPLIT_ABOVE, fraction, Node.leaf_with(tabs^))

    fn split_below(mut self, parent: NodeIndex, fraction: Float64,
                   var tabs: List[DockTab]) -> Tuple[NodeIndex, NodeIndex]:
        """New leaf BELOW `parent` (port of `Tree::split_below`)."""
        return self.split(parent, SPLIT_BELOW, fraction, Node.leaf_with(tabs^))

    # ----- first_leaf helper (tree/mod.rs:558) -----------------------------

    fn _node_kind_at(self, idx: Int) -> Int32:
        """`kind` of node `idx`, or -1 if out of bounds (stand-in for the
        `self.nodes.get(idx)` Option used by `first_leaf`)."""
        if idx >= 0 and idx < len(self.nodes):
            return self.nodes[idx].kind
        return -1

    fn first_leaf(self, top: NodeIndex) -> NodeIndex:
        """First leaf at or under `top`, or -1 (port of `Tree::first_leaf`)."""
        var left = node_left(top)
        var right = node_right(top)
        var lk = self._node_kind_at(left)
        var rk = self._node_kind_at(right)

        if lk == NODE_LEAF:
            return left
        if rk == NODE_LEAF:
            return right

        var l_parent = (lk == NODE_HORIZONTAL or lk == NODE_VERTICAL)
        var r_parent = (rk == NODE_HORIZONTAL or rk == NODE_VERTICAL)
        if l_parent and r_parent:
            var fl = self.first_leaf(left)
            if fl != -1:
                return fl
            return self.first_leaf(right)
        if l_parent:
            return self.first_leaf(left)
        if r_parent:
            return self.first_leaf(right)
        return -1

    # ----- remove (tree/mod.rs:612) ----------------------------------------

    fn remove_leaf(mut self, node: NodeIndex):
        """Remove the leaf at `node`, pulling its sibling subtree up into the
        parent's slot (faithful port of `Tree::remove_leaf`).

        Caller must ensure the tree is non-empty and `node` is a leaf.
        """
        var parent = node_parent(node)
        if parent == -1:
            # Removing the root: the tree becomes empty.
            self.nodes.clear()
            self.focused_node = -1
            return

        # Re-home focus away from the node being removed.
        if node == self.focused_node:
            self.focused_node = -1
            var cur = node
            while True:
                var p = node_parent(cur)
                if p == -1:
                    break
                var nxt: NodeIndex
                if node_is_left(cur):
                    nxt = node_right(p)
                else:
                    nxt = node_left(p)
                if nxt >= 0 and nxt < len(self.nodes) and self.nodes[nxt].is_leaf():
                    self.focused_node = nxt
                    break
                var fl = self.first_leaf(nxt)
                if fl != -1:
                    self.focused_node = fl
                    break
                cur = p

        self.nodes[parent] = Node.empty()
        self.nodes[node] = Node.empty()

        var level = 0
        if node_is_left(node):
            # Pull the right sibling subtree up into the parent slots.
            var done = False
            while not done:
                var dst_start = node_children_at_start(parent, level)
                var dst_end = node_children_at_end(parent, level)
                var src_start = node_children_right_start(parent, level + 1)
                var count = dst_end - dst_start
                for k in range(count):
                    var src = src_start + k
                    var dst = dst_start + k
                    if src >= len(self.nodes):
                        done = True
                        break
                    if src == self.focused_node:
                        self.focused_node = dst
                    self.nodes[dst] = self.nodes[src].copy()
                    self.nodes[src] = Node.empty()
                level += 1
        else:
            # Pull the left sibling subtree up into the parent slots.
            var done = False
            while not done:
                var dst_start = node_children_at_start(parent, level)
                var dst_end = node_children_at_end(parent, level)
                var src_start = node_children_left_start(parent, level + 1)
                var count = dst_end - dst_start
                for k in range(count):
                    var src = src_start + k
                    var dst = dst_start + k
                    if src >= len(self.nodes):
                        done = True
                        break
                    if src == self.focused_node:
                        self.focused_node = dst
                    self.nodes[dst] = self.nodes[src].copy()
                    self.nodes[src] = Node.empty()
                level += 1

        # Trim trailing Empty nodes whose parent is not a parent-node.
        while len(self.nodes) > 0:
            var last = len(self.nodes) - 1
            var lp = node_parent(last)
            var parent_not_parent = (lp != -1 and not self.nodes[lp].is_parent())
            if self.nodes[last].is_empty() and parent_not_parent:
                _ = self.nodes.pop()
            else:
                break

    fn remove_tab(mut self, node_index: NodeIndex,
                  tab_index: TabIndex) -> DockTab:
        """Remove the tab at `(node_index, tab_index)`, removing the leaf if it
        becomes empty (port of `Tree::remove_tab`).

        Caller must ensure the node is a leaf and the tab index is in bounds.
        """
        var removed = self.nodes[node_index].remove_tab(tab_index)
        if self.nodes[node_index].tabs_count() == 0:
            self.remove_leaf(node_index)
        return removed

    # ----- push (tree/mod.rs:691,732) --------------------------------------

    fn push_to_first_leaf(mut self, tab: DockTab):
        """Push `tab` to the first Leaf/Empty slot, creating one if needed
        (port of `Tree::push_to_first_leaf`)."""
        for i in range(len(self.nodes)):
            if self.nodes[i].kind == NODE_LEAF:
                self.nodes[i].leaf.active = len(self.nodes[i].leaf.tabs)
                self.nodes[i].leaf.tabs.append(tab)
                self.focused_node = i
                return
            elif self.nodes[i].kind == NODE_EMPTY:
                self.nodes[i] = Node.leaf_one(tab)
                self.focused_node = i
                return
        # No leaf/empty slot found: the tree must be empty.
        var tabs = List[DockTab]()
        tabs.append(tab)
        self.nodes.append(Node.leaf_with(tabs^))
        self.focused_node = 0

    fn push_to_focused_leaf(mut self, tab: DockTab):
        """Push `tab` to the focused leaf, falling back to the first available
        leaf, or creating one (port of `Tree::push_to_focused_leaf`)."""
        if self.focused_node != -1:
            if len(self.nodes) == 0:
                self.nodes.append(Node.leaf_one(tab))
                self.focused_node = node_root()
                return
            var fn_idx = self.focused_node
            if self.nodes[fn_idx].kind == NODE_EMPTY:
                self.nodes[fn_idx] = Node.leaf_one(tab)
                self.focused_node = fn_idx
            elif self.nodes[fn_idx].kind == NODE_LEAF:
                self.nodes[fn_idx].leaf.append_tab(tab)
                self.focused_node = fn_idx
            else:
                self.push_to_first_leaf(tab)
        else:
            if len(self.nodes) == 0:
                self.nodes.append(Node.leaf_one(tab))
                self.focused_node = node_root()
            else:
                self.push_to_first_leaf(tab)

    # ----- collapse bookkeeping (tree/mod.rs:890) --------------------------

    fn node_update_collapsed(mut self, node_index: NodeIndex):
        """Propagate collapsed state up to ancestors (port of
        `Tree::node_update_collapsed`)."""
        var collapsed = self.nodes[node_index].is_collapsed()
        if not collapsed:
            var p = node_parent(node_index)
            while p != -1:
                var next_p = node_parent(p)
                var left_count = self.nodes[node_left(p)].collapsed_leaf_count()
                var right_count = self.nodes[node_right(p)].collapsed_leaf_count()
                self.nodes[p].set_collapsed(False)
                if self.nodes[p].is_horizontal():
                    self.nodes[p].set_collapsed_leaf_count(max(left_count, right_count))
                else:
                    self.nodes[p].set_collapsed_leaf_count(left_count + right_count)
                p = next_p
            self.collapsed = False
            self.collapsed_leaf_count = self.nodes[node_root()].collapsed_leaf_count()
        else:
            var p = node_parent(node_index)
            while p != -1:
                var next_p = node_parent(p)
                var left_count = self.nodes[node_left(p)].collapsed_leaf_count()
                var right_count = self.nodes[node_right(p)].collapsed_leaf_count()
                if self.nodes[p].is_horizontal():
                    self.nodes[p].set_collapsed_leaf_count(max(left_count, right_count))
                else:
                    self.nodes[p].set_collapsed_leaf_count(left_count + right_count)
                if (self.nodes[node_left(p)].is_collapsed()
                        and self.nodes[node_right(p)].is_collapsed()):
                    self.nodes[p].set_collapsed(True)
                p = next_p
            if len(self.nodes) > 0 and self.nodes[node_root()].is_collapsed():
                self.collapsed = True
                self.collapsed_leaf_count = self.nodes[node_root()].collapsed_leaf_count()

    # ----- find (tree/mod.rs:949) ------------------------------------------

    fn find_tab_by_id(self, tab_id: Int32) -> Tuple[NodeIndex, TabIndex]:
        """First (node, tab) holding a tab with `id == tab_id`, or `(-1, -1)`
        (adapted from `Tree::find_tab` for the concrete `DockTab`)."""
        for ni in range(len(self.nodes)):
            if self.nodes[ni].kind == NODE_LEAF:
                var count = len(self.nodes[ni].leaf.tabs)
                for ti in range(count):
                    if self.nodes[ni].leaf.tabs[ti].id == tab_id:
                        return Tuple[NodeIndex, TabIndex](ni, ti)
        return Tuple[NodeIndex, TabIndex](-1, -1)


# =============================================================================
# DockState — port of mod.rs `struct DockState` (main surface only)
# =============================================================================

struct DockState(Copyable, Movable):
    """Top-level dock state holding the main-surface `Tree`.

    Port of `DockState<Tab>` in dock_state/mod.rs.  Window surfaces are
    DEFERRED (single GLFW window), so only the main surface exists here.
    """

    var main: Tree
    """The main-surface layout tree."""

    fn __init__(out self, var tabs: List[DockTab]):
        """Create a dock state with `tabs` at the main surface root
        (port of `DockState::new`)."""
        self.main = Tree(tabs^)

    fn main_surface(self) -> Tree:
        """Copy of the main-surface tree (port of `DockState::main_surface`).

        For mutation, operate on `self.main` directly or via the `*_main`
        helpers below — Mojo can't hand out a `&mut Tree` the way Rust does.
        """
        return self.main.copy()

    fn push_to_focused_leaf(mut self, tab: DockTab):
        """Push `tab` to the focused leaf of the main surface
        (port of `DockState::push_to_focused_leaf`)."""
        self.main.push_to_focused_leaf(tab)
