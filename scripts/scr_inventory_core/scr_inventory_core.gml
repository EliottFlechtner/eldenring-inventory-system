/// scr_inventory_core

// Create a new empty inventory.
function inventory_create(_capacity) {
    if (!is_real(_capacity)) {
        _capacity = 24;
    }

    _capacity = floor(_capacity);

    if (_capacity < 1) {
        _capacity = 1;
    }

    return {
        capacity: _capacity,
        slots: array_create(_capacity, undefined)
    };
}


// Return the number of valid items of this type.
function inventory_count_item(_inventory, _item_id) {
    if (!is_struct(_inventory)) return 0;

    var _total = 0;

    for (var i = 0; i < _inventory.capacity; i++) {
        var _slot = _inventory.slots[i];

        if (is_struct(_slot) && _slot.item_id == _item_id) {
            _total += _slot.quantity;
        }
    }

    return _total;
}


// Find the first occupied slot containing this item.
// Returns -1 if it is not present.
function inventory_find_slot(_inventory, _item_id) {
    if (!is_struct(_inventory)) return -1;

    for (var i = 0; i < _inventory.capacity; i++) {
        var _slot = _inventory.slots[i];

        if (is_struct(_slot) && _slot.item_id == _item_id) {
            return i;
        }
    }

    return -1;
}


// Find the first empty slot.
// Returns -1 if the inventory is full.
function inventory_find_empty_slot(_inventory) {
    if (!is_struct(_inventory)) return -1;

    for (var i = 0; i < _inventory.capacity; i++) {
        if (is_undefined(_inventory.slots[i])) {
            return i;
        }
    }

    return -1;
}


// Add items and return the quantity successfully added.
// Any quantity that does not fit remains with the caller.
function inventory_add(_inventory, _item_id, _amount) {
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

                if (_remaining <= 0) return _added;
            }
        }
    }

    // Then, use empty slots.
    while (_remaining > 0) {
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

    return _added;
}


// Remove a quantity of an item.
// Returns true only if the entire requested quantity was removed.
function inventory_remove(_inventory, _item_id, _amount) {
    if (!is_struct(_inventory)) return false;
    if (!is_string(_item_id)) return false;
    if (!is_real(_amount)) return false;
    if (_amount <= 0 || floor(_amount) != _amount) return false;

    // Validate first so a failed removal changes nothing.
    if (inventory_count_item(_inventory, _item_id) < _amount) {
        return false;
    }

    var _remaining = _amount;

    for (var i = 0; i < _inventory.capacity; i++) {
        var _slot = _inventory.slots[i];

        if (is_struct(_slot) && _slot.item_id == _item_id) {
            var _take = min(_slot.quantity, _remaining);

            _slot.quantity -= _take;
            _remaining -= _take;

            if (_slot.quantity <= 0) {
                _inventory.slots[i] = undefined;
            }

            if (_remaining <= 0) {
                return true;
            }
        }
    }

    return true;
}


// Safely return the slot data at a given index.
// Returns undefined for invalid or empty slots.
function inventory_get_slot(_inventory, _index) {
    if (!is_struct(_inventory)) return undefined;
    if (!is_real(_index)) return undefined;
    if (_index < 0 || _index >= _inventory.capacity) {
        return undefined;
    }

    return _inventory.slots[_index];
}
