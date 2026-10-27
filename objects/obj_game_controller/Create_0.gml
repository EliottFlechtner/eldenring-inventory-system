///@description Initialize game state and player inventory

// Initialize shared item definitions.
// Also creates global.inventory_templates.
item_database_init();

// Create the player object (health, base stats, equipment).
global.player = new Player("Hero", 100, 65, 5, 0);

// Create the player's hotbar
global.player_hotbar = hotbar_create();

// Temporary list for dropped items.
// World pickups will consume this in a later stage.
global.ground_items = [];

// Create the player's inventory with 24 fixed slots.
global.player_inventory = inventory_create(24);

// Run the automated tests.
inventory_run_tests();

// Add some starting items for later UI development.
//inventory_fill_from_config(global.player_inventory, { template: "starter" });

var _random_config = {
    categories: ["weapon", "armor", "consumable"], // omit for all categories
    exclude: ["lords_rune"],                       // item ids never added
    min_qty: 1,                                    // stackable quantity range
    max_qty: 5,
    unique: true,                                  // each item id at most once
    max_items: 10,                                 // omit to fill until full
    clear: true,                                   // empty the inventory first
};
inventory_fill_from_config(global.player_inventory, _random_config);

show_debug_message("Player inventory initialized.");
show_debug_message(
    "Starting flasks: "
    + string(inventory_count_item(global.player_inventory, "flask_crimson_tears"))
);