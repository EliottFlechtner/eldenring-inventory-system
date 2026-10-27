/// scr_character_stats
/// Player object: health, base stats and equipment. Created as global.player.

function Player(_name = "Player", _max_health = 100, _health = 100, _base_attack = 0, _base_defense = 0) constructor {
    name = _name;
    max_health = _max_health;
    health_ = clamp(_health, 0, _max_health);
    base_attack = _base_attack;
    base_defense = _base_defense;

    // Equipped item IDs. Empty string means no equipment.
    equipment = {
        weapon: "",
        armor: ""
    };

    static is_equipment_slot = function(_slot) {
        return _slot == "weapon" || _slot == "armor";
    };

    static get_equipped_id = function(_slot) {
        if (!is_equipment_slot(_slot)) return "";
        return equipment[$ _slot];
    };

    static get_equipped_definition = function(_slot) {
        var _item_id = get_equipped_id(_slot);
        if (_item_id == "") return undefined;
        return item_definition_get(_item_id);
    };

    static is_equipped = function(_item_id) {
        return _item_id != "" && (equipment.weapon == _item_id || equipment.armor == _item_id);
    };

    static equip = function(_slot, _item_id) {
        if (!is_equipment_slot(_slot)) return false;
        equipment[$ _slot] = _item_id;
        return true;
    };

    static unequip = function(_slot) {
        return equip(_slot, "");
    };

    // Clear any slot holding this item (used when it is dropped or discarded).
    static unequip_item = function(_item_id) {
        if (equipment.weapon == _item_id) equipment.weapon = "";
        if (equipment.armor == _item_id) equipment.armor = "";
    };

    static get_attack = function() {
        var _attack = base_attack;
        var _weapon = get_equipped_definition("weapon");

        if (is_struct(_weapon) && variable_struct_exists(_weapon, "attack")) {
            _attack += _weapon.attack;
        }

        return _attack;
    };

    static get_defense = function() {
        var _defense = base_defense;
        var _armor = get_equipped_definition("armor");

        if (is_struct(_armor) && variable_struct_exists(_armor, "defense")) {
            _defense += _armor.defense;
        }

        return _defense;
    };

    static is_health_full = function() {
        return health_ >= max_health;
    };

    // Restore health, capped at max_health. Returns the amount actually restored.
    static heal = function(_amount) {
        var _before = health_;
        health_ = min(health_ + _amount, max_health);
        return health_ - _before;
    };
}