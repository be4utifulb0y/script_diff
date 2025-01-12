local Placer = Class(function(self, inst)
    self.inst = inst
	self.can_build = false
	self.radius = 1
	self.selected_pos = nil
	self.inst:AddTag("NOCLICK")
    self.hide = false
    self.actionButtonPressed = false
end)

function Placer:SetBuilder(builder, recipe, invobject)
	self.builder = builder
	self.recipe = recipe
	self.invobject = invobject
	self.inst:StartUpdatingComponent(self)	
end

function Placer:GetDeployAction()
	if self.invobject then
		self.selected_pos = self.inst:GetPosition()
		if self.invobject:HasTag("boat") then
			local action = BufferedAction(self.builder, nil, ACTIONS.LAUNCH, self.invobject, self.selected_pos)
			table.insert(action.onsuccess, function() self.selected_pos = nil end)
			return action
		else
			
			local action = BufferedAction(self.builder, nil, ACTIONS.DEPLOY, self.invobject, self.selected_pos)
			table.insert(action.onsuccess, function() self.selected_pos = nil end)
			return action
		end
	end
end

function Placer:getOffset()
	local offset = 1
    if self.recipe then
        if self.recipe.distance then
            offset = self.recipe.distance - 1
            offset = math.max(offset, 1)
        end
    end
    return offset
end

function Placer:DoPlace(pt, onsuccess, actionButtonPressed)
    local xdir = GetPlayer().components.playercontroller:GetWorldControllerVector()
    if self.actionButtonPressed and pt == nil then
        self.actionButtonPressed = false
        return true
    end
    

    if self.snap_to_meters and pt == nil then
        pt = Vector3(GetPlayer().entity:LocalToWorldSpace(1, 0, 0))
        pt = Vector3(math.floor(pt.x) + .5, 0, math.floor(pt.z) + .5)
        self.inst.Transform:SetPosition(pt:Get())
    else
        if self.inst.parent == nil and pt == nil then
            GetPlayer():AddChild(self.inst)
            self.inst.Transform:SetPosition(1, 0, 0)
        end
    end
        
    if not pt then
        pt = self.inst:GetPosition()
    end
        
    if self.can_build then
        GetPlayer().components.locomotor:Stop()
        local buffaction = nil
        if actionButtonPressed then
            if xdir == nil then
                self.actionButtonPressed = true
            end
            buffaction = BufferedAction(self.builder, nil, ACTIONS.DEPLOY, self.invobject, pt, nil, 1)
        else
            buffaction = BufferedAction(self.builder, nil, ACTIONS.DEPLOY, self.invobject, pt)
        end
        
        if onsuccess then
            buffaction:AddSuccessAction(function()
                self.selected_pos = nil
                onsuccess()
            end)
        else
            buffaction:AddSuccessAction(function()
                self.selected_pos = nil
            end)
        end
            
        GetPlayer().components.locomotor:PushAction(buffaction, true)
            
        return true
    end
    return false
end

local function findFloodGridNum(num)
	-- the flood grid is is the center of a 2x2 tile pattern. So 1,3,5,7..
    if math.mod(num, 2) == 0 then
        num = num +1
    end
    return num
end


function Placer:OnUpdate(dt)
    local pt = Input:GetWorldPosition()
    local currentAction = GetPlayer().components.playercontroller:GetCurrentAction()

    if dt == 0 and not TheInput:ControllerAttached() then
        if self.snap_to_tile and GetWorld().Map then
            pt = Vector3(GetWorld().Map:GetTileCenterPoint(pt:Get()))
        elseif self.snap_to_meters then
            pt = Vector3(math.floor(pt.x)+.5, 0, math.floor(pt.z)+.5)
        elseif self.snap_to_flood then
            pt.x = findFloodGridNum(math.floor(pt.x))
            pt.z = findFloodGridNum(math.floor(pt.z))
        end
    end
    local xdir = GetPlayer().components.playercontroller:GetWorldControllerVector()

    if not TheInput:ControllerAttached() then
        pt = Input:GetWorldPosition()
        if self.snap_to_tile and GetWorld().Map then
            pt = Vector3(GetWorld().Map:GetTileCenterPoint(pt:Get()))
        elseif self.snap_to_meters then
            pt = Vector3(math.floor(pt.x)+.5, 0, math.floor(pt.z)+.5)
        elseif self.snap_to_flood then
            pt.x = findFloodGridNum(math.floor(pt.x))
            pt.z = findFloodGridNum(math.floor(pt.z))
        end
        if not TheInput:IsTouchDown() and not self.hide then
            if self.snap_to_meters then
                pt = Vector3(GetPlayer().entity:LocalToWorldSpace(1,0,0))
                pt = Vector3(math.floor(pt.x)+.5, 0, math.floor(pt.z)+.5)
                self.inst.Transform:SetPosition(pt:Get())
            else
                if self.inst.parent == nil then
                    GetPlayer():AddChild(self.inst)
                    self.inst.Transform:SetPosition(1,0,0)
                end
            end
        elseif TheInput:IsTouchDown() then
            if xdir ~= nil then
                if self.snap_to_meters then
                    pt = Vector3(GetPlayer().entity:LocalToWorldSpace(1,0,0))
                    pt = Vector3(math.floor(pt.x)+.5, 0, math.floor(pt.z)+.5)
                    self.inst.Transform:SetPosition(pt:Get())
                else
                    if self.inst.parent == nil then
                        GetPlayer():AddChild(self.inst)
                        self.inst.Transform:SetPosition(1,0,0)
                    end
                end
                self.hide = false
            elseif dt ~= 0 and currentAction == 0 then
                if self.inst.parent ~= nil then
                    GetPlayer():RemoveChild(self.inst)
                end
                self.inst.Transform:SetPosition(pt:Get())
                self.hide = true
            end
        else
            if self.inst.parent ~= nil and self.hide then
                GetPlayer():RemoveChild(self.inst)
            end
            self.inst.Transform:SetPosition(pt:Get())
        end
    else

        local offset = self:getOffset()

        if self.snap_to_tile and GetWorld().Map then
            --Using an offset in this causes a bug in the terraformer functionality while using a controller.
            local pt = Vector3(GetPlayer().entity:LocalToWorldSpace(0,0,0))
            pt = Vector3(GetWorld().Map:GetTileCenterPoint(pt:Get()))
            self.inst.Transform:SetPosition(pt:Get())
        elseif self.snap_to_meters then
            local pt = Vector3(GetPlayer().entity:LocalToWorldSpace(offset,0,0))
            pt = Vector3(math.floor(pt.x)+.5, 0, math.floor(pt.z)+.5)
            self.inst.Transform:SetPosition(pt:Get())
        elseif self.snap_to_flood then
            local pt = Vector3(GetPlayer().entity:LocalToWorldSpace(offset,0,0))
            pt.x = findFloodGridNum(math.floor(pt.x))
            pt.z = findFloodGridNum(math.floor(pt.z))
            self.inst.Transform:SetPosition(pt:Get())
        elseif self.onground then
        --V2C: this will keep ground orientation accurate and smooth,
        --     but unfortunately position will be choppy compared to parenting

            self.inst.Transform:SetPosition(ThePlayer.entity:LocalToWorldSpace(1, 0, 0))
        else
            if self.inst.parent == nil then
                GetPlayer():AddChild(self.inst)
                self.inst.Transform:SetPosition(offset,0,0)
            end
        end
    end
    
    if self.fixedcameraoffset then
            local rot = TheCamera:GetHeading()
         self.inst.Transform:SetRotation(-rot+self.fixedcameraoffset) -- rotate against the camera
    end
    
    self.can_build = true

    if self.placeTestFn then
        local inputPt = Input:GetWorldPosition()

        if TheInput:ControllerAttached() then
            local offset = self:getOffset()
            inputPt =  Vector3(GetPlayer().entity:LocalToWorldSpace(offset,0,0))
        end

        local pt = self.selected_pos or inputPt
    
        self.can_build = self.placeTestFn(self.inst,pt)
        self.targetPos = self.inst:GetPosition()
    end

    if self.testfn and self.can_build then
        self.can_build = self.testfn(Vector3(self.inst.Transform:GetWorldPosition()))
    end
    
    --self.inst.AnimState:SetMultColour(0,0,0,.5)

    local pt = self.selected_pos or Input:GetWorldPosition()
    local ground = GetWorld()
    local tile = GROUND.GRASS
    if ground and ground.Map then
        tile = ground.Map:GetTileAtPoint(pt:Get())
    end

    local onground = not ground.Map:IsWater(tile)

    if (not self.can_build and self.hide_on_invalid) or (self.hide_on_ground and onground) then
        self.inst:Hide()
    else
        self.inst:Show()
        local color = self.can_build and Vector3(.25,.75,.25) or Vector3(.75,.25,.25)
        self.inst.AnimState:SetAddColour(color.x, color.y, color.z ,0)
    end

    if TheInput:IsTouchDown() or TheInput:ControllerAttached() then
        local player = GetPlayer()
        if player and player.HUD then
            local hover = player.HUD.controls.hover
            if hover.inMenu then
                self.inst:Hide()
            else
                self.inst:Show()
            end
        else
            self.inst:Show()
        end
    else
        if self.hide then
            self.inst:Hide()
        end
    end
end

return Placer
