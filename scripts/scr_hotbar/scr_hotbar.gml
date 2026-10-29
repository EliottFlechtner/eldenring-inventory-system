/// @function hotbar_create()
/// @description Create an empty four-slot hotbar.
/// @returns {Struct.Hotbar} A hotbar with empty slots and the first slot selected.
function hotbar_create() {
    return {
        slot_count: 4,
        slots: ["", "", "", ""],
        selected_slot: 0
    };
}


/// @function hotbar_assign(_hotbar, _slot, _item_id)
/// @description Assign a valid consumable item to an unoccupied quick slot.
/// @param {Struct.Hotbar} _hotbar The hotbar to update.
/// @param {Real} _slot The zero-based quick-slot index.
/// @param {String} _item_id The consumable item id to assign.
/// @returns {Boolean} Whether the item was assigned successfully.
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
/// @description Use the item assigned to a quick slot if it remains in inventory.
/// @param {Struct.Hotbar} _hotbar The hotbar containing the assignment.
/// @param {Real} _slot The zero-based quick-slot index.
/// @returns {Struct.ActionResult} Whether use succeeded and a message describing the result.
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
/// @description Move the selected quick slot by one position, wrapping at either end.
/// @param {Struct.Hotbar} _hotbar The hotbar whose selection to update.
/// @param {Real} _direction The number of slot positions to move.
/// @returns {undefined} No value is returned; the hotbar selection is updated in place.
function hotbar_cycle(_hotbar, _direction) {
    _hotbar.selected_slot += _direction;

    if (_hotbar.selected_slot < 0) {
        _hotbar.selected_slot = _hotbar.slot_count - 1;
    }

    if (_hotbar.selected_slot >= _hotbar.slot_count) {
        _hotbar.selected_slot = 0;
    }
}