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


#region Action execution
/// @function inventory_execute_action(_item_id, _action)
/// @description Execute an item action that does not drop or discard the item.
/// @param {String} _item_id The item id to act on.
/// @param {String} _action The action name, such as Use, Equip, or Unequip.
/// @returns {Struct.ActionResult} Whether the action succeeded and a user-facing result message.
function inventory_execute_action(_item_id, _action) {
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

    var _fn = _handler.actions[$ _action];

    if (is_undefined(_fn)) {
        return inventory_action_result(false, "Unknown action.");
    }

    return _fn(_item_id, _def);
}
#endregion


#region Dropping and discarding
/// @function inventory_drop_item(_item_id, _x, _y)
/// @description Remove one item from inventory and create its pickup in the world.
/// @param {String} _item_id The item id to drop.
/// @param {Real} _x The world x-coordinate for the pickup.
/// @param {Real} _y The world y-coordinate for the pickup.
/// @returns {Struct.ActionResult} Whether the drop succeeded and a user-facing result message.
function inventory_drop_item(_item_id, _x, _y) {
    var _inv = global.player_inventory;

    if (inventory_count_item(_inv, _item_id) <= 0) {
        return inventory_action_result(false, "Item not in inventory.");
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
    _pickup.quantity = 1;

    if (!inventory_remove(_inv, _item_id, 1)) {
        with (_pickup) {
            instance_destroy();
        }

        return inventory_action_result(false, "Could not drop item.");
    }

    // Unequip it if the dropped item was equipped.
    global.player.unequip_item(_item_id);

    return inventory_action_result(true, "Item dropped.");
}

/// @function inventory_discard_item(_item_id)
/// @description Permanently remove one item from inventory.
/// @param {String} _item_id The item id to discard.
/// @returns {Struct.ActionResult} Whether discarding succeeded and a user-facing result message.
function inventory_discard_item(_item_id) {
    var _inv = global.player_inventory;

    if (inventory_count_item(_inv, _item_id) <= 0) {
        return inventory_action_result(false, "Item not in inventory.");
    }

    if (!inventory_remove(_inv, _item_id, 1)) {
        return inventory_action_result(false, "Could not discard item.");
    }

    global.player.unequip_item(_item_id);
    return inventory_action_result(true, "Item discarded.");
}
#endregion