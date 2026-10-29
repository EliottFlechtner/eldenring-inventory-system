/// scr_inventory_actions

/// @function inventory_action_result(_ok, _message)
/// @description Create a standardized result for an inventory action.
/// @param {Boolean} _ok Whether the action succeeded.
/// @param {String} _message A user-facing explanation of the result.
/// @returns {Struct.ActionResult} A result containing the success flag and message.
function inventory_action_result(_ok, _message) {
    return {
        ok: _ok,
        message: _message
    };
}


#region Available actions
/// @function inventory_get_actions(_item_id)
/// @description Get the actions currently available for an item.
/// @param {String} _item_id The item id to inspect.
/// @returns {Array<String>} The available action names, or an empty array if the item is unknown.
function inventory_get_actions(_item_id) {
    var _actions = [];
    var _def = item_definition_get(_item_id);

    if (is_undefined(_def)) {
        return _actions;
    }

    var _handler = item_category_get_handler(_def.category);

    if (is_struct(_handler)) {
        _actions = _handler.get_actions(_item_id, _def);
    }

    array_push(_actions, "Drop");
    array_push(_actions, "Discard");

    return _actions;
}
#endregion


/// @function inventory_get_action_unsupported_reason(_item_id, _action)
/// @description Explain why an action is not supported yet, for graying it out in the menu.
/// @param {String} _item_id The item id.
/// @param {String} _action The action name.
/// @returns {String} The reason, or an empty string if the action is supported.
function inventory_get_action_unsupported_reason(_item_id, _action) {
    var _def = item_definition_get(_item_id);
    if (is_undefined(_def)) return "";

    var _handler = item_category_get_handler(_def.category);
    if (!is_struct(_handler) || !is_callable(_handler.get_unsupported_reason)) return "";

    // Only handler-owned actions can be unsupported; Drop and Discard never are.
    if (!variable_struct_exists(_handler.actions, _action)) return "";

    return _handler.get_unsupported_reason(_item_id, _def, _action);
}


/// @function inventory_get_action_max_quantity(_item_id, _action)
/// @description How many items an action can apply at once; above 1 the UI shows a quantity picker.
/// @param {String} _item_id The item id.
/// @param {String} _action The action name.
/// @returns {Real} The maximum quantity, at least 1. Unsupported actions always return 1.
function inventory_get_action_max_quantity(_item_id, _action) {
    // Dropping and discarding can always take any part of the stack.
    if (_action == "Drop" || _action == "Discard") {
        return max(1, inventory_count_item(global.player_inventory, _item_id));
    }

    var _def = item_definition_get(_item_id);
    if (is_undefined(_def)) return 1;

    var _handler = item_category_get_handler(_def.category);
    if (!is_struct(_handler) || !is_callable(_handler.get_max_quantity)) return 1;
    if (!variable_struct_exists(_handler.actions, _action)) return 1;
    if (inventory_get_action_unsupported_reason(_item_id, _action) != "") return 1;

    return max(1, _handler.get_max_quantity(_item_id, _def, _action));
}


/// @function inventory_get_action_replace_options(_item_id, _action)
/// @description Items the player must choose one of to replace before the action can run (for example
/// when all talisman slots are taken).
/// @param {String} _item_id The item id.
/// @param {String} _action The action name.
/// @returns {Array<String>} Item ids to choose from; empty when no choice is needed.
function inventory_get_action_replace_options(_item_id, _action) {
    var _def = item_definition_get(_item_id);
    if (is_undefined(_def)) return [];

    var _handler = item_category_get_handler(_def.category);
    if (!is_struct(_handler) || !is_callable(_handler.get_replace_options)) return [];
    if (!variable_struct_exists(_handler.actions, _action)) return [];
    if (inventory_get_action_unsupported_reason(_item_id, _action) != "") return [];

    return _handler.get_replace_options(_item_id, _def, _action);
}


#region Action execution
/// @function inventory_execute_action(_item_id, _action, _quantity)
/// @description Execute an item action that does not drop or discard the item.
/// @param {String} _item_id The item id to act on.
/// @param {String} _action The action name, such as Use, Equip, or Unequip.
/// @param {Real} [_quantity] How many to apply at once; clamped to the action's maximum.
/// @param {String} [_replace_id] The item chosen to be replaced, when the action requires a choice.
/// @returns {Struct.ActionResult} Whether the action succeeded and a user-facing result message.
function inventory_execute_action(_item_id, _action, _quantity = 1, _replace_id = undefined) {
    var _inv = global.player_inventory;
    var _def = item_definition_get(_item_id);

    if (is_undefined(_def)) {
        return inventory_action_result(false, "Unknown item.");
    }

    if (inventory_count_item(_inv, _item_id) <= 0) {
        return inventory_action_result(false, "Item not in inventory.");
    }

    var _handler = item_category_get_handler(_def.category);

    if (!is_struct(_handler)) {
        return inventory_action_result(false, "This item has no available actions.");
    }

    // Only actions the handler currently offers may run (e.g. no Unequip for unequipped gear).
    if (!array_contains(_handler.get_actions(_item_id, _def), _action)) {
        return inventory_action_result(false, "This item cannot be used that way.");
    }

    // Unsupported actions stay selectable but explain why nothing happens.
    var _unsupported = inventory_get_action_unsupported_reason(_item_id, _action);

    if (_unsupported != "") {
        return inventory_action_result(false, _unsupported);
    }

    // A required replacement must be chosen from the offered options.
    var _replace_options = inventory_get_action_replace_options(_item_id, _action);

    if (array_length(_replace_options) > 0 && !array_contains(_replace_options, _replace_id)) {
        return inventory_action_result(false, "Choose an item to replace.");
    }

    var _fn = _handler.actions[$ _action];

    if (is_undefined(_fn)) {
        return inventory_action_result(false, "Unknown action.");
    }

    _quantity = clamp(_quantity, 1, inventory_get_action_max_quantity(_item_id, _action));

    return _fn(_item_id, _def, _quantity, _replace_id);
}
#endregion


#region Dropping and discarding
/// @function inventory_drop_item(_item_id, _x, _y, _quantity)
/// @description Remove items from inventory and create a pickup holding them in the world.
/// @param {String} _item_id The item id to drop.
/// @param {Real} _x The world x-coordinate for the pickup.
/// @param {Real} _y The world y-coordinate for the pickup.
/// @param {Real} [_quantity] How many to drop.
/// @returns {Struct.ActionResult} Whether the drop succeeded and a user-facing result message.
function inventory_drop_item(_item_id, _x, _y, _quantity = 1) {
    var _inv = global.player_inventory;

    if (inventory_count_item(_inv, _item_id) <= 0) {
        return inventory_action_result(false, "Item not in inventory.");
    }

    if (!is_real(_quantity) || _quantity < 1 || floor(_quantity) != _quantity) {
        return inventory_action_result(false, "Invalid quantity.");
    }

    if (inventory_count_item(_inv, _item_id) < _quantity) {
        return inventory_action_result(false, "Not enough items.");
    }

    var _def = item_definition_get(_item_id);

    if (is_undefined(_def)) {
        return inventory_action_result(false, "Unknown item.");
    }

    // Create the world object before removing the inventory item.
    var _pickup = instance_create_layer(
        _x,
        _y,
        "Instances",
        obj_item_pickup
    );

    if (!instance_exists(_pickup)) {
        return inventory_action_result(false, "Could not create pickup.");
    }

    _pickup.item_id = _item_id;
    _pickup.quantity = _quantity;

    if (!inventory_remove(_inv, _item_id, _quantity)) {
        with (_pickup) {
            instance_destroy();
        }

        return inventory_action_result(false, "Could not drop item.");
    }

    // Unequip it only once no copies remain.
    if (inventory_count_item(_inv, _item_id) <= 0) {
        global.player.unequip_item(_item_id);
    }

    return inventory_action_result(true, _quantity > 1 ? string(_quantity) + " items dropped." : "Item dropped.");
}

/// @function inventory_discard_item(_item_id, _quantity)
/// @description Permanently remove items from inventory.
/// @param {String} _item_id The item id to discard.
/// @param {Real} [_quantity] How many to discard.
/// @returns {Struct.ActionResult} Whether discarding succeeded and a user-facing result message.
function inventory_discard_item(_item_id, _quantity = 1) {
    var _inv = global.player_inventory;

    if (inventory_count_item(_inv, _item_id) <= 0) {
        return inventory_action_result(false, "Item not in inventory.");
    }

    if (!is_real(_quantity) || _quantity < 1 || floor(_quantity) != _quantity) {
        return inventory_action_result(false, "Invalid quantity.");
    }

    if (!inventory_remove(_inv, _item_id, _quantity)) {
        return inventory_action_result(false, "Could not discard item.");
    }

    if (inventory_count_item(_inv, _item_id) <= 0) {
        global.player.unequip_item(_item_id);
    }

    return inventory_action_result(true, _quantity > 1 ? string(_quantity) + " items discarded." : "Item discarded.");
}
#endregion