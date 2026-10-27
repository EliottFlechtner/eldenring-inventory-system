/// scr_inventory_ui_helpers

function inventory_ui_draw_panel(_x1, _y1, _x2, _y2, _color, _alpha) {
    draw_set_color(_color);
    draw_set_alpha(_alpha);
    draw_rectangle(_x1, _y1, _x2, _y2, false);
    draw_set_alpha(1);
}

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