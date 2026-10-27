/// scr_item_database
function item_database_create() {
    return {
        potion: {
		    id: "potion",
		    name: "Crimson Flask",
		    category: "consumable",
		    description: "Restores a small amount of health.",
		    stackable: true,
		    max_stack: 10,
		    icon: -1,

		    use_effect: "heal",
		    use_amount: 30
		},

        herb: {
            id: "herb",
            name: "Green Herb",
            category: "material",
            description: "A common medicinal plant.",
            stackable: true,
            max_stack: 99,
            icon: -1
        },

        iron_sword: {
            id: "iron_sword",
            name: "Iron Sword",
            category: "weapon",
            description: "A reliable sword forged from iron.",
            stackable: false,
            max_stack: 1,
            icon: -1,
            attack: 12
        },

        leather_armor: {
            id: "leather_armor",
            name: "Leather Armor",
            category: "armor",
            description: "Light armor made from treated leather.",
            stackable: false,
            max_stack: 1,
            icon: -1,
            defense: 5
        },
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