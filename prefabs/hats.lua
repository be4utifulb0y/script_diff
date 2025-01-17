
function MakeHat(name)local fname="hat_"..name
local symname=name.."hat"
local texture=symname..".tex"
local prefabname=symname
local assets={Asset("ANIM","anim/"..fname..".zip"),}if name=="miner"then
table.insert(assets, Asset("ANIM","anim/hat_miner_off.zip"))end
if name=="slurtle"then
table.insert(assets,Asset("INV_IMAGE","slurtlehat"))end
if name=="mole"then
table.insert(assets, Asset("IMAGE","images/colour_cubes/mole_vision_on_cc.tex"))table.insert(assets, Asset("IMAGE","images/colour_cubes/mole_vision_off_cc.tex"))end
local function generic_perish(inst)inst:Remove()end
local function onequip(inst,owner,fname_override)local build=fname_override or fname
owner.AnimState:OverrideSymbol("swap_hat",build,"swap_hat")owner.AnimState:Show("HAT")owner.AnimState:Show("HAT_HAIR")owner.AnimState:Hide("HAIR_NOHAT")owner.AnimState:Hide("HAIR")if owner:HasTag("player")then
owner.AnimState:Hide("HEAD")owner.AnimState:Show("HEAD_HAIR")end
if inst.components.fueled then
inst.components.fueled:StartConsuming()end
end
local function onunequip(inst,owner)owner.AnimState:Hide("HAT")owner.AnimState:Hide("HAT_HAIR")owner.AnimState:Show("HAIR_NOHAT")owner.AnimState:Show("HAIR")
if owner:HasTag("player")then
owner.AnimState:Show("HEAD")owner.AnimState:Hide("HEAD_HAIR")end
if inst.components.fueled then
inst.components.fueled:StopConsuming()end
end
local function opentop_onequip(inst,owner)owner.AnimState:OverrideSymbol("swap_hat", fname,"swap_hat")owner.AnimState:Show("HAT")owner.AnimState:Hide("HAT_HAIR")owner.AnimState:Show("HAIR_NOHAT")owner.AnimState:Show("HAIR")owner.AnimState:Show("HEAD")owner.AnimState:Hide("HEAD_HAIR")
if inst.components.fueled then
inst.components.fueled:StartConsuming()end
end
local function simple()local inst=CreateEntity()inst.entity:AddTransform()inst.entity:AddAnimState()MakeInventoryPhysics(inst)
if name~="double_umbrella"and name~="aerodynamic"then
inst.AnimState:SetBank(symname)inst.AnimState:SetBuild(fname)inst.AnimState:PlayAnimation("anim")end
MakeInventoryFloatable(inst,"idle_water","anim")inst:AddTag("hat")inst:AddComponent("inspectable")inst:AddComponent("inventoryitem")inst:AddComponent("tradable")inst:AddComponent("equippable")
inst.components.equippable.equipslot=EQUIPSLOTS.HEAD
inst.components.equippable:SetOnEquip(onequip)inst.components.equippable:SetOnUnequip(onunequip)
return inst
end
local function straw()local inst=simple()inst:AddComponent("waterproofer")inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)inst:AddComponent("insulator")inst.components.insulator:SetSummer()inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)
return inst
end
local function bee()local inst=simple()inst:AddComponent("armor")inst.components.armor:InitCondition(9999,1)inst.components.armor:SetTags({"bee"})inst:AddComponent("waterproofer")inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)return inst
end
local function earmuffs()local inst=simple()inst:AddComponent("insulator")inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)inst.components.equippable:SetOnEquip(opentop_onequip)inst.AnimState:SetRayTestOnBB(true)return inst
end
local function winter()local inst=simple()inst.components.equippable.dapperness=TUNING.DAPPERNESS_TINY
inst:AddComponent("insulator")inst.components.insulator:SetInsulation(TUNING.INSULATION_MED)inst:AddComponent("fueled")inst.components.fueled.fueltype="USAGE"inst.components.fueled:InitializeFuelLevel(5000)inst.components.fueled:SetDepletedFn(generic_perish)return inst
end
local function football()local inst=simple()inst:AddComponent("armor")inst:AddComponent("waterproofer")inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)inst.components.armor:InitCondition(500,0.8)return inst
end
local function ruinshat_proc(inst,owner)inst:AddTag("forcefield")inst.components.armor:SetAbsorption(TUNING.FULL_ABSORPTION)local fx=SpawnPrefab("forcefieldfx")fx.entity:SetParent(owner.entity)fx.Transform:SetPosition(0,0.2,0)local fx_hitanim=function()fx.AnimState:PlayAnimation("hit")fx.AnimState:PushAnimation("idle_loop")end
fx:ListenForEvent("blocked",fx_hitanim,owner)inst.components.armor.ontakedamage=function(inst,damage_amount)if owner then
local sanity=owner.components.sanity
if sanity then
local unsaneness=damage_amount*TUNING.ARMOR_RUINSHAT_DMG_AS_SANITY
sanity:DoDelta(-unsaneness,false)end
end
end
inst.active=true
owner:DoTaskInTime(TUNING.ARMOR_RUINSHAT_DURATION,function()fx:RemoveEventCallback("blocked",fx_hitanim,owner)fx.kill_fx(fx)if inst:IsValid()then
inst:RemoveTag("forcefield")inst.components.armor.ontakedamage=nil
inst.components.armor:SetAbsorption(TUNING.ARMOR_RUINSHAT_ABSORPTION)owner:DoTaskInTime(TUNING.ARMOR_RUINSHAT_COOLDOWN,function()inst.active=false end)end
end)end
local function tryproc(inst,owner)if not inst.active and math.random()<TUNING.ARMOR_RUINSHAT_PROC_CHANCE then
ruinshat_proc(inst,owner)end
end
local function ruins_onunequip(inst,owner)owner.AnimState:Hide("HAT")owner.AnimState:Hide("HAT_HAIR")owner.AnimState:Show("HAIR_NOHAT")owner.AnimState:Show("HAIR")
if owner:HasTag("player")then
owner.AnimState:Show("HEAD")owner.AnimState:Hide("HEAD_HAIR")end
owner:RemoveEventCallback("attacked", inst.procfn)end
local function ruins_onequip(inst,owner)owner.AnimState:OverrideSymbol("swap_hat",fname,"swap_hat")owner.AnimState:Show("HAT")owner.AnimState:Hide("HAT_HAIR")owner.AnimState:Show("HAIR_NOHAT")owner.AnimState:Show("HAIR")
owner.AnimState:Show("HEAD")owner.AnimState:Hide("HEAD_HAIR")inst.procfn=function()tryproc(inst,owner)end
owner:ListenForEvent("attacked",inst.procfn)end
local function ruins()local inst=simple()inst:AddComponent("armor")inst:AddTag("metal")inst.components.armor:InitCondition(1500,0.9)inst.components.equippable:SetOnEquip(ruins_onequip)inst.components.equippable:SetOnUnequip(ruins_onunequip)
return inst
end
local function feather_equip(inst,owner)onequip(inst,owner)local ground=GetWorld()if ground and ground.components.birdspawner then
ground.components.birdspawner:SetSpawnTimes(TUNING.BIRD_SPAWN_DELAY_FEATHERHAT)ground.components.birdspawner:SetMaxBirds(TUNING.BIRD_SPAWN_MAX_FEATHERHAT)end
end
local function feather_unequip(inst,owner)onunequip(inst,owner)local ground=GetWorld()if ground and ground.components.birdspawner then
ground.components.birdspawner:SetSpawnTimes(TUNING.BIRD_SPAWN_DELAY)ground.components.birdspawner:SetMaxBirds(TUNING.BIRD_SPAWN_MAX)end
end
local function feather()local inst=simple()
inst.components.equippable.dapperness=TUNING.DAPPERNESS_SMALL
inst.components.equippable:SetOnEquip(feather_equip)inst.components.equippable:SetOnUnequip(feather_unequip)return inst
end
local function beefalo_equip(inst,owner)onequip(inst,owner)owner:AddTag("beefalo")end
local function beefalo_unequip(inst,owner)onunequip(inst,owner)owner:RemoveTag("beefalo")end
local function beefalo()local inst=simple()inst.components.equippable:SetOnEquip(beefalo_equip)inst.components.equippable:SetOnUnequip(beefalo_unequip)inst:AddComponent("insulator")inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)inst:AddComponent("waterproofer")inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
inst:AddComponent("fueled")inst.components.fueled.fueltype="USAGE"inst.components.fueled:InitializeFuelLevel(5000)inst.components.fueled:SetDepletedFn(generic_perish)
return inst
end
local function walrus()local inst=simple()inst.components.equippable.dapperness=TUNING.DAPPERNESS_LARGE
inst:AddComponent("insulator")inst.components.insulator:SetInsulation(TUNING.INSULATION_MED)
inst:AddComponent("fueled")inst.components.fueled.fueltype="USAGE"inst.components.fueled:InitializeFuelLevel(12000)inst.components.fueled:SetDepletedFn(generic_perish)return inst
end
local function miner_turnon(inst)local owner=inst.components.inventoryitem and inst.components.inventoryitem.owner
if inst.components.fueled:IsEmpty()then
if owner then
onequip(inst, owner,"hat_miner_off")end
else
if owner then
onequip(inst,owner)end
inst.components.fueled:StartConsuming()inst.SoundEmitter:PlaySound("dontstarve/common/minerhatAddFuel")inst.Light:Enable(true)end
end
local function miner_turnoff(inst,ranout)if inst.components.equippable and inst.components.equippable:IsEquipped()then
local owner=inst.components.inventoryitem and inst.components.inventoryitem.owner
if owner then
onequip(inst,owner,"hat_miner_off")end
end
inst.components.fueled:StopConsuming()inst.SoundEmitter:PlaySound("dontstarve/common/minerhatOut")inst.Light:Enable(false)end
local function miner_equip(inst,owner)miner_turnon(inst)end
local function miner_unequip(inst,owner)onunequip(inst,owner)miner_turnoff(inst)end
local function miner_perish(inst)local owner=inst.components.inventoryitem and inst.components.inventoryitem.owner
if owner then
owner:PushEvent("torchranout",{torch=inst})end
miner_turnoff(inst)end
local function miner_drop(inst)miner_turnoff(inst)end
local function miner_takefuel(inst)if inst.components.equippable and inst.components.equippable:IsEquipped()then
miner_turnon(inst)end
end
local function miner()local inst=simple()inst.entity:AddSoundEmitter()local light=inst.entity:AddLight()light:SetFalloff(0.4)light:SetIntensity(.7)light:SetRadius(2.5)light:SetColour(180/255,195/255,150/255)light:Enable(false)inst:AddComponent("waterproofer")inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)inst.components.inventoryitem:SetOnDroppedFn(miner_drop)inst.components.equippable:SetOnEquip(miner_equip)inst.components.equippable:SetOnUnequip(miner_unequip)inst:AddComponent("fueled")inst.components.fueled.fueltype="CAVE"inst.components.fueled:InitializeFuelLevel(TUNING.MINERHAT_LIGHTTIME)inst.components.fueled:SetDepletedFn(miner_perish)inst.components.fueled.ontakefuelfn=miner_takefuel
inst.components.fueled.accepting=true
return inst
end
local function spider_disable(inst)if inst.updatetask then
inst.updatetask:Cancel()inst.updatetask=nil
end
local owner=inst.components.inventoryitem and inst.components.inventoryitem.owner
if owner and owner.components.leader then
if not owner:HasTag("spiderwhisperer")then
owner:RemoveTag("monster")for k,v in pairs(owner.components.leader.followers)do
if k:HasTag("spider")and k.components.combat then
k.components.combat:SuggestTarget(owner)end
end
owner.components.leader:RemoveFollowersByTag("spider")else
owner.components.leader:RemoveFollowersByTag("spider",function(follower)if follower and follower.components.follower then
if follower.components.follower:GetLoyaltyPercent()>0 then
return false
else
return true
end
end
end)end
end
end
local function spider_update(inst)
local owner=inst.components.inventoryitem and inst.components.inventoryitem.owner
if owner and owner.components.leader then
owner.components.leader:RemoveFollowersByTag("pig")
local x,y,z=owner.Transform:GetWorldPosition()local ents = TheSim:FindEntities(x,y,z,TUNING.SPIDERHAT_RANGE,{"spider"})for k,v in pairs(ents)do
if v.components.follower and not v.components.follower.leader and not owner.components.leader:IsFollower(v) and owner.components.leader.numfollowers<10 then
owner.components.leader:AddFollower(v)end
end
end
end
local function spider_enable(inst)local owner=inst.components.inventoryitem and inst.components.inventoryitem.owner
if owner and owner.components.leader then
owner.components.leader:RemoveFollowersByTag("pig")owner:AddTag("monster")end
inst.updatetask=inst:DoPeriodicTask(0.5,spider_update,1)end
local function spider_equip(inst,owner)onequip(inst,owner)spider_enable(inst)end
local function spider_unequip(inst,owner)onunequip(inst,owner)spider_disable(inst)end
local function spider_perish(inst)spider_disable(inst)inst:Remove()end
local function ondropped(inst)inst.components.container.canbeopened=true
inst.components.inventoryitem.canbepickedup=false

local widgetbuttoninfo={
text="Plant",
position=Vector3(0,-145,0),
fn=function(inst)
RemovePhysicsColliders(inst)
inst.components.container.canbeopened=false
inst.components.container:Close()
local player=GetPlayer()
if inst.components.container:Has("dug_grass",25)then
inst.components.container:ConsumeByName("dug_grass",25)
inst.plants="grass"
end
if inst.components.container:Has("dug_sapling",25)then
inst.components.container:ConsumeByName("dug_sapling",25)
inst.plants="sapling"
end
if inst.components.container:Has("dug_berrybush",25)then
inst.components.container:ConsumeByName("dug_berrybush",25)
inst.plants="berrybush"
end
if inst.components.container:Has("dug_berrybush2",25)then
inst.components.container:ConsumeByName("dug_berrybush2",25)
inst.plants="berrybush2"
end
if inst.components.container:Has("dug_marsh_bush",25)then
inst.components.container:ConsumeByName("dug_marsh_bush",25)
inst.plants="marsh_bush"
end
if inst.components.container:Has("green_cap",25)then
inst.components.container:ConsumeByName("green_cap",25)
inst.plants="green_mushroom"
end
if inst.components.container:Has("blue_cap",25)then
inst.components.container:ConsumeByName("blue_cap",25)
inst.plants="blue_mushroom"
end
if inst.components.container:Has("pinecone",25)then
inst.components.container:ConsumeByName("pinecone",25)
inst.plants="evergreen_short"
end
if inst.components.container:Has("jungletreeseed",25) then
inst.components.container:ConsumeByName("jungletreeseed",25)
inst.plants="jungletree_short"
end
if inst.components.container:Has("dug_bush_vine",25) then
inst.components.container:ConsumeByName("dug_bush_vine",25)
inst.plants="bush_vine"
end
if inst.components.container:Has("dug_coffeebush",25) then
inst.components.container:ConsumeByName("dug_coffeebush",25)
inst.plants="coffeebush" 
end
if inst.components.container:Has("dug_bambootree",25) then
inst.components.container:ConsumeByName("dug_bambootree",25)
inst.plants="bambootree"
end
if inst.components.container:Has("coconut",25) then
inst.components.container:ConsumeByName("coconut",25)
inst.plants="palmtree_short"
end
inst:DoTaskInTime(1,function()
inst.task=inst:DoPeriodicTask(.5,function()
inst.Physics:SetMotorVelOverride(2,0,2)
inst.Physics:ClearMotorVelOverride()
SpawnPrefab(inst.plants).Transform:SetPosition(inst.Transform:GetWorldPosition())
end)
end)
inst:DoTaskInTime(3.5,function() 
if inst.task then inst.task:Cancel()inst.task=nil end 
inst.Physics:SetMotorVelOverride(-3,0,1)
inst.Physics:ClearMotorVelOverride()
inst.components.container.canbeopened=true
end)

inst:DoTaskInTime(4,function()
inst.task=inst:DoPeriodicTask(.5,function()
inst.Physics:SetMotorVelOverride(-2,0,-2)
inst.Physics:ClearMotorVelOverride()
SpawnPrefab(inst.plants).Transform:SetPosition(inst.Transform:GetWorldPosition())
end)
end)
inst:DoTaskInTime(6.5,function() 
if inst.task then inst.task:Cancel()inst.task=nil end 
inst.Physics:SetMotorVelOverride(-1,0,3)     
inst.Physics:ClearMotorVelOverride()
inst.components.container.canbeopened=true
end)

inst:DoTaskInTime(7,function()
inst.task=inst:DoPeriodicTask(.5,function()
inst.Physics:SetMotorVelOverride(2,0,2)
inst.Physics:ClearMotorVelOverride()
SpawnPrefab(inst.plants).Transform:SetPosition(inst.Transform:GetWorldPosition())
end)
end)
inst:DoTaskInTime(9.5,function() 
if inst.task then inst.task:Cancel()inst.task=nil end 
inst.Physics:SetMotorVelOverride(-3,0,1)
inst.Physics:ClearMotorVelOverride()
inst.components.container.canbeopened=true
end)

inst:DoTaskInTime(10,function()
inst.task=inst:DoPeriodicTask(.5,function()
inst.Physics:SetMotorVelOverride(-2,0,-2)
inst.Physics:ClearMotorVelOverride()
SpawnPrefab(inst.plants).Transform:SetPosition(inst.Transform:GetWorldPosition())
end)
end)
inst:DoTaskInTime(12.5,function() 
if inst.task then inst.task:Cancel()inst.task=nil end 
inst.Physics:SetMotorVelOverride(-1,0,3) 
inst.Physics:ClearMotorVelOverride()
inst.components.container.canbeopened=true
end)

inst:DoTaskInTime(13,function()
inst.task=inst:DoPeriodicTask(.5, function()
inst.Physics:SetMotorVelOverride(2,0,2)
inst.Physics:ClearMotorVelOverride()
SpawnPrefab(inst.plants).Transform:SetPosition(inst.Transform:GetWorldPosition())
end)
end)
inst:DoTaskInTime(15.5,function() 
if inst.task then inst.task:Cancel()inst.task=nil end 
inst.Physics:SetMotorVelOverride(-3,0,1)    
inst.Physics:ClearMotorVelOverride()
inst.components.container.canbeopened=true
end)
end,
validfn=function(inst)
return inst.components.container:Has("pinecone",25)
or inst.components.container:Has("green_cap",25)
or inst.components.container:Has("blue_cap",25)
or inst.components.container:Has("dug_marsh_bush",25)
or inst.components.container:Has("dug_berrybush2",25)
or inst.components.container:Has("dug_berrybush",25)
or inst.components.container:Has("dug_sapling",25)
or inst.components.container:Has("dug_grass",25)
or inst.components.container:Has("coconut",25)
or inst.components.container:Has("dug_bambootree",25)
or inst.components.container:Has("dug_bush_vine",25)
or inst.components.container:Has("dug_coffeebush",25)
or inst.components.container:Has("jungletreeseed",25)
end,}
inst:AddComponent("machine")
inst.components.machine.turnofffn=function()inst.components.inventoryitem.canbepickedup=true end
inst.components.machine.ison=true

inst.components.container.widgetbuttoninfo=widgetbuttoninfo
end
local function top()
local inst=simple()
inst.components.equippable.dapperness=TUNING.DAPPERNESS_MED
local function pickupfn(inst)
inst.components.container:Close()
inst.components.container.canbeopened=false
end
inst.components.inventoryitem:SetOnDroppedFn(ondropped)
inst.components.inventoryitem:SetOnPickupFn(pickupfn)

local slotpos={ Vector3(0,-75,0)}
local function itemtest(inst, item, slot)
if item.prefab == "dug_grass" or item.prefab == "dug_sapling" or item.prefab == "green_cap" or item.prefab == "blue_cap" or item.prefab == "dug_berrybush" or item.prefab == "dug_berrybush2" or item.prefab == "dug_marsh_bush" or item.prefab == "pinecone" or item.prefab == "coconut" or item.prefab == "dug_bambootree" or item.prefab == "dug_bush_vine" or item.prefab == "dug_coffeebush" or item.prefab == "jungletreeseed" then
return true
end
return false
end
inst:AddComponent("container")
inst.components.container:SetNumSlots(#slotpos)
inst.components.container.widgetslotpos=slotpos
inst.components.container.widgetpos=Vector3(0,180,0)
inst.components.container.side_align_tip=160
inst.components.container.itemtestfn=itemtest
inst:AddComponent("waterproofer")
inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
return inst
end
local function spider()
local inst=simple()
inst.components.equippable.dapperness=-TUNING.DAPPERNESS_SMALL
inst.components.inventoryitem:SetOnDroppedFn(spider_disable)inst.components.equippable:SetOnEquip(spider_equip)inst.components.equippable:SetOnUnequip(spider_unequip)return inst
end
local function stopusingbush(inst,data)
local hat=inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)if hat and not(data.statename=="hide_idle"or data.statename=="hide")then
hat.components.useableitem:StopUsingItem()end
end
local function poop(inst)SpawnPrefab("poop").Transform:SetPosition(inst.Transform:GetWorldPosition())end
local function onequipbush(inst,owner)owner:AddTag("beefalo")owner:AddTag("qupick")owner.AnimState:OverrideSymbol("swap_hat",fname,"swap_hat")owner.AnimState:Show("HAT")owner.AnimState:Show("HAT_HAIR")owner.AnimState:Hide("HAIR_NOHAT")owner.AnimState:Hide("HAIR")if owner:HasTag("player")then
owner.AnimState:Hide("HEAD")owner.AnimState:Show("HEAD_HAIR")end
if inst.components.fueled then
inst.components.fueled:StartConsuming()end
owner:ListenForEvent("oneatsomething",poop,owner)inst:ListenForEvent("newstate",stopusingbush,owner) end
local function onunequipbush(inst,owner)owner:RemoveTag("beefalo")owner:RemoveTag("qupick")owner.AnimState:Hide("HAT")owner.AnimState:Hide("HAT_HAIR")owner.AnimState:Show("HAIR_NOHAT")owner.AnimState:Show("HAIR")
if owner:HasTag("player")then
owner.AnimState:Show("HEAD")owner.AnimState:Hide("HEAD_HAIR")end
if inst.components.fueled then
inst.components.fueled:StopConsuming()end
owner:RemoveEventCallback("oneatsomething",poop,owner)inst:RemoveEventCallback("newstate",stopusingbush,owner)end
local function onusebush(inst)local owner=inst.components.inventoryitem.owner
if owner then
owner.sg:GoToState("hide")end
end
local function bush()local inst=simple()inst:AddTag("hide")inst.components.inventoryitem.foleysound="dontstarve/movement/foley/bushhat"inst:AddComponent("useableitem")inst.components.useableitem:SetOnUseFn(onusebush)inst.components.equippable:SetOnEquip(onequipbush)inst.components.equippable:SetOnUnequip(onunequipbush)return inst
end

local function flower()local inst=simple()inst.components.equippable.dapperness=TUNING.DAPPERNESS_TINY
inst:AddTag("show_spoilage")inst:AddComponent("perishable")inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)inst.components.perishable:StartPerishing()inst.components.perishable:SetOnPerishFn(generic_perish)inst.components.equippable:SetOnEquip(opentop_onequip)return inst
end

local function slurtle()local inst=simple()inst:AddComponent("armor")inst.components.armor:InitCondition(999,0.9)inst:AddComponent("waterproofer")inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)return inst
end	
local function wathgrithr()local inst=simple()inst:AddComponent("armor")inst.components.armor:InitCondition(999,0.8)
inst:AddComponent("waterproofer")inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)return inst
end
local function ice()local inst=simple()inst:AddComponent("heater")inst.components.heater.iscooler=true
inst.components.heater.equippedheat=TUNING.ICEHAT_COOLER
inst.components.equippable.walkspeedmult=TUNING.ICE_HAT_SPEED_MULT
inst.components.equippable.equippedmoisture=1
inst.components.equippable.maxequippedmoisture=49
inst:AddComponent("insulator")inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)inst.components.insulator:SetSummer()inst:AddComponent("waterproofer")inst.components.waterproofer.effectiveness=0 
inst:AddComponent("perishable")inst.components.perishable:SetPerishTime(TUNING.PERISH_FASTISH)inst.components.perishable:StartPerishing()inst.components.perishable:SetOnPerishFn(function(inst)local player=GetPlayer()if inst.components.inventoryitem and player and inst.components.inventoryitem:IsHeldBy(player)then
if player.components.moisture then
player.components.moisture:DoDelta(20)end
end
inst:Remove()end)inst:AddComponent("repairable")inst.components.repairable.repairmaterial="ICE"inst.components.repairable.announcecanfix=false
inst:AddTag("show_spoilage")inst:AddTag("frozen")return inst
end
local function mole_onequip(inst,owner)onequip(inst,owner)if owner~=GetPlayer()then return end
owner.SoundEmitter:PlaySound("dontstarve_DLC001/common/moggles_on")if GetClock()and GetWorld()and GetWorld().components.colourcubemanager then
GetClock():SetNightVision(true)if GetClock():IsDay()and not GetWorld():IsCave()then
GetWorld().components.colourcubemanager:SetOverrideColourCube("images/colour_cubes/mole_vision_off_cc.tex",.25)else
GetWorld().components.colourcubemanager:SetOverrideColourCube("images/colour_cubes/mole_vision_on_cc.tex",.25)end
end
end
local function mole_onunequip(inst,owner)onunequip(inst,owner)if owner~=GetPlayer()then return end
owner.SoundEmitter:PlaySound("dontstarve_DLC001/common/moggles_off")if GetClock()then
GetClock():SetNightVision(false)end
if GetWorld()and GetWorld().components.colourcubemanager then
GetWorld().components.colourcubemanager:SetOverrideColourCube(nil,.5)end
end

local function mole_perish(inst)
if inst.components.inventoryitem:GetGrandOwner() == GetPlayer() and inst.components.equippable and inst.components.equippable:IsEquipped()then
if GetClock()then
GetClock():SetNightVision(false)end
if GetWorld()and GetWorld().components.colourcubemanager then
GetWorld().components.colourcubemanager:SetOverrideColourCube(nil,.5)end
end
generic_perish(inst)end
local function mole()local inst=simple()
inst.components.equippable:SetOnEquip(mole_onequip)
inst.components.equippable:SetOnUnequip(mole_onunequip)
inst:AddComponent("fueled")
inst.components.fueled.fueltype= "MOLEHAT"
inst.components.fueled:InitializeFuelLevel(999)
inst.components.fueled:SetDepletedFn( mole_perish )
inst.components.fueled.accepting = true
inst:AddTag("no_sewing")

inst:ListenForEvent("daytime", function(it)
if GetWorld():IsCave() then return end
if inst.components.equippable and inst.components.equippable:IsEquipped() and inst.components.inventoryitem:GetGrandOwner() == GetPlayer() and not GetWorld():IsCave() then
GetWorld().components.colourcubemanager:SetOverrideColourCube("images/colour_cubes/mole_vision_off_cc.tex", 2)
end
end, GetWorld())
inst:ListenForEvent("dusktime", function(it)
if GetWorld():IsCave() then return end
if inst.components.equippable and inst.components.equippable:IsEquipped() and inst.components.inventoryitem:GetGrandOwner() == GetPlayer() then
GetWorld().components.colourcubemanager:SetOverrideColourCube("images/colour_cubes/mole_vision_on_cc.tex", 2)
end
end, GetWorld())
inst:ListenForEvent("nighttime", function(it)
if GetWorld():IsCave() then return end
if inst.components.equippable and inst.components.equippable:IsEquipped() and inst.components.inventoryitem:GetGrandOwner() == GetPlayer() then
GetWorld().components.colourcubemanager:SetOverrideColourCube("images/colour_cubes/mole_vision_on_cc.tex", 2)
end
end, GetWorld())

return inst
end

local function rain()
local inst = simple()
inst:AddComponent("waterproofer")
inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_LARGE)

inst.components.equippable.insulated = true

return inst
end

local function snakeskin()
local inst = simple()
inst:AddComponent("fueled")
inst.components.fueled.fueltype = "USAGE"
inst.components.fueled:InitializeFuelLevel(5000)
inst.components.fueled:SetDepletedFn(generic_perish)

inst:AddComponent("waterproofer")
inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_LARGE)

inst.components.equippable.insulated = true

return inst
end

local function eyebrella_updatesound(inst)
local soundShouldPlay = GetSeasonManager():IsRaining() and inst.components.equippable:IsEquipped()
if soundShouldPlay ~= inst.SoundEmitter:PlayingSound("umbrellarainsound") then
if soundShouldPlay then
inst.SoundEmitter:PlaySound("dontstarve/rain/rain_on_umbrella", "umbrellarainsound") 
else
inst.SoundEmitter:KillSound("umbrellarainsound")
end
end
end  

local function eyebrella_onequip(inst, owner) 
opentop_onequip(inst, owner)
eyebrella_updatesound(inst)

owner.DynamicShadow:SetSize(2.2, 1.4)
end

local function eyebrella_onunequip(inst, owner) 
onunequip(inst, owner)
eyebrella_updatesound(inst)

owner.DynamicShadow:SetSize(1.3, 0.6)
end

local function eyebrella_perish(inst)
inst.SoundEmitter:KillSound("umbrellarainsound")
if inst.components.inventoryitem and inst.components.inventoryitem.owner then
inst.components.inventoryitem.owner.DynamicShadow:SetSize(1.3, 0.6)
end
generic_perish(inst)
end

local function eyebrella()
local inst = simple()

inst.entity:AddSoundEmitter()

inst:AddComponent("fueled")
inst.components.fueled.fueltype = "USAGE"
inst.components.fueled:InitializeFuelLevel(5000)
inst.components.fueled:SetDepletedFn( eyebrella_perish )

inst.components.equippable:SetOnEquip( eyebrella_onequip )
inst.components.equippable:SetOnUnequip( eyebrella_onunequip )

inst:AddComponent("waterproofer")
inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_ABSOLUTE)

inst:AddComponent("insulator")
inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)
inst.components.insulator:SetSummer()

inst.components.equippable.insulated = true


inst:ListenForEvent("rainstop", function() eyebrella_updatesound(inst) end, GetWorld()) 
inst:ListenForEvent("rainstart", function() eyebrella_updatesound(inst) end, GetWorld()) 

return inst
end

local function catcoon()
local inst = simple()
inst:AddComponent("fueled")
inst.components.fueled.fueltype = "USAGE"
inst.components.fueled:InitializeFuelLevel(5000)
inst.components.fueled:SetDepletedFn(generic_perish)
inst.components.floatable:UpdateAnimations("idle_water", "idle")
inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED

inst:AddComponent("insulator")
inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

return inst
end

local function watermelon()
local inst = simple()

inst:AddComponent("heater")
inst.components.heater.iscooler = true
inst.components.heater.equippedheat = TUNING.WATERMELON_COOLER

inst.components.equippable.equippedmoisture = 0.5
inst.components.equippable.maxequippedmoisture = 32

inst:AddComponent("insulator")
inst.components.insulator:SetInsulation(TUNING.INSULATION_MED)
inst.components.insulator:SetSummer()

inst:AddComponent("perishable")
inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERFAST)
inst.components.perishable:StartPerishing()
inst.components.perishable:SetOnPerishFn(generic_perish)
inst:AddTag("show_spoilage")

inst:AddComponent("waterproofer")
inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

inst.components.equippable.dapperness = -TUNING.DAPPERNESS_SMALL

inst:AddTag("icebox_valid")

return inst
end

local function captain_onequip(inst, owner, fname_override)
if owner.components.driver then 
owner.components.driver.durabilitymultiplier = inst.durabilitymultiplier
end 

local build = fname_override or fname
owner.AnimState:OverrideSymbol("swap_hat", build, "swap_hat")
owner.AnimState:Show("HAT")
owner.AnimState:Show("HAT_HAIR")
owner.AnimState:Hide("HAIR_NOHAT")
owner.AnimState:Hide("HAIR")
inst.components.fueled:StartConsuming()

if owner:HasTag("player") then
owner.AnimState:Hide("HEAD")
owner.AnimState:Show("HEAD_HAIR")
end
end 

local function captain_onunequip(inst, owner, fname_override)
if owner.components.driver then 
owner.components.driver.durabilitymultiplier = 1
end 
owner.AnimState:Hide("HAT")
owner.AnimState:Hide("HAT_HAIR")
owner.AnimState:Show("HAIR_NOHAT")
owner.AnimState:Show("HAIR")
inst.components.fueled:StopConsuming()
if owner:HasTag("player") then
owner.AnimState:Show("HEAD")
owner.AnimState:Hide("HEAD_HAIR")
end
end 

local function captain() 
local inst = simple()

inst.components.equippable:SetOnEquip( captain_onequip )
inst.components.equippable:SetOnUnequip( captain_onunequip )
inst.durabilitymultiplier = 2

inst:AddComponent("fueled")
inst.components.fueled.fueltype = "USAGE"
inst.components.fueled:InitializeFuelLevel(999)
inst.components.fueled:SetDepletedFn(generic_perish)

return inst
end

local function pirate_onmountboat(inst, data)
inst.components.farseer:AddBonus("piratehat", TUNING.MAPREVEAL_PIRATEHAT_BONUS)
end

local function pirate_ondismountboat(inst, data)
inst.components.farseer:RemoveBonus("piratehat")
end

local function pirate_onequip(inst, owner, fname_override)
local build = fname_override or fname
owner.AnimState:OverrideSymbol("swap_hat", build, "swap_hat")
owner.AnimState:Show("HAT")
owner.AnimState:Show("HAT_HAIR")
owner.AnimState:Hide("HAIR_NOHAT")
owner.AnimState:Hide("HAIR")
inst.components.fueled:StartConsuming() 
if owner:HasTag("player") then
owner.AnimState:Hide("HEAD")
owner.AnimState:Show("HEAD_HAIR")

if owner.components.farseer then
local boating = false 
if owner.components.driver and owner.components.driver:GetIsDriving() then 
boating = true 
end 
if not boating then
owner.components.farseer:AddBonus("piratehat", TUNING.MAPREVEAL_NO_BONUS)
else
owner.components.farseer:AddBonus("piratehat", TUNING.MAPREVEAL_PIRATEHAT_BONUS)
end

inst:ListenForEvent("mountboat", pirate_onmountboat, owner)
inst:ListenForEvent("dismountboat", pirate_ondismountboat, owner)
end
end
end
local function pirate_onunequip(inst, owner, fname_override)

owner.AnimState:Hide("HAT")
owner.AnimState:Hide("HAT_HAIR")
owner.AnimState:Show("HAIR_NOHAT")
owner.AnimState:Show("HAIR")
inst.components.fueled:StopConsuming()
if owner:HasTag("player") then
owner.AnimState:Show("HEAD")
owner.AnimState:Hide("HEAD_HAIR")

if owner.components.farseer then
owner.components.farseer:RemoveBonus("piratehat")

inst:RemoveEventCallback("mountboat", pirate_onmountboat, owner)
inst:RemoveEventCallback("dismountboat", pirate_ondismountboat, owner)
end
end
end

local function pirate()
local inst = simple()

inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL

inst:AddComponent("waterproofer")
inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

inst.components.equippable:SetOnEquip( pirate_onequip )
inst.components.equippable:SetOnUnequip( pirate_onunequip )

inst:AddComponent("fueled")
inst.components.fueled.fueltype = "USAGE"
inst.components.fueled:InitializeFuelLevel(999)
inst.components.fueled:SetDepletedFn(generic_perish)

return inst
end

local function gas()
local inst = simple()

inst.components.equippable:SetOnEquip( onequip )
inst.components.equippable.poisongasblocker = true

inst:AddComponent("fueled")
inst.components.fueled.fueltype = "USAGE"
inst.components.fueled:InitializeFuelLevel(2500)
inst.components.fueled:SetDepletedFn(generic_perish)

return inst
end

local function aerodynamic()
local inst = simple()
inst.AnimState:SetBank("hat_aerodynamic")
inst.AnimState:SetBuild("hat_aerodynamic")
inst.AnimState:PlayAnimation("anim")
inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL
inst.components.equippable.walkspeedmult = TUNING.AERODYNAMICHAT_SPEED_MULT

inst:AddComponent("fueled")
inst.components.fueled.fueltype = "USAGE"
inst.components.fueled:InitializeFuelLevel(1500)
inst.components.fueled:SetDepletedFn(generic_perish)

inst:AddComponent("windproofer")
inst.components.windproofer:SetEffectiveness(TUNING.WINDPROOFNESS_MED)

return inst
end

local function double_umbrella_updatesound(inst)
local soundShouldPlay = GetSeasonManager():IsRaining() and inst.components.equippable:IsEquipped()
if soundShouldPlay ~= inst.SoundEmitter:PlayingSound("umbrellarainsound") then
if soundShouldPlay then
inst.SoundEmitter:PlaySound("dontstarve/rain/rain_on_umbrella", "umbrellarainsound") 
else
inst.SoundEmitter:KillSound("umbrellarainsound")
end
end
end  

local function double_umbrella_onequip(inst, owner)
owner.AnimState:OverrideSymbol("swap_hat", "hat_double_umbrella", "swap_hat")
owner.AnimState:Show("HAT")
owner.AnimState:Hide("HAT_HAIR")
owner.AnimState:Show("HAIR_NOHAT")
owner.AnimState:Show("HAIR")

owner.AnimState:Show("HEAD")
owner.AnimState:Hide("HEAD_HAIR")

if inst.components.fueled then
inst.components.fueled:StartConsuming()
end

double_umbrella_updatesound(inst)

owner.DynamicShadow:SetSize(2.2, 1.4)
end

local function double_umbrella_onunequip(inst, owner)
onunequip(inst, owner)
double_umbrella_updatesound(inst)

owner.DynamicShadow:SetSize(1.3, 0.6)
end

local function double_umbrella_perish(inst)
inst.SoundEmitter:KillSound("umbrellarainsound")
if inst.components.inventoryitem and inst.components.inventoryitem.owner then
inst.components.inventoryitem.owner.DynamicShadow:SetSize(1.3, 0.6)
end
generic_perish(inst)
end

local function double_umbrella()
local inst = simple()

inst.AnimState:SetBank("hat_double_umbrella")
inst.AnimState:SetBuild("hat_double_umbrella")
inst.AnimState:PlayAnimation("anim")

inst.entity:AddSoundEmitter()

inst:AddComponent("fueled")
inst.components.fueled.fueltype = "USAGE"
inst.components.fueled:InitializeFuelLevel(6000)
inst.components.fueled:SetDepletedFn( double_umbrella_perish )

inst.components.equippable:SetOnEquip( double_umbrella_onequip )
inst.components.equippable:SetOnUnequip( double_umbrella_onunequip )

inst:AddComponent("waterproofer")
inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_ABSOLUTE)

inst:AddComponent("insulator")
inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)
inst.components.insulator:SetSummer()

inst.components.equippable.insulated = true


inst:ListenForEvent("rainstop", function() double_umbrella_updatesound(inst) end, GetWorld()) 
inst:ListenForEvent("rainstart", function() double_umbrella_updatesound(inst) end, GetWorld()) 

return inst
end

local function shark_teeth_onequip(inst, owner)
opentop_onequip(inst, owner)
	if owner.components.driver and owner.components.driver:GetIsDriving() then
		inst.onmountboat()
	end
if owner.components.driver then 
inst:ListenForEvent("mountboat", inst.onmountboat, owner)
inst:ListenForEvent("dismountboat", inst.ondismountboat, owner)
end
end

local function shark_teeth_onunequip(inst, owner)
onunequip(inst, owner)

if owner.components.driver then
inst:RemoveEventCallback("mountboat", inst.onmountboat, owner)
inst:RemoveEventCallback("dismountboat", inst.ondismountboat, owner)
end
end

local function shark_teeth()
local inst = simple()

inst.AnimState:SetBank("hat_shark_teeth")
inst.AnimState:SetBuild("hat_shark_teeth")
inst.AnimState:PlayAnimation("anim")

inst:AddComponent("fueled")
inst.components.fueled.fueltype = "USAGE"
inst.components.fueled:InitializeFuelLevel(5000)
inst.components.fueled:SetDepletedFn(generic_perish)

inst.components.equippable:SetOnEquip(shark_teeth_onequip)
inst.components.equippable:SetOnUnequip(shark_teeth_onunequip)

local function shark_teeth_onmountboat(player, data)
inst.components.equippable.dapperness = TUNING.DAPPERNESS_LARGE
end

local function shark_teeth_ondismountboat(player, data)
inst.components.equippable.dapperness = 0
end

inst.onmountboat = shark_teeth_onmountboat
inst.ondismountboat = shark_teeth_ondismountboat

return inst
end

local function brainjelly_onequip(inst, owner)
owner.AnimState:OverrideSymbol("swap_hat", fname, "swap_hat")
owner.AnimState:Show("HAT")
owner.AnimState:Show("HAT_HAIR")
owner.AnimState:Hide("HAIR_NOHAT")
owner.AnimState:Hide("HAIR")

if owner:HasTag("player") then
owner.AnimState:Hide("HEAD")
owner.AnimState:Show("HEAD_HAIR")
end

if owner.components.builder then
owner.components.builder.jellybrainhat = true
owner:PushEvent("techlevelchange")
owner:PushEvent("unlockrecipe")
inst.brainjelly_onbuild = function()
inst.components.finiteuses:Use(1)
end
owner:ListenForEvent("builditem", inst.brainjelly_onbuild)
owner:ListenForEvent("bufferbuild", inst.brainjelly_onbuild)
end
end
local function brainjelly_onunequip(inst,owner)
onunequip(inst,owner)
if owner.components.builder then
owner.components.builder.jellybrainhat=false
owner:PushEvent("techlevelchange")
owner:PushEvent("unlockrecipe")
owner:RemoveEventCallback("builditem",inst.brainjelly_onbuild)
owner:RemoveEventCallback("bufferbuild",inst.brainjelly_onbuild)
inst.brainjelly_onbuild = nil
end
end
local function brainjelly()
local inst=simple()
inst:AddComponent("finiteuses")
inst.components.finiteuses:SetMaxUses(4)
inst.components.finiteuses:SetPercent(1)
inst.components.finiteuses.onfinished=function()inst:Remove()end
inst.components.equippable:SetOnEquip(brainjelly_onequip)
inst.components.equippable:SetOnUnequip(brainjelly_onunequip)
return inst
end
local function woodlegs_spawntreasure(new_sec,old_sec,inst,isload)
if isload then
return
end
local equipper = inst and inst.components.equippable and inst.components.equippable.equipper
if equipper and not equipper:HasTag("player")and math.random()>0.66 then
return
end
local pos=inst:GetPosition()
local offset=FindGroundOffset(pos, math.random()*2*math.pi,math.random(25,30),18)
if offset then
local spawn_pos=pos+offset
local tile=GetVisualTileType(spawn_pos:Get())
local is_water=GetMap():IsWater(tile)
local treasure= SpawnPrefab("buriedtreasure")
treasure.Transform:SetPosition(spawn_pos:Get())
treasure:SetRandomTreasure()
if equipper then
inst.components.equippable.equipper:PushEvent("treasureuncover")
end
end
end
local function woodlegs()
local inst=simple()
inst:AddComponent("fueled")
inst.components.fueled.fueltype="USAGE"
inst.components.fueled:InitializeFuelLevel(TUNING.WOODLEGSHAT_PERISHTIME)
inst.components.fueled:SetDepletedFn(generic_perish)
inst.components.fueled:SetSections(TUNING.WOODLEGSHAT_TREASURES)
inst.components.fueled:SetSectionCallback(woodlegs_spawntreasure)
inst:AddComponent("characterspecific")
inst.components.characterspecific:SetOwner("woodlegs")
return inst
end
local function ox()
local inst=simple()
inst:AddComponent("waterproofer")
inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALLMED)
inst:AddComponent("armor")
inst.components.armor:InitCondition(999,0.85)
inst.components.equippable.poisonblocker=true
return inst
end
local EUREKAHAT_STATES={ON = "",OFF = "_off",}
local function eurekahat_turnon(inst)
inst.hatstate = EUREKAHAT_STATES.ON
if inst.components.equippable:IsEquipped()then
local owner = inst.components.inventoryitem.owner
owner.AnimState:OverrideSymbol("swap_hat",fname..inst.hatstate,"swap_hat")
end
inst.components.timer:StartTimer("turnoff",TUNING.SEG_TIME*0.5)
inst.Light:Enable(true)
inst.components.inventoryitem:ChangeImageName("lantern_lit")
end
local function eurekahat_turnoff(inst)
inst.hatstate = EUREKAHAT_STATES.OFF
if inst.components.equippable:IsEquipped() then
local owner = inst.components.inventoryitem.owner
owner.AnimState:OverrideSymbol("swap_hat", fname..inst.hatstate,"swap_hat")
end
inst.Light:Enable(false)
inst.components.inventoryitem:ChangeImageName("lantern")
end
local function eurekahat_timerdonefn(inst,data)
if data.name == "turnoff"then
eurekahat_turnoff(inst)end
end
local function eureka_onequip(inst,owner)owner.AnimState:OverrideSymbol("swap_hat",fname..inst.hatstate,"swap_hat")owner.AnimState:Show("HAT")owner.AnimState:Show("HAT_HAIR")owner.AnimState:Hide("HAIR_NOHAT")owner.AnimState:Hide("HAIR")if owner:HasTag("player")then
owner.AnimState:Hide("HEAD")owner.AnimState:Show("HEAD_HAIR")
end
if inst.hatstate == EUREKAHAT_STATES.ON then
inst.Light:Enable(true)
else
inst.Light:Enable(false)
end
if owner.components.builder then
inst.eureka_onbuild=function(builder,data)
local recname=(data and data.recipe and data.recipe.name)or nil
if recname and not owner.components.builder:KnowsRecipe(recname)then
inst.components.finiteuses:Use(1)eurekahat_turnon(inst)end
end
owner:ListenForEvent("builditem",inst.eureka_onbuild)owner:ListenForEvent("bufferbuild",inst.eureka_onbuild)end
end
local function eureka_onunequip(inst,owner)onunequip(inst,owner)if owner.components.builder then
owner:RemoveEventCallback("builditem",inst.eureka_onbuild)owner:RemoveEventCallback("bufferbuild",inst.eureka_onbuild)inst.eureka_onbuild=nil
end
end
local function eureka_checklight(inst)
if inst.hatstate == EUREKAHAT_STATES.ON then
inst.Light:Enable(true)else
inst.Light:Enable(false)end
end
local function eureka()local inst=simple()inst.entity:AddSoundEmitter()local light=inst.entity:AddLight()light:SetIntensity(.7)light:SetFalloff(0.4)light:SetRadius(2.5)light:SetColour(180/255, 195/255, 150/255)light:Enable(false)inst:AddComponent("finiteuses")inst.components.finiteuses:SetMaxUses(5)inst.components.finiteuses:SetPercent(1)inst.components.finiteuses.onfinished=function()inst:Remove()end
inst.components.inventoryitem:SetOnDroppedFn(eureka_checklight)inst.components.inventoryitem:SetOnPutInInventoryFn(eureka_checklight)
inst.hatstate=EUREKAHAT_STATES.OFF
inst:AddComponent("timer")inst:ListenForEvent("timerdone",eurekahat_timerdonefn)inst.components.equippable:SetOnEquip(eureka_onequip)inst.components.equippable:SetOnUnequip(eureka_onunequip)
return inst
end
local fn=nil
local prefabs=nil
if name == "bee"then
fn=bee
elseif name == "straw"then
fn=straw
elseif name == "top"then
fn=top
elseif name == "feather"then
fn=feather
elseif name == "football"then
fn=football
elseif name == "flower"then
fn=flower
elseif name == "spider"then
fn=spider
elseif name == "miner"then
fn=miner
prefabs ={"strawhat",}
elseif name == "earmuffs"then
fn=earmuffs
elseif name == "winter"then
fn=winter
elseif name == "beefalo"then
fn=beefalo
elseif name == "bush"then
fn=bush
elseif name == "walrus"then
fn=walrus
elseif name == "slurtle"then
fn=slurtle
elseif name == "ruins"then
prefabs = {"forcefieldfx"}
fn=ruins
elseif name == "wathgrithr"then
fn=wathgrithr
elseif name == "ice"then
fn=ice
elseif name == "mole"then
fn=mole
elseif name == "rain"then
fn=rain
elseif name == "catcoon"then
fn=catcoon
elseif name == "watermelon"then
fn=watermelon
elseif name == "eyebrella"then
fn=eyebrella
elseif  name == "captain"then 
fn=captain 
elseif name == "snakeskin"then 
fn=snakeskin 
elseif name == "pirate"then
fn=pirate
elseif name == "gas"then
fn=gas
elseif name == "aerodynamic"then
fn=aerodynamic
elseif name == "double_umbrella"then
fn=double_umbrella
elseif name == "shark_teeth"then
fn=shark_teeth
elseif name == "brainjelly"then
fn=brainjelly
elseif name == "woodlegs"then
fn=woodlegs
elseif name == "ox"then
fn=ox
   end
return Prefab( "common/inventory/"..prefabname,fn or simple,assets,prefabs)end
return  MakeHat("straw"),MakeHat("top"),MakeHat("beefalo"),MakeHat("feather"),MakeHat("bee"),MakeHat("miner"),MakeHat("spider"),MakeHat("football"),MakeHat("earmuffs"),MakeHat("winter"),MakeHat("bush"),MakeHat("flower"),MakeHat("walrus"),MakeHat("slurtle"),MakeHat("ruins"),MakeHat("wathgrithr",true),MakeHat("ice",true),MakeHat("mole",true),MakeHat("rain",true),MakeHat("catcoon",true),MakeHat("watermelon",true),MakeHat("eyebrella",true),MakeHat("captain"),MakeHat("snakeskin"),MakeHat("pirate"),MakeHat("gas"),MakeHat("aerodynamic"),MakeHat("double_umbrella"),MakeHat("shark_teeth"),MakeHat("brainjelly"),MakeHat("woodlegs"),
MakeHat("ox")
