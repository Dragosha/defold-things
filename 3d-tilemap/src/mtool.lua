local mtool = {}

-- 
function mtool.create_mesh_from_tilemap(mesh_url, options)
	assert(options)
	assert(options.tilemap, "You must set 'tilemap' url")
	assert(options.layer, "You must set a tilemap 'layer' name")
	assert(options.w)
	assert(options.h)

	local bx, by, bw, bh = tilemap.get_bounds(options.tilemap)
	local by2 = by+bh-1
	local bx2 = bx+bw-1
	local res = go.get(mesh_url, "vertices")
	
	local tile_indices = {} -- map of tile(x,y) to quad index in stream buffers
	local tindex = 0
	local num_quads = 0

	-- buffers
	local positions = {}
	local normals = {}
	local texcoords = {}
	local colors = {}

	--   1 Quad == 2 triangles == 6 vertices, normal vector looks to us
	--   D-<----C
	--   |    / |
	--   | 2 /  |
	--   |  / 1 |
	--   | /    | 
	--   A-->---B

	--   UV texture coordinates
	--   1
	--   ^ V
	--   |
	--   |
	--   |       U
	--   0-------> 1
	local texcoord0 = {
		0.00001, 0.00001,
		0.99999, 0.00001,
		0.99999, 0.99999,
		0.00001, 0.00001,
		0.99999, 0.99999,
		0.00001, 0.99999
	}
	
	-- a box has 6 edges
	-- 1 is front edge, 2 - top, etc.
	--    [2]
	-- [4][1][5][6]
	--    [3]
	--  Box vertices position (1 unit scale):
	local position = {
		{
		vmath.vector3(0, 0, 0),	vmath.vector3(1, 0, 0), vmath.vector3(1, 1, 0),
		vmath.vector3(0, 0, 0),	vmath.vector3(1, 1, 0),	vmath.vector3(0, 1, 0) },
		{
		vmath.vector3(0, 1, 0),	vmath.vector3(1, 1, 0), vmath.vector3(1, 1, -1),
		vmath.vector3(0, 1, 0),	vmath.vector3(1, 1, -1), vmath.vector3(0, 1, -1) },
		{
		vmath.vector3(0, 0, -1), vmath.vector3(1, 0, -1), vmath.vector3(1, 0, 0),
		vmath.vector3(0, 0, -1), vmath.vector3(1, 0, 0), vmath.vector3(0, 0, 0) },
		{
		vmath.vector3(0, 0, -1), vmath.vector3(0, 0, 0), vmath.vector3(0, 1, 0),
		vmath.vector3(0, 0, -1), vmath.vector3(0, 1, 0), vmath.vector3(0, 1, -1) },
		{
		vmath.vector3(1, 0, 0),	vmath.vector3(1, 0, -1), vmath.vector3(1, 1, -1),
		vmath.vector3(1, 0, 0),	vmath.vector3(1, 1, -1), vmath.vector3(1, 1, 0) },
		{
		vmath.vector3(1, 0, -1), vmath.vector3(0, 0, -1), vmath.vector3(0, 1, -1),
		vmath.vector3(1, 0, -1), vmath.vector3(0, 1, -1),vmath.vector3(1, 1, -1) }
	}
	-- normals by edges:
	local norm = {
		vmath.vector3(0, 0, 1),
		vmath.vector3(0, 1, 0),
		vmath.vector3(0, -1, 0),
		vmath.vector3(-1, 0, 0),
		vmath.vector3(1, 0, 0),
		vmath.vector3(0, 0, -1)
	}

	-- for debug
	-- local quat = vmath.quat_rotation_y(math.pi/2)
	-- for i = 1, 6 do	print(vmath.rotate(quat, position[1][i])) end
	

	-- create geometry 
	local index = 0
	local scale = options.tilesize or 1
	local index2 = 0
	local index4 = 0
	local xoff = 1 / options.w
	local yoff = 1 / options.h

	local u_x = 1 
	local u_y = 1
	local check_texture_mapping = options.texture
	if check_texture_mapping then
		u_x = 1 / (options.texture.width or 1)
		u_y = 1 / (options.texture.height or 1)
	end

	for y = by, by2 do
		for x = bx, bx2 do
			local tileno = tilemap.get_tile(options.tilemap, options.layer, x, y)
			if tileno and tileno>0 then

				local tile_info = options.tile_info and options.tile_info[tileno] or nil
				if options.tile_info_fn then
					tile_info = options.tile_info_fn(tileno, x, y)
				end
				
				tile_indices[tindex] = {}
				for edge = 1, 6 do
					local skip = false

					-- culling hidden faces (edges)
					if edge == 6 and options.optimize_back then
						skip = true
					elseif options.optimize then
					 	if edge == 5 and x + 1 <= bx2 then
							local tn = tilemap.get_tile(options.tilemap, options.layer, x + 1, y)
							if tn and tn > 0 then skip = true end
						elseif edge == 4 and x - 1 >= bx then
							local tn = tilemap.get_tile(options.tilemap, options.layer, x - 1, y)
							if tn and tn > 0 then skip = true end
						elseif edge == 2 and y + 1 <= by2 then
							local tn = tilemap.get_tile(options.tilemap, options.layer, x, y + 1)
							if tn and tn > 0 then skip = true end
						elseif edge == 3 and y - 1 >= by then
							local tn = tilemap.get_tile(options.tilemap, options.layer, x, y - 1)
							if tn and tn > 0 then skip = true end
						end
					end
					
					if not skip then
						
						-- if provided users tilenumber for this edge then use it
						if tile_info then
							tileno = tile_info[edge] 
						end
						
						local U = xoff * ((tileno - 1)%options.w)
						local V = 1 - yoff * (math.floor((tileno - 1)/options.h)+1)
						local U2 = xoff
						local V2 = yoff
						
						-- If there is a texture coordinates for present tile - use it.
						if check_texture_mapping then
							local tex = options.texture[tileno]
							if tex then
								U = u_x * tex.x
								V = 1 - u_y * (tex.y + tex.h)
								V2 = u_y * tex.h
								U2 = u_x * tex.w
							end
						end
					
						local p = position[edge]
						local n = norm[edge]
						-- 6 vertices per one quad
						for i = 0, 5 do
							-- fill position buffer
							local v = p[i+1] * 1.01 -- < a small scale factor for reduce box' border artefacts
							positions[index + 1] = x * scale + (v.x - 1) * scale
							positions[index + 2] = y * scale + (v.y - 1) * scale
							positions[index + 3] = v.z * scale 

							-- fill normals
							normals[index + 1] = n.x
							normals[index + 2] = n.y
							normals[index + 3] = n.z
						
							index = index + 3

							-- fill UV texture coorinates
							texcoords[index2 + 1] = U + texcoord0[i*2 + 1]*U2
							texcoords[index2 + 2] = V + texcoord0[i*2 + 2]*V2
			
							index2 = index2 + 2
							
							-- fill colors, RGBA, you may use it in vertex/fragment shaders
							colors[index4 + 1] = 1
							colors[index4 + 2] = 1
							colors[index4 + 3] = 1
							colors[index4 + 4] = 1
						
							index4 = index4 + 4
						end
						-- 
						tile_indices[tindex][edge] = num_quads  -- store (mapping) number of created quad by index(coord)
						num_quads = num_quads + 1
					end
				end
			else
				tile_indices[tindex] = -1
			end
			tindex = tindex + 1
		end
	end

	print("Created quads:", num_quads, "Tilemap bx, by, bw, bh:", bx, by, bw, bh)

	-- calculate numbers of vertices for creating a mesh buffer
	local num_vertices = 6 * num_quads

	-- create a new buffer, since the one in the resource doesn't have enough size
	local new_buffer = buffer.create(num_vertices, {
		{ name = hash("position"), type = buffer.VALUE_TYPE_FLOAT32, count = 3 },
		{ name = hash("normal"), type = buffer.VALUE_TYPE_FLOAT32, count = 3 },
		{ name = hash("texcoord0"), type = buffer.VALUE_TYPE_FLOAT32, count = 2 },
		{ name = hash("color0"), type = buffer.VALUE_TYPE_FLOAT32, count = 4 }
	})
	
	-- get streams
	local stream_position = buffer.get_stream(new_buffer, "position")
	local stream_normal = buffer.get_stream(new_buffer, "normal")
	local stream_texcoord0 = buffer.get_stream(new_buffer, "texcoord0")
	local stream_color0 = buffer.get_stream(new_buffer, "color0")
	
	-- fill streams
	local len = #colors
	for i = 1, len do stream_color0[i] = colors[i] end
	len = #positions
	for i = 1, len do stream_position[i] = positions[i] end
	len = #texcoords
	for i = 1, len do stream_texcoord0[i] = texcoords[i] end
	len = #normals
	for i = 1, len do stream_normal[i] = normals[i] end

	-- set buffers to resource (mesh)
	resource.set_buffer(res, new_buffer)

	-- save origin values
	local obj={}
	obj.cols = bw
	obj.rows = bh
	obj.tile_indices = tile_indices
	obj.x_off = bx
	obj.y_off = by
	obj.mesh_url = mesh_url
	obj.num_vertices = num_vertices
	obj.num_quads = num_quads
	obj.cell_size = scale

	-- Not sure why we can't use stream_color0, but for correct works with buffer values
	-- in the runtime we need to get buffers again.
	local res = go.get(mesh_url, "vertices")
	local buf = resource.get_buffer(res)
	local color0 = buffer.get_stream(buf, "color0")

	obj.color0 = color0
	obj.color0_origin = {}
	local len = #color0
	for i = 1, len do obj.color0_origin[i] = color0[i] end

	
	---------------------------------------------------------------------------------
	-- Utility methods.
	-- 
	-- Returns indices table for quads on x, y. Or '-1' if no indices found or out of the range.
	function obj.quad_index(x, y)
		if x < obj.x_off or y < obj.y_off or x >= obj.x_off + obj.cols  or  y >= obj.y_off + obj.rows then
			return -1
		end
		local index = (y - obj.y_off)*obj.cols + (x - obj.x_off)
		return obj.tile_indices[index]
	end

	-- Convert world 'x' to tilemap coords.
	function obj.world_to_map_X(value)
		return math.floor(value / obj.cell_size) + 1
	end
	
	-- Convert world 'y' to tilemap coords.
	function obj.world_to_map_Y(value)
		return math.floor(value / obj.cell_size) + 1
	end

	return obj
end

---------------------------------------------------------------------------------
-- Set original colors to all verticies.
function mtool.reset_color(mesh)
	for i = 1, #mesh.color0 do 		mesh.color0[i] = mesh.color0_origin[i] end
end

-- Coloring quads.
-- @table mesh object created mtool.create_mesh_from_tilemap()
-- @param number x coord in tilemap
-- @param number y coord in tilemap
-- @param vector4 rgba
-- Returns 'true' if found quads on x,y. Or 'false' if a mesh has no quads in these coords.
function mtool.coloring_quad(mesh, x, y, rgba)

	local color0 = mesh.color0
	local R,G,B,A = 1, 2, 3, 4
	local quad_index = mesh.quad_index(x, y)
	if not quad_index or quad_index == -1 then return false end
	for index, value in pairs(quad_index) do
		local index = value*6*4 -- 6*4 sizeof of colors for 1 quad
		for v = 0, 5 do
			color0[index+v*4+R] = rgba.x or mesh.color0_origin[index+v*4+R]
			color0[index+v*4+G] = rgba.y or mesh.color0_origin[index+v*4+G]
			color0[index+v*4+B] = rgba.z or mesh.color0_origin[index+v*4+B]
			color0[index+v*4+A] = rgba.w or mesh.color0_origin[index+v*4+A]
		end
	end
	return true

end


return mtool