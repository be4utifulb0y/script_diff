local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
require("constants")


local ItemTile = Class(Widget, function(self, invitem)
    Widget._ctor(self, "ItemTile")
    self.item = invitem

	-- NOT SURE WAHT YOU WANT HERE
	if invitem.components.inventoryitem == nil then
		print("NO INVENTORY ITEM COMPONENT"..tostring(invitem.prefab), invitem)
		return
	end
	
	self.bg = self:AddChild(Image())
	self.bg:SetTexture(HUD_ATLAS, "inv_slot_spoiled.tex")
	self.bg:Hide()
	self.bg:SetClickable(false)
	self.basescale = 1
	
    self.fusebg = self:AddChild(Image())
    self.fusebg:SetTexture(HUD_ATLAS, "resource_needed.tex")
    self.fusebg:SetClickable(false)
    self.fusebg:Hide()
    self.basescale = 1

	self.spoilage = self:AddChild(UIAnim())
    self.spoilage:GetAnimState():SetBank("spoiled_meter")
    self.spoilage:GetAnimState():SetBuild("spoiled_meter")
    self.spoilage:Hide()
    self.spoilage:SetClickable(false)

    self.invspace = self:AddChild(UIAnim())
    self.invspace:GetAnimState():SetBank("trawlnet_meter")
    self.invspace:GetAnimState():SetBuild("trawlnet_meter")
    self.invspace:Hide()
    self.invspace:SetClickable(false)

    self.obsidian_charge = self:AddChild(UIAnim())
    self.obsidian_charge:GetAnimState():SetBank("obsidian_tool_meter")
    self.obsidian_charge:GetAnimState():SetBuild("obsidian_tool_meter")
    self.obsidian_charge:Hide()
    self.obsidian_charge:SetClickable(false)

    self.wetness = self:AddChild(UIAnim())
    self.wetness:GetAnimState():SetBank("wet_meter")
	self.wetness:GetAnimState():SetBuild("wet_meter")
    self.wetness:GetAnimState():PlayAnimation("idle")
    self.wetness:Hide()
    self.wetness:SetClickable(false)
	
    self.image = self:AddChild(Image(invitem.components.inventoryitem:GetAtlas(), invitem.components.inventoryitem:GetImage()))
    --self.image:SetClickable(false)

    local owner = self.item.components.inventoryitem.owner
    
    if self.item.prefab == "spoiled_food" or self.item.prefab == "spoiled_fish" or self:HasSpoilage() then
		self.bg:Show( )
	end

    if self.item.components.fuse and self.item.components.fuse.consuming then
        self.fusebg:Show()
        self:SetFuse(self.item.components.fuse.fusetime)
    end

	if self:HasSpoilage() then
		self.spoilage:Show()
	end

    if self:ShowInvSpace() then
        self.invspace:Show()
        self:SetInvSpace()
    end

    if self:ShowObsidian() then
        self.obsidian_charge:Show()
        self:SetObsidianCharge()
    end

    if self:IsWet() then
        self.wetness:Show()
    end

    self.inst:ListenForEvent("imagechange", function() 
        self.image:SetTexture(invitem.components.inventoryitem:GetAtlas(), invitem.components.inventoryitem:GetImage())
    end, invitem)
    
    self.inst:ListenForEvent("stacksizechange",
            function(inst, data)
                if invitem.components.stackable then
					if data.src_pos then
						local dest_pos = self:GetWorldPosition()
						local im = Image(invitem.components.inventoryitem:GetAtlas(), invitem.components.inventoryitem:GetImage())
						im:MoveTo(data.src_pos, dest_pos, .3, function() 
							self:SetQuantity(invitem.components.stackable:StackSize())
							self:ScaleTo(self.basescale*2, self.basescale, .25)
							im:Kill() end)
					else
	                    self:SetQuantity(invitem.components.stackable:StackSize())
						self:ScaleTo(self.basescale*2, self.basescale, .25)
					end
                end
            end, invitem)


    if invitem.components.stackable then
        self:SetQuantity(invitem.components.stackable:StackSize())
    end

    self.inst:ListenForEvent("percentusedchange",
            function(inst, data)
                self:SetPercent(data.percent)
            end, invitem)

    self.inst:ListenForEvent("perishchange",
            function(inst, data)
				if self.item.components.perishable then
                    if self:HasSpoilage() then
                        self:SetPerishPercent(data.percent)
    				else
                        self:SetPercent(data.percent)
    				end
                end
            end, invitem)

    self.inst:ListenForEvent("fusestart",
        function(inst, data)
            if self.item.components.fuse then
                self.fusebg:Show()
                self:SetFuse(data.time)
            end
        end, invitem)

    self.inst:ListenForEvent("fusedelta",
        function(inst, data)
            if self.item.components.fuse then
                self:SetFuse(data.time)
            end
        end, invitem)

    self.inst:ListenForEvent("fusestop",
        function(inst, data)
            if self.item.components.fuse then
                self:RemoveFuse()
            end
        end, invitem)

    self.inst:ListenForEvent("itemget",
        function(inst, data)
            if self:ShowInvSpace() then
                self:SetInvSpace()
            end
        end, invitem)

    self.inst:ListenForEvent("dropitem",
        function(inst, data)
            if self:ShowInvSpace() then
                self:SetInvSpace()
            end
        end, invitem)

    self.inst:ListenForEvent("itemwet", function()
        if GetPlayer().components.inventory:GetActiveItem() ~= invitem then
            self.wetness:Show()
        end
    end, invitem)

    self.inst:ListenForEvent("itemdry", function() 
        self.wetness:Hide()
    end, invitem)

    self.inst:ListenForEvent("obsidian_charge_delta", function()
        if self:ShowObsidian() then
            self:SetObsidianCharge()
        end
    end, invitem)

    if invitem.components.fueled then
        self:SetPercent(invitem.components.fueled:GetPercent(), invitem.components.fueled.currentfuel)
    end

    if invitem.components.finiteuses then
        self:SetPercent(invitem.components.finiteuses:GetPercent())
    end

    if invitem.components.perishable then
        if self:HasSpoilage() then
            self:SetPerishPercent(invitem.components.perishable:GetPercent())
        else
            self:SetPercent(invitem.components.perishable:GetPercent())
        end
    end
    
    if invitem.components.armor then
        self:SetPercent(invitem.components.armor:GetPercent())
    end
    
end)

function ItemTile:SetBaseScale(sc)
	self.basescale = sc
	self:SetScale(sc)
end

function ItemTile:OnControl(control, down)
    self:UpdateTooltip()
    return false
end

function ItemTile:UpdateTooltip()
	local str = self:GetDescriptionString()
	self:SetTooltip(str)
    if self:IsWet() then
        self:SetTooltipColour(WET_TEXT_COLOUR[1], WET_TEXT_COLOUR[2], WET_TEXT_COLOUR[3], WET_TEXT_COLOUR[4])
    else
        self:SetTooltipColour(NORMAL_TEXT_COLOUR[1], NORMAL_TEXT_COLOUR[2], NORMAL_TEXT_COLOUR[3], NORMAL_TEXT_COLOUR[4])
    end
end

function ItemTile:GetDescriptionStrings()
    local str1 = nil
    local str2 = nil
    local str3 = nil
    local in_equip_slot = self.item and self.item.components.equippable and self.item.components.equippable:IsEquipped()
    local active_item = GetPlayer().components.inventory:GetActiveItem()
    if self.item and self.item.components.inventoryitem then

    local adjective = self.item:GetAdjective()

    if adjective then
        str1 = adjective .. " " .. self.item:GetDisplayName()
    else
        str1 = self.item:GetDisplayName()
    end

    if active_item then

        if not in_equip_slot then
            if active_item.components.stackable and active_item.prefab == self.item.prefab then
                --str2 = STRINGS.LMB .. ": " .. STRINGS.UI.HUD.PUT
                str2 = STRINGS.UI.HUD.PUT
            else
                --str2 = STRINGS.LMB .. ": " .. STRINGS.UI.HUD.SWAP
                str2 = STRINGS.UI.HUD.SWAP
            end
        end

        local actions = GetPlayer().components.playeractionpicker:GetUseItemActions(self.item, active_item, true)
        if actions then
            --str3 = STRINGS.RMB .. ": " .. actions[1]:GetActionString()
            str3 = actions[1]:GetActionString()
        end
    else

        --self.namedisp:SetHAlign(ANCHOR_LEFT)
        local owner = self.item.components.inventoryitem and self.item.components.inventoryitem.owner
        local actionpicker = owner and owner.components.playeractionpicker or GetPlayer().components.playeractionpicker
        local inventory = owner and owner.components.inventory or GetPlayer().components.inventory
        if owner and inventory and actionpicker then

            if TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) then
                --str2 = STRINGS.LMB .. ": " .. STRINGS.INSPECTMOD
                str2 = STRINGS.INSPECTMOD
            elseif TheInput:IsControlPressed(CONTROL_FORCE_TRADE) then
                --str2 = STRINGS.LMB .. ": " .. ( (TheInput:IsControlPressed(CONTROL_FORCE_STACK) and self.item.components.stackable) and (STRINGS.STACKMOD .. " " ..STRINGS.TRADEMOD) or STRINGS.TRADEMOD)
                str2 = ( (TheInput:IsControlPressed(CONTROL_FORCE_STACK) and self.item.components.stackable) and (STRINGS.STACKMOD .. " " ..STRINGS.TRADEMOD) or STRINGS.TRADEMOD)
            elseif TheInput:IsControlPressed(CONTROL_FORCE_STACK) and self.item.components.stackable then
                --str2 = STRINGS.LMB .. ": " .. STRINGS.STACKMOD
                str2 = STRINGS.STACKMOD
            end

            local actions = nil
            if inventory:GetActiveItem() then
                actions = actionpicker:GetUseItemActions(self.item, inventory:GetActiveItem(), true)
            end

            if not actions then
                actions = actionpicker:GetInventoryActions(self.item)
            end

            if actions then
                --str3 = STRINGS.RMB .. ": " .. actions[1]:GetActionString()
                str2 = actions[1]:GetActionString()
                if actions[2] then
                    str3 = actions[2]:GetActionString()
                end
            end

            end
        end
    end

    return str1, str2, str3
end


function ItemTile:GetDescriptionString()
    local str = nil
    local str1 = nil
    local str2 = nil
    local str3 = nil
    str1,str2,str3 = self:GetDescriptionStrings()
    if str1 then
        str = str1
        if str2 then
            str = str .. "\n" .. str2
        end
        if str3 then
            str = str .. "\n" .. str3
        end
    end
    return str or ""
end

function ItemTile:GetActions()
    local act1 = nil
    local act2 = nil
    local in_equip_slot = self.item and self.item.components.equippable and self.item.components.equippable:IsEquipped()
    local active_item = GetPlayer().components.inventory:GetActiveItem()
    if self.item and self.item.components.inventoryitem then

        if active_item then
            act1 = nil

            local actions = GetPlayer().components.playeractionpicker:GetUseItemActions(self.item, active_item, true)
            if actions then
                act2 = actions[1]
            end
        else

            local owner = self.item.components.inventoryitem and self.item.components.inventoryitem.owner
            local actionpicker = owner and owner.components.playeractionpicker or GetPlayer().components.playeractionpicker
            local inventory = owner and owner.components.inventory or GetPlayer().components.inventory
            if owner and inventory and actionpicker then

                local actions = nil
                if inventory:GetActiveItem() then
                    actions = actionpicker:GetUseItemActions(self.item, inventory:GetActiveItem(), true)
                end

                if not actions then
                    actions = actionpicker:GetInventoryActions(self.item)
                end

                if actions then
                    act1 = actions[1]
                    if actions[2] then
                        act2 = actions[2]
                    end
                end

            end
        end
    end

    return act1, act2
end

function ItemTile:OnGainFocus()
    self:UpdateTooltip()
end

function ItemTile:SetQuantity(quantity)
    if not self.quantity then
        self.quantity = self:AddChild(Text(NUMBERFONT, 42))
        self.quantity:SetPosition(2,16,0)
        if IPHONE_VERSION then
            if GetPlayer().HUD.controls.inv.open then
                self:MakeNumbersSmall()
            else
                self:MakeNumbersBig()
            end
        end
    end
    self.quantity:SetString(tostring(quantity))
end

function ItemTile:SetPerishPercent(percent)
	if self:HasSpoilage() then
		self.spoilage:GetAnimState():SetPercent("anim", 1-self.item.components.perishable:GetPercent())
	end
end

function ItemTile:SetFuse(time)
    if not self.fuse then
        self.fuse = self:AddChild(Text(NUMBERFONT, 50))
        if JapaneseOnPS4() then
            self.fuse:SetHorizontalSqueeze(0.7)
        end
        self.fuse:SetPosition(5,0,0)
    end

    local val_to_show = time
    if val_to_show > 0 and val_to_show < 1 then
        val_to_show = 1
    end
    self.fuse:SetString(string.format("%2.0f", val_to_show))
end

function ItemTile:RemoveFuse()
    self.fuse:Remove()
    self.fusebg:Hide()
end

function ItemTile:SetPercent(percent)
    --if not self.item.components.stackable then
    if not self.percent then
        self.percent = self:AddChild(Text(NUMBERFONT, 42))
        if JapaneseOnPS4() then
            self.percent:SetHorizontalSqueeze(0.7)
        end
        self.percent:SetPosition(5,-32+15,0)

        if IPHONE_VERSION then
            if IPHONE_VERSION then
                if GetPlayer().HUD.controls.inv.open then
                    self:MakeNumbersSmall()
                else
                    self:MakeNumbersBig()
                end
            end
        end
    end
    local val_to_show = percent*100
    if val_to_show > 0 and val_to_show < 1 then
        val_to_show = 1
    end
	self.percent:SetString(string.format("%2.0f%%", val_to_show))
end

--[[
function ItemTile:CancelDrag()
    self:StopFollowMouse()
    
    if self.item.prefab == "spoiled_food" or (self.item.components.edible and self.item.components.perishable) then
		self.bg:Show( )
	end
	
	if self.item.components.perishable and self.item.components.edible then
		self.spoilage:Show()
	end
	
	self.image:SetClickable(true)

    
end
--]]

function ItemTile:SetInvSpace()
    local fullness = self.item.components.inventory:NumItems()/self.item.components.inventory.maxslots
    self.invspace:GetAnimState():SetPercent("anim", fullness)
end

function ItemTile:StartDrag()
    --self:SetScale(1,1,1)
    self.spoilage:Hide()
    self.wetness:Hide()
    self.bg:Hide()
    self.fusebg:Hide()
    self.image:SetClickable(false)
    self.invspace:Hide()
    self.obsidian_charge:Hide()
end

function ItemTile:HasSpoilage()
    return (self.item.components.perishable and (self.item.components.edible or self.item:HasTag("show_spoilage")))
end

function ItemTile:ShowInvSpace()
    return (self.item.components.inventory and self.item.components.inventory.show_invspace)
end

function ItemTile:IsWet()
    local MoistureManager = GetWorld().components.moisturemanager
    return MoistureManager and MoistureManager:IsEntityWet(self.item)
end

function ItemTile:ShowObsidian()
    return self.item.components.obsidiantool
end

function ItemTile:SetObsidianCharge()
    local cur, max = self.item.components.obsidiantool:GetCharge() 
    self.obsidian_charge:GetAnimState():SetPercent("anim", cur/max)
end

function ItemTile:MakeNumbersSmall()
    if self.quantity then
        self.quantity:SetSize(42)
        self.quantity:SetPosition(2,16,0)
    end
    if self.percent then
        self.percent:SetSize(42)
    end
end

function ItemTile:MakeNumbersBig()
    if self.quantity then
        self.quantity:SetSize(60)
        self.quantity:SetPosition(6,0,0)
    end

    if self.percent then
        self.percent:SetSize(60)
        self.percent:SetPosition(6,-10,0)
    end
end

return ItemTile