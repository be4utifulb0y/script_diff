require "prefabutil"

local cooking = require("cooking")

local assets=
{
	Asset("ANIM", "anim/cook_pot_warly.zip"),
	Asset("ANIM", "anim/cook_pot_food.zip"),
	Asset("MINIMAP_IMAGE", "cookpotwarly")
}

local prefabs = {"collapse_small"}
for k,v in pairs(cooking.recipes.cookpot) do
	table.insert(prefabs, v.name)
end

local function onhammered(inst, worker)
	if inst.components.stewer and inst.components.stewer.product and inst.components.stewer.done then
		inst.components.lootdropper:AddChanceLoot(inst.components.stewer.product, 1)
	end
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")
	inst:Remove()
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit_empty")
	
	if inst.components.stewer.cooking then
		inst.AnimState:PushAnimation("cooking_loop")
	elseif inst.components.stewer.done then
		inst.AnimState:PushAnimation("idle_full")
	else
		inst.AnimState:PushAnimation("idle_empty")
	end
end

local slotpos = {	Vector3(0,64+32+8+4,0), 
					Vector3(0,32+4,0),
					Vector3(0,-(32+4),0), 
					Vector3(0,-(64+32+8+4),0)}

local widgetbuttoninfo = {
	text = "Cook",
	position = Vector3(0, -165, 0),
	fn = function(inst)
		inst.components.stewer:StartCooking()	
	end,
	
	validfn = function(inst)
		return inst.components.stewer:CanCook()
	end,
}

local function itemtest(inst, item, slot)
	if cooking.IsCookingIngredient(item.prefab) then
		return true
	end
end

--anim and sound callbacks

local function ShowProduct(inst)
	local product = inst.components.stewer.product
	if IsModCookingProduct(inst.prefab, product) then
		inst.AnimState:OverrideSymbol("swap_cooked", product, product)
	else
		inst.AnimState:OverrideSymbol("swap_cooked", "cook_pot_food", product)
	end
end

local function startcookfn(inst)
	inst.AnimState:PlayAnimation("cooking_loop", true)
	--play a looping sound
	inst.SoundEmitter:KillSound("snd")
	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
	inst.Light:Enable(true)
end


local function onopen(inst)
	inst.AnimState:PlayAnimation("cooking_pre_loop", true)
	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open", "open")
	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot", "snd")
end

local function onclose(inst)
	if not inst.components.stewer.cooking then
		inst.AnimState:PlayAnimation("idle_empty")
		inst.SoundEmitter:KillSound("snd")
	end
	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close", "close")
end

local function spoilfn(inst)
	inst.components.stewer.product = inst.components.stewer.spoiledproduct
	ShowProduct(inst)
end

local function donecookfn(inst)
	inst.AnimState:PlayAnimation("cooking_pst")
	inst.AnimState:PushAnimation("idle_full")
	ShowProduct(inst)
	inst.SoundEmitter:KillSound("snd")
	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_finish", "snd")
	inst.Light:Enable(false)
	--play a one-off sound
end

local function continuedonefn(inst)
	inst.AnimState:PlayAnimation("idle_full")
	ShowProduct(inst)
end

local function continuecookfn(inst)
	inst.AnimState:PlayAnimation("cooking_loop", true)
	--play a looping sound
	inst.Light:Enable(true)

	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
end

local function harvestfn(inst)
	inst.AnimState:PlayAnimation("idle_empty")
end

local function getstatus(inst)
	if inst.components.stewer.cooking and inst.components.stewer:GetTimeToCook() > 15 then
		return "COOKING_LONG"
	elseif inst.components.stewer.cooking then
		return "COOKING_SHORT"
	elseif inst.components.stewer.done then
		return "DONE"
	else
		return "EMPTY"
	end
end

local function onfar(inst)
	if inst.components.container then
		inst.components.container:Close()
	end
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle_empty")
end

local function ondeploy(inst, pt, deployer)
	local pot = SpawnPrefab("portablecookpot") 
	if pot then 
		pt = Vector3(pt.x, 0, pt.z)
		pot.Physics:SetCollides(false)
		pot.Physics:Teleport(pt.x, pt.y, pt.z) 
		pot.Physics:SetCollides(true)
		pot.SoundEmitter:PlaySound("dontstarve/common/place_structure_stone")
		pot.AnimState:PlayAnimation("place")
		pot.AnimState:PushAnimation("idle_empty", false)
		inst:Remove()
	end        
end

local function pickupfn(inst, guy)
	if guy.components and guy.components.inventory then
		local potitem = SpawnPrefab("portablecookpot_item")
		guy.components.inventory:GiveItem(potitem)
		inst:Remove()
		return true
	end
end

local function onFloodedStart(inst)
	if inst.components.container then 
		inst.components.container.canbeopened = false 
	end
	if inst.components.stewer then 
		if inst.components.stewer.cooking then 
			inst.components.stewer.product = "wetgoop"
		end
	end
end


local function onFloodedEnd(inst)
	if inst.components.container then 
		inst.components.container.canbeopened = true 
	end
end

local function item_deploytest(inst, pt)
	local ground = GetWorld()
	local tile = GROUND.GRASS

	if ground and ground.Map then
		tile = ground.Map:GetTileAtPoint(pt:Get())
	end

	local onWater = ground.Map:IsWater(tile)

	return not onWater
end

local function item_droppedfn(inst)
	--If this is a valid place to be deployed, auto deploy yourself.
	if inst.components.deployable and inst.components.deployable:CanDeploy(inst:GetPosition()) then
		inst.components.deployable:Deploy(inst:GetPosition(), inst)
	end
end

local function itemfn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "idle_water", "idle_drop")

	inst:AddTag("irreplaceable")

	inst.AnimState:SetBank("cook_pot_warly")
	inst.AnimState:SetBuild("cook_pot_warly")
	inst.AnimState:PlayAnimation("idle_empty")
	
	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnDroppedFn(item_droppedfn)

	inst:AddComponent("deployable")
	inst.components.deployable.ondeploy = ondeploy
	inst.components.deployable.placer = "portablecookpot_placer"
	inst.components.deployable.test = item_deploytest

	inst:AddComponent("characterspecific")
    inst.components.characterspecific:SetOwner("warly")
	
	return inst
end

local function canpickup(inst)
	local stewer = inst.components.stewer
	local container = inst.components.container

	if not stewer or not container then
		--Something has gone very wrong...
		return false
	end

	return container:IsEmpty() and not stewer.cooking and not stewer.product
end

local function fn(Sim)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	
	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon( "cookpotwarly.png" )
	
	local light = inst.entity:AddLight()
	inst.Light:Enable(false)
	inst.Light:SetRadius(.6)
	inst.Light:SetFalloff(1)
	inst.Light:SetIntensity(.5)
	inst.Light:SetColour(235/255,62/255,12/255)

	inst:AddTag("structure")
	MakeObstaclePhysics(inst, .5)
	
	inst.AnimState:SetBank("cook_pot_warly")
	inst.AnimState:SetBuild("cook_pot_warly")
	inst.AnimState:PlayAnimation("idle_empty")

	inst:AddComponent("stewer")
	inst.components.stewer.specialcookername = "portablecookpot"
	inst.components.stewer:SetCookerName("cookpot")
	inst.components.stewer.onstartcooking = startcookfn
	inst.components.stewer.oncontinuecooking = continuecookfn
	inst.components.stewer.oncontinuedone = continuedonefn
	inst.components.stewer.ondonecooking = donecookfn
	inst.components.stewer.onharvest = harvestfn
	inst.components.stewer.onspoil = spoilfn
	
	inst:AddComponent("container")
	inst.components.container.itemtestfn = itemtest
	inst.components.container:SetNumSlots(4)
	inst.components.container.widgetslotpos = slotpos
	inst.components.container.widgetanimbank = "ui_cookpot_1x4"
	inst.components.container.widgetanimbuild = "ui_cookpot_1x4"
	inst.components.container.widgetpos = Vector3(150,75,0)
	inst.components.container.side_align_tip = 100
	inst.components.container.widgetbuttoninfo = widgetbuttoninfo
	inst.components.container.acceptsstacks = false
	inst.components.container.type = "cooker"

	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = getstatus

	inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(3,5)
	inst.components.playerprox:SetOnPlayerFar(onfar)

	inst:AddComponent("floodable")
	inst.components.floodable.onStartFlooded = onFloodedStart
	inst.components.floodable.onStopFlooded = onFloodedEnd
	inst.components.floodable.floodEffect = "shock_machines_fx"
	inst.components.floodable.floodSound = "dontstarve_DLC002/creatures/jellyfish/electric_land"

	MakeSnowCovered(inst, .01)    
	inst:ListenForEvent( "onbuilt", onbuilt)

	inst:AddComponent("pickupable")
	inst.components.pickupable:SetOnPickupFn(pickupfn)
	inst.components.pickupable.canpickupfn = canpickup

	inst:AddComponent("characterspecific")
    inst.components.characterspecific:SetOwner("warly")

	return inst
end

return Prefab( "common/portablecookpot", fn, assets, prefabs),
		MakePlacer( "common/portablecookpot_placer", "cook_pot_warly", "cook_pot_warly", "idle_empty" ),
		Prefab("common/portablecookpot_item", itemfn, assets, prefabs)
