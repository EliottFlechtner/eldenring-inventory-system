/// Handle inventory movement and actions

// Message timer.
if (ui_message_timer > 0) {
    ui_message_timer--;
}

// Open/close the main inventory.
if (keyboard_check_pressed(vk_tab)) {
    if (!ui_context_open && !ui_confirm_open) {
        ui_open = !ui_open;
        ui_message = "";
    }
}

// Escape closes the topmost layer first.
if (ui_open && keyboard_check_pressed(vk_escape)) {
    if (ui_confirm_open) {
        ui_confirm_open = false;
        ui_pending_action = "";
        ui_message = "Cancelled.";
        ui_message_timer = 90;
    }
    else if (ui_context_open) {
        ui_context_open = false;
        ui_actions = [];
        ui_message = "";
    }
    else {
        ui_open = false;
        ui_message = "";
    }
}

// Don't process other inputs when the inventory is closed.
if (!ui_open) {
    exit;
}


// Confirmation dialog has highest priority.
if (ui_confirm_open) {
    if (keyboard_check_pressed(vk_enter)) {
        var _result;

       if (ui_pending_action == "Drop") {
		    // Temporary fallback until a player object exists.
		    var _drop_x = room_width * 0.5;
		    var _drop_y = room_height * 0.5;

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

        ui_message = _result.message;
        ui_message_timer = 120;

        ui_confirm_open = false;
        ui_pending_action = "";
        ui_context_open = false;
        ui_actions = [];
    }

    exit;
}


// Context-menu navigation.
if (ui_context_open) {
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

                ui_message = _result.message;
                ui_message_timer = 120;

                // Close the context menu after executing.
                ui_context_open = false;
                ui_actions = [];
            }
        }
    }

    exit;
}


// Normal grid navigation.
var _selected = ui_selected_slot;
var _column = _selected mod ui_columns;
var _row = floor(_selected / ui_columns);

if (keyboard_check_pressed(vk_left) && _column > 0) {
    _selected--;
}

if (keyboard_check_pressed(vk_right) && _column < ui_columns - 1) {
    _selected++;
}

if (keyboard_check_pressed(vk_up) && _row > 0) {
    _selected -= ui_columns;
}

if (keyboard_check_pressed(vk_down) && _row < ui_rows - 1) {
    _selected += ui_columns;
}

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
            ui_context_open = true;
        }
    }
    else {
        ui_message = "Empty slot.";
        ui_message_timer = 90;
    }
}

/// HOTBAR CONTROLS

// When the inventory is open, Ctrl + 1..4 assigns
// the currently selected item to a quick slot.
if (ui_open) {
    if (keyboard_check(vk_control)) {
        var assign_slot = -1;

        if (keyboard_check_pressed(ord("1"))) assign_slot = 0;
        if (keyboard_check_pressed(ord("2"))) assign_slot = 1;
        if (keyboard_check_pressed(ord("3"))) assign_slot = 2;
        if (keyboard_check_pressed(ord("4"))) assign_slot = 3;

        if (assign_slot != -1) {
			var hovered_item_id = "";

			// Match the exact layout used by your Draw GUI event.
			var _gw = display_get_gui_width();
			var _gh = display_get_gui_height();

			var _panel_x = (_gw - 860) * 0.5;
			var _panel_y = (_gh - 500) * 0.5;

			var _grid_x = _panel_x + 24;
			var _grid_y = _panel_y + 76;

			var _slot_size = ui_slot_size;
			var _gap = ui_slot_gap;
			var _columns = ui_columns;
			var _rows = ui_rows;

			// Mouse position in GUI coordinates.
			var _mx = device_mouse_x_to_gui(0);
			var _my = device_mouse_y_to_gui(0);

			// Find the grid cell under the mouse.
			var _rel_x = _mx - _grid_x;
			var _rel_y = _my - _grid_y;

			if (_rel_x >= 0 && _rel_y >= 0) {
			    var _col = floor(_rel_x / (_slot_size + _gap));
			    var _row = floor(_rel_y / (_slot_size + _gap));

			    if (_col >= 0 && _col < _columns
			    && _row >= 0 && _row < _rows) {

			        var _cell_x = _col * (_slot_size + _gap);
			        var _cell_y = _row * (_slot_size + _gap);

			        // Ignore the gaps between inventory slots.
			        if (_rel_x - _cell_x <= _slot_size
			        && _rel_y - _cell_y <= _slot_size) {

			            var _index = _row * _columns + _col;

			            var _slot = inventory_get_slot(
			                global.player_inventory,
			                _index
			            );

			            if (is_struct(_slot)) {
			                hovered_item_id = _slot.item_id;
			            }
			        }
			    }
			}

			// Assign the item currently under the mouse.
			if (hovered_item_id != "") {
			    if (hotbar_assign(
			        global.player_hotbar,
			        assign_slot,
			        hovered_item_id
			    )) {
			        ui_message = "Quick slot assigned.";
			        ui_message_timer = 90;
			    }
			}
        }
    }
}
else {
    // Number keys use a quick slot directly.
    if (keyboard_check_pressed(ord("1"))) {
        hotbar_use(global.player_hotbar, 0);
    }
    if (keyboard_check_pressed(ord("2"))) {
        hotbar_use(global.player_hotbar, 1);
    }
    if (keyboard_check_pressed(ord("3"))) {
        hotbar_use(global.player_hotbar, 2);
    }
    if (keyboard_check_pressed(ord("4"))) {
        hotbar_use(global.player_hotbar, 3);
    }

    // Q cycles the selected slot.
    if (keyboard_check_pressed(ord("Q"))) {
        hotbar_cycle(global.player_hotbar, 1);
    }
}