local M = {}
-- ## usage
-- local rnd2 = require "helper.rnd2"
-- ...
-- thor = rnd2.create(11) -- set 11% probability 
-- if thor.get() then 
-- 		do something...
-- end

function M.create(probability)
	local rnd = {}

	function rnd.init(probability)
		rnd.mass = {}
		if probability < 1 then
			probability = math.floor(probability * 100)
		else
			probability = math.floor(probability)
		end
		rnd.probability = probability
		for i = 1, probability do table.insert(rnd.mass, 1) end
		for i = 1, 100-probability do table.insert(rnd.mass, 0) end
	end
	rnd.init(probability)

	function rnd.get()
		local num = math.random(1, #rnd.mass)
		local el = table.remove(rnd.mass, num)
		if #rnd.mass == 0 then rnd.init(rnd.probability) end
		-- pprint(rnd.mass)
		return el == 1
	end

	return rnd
end

return M
