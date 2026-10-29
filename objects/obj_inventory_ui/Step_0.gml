/// @description Handle inventory navigation, hotbar input, and item actions.

inventory_ui_message_tick(id);

#region Inventory visibility
// Open/close the main inventory.
if (keyboard_check_pressed(vk_tab)) {
    if (!ui_actions_menu_open && !ui_confirm_open) {
        inventory_open = !inventory_open;
        inventory_ui_message_clear(id);
    }
}
#endregion

#region Cancel key press handling
// Escape closes the topmost layer first.
if (inventory_open && keyboard_check_pressed(vk_escape)) {
    if (ui_confirm_open) {
        ui_confirm_open = false;
        ui_pending_action = "";
        inventory_ui_message_show(
            id,
            "Cancelled.",
            ui_message_duration_brief
        );
    }
    else if (ui_actions_menu_open) {
        ui_actions_menu_open = false;
        ui_actions = [];
        inventory_ui_message_clear(id);
    }
    else {
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

#region Confirmation sub-menu navigation
// Confirmation dialog has highest priority.
// Currently, confirmation can only be for dropping/discarding
if (ui_confirm_open) {
    if (keyboard_check_pressed(vk_enter)) {
        var _result;

       if (ui_pending_action == "Drop") {
		    // Temporary fallback until a player object exists.
		    var _drop_x = irandom_range(100, room_width);
		    var _drop_y = irandom_range(100, room_height);

		    _result = inventory_drop_item(
		        ui_pending_item,
		        _drop_x,
		        _drop_y
		    );
		}
        else if (ui_pending_action == "Discard") {
            _result = inventory_discard_item(ui_pending_item);
        }
        else {
            _result = inventory_action_result(
                false,
                "Invalid pending action."
            );
        }

        inventory_ui_message_show(
            id,
            _result.message,
            ui_message_duration_standard
        );

        // Reset the confirmation state so the next action starts cleanly.
        ui_confirm_open = false;
        ui_pending_action = "";
        ui_actions_menu_open = false;
        ui_actions = [];
    }

    exit;
}
#endregion

#region Action-menu navigation
if (ui_actions_menu_open) {
    var _action_count = array_length(ui_actions);

    if (_action_count > 0) {
        if (keyboard_check_pressed(vk_up)) {
            ui_action_selected--;

            if (ui_action_selected < 0) {
                ui_action_selected = _action_count - 1;
            }
        }

        if (keyboard_check_pressed(vk_down)) {
            ui_action_selected++;

            if (ui_action_selected >= _action_count) {
                ui_action_selected = 0;
            }
        }

        if (keyboard_check_pressed(vk_enter)) {
            var _action = ui_actions[ui_action_selected];

            if (_action == "Drop" || _action == "Discard") {
                ui_pending_action = _action;
                ui_pending_item = ui_context_item;
                ui_confirm_open = true;
            }
            else {
                var _result = inventory_execute_action(
                    ui_context_item,
                    _action
                );

                inventory_ui_message_show(
                    id,
                    _result.message,
                    ui_message_duration_standard
                );

                // Close the context menu after executing.
                ui_actions_menu_open = false;
                ui_actions = [];
            }
        }
    }

    exit;
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
        ui_context_item = _slot.item_id;
        ui_actions = inventory_get_actions(_slot.item_id);
        ui_action_selected = 0;

        if (array_length(ui_actions) > 0) {
            ui_actions_menu_open = true;
        }
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
// When the inventory is open, Ctrl + 1..4 assigns
// the currently selected item to a quick slot.
if (inventory_open) {
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

            if (is_struct(_selected_slot) && hotbar_assign(
                global.player_hotbar,
                assign_slot,
                _selected_slot.item_id
            )) {
                inventory_ui_message_show(
                    id,
                    "Quick slot assigned.",
                    ui_message_duration_brief
                );
            }
        }
    }
}
#endregion