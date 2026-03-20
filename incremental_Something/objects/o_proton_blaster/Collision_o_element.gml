instance_destroy();
//instance_create_layer(x,y,"Instances",o_partical_spawning)
//global.elements[$ global.current_ele.produces].amt++

is_noble_gas = false

for (var i = 0; i < array_length(global.no_split); i++) {
    if global.current_ele.index == global.no_split[i] {
        is_noble_gas = true;
        break;
    }
}

target_index = global.elements[$ global.current_ele.produces].index

if !is_noble_gas && target_index >= 2 && random(1) < 0.75 {
    // ... your split_a / split_b / ele_a / ele_b lookup ...
	split_a = irandom_range(1, target_index - 1)
    split_b = target_index - split_a
	ele_names = variable_struct_get_names(global.elements);
    ele_a = undefined;
    ele_b = undefined;
	
	for (var i = 0; i < array_length(ele_names); i++) {
        var ele = global.elements[$ ele_names[i]];
        if ele.index == split_a { ele_a = ele_names[i]; }
        if ele.index == split_b { ele_b = ele_names[i]; }
    }
	
    if !is_undefined(ele_a) && !is_undefined(ele_b) {
        global.elements[$ ele_a].amt++
        global.elements[$ ele_b].amt++

        var p1 = instance_create_layer(x, y, "Instances", o_partical_spawning)
        p1.image_index = global.elements[$ ele_a].index

        var p2 = instance_create_layer(x, y, "Instances", o_partical_spawning)
        p2.image_index = global.elements[$ ele_b].index
    } else {
        instance_create_layer(x, y, "Instances", o_partical_spawning)
        global.elements[$ global.current_ele.produces].amt++
    }
} else {
    instance_create_layer(x, y, "Instances", o_partical_spawning)
    global.elements[$ global.current_ele.produces].amt++
}