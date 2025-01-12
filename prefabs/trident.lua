local assets=
{
	Asset("ANIM", "anim/trident.zip"),
	Asset("ANIM", "anim/swap_trident.zip"),
}

local function onequip(inst,owner)
	owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
	owner.AnimState:OverrideSymbol("swap_object","swap_trident","swap_trident")
	owner.components.talker:Say("Valar Morghulis!")             
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst,owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function onattack(inst,attacker,target)
	inst:StartThread(function()
	local r={1,2,3,4,5}
	local k=r[math.random(#r)]
	if k==1 then
		local pos=target:GetPosition()
		GetSeasonManager():DoLightningStrike(pos)
		target.components.health:DoDelta(-200)
end
 
	if k==3 and target.components.freezable then
		target.components.freezable:AddColdness(2)
		target.components.freezable:SpawnShatterFX()
end

end)

end

local function commonfn(Sim)
	local i=CreateEntity()
	local i=CreateEntity()
	local trans=i.entity:AddTransform()
	local anim=i.entity:AddAnimState()
	MakeInventoryPhysics(i)
	                                                  anim:SetBank("trident")anim:SetBuild("trident")anim:PlayAnimation("idle")i:AddComponent("inspectable")                 i:AddComponent("tool")i.components.tool:SetAction(ACTIONS.DIG)i.components.tool:SetAction(ACTIONS.HAMMER)i:AddComponent("weapon")i.components.weapon:SetOnAttack(onattack)i.components.weapon:SetDamage(120)i.components.weapon:SetRange(3,5)i.components.weapon:SetProjectile("bishop_charge")                                i:AddComponent("inventoryitem")
	i:AddComponent("equippable")i.components.equippable:SetOnEquip(onequip)i.components.equippable:SetOnUnequip(onunequip)                                                                                                                    
	return i
end

return Prefab("common/inventory/trident",commonfn,assets)                                      
