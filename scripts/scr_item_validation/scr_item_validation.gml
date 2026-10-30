/// scr_item_validation
/// Startup checks for the item database, templates, category handlers, and consumable effects.
/// Errors mean something is broken; warnings mean something is incomplete but safe (for example an
/// effect that is intentionally unsupported, which just grays the action out).

/// @function item_validation_add(_report, _is_error, _message)
/// @param {Struct} _report The report to add to.
/// @param {Boolean} _is_error True for an error, false for a warning.
/// @param {String} _message The problem description.
function item_validation_add(_report, _is_error, _message) {
    array_push(_is_error ? _report.errors : _report.warnings, _message);
}


/// @function item_validation_is_whole(_value)
/// @param {Any} _value The value to test.
/// @returns {Boolean} Whether it is a real, whole number.
function item_validation_is_whole(_value) {
    return is_real(_value) && floor(_value) == _value;
}


/// @function item_validation_check_cost(_report, _cost, _owner)
/// @description Check that a cost struct only holds non-negative whole fp, hp, and runes values.
function item_validation_check_cost(_report, _cost, _owner) {
    if (!is_struct(_cost)) {
        item_validation_add(_report, true, _owner + " has a cost that is not a struct.");
        return;
    }

    var _names = variable_struct_get_names(_cost);

    for (var i = 0; i < array_length(_names); i++) {
        var _name = _names[i];

        if (_name != "fp" && _name != "hp" && _name != "runes") {
            item_validation_add(_report, true, _owner + " has an unknown cost resource '" + _name + "'.");
        }
        else if (!item_validation_is_whole(_cost[$ _name]) || _cost[$ _name] < 0) {
            item_validation_add(_report, true, _owner + " has an invalid " + _name + " cost.");
        }
    }
}


/// @function item_validation_check_definition(_report, _def, _index)
/// @description Check one raw definition's fields and its effect and handler references.
/// @param {Struct} _report The report to add to.
/// @param {Struct.ItemDefinition} _def The definition to check.
/// @param {Real} _index Its position in the raw list, used when it has no usable id.
function item_validation_check_definition(_report, _def, _index) {
    if (!is_struct(_def)) {
        item_validation_add(_report, true, "Item #" + string(_index) + " is not a struct.");
        return;
    }

    var _id = _def[$ "id"];
    var _label = is_string(_id) && _id != "" ? _id : "#" + string(_index);

    if (!is_string(_id) || _id == "") {
        item_validation_add(_report, true, "Item " + _label + " has no valid id.");
    }
    if (!is_string(_def[$ "name"]) || _def[$ "name"] == "") {
        item_validation_add(_report, true, "Item " + _label + " has no name.");
    }
    if (!is_string(_def[$ "category"]) || _def[$ "category"] == "") {
        item_validation_add(_report, true, "Item " + _label + " has no category.");
    }
    if (!is_string(_def[$ "description"])) {
        item_validation_add(_report, false, "Item " + _label + " has no description.");
    }
    if (!is_bool(_def[$ "stackable"])) {
        item_validation_add(_report, true, "Item " + _label + " needs a boolean 'stackable'.");
    }

    var _max_stack = _def[$ "max_stack"];
    if (!item_validation_is_whole(_max_stack) || _max_stack < 1) {
        item_validation_add(_report, true, "Item " + _label + " needs a whole 'max_stack' of at least 1.");
    }
    else if (_def[$ "stackable"] == false && _max_stack != 1) {
        item_validation_add(_report, true, "Item " + _label + " is not stackable but has max_stack " + string(_max_stack) + ".");
    }

    // Numeric stats must be non-negative numbers when present.
    var _stat_fields = ["attack", "defense", "weight", "use_amount"];
    for (var i = 0; i < array_length(_stat_fields); i++) {
        var _field = _stat_fields[i];
        if (!variable_struct_exists(_def, _field)) continue;

        if (!is_real(_def[$ _field]) || _def[$ _field] < 0) {
            item_validation_add(_report, true, "Item " + _label + " has an invalid '" + _field + "'.");
        }
    }

    var _category = _def[$ "category"];
    if (!is_string(_category)) return;

    if (_category == "weapon" && !variable_struct_exists(_def, "attack")) {
        item_validation_add(_report, false, "Weapon " + _label + " has no attack.");
    }
    if ((_category == "armor" || _category == "shield") && !variable_struct_exists(_def, "defense")) {
        item_validation_add(_report, false, "Armor/shield " + _label + " has no defense.");
    }

    #region Costs and skills
    if (variable_struct_exists(_def, "cost")) {
        item_validation_check_cost(_report, _def.cost, "Item " + _label);
    }

    if (variable_struct_exists(_def, "skill")) {
        var _skills = global[$ "item_skills"];

        if (_category != "weapon") {
            item_validation_add(_report, false, "Item " + _label + " has a skill but is not a weapon (the skill is ignored).");
        }
        else if (!is_string(_def.skill) || _def.skill == "") {
            item_validation_add(_report, true, "Weapon " + _label + " has an invalid skill.");
        }
        else if (is_struct(_skills) && !variable_struct_exists(_skills, _def.skill)) {
            item_validation_add(_report, false, "Weapon " + _label + " uses unregistered skill '" + _def.skill + "' (no Weapon Skill action).");
        }
    }
    #endregion

    #region Effects
    if (_category == "consumable") {
        if (!variable_struct_exists(_def, "use_effect")) {
            item_validation_add(_report, false, "Consumable " + _label + " has no use_effect.");
        }
        else if (!is_string(_def.use_effect) || _def.use_effect == "") {
            item_validation_add(_report, true, "Consumable " + _label + " has an invalid use_effect.");
        }
        else {
            if (!variable_struct_exists(_def, "use_amount")) {
                item_validation_add(_report, true, "Consumable " + _label + " has an effect but no use_amount.");
            }

            var _effects = global[$ "item_effect_handlers"];
            if (is_struct(_effects) && !variable_struct_exists(_effects, _def.use_effect)) {
                item_validation_add(_report, false, "Consumable " + _label + " uses unregistered effect '" + _def.use_effect + "' (Use stays grayed out).");
            }
        }
    }
    #endregion

    #region Handler coverage
    var _handlers = global[$ "item_category_handlers"];
    if (!is_struct(_handlers)) return;

    if (!variable_struct_exists(_handlers, _category)) {
        item_validation_add(_report, false, "Item " + _label + " has category '" + _category + "' with no handler (only Drop and Discard).");
        return;
    }

    // Every action a handler offers for this item must have an implementation.
    var _handler = _handlers[$ _category];
    if (!is_struct(_handler) || !is_callable(_handler[$ "get_actions"]) || !is_struct(_handler[$ "actions"])) return;

    try {
        var _offered = _handler.get_actions(_id, _def);

        if (!is_array(_offered)) {
            item_validation_add(_report, true, "Handler '" + _category + "' returned non-array actions for " + _label + ".");
        }
        else {
            for (var a = 0; a < array_length(_offered); a++) {
                if (!is_callable(_handler.actions[$ _offered[a]])) {
                    item_validation_add(_report, true, "Handler '" + _category + "' offers '" + string(_offered[a]) + "' for " + _label + " without an implementation.");
                }
            }
        }
    }
    catch (_e) {
        item_validation_add(_report, true, "Handler '" + _category + "' failed on " + _label + ": " + string(_e.message));
    }
    #endregion
}


/// @function item_validation_check_handlers(_report)
/// @description Check the structure of every registered category handler and consumable effect.
/// @param {Struct} _report The report to add to.
function item_validation_check_handlers(_report) {
    var _skills = global[$ "item_skills"];

    if (is_struct(_skills)) {
        var _skill_ids = variable_struct_get_names(_skills);

        for (var s = 0; s < array_length(_skill_ids); s++) {
            var _skill = _skills[$ _skill_ids[s]];

            if (!is_string(_skill[$ "name"]) || _skill.name == "") {
                item_validation_add(_report, true, "Skill '" + _skill_ids[s] + "' has no name.");
            }

            item_validation_check_cost(_report, _skill[$ "cost"] ?? {}, "Skill '" + _skill_ids[s] + "'");
        }
    }

    var _handlers = global[$ "item_category_handlers"];

    if (!is_struct(_handlers)) {
        item_validation_add(_report, true, "Category handlers are not initialized (call item_handlers_init()).");
    }
    else {
        var _names = variable_struct_get_names(_handlers);

        for (var i = 0; i < array_length(_names); i++) {
            var _name = _names[i];
            var _h = _handlers[$ _name];

            if (!is_struct(_h) || !is_callable(_h[$ "get_actions"]) || !is_struct(_h[$ "actions"])) {
                item_validation_add(_report, true, "Handler '" + _name + "' needs get_actions and an actions struct.");
                continue;
            }

            var _action_names = variable_struct_get_names(_h.actions);
            for (var a = 0; a < array_length(_action_names); a++) {
                if (!is_callable(_h.actions[$ _action_names[a]])) {
                    item_validation_add(_report, true, "Handler '" + _name + "' action '" + _action_names[a] + "' is not a function.");
                }
            }

            // Optional callbacks must be callable when provided.
            var _optional = ["get_unsupported_reason", "get_max_quantity", "get_replace_options"];
            for (var o = 0; o < array_length(_optional); o++) {
                var _cb = _h[$ _optional[o]];
                if (!is_undefined(_cb) && !is_callable(_cb)) {
                    item_validation_add(_report, true, "Handler '" + _name + "' has an invalid " + _optional[o] + ".");
                }
            }
        }
    }

    var _effects = global[$ "item_effect_handlers"];

    if (!is_struct(_effects)) {
        item_validation_add(_report, true, "Item effects are not initialized (call item_handlers_init()).");
        return;
    }

    var _effect_names = variable_struct_get_names(_effects);
    for (var i = 0; i < array_length(_effect_names); i++) {
        var _effect = _effects[$ _effect_names[i]];

        if (!is_struct(_effect) || !is_callable(_effect[$ "apply"])) {
            item_validation_add(_report, true, "Effect '" + _effect_names[i] + "' has no apply function.");
        }
        else if (!is_undefined(_effect[$ "max_uses"]) && !is_callable(_effect.max_uses)) {
            item_validation_add(_report, true, "Effect '" + _effect_names[i] + "' has an invalid max_uses.");
        }
    }
}


/// @function item_validation_check_templates(_report, _templates)
/// @description Check that template entries reference known items with valid quantities.
/// @param {Struct} _report The report to add to.
/// @param {Struct} _templates The inventory templates struct.
function item_validation_check_templates(_report, _templates) {
    if (!is_struct(_templates)) return;

    var _names = variable_struct_get_names(_templates);

    for (var i = 0; i < array_length(_names); i++) {
        var _entries = _templates[$ _names[i]];

        if (!is_array(_entries)) {
            item_validation_add(_report, true, "Template '" + _names[i] + "' is not a list.");
            continue;
        }

        for (var e = 0; e < array_length(_entries); e++) {
            var _entry = _entries[e];
            var _item_id = is_array(_entry) ? _entry[0] : undefined;
            var _qty = is_array(_entry) && array_length(_entry) > 1 ? _entry[1] : 1;

            if (!is_string(_item_id) || is_undefined(item_definition_get(_item_id))) {
                item_validation_add(_report, false, "Template '" + _names[i] + "' references unknown item '" + string(_item_id) + "' (skipped when filling).");
            }
            else if (!item_validation_is_whole(_qty) || _qty < 1) {
                item_validation_add(_report, true, "Template '" + _names[i] + "' has an invalid quantity for '" + _item_id + "'.");
            }
        }
    }
}


/// @function item_validation_collect(_definitions, _duplicates, _templates)
/// @description Run every check and return the findings without logging them.
/// @param {Array<Struct>} _definitions The raw definition list.
/// @param {Array<String>} _duplicates Ids that appeared more than once when the database was built.
/// @param {Struct} _templates The inventory templates struct.
/// @returns {Struct} A report with `errors` and `warnings` string arrays.
function item_validation_collect(_definitions, _duplicates, _templates) {
    var _report = { errors: [], warnings: [] };

    for (var i = 0; i < array_length(_duplicates); i++) {
        item_validation_add(_report, true, "Duplicate item id '" + _duplicates[i] + "'.");
    }

    for (var i = 0; i < array_length(_definitions); i++) {
        item_validation_check_definition(_report, _definitions[i], i);
    }

    item_validation_check_handlers(_report);
    item_validation_check_templates(_report, _templates);

    return _report;
}


/// @function item_validation_run()
/// @description Validate the live database, handlers, effects, and templates, and log the findings.
/// Call after item_database_init() and item_handlers_init().
/// @returns {Struct} The report, also stored in global.item_validation.
function item_validation_run() {
    var _report = item_validation_collect(
        global.item_db_raw,
        global.item_db_duplicates,
        global.inventory_templates
    );

    global.item_validation = _report;

    for (var i = 0; i < array_length(_report.errors); i++) {
        show_debug_message("[VALIDATION ERROR] " + _report.errors[i]);
    }
    for (var i = 0; i < array_length(_report.warnings); i++) {
        show_debug_message("[VALIDATION WARNING] " + _report.warnings[i]);
    }

    show_debug_message("Item validation: " + string(array_length(_report.errors)) + " error(s), "
        + string(array_length(_report.warnings)) + " warning(s).");

    return _report;
}
