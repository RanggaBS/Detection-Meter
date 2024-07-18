for _, filename in ipairs({ "utils", "UI/base/Texture", "UI/base/Text" }) do
	LoadScript("src/" .. filename .. ".lua")
end

--[[ 
	The `self.widgets` table structure
	{ [pedId] = WidgetMeterAuthority }

	Widget State v1 (previous idea)
	-- 1: red - being chased
	-- 2: orange - getting spotted
	-- 3: yellow - getting closer
	-- 4: white - there's an authority nearby
	-- 5: fade - fade in if getting closer, fade out if moving away

	Widget State v2 (current)
	-- 1: red - punishment points > 200 AND being chased by authority
	-- 2: orange - punishment points > 100 AND being chased by authority
	-- 3: yellow - punishment points > 0 AND being chased by authority
	-- 4: white - punishment points > 0 AND there's an authority nearby
	-- 5: fade - fade in if getting closer, fade out if moving away

	Widget State v3 (very current) (not sure..)
	1: red - (punishment points > 200 AND being chased by authority) OR other NPC attacking player
	2: ...
]]

-- -------------------------------------------------------------------------- --
--                                    Types                                   --
-- -------------------------------------------------------------------------- --

---@alias WidgetMeter_ColorIndividual { value: number, nextValue: number, startTime: number }
---@alias WidgetMeter_Color [ WidgetMeter_ColorIndividual, WidgetMeter_ColorIndividual, WidgetMeter_ColorIndividual,WidgetMeter_ColorIndividual ]

---@alias DetectionMeter_Widget { pedType: "normal"|"mission", visionRange: number, state: 1|2|3|4|5, color: ArrayOfNumbers4D, targetColor: ArrayOfNumbers4D }

---@alias DetectionMeter_ActivationOptions { enableOnFirstPerson: boolean, enableOnThirdPerson: boolean }
---@alias DetectionMeter_WidgetOptions { imgPath: string, heightNormalized: number, usePixelUnit: boolean, heightInPixel: number }
---@alias DetectionMeter_DrawingOptions { centerOffset: ArrayOfNumbers2D, radius: ArrayOfNumbers2D, colorTransitionSpeed: number }
---@alias DetectionMeter_StealthOptions { useStaticVisionRange: boolean, visionRange: number, fadingDistanceOffset: number }

-- -------------------------------------------------------------------------- --

---@class DetectionMeter
---@field private __index DetectionMeter
---@field private _isSimpleFirstPersonInstalled boolean
---@field private _isSimpleCustomThirdPersonInstalled boolean
---@field private _simpleFPInstance SimpleFirstPerson
---@field private _simpleTPInstance SimpleCustomThirdPerson
---@field private _enableOnFirstPerson boolean
---@field private _enableOnThirdPerson boolean
---@field yaw number The value is obtained from main camera mod (Simple FP or Simple Custom TP), in radians.
---@field textureInstance Texture
---@field widgets DetectionMeter_Widget[]
---@field centerOffset2d ArrayOfNumbers2D
---@field radius2d ArrayOfNumbers2D
---@field colorTransitionSpeed number
---@field useStaticVisionRange boolean
---@field staticVisionRange number
---@field fadingDistanceOffset number
DetectionMeter = {}
DetectionMeter.__index = DetectionMeter

-- -------------------------------------------------------------------------- --
--                                 Constructor                                --
-- -------------------------------------------------------------------------- --

---@param activationOptions DetectionMeter_ActivationOptions
---@param widgetOptions DetectionMeter_WidgetOptions
---@param drawingOptions DetectionMeter_DrawingOptions
---@param stealthOptions DetectionMeter_StealthOptions
---@return DetectionMeter
function DetectionMeter.new(
	activationOptions,
	widgetOptions,
	drawingOptions,
	stealthOptions
)
	-- Check required mod installation

	DetectionMeter._isSimpleFirstPersonInstalled = false
	DetectionMeter._isSimpleCustomThirdPersonInstalled = false
	DetectionMeter._simpleFPInstance = nil
	DetectionMeter._simpleTPInstance = nil
	DetectionMeter._CheckRequiredMod()

	local instance = setmetatable({}, DetectionMeter)

	-- Instance variables initialization

	instance._enableOnFirstPerson = activationOptions.enableOnFirstPerson
	instance._enableOnThirdPerson = activationOptions.enableOnThirdPerson
	if
		instance._enableOnFirstPerson
		and not DetectionMeter._isSimpleFirstPersonInstalled
	then
		PrintWarning(
			'`bEnableOnFirstPerson` is set to `true` while "Simple First Person"'
				.. " is not installed."
		)
	end
	if
		instance._enableOnThirdPerson
		and not DetectionMeter._isSimpleCustomThirdPersonInstalled
	then
		PrintWarning(
			'`bEnableOnThirdPerson` is set to `true` while "Simple Custom Third'
				.. ' Person Camera" is not installed.'
		)
	end

	instance.yaw = 0

	instance.widgets = {}

	-- Stealth

	instance.useStaticVisionRange = stealthOptions.useStaticVisionRange
	instance.staticVisionRange = stealthOptions.visionRange
	instance.fadingDistanceOffset = stealthOptions.fadingDistanceOffset

	-- Widget texture

	instance.textureInstance = Texture.create(widgetOptions.imgPath)
	instance.textureInstance:SetAlignment("CENTER", "MIDDLE")
	if widgetOptions.usePixelUnit then
		instance.textureInstance:SetSize(
			UTIL.PixelToNormalized(widgetOptions.heightInPixel, "height")
				* instance.textureInstance:GetDisplayAspectRatio(),
			UTIL.PixelToNormalized(widgetOptions.heightInPixel, "height")
		)
	else
		instance.textureInstance:SetSize(
			widgetOptions.heightNormalized
				* instance.textureInstance:GetDisplayAspectRatio(),
			widgetOptions.heightNormalized
		)
	end

	-- Drawing options

	instance.centerOffset2d = drawingOptions.centerOffset
	instance.radius2d = drawingOptions.radius
	instance.radius2d[1] =
		UTIL.PixelToNormalized(drawingOptions.radius[1], "width")
	instance.radius2d[2] =
		UTIL.PixelToNormalized(drawingOptions.radius[2], "height")
	instance.colorTransitionSpeed = drawingOptions.colorTransitionSpeed

	return instance
end

-- -------------------------------------------------------------------------- --
--                         Local variables & functions                        --
-- -------------------------------------------------------------------------- --

-- ------------------------- _ProcessAndDrawWidget() ------------------------ --

---@param widget DetectionMeter_Widget
---@param red number
---@param green number
---@param blue number
---@param alpha number
local function SetWidgetTargetColor(widget, red, green, blue, alpha)
	widget.targetColor[1] = red
	widget.targetColor[2] = green
	widget.targetColor[3] = blue
	widget.targetColor[4] = alpha
end

---@param widget DetectionMeter_Widget
---@param valueChange number
local function IncrementOrDecrementCurrentColor(widget, valueChange)
	for i = 1, 4 do
		if widget.targetColor[i] < widget.color[i] then
			widget.color[i] = UTIL.Clamp(widget.color[i] - valueChange, 0, 255)
		elseif widget.targetColor[i] > widget.color[i] then
			widget.color[i] = UTIL.Clamp(widget.color[i] + valueChange, 0, 255)
		end
	end
end

---@param widget DetectionMeter_Widget
---@param points number
local function SetWidgetStateColorBasedOnPunishmentPoints(widget, points)
	if points > 200 then
		widget.state = 5
		SetWidgetTargetColor(widget, 255, 0, 0, 255)
	elseif points > 100 then
		widget.state = 4
		SetWidgetTargetColor(widget, 255, 127.5, 0, 255)
	elseif points > 0 then
		widget.state = 3
		SetWidgetTargetColor(widget, 255, 255, 0, 255)
	end
end

local visionRange = 0

local distance = 0
local centerOffset2d = { 0, 0 }
local radius2d = { 0, 0 }
local widgetPos2d = { 0, 0 }
local alphaLerpValue = 0

-- ---------------------------- ProcessWidgets() ---------------------------- --

local playerPos2d = { 0, 0 }
local pedPos2d = { 0, 0 }
local direction, angleDiff = 0, 0

---@param self DetectionMeter
---@return boolean
local function IsFirstPersonEnabled(self)
	return self._isSimpleFirstPersonInstalled --[[@diagnostic disable-line]]
		and self:IsEnabledOnPOV("fp")
		and self._simpleFPInstance:IsEnabled() --[[@diagnostic disable-line]]
end

---@param self DetectionMeter
---@return boolean
local function IsThirdPersonEnabled(self)
	return self._isSimpleCustomThirdPersonInstalled --[[@diagnostic disable-line]]
		and self:IsEnabledOnPOV("tp")
		and self._simpleTPInstance:IsEnabled() --[[@diagnostic disable-line]]
end

-- -------------------------------------------------------------------------- --
--                                   Methods                                  --
-- -------------------------------------------------------------------------- --

-- ----------------------------- Private Static ----------------------------- --

---@return boolean
function DetectionMeter._CheckSimpleFirstPersonInstalled()
	if type(_G.SIMPLE_FIRST_PERSON) == "table" then
		return true
	end
	return false
end

---@return boolean
function DetectionMeter._CheckSimpleCustomThirdPersonInstalled()
	if type(_G.SIMPLE_CUSTOM_THIRD_PERSON) == "table" then
		return true
	end
	return false
end

function DetectionMeter._CheckRequiredMod()
	if DetectionMeter._CheckSimpleFirstPersonInstalled() then
		DetectionMeter._isSimpleFirstPersonInstalled = true
		DetectionMeter._simpleFPInstance = _G.SIMPLE_FIRST_PERSON.GetSingleton()
		print('"Simple First Person" mod installed.')
	end
	if DetectionMeter._CheckSimpleCustomThirdPersonInstalled() then
		DetectionMeter._isSimpleCustomThirdPersonInstalled = true
		DetectionMeter._simpleTPInstance =
			_G.SIMPLE_CUSTOM_THIRD_PERSON.GetSingleton()
		print('"Simple Custom Third Person" mod installed.')
	end
	if
		not DetectionMeter._isSimpleFirstPersonInstalled
		and not DetectionMeter._isSimpleCustomThirdPersonInstalled
	then
		error(
			'Missing required mod: "Simple First Person" or "Simple Custom Third'
				.. ' Person".'
		)
	end
end

-- --------------------------- Private Non-static --------------------------- --

---@param ped integer
---@param angleDiff2 number
function DetectionMeter:_ProcessAndDrawWidget(ped, angleDiff2)
	visionRange = self.useStaticVisionRange and self.staticVisionRange
		or UTIL.GetPedVisionRange(ped)
	distance = DistanceBetweenPeds3D(gPlayer, ped)

	if distance < visionRange + self.fadingDistanceOffset then
		-- Color determination
		if UTIL.PedIsChasingPlayer(ped) then
			SetWidgetStateColorBasedOnPunishmentPoints(
				self.widgets[ped],
				PlayerGetPunishmentPoints()
			)

		-- If not being chased
		else
			if
				(
					self.widgets[ped].pedType == "normal"
					and PlayerGetPunishmentPoints() > 0
				) or self.widgets[ped].pedType == "mission"
			then
				if distance < visionRange then
					self.widgets[ped].state = 2
					SetWidgetTargetColor(self.widgets[ped], 255, 255, 255, 255)

				-- Fading in/out
				else
					alphaLerpValue = UTIL.Clamp(
						(distance - visionRange)
							/ ((visionRange + self.fadingDistanceOffset) - visionRange),
						0,
						1
					)

					SetWidgetTargetColor(
						self.widgets[ped],
						255,
						255,
						255,
						UTIL.LerpOptimized(255, 0, alphaLerpValue)
					)
				end

			-- If punishment point is zero
			else
				if self.widgets[ped].pedType == "normal" then
					self.widgets[ped] = nil
				end

				-- No need to continue to draw the widget
				return
			end
		end

		-- Increment/decrement the color values if the state changes
		IncrementOrDecrementCurrentColor(
			self.widgets[ped],
			self.colorTransitionSpeed
		)

		-- Calculate center offset position
		centerOffset2d[1] = 0.5 + self.centerOffset2d[1]
		centerOffset2d[2] = 0.5 + self.centerOffset2d[2]

		-- Calculate orbit distance from center point (direction * radius)
		radius2d[1] = math.sin(angleDiff2) * self.radius2d[1]
		radius2d[2] = -math.cos(angleDiff2) * self.radius2d[2]

		-- Calculate the widget position
		widgetPos2d[1] = centerOffset2d[1] + radius2d[1]
		widgetPos2d[2] = centerOffset2d[2] + radius2d[2]

		-- Finally, draw the widget
		self:_DrawWidget(widgetPos2d, self.widgets[ped].color, math.deg(angleDiff2))

	-- If distance >= vision range + fading offset
	else
		if self.widgets[ped].pedType == "normal" then
			self.widgets[ped] = nil
		end
	end
end

function DetectionMeter:ProcessWidgets()
	if IsFirstPersonEnabled(self) or IsThirdPersonEnabled(self) then
		for ped, _ in pairs(self.widgets) do
			if PedIsValid(ped) and not PedIsDead(ped) then
				playerPos2d[1], playerPos2d[2] = PlayerGetPosXYZ()
				pedPos2d[1], pedPos2d[2] = PedGetPosXYZ(ped)
				direction =
					math.atan2(pedPos2d[2] - playerPos2d[2], pedPos2d[1] - playerPos2d[1])
				angleDiff = UTIL.FixRadians(self:GetYaw() - direction)

				self:_ProcessAndDrawWidget(ped, angleDiff)

			-- If ped is not exist or knocked out
			else
				self.widgets[ped] = nil
			end
		end
	end
end

-- This is the game's default minimum distance to start displaying vision yaw
-- on the radar. Inclusive, meaning `dist <= 40`, not `dist < 40`.
-- local MIN_DISTANCE = 40

function DetectionMeter:CheckForInsertWidgetTrigger()
	for _, ped in { PedFindInAreaXYZ(0, 0, 0, 99999) } do
		if PedIsValid(ped) and ped ~= gPlayer and not PedIsDead(ped) then
			if
				not self:IsWidgetExistWithPed(ped)
				and UTIL.PedIsAuthority(ped)
				and PlayerGetPunishmentPoints() > 0
			then
				distance = DistanceBetweenPeds2D(gPlayer, ped)
				visionRange = self.useStaticVisionRange and self.staticVisionRange
					or UTIL.GetPedVisionRange(ped)

				if distance < visionRange + self.fadingDistanceOffset then
					---@type DetectionMeter_Widget
					local widget = {
						pedType = "normal",
						visionRange = visionRange,
						state = 1,
						color = { 255, 255, 255, 0 },
						targetColor = { 255, 255, 255, 0 },
					}
					self:InsertWidget(ped, widget)
				end
			end
		end
	end
end

---@param pos ArrayOfNumbers2D
---@param color ArrayOfNumbers4D
---@param rot number in degrees
function DetectionMeter:_DrawWidget(pos, color, rot)
	self.textureInstance:SetPosition(unpack(pos))
	self.textureInstance:SetColor(unpack(color))
	self.textureInstance:DrawWithRotation(rot)
end

-- ---------------------------- Public Non-static --------------------------- --

-- Utility methods

---@return number
function DetectionMeter:GetYaw()
	if IsFirstPersonEnabled(self) then
		self.yaw = self._simpleFPInstance:GetYaw()
	elseif IsThirdPersonEnabled(self) then
		self.yaw = self._simpleTPInstance:GetYaw()
	end

	return self.yaw
end

---@param pov "fp"|"tp"
---@return boolean
function DetectionMeter:IsEnabledOnPOV(pov)
	local key = pov == "fp" and "_enableOnFirstPerson" or "_enableOnThirdPerson"
	return self[key]
end

---@param pov "fp"|"tp"
---@param enable boolean
function DetectionMeter:SetEnabledOnPOV(pov, enable)
	local key = pov == "fp" and "_enableOnFirstPerson" or "_enableOnThirdPerson"
	self[key] = enable
end

---@param ped integer
---@return boolean
function DetectionMeter:IsWidgetExistWithPed(ped)
	return type(self.widgets[ped]) == "table"
end

---@param ped integer
---@param widget DetectionMeter_Widget
function DetectionMeter:InsertWidget(ped, widget)
	self.widgets[ped] = widget
end

---@param ped integer
function DetectionMeter:DeleteWidget(ped)
	self.widgets[ped] = nil
end

---@return integer[] peds
function DetectionMeter:GetAllWidgetPeds()
	local peds, count = {}, 1
	for ped, _ in pairs(self.widgets) do
		peds[count] = ped
		count = count + 1
	end
	return peds
end
