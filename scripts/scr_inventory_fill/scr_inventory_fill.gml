/// scr_inventory_fill
/// Helpers to fill an inventory (see scr_inventory_core) from global.item_db.

// Remove every item from the inventory.
function inventory_clear(_inventory) {
    if (!is_struct(_inventory)) return;

    for (var i = 0; i < _inventory.capacity; i++) {
        _inventory.slots[i] = undefined;
    }
}


// Return the ids of items in global.item_db, optionally filtered.
// _categories: undefined, a category string, or an array of category strings.
// _exclude: undefined or an array of item ids to leave out.
function item_database_get_ids(_categories = undefined, _exclude = undefined) {
    if (is_string(_categories)) _categories = [_categories];

    var _keys = variable_struct_get_names(global.item_db);
    var _ids = [];

    for (var i = 0; i < array_length(_keys); i++) {
        var _def = variable_struct_get(global.item_db, _keys[i]);

        if (is_array(_categories) && !array_contains(_categories, _def.category)) continue;
        if (is_array(_exclude) && array_contains(_exclude, _keys[i])) continue;

        array_push(_ids, _keys[i]);
    }

    return _ids;
}


// Randomly add items until the inventory is full or the limit is reached.
// _config (all fields optional):
//   categories: string or array of categories to draw from (default: all)
//   exclude:    array of item ids never to add
//   min_qty / max_qty: quantity range for stackable items (default 1 / max_stack)
//   unique:     true to add each item id at most once (default false)
//   max_items:  number of random picks to make (default: until full)
//   clear:      true to empty the inventory first (default false)
//   seed:       if set, makes the result reproducible (uses random_set_seed)
// Returns the total quantity added.
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


// Fill from an explicit list of entries: [{ id: "arrow", qty: 40 }, ["potion", 3], ...].
// Unknown ids are skipped. Returns the total quantity added.
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


// Fill from a config struct. Either:
//   { entries: [...], clear: bool }          -> exact list (see inventory_fill_from_list)
//   { template: "samurai", clear: bool }     -> named entry in global.inventory_templates
//   { categories: ..., max_items: ... }      -> random fill (see inventory_fill_random)
// Returns the total quantity added.
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
