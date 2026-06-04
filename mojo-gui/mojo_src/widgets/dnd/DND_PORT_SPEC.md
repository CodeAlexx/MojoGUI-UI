# egui_dnd → MojoGUI port spec (dnd addon)

Port the Rust crate `egui_dnd` (1,521 LOC, ref `/tmp/hello_egui-ref/crates/egui_dnd/src/`)
into a native MojoGUI drag-to-reorder list widget at `mojo-gui/mojo_src/widgets/dnd/`.

## Conventions (SAME verified Mojo 0.26.2 set as chart/dock)
out/mut/self (NO inout) · COMPOSE, no struct inheritance · comptime not alias ·
List-stored structs `(ImplicitlyCopyable, Movable)`, List-owning structs `(Copyable, Movable)`
+ `.copy()`/`^` · multi-value return via `Tuple[...]` explicit ctor (bare `(a,b)` is a hard
error) · NO libm (no math.cos/sin/log10) · imports inside dnd/: `from ...rendering_int import
RenderingContextInt, ColorInt, RectInt`, `from ...widget_int import MouseEventInt`. Build from
repo ROOT, compile-only (no run): `pixi run mojo build mojo-gui/<root>.mojo -o /tmp/x`; verify
package-internal files via a root harness with absolute imports that CONSTRUCTS+CALLS the code.

## Adaptation (immediate-mode → retained)
egui_dnd's `Dnd::show_vec` renders + reorders in one immediate call. MojoGUI is retained, so:
- `DndItem { id: Int32, label: String }` (concrete; egui's DragDropItem.id() → .id).
- `DndListInt` owns `List[DndItem]`, renders them as vertical draggable rows, tracks drag,
  and reorders its own list on drop. Host reads the order back + a DragDropResponse.

## Files
```
dnd/
  dnd.mojo   - DndItem; DragUpdate{from_:Int,to:Int}; DragDropResponse{has_update:Bool,from_,to,
               is_dragging:Bool,finished:Bool,dragged_id:Int32}; free fn shift_vec(mut list, from_, to)
               (PORT utils.rs::shift_vec EXACTLY — it's the reorder primitive); struct DndListInt
               (composes x/y/width/height/visible): rows of row_height; press on a row arms drag
               (record from index + grab offset); on_mouse_move tracks cursor → hovered insertion
               index (to); render draws static rows + an insertion-gap indicator + the dragged row
               floating at the cursor; release → shift_vec(from,to), set last_response, clear drag.
               API: create_dnd_list_int(x,y,w,h), add_item(id,label)/set_items, handle_mouse_event,
               on_mouse_move(px,py), draw(ctx), update, item_count(), item_id(i), item_label(i),
               order()->List[Int32], last_response()->DragDropResponse, set_style/colors.
dnd_demo.mojo (root) - a DndListInt with ~6 labeled items; window loop; drag rows to reorder;
               header prints the live order + last from->to. (return/swap ANIMATIONS deferred —
               instant reorder for phase 1; note in code.)
DND_STATUS.md - ported vs deferred (animations, touch config, selectable labels, custom item ui).
```

## Faithful bits (read the .rs)
- `utils.rs::shift_vec(from, to, vec)` — remove at `from`, insert at adjusted `to`. Port the
  index-adjustment exactly (when from < to, the insert index shifts by one after removal).
- `state.rs` DragUpdate{from,to} + DragDropResponse semantics (is_dragging / is_drag_finished /
  update applied via shift_vec). Insertion index = which gap the cursor is over (row midpoints).

## Done (phase 1)
`pixi run mojo build mojo-gui/dnd_demo.mojo` → EXIT 0, 0 libm undefined. Demo: drag a row, the
list visibly reorders, order()/last_response reflect the move.
