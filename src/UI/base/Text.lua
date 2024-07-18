-- -------------------------------------------------------------------------- --
--                        Utilities / Helper Functions                        --
-- -------------------------------------------------------------------------- --

---@param word string
---@return string
local function CapitalizeFirstLetter(word)
	return string.upper(string.sub(word, 1, 1))
		.. string.sub(word, 2, string.len(word))
end

---@param pixel number
---@param size "width"|"height"
---@return number
function PixelToNormalized(pixel, size)
	local screenWidth, screenHeight = GetScreenResolution()
	return pixel / (size == "width" and screenWidth or screenHeight)
end

-- -------------------------------------------------------------------------- --
--                                    Types                                   --
-- -------------------------------------------------------------------------- --

---@alias Text_AlignmentHorizontal "CENTER"|"LEFT"|"RIGHT"
---@alias Text_AlignmentVertical "TOP"|"CENTER"|"BOTTOM"
---@alias Text_Alignment [ Text_AlignmentHorizontal, Text_AlignmentVertical ]
-- ---@alias Text_Black boolean?
-- ---@alias Text_Bold boolean?
---@alias Text_Clipping ArrayOfNumbers2DOptional
-- ---@alias Text_Color ArrayOfNumbers4DOptional
-- ---@alias Text_Font string
-- ---@alias Text_Height number?
-- ---@alias Text_Scale number
-- ---@alias Text_Text string
-- ---@alias Text_Outline ArrayOfNumbers3D
-- ---@alias Text_Position ArrayOfNumbers2D
---@alias Text_RedrawingMode "RESIZE"|"ALWAYS"|"NEEDED"
---@alias Text_Shadow ArrayOfNumbers3DOptional
---@alias Text_Wrapping number?

---@alias Text_FormattingTable table

---@alias Text_Options { align?: Text_Alignment, black?: boolean, bold?: boolean, clipping?: Text_Clipping, color?: ArrayOfNumbers4D, color?: ArrayOfNumbers4D, font?: string, height?: number, italic: boolean, outline?: ArrayOfNumbers3D, position?: ArrayOfNumbers2D, redrawing: Text_RedrawingMode, scale?: number, shadow?: ArrayOfNumbers3D, wrapping?: number }

-- -------------------------------------------------------------------------- --
--                            Attributes & Methods                            --
-- -------------------------------------------------------------------------- --

---@class Text
---@field private __index Text
---@field private _formatting table
---@field text string
---@field align Text_Alignment
---@field black boolean
---@field bold boolean
---@field clipping ArrayOfNumbers2DOptional
---@field color ArrayOfNumbers4D
---@field font string
---@field height number
---@field italic boolean
---@field private _isOutlineEnabled boolean
---@field outline? ArrayOfNumbers3D
---@field position ArrayOfNumbers2D
---@field redrawing Text_RedrawingMode
---@field scale number
---@field private _isShadowEnabled boolean
---@field shadow? ArrayOfNumbers3D
---@field wrapping number
Text = {
	-- Define keys to allow iterate using `pairs()` inside methods.
	--[[ text = "",

	align = { "LEFT", "TOP" },
	bold = false,
	black = false,
	clipping = { nil, nil },
	color = { 0, 0, 0, 0 },
	font = "Arial",
	height = PixelToNormalized(16, "height"),
	outline = { 0, 0, 0 },
	position = { 0, 0 },
	scale = 1,
	shadow = { 0, 0, 0 },
	wrapping = 0, ]]
}
Text.__index = Text

-- -------------------------------------------------------------------------- --
--                                 Constructor                                --
-- -------------------------------------------------------------------------- --

---@param text string
---@param options? Text_Options
function Text.new(text, options)
	local instance = setmetatable({}, Text)

	instance._formatting = {}

	instance.text = text

	instance.align = { "LEFT", "TOP" }
	instance.black = false
	instance.bold = false
	instance.clipping = { nil, nil }
	instance.color = { 0, 0, 0, 255 }
	instance.font = "Arial"
	instance.height = PixelToNormalized(16, "height")
	instance.italic = false
	instance._isOutlineEnabled = false
	instance.outline = { 0, 0, 0 }
	instance.position = { 0, 0 }
	instance.redrawing = "RESIZE"
	instance.scale = 1
	instance._isShadowEnabled = false
	instance.shadow = { 0, 0, 0 }
	instance.wrapping = 0

	-- Overwrite above default values
	if options then
		for key, value in pairs(options) do
			instance[key] = value or instance[key]
		end
	end

	return instance
end

-- -------------------------------------------------------------------------- --
--                                   Methods                                  --
-- -------------------------------------------------------------------------- --

---@return string
function Text:GetText()
	return self.text
end

---@param text string
function Text:SetText(text)
	self.text = text
end

---@param horizontal? Text_AlignmentHorizontal
---@param vertical? Text_AlignmentVertical
function Text:SetAlignment(horizontal, vertical)
	self.align[1] = horizontal or self.align[1]
	self.align[2] = vertical or self.align[2]
end

---@return Text_AlignmentHorizontal, Text_AlignmentVertical
function Text:GetAlignment()
	return self.align[1], self.align[2]
end

---@return boolean
function Text:IsBlack()
	return self.black
end

---@param bool boolean
function Text:SetBlack(bool)
	self.black = bool
end

---@return boolean
function Text:IsBold()
	return self.bold
end

---@param bool boolean
function Text:SetBold(bool)
	self.bold = bool
end

---@return number?, number?
function Text:GetClipping()
	return self.clipping[1], self.clipping[2]
end

---@param maxWidth number?
---@param maxHeight number?
function Text:SetClipping(maxWidth, maxHeight)
	self.clipping[1] = maxWidth
	self.clipping[2] = maxHeight
end

---@return number red, number green, number blue, number alpha
function Text:GetColor()
	return self.color[1], self.color[2], self.color[3], self.color[4]
end

---@param red? number
---@param green? number
---@param blue? number
---@param alpha? number
function Text:SetColor(red, green, blue, alpha)
	self.color[1] = red or self.color[1]
	self.color[2] = green or self.color[2]
	self.color[3] = blue or self.color[3]
	self.color[4] = alpha or self.color[4]
end

---@return string
function Text:GetFont()
	return self.font
end

---@param fontName string
function Text:SetFont(fontName)
	self.font = fontName
end

---@return number
function Text:GetHeight()
	return self.height
end

---@param height number
function Text:SetHeight(height)
	self.height = height
end

---@return boolean
function Text:IsItalic()
	return self.italic
end

---@param enable boolean
function Text:SetItalic(enable)
	self.italic = enable
end

---@return number red, number green, number blue
function Text:GetOutline()
	return self.outline[1], self.outline[2], self.outline[3]
end

---@param enable boolean
---@param red? number
---@param green? number
---@param blue? number
function Text:SetOutline(enable, red, green, blue)
	self._isOutlineEnabled = enable

	if enable then
		self.outline[1] = red or self.outline[1]
		self.outline[2] = green or self.outline[2]
		self.outline[3] = blue or self.outline[3]
	end
end

---@return number x, number y
function Text:GetPosition()
	return self.position[1], self.position[2]
end

---@param x number
---@param y number
function Text:SetPosition(x, y)
	self.position[1] = x
	self.position[2] = y
end

---@return Text_RedrawingMode
function Text:GetRedrawing()
	return self.redrawing
end

---@param redrawingMode Text_RedrawingMode
function Text:SetRedrawing(redrawingMode)
	self.redrawing = redrawingMode
end

---@return number
function Text:GetScale()
	return self.scale
end

---@param scale number
function Text:SetScale(scale)
	self.scale = scale
end

---@return number red, number green, number blue
function Text:GetShadow()
	return self.shadow[1], self.shadow[2], self.shadow[3]
end

---@param enable boolean
---@param red? number
---@param green? number
---@param blue? number
function Text:SetShadow(enable, red, green, blue)
	self._isShadowEnabled = enable

	if enable then
		self.shadow[1] = red or self.shadow[1]
		self.shadow[2] = green or self.shadow[2]
		self.shadow[3] = blue or self.shadow[3]
	end
end

---@return table
function Text:GetFormatting()
	return GetTextFormatting()
end

---@return table
function Text:PopFormatting()
	return PopTextFormatting()
end

---@param textFormatting table
function Text:SetFormatting(textFormatting)
	return SetTextFormatting(textFormatting)
end

local keys = {
	"align",
	"black",
	"bold",
	"clipping",
	"color",
	"font",
	"height",
	"italic",
	"outline",
	"position",
	"redrawing",
	"scale",
	"shadow",
	"wrapping",
}
function Text:Draw()
	-- for key, value in pairs(self) do -- hidden, not work. Must direct access using dot (.)

	for _, key in ipairs(keys) do
		if
			(key == "outline" and self._isOutlineEnabled)
			or (key == "shadow" and self._isShadowEnabled)
			or (key ~= "outline" and key ~= "shadow")
		then
			local value

			if type(self[key]) == "table" then
				value = { unpack(self[key]) }
			else
				value = { self[key] }
			end

			_G["SetText" .. CapitalizeFirstLetter(key)](unpack(value))
		end
	end

	DrawText(self.text)
end

-- -------------------------------------------------------------------------- --
--                                    Test                                    --
-- -------------------------------------------------------------------------- --

-- function Text:_test()
-- 	for key, value in pairs(self) do
-- 		print(key, value)
-- 	end
-- end

-- local a = Text.new("Boo!")

-- print("pairs()")
-- for key, value in pairs(a) do
-- 	print(key, value)
-- end
-- print("direct", a.text)

-- for key, value in pairs(Text) do
-- 	print(key, value)
-- end
