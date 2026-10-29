/// scr_item_handlers
/// Registry of per-category item handlers and consumable use effects.
///
/// Add a new item type:
///   1. Give its definitions a `category` in scr_item_database.
///   2. Register a handler in item_handlers_init(), e.g.
///        item_category_register("tool", item_handler_create(
///            function(_item_id, _def) { return ["Use"]; },
///            { Use: function(_item_id, _def) { return inventory_action_result(true, "Used."); } }
///        ));
///      or use item_handler_equipment(...) / item_handler_placeholder(...).
/// Add a new consumable effect:
///   item_effect_register("my_effect", function(_def) { ... return inventory_action_result(...); });
/// Categories without a handler only offer Drop and Discard.

#region Registry
/// @function item_handlers_init()
/// @description Build the category and effect registries. Call once at startup, after the item database.
function item_handlers_init() {
    global.item_category_handlers = {};
    global.item_effect_handlers = {};

    #region Consumable effects
    item_effect_register("heal", function(_def) {
        if (global.player.is_health_full()) {
            return inventory_action_result(false, "Health is already full.");
        }

        global.player.heal(_def.use_amount);
        return inventory_action_result(true, "Health restored.");
    });

    item_effect_register("restore_fp", function(_def) {
        if (global.player.is_fp_full()) {
            return inventory_action_result(false, "FP is already full.");
        }

        global.player.restore_fp(_def.use_amount);
        return inventory_action_result(true, "FP restored.");
    });

    item_effect_register("runes", function(_def) {
        global.player.add_runes(_def.use_amount);
        return inventory_action_result(true, "Gained " + string(_def.use_amount) + " runes.");
    });
    #endregion

    #region Category handlers
    item_category_register("consumable", item_handler_create(
        function(_item_id, _def) {
            return ["Use"];
        },
        { Use: item_action_use_consumable }
    ));

    item_category_register("weapon", item_handler_equipment("weapon", "Weapon"));
    item_category_register("shield", item_handler_equipment("shield", "Shield"));
    item_category_register("armor", item_handler_equipment("armor", "Armor"));
    item_category_register("talisman", item_handler_equipment("talisman", "Talisman"));

    // Types without gameplay yet: they show an explanatory action instead of "silently" doing nothing.
    item_category_register("material", item_handler_placeholder("Upgrade materials are used at a site of grace."));
    item_category_register("ammo", item_handler_placeholder("Ammunition is not supported yet."));
    item_category_register("key", item_handler_placeholder("Key items cannot be used here."));
    item_category_register("spirit_ash", item_handler_placeholder("Spirit summoning is not supported yet."));
    #endregion
}

/// @function item_category_register(_category, _handler)
/// @description Register (or replace) the handler for an item category.
/// @param {String} _category The item category name.
/// @param {Struct.ItemHandler} _handler A handler built with item_handler_create().
function item_category_register(_category, _handler) {
    global.item_category_handlers[$ _category] = _handler;
}

/// @function item_category_get_handler(_category)
/// @param {String} _category The item category name.
/// @returns {Struct.ItemHandler|undefined} The registered handler, or undefined if the category has none.
function item_category_get_handler(_category) {
    return global.item_category_handlers[$ _category];
}

/// @function item_effect_register(_effect, _fn)
/// @description Register a consumable effect. The function receives the item definition and returns an
/// ActionResult; the item is consumed only when the result is ok.
/// @param {String} _effect The use_effect name used in item definitions.
/// @param {Function} _fn The effect function.
function item_effect_register(_effect, _fn) {
    global.item_effect_handlers[$ _effect] = _fn;
}

/// @function item_handler_create(_get_actions, _actions)
/// @param {Function} _get_actions function(item_id, def) returning the category-specific action names.
/// @param {Struct} _actions Map of action name to function(item_id, def) returning an ActionResult.
/// @returns {Struct.ItemHandler} The handler.
function item_handler_create(_get_actions, _actions) {
    return {
        get_actions: _get_actions,
        actions: _actions
    };
}
#endregion


#region Handler builders
/// @function item_handler_equipment(_slot, _label)
/// @description Build a handler providing Equip/Unequip for a player equipment slot.
/// @param {String} _slot The player equipment slot.
/// @param {String} _label The display name used in messages.
/// @returns {Struct.ItemHandler} The handler.
function item_handler_equipment(_slot, _label) {
    var _handler = item_handler_create(
        method({ slot: _slot }, function(_item_id, _def) {
            return [global.player.get_equipped_id(slot) == _item_id ? "Unequip" : "Equip"];
        }),
        {}
    );

    _handler.actions[$ "Equip"] = method({ slot: _slot, label: _label }, function(_item_id, _def) {
        global.player.equip(slot, _item_id);
        return inventory_action_result(true, label + " equipped.");
    });

    _handler.actions[$ "Unequip"] = method({ slot: _slot, label: _label }, function(_item_id, _def) {
        if (global.player.get_equipped_id(slot) != _item_id) {
            return inventory_action_result(false, "Item is not equipped.");
        }

        global.player.unequip(slot);
        return inventory_action_result(true, label + " unequipped.");
    });

    return _handler;
}

/// @function item_handler_placeholder(_message)
/// @description Build a handler for a type that has no behavior yet; "Use" reports the message.
/// @param {String} _message The message shown when the action is chosen.
/// @returns {Struct.ItemHandler} The handler.
function item_handler_placeholder(_message) {
    return item_handler_create(
        function(_item_id, _def) {
            return ["Use"];
        },
        { Use: method({ message: _message }, function(_item_id, _def) {
            return inventory_action_result(false, message);
        }) }
    );
}

/// @function item_action_use_consumable(_item_id, _def)
/// @description Run a consumable's use_effect and consume one item when it succeeds.
/// @param {String} _item_id The item id.
/// @param {Struct.ItemDefinition} _def The item definition.
/// @returns {Struct.ActionResult} The outcome.
function item_action_use_consumable(_item_id, _def) {
    if (!variable_struct_exists(_def, "use_effect")) {
        return inventory_action_result(false, "This item has no use effect.");
    }

    var _effect = global.item_effect_handlers[$ _def.use_effect];

    if (is_undefined(_effect)) {
        return inventory_action_result(false, "This item cannot be used yet.");
    }

    var _result = _effect(_def);

    if (_result.ok && !inventory_remove(global.player_inventory, _item_id, 1)) {
        return inventory_action_result(false, "Could not consume item.");
    }

    return _result;
}
#endregion
