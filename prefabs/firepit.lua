require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/firepit.zip"),
}

local prefabs =
{
    "campfirefire",
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

local function onignite(inst)
    if not inst.components.cooker then
inst:AddComponent("cooker")
end
end
local function onextinguish(inst)
if inst.components.cooker then
inst:RemoveComponent("cooker")
end
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
minimap:SetIcon( "firepit.png" )
minimap:SetPriority( 1 )
anim:SetBank("firepit")
anim:SetBuild("firepit")
anim:PlayAnimation("idle",false)
inst:AddTag("campfire")
inst:AddTag("structure")
MakeObstaclePhysics(inst, .3)    
inst:AddComponent("burnable")
inst.components.burnable:AddBurnFX("campfirefire", Vector3(0,.4,0) )
inst.components.burnable:MakeNotWildfireStarter()
inst:ListenForEvent("onextinguish", onextinguish)
inst:ListenForEvent("onignite", onignite)
inst:AddComponent("lootdropper")
inst:AddComponent("workable")
inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
inst.components.workable:SetWorkLeft(4)
inst.components.workable:SetOnFinishCallback(onhammered)
inst.components.workable:SetOnWorkCallback(onhit)    
inst:AddComponent("fueled")
inst.components.fueled.maxfuel = TUNING.FIREPIT_FUEL_MAX
inst.components.fueled.accepting = true
inst.components.fueled:SetSections(4)
inst.components.fueled.bonusmult = TUNING.FIREPIT_BONUS_MULT
inst.components.fueled.ontakefuelfn = function() inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel") end
inst.components.fueled:SetUpdateFn( function()
local rate = 1 
if GetSeasonManager() and GetSeasonManager():IsRaining() then
inst.components.fueled.rate = 1 + TUNING.FIREPIT_RAIN_RATE*GetSeasonManager():GetPrecipitationRate()
end
if inst:GetIsFlooded() then 
rate = rate + TUNING.FIREPIT_FLOOD_RATE
end 
rate = rate +  GetSeasonManager():GetHurricaneWindSpeed() * TUNING.FIREPIT_WIND_RATE
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
inst.components.fueled:InitializeFuelLevel(TUNING.FIREPIT_FUEL_START)
inst:AddComponent("inspectable")
inst.components.inspectable.getstatus = function(inst)
local sec = inst.components.fueled:GetCurrentSection()
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
local function ShouldAcceptItem(inst, item)
return 
item.prefab=="bluegem" 
end
local function OnGetItemFromPlayer(inst, giver, item)
inst.gt=(inst.gt or 0 ) +10
giver.components.health.maxhealth=giver.components.health.maxhealth + 10
giver.components.hunger.max=giver.components.hunger.max + 10
giver.components.sanity.max=giver.components.sanity.max + 10
giver.components.health:DoDelta(.1)
giver.components.hunger:DoDelta(.1)
giver.components.sanity:DoDelta(.1)
giver.components.talker:Say('update')
end
local function onsave(inst, data)
data.gt=inst.gt or 0
end
local function onload(inst, data)
inst.gt=data and data.gt or 0
local giver=GetPlayer()
if giver then
giver.components.health.maxhealth=giver.components.health.maxhealth + (inst.gt or 0)
giver.components.hunger.max=giver.components.hunger.max + (inst.gt or 0)
giver.components.sanity.max=giver.components.sanity.max + (inst.gt or 0)
giver.components.health:DoDelta(.1)
giver.components.hunger:DoDelta(.1)
giver.components.sanity:DoDelta(.1)
end
end
inst:AddComponent("trader")
inst.components.trader:SetAcceptTest(ShouldAcceptItem)
inst.components.trader.onaccept = OnGetItemFromPlayer
inst.OnSave = onsave
inst.OnLoad = onload
return inst
end

return Prefab( "common/objects/firepit", fn, assets, prefabs),
		MakePlacer( "common/firepit_placer", "firepit", "firepit", "preview" ) 
