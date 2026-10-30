/// scr_inventory_core

/// @function inventory_create(_capacity)
/// @description Create an empty inventory with a validated slot capacity.
/// @param {Real} _capacity The requested number of slots; invalid values default to 24 and values below one are raised to one.
/// @returns {Struct.Inventory} An inventory containing its capacity and empty slot array.
function inventory_create(_capacity) {
    if (!is_real(_capacity)) _capacity = global.player_inventory.capacity;

    _capacity = floor(_capacity);
    if (_capacity < 1) _capacity = 1;

    return {
        capacity: _capacity,
        slots: array_create(_capacity, undefined)
    };
}


#region Inventory queries
/// @function inventory_count_item(_inventory, _item_id)
/// @description Count all quantities of an item across inventory slots.
/// @param {Struct.Inventory} _inventory The inventory to search.
/// @param {String} _item_id The item id to count.
/// @returns {Real} The total quantity found, or zero for an invalid inventory.
function inventory_count_item(_inventory, _item_id) {
    if (!is_struct(_inventory)) return 0;

    var _total = 0;
    for (var i = 0; i < _inventory.capacity; i++) {
        var _slot = _inventory.slots[i];
        if (is_struct(_slot) && _slot.item_id == _item_id) _total += _slot.quantity;
    }

    return _total;
}


/// @function inventory_find_slot(_inventory, _item_id)
/// @description Find the first occupied slot containing an item.
/// @param {Struct.Inventory} _inventory The inventory to search.
/// @param {String} _item_id The item id to find.
/// @returns {Real} The zero-based slot index, or -1 if invalid or not found.
function inventory_find_slot(_inventory, _item_id) {
    if (!is_struct(_inventory)) return -1;

    for (var i = 0; i < _inventory.capacity; i++) {
        var _slot = _inventory.slots[i];
        if (is_struct(_slot) && _slot.item_id == _item_id) return i;
    }

    return -1;
}


/// @function inventory_find_empty_slot(_inventory)
/// @description Find the first unoccupied slot in an inventory.
/// @param {Struct.Inventory} _inventory The inventory to search.
/// @returns {Real} The zero-based slot index, or -1 if invalid or full.
function inventory_find_empty_slot(_inventory) {
    if (!is_struct(_inventory)) return -1;

    for (var i = 0; i < _inventory.capacity; i++) {
        if (is_undefined(_inventory.slots[i])) return i;
    }

    return -1;
}
#endregion


#region Inventory updates
/// @function inventory_add(_inventory, _item_id, _amount)
/// @description Add an item quantity to existing stacks and then empty slots.
/// @param {Struct.Inventory} _inventory The inventory to update.
/// @param {String} _item_id The item id to add.
/// @param {Real} _amount The positive whole-number quantity to add.
/// @returns {Real} The quantity added; any remainder stays with the caller.
function inventory_add(_inventory, _item_id, _amount) {
	// Validate the arguments
    if (!is_struct(_inventory)) return 0;
    if (!is_string(_item_id)) return 0;
    if (!is_real(_amount)) return 0;
    if (_amount <= 0 || floor(_amount) != _amount) return 0;

    var _definition = item_definition_get(_item_id);

    if (is_undefined(_definition)) return 0;

    var _remaining = _amount;
    var _added = 0;

    // First, fill existing stacks where possible.
    if (_definition.stackable) {
        for (var i = 0; i < _inventory.capacity; i++) {
            var _slot = _inventory.slots[i];

            if (is_struct(_slot) && _slot.item_id == _item_id) {
                var _space = _definition.max_stack - _slot.quantity;
                var _transfer = min(_space, _remaining);

                if (_transfer > 0) {
                    _slot.quantity += _transfer;
                    _remaining -= _transfer;
                    _added += _transfer;
                }

                if (_remaining <= 0) {
                    inventory_notify_changed(_inventory);
                    return _added;
                }
            }
        }
    }

    // Then, use empty slots.
    while (_remaining > 0) {
		// Store the rest if there is empty slots left
        var _empty = inventory_find_empty_slot(_inventory);
        if (_empty == -1) break;

        var _transfer = min(_definition.max_stack, _remaining);
        _inventory.slots[_empty] = {
            item_id: _item_id,
            quantity: _transfer
        };

        _remaining -= _transfer;
        _added += _transfer;

        // Non-stackable items have a maximum stack of one.
    }

    if (_added > 0) inventory_notify_changed(_inventory);

    return _added;
}


/// @function inventory_remove(_inventory, _item_id, _amount)
/// @description Remove a whole-number quantity if the inventory contains all of it.
/// @param {Struct.Inventory} _inventory The inventory to update.
/// @param {String} _item_id The item id to remove.
/// @param {Real} _amount The positive whole-number quantity to remove.
/// @returns {Boolean} Whether the full quantity was removed; failure leaves the inventory unchanged.
function inventory_remove(_inventory, _item_id, _amount) {
    if (!is_struct(_inventory)) return false;
    if (!is_string(_item_id)) return false;
    if (!is_real(_amount)) return false;
    if (_amount <= 0 || floor(_amount) != _amount) return false;

    // Validate first so a failed removal changes nothing.
    if (inventory_count_item(_inventory, _item_id) < _amount) return false;

    var _remaining = _amount;
    for (var i = 0; i < _inventory.capacity; i++) {
        var _slot = _inventory.slots[i];

        if (is_struct(_slot) && _slot.item_id == _item_id) {
			// Withdraw as much as possible from curent slot
            var _take = min(_slot.quantity, _remaining);
            _slot.quantity -= _take;
            _remaining -= _take;

			// Reset the inventory slot
            if (_slot.quantity <= 0) _inventory.slots[i] = undefined;
            
			// Successfully removed all the items
			if (_remaining <= 0) {
                inventory_notify_changed(_inventory);
                return true;
            }
        }
    }

    inventory_notify_changed(_inventory);
    return true;
}
#endregion


#region Slot access
/// @function inventory_get_slot(_inventory, _index)
/// @description Retrieve a slot's item data after validating the inventory and index.
/// @param {Struct.Inventory} _inventory The inventory to read.
/// @param {Real} _index The zero-based slot index.
/// @returns {Struct.InventorySlot|undefined} The slot data, or undefined for invalid or empty slots.
function inventory_get_slot(_inventory, _index) {
	// Validate arguments
    if (!is_struct(_inventory)) return undefined;
    if (!is_real(_index)) return undefined;
    if (_index < 0 || _index >= _inventory.capacity) return undefined;

    return _inventory.slots[_index];
}
#endregion
