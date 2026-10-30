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


/// @function hotbar_can_assign(_item_id)
/// @description Whether an item may sit in a quick slot: consumables and spirit ashes.
/// @param {String} _item_id The item id to check.
/// @returns {Boolean} True for assignable items.
function hotbar_can_assign(_item_id) {
    var _def = item_definition_get(_item_id);

    if (is_undefined(_def)) return false;

    return _def.category == "consumable" || _def.category == "spirit_ash";
}


/// @function hotbar_assign_result(_hotbar, _slot, _item_id)
/// @description Put an item in a quick slot, handling conflicts. An item lives in at most one slot:
/// assigning one that is already in another slot moves it, and swaps with whatever the target slot held.
/// @param {Struct.Hotbar} _hotbar The hotbar to update.
/// @param {Real} _slot The zero-based quick-slot index.
/// @param {String} _item_id The item id to assign.
/// @returns {Struct.ActionResult} Whether the hotbar changed, with a message describing what happened.
function hotbar_assign_result(_hotbar, _slot, _item_id) {
    if (!is_real(_slot) || _slot < 0 || _slot >= _hotbar.slot_count || floor(_slot) != _slot) {
        return inventory_action_result(false, "Invalid quick slot.");
    }

    if (!hotbar_can_assign(_item_id)) {
        return inventory_action_result(false, "Only consumables and spirit ashes can use quick slots.");
    }

    var _name = item_definition_get(_item_id).name;
    var _from = array_get_index(_hotbar.slots, _item_id);

    if (_from == _slot) {
        return inventory_action_result(false, _name + " is already in quick slot " + string(_slot + 1) + ".");
    }

    var _displaced = _hotbar.slots[_slot];
    var _message;

    _hotbar.slots[_slot] = _item_id;

    if (_from != -1) {
        // Moving within the bar: the previous occupant (if any) takes the vacated slot.
        _hotbar.slots[_from] = _displaced;

        _message = _displaced == ""
            ? "Moved " + _name + " to quick slot " + string(_slot + 1) + "."
            : "Swapped " + _name + " with " + item_definition_get(_displaced).name + ".";
    }
    else {
        _message = _displaced == ""
            ? "Assigned " + _name + " to quick slot " + string(_slot + 1) + "."
            : "Quick slot " + string(_slot + 1) + ": " + item_definition_get(_displaced).name + " replaced by " + _name + ".";
    }

    inventory_event_emit(INV_EVENT_HOTBAR);

    return inventory_action_result(true, _message);
}


/// @function hotbar_assign(_hotbar, _slot, _item_id)
/// @description Boolean wrapper around hotbar_assign_result().
/// @returns {Boolean} Whether the hotbar changed.
function hotbar_assign(_hotbar, _slot, _item_id) {
    return hotbar_assign_result(_hotbar, _slot, _item_id).ok;
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

    // Out of stock: keep the assignment (shown as x0) so it is ready once restocked.
    if (inventory_count_item(global.player_inventory, item_id) <= 0) {
        return inventory_action_result(false, "No items remaining.");
    }

    // A summoned spirit ash no longer offers Use, so its quick slot dismisses it instead.
    var _action = (global.player.summon == item_id) ? "Dismiss" : "Use";

    return inventory_execute_action(item_id, _action);
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