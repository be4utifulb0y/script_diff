local BigPopupDialogScreen = require "screens/bigpopupdialog"
local SaveIntegrationScreen = require "screens/saveintegrationscreen"
local NewIntegratedGameScreen = require "screens/newintegratedgamescreen"

local assets=
{
    Asset("ANIM", "anim/portal_shipwrecked.zip"),
    Asset("ANIM", "anim/portal_shipwrecked_build.zip"),
}

local function OnActivate(inst)
	SetPause(true)

	local function leaveshipwrecked()

        if not SaveGameIndex:OwnsMode("survival") then
            if SaveGameIndex:GetNumberOfSavesForMode("survival", "shipwrecked") > 0 then
                TheFrontEnd:PushScreen(SaveIntegrationScreen("survival"))
            else
                TheFrontEnd:PushScreen(NewIntegratedGameScreen("survival", SaveGameIndex:GetCurrentSaveSlot(), true))
            end
        else

            GetPlayer().components.inventory:DropItemBySlot(GetPlayer().components.inventory:GetItemSlotByName("packim_fishbone"))

            GetClock():SetDepartureDay(GetPlayer().components.age:GetAge())
            SaveGameIndex:SetSaveClockData(GetPlayer())
            SaveGameIndex:SetSaveSeasonData(GetPlayer())
            SaveGameIndex:SetSaveVolcanoData(GetPlayer())
            SaveGameIndex:SetSaveHoundedData(GetPlayer())

            local function onsaved()
                TheFrontEnd:PopScreen()
                SetPause(false)
                StartNextInstance({reset_action=RESET_ACTION.LOAD_SLOT, save_slot = SaveGameIndex:GetCurrentSaveSlot()}, true)
            end

            local function onenter()
                SaveGameIndex:SaveCurrent(function() SaveGameIndex:LeaveShipwrecked(onsaved) end)
            end
            SetPause(false)
            TheFrontEnd:PopScreen()
            GetPlayer().HUD:Hide()
            GetPlayer():PushEvent("shipwrecked_portal")
            inst:DoTaskInTime(7.5, function()
                TheFrontEnd:Fade(false, 3, function() onenter() end)
            end)
        end
	end

	local function stayshipwrecked()
        TheFrontEnd:PopScreen()
        SetPause(false) 
        inst.components.activatable.inactive = true
	end

    local warning_str = STRINGS.UI.SAVEINTEGRATION.EARLY_ACCESS

    if not SaveGameIndex:OwnsMode("survival") then
        warning_str = warning_str .. "\n" .. STRINGS.UI.SAVEINTEGRATION.MERGE_MOD_WARNING
    end

    TheFrontEnd:PushScreen(BigPopupDialogScreen(STRINGS.UI.SAVEINTEGRATION.WARNING, warning_str,
            {{text=STRINGS.UI.SAVEINTEGRATION.UNDERSTOOD, cb = leaveshipwrecked},
             {text=STRINGS.UI.SAVEINTEGRATION.CANCEL, cb = stayshipwrecked}  }))
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    MakeObstaclePhysics(inst, 1.5)

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("shipwrecked_exit.png")
    
    inst:AddTag("shipwrecked_portal")

    anim:SetBank("boatportal")
    anim:SetBuild("portal_shipwrecked_build")
    anim:PlayAnimation("idle_off")
    print("HERE")

    --inst:AddComponent("inspectable")

	--inst:AddComponent("activatable")
    --inst.components.activatable.OnActivate = OnActivate
    --inst.components.activatable.inactive = true
	--inst.components.activatable.quickaction = true

    return inst
end

return Prefab( "common/shipwrecked_exit", fn, assets) 
