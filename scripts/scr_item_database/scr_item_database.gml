/// scr_item_database
function item_database_create() {
    return {
        flask_crimson_tears: { id: "flask_crimson_tears", name: "Flask of Crimson Tears", category: "consumable", description: "Restores HP.", stackable: true, max_stack: 14, icon: -1, use_effect: "heal", use_amount: 250 },
        flask_cerulean_tears: { id: "flask_cerulean_tears", name: "Flask of Cerulean Tears", category: "consumable", description: "Restores FP.", stackable: true, max_stack: 14, icon: -1, use_effect: "restore_fp", use_amount: 100 },
        golden_rune_1: { id: "golden_rune_1", name: "Golden Rune [1]", category: "consumable", description: "Grants a small amount of runes.", stackable: true, max_stack: 99, icon: -1, use_effect: "runes", use_amount: 200 },
        golden_rune_5: { id: "golden_rune_5", name: "Golden Rune [5]", category: "consumable", description: "Grants runes.", stackable: true, max_stack: 99, icon: -1, use_effect: "runes", use_amount: 1000 },
        golden_rune_10: { id: "golden_rune_10", name: "Golden Rune [10]", category: "consumable", description: "Grants many runes.", stackable: true, max_stack: 99, icon: -1, use_effect: "runes", use_amount: 3000 },
        lords_rune: { id: "lords_rune", name: "Lord's Rune", category: "consumable", description: "Grants a huge amount of runes.", stackable: true, max_stack: 99, icon: -1, use_effect: "runes", use_amount: 50000 },
        rowa_fruit: { id: "rowa_fruit", name: "Rowa Fruit", category: "consumable", description: "Restores a little HP.", stackable: true, max_stack: 99, icon: -1, use_effect: "heal", use_amount: 40 },
        sacred_tear: { id: "sacred_tear", name: "Sacred Tear", category: "material", description: "Upgrades flask potency.", stackable: true, max_stack: 12, icon: -1 },
        golden_seed: { id: "golden_seed", name: "Golden Seed", category: "material", description: "Increases flask charges.", stackable: true, max_stack: 30, icon: -1 },
        smithing_stone_1: { id: "smithing_stone_1", name: "Smithing Stone [1]", category: "material", description: "Reinforces weapons.", stackable: true, max_stack: 99, icon: -1 },
        smithing_stone_2: { id: "smithing_stone_2", name: "Smithing Stone [2]", category: "material", description: "Reinforces weapons.", stackable: true, max_stack: 99, icon: -1 },
        somber_smithing_stone_1: { id: "somber_smithing_stone_1", name: "Somber Smithing Stone [1]", category: "material", description: "Reinforces unique weapons.", stackable: true, max_stack: 99, icon: -1 },
        ghost_glovewort_1: { id: "ghost_glovewort_1", name: "Grave Glovewort [1]", category: "material", description: "Upgrades spirit ashes.", stackable: true, max_stack: 99, icon: -1 },
        arteria_leaf: { id: "arteria_leaf", name: "Arteria Leaf", category: "material", description: "Used in crafting.", stackable: true, max_stack: 99, icon: -1 },
        bone_dart: { id: "bone_dart", name: "Bone Dart", category: "material", description: "Used in crafting.", stackable: true, max_stack: 99, icon: -1 },
        fire_pot: { id: "fire_pot", name: "Fire Pot", category: "consumable", description: "Throwable fire bomb.", stackable: true, max_stack: 20, icon: -1, use_effect: "throw_fire", use_amount: 100 },
        throwing_dagger: { id: "throwing_dagger", name: "Throwing Dagger", category: "consumable", description: "Thrown projectile.", stackable: true, max_stack: 99, icon: -1, use_effect: "throw", use_amount: 30 },
        arrow: { id: "arrow", name: "Arrow", category: "ammo", description: "Standard arrow.", stackable: true, max_stack: 99, icon: -1, attack: 20 },
        bolt: { id: "bolt", name: "Bolt", category: "ammo", description: "Standard crossbow bolt.", stackable: true, max_stack: 99, icon: -1, attack: 25 },
        uchigatana: { id: "uchigatana", name: "Uchigatana", category: "weapon", description: "Katana causing blood loss.", stackable: false, max_stack: 1, icon: -1, attack: 115 },
        claymore: { id: "claymore", name: "Claymore", category: "weapon", description: "Greatsword with a good moveset.", stackable: false, max_stack: 1, icon: -1, attack: 130 },
        longsword: { id: "longsword", name: "Longsword", category: "weapon", description: "Straight sword.", stackable: false, max_stack: 1, icon: -1, attack: 110 },
        rogiers_rapier: { id: "rogiers_rapier", name: "Rogier's Rapier", category: "weapon", description: "Thrusting sword.", stackable: false, max_stack: 1, icon: -1, attack: 100 },
        moonveil: { id: "moonveil", name: "Moonveil", category: "weapon", description: "Katana of magic.", stackable: false, max_stack: 1, icon: -1, attack: 130 },
        rivers_of_blood: { id: "rivers_of_blood", name: "Rivers of Blood", category: "weapon", description: "Katana of crimson blades.", stackable: false, max_stack: 1, icon: -1, attack: 120 },
        sword_of_night_and_flame: { id: "sword_of_night_and_flame", name: "Sword of Night and Flame", category: "weapon", description: "Legendary dual-spell sword.", stackable: false, max_stack: 1, icon: -1, attack: 125 },
        grafted_blade_greatsword: { id: "grafted_blade_greatsword", name: "Grafted Blade Greatsword", category: "weapon", description: "Colossal sword.", stackable: false, max_stack: 1, icon: -1, attack: 200 },
        giants_red_braid_mace: { id: "giants_red_braid_mace", name: "Giant's Red Braid", category: "weapon", description: "Mace-like weapon.", stackable: false, max_stack: 1, icon: -1, attack: 140 },
        morning_star: { id: "morning_star", name: "Morning Star", category: "weapon", description: "Spiked flail-like club.", stackable: false, max_stack: 1, icon: -1, attack: 105 },
        short_bow: { id: "short_bow", name: "Short Bow", category: "weapon", description: "Quick, light bow.", stackable: false, max_stack: 1, icon: -1, attack: 60 },
        longbow: { id: "longbow", name: "Longbow", category: "weapon", description: "Bow with long range.", stackable: false, max_stack: 1, icon: -1, attack: 70 },
        astrologers_staff: { id: "astrologers_staff", name: "Astrologer's Staff", category: "weapon", description: "Sorcery catalyst.", stackable: false, max_stack: 1, icon: -1, attack: 40 },
        glintstone_staff: { id: "glintstone_staff", name: "Glintstone Staff", category: "weapon", description: "Boosts glintstone sorceries.", stackable: false, max_stack: 1, icon: -1, attack: 45 },
        finger_seal: { id: "finger_seal", name: "Finger Seal", category: "weapon", description: "Incantation catalyst.", stackable: false, max_stack: 1, icon: -1, attack: 30 },
        buckler: { id: "buckler", name: "Buckler", category: "shield", description: "Small shield for parrying.", stackable: false, max_stack: 1, icon: -1, defense: 20 },
        large_leather_shield: { id: "large_leather_shield", name: "Large Leather Shield", category: "shield", description: "Medium shield.", stackable: false, max_stack: 1, icon: -1, defense: 35 },
        carian_knight_shield: { id: "carian_knight_shield", name: "Carian Knight's Shield", category: "shield", description: "Shield with magic resistance.", stackable: false, max_stack: 1, icon: -1, defense: 50 },
        greatshield: { id: "greatshield", name: "Great Turtle Shell", category: "shield", description: "Shield that boosts stamina recovery.", stackable: false, max_stack: 1, icon: -1, defense: 60 },
        knight_helm: { id: "knight_helm", name: "Knight Helm", category: "armor", description: "Sturdy helm.", stackable: false, max_stack: 1, icon: -1, defense: 12 },
        banished_knight_armor: { id: "banished_knight_armor", name: "Banished Knight Armor", category: "armor", description: "Heavy armor.", stackable: false, max_stack: 1, icon: -1, defense: 30 },
        bull_goat_armor: { id: "bull_goat_armor", name: "Bull-Goat Armor", category: "armor", description: "Extremely heavy armor.", stackable: false, max_stack: 1, icon: -1, defense: 45 },
        blaidd_armor: { id: "blaidd_armor", name: "Blaidd's Armor", category: "armor", description: "Armor of the half-wolf.", stackable: false, max_stack: 1, icon: -1, defense: 28 },
        raya_lucaria_robe: { id: "raya_lucaria_robe", name: "Raya Lucaria Robe", category: "armor", description: "Scholar's robe.", stackable: false, max_stack: 1, icon: -1, defense: 8 },
        vagabond_armor: { id: "vagabond_armor", name: "Vagabond Knight Armor", category: "armor", description: "Armor of a wandering knight.", stackable: false, max_stack: 1, icon: -1, defense: 22 },
        crimson_amber_medallion: { id: "crimson_amber_medallion", name: "Crimson Amber Medallion", category: "talisman", description: "Boosts max HP.", stackable: false, max_stack: 1, icon: -1 },
        cerulean_amber_medallion: { id: "cerulean_amber_medallion", name: "Cerulean Amber Medallion", category: "talisman", description: "Boosts max FP.", stackable: false, max_stack: 1, icon: -1 },
        green_turtle_talisman: { id: "green_turtle_talisman", name: "Green Turtle Talisman", category: "talisman", description: "Boosts stamina recovery.", stackable: false, max_stack: 1, icon: -1 },
        erdtree_favor: { id: "erdtree_favor", name: "Erdtree's Favor", category: "talisman", description: "Boosts HP, stamina, and equip load.", stackable: false, max_stack: 1, icon: -1 },
        stonesword_key: { id: "stonesword_key", name: "Stonesword Key", category: "key", description: "Unlocks imp statues.", stackable: true, max_stack: 99, icon: -1 },
        dectus_medallion_left: { id: "dectus_medallion_left", name: "Dectus Medallion (Left)", category: "key", description: "Half of a grand lift medallion.", stackable: false, max_stack: 1, icon: -1 },
        spectral_steed_whistle: { id: "spectral_steed_whistle", name: "Spectral Steed Whistle", category: "key", description: "Summons Torrent.", stackable: false, max_stack: 1, icon: -1 },
        lone_wolf_ashes: { id: "lone_wolf_ashes", name: "Lone Wolf Ashes", category: "spirit_ash", description: "Summons spectral wolves.", stackable: false, max_stack: 1, icon: -1 },
        mimic_tear_ashes: { id: "mimic_tear_ashes", name: "Mimic Tear Ashes", category: "spirit_ash", description: "Summons a copy of yourself.", stackable: false, max_stack: 1, icon: -1 },
    };
}


/// item_database_init()
/// Call once at game start: creates global.item_db and fill templates.
function item_database_init() {
    global.item_db = item_database_create();
    global.inventory_templates = inventory_templates_create();
}


/// inventory_templates_create()
/// Each entry: [item_id, quantity]
function inventory_templates_create() {
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
        crafter: [
            ["arteria_leaf", 10], ["bone_dart", 20], ["fire_pot", 5], ["throwing_dagger", 15]
        ]
    };
}


/// item_definition_get(_item_id)
function item_definition_get(_item_id) {
    if (!is_string(_item_id)) {
        return undefined;
    }

    if (!variable_struct_exists(global.item_db, _item_id)) {
        return undefined;
    }

    return variable_struct_get(global.item_db, _item_id);
}
