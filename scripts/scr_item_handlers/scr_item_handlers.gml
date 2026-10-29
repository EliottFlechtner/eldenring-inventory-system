/// scr_item_handlers
/// Registry of per-category item handlers and consumable use effects.
///
/// Add a new item type:
///   1. Give its definitions a `category` in scr_item_database.
///   2. Register a handler in item_handlers_init(), e.g.
///        item_category_register("tool", item_handler_create(
///            function(_item_id, _def) { return ["Use"]; },
///            { Use: function(_item_id, _def, _quantity) { return inventory_action_result(true, "Used."); } }
///        ));
///      Optional extra arguments: an unsupported-reason callback (grays the action out), a
///      max-quantity callback (opens the quantity picker when it returns more than 1), and a
///      replace-options callback (opens a "replace which one?" menu; the chosen id is passed to the
///      action as its fourth argument).
///      or use item_handler_equipment(...) / item_handler_placeholder(...).
/// Add a new consumable effect:
///   item_effect_register("my_effect", function(_def, _quantity) { ... return inventory_action_result(...); },
///       function(_def) { return max_useful_count; }); // the max callback is optional
/// Categories without a handler only offer Drop and Discard.

#region Registry
/// @function item_handlers_init()
/// @description Build the category and effect registries. Call once at startup, after the item database.
function item_handlers_init() {
    global.item_category_handlers = {};
    global.item_effect_handlers = {};

    #region Consumable effects
    item_effect_register(
		"heal",
		function(_def, _quantity) { // Heal the player.
		    if (global.player.is_health_full()) return inventory_action_result(false, "Health is already full.");
		    global.player.heal(_def.use_amount * _quantity);
		    return inventory_action_result(true, "Health restored.");
		},
		function(_def) { // No point using more than it takes to fill health.
		    return ceil((global.player.max_health - global.player.health_) / _def.use_amount);
		}
	);

    item_effect_register(
		"restore_fp",
		function(_def, _quantity) { // Restore player's FP
	        if (global.player.is_fp_full()) return inventory_action_result(false, "FP is already full.");
	        global.player.restore_fp(_def.use_amount * _quantity);
	        return inventory_action_result(true, "FP restored.");
	    },
		function(_def) { // No point using more than it takes to fill FP.
	        return ceil((global.player.max_fp - global.player.fp) / _def.use_amount);
	    }
	);

    item_effect_register(
		"runes",
		function(_def, _quantity) { // Increase player's runes (no limit)
	        var _total = _def.use_amount * _quantity;
	        global.player.add_runes(_total);
	        return inventory_action_result(true, "Gained " + string(_total) + " runes.");
		}
	);
    #endregion

    #region Category handlers
    item_category_register(
		"consumable",
		
		item_handler_create(
	        function(_item_id, _def) {				// Consumable-specific actions
	            return ["Use"];
	        },
			{ Use: item_action_use_consumable },	// Actions handlers mapping
			function(_item_id, _def, _action) {		// Always support use
	            if (is_undefined(item_effect_get(_def))) {
	                return "Using this item is not supported yet.";
	            }

	            return "";
	        },
	        function(_item_id, _def, _action) {		// Maximum usage is amount in inventory
	            var _effect = item_effect_get(_def);
	            var _max = inventory_count_item(global.player_inventory, _item_id);

	            if (is_struct(_effect) && is_callable(_effect.max_uses)) {
	                _max = min(_max, _effect.max_uses(_def));
	            }

	            return _max;
	        }
			// Non-replacable on use
		)
	);

	// (Un)Equippable items
    item_category_register("weapon", item_handler_equipment("weapon", "Weapon"));
    item_category_register("shield", item_handler_equipment("shield", "Shield"));
    item_category_register("armor", item_handler_equipment("armor", "Armor"));
    item_category_register("talisman", item_handler_talisman());

    // Types without gameplay yet: they show an explanatory action instead of "silently" doing nothing.
    item_category_register("material", item_handler_placeholder("Upgrade materials are not supported yet."));
    item_category_register("ammo", item_handler_placeholder("Ammunition is not supported yet."));
    item_category_register("key", item_handler_placeholder("Key items are not supported yet."));
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

/// @function item_effect_register(_effect, _fn, _max_uses)
/// @description Register a consumable effect. The function receives the item definition and the quantity
/// used, and returns an ActionResult; the items are consumed only when the result is ok.
/// @param {String} _effect The use_effect name used in item definitions.
/// @param {Function} _fn function(def, quantity) applying the effect.
/// @param {Function} [_max_uses] function(def) returning how many are useful at once; omit for no cap.
function item_effect_register(_effect, _fn, _max_uses = undefined) {
    global.item_effect_handlers[$ _effect] = { apply: _fn, max_uses: _max_uses };
}

/// @function item_effect_get(_def)
/// @param {Struct.ItemDefinition} _def The consumable definition.
/// @returns {Struct|undefined} The registered effect, or undefined if the item has no supported effect.
function item_effect_get(_def) {
    if (!variable_struct_exists(_def, "use_effect")) return undefined;
    return global.item_effect_handlers[$ _def.use_effect];
}

/// @function item_handler_create(_get_actions, _actions, _get_unsupported_reason, _get_max_quantity, _get_replace_options)
/// @param {Function} _get_actions function(item_id, def) returning the category-specific action names.
/// @param {Struct} _actions Map of action name to function(item_id, def, quantity, replace_id) returning an
/// ActionResult. replace_id is undefined unless the player picked an item to replace.
/// @param {Function} [_get_unsupported_reason] function(item_id, def, action) returning a reason string
/// when the action is not supported (shown grayed out in the menu), or "" when it is supported.
/// Only called for actions listed in `_actions`; Drop and Discard are always supported.
/// @param {Function} [_get_max_quantity] function(item_id, def, action) returning how many can be used at
/// once. Above 1, the UI asks for a quantity; omit for single-use actions.
/// @param {Function} [_get_replace_options] function(item_id, def, action) returning item ids the player must
/// choose one of to replace (e.g. all talisman slots full); an empty array means no choice is needed.
/// @returns {Struct.ItemHandler} The handler.
function item_handler_create(_get_actions, _actions, _get_unsupported_reason = undefined, _get_max_quantity = undefined, _get_replace_options = undefined) {
    return {
        get_actions: _get_actions,
        actions: _actions,
        get_unsupported_reason: _get_unsupported_reason,
        get_max_quantity: _get_max_quantity,
        get_replace_options: _get_replace_options
    };
}#endregion


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

    _handler.actions[$ "Equip"] = method({ slot: _slot, label: _label }, function(_item_id, _def, _quantity) {
        if (!global.player.can_equip_within_load(slot, _item_id)) {
            return inventory_action_result(false, "Too heavy: exceeds your equip load.");
        }

        global.player.equip(slot, _item_id);
        return inventory_action_result(true, label + " equipped.");
    });

    _handler.actions[$ "Unequip"] = method({ slot: _slot, label: _label }, function(_item_id, _def, _quantity) {
        if (global.player.get_equipped_id(slot) != _item_id) {
            return inventory_action_result(false, "Item is not equipped.");
        }

        global.player.unequip(slot);
        return inventory_action_result(true, label + " unequipped.");
    });

    return _handler;
}

/// @function item_handler_talisman()
/// @description Build a handler for talismans, which share a capped list of worn slots.
/// @returns {Struct.ItemHandler} The handler.
function item_handler_talisman() {
    return item_handler_create(
        function(_item_id, _def) {
            return [global.player.is_talisman_equipped(_item_id) ? "Unequip" : "Equip"];
        },
        {
            Equip: function(_item_id, _def, _quantity, _replace_id = undefined) {
                if (!global.player.can_equip_within_load("talisman", _item_id, _replace_id)) {
                    return inventory_action_result(false, "Too heavy: exceeds your equip load.");
                }

                if (!is_undefined(_replace_id) && global.player.unequip_talisman(_replace_id)) {
                    global.player.equip_talisman(_item_id);
                    return inventory_action_result(true, "Replaced " + item_definition_get(_replace_id).name + ".");
                }

                if (!global.player.equip_talisman(_item_id)) {
                    return inventory_action_result(false, "All " + string(global.player.max_talismans) + " talisman slots are full.");
                }

                return inventory_action_result(true, "Talisman equipped.");
            },
            Unequip: function(_item_id, _def, _quantity, _replace_id = undefined) {
                if (!global.player.unequip_talisman(_item_id)) {
                    return inventory_action_result(false, "Item is not equipped.");
                }

                return inventory_action_result(true, "Talisman unequipped.");
            }
        },
        undefined,
        undefined,
        function(_item_id, _def, _action) {
            // Only Equip with every slot taken needs a choice.
            if (_action == "Equip" && !global.player.can_equip_talisman()) {
                return variable_clone(global.player.talismans);
            }

            return [];
        }
    );
}

/// @function item_handler_placeholder(_message)
/// @description Build a handler for a type that has no behavior yet; its "Use" action is grayed out and reports the message.
/// @param {String} _message The reason shown when the action is chosen.
/// @returns {Struct.ItemHandler} The handler.
function item_handler_placeholder(_message) {
    return item_handler_create(
        function(_item_id, _def) {
            return ["Use"];
        },
        { Use: method({ message: _message }, function(_item_id, _def, _quantity) {
            return inventory_action_result(false, message);
        }) },
        method({ message: _message }, function(_item_id, _def, _action) {
            return message;
        })
    );
}

/// @function item_action_use_consumable(_item_id, _def, _quantity)
/// @description Run a consumable's use_effect and consume the used items when it succeeds.
/// @param {String} _item_id The item id.
/// @param {Struct.ItemDefinition} _def The item definition.
/// @param {Real} _quantity How many to use at once.
/// @returns {Struct.ActionResult} The outcome.
function item_action_use_consumable(_item_id, _def, _quantity) {
    var _effect = item_effect_get(_def);

    if (is_undefined(_effect)) {
        return inventory_action_result(false, "This item cannot be used yet.");
    }

    var _result = _effect.apply(_def, _quantity);

    if (_result.ok && !inventory_remove(global.player_inventory, _item_id, _quantity)) {
        return inventory_action_result(false, "Could not consume item.");
    }

    return _result;
}
#endregion