require "prefabutil"

local function onhammered(inst, worker)
	if inst:HasTag("fire") and inst.components.burnable then
		inst.components.burnable:Extinguish()
	end
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end

local function CheckRain(inst)
	if not inst:HasTag("burnt") then
	    if not inst.task then
		    inst.task = inst:DoPeriodicTask(1, CheckRain)
		end
		inst.AnimState:SetPercent("meter", GetSeasonManager():GetPOP())
	end
end



local assets = 
{
	Asset("ANIM", "anim/rain_meter.zip"),
}

local prefabs =
{
	"collapse_small",
}

local function onbuilt(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
	inst.AnimState:PlayAnimation("place")
end


local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	
	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon( "rainometer.png" )
    
    inst:AddComponent("container")
    inst.components.container:SetNumSlots(4)
    local slotpos = {	Vector3(0,64+32+8+4,0) , Vector3(0,32+4,0) ,Vector3(0,-(32+4),0) , Vector3(0,-(64+32+8+4),0)}
    inst.components.container.widgetslotpos = slotpos
    inst.components.container.widgetanimbank = "ui_cookpot_1x4"
    inst.components.container.widgetanimbuild = "ui_cookpot_1x4"
    inst.components.container.widgetpos = Vector3(180,20,0)
    inst.components.container.side_align_tip = 100
	                                            
	local widgetbuttoninfo = {
	text = "Delete",
	position = Vector3(0, -165, 0),
	fn = function(inst)
	inst.components.container:DestroyContents()
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    end }
	inst.components.container.widgetbuttoninfo = widgetbuttoninfo

	MakeObstaclePhysics(inst, .4)

	anim:SetBank("rain_meter")
	anim:SetBuild("rain_meter")
	anim:SetPercent("meter", 0)
	inst:AddTag("spoiler")
	inst:AddComponent("inspectable")
	
	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	                        
	MakeSnowCovered(inst, .01)
	inst:ListenForEvent("onbuilt", onbuilt)
	inst:ListenForEvent("animover", CheckRain)
	
	CheckRain(inst)

	inst:AddTag("structure")--0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
	
	return inst
end
return Prefab( "common/objects/rainometer", fn, assets, prefabs),
	   MakePlacer("common/rainometer_placer", "rain_meter", "rain_meter", "idle" ) 


