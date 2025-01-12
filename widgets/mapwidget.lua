local Widget = require "widgets/widget"
local Image = require "widgets/image"

local MapWidget = Class(Widget, function(self)
    Widget._ctor(self, "MapWidget")
	self.owner = GetPlayer()

    self.bg = self:AddChild(Image("images/hud_shipwrecked.xml", "map_shipwrecked.tex"))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.bg.inst.ImageWidget:SetBlendMode( BLENDMODE.Premultiplied )
    
    self.minimap = GetWorld().minimap.MiniMap
    
    self.img = self:AddChild(Image())
    self.img:SetHAnchor(ANCHOR_MIDDLE)
    self.img:SetVAnchor(ANCHOR_MIDDLE)
    self.img.inst.ImageWidget:SetBlendMode( BLENDMODE.Additive )    
    
    if TheSim:IsUnsupportedDevice() then
        self.img:SetScale(1.667)
    else
        self.img:SetScale(1.333)
    end

	self.lastpos = nil
	self.minimap:ResetOffset()	
	self:StartUpdating()

	self.baseZoom = nil
 
     -- the touch start call is forcibly called on children by widget.lua, so no need for another handler
    --self.touchstarthandler = TheInput:AddTouchStartHandler(function(id, x, y) self:OnTouchStart(id, x, y) end)
    self.touchendhandler = TheInput:AddTouchEndHandler(function(id) self:OnTouchEnd(id) end)
    self.touchmovehandler = TheInput:AddTouchMoveHandler(function(id, x, y) self:OnTouchMove(id, x, y) end)
    self.numTouches = 0
    self.firstTouchId = -10

    self.inGesture = false
end)


function MapWidget:SetTextureHandle(handle)
	self.img.inst.ImageWidget:SetTextureHandle( handle )
end

function MapWidget:OnZoomIn(  )
	if self.shown then
		self.minimap:Zoom(self.minimap:GetZoom() -1 )
	end
end

function MapWidget:OnZoomOut( )
	if self.shown and self.minimap:GetZoom() < 20 then
		self.minimap:Zoom(self.minimap:GetZoom()+ 1 )
	end
end

function MapWidget:Distance(x0, y0, x1, y1)
    if not x0 or not y0 or not x1 or not y1 then return 0 end
	return math.sqrt((x1-x0)*(x1-x0) + (y1-y0)*(y1-y0))
end

function MapWidget:DoZoom( scale, state, x0, y0, x1, y1 )
    if self.shown then
        if state == 0 then
            self.baseZoom = self.minimap:GetZoom()
            self.baseX0 = x0
            self.baseY0 = y0
            self.baseX1 = x1
            self.baseY1 = y1
        end
        if self.baseZoom then
    local w = RESOLUTION_X
    local h = RESOLUTION_Y
            local pos0 = TheInput:GetScreenPosition()
            pos0.x = x0
            pos0.y = y0
            pos0.x = pos0.x - w*0.5
            pos0.y = pos0.y - h*0.5
            pos0 = pos0 * 0.22
            local scale0 = self:Distance(self.baseX0, self.baseY0, x0, y0)

            local pos1 = TheInput:GetScreenPosition()
            pos1.x = x1
            pos1.y = y1
            pos1.x = pos1.x - w*0.5
            pos1.y = pos1.y - h*0.5
            pos1 = pos1 * 0.22
            local scale1 = self:Distance(self.baseX1, self.baseY1, x1, y1)

            local sum = scale0 + scale1
            if(sum == 0) then return end
            scale0 = scale0 / sum
            scale1 = scale1 / sum

            local fPos = pos1-pos0
            fPos = fPos * scale0
            fPos = pos0+fPos

            self.minimap:Offset(-fPos.x, fPos.y)
            self.minimap:Zoom( self.baseZoom / scale )
            self.minimap:Offset(fPos.x, -fPos.y)

            self.baseX0 = x0
            self.baseY0 = y0
            self.baseX1 = x1
            self.baseY1 = y1
        end
        if state == 2 then
            self.baseZoom = nil
            self.inGesture = false
        end
    end
end

function MapWidget:SetRotation( rotation, state, x0, y0, x1, y1 )
    if self.shown then
        if state == 0 then
            self.baseRX0 = x0
            self.baseRY0 = y0
            self.baseRX1 = x1
            self.baseRY1 = y1
        end

    local w = RESOLUTION_X
    local h = RESOLUTION_Y
        local pos0 = TheInput:GetScreenPosition()
        pos0.x = x0
        pos0.y = y0
        pos0.x = pos0.x - w*0.5
        pos0.y = pos0.y - h*0.5
        pos0 = pos0 * 0.22
        local scale0 = self:Distance(self.baseRX0, self.baseRY0, x0, y0)

        local pos1 = TheInput:GetScreenPosition()
        pos1.x = x1
        pos1.y = y1
        pos1.x = pos1.x - w*0.5
        pos1.y = pos1.y - h*0.5
        pos1 = pos1 * 0.22
        local scale1 = self:Distance(self.baseRX1, self.baseRY1, x1, y1)

        local sum = scale0 + scale1
        if(sum == 0) then return end
        scale0 = scale0 / sum
        scale1 = scale1 / sum

        local fPos = pos1-pos0
        fPos = fPos * scale0
        fPos = pos0+fPos

        self.minimap:Offset(-fPos.x, fPos.y)
        local rot = self.minimap:GetRotation()
        local factor = 0.5
        if PLATFORM == "iOS" then
            if(TheSim:IsiPad3() or IPHONE_VERSION or TheSim:IsUnsupportedDevice()) then
                factor = 1
            end
        end
        
        if PLATFORM == "Android" then
            if IPHONE_VERSION then
                factor = 1
            end
        end
             
        self.minimap:SetRotation( rot + rotation*factor )
        self.minimap:Offset(fPos.x, -fPos.y)

        self.baseRX0 = x0
        self.baseRY0 = y0
        self.baseRX1 = x1
        self.baseRY1 = y1
    end
end


function MapWidget:UpdateTexture()
    local handle = self.minimap:GetTextureHandle()
    self:SetTextureHandle( handle )
end

function MapWidget:GestureStarted()
    self.inGesture = true
end

function MapWidget:GestureEnded()
    self.inGesture = false
    self.numTouches = 0
end

-- gestures are considered for OnTouchStart but not OnTouchEnd, so numTouches may increase to infinity.
    -- therefore we must set numTouches to 0 on GestureEnded
function MapWidget:OnTouchStart(id, x, y)
    if self.numTouches == 0 then
        self.firstTouchId = id
        self.lastpos = Vector3(x, y, 0)
    end
    self.numTouches = self.numTouches + 1
end

function MapWidget:OnTouchEnd(id)
    self.numTouches = self.numTouches - 1
    if self.numTouches < 0 then self.numTouches = 0 end
    if self.numTouches == 0 then
        self.lastpos = nil
        self.firstTouchId = -10
    end
end

function MapWidget:OnTouchMove(id, x, y)
    if self.inGesture then
        return
    end

    if id == self.firstTouchId then
        local pos = Vector3(x, y, 0)
        if self.lastpos then
            local scaleX = 0.1
            local scaleY = 0.1
            local dx = scaleX * ( pos.x - self.lastpos.x )
            local dy = scaleY * ( pos.y - self.lastpos.y )
            self.minimap:Offset( dx, dy )
        end
        self.lastpos = pos
    end
end

-- this function/class handles single taps and mapscreen.lua handles gestures, for some reason
function MapWidget:OnUpdate(dt)

    if not self.shown then return end
    
    --print("num touches: ", self.numTouches)

    --don't scroll the screen as if a touch move when releasing 1 finger after gesture
    if self.numTouches == 0 then
        self.inGesture = false
    end

    -- this is only for controllers?
    if TheInput:IsControlPressed(CONTROL_PRIMARY) then
        local pos = TheInput:GetScreenPosition()
        self:OnTouchMove(self.firstTouchId, pos.x, pos.y)
    end
end

function MapWidget:Offset(dx,dy)
    self.minimap:Offset(dx,dy)
end


function MapWidget:OnShow()
    self.minimap:ResetOffset()
end

function MapWidget:OnHide()
    self.lastpos = nil
end

return MapWidget
