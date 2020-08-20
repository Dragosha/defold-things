# Simple GUI button handler

Register node with parameters:

	si.register(node, callback, value, click_cb, longtap_cb)
where 'node' is required, other parameters are optional

or register with options table:

	si.register({
		node = node name or nodeId,
		callback = .. handler function (pressed and released on this node),
		click_cb = .. (just press this node),
		longtap_cb = ..,
		value = this param will dispatch to callback functions
	})

## usage
gui_script:

	local si = require "helpers.simple_input"

	local function on_release_cb(self, value, node)
	-- press and release handler
		print(value)
		.. do something
		gui.set_enabled(node, false)
		si.unregister(node) -- unregister handler for this button only
	end

	local function on_press_cb(self, value, node)
	-- press handler
	end

	local function on_longtap_cb(self, value, node)
	-- longtap detected
	end

	function init(self)
		si.acquire()
		local value = 1
		si.register("button_name", on_release_cb, value, on_press_cb, on_longtap_cb)
		si.register("button_name2", on_release_cb, 2) -- the same handler get other value (2)
	end

	function final(self)
		si.release()
		si.unregister() -- unregister all buttons registered in this GUI script.
	end

	function on_input(self, action_id, action)
		if si.on_input(self, action_id, action) then
			return
		end
	end