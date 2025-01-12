require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/coldfirepit.zip"),
}

local prefabs =
{
    "coldfirefire",
    "collapse_small",
}    

local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	local ash = SpawnPrefab("ash")
	ash.Transform:SetPosition(inst.Transform:GetWorldPosition())
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("idle")
end

local function onextinguish(inst)
    if inst.components.fueled then
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function fn(Sim)

	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon( "coldfirepit.png" )
	minimap:SetPriority( 1 )

    anim:SetBank("coldfirepit")
    anim:SetBuild("coldfirepit")
    anim:PlayAnimation("idle",false)
    inst:AddTag("campfire")
    inst:AddTag("structure")
  
    MakeObstaclePhysics(inst, .3)    

    -----------------------
    inst:AddComponent("burnable")
    --inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:AddBurnFX("coldfirefire", Vector3(0,0,0) )
    inst.components.burnable:MakeNotWildfireStarter()
    inst:ListenForEvent("onextinguish", onextinguish)
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
   inst.components.workable:SetWorkLeft(4)
inst.components.workable:SetOnFinishCallback(onhammered)
inst.components.workable:SetOnWorkCallback(onhit)    
inst:AddComponent("fueled")
inst.components.fueled.maxfuel = TUNING.COLDFIREPIT_FUEL_MAX
inst.components.fueled.accepting = true    
inst.components.fueled.secondaryfueltype = "CHEMICAL"
inst.components.fueled:SetSections(4)
inst.components.fueled.bonusmult = TUNING.COLDFIREPIT_BONUS_MULT
inst.components.fueled.ontakefuelfn = function() inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel") end
inst.components.fueled:SetUpdateFn( function()
local rate = 1
if GetSeasonManager() and GetSeasonManager():IsRaining() then
rate = 1 + TUNING.COLDFIREPIT_RAIN_RATE*GetSeasonManager():GetPrecipitationRate()
end
if inst:GetIsFlooded() then 
rate = rate + TUNING.COLDFIREPIT_FLOOD_RATE
end 
rate = rate +  GetSeasonManager():GetHurricaneWindSpeed() * TUNING.COLDFIREPIT_WIND_RATE
inst.components.fueled.rate = rate 
if inst.components.burnable and inst.components.fueled then
inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
end
end)
inst.components.fueled:SetSectionCallback( function(section)
if section == 0 then
inst.components.burnable:Extinguish() 
else
if not inst.components.burnable:IsBurning() then
inst.components.burnable:Ignite()
end            
inst.components.burnable:SetFXLevel(section, inst.components.fueled:GetSectionPercent())
end
end)
inst.components.fueled:InitializeFuelLevel(TUNING.COLDFIREPIT_FUEL_START)
inst:AddComponent("inspectable")
inst.components.inspectable.getstatus = function(inst)
local sec=inst.components.fueled:GetCurrentSection()
if sec == 0 then 
return "OUT"
elseif sec <= 4 then
local t = {"EMBERS","LOW","NORMAL","HIGH"}
return t[sec]
end
end
inst:ListenForEvent( "onbuilt", function()
anim:PlayAnimation("place")
anim:PushAnimation("idle",false)
inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end)
local function SAI(inst, item)
return 
item.prefab=="redgem" 
end
local function OGIFP(inst, giver, item)
inst.gt=(inst.gt or 0 ) + 1
giver.components.combat.damagebonus=(giver.components.combat.damagebonus or 0) + 5
giver.damage_a=(giver.damage_a or 0) + 5
giver.components.locomotor.bonusspeed=(giver.components.locomotor.bonusspeed or 0) + 0.03
giver.components.talker:Say('update')--0000000000000000000
end
local function OS(inst, data)
data.gt=inst.gt or 0
end
local function OL(inst, data)
inst.gt=data and data.gt or 0
local giver=GetPlayer()
if giver then
giver.components.combat.damagebonus=(giver.components.combat.damagebonus or 0) + (inst.gt or 0)*5
giver.damage_a=(giver.damage_a or 0) + (inst.gt or 0)*5
giver.components.locomotor.bonusspeed=(giver.components.locomotor.bonusspeed or 0) + (inst.gt or 0)*0.03
end
end
inst:AddComponent("trader")
inst.components.trader:SetAcceptTest(SAI)
inst.components.trader.onaccept = OGIFP
inst.OnSave = OS
inst.OnLoad = OL
return inst
end

return Prefab( "common/objects/coldfirepit", fn, assets, prefabs),
MakePlacer( "common/coldfirepit_placer", "coldfirepit", "coldfirepit", "preview" )
