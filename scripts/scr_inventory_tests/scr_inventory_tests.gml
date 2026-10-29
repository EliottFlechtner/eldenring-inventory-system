/// scr_inventory_tests

/// @function inventory_test_assert(_condition, _message)
/// @description Log a test result and return whether its condition passed.
/// @param {Boolean} _condition The test condition to evaluate.
/// @param {String} _message The test name or outcome description.
/// @returns {Boolean} The value of the test condition.
function inventory_test_assert(_condition, _message) {
    if (_condition) {
        show_debug_message("[PASS] " + _message);
    } else {
        show_debug_message("[FAIL] " + _message);
    }

    return _condition;
}


/// @function inventory_run_tests()
/// @description Run the inventory core's built-in debug checks.
/// @returns {Boolean} True after the test sequence finishes; individual pass or failure results are written to the debug log.
function inventory_run_tests() {
    show_debug_message("=== INVENTORY TESTS BEGIN ===");

    var _inv = inventory_create(3);

    // Test 1: Add a stackable item.
    inventory_test_assert(
        inventory_add(_inv, "potion", 5) == 5,
        "Add five potions"
    );

    inventory_test_assert(
        inventory_count_item(_inv, "potion") == 5,
        "Potion count is five"
    );

    // Test 2: Merge with an existing stack.
    inventory_test_assert(
        inventory_add(_inv, "potion", 3) == 3,
        "Merge additional potions"
    );

    inventory_test_assert(
        inventory_count_item(_inv, "potion") == 8,
        "Potion stack contains eight"
    );

    // Test 3: Reject unknown items.
    inventory_test_assert(
        inventory_add(_inv, "unknown_item", 1) == 0,
        "Reject an unknown item"
    );

    // Test 4: Reject non-positive quantities.
    inventory_test_assert(
        inventory_add(_inv, "potion", 0) == 0,
        "Reject a zero quantity"
    );

    // Test 5: Add a unique item.
    inventory_test_assert(
        inventory_add(_inv, "iron_sword", 1) == 1,
        "Add an iron sword"
    );

    // Test 6: Fill the last slot.
    inventory_test_assert(
        inventory_add(_inv, "leather_armor", 1) == 1,
        "Add leather armor"
    );

    // Test 7: Inventory is full for a new item.
    inventory_test_assert(
        inventory_add(_inv, "herb", 1) == 0,
        "Reject an item when all slots are occupied"
    );

    // Test 8: Removal succeeds.
    inventory_test_assert(
        inventory_remove(_inv, "potion", 3),
        "Remove three potions"
    );

    inventory_test_assert(
        inventory_count_item(_inv, "potion") == 5,
        "Five potions remain"
    );

    // Test 9: Failed removal changes nothing.
    inventory_test_assert(
        !inventory_remove(_inv, "potion", 100),
        "Reject removal of unavailable quantity"
    );

    inventory_test_assert(
        inventory_count_item(_inv, "potion") == 5,
        "Failed removal leaves inventory unchanged"
    );

    // Test 10: Invalid empty-slot lookup.
    inventory_test_assert(
        inventory_find_empty_slot(_inv) == -1,
        "Detect full inventory"
    );

    show_debug_message("=== INVENTORY TESTS END ===");

    return true;
}