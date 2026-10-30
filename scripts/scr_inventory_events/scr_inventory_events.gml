/// scr_inventory_events
/// A small event bus plus transactional snapshots.
///
/// Events: code that changes inventory, equipment, stats, or quick slots emits an event; anything that
/// derives state from them (cached player stats, equipment cleanup, the inventory UI) subscribes once and
/// stays consistent, without the changing code knowing who listens.
///
/// Transactions: inventory_execute_action snapshots the game state before running an action and restores it
/// if the action fails, so a failed action never loses items, FP, or equipment.

#macro INV_EVENT_INVENTORY "inventory_changed"
#macro INV_EVENT_EQUIPMENT "equipment_changed"
#macro INV_EVENT_STATS "stats_changed"
#macro INV_EVENT_HOTBAR "hotbar_changed"


#region Event bus
/// @function inventory_events_init()
/// @description Make sure the event bus exists and the built-in listeners are registered. Safe to call
/// repeatedly and in any object order; it never removes existing subscribers.
function inventory_events_init() {
    if (!variable_global_exists("inventory_events")) {
        global.inventory_events = {};
    }

    if (!variable_global_exists("inventory_events_defaults")) {
        global.inventory_events_defaults = true;

        inventory_event_subscribe(INV_EVENT_INVENTORY, function(_data) { inventory_state_cleanup(); });
        inventory_event_subscribe(INV_EVENT_INVENTORY, function(_data) { inventory_state_refresh(); });
        inventory_event_subscribe(INV_EVENT_EQUIPMENT, function(_data) { inventory_state_refresh(); });
        inventory_event_subscribe(INV_EVENT_STATS, function(_data) { inventory_state_refresh(); });
    }
}


/// @function inventory_event_subscribe(_event, _fn)
/// @param {String} _event An INV_EVENT_* name.
/// @param {Function} _fn function(data) called whenever the event is emitted.
/// @returns {Function} The function, for later unsubscribing.
function inventory_event_subscribe(_event, _fn) {
    if (!variable_global_exists("inventory_events")) {
        global.inventory_events = {};
    }

    if (!variable_struct_exists(global.inventory_events, _event)) {
        global.inventory_events[$ _event] = [];
    }

    array_push(global.inventory_events[$ _event], _fn);

    return _fn;
}


/// @function inventory_event_unsubscribe(_event, _fn)
/// @returns {Boolean} Whether the listener was registered.
function inventory_event_unsubscribe(_event, _fn) {
    if (!variable_global_exists("inventory_events")) return false;

    var _list = global.inventory_events[$ _event];
    if (!is_array(_list)) return false;

    var _index = array_get_index(_list, _fn);
    if (_index < 0) return false;

    array_delete(_list, _index, 1);
    return true;
}


/// @function inventory_event_emit(_event, _data)
/// @description Call every listener of an event. Does nothing before the bus exists.
/// @param {String} _event An INV_EVENT_* name.
/// @param {Any} [_data] Optional payload passed to listeners.
function inventory_event_emit(_event, _data = undefined) {
    if (!variable_global_exists("inventory_events")) return;

    var _list = global.inventory_events[$ _event];
    if (!is_array(_list)) return;

    // Listeners may change state and emit again; a depth limit stops runaway loops.
    var _depth = global[$ "inventory_event_depth"] ?? 0;
    if (_depth >= 6) return;
    global.inventory_event_depth = _depth + 1;

    // Iterate a copy so listeners can subscribe or unsubscribe safely.
    var _copy = array_create(array_length(_list));
    array_copy(_copy, 0, _list, 0, array_length(_list));

    try {
        for (var i = 0; i < array_length(_copy); i++) {
            _copy[i](_data);
        }
    }
    finally {
        global.inventory_event_depth = _depth;
    }
}


/// @function inventory_notify_changed(_inventory)
/// @description Emit INV_EVENT_INVENTORY if the given inventory is the player's.
/// @param {Struct.Inventory} _inventory The inventory that changed.
function inventory_notify_changed(_inventory) {
    if (variable_global_exists("player_inventory") && global.player_inventory == _inventory) {
        inventory_event_emit(INV_EVENT_INVENTORY);
    }
}
#endregion


#region Derived state
/// @function inventory_state_cleanup()
/// @description Remove equipment, talismans, and summons whose item is no longer owned. Runs on inventory
/// changes, so any code that removes items (consuming, dropping, loading) keeps equipment consistent.
function inventory_state_cleanup() {
    var _p = global[$ "player"];
    var _inv = global[$ "player_inventory"];
    if (!is_struct(_p) || !is_struct(_inv)) return;

    var _changed = false;
    var _slots = variable_struct_get_names(_p.equipment);

    for (var i = 0; i < array_length(_slots); i++) {
        var _id = _p.equipment[$ _slots[i]];

        if (_id != "" && inventory_count_item(_inv, _id) <= 0) {
            _p.equipment[$ _slots[i]] = "";
            _changed = true;
        }
    }

    for (var i = array_length(_p.talismans) - 1; i >= 0; i--) {
        if (inventory_count_item(_inv, _p.talismans[i]) <= 0) {
            array_delete(_p.talismans, i, 1);
            _changed = true;
        }
    }

    if (_p.summon != "" && inventory_count_item(_inv, _p.summon) <= 0) {
        _p.summon = "";
        _changed = true;
    }

    if (_changed) inventory_event_emit(INV_EVENT_EQUIPMENT);
}


/// @function inventory_state_refresh()
/// @description Recompute the player's cached derived stats.
function inventory_state_refresh() {
    var _p = global[$ "player"];

    if (is_struct(_p) && is_callable(_p[$ "refresh_derived"])) {
        _p.refresh_derived();
    }
}
#endregion


#region Transactions
/// @function inventory_tx_begin()
/// @description Snapshot everything an item action can change: inventory slots, quick slots, equipment,
/// talismans, summon, HP, FP, and runes.
/// @returns {Struct} The snapshot, for inventory_tx_rollback().
function inventory_tx_begin() {
    var _inv = global.player_inventory;
    var _p = global.player;
    var _hotbar = global.player_hotbar;

    var _slots = array_create(_inv.capacity, undefined);
    for (var i = 0; i < _inv.capacity; i++) {
        var _slot = _inv.slots[i];
        if (is_struct(_slot)) _slots[i] = { item_id: _slot.item_id, quantity: _slot.quantity };
    }

    return {
        slots: _slots,
        hotbar: variable_clone(_hotbar.slots),
        hotbar_selected: _hotbar.selected_slot,
        equipment: variable_clone(_p.equipment),
        talismans: variable_clone(_p.talismans),
        summon: _p.summon,
        health: _p.health_,
        fp: _p.fp,
        runes: _p.runes
    };
}


/// @function inventory_tx_rollback(_snapshot)
/// @description Restore the state captured by inventory_tx_begin() and refresh everything derived from it.
/// @param {Struct} _snapshot The snapshot to restore.
function inventory_tx_rollback(_snapshot) {
    var _inv = global.player_inventory;
    var _p = global.player;
    var _hotbar = global.player_hotbar;

    _inv.slots = _snapshot.slots;
    _hotbar.slots = _snapshot.hotbar;
    _hotbar.selected_slot = _snapshot.hotbar_selected;
    _p.equipment = _snapshot.equipment;
    _p.talismans = _snapshot.talismans;
    _p.summon = _snapshot.summon;
    _p.health_ = _snapshot.health;
    _p.fp = _snapshot.fp;
    _p.runes = _snapshot.runes;

    inventory_event_emit(INV_EVENT_INVENTORY);
    inventory_event_emit(INV_EVENT_EQUIPMENT);
    inventory_event_emit(INV_EVENT_STATS);
    inventory_event_emit(INV_EVENT_HOTBAR);
}
#endregion
