if (gmkui_window_resized())
{
	display_set_gui_size(window_get_width(), window_get_height());
	camera_set_view_size(view_camera[0], window_get_width(), window_get_height());
	surface_resize(application_surface, window_get_width(), window_get_height());
	exit;
}

var title = string("Window [FPS: ({0}) {1}]##window_example", fps, fps_real);
if (gmkui_begin(title, window_example_ref, 360, 32, 480, 640))
{
	var wind = gmkui_current_window();

	gmkui_text("Hello, {0}", "World!");
	gmkui_text("Position: [{0}, {1}]", wind.x, wind.y);

	gmkui_separator();

	gmkui_button("Button");
	gmkui_checkbox("Fixed window", window_fixed_ref);
	gmkui_checkbox("Debug interact", debug_interact_ref);
	
	gmkui_separator();
	
	gmkui_radio("Num. buttons", radio_ref, ["1 Button", "2 Buttons", "3 Buttons", "4 Buttons"]);

	gmkui_text("Add more buttons");
	gmkui_sameline();
	if (gmkui_button("<")) { radio = max(0, --radio); }
	gmkui_sameline();
	gmkui_text(radio + 1);
	gmkui_sameline();
	if (gmkui_button(">")) { radio = min(3, ++radio); }
	var num_buttons = radio + 1;

	// set widget width
	gmkui_set_width((wind.viewport_w - gmkui_style.gap[0] * (num_buttons - 1)) / num_buttons);
		for (var i = 0; i < num_buttons; ++i)
		{
			if (i > 0) { gmkui_sameline(); }
			if (gmkui_button(string("Button {0}", i+1))) { gmkui_print("Pressed \"Button {0}\"", i+1); }
		}
	gmkui_reset_width();

	gmkui_set_width((wind.viewport_w - gmkui_style.gap[0]) * 0.25);
		if (gmkui_button("Button 25%")) { gmkui_print("Button 25%"); }
		gmkui_sameline();
		gmkui_set_width((wind.viewport_w - gmkui_style.gap[0]) * 0.75);
		if (gmkui_button("Button 75%")) { gmkui_print("Button 75%"); }
	gmkui_reset_width();

	// collapse
	if (gmkui_collapse("Background Color", collapse_bg_color_ref)) {
		gmkui_slider("Red", bg_red_ref, 0, 255, gmkui_slider_flags.integer);
		gmkui_slider("Green", bg_green_ref, 0, 255, gmkui_slider_flags.integer);
		gmkui_slider("Blue", bg_blue_ref, 0, 255, gmkui_slider_flags.integer);
		layer_background_blend(layer_bg, make_colour_rgb(bg_red_ref.get(), bg_green_ref.get(), bg_blue_ref.get()));
	}
	
	gmkui_end();
}

var flags = window_fixed_flags.get();
if (gmkui_begin("Fixed window", window_fixed_ref, 16, 16, 300, 0, flags))
{
	gmkui_text("Window size: [{0}, {1}]", window_get_width(), window_get_height());
	gmkui_text("Display size: [{0}, {1}]", display_get_width(), display_get_height());
	gmkui_text("GUI size: [{0}, {1}]", display_get_gui_width(), display_get_gui_height());

	gmkui_separator();

	gmkui_text("Current window flags");
	if (gmkui_checkbox("gmkui_window_flags.no_move", (flags & gmkui_window_flags.no_move) == gmkui_window_flags.no_move))
	{
		window_fixed_flags.set(flags ^ gmkui_window_flags.no_move);
	}

	if (gmkui_checkbox("gmkui_window_flags.no_title", (flags & gmkui_window_flags.no_title) == gmkui_window_flags.no_title))
	{
		window_fixed_flags.set(flags ^ gmkui_window_flags.no_title);
	}
	
	gmkui_text("Stack size: {0}", ds_stack_size(gmkui.windows_stack));

	gmkui_separator();

	if (gmkui_button("Close")) { window_fixed_ref.set(false); }

	gmkui_end();
}

gmkui_draw();