"""
_dnd_check.mojo — package-internal elaboration harness for dnd/dnd.mojo.

This is NOT a window demo (dnd_demo.mojo covers that).  Its job is to CONSTRUCT
a DndListInt, populate it, and synthesize a full press -> move -> release
MouseEventInt sequence so every dnd.mojo + DndListInt method body (handle_mouse_
event/_on_press/on_mouse_move/_gap_at/_row_at/_on_release/shift_vec/order/
item_label/last_response/draw helpers) is type-checked and linked.

Compile-only check from repo ROOT (do NOT run — GPU may be in use):
    pixi run mojo build mojo-gui/_dnd_check.mojo -o /tmp/dnd_check

The drag drives row 0 ("Apple") downward past rows 1 and 2, which lands the
cursor in the gap after row 2 -> shift_vec(0, 3) -> the from_ < to branch.
"""

from mojo_src.widget_int import MouseEventInt
from mojo_src.widgets.dnd.dnd import (
    DndListInt,
    DndItem,
    DragUpdate,
    DragDropResponse,
    DndStyle,
    shift_vec,
    create_dnd_list_int,
)


comptime MB_LEFT: Int32 = 0
comptime ROW_H: Int32 = 26
comptime LIST_X: Int32 = 40
comptime LIST_Y: Int32 = 80


fn main():
    print("dnd_check — elaborating DndListInt + dnd.mojo method bodies")

    # --- Build the list (factory + add_item) --------------------------------
    var dnd = create_dnd_list_int(LIST_X, LIST_Y, 400, 600)
    dnd.set_row_height(ROW_H)
    dnd.set_style(DndStyle())
    dnd.add_item(1, String("Apple"))
    dnd.add_item(2, String("Banana"))
    dnd.add_item(3, String("Cherry"))
    dnd.add_item(4, String("Date"))
    dnd.add_item(5, String("Elderberry"))
    dnd.add_item(6, String("Fig"))

    print("initial count =", dnd.item_count())
    _print_order(dnd)

    # --- Synthesize a drag: press row 0, move down, release in gap 3 --------
    # Press inside row 0 (top region of the first row).
    var press_y = LIST_Y + Int32(4)
    var pressed_ok = dnd.handle_mouse_event(
        MouseEventInt(LIST_X + Int32(20), press_y, MB_LEFT, True))
    print("press handled =", pressed_ok)

    # Drag the cursor down through rows 1 and 2; feed several moves so the
    # in-progress drag tracks (on_mouse_move + _gap_at exercised each frame).
    dnd.on_mouse_move(LIST_X + Int32(20), LIST_Y + ROW_H + Int32(8))
    dnd.update()
    dnd.on_mouse_move(LIST_X + Int32(20), LIST_Y + ROW_H * Int32(2) + Int32(8))
    dnd.update()
    # Settle in the lower half of row 2 -> insertion gap 3 (after Cherry).
    dnd.on_mouse_move(LIST_X + Int32(20), LIST_Y + ROW_H * Int32(2) + Int32(20))
    dnd.update()

    var mid = dnd.last_response()
    print("mid-drag dragging =", mid.is_dragging,
          " dragged_id =", mid.dragged_id,
          " to =", mid.to)

    # Release at the same lower-half-of-row-2 position -> shift_vec(0, 3).
    var released_ok = dnd.handle_mouse_event(
        MouseEventInt(LIST_X + Int32(20),
                      LIST_Y + ROW_H * Int32(2) + Int32(20),
                      MB_LEFT, False))
    print("release handled =", released_ok)

    # --- Read back the result (last_response + order) -----------------------
    var resp = dnd.last_response()
    print("after release: has_update =", resp.has_update,
          " finished =", resp.finished,
          " from =", resp.from_, " to =", resp.to,
          " dragged_id =", resp.dragged_id)

    print("final count =", dnd.item_count())
    _print_order(dnd)
    print("top label now =", dnd.item_label(0))

    # --- Directly elaborate shift_vec + the value structs -------------------
    var local = List[DndItem]()
    local.append(DndItem(10, String("x")))
    local.append(DndItem(20, String("y")))
    local.append(DndItem(30, String("z")))
    local.append(DndItem(40, String("w")))
    # utils.rs doctest: [1,2,3,4] --0->2--> [2,1,3,4] (from_ < to branch).
    shift_vec(local, 0, 2)
    print("shift_vec(0,2) ids:", Int(local[0].id), Int(local[1].id),
          Int(local[2].id), Int(local[3].id))
    # And the from_ > to branch: --2->0--> [3,1,2,4] relative to the above.
    shift_vec(local, 2, 0)
    print("shift_vec(2,0) ids:", Int(local[0].id), Int(local[1].id),
          Int(local[2].id), Int(local[3].id))

    # Touch DragUpdate so its body elaborates too.
    var upd = DragUpdate(0, 3)
    print("DragUpdate from/to:", upd.from_, upd.to)

    print("dnd_check done")


fn _print_order(dnd: DndListInt):
    var ids = dnd.order()
    var s = String("order ids: ")
    for i in range(len(ids)):
        if i > 0:
            s += String(",")
        s += String(Int(ids[i]))
    print(s)
