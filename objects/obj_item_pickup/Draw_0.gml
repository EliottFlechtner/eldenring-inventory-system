/// @description Draw the dropped item


// TODO: Change color based on assigned color per type of item dropped
draw_set_color(make_color_rgb(239, 203, 119));



draw_circle(x, y, 7, false);

draw_set_color(c_white);
draw_text(
    x + 12,
    y - 8,
    item_id + " x" + string(quantity)
);