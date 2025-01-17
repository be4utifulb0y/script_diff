require "prefabutil"

local assets=
{
	Asset("ANIM", "anim/cave_ferns_potted.zip"),
}
local prefabs=
{
    "collapse_small",
}
local names = {"f1","f2","f3","f4","f5","f6","f7","f8","f9","f10"}

local function onsave(inst, data)
	data.anim = inst.animname
end

local function onload(inst, data)
	if data and data.anim then
	inst.animname = data.anim
	inst.AnimState:PlayAnimation(inst.animname)
	end
end


local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_pot")
	inst:Remove()
end

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddSoundEmitter()
	inst.entity:AddAnimState()
	inst.AnimState:SetBank("ferns_potted")

	inst.animname = names[math.random(#names)]
	inst.AnimState:SetBuild("cave_ferns_potted")
	inst.AnimState:PlayAnimation(inst.animname)
	inst.AnimState:SetRayTestOnBB(true);	
 
	inst:AddComponent("inspectable")

	inst:AddTag("flower")
	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = 0.1 
	inst:AddComponent("pickable")
	inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
	inst.components.pickable:SetUp("butterfly", 480)
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(onhammered)

	inst:AddComponent("lootdropper")

	inst.OnSave = onsave 
	inst.OnLoad = onload 
 return inst
end

return Prefab( "cave/objects/pottedfern", fn, assets, prefabs),
    MakePlacer( "common/pottedfern_placer", "ferns_potted", "cave_ferns_potted", "f1")
