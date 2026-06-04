# DND_STATUS.md — egui_dnd → MojoGUI port ledger

Audit date: 2026-06-04. Auditor: read-only skeptic pass.
Reference: `/tmp/hello_egui-ref/crates/egui_dnd/src/` (1,521 LOC).
Ported: `mojo_src/widgets/dnd/dnd.mojo` (458 LOC) + `dnd_demo.mojo`.

## Ported (faithful or adapted)

| egui_dnd construct | Rust ref | Mojo | Status |
|---|---|---|---|
| `utils::shift_vec(from,to,vec)` | utils.rs:30-43 | `shift_vec` dnd.mojo:108-138 | FAITHFUL — remove+insert is bit-identical to rotate_left/rotate_right incl. from<to → insert_at=to-1 (traced 0→2, 2→0, all 4×5 from/to pairs preserve elements, see DND_FINDINGS #1) |
| `DragUpdate{from,to}` | state.rs:27-33 | `DragUpdate` dnd.mojo:58-70 | FAITHFUL (field rename from→from_, usize→Int) |
| `DragDropResponse` (subset) | state.rs:37-101 | `DragDropResponse` dnd.mojo:72-101 | PARTIAL — see "Deferred fields" below |
| `is_dragging()` | state.rs:58 / :179-181 | `.is_dragging` flag | adapted (bool field vs enum match) |
| `is_drag_finished()` | state.rs:71-73 | `.finished` flag | adapted |
| `dragged_item_id()` | state.rs:64-66 | `.dragged_id` (-1=none) | adapted (Int32 vs Option<Id>) |
| `update: Option<DragUpdate>` | state.rs:43 | `.has_update`+`.from_`+`.to` | adapted (flattened Option) |
| reorder-on-drop (`show_vec` → `update_vec`) | lib.rs:178-189, state.rs:77-83 | `_on_release` dnd.mojo:363-395 | adapted — instant reorder, no `has_changed`-vs-`finished` distinction |
| live `update` during drag | state.rs:621-641 | `on_mouse_move` dnd.mojo:350-361 | PARTIAL — see FINDINGS #2 (different hover model) |
| floating dragged row render | item.rs:266-302 | `draw` dnd.mojo:421-435 | adapted (no animation, no Area/layer) |
| insertion indicator | (egui animates gap) | gap line dnd.mojo:421-425 | NEW (egui has no explicit line; it animates item slide) |

## Deferred (intentionally NOT ported — phase 1)

| Feature | Rust ref | Notes |
|---|---|---|
| Return animation (item slides back/into place on drop) | state.rs:656-659 `TransitioningBackAfterDragFinished`, item.rs:114-161, lib.rs:97-100 | DEFERRED per spec; `_on_release` reorders instantly. TODO at dnd.mojo:366-368. |
| Swap animation (items slide as you hover) | item.rs:87-94,172-225 `animate_position`, lib.rs:102-108 | DEFERRED. |
| Touch config / drag delay / scroll tolerance | state.rs:386-443 `DragDropConfig`, :458-469 | DEFERRED — Mojo arms drag on press immediately, no delay/threshold. |
| Click-threshold detection state machine | state.rs:142-170 `DragDetectionState`, :336-357 | DEFERRED — Mojo has no press-vs-drag disambiguation; press == drag start. |
| Drag CANCELLATION (cursor not over handle; not over target) | state.rs:575-578, :670-680, :96-99 | **NOT PORTED, NOT DOCUMENTED as deferred** — see FINDINGS #5. |
| `cancellation_reason` | state.rs:45,96-99 | DEFERRED. |
| `is_evaluating_drag()` / `has_changed` | state.rs:52-54, :46, :77-78 | DEFERRED (no eval phase). |
| Selectable-label suppression in handle | state.rs:256-287 | DEFERRED (no rich item UI). |
| Custom item UI / `show_custom` | lib.rs:206-222, item_iterator.rs | DEFERRED — items are fixed `{id,label}` rows, no closure UI. |
| Sized / horizontal-wrapped variants | lib.rs:157-204, item.rs:44-51,166-208 | DEFERRED — vertical fixed-height rows only. |
| Drag handle (only-handle-is-draggable) | state.rs:127-384 `Handle` | DEFERRED — whole row is the grab area. |
| Horizontal layout / `main_wrap` | item_iterator.rs:140-153, :164-167 | DEFERRED — vertical only. |
| ScrollArea integration (`scroll_to_rect`) | state.rs:606-611 | DEFERRED. |

## Honest coverage estimate

- **Reorder primitive (`shift_vec`): 100% faithful.** This is the load-bearing 13-LOC core and it is correct.
- **Response/update data model: ~70%** (Option flattened, drag/finished/dragged_id present; cancellation, has_changed, evaluating, cancellation_reason absent).
- **Drag lifecycle: ~40%** — press/move/release works and never loses items, but the detection state machine (delay, click threshold, cancellation, transition-back) is absent; the hover→target mapping uses a different model than egui (FINDINGS #2).
- **Rendering/animation: ~15%** — static rows + floating row + a gap line; ALL animation (the crate's largest single concern, item.rs + much of state.rs) is deferred.
- **Layout variants (sized/horizontal/custom/handle/touch): 0%.**

**Overall faithful coverage of the 1,521-LOC crate: ~20-25%.** The deferred surface (animation, detection state machine, layout variants, custom UI) is the bulk of the crate. What IS ported is the conceptual spine (shift_vec + a from→to update applied on drop) and it is functionally sound for a phase-1 instant-reorder vertical list. Faithfulness of the *primitive* is high; faithfulness of the *interaction model* is approximate (see FINDINGS #2).
