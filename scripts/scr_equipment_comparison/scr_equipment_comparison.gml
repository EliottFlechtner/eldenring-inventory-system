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
    var _stat_field = "";

    if (_def.category == "weapon") {
        _stat_field = "attack";
        _comparison.stat_name = "Attack";
        _comparison.current_value = global.player.get_attack();
    }
    else if (_def.category == "armor") {
        _stat_field = "defense";
        _comparison.stat_name = "Defense";
        _comparison.current_value = global.player.get_defense();
    }
    else {
        return _comparison;
    }
	#endregion

    #region Calculate candidate stat
    var _new_bonus = 0;

    if (variable_struct_exists(_def, _stat_field)) {
        _new_bonus = variable_struct_get(_def, _stat_field);
    }

    var _base_stat = _stat_field == "attack"
        ? global.player.base_attack
        : global.player.base_defense;

    _comparison.valid = true;
    _comparison.new_value = _base_stat + _new_bonus;
    #endregion
	
    return _comparison;
}