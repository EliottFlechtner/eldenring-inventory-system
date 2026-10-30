/// scr_inventory_tests
/// Debug self-tests. Call inventory_run_tests() (see obj_game_controller Create) and read the debug log.
/// Tests swap in a throwaway player, inventory, and hotbar, and restore the real ones afterwards.

/// @function inventory_test_assert(_condition, _message)
/// @description Log a test result, count failures, and return whether its condition passed.
/// @param {Boolean} _condition The test condition to evaluate.
/// @param {String} _message The test name or outcome description.
/// @returns {Boolean} The value of the test condition.
function inventory_test_assert(_condition, _message) {
    if (_condition) {
        show_debug_message("[PASS] " + _message);
    } else {
        show_debug_message("[FAIL] " + _message);
        global.inventory_test_failures++;
    }

    return _condition;
}


/// @function inventory_test_reset()
/// @description Install a fresh player (3 talisman slots), empty 12-slot inventory, and hotbar.
function inventory_test_reset() {
    global.player = new Player("Tester", 100, 50, 5, 0, 50, 10, 0, 3, 40);
    global.player_inventory = inventory_create(12);
    global.player_hotbar = hotbar_create();
}


/// @function inventory_run_tests()
/// @description Run the inventory, action, handler, and player-stat checks.
/// @returns {Boolean} True if every check passed; each result is written to the debug log.
function inventory_run_tests() {
    show_debug_message("=== INVENTORY TESTS BEGIN ===");
    global.inventory_test_failures = 0;

    // Keep the real game state so the tests are side-effect free.
    var _saved_player = global[$ "player"];
    var _saved_inventory = global[$ "player_inventory"];
    var _saved_hotbar = global[$ "player_hotbar"];

    inventory_test_core();
    inventory_test_player();
    inventory_test_actions();
    inventory_test_equipment();
    inventory_test_quantities();
    inventory_test_drop_discard();
    inventory_test_registry();
    inventory_test_equip_load();
    inventory_test_save_load();
    inventory_test_validation();
    inventory_test_events();
    inventory_test_transactions();
    inventory_test_quick_slots();
    inventory_test_skills();
    inventory_test_spirit_ash();
    inventory_test_ui_state();

    global.player = _saved_player;
    global.player_inventory = _saved_inventory;
    global.player_hotbar = _saved_hotbar;

    var _ok = global.inventory_test_failures == 0;
    show_debug_message("=== INVENTORY TESTS END: " + (_ok ? "ALL PASSED" : string(global.inventory_test_failures) + " FAILED") + " ===");

    return _ok;
}


#region Inventory core
function inventory_test_core() {
    var _inv = inventory_create(3);

    inventory_test_assert(inventory_add(_inv, "flask_crimson_tears", 5) == 5, "Add five flasks");
    inventory_test_assert(inventory_add(_inv, "flask_crimson_tears", 3) == 3, "Merge additional flasks");
    inventory_test_assert(inventory_count_item(_inv, "flask_crimson_tears") == 8, "Flask stack contains eight");
    inventory_test_assert(inventory_add(_inv, "unknown_item", 1) == 0, "Reject an unknown item");
    inventory_test_assert(inventory_add(_inv, "flask_crimson_tears", 0) == 0, "Reject a zero quantity");

    // Overflow past max_stack (14) spills into a second slot.
    inventory_test_assert(inventory_add(_inv, "flask_crimson_tears", 10) == 10, "Overflow into a second stack");
    inventory_test_assert(inventory_count_item(_inv, "flask_crimson_tears") == 18, "Count sums across stacks");
    inventory_test_assert(inventory_remove(_inv, "flask_crimson_tears", 16), "Remove across two stacks");
    inventory_test_assert(inventory_count_item(_inv, "flask_crimson_tears") == 2, "Two flasks remain after cross-stack removal");

    inventory_test_assert(!inventory_remove(_inv, "flask_crimson_tears", 100), "Reject removal of unavailable quantity");
    inventory_test_assert(inventory_count_item(_inv, "flask_crimson_tears") == 2, "Failed removal leaves inventory unchanged");
    inventory_test_assert(!inventory_remove(_inv, "flask_crimson_tears", 0), "Reject removing zero");
    inventory_test_assert(!inventory_remove(_inv, "flask_crimson_tears", 1.5), "Reject fractional removal");

    inventory_add(_inv, "uchigatana", 1);
    inventory_add(_inv, "claymore", 1);
    inventory_test_assert(inventory_find_empty_slot(_inv) == -1, "Detect a full inventory");
    inventory_test_assert(inventory_add(_inv, "moonveil", 1) == 0, "Reject an item when all slots are occupied");

    inventory_clear(_inv);
    inventory_test_assert(inventory_count_item(_inv, "uchigatana") == 0 && inventory_find_empty_slot(_inv) == 0, "Clear empties the inventory");

    var _big = inventory_create(24);
    inventory_fill_from_config(_big, { template: "debug", clear: true });
    inventory_test_assert(inventory_count_item(_big, "mimic_tear_ashes") == 1, "Debug template fills a 24-slot inventory");
    inventory_test_assert(inventory_find_empty_slot(_big) != -1, "Debug template leaves room to pick items up");
}
#endregion


#region Player state
function inventory_test_player() {
    inventory_test_reset();
    var _p = global.player;

    inventory_test_assert(_p.heal(30) == 30 && _p.health_ == 80, "Heal restores the requested amount");
    inventory_test_assert(_p.heal(100) == 20 && _p.is_health_full(), "Heal is capped at max health");
    inventory_test_assert(_p.restore_fp(100) == 40 && _p.is_fp_full(), "FP restore is capped at max FP");
    inventory_test_assert(_p.add_runes(250) == 250 && _p.runes == 250, "Runes accumulate");

    inventory_test_assert(_p.equip_talisman("a"), "Equip talisman a");
    inventory_test_assert(!_p.equip_talisman("a"), "Reject equipping the same talisman twice");
    inventory_test_assert(_p.equip_talisman("b") && _p.equip_talisman("c"), "Fill the remaining talisman slots");
    inventory_test_assert(!_p.can_equip_talisman() && !_p.equip_talisman("d"), "Talisman cap is enforced");
    inventory_test_assert(_p.is_equipped("b"), "is_equipped sees talismans");
    inventory_test_assert(_p.unequip_talisman("b") && _p.can_equip_talisman(), "Unequipping frees a talisman slot");
    inventory_test_assert(!_p.unequip_talisman("b"), "Unequipping an unworn talisman fails");

    _p.unequip_item("a");
    inventory_test_assert(!_p.is_talisman_equipped("a"), "unequip_item clears talismans");

    inventory_test_assert(!_p.is_equipment_slot("talisman"), "Talismans are not a single equipment slot");
    inventory_test_assert(_p.is_equipment_slot("weapon") && _p.is_equipment_slot("shield") && _p.is_equipment_slot("armor"), "Weapon, shield and armor are slots");
    inventory_test_assert(_p.get_attack() == 5 && _p.get_defense() == 0, "Base stats with nothing equipped");
}
#endregion


#region Action availability and use
function inventory_test_actions() {
    inventory_test_reset();
    var _inv = global.player_inventory;

    inventory_add(_inv, "flask_crimson_tears", 5);
    inventory_add(_inv, "flask_cerulean_tears", 5);
    inventory_add(_inv, "golden_rune_1", 5);
    inventory_add(_inv, "fire_pot", 2);
    inventory_add(_inv, "arrow", 10);
    inventory_add(_inv, "stonesword_key", 1);

    var _acts = inventory_get_actions("flask_crimson_tears");
    inventory_test_assert(array_contains(_acts, "Use") && array_contains(_acts, "Drop") && array_contains(_acts, "Discard"), "Consumable offers Use, Drop, Discard");
    inventory_test_assert(inventory_get_action_unsupported_reason("flask_crimson_tears", "Use") == "", "Heal flask Use is supported");
    inventory_test_assert(inventory_get_action_unsupported_reason("fire_pot", "Use") != "", "Fire pot Use is unsupported");
    inventory_test_assert(inventory_get_action_unsupported_reason("fire_pot", "Drop") == "", "Drop is never unsupported");
    inventory_test_assert(inventory_get_action_unsupported_reason("arrow", "Discard") == "", "Discard is never unsupported");
    inventory_test_assert(inventory_get_action_unsupported_reason("arrow", "Use") != "", "Placeholder Use is unsupported");
    inventory_test_assert(inventory_get_action_unsupported_reason("stonesword_key", "Use") != "", "Key Use is unsupported");
    inventory_test_assert(array_length(inventory_get_actions("nope")) == 0, "Unknown item has no actions");

    // Unsupported actions neither run nor consume.
    var _r = inventory_execute_action("fire_pot", "Use");
    inventory_test_assert(!_r.ok && inventory_count_item(_inv, "fire_pot") == 2, "Unsupported Use reports a reason and consumes nothing");
    _r = inventory_execute_action("arrow", "Use");
    inventory_test_assert(!_r.ok && inventory_count_item(_inv, "arrow") == 10, "Placeholder Use consumes nothing");
    _r = inventory_execute_action("flask_crimson_tears", "Equip");
    inventory_test_assert(!_r.ok, "Actions a category does not offer are rejected");
    _r = inventory_execute_action("not_a_real_item", "Use");
    inventory_test_assert(!_r.ok, "Unknown item action is rejected");
    _r = inventory_execute_action("moonveil", "Equip");
    inventory_test_assert(!_r.ok, "Cannot act on an item that is not in the inventory");

    // Use effects.
    _r = inventory_execute_action("flask_crimson_tears", "Use");
    inventory_test_assert(_r.ok && inventory_count_item(_inv, "flask_crimson_tears") == 4 && global.player.health_ == 100, "Heal flask heals (capped) and consumes one");
    _r = inventory_execute_action("flask_crimson_tears", "Use");
    inventory_test_assert(!_r.ok && inventory_count_item(_inv, "flask_crimson_tears") == 4, "Heal at full health fails without consuming");

    _r = inventory_execute_action("flask_cerulean_tears", "Use");
    inventory_test_assert(_r.ok && global.player.fp == 50, "FP flask restores FP");
    _r = inventory_execute_action("flask_cerulean_tears", "Use");
    inventory_test_assert(!_r.ok && inventory_count_item(_inv, "flask_cerulean_tears") == 4, "FP at full fails without consuming");

    _r = inventory_execute_action("golden_rune_1", "Use");
    inventory_test_assert(_r.ok && global.player.runes == 200 && inventory_count_item(_inv, "golden_rune_1") == 4, "Golden rune grants runes");

    // Hotbar goes through the same path.
    inventory_test_assert(hotbar_assign(global.player_hotbar, 0, "golden_rune_1"), "Assign a consumable to the hotbar");
    inventory_test_assert(!hotbar_assign(global.player_hotbar, 1, "uchigatana"), "Reject a non-consumable on the hotbar");
    _r = hotbar_use(global.player_hotbar, 0);
    inventory_test_assert(_r.ok && global.player.runes == 400, "Hotbar use applies the effect");
}
#endregion


#region Equipment
function inventory_test_equipment() {
    inventory_test_reset();
    var _inv = global.player_inventory;
    var _p = global.player;

    var _ids = ["uchigatana", "claymore", "buckler", "knight_helm",
                "crimson_amber_medallion", "cerulean_amber_medallion", "green_turtle_talisman", "erdtree_favor"];
    for (var i = 0; i < array_length(_ids); i++) inventory_add(_inv, _ids[i], 1);

    var _weapon_attack = item_definition_get("uchigatana").attack;
    var _other_attack = item_definition_get("claymore").attack;
    var _shield_def = item_definition_get("buckler").defense;
    var _armor_def = item_definition_get("knight_helm").defense;

    inventory_test_assert(array_contains(inventory_get_actions("uchigatana"), "Equip"), "Unequipped weapon offers Equip");

    var _cmp = equipment_get_comparison("uchigatana");
    inventory_test_assert(_cmp.valid && _cmp.new_value == 5 + _weapon_attack, "Comparison shows base plus weapon attack");

    inventory_test_assert(inventory_execute_action("uchigatana", "Equip").ok && _p.get_attack() == 5 + _weapon_attack, "Equip weapon raises attack");
    inventory_test_assert(array_contains(inventory_get_actions("uchigatana"), "Unequip") && !array_contains(inventory_get_actions("uchigatana"), "Equip"), "Equipped weapon offers Unequip only");

    // Comparison replaces the equipped weapon rather than stacking onto it.
    _cmp = equipment_get_comparison("claymore");
    inventory_test_assert(_cmp.new_value == 5 + _other_attack, "Comparison swaps out the equipped weapon");

    inventory_test_assert(inventory_execute_action("buckler", "Equip").ok && inventory_execute_action("knight_helm", "Equip").ok, "Equip shield and armor");
    inventory_test_assert(_p.get_defense() == _shield_def + _armor_def, "Defense sums armor and shield");
    _cmp = equipment_get_comparison("buckler");
    inventory_test_assert(_cmp.valid && _cmp.new_value == _p.get_defense(), "Shield comparison against itself is unchanged");
    inventory_test_assert(!equipment_get_comparison("crimson_amber_medallion").valid, "Talismans have no stat comparison");

    inventory_test_assert(inventory_execute_action("uchigatana", "Unequip").ok && _p.get_attack() == 5, "Unequip weapon restores base attack");
    inventory_test_assert(!inventory_execute_action("uchigatana", "Unequip").ok, "Unequip twice fails");

    // Talismans respect the cap (3 in this test).
    inventory_test_assert(inventory_execute_action("crimson_amber_medallion", "Equip").ok, "Equip talisman 1");
    inventory_test_assert(inventory_execute_action("cerulean_amber_medallion", "Equip").ok, "Equip talisman 2");
    inventory_test_assert(inventory_execute_action("green_turtle_talisman", "Equip").ok, "Equip talisman 3");
    var _r = inventory_execute_action("erdtree_favor", "Equip");
    inventory_test_assert(!_r.ok && array_length(_p.talismans) == 3, "Fourth talisman is rejected at the cap: " + _r.message);
    var _opts = inventory_get_action_replace_options("erdtree_favor", "Equip");
    inventory_test_assert(array_length(_opts) == 3 && array_contains(_opts, "cerulean_amber_medallion"), "Full talisman slots offer the worn talismans as replace options");
    inventory_test_assert(array_length(inventory_get_action_replace_options("erdtree_favor", "Unequip")) == 0, "Unequip never needs a replacement");
    inventory_test_assert(array_length(inventory_get_action_replace_options("uchigatana", "Equip")) == 0, "Single-slot equipment needs no replacement choice");

    // Replacing requires a valid choice from the offered options.
    _r = inventory_execute_action("erdtree_favor", "Equip", 1, "uchigatana");
    inventory_test_assert(!_r.ok && !_p.is_talisman_equipped("erdtree_favor"), "Replacing with a non-worn item is rejected");
    _r = inventory_execute_action("erdtree_favor", "Equip", 1, "green_turtle_talisman");
    inventory_test_assert(_r.ok && _p.is_talisman_equipped("erdtree_favor") && !_p.is_talisman_equipped("green_turtle_talisman") && array_length(_p.talismans) == 3, "Replacing swaps the chosen talisman");
    inventory_test_assert(array_length(inventory_get_action_replace_options("erdtree_favor", "Equip")) == 0 || !array_contains(inventory_get_actions("erdtree_favor"), "Equip"), "An equipped talisman offers Unequip instead of Equip");

    inventory_test_assert(inventory_execute_action("crimson_amber_medallion", "Unequip").ok, "Unequip a talisman");
    inventory_test_assert(inventory_execute_action("green_turtle_talisman", "Equip").ok, "Equip succeeds without a choice once a slot is free");
}
#endregion


#region Quantities
function inventory_test_quantities() {
    inventory_test_reset();
    var _inv = global.player_inventory;
    var _p = global.player;

    inventory_add(_inv, "flask_crimson_tears", 14);
    inventory_add(_inv, "golden_rune_5", 10);
    inventory_add(_inv, "fire_pot", 5);
    inventory_add(_inv, "uchigatana", 1);

    inventory_test_assert(inventory_get_action_max_quantity("golden_rune_5", "Use") == 10, "Rune max quantity equals the stack");
    inventory_test_assert(inventory_get_action_max_quantity("fire_pot", "Use") == 1, "Unsupported action has quantity 1");
    inventory_test_assert(inventory_get_action_max_quantity("uchigatana", "Equip") == 1, "Equip has quantity 1");
    inventory_test_assert(inventory_get_action_max_quantity("flask_crimson_tears", "Drop") == 14, "Drop max quantity is the full stack");
    inventory_test_assert(inventory_get_action_max_quantity("uchigatana", "Discard") == 1, "Discard of a single item has quantity 1");

    var _r = inventory_execute_action("golden_rune_5", "Use", 4);
    inventory_test_assert(_r.ok && _p.runes == 4000 && inventory_count_item(_inv, "golden_rune_5") == 6, "Using four rune items grants and consumes four");

    _r = inventory_execute_action("golden_rune_5", "Use", 999);
    inventory_test_assert(_r.ok && inventory_count_item(_inv, "golden_rune_5") == 0 && _p.runes == 10000, "Quantity above the stack is clamped");

    _r = inventory_execute_action("golden_rune_5", "Use", 1);
    inventory_test_assert(!_r.ok, "Using an exhausted item fails");

    _r = inventory_execute_action("flask_crimson_tears", "Use", -5);
    inventory_test_assert(_r.ok && inventory_count_item(_inv, "flask_crimson_tears") == 13, "Quantities below one are clamped to one");

    // A flask heals 250, so one is enough to fill a hurt player: extra uses must not be consumed.
    _p.health_ = 10;
    _r = inventory_execute_action("flask_crimson_tears", "Use", 5);
    inventory_test_assert(_r.ok && _p.is_health_full() && inventory_count_item(_inv, "flask_crimson_tears") == 12, "Quantity is capped to what is useful");
}
#endregion


#region Drop and discard
function inventory_test_drop_discard() {
    inventory_test_reset();
    var _inv = global.player_inventory;
    var _p = global.player;

    inventory_add(_inv, "golden_rune_1", 20);
    inventory_add(_inv, "uchigatana", 1);

    var _r = inventory_discard_item("golden_rune_1", 5);
    inventory_test_assert(_r.ok && inventory_count_item(_inv, "golden_rune_1") == 15, "Discard a specified amount");

    _r = inventory_discard_item("golden_rune_1", 100);
    inventory_test_assert(!_r.ok && inventory_count_item(_inv, "golden_rune_1") == 15, "Discarding more than owned fails unchanged");

    _r = inventory_discard_item("golden_rune_1", 0);
    inventory_test_assert(!_r.ok && inventory_count_item(_inv, "golden_rune_1") == 15, "Discarding zero fails");

    _r = inventory_discard_item("golden_rune_1");
    inventory_test_assert(_r.ok && inventory_count_item(_inv, "golden_rune_1") == 14, "Discard defaults to one");

    // Equipped gear is only unequipped when its last copy leaves.
    inventory_execute_action("uchigatana", "Equip");
    inventory_test_assert(_p.is_equipped("uchigatana"), "Weapon equipped before discard");
    inventory_discard_item("uchigatana", 1);
    inventory_test_assert(!_p.is_equipped("uchigatana") && inventory_count_item(_inv, "uchigatana") == 0, "Discarding the last copy unequips it");

    inventory_add(_inv, "green_turtle_talisman", 1);
    inventory_execute_action("green_turtle_talisman", "Equip");
    inventory_discard_item("green_turtle_talisman");
    inventory_test_assert(!_p.is_talisman_equipped("green_turtle_talisman"), "Discarding a worn talisman frees its slot");

    // Dropping needs the world layer and pickup object.
    if (!layer_exists("Instances")) {
        show_debug_message("[SKIP] Drop tests: no 'Instances' layer in this room");
        return;
    }

    var _before = instance_number(obj_item_pickup);

    _r = inventory_drop_item("golden_rune_1", 10, 10, 6);
    inventory_test_assert(_r.ok && inventory_count_item(_inv, "golden_rune_1") == 8, "Drop a specified amount");
    inventory_test_assert(instance_number(obj_item_pickup) == _before + 1, "Drop creates one pickup");

    var _pickup = instance_find(obj_item_pickup, instance_number(obj_item_pickup) - 1);
    inventory_test_assert(_pickup.quantity == 6 && _pickup.item_id == "golden_rune_1", "Pickup holds the dropped quantity");

    _r = inventory_drop_item("golden_rune_1", 10, 10, 50);
    inventory_test_assert(!_r.ok && inventory_count_item(_inv, "golden_rune_1") == 8 && instance_number(obj_item_pickup) == _before + 1, "Over-dropping fails and creates no pickup");

    _r = inventory_drop_item("golden_rune_1", 10, 10, 0);
    inventory_test_assert(!_r.ok && instance_number(obj_item_pickup) == _before + 1, "Dropping zero fails and creates no pickup");

    // Clean up the pickups this test created.
    while (instance_number(obj_item_pickup) > _before) {
        with (instance_find(obj_item_pickup, instance_number(obj_item_pickup) - 1)) instance_destroy();
    }
}
#endregion


#region Handler registry extensibility
function inventory_test_registry() {
    inventory_test_reset();
    var _inv = global.player_inventory;

    inventory_test_assert(is_struct(item_category_get_handler("consumable")), "Consumable handler is registered");
    inventory_test_assert(is_undefined(item_category_get_handler("not_a_category")), "Unknown category has no handler");

    // A brand-new category and effect plugged in at runtime.
    item_effect_register("test_runes", function(_def, _quantity) {
        global.player.add_runes(7 * _quantity);
        return inventory_action_result(true, "ok");
    });

    global.item_db.test_elixir = {
        id: "test_elixir", name: "Test Elixir", category: "consumable", description: "", stackable: true,
        max_stack: 9, icon: -1, use_effect: "test_runes", use_amount: 1
    };
    global.item_db.test_gadget = {
        id: "test_gadget", name: "Test Gadget", category: "test_category", description: "", stackable: false,
        max_stack: 1, icon: -1
    };

    inventory_add(_inv, "test_elixir", 3);
    inventory_add(_inv, "test_gadget", 1);

    var _r = inventory_execute_action("test_elixir", "Use", 2);
    inventory_test_assert(_r.ok && global.player.runes == 14 && inventory_count_item(_inv, "test_elixir") == 1, "A newly registered effect works without changing the action code");
    inventory_test_assert(inventory_get_action_max_quantity("test_elixir", "Use") == 1, "Max quantity follows the remaining stack");

    // Category with no handler: only Drop and Discard, and no crash.
    var _acts = inventory_get_actions("test_gadget");
    inventory_test_assert(array_length(_acts) == 2 && _acts[0] == "Drop" && _acts[1] == "Discard", "Unhandled category offers only Drop and Discard");
    inventory_test_assert(!inventory_execute_action("test_gadget", "Use").ok, "Unhandled category rejects Use");

    item_category_register("test_category", item_handler_create(
        function(_item_id, _def) { return ["Use"]; },
        { Use: function(_item_id, _def, _quantity) { return inventory_action_result(true, "gadget used"); } }
    ));
    inventory_test_assert(array_contains(inventory_get_actions("test_gadget"), "Use"), "A newly registered category adds its actions");
    inventory_test_assert(inventory_execute_action("test_gadget", "Use").ok, "A newly registered category handles its action");

    variable_struct_remove(global.item_db, "test_elixir");
    variable_struct_remove(global.item_db, "test_gadget");
    variable_struct_remove(global.item_effect_handlers, "test_runes");
    variable_struct_remove(global.item_category_handlers, "test_category");
}
#endregion

#region Equip load
function inventory_test_equip_load() {
    inventory_test_reset();
    var _inv = global.player_inventory;
    var _p = global.player;

    inventory_add(_inv, "bull_goat_armor", 1);
    inventory_add(_inv, "greatshield", 1);
    inventory_add(_inv, "claymore", 1);

    inventory_test_assert(_p.get_equip_load() == 0, "Equip load starts at zero");
    inventory_test_assert(inventory_execute_action("bull_goat_armor", "Equip").ok, "Heavy armor fits an empty load");
    inventory_test_assert(inventory_execute_action("greatshield", "Equip").ok, "Shield still fits");
    inventory_test_assert(abs(_p.get_equip_load() - 34.5) < 0.001, "Equip load sums worn weights");

    var _r = inventory_execute_action("claymore", "Equip");
    inventory_test_assert(!_r.ok && _p.get_equipped_id("weapon") == "", "Over-limit weapon is rejected and not equipped");
    inventory_test_assert(abs(_p.get_equip_load() - 34.5) < 0.001, "Rejected equip leaves load unchanged");

    // Swapping a heavy item for a lighter one only counts the net change.
    inventory_add(_inv, "buckler", 1);
    inventory_test_assert(inventory_execute_action("buckler", "Equip").ok, "Swapping shield uses the net weight");
    inventory_test_assert(abs(_p.get_equip_load() - 23) < 0.001, "Load reflects the swapped shield");
    inventory_test_assert(inventory_execute_action("claymore", "Equip").ok, "Weapon fits after lightening the load");

    inventory_test_assert(item_get_weight("bull_goat_armor") == 21, "Explicit weights are kept");
    inventory_test_assert(item_get_weight("flask_crimson_tears") == 0, "Consumables default to zero weight");
}
#endregion


#region Save and load
function inventory_test_save_load() {
    inventory_test_reset();
    var _inv = global.player_inventory;
    var _p = global.player;

    inventory_add(_inv, "flask_crimson_tears", 9);
    inventory_add(_inv, "claymore", 1);
    inventory_add(_inv, "buckler", 1);
    inventory_add(_inv, "crimson_amber_medallion", 1);
    inventory_add(_inv, "green_turtle_talisman", 1);
    inventory_execute_action("claymore", "Equip");
    inventory_execute_action("buckler", "Equip");
    inventory_execute_action("crimson_amber_medallion", "Equip");
    inventory_execute_action("green_turtle_talisman", "Equip");
    hotbar_assign(global.player_hotbar, 2, "flask_crimson_tears");
    global.player_hotbar.selected_slot = 2;
    _p.health_ = 37;
    _p.fp = 11;
    _p.runes = 1234;

    // Round trip through JSON text, like a real save file.
    var _json = json_stringify(save_serialize());

    inventory_test_reset();
    var _r = save_apply(json_parse(_json));
    _inv = global.player_inventory;
    _p = global.player;

    inventory_test_assert(_r.ok && array_length(_r.warnings) == 0, "A valid save loads without warnings");
    inventory_test_assert(inventory_count_item(_inv, "flask_crimson_tears") == 9, "Quantities are restored");
    inventory_test_assert(_p.get_equipped_id("weapon") == "claymore" && _p.get_equipped_id("shield") == "buckler", "Equipment is restored");
    inventory_test_assert(array_length(_p.talismans) == 2 && _p.talismans[0] == "crimson_amber_medallion", "Talismans are restored in order");
    inventory_test_assert(global.player_hotbar.slots[2] == "flask_crimson_tears" && global.player_hotbar.selected_slot == 2, "Quick slots are restored");
    inventory_test_assert(_p.health_ == 37 && _p.fp == 11 && _p.runes == 1234, "HP, FP, and runes are restored");

    // Slot positions are preserved.
    inventory_test_reset();
    inventory_add(global.player_inventory, "claymore", 1);
    global.player_inventory.slots[5] = global.player_inventory.slots[0];
    global.player_inventory.slots[0] = undefined;
    var _data = save_serialize();
    inventory_test_reset();
    save_apply(_data);
    inventory_test_assert(is_struct(global.player_inventory.slots[5]) && is_undefined(global.player_inventory.slots[0]), "Slot positions are preserved");

    // Real file round trip.
    var _path = "inventory_test_save.json";
    inventory_test_assert(save_write(_path).ok, "Save file is written");
    inventory_test_reset();
    inventory_test_assert(save_read(_path).ok && inventory_count_item(global.player_inventory, "claymore") == 1, "Save file is read back");
    file_delete(_path);
    inventory_test_assert(!save_read(_path).ok, "A missing save file is reported");

    // Invalid data never half-applies.
    inventory_test_reset();
    inventory_add(global.player_inventory, "claymore", 2);
    inventory_test_assert(!save_apply(undefined).ok, "Non-struct data is rejected");
    inventory_test_assert(!save_apply({ version: 999 }).ok, "Wrong version is rejected");
    inventory_test_assert(!save_apply({ version: INVENTORY_SAVE_VERSION, player: {}, inventory: {} }).ok, "Missing slots are rejected");
    inventory_test_assert(inventory_count_item(global.player_inventory, "claymore") == 2, "Failed loads leave the game untouched");

    // Bad entries are repaired and reported.
    var _bad = {
        version: INVENTORY_SAVE_VERSION,
        player: { name: "x", health: 9999, fp: -5, runes: 10 },
        inventory: { capacity: 12, slots: [
            { slot: 0, id: "no_such_item", qty: 1 },
            { slot: 1, id: "flask_crimson_tears", qty: 9999 },
            { slot: 2, id: "claymore", qty: 1 }
        ] },
        equipment: { weapon: "claymore", shield: "buckler", armor: "bull_goat_armor" },
        talismans: ["green_turtle_talisman", "claymore"],
        hotbar: { slots: ["claymore", "", "", ""], selected: 99 }
    };
    var _fixed = save_apply(_bad);
    var _fp = global.player;

    inventory_test_assert(_fixed.ok && array_length(_fixed.warnings) >= 5, "Bad entries load with warnings");
    inventory_test_assert(inventory_count_item(global.player_inventory, "no_such_item") == 0, "Unknown items are dropped");
    inventory_test_assert(inventory_count_item(global.player_inventory, "flask_crimson_tears") <= item_definition_get("flask_crimson_tears").max_stack, "Oversized stacks are clamped");
    inventory_test_assert(_fp.get_equipped_id("weapon") == "claymore" && _fp.get_equipped_id("shield") == "" && _fp.get_equipped_id("armor") == "", "Equipment not in the inventory is unequipped");
    inventory_test_assert(array_length(_fp.talismans) == 0, "Unowned or non-talisman entries are removed");
    inventory_test_assert(_fp.health_ == _fp.max_health && _fp.fp == 0, "HP and FP are clamped");
    inventory_test_assert(global.player_hotbar.slots[0] == "" && global.player_hotbar.selected_slot == 3, "Invalid quick slots are cleared and selection is clamped");
}
#endregion


#region Data validation
function inventory_test_validation() {
    var _good = item_validation_collect(global.item_db_raw, [], {});
    inventory_test_assert(array_length(_good.errors) == 0, "The shipped item database has no validation errors");

    var _defs = [
        { id: "dup", name: "A", category: "consumable", description: "", stackable: true, max_stack: 5, icon: -1, use_effect: "heal_hp", use_amount: 1 },
        { id: "dup", name: "B", category: "consumable", description: "", stackable: true, max_stack: 5, icon: -1 },
        { id: "broken", category: "weapon", stackable: false, max_stack: 3 },
        { id: "bad_effect", name: "C", category: "consumable", description: "", stackable: true, max_stack: 5, icon: -1, use_effect: "nope", use_amount: 1 },
        { id: "no_handler", name: "D", category: "mystery", description: "", stackable: false, max_stack: 1, icon: -1 }
    ];
    var _built = item_database_build(_defs);
    var _report = item_validation_collect(_defs, _built.duplicates, { bad: [["ghost_item", 1]] });
    var _text = "";
    for (var i = 0; i < array_length(_report.errors); i++) _text += _report.errors[i] + "\n";
    var _warn = "";
    for (var i = 0; i < array_length(_report.warnings); i++) _warn += _report.warnings[i] + "\n";

    inventory_test_assert(string_pos("Duplicate item id 'dup'", _text) > 0, "Duplicate ids are detected");
    inventory_test_assert(string_pos("broken", _text) > 0, "Broken definitions are detected");
    inventory_test_assert(string_pos("no_handler", _warn) > 0, "Categories without a handler are reported");
    inventory_test_assert(string_pos("ghost_item", _warn) > 0, "Unknown template items are reported");
    inventory_test_assert(!is_undefined(_built.db[$ "dup"]) && _built.db.dup.name == "A", "The first duplicate definition wins");
}
#endregion


#region Events and transactions
function inventory_test_events() {
    inventory_test_reset();
    var _inv = global.player_inventory;
    var _p = global.player;

    inventory_add(_inv, "uchigatana", 1);
    inventory_add(_inv, "moonveil", 1);

    var _base_attack = _p.derived.attack;
    inventory_execute_action("uchigatana", "Equip");
    inventory_test_assert(_p.derived.attack > _base_attack, "Derived attack refreshes after equipping");

    var _count = { n: 0 };
    var _fn = inventory_event_subscribe(INV_EVENT_STATS, method(_count, function(_d) { n++; }));
    _p.add_runes(10);
    inventory_test_assert(_count.n == 1, "Stat changes emit a stats event");
    inventory_event_unsubscribe(INV_EVENT_STATS, _fn);
    _p.add_runes(10);
    inventory_test_assert(_count.n == 1, "Unsubscribed listeners are not called");

    inventory_remove(_inv, "uchigatana", 1);
    inventory_test_assert(_p.get_equipped_id("weapon") != "uchigatana", "Removing an equipped item unequips it");
    inventory_test_assert(_p.derived.attack == _base_attack, "Derived attack refreshes after the item is gone");
}


function inventory_test_transactions() {
    inventory_test_reset();
    var _inv = global.player_inventory;
    var _p = global.player;

    inventory_add(_inv, "flask_crimson_tears", 3);
    _p.fp = 30;
    _p.runes = 100;

    var _snap = inventory_tx_begin();
    inventory_remove(_inv, "flask_crimson_tears", 3);
    _p.spend_fp(20);
    _p.runes = 0;
    inventory_tx_rollback(_snap);
    inventory_test_assert(inventory_count_item(_inv, "flask_crimson_tears") == 3 && _p.fp == 30 && _p.runes == 100, "Rollback restores items, FP, and runes");

    // A failed Use must not consume anything.
    _p.health_ = _p.max_health;
    var _r = inventory_execute_action("flask_crimson_tears", "Use");
    inventory_test_assert(!_r.ok && inventory_count_item(_inv, "flask_crimson_tears") == 3, "A failed effect does not consume the item");
}
#endregion


#region Quick slots
function inventory_test_quick_slots() {
    inventory_test_reset();
    var _hb = global.player_hotbar;

    hotbar_assign(_hb, 0, "flask_crimson_tears");
    hotbar_assign(_hb, 1, "flask_cerulean_tears");

    var _r = hotbar_assign_result(_hb, 1, "flask_crimson_tears");
    inventory_test_assert(_r.ok && _hb.slots[1] == "flask_crimson_tears" && _hb.slots[0] == "flask_cerulean_tears", "Assigning to an occupied slot swaps the two items");

    _r = hotbar_assign_result(_hb, 1, "flask_crimson_tears");
    inventory_test_assert(!_r.ok, "Assigning an item to its own slot is rejected");

    _r = hotbar_assign_result(_hb, 3, "flask_crimson_tears");
    inventory_test_assert(_r.ok && _hb.slots[3] == "flask_crimson_tears" && _hb.slots[1] == "", "Moving to an empty slot vacates the old one");

    _r = hotbar_assign_result(_hb, 0, "golden_rune_1");
    inventory_test_assert(_r.ok && _hb.slots[0] == "golden_rune_1" && array_get_index(_hb.slots, "flask_cerulean_tears") == -1, "A new item replaces the slot occupant");

    inventory_test_assert(hotbar_assign(_hb, 2, "lone_wolf_ashes"), "Spirit ashes can be assigned");
    inventory_test_assert(!hotbar_assign(_hb, 4, "golden_rune_1"), "Out-of-range slots are rejected");

    // Out-of-stock items stay in their slot, and can still be swapped or replaced.
    inventory_test_assert(!hotbar_use(_hb, 0).ok && _hb.slots[0] == "golden_rune_1", "Using an out-of-stock slot keeps the assignment");
    inventory_test_assert(hotbar_assign(_hb, 3, "golden_rune_1") && _hb.slots[3] == "golden_rune_1" && _hb.slots[0] == "flask_crimson_tears", "An out-of-stock item swaps like any other");
    inventory_test_assert(hotbar_assign(_hb, 3, "flask_cerulean_tears") && _hb.slots[3] == "flask_cerulean_tears", "An out-of-stock slot can be replaced");
}
#endregion


#region Weapon skills
function inventory_test_skills() {
    inventory_test_reset();
    var _inv = global.player_inventory;
    var _p = global.player;

    inventory_add(_inv, "uchigatana", 1);
    inventory_test_assert(!array_contains(inventory_get_actions("uchigatana"), "Weapon Skill"), "Skill is not offered while unequipped");

    inventory_execute_action("uchigatana", "Equip");
    inventory_test_assert(array_contains(inventory_get_actions("uchigatana"), "Weapon Skill"), "Skill is offered once equipped");

    _p.fp = 30;
    var _r = inventory_execute_action("uchigatana", "Weapon Skill");
    inventory_test_assert(_r.ok && _p.fp == 20, "Weapon skill spends FP");

    _p.fp = 5;
    inventory_test_assert(inventory_get_action_unsupported_reason("uchigatana", "Weapon Skill") != "", "Skill is grayed out without enough FP");
    _r = inventory_execute_action("uchigatana", "Weapon Skill");
    inventory_test_assert(!_r.ok && _p.fp == 5, "Skill fails without spending when FP is short");
}
#endregion


#region Spirit ashes
function inventory_test_spirit_ash() {
    inventory_test_reset();
    var _inv = global.player_inventory;
    var _p = global.player;

    inventory_add(_inv, "lone_wolf_ashes", 1);
    inventory_add(_inv, "mimic_tear_ashes", 1);

    _p.fp = 10;
    inventory_test_assert(inventory_get_action_unsupported_reason("lone_wolf_ashes", "Use") != "", "Ash is grayed out without enough FP");

    _p.fp = 50;
    var _r = inventory_execute_action("lone_wolf_ashes", "Use");
    inventory_test_assert(_r.ok && _p.fp == 30 && _p.summon == "lone_wolf_ashes", "Summoning pays the cost and sets the summon");
    inventory_test_assert(inventory_count_item(_inv, "lone_wolf_ashes") == 1, "Summoning does not consume the ash");
    inventory_test_assert(array_contains(inventory_get_actions("lone_wolf_ashes"), "Dismiss"), "A summoned ash offers Dismiss");
    inventory_test_assert(inventory_get_action_unsupported_reason("mimic_tear_ashes", "Use") != "", "Only one spirit can be summoned");

    _r = inventory_execute_action("lone_wolf_ashes", "Dismiss");
    inventory_test_assert(_r.ok && _p.summon == "", "Dismiss clears the summon");

    _p.fp = 50;
    _p.health_ = 20;
    _r = inventory_execute_action("mimic_tear_ashes", "Use");
    inventory_test_assert(!_r.ok && _p.fp == 50 && _p.health_ == 20, "An HP cost cannot kill and nothing is spent on failure");

    _p.health_ = 60;
    _r = inventory_execute_action("mimic_tear_ashes", "Use");
    inventory_test_assert(_r.ok && _p.fp == 15 && _p.health_ == 40, "Multi-resource costs are all paid");

    inventory_remove(_inv, "mimic_tear_ashes", 1);
    inventory_test_assert(_p.summon == "", "Losing the ash ends the summon");
}
#endregion

#region UI state machine
function inventory_test_ui_state() {
    inventory_test_reset();
    var _inv = global.player_inventory;
    var _p = global.player;

    // A plain struct stands in for the UI instance.
    var _ui = { ui_message: "", ui_message_timer: 0, ui_message_duration_brief: 90, ui_message_duration_standard: 120 };
    inventory_ui_state_init(_ui);

    inventory_add(_inv, "flask_crimson_tears", 5);
    inventory_test_assert(inventory_ui_is_grid(_ui), "UI starts on the grid");
    inventory_test_assert(inventory_ui_open_actions(_ui, "flask_crimson_tears") && _ui.ui_state == InventoryUIState.ACTIONS, "Opening an item shows its action menu");

    // Discard a stack: quantity -> confirm -> execute.
    _ui.ui_action_selected = array_get_index(_ui.ui_actions, "Discard");
    inventory_ui_choose_selected_action(_ui);
    inventory_test_assert(_ui.ui_state == InventoryUIState.QUANTITY && _ui.ui_ctx.quantity_max == 5, "Stack actions ask for a quantity first");
    inventory_ui_quantity_adjust(_ui, 99);
    inventory_test_assert(_ui.ui_ctx.quantity == 5, "Quantity is clamped to the stack");
    inventory_ui_quantity_adjust(_ui, -99);
    inventory_test_assert(_ui.ui_ctx.quantity == 1, "Quantity never drops below one");
    inventory_ui_quantity_adjust(_ui, 2);
    inventory_ui_quantity_confirm(_ui);
    inventory_test_assert(_ui.ui_state == InventoryUIState.CONFIRM, "Quantity leads to confirmation");

    inventory_ui_back(_ui);
    inventory_test_assert(_ui.ui_state == InventoryUIState.ACTIONS && _ui.ui_message == "Cancelled.", "Back from a dialog returns to the action menu");
    inventory_test_assert(inventory_count_item(_inv, "flask_crimson_tears") == 5, "Cancelling changes nothing");

    inventory_ui_choose_selected_action(_ui);
    inventory_ui_quantity_adjust(_ui, 2);
    inventory_ui_quantity_confirm(_ui);
    inventory_ui_confirm_accept(_ui);
    inventory_test_assert(inventory_ui_is_grid(_ui) && inventory_count_item(_inv, "flask_crimson_tears") == 2, "Confirming executes and returns to the grid");

    // Single items skip the quantity step.
    inventory_add(_inv, "claymore", 1);
    inventory_ui_open_actions(_ui, "claymore");
    _ui.ui_action_selected = array_get_index(_ui.ui_actions, "Discard");
    inventory_ui_choose_selected_action(_ui);
    inventory_test_assert(_ui.ui_state == InventoryUIState.CONFIRM, "Single items skip the quantity picker");
    inventory_ui_reset(_ui);

    // Equip with full talismans: replace -> execute.
    inventory_add(_inv, "crimson_amber_medallion", 1);
    inventory_add(_inv, "cerulean_amber_medallion", 1);
    inventory_add(_inv, "green_turtle_talisman", 1);
    inventory_add(_inv, "erdtree_favor", 1);
    inventory_execute_action("crimson_amber_medallion", "Equip");
    inventory_execute_action("cerulean_amber_medallion", "Equip");
    inventory_execute_action("green_turtle_talisman", "Equip");

    inventory_ui_open_actions(_ui, "erdtree_favor");
    _ui.ui_action_selected = array_get_index(_ui.ui_actions, "Equip");
    inventory_ui_choose_selected_action(_ui);
    inventory_test_assert(_ui.ui_state == InventoryUIState.REPLACE, "Full talisman slots open the replacement picker");
    inventory_ui_replace_move(_ui, 1);
    inventory_ui_replace_confirm(_ui);
    inventory_test_assert(inventory_ui_is_grid(_ui) && array_contains(_p.talismans, "erdtree_favor") && array_length(_p.talismans) == 3, "Picking a replacement equips the new talisman");

    // Escape unwinds one layer at a time.
    inventory_ui_open_actions(_ui, "claymore");
    inventory_test_assert(inventory_ui_back(_ui) && inventory_ui_is_grid(_ui), "Back from the menu returns to the grid");
    inventory_test_assert(!inventory_ui_back(_ui), "Back on the grid reports nothing to close");
}
#endregion