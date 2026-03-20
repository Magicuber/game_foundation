if !global.paused {
    prev = Get_Ele_By_Index(global.current_ele.index - 1)
    if prev != noone && prev.unlocked {
        global.current_ele = prev
        with (o_element) { image_index = global.current_ele.index }
    }
}