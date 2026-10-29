/// @function equipment_get_comparison(_item_id)
/// @description Compare an item's attack or defense against the currently equipped item.
/// @param {String} _item_id The item id to compare with the current equipment.
/// @returns {Struct.EquipmentComparison|undefined} Comparison data with validity, stat name, current value, and new value; undefined if the item is unknown.
function equipment_get_comparison(_item_id) {
    var _def = item_definition_get(_item_id);

    if (is_undefined(_def)) {
        return undefined;
    }

    var _comparison = {
        valid: false,
        stat_name: "",
        current_value: 0,
        new_value: 0
    };

    #region Select comparable stat
    // Which stat each equipment category affects.
    var _stat_field = "";

    switch (_def.category) {
        case "weapon":
            _stat_field = "attack";
            _comparison.stat_name = "Attack";
            _comparison.current_value = global.player.get_attack();
            break;
        case "armor":
        case "shield":
            _stat_field = "defense";
            _comparison.stat_name = "Defense";
            _comparison.current_value = global.player.get_defense();
            break;
        default:
            return _comparison;
    }
    #endregion

    #region Calculate candidate stat
    // Replace whatever the slot currently provides with the candidate's bonus.
    var _new_bonus = variable_struct_exists(_def, _stat_field) ? _def[$ _stat_field] : 0;
    var _old_bonus = global.player.get_equipped_stat(_def.category, _stat_field);

    _comparison.valid = true;
    _comparison.new_value = _comparison.current_value - _old_bonus + _new_bonus;
    #endregion

    return _comparison;
}