/// scr_item_database
/// @function item_database_create()
/// @description Build the game's item definitions as a list. item_database_init() turns it into the
/// id-keyed database and reports duplicate ids. Optional fields: attack, defense, weight, use_effect, use_amount.
/// @returns {Array<Struct.ItemDefinition>} Every item definition.
function item_database_create() {
    #region Item definitions
    return [
        // Consumables (heals/runes)
        { id: "flask_crimson_tears", name: "Flask of Crimson Tears", category: "consumable", description: "Restores HP.", stackable: true, max_stack: 14, icon: -1, use_effect: "heal", use_amount: 250 },
        { id: "flask_cerulean_tears", name: "Flask of Cerulean Tears", category: "consumable", description: "Restores FP.", stackable: true, max_stack: 14, icon: -1, use_effect: "restore_fp", use_amount: 100 },
        { id: "golden_rune_1", name: "Golden Rune [1]", category: "consumable", description: "Grants a small amount of runes.", stackable: true, max_stack: 99, icon: -1, use_effect: "runes", use_amount: 200 },
        { id: "golden_rune_5", name: "Golden Rune [5]", category: "consumable", description: "Grants runes.", stackable: true, max_stack: 99, icon: -1, use_effect: "runes", use_amount: 1000 },
        { id: "golden_rune_10", name: "Golden Rune [10]", category: "consumable", description: "Grants many runes.", stackable: true, max_stack: 99, icon: -1, use_effect: "runes", use_amount: 3000 },
        { id: "lords_rune", name: "Lord's Rune", category: "consumable", description: "Grants a huge amount of runes.", stackable: true, max_stack: 99, icon: -1, use_effect: "runes", use_amount: 50000 },
        { id: "rowa_fruit", name: "Rowa Fruit", category: "consumable", description: "Restores a little HP.", stackable: true, max_stack: 99, icon: -1, use_effect: "heal", use_amount: 40 },
        
        // Consumables (weapons)
        { id: "fire_pot", name: "Fire Pot", category: "consumable", description: "Throwable fire bomb.", stackable: true, max_stack: 20, icon: -1, use_effect: "throw_fire", use_amount: 100 },
        { id: "throwing_dagger", name: "Throwing Dagger", category: "consumable", description: "Thrown projectile.", stackable: true, max_stack: 99, icon: -1, use_effect: "throw", use_amount: 30 },
        
        // Materials
        { id: "sacred_tear", name: "Sacred Tear", category: "material", description: "Upgrades flask potency.", stackable: true, max_stack: 12, icon: -1 },
        { id: "golden_seed", name: "Golden Seed", category: "material", description: "Increases flask charges.", stackable: true, max_stack: 30, icon: -1 },
        { id: "smithing_stone_1", name: "Smithing Stone [1]", category: "material", description: "Reinforces weapons.", stackable: true, max_stack: 99, icon: -1 },
        { id: "smithing_stone_2", name: "Smithing Stone [2]", category: "material", description: "Reinforces weapons.", stackable: true, max_stack: 99, icon: -1 },
        { id: "somber_smithing_stone_1", name: "Somber Smithing Stone [1]", category: "material", description: "Reinforces unique weapons.", stackable: true, max_stack: 99, icon: -1 },
        { id: "ghost_glovewort_1", name: "Grave Glovewort [1]", category: "material", description: "Upgrades spirit ashes.", stackable: true, max_stack: 99, icon: -1 },
        { id: "arteria_leaf", name: "Arteria Leaf", category: "material", description: "Used in crafting.", stackable: true, max_stack: 99, icon: -1 },
        { id: "bone_dart", name: "Bone Dart", category: "material", description: "Used in crafting.", stackable: true, max_stack: 99, icon: -1 },
        
        // Ammunitions
        { id: "arrow", name: "Arrow", category: "ammo", description: "Standard arrow.", stackable: true, max_stack: 99, icon: -1, attack: 20 },
        { id: "bolt", name: "Bolt", category: "ammo", description: "Standard crossbow bolt.", stackable: true, max_stack: 99, icon: -1, attack: 25 },
        
        // Weapons
        { id: "uchigatana", name: "Uchigatana", category: "weapon", description: "Katana causing blood loss.", stackable: false, max_stack: 1, icon: -1, attack: 115, weight: 5.5 },
        { id: "claymore", name: "Claymore", category: "weapon", description: "Greatsword with a good moveset.", stackable: false, max_stack: 1, icon: -1, attack: 130, weight: 9 },
        { id: "longsword", name: "Longsword", category: "weapon", description: "Straight sword.", stackable: false, max_stack: 1, icon: -1, attack: 110, weight: 7 },
        { id: "rogiers_rapier", name: "Rogier's Rapier", category: "weapon", description: "Thrusting sword.", stackable: false, max_stack: 1, icon: -1, attack: 100, weight: 2.5 },
        { id: "moonveil", name: "Moonveil", category: "weapon", description: "Katana of magic.", stackable: false, max_stack: 1, icon: -1, attack: 130, weight: 5.5 },
        { id: "rivers_of_blood", name: "Rivers of Blood", category: "weapon", description: "Katana of crimson blades.", stackable: false, max_stack: 1, icon: -1, attack: 120, weight: 5.5 },
        { id: "sword_of_night_and_flame", name: "Sword of Night and Flame", category: "weapon", description: "Legendary dual-spell sword.", stackable: false, max_stack: 1, icon: -1, attack: 125, weight: 5 },
        { id: "grafted_blade_greatsword", name: "Grafted Blade Greatsword", category: "weapon", description: "Colossal sword.", stackable: false, max_stack: 1, icon: -1, attack: 200, weight: 20 },
        { id: "giants_red_braid_mace", name: "Giant's Red Braid", category: "weapon", description: "Mace-like weapon.", stackable: false, max_stack: 1, icon: -1, attack: 140, weight: 14 },
        { id: "morning_star", name: "Morning Star", category: "weapon", description: "Spiked flail-like club.", stackable: false, max_stack: 1, icon: -1, attack: 105, weight: 6.5 },
        { id: "short_bow", name: "Short Bow", category: "weapon", description: "Quick, light bow.", stackable: false, max_stack: 1, icon: -1, attack: 60, weight: 1.5 },
        { id: "longbow", name: "Longbow", category: "weapon", description: "Bow with long range.", stackable: false, max_stack: 1, icon: -1, attack: 70, weight: 3 },
        { id: "astrologers_staff", name: "Astrologer's Staff", category: "weapon", description: "Sorcery catalyst.", stackable: false, max_stack: 1, icon: -1, attack: 40, weight: 2.5 },
        { id: "glintstone_staff", name: "Glintstone Staff", category: "weapon", description: "Boosts glintstone sorceries.", stackable: false, max_stack: 1, icon: -1, attack: 45, weight: 2.5 },
        { id: "finger_seal", name: "Finger Seal", category: "weapon", description: "Incantation catalyst.", stackable: false, max_stack: 1, icon: -1, attack: 30, weight: 0.5 },
        
        // Shields
        { id: "buckler", name: "Buckler", category: "shield", description: "Small shield for parrying.", stackable: false, max_stack: 1, icon: -1, defense: 20, weight: 2 },
        { id: "large_leather_shield", name: "Large Leather Shield", category: "shield", description: "Medium shield.", stackable: false, max_stack: 1, icon: -1, defense: 35, weight: 5 },
        { id: "carian_knight_shield", name: "Carian Knight's Shield", category: "shield", description: "Shield with magic resistance.", stackable: false, max_stack: 1, icon: -1, defense: 50, weight: 6 },
        { id: "greatshield", name: "Great Turtle Shell", category: "shield", description: "Shield that boosts stamina recovery.", stackable: false, max_stack: 1, icon: -1, defense: 60, weight: 13.5 },
       
        // Armors
        { id: "knight_helm", name: "Knight Helm", category: "armor", description: "Sturdy helm.", stackable: false, max_stack: 1, icon: -1, defense: 12, weight: 4.5 },
        { id: "banished_knight_armor", name: "Banished Knight Armor", category: "armor", description: "Heavy armor.", stackable: false, max_stack: 1, icon: -1, defense: 30, weight: 14.5 },
        { id: "bull_goat_armor", name: "Bull-Goat Armor", category: "armor", description: "Extremely heavy armor.", stackable: false, max_stack: 1, icon: -1, defense: 45, weight: 21 },
        { id: "blaidd_armor", name: "Blaidd's Armor", category: "armor", description: "Armor of the half-wolf.", stackable: false, max_stack: 1, icon: -1, defense: 28, weight: 12 },
        { id: "raya_lucaria_robe", name: "Raya Lucaria Robe", category: "armor", description: "Scholar's robe.", stackable: false, max_stack: 1, icon: -1, defense: 8, weight: 3 },
        { id: "vagabond_armor", name: "Vagabond Knight Armor", category: "armor", description: "Armor of a wandering knight.", stackable: false, max_stack: 1, icon: -1, defense: 22, weight: 15 },
        
        // Talismans
        { id: "crimson_amber_medallion", name: "Crimson Amber Medallion", category: "talisman", description: "Boosts max HP.", stackable: false, max_stack: 1, icon: -1 },
        { id: "cerulean_amber_medallion", name: "Cerulean Amber Medallion", category: "talisman", description: "Boosts max FP.", stackable: false, max_stack: 1, icon: -1 },
        { id: "green_turtle_talisman", name: "Green Turtle Talisman", category: "talisman", description: "Boosts stamina recovery.", stackable: false, max_stack: 1, icon: -1 },
        { id: "erdtree_favor", name: "Erdtree's Favor", category: "talisman", description: "Boosts HP, stamina, and equip load.", stackable: false, max_stack: 1, icon: -1 },
        
        // Keys
        { id: "stonesword_key", name: "Stonesword Key", category: "key", description: "Unlocks imp statues.", stackable: true, max_stack: 99, icon: -1 },
        { id: "dectus_medallion_left", name: "Dectus Medallion (Left)", category: "key", description: "Half of a grand lift medallion.", stackable: false, max_stack: 1, icon: -1 },
        { id: "spectral_steed_whistle", name: "Spectral Steed Whistle", category: "key", description: "Summons Torrent.", stackable: false, max_stack: 1, icon: -1 },
        
        // Spirit Ashes
        { id: "lone_wolf_ashes", name: "Lone Wolf Ashes", category: "spirit_ash", description: "Summons spectral wolves.", stackable: false, max_stack: 1, icon: -1 },
        { id: "mimic_tear_ashes", name: "Mimic Tear Ashes", category: "spirit_ash", description: "Summons a copy of yourself.", stackable: false, max_stack: 1, icon: -1 },
    ];
    #endregion
}


/// @function item_weight_default(_category)
/// @description Default weight for items that do not define one, by category.
/// @param {String} _category The item category.
/// @returns {Real} The default weight.
function item_weight_default(_category) {
    switch (_category) {
        case "weapon": return 4;
        case "shield": return 4;
        case "armor": return 8;
        case "talisman": return 0.3;
    }

    return 0;
}


/// @function item_database_build(_definitions)
/// @description Turn a list of definitions into an id-keyed struct, filling in default weights.
/// Duplicate ids keep the first definition and are recorded for validation.
/// @param {Array<Struct.ItemDefinition>} _definitions The definitions to index.
/// @returns {Struct} A struct with `db` (id to definition) and `duplicates` (repeated ids).
function item_database_build(_definitions) {
    var _db = {};
    var _duplicates = [];

    for (var i = 0; i < array_length(_definitions); i++) {
        var _def = _definitions[i];
        var _id = is_struct(_def) ? _def[$ "id"] : undefined;

        // Malformed entries stay out of the database; validation reports them via the raw list.
        if (!is_string(_id)) continue;

        if (variable_struct_exists(_db, _id)) {
            array_push(_duplicates, _id);
            continue;
        }

        if (!variable_struct_exists(_def, "weight") && is_string(_def[$ "category"])) {
            _def.weight = item_weight_default(_def.category);
        }

        _db[$ _id] = _def;
    }

    return { db: _db, duplicates: _duplicates };
}


/// @function item_database_init()
/// @description Initialize the global item database and inventory templates.
/// @returns {undefined} No value is returned; global.item_db, global.item_db_raw, global.item_db_duplicates
/// and global.inventory_templates are assigned.
function item_database_init() {
    global.item_db_raw = item_database_create();

    var _built = item_database_build(global.item_db_raw);
    global.item_db = _built.db;
    global.item_db_duplicates = _built.duplicates;

    global.inventory_templates = inventory_templates_create();
}


/// @function inventory_templates_create()
/// @description Create the named starting-inventory templates.
/// @returns {Struct.InventoryTemplates} A struct whose template values contain [item_id, quantity] entries.
function inventory_templates_create() {
    #region Inventory templates
    return {
        starter: [
            ["flask_crimson_tears", 5], ["rowa_fruit", 20], ["longsword", 1], ["knight_helm", 1]
        ],
        wretch: [
            ["flask_crimson_tears", 4], ["golden_rune_1", 2], ["club_placeholder_skip", 1]
        ],
        samurai: [
            ["uchigatana", 1], ["short_bow", 1], ["arrow", 40], ["flask_crimson_tears", 4], ["golden_rune_1", 2]
        ],
        astrologer: [
            ["astrologers_staff", 1], ["raya_lucaria_robe", 1], ["flask_cerulean_tears", 3], ["flask_crimson_tears", 3]
        ],
        knight: [
            ["longsword", 1], ["large_leather_shield", 1], ["knight_helm", 1], ["flask_crimson_tears", 5], ["smithing_stone_1", 4]
        ],
        // Covers every category and handler path for manual testing (22 slots).
        debug: [
            ["flask_crimson_tears", 10], ["flask_cerulean_tears", 8], ["golden_rune_1", 20], ["golden_rune_5", 5],
            ["rowa_fruit", 20], ["fire_pot", 5], ["smithing_stone_1", 12], ["arrow", 40],
            ["uchigatana", 1], ["claymore", 1], ["moonveil", 1], ["buckler", 1], ["greatshield", 1],
            ["knight_helm", 1], ["bull_goat_armor", 1],
            ["crimson_amber_medallion", 1], ["cerulean_amber_medallion", 1], ["green_turtle_talisman", 1], ["erdtree_favor", 1],
            ["stonesword_key", 1], ["mimic_tear_ashes", 1], ["lone_wolf_ashes", 1]
        ],
        crafter: [
            ["arteria_leaf", 10], ["bone_dart", 20], ["fire_pot", 5], ["throwing_dagger", 15]
        ]
    };
    #endregion
}


/// @function item_definition_get(_item_id)
/// @description Look up an item definition by its id in the initialized global database.
/// @param {String} _item_id The item id to look up.
/// @returns {Struct.ItemDefinition|undefined} The definition if found, or undefined for invalid or unknown ids.
function item_definition_get(_item_id) {
    if (!is_string(_item_id)) {
        return undefined;
    }

    if (!variable_struct_exists(global.item_db, _item_id)) {
        return undefined;
    }

    return variable_struct_get(global.item_db, _item_id);
}


/// @function item_database_get_ids(_categories, _exclude)
/// @description Get item ids, optionally filtered by category and excluded ids.
/// @param {String|Array<String>|undefined} _categories One category, a list of categories, or undefined for all categories.
/// @param {Array<String>|undefined} _exclude Item ids to omit, or undefined to omit none.
/// @returns {Array<String>} Matching item ids from the global item database.
function item_database_get_ids(_categories = undefined, _exclude = undefined) {
    if (is_string(_categories)) _categories = [_categories];

    var _keys = variable_struct_get_names(global.item_db);
    var _ids = [];

    for (var i = 0; i < array_length(_keys); i++) {
        var _def = variable_struct_get(global.item_db, _keys[i]);

        if (is_array(_categories) && !array_contains(_categories, _def.category)) continue;
        if (is_array(_exclude) && array_contains(_exclude, _keys[i])) continue;

        array_push(_ids, _keys[i]);
    }

    return _ids;
}