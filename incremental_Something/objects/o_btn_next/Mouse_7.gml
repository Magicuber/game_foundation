if !global.paused {
    var next = Get_Ele_By_Index(global.current_ele.index + 1)
    if next != noone && next.unlocked {
        global.current_ele = next
        with (o_element) { image_index = global.current_ele.index }
    }
}
