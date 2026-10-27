/// obj_game_controller : Create Event

// Initialize shared item definitions.
global.item_db = item_database_create();

// Create the player's hotbar
global.player_hotbar = hotbar_create();

// Example player stats for consumable testing.
global.player_max_health = 100;
global.player_health = 65;
global.player_base_attack = 5;
global.player_base_defense = 0;

// Equipped item IDs. Empty string means no equipment.
global.player_equipment = {
    weapon: "",
    armor: ""
};

// Temporary list for dropped items.
// World pickups will consume this in a later stage.
global.ground_items = [];

// Create the player's inventory with 24 fixed slots.
global.player_inventory = inventory_create(24);

//// Run the automated tests.
inventory_run_tests();

// Add some starting items for later UI development.
inventory_add(global.player_inventory, "potion", 5);
inventory_add(global.player_inventory, "herb", 20);
inventory_add(global.player_inventory, "iron_sword", 1);
inventory_add(global.player_inventory, "leather_armor", 1);

show_debug_message("Player inventory initialized.");
show_debug_message(
    "Starting potions: "
    + string(inventory_count_item(global.player_inventory, "potion"))
);