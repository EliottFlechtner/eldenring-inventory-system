/// scr_inventory_fill
/// Helpers to fill an inventory (see scr_inventory_core) from global.item_db.

/// @function inventory_clear(_inventory)
/// @description Empty every slot in an inventory.
/// @param {Struct.Inventory} _inventory The inventory to clear.
/// @returns {undefined} No value is returned; the inventory is updated in place.
function inventory_clear(_inventory) {
    if (!is_struct(_inventory)) return;

    for (var i = 0; i < _inventory.capacity; i++) {
        _inventory.slots[i] = undefined;
    }

    inventory_notify_changed(_inventory);
}

#region Random fill
/// @function inventory_fill_random(_inventory, _config)
/// @description Add randomly selected database items until full or the configured pick limit is reached.
/// @param {Struct.Inventory} _inventory The inventory to fill.
/// @param {Struct} _config Optional categories, excluded ids, stack quantity bounds, uniqueness, pick limit, clear flag, and random seed.
/// @returns {Real} The total quantity successfully added.
function inventory_fill_random(_inventory, _config = {}) {
    if (!is_struct(_inventory)) return 0;
    if (!is_struct(_config)) _config = {};

    var _categories = _config[$ "categories"];
    var _exclude = _config[$ "exclude"];
    var _min_qty = max(1, _config[$ "min_qty"] ?? 1);
    var _max_qty = _config[$ "max_qty"];
    var _unique = _config[$ "unique"] ?? false;
    var _max_items = _config[$ "max_items"] ?? infinity;

    if (_config[$ "clear"] ?? false) inventory_clear(_inventory);
    // Seeding the built-in RNG also affects other random calls in the game.
    if (!is_undefined(_config[$ "seed"])) random_set_seed(_config.seed);

    var _pool = item_database_get_ids(_categories, _exclude);
    var _total = 0;
    var _picks = 0;

    while (array_length(_pool) > 0 && _picks < _max_items) {
        if (inventory_find_empty_slot(_inventory) == -1) break;

        // Randomly pick an item from the pool
        var _index = irandom(array_length(_pool) - 1);
        var _id = _pool[_index];
        var _def = item_definition_get(_id);
        var _qty = 1;

        // Stack it if possible, a random amount within the specified range
        if (_def.stackable) {
            var _hi = min(_max_qty ?? _def.max_stack, _def.max_stack);
            _qty = irandom_range(min(_min_qty, _hi), _hi);
        }

        // Add the item to the inventory (should have room as checked before entering)
        var _added = inventory_add(_inventory, _id, _qty);
        _total += _added;
        _picks++;

        // Stop retrying an item that no longer fits.
        if (_unique || _added < _qty) array_delete(_pool, _index, 1);
    }

    return _total;
}
#endregion


#region Explicit entries and templates
/// @function inventory_fill_from_list(_inventory, _entries, _clear)
/// @description Add item quantities from struct or array entries; unknown item ids add nothing.
/// @param {Struct.Inventory} _inventory The inventory to fill.
/// @param {Array<Struct|Array>} _entries Entries containing an item id and optional quantity.
/// @param {Boolean} _clear Whether to empty the inventory before adding entries.
/// @returns {Real} The total quantity successfully added.
function inventory_fill_from_list(_inventory, _entries, _clear = false) {
    if (!is_struct(_inventory) || !is_array(_entries)) return 0;
    if (_clear) inventory_clear(_inventory);

    var _total = 0;

    for (var i = 0; i < array_length(_entries); i++) {
        var _entry = _entries[i];
        var _id, _qty;

        if (is_array(_entry)) {
            _id = _entry[0];
            _qty = array_length(_entry) > 1 ? _entry[1] : 1;
        } else if (is_struct(_entry)) {
            _id = _entry[$ "id"];
            _qty = _entry[$ "qty"] ?? 1;
        } else {
            continue;
        }

        _total += inventory_add(_inventory, _id, _qty);
    }

    return _total;
}


/// @function inventory_fill_from_config(_inventory, _config)
/// @description Fill an inventory from explicit entries, a named template, or random-fill options.
/// @param {Struct.Inventory} _inventory The inventory to fill.
/// @param {Struct} _config Configuration containing entries, a template name, or random-fill options.
/// @returns {Real} The total quantity successfully added; zero for an unknown template.
function inventory_fill_from_config(_inventory, _config) {
    if (!is_struct(_config)) return inventory_fill_random(_inventory);

    if (!is_undefined(_config[$ "entries"])) {
        return inventory_fill_from_list(_inventory, _config.entries, _config[$ "clear"] ?? false);
    }

    var _template = _config[$ "template"];
    if (is_string(_template)) {
        if (!is_struct(global[$ "inventory_templates"]) || !variable_struct_exists(global.inventory_templates, _template)) {
            return 0;
        }
        return inventory_fill_from_list(
            _inventory,
            variable_struct_get(global.inventory_templates, _template),
            _config[$ "clear"] ?? false
        );
    }

    return inventory_fill_random(_inventory, _config);
}
#endregion
