local Screen = require "widgets/screen"
local ContainerWidget = require("widgets/containerwidget")
local Controls = require("widgets/controls")
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local IceOver = require "widgets/iceover"
local FireOver = require "widgets/fireover"
local BloodOver = require "widgets/bloodover"
local HeatOver = require "widgets/heatover"
local PoisonOver = require "widgets/poisonover"
local BoatOver = require "widgets/boatover"

local easing = require("easing")

local ConsoleScreen = require "screens/consolescreen"
local MapScreen = require "screens/mapscreen"
local PauseScreen = require "screens/pausescreen"

local PlayerHud = Class(Screen, function(self)
	Screen._ctor(self, "HUD")
    
    self.overlayroot = self:AddChild(Widget("overlays"))

    self.under_root = self:AddChild(Widget("under_root"))
    self.root = self:AddChild(Widget("root"))

    self.isLastOpenInventory = false
end)

function PlayerHud:CreateOverlays(owner)
	
	self.overlayroot:KillAllChildren()

    self.vig = self.overlayroot:AddChild(UIAnim())
    self.vig:GetAnimState():SetBuild("vig")
    self.vig:GetAnimState():SetBank("vig")
    self.vig:GetAnimState():PlayAnimation("basic", true)
    self.vig:GetAnimState():SetLayer(LAYER_PRE_FRONTEND)

    self.vig:SetHAnchor(ANCHOR_MIDDLE)
    self.vig:SetVAnchor(ANCHOR_MIDDLE)
    self.vig:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)

    self.vig:SetClickable(false)
    
    self.bloodover = self.overlayroot:AddChild(BloodOver(owner))
    self.boatover = self.overlayroot:AddChild(BoatOver(owner))
    self.poisonover = self.overlayroot:AddChild(PoisonOver(owner))
    self.iceover = self.overlayroot:AddChild(IceOver(owner))
    self.fireover = self.overlayroot:AddChild(FireOver(owner))
    self.heatover = self.overlayroot:AddChild(HeatOver(owner))
    self.iceover:Hide()
    self.fireover:Hide()
    self.heatover:Hide()


    self.clouds = self.overlayroot:AddChild(UIAnim())
    self.clouds:SetClickable(false)
    self.clouds:SetHAnchor(ANCHOR_MIDDLE)
    self.clouds:SetVAnchor(ANCHOR_MIDDLE)
    self.clouds:GetAnimState():SetBank("clouds_ol")
    self.clouds:GetAnimState():SetBuild("clouds_ol")
    self.clouds:GetAnimState():PlayAnimation("idle", true)
    self.clouds:GetAnimState():SetMultColour(1,1,1,0)
    self.clouds:GetAnimState():SetLayer(LAYER_PRE_FRONTEND)
    self.clouds:Hide()

    --[[self.oceanfog = self.overlayroot:AddChild(UIAnim())
    self.oceanfog:SetClickable(false)
    self.oceanfog:SetHAnchor(ANCHOR_MIDDLE)
    self.oceanfog:SetVAnchor(ANCHOR_MIDDLE)
    self.oceanfog:GetAnimState():SetBank("clouds_ol")
    self.oceanfog:GetAnimState():SetBuild("clouds_ol")
    self.oceanfog:GetAnimState():PlayAnimation("idle", true)
    self.oceanfog:GetAnimState():SetMultColour(1,1,1,0)
    self.oceanfog:Hide()]]

    self.smoke = self.overlayroot:AddChild(UIAnim())
    self.smoke:SetClickable(false)
    self.smoke:SetHAnchor(ANCHOR_MIDDLE)
    self.smoke:SetVAnchor(ANCHOR_MIDDLE)
    self.smoke:GetAnimState():SetBank("clouds_ol")
    self.smoke:GetAnimState():SetBuild("clouds_ol")
    self.smoke:GetAnimState():PlayAnimation("idle", true)
    self.smoke:GetAnimState():SetMultColour(1,1,1,0)
    self.smoke:Hide()

end

function PlayerHud:OnHide()
    if self.controls then
        local hover = self.controls.hover;
        if hover.inMenu then
            hover:EndMenu()
        end
    end
end

function PlayerHud:OnLoseFocus()
	Screen.OnLoseFocus(self)
	TheInput:EnableMouse(true)

	--[[
	if self:IsControllerCraftingOpen() then
		self:CloseControllerCrafting()
	end

	if self:IsControllerInventoryOpen() then
		self:CloseControllerInventory()
	end
	--]]

	local is_controller_attached = TheInput:ControllerAttached()
	if is_controller_attached then
		self.owner.components.inventory:ReturnActiveItem()
	end
	self.controls.hover:Hide()
end

function PlayerHud:OnGainFocus()
	Screen.OnGainFocus(self)
	local controller = TheInput:ControllerAttached()
	if controller then
		TheInput:EnableMouse(false)
	else
		TheInput:EnableMouse(true)
	end
	
	if self.controls then
		self.controls:SetHUDSize()
        self.controls:ShowActionControls()
        self.controls:ShowRecordControls()
        if not self:IsPhoneControllerInventoryOpen() then
            self.controls:ShowVirtualStick()
        end
		if controller then
			self.controls.hover:Hide()
		else
			self.controls.hover:Show()
		end
	end
	
	if not TheInput:ControllerAttached() then
		if self:IsControllerCraftingOpen() then
			self:CloseControllerCrafting()
		end

		if self:IsControllerInventoryOpen() then
			self:CloseControllerInventory()
		end
	end

end
	
function PlayerHud:Toggle()
	self.shown = not self.shown
	if self.shown then
		self.root:Show()
	else
		self.root:Hide()
	end
end

function PlayerHud:Hide()
	self.shown = false
	self.root:Hide()
end

function PlayerHud:Show()
	self.shown = true
	self.root:Show()
end

function PlayerHud:IsCraftingOpen()
return self.controls ~= nil and self.controls.crafttabs:IsCraftingOpen()
end

function PlayerHud:OpenBoat(boat, riding)
	if boat then
		local boatwidget = nil
		if riding then
			self.controls.inv.boatwidget = self.controls.inv.root:AddChild(ContainerWidget(self.owner))
			boatwidget = self.controls.inv.boatwidget
			boatwidget:SetScale(1)
			boatwidget.scalewithinventory = false
			boatwidget:MoveToBack()
			self.controls.inv:Rebuild()
		else
			boatwidget = self.controls.containerroot:AddChild(ContainerWidget(self.owner))
		end

		boatwidget:Open(boat, self.owner, not riding)

		for k,v in pairs(self.controls.containers) do
			if v.container then
				if v.parent == boatwidget.parent or k == boat then
					v:Close()
				end
			else
				self.controls.containers[k] = nil
			end
		end
	    
		self.controls.containers[boat] = boatwidget
	end
end

function PlayerHud:CloseContainer(container)
    for k,v in pairs(self.controls.containers) do
		if v.container == container then
			v:Close()
		end
    end
end

function PlayerHud:GetOpenContainerWidgets()
	return self.controls.containers
end


function PlayerHud:GetFirstOpenContainerWidget()
	local k,v = next(self.controls.containers)
	return v
end

function PlayerHud:OpenContainer(container, side)

	if side and (TheInput:ControllerAttached() or IPHONE_VERSION) then
		return
	end

	if container then
		local containerwidget = nil
		if side then
			containerwidget = self.controls.containerroot_side:AddChild(ContainerWidget(self.owner))
		else
			containerwidget = self.controls.containerroot:AddChild(ContainerWidget(self.owner))
		end
		containerwidget:Open(container, self.owner)
	    
		for k,v in pairs(self.controls.containers) do
			if v.container then
		
				if TheInput:ControllerAttached() then	
					if v.container.prefab == container.prefab or v.parent == containerwidget.parent then
						v:Close()
					end
				else
					if v.container.prefab == container.prefab or v.container.components.container.type == container.components.container.type then
						v:Close()
					end
				end
			else
				self.controls.containers[k] = nil
			end
		end
	    
		self.controls.containers[container] = containerwidget
	end
end

function PlayerHud:GoSane()
    self.vig:GetAnimState():PlayAnimation("basic", true)
end

function PlayerHud:GoInsane()
    self.vig:GetAnimState():PlayAnimation("insane", true)
end

function PlayerHud:SetMainCharacter(maincharacter)
    if maincharacter then
		maincharacter.HUD = self
		self.owner = maincharacter

		self:CreateOverlays(self.owner)
		self.controls = self.root:AddChild(Controls(self.owner))

		self.inst:ListenForEvent("badaura", function(inst, data) return self.bloodover:Flash() end, self.owner)
		self.inst:ListenForEvent("attacked", function(inst, data) return self.bloodover:Flash() end, self.owner)
		self.inst:ListenForEvent("startstarving", function(inst, data) self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("stopstarving", function(inst, data) self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("startfreezing", function(inst, data) self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("stopfreezing", function(inst, data) self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("startoverheating", function(inst, data) self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("stopoverheating", function(inst, data) self.bloodover:UpdateState() end, self.owner)
		self.inst:ListenForEvent("gosane", function(inst, data) self:GoSane() end, self.owner)
		self.inst:ListenForEvent("goinsane", function(inst, data) self:GoInsane() end, self.owner)
		
		self.inst:ListenForEvent("poisondamage", function(inst, data) return self.poisonover:Flash() end, self.owner)
		self.inst:ListenForEvent("boatattacked", function(inst, data) return self.boatover:Flash() end, self.owner)

		if not self.owner.components.sanity:IsSane() then
			self:GoInsane()
		end
		self.controls.crafttabs:UpdateRecipes()
		
		local bp = maincharacter.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
		if bp and bp.components.container then
			bp.components.container:Close()
			bp.components.container:Open(maincharacter)
		end
	end
end

function PlayerHud:OnUpdate(dt)
	self:UpdateClouds(dt)
	--self:UpdateOceanFog(dt)
	self:UpdateSmoke(dt)
	
	if Profile and self.vig then
		if RENDER_QUALITY.LOW == Profile:GetRenderQuality() or TheConfig:IsEnabled("hide_vignette") then
			self.vig:Hide()
		else
			self.vig:Show()
		end
	end
end

function PlayerHud:HideControllerCrafting()
	
	self.controls.crafttabs:MoveTo(self.controls.crafttabs:GetPosition(), Vector3(-200, 0, 0), .25)
end

function PlayerHud:ShowControllerCrafting()
	self.controls.crafttabs:MoveTo(self.controls.crafttabs:GetPosition(), Vector3(0,0,0), .25)
end


function PlayerHud:OpenControllerInventory()
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_open")
	TheFrontEnd:StopTrackingMouse()
	self:CloseControllerCrafting()
	self:HideControllerCrafting()
	self.controls.inv:OpenControllerInventory()
	self.controls:ShowStatusNumbers()

	self.owner.components.playercontroller:OnUpdate(0)
end

function PlayerHud:CloseControllerInventory()
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_close")
	self.controls:HideStatusNumbers()
	self:ShowControllerCrafting()
	self.controls.inv:CloseControllerInventory()
end

function PlayerHud:ClosePhoneInventory()
    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_close")
    --self.controls:HideStatusNumbers()
    --self:ShowControllerCrafting()
    self.controls.inv:ClosePhoneInventory()
end

function PlayerHud:IsControllerInventoryOpen()
	return false--self.controls and self.controls.inv.open
end

function PlayerHud:IsPhoneControllerInventoryOpen()
    return self.controls and self.controls.inv.open
end

function PlayerHud:IsCraftingOpen()
    return self.controls ~= nil and self.controls.crafttabs:IsCraftingOpen()
end

function PlayerHud:IsPhoneControllerInventoryOpen()
    return self.controls and self.controls.inv.open
end

function PlayerHud:OpenControllerCrafting()
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_open")
	TheFrontEnd:StopTrackingMouse()
	self:CloseControllerInventory()
	self.controls.inv:Disable()
	self.controls.crafttabs:OpenControllerCrafting()
	self.owner.components.locomotor:Stop()
	--self.owner.components.playercontroller.draggingonground = false
	--self.owner.components.playercontroller.startdragtime = nil
end

function PlayerHud:CloseControllerCrafting()
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_close")
	self.controls.crafttabs:CloseControllerCrafting()	
	self.controls.inv:Enable()
end

function PlayerHud:ClosePhoneCrafting()
TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/craft_close")
self.controls.crafttabs:ClosePhoneCraftTabs()
end

function PlayerHud:IsControllerCraftingOpen()
	return self.controls and self.controls.crafttabs.controllercraftingopen
end

function PlayerHud:IsPhoneControllerCraftingOpen()
    return self.controls and self.controls.crafttabs.open
end

function PlayerHud:OnControl(control, down)
	if PlayerHud._base.OnControl(self, control, down) then return true end
	if not self.shown then return end


	if not down and control == CONTROL_PAUSE then
		TheFrontEnd:PushScreen(PauseScreen())
		return true
	end

	if not down and control == CONTROL_MAP then
		
		
		if not self.owner:HasTag("beaver") then
			self.controls:ToggleMap()			
			return true
		end
	end
	
	if not down and control == CONTROL_CANCEL then
		if self:IsControllerCraftingOpen() then
			self:CloseControllerCrafting()
		end

		if self:IsControllerInventoryOpen() then
			self:CloseControllerInventory()
		end
	end

	
	if down and control == CONTROL_OPEN_CRAFTING then
		if self:IsControllerCraftingOpen() then
			self:CloseControllerCrafting()
		elseif not self.owner:HasTag("beaver") then
			self:OpenControllerCrafting()
		end
	end

	if down and control == CONTROL_OPEN_INVENTORY then
		if self:IsControllerInventoryOpen() then
			self:CloseControllerInventory()
		elseif not self.owner:HasTag("beaver") then
			self:OpenControllerInventory()
		end
	end
	
	if not self.owner:HasTag("beaver") then
		--inventory hotkeys
		if down and control >= CONTROL_INV_1 and control <= CONTROL_INV_10 then
			local num = (control - CONTROL_INV_1) + 1
			local item = self.owner.components.inventory:GetItemInSlot(num)
			self.owner.components.inventory:UseItemFromInvTile(item)
			return true
		end
	end
end

function PlayerHud:OnRawKey( key, down )
	if PlayerHud._base.OnRawKey(self, key, down) then return true end
end

function PlayerHud:UpdateClouds(dt)
   if not GetWorld():IsCave() then
	    --this is kind of a weird place to do all of this, but the anim *is* a hud asset...
	    local timeSinceZoom = TheCamera:GetTimeSinceZoom() or 1
	    if TheCamera and TheCamera.distance and not TheCamera.dollyzoom and TheCamera:IsControllable() and timeSinceZoom < 1 then --last two conditions are to keep clouds away from the volcano auto-zoom
	        local dist_percent = (TheCamera.distance - TheCamera.mindist) / (TheCamera.maxdist - TheCamera.mindist)
	        local cutoff = .6
	        if dist_percent > cutoff then
	            if not self.clouds_on then
					TheCamera.should_push_down = true
	                self.clouds_on = true
	                self.clouds:Show()
	                self.owner.SoundEmitter:PlaySound("dontstarve/common/clouds", "windsound")
	                TheMixer:PushMix("high")
	            end
	            
	            local p = easing.outCubic( dist_percent-cutoff , 0, 1, 1 - cutoff) 
	            self.clouds:GetAnimState():SetMultColour(1,1,1, p )
	            self.owner.SoundEmitter:SetVolume("windsound",p)
	        else
	            if self.clouds_on then
					TheCamera.should_push_down = false
	                self.clouds_on = false
	                self.clouds:Hide()
	                self.owner.SoundEmitter:KillSound("windsound")
	                TheMixer:PopMix("high")
	            end
	        end
	    end
	end
end

function PlayerHud:UpdateOceanFog(dt)
	local mapwrapper = GetPlayer().components.mapwrapper
	if mapwrapper and self.oceanfog then
		local x, y, z = GetPlayer().Transform:GetLocalPosition()
		local dist = mapwrapper:GetDistanceFromEdge(x, y, z)
		local distMax = TUNING.MAPWRAPPER_WARN_RANGE * TILE_SCALE
		local distMin = TUNING.MAPWRAPPER_LOSECONTROL_RANGE * TILE_SCALE

		if dist < distMax then
			local p = 1 - easing.outCubic(dist - distMin, 0, 1, distMax - distMin)

			self.oceanfog:Show()
			self.oceanfog:GetAnimState():SetMultColour(1, 1, 1, p)
		else
			self.oceanfog:Hide()
		end
	end
end

function PlayerHud:UpdateSmoke(dt)
	local vm = GetWorld().components.volcanomanager
	if self.smoke and vm then
		local rate = vm:GetSmokeRate()
		if rate > 0.0 then
			local g = 0.5
			local a = math.sin(PI*rate)
			self.smoke:Show()
			self.smoke:GetAnimState():SetMultColour(g, g, g, a)
			--[[local x, y, z = GetPlayer().Transform:GetLocalPosition()
			local dist = vm:GetDistanceFromVolcano(x, y, z)
			local distMax = 250 * TILE_SCALE
			local distMin = 25 * TILE_SCALE

			--print(string.format("%f < %f\n", dist, distMax))
			if dist < distMax then
				local p = 1 - easing.outCubic(dist - distMin, 0, 1, distMax - distMin)
				local g = easing.inOutSine(dist - distMin, 0.25, 0.5, distMax - distMin)
				--print(string.format("(%f, %f)\n", g, p))

				self.smoke:Show()
				self.smoke:GetAnimState():SetMultColour(g, g, g, p)
			else
				self.smoke:Hide()
			end]]
		else
			self.smoke:Hide()
		end
	end
end

return PlayerHud

