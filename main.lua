--[[
	A modification script for Bully SE game

	Mod name: Detection Meter
	Author: RBS ID

	Requirements:
		- Derpy's Script Loader v7 or greater
]]

-- Header

RequireLoaderVersion(7)

-- -------------------------------------------------------------------------- --
--                                 Entry Point                                --
-- -------------------------------------------------------------------------- --

function main()
	while not SystemIsReady() do
		Wait(0)
	end

	-- Wait a milisecond to let other scripts to load first
	Wait(0)

	--[[ if not DETECTION_METER.CheckInstalledCameraMod() then
		error(
			"No custom camera mod installed.\nYou need to install at least either"
				.. ' "Simple First Person Camera" or "Simple Custom Third Person Camera"'
				.. " or both are fine."
		)
	end ]]

	LoadScript("src/setup.lua")

	local MOD = DETECTION_METER

	MOD.Init()

	LoadScript("src/hook.lua")

	local dm = MOD.GetSingleton()

	while true do
		Wait(0)

		if MOD.IsEnabled() then
			if dm:IsEnabledOnPOV("fp") or dm:IsEnabledOnPOV("tp") then
				dm:CheckForInsertWidgetTrigger()
				dm:ProcessWidgets()
			end
		end
	end
end
