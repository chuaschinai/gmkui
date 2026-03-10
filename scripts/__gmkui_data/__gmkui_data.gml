// GameMakerUI v1.0.0 - by chuas

// global context
function __gmkui() constructor
{
	self.windows = ds_map_create();
	self.windows_stack = ds_stack_create();
	self.windows_ordered = ds_list_create();
	self.draw_calls = ds_queue_create();
	self.post_draw_calls = ds_queue_create();
	self.clip = ds_stack_create();
	self.mx = 0;
	self.my = 0;
	self.window_hover_id = 0;
	self.window_focus_id = 0;
	self.count_draw_calls = 0;
	self.previous_hover_id = 0;
	self.hover_id = 0;
	self.active_id = 0;
	self.drag_offset_x = 0;
	self.drag_offset_y = 0;
	self.item_width = 0;
	self.previous_window_w = window_get_width();
	self.previous_window_h = window_get_height();
	self.debug_interact = false;
}

global.__ggmkui = new __gmkui(); #macro gmkui global.__ggmkui

// defaul theme
function __gmkui_dark() constructor
{
	self.gap = [2, 2];
	self.window_padding = [4, 4];
	self.button_padding = [4, 2];
	self.title_height = 24;
	
	self.col = {
		background: #282828,
		border: #464646,
		bg_widget: #181818,

		button: #363636,
		button_hover: #346EEB,
		button_active: #8CB0FF,
		button_disabled: #242424,

		checkbox: #363636,
		checkbox_hover: #346EEB,
		checkbox_active: #8CB0FF,
		checkbox_disabled: #1A1A1A,
		
		slider_thumb: #363636,
		slider_thumbHover: #346EEB,
		slider_thumbActive: #8CB0FF,
		
		bg_title: #346EEB,
		bg_title_hover: #346EEB,
		bg_title_active: #8CB0FF,
		bg_title_unfocused: #363636,
		
		text: #F8F8F8,
		text_inv: #C0C0C0
	}
}

global.__gmkui_style = new __gmkui_dark(); #macro gmkui_style global.__gmkui_style

function __gmkui_window(id, name, x, y) constructor
{
	self.id = id;
	self.name = name;
	self.x = x;
	self.y = y;
	self.w = 0;
	self.h = 0;
	self.last_height = 0;
	self.viewport_w = 0;
	self.viewport_h = 0;
	self.cursor_start_x = 0;
	self.cursor_start_y = 0;
	self.cursor_x = 0;
	self.cursor_y = 0;
	self.line_width = 0;
	self.line_height = 0;
	self.sameline = false;
	self.hidden = false;
	self.offset_y = 0;
	self.scrollbar_y = 0;
	self.content_height = 0; // total content size widgets and gaps
	
	static depth_count = -1; // increment for gmkui_interact(...)
	static depth_hovered = -1; // store current interact depth
	
	self.draw_calls = ds_queue_create();
}

/// @param {Id.Instance|Struct|Undefined} src
/// @param {String} name
/// @param {Any} value
function __gmkui_ref(src, name, value) constructor
{
	self.data = src;
	self.name = name;
	self.type = typeof(src);
	
	if (typeof(src) == "ref")
	{
		if (string_count("instance", src) != 0) { self.type = "instance"; }
	}
	
	switch (self.type)
	{
		case "instance": if (!variable_instance_exists(self.data, self.name)) { variable_instance_set(self.data, self.name, value); } break;
		case "struct": if (!variable_struct_exists(self.data, self.name)) { variable_struct_set(self.data, self.name, value); } break;
	}

	static set = function(value)
	{
		switch (self.type)
		{
			case "instance": variable_instance_set(self.data, self.name, value); break;
			case "struct": struct_set(self.data, self.name, value); break;
		}
	}

	static get = function()
	{
		switch (self.type)
		{
			case "instance": return variable_instance_get(self.data, self.name);
			case "struct": return struct_get(self.data, self.name);
		}
	}
}

enum gmkui_draw_call_flags
{
	// gpu
	push_clip,
	pop_clip,
	// basic
	line,
	text,
	rect,
	sprite,
	// prefabs
	button,
	checkbox,
	radio,
	slider,
	collapse,
	titlebar
};

// WIDGET FLAGS

/// @TODO: impl
// enum gmkui_widget_flags
// {
// 	none = 0,
// 	disabled = 1,
// }

/// @TODO: impl
// enum gmkui_button_flags
// {
// 	none = 0,
// 	left,
// 	right,
// 	middle
// }

enum gmkui_window_flags
{
	none = 0,
	no_move = 1,
	no_title = 2
}

enum gmkui_slider_flags
{
	none = 0,
	integer = 1
}

enum gmkui_interact_flags
{
	none = 0,
	hover = 1,
	pressed = 2,
	held = 4,
	wheel = 8,
	All = 15,
	out_of_window = 16 // interacts with the window even when outside
}