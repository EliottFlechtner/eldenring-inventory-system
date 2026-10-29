/// @description Initialize the item database, player state, hotbar, and starting inventory.
// Set game speed
game_set_speed(60, gamespeed_fps);

// Initialize shared item definitions.
// Also creates global.inventory_templates.
item_database_init();

// Register per-category item handlers and consumable effects.
item_handlers_init();

// Create the player object (health, base stats, FP, runes, equipment).
// Starts hurt, low on FP, and with only 3 talisman slots, and a 40 equip load (the heaviest gear exceeds it) so healing, FP, and the talisman cap can be tested.
global.player = new Player("Hero", 100, 65, 5, 0, 50, 30, 0, 3, 40);

// Create the player's hotbar
global.player_hotbar = hotbar_create();

// Temporary list for dropped items.
// World pickups will consume this in a later stage.
global.ground_items = [];

// Create the player's inventory with max capacity fixed slots.
global.player_inventory = inventory_create(24);

// Add some starting items for later UI development.
//inventory_fill_from_config(global.player_inventory, { template: "starter" });

// Debug loadout covering every item category (see the "debug" template). Swap to the random config
// below for variety.
inventory_fill_from_config(global.player_inventory, { template: "debug", clear: true });

//var _random_config = { min_qty: 1, unique: true, max_items: global.player_inventory.capacity - 10, clear: true };
//inventory_fill_from_config(global.player_inventory, _random_config);

// Validate item data now that handlers and the player exist. Problems are logged, not fatal.
item_validation_run();

// Uncomment to restore the last save (F5 saves, F9 loads in the inventory).
save_read();

// Set to true to log the inventory self-tests at startup.
if (false) inventory_run_tests();
show_debug_message("Player inventory initialized.");