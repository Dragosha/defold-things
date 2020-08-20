# Guaranteed random
The method returns 'true' in cases setted as probability value in 100 cases. 
And returns 'false' in (100 - probability value) cases.

## usage
	local rnd2 = require "helpers.rnd2"
	...
	local foo = rnd2.create(11) -- set 11% probability 
	local foo = rnd2.create(0.11) -- the same
	if foo.get() then
		-- do something...
	end