# DOCK_FINDINGS.md — egui_dock → MojoGUI port audit

Skeptical faithfulness + correctness audit. Reference (read-only):
`/tmp/egui_dock-ref/src/`. Ported: `mojo_src/widgets/dock/{model,area,style}.mojo`
+ `mojo-gui/dock_demo.mojo`.

Severity: **BLOCKER** (does not compile / data loss) · **CORRECTNESS** (wrong
behavior) · **FAITHFULNESS** (diverges from egui_dock semantics) · **MINOR**.

Line numbers are as of audit time; the bugfixer is editing concurrently so they
may drift — anchor on the function name.

---

## 1. BLOCKER — `create_dock_area_int` arity vs. demo call site (RESOLVED)

> **RESOLVED** (re-verified on disk): the original report was from a stale
> snapshot during concurrent editing. Current `dock_demo.mojo:114-115` uses the
> 4-arg factory + `area.set_state(state^)`, and `area.mojo:719`
> `create_dock_area_int(x,y,width,height)` matches `__init__`.
> `pixi run mojo build mojo-gui/dock_demo.mojo` → **EXIT 0**. Original report
> retained below for the record.

- **Mojo:** `area.mojo:703` `fn create_dock_area_int(x, y, width, height) -> DockAreaInt` (4 args, builds an EMPTY state); `area.mojo:119` `DockAreaInt.__init__(out self, x, y, width, height)`.
- **Caller:** `dock_demo.mojo:114` `var area = create_dock_area_int(DOCK_X, DOCK_Y, DOCK_W, DOCK_H, state^)` — passes a 5th `state^` arg and never calls `area.set_state(state^)`.
- **Evidence:** `pixi run mojo build mojo-gui/dock_demo.mojo` →
  `error: invalid call to 'create_dock_area_int': expected at most 4 positional arguments, got 5`. EXIT 1. Definition-of-done (EXIT 0) is unmet.
- **What's wrong:** the factory contract changed to 4-arg/empty-state but the demo still uses the old 5-arg form, and there is no `set_state` call to install the built layout. Even if it compiled, `area` would render an empty dock.
- **Fix (pick one, keep them consistent):**
  - (a) Re-add the state-taking factory: `fn create_dock_area_int(x, y, w, h, var state: DockState) -> DockAreaInt:` that calls `set_state`, and add a matching 5-arg `__init__` (or have the factory build then `set_state`); **or**
  - (b) Keep the 4-arg factory and fix the demo: `var area = create_dock_area_int(...)` then `area.set_state(state^)`.
  - Option (b) is the smaller change and matches the docstring on the current `create_dock_area_int`.

---

## 2. CORRECTNESS — drop commit re-finds target using STALE rects after `remove_tab` (RESOLVED)

> **RESOLVED** (re-verified on disk): `area.mojo:_commit_drop` now calls
> `self.layout()` immediately after `remove_tab(src_node, src_tab)` (area.mojo:581+)
> and before `new_target = self._leaf_at(px, py)`, so the re-find hit-tests
> fresh post-collapse rects. Original report retained below.

- **Mojo:** `area.mojo:_commit_drop` (~:564–591). Sequence: `remove_tab(src_node, src_tab)` → `new_target = self._leaf_at(px, py)` → split/append on `new_target` → `self.layout()` (only at the end).
- **Rust ref:** `tree/mod.rs` `remove_tab`→`remove_leaf` (sibling pull-up at :612) mutates node positions; egui recomputes all rects each immediate-mode frame before any hit-test, so it never hit-tests against stale geometry.
- **What's wrong:** when the source leaf empties, `remove_tab` calls `remove_leaf`, which **moves nodes between heap slots without touching their `rect`s** (the model has no layout; `area.layout()` is what assigns rects). `_leaf_at` then hit-tests against `.leaf.rect` values that are now attached to the wrong nodes (post-pull-up). `new_target` can resolve to the wrong leaf, or a leaf whose stale rect still covers `(px,py)` though it has moved. The subsequent `split`/`append` then targets the wrong node. Result: dropping a tab out of a soon-to-be-emptied leaf docks it in the wrong place.
- **Fix:** call `self.layout()` immediately after `remove_tab` and before re-finding (`new_target = self._leaf_at(...)`). Re-running layout reassigns every node's rect to its new heap position, so the hit-test is valid. (Cheap; layout is O(n).)

---

## 3. FAITHFULNESS — drop-zone geometry differs from `resolve_traditional`

- **Mojo:** `area.mojo:_zone_at` (~:273–311) + `EDGE_ZONE_FRAC=0.30` (:52). Closest-edge band: if the cursor is within 0.30 of the nearest edge (normalized), that edge's split; else center/append.
- **Rust ref:** `drag_and_drop.rs` `resolve_traditional` (~:230–300): a reverse-lerp to `(-0.5..0.5)`; a **center square** of side `center_drop_coverage = 0.25` (style.rs:507) ⇒ Append; otherwise the four edges are chosen by **diagonal quadrants** via the sign of `a_pos.x - a_pos.y` and `-a_pos.x - a_pos.y` (the overlay rect is `everything_above/left_of/right_of/below(center)`).
- **What's wrong:** the regions don't match egui_dock. egui's center zone is a small central square (half-extent 0.125); its edges are triangular quadrants meeting at the diagonals. Mojo's center is a large cross-shaped remainder and its edges are rectangular bands ~0.30 thick. A drop near a corner, or ~0.2 from an edge, can land in a different zone than egui_dock would choose.
- **Note:** this was explicitly sanctioned as an "adaptation" by the team-lead spec, so it is FAITHFULNESS not CORRECTNESS. If bit-faithfulness is wanted: implement the center square (coverage 0.25) and the two-line diagonal test; the preview rect for an edge should be the half-rect split at the leaf center (not `w//2` from the side, which already matches for L/R/T/B).
- **Sub-issue (MINOR):** `_zone_at` precedence — left/right are tested before top/bottom with strict `<`, so an exact tie (e.g. perfectly centered) resolves toward LEFT/TOP arbitrarily. egui uses the diagonal which is symmetric. Low impact.

---

## 4. FAITHFULNESS — split fraction semantics + non-centered separator

- **Mojo:** `area.mojo:_layout_node` (~:191–208). Vertical: `avail = height - sw`, `top_h = avail*frac`, top child `[y, y+top_h]`, separator `[y+top_h, y+top_h+sw]`, bottom `[y+top_h+sw, …]`. Splitter draw (`_draw_splitter`) and drag (`_drag_splitter_to`) use the same `avail`.
- **Rust ref:** `show/mod.rs:compute_rect_sizes` (~:430–460): `midpoint = rect.min + dim_size * fraction` (fraction of the **FULL** rect), then children are `everything_above(midpoint - sep*0.5)` and `everything_below(midpoint + sep*0.5)` — i.e. the `sep`-wide separator is **centered on the midpoint**, taking `sep/2` from each child.
- **What's wrong:** (a) Rust `fraction` is a fraction of the full dimension; Mojo's is a fraction of `(dimension − sw)`. For the same stored `fraction` the boundary differs by up to `sw*frac` px. (b) Rust centers the separator on the midpoint; Mojo puts the entire separator on the far side of the first child. With `sw=4` this is a ≤4px visual offset. Internally consistent (layout/draw/drag agree), so it round-trips — but it is not bit-faithful and a layout deserialized from egui_dock would render slightly shifted.
- **Fix (if faithfulness desired):** `mid = rect_min + dim*frac; first = [rect_min, mid - sw/2]; second = [mid + sw/2, rect_max]`.

---

## 5. FAITHFULNESS — splitter drag model + clamp differ from `show_separator`

- **Mojo:** `area.mojo:_drag_splitter_to` (~:429–456): sets `fraction` **absolutely** from cursor (`(py - r.y)/avail`), clamps to fixed `MIN/MAX_FRACTION = 0.05/0.95` (:55–56). No double-click reset, no arrow-key nudge.
- **Rust ref:** `show/mod.rs:show_separator` (~:555–567): applies a **relative** `response.drag_delta()/range`; clamp is **dynamic** `min = (style.separator.extra / range).min(1.0)` with `extra` default `175.0` (style.rs SeparatorStyle), `max = 1 - min`; plus `double_clicked() ⇒ fraction = 0.5` and arrow-key `±16px` nudges.
- **What's wrong:** Mojo's absolute mapping means grabbing the splitter anywhere snaps the boundary to the exact cursor (egui keeps the grab offset). The clamp is a fixed 5%/95% rather than egui's pixel-budget-based 175px-from-each-edge clamp — on a tall panel egui allows the splitter much closer to the edge than 5%; on a short panel it forbids it. Double-click-reset and keyboard resize are absent.
- **Fix:** if matching egui matters, store a grab offset, apply delta, and use the `extra/range` clamp. Otherwise document as an intentional simplification (currently undocumented as a divergence).

---

## 6. CORRECTNESS — `find_active` semantics changed (first leaf ≠ focused leaf)

- **Mojo:** `model.mojo:find_active` (:591–600) returns the index of the **first leaf in heap order**.
- **Rust ref:** `tree/mod.rs:find_active` returns the active tab of the **first leaf that has tabs** (`leaf.tabs.get(active.0)`), and the closely-related `find_active_focused` keys off `focused_node`.
- **What's wrong:** the Mojo name `find_active` suggests "the active/focused thing" but it returns the first leaf regardless of focus or whether it has an active tab. If a caller expects the focused leaf, this is wrong. Currently unused by `area.mojo` (which tracks focus separately), so impact is low — but it is a latent trap.
- **Fix:** rename to `first_leaf_index()` or implement focused-leaf semantics; at minimum the docstring already flags the divergence — make the name match.

---

## 7. FAITHFULNESS — center drop is always Append; no insert-at-tab-index

- **Mojo:** `area.mojo:_commit_drop` ZONE_CENTER branch (~:578) `append_tab(moved)`.
- **Rust ref:** `drag_and_drop.rs` `is_on_title_bar()` / `TreeComponent::Tab` ⇒ `TabInsert::Insert(dst.tab)`: dropping onto a specific tab title inserts the moved tab at that index, not the end.
- **What's wrong:** you cannot reorder tabs within a leaf or drop-before a specific tab; every center drop appends. Reasonable phase-1 cut, but it means tab reordering is impossible. Track in STATUS (done).
- **Fix:** detect the cursor over a tab button in the target strip and call `insert_tab(ti, moved)` instead of `append_tab`.

---

## 8. MINOR — fixed-width tab strip vs. egui text-measured widths

- **Mojo:** `area.mojo:_tab_rect` uses `_tab_strip_width()` (a constant) for every tab.
- **Rust ref:** `show/leaf.rs:tab_bar` measures each tab's title and honors `TabBarStyle.fill_tab_bar` / `minimum_width`.
- **Impact:** long titles overflow / short titles waste space; tabs beyond the strip width are not scrolled (scroll DEFERRED). Cosmetic. The `style.tab_min_width` field exists but is unused by the strip layout.

---

## 9. MINOR — `split_in_place` copies the whole subtree-owning node

- **Mojo:** `model.mojo:split_in_place` (:466–484) does `var old = self.copy()` to emulate `mem::replace`.
- **Rust ref:** `node/mod.rs:Node::split` uses `std::mem::replace` (a move, O(1)).
- **Impact:** correctness is fine (the copy is then overwritten), but `Node.copy()` deep-copies the `LeafNode`'s `List[DockTab]`. For a leaf being split this copies its tabs once. Negligible at phase-1 scale; note for perf only.

---

## 10. MINOR — splitter hit-test ignores the centered-separator geometry

- **Mojo:** `area.mojo:_splitter_at` (~:342–375) tests a band `[bar - GRAB, bar + sw + GRAB]` where `bar = r + avail*frac` — consistent with the (non-centered) layout in finding #4. If #4 is fixed to center the separator, this must move to `[mid - sw/2 - GRAB, mid + sw/2 + GRAB]` too, or the grab zone will be offset from the drawn bar.
- **Impact:** only relevant as a follow-on to fixing #4; flagged so they stay in sync.

---

## Things verified CORRECT (faithful — no action)

- **Heap indexing** (`node_left/right/parent/level/children_at/left/right`,
  `model.mojo:48–133`) is bit-faithful to `node_index.rs`, including the
  reimplemented `level` (== `BITS − leading_zeros(n+1)`).
- **`Tree.split` subtree relocation** (`model.mojo:619–673`) matches
  `tree/mod.rs:split` (:476): rposition→level→resize-to-`(1<<(level+1))−1`,
  child-slot selection by direction (`Left|Above ⇒ [right,left]`), per-level
  swap loop from `levels_to_move−1` down to `1`. Correct.
- **`remove_leaf`** (`model.mojo:737–823`) matches `tree/mod.rs:remove_leaf`
  (:612): focus re-homing walk, parent+node cleared, left vs right sibling
  pull-up using `children_at` ← `children_right/left(level+1)`, trailing-Empty
  trim guarded by `parent is not a parent-node`. Correct.
- **`LeafNode.remove_tab`** saturating-active (`model.mojo:249–264`) matches
  `leaf.rs` (`if index <= active { active = active.saturating_sub(1) }`).
- **`push_to_first_leaf` / `push_to_focused_leaf`** (`model.mojo:839–880`)
  match `tree/mod.rs` (:691,732) including the empty-tree and focused-but-split
  fallbacks.
- **`node_update_collapsed`** (`model.mojo:884–918`) matches `tree/mod.rs:890`
  (horizontal ⇒ max, vertical ⇒ sum; collapse propagation both directions).
- **Leaf `viewport` = rect − tab strip** (`area.mojo:_layout_node` leaf branch)
  matches `show/leaf.rs:tab_body` (`viewport = body_rect` below the tab bar).
  The host API `leaf_body_rect` correctly returns this body rect (excludes the
  strip).
- **Style sizes/colors**: tab_bar.height=24, separator.width=1.0,
  selection_color=rgb(0,191,255)*0.5 all match `style.rs` defaults.
