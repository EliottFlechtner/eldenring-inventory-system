/// scr_character_stats

function character_get_equipment_definition(_slot_name) {
    var _item_id = "";

    switch (_slot_name) {
        case "weapon":
            _item_id = global.player_equipment.weapon;
            break;

        case "armor":
            _item_id = global.player_equipment.armor;
            break;
    }

    if (_item_id == "") {
        return undefined;
    }

    return item_definition_get(_item_id);
}


function character_get_attack() {
    var _attack = global.player_base_attack;
    var _weapon = character_get_equipment_definition("weapon");

    if (is_struct(_weapon)
    && variable_struct_exists(_weapon, "attack")) {
        _attack += _weapon.attack;
    }

    return _attack;
}


function character_get_defense() {
    var _defense = global.player_base_defense;
    var _armor = character_get_equipment_definition("armor");

    if (is_struct(_armor)
    && variable_struct_exists(_armor, "defense")) {
        _defense += _armor.defense;
    }

    return _defense;
}


function character_get_equipment_item_id(_slot_name) {
    switch (_slot_name) {
        case "weapon":
            return global.player_equipment.weapon;

        case "armor":
            return global.player_equipment.armor;
    }

    return "";
}