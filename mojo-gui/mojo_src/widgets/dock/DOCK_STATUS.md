# DOCK_STATUS.md — egui_dock → MojoGUI port ledger

Honest coverage ledger for the phase-1 in-window-docking port of `egui_dock`
0.19.x (reference: `/tmp/egui_dock-ref/src/`, **7,425 LOC**) into
`mojo-gui/mojo_src/widgets/dock/`.

Status vocabulary: **PORTED** (faithful, verified against the .rs) · **PARTIAL**
(present but diverges or is incomplete) · **STUBBED** (placeholder / no-op) ·
**DEFERRED** (intentionally out of phase-1 scope).

Audited by the skeptic agent (read-only). Findings with file:line are in
`DOCK_FINDINGS.md`.

---

## Per-module ledger

### `dock_state/tree/` — the layout model (ported into `model.mojo`)

| egui_dock module | Mojo | Status | Notes |
|---|---|---|---|
| `tree/node_index.rs` (heap indexing: left/right/parent/level/children_at/left/right) | `model.mojo` free fns `node_left/right/parent/level/children_*` | **PORTED** | Bit-faithful. `parent`→`-1` sentinel for None. `level` reimplemented without `leading_zeros`, verified equivalent. |
| `tree/tab_index.rs` (`TabIndex`, `TabPath`, `NodePath`) | `comptime TabIndex = Int` | **PARTIAL** | `TabIndex` kept as plain Int. `TabPath`/`NodePath` DEFERRED (single surface ⇒ surface component unused). |
| `tree/node/leaf.rs` (`LeafNode`) | `struct LeafNode` | **PORTED** | rect/viewport/tabs/active/collapsed. `scroll` DEFERRED. `set_active_tab`→Bool. `remove_tab` saturating-active faithful. `active_focused`/`retain_tabs`/Index ops not ported (unused). |
| `tree/node/split.rs` (`SplitNode`) | `struct SplitNode` | **PORTED** | rect/fraction(f32→Float64)/fully_collapsed/collapsed_leaf_count. |
| `tree/node/mod.rs` (`Node` enum) | `struct Node` (tag + both payloads) | **PORTED** | Empty/Leaf/Vertical/Horizontal via `kind`. All predicates, rect/set_rect, split_in_place (`mem::replace`), collapse accessors ported. `filter_map_tabs/map_tabs/retain_tabs/tabs_mut/iter_tabs*` DEFERRED (tab-type remap not needed for concrete `DockTab`). |
| `tree/mod.rs` (`Tree`) | `struct Tree` | **PORTED** (mostly) | `new/empty/len/is_empty/num_tabs/root_node/leaf/is_leaf/set/focused_leaf/find_active*/first_leaf/split(+tabs/left/right/above/below)/remove_leaf/remove_tab/push_to_first_leaf/push_to_focused_leaf/node_update_collapsed/find_tab` all ported. Subtree relocation (`split`) and sibling pull-up (`remove_leaf`) ported verbatim. **`find_active` semantics changed** (returns first-leaf index, not focused-leaf viewport — see findings). `balance/filter_map_tabs/map_tabs/retain_tabs/iter*/root_node_mut/leaf_mut` DEFERRED. |
| `tree/tab_iter.rs` (`TabIter`) | — | **DEFERRED** | Iterator type; not needed (host walks leaves directly). |
| `dock_state/mod.rs` (`DockState`) | `struct DockState` | **PARTIAL** | `new/main_surface/push_to_focused_leaf` ported. Multi-surface (`surfaces` Vec, `focused_surface`), `Index`/`IndexMut`, `detach_tab`, `split` (state-level), `find_active_focused`, `set_focused_node` (state-level), `translations` all DEFERRED. `main_surface()` returns a COPY (Mojo can't hand `&mut`). |
| `dock_state/surface.rs` / `surface_index.rs` | — | **DEFERRED** | Single GLFW window ⇒ main surface only. |
| `dock_state/window_state.rs` | — | **DEFERRED** | Separate-OS-window tearing — no MojoGUI equivalent. |
| `dock_state/translations.rs` | — | **DEFERRED** | i18n strings; no context menus/buttons to label. |
| `dock_state/error.rs` (`Error`/`Result`) | sentinels (`-1`, `Bool`, zero-rect) | **PARTIAL** | Result/Option lowered to sentinels per spec. |

### `widgets/dock_area/` — layout/render/interaction (ported into `area.mojo`)

| egui_dock module | Mojo | Status | Notes |
|---|---|---|---|
| `show/main_surface.rs` (root surface walk) | `layout()` / `_layout_node` | **PORTED** | Recursive rect division. |
| `show/mod.rs` `compute_rect_sizes` (split rect math) | `_layout_node` split branch | **PARTIAL** | Fraction semantics diverge: Rust splits the FULL rect at `fraction` and centers an `sw`-wide separator on the midpoint; Mojo applies `fraction` to `(total − sw)` and places the whole separator AFTER the first child. Off by ≲sw px; internally consistent w/ splitter draw+drag. Collapsed-child branch DEFERRED. |
| `show/mod.rs` `show_separator` (draw + drag clamp) | `_draw_splitter` + `_drag_splitter_to` | **PARTIAL** | Draw faithful to Mojo's own layout. **Drag model differs**: Rust applies relative `drag_delta` and clamps with dynamic `min=(separator.extra/range)` (extra=175); Mojo sets fraction ABSOLUTELY from cursor and clamps to fixed 0.05/0.95. Double-click-reset-to-0.5 and arrow-key nudge NOT ported. |
| `show/leaf.rs` `tab_bar` / `tab_body` (viewport) | `_draw_leaf` + viewport in `_layout_node` | **PARTIAL** | `viewport = rect − tab strip` faithful. Tabs drawn fixed-width L→R (Mojo `_tab_strip_width`), NOT egui's text-measured/`fill_tab_bar` widths. Tab scroll, add(+)/close-all/collapse buttons, hover-name, context menus DEFERRED. Close 'x' per-tab PORTED. |
| `drag_and_drop.rs` `resolve_traditional` (drop zones) | `_zone_at` / `_zone_preview_rect` / `_commit_drop` | **PARTIAL** | **Different geometry**: Rust uses a center coverage square (`center_drop_coverage=0.25`) + diagonal-quadrant split (lines x−y=0, −x−y=0) for the 4 edges; Mojo uses a closest-edge band (`EDGE_ZONE_FRAC=0.30`) with a center remainder. Same 5 outcomes (append + 4 splits), materially different hit regions. `is_on_title_bar` (insert-at-index when dropping on a tab title) NOT ported — every center drop is Append. |
| `drag_and_drop.rs` `resolve_icon_based` (overlay buttons) | — | **DEFERRED** | Alternate icon-button overlay UI. |
| `drag_and_drop.rs` window/lock/fade logic | — | **DEFERRED** | Window previews, soft/hard lock, fade timing. |
| `allowed_splits.rs` (`AllowedSplits`) | — | **STUBBED** | No `AllowedSplits` type; all four splits always allowed. |
| `tab_removal.rs` (`TabRemoval`) | inline `remove_tab` on click | **PARTIAL** | Close button removes immediately; no deferred `to_remove` queue, no `force_close`. |
| `state.rs` (`State`: hover_pos, drag/drop state) | inline fields on `DockAreaInt` | **PARTIAL** | Drag/press/hover tracked as flat fields; faithful enough for phase-1. |
| `mod.rs` (`DockArea` builder + option flags) | `DockAreaInt` + `create_dock_area_int` | **PARTIAL** | Bounds/state/style + handle_mouse_event/render. Builder option flags (`draggable_tabs`, `show_close_buttons`, `tab_context_menus`, `show_add_*`, `allowed_splits`, `window_bounds`, secondary-button, …) DEFERRED. **Constructor/demo contract is currently BROKEN — see findings #1.** |
| `tab_viewer.rs` (`TabViewer` trait) | host content-rect API (`leaf_count`/`visible_leaf_index`/`leaf_body_rect`/`leaf_active_tab_id`) | **PORTED (adapted)** | Immediate-mode `TabViewer::ui` → retained content-rect callback. `leaf_body_rect` correctly excludes the tab strip. Sufficient for a host to draw content; `title/closeable/on_close/context_menu/clear_background` etc. NOT exposed. |

### `style.rs` → `style.mojo`

| egui_dock | Mojo | Status | Notes |
|---|---|---|---|
| `Style` (deep sub-style tree, `from_egui`) | `DockStyle` (flattened) | **PARTIAL** | Sizes faithful: tab_bar.height=24, separator.width=1.0 (Mojo widens to 4px grab — documented). selection_color=rgb(0,191,255)*0.5 faithful. Sub-styles flattened to one ColorInt set; corner radius, strokes, inner_margin, fill_tab_bar, hundreds of button colors NOT modeled. |

### `utils.rs`, `lib.rs`

| egui_dock | Mojo | Status |
|---|---|---|
| `utils.rs` (`expand_to_pixel`, `map_to_pixel`, rect helpers) | — | **DEFERRED** (integer px ⇒ no pixel-rounding helpers needed) |
| `lib.rs` (re-exports, docs) | — | n/a |

---

## Honest coverage estimate

Phase-1 scope (in-window docking, main surface) is the right ~25–30% of the
crate; the rest is explicitly deferred (windows, serde, context menus,
add-popups, collapse, scroll, i18n, tab-type remap).

- **Within phase-1 scope:** the **model (`model.mojo`) is ~90% faithful** — the
  hard parts (heap indexing, split subtree-relocation, remove_leaf pull-up,
  collapse bookkeeping) are ported verbatim and look correct. The **area
  (`area.mojo`) is ~60% faithful**: layout/draw work, but drop-zone geometry,
  splitter-drag model, and tab-strip widths are adaptations rather than ports,
  and insert-on-title-bar is missing.
- **Against the full 7,425-LOC crate:** real functional coverage ≈ **22–27%**.
  Most of the crate is the deferred surfaces/windows/overlay/buttons/i18n
  machinery that phase-1 deliberately excludes.

## Blocking issue

`dock_demo.mojo` does **not compile** as of this audit: `create_dock_area_int`
takes 4 args (empty state) but the demo calls it with 5 (`state^`) and never
calls `set_state`. See `DOCK_FINDINGS.md` #1. Definition-of-done (EXIT 0) is
currently unmet.
