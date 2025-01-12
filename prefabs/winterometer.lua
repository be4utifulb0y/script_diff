require "prefabutil"

local function CheckTemp(inst)
	if not inst:HasTag("burnt") then
	    if not inst.task then
		    inst.task = inst:DoPeriodicTask(1, CheckTemp)
		end
			local temp = GetSeasonManager() and GetSeasonManager():GetCurrentTemperature() or 30
			local high_temp = TUNING.OVERHEAT_TEMP
			local low_temp = 0
			
			temp = math.min( math.max(low_temp, temp), high_temp)
			local percent = (temp + low_temp) / (high_temp - low_temp)
			inst.AnimState:SetPercent("meter", 1-percent)

	end
end

local function onhammered(inst, worker)

	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end



local function onbuilt(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
	inst.AnimState:PlayAnimation("place")

end

local assets = 
{
	Asset("ANIM", "anim/winter_meter.zip"),
}

local prefabs =
{
	"collapse_small",
}



local function itemtest(inst, item, slot)
	if item.prefab == "goldnugget" then
		return true
	end
	return false
end

local slotpos = {}

for y = 0, 2 do
	table.insert(slotpos, Vector3(-162, -y*75 + 75 ,0))
	table.insert(slotpos, Vector3(-162 +75, -y*75 + 75 ,0))
end

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	
	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon( "winterometer.png" )
    
	MakeObstaclePhysics(inst, .4)
    
	anim:SetBank("winter_meter")
	anim:SetBuild("winter_meter")
	anim:SetPercent("meter", 0)

	inst:AddComponent("inspectable")
	
    inst:AddComponent("container")
    inst.components.container:SetNumSlots(#slotpos)
    inst.components.container.widgetslotpos = slotpos
    inst.components.container.widgetanimbank = "ui_icepack_2x3"
    inst.components.container.widgetanimbuild = "ui_icepack_2x3"
    inst.components.container.widgetpos = Vector3(0,200,0) 
    inst.components.container.side_align_tip = 160
    inst.components.container.itemtestfn = itemtest

	inst:ListenForEvent( "daytime", function()
		local num_found = 0
		for k,v in pairs(inst.components.container.slots) do
			num_found = num_found + v.components.stackable:StackSize()
		end
		local Interests = math.floor(num_found/100*3)
		for k = 1, Interests do
			inst.components.container:ConsumeByName("goldnugget", -1)
        end
	end, GetWorld())   
	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	
	CheckTemp(inst)

	inst:ListenForEvent("onbuilt", onbuilt)
	inst:ListenForEvent("animover", CheckTemp)

inst:AddTag("structure")--000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

	return inst
end
return Prefab( "common/objects/winterometer", fn, assets, prefabs),
	   MakePlacer("common/winterometer_placer", "winter_meter", "winter_meter", "idle" ) 


