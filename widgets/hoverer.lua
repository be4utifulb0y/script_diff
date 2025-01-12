local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Image = require "widgets/image"

require("constants")

local YOFFSETUP = 40
local YOFFSETDOWN = 30
local XOFFSET = 10

if PLATFORM == "iOS" or PLATFORM == "Android" then
    YOFFSETUP = 60
    YOFFSETDOWN = -120
    YOFFSETUPTEXT = YOFFSETUP+3
    YOFFSETDOWNTEXT = YOFFSETDOWN-3
end
local HoverText = Class(Widget, function(self, owner)
    Widget._ctor(self, "HoverText")
	self.owner = owner
    self.isFE = false
    self:SetClickable(false)
    --self:MakeNonClickable()
    self.text = self:AddChild(Text(UIFONT, 30))
    self.text:SetPosition(0,YOFFSETUP,0)
    self.secondarytext = self:AddChild(Text(UIFONT, 30))
    self.secondarytext:SetPosition(0,-YOFFSETDOWN,0)
    self:StartUpdating()

    local factor = 1
    if IPHONE_VERSION then
        factor = 1.25
    end
    
    self.bg = self:AddChild(Image("images/ui.xml", "button.tex"))
    self.bg:SetPosition(0, YOFFSETUP*factor, 0)
    self.bg:SetScale(2*factor, 1*factor, 1*factor)
    self.bg:SetTint(0.25, 0.25, 0.25, 1)
    self.text = self:AddChild(Text(UIFONT, 30*factor))
    self.text:SetPosition(0,YOFFSETUPTEXT*factor,0)
    
    self.bg2 = self:AddChild(Image("images/ui.xml", "button.tex"))
    self.bg2:SetPosition(0, -YOFFSETDOWN*factor, 0)
    self.bg2:SetScale(2*factor, 1*factor, 1*factor)
    self.bg2:SetTint(0.25, 0.25, 0.25, 1)
    self.secondarytext = self:AddChild(Text(UIFONT, 30*factor))
    self.secondarytext:SetPosition(0,-YOFFSETDOWNTEXT*factor,0)

    self.bg3 = self:AddChild(Image("images/ui.xml", "button.tex"))
    self.bg3:SetPosition(0, -(YOFFSETDOWN*1.5*factor), 0)
    self.bg3:SetScale(2*factor, 1*factor, 1*factor)
    self.bg3:SetTint(0.25, 0.25, 0.25, 1)
    self.thirdtext = self:AddChild(Text(UIFONT, 30*factor))
    self.thirdtext:SetPosition(0,-(YOFFSETDOWNTEXT*1.5*factor),0)

    self.titleText = self:AddChild(Text(UIFONT, 40*factor))
    self.titleText:SetPosition(0,(YOFFSETUPTEXT*2.5*factor),0)
    self.titleText:SetString("")
    self.titleText:Hide()

    self.bg:Hide()
    self.bg2:Hide()
    self.bg3:Hide()

    self.menuFirstAction = nil
    self.menuSecondAction = nil
    self.menuThirdAction = nil

    self.x = 0
    self.y = 0

    self.projX = nil
    self.projY = nil
    self.projZ = nil

    self.actionControlsAction = 0

    self.delayTimer = 2.0
    self.inDelay = false

    if PLATFORM == "iOS" or PLATFORM == "Android" then
        self.inMenu = false
        self.highlightedAction = -1

        self.item = nil
        self.onEnd = false
        self.start_time = 0
    else
        self:FollowMouseConstrained()
    end
    self:StartUpdating()
end)

function HoverText:OnUpdate(dt)
	  
    if PLATFORM == "iOS" or PLATFORM == "Android" then
        if not TheInput:IsTouchDown() then
            self.inDelay = false
        end
        if self.actionControlsAction > 0 or (self.owner and self.owner.components and self.owner.components.playercontroller and self.owner.components.playercontroller.directwalking) then
            return
        end
        if self.inMenu then

            if self.onEnd then
                self.onEnd = false
                self.inMenu = false
                return
            end

            if (GetTime() - self.start_time) < 0.15 and self.item and self.item.isPlayerController then
                return
            end

            if self.highlightedAction == 0 then
                self.text:SetColour(MENU_HIGHLIGHT_TEXT_COLOUR[1], MENU_HIGHLIGHT_TEXT_COLOUR[2], MENU_HIGHLIGHT_TEXT_COLOUR[3], MENU_HIGHLIGHT_TEXT_COLOUR[4])
                self.bg:SetTint(0.75, 0.75, 0.75, 1)

                self.secondarytext:SetColour(MENU_TEXT_COLOUR[1], MENU_TEXT_COLOUR[2], MENU_TEXT_COLOUR[3], MENU_TEXT_COLOUR[4])
                self.bg2:SetTint(0.25, 0.25, 0.25, 1)

                self.thirdtext:SetColour(MENU_TEXT_COLOUR[1], MENU_TEXT_COLOUR[2], MENU_TEXT_COLOUR[3], MENU_TEXT_COLOUR[4])
                self.bg3:SetTint(0.25, 0.25, 0.25, 1)
            elseif self.highlightedAction == 1 then
                self.text:SetColour(MENU_TEXT_COLOUR[1], MENU_TEXT_COLOUR[2], MENU_TEXT_COLOUR[3], MENU_TEXT_COLOUR[4])
                self.bg:SetTint(0.25, 0.25, 0.25, 1)

                self.secondarytext:SetColour(MENU_HIGHLIGHT_TEXT_COLOUR[1], MENU_HIGHLIGHT_TEXT_COLOUR[2], MENU_HIGHLIGHT_TEXT_COLOUR[3], MENU_HIGHLIGHT_TEXT_COLOUR[4])
                self.bg2:SetTint(0.75, 0.75, 0.75, 1)

                self.thirdtext:SetColour(MENU_TEXT_COLOUR[1], MENU_TEXT_COLOUR[2], MENU_TEXT_COLOUR[3], MENU_TEXT_COLOUR[4])
                self.bg3:SetTint(0.25, 0.25, 0.25, 1)
            elseif self.highlightedAction == 2 then
                self.text:SetColour(MENU_TEXT_COLOUR[1], MENU_TEXT_COLOUR[2], MENU_TEXT_COLOUR[3], MENU_TEXT_COLOUR[4])
                self.bg:SetTint(0.25, 0.25, 0.25, 1)

                self.secondarytext:SetColour(MENU_TEXT_COLOUR[1], MENU_TEXT_COLOUR[2], MENU_TEXT_COLOUR[3], MENU_TEXT_COLOUR[4])
                self.bg2:SetTint(0.25, 0.25, 0.25, 1)

                self.thirdtext:SetColour(MENU_HIGHLIGHT_TEXT_COLOUR[1], MENU_HIGHLIGHT_TEXT_COLOUR[2], MENU_HIGHLIGHT_TEXT_COLOUR[3], MENU_HIGHLIGHT_TEXT_COLOUR[4])
                self.bg3:SetTint(0.75, 0.75, 0.75, 1)
            else
                self.text:SetColour(MENU_TEXT_COLOUR[1], MENU_TEXT_COLOUR[2], MENU_TEXT_COLOUR[3], MENU_TEXT_COLOUR[4])
                self.bg:SetTint(0.25, 0.25, 0.25, 1)

                self.secondarytext:SetColour(MENU_TEXT_COLOUR[1], MENU_TEXT_COLOUR[2], MENU_TEXT_COLOUR[3], MENU_TEXT_COLOUR[4])
                self.bg2:SetTint(0.25, 0.25, 0.25, 1)

                self.thirdtext:SetColour(MENU_TEXT_COLOUR[1], MENU_TEXT_COLOUR[2], MENU_TEXT_COLOUR[3], MENU_TEXT_COLOUR[4])
                self.bg3:SetTint(0.25, 0.25, 0.25, 1)
            end
        else
            self.text:SetColour(MENU_HIGHLIGHT_TEXT_COLOUR[1], MENU_HIGHLIGHT_TEXT_COLOUR[2], MENU_HIGHLIGHT_TEXT_COLOUR[3], MENU_HIGHLIGHT_TEXT_COLOUR[4])
            self.secondarytext:SetColour(MENU_HIGHLIGHT_TEXT_COLOUR[1], MENU_HIGHLIGHT_TEXT_COLOUR[2], MENU_HIGHLIGHT_TEXT_COLOUR[3], MENU_HIGHLIGHT_TEXT_COLOUR[4])
            self.thirdtext:SetColour(MENU_HIGHLIGHT_TEXT_COLOUR[1], MENU_HIGHLIGHT_TEXT_COLOUR[2], MENU_HIGHLIGHT_TEXT_COLOUR[3], MENU_HIGHLIGHT_TEXT_COLOUR[4])
        end

        local str = nil
        local secondarystr = nil
        local thirdstr = nil

        if self.isFE == false then
            if self.inMenu then
                --str, secondarystr = self.item:GetMenuStrings()
            elseif TheInput:IsTouchDown() then
                str = self.owner.HUD.controls:GetTooltip() or self.owner.components.playercontroller:GetHoverTextOverride()
            end
        else
            str = self.owner:GetTooltip()
        end
     

        if not str and self.isFE == false and (TheInput:IsTouchDown() or self.inMenu) then

            local lmb = self.owner.components.playercontroller:GetLeftMouseAction()
            if not TheInput:IsTouchDown() or GetPlayer().HUD.controls.crafttabs.open or GetPlayer().HUD.controls.inv.open then
                lmb = nil
            end
            if(self.inMenu) then
                lmb = self.menuFirstAction
            end
            if lmb then
                str = lmb:GetActionString()

                if lmb.target and lmb.invobject == nil and lmb.target ~= lmb.doer then
                    local name = lmb.target:GetDisplayName() or (lmb.target.components.named and lb.target.components.named.name)
                    if name then
                        local adjective = lmb.target:GetAdjective()
                        
                        if adjective then
                            str = str.. " " .. adjective .. " " .. name
                        else
                            str = str.. " " .. name
                        end
                        
                        if lmb.target.components.stackable and lmb.target.components.stackable.stacksize > 1 then
                            str = str .. " x" .. tostring(lmb.target.components.stackable.stacksize)
                        end
                        if lmb.target.components.inspectable and lmb.target.components.inspectable.recordview and lmb.target.prefab then
                            ProfileStatsSet(lmb.target.prefab .. "_seen", true)
                        end
                    end
                end
            else
                if self.inMenu then
                    str, secondarystr = self.item:GetMenuStrings()
                end
            end


            local rmb =  self.owner.components.playercontroller:GetRightMouseAction()

            if rmb and rmb.action == ACTIONS.TERRAFORM then
                if GetPlayer().components.inventory:GetActiveItem() then
                    rmb = nil 
                end
            end

            if(self.inMenu) then
                rmb = self.menuSecondAction
            end
            if rmb then
                secondarystr = STRINGS.RMB .. ": " .. rmb:GetActionString()
                if( PLATFORM == "iOS" or PLATFORM == "Android") then -- remove right click symbol
                    secondarystr = rmb:GetActionString()
                end
            end
            if self.inMenu and self.menuThirdAction then
                thirdstr = self.menuThirdAction:GetActionString()
            end
        end


        if self.inMenu then
            if str then
                --self.text:SetColour(MENU_TEXT_COLOUR[1], MENU_TEXT_COLOUR[2], MENU_TEXT_COLOUR[3], MENU_TEXT_COLOUR[4])
                self.text:SetString(str)
                self.text:Show()
                self.bg:Show()
            else
                --self.text:Hide()
            end
            if secondarystr then
                YOFFSETUP = -80
                YOFFSETDOWN = -50
                --self.secondarytext:SetColour(MENU_TEXT_COLOUR[1], MENU_TEXT_COLOUR[2], MENU_TEXT_COLOUR[3], MENU_TEXT_COLOUR[4])
                self.secondarytext:SetString(secondarystr)
                self.secondarytext:Show()
                self.bg2:Show()
            else
                self.secondarytext:Hide()
            end
            if thirdstr then
                self.thirdtext:SetString(thirdstr)
                self.thirdtext:Show()
                self.bg3:Show()
            else
                self.thirdtext:Hide()
            end

            self.str = str
            self.secondarystr = secondarystr
            self.thirdstr = thirdstr
        else
            if IPHONE_VERSION then
                if not self.inDelay then
                    self.inDelay = true
                    self.delayTimer = 0.2
                end
                self.delayTimer = self.delayTimer-dt
                if self.delayTimer > 0.0 then
                    str = nil
                    secondarystr = nil
                    thirdstr = nil
                end
            end
            if str then
                self.text:SetString(str)
                self.text:Show()
            else
                self.text:Hide()
            end
            if secondarystr then
                YOFFSETUP = -80
                YOFFSETDOWN = -50
                self.secondarytext:SetString(secondarystr)
                self.secondarytext:Show()
            else
                self.secondarytext:Hide()
            end
            if thirdstr then
                self.thirdtext:SetString(thirdstr)
                self.thirdtext:Show()
            else
                self.thirdtext:Hide()
            end

            self.str = str
            self.secondarystr = secondarystr
            self.thirdstr = thirdstr
            local pos = TheInput:GetScreenPosition()
            self:UpdatePosition(pos.x, pos.y)
        end
        if self.projX and self.projY and self.projZ and ((not self.item) or self.item.isPlayerController) then
            local scrPosX, scrPosY, scrPosZ = TheSim:GetScreenPos(self.projX, self.projY, self.projZ)
            if not self.inMenu and GetPlayer() and GetPlayer().components.playercontroller.placer then
                scrPosY = scrPosY + TheInput:GetTouchYOffset()
            end
            self:UpdatePosition(scrPosX, scrPosY, scrPosZ)
        end
    else  
        local using_mouse = self.owner.components and self.owner.components.playercontroller:UsingMouse()        
    	
    	if using_mouse ~= self.shown then
    		if using_mouse then
    			self:Show()
    		else
    			self:Hide()
    		end
    	end
    	
    	if not self.shown then 
    		return 
    	end
    	
        local str = nil
        local colour = nil
        if self.isFE == false then 
            str = self.owner.HUD.controls:GetTooltip() or self.owner.components.playercontroller:GetHoverTextOverride()
            if self.owner.HUD.controls:GetTooltip() then
                colour = self.owner.HUD.controls:GetTooltipColour()
            end
        else
            str = self.owner:GetTooltip()
        end

        local secondarystr = nil
     
        if not str and self.isFE == false then
            local lmb = self.owner.components.playercontroller:GetLeftMouseAction()
            if lmb then
                
                str = lmb:GetActionString()
                if not colour and lmb.target then
                    colour = (lmb.target and lmb.target:GetIsWet()) and WET_TEXT_COLOUR or NORMAL_TEXT_COLOUR
                    if lmb.invobject and not (lmb.invobject.components.weapon or lmb.invobject.components.tool) then
                        colour = (lmb.invobject and lmb.invobject:GetIsWet()) and WET_TEXT_COLOUR or NORMAL_TEXT_COLOUR
                    end
                elseif not colour and lmb.invobject then
                    colour = (lmb.invobject and lmb.invobject:GetIsWet()) and WET_TEXT_COLOUR or NORMAL_TEXT_COLOUR
                end
                
                if lmb.target and lmb.invobject == nil and lmb.target ~= lmb.doer then
    				local name = lmb.target:GetDisplayName() or (lmb.target.components.named and lb.target.components.named.name)
                    if name then
    					local adjective = lmb.target:GetAdjective()
    					
    					if adjective then
    						str = str.. " " .. adjective .. " " .. name
    					else
    						str = str.. " " .. name
    					end
    					
    					if lmb.target.components.stackable and lmb.target.components.stackable.stacksize > 1 then
    	                    str = str .. " x" .. tostring(lmb.target.components.stackable.stacksize)
    					end
                        if lmb.target.components.inspectable and lmb.target.components.inspectable.recordview and lmb.target.prefab then
                            ProfileStatsSet(lmb.target.prefab .. "_seen", true)
                        end
    				end
                end
            end
            local rmb = self.owner.components.playercontroller:GetRightMouseAction()
            if rmb then
                secondarystr = STRINGS.RMB .. ": " .. rmb:GetActionString()
            end
        end

        if not colour then colour = NORMAL_TEXT_COLOUR end
        if str then
            self.text:SetColour(colour[1], colour[2], colour[3], colour[4])
            self.text:SetString(str)
            self.text:Show()
        else
            self.text:SetColour(colour[1], colour[2], colour[3], colour[4])
            self.text:Hide()
        end
        if secondarystr then
            YOFFSETUP = -80
            YOFFSETDOWN = -50
            self.secondarytext:SetString(secondarystr)
            self.secondarytext:Show()
        else
            self.secondarytext:Hide()
        end

        local changed = (self.str ~= str) or (self.secondarystr ~= secondarystr)
        self.str = str
        self.secondarystr = secondarystr
        if changed then
            local pos = TheInput:GetScreenPosition()
            self:UpdatePosition(pos.x, pos.y)
        end
    end
end

function HoverText:UpdatePosition(x,y)

    if self.inMenu then

        local scr_w, scr_h = TheSim:GetScreenSize()

        local minx = scr_w
        local maxx = 0
        local miny = scr_h
        local maxy = 0
        
        local w0, h0 = self.bg:GetSize()
        
        if self.text and self.str then
            w0 = w0*self.bg:GetScale().x
            h0 = h0*self.bg:GetScale().y
            local pos0 = self.bg:GetPosition()
            pos0.x = pos0.x*self.bg:GetScale().x
            pos0.y = pos0.y*self.bg:GetScale().y
            minx = math.min(minx, pos0.x - w0/2)
            maxx = math.max(maxx, pos0.x + w0/2)
            miny = math.min(miny, pos0.y - h0/2)
            maxy = math.max(maxy, pos0.y + h0/2)
        end
        if self.secondarytext and self.secondarystr then
            local w1, h1 = self.bg2:GetSize()
            w1 = w1*self.bg2:GetScale().x
            h1 = h1*self.bg2:GetScale().y
            local pos1 = self.bg2:GetPosition()
            pos1.x = pos1.x*self.bg2:GetScale().x
            pos1.y = pos1.y*self.bg2:GetScale().y
            minx = math.min(minx, pos1.x - w1/2)
            maxx = math.max(maxx, pos1.x + w1/2)
            miny = math.min(miny, pos1.y - h1/2)
            maxy = math.max(maxy, pos1.y + h1/2)
        end
        if self.thirdtext and self.thirdstr then
            local w2, h2 = self.bg3:GetSize()
            w2 = w2*self.bg3:GetScale().x
            h2 = h2*self.bg3:GetScale().y
            local pos2 = self.bg3:GetPosition()
            pos2.x = pos2.x*self.bg3:GetScale().x
            pos2.y = pos2.y*self.bg3:GetScale().y
            minx = math.min(minx, pos2.x - w2/2)
            maxx = math.max(maxx, pos2.x + w2/2)
            miny = math.min(miny, pos2.y - h2/2)
            maxy = math.max(maxy, pos2.y + h2/2)
        end

        if (x + maxx) > scr_w then
            x = scr_w - maxx
        elseif (x + minx) < 0 then
            x = -minx
        end

        if (y + maxy) > scr_h then
            y = scr_h - maxy
        elseif (y + miny) < 0 then
            y = -miny
        end

        local items = 1
        if self.menuThirdAction then
            items = 3
        elseif self.menuSecondAction then
            items = 2
        end

        y = y - 50 * (1+items)

        if ( y < 0) then
          y = 0
        end

        if ( x < w0 ) then
          x = w0
        elseif (x > (scr_w - w0)) then
          x = scr_w - w0
        end
        
        -- --

        if ( x < w0 ) then
          x = w0
        elseif (x > (scr_w - w0)) then
          x = scr_w - w0
        end

        if ( y < 0 ) then
          y = h0
        elseif (y > scr_h) then
          y = scr_h - h0
        end

        self.x = x
        self.y = y
        
        self:SetPosition(x,y,0)

    else

        local scale = self:GetScale()
        local scr_w, scr_h = TheSim:GetScreenSize()

        local w = 0
        local h = 0

        if self.text and self.str then
            local w0, h0 = self.text:GetRegionSize()
            w = math.max(w, w0)
            h = math.max(h, h0)
        end
        if self.secondarytext and self.secondarystr then
            local w1, h1 = self.secondarytext:GetRegionSize()
            w = math.max(w, w1)
            h = math.max(h, h1)
        end

        w = w*scale.x
        h = h*scale.y

        x = math.max(x, w/2 + XOFFSET)
        x = math.min(x, scr_w - w/2 - XOFFSET)

        y = math.max(y, h/2 + YOFFSETDOWN*scale.y)
        y = math.min(y, scr_h - h/2 - YOFFSETUP*scale.y)

        self.x = x
        self.y = y

        self.projX, self.projY, self.projZ = TheSim:ProjectScreenPos(x, y, 0)

        self:SetPosition(x,y,0)

    end
end

function HoverText:FollowMouseConstrained()
    if not self.followhandler then
        self.followhandler = TheInput:AddMoveHandler(function(x,y) self:UpdatePosition(x,y) end)
        local pos = TheInput:GetScreenPosition()
        self:UpdatePosition(pos.x, pos.y)
    end
end

function HoverText:StartMenu(title)
    self.highlightedAction = 0
    self.inMenu = true
    self:Show()
    self.onEnd = false
    TheFrontEnd.tracking_mouse = false
    self.start_time = GetTime()

    if title then
        local factor = 1
        if IPHONE_VERSION then
            factor = 1.5
        end

        local items = 1
        if self.menuThirdAction then
            items = 3
        elseif self.menuSecondAction then
            items = 2
        end
        self.titleText:SetString(title)

        local y = YOFFSETUPTEXT*(1+items)*factor
        if IPHONE_VERSION then
          y = y - 40 - 10 * items
        end

        self.titleText:SetPosition(0,y,0)
        self.titleText:Show()
    end

    if title then
        self.isWorldMenu = false
    else
        self.isWorldMenu = true
    end

    if IPHONE_VERSION and (not self.isWorldMenu) then
        self.owner.HUD.controls:HideVirtualStick()
    end
end

function HoverText:DoMenu()
    if self.item then
        local result = self.item:DoMenu()
        if IPHONE_VERSION and result then
            GetPlayer().HUD:ClosePhoneInventory()
        end
    end
end

function HoverText:EndMenu()
    print("EndMenu")
    self.highlightedAction = -1
    --self.inMenu = false
    self.onEnd = true
    self.item = nil
    self.text:Hide()
    self.secondarytext:Hide()
    self.thirdtext:Hide()
    self.str = nil
    self.secondarystr = nil
    self.thirdstr = nil
    self.menuFirstAction = nil
    self.menuSecondAction = nil
    self.menuThirdAction = nil
    self.bg:Hide()
    self.bg2:Hide()
    self.bg3:Hide()
    self.titleText:Hide()
    --self:Hide()
    if IPHONE_VERSION and (not self.isWorldMenu) then
        self.owner.HUD.controls:ShowVirtualStick()
    end
end

function HoverText:UpdateHighlightedActions(x, y)
    if self.inMenu then

        local scale = self:GetScale()

        self.highlightedAction = -1

        if self.text and self.str then
            local pos = self:GetWorldPosition()
            --[[if not (x < (pos.x - 20) or x > (pos.x + 20) or y < (pos.y - 20) or y > (pos.y + 20)) then
                self.highlightedAction = 0
                return
            end]]

            local w0, h0 = self.bg:GetSize()
            w0 = w0*self.bg:GetScale().x
            h0 = h0*self.bg:GetScale().y
            local pos0 = self.bg:GetWorldPosition()

            local minx0, maxx0 = (pos0.x - w0/2), (pos0.x + w0/2)
            local miny0, maxy0 = (pos0.y - h0/2), (pos0.y + h0/2)
            if not (x < minx0 or x > maxx0 or y < miny0 or y > maxy0) then
                self.highlightedAction = 0
                return 0
            end
        end
        if self.secondarytext and self.secondarystr then
            local w1, h1 = self.bg2:GetSize()
            w1 = w1*self.bg:GetScale().x
            h1 = h1*self.bg:GetScale().y
            local pos1 = self.bg2:GetWorldPosition()

            local minx1, maxx1 = (pos1.x - w1/2), (pos1.x + w1/2)
            local miny1, maxy1 = (pos1.y - h1/2), (pos1.y + h1/2)
            if not (x < minx1 or x > maxx1 or y < miny1 or y > maxy1) then
                self.highlightedAction = 1
                return 1
            end
        end
        if self.thirdtext and self.thirdstr then
            local w2, h2 = self.bg3:GetSize()
            w2 = w2*self.bg:GetScale().x
            h2 = h2*self.bg:GetScale().y
            local pos2 = self.bg3:GetWorldPosition()

            local minx2, maxx2 = (pos2.x - w2/2), (pos2.x + w2/2)
            local miny2, maxy2 = (pos2.y - h2/2), (pos2.y + h2/2)
            if not (x < minx2 or x > maxx2 or y < miny2 or y > maxy2) then
                self.highlightedAction = 2
                return 2
            end
        end
    end
    return -1
end

return HoverText
