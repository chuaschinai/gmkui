window_example_ref = gmkui_ref(global, "__window_example", true);
debug_interact_ref = gmkui_ref(gmkui, "debug_interact");

window_fixed_ref = gmkui_ref(global, "__window_fixed", false);
window_fixed_flags = gmkui_ref(global, "__window_fixed_flags", gmkui_window_flags.no_title);

collapse_bg_color_ref = gmkui_ref(self, "collapse_bg_color");
bg_red_ref = gmkui_ref(self, "bg_red", 93);
bg_green_ref = gmkui_ref(self, "bg_green", 124);
bg_blue_ref = gmkui_ref(self, "bg_blue", 160);
layer_bg = layer_background_get_id("Background");
layer_background_blend(layer_bg, make_colour_rgb(bg_red_ref.get(), bg_green_ref.get(), bg_blue_ref.get()));

radio = 0;
radio_ref = gmkui_ref(self, "radio");

view_enabled = true;
view_visible[0] = true;
view_camera[0] = camera_create();
camera_set_view_size(view_camera[0], 1366, 768);