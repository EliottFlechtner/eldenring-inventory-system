/// @description Handle inventory navigation, hotbar input, and item actions.

inventory_ui_message_tick(id);

#region Inventory visibility
// Open/close the main inventory (only when no menu or dialog is open).
if (keyboard_check_pressed(vk_tab) && inventory_ui_is_grid(id)) {
    inventory_open = !inventory_open;
    inventory_ui_message_clear(id);
}
#endregion

#region Cancel key press handling
// Escape closes the topmost layer first.
if (inventory_open && keyboard_check_pressed(vk_escape)) {
    if (!inventory_ui_back(id)) {
        inventory_open = false;
        inventory_ui_message_clear(id);
    }
}
#endregion

#region Closed-inventory hotbar input
// Don't process other inputs when the inventory is closed.
if (!inventory_open) {
    // Number keys use a quick slot directly while the inventory is closed.
    if (keyboard_check_pressed(ord("1"))) hotbar_use(global.player_hotbar, 0);
    if (keyboard_check_pressed(ord("2"))) hotbar_use(global.player_hotbar, 1);
    if (keyboard_check_pressed(ord("3"))) hotbar_use(global.player_hotbar, 2);
    if (keyboard_check_pressed(ord("4"))) hotbar_use(global.player_hotbar, 3);

    // 'A' cycles the selected quick slot.
    if (keyboard_check_pressed(ord("A"))) hotbar_cycle(global.player_hotbar, 1);
    exit;
}
#endregion

#region Dialog and menu input
// Each state handles its own input; the state machine decides what comes next.
switch (ui_state) {
    case InventoryUIState.REPLACE:
        if (keyboard_check_pressed(vk_up)) inventory_ui_replace_move(id, -1);
        if (keyboard_check_pressed(vk_down)) inventory_ui_replace_move(id, 1);
        if (keyboard_check_pressed(vk_enter)) inventory_ui_replace_confirm(id);
        exit;

    case InventoryUIState.QUANTITY:
        if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(vk_right)) inventory_ui_quantity_adjust(id, 1);
        if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(vk_left)) inventory_ui_quantity_adjust(id, -1);
        if (keyboard_check_pressed(vk_pageup)) inventory_ui_quantity_adjust(id, 10);
        if (keyboard_check_pressed(vk_pagedown)) inventory_ui_quantity_adjust(id, -10);
        if (keyboard_check_pressed(vk_end)) inventory_ui_quantity_adjust(id, ui_ctx.quantity_max);
        if (keyboard_check_pressed(vk_home)) inventory_ui_quantity_adjust(id, -ui_ctx.quantity_max);
        if (keyboard_check_pressed(vk_enter)) inventory_ui_quantity_confirm(id);
        exit;

    case InventoryUIState.CONFIRM:
        if (keyboard_check_pressed(vk_enter)) inventory_ui_confirm_accept(id);
        exit;

    case InventoryUIState.ACTIONS:
        if (keyboard_check_pressed(vk_up)) inventory_ui_move_action(id, -1);
        if (keyboard_check_pressed(vk_down)) inventory_ui_move_action(id, 1);
        if (keyboard_check_pressed(vk_enter)) inventory_ui_choose_selected_action(id);
        exit;
}
#endregion

#region Save and load
// F5 saves, F9 loads. Only available while browsing the grid.
if (keyboard_check_pressed(vk_f5)) {
    var _save_result = save_write();
    inventory_ui_message_show(id, _save_result.message, ui_message_duration_standard);
}

if (keyboard_check_pressed(vk_f9)) {
    var _load_result = save_read();
    inventory_ui_message_show(id, _load_result.message, ui_message_duration_standard);
}
#endregion

#region Normal grid navigation
var _selected = ui_selected_slot;
var _column = _selected mod ui_columns;
var _row = floor(_selected / ui_columns);

// Move around in the inventory.
if (keyboard_check_pressed(vk_left) && _column > 0) _selected--;
if (keyboard_check_pressed(vk_right) && _column < ui_columns - 1) _selected++;
if (keyboard_check_pressed(vk_up) && _row > 0) _selected -= ui_columns;
if (keyboard_check_pressed(vk_down) && _row < ui_rows - 1) _selected += ui_columns;
ui_selected_slot = clamp(_selected, 0, ui_slot_count - 1);

// Enter opens the action menu for an occupied slot.
if (keyboard_check_pressed(vk_enter)) {
    var _slot = inventory_get_slot(
        global.player_inventory,
        ui_selected_slot
    );

    if (is_struct(_slot)) {
        inventory_ui_open_actions(id, _slot.item_id);
    }
    else {
        inventory_ui_message_show(
            id,
            "Empty slot.",
            ui_message_duration_brief
        );
    }
}
#endregion

#region Hotbar controls
// Ctrl + 1..4 assigns the currently selected item to a quick slot.
if (keyboard_check(vk_control)) {
    var assign_slot = -1;

    if (keyboard_check_pressed(ord("1"))) assign_slot = 0;
    if (keyboard_check_pressed(ord("2"))) assign_slot = 1;
    if (keyboard_check_pressed(ord("3"))) assign_slot = 2;
    if (keyboard_check_pressed(ord("4"))) assign_slot = 3;

    if (assign_slot != -1) {
        var _selected_slot = inventory_get_slot(
            global.player_inventory,
            ui_selected_slot
        );

        if (is_struct(_selected_slot)) {
            var _assign_result = hotbar_assign_result(
                global.player_hotbar,
                assign_slot,
                _selected_slot.item_id
            );

            inventory_ui_message_show(
                id,
                _assign_result.message,
                ui_message_duration_brief
            );
        }
    }
}
#endregion
