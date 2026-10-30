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

        // Slot number, small, in the corner.
        draw_set_color(c_gray);
        draw_text(_sx + 4, _sy + 2, string(i + 1));

        if (_item_id != "") {
            var _def = item_definition_get(_item_id);

            if (!is_undefined(_def)) {
                // Placeholder icon (first letter), same as the inventory slots.
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_set_color(make_color_rgb(224, 207, 165));
                draw_text(_sx + ui_slot_size * 0.5, _sy + ui_slot_size * 0.43, string_upper(string_copy(_def.name, 1, 1)));

                // Total owned count, bottom-right.
                var _quantity = inventory_count_item(global.player_inventory, _item_id);
                draw_set_color(_quantity > 0 ? c_white : make_color_rgb(220, 130, 115));
                draw_set_halign(fa_right);
                draw_set_valign(fa_bottom);
                draw_text(_sx + ui_slot_size - 5, _sy + ui_slot_size - 4, "x" + string(_quantity));
                draw_set_halign(fa_left);
                draw_set_valign(fa_top);

                // Green dot: this spirit ash is currently summoned.
                if (global.player.summon == _item_id) {
                    draw_set_color(make_color_rgb(110, 210, 130));
                    draw_circle(_sx + ui_slot_size - 8, _sy + 8, 4, false);
                }

                // Full name of the selected quick slot, above the bar.
                if (i == hb.selected_slot) {
                    draw_set_color(make_color_rgb(239, 203, 119));
                    draw_set_halign(fa_center);
                    draw_set_valign(fa_bottom);
                    draw_text(display_get_gui_width() * 0.5, _slot_y - 6, _def.name);
                    draw_set_halign(fa_left);
                    draw_set_valign(fa_top);
                }
            }
        }
    }
    // Short feedback line above the selected slot name.
    if (ui_message_timer > 0 && ui_message != "") {
        draw_set_halign(fa_center);
        draw_set_valign(fa_bottom);
        draw_set_color(c_white);
        draw_text(display_get_gui_width() * 0.5, _slot_y - 28, ui_message);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
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

            // Equipped marker: a small dot in the top-right corner.
            if (global.player.is_equipped(_slot.item_id)) {
                draw_set_color(make_color_rgb(239, 203, 119));
                draw_circle(_sx + _slot_size - 8, _sy + 8, 4, false);
                draw_set_color(make_color_rgb(15, 16, 18));
                draw_circle(_sx + _slot_size - 8, _sy + 8, 4, true);
            }

            // Quick slot marker: a blue dot with the assigned slot number, top-left.
            var _quick_index = array_get_index(global.player_hotbar.slots, _slot.item_id);
            if (_quick_index != -1) {
                draw_set_color(make_color_rgb(95, 160, 235));
                draw_circle(_sx + 9, _sy + 9, 7, false);
                draw_set_color(make_color_rgb(15, 16, 18));
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_text(_sx + 9, _sy + 9, string(_quick_index + 1));
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
            "Category: " + string_upper(_definition.category) + "   Weight: " + string(item_get_weight(_definition.id))
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

        // Weapon skill or summon cost, when the item has one
        var _extra_line = "";
        if (_definition.category == "weapon") {
            var _skill = item_skill_get(_definition);
            if (is_struct(_skill)) _extra_line = "Skill: " + _skill.name + " (" + item_cost_text(_skill.cost) + ")";
        }
        else if (_definition.category == "spirit_ash" && variable_struct_exists(_definition, "cost")) {
            _extra_line = "Summon cost: " + item_cost_text(_definition.cost);
        }
        if (_extra_line != "") {
            draw_set_color(make_color_rgb(130, 177, 220));
            draw_text(_detail_x, _grid_y + 96, _extra_line);
        }

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

    }
}
else {
    draw_set_color(make_color_rgb(180, 176, 164));

    draw_text(_detail_x, _grid_y, "Empty slot");
    draw_text(_detail_x, _grid_y + 32, "No item is stored here.");
}

#region Character stats
// Always visible, whether or not the selected slot holds an item.
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
    "Attack: " + string(global.player.derived.attack)
);

draw_text(
    _detail_x + 170,
    _stats_y + 23,
    "Defense: " + string(global.player.derived.defense)
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

var _shield_def = global.player.get_equipped_definition("shield");
draw_text(
    _detail_x,
    _stats_y + 136,
    "Shield: " + (is_struct(_shield_def) ? _shield_def.name : "None")
);

draw_text(
    _detail_x,
    _stats_y + 158,
    "Equip Load: " + string(global.player.derived.equip_load) + " / " + string(global.player.max_equip_load)
);

draw_text(
    _detail_x + 170,
    _stats_y + 70,
    "Talismans (" + string(array_length(global.player.talismans)) + " / " + string(global.player.max_talismans) + "):"
);

for (var _t = 0; _t < global.player.max_talismans; _t++) {
    var _talisman_name = "-";

    if (_t < array_length(global.player.talismans)) {
        _talisman_name = item_definition_get(global.player.talismans[_t]).name;
    }

    draw_text(_detail_x + 186, _stats_y + 92 + _t * 22, _talisman_name);
}

var _summon_def = (global.player.summon != "") ? item_definition_get(global.player.summon) : undefined;
draw_text(
    _detail_x + 170,
    _stats_y + 158,
    "Summon: " + (is_struct(_summon_def) ? _summon_def.name : "None")
);
#endregion

#region Action menu
if (ui_state != InventoryUIState.GRID) {
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

        // Unsupported actions are grayed out but remain selectable.
        if (inventory_get_action_unsupported_reason(ui_ctx.item, ui_actions[i]) != "") {
            draw_set_color(i == ui_action_selected ? make_color_rgb(150, 140, 110) : make_color_rgb(110, 108, 102));
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
if (ui_state == InventoryUIState.CONFIRM) {

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

    var _confirm_def = item_definition_get(ui_ctx.item);
    var _confirm_text =
        "Confirm " + string_lower(ui_ctx.action)
        + " " + (ui_ctx.quantity > 1 ? string(ui_ctx.quantity) + "x " : "")
        + (is_struct(_confirm_def) ? _confirm_def.name : "");

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

#region Replacement dialog
if (ui_state == InventoryUIState.REPLACE) {
    var _rep_count = array_length(ui_ctx.replace_options);
    var _rep_row_h = ui_menu_row_height;
    var _rep_w = ui_replace_width;
    var _rep_h = 60 + _rep_count * _rep_row_h + 34;
    var _rep_x = (_gw - _rep_w) * 0.5;
    var _rep_y = (_gh - _rep_h) * 0.5;
    var _rep_new = item_definition_get(ui_ctx.item);

    draw_set_color(c_black);
    draw_set_alpha(0.45);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    draw_set_color(make_color_rgb(31, 30, 28));
    draw_rectangle(_rep_x, _rep_y, _rep_x + _rep_w, _rep_y + _rep_h, false);

    draw_set_color(make_color_rgb(239, 203, 119));
    draw_rectangle(_rep_x, _rep_y, _rep_x + _rep_w, _rep_y + _rep_h, true);

    draw_set_color(c_white);
    draw_text(_rep_x + 18, _rep_y + 14, "No free slot for " + (is_struct(_rep_new) ? _rep_new.name : ""));
    draw_set_color(make_color_rgb(190, 186, 176));
    draw_text(_rep_x + 18, _rep_y + 36, "Choose one to replace:");

    for (var _r = 0; _r < _rep_count; _r++) {
        var _row_y = _rep_y + 60 + _r * _rep_row_h;
        var _rep_def = item_definition_get(ui_ctx.replace_options[_r]);

        if (_r == ui_ctx.replace_selected) {
            draw_set_color(make_color_rgb(91, 77, 51));
            draw_rectangle(_rep_x + 4, _row_y, _rep_x + _rep_w - 4, _row_y + _rep_row_h, false);
            draw_set_color(make_color_rgb(239, 203, 119));
        }
        else {
            draw_set_color(c_white);
        }

        draw_text(_rep_x + 18, _row_y + 8, is_struct(_rep_def) ? _rep_def.name : ui_ctx.replace_options[_r]);
    }

    draw_set_color(make_color_rgb(190, 186, 176));
    draw_text(_rep_x + 18, _rep_y + _rep_h - 26, "UP/DOWN: Select   ENTER: Replace   ESC: Cancel");
}
#endregion

#region Quantity dialog
if (ui_state == InventoryUIState.QUANTITY) {
    var _qty_w = ui_quantity_width;
    var _qty_h = ui_quantity_height;
    var _qty_x = (_gw - _qty_w) * 0.5;
    var _qty_y = (_gh - _qty_h) * 0.5;

    draw_set_color(c_black);
    draw_set_alpha(0.45);
    draw_rectangle(0, 0, _gw, _gh, false);
    draw_set_alpha(1);

    draw_set_color(make_color_rgb(31, 30, 28));
    draw_rectangle(_qty_x, _qty_y, _qty_x + _qty_w, _qty_y + _qty_h, false);

    draw_set_color(make_color_rgb(239, 203, 119));
    draw_rectangle(_qty_x, _qty_y, _qty_x + _qty_w, _qty_y + _qty_h, true);

    var _qty_def = item_definition_get(ui_ctx.item);

    draw_set_color(c_white);
    draw_text(_qty_x + 18, _qty_y + 18, ui_ctx.action + " " + (is_struct(_qty_def) ? _qty_def.name : ""));

    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(239, 203, 119));
    draw_text(_qty_x + _qty_w * 0.5, _qty_y + 56, "<  " + string(ui_ctx.quantity) + " / " + string(ui_ctx.quantity_max) + "  >");
    draw_set_halign(fa_left);

    draw_set_color(make_color_rgb(190, 186, 176));
    draw_text(_qty_x + 18, _qty_y + 100, "ARROWS: Amount   ENTER: Confirm");
    draw_text(_qty_x + 18, _qty_y + 122, "PGUP/PGDN: +/-10   ESC: Cancel");
}
#endregion

// --------------------------------------------------
// Reset drawing state
// --------------------------------------------------

draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);