-- src/utils/class.lua
local function include_helper(to, from, seen)
	if from == nil then return to end
	seen = seen or {}
	for k,v in pairs(from) do
		if type(v) == 'table' and not seen[v] then
			seen[v] = true
			to[k] = include_helper({}, v, seen)
		else
			to[k] = v
		end
	end
	return to
end

local function class(base)
	local c = {}
	if type(base) == 'table' then
		for i,v in pairs(base) do c[i] = v end
		c._base = base
	end
	c.__index = c
	local mt = {}
	mt.__call = function(class_tbl, ...)
		local obj = {}
		setmetatable(obj,c)
		if class_tbl.init then class_tbl.init(obj,...) end
		return obj
	end
	c.init = base and base.init
	c.is_a = function(self, klass)
		local m = getmetatable(self)
		while m do 
			if m == klass then return true end
			m = m._base
		end
		return false
	end
	setmetatable(c, mt)
	return c
end

return class