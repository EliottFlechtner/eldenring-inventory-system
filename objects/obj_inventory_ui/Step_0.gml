/// @description Handle inventory navigation, hotbar input, and item actions.

inventory_ui_message_tick(id);

#region Inventory visibility
// Open/close the main inventory.
if (keyboard_check_pressed(vk_tab)) {
    if (!ui_actions_menu_open && !ui_confirm_open && !ui_quantity_open && !ui_replace_open) {
        inventory_open = !inventory_open;
        inventory_ui_message_clear(id);
    }
}
#endregion

#region Cancel key press handling
// Escape closes the topmost layer first.
if (inventory_open && keyboard_check_pressed(vk_escape)) {
    if (ui_replace_open) {
        ui_replace_open = false;
        inventory_ui_message_show(
            id,
            "Cancelled.",
            ui_message_duration_brief
        );
    }
    else if (ui_quantity_open) {
        ui_quantity_open = false;
        inventory_ui_message_show(
            id,
            "Cancelled.",
            ui_message_duration_brief
        );
    }
    else if (ui_confirm_open) {
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

#region Replacement picker navigation
if (ui_replace_open) {
    var _replace_count = array_length(ui_replace_options);

    if (keyboard_check_pressed(vk_up)) {
        ui_replace_selected = (ui_replace_selected - 1 + _replace_count) mod _replace_count;
    }

    if (keyboard_check_pressed(vk_down)) {
        ui_replace_selected = (ui_replace_selected + 1) mod _replace_count;
    }

    if (keyboard_check_pressed(vk_enter)) {
        var _result = inventory_execute_action(
            ui_replace_item,
            ui_replace_action,
            1,
            ui_replace_options[ui_replace_selected]
        );

        inventory_ui_message_show(id, _result.message, ui_message_duration_standard);

        ui_replace_open = false;
        ui_actions_menu_open = false;
        ui_actions = [];
    }

    exit;
}
#endregion

#region Quantity picker navigation
if (ui_quantity_open) {
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(vk_right)) {
        ui_quantity_value = min(ui_quantity_value + 1, ui_quantity_max);
    }

    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(vk_left)) {
        ui_quantity_value = max(ui_quantity_value - 1, 1);
    }

    // Page keys jump by 10; Home/End select the minimum or maximum.
    if (keyboard_check_pressed(vk_pageup)) ui_quantity_value = min(ui_quantity_value + 10, ui_quantity_max);
    if (keyboard_check_pressed(vk_pagedown)) ui_quantity_value = max(ui_quantity_value - 10, 1);
    if (keyboard_check_pressed(vk_end)) ui_quantity_value = ui_quantity_max;
    if (keyboard_check_pressed(vk_home)) ui_quantity_value = 1;

    if (keyboard_check_pressed(vk_enter)) {
        ui_quantity_open = false;

        // Drop and discard still need confirmation, now with the chosen amount.
        if (ui_quantity_action == "Drop" || ui_quantity_action == "Discard") {
            ui_pending_action = ui_quantity_action;
            ui_pending_item = ui_quantity_item;
            ui_pending_quantity = ui_quantity_value;
            ui_confirm_open = true;
            exit;
        }

        var _result = inventory_execute_action(
            ui_quantity_item,
            ui_quantity_action,
            ui_quantity_value
        );

        inventory_ui_message_show(id, _result.message, ui_message_duration_standard);

        ui_actions_menu_open = false;
        ui_actions = [];
    }

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
		        _drop_y,
		        ui_pending_quantity
		    );
		}
        else if (ui_pending_action == "Discard") {
            _result = inventory_discard_item(ui_pending_item, ui_pending_quantity);
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
                var _stack_count = inventory_get_action_max_quantity(ui_context_item, _action);

                // Stacks ask for an amount first; single items go straight to confirmation.
                if (_stack_count > 1) {
                    ui_quantity_open = true;
                    ui_quantity_action = _action;
                    ui_quantity_item = ui_context_item;
                    ui_quantity_max = _stack_count;
                    ui_quantity_value = 1;
                }
                else {
                    ui_pending_action = _action;
                    ui_pending_item = ui_context_item;
                    ui_pending_quantity = 1;
                    ui_confirm_open = true;
                }
            }
            else if (array_length(inventory_get_action_replace_options(ui_context_item, _action)) > 0) {
                ui_replace_open = true;
                ui_replace_action = _action;
                ui_replace_item = ui_context_item;
                ui_replace_options = inventory_get_action_replace_options(ui_context_item, _action);
                ui_replace_selected = 0;
            }
            else if (inventory_get_action_max_quantity(ui_context_item, _action) > 1) {
                ui_quantity_open = true;
                ui_quantity_action = _action;
                ui_quantity_item = ui_context_item;
                ui_quantity_max = inventory_get_action_max_quantity(ui_context_item, _action);
                ui_quantity_value = 1;
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