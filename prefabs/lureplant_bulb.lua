require "prefabutil"
local assets =
{
	Asset("ANIM", "anim/eyeplant_bulb.zip"),
	Asset("ANIM", "anim/eyeplant_trap.zip"),
}

local function ondeploy(inst, pt) --ʳ�˻����ӵ��޸�,,,,233,,,,,,,,,,,,,,,,,,,,�տտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտտ�..�տ�
	local lp = SpawnPrefab("lureplant")
	if lp then
	lp.Transform:SetPosition(pt.x, pt.y, pt.z)
	inst.components.stackable:Get():Remove()
	lp.sg:GoToState("spawn")
	end
end

local function eat(inst)
	local pos = Vector3(GetPlayer().Transform:GetWorldPosition())
	local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, 3000)
	for k,v in pairs(ents) do
	if v.components.pickable then
	v.components.pickable:FinishGrowing()
	end
	if v.components.crop then
	v.components.crop:DoGrow(1500)
	end
	end
end
local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("eyeplant_bulb")
	inst.AnimState:SetBuild("eyeplant_bulb")
	inst.AnimState:PlayAnimation("idle")

	inst:AddComponent("stackable")
	inst:AddComponent("inspectable")

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue =90

	inst:AddComponent("edible")
    inst.components.edible.healthvalue = 20    
	inst.components.edible:SetOnEatenFn(eat)
	inst:AddComponent("inventoryitem")

	inst:AddComponent("deployable")
	inst.components.deployable.ondeploy = ondeploy
	return inst
end

return Prefab( "common/inventory/lureplantbulb", fn, assets),
MakePlacer( "common/lureplantbulb_placer", "eyeplant_trap", "eyeplant_trap", "idle_hidden" )

