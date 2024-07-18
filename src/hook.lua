local dm = DETECTION_METER.GetSingleton()

HookFunction("PedSetIsStealthMissionPed", function(args, results, isReplacement)
	local ped = args[1]
	local isStealthMission = args[2]

	-- print("ped name: ", PedGetName(ped))
	-- print("isStealthMission: ", isStealthMission)

	if isStealthMission and PedIsValid(ped) and not PedIsDead(ped) then
		dm:InsertWidget(ped, {
			pedType = "mission",
			state = 1,
			color = { 255, 255, 255, 0 },
			targetColor = { 255, 255, 255, 0 },
		})
	else
		dm:DeleteWidget(ped)
	end
end)

HookFunction("PedSetStealthBehavior", function(args, results, isReplacement)
	local ped = args[1]
	local behaviourEnum = args[2]
	local callback1 = args[3]
	local callback2 = args[4]

	-- print("ped name: ", PedGetName(ped))
	-- print("[HOOK] PedSetStealthBehavior()")
	-- print("behavior: ", behaviourEnum)

	if --[[ behaviourEnum == 1 and ]]
		PedIsValid(ped) and not PedIsDead(ped)
	then
		dm:InsertWidget(ped, {
			pedType = "mission",
			state = 1,
			color = { 255, 255, 255, 0 },
			targetColor = { 255, 255, 255, 0 },
		})
	else
		dm:DeleteWidget(ped)
	end
end)

--[[ HookFunction("PedOverrideStat", function(args, results, isReplacement)
	local ped = args[1]
	local statId = args[2]
	local statValue = args[3]

	local VISION_RANGE_STAT_ID = 3

	if statId == VISION_RANGE_STAT_ID and dm:IsWidgetExistWithPed(ped) then
		--dm.widgets[ped]
	end
end) ]]
