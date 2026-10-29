/// @function Player(_name, _max_health, _health, _base_attack, _base_defense)
/// @description Create a player state object with health, base stats, and equipment.
/// @param {String} _name The player's display name.
/// @param {Real} _max_health The maximum health value.
/// @param {Real} _health The starting health, clamped to the valid range.
/// @param {Real} _base_attack The player's unequipped attack value.
/// @param {Real} _base_defense The player's unequipped defense value.
/// @param {Real} _max_fp The maximum FP value.
/// @param {Real} _fp The starting FP, clamped to the valid range.
/// @param {Real} _runes The starting rune count.
/// @param {Real} _max_talismans How many talismans can be worn at once.
/// @param {Real} _max_equip_load The total weight of equipment the player can wear.
/// @returns {Struct.Player} The initialized player object and its instance methods.
function Player(_name = "Player", _max_health = 100, _health = 100, _base_attack = 0, _base_defense = 0, _max_fp = 50, _fp = 50, _runes = 0, _max_talismans = 4, _max_equip_load = 40) constructor {
    name = _name;
    max_health = _max_health;
    health_ = clamp(_health, 0, _max_health);
    base_attack = _base_attack;
    base_defense = _base_defense;
    max_fp = _max_fp;
    fp = clamp(_fp, 0, _max_fp);
    runes = max(_runes, 0);
    max_talismans = _max_talismans;
    max_equip_load = _max_equip_load;

    #region Equipment methods
    // Equipped item IDs. Empty string means no equipment.
    equipment = {
        weapon: "",
        shield: "",
        armor: ""
    };

    // Worn talisman item ids; the count is capped by max_talismans.
    talismans = [];

    /// @function Player.is_equipment_slot(_slot)
    /// @description Check whether a slot accepts equipment.
    /// @param {String} _slot The equipment slot name to validate.
    /// @returns {Boolean} Whether the slot exists in the equipment struct.
    static is_equipment_slot = function(_slot) {
        return variable_struct_exists(equipment, _slot);
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
        if (_item_id == "") return false;
        if (is_talisman_equipped(_item_id)) return true;

        var _slots = variable_struct_get_names(equipment);
        for (var i = 0; i < array_length(_slots); i++) {
            if (equipment[$ _slots[i]] == _item_id) return true;
        }

        return false;
    };

    /// @function Player.is_talisman_equipped(_item_id)
    /// @returns {Boolean} Whether the talisman is currently worn.
    static is_talisman_equipped = function(_item_id) {
        return array_contains(talismans, _item_id);
    };

    /// @function Player.can_equip_talisman()
    /// @returns {Boolean} Whether a talisman slot is free.
    static can_equip_talisman = function() {
        return array_length(talismans) < max_talismans;
    };

    /// @function Player.equip_talisman(_item_id)
    /// @param {String} _item_id The talisman item id.
    /// @returns {Boolean} Whether it was equipped (false if already worn or all slots are full).
    static equip_talisman = function(_item_id) {
        if (is_talisman_equipped(_item_id) || !can_equip_talisman()) return false;
        array_push(talismans, _item_id);
        return true;
    };

    /// @function Player.unequip_talisman(_item_id)
    /// @param {String} _item_id The talisman item id.
    /// @returns {Boolean} Whether the talisman was worn and removed.
    static unequip_talisman = function(_item_id) {
        var _index = array_get_index(talismans, _item_id);
        if (_index < 0) return false;
        array_delete(talismans, _index, 1);
        return true;
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
        unequip_talisman(_item_id);
        var _slots = variable_struct_get_names(equipment);
        for (var i = 0; i < array_length(_slots); i++) {
            if (equipment[$ _slots[i]] == _item_id) equipment[$ _slots[i]] = "";
        }
    };

    #endregion

    #region Character stat methods
    /// @function Player.get_equipped_stat(_slot, _stat)
    /// @description Read a numeric stat from the item equipped in a slot.
    /// @param {String} _slot The equipment slot to query.
    /// @param {String} _stat The definition field, such as attack or defense.
    /// @returns {Real} The stat value, or 0 if the slot is empty or lacks the stat.
    static get_equipped_stat = function(_slot, _stat) {
        var _def = get_equipped_definition(_slot);
        if (is_struct(_def) && variable_struct_exists(_def, _stat)) return _def[$ _stat];
        return 0;
    };

    /// @function Player.get_equip_load()
    /// @description Total weight of everything equipped, including talismans.
    /// @returns {Real} The current equip load.
    static get_equip_load = function() {
        var _load = 0;
        var _slots = variable_struct_get_names(equipment);

        for (var i = 0; i < array_length(_slots); i++) {
            _load += item_get_weight(equipment[$ _slots[i]]);
        }

        for (var i = 0; i < array_length(talismans); i++) {
            _load += item_get_weight(talismans[i]);
        }

        return _load;
    };

    /// @function Player.can_equip_within_load(_slot, _item_id, _replace_id)
    /// @description Check whether equipping an item keeps the equip load within the maximum. The item it
    /// displaces (the slot's current item, or the talisman being replaced) is subtracted first.
    /// @param {String} _slot An equipment slot, or "talisman".
    /// @param {String} _item_id The item to equip.
    /// @param {String} [_replace_id] The worn talisman being replaced, when _slot is "talisman".
    /// @returns {Boolean} Whether the resulting load fits.
    static can_equip_within_load = function(_slot, _item_id, _replace_id = undefined) {
        var _after = get_equip_load() + item_get_weight(_item_id);

        if (_slot == "talisman") {
            if (!is_undefined(_replace_id)) _after -= item_get_weight(_replace_id);
        }
        else if (is_equipment_slot(_slot)) {
            _after -= item_get_weight(equipment[$ _slot]);
        }

        // Small tolerance for fractional weights.
        return _after <= max_equip_load + 0.0001;
    };

    /// @function Player.get_attack()
    /// @description Calculate attack from the base stat and equipped weapon.
    /// @returns {Real} The total attack value.
    static get_attack = function() {
        return base_attack + get_equipped_stat("weapon", "attack");
    };

    /// @function Player.get_defense()
    /// @description Calculate defense from the base stat, equipped armor, and shield.
    /// @returns {Real} The total defense value.
    static get_defense = function() {
        return base_defense
            + get_equipped_stat("armor", "defense")
            + get_equipped_stat("shield", "defense");
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

    /// @function Player.is_fp_full()
    /// @returns {Boolean} Whether current FP has reached its maximum.
    static is_fp_full = function() {
        return fp >= max_fp;
    };

    /// @function Player.restore_fp(_amount)
    /// @param {Real} _amount The requested amount of FP to restore.
    /// @returns {Real} The amount of FP actually restored.
    static restore_fp = function(_amount) {
        var _before = fp;
        fp = min(fp + _amount, max_fp);
        return fp - _before;
    };

    /// @function Player.add_runes(_amount)
    /// @param {Real} _amount The runes to add.
    /// @returns {Real} The new rune total.
    static add_runes = function(_amount) {
        runes += _amount;
        return runes;
    };
    #endregion
}