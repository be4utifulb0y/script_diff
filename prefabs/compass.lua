local assets=
{
	Asset("ANIM", "anim/compass.zip"),
}

local function onequip(inst, owner)
local minimap = TheSim:FindFirstEntityWithTag("minimap")
if minimap then
minimap.MiniMap:EnableFogOfWar(false)
end
end

local function onunequip(inst, owner) 
local minimap = TheSim:FindFirstEntityWithTag("minimap")
if minimap then
minimap.MiniMap:EnableFogOfWar(true)
end
end

local function GetStatus(inst, viewer)
                      
end

local function modify(inst)
    inst.components.equippable:SetOnEquip( onequip )
    inst.components.equippable:SetOnUnequip( onunequip )
end

local function fn(Sim)
local inst = CreateEntity()
local trans = inst.entity:AddTransform()
local anim = inst.entity:AddAnimState()
anim:SetBank("compass")
anim:SetBuild("compass")
anim:PlayAnimation("idle")
    
    MakeInventoryPhysics(inst)
      inst:AddComponent("inventoryitem")
inst:AddComponent("inspectable")
inst.components.inspectable.getstatus = GetStatus
inst:AddComponent("equippable")
modify(inst)
inst.OnLoad = function(inst)
inst:AddComponent("equippable")
inst:DoTaskInTime(3, function()
modify(inst)
end)
end
return inst
end

return Prefab( "common/inventory/compass", fn, assets)
