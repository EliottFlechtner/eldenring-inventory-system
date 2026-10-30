/// scr_inventory_ui_state
/// Central state machine for the inventory UI's menus and dialogs.
///
/// States: GRID (browsing slots) -> ACTIONS (item action menu) -> optional QUANTITY -> optional REPLACE
/// -> optional CONFIRM -> execute -> back to GRID. Dialogs are never opened or closed directly; use these
/// functions so a transition cannot leave stale state behind. Every function takes the UI instance (or any
/// struct with the same ui_* fields), so the flow can be tested without a room.

enum InventoryUIState {
    GRID,
    ACTIONS,
    QUANTITY,
    REPLACE,
    CONFIRM
}


/// @function inventory_ui_ctx_create()
/// @description Create a fresh action context: what is being done, and which steps are already resolved.
/// @returns {Struct} The context.
function inventory_ui_ctx_create() {
    return {
        item: "",
        action: "",
        quantity: 1,
        quantity_max: 1,
        replace_options: [],
        replace_selected: 0,
        replace_id: undefined,
        quantity_done: false,
        replace_done: false,
        confirm_done: false
    };
}


/// @function inventory_ui_state_init(_ui)
/// @param {Id.Instance|Struct} _ui The UI instance.
function inventory_ui_state_init(_ui) {
    _ui.ui_state = InventoryUIState.GRID;
    _ui.ui_ctx = inventory_ui_ctx_create();
    _ui.ui_actions = [];
    _ui.ui_action_selected = 0;
}


/// @function inventory_ui_state_set(_ui, _state)
/// @param {Id.Instance|Struct} _ui The UI instance.
/// @param {Real} _state An InventoryUIState value.
function inventory_ui_state_set(_ui, _state) {
    _ui.ui_state = _state;
}


/// @function inventory_ui_is_grid(_ui)
/// @returns {Boolean} Whether no menu or dialog is open.
function inventory_ui_is_grid(_ui) {
    return _ui.ui_state == InventoryUIState.GRID;
}


/// @function inventory_ui_reset(_ui)
/// @description Close every menu and dialog and clear the action context.
/// @param {Id.Instance|Struct} _ui The UI instance.
function inventory_ui_reset(_ui) {
    inventory_ui_state_init(_ui);
}


#region Event-driven refresh
/// @function inventory_ui_refresh(_ui)
/// @description Bring open menus and dialogs back in line with the game state after inventory, equipment,
/// or stat changes: close them if their item is gone, otherwise rebuild the action list and limits.
/// @param {Id.Instance|Struct} _ui The UI instance.
function inventory_ui_refresh(_ui) {
    if (_ui.ui_state == InventoryUIState.GRID) return;

    var _c = _ui.ui_ctx;

    if (inventory_count_item(global.player_inventory, _c.item) <= 0) {
        inventory_ui_reset(_ui);
        return;
    }

    if (_ui.ui_state == InventoryUIState.ACTIONS) {
        _ui.ui_actions = inventory_get_actions(_c.item);
        _ui.ui_action_selected = clamp(_ui.ui_action_selected, 0, max(0, array_length(_ui.ui_actions) - 1));
        return;
    }

    // A quantity dialog must not offer more than the action can now apply.
    if (_ui.ui_state == InventoryUIState.QUANTITY) {
        _c.quantity_max = inventory_get_action_max_quantity(_c.item, _c.action);
        _c.quantity = clamp(_c.quantity, 1, _c.quantity_max);
    }
}


/// @function inventory_ui_subscribe(_ui)
/// @description Refresh the UI whenever inventory, equipment, stats, or quick slots change.
/// @param {Id.Instance} _ui The UI instance.
function inventory_ui_subscribe(_ui) {
    var _listener = method({ ui: _ui }, function(_data) {
        if (instance_exists(ui)) inventory_ui_refresh(ui);
    });

    inventory_event_subscribe(INV_EVENT_INVENTORY, _listener);
    inventory_event_subscribe(INV_EVENT_EQUIPMENT, _listener);
    inventory_event_subscribe(INV_EVENT_STATS, _listener);
    inventory_event_subscribe(INV_EVENT_HOTBAR, _listener);
}
#endregion

#region Opening and choosing actions
/// @function inventory_ui_open_actions(_ui, _item_id)
/// @description Open the action menu for an item.
/// @param {Id.Instance|Struct} _ui The UI instance.
/// @param {String} _item_id The item to act on.
/// @returns {Boolean} Whether the menu opened (false if the item has no actions).
function inventory_ui_open_actions(_ui, _item_id) {
    var _actions = inventory_get_actions(_item_id);
    if (array_length(_actions) == 0) return false;

    _ui.ui_ctx = inventory_ui_ctx_create();
    _ui.ui_ctx.item = _item_id;
    _ui.ui_actions = _actions;
    _ui.ui_action_selected = 0;
    inventory_ui_state_set(_ui, InventoryUIState.ACTIONS);

    return true;
}


/// @function inventory_ui_move_action(_ui, _delta)
/// @description Move the action menu selection, wrapping at both ends.
function inventory_ui_move_action(_ui, _delta) {
    var _count = array_length(_ui.ui_actions);
    if (_count == 0) return;

    _ui.ui_action_selected = (_ui.ui_action_selected + _delta + _count) mod _count;
}


/// @function inventory_ui_choose_selected_action(_ui)
/// @description Start the highlighted action; it may open further dialogs before it runs.
function inventory_ui_choose_selected_action(_ui) {
    var _item = _ui.ui_ctx.item;

    _ui.ui_ctx = inventory_ui_ctx_create();
    _ui.ui_ctx.item = _item;
    _ui.ui_ctx.action = _ui.ui_actions[_ui.ui_action_selected];

    inventory_ui_advance(_ui);
}


/// @function inventory_ui_advance(_ui)
/// @description Move to the next unresolved step of the current action: quantity, replacement, confirmation,
/// then execution. Steps the action does not need are skipped.
function inventory_ui_advance(_ui) {
    var _c = _ui.ui_ctx;

    if (!_c.quantity_done) {
        var _max = inventory_get_action_max_quantity(_c.item, _c.action);

        if (_max > 1) {
            _c.quantity_max = _max;
            _c.quantity = 1;
            inventory_ui_state_set(_ui, InventoryUIState.QUANTITY);
            return;
        }

        _c.quantity_done = true;
    }

    if (!_c.replace_done) {
        var _options = inventory_get_action_replace_options(_c.item, _c.action);

        if (array_length(_options) > 0) {
            _c.replace_options = _options;
            _c.replace_selected = 0;
            inventory_ui_state_set(_ui, InventoryUIState.REPLACE);
            return;
        }

        _c.replace_done = true;
    }

    if (!_c.confirm_done) {
        if (_c.action == "Drop" || _c.action == "Discard") {
            inventory_ui_state_set(_ui, InventoryUIState.CONFIRM);
            return;
        }

        _c.confirm_done = true;
    }

    inventory_ui_execute(_ui);
}
#endregion


#region Dialog input
/// @function inventory_ui_quantity_adjust(_ui, _delta)
function inventory_ui_quantity_adjust(_ui, _delta) {
    var _c = _ui.ui_ctx;
    _c.quantity = clamp(_c.quantity + _delta, 1, _c.quantity_max);
}


/// @function inventory_ui_quantity_confirm(_ui)
function inventory_ui_quantity_confirm(_ui) {
    _ui.ui_ctx.quantity_done = true;
    inventory_ui_advance(_ui);
}


/// @function inventory_ui_replace_move(_ui, _delta)
function inventory_ui_replace_move(_ui, _delta) {
    var _c = _ui.ui_ctx;
    var _count = array_length(_c.replace_options);
    if (_count == 0) return;

    _c.replace_selected = (_c.replace_selected + _delta + _count) mod _count;
}


/// @function inventory_ui_replace_confirm(_ui)
function inventory_ui_replace_confirm(_ui) {
    var _c = _ui.ui_ctx;
    _c.replace_id = _c.replace_options[_c.replace_selected];
    _c.replace_done = true;
    inventory_ui_advance(_ui);
}


/// @function inventory_ui_confirm_accept(_ui)
function inventory_ui_confirm_accept(_ui) {
    _ui.ui_ctx.confirm_done = true;
    inventory_ui_advance(_ui);
}
#endregion


#region Execution and cancelling
/// @function inventory_ui_drop_position()
/// @description Temporary drop location until a player object exists.
function inventory_ui_drop_position() {
    return {
        x: irandom_range(100, max(100, room_width)),
        y: irandom_range(100, max(100, room_height))
    };
}


/// @function inventory_ui_execute(_ui)
/// @description Run the resolved action, show its message, and return to the grid.
/// @returns {Struct} The action's result.
function inventory_ui_execute(_ui) {
    var _c = _ui.ui_ctx;
    var _result;

    switch (_c.action) {
        case "Drop":
            var _pos = inventory_ui_drop_position();
            _result = inventory_drop_item(_c.item, _pos.x, _pos.y, _c.quantity);
            break;

        case "Discard":
            _result = inventory_discard_item(_c.item, _c.quantity);
            break;

        default:
            _result = inventory_execute_action(_c.item, _c.action, _c.quantity, _c.replace_id);
            break;
    }

    inventory_ui_message_show(_ui, _result.message, _ui.ui_message_duration_standard);
    inventory_ui_reset(_ui);

    return _result;
}


/// @function inventory_ui_back(_ui)
/// @description Cancel the topmost layer: a dialog returns to the action menu, the menu returns to the grid.
/// @returns {Boolean} Whether a layer was closed; false when already on the grid.
function inventory_ui_back(_ui) {
    switch (_ui.ui_state) {
        case InventoryUIState.QUANTITY:
        case InventoryUIState.REPLACE:
        case InventoryUIState.CONFIRM:
            var _item = _ui.ui_ctx.item;
            _ui.ui_ctx = inventory_ui_ctx_create();
            _ui.ui_ctx.item = _item;
            inventory_ui_state_set(_ui, InventoryUIState.ACTIONS);
            inventory_ui_message_show(_ui, "Cancelled.", _ui.ui_message_duration_brief);
            return true;

        case InventoryUIState.ACTIONS:
            inventory_ui_reset(_ui);
            return true;
    }

    return false;
}
#endregion
