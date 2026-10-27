/// @function hotbar_create()
function hotbar_create() {
    return {
        slot_count: 4,
        slots: ["", "", "", ""],
        selected_slot: 0
    };
}


/// @function hotbar_assign(_hotbar, _slot, _item_id)
function hotbar_assign(_hotbar, _slot, _item_id) {
    if (_slot < 0 || _slot >= _hotbar.slot_count) {
        return false;
    }

    var def = item_definition_get(_item_id);

    // Only assign valid consumable items.
    if (is_undefined(def)) return false;
    if (def.category != "consumable") return false;

    // An item can only be assigned to one quick slot.
    for (var i = 0; i < _hotbar.slot_count; i++) {
        if (i != _slot && _hotbar.slots[i] == _item_id) {
            return false;
        }
    }
    // TODO, review what should happen when 2 stacks of same item are wanted to be assigned as multiple quickslots

    _hotbar.slots[_slot] = _item_id;
    return true;
}


/// @function hotbar_use(_hotbar, _slot)
function hotbar_use(_hotbar, _slot) {
    if (_slot < 0 || _slot >= _hotbar.slot_count) {
        return inventory_action_result(false, "Invalid quick slot.");
    }

    var item_id = _hotbar.slots[_slot];

    if (item_id == "") {
        return inventory_action_result(false, "Quick slot is empty.");
    }

    // The item may have been consumed or discarded since assignment.
    if (inventory_count_item(global.player_inventory, item_id) <= 0) {
        _hotbar.slots[_slot] = "";
        return inventory_action_result(false, "No items remaining.");
    }

    return inventory_execute_action(item_id, "Use");
}


/// @function hotbar_cycle(_hotbar, _direction)
function hotbar_cycle(_hotbar, _direction) {
    _hotbar.selected_slot += _direction;

    if (_hotbar.selected_slot < 0) {
        _hotbar.selected_slot = _hotbar.slot_count - 1;
    }

    if (_hotbar.selected_slot >= _hotbar.slot_count) {
        _hotbar.selected_slot = 0;
    }
}