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

    if (_def.category == "consumable") {
        array_push(_actions, "Use");
    }

    if (global.player.is_equipment_slot(_def.category)) {
        var _equipment_slot = _def.category;
        var _equipped_id = global.player.get_equipped_id(_equipment_slot);

        array_push(_actions, _equipped_id == _item_id ? "Unequip" : "Equip");
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

    switch (_action) {
        case "Use":
            if (_def.category != "consumable") {
                return inventory_action_result(false, "This item cannot be used.");
            }

            if (!variable_struct_exists(_def, "use_effect")) {
                return inventory_action_result(false, "This item has no use effect.");
            }

            if (_def.use_effect == "heal") {
                if (global.player.is_health_full()) {
                    return inventory_action_result(false, "Health is already full.");
                }

                if (!inventory_remove(_inv, _item_id, 1)) {
                    return inventory_action_result(false, "Could not consume item.");
                }

                global.player.heal(_def.use_amount);

                return inventory_action_result(true, "Health restored.");
            }

            return inventory_action_result(false, "Unknown item effect.");

        case "Equip":
        case "Unequip":
            if (!global.player.is_equipment_slot(_def.category)) {
                var _error_message = _action == "Equip"
                    ? "This item cannot be equipped."
                    : "Item is not equipped.";
                return inventory_action_result(false, _error_message);
            }

            var _equipment_slot = _def.category;
            var _equipment_name = _equipment_slot == "weapon" ? "Weapon" : "Armor";

            if (_action == "Equip") {
                global.player.equip(_equipment_slot, _item_id);
                return inventory_action_result(true, _equipment_name + " equipped.");
            }

            if (global.player.get_equipped_id(_equipment_slot) != _item_id) {
                return inventory_action_result(false, "Item is not equipped.");
            }

            global.player.unequip(_equipment_slot);
            return inventory_action_result(true, _equipment_name + " unequipped.");
    }

    return inventory_action_result(false, "Unknown action.");
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