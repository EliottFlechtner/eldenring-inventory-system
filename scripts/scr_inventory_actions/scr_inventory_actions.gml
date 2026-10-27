/// scr_inventory_actions

function inventory_action_result(_ok, _message) {
    return {
        ok: _ok,
        message: _message
    };
}


/// Return the available actions for an item.
function inventory_get_actions(_item_id) {
    var _actions = [];
    var _def = item_definition_get(_item_id);

    if (is_undefined(_def)) {
        return _actions;
    }

    if (_def.category == "consumable") {
        array_push(_actions, "Use");
    }

    if (_def.category == "weapon") {
        if (global.player.get_equipped_id("weapon") == _item_id) {
        } else {
			array_push(_actions, "Equip");
		}
    }

    if (_def.category == "armor") {
        if (global.player.get_equipped_id("armor") == _item_id) {
        } else {
			array_push(_actions, "Equip");
		}
    }

    array_push(_actions, "Drop");
    array_push(_actions, "Discard");

    return _actions;
}


/// Execute a non-destructive action.
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
            if (_def.category == "weapon") {
                global.player.equip("weapon", _item_id);

                return inventory_action_result(true, "Weapon equipped.");
            }

            if (_def.category == "armor") {
                global.player.equip("armor", _item_id);

                return inventory_action_result(true, "Armor equipped.");
            }

            return inventory_action_result(false, "This item cannot be equipped.");
			
		case "Unequip":
		    if (_def.category == "weapon"
		    && global.player.get_equipped_id("weapon") == _item_id) {
		        global.player.unequip("weapon");
		        return inventory_action_result(true, "Weapon unequipped.");
		    }

		    if (_def.category == "armor"
		    && global.player.get_equipped_id("armor") == _item_id) {
		        global.player.unequip("armor");
		        return inventory_action_result(true, "Armor unequipped.");
		    }

		    return inventory_action_result(false, "Item is not equipped.");
    }

    return inventory_action_result(false, "Unknown action.");
}


/// Remove one item and place it in the temporary ground-item list.
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

/// Permanently remove one item.
function inventory_discard_item(_item_id) {
    var _inv = global.player_inventory;

    if (inventory_count_item(_inv, _item_id) <= 0) {
        return inventory_action_result(false, "Item not in inventory.");
    }

    if (!inventory_remove(_inv, _item_id, 1)) {
        return inventory_action_result(false, "Could not discard item.");
    }

    global.player.unequip_item(_item_id);
}