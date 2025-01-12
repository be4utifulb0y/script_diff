require 'prefabutil'

local assets=
{
	Asset("ANIM", "anim/portal_shipwrecked.zip"),
	Asset("ANIM", "anim/portal_shipwrecked_build.zip"),
}

local prefabs = {}

local modes = {
	shipwrecked = {
		title = STRINGS.UI.SAVEINTEGRATION.SHIPWRECKED,
		body = STRINGS.UI.SAVEINTEGRATION.TRAVEL_SHIPWRECKED,
		excludeslotswith = "survival",
	},
	survival = {
		title = STRINGS.UI.SAVEINTEGRATION.SURVIVAL,
		body = STRINGS.UI.SAVEINTEGRATION.TRAVEL_SURVIVAL,
		excludeslotswith = "shipwrecked"
	}
}

local function OnActivate(inst)
    SetPause(true)

	local targetmode = SaveGameIndex:IsModeShipwrecked() and "survival" or "shipwrecked"

	local function cancel()
		SetPause(false)
		inst.components.activatable.inactive = true
	end

	local function startnextmode()
		local SaveIntegrationScreen = require "screens/saveintegrationscreen"
		local NewIntegratedGameScreen = require "screens/newintegratedgamescreen"
		
		TheFrontEnd:PopScreen()
		if not SaveGameIndex:OwnsMode(targetmode) then
			if SaveGameIndex:GetNumberOfSavesForMode(targetmode, modes[targetmode].excludeslotswith) > 0 then
				TheFrontEnd:PushScreen(SaveIntegrationScreen(targetmode, cancel))
			else
				TheFrontEnd:PushScreen(NewIntegratedGameScreen(targetmode, SaveGameIndex:GetCurrentSaveSlot(), true, cancel))
			end
		else
			TravelBetweenWorlds("shipwrecked_portal", 7.5, {"chester_eyebone", "packim_fishbone"})
		end
	end

	local title = modes[targetmode].title
	local body = modes[targetmode].body
	if not SaveGameIndex:OwnsMode(targetmode) then
		title = STRINGS.UI.SAVEINTEGRATION.WARNING
		body = string.format("%s\n%s", STRINGS.UI.SAVEINTEGRATION.EARLY_ACCESS, STRINGS.UI.SAVEINTEGRATION.MERGE_MOD_WARNING)
	end

	local BigPopupDialogScreen = require "screens/bigpopupdialog"
	
	TheFrontEnd:PushScreen(BigPopupDialogScreen(
				title, body,
				{
					{text=STRINGS.UI.SAVEINTEGRATION.YES, cb = startnextmode},
					{text=STRINGS.UI.SAVEINTEGRATION.NO, cb = function()
						TheFrontEnd:PopScreen()
						cancel()
					end}
				}))
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    MakeObstaclePhysics(inst, 1)
    local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon("shipwrecked_exit.png")

    anim:SetBank("boatportal")
    anim:SetBuild("portal_shipwrecked_build")
    anim:PlayAnimation("idle_off")

    inst:AddTag("shipwrecked_portal")

    --inst:AddComponent("inspectable")

	inst.no_wet_prefix = true

	--inst:AddComponent("activatable")
    --inst.components.activatable.OnActivate = OnActivate
    --inst.components.activatable.inactive = true
	--inst.components.activatable.quickaction = true
	
	--this is a hack to make sure these don't show up in adventure mode
	if SaveGameIndex:GetCurrentMode() == "adventure" then
		inst:DoTaskInTime(0, function() inst:Remove() end)
	end

    return inst
end

-- backwards compatability
local function exit_fn()
	local inst = fn()
	-- for the moment these two prefabs are identical, but leave them as separate prefabs in case
	-- the behaviour ever changes between SW and Forest
	return inst
end

return Prefab( "common/shipwrecked_entrance", fn, assets, prefabs),
	MakePlacer("shipwrecked_entrance_placer", "boatportal", "portal_shipwrecked_build", "idle_off"),
	Prefab( "common/shipwrecked_exit", exit_fn, assets, prefabs)
