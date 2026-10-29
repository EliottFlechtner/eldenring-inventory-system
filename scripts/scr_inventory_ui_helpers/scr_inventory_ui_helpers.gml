/// scr_inventory_ui_helpers

/// @function inventory_ui_message_show(_ui_id, _message, _duration)
/// @description Show a UI message for a number of step frames.
/// @param {Id.Instance} _ui_id The UI instance that owns the message state.
/// @param {String} _message The message to display.
/// @param {Real} _duration How many frames to display the message.
/// @returns {undefined} No value is returned; the UI instance's message state is updated.
function inventory_ui_message_show(_ui_id, _message, _duration) {
    with (_ui_id) {
        ui_message = _message;
        ui_message_timer = _duration;
    }
}

/// @function inventory_ui_message_clear(_ui_id)
/// @description Clear a UI message and stop its timer.
/// @param {Id.Instance} _ui_id The UI instance that owns the message state.
/// @returns {undefined} No value is returned; the UI instance's message state is reset.
function inventory_ui_message_clear(_ui_id) {
    with (_ui_id) {
        ui_message = "";
        ui_message_timer = 0;
    }
}

/// @function inventory_ui_message_tick(_ui_id)
/// @description Advance the message's frame timer by one step.
/// @param {Id.Instance} _ui_id The UI instance that owns the message state.
/// @returns {undefined} No value is returned; the UI instance's timer is updated.
function inventory_ui_message_tick(_ui_id) {
    with (_ui_id) {
        if (ui_message_timer > 0) {
            ui_message_timer--;
        }
    }
}

/// @function inventory_ui_draw_slot(_x1, _y1, _size, _selected)
/// @description Draw an inventory slot and highlight it when selected.
/// @param {Real} _x1 The slot's left coordinate.
/// @param {Real} _y1 The slot's top coordinate.
/// @param {Real} _size The slot width and height.
/// @param {Boolean} _selected Whether to draw the selection outline.
/// @returns {undefined} No value is returned; the slot is drawn at the requested position.
function inventory_ui_draw_slot(_x1, _y1, _size, _selected) {
    // Slot background
    draw_set_color(make_color_rgb(37, 38, 43));
    draw_rectangle(
        _x1, _y1,
        _x1 + _size, _y1 + _size,
        false
    );

    // Subtle border
    draw_set_color(make_color_rgb(92, 89, 81));
    draw_rectangle(
        _x1, _y1,
        _x1 + _size, _y1 + _size,
        true
    );

    // Selected slot: gold outline
    if (_selected) {
        draw_set_color(make_color_rgb(239, 203, 119));

        draw_rectangle(
            _x1 - 2, _y1 - 2,
            _x1 + _size + 2, _y1 + _size + 2,
            true
        );

        draw_rectangle(
            _x1 - 1, _y1 - 1,
            _x1 + _size + 1, _y1 + _size + 1,
            true
        );
    }
}