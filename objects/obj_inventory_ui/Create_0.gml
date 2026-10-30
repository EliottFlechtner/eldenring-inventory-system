/// @description Initialize inventory UI state, layout settings, and GUI drawing defaults.

// The UI has its own state; inventory data lives elsewhere.
inventory_open = false;
ui_selected_slot = 0;

// Grid configuration.
ui_columns = 4;
ui_rows = 6;
ui_slot_count = ui_columns * ui_rows;
ui_slot_size = 54;
ui_slot_gap = 8;
ui_hotbar_bottom_margin = 24;

ui_panel_width = 860;
ui_panel_height = 560;
ui_panel_padding = 24;
ui_panel_header_height = 76;
ui_detail_gap = 28;
ui_menu_width = 210;
ui_menu_row_height = 32;
ui_message_width = 340;
ui_message_height = 34;
ui_message_bottom_margin = 92;
ui_confirmation_width = 390;
ui_confirmation_height = 145;

// Keyboard repeat and menu behavior can be extended later.
ui_last_action = "";

// Menus and dialogs share one state machine (see scr_inventory_ui_state).
inventory_ui_state_init(id);
inventory_ui_subscribe(id);

// Dialog sizes.
ui_replace_width = 340;
ui_quantity_width = 320;
ui_quantity_height = 150;
ui_message = "";
ui_message_timer = 0;
// Message durations are frame counts, scaled to the game's step rate.
ui_message_duration_brief = game_get_speed(gamespeed_fps) * 1.5; // Preserve the original 90 frames at 60 FPS.
ui_message_duration_standard = game_get_speed(gamespeed_fps) * 2; // Two seconds.

// Use a consistent GUI coordinate system.
display_set_gui_size(960, 540);
draw_set_font(fnt_inventory);