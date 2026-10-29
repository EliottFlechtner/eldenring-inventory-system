/// @function Player(_name, _max_health, _health, _base_attack, _base_defense)
/// @description Create a player state object with health, base stats, and equipment.
/// @param {String} _name The player's display name.
/// @param {Real} _max_health The maximum health value.
/// @param {Real} _health The starting health, clamped to the valid range.
/// @param {Real} _base_attack The player's unequipped attack value.
/// @param {Real} _base_defense The player's unequipped defense value.
/// @returns {Struct.Player} The initialized player object and its instance methods.
function Player(_name = "Player", _max_health = 100, _health = 100, _base_attack = 0, _base_defense = 0) constructor {
    name = _name;
    max_health = _max_health;
    health_ = clamp(_health, 0, _max_health);
    base_attack = _base_attack;
    base_defense = _base_defense;

    #region Equipment methods
    // Equipped item IDs. Empty string means no equipment.
    equipment = {
        weapon: "",
        armor: ""
    };

    /// @function Player.is_equipment_slot(_slot)
    /// @description Check whether a slot accepts equipment.
    /// @param {String} _slot The equipment slot name to validate.
    /// @returns {Boolean} Whether the slot is weapon or armor.
    static is_equipment_slot = function(_slot) {
        return _slot == "weapon" || _slot == "armor";
    };

    /// @function Player.get_equipped_id(_slot)
    /// @description Get the item id equipped in a valid slot.
    /// @param {String} _slot The equipment slot to query.
    /// @returns {String} The equipped item id, or an empty string for invalid or empty slots.
    static get_equipped_id = function(_slot) {
        if (!is_equipment_slot(_slot)) return "";
        return equipment[$ _slot];
    };

    /// @function Player.get_equipped_definition(_slot)
    /// @description Look up the definition of the item in an equipment slot.
    /// @param {String} _slot The equipment slot to query.
    /// @returns {Struct.ItemDefinition|undefined} The equipped item definition, or undefined if the slot is empty or invalid.
    static get_equipped_definition = function(_slot) {
        var _item_id = get_equipped_id(_slot);
        if (_item_id == "") return undefined;
        return item_definition_get(_item_id);
    };

    /// @function Player.is_equipped(_item_id)
    /// @description Check whether an item is equipped in either supported slot.
    /// @param {String} _item_id The item id to check.
    /// @returns {Boolean} Whether the item is currently equipped.
    static is_equipped = function(_item_id) {
        return _item_id != "" && (equipment.weapon == _item_id || equipment.armor == _item_id);
    };

    /// @function Player.equip(_slot, _item_id)
    /// @description Equip an item id in a supported slot.
    /// @param {String} _slot The equipment slot to update.
    /// @param {String} _item_id The item id to equip, or an empty string to clear the slot.
    /// @returns {Boolean} Whether the slot was valid and updated.
    static equip = function(_slot, _item_id) {
        if (!is_equipment_slot(_slot)) return false;
        equipment[$ _slot] = _item_id;
        return true;
    };

    /// @function Player.unequip(_slot)
    /// @description Clear a supported equipment slot.
    /// @param {String} _slot The equipment slot to clear.
    /// @returns {Boolean} Whether the slot was valid and cleared.
    static unequip = function(_slot) {
        return equip(_slot, "");
    };

    /// @function Player.unequip_item(_item_id)
    /// @description Clear any equipment slot containing the specified item.
    /// @param {String} _item_id The item id to remove from equipment.
    /// @returns {undefined} No value is returned.
    static unequip_item = function(_item_id) {
        if (equipment.weapon == _item_id) equipment.weapon = "";
        if (equipment.armor == _item_id) equipment.armor = "";
    };

    #endregion

    #region Character stat methods
    /// @function Player.get_attack()
    /// @description Calculate attack from the base stat and equipped weapon.
    /// @returns {Real} The total attack value.
    static get_attack = function() {
        var _attack = base_attack;
        var _weapon = get_equipped_definition("weapon");

        if (is_struct(_weapon) && variable_struct_exists(_weapon, "attack")) {
            _attack += _weapon.attack;
        }

        return _attack;
    };

    /// @function Player.get_defense()
    /// @description Calculate defense from the base stat and equipped armor.
    /// @returns {Real} The total defense value.
    static get_defense = function() {
        var _defense = base_defense;
        var _armor = get_equipped_definition("armor");

        if (is_struct(_armor) && variable_struct_exists(_armor, "defense")) {
            _defense += _armor.defense;
        }

        return _defense;
    };

    /// @function Player.is_health_full()
    /// @description Check whether health has reached its maximum.
    /// @returns {Boolean} Whether current health is at least maximum health.
    static is_health_full = function() {
        return health_ >= max_health;
    };

    /// @function Player.heal(_amount)
    /// @description Restore health without exceeding maximum health.
    /// @param {Real} _amount The requested amount of health to restore.
    /// @returns {Real} The amount of health actually restored.
    static heal = function(_amount) {
        var _before = health_;
        health_ = min(health_ + _amount, max_health);
        return health_ - _before;
    };
    #endregion
}