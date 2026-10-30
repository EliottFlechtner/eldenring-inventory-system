/// scr_save_load
/// Save and load the player's progress: inventory slots, quantities, equipment, talismans, quick slots,
/// HP, FP, and runes. Loading validates everything against the current item database and only applies the
/// result once the whole file has been checked, so a bad file never leaves the game half-loaded.

#macro INVENTORY_SAVE_FILE "inventory_save.json"
#macro INVENTORY_SAVE_VERSION 1


/// @function save_serialize()
/// @description Capture the current game state as plain data.
/// @returns {Struct} A JSON-friendly struct.
function save_serialize() {
    var _inv = global.player_inventory;
    var _player = global.player;
    var _hotbar = global.player_hotbar;
    var _slots = [];

    // Only occupied slots are stored, with their positions.
    for (var i = 0; i < _inv.capacity; i++) {
        var _slot = _inv.slots[i];

        if (is_struct(_slot)) {
            array_push(_slots, { slot: i, id: _slot.item_id, qty: _slot.quantity });
        }
    }

    return {
        version: INVENTORY_SAVE_VERSION,
        player: {
            name: _player.name,
            health: _player.health_,
            fp: _player.fp,
            runes: _player.runes
        },
        inventory: { capacity: _inv.capacity, slots: _slots },
        equipment: variable_clone(_player.equipment),
        talismans: variable_clone(_player.talismans),
        hotbar: { slots: variable_clone(_hotbar.slots), selected: _hotbar.selected_slot }
    };
}


/// @function save_apply(_data)
/// @description Validate saved data and, if it is usable, apply it to the live game state. Unknown items,
/// mismatched equipment, and out-of-range values are dropped or clamped and reported in `warnings`.
/// @param {Struct} _data The data from save_serialize() (or parsed from a save file).
/// @returns {Struct.ActionResult} The result, with a `warnings` array of strings.
function save_apply(_data) {
    var _warnings = [];

    if (!is_struct(_data)) return save_fail("Save data is corrupt.");
    if (_data[$ "version"] != INVENTORY_SAVE_VERSION) return save_fail("Unsupported save version.");

    var _player_data = _data[$ "player"];
    var _inv_data = _data[$ "inventory"];
    if (!is_struct(_player_data) || !is_struct(_inv_data) || !is_array(_inv_data[$ "slots"])) {
        return save_fail("Save data is incomplete.");
    }

    var _player = global.player;
    var _inv = global.player_inventory;
    var _hotbar = global.player_hotbar;

    #region Inventory
    var _new_slots = array_create(_inv.capacity, undefined);
    var _overflow = [];
    var _entries = _inv_data.slots;

    for (var i = 0; i < array_length(_entries); i++) {
        var _e = _entries[i];
        var _def = is_struct(_e) ? item_definition_get(_e[$ "id"]) : undefined;

        if (is_undefined(_def)) {
            array_push(_warnings, "Skipped unknown item in slot entry " + string(i) + ".");
            continue;
        }

        var _qty = _e[$ "qty"];
        if (!is_real(_qty) || _qty < 1) {
            array_push(_warnings, "Skipped " + _def.id + ": invalid quantity.");
            continue;
        }

        _qty = floor(_qty);
        if (_qty > _def.max_stack) {
            array_push(_warnings, "Reduced " + _def.id + " to its max stack.");
            _qty = _def.max_stack;
        }

        var _index = _e[$ "slot"];
        var _entry = { item_id: _def.id, quantity: _qty };

        if (item_validation_is_whole(_index) && _index >= 0 && _index < _inv.capacity && is_undefined(_new_slots[_index])) {
            _new_slots[_index] = _entry;
        }
        else {
            array_push(_overflow, _entry);
        }
    }

    // Entries whose saved position is unusable go to the first free slot.
    for (var i = 0; i < array_length(_overflow); i++) {
        var _free = -1;
        for (var s = 0; s < _inv.capacity; s++) {
            if (is_undefined(_new_slots[s])) { _free = s; break; }
        }

        if (_free == -1) {
            array_push(_warnings, "Dropped " + _overflow[i].item_id + ": no room.");
        }
        else {
            _new_slots[_free] = _overflow[i];
        }
    }

    var _owned = {};
    for (var i = 0; i < _inv.capacity; i++) {
        if (is_struct(_new_slots[i])) _owned[$ _new_slots[i].item_id] = true;
    }
    #endregion

    #region Equipment and talismans
    // Equipment must reference an owned item of the matching category.
    var _new_equipment = {};
    var _slot_names = variable_struct_get_names(_player.equipment);
    var _saved_equipment = is_struct(_data[$ "equipment"]) ? _data.equipment : {};

    for (var i = 0; i < array_length(_slot_names); i++) {
        var _slot_name = _slot_names[i];
        var _id = _saved_equipment[$ _slot_name] ?? "";
        var _eq_def = is_string(_id) && _id != "" ? item_definition_get(_id) : undefined;

        if (_id != "" && (is_undefined(_eq_def) || _eq_def.category != _slot_name || !variable_struct_exists(_owned, _id))) {
            array_push(_warnings, "Unequipped invalid " + _slot_name + " '" + string(_id) + "'.");
            _id = "";
        }

        _new_equipment[$ _slot_name] = _id;
    }

    var _new_talismans = [];
    var _saved_talismans = is_array(_data[$ "talismans"]) ? _data.talismans : [];

    for (var i = 0; i < array_length(_saved_talismans); i++) {
        var _id = _saved_talismans[i];
        var _t_def = is_string(_id) ? item_definition_get(_id) : undefined;

        if (is_undefined(_t_def) || _t_def.category != "talisman" || !variable_struct_exists(_owned, _id)
            || array_contains(_new_talismans, _id) || array_length(_new_talismans) >= _player.max_talismans) {
            array_push(_warnings, "Removed invalid talisman '" + string(_id) + "'.");
            continue;
        }

        array_push(_new_talismans, _id);
    }
    #endregion

    #region Quick slots
    var _new_hotbar = array_create(_hotbar.slot_count, "");
    var _hotbar_data = is_struct(_data[$ "hotbar"]) ? _data.hotbar : {};
    var _saved_quick = is_array(_hotbar_data[$ "slots"]) ? _hotbar_data.slots : [];

    for (var i = 0; i < min(_hotbar.slot_count, array_length(_saved_quick)); i++) {
        var _id = _saved_quick[i];
        if (_id == "") continue;

        if (!hotbar_can_assign(_id) || array_contains(_new_hotbar, _id)) {
            array_push(_warnings, "Cleared invalid quick slot " + string(i + 1) + ".");
            continue;
        }

        _new_hotbar[i] = _id;
    }

    var _selected = _hotbar_data[$ "selected"];
    _selected = item_validation_is_whole(_selected) ? clamp(_selected, 0, _hotbar.slot_count - 1) : 0;
    #endregion

    #region Player stats
    var _health = is_real(_player_data[$ "health"]) ? _player_data.health : _player.health_;
    var _fp = is_real(_player_data[$ "fp"]) ? _player_data.fp : _player.fp;
    var _runes = is_real(_player_data[$ "runes"]) ? _player_data.runes : 0;
    #endregion

    // Everything validated; commit.
    _inv.slots = _new_slots;

    for (var i = 0; i < array_length(_slot_names); i++) {
        _player.equipment[$ _slot_names[i]] = _new_equipment[$ _slot_names[i]];
    }

    _player.talismans = _new_talismans;
    _hotbar.slots = _new_hotbar;
    _hotbar.selected_slot = _selected;

    _player.health_ = clamp(_health, 0, _player.max_health);
    _player.fp = clamp(_fp, 0, _player.max_fp);
    _player.runes = max(0, floor(_runes));

    // Summons are not saved; the loaded state starts without one.
    _player.summon = "";

    inventory_event_emit(INV_EVENT_INVENTORY);
    inventory_event_emit(INV_EVENT_EQUIPMENT);
    inventory_event_emit(INV_EVENT_STATS);
    inventory_event_emit(INV_EVENT_HOTBAR);

    var _result = inventory_action_result(true, array_length(_warnings) > 0
        ? "Game loaded with " + string(array_length(_warnings)) + " warning(s)."
        : "Game loaded.");
    _result.warnings = _warnings;

    for (var i = 0; i < array_length(_warnings); i++) {
        show_debug_message("[LOAD WARNING] " + _warnings[i]);
    }

    return _result;
}


/// @function save_fail(_message)
/// @param {String} _message The failure reason.
/// @returns {Struct.ActionResult} A failed result with an empty warnings list.
function save_fail(_message) {
    var _result = inventory_action_result(false, _message);
    _result.warnings = [];
    return _result;
}


/// @function save_write(_path)
/// @description Save the current game state to a JSON file.
/// @param {String} [_path] The file to write.
/// @returns {Struct.ActionResult} Whether the file was written.
function save_write(_path = INVENTORY_SAVE_FILE) {
    var _json = json_stringify(save_serialize());
    var _file = file_text_open_write(_path);

    if (_file == -1) return save_fail("Could not write save file.");

    file_text_write_string(_file, _json);
    file_text_close(_file);

    return inventory_action_result(true, "Game saved.");
}


/// @function save_read(_path)
/// @description Load the game state from a JSON file.
/// @param {String} [_path] The file to read.
/// @returns {Struct.ActionResult} Whether the file was loaded.
function save_read(_path = INVENTORY_SAVE_FILE) {
    if (!file_exists(_path)) return save_fail("No save file found.");

    var _file = file_text_open_read(_path);
    if (_file == -1) return save_fail("Could not read save file.");

    var _json = "";
    while (!file_text_eof(_file)) {
        _json += file_text_read_string(_file);
        file_text_readln(_file);
    }
    file_text_close(_file);

    var _data;

    try {
        _data = json_parse(_json);
    }
    catch (_e) {
        return save_fail("Save file is corrupt.");
    }

    return save_apply(_data);
}
