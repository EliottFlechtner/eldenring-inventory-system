/// @description Draw the hotbar or the open inventory, including item details and character stats.

#region Hotbar
if (!inventory_open) {
    var hb = global.player_hotbar;

    var _total_width = hb.slot_count * ui_slot_size
                     + (hb.slot_count - 1) * ui_slot_gap;

    var _start_x = (display_get_gui_width() - _total_width) * 0.5;
    var _slot_y = display_get_gui_height() - ui_slot_size - ui_hotbar_bottom_margin;

    for (var i = 0; i < hb.slot_count; i++) {
        var _sx = _start_x + i * (ui_slot_size + ui_slot_gap);
        var _sy = _slot_y;

        // Slot background.
        draw_set_color(c_black);
        draw_set_alpha(0.8);
        draw_rectangle(_sx, _sy, _sx + ui_slot_size, _sy + ui_slot_size, false);

        // Border: gold for selected, grey otherwise.
        if (i == hb.selected_slot) {
            draw_set_color(make_color_rgb(230, 190, 90));
        } else {
            draw_set_color(make_color_rgb(130, 130, 130));
        }

        draw_set_alpha(1);
        draw_rectangle(_sx, _sy, _sx + ui_slot_size, _sy + ui_slot_size, true);

        var _item_id = hb.slots[i];

        if (_item_id != "") {
            var _def = item_definition_get(_item_id);

            if (!is_undefined(_def)) {
                // Placeholder icon until real item sprites are added.
                draw_set_color(c_white);
                draw_text(_sx + 6, _sy + 6, string(i + 1));
                draw_text(_sx + 6, _sy + 25, _def.name);

                var _quantity = inventory_count_item(
                    global.player_inventory,
                    _item_id
                );

                draw_text(
                    _sx + ui_slot_size - 16,
                    _sy + ui_slot_size - 18,
                    string(_quantity)
                );
            }
        } else {
            draw_set_color(c_gray);
            draw_text(_sx + 8, _sy + 18, string(i + 1));
        }
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
    exit;
}
#endregion

#region Dimensions and background
// --------------------------------------------------
// GUI dimensions and layout
// --------------------------------------------------

var _gw = display_get_gui_width();
var _gh = display_get_gui_height();

var _slot_size = ui_slot_size;
var _gap = ui_slot_gap;
var _columns = ui_columns;
var _rows = ui_rows;

var _grid_w = _columns * _slot_size
            + (_columns - 1) * _gap;

var _grid_h = _rows * _slot_size
            + (_rows - 1) * _gap;

var _panel_w = ui_panel_width;
var _panel_h = ui_panel_height;

var _panel_x = (_gw - _panel_w) * 0.5;
var _panel_y = (_gh - _panel_h) * 0.5;

var _grid_x = _panel_x + ui_panel_padding;
var _grid_y = _panel_y + ui_panel_header_height;

var _detail_x = _grid_x + _grid_w + ui_detail_gap;
var _detail_w = _panel_x + _panel_w - ui_panel_padding - _detail_x;

// --------------------------------------------------
// Background overlay
// --------------------------------------------------

draw_set_alpha(1);
draw_set_color(c_black);
draw_set_alpha(0.72);
draw_rectangle(0, 0, _gw, _gh, false);
draw_set_alpha(1);
#endregion

#region Inventory panel and slots
// --------------------------------------------------
// Main panel
// --------------------------------------------------

draw_set_color(make_color_rgb(24, 25, 29));
draw_rectangle(
    _panel_x,
    _panel_y,
    _panel_x + _panel_w,
    _panel_y + _panel_h,
    false
);

draw_set_color(make_color_rgb(156, 135, 91));
draw_rectangle(
    _panel_x,
    _panel_y,
    _panel_x + _panel_w,
    _panel_y + _panel_h,
    true
);

// Header
draw_set_color(make_color_rgb(239, 203, 119));
draw_text(_panel_x + ui_panel_padding, _panel_y + 18, "INVENTORY");

draw_set_color(c_white);
draw_text(_panel_x + ui_panel_padding, _panel_y + 40, "Items");

// --------------------------------------------------
// Inventory grid
// --------------------------------------------------

for (var i = 0; i < ui_slot_count; i++) {
    var _col = i mod _columns;
    var _row = floor(i / _columns);

    var _sx = _grid_x + _col * (_slot_size + _gap);
    var _sy = _grid_y + _row * (_slot_size + _gap);

    inventory_ui_draw_slot(
        _sx,
        _sy,
        _slot_size,
        i == ui_selected_slot
    );

    var _slot = inventory_get_slot(
        global.player_inventory,
        i
    );

    if (is_struct(_slot)) {
        var _def = item_definition_get(_slot.item_id);

        if (!is_undefined(_def)) {

            // Item icon
            if (_def.icon != -1) {
                var _sprite = _def.icon;

                var _sw = sprite_get_width(_sprite);
                var _sh = sprite_get_height(_sprite);

                if (_sw > 0 && _sh > 0) {
                    var _scale = min(32 / _sw, 32 / _sh);

                    draw_sprite_ext(
                        _sprite,
                        0,
                        _sx + _slot_size * 0.5,
                        _sy + _slot_size * 0.42,
                        _scale,
                        _scale,
                        0,
                        c_white,
                        1
                    );
                }
            }
            else {
                // Temporary icon: first letter of the item name
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_set_color(make_color_rgb(224, 207, 165));

                draw_text(
                    _sx + _slot_size * 0.5,
                    _sy + _slot_size * 0.43,
                    string_upper(string_copy(_def.name, 1, 1))
                );

                draw_set_halign(fa_left);
                draw_set_valign(fa_top);
            }

            // Stack quantity
            if (_slot.quantity > 1) {
                draw_set_color(c_white);
                draw_set_halign(fa_right);
                draw_set_valign(fa_bottom);

                draw_text(
                    _sx + _slot_size - 5,
                    _sy + _slot_size - 4,
                    "x" + string(_slot.quantity)
                );

                draw_set_halign(fa_left);
                draw_set_valign(fa_top);
            }
        }
    }
}
#endregion
#region Divider
draw_set_color(make_color_rgb(90, 85, 74));

draw_line(
    _detail_x - 14,
    _grid_y,
    _detail_x - 14,
    _grid_y + _grid_h
);
#endregion

#region Selected item details
var _selected = inventory_get_slot(
    global.player_inventory,
    ui_selected_slot
);

if (is_struct(_selected)) {
    var _definition = item_definition_get(_selected.item_id);

    if (!is_undefined(_definition)) {

        draw_set_color(make_color_rgb(239, 203, 119));
        draw_text(
            _detail_x,
            _grid_y,
            _definition.name
        );

        draw_set_color(make_color_rgb(191, 188, 180));

        draw_text(
            _detail_x,
            _grid_y + 32,
            "Category: " + string_upper(_definition.category)
        );

        draw_text(
            _detail_x,
            _grid_y + 54,
            "Quantity: " + string(_selected.quantity)
        );

        draw_text(
            _detail_x,
            _grid_y + 76,
            "Max stack: " + string(_definition.max_stack)
        );

        // Description
        draw_set_color(c_white);

        draw_text_ext(
            _detail_x,
            _grid_y + 116,
            _definition.description,
            18,
            _detail_w
        );

        // Item's own combat stats
        var _item_stat_y = _grid_y + 190;

        if (variable_struct_exists(_definition, "attack")) {
            draw_set_color(make_color_rgb(220, 130, 115));

            draw_text(
                _detail_x,
                _item_stat_y,
                "Attack: " + string(_definition.attack)
            );

            _item_stat_y += 24;
        }

        if (variable_struct_exists(_definition, "defense")) {
            draw_set_color(make_color_rgb(130, 177, 220));

            draw_text(
                _detail_x,
                _item_stat_y,
                "Defense: " + string(_definition.defense)
            );
        }

        // Compare an equippable item against the current slot.

        var _comparison = equipment_get_comparison(_selected.item_id);

        if (is_struct(_comparison) && _comparison.valid) {
            var _compare_y = _grid_y + 244;

            draw_set_color(make_color_rgb(239, 203, 119));

            draw_text(
                _detail_x,
                _compare_y,
                "EQUIPMENT COMPARISON"
            );

            var _difference = _comparison.new_value - _comparison.current_value;
            var _difference_text = "";

            if (_difference > 0) {
                _difference_text = " (+" + string(_difference) + ")";
            }
            else if (_difference < 0) {
                _difference_text = " (" + string(_difference) + ")";
            }
            else {
                _difference_text = " (no change)";
            }

            if (_difference > 0) {
                draw_set_color(make_color_rgb(130, 210, 140));
            }
            else if (_difference < 0) {
                draw_set_color(make_color_rgb(220, 130, 115));
            }
            else {
                draw_set_color(c_white);
            }

            draw_text(
                _detail_x,
                _compare_y + 24,
                _comparison.stat_name + ": "
                + string(_comparison.current_value)
                + " -> "
                + string(_comparison.new_value)
                + _difference_text
            );
        }

        // Show the resulting character stats and equipped gear.

        var _stats_y = _grid_y + 292;

        draw_set_color(make_color_rgb(239, 203, 119));
        draw_text(
            _detail_x,
            _stats_y,
            "CHARACTER"
        );

        draw_set_color(c_white);

        draw_text(
            _detail_x,
            _stats_y + 23,
            "Attack: " + string(global.player.get_attack())
        );

        draw_text(
            _detail_x + 170,
            _stats_y + 23,
            "Defense: " + string(global.player.get_defense())
        );

        // The helper returns undefined when no item is equipped.
        var _weapon_def = global.player.get_equipped_definition("weapon");
        var _weapon_name = is_struct(_weapon_def) ? _weapon_def.name : "None";
        var _armor_def = global.player.get_equipped_definition("armor");
        var _armor_name = is_struct(_armor_def) ? _armor_def.name : "None";

        draw_set_color(make_color_rgb(191, 188, 180));

        draw_text(
            _detail_x,
            _stats_y + 48,
            "Health: " + string(global.player.health_) + " / " + string(global.player.max_health)
        );

        draw_text(
            _detail_x + 170,
            _stats_y + 48,
            "FP: " + string(global.player.fp) + " / " + string(global.player.max_fp)
        );

        draw_text(
            _detail_x,
            _stats_y + 70,
            "Runes: " + string(global.player.runes)
        );

        draw_text(
            _detail_x,
            _stats_y + 92,
            "Weapon: " + _weapon_name
        );

        draw_text(
            _detail_x,
            _stats_y + 114,
            "Armor: " + _armor_name
        );
    }
}
else {
    draw_set_color(make_color_rgb(180, 176, 164));

    draw_text(_detail_x, _grid_y, "Empty slot");
    draw_text(_detail_x, _grid_y + 32, "No item is stored here.");
}
#endregion

#region Action menu
if (ui_actions_menu_open) {
    var _menu_x = _panel_x + 300;
    var _menu_y = _panel_y + 120;
    var _menu_w = ui_menu_width;
    var _menu_row_h = ui_menu_row_height;
    var _menu_count = array_length(ui_actions);
    var _menu_h = _menu_count * _menu_row_h + 16;

    // Fully opaque menu background
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(15, 16, 18));

    draw_rectangle(
        _menu_x,
        _menu_y,
        _menu_x + _menu_w,
        _menu_y + _menu_h,
        false
    );

    // Menu border
    draw_set_color(make_color_rgb(156, 135, 91));

    draw_rectangle(
        _menu_x,
        _menu_y,
        _menu_x + _menu_w,
        _menu_y + _menu_h,
        true
    );

    // Menu options
    for (var i = 0; i < _menu_count; i++) {
        var _row_y = _menu_y + 8 + i * _menu_row_h;

        if (i == ui_action_selected) {
            draw_set_color(make_color_rgb(91, 77, 51));

            draw_rectangle(
                _menu_x + 4,
                _row_y,
                _menu_x + _menu_w - 4,
                _row_y + _menu_row_h,
                false
            );

            draw_set_color(make_color_rgb(239, 203, 119));
        }
        else {
            draw_set_color(c_white);
        }

        draw_text(
            _menu_x + 14,
            _row_y + 8,
            ui_actions[i]
        );
    }
}
#endregion

#region Feedback message
if (ui_message_timer > 0 && ui_message != "") {

    var _message_w = ui_message_width;
    var _message_x = (_gw - _message_w) * 0.5;
    var _message_y = _gh - ui_message_bottom_margin;

    // Filled message background
    draw_set_color(make_color_rgb(20, 20, 22));
    draw_rectangle(
        _message_x,
        _message_y,
        _message_x + _message_w,
        _message_y + ui_message_height,
        false
    );

    draw_set_color(make_color_rgb(156, 135, 91));
    draw_rectangle(
        _message_x,
        _message_y,
        _message_x + _message_w,
        _message_y + ui_message_height,
        true
    );

    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_text(
        _gw * 0.5,
        _message_y + ui_message_height * 0.5,
        ui_message
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
#endregion

#region Confirmation dialog
if (ui_confirm_open) {

    var _confirm_w = ui_confirmation_width;
    var _confirm_h = ui_confirmation_height;
    var _confirm_x = (_gw - _confirm_w) * 0.5;
    var _confirm_y = (_gh - _confirm_h) * 0.5;

    // Dim everything behind the dialog
    draw_set_color(c_black);
    draw_set_alpha(0.45);

    draw_rectangle(
        0,
        0,
        _gw,
        _gh,
        false
    );

    draw_set_alpha(1);

    // Opaque dialog background
    draw_set_color(make_color_rgb(31, 30, 28));

    draw_rectangle(
        _confirm_x,
        _confirm_y,
        _confirm_x + _confirm_w,
        _confirm_y + _confirm_h,
        false
    );

    // Dialog border
    draw_set_color(make_color_rgb(239, 203, 119));

    draw_rectangle(
        _confirm_x,
        _confirm_y,
        _confirm_x + _confirm_w,
        _confirm_y + _confirm_h,
        true
    );

    var _confirm_text =
        "Confirm " + string_lower(ui_pending_action);

    draw_set_color(c_white);

    draw_text(
        _confirm_x + 18,
        _confirm_y + 18,
        _confirm_text + "?"
    );

    draw_set_color(make_color_rgb(190, 186, 176));

    draw_text(
        _confirm_x + 18,
        _confirm_y + 52,
        "This action cannot be undone."
    );

    draw_text(
        _confirm_x + 18,
        _confirm_y + 100,
        "ENTER: Confirm     ESC: Cancel"
    );
}
#endregion

// --------------------------------------------------
// Reset drawing state
// --------------------------------------------------

draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);