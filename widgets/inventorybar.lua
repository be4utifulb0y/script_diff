require "class"
local InvSlot = require "widgets/invslot"
local TileBG = require "widgets/tilebg"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local EquipSlot = require "widgets/equipslot"
local ItemTile = require "widgets/itemtile"
local Text = require "widgets/text"
local ThreeSlice = require "widgets/threeslice"

local HUD_ATLAS = "images/hud.xml"
local W = 68
local SEP = 12
local YSEP = 8
local INTERSEP = 28

local CURSOR_STRING_DELAY = 10
local TIP_YFUDGE = 16
local HINT_UPDATE_INTERVAL = 2.0 -- once per second

local CLOSED_MENU_TOP = 70
local OPEN_MENU_TOP = 120
local SCROLL_LIMIT_START = 430
local SCROLL_LIMIT_END = -345
local SCROLL_DRAG_LIMIT_START = 303
local SCROLL_DRAG_LIMIT_END = -185
local SCROLL_HOLD_MAX_TIME = 0.2

local inv_offset = 8
if TheSim:IsiPhone() then
  inv_offset = 8 -- iphone
elseif TheSim:IsiPad() then
  inv_offset = 40 -- ipad
end

local Inv = Class(Widget, function(self, owner)
    Widget._ctor(self, "Inventory")
    self.owner = owner

	self.out_pos = Vector3(0,W+50,0)
	self.in_pos = Vector3(0,W*2.0,0)

	self.base_scale = .6
	self.selected_scale = .9

    self:SetPosition(-60,-8,0)

    self.originalX = -60 -- Original position of the inventory
    self.scrollX = 0 -- Total offset in the X axis from the original position 
    self.baseScroll = 0 -- The scroll offset when the scroll started
    self.startScrollX = 0 -- The touch position when the scroll started
    self.scrollHoldTime = 0 -- Time the user holds the scroll without moving
    self.scrollState = SCROLL_NONE -- see constants.lua
    self.disableChildFocus = false -- set this to true to disable the tiles from scaling

    if IPHONE_VERSION then
		self.base_scale = .46
		self.originalX = -45
		self:SetPosition(self.originalX,-8,0)
		self.out_pos = Vector3(0,W,0)
        self.disableChildFocus = true
	end

	self:SetScale(self.base_scale)

    self.inv = {}
    self.backpackinv = {}
    self.equip = {}
    self.equipslotinfo = {}

	self.root = self:AddChild(Widget("root"))
	
	self.bg = self.root:AddChild(Image(HUD_ATLAS, "inventory_bg.tex"))
	self.bg:SetScale(1.15,1,1)
	--self.bg = self.root:AddChild(ThreeSlice(HUD_ATLAS, "inventory_corner.tex", "inventory_filler.tex"))
	
	self.bgcover = self.root:AddChild(Image(HUD_ATLAS, "inventory_bg_cover.tex"))
	self.bgcover:SetScale(1.15,1,1)
	
    self.hovertile = nil
    self.cursortile = nil

	self.repeat_time = .2

	--this is for the keyboard / controller inventory controls
	self.actionstring = self.root:AddChild(Widget("actionstring"))
	self.actionstring:SetScaleMode(SCALEMODE_PROPORTIONAL)


	self.actionstringtitle = self.actionstring:AddChild(Text(TALKINGFONT, 35))
	self.actionstringtitle:SetColour(204/255, 180/255, 154/255, 1)

	self.actionstringbody = self.actionstring:AddChild(Text(TALKINGFONT, 25))
	self.actionstringbody:EnableWordWrap(true)
	self.actionstring:Hide()

	--default equip slots
	self:AddEquipSlot(EQUIPSLOTS.HANDS, HUD_ATLAS, "equip_slot.tex")
	self:AddEquipSlot(EQUIPSLOTS.BODY, HUD_ATLAS, "equip_slot_body.tex")
	self:AddEquipSlot(EQUIPSLOTS.HEAD, HUD_ATLAS, "equip_slot_head.tex")

    self.inst:ListenForEvent("builditem", function(inst, data) self:OnBuild() end, self.owner)
    self.inst:ListenForEvent("itemget", function(inst, data) self:OnItemGet(data.item, self.inv[data.slot], data.src_pos) end, self.owner)
    self.inst:ListenForEvent("equip", function(inst, data) self:OnItemEquip(data.item, data.eslot) end, self.owner)
    self.inst:ListenForEvent("unequip", function(inst, data) self:OnItemUnequip(data.item, data.eslot) end, self.owner)
    self.inst:ListenForEvent("newactiveitem", function(inst, data) self:OnNewActiveItem(data.item) end, self.owner)
    self.inst:ListenForEvent("itemlose", function(inst, data) self:OnItemLose(self.inv[data.slot]) end, self.owner)
    self.inst:ListenForEvent("setoverflow", function(inst, data) self:Rebuild() end, self.owner)

    self.root:SetPosition(self.in_pos)
    self:StartUpdating()

    self.actionstringtime = CURSOR_STRING_DELAY

	self.openhint = self:AddChild(Text(UIFONT, 52))
	self.openhint:SetRegionSize(300, 60)
	self.openhint:SetHAlign(ANCHOR_LEFT)
	self.openhint:SetPosition(940, 70 + inv_offset, 0)
	
    self.hint_update_check = HINT_UPDATE_INTERVAL
    

end)




function Inv:AddEquipSlot(slot, atlas, image, sortkey)
	sortkey = sortkey or #self.equipslotinfo
	table.insert(self.equipslotinfo, {slot = slot, atlas = atlas, image = image, sortkey = sortkey})
	table.sort(self.equipslotinfo, function(a,b) return a.sortkey < b.sortkey end)
	self.rebuild_pending = true
end


local function BackpackGet(inst, data)
	local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
	
	if owner then
		local inv = owner.HUD.controls.inv
		if inv then
			inv:OnItemGet(data.item, inv.backpackinv[data.slot], data.src_pos)
		end
	end		
end

local function BackpackLose(inst, data)
	local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
	if owner then
		local inv = owner.HUD.controls.inv
		if inv then
			inv:OnItemLose(inv.backpackinv[data.slot])
		end
	end		
end

function Inv:Rebuild()

	if self.cursor then
		self.cursor:Kill()
		self.cursor = nil
	end
	
	if self.toprow then
		self.toprow:Kill()
	end

	if self.bottomrow then
		self.bottomrow:Kill()
	end

	self.toprow = self.root:AddChild(Widget("toprow"))
	self.bottomrow = self.root:AddChild(Widget("toprow"))

    self.inv = {}
    self.equip = {}
	self.backpackinv = {}

    local y = self.owner.components.inventory.overflow and (W/2+YSEP/2) or 0
    local eslot_order = {}

    local num_slots = self.owner.components.inventory:GetNumSlots()
    local num_equip = #self.equipslotinfo
    local num_intersep = math.floor(num_slots / 5) + 1 
    local total_w = (num_slots + num_equip)*(W) + (num_slots + num_equip - 2 - num_intersep) *(SEP) + INTERSEP*num_intersep
    
    for k, v in ipairs(self.equipslotinfo) do
        local slot = EquipSlot(v.slot, v.atlas, v.image, self.owner)
        self.equip[v.slot] = self.toprow:AddChild(slot)
        local x = -total_w/2 + (num_slots)*(W)+num_intersep*(INTERSEP - SEP) + (num_slots-1)*SEP + INTERSEP + W*(k-1) + SEP*(k-1)
        slot:SetPosition(x,0,0)
        table.insert(eslot_order, slot)
        
		local item = self.owner.components.inventory:GetEquippedItem(v.slot)
		if item then
			slot:SetTile(ItemTile(item))
		end

    end    

    for k = 1,num_slots do
        local slot = InvSlot(k, HUD_ATLAS, "inv_slot.tex", self.owner, self.owner.components.inventory)
        self.inv[k] = self.toprow:AddChild(slot)
        local interseps = math.floor((k-1) / 5)
        local x = -total_w/2 + W/2 + interseps*(INTERSEP - SEP) + (k-1)*W + (k-1)*SEP
        slot:SetPosition(x,0,0)
        
		slot.top_align_tip = W*0.5 + YSEP

		local item = self.owner.components.inventory:GetItemInSlot(k)
		if item then
			slot:SetTile(ItemTile(item))
		end
        
    end


	local old_backpack = self.backpack
	if self.backpack then
		self.inst:RemoveEventCallback("itemget", BackpackGet, self.backpack)
		self.inst:ListenForEvent("itemlose", BackpackLose, self.backpack)
		self.backpack = nil
	end


	local new_backpack = self.owner.components.inventory.overflow
	local do_integrated_backpack = (TheInput:ControllerAttached() or IPHONE_VERSION) and new_backpack

	if self.boatwidget then
		if self.boatwidget.inst:IsValid() then
			self.boatwidget:SetPosition(Vector3(700, do_integrated_backpack and 105 or 65, 0))
		else
			self.boatwidget = nil
		end
	end

	OPEN_MENU_TOP = 120
	CLOSED_MENU_TOP = 70
	if do_integrated_backpack then
		OPEN_MENU_TOP = 220
		CLOSED_MENU_TOP = 170
		local num = new_backpack.components.container.numslots



		local x = - (num * (W+SEP) / 2)
		--local offset = #self.inv >= num and 1 or 0 --math.ceil((#self.inv - num)/2)
		local offset = 1 + #self.inv - num

		for k = 1, num do
			local slot = InvSlot(k, HUD_ATLAS, "inv_slot.tex", self.owner, new_backpack.components.container)
			self.backpackinv[k] = self.bottomrow:AddChild(slot)

			slot.top_align_tip = W*1.5 + YSEP*2
			
			if offset > 0 then
				slot:SetPosition(self.inv[offset+k-1]:GetPosition().x,0,0)
			else
				slot:SetPosition(x,0,0)
				x = x + W + SEP
			end
			
			local item = new_backpack.components.container:GetItemInSlot(k)
			if item then
				slot:SetTile(ItemTile(item))
			end
			
		end
		
		self.backpack = self.owner.components.inventory.overflow
	    self.inst:ListenForEvent("itemget", BackpackGet, self.backpack)
	    self.inst:ListenForEvent("itemlose", BackpackLose, self.backpack)
	end

	if old_backpack	and not self.backpack then
		self:SelectSlot(self.inv[1])
		self.current_list = self.inv
	end

	--self.bg:Flow(total_w+60, 256, true)
	
  if do_integrated_backpack then
		self.bg:SetPosition(Vector3(0,-24,0))
    self.bgcover:SetPosition(Vector3(0, -135, 0))
		self.toprow:SetPosition(Vector3(0,W/2 + YSEP/2,0))
		self.bottomrow:SetPosition(Vector3(0,-W/2 - YSEP/2,0))
		self.root:MoveTo(self.out_pos, self.in_pos, .5)
	else
		self.bg:SetPosition(Vector3(0, -64, 0))
	    self.bgcover:SetPosition(Vector3(0, -100, 0))
		self.toprow:SetPosition(Vector3(0,0,0))
		self.bottomrow:SetPosition(0,0,0)
		
		if TheInput:ControllerAttached() then
			self.root:MoveTo(self.in_pos, self.out_pos, .2)
		else
			self.root:SetPosition(self.out_pos)
		end
		
		
	end
	
	self.actionstring:MoveToFront()
	
	self:SelectSlot(self.inv[1])
	self.current_list = self.inv
	self:UpdateCursor()
	
	if self.cursor then
		self.cursor:MoveToFront()
	end


	self.rebuild_pending = false
end

function Inv:OnUpdate(dt)
  local BOTTOM_SAFE_AREA = TheSim:GetBottomSafeArea()
  local isControllerAttached = TheInput:ControllerAttached()
  if self.isControllerAttached ~= isControllerAttached then
    self.isControllerAttached = isControllerAttached
    if(self.isControllerAttached) then
      self:SetPosition(self.originalX + 40, BOTTOM_SAFE_AREA - inv_offset, 0)
    else
      self:SetPosition(self.originalX, BOTTOM_SAFE_AREA - inv_offset, 0)
    end
  end

	self.hint_update_check = self.hint_update_check - dt
	if 0 > self.hint_update_check then	
		if not TheInput:ControllerAttached() then
			self.openhint:Hide()
		else
			self.openhint:Show()
			self.openhint:SetString(TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_OPEN_INVENTORY))
		end
	    self.hint_update_check = HINT_UPDATE_INTERVAL
	end
	
	if GetPlayer().HUD ~= TheFrontEnd:GetActiveScreen() then return end
	if not GetPlayer().HUD.shown then return end

	if self.rebuild_pending == true then
		self:Rebuild()
		self:Refresh()
	end

	if IPHONE_VERSION and not TheInput:ControllerAttached()then
		self:UpdateScrolling(dt)
	end

	if self.open and TheInput:ControllerAttached() then
		--SetPause(true, "inv")
	end


	if not self.open and self.actionstring and self.actionstringtime and self.actionstringtime > 0 then
		self.actionstringtime = self.actionstringtime - dt
		if self.actionstringtime <= 0 then
			self.actionstring:Hide()
		end
	end

	if self.repeat_time > 0 then
		self.repeat_time = self.repeat_time - dt
	end
	
	if self.active_slot and not self.active_slot.inst:IsValid() then
		self:SelectSlot(self.inv[1])
		
		self.current_list = self.inv
		
		if self.cursor then
			self.cursor:Kill()
			self.cursor = nil
		end
		
	end

	if self.hovertile then
        if TheInput:IsTouchDown() then
            local player = GetPlayer()
            if player and player.HUD then
                local hover = player.HUD.controls.hover
                if hover.inMenu then
                    self.hovertile:Hide()
                else
                    self.hovertile:Show()
                end
            else
                self.hovertile:Show()
            end
        else
            self.hovertile:Hide()
        end
	end


	self:UpdateCursor()
	
	if IPHONE_VERSION then
		local hudEntity = TheInput:GetHUDEntityUnderMouse()
		local pos = TheInput:GetScreenPosition()
		if not hudEntity and not self.scrolling and self.open and not self.opening and pos.y >= OPEN_MENU_TOP + TheInput:GetTouchYOffset() then
			if TheInput:IsTouchDown() then
				self:ClosePhoneInventory()
			end
		else
			if not self.open and TheInput:IsTouchDown() and GetPlayer().components.inventory:GetActiveItem() then
				if pos.y <= CLOSED_MENU_TOP + TheInput:GetTouchYOffset() then --hardcoded.... this is similar to "touch is over inventory"
					self:OpenPhoneInventory()
				end
			end
		end
	end

	if not self.owner:HasTag("beaver") then
		--this is intentionally unaware of focus
		if self.repeat_time <= 0 then
			if TheInput:IsControlPressed(CONTROL_INVENTORY_LEFT) or (self.open and TheInput:IsControlPressed(CONTROL_MOVE_LEFT)) then
				self:CursorLeft()
			elseif TheInput:IsControlPressed(CONTROL_INVENTORY_RIGHT) or (self.open and TheInput:IsControlPressed(CONTROL_MOVE_RIGHT)) then
				self:CursorRight()
			elseif TheInput:IsControlPressed(CONTROL_INVENTORY_UP) or (self.open and TheInput:IsControlPressed(CONTROL_MOVE_UP)) then
				self:CursorUp()
			elseif TheInput:IsControlPressed(CONTROL_INVENTORY_DOWN) or (self.open and TheInput:IsControlPressed(CONTROL_MOVE_DOWN)) then
				self:CursorDown()
			else
				self.repeat_time = 0
				self.reps = 0
				return
			end

			self.reps = self.reps and (self.reps + 1) or 1
			
			if self.reps <= 1 then
				self.repeat_time = 5/30
			elseif self.reps < 4 then
				self.repeat_time = 2/30
			else
				self.repeat_time = 1/30
			end
			
		end	
	end
	
end


function Inv:OffsetCursor(offset, val, minval, maxval, slot_is_valid_fn)
	if val == nil then
		val = minval
	else
		
		local idx = val
		local start_idx = idx

		repeat 
			idx = idx + offset
			
			if idx < minval then idx = maxval end
			if idx > maxval then idx = minval end

			if slot_is_valid_fn(idx) then 
				val = idx
				break
			end

		until start_idx == idx
	end
	
	return val
end

function Inv:GetInventoryLists(same_container_only)
	if same_container_only then
		local lists = {self.current_list}

		if self.current_list == self.inv then
			table.insert(lists, self.equip)
		elseif self.current_list == self.equip then
			table.insert(lists, self.inv)
		end

		return lists
	else
		local lists = {self.inv, self.equip, self.backpackinv}
		--[[
		local bp = self.owner.HUD:GetFirstOpenContainerWidget()
		if bp then
			table.insert(lists, bp.inv)
			if bp.boatEquip then 
				table.insert(lists, bp.boatEquip)
			end 
		end
	]]
		local containers = self.owner.HUD:GetOpenContainerWidgets() 
		if containers then 
			for k,v in pairs(containers) do
				if v then 
					table.insert(lists, v.inv)
					if v.boatEquip then 
						table.insert(lists, v.boatEquip)
					end 
				end 
			end 	
		end 

		return lists
	end

end

function Inv:CursorNav(dir, same_container_only)

	GetPlayer().components.playercontroller:CancelDeployPlacement()

	if self:GetCursorItem() then
    	self.actionstringtime = CURSOR_STRING_DELAY
    	self.actionstring:Show()
    end


	if self.active_slot and not self.active_slot.inst:IsValid() then
		self.current_list = self.inv
		return self:SelectSlot(self.inv[1])
	end

	local lists = self:GetInventoryLists(same_container_only)
	local slot, list = self:GetClosestWidget(lists, self.active_slot:GetWorldPosition(), dir)
	if slot and list then		
		self.current_list = list
		return self:SelectSlot(slot)
	end
end


function Inv:CursorLeft()
	
	if self:CursorNav(Vector3(-1,0,0)) then
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
	end
end

function Inv:CursorRight()
	if self:CursorNav(Vector3(1,0,0)) then
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
	end
end

function Inv:CursorUp()
	if self:CursorNav(Vector3(0,1,0)) then
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
	end
end

function Inv:CursorDown()
	if self:CursorNav(Vector3(0,-1,0)) then
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
	end
end


function Inv:GetClosestWidget(lists, pos, dir)
	local closest = nil
	local closest_score = nil
	local closest_list = nil
	
	for kk, vv in pairs(lists) do
		for k,v in pairs(vv) do
			if v ~= self.active_slot and v.shown then
				local world_pos = v:GetWorldPosition()
				local dst = pos:DistSq(world_pos)
				local local_dir = (world_pos - pos):GetNormalized()
				local dot = local_dir:Dot(dir)

				if dot > 0 then
					local score = dot/dst

					if not closest or score > closest_score then
						closest = v
						closest_score = score
						closest_list = vv
					end
				end
			end
		end
	end

	return closest, closest_list
end



function Inv:GetCursorItem()
	return self.active_slot and self.active_slot.tile and self.active_slot.tile.item
end

function Inv:OnControl(control, down)
	if IPHONE_VERSION and not TheInput:ControllerAttached() then
        if GetPlayer().components.playercontroller:GetActiveInventoryObject() then
            GetPlayer().components.playercontroller:ResetActiveInventoryTile()
        end
		if not self.open and down then
			self:OpenPhoneInventory()
			return
		end

        if self.open then
            self.disableChildFocus = true
            if down then
                self.autoScroll = false
            end
        end

        if self.open and not down and self.scrollState == SCROLL_HOLD and self.scrollHoldTime < SCROLL_HOLD_MAX_TIME then
            self.scrollState = SCROLL_INVALID
            -- We don't want to lose the down interaction
            Inv._base.OnControl(self, control, true)
        elseif self.scrollState == SCROLL_HOLD or self.scrollState == SCROLL_MOVING or self:WillScroll() then
			return
		end
	end 

	if Inv._base.OnControl(self, control, down) then return true end
	
	--[[if not down then
		local inventory = GetPlayer().components.inventory
		local activeitem = inventory:GetActiveItem()
		if activeitem then
			inventory:ReturnActiveItem()
		end
	end]]

	
	if self.open then
		if not down then 
			
			local active_item = self.owner.components.inventory:GetActiveItem()
			local inv_item = self:GetCursorItem()
			
			if control == CONTROL_ACCEPT then
				
				if inv_item and not inv_item.components.inventoryitem.cangoincontainer and not active_item then
					self.owner.components.inventory:DropItem(inv_item)
					self:CloseControllerInventory()
				else
					self.active_slot:Click()
				end
				return true
			elseif control == CONTROL_PUTSTACK then
				if self.open and self.active_slot then
					self.active_slot:Click(true)
					return true
				end
			elseif control == CONTROL_INVENTORY_DROP then
				if inv_item and not active_item then
					self.owner.components.inventory:DropItem(inv_item)
				end
			elseif control == CONTROL_USE_ITEM_ON_ITEM then
				if inv_item and active_item then
					local use_action_l, use_action_r = self.owner.components.playercontroller:GetItemUseAction(active_item, inv_item)
					local use_action = use_action_l or use_action_r
					if use_action then
						self.owner.components.locomotor:PushAction(use_action, true)
						self:CloseControllerInventory()
					end
				end
			
			end
		end
	end
end

function Inv:OpenControllerInventory()
	if not self.open then
        self.owner.HUD.isLastOpenInventory = true
        GetPlayer().components.talker:ShutUp()

        GetPlayer().HUD:CloseCrafting()
        self:HideHUD()

        self.owner.HUD.controls:SetDark(true)
        SetPause(true, "inv")
        self.owner.components.playercontroller.comesFromInventory = true
        self.open = true
        self.controller_open = true

        --self:ScaleTo(self.base_scale,self.selected_scale_controller,.2)

        for k,v in pairs(self.owner.components.inventory.itemslots) do
            if v then
                local tile = self.inv[k].tile
                if tile then
                    tile:MakeNumbersSmall()
                end
            end
        end

        for k,v in pairs(self.owner.components.inventory.equipslots) do
            if v then
                local tile = self.equip[k].tile
                if tile then
                    tile:MakeNumbersSmall()
                end
            end
        end

        local new_backpack = self.owner.components.inventory.overflow
        if new_backpack then
            local num = new_backpack.components.container.numslots
            for k = 1, num do
                local tile = self.backpackinv[k].tile
                if tile then
                    tile:MakeNumbersSmall()
                end
            end
        end

        TheFrontEnd:LockFocus(true)
        self:SetFocus()

    end
end

function Inv:CloseInventory()
    if self.phone_open then
        self:ClosePhoneInventory()
    end
    if self.controller_open then
        self:CloseControllerInventory()
    end
end

function Inv:OpenPhoneInventory()
	if not self.open then
        self.owner.HUD.isLastOpenInventory = true
        GetPlayer().components.talker:ShutUp()
        if GetPlayer().components.inventory:GetActiveItem() then
            self.disableChildFocus = false
        else
            self.disableChildFocus = true
        end

		GetPlayer().HUD:CloseCrafting()
		self:HideHUD()
		
		self.owner.HUD.controls:SetDark(true)
		SetPause(true, "inv")
        self.owner.components.playercontroller.comesFromInventory = true
        self.opening = true

        self:ScaleTo(self.base_scale,self.selected_scale,.2)
        self.scrollHoldTime = 0.0

        local touchPos = TheInput:GetScreenPosition()
        local inventoryPos = self:GetWorldPosition()

        -- The scroll starts where the touch is! TODO: Is not 100% accurate
        local dist = touchPos.x - inventoryPos.x
        local scaledDist = dist * (self.selected_scale / self.base_scale)

        self.scrollX = -(scaledDist - dist)
        self.scrollX = math.max(SCROLL_LIMIT_END, self.scrollX)
        self.scrollX = math.min(SCROLL_LIMIT_START, self.scrollX)
        self:MoveTo(self:GetPosition(), self:GetPosition() + Vector3(self.scrollX, 0, 0), .2, function() self.open = true self.phone_open = true self.opening = false end)

        self.baseScroll = self.scrollX

        for k,v in pairs(self.owner.components.inventory.itemslots) do
			if v then
				local tile = self.inv[k].tile
				if tile then
					tile:MakeNumbersSmall()
				end
			end
		end

		for k,v in pairs(self.owner.components.inventory.equipslots) do
			if v then
				local tile = self.equip[k].tile
				if tile then
					tile:MakeNumbersSmall()
				end
			end
		end

		local new_backpack = self.owner.components.inventory.overflow
		if new_backpack then
			local num = new_backpack.components.container.numslots
			for k = 1, num do
				local tile = self.backpackinv[k].tile
				if tile then
					tile:MakeNumbersSmall()
				end
			end
		end
	end
end

function Inv:ClosePhoneInventory()
	if self.open then
        self.disableChildFocus = true

		self:ShowHUD()
		self.owner.HUD.controls:SetDark(false)
		SetPause(false)
		self.open = false
        self.phone_open = false
        self.opening = true

        self:ScaleTo(self.selected_scale, self.base_scale,.1)

        self.owner.components.playercontroller.comesFromInventory = false

        local pos = self:GetPosition()
        self:MoveTo(pos, Vector3(self.originalX, pos.y, pos.z), .1, function() self.opening = false end)
	
  --       for k,v in pairs(self.owner.components.inventory.itemslots) do
		-- 	if v then
		-- 		local tile = self.inv[k].tile
		-- 		if tile then
		-- 			tile:MakeNumbersBig()
		-- 		end
		-- 	end
		-- end
		
		-- for k,v in pairs(self.owner.components.inventory.equipslots) do
		-- 	if v then
		-- 		local tile = self.equip[k].tile
		-- 		if tile then
		-- 			tile:MakeNumbersBig()
		-- 		end
		-- 	end
		-- end

		-- local new_backpack = self.owner.components.inventory.overflow
		-- if new_backpack then
		-- 	local num = new_backpack.components.container.numslots
		-- 	for k = 1, num do
		-- 		local tile = self.backpackinv[k].tile
		-- 		if tile then
		-- 			tile:MakeNumbersBig()
		-- 		end
		-- 	end
		-- end
	end
end

function Inv:OnEnable()
	self:UpdateCursor()
end

function Inv:OnDisable()
	self.actionstring:Hide()
end

function Inv:CloseControllerInventory()
	print("closeinv dlc")
    if self.open then
        self.disableChildFocus = true

        self:ShowHUD()
        self.owner.HUD.controls:SetDark(false)
        SetPause(false)
        self.open = false
        self.controller_open = false
        --self.opening = true

        --self:ScaleTo(self.selected_scale_controller, self.base_scale,.1)

        --local pos = self:GetPosition()
        --self:MoveTo(pos, Vector3(self.originalX, pos.y, pos.z), .1, function() self.opening = false end)

        for k,v in pairs(self.owner.components.inventory.itemslots) do
            if v then
                local tile = self.inv[k].tile
                if tile then
                    tile:MakeNumbersBig()
                end
            end
        end

        for k,v in pairs(self.owner.components.inventory.equipslots) do
            if v then
                local tile = self.equip[k].tile
                if tile then
                    tile:MakeNumbersBig()
                end
            end
        end

        local new_backpack = self.owner.components.inventory.overflow
        if new_backpack then
            local num = new_backpack.components.container.numslots
            for k = 1, num do
                local tile = self.backpackinv[k].tile
                if tile then
                    tile:MakeNumbersBig()
                end
            end
        end

        TheFrontEnd:LockFocus(false)

    end
end

function Inv:GetDescriptionString(item)
    local str = nil
    local in_equip_slot = item and item.components.equippable and item.components.equippable:IsEquipped()
    local active_item = GetPlayer().components.inventory:GetActiveItem()
    if item and item.components.inventoryitem then
        local adjective = item:GetAdjective()
        if adjective then
            str = adjective .. " " .. item:GetDisplayName()
        else
            str = item:GetDisplayName()
        end
    end
    
    return str or ""
end

function Inv:IsWet(item)
    local MoistureManager = GetWorld().components.moisturemanager
    return MoistureManager and MoistureManager:IsEntityWet(item)
end

function Inv:SetTooltipColour(r,g,b,a)
	self.actionstringtitle:SetColour(r,g,b,a)
end

function Inv:UpdateCursorText()
	
	local inv_item = self:GetCursorItem()
	local active_item = self.cursortile and self.cursortile.item 
	local item = active_item or inv_item
	
	local controller_id = TheInput:GetControllerID()

	if item then
		local itemname = self:GetDescriptionString(item)
		self.actionstringtitle:SetString(itemname)
    	if self:IsWet(item) then
        	self:SetTooltipColour(WET_TEXT_COLOUR[1], WET_TEXT_COLOUR[2], WET_TEXT_COLOUR[3], WET_TEXT_COLOUR[4])
    	else
        	self:SetTooltipColour(NORMAL_TEXT_COLOUR[1], NORMAL_TEXT_COLOUR[2], NORMAL_TEXT_COLOUR[3], NORMAL_TEXT_COLOUR[4])
	    end

	    local is_equip_slot = self.active_slot and self.active_slot.equipslot
	    local str = {}
	    
		if not self.open then
			if inv_item then
				table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_EXAMINE) .. " " .. STRINGS.UI.HUD.INSPECT)
				
				if not is_equip_slot then
					
					if inv_item.components.inventoryitem:GetGrandOwner() ~= self.owner then
						table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_USEONSCENE) .. " " .. STRINGS.UI.HUD.TAKE)
					else
						local scene_action = self.owner.components.playercontroller:GetItemUseAction(inv_item)
						if scene_action then
							table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_USEONSCENE) .. " " .. scene_action:GetActionString())
						end
					end
					local self_action = self.owner.components.playercontroller:GetItemSelfAction(inv_item)
					if self_action then
						table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_USEONSELF) .. " " .. self_action:GetActionString())
					end
				else

					local self_action = self.owner.components.playercontroller:GetItemSelfAction(inv_item)
					if self_action and self_action.action ~= ACTIONS.UNEQUIP then
						table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_USEONSCENE) .. " " .. self_action:GetActionString())
					end

					table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_USEONSELF) .. " " .. STRINGS.UI.HUD.UNEQUIP)
				end
								
				table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_DROP) .. " " .. STRINGS.UI.HUD.DROP)
			end
		else 
			if is_equip_slot then
				--handle the quip slot stuff as a special case because not every item can go there
				local can_equip = active_item and active_item.components.equippable and active_item.components.equippable.equipslot == self.active_slot.equipslot
				if can_equip then
	    			if inv_item and active_item then
	    				table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HUD.SWAP)
	    			elseif not inv_item and active_item then
	    				table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HUD.EQUIP)
	    			end
				elseif not active_item and inv_item then
					if inv_item.components.inventoryitem.cangoincontainer then
						table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HUD.UNEQUIP)				
					else
						table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HUD.DROP)				
					end
				end
			else
                local can_take_active_item = active_item and (not self.active_slot.container.CanTakeItemInSlot or self.active_slot.container:CanTakeItemInSlot(active_item, self.active_slot:GetSlotNum()))

	    		if active_item and active_item.components.stackable then
	    			if (inv_item and inv_item.prefab == active_item.prefab) or (not inv_item and can_take_active_item)  then
	    				table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_PUTSTACK) .. " " .. STRINGS.UI.HUD.PUTONE)
	    			end
	    		end
	    		
	    		if not active_item and inv_item and inv_item.components.stackable and inv_item.components.stackable:IsStack() then
	    			table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_PUTSTACK) .. " " .. STRINGS.UI.HUD.GETHALF)
	    		end

	    		if inv_item and not active_item then
					table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HUD.SELECT)
		    		table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_INVENTORY_DROP) .. " " .. STRINGS.UI.HUD.DROP)
	    		elseif inv_item and active_item then
	    			if inv_item.prefab == active_item.prefab and active_item.components.stackable then
		    			table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HUD.PUT)
	    			elseif can_take_active_item then
		    			table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HUD.SWAP)
		    		else
		    			table.insert(str, " ")
	    			end
	    		elseif not inv_item and active_item and can_take_active_item then
	    			table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HUD.PUT)
	    		else
	    			table.insert(str, " ")
	    		end

	    	end
	    	
	    	if active_item and inv_item then
				local use_action_l, use_action_r = self.owner.components.playercontroller:GetItemUseAction(active_item, inv_item)
				local use_action = use_action_l or use_action_r
				if use_action then
					table.insert(str, TheInput:GetLocalizedControl(controller_id, CONTROL_USE_ITEM_ON_ITEM) .. " " .. use_action:GetActionString())
				end
	    	end
	    	
	    end
	   
	    local was_shown = self.actionstring.shown
	    local old_string = self.actionstringbody:GetString()
	    local new_string = table.concat(str, '\n')
	    if old_string ~= new_string then
		    self.actionstringbody:SetString(new_string)
		    self.actionstringtime = CURSOR_STRING_DELAY
		    self.actionstring:Show()
		end


		local w0, h0 = self.actionstringtitle:GetRegionSize()
		local w1, h1 = self.actionstringbody:GetRegionSize()

		local wmax = math.max(w0, w1)

		local dest_pos = self.active_slot:GetWorldPosition()

		local yscale = self.root:GetScale().y
		local xscale = self.root:GetScale().x

		if self.active_slot.side_align_tip then
			-- in-game containers, chests, fridge
			self.actionstringtitle:SetPosition(wmax/2, h0/2)
			self.actionstringbody:SetPosition(wmax/2, -h1/2)

			dest_pos = dest_pos + Vector3(self.active_slot.side_align_tip * xscale, 0, 0)
		elseif self.active_slot.top_align_tip then
			-- main inventory
			self.actionstringtitle:SetPosition(0, h0/2 + h1)
			self.actionstringbody:SetPosition(0, h1/2)

			dest_pos = dest_pos + Vector3(0, (self.active_slot.top_align_tip + TIP_YFUDGE) * yscale, 0)
		else
			-- old default as fallback ?
			self.actionstringtitle:SetPosition(0, h0/2 + h1)
			self.actionstringbody:SetPosition(0, h1/2)

			dest_pos = dest_pos + Vector3(0, (W/2 + TIP_YFUDGE) * yscale, 0)
		end

		-- print("self.active_slot:GetWorldPosition()", self.active_slot:GetWorldPosition())
		-- print("h0", h0)
		-- print("w0", w0)
		-- print("h1", h1)
		-- print("w1", h1)
		-- print("dest_pos", dest_pos)

		if dest_pos:DistSq(self.actionstring:GetPosition()) > 1 then
			self.actionstringtime = CURSOR_STRING_DELAY
			if was_shown then
				self.actionstring:MoveTo(self.actionstring:GetPosition(), dest_pos, .1)
			else
				self.actionstring:SetPosition(dest_pos)
				self.actionstring:Show()
			end
		end

	else
		self.actionstringbody:SetString("")
		self.actionstring:Hide()
	end
end

function Inv:SelectSlot(slot)
	if slot and slot ~= self.active_slot then
		if self.active_slot and self.active_slot ~= slot then
			self.active_slot:DeHighlight()
		end
		self.active_slot = slot
		return true
	end
end

function Inv:UpdateCursor()

	if not TheInput:ControllerAttached() then
		self.actionstring:Hide()
		if self.cursor then
			self.cursor:Hide()
		end

		if self.cursortile then
			self.cursortile:Kill()
			self.cursortile = nil
		end
		return
	end

	if not self.active_slot then
		self:SelectSlot(self.inv[1])
	end


	if self.active_slot and self.cursortile	then
		self.cursortile:SetPosition(self.active_slot:GetWorldPosition())
	end

	if self.active_slot then
	
		if self.cursor then
			self.cursor:Kill()
			self.cursor = nil
		end

		if not self.cursor then
			self.cursor = self.root:AddChild(Image( HUD_ATLAS, "slot_select.tex"))
		end
	
		if self.active_slot.tile and self.active_slot.tile:HasSpoilage() then
			self.cursor:Show()
			self.active_slot.tile:AddChild(self.cursor)
			self.active_slot:Highlight()

			self.cursor:MoveToBack()
			self.active_slot.tile.spoilage:MoveToBack()
			self.active_slot.tile.bg:MoveToBack()
		else
			self.cursor:Show()
			self.active_slot:AddChild(self.cursor)
			self.active_slot:Highlight()

			self.cursor:MoveToBack()
			self.active_slot.bgimage:MoveToBack()
		end
	else
		self.cursor:Hide()
	end

	--if self.open then
	local active_item = self.owner.components.inventory:GetActiveItem()
	if active_item then
		
		if not self.cursortile or active_item ~= self.cursortile.item then
			
			if self.cursortile then
				self.cursortile:Kill()
			end
			
			self.cursortile = self.root:AddChild(ItemTile(active_item))
			self.cursortile.image:SetScale(1.3)
			self.cursortile:SetScaleMode(SCALEMODE_PROPORTIONAL)
			self.cursortile:StartDrag()
			self.cursortile:SetPosition(self.active_slot:GetWorldPosition())
		end
	else
		if self.cursortile then
			self.cursortile:Kill()
			self.cursortile = nil
		end
	end

	self:UpdateCursorText()
end

function Inv:Refresh()
	
	for k,v in pairs(self.inv) do
		v:SetTile(nil)
	end

	for k,v in pairs(self.equip) do
		v:SetTile(nil)
	end

	for k,v in pairs(self.owner.components.inventory.itemslots) do
		if v then
			local tile = ItemTile(v)
			self.inv[k]:SetTile(tile)
		end
	end

	for k,v in pairs(self.owner.components.inventory.equipslots) do
		if v then
			local tile = ItemTile(v)
			self.equip[k]:SetTile(tile)
		end
	end
	
	self:OnNewActiveItem(self.owner.components.inventory.activeitem)

end


function Inv:Cancel()
    local active_item = self.owner.components.inventory:GetActiveItem()
    if active_item then
        self.owner.components.inventory:ReturnActiveItem()
    end
end

function Inv:OnItemLose(slot)
	if slot then
		slot:SetTile(nil)
	end
	
	--self:UpdateCursor()
end

function Inv:OnBuild()
    if self.hovertile then
        self.hovertile:ScaleTo(3, 1, .5)
    end
end

function Inv:OnNewActiveItem(item)
    
    if self.hovertile then
        self.hovertile:Kill()
        self.hovertile = nil
    end

    if item and self.owner.HUD.controls and not TheInput:ControllerAttached() then
    	
    	if not self.open or (IPHONE_VERSION and self.open) then
        	self.hovertile = self.owner.HUD.controls.mousefollow:AddChild(ItemTile(item))
        	self.hovertile:StartDrag()
        end
    end

end

function Inv:OnItemGet(item, slot, source_pos)
    if slot  then
		local tile = ItemTile(item)
        slot:SetTile(tile)
        tile:Hide()

        if source_pos then
			local dest_pos = slot:GetWorldPosition()
			local im = Image(item.components.inventoryitem:GetAtlas(), item.components.inventoryitem:GetImage())
			im:MoveTo(source_pos, dest_pos, .3, function() tile:Show() tile:ScaleTo(2, 1, .25) im:Kill() end)
        else
			tile:Show() 
			--tile:ScaleTo(2, 1, .25)
        end
	end
end

function Inv:OnItemEquip(item, slot)
    self.equip[slot]:SetTile(ItemTile(item))
end

function Inv:OnItemUnequip(item, slot)
    if slot and self.equip[slot] then
		self.equip[slot]:SetTile(nil)
	end
end

function Inv:UpdateScrolling(dt)
	local pos = self:GetPosition()
	if self.open then
        local hover = self.owner.components.playercontroller.inst.HUD.controls.hover
        if hover.inMenu then
            return
        end

		local screenPos = TheInput:GetScreenPosition()
		if TheInput:IsTouchDown() and screenPos.y < OPEN_MENU_TOP then -- 
			if self.scrollState == SCROLL_NONE then -- start scrolling
				self.scrollState = SCROLL_HOLD
				self.startScrollX = screenPos.x
				self.baseScroll = self.scrollX
                self.scrollHoldTime = 0.0
                self.lastY = screenPos.y
			end
			local delta = (screenPos.x - self.startScrollX)
            local deltaY = (screenPos.y - self.lastY)
            self.lastY = screenPos.y
			if self.scrollState == SCROLL_HOLD then
                local activeitem = GetPlayer().components.inventory:GetActiveItem()
                if(math.abs(delta) < 10) or activeitem ~= nil then
					self.scrollHoldTime = self.scrollHoldTime + dt
					if(self.scrollHoldTime > SCROLL_HOLD_MAX_TIME) or (deltaY > 10 and deltaY > 3*delta) then --it's a drag!
						self.scrollState = SCROLL_INVALID
                        if activeitem == nil then --if was dragging an item don't send the tap so we can correctly drop the item
                            self:OnControl(CONTROL_ACCEPT, true) -- Send the "tap" from 0.15 seconds ago
                        end
                        self.disableChildFocus = false
					end
				else
                    self.scrollState = SCROLL_MOVING
                    self.scrollVelocity = 0
                    self.scrollAmplitude = 0
				end
			end
			if self.scrollState == SCROLL_MOVING then
                local oldScrollX = self.scrollX

				self.scrollX = self.baseScroll + delta
				if self.scrollX > SCROLL_LIMIT_START then
					self.scrollX = SCROLL_LIMIT_START
				elseif self.scrollX < SCROLL_LIMIT_END then
					self.scrollX = SCROLL_LIMIT_END
				end

                local frameDelta = self.scrollX - oldScrollX
                local v = 10 * frameDelta / (1 + dt);
                self.scrollVelocity = 0.8 * v + 0.2 * self.scrollVelocity;

            elseif self.scrollState == SCROLL_INVALID then
                local w, h = TheSim:GetWindowSize()
                -- Dragging
                if screenPos.x < 60 then
                	local vel = 220
                	if screenPos.x < 30 then vel = 450 end
                    if self.scrollX < SCROLL_DRAG_LIMIT_START then
                        self.scrollX = math.min(SCROLL_DRAG_LIMIT_START, self.scrollX + (vel * dt))
                    end
                end
                if screenPos.x > (w - 60) then
                	local vel = 220
                	if screenPos.x > (w - 30) then vel = 450 end
                    if self.scrollX > SCROLL_DRAG_LIMIT_END then
                        self.scrollX = math.max(SCROLL_DRAG_LIMIT_END, self.scrollX - (vel * dt))
                    end
                end
			end
        elseif not TheInput:IsTouchDown() then
            if self.open and self.scrollState == SCROLL_MOVING then
                if self.scrollVelocity > 10 or self.scrollVelocity < -10 then
                    self.scrollAmplitude = 0.8 * self.scrollVelocity;
                    self.scrollTarget = math.floor((self.scrollX + self.scrollAmplitude) + 0.5);
                    self.autoScroll = true
                    self.autoScrollDt = 0.0
                end
            end

            if self.autoScroll and self.scrollAmplitude ~= 0 then
                self.autoScrollDt = self.autoScrollDt + dt
                local delta = -self.scrollAmplitude * math.exp(-self.autoScrollDt / 0.325)
                if delta > 0.5 or delta < -0.5 then
                    self.scrollX = self.scrollTarget + delta
                    if self.scrollX > SCROLL_LIMIT_START then
                        self.scrollX = SCROLL_LIMIT_START
                        self.autoScroll = false
                    elseif self.scrollX < SCROLL_LIMIT_END then
                        self.scrollX = SCROLL_LIMIT_END
                        self.autoScroll = false
                    end
                else
                    self.scrollX = self.scrollTarget
                    self.autoScroll = false
                end
            end
		end
		self:SetPosition(self.originalX + self.scrollX, pos.y, 0)
	elseif not self.opening then
		self:SetPosition(self.originalX, pos.y, 0)
	end

	if not TheInput:IsTouchDown() then
		self.scrollState = SCROLL_NONE
	end
end

function Inv:WillScroll()
	local screenPos = TheInput:GetScreenPosition()
	if screenPos.y < OPEN_MENU_TOP and self.scrollState == SCROLL_NONE then
		return true
	end
end

function Inv:ShowHUD()
    self.owner.HUD.controls:ShowActionControls()
    self.owner.HUD.controls:ShowRecordControls()
    if not TheInput:ControllerAttached() then
        self.owner.HUD.controls.mapcontrols:Show()
    end
    self.owner.HUD.controls.crafttabs:Show() -- TODO: Change to "MoveTo()"
    self.owner.HUD.controls:ShowVirtualStick()
    -- [blit-vicent] fix issue phone version when dragging object from inventory moves virtual stick
    self.owner.HUD.controls.virtualstick:ResetStick()
end

function Inv:HideHUD()
    self.owner.HUD.controls.actioncontrols:Hide()
    self.owner.HUD.controls.mapcontrols:Hide()
    self.owner.HUD.controls.crafttabs:Hide() -- TODO: Change to "MoveTo()"
    self.owner.HUD.controls:HideVirtualStick()
end

return Inv
