/// scr_item_skills
/// Resource costs, weapon skills, and spirit ash summoning.
///
/// A cost is a struct with any of `fp`, `hp`, `runes` (whole numbers), for example { fp: 20, hp: 10 }.
/// Anything that costs resources (a weapon skill, a spirit ash) puts a `cost` struct on its definition or
/// registered skill, and uses item_cost_shortfall() / item_cost_pay(), so a new resource only needs
/// support here.

#region Costs
/// @function item_cost_shortfall(_cost)
/// @description Explain why a cost cannot be paid right now.
/// @param {Struct|undefined} _cost The cost, or undefined for a free action.
/// @returns {String} The reason, or an empty string if the player can pay.
function item_cost_shortfall(_cost) {
    if (!is_struct(_cost)) return "";

    var _p = global.player;
    var _fp = _cost[$ "fp"] ?? 0;
    var _hp = _cost[$ "hp"] ?? 0;
    var _runes = _cost[$ "runes"] ?? 0;

    if (_p.fp < _fp) return "Not enough FP (needs " + string(_fp) + ", you have " + string(_p.fp) + ").";
    if (_hp > 0 && _p.health_ <= _hp) return "Not enough HP (costs " + string(_hp) + ", you have " + string(_p.health_) + ").";
    if (_p.runes < _runes) return "Not enough runes (needs " + string(_runes) + ").";

    return "";
}


/// @function item_cost_pay(_cost)
/// @description Spend a cost. All resources are checked first, so it is paid in full or not at all.
/// @param {Struct|undefined} _cost The cost.
/// @returns {Boolean} Whether the cost was paid.
function item_cost_pay(_cost) {
    if (!is_struct(_cost)) return true;
    if (item_cost_shortfall(_cost) != "") return false;

    var _p = global.player;
    var _hp = _cost[$ "hp"] ?? 0;

    return _p.spend_fp(_cost[$ "fp"] ?? 0)
        && (_hp <= 0 || _p.spend_health(_hp))
        && _p.spend_runes(_cost[$ "runes"] ?? 0);
}


/// @function item_cost_text(_cost)
/// @param {Struct|undefined} _cost The cost.
/// @returns {String} A short description such as "20 FP, 10 HP", or "Free".
function item_cost_text(_cost) {
    if (!is_struct(_cost)) return "Free";

    var _parts = [];
    if ((_cost[$ "fp"] ?? 0) > 0) array_push(_parts, string(_cost.fp) + " FP");
    if ((_cost[$ "hp"] ?? 0) > 0) array_push(_parts, string(_cost.hp) + " HP");
    if ((_cost[$ "runes"] ?? 0) > 0) array_push(_parts, string(_cost.runes) + " Runes");

    if (array_length(_parts) == 0) return "Free";

    var _text = _parts[0];
    for (var i = 1; i < array_length(_parts); i++) _text += ", " + _parts[i];

    return _text;
}
#endregion


#region Weapon skills
/// @function item_skills_init()
/// @description Build the weapon skill registry. Weapons reference a skill by id through their `skill` field.
function item_skills_init() {
    global.item_skills = {};

    item_skill_register("unsheathe", "Unsheathe", { fp: 10 }, "A swift draw strike.");
    item_skill_register("lion_claw", "Lion's Claw", { fp: 20 }, "A leaping, powerful slash.");
    item_skill_register("square_off", "Square Off", { fp: 12 }, "A guarded stance with a heavy counter.");
    item_skill_register("carian_grandeur", "Carian Grandeur", { fp: 25 }, "Imbues the blade with glintstone.");
    item_skill_register("transient_moonlight", "Transient Moonlight", { fp: 28 }, "Looses a wave of moonlight.");
    item_skill_register("corpse_piler", "Corpse Piler", { fp: 18 }, "A flurry of crimson cuts.");
    item_skill_register("night_and_flame_stance", "Night-and-Flame Stance", { fp: 30 }, "Unleashes both flame and night.");
    item_skill_register("oath_of_vengeance", "Oath of Vengeance", { fp: 25 }, "Turns pain into power.");
    item_skill_register("flaming_strike", "Flaming Strike", { fp: 15 }, "A fiery overhead smash.");
    item_skill_register("mighty_shot", "Mighty Shot", { fp: 10 }, "A powerful, long-range shot.");
    item_skill_register("rain_of_arrows", "Rain of Arrows", { fp: 20 }, "Fires arrows high into the air.");
}


/// @function item_skill_register(_id, _name, _cost, _description, _apply)
/// @description Register (or replace) a weapon skill.
/// @param {String} _id The id weapons use in their `skill` field.
/// @param {String} _name The display name.
/// @param {Struct} _cost The resources the skill costs.
/// @param {String} _description A short description.
/// @param {Function} [_apply] function(def, skill) applying extra effects and returning an ActionResult.
function item_skill_register(_id, _name, _cost, _description, _apply = undefined) {
    global.item_skills[$ _id] = { id: _id, name: _name, cost: _cost, description: _description, apply: _apply };
}


/// @function item_skill_get(_def)
/// @param {Struct.ItemDefinition} _def A weapon definition.
/// @returns {Struct|undefined} The weapon's registered skill, or undefined if it has none.
function item_skill_get(_def) {
    if (!is_struct(_def) || !variable_struct_exists(_def, "skill")) return undefined;

    var _skills = global[$ "item_skills"];
    if (!is_struct(_skills)) return undefined;

    return _skills[$ _def.skill];
}


/// @function item_action_weapon_skill(_item_id, _def, _quantity)
/// @description Pay a weapon skill's cost and apply it. A failure is rolled back by inventory_execute_action.
/// @returns {Struct.ActionResult} The outcome.
function item_action_weapon_skill(_item_id, _def, _quantity) {
    var _skill = item_skill_get(_def);

    if (!is_struct(_skill)) return inventory_action_result(false, "This weapon has no skill.");

    var _reason = item_cost_shortfall(_skill.cost);
    if (_reason != "") return inventory_action_result(false, _reason);

    if (!item_cost_pay(_skill.cost)) return inventory_action_result(false, "Could not pay the skill cost.");

    if (is_callable(_skill.apply)) {
        var _result = _skill.apply(_def, _skill);
        if (!_result.ok) return _result;
    }

    return inventory_action_result(true, _skill.name + "! (-" + item_cost_text(_skill.cost) + ")");
}


/// @function item_handler_weapon()
/// @description Equipment handler for weapons, plus a "Weapon Skill" action while the weapon is equipped.
/// @returns {Struct.ItemHandler} The handler.
function item_handler_weapon() {
    var _handler = item_handler_equipment("weapon", "Weapon");

    _handler.get_actions = method({ base: _handler.get_actions }, function(_item_id, _def) {
        var _actions = base(_item_id, _def);

        if (global.player.get_equipped_id("weapon") == _item_id && is_struct(item_skill_get(_def))) {
            array_insert(_actions, 0, "Weapon Skill");
        }

        return _actions;
    });

    _handler.actions[$ "Weapon Skill"] = item_action_weapon_skill;

    _handler.get_unsupported_reason = function(_item_id, _def, _action) {
        if (_action != "Weapon Skill") return "";

        var _skill = item_skill_get(_def);
        if (!is_struct(_skill)) return "This weapon has no skill.";

        return item_cost_shortfall(_skill.cost);
    };

    return _handler;
}
#endregion


#region Spirit ashes
/// @function item_handler_spirit_ash()
/// @description Handler for spirit ashes: Use summons the spirit (paying the definition's `cost`) and Dismiss
/// ends it. The ash is not consumed.
/// @returns {Struct.ItemHandler} The handler.
function item_handler_spirit_ash() {
    return item_handler_create(
        function(_item_id, _def) {
            return [global.player.summon == _item_id ? "Dismiss" : "Use"];
        },
        {
            Use: function(_item_id, _def, _quantity) {
                var _reason = item_cost_shortfall(_def[$ "cost"]);
                if (_reason != "") return inventory_action_result(false, _reason);

                if (!item_cost_pay(_def[$ "cost"])) return inventory_action_result(false, "Could not pay the summoning cost.");

                global.player.summon = _item_id;
                inventory_event_emit(INV_EVENT_EQUIPMENT);

                return inventory_action_result(true, _def.name + " summoned. (-" + item_cost_text(_def[$ "cost"]) + ")");
            },
            Dismiss: function(_item_id, _def, _quantity) {
                if (global.player.summon != _item_id) return inventory_action_result(false, "This spirit is not summoned.");

                global.player.summon = "";
                inventory_event_emit(INV_EVENT_EQUIPMENT);

                return inventory_action_result(true, _def.name + " dismissed.");
            }
        },
        function(_item_id, _def, _action) {
            if (_action != "Use") return "";

            if (global.player.summon != "") {
                return item_definition_get(global.player.summon).name + " is already summoned. Dismiss it first.";
            }

            return item_cost_shortfall(_def[$ "cost"]);
        }
    );
}
#endregion
