-- -------------------------------------------------------------------------- --
--                                  Structure                                 --
-- -------------------------------------------------------------------------- --

---@alias TextureAlignmentHorizontal "LEFT"|"CENTER"|"RIGHT"
---@alias TextureAlignmentVertical "TOP"|"MIDDLE"|"BOTTOM"
---@alias TextureAlignment [ TextureAlignmentHorizontal, TextureAlignmentVertical ]

---@class Texture
---@field private __index Texture
---@field texture userdata
---@field aspectRatio number
---@field displayAspectRatio number
---@field pos ArrayOfNumbers2D
---@field alignment TextureAlignment
---@field size ArrayOfNumbers2D
---@field color ArrayOfNumbers4D
Texture = {
	-- ---@diagnostic disable-next-line: assign-type-mismatch
	-- texture = nil,
	-- aspectRatio = 0,
	-- displayAspectRatio = 0,
	-- pos = { 0, 0 },
	-- size = { 0.1, 0.1 },
	-- color = { 255, 255, 255, 255 },
}
Texture.__index = Texture

-- -------------------------------------------------------------------------- --
--                                 Constructor                                --
-- -------------------------------------------------------------------------- --

---@param source string
---@param props? { position?: ArrayOfNumbers2D, size?: ArrayOfNumbers2D, color?: ArrayOfNumbers4D, alignment?: TextureAlignment }
---@return Texture
function Texture.create(source, props)
	local instance = setmetatable({}, Texture)

	instance.texture = CreateTexture(source)

	instance.alignment = { "LEFT", "TOP" }
	instance.aspectRatio = GetTextureAspectRatio(instance.texture)
	instance.displayAspectRatio = GetTextureDisplayAspectRatio(instance.texture)
	instance.pos = { 0, 0 }
	instance.size = { 0.1, 0.1 }
	instance.color = { 255, 255, 255, 255 }

	if props then
		if props.alignment then
			for i, _ in ipairs(instance.alignment) do
				instance.alignment[i] = props.alignment[i] or instance.alignment[i]
			end
		end

		if props.position then
			instance.pos = props.position
		end
		if props.size then
			instance.size = props.size
		end
		if props.color then
			instance.color = props.color
		end
	end

	return instance
end

-- -------------------------------------------------------------------------- --
--                                   Method                                   --
-- -------------------------------------------------------------------------- --

---@return userdata
function Texture:GetTexture()
	return self.texture
end

---@return TextureAlignmentHorizontal, TextureAlignmentVertical
function Texture:GetAlignment()
	return self.alignment[1], self.alignment[2]
end

---@param horizontal TextureAlignmentHorizontal
---@param vertical TextureAlignmentVertical
function Texture:SetAlignment(horizontal, vertical)
	self.alignment[1] = horizontal
	self.alignment[2] = vertical
end

---@return number
function Texture:GetAspectRatio()
	return self.aspectRatio
end

---@return number
function Texture:GetDisplayAspectRatio()
	return self.displayAspectRatio
end

---@return number x, number y
function Texture:GetPosition()
	return self.pos[1], self.pos[2]
end

---@param x number
---@param y number
function Texture:SetPosition(x, y)
	self.pos[1], self.pos[2] = x, y
end

---@return number width
---@return number height
function Texture:GetSize()
	return self.size[1], self.size[2]
end

---@param width? number
---@param height? number
function Texture:SetSize(width, height)
	self.size[1] = width and width or self.size[1]
	self.size[2] = height and height or self.size[2]
end

---@return number red
---@return number green
---@return number blue
---@return number alpha
function Texture:GetColor()
	return self.color[1], self.color[2], self.color[3], self.color[4]
end

---@param red? number
---@param green? number
---@param blue? number
---@param alpha? number
function Texture:SetColor(red, green, blue, alpha)
	self.color[1] = red and red or self.color[1]
	self.color[2] = green and green or self.color[2]
	self.color[3] = blue and blue or self.color[3]
	self.color[4] = alpha and alpha or self.color[4]
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function Texture:SetBounds(x1, y1, x2, y2)
	SetTextureBounds(self.texture, x1, y1, x2, y2)
end

---@return number width
---@return number height
function Texture:GetResolution()
	return GetTextureResolution(self.texture)
end

-- Local shared variables
local x, y = 0, 0

function Texture:Draw()
	x = self.pos[1]
	if self.alignment[1] == "CENTER" then
		x = x - (self.size[1] / 2)
	elseif self.alignment[1] == "RIGHT" then
		x = x - self.size[1]
	end

	y = self.pos[2]
	if self.alignment[2] == "MIDDLE" then
		y = y - (self.size[2] / 2)
	elseif self.alignment[2] == "BOTTOM" then
		y = y - self.size[2]
	end

	DrawTexture(
		self.texture,
		x,
		y,
		self.size[1],
		self.size[2],
		self.color[1],
		self.color[2],
		self.color[3],
		self.color[4]
	)
end

---Draw the texture with the origin on the center of the texture, with
---specified rotation (in degrees)
---@param rotation number
function Texture:DrawWithRotation(rotation)
	x = self.pos[1]
	if self.alignment[1] == "LEFT" then
		x = x + (self.size[1] / 2)
	elseif self.alignment[1] == "RIGHT" then
		x = x - (self.size[1] / 2)
	end

	y = self.pos[2]
	if self.alignment[2] == "TOP" then
		y = y + (self.size[2] / 2)
	elseif self.alignment[2] == "BOTTOM" then
		y = y - (self.size[2] / 2)
	end

	DrawTexture2(
		self.texture,
		x,
		y,
		self.size[1],
		self.size[2],
		rotation,
		self.color[1],
		self.color[2],
		self.color[3],
		self.color[4]
	)
end
