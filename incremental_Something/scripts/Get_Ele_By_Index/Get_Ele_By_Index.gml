function Get_Ele_By_Index(idx){
    ele_names = variable_struct_get_names(global.elements)
    for (i = 0; i < array_length(ele_names); i++) {
        var ele = global.elements[$ ele_names[i]]
        if ele.index == idx {
			return ele
		}
    }
    return noone
}