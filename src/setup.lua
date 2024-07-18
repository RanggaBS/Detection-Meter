for _, filename in ipairs({
	"Config",
	"DetectionMeter",
	"DSLCommandManager",
}) do
	LoadScript("src/" .. filename .. ".lua")
end

-- -------------------------------------------------------------------------- --
--                                 Attributes                                 --
-- -------------------------------------------------------------------------- --

local privateFields = {
	_INTERNAL = {
		INITIALIZED = false,

		-- Stores the installed custom camera mod
		CAMERA_MOD_INSTALLED = {
			-- [variable_name] = <boolean>

			SIMPLE_FIRST_PERSON = false,
			SIMPLE_CUSTOM_THIRD_PERSON = false,
		},

		COMMAND = {
			NAME = "detectionmeter",
			HELP_TEXT = [[detectionmeter

Usage:
  - detectionmeter <toggle> (Enable/disable the mod, where <toggle> must be "enable" or "disable")
  - detectionmeter set <pov> <toggle> (Enable/disable HUD display on specified POV, <pov> must be "fp" or "tp")]],
		},

		CONFIG = {
			FILENAME_WITH_EXTENSION = "settings.ini",
			DEFAULT_SETTING = {
				bEnabled = true,
				bEnableOnFirstPerson = true,
				bEnableOnThirdPerson = true,

				bUseStaticVisionRange = false,
				fVisionRange = 30,
				fFadingDistanceOffset = 10,

				sWidgetImgPath = "assets/images/meter_frame.png",
				fWidgetHeightNormalized = 0.1,
				bUsePixelOnWidgetHeight = false,
				fWidgetHeightInPixel = 100,
				fCenterOffsetX = 0,
				fCenterOffsetY = 0,
				fRadiusX = 300,
				fRadiusY = 300,
				fColorTransitionSpeed = 3,
			},
		},

		INSTANCE = {
			---@type Config
			Config = nil,

			---@type DetectionMeter
			DetectionMeter = nil,
		},
	},
}

-- -------------------------------------------------------------------------- --
--                           Private Static Methods                           --
-- -------------------------------------------------------------------------- --

function privateFields._RegisterCommand()
	local command = privateFields._INTERNAL.COMMAND
	local instance = privateFields._INTERNAL.INSTANCE

	---@param value string
	---@param thingName string
	---@return boolean
	local function checkIfArgSpecified(value, thingName)
		if not value or value == "" then
			PrintError(thingName .. " didn't specified.")
			return false
		end
		return true
	end

	---@param value string
	---@return boolean
	local function isFirstArgValid(value)
		if not checkIfArgSpecified(value, "Action Type") then
			return false
		end

		if
			not ({
				["enable"] = true,
				["disable"] = true,
				["set"] = true,
			})[string.lower(value)]
		then
			PrintError('Allowed Action Type are "enable"|"disable"|"set".')
			return false
		end

		return true
	end

	---@param value string
	---@return boolean
	local function isSecondArgValid(value)
		if not checkIfArgSpecified(value, "Setting Key") then
			return false
		end

		if not ({ ["fp"] = true, ["tp"] = true })[string.lower(value)] then
			PrintError('Available Setting Key are "fp"|"tp".')
			return false
		end

		return true
	end

	---@param value string
	---@return boolean
	local function isThirdArgValid(value)
		if not checkIfArgSpecified(value, "Setting Value") then
			return false
		end

		if not ({ ["enable"] = true, ["disable"] = true })[string.lower(value)] then
			PrintError('Setting Value must be "enable" or "disable".')
			return false
		end

		return true
	end

	if DSLCommandManager.IsAlreadyExist(command.NAME) then
		DSLCommandManager.Unregister(command.NAME)
	end

	DSLCommandManager.Register(command.NAME, function(...)
		local actionType = arg[1]
		local pov = arg[2]
		local toggle = arg[3]

		if not isFirstArgValid(actionType) then
			return
		end

		actionType = string.lower(arg[1])

		if actionType == "enable" or actionType == "disable" then
			DETECTION_METER.SetEnabled(actionType == "enable")
			print("Detection Meter: Mod " .. actionType .. "d.")

		-- actionType == "set"
		else
			-- Grouping matter, really.. (I just know)

			-- This will call both function to make sure the result of `and`.
			-- if not isSecondArgValid(pov) and not isThirdArgValid(toggle) then

			-- But this doesn't
			if not (isSecondArgValid(pov) and isThirdArgValid(toggle)) then
				return
			end

			instance.DetectionMeter:SetEnabledOnPOV(pov, toggle == "enable")
			print(
				string.format(
					"Detection Meter: HUD display %sd on %s POV.",
					toggle,
					pov == "fp" and "First Person" or "Custom Third Person"
				)
			)
		end
	end, {
		rawArgument = false,
		helpText = command.HELP_TEXT,
	})
end

---@return boolean isFPInstalled, boolean isCTPInstalled
function privateFields.CheckInstalledCameraMod()
	---@type [boolean, boolean] { fp, tp }
	local camMods = {}

	-- Check the installed camera mod
	for index, varName in pairs({
		"SIMPLE_FIRST_PERSON",
		"SIMPLE_CUSTOM_THIRD_PERSON",
	}) do
		local var = _G[varName]

		if
			type(var) == "table"
			and type(var.GetSingleton) == "function"
			and type(var.GetSingleton()) == "table"
		then
			camMods[index] = true
		end
	end

	return unpack(camMods)
end

-- -------------------------------------------------------------------------- --
--                               Global Variable                              --
-- -------------------------------------------------------------------------- --

-- Hide keys from `pairs()`
-- And define global variable

privateFields.__index = privateFields

_G.DETECTION_METER = setmetatable({
	-- Mod version
	VERSION = "1.0.0",

	DATA = {
		-- The core mod state. This can be toggled only via console.
		IS_ENABLED = true,
	},
}, privateFields)

-- -------------------------------------------------------------------------- --
--                            Public Static Methods                           --
-- -------------------------------------------------------------------------- --

local internal = DETECTION_METER._INTERNAL
local instance = internal.INSTANCE

---@return DetectionMeter
function DETECTION_METER.GetSingleton()
	if not instance.DetectionMeter then
		local conf = instance.Config

		---@type DetectionMeter_ActivationOptions
		local activationOptions = {
			enableOnFirstPerson = conf:GetSettingValue("bEnableOnFirstPerson") --[[@as boolean]],
			enableOnThirdPerson = conf:GetSettingValue("bEnableOnThirdPerson") --[[@as boolean]],
		}

		---@type DetectionMeter_WidgetOptions
		local widgetOptions = {
			imgPath = conf:GetSettingValue("sWidgetImgPath") --[[@as string]],
			heightNormalized = conf:GetSettingValue("fWidgetHeightNormalized") --[[@as number]],
			usePixelUnit = conf:GetSettingValue("bUsePixelOnWidgetHeight") --[[@as boolean]],
			heightInPixel = conf:GetSettingValue("fWidgetHeightInPixel") --[[@as number]],
		}

		---@type DetectionMeter_DrawingOptions
		local drawingOptions = {
			centerOffset = {
				conf:GetSettingValue("fCenterOffsetX") --[[@as number]],
				conf:GetSettingValue("fCenterOffsetY") --[[@as number]],
			},
			radius = {
				conf:GetSettingValue("fRadiusX") --[[@as number]],
				conf:GetSettingValue("fRadiusY") --[[@as number]],
			},
			colorTransitionSpeed = conf:GetSettingValue("fColorTransitionSpeed") --[[@as number]],
		}

		---@type DetectionMeter_StealthOptions
		local stealthOptions = {
			useStaticVisionRange = conf:GetSettingValue("bUseStaticVisionRange") --[[@as boolean]],
			visionRange = conf:GetSettingValue("fVisionRange") --[[@as number]],
			fadingDistanceOffset = conf:GetSettingValue("fFadingDistanceOffset") --[[@as number]],
		}

		instance.DetectionMeter = DetectionMeter.new(
			activationOptions,
			widgetOptions,
			drawingOptions,
			stealthOptions
		)

		-- Apply settings
		instance.DetectionMeter:SetEnabledOnPOV(
			"fp",
			conf:GetSettingValue("bEnableOnFirstPerson") --[[@as boolean]]
		)
		instance.DetectionMeter:SetEnabledOnPOV(
			"tp",
			conf:GetSettingValue("bEnableOnThirdPerson") --[[@as boolean]]
		)
	end

	return instance.DetectionMeter
end

function DETECTION_METER.Init()
	if not internal.INITIALIZED then
		local camMods = internal.CAMERA_MOD_INSTALLED
		camMods.SIMPLE_FIRST_PERSON, camMods.SIMPLE_CUSTOM_THIRD_PERSON =
			DETECTION_METER.CheckInstalledCameraMod()

		instance.Config = Config.new(
			"src/" .. internal.CONFIG.FILENAME_WITH_EXTENSION,
			internal.CONFIG.DEFAULT_SETTING
		)

		instance.DetectionMeter = DETECTION_METER.GetSingleton()

		DETECTION_METER._RegisterCommand()

		DETECTION_METER.DATA.IS_ENABLED =
			instance.Config:GetSettingValue("bEnabled") --[[@as boolean]]

		internal.INITIALIZED = true
	end
end

---@return string
function DETECTION_METER.GetVersion()
	return DETECTION_METER.VERSION
end

---@return boolean
function DETECTION_METER.IsInstalled()
	return true
end

---@return boolean
function DETECTION_METER.IsEnabled()
	return DETECTION_METER.DATA.IS_ENABLED
end

---@param enable boolean
function DETECTION_METER.SetEnabled(enable)
	DETECTION_METER.DATA.IS_ENABLED = enable
end
