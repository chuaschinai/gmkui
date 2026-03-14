/// GameMakerUI v1.0.0 - by chuas

/// @param {String} name
/// @param {Struct.__gmkui_ref} ref
/// @param {Real} x
/// @param {Real} y
/// @param {Real} width
/// @param {Real} [height] default is 0,
function gmkui_begin(name, ref, x, y, width, height=0, flags=0)
{	
	if (ref != undefined && ref.get() == false)
		return false;

	var _id;
	if (gmkui.next_window_id)
	{
		_id = gmkui.next_window_id;
		gmkui.next_window_id = 0;
	}
	else {
		_id = __gmkui_hash(name);
	}

	if (ds_list_find_index(gmkui.windows_ordered, _id) == -1)
		ds_list_add(gmkui.windows_ordered, _id);
	
	if (!ds_map_exists(gmkui.windows, _id))
	{
		gmkui.window_focus_id = _id;
		var data = new __gmkui_window(_id, name, x, y);
		data.w = width;
		if (height == 0) { height = 200; }
		data.h = height;
		ds_map_add(gmkui.windows, _id, data);
		
		gmkui_print("Registered window '{0}'", name);
	}
	
	ds_stack_push(gmkui.windows_stack, _id);
	
	gmkui.mx = device_mouse_x_to_gui(0);
	gmkui.my = device_mouse_y_to_gui(0);

	/// @type {Struct.__gmkui_window} 
	var wind = ds_map_find_value(gmkui.windows, _id);
	
	// titlebar
	if (!(flags & (gmkui_window_flags.no_move | gmkui_window_flags.no_title)))
	{
		var titlebar = gmkui_interact("#TITLEBAR", wind.x, wind.y, wind.w, gmkui_style.title_height, GMKUI_INTERACT_MAX_DEPTH - 1);
		if (titlebar && titlebar.held)
		{
			wind.x = clamp(gmkui.mx - gmkui.drag_offset_x, -wind.w+32, window_get_width()-32);
			wind.y = clamp(gmkui.my - gmkui.drag_offset_y, 0, window_get_height()-32);
		}
	}

	// draw content area
	__gmkui_push_draw_rect(wind.x, wind.y, wind.w, wind.h, gmkui_style.col.background);

	var title_height_offset = 0;
	if (!(flags & gmkui_window_flags.no_title)) {
		__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.titlebar, { text: name, x: wind.x, y: wind.y, w: wind.w, h: gmkui_style.title_height, is_focused: gmkui.window_focus_id == wind.id });
		
		title_height_offset = gmkui_style.title_height;

		var button_size = gmkui_style.title_height - gmkui_style.gap[1] * 2;
		var button_x = wind.x + wind.w - button_size - gmkui_style.window_padding[0];
		var button_y = wind.y + gmkui_style.gap[1];

		// close
		var close = gmkui_interact("#CLOSE", button_x, button_y, button_size, button_size, GMKUI_INTERACT_MAX_DEPTH);
		if (close)
		{
			if (close.pressed)
			{
				var idx = ds_list_find_index(gmkui.windows_ordered, _id);
				if (idx != -1) { ds_list_delete(gmkui.windows_ordered, idx); }
				gmkui.window_focus_id = gmkui.windows_ordered[| ds_list_size(gmkui.windows_ordered)-1];
				gmkui.window_hover_id = 0;
				ds_stack_pop(gmkui.windows_stack);
				
				if (ref != undefined) { ref.set(false); }
				
				return false;
			}

			__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.button, { x: button_x, y: button_y, text: "X", w: button_size, h: button_size, hovered: false, active: false, disabled: false });
		}
		
		// collapse
		button_x -= button_size + gmkui_style.gap[0];
		var collapse = gmkui_interact("#COLLAPSE", button_x, button_y, button_size, button_size, GMKUI_INTERACT_MAX_DEPTH);
		if (collapse)
		{
			if (collapse.pressed)
			{
				if (!wind.hidden) { wind.last_height = wind.h; }
				else { wind.h = wind.last_height; }
				wind.hidden = !wind.hidden;
			}

			__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.button, { x: button_x, y: button_y, text: "_", w: button_size, h: button_size, hovered: false, active: false, disabled: false });
		}
	}

	// border
	__gmkui_push_draw_rect(wind.x, wind.y, wind.w, wind.h, gmkui_style.col.border, 1, true);

	// resize
	var resize = gmkui_interact("#RESIZE", wind.x + wind.w - 4, wind.y + wind.h - 4, 8, 8, GMKUI_INTERACT_MAX_DEPTH, gmkui_interact_flags.All | gmkui_interact_flags.out_of_window);
	if (resize) {
		if (resize.held)
		{
			wind.w = (gmkui.mx - gmkui.drag_offset_x) - wind.x + gmkui_style.window_padding[0];
			wind.h = (gmkui.my - gmkui.drag_offset_y) - wind.y + gmkui_style.window_padding[1];
			wind.w = max(wind.w, 64);
			wind.h = max(wind.h, gmkui_style.title_height + gmkui_style.window_padding[1] * 3);
		}

		__gmkui_push_draw_rect(wind.x + wind.w - 4, wind.y + wind.h - 4, 8, 8, c_aqua, resize.hovered || resize.held);
	}
	
	wind.viewport_w = wind.w - gmkui_style.window_padding[0] * 2;
	wind.viewport_h = wind.h - (gmkui_style.window_padding[1] * 2 + title_height_offset);
	var overflow_height = wind.content_height - wind.viewport_h;
	var scrollbar_thumb_height = max(wind.viewport_h - overflow_height, 16);
	
	// scrollbar
	var right_padding = 0;
	var content_start_y = wind.y + title_height_offset + gmkui_style.window_padding[1] + wind.scrollbar_y;

	if (!wind.hidden)
	{
		// content
		var content = gmkui_interact("#CONTENT", wind.x, wind.y + title_height_offset, wind.w, wind.h - title_height_offset, -1, gmkui_interact_flags.hover | gmkui_interact_flags.pressed | gmkui_interact_flags.wheel);
		if (content && content.wheel != 0 && overflow_height > 0)
		{
			wind.offset_y += content.wheel * 16;
			wind.offset_y = min(wind.offset_y, 0);
			
			// convert to scrollbar
			var ratio = clamp(abs(wind.offset_y) / (wind.content_height - wind.viewport_h), 0, 1);
			wind.scrollbar_y = ratio * (wind.viewport_h - scrollbar_thumb_height);
		}

		// scrollbar
		if (wind.cursor_y > wind.y + wind.viewport_h + wind.offset_y)
		{
			right_padding = gmkui_style.window_padding[0] * 2;
			wind.viewport_w -= gmkui_style.window_padding[0] * 2;
			var scrollbar = gmkui_interact("#SCROLLBAR", wind.x + wind.w - right_padding - gmkui_style.window_padding[0] * 0.5, content_start_y, right_padding, scrollbar_thumb_height, GMKUI_INTERACT_MAX_DEPTH);
	
			if (scrollbar && scrollbar.held)
			{
				wind.scrollbar_y = (gmkui.my - gmkui.drag_offset_y) - (wind.y + title_height_offset/*+ gmkui_style.gap[1] * 2 */);
				wind.scrollbar_y = clamp(wind.scrollbar_y, 0, wind.viewport_h - scrollbar_thumb_height);
				var ratio = wind.scrollbar_y / (wind.viewport_h - scrollbar_thumb_height);

				wind.offset_y = round(-ratio * overflow_height);
				wind.offset_y = clamp(wind.offset_y, -overflow_height, 0);
			}
		}

		// scrollbar bg
		__gmkui_push_draw_rect(wind.x + wind.w - right_padding - gmkui_style.window_padding[0] * 0.5, wind.y + title_height_offset + gmkui_style.window_padding[1], right_padding, wind.viewport_h, c_dkgray);
		// scrollbar thumb
		__gmkui_push_draw_rect(wind.x + wind.w - right_padding - gmkui_style.window_padding[0] * 0.5, content_start_y, right_padding, scrollbar_thumb_height, gmkui_style.col.bg_title, 1, false);

	} else {
		wind.h = title_height_offset + 1;
	}
	
	var extra_space = wind.viewport_h - wind.content_height - wind.offset_y;
	if (extra_space > 0 && wind.offset_y < 0)
	{
		wind.offset_y += extra_space;
	}
	wind.scrollbar_y = clamp(wind.scrollbar_y, 0, wind.viewport_h - scrollbar_thumb_height);

	__gmkui_pushclip(
		wind.x + gmkui_style.window_padding[0],
		wind.y + gmkui_style.window_padding[1] + title_height_offset,
		wind.w - (gmkui_style.window_padding[0] * 2 + right_padding + 1),
		wind.viewport_h
	);

	// reset cursor
	wind.cursor_start_x = wind.x + gmkui_style.window_padding[0];
	wind.cursor_start_y = wind.y + title_height_offset + gmkui_style.window_padding[1] + wind.offset_y;
	wind.cursor_x = wind.cursor_start_x;
	wind.cursor_y = wind.cursor_start_y;
	
	return true;	
}

function gmkui_end()
{
	var wind = gmkui_current_window();

	gmkui_assert(ds_stack_size(wind.stack_id) <= 1, "gmkui_popid() missing somewhere!");

	wind.line_width = 0;
	wind.line_height = 0;
	wind.content_height = wind.cursor_y - (wind.y + wind.offset_y + gmkui_style.window_padding[1]);
	wind.depth_count = -1;
	wind.depth_hovered = -1;
	
	__gmkui_popclip();
	ds_stack_pop(gmkui.windows_stack);
}

function gmkui_draw()
{
	var stacked_id = ds_stack_top(gmkui.windows_stack);
	if (stacked_id != undefined)
	{
		var wind = gmkui_get_window(stacked_id);
		gmkui_assert(0, string("\n\nYou need use gmkui_end() at the end \"{0}\")\n\n", wind.name));
	}

	// bring current window_focus_id to front
	var index = ds_list_find_index(gmkui.windows_ordered, gmkui.window_focus_id);
	if (index != ds_list_size(gmkui.windows_ordered) - 1)
	{
		var wind = gmkui_get_window(gmkui.window_focus_id);
		gmkui_print("bringing window({0}, \"{1}\") to front", wind.id, wind.name);
		ds_list_delete(gmkui.windows_ordered, index);
		ds_list_add(gmkui.windows_ordered, gmkui.window_focus_id);
	}
	
	// draw windows
	gmkui.count_draw_calls = 0;
	// reset window_hover_id for prevent __gmkui_interact when mouse out of window
	if (gmkui.active_id == 0) { gmkui.window_hover_id = 0;}
	for (var i = 0; i < ds_list_size(gmkui.windows_ordered); ++i)
	{
		var wind = gmkui_get_window(gmkui.windows_ordered[| i]);

		if (point_in_rectangle(gmkui.mx, gmkui.my, wind.x, wind.y, wind.x + wind.w, wind.y + wind.h)) { gmkui.window_hover_id = wind.id; }
		
		__gmkui_window_draw(wind);
	}
	
	while (!ds_queue_empty(gmkui.post_draw_calls))
	{
		/// @type {Struct.__gmkui_draw_cmd}
		var draw = ds_queue_dequeue(gmkui.post_draw_calls);
		switch (draw.type)
		{
			case gmkui_draw_call_flags.rect:
				var color = draw.data[$ "color"] ?? -1;
				var alpha = draw.data[$ "alpha"] ?? 1;
				var outline = draw.data[$ "outline"] ?? false;
				__gmkui_draw_rect(draw.data.x, draw.data.y, draw.data.w, draw.data.h, color, alpha, outline);
			break;
		}
	}	
	
	gmkui.previous_hover_id = gmkui.hover_id;
	gmkui.hover_id = 0;
}

/// @param {String} text
/// @param {Any} [arg0]
/// @param {Any} [arg1]
/// @param {Any} [arg2]
/// @param {Any} [arg3]
/// @param {Any} [arg4]
function gmkui_text(text)
{	
	var wind = gmkui_current_window();

	if (argument_count > 1)
	{
		var args = [];
		for (var i = 1; i < argument_count; ++i) { array_push(args, string(argument[i])); }
		text = string_ext(text, args);
	}

	var str_w = string_width(text);
	var str_h = string_height(text);
	
	if (!__gmkui_newline(wind, str_w + gmkui_style.gap[0], str_h)) { return; }

	var x0 = wind.cursor_x;
	var y0 = wind.cursor_y;

	__gmkui_push_draw_text(floor(x0), floor(y0), text, gmkui_style.col.text);
}

function gmkui_button(label, flags=0)
{
	var wind = gmkui_current_window();
	
	var ids = __gmkui_extract_id(label);
	label = ids[0];
	
	var str_w = string_width(label);
	var str_h = string_height(label);
	
	var width = clamp(str_w + gmkui_style.button_padding[0] * 2, 0, wind.w);
	width = __gmkui_item_width(0, width);
	var height = clamp(str_h + gmkui_style.button_padding[1] * 2, 0, wind.h);

	if (!__gmkui_newline(wind, width, height)) { return false; }
	
	var x0 = wind.cursor_x;
	var y0 = wind.cursor_y;
	
	var it = gmkui_interact(ids[1], x0, y0, width, height);
	
	__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.button, { x: x0, y: y0, text: label, w: width, h: height, hovered: it.hovered, active: (it.pressed || it.held) });
	
	return it.pressed;
}

/// @param {String} label
/// @param {Struct.__gmkui_ref|Bool} ref_or_bool
function gmkui_checkbox(label, ref_or_bool)
{
	var wind = gmkui_current_window();
	
	var str_w = string_width(label);
	var str_h = string_height(label);
	
	var width = str_h + str_w + gmkui_style.gap[0] * 2;
	var height = str_h;
	
	if (!__gmkui_newline(wind, width, height)) { return false; }

	var x0 = wind.cursor_x;
	var y0 = wind.cursor_y;
	
	var it = gmkui_interact(label, x0, y0, width, height);
	
	var color = gmkui_style.col.checkbox;
	var _is_bool = is_bool(ref_or_bool);
	var checked = false;
	
	if (it.hovered) { color = gmkui_style.col.checkbox_hover; }
	if (it.held) { color = gmkui_style.col.checkbox_active; }
	if (!_is_bool)
	{
		var inv_value = ref_or_bool.get();
		if (it.pressed) { ref_or_bool.set(!inv_value); }
		checked = inv_value;
	}
	else { checked = ref_or_bool; }

	__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.checkbox, { label: label, checked: checked, x: x0, y: y0, h: height - 2, color: color });

	return it.pressed;
}

/// @param {String} label
/// @param {Struct.__gmkui_ref} ref
/// @param {Array<String>} options
function gmkui_radio(label, ref, options, flags=0)
{
	var wind = gmkui_current_window();
	
	var str_w = string_width(label);
	var str_h = string_height(label);
	var height = str_h;
	
	if (!__gmkui_newline(wind, 0, height)) { return false; }

	var size = str_h;
	
	var x0 = wind.cursor_x;
	var y0 = wind.cursor_y;
	
	var pressed = false;
	
	for (var i = 0; i < array_length(options); ++i)
	{
		var option_label = options[i];
		var option_label_w = string_width(option_label);
		var option_w = size + option_label_w + gmkui_style.gap[0] * 2; 
		
		var it = gmkui_interact(option_label + string(i), x0, y0, option_w, height);
		if (it.pressed)
		{
			ref.set(i);
			pressed = true;
		}
		
		__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.radio, { text: option_label, checked: (ref.get() == i), x: x0, y: y0, size: size });
		x0 += option_label_w + size + gmkui_style.gap[0] * 4;
	}
	
	wind.line_width += x0 - wind.cursor_x;
	
	return pressed;
}

/// @param {String} label
/// @param {Struct.__gmkui_ref} ref
/// @param {Real} value_min
/// @param {Real} value_max
/// @param {Enum.gmkui_slider_flags} flags
function gmkui_slider(label, ref, value_min, value_max, flags=gmkui_slider_flags.none)
{
	var wind = gmkui_current_window();

	var str_w = string_width(label);
	var str_h = string_height(label);

	var ids = __gmkui_extract_id(label);
	label = ids[0];

	var track_width = __gmkui_item_width(0);
	var track_height = str_h;
	var width = track_width + str_w + gmkui_style.gap[0];
	var height = track_height + gmkui_style.gap[1];
	
	if (!__gmkui_newline(wind, width, height)) { return false; }

	var is_int = (flags & gmkui_slider_flags.integer);

	var x0 = wind.cursor_x;
	var y0 = wind.cursor_y;

	var thumb_width = track_height;
	var track_passable = track_width - thumb_width;

	var d = (value_max - value_min);
	var value = ref.get();
	var offset = (value - value_min) / d * track_passable;

	/// TODO: impl value_step
	var thumb = gmkui_interact(ids[1], x0 + offset, y0, thumb_width, track_height);
	if (thumb.held)
	{
		var pos = clamp(gmkui.mx - gmkui.drag_offset_x - x0, 0, track_passable);
		value = value_min + d * (pos / track_passable);
		offset = (value - value_min) / d * track_passable;
		if (is_int) { value = round(value); }
		ref.set(value);
	}

	if (!is_int) { value = string_format(real(value), 0, 2); }
	
	__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.slider, { x: x0, y: y0, w: track_width, h: track_height, value: value, offset: offset, thumb_width: thumb_width, hover: thumb.hovered, active: thumb.held });
	__gmkui_push_draw_text(x0 + track_width + gmkui_style.gap[0], y0, label);

	return (thumb.pressed || thumb.held);
}

/// @param {String} label
/// @param {Struct.__gmkui_ref} ref
function gmkui_collapse(label, ref)
{
	var wind = gmkui_current_window();
	
	var str_w = string_width(label);
	var str_h = string_height(label);
	
	var width = wind.viewport_w;
	var height = str_h + gmkui_style.button_padding[1] * 2;
	
	if (!__gmkui_newline(wind, width, height)) { return false; }

	var x0 = wind.cursor_x;
	var y0 = wind.cursor_y;
	
	var it = gmkui_interact(label, x0, y0, width, height);
	
	if (it.pressed) { ref.set(!ref.get()); }
	
	__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.collapse, { x: x0, y: y0, w: width, h: height, open: ref.get(), text: label, hovered: it.hovered, active: (it.pressed || it.held) });

	return ref.get();
}

/// @param {Asset.GMSprite} sprite
/// @param {Real} [index] default 0
/// @param {Real} [width] default 64
/// @param {Real} [height] default 64
function gmkui_sprite(sprite, index=0, width=64, height=64)
{
	var wind = gmkui_current_window();
	
	if (!__gmkui_newline(wind, width + gmkui_style.gap[0], height)) { return; }
	
	var x0 = wind.cursor_x;
	var y0 = wind.cursor_y;
	
	var info = sprite_get_info(sprite);
	
	__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.sprite, { sprite: sprite, index: index, x: x0, y: y0, w: width, h: height });
}

function gmkui_separator(height=gmkui_style.gap[1])
{
	var wind = gmkui_current_window();
	
	wind.cursor_y += gmkui_style.gap[1];

	if (!__gmkui_newline(wind, 0, height + gmkui_style.gap[1])) { return; }

	__gmkui_push_draw_rect(
		wind.cursor_start_x,
		wind.cursor_y,
		wind.viewport_w,
		height,
		c_gray
	);
}

function gmkui_sameline()
{
	var wind = gmkui_current_window();
	
	wind.sameline = true;
}

/// @desc Set width for next item
/// @param {Real} width
function gmkui_set_width(width) { gmkui.item_width = round(width); }

/// @desc Reset previous gmkui_set_width
function gmkui_reset_width() { gmkui.item_width = 0; }

/// @desc Check if window is resized
/// @returns {Bool}
function gmkui_window_resized()
{
	var ret = (gmkui.previous_window_w != window_get_width() || gmkui.previous_window_h != window_get_height());
	if (ret)
	{
		gmkui.previous_window_w = window_get_width();
		gmkui.previous_window_h = window_get_height();
	}
	return ret;
}

// HELPERS

/// @return {Struct.__gmkui_window}
function gmkui_get_window(uid) { return gmkui.windows[? uid] ?? -1; }

/// @return {Struct.__gmkui_window}
function gmkui_get_window_by_name(name)
{
	var uid = __gmkui_hash(name, 0);
	return gmkui_get_window(uid);
}

/// @return {Struct.__gmkui_window}
function gmkui_current_window()
{
	var uid = ds_stack_top(gmkui.windows_stack);
	return ds_map_find_value(gmkui.windows, uid);
}

/// @desc Just return a hash id and don't push to stack
function gmkui_getid(str)
{
	var wind = gmkui_current_window();
	var base = 0;
	if (ds_stack_size(wind.stack_id) > 0) { base = ds_stack_top(wind.stack_id); }
	return __gmkui_hash(str, base);
}

/// @param {String} str
function gmkui_pushid(str)
{
	var wind = gmkui_current_window();
	ds_stack_push(wind.stack_id, gmkui_getid(str));
}

function gmkui_popid()
{
	var wind = gmkui_current_window();
	gmkui_assert(ds_stack_size(wind.stack_id) > 1, "Calling PopID() too many times!");
	ds_stack_pop(wind.stack_id);
}

function gmkui_next_window_id(str)
{
	gmkui.next_window_id = __gmkui_hash(str, 0);
}

/// @desc Creates a reference for widgets
/// @param {Id.Instance|Struct|Undefined} src if undefined, creates a global variable by default
/// @param {String} name field name(variable) of instance or struct
/// @param {Any} [value] default is 0
function gmkui_ref(src, name=undefined, value=0)
{
	return new __gmkui_ref(src, name, value);
}