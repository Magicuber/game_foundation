visible  = false
//depth    = -20

// Panel dimensions
panel_x  = 54
panel_y  = 200
panel_w  = 972
panel_h  = 1400

// Scrolling
scroll_y       = 0
scroll_speed   = 20
max_scroll     = 0

// Each entry: { label, description, cost_func, buy_func, available_func }
upgrades = []

// --- Particle Smasher ---
var smasher = {
    label: "Particle Smasher",
    description: "Auto-fires protons at your element.",
    cost_func: function() {
        return string(global.smasher_cost) + " H"
    },
    buy_func: function() {
        if global.elements.ele_H.amt >= global.smasher_cost {
            global.elements.ele_H.amt -= global.smasher_cost
            global.smasher_lvl++
            Smasher_cost()
            with (o_controller_main) {
                gen_interval = max(5, 300 / global.smasher_lvl)
            }
            return true
        }
        return false
    },
    available_func: function() {
        return global.elements.ele_H.amt >= global.smasher_cost
    },
    level_func: function() {
        return "Lv " + string(global.smasher_lvl)
    }
}
array_push(upgrades, smasher)

// --- Element Unlock ---
var ele_unlock = {
    label: "Unlock Next Element",
    description: "Fuse your current element to discover the next.",
    cost_func: function() {
        var cost = global.elements[$ global.current_ele.produces].cost
        return string(cost) + " H  →  " + global.current_ele.produces
    },
    buy_func: function() {
        var next = global.current_ele.produces
        var cost = global.elements[$ next].cost
        if global.elements.ele_H.amt >= cost {
            global.elements.ele_H.amt -= cost
            global.elements[$ next].unlocked = true
            global.current_ele = global.elements[$ next]
            global.elements[$ next].show_in_counter = true
            with (o_element) {
                image_index = global.current_ele.index
            }
            return true
        }
        return false
    },
    available_func: function() {
        var next = global.current_ele.produces
        if next == "Dust" { return false }
        return global.elements.ele_H.amt >= global.elements[$ next].cost
    },
    level_func: function() {
        return global.current_ele.name
    }
}
array_push(upgrades, ele_unlock)

// Row layout constants
row_h        = 220
row_padding  = 20