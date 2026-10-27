///@description Initialize the UI

// The UI has its own state; inventory data lives elsewhere.
inventory_open = false;
ui_selected_slot = 0;

// Grid configuration.
ui_columns = 4;
ui_rows = 6;
ui_slot_count = 24;
ui_slot_size = 54;
ui_slot_gap = 8;

// Keyboard repeat and menu behavior can be extended later.
ui_last_action = "";

// Actions related.
ui_context_open = false;
ui_context_item = "";
ui_actions = [];
ui_action_selected = 0;

ui_confirm_open = false;
ui_pending_action = "";
ui_pending_item = "";

ui_message = "";
ui_message_timer = 0;

// Use a consistent GUI coordinate system.
display_set_gui_size(960, 540);
draw_set_font(fnt_inventory);