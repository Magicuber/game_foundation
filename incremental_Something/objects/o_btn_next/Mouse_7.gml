if !global.paused {
    
    if next != noone && next.unlocked {
        global.current_ele = next
        with (o_element) { image_index = global.current_ele.index }
    }
}
