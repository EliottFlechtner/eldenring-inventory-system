/// scr_equipment_comparison

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

    if (_def.category == "weapon") {
        var _old_weapon_id = global.player.get_equipped_id("weapon");
        var _old_bonus = 0;

        if (_old_weapon_id != "") {
            var _old_weapon = item_definition_get(_old_weapon_id);

            if (is_struct(_old_weapon)
            && variable_struct_exists(_old_weapon, "attack")) {
                _old_bonus = _old_weapon.attack;
            }
        }

        var _new_bonus = 0;

        if (variable_struct_exists(_def, "attack")) {
            _new_bonus = _def.attack;
        }

        _comparison.valid = true;
        _comparison.stat_name = "Attack";
        _comparison.current_value = global.player.get_attack();
        _comparison.new_value =
            global.player.base_attack + _new_bonus;

        return _comparison;
    }

    if (_def.category == "armor") {
        var _old_armor_id = global.player.get_equipped_id("armor");
        var _old_armor_bonus = 0;

        if (_old_armor_id != "") {
            var _old_armor = item_definition_get(_old_armor_id);

            if (is_struct(_old_armor)
            && variable_struct_exists(_old_armor, "defense")) {
                _old_armor_bonus = _old_armor.defense;
            }
        }

        var _new_armor_bonus = 0;

        if (variable_struct_exists(_def, "defense")) {
            _new_armor_bonus = _def.defense;
        }

        _comparison.valid = true;
        _comparison.stat_name = "Defense";
        _comparison.current_value = global.player.get_defense();
        _comparison.new_value =
            global.player.base_defense + _new_armor_bonus;

        return _comparison;
    }

    return _comparison;
}