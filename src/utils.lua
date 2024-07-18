-- -------------------------------------------------------------------------- --
--                        Utilities / Helper Functions                        --
-- -------------------------------------------------------------------------- --

UTIL = {}

---@param value number
---@param min number
---@param max number
---@return number
function UTIL.Clamp(value, min, max)
	return value < min and min or value > max and max or value
end

--[[ ---@param value number
---@param min number
---@param max number
---@param ifmin number
---@param ifmax number
---@return number
function Clamp2(value, min, max, ifmin, ifmax)
	return value < min and ifmin or value > max and ifmax or value
end ]]

---@param radians number
---@return number
function UTIL.FixRadians(radians)
	while radians > math.pi do
		radians = radians - math.pi * 2
	end
	while radians < -math.pi do
		radians = radians + math.pi * 2
	end
	return radians
end

---@param a number
---@param b number
---@param t number
---@return number
function Lerp(a, b, t)
	return a + (b - a) * t
end

local DIGITS_PRECISION_TOLERANCY = 0.01
---@param a number
---@param b number
---@param t number
---@return number
function UTIL.LerpOptimized(a, b, t)
	local lerp = Lerp(a, b, t)

	if b < 0 then
		-- if (-v < -b) && (-v > -b) - 0.01
		if lerp < b and lerp > b - DIGITS_PRECISION_TOLERANCY then
			return b

		-- if (-v > -b) && (-v < -b) + 0.01
		elseif lerp > b and lerp < b + DIGITS_PRECISION_TOLERANCY then
			return b
		end
	--
	elseif b > 0 then
		-- if (v < b) && (v > b) - 0.01
		if lerp < b and lerp > b - DIGITS_PRECISION_TOLERANCY then
			return b

		-- if (v > b) && (v < b) + 0.01
		elseif lerp > b and lerp < b + DIGITS_PRECISION_TOLERANCY then
			return b
		end
	end

	return lerp
end

---@param ped integer
---@return boolean
function UTIL.PedIsChasingPlayer(ped)
	return PedIsInCombat(ped) and PedGetTargetPed(ped) == gPlayer
end

---@param pixel number
---@param size "width"|"height"
---@return number
function UTIL.PixelToNormalized(pixel, size)
	local screenWidth, screenHeight = GetScreenResolution()
	return pixel / (size == "width" and screenWidth or screenHeight)
end

---Reference:
---[Code](https://help.interfaceware.com/v6/extract-a-filename-from-a-file-path),
---[Regex](https://onecompiler.com/lua/3zzskbj4q)
---@param path string
---@return string
function GetFilenameWithExtensionFromPath(path)
	local startIndex, _ = string.find(path, "[^%\\/]-$")
	---@diagnostic disable-next-line: param-type-mismatch
	return string.sub(path, startIndex, string.len(path))
end

local PREFECT_MODEL_ID = {
	[49] = true,
	[50] = true,
	[51] = true,
	[52] = true,
}
function UTIL.PedIsSchoolPrefect(ped)
	return PREFECT_MODEL_ID[PedGetModelId(ped)] == true
end

local AUTHORITY_FACTION = {
	[0] = true,
	[7] = true,
	[8] = true,
}
---@param ped integer
---@return boolean
function UTIL.PedIsAuthority(ped)
	return AUTHORITY_FACTION[PedGetFaction(ped)] == true
		or UTIL.PedIsSchoolPrefect(ped)
end

---@param word string
---@return string
function CapitalizeFirstLetter(word)
	return string.upper(string.sub(word, 1, 1))
		.. string.sub(word, 2, string.len(word))
end

local VISION_RANGE_STAT_ID = 3
local WORLD_VISION_RANGE_MULTIPLIER = 2.5
---@param ped integer
---@return number
function UTIL.GetPedVisionRange(ped)
	return GameGetPedStat(ped, VISION_RANGE_STAT_ID) --[[@as number]]
		* (AreaGetVisible() == 0 and WORLD_VISION_RANGE_MULTIPLIER or 1)
end
