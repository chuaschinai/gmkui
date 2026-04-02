#macro GMKUI_INTERACT_MAX_DEPTH 65535

/// @param {Bool} x
/// @param {String} str
function gmkui_assert(x, str) { if (!x) { show_error(str, true); } }

/// @param {String|Any} str
/// @param {Any} [arg0]
/// @param {Any} [arg1]
/// @param {Any} [arg2]
/// @param {Any} [arg3]
/// @param {Any} [arg4]
function gmkui_print(str)
{
	var args = [];
	for (var i = 1; i < argument_count; ++i) { array_push(args, string(argument[i])); }
	if (argument_count == 1)
		str = string(str);
	var date = date_time_string(date_current_datetime());
	str = string_ext("[" + date + "] (gmkui) : " + str, args);
	show_debug_message(str);
};

function __gmkui_hash(str, seed=0)
{
	// FNV-1a 32-bit
    var h = 2166136261;
    h ^= seed;

    var len = string_length(str);
    for (var i = 1; i <= len; i++) {
        var c = ord(string_char_at(str, i));
        h ^= c;
        h = (h * 16777619) mod 4294967296;
    }
    return h;
}

/// @param {Struct.__gmkui_window} wind
/// @param {Real} width
/// @param {Real} height
/// @returns {Bool} 
function __gmkui_newline(wind, width, height)
{
	var temp_sameline = wind.sameline;

	if (wind.sameline)
	{
		wind.cursor_x += wind.line_width + gmkui_style.gap[0];
		wind.sameline = false;
	} else
	{
		wind.cursor_x = wind.cursor_start_x;
		wind.cursor_y += wind.line_height + gmkui_style.gap[1];
	}
	
	wind.line_width = width;
	wind.line_height = temp_sameline ? max(height, wind.line_height) : height;
	
	return rectangle_in_rectangle(
		wind.cursor_x, wind.cursor_y,
		wind.cursor_x + width, wind.cursor_y + height,
		wind.x, wind.y,
		wind.x + wind.w, wind.y + wind.h
	);
}

/// @param {Real} width
/// @param {Real} [def_w] default 0, if width is 0
function __gmkui_item_width(width, def_w=0)
{
	if (def_w == 0)
	{
		if (width == 0)
		{
			var viewport_w = gmkui_current_window().viewport_w * 0.65;
			width = max(1, viewport_w + width);
		}
	}
	else { width = def_w; }

	if (gmkui.item_width > 0) { width = gmkui.item_width; }

	return round(width);
}

/// @param {Enum.gmkui_draw_call_flags} type
/// @param {Any} data
function __gmkui_draw_cmd(type, data) constructor
{
	self.type = type;
	self.data = data;
}

// DRAW COMMANDS

function __gmkui_push_post_draw(type, data)
{
	var cmd = new __gmkui_draw_cmd(type, data);
	ds_queue_enqueue(gmkui.post_draw_calls, cmd);
}

function __gmkui_push_draw_cmd(wind, type, data)
{
	var cmd = new __gmkui_draw_cmd(type, data);
	ds_queue_enqueue(wind.draw_calls, cmd);
}

function __gmkui_pushclip(x, y, w, h)
{
	var wind = gmkui_current_window();
	__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.push_clip, { x: x, y: y, w: w, h: h, });
}

function __gmkui_popclip()
{
	var wind = gmkui_current_window();
	__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.pop_clip, 0);
}

function __gmkui_push_draw_text(x, y, text, color=gmkui_style.col.text, halign=fa_left, valign=fa_top)
{
	var wind = gmkui_current_window();
	__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.text, { x: x, y: y, text: text, color: color, halign: halign, valign: valign });
}

function __gmkui_push_draw_rect(x, y, w, h, color=c_white, alpha=1, outline=false)
{
	var wind = gmkui_current_window();
	__gmkui_push_draw_cmd(wind, gmkui_draw_call_flags.rect, { x: x, y: y, w: w, h: h, color: color, alpha: alpha, outline: outline });
}

// DRAWS

function __gmkui_draw_rect(x, y, w, h, color=-1, alpha=1, outline=false)
{
	var backup_alpha = draw_get_alpha();
	draw_set_alpha(alpha);
	draw_rectangle_colour(x, y, x + w, y + h, color, color, color, color, outline);
	draw_set_alpha(backup_alpha);
}

function __gmkui_draw_button(x, y, w, h, text, hovered, active)
{
	var col = gmkui_style.col.button;
	var col_text = gmkui_style.col.text;
	var alpha_text = 1;
	var col_border = gmkui_style.col.border;
	
	if (hovered) { col = gmkui_style.col.button_hover; }
	if (active) { col = gmkui_style.col.button_active; }

	draw_rectangle_colour(x, y, x + w, y + h, col, col, col, col, false);
	
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_text_colour(x + round(w * 0.5), y + round(h * 0.5), text, col_text, col_text, col_text, col_text, alpha_text);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

function __gmkui_draw_titlebar(title, x, y, width, height, is_focus)
{
	var col = is_focus ? gmkui_style.col.bg_title : gmkui_style.col.bg_title_unfocused;

	draw_rectangle_colour(x, y, x + width, y + height, col, col, col, col, false);

	var temp = gpu_get_scissor();
	gpu_set_scissor(x, y, width, height);
	draw_set_valign(fa_middle);
	draw_text(x + gmkui_style.window_padding[0], y + height * 0.5, title);
	draw_set_valign(fa_top);
	gpu_set_scissor(temp);
}

function __gmkui_draw_checkbox(label, checked, x, y, height, color)
{
	__gmkui_draw_rect(x - 1, y - 1, height + 2, height + 2, gmkui_style.col.border);
	__gmkui_draw_rect(x, y, height, height, checked ? gmkui_style.col.checkbox_active : gmkui_style.col.bg_widget);
	draw_text(x + height + gmkui_style.gap[0] * 2, y, label);
}

function __gmkui_draw_radio(text, checked, x, y, size)
{
	var x0 = x + size * 0.5;
	var y0 = y + size * 0.5;
	
	var col = gmkui_style.col.bg_widget;

	if (checked) { col = gmkui_style.col.checkbox_active; }
	
	draw_circle_colour(x0, y0, size * 0.5 + 1, gmkui_style.col.border, gmkui_style.col.border, false);
	draw_circle_colour(x0, y0, size * 0.5, col, col, false);
	
	draw_text_colour(x + size + gmkui_style.gap[0] * 2, y, text, gmkui_style.col.text, gmkui_style.col.text, gmkui_style.col.text, gmkui_style.col.text, 1);
}

function __gmkui_draw_slider(x, y, w, h, value, offset, thumb_width, hovered, active)
{	
	draw_rectangle_color(x, y, x + w, y + h, gmkui_style.col.bg_widget, gmkui_style.col.bg_widget, gmkui_style.col.bg_widget, gmkui_style.col.bg_widget, false);
	
	var thumb_x = x + offset;
	var thumb_y = y;
	var thumb_col = gmkui_style.col.slider_thumb;
	if (hovered) { thumb_col = gmkui_style.col.slider_thumbHover; }
	if (active) { thumb_col = gmkui_style.col.slider_thumbActive; }
	draw_rectangle_colour(thumb_x, thumb_y, thumb_x + thumb_width, thumb_y + h, thumb_col, thumb_col, thumb_col, thumb_col, false);
	
	draw_set_halign(fa_center);
	draw_text_colour(round(x + w * 0.5), y, value, gmkui_style.col.text, gmkui_style.col.text, gmkui_style.col.text, gmkui_style.col.text, 1);
	draw_set_halign(fa_left);
}

function __gmkui_draw_collapse(x, y, w, h, open, text, hovered, active)
{
	var col = gmkui_style.col.button;
	var col_text = gmkui_style.col.text;
	var alpha_text = 1;
	var col_border = gmkui_style.col.border;
	
	if (hovered) { col = gmkui_style.col.button_hover; }
	if (active) { col = gmkui_style.col.button_active; }

	draw_rectangle_colour(x, y, x + w, y + h, col, col, col, col, false);
	var gap = gmkui_style.gap[0] * 2;

	if (open)
		draw_triangle(x + gap, y + gap, x + h - gap, y + gap, x + h * 0.5, y + h - gap, false);
	else
		draw_triangle(x + gap, y + gap, x + h - gap, y + h * 0.5, x + gap, y + h - gap, false);

	draw_set_valign(fa_middle);
	draw_text_colour(x + h, y + round(h * 0.5), text, col_text, col_text, col_text, col_text, alpha_text);
	draw_set_valign(fa_top);
}

function __gmkui_window_draw(wind)
{
	while (!ds_queue_empty(wind.draw_calls))
	{
		gmkui.count_draw_calls++;
		
		/// @type {Struct.__gmkui_draw_cmd}
		var draw = ds_queue_dequeue(wind.draw_calls);
		var data = draw.data;

		var clip, color, alpha, outline, halign, valign;

		switch (draw.type)
		{
			case gmkui_draw_call_flags.push_clip:
				clip = gpu_get_scissor();
				ds_stack_push(gmkui.clip, clip);
				gpu_set_scissor(data.x, data.y, data.w, data.h);
			break;
			
			case gmkui_draw_call_flags.pop_clip:
				clip = ds_stack_pop(gmkui.clip);
				gpu_set_scissor(clip);
			break;
			
			case gmkui_draw_call_flags.rect:
				color = data[$ "color"] ?? -1;
				alpha = data[$ "alpha"] ?? 1;
				outline = data[$ "outline"] ?? false;
				__gmkui_draw_rect(data.x, data.y, data.w, data.h, color, alpha, outline);
			break;
			
			case gmkui_draw_call_flags.sprite:
				color = data[$ "color"] ?? -1;
				alpha = data[$ "alpha"] ?? 1;
				draw_sprite_stretched_ext(data.sprite, data.index, data.x, data.y, data.w, data.h, color, alpha);
			break;
			
			case gmkui_draw_call_flags.text:
				color = data.color ?? gmkui_style.col.text;
				halign = data.halign ?? fa_left;
				valign = data.valign ?? fa_top;
				
				draw_set_colour(color);
				draw_set_halign(halign);
				draw_set_valign(valign);
				draw_text(data.x, data.y, data.text);
				draw_set_halign(fa_left);
				draw_set_valign(fa_top);
				draw_set_colour(-1);
			break;
			
			case gmkui_draw_call_flags.checkbox:
				__gmkui_draw_checkbox(data.label, data.checked, data.x, data.y, data.h, data.color);
			break;
			
			case gmkui_draw_call_flags.radio:
				__gmkui_draw_radio(data.text, data.checked, data.x, data.y, data.size);
			break;
			
			case gmkui_draw_call_flags.button:
				__gmkui_draw_button(data.x, data.y, data.w, data.h, data.text, data.hovered, data.active);
			break;
			
			case gmkui_draw_call_flags.slider:
				__gmkui_draw_slider(data.x, data.y, data.w, data.h, data.value, data.offset, data.thumb_width, data.hover, data.active);
			break;

			case gmkui_draw_call_flags.collapse:
				__gmkui_draw_collapse(data.x, data.y, data.w, data.h, data.open, data.text, data.hovered, data.active);
			break;
			
			case gmkui_draw_call_flags.titlebar:
				__gmkui_draw_titlebar(data.text, data.x, data.y, data.w, data.h, data.is_focused);
			break;
		}
	}
}

function __gmkui_state_interact() constructor
{
	self.hovered = false;
	self.pressed = false;
	self.held = false;
	self.released = false;
	self.wheel = 0;
}

/// @param {String} str_id
/// @param {Real} x
/// @param {Real} y
/// @param {Real} w
/// @param {Real} h
/// @param {Real|Undefined} [_depth]
/// @returns {Struct.__gmkui_state_interact}
function gmkui_interact(str_id, x, y, w, h, _depth=undefined, flags=gmkui_interact_flags.All)
{
	var wind = gmkui_current_window();
	
	_depth ??= ++wind.depth_count;
	
	// debug purpose
	if (gmkui.debug_interact) { __gmkui_push_post_draw(gmkui_draw_call_flags.rect, { x: x + 1, y: y + 1, w: w - 1, h: h - 1, color: c_red, outline: true, alpha: 0.5 }); }
	
	var uid = gmkui_getid(str_id);
	
	var it = new __gmkui_state_interact();

	if (!(flags & gmkui_interact_flags.out_of_window) && gmkui.window_hover_id != wind.id) { return it; }

	var hover = point_in_rectangle(gmkui.mx, gmkui.my, x, y, x + w, y + h);

	if ((flags & gmkui_interact_flags.hover) && hover)
	{
		if (_depth >= wind.depth_hovered)
		{
			wind.depth_hovered = _depth;
			gmkui.hover_id = uid;
			it.hovered = (gmkui.previous_hover_id == uid);
		}
	}

	// pressed button is processed on next frame
	if ((flags & gmkui_interact_flags.pressed) && mouse_check_button_pressed(mb_left))
	{
		if (wind.depth_hovered == _depth && gmkui.previous_hover_id == uid)
		{
			it.pressed = true;

			gmkui.active_id = uid;	
			gmkui.drag_offset_x = gmkui.mx - x;
			gmkui.drag_offset_y = gmkui.my - y;

			gmkui_print("gmkui.active_id({0}) {1}", uid, str_id);
		}
	}
	
	if (gmkui.active_id == uid)
	{
		if ((flags & gmkui_interact_flags.held) && mouse_check_button(mb_left)) { it.held = true; }
		
		if (mouse_check_button_released(mb_left))
		{
			gmkui.active_id = 0;
			it.released = true;
		}
		
		// set focus to current window
		if (gmkui.window_focus_id != wind.id)
		{
			gmkui.window_focus_id = wind.id;
			gmkui_print("gmkui.window_focus_id({0}) -> {1}", wind.id, wind.name);
		}
	}

	var wheel = mouse_wheel_up() - mouse_wheel_down();
	if ((flags & gmkui_interact_flags.wheel) && wheel != 0 && hover) { it.wheel = wheel; }
	
	return it;
}

/// @param {String} str
/// @return {Array<String>}
function __gmkui_extract_id(str)
{
	if (string_count("##", str) == 0) { return [str, str]; }
	var split = string_split(str, "##", false, 1);
	return split;
}