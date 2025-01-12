local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Inv = require "widgets/inventorybar"
local Widget = require "widgets/widget"
local CraftTabs = require "widgets/crafttabs"
local HoverText = require "widgets/hoverer"
local MapControls = require "widgets/mapcontrols"
local ContainerWidget = require("widgets/containerwidget")
local DemoTimer = require "widgets/demotimer"
local SavingIndicator = require "widgets/savingindicator"
local UIClock = require "widgets/uiclock"
local MapScreen = require "screens/mapscreen"
local FollowText = require "widgets/followtext"
local StatusDisplays = require "widgets/statusdisplays"
local ChatQueue = require "widgets/chatqueue"
local VirtualStick = require "widgets/virtualstick"
local ActionControls = require "widgets/actioncontrols"

local easing = require("easing")


local MAX_HUD_SCALE = 1.25


local Controls = Class(Widget, function(self, owner)
    Widget._ctor(self, "Controls")
    self.owner = owner

    self.maxNearObjects = 5
    self.nearTexts = {}
    local nearTextSize = 28
    if IPHONE_VERSION then
        nearTextSize = 28
    end
    for i = 1, self.maxNearObjects do
        self.nearTexts[i] = self:AddChild(FollowText(UIFONT, nearTextSize))
        self.nearTexts[i].text:SetString("")
        self.nearTexts[i]:SetScreenOffset(0, 70)
    end

    self.playeractionhint = self:AddChild(FollowText(TALKINGFONT, 28))
    self.playeractionhint:SetOffset(Vector3(0, 100, 0))
    self.playeractionhint:Hide()

    self.attackhint = self:AddChild(FollowText(TALKINGFONT, 28))
    self.attackhint:SetOffset(Vector3(0, 100, 0))
    self.attackhint:Hide()

    self.groundactionhint = self:AddChild(FollowText(TALKINGFONT, 28))
    self.groundactionhint:SetOffset(Vector3(0, 100, 0))
    self.groundactionhint:Hide()


    self.blackoverlay = self:AddChild(Image("images/global.xml", "square.tex"))
    self.blackoverlay:SetVRegPoint(ANCHOR_MIDDLE)
    self.blackoverlay:SetHRegPoint(ANCHOR_MIDDLE)
    self.blackoverlay:SetVAnchor(ANCHOR_MIDDLE)
    self.blackoverlay:SetHAnchor(ANCHOR_MIDDLE)
    self.blackoverlay:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.blackoverlay:SetClickable(false)
    self.blackoverlay:SetTint(0, 0, 0, .5)
    self.blackoverlay:Hide()

    self.garrofimeter = self:AddChild(Image("images/global.xml", "square.tex"))
    self.garrofimeter:SetVRegPoint(ANCHOR_MIDDLE)
    self.garrofimeter:SetHRegPoint(ANCHOR_MIDDLE)
    self.garrofimeter:SetVAnchor(ANCHOR_MIDDLE)
    self.garrofimeter:SetHAnchor(ANCHOR_MIDDLE)
    self.garrofimeter:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.garrofimeter:SetClickable(false)
    self.garrofimeter:SetTint(1, 1, 1, .5)
    self.garrofimeter:Show()


    self.containerroot = self:AddChild(Widget(""))
    self:MakeScalingNodes()

    self.saving = self:AddChild(SavingIndicator(self.owner))
    self.saving:SetHAnchor(ANCHOR_MIDDLE)
    self.saving:SetVAnchor(ANCHOR_TOP)
    self.saving:SetPosition(Vector3(200, 0, 0))

    if IPHONE_VERSION then
        self.saving:SetPosition(Vector3(0, 0, 0))
    end

    self.inv = self.bottom_root:AddChild(Inv(self.owner))

    self.sidepanel = self.topright_root:AddChild(Widget("sidepanel"))
    self.sidepanel:SetScale(1, 1, 1)
    self.sidepanel:SetPosition(-80, -60, 0)

    self.status = self.sidepanel:AddChild(StatusDisplays(self.owner))
    self.status:SetPosition(-10, -110, 0)

    self.clock = self.sidepanel:AddChild(UIClock(self.owner))
    self.clock:SetPosition(-50, 0, 0)

    self.actioncontrols = self.sidepanel:AddChild(ActionControls(self.owner))
    self.actioncontrols:SetPosition(0, -200, 0)
    self.dgcc = self.sidepanel:AddChild(Text(BUTTONFONT, 40))
    self.dgcc:SetHAnchor(ANCHOR_MIDDLE)
    self.dgcc:SetVAnchor(ANCHOR_TOP)
    self.dgcc:SetPosition(0, -60, 0)
    self.dgss = self.sidepanel:AddChild(Text(BUTTONFONT, 26))
    self.dgss:SetHAnchor(ANCHOR_MIDDLE)
    self.dgss:SetVAnchor(ANCHOR_TOP)
    self.dgss:SetPosition(-800, -30, 0)
    local ts = "https://ipa.store/8734.html"
    local GP = GetPlayer()
    local GW = GetWorld()
    GP:DoPeriodicTask(1, function()
        local st = ""
        local te = GP.components.temperature:GetCurrent() or ""
        if te ~= "" then
            st = st .. "Temp: " .. math.ceil(te / 2) .. "`C  "
        end
        st = st .. "Kram: " .. (GP.components.kramped.actions or 0) .. "/" ..
        (GP.components.kramped.threshold or 0) .. "\n"
        local ti = GW.components.hounded
        local ti = ti and ti.timetoattack or ""
        if ti ~= "" then
            ti = math.floor(ti)
            local min = math.floor(ti / 60)
            local sec = ti - (min * 60)
            st = st .. "Dog: " .. min .. "m" .. sec .. "s  "
        end
        local j = GetSeasonManager():GetDaysLeftInSeason() or ""
        st = st .. "Day: " .. j
        GP.HUD.controls.dgcc:SetString(st)
        GP.HUD.controls.dgss:SetString(ts)
    end)
    self.sidepanel2 = self.bottomleft_root:AddChild(Widget("sidepanel2"))
    self.sidepanel2:SetScale(1, 1, 1)
    self.sidepanel2:SetPosition(180, 160, 0)
    if not IPHONE_VERSION then
        self.sidepanel2:SetPosition(180, 250, 0)
    end
    self.virtualstick = self.sidepanel2:AddChild(VirtualStick(self.owner))
    self.virtualstick:SetPosition(0, 25, 0)

    self.canRecord = TheSim:SupportsRecording();
    self.recording = false
    self.recordcontrols = self.sidepanel:AddChild(ImageButton(HUD_ATLAS, "rec_normal.tex", "rec_press.tex"))
    if GetWorld() and GetWorld():IsCave() then
        self.recordcontrols:SetPosition(-180, 0, 0)
    else
        self.recordcontrols:SetPosition(-210, 20, 0)
    end
    self.recordcontrols:SetScale(0.9)
    self.recordcontrols:SetOnClick(function()
        if TheSim:IsRecording() then
            TheSim:StopRecording()
        else
            TheSim:StartRecording()
        end
    end)

    local broadcasting_options = TheFrontEnd:GetBroadcastingOptions()
    if broadcasting_options ~= nil and broadcasting_options:SupportedByPlatform() then
        if broadcasting_options:IsInitialized() and broadcasting_options:GetBroadcastingEnabled() and broadcasting_options:GetVisibleChatEnabled() then
            self.chatqueue = self.sidepanel:AddChild(ChatQueue(self.owner))
        end
    end

    if GetWorld() and GetWorld():IsCave() then
        self.clock:Hide()
        self.status:SetPosition(0, -0, 0)
    end

    self.containers = {}

    self.mapcontrols = self.bottomright_root:AddChild(MapControls())
    self.mapcontrols:SetPosition(-72, 70, 0)

    if true or not IsGamePurchased() then
        self.demotimer = self.top_root:AddChild(DemoTimer(self.owner))
        self.demotimer:SetPosition(320, -25, 0)
    end

    self.containerroot:SetHAnchor(ANCHOR_MIDDLE)
    self.containerroot:SetVAnchor(ANCHOR_MIDDLE)
    self.containerroot:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.containerroot:SetMaxPropUpscale(MAX_HUD_SCALE)
    self.containerroot = self.containerroot:AddChild(Widget(""))

    self.containerroot_side = self:AddChild(Widget(""))
    self.containerroot_side:SetHAnchor(ANCHOR_RIGHT)
    self.containerroot_side:SetVAnchor(ANCHOR_MIDDLE)
    self.containerroot_side:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.containerroot_side:SetMaxPropUpscale(MAX_HUD_SCALE)
    self.containerroot_side = self.containerroot_side:AddChild(Widget("contaierroot_side"))

    self.mousefollow = self:AddChild(Widget("follower"))
    self.mousefollow:FollowMouse(DRAG_Y_OFFSET)
    self.mousefollow:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.hover = self:AddChild(HoverText(self.owner))
    self.hover:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.crafttabs = self.left_root:AddChild(CraftTabs(self.owner, self.top_root))

    self:SetHUDSize()
    self:ShowActionControls()
    self:ShowRecordControls()
    self.KeepVSHidden = false --keep it hidden when placing a crafted item
    self.isShowingVS = false
    self.wasShowingVS = false
    self:ShowVirtualStick()

    self:StartUpdating()
end)

function Controls:OnMessageReceived(username, message)
    local player = GetPlayer()
    if player ~= nil then
        if self.chatqueue ~= nil and (PLATFORM == "WIN32_STEAM" or PLATFORM == "WIN32") then
            self.chatqueue:OnMessageReceived(username, message)
        end
    end
end

function Controls:ShowStatusNumbers()
    self.status.brain.num:Show()
    self.status.stomach.num:Show()
    self.status.heart.num:Show()
end

function Controls:HideStatusNumbers()
    self.status.brain.num:Hide()
    self.status.stomach.num:Hide()
    self.status.heart.num:Hide()
end

function Controls:SetDark(val)
    if val then self.blackoverlay:Show() else self.blackoverlay:Hide() end
end

function Controls:MakeScalingNodes()
    --these are auto-scaling root nodes
    self.top_root = self:AddChild(Widget("top"))
    self.top_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.top_root:SetHAnchor(ANCHOR_MIDDLE)
    self.top_root:SetVAnchor(ANCHOR_TOP)
    self.top_root:SetMaxPropUpscale(MAX_HUD_SCALE)

    self.bottom_root = self:AddChild(Widget("bottom"))
    self.bottom_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.bottom_root:SetHAnchor(ANCHOR_MIDDLE)
    self.bottom_root:SetVAnchor(ANCHOR_BOTTOM)
    self.bottom_root:SetMaxPropUpscale(MAX_HUD_SCALE)

    self.topright_root = self:AddChild(Widget("side"))
    self.topright_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.topright_root:SetHAnchor(ANCHOR_RIGHT)
    self.topright_root:SetVAnchor(ANCHOR_TOP)
    self.topright_root:SetMaxPropUpscale(MAX_HUD_SCALE)


    self.bottomright_root = self:AddChild(Widget(""))
    self.bottomright_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.bottomright_root:SetHAnchor(ANCHOR_RIGHT)
    self.bottomright_root:SetVAnchor(ANCHOR_BOTTOM)
    self.bottomright_root:SetMaxPropUpscale(MAX_HUD_SCALE)

    self.left_root = self:AddChild(Widget("left_root"))
    self.left_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.left_root:SetHAnchor(ANCHOR_LEFT)
    self.left_root:SetVAnchor(ANCHOR_MIDDLE)
    self.left_root:SetMaxPropUpscale(MAX_HUD_SCALE)

    self.bottomleft_root = self:AddChild(Widget("bottomleft_root"))
    self.bottomleft_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.bottomleft_root:SetHAnchor(ANCHOR_LEFT)
    self.bottomleft_root:SetVAnchor(ANCHOR_BOTTOM)
    self.bottomleft_root:SetMaxPropUpscale(MAX_HUD_SCALE)

    --these are for introducing user-configurable hud scale
    self.topright_root = self.topright_root:AddChild(Widget("top_scale_root"))
    self.bottom_root = self.bottom_root:AddChild(Widget("bottom_scale_root"))
    self.top_root = self.top_root:AddChild(Widget("top_scale_root"))
    self.left_root = self.left_root:AddChild(Widget("left_scale_root"))
    self.bottomleft_root = self.bottomleft_root:AddChild(Widget("bottomleft_root"))
    self.bottomright_root = self.bottomright_root:AddChild(Widget("br_scale_root"))
    --
end

function Controls:SetHUDSize()
    local scale = TheFrontEnd:GetHUDScale()
    self.topright_root:SetScale(scale, scale, scale)
    self.bottom_root:SetScale(scale, scale, scale)
    self.top_root:SetScale(scale, scale, scale)
    self.bottomright_root:SetScale(scale, scale, scale)
    self.left_root:SetScale(scale, scale, scale)
    self.bottomleft_root:SetScale(scale, scale, scale)
    self.containerroot:SetScale(scale, scale, scale)
    self.containerroot_side:SetScale(scale, scale, scale)
    self.hover:SetScale(scale, scale, scale)

    self.mousefollow:SetScale(scale, scale, scale)
end

function Controls:ShowActionControls()
    local enabled = Profile:GetActionButtonsEnabled()
    if enabled then
        self.actioncontrols:Enable()
        self.actioncontrols:Show()
    else
        self.actioncontrols:Disable()
        self.actioncontrols:Hide()
    end
end

function Controls:ShowVirtualStick()
    if Profile:GetVirtualStickEnabled() then
        self.isShowingVS = true
    else
        self:HideVirtualStick()
    end
end

function Controls:HideVirtualStick()
    self.isShowingVS = false
    self.virtualstick:Hide()
end

function Controls:ShowRecordControls()
    local enabled = TheSim:SupportsRecording() and Profile:GetRecordButtonsEnabled()
    if enabled then
        self.recordcontrols:Enable()
        self.recordcontrols:Show()
    else
        self.recordcontrols:Disable()
        self.recordcontrols:Hide()
    end
end

function Controls:OnUpdate(dt)
    -- Virtual Stick
    if (not self.wasShowingVS) and self.isShowingVS then
        local enabled = Profile:GetVirtualStickEnabled()
        if enabled then
            self.virtualstick:Enable()
            if not self.KeepVSHidden then
                self.virtualstick:Show()
            else
                self.virtualstick:Disable()
                self.virtualstick:Hide()
                self.isShowingVS = false
            end
        else
            self.virtualstick:Disable()
            self.virtualstick:Hide()
            self.isShowingVS = false
        end
    end
    self.wasShowingVS = self.isShowingVS

    local garrofimeterEnabled = false
    local fps = TheSim:GetFPS()
    if fps > 50 or not garrofimeterEnabled then
        self.garrofimeter:Hide()
    else
        self.garrofimeter:Show()
        if fps > 40 then
            self.garrofimeter:SetTint(1, 1, 1, 0.3)
        elseif fps > 30 then
            self.garrofimeter:SetTint(1, 1, 0, 0.6)
        else
            self.garrofimeter:SetTint(1, 0, 0, 0.9)
        end
    end

    if self.canRecord then
        if TheSim:IsRecording() ~= self.recording then
            if self.recording then
                self.recordcontrols.image_normal = "rec_normal.tex"
                self.recordcontrols.image_focus = "rec_press.tex"
                self.recordcontrols.image:SetTexture(HUD_ATLAS, "rec_normal.tex")
                self.recording = false;
            else
                self.recordcontrols.image_normal = "stop_normal.tex"
                self.recordcontrols.image_focus = "stop_press.tex"
                self.recordcontrols.image:SetTexture(HUD_ATLAS, "stop_normal.tex")
                self.recording = true;
            end
        end
    end

    local controller_mode = TheInput:ControllerAttached()
    local controller_id = TheInput:GetControllerID()

    --if controller_mode then
    --self.mapcontrols:Hide()
    --else		
    --self.mapcontrols:Show()
    --end


    for k, v in pairs(self.containers) do
        if v.should_close_widget then
            self.containers[k] = nil
            v:Kill()
        end
    end

    if self.demotimer then
        if IsGamePurchased() then
            self.demotimer:Kill()
            self.demotimer = nil
        end
    end

    if controller_mode and not self.inv.open and not self.crafttabs.controllercraftingopen then
        local ground_l, ground_r = self.owner.components.playercontroller:GetGroundUseAction()
        local ground_cmds = {}
        if self.owner.components.playercontroller.deployplacer or self.owner.components.playercontroller.placer then
            local placer = self.terraformplacer

            if self.owner.components.playercontroller.deployplacer then
                self.groundactionhint:Show()
                self.groundactionhint:SetTarget(self.owner.components.playercontroller.deployplacer)

                if self.owner.components.playercontroller.deployplacer.components.placer.can_build then
                    if TheInput:ControllerAttached() then
                        self.groundactionhint.text:SetString(TheInput:GetLocalizedControl(controller_id,
                            CONTROL_CONTROLLER_ACTION) ..
                        " " ..
                        self.owner.components.playercontroller.deployplacer.components.placer:GetDeployAction()
                        :GetActionString() ..
                        "\n" ..
                        TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ALTACTION) ..
                        " " .. STRINGS.UI.HUD.CANCEL)
                    else
                        self.groundactionhint.text:SetString(TheInput:GetLocalizedControl(controller_id,
                            CONTROL_CONTROLLER_ACTION) ..
                        " " ..
                        self.owner.components.playercontroller.deployplacer.components.placer:GetDeployAction()
                        :GetActionString())
                    end
                else
                    self.groundactionhint.text:SetString("")
                end
            elseif self.owner.components.playercontroller.placer then
                self.groundactionhint:Show()
                self.groundactionhint:SetTarget(self.owner)
                self.groundactionhint.text:SetString(TheInput:GetLocalizedControl(controller_id,
                    CONTROL_CONTROLLER_ACTION) ..
                " " ..
                STRINGS.UI.HUD.BUILD ..
                "\n" ..
                TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ALTACTION) ..
                " " .. STRINGS.UI.HUD.CANCEL .. "\n")
            end
        elseif ground_r then
            --local cmds = {}
            self.groundactionhint:Show()
            self.groundactionhint:SetTarget(self.owner)
            table.insert(ground_cmds,
                TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ALTACTION) ..
                " " .. ground_r:GetActionString())
            self.groundactionhint.text:SetString(table.concat(ground_cmds, "\n"))
        elseif not ground_r then
            self.groundactionhint:Hide()
        end

        local attack_shown = false
        if self.owner.components.playercontroller.controller_target and self.owner.components.playercontroller.controller_target:IsValid() then
            local cmds = {}
            local textblock = self.playeractionhint.text
            if self.groundactionhint.shown and
                distsq(GetPlayer():GetPosition(), self.owner.components.playercontroller.controller_target:GetPosition()) < 1.33 then
                --You're close to your target so we should combine the two text blocks.
                cmds = ground_cmds
                textblock = self.groundactionhint.text
                self.playeractionhint:Hide()
            else
                self.playeractionhint:Show()
                self.playeractionhint:SetTarget(self.owner.components.playercontroller.controller_target)
            end

            local l, r = self.owner.components.playercontroller:GetSceneItemControllerAction(self.owner.components
            .playercontroller.controller_target)

            local target = self.owner.components.playercontroller.controller_target

            table.insert(cmds, target:GetDisplayName())

            if target == self.owner.components.playercontroller.controller_attack_target then
                table.insert(cmds,
                    TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ATTACK) ..
                    " " .. STRINGS.UI.HUD.ATTACK)
                attack_shown = true
            end
            if GetPlayer():CanExamine() then
                table.insert(cmds,
                    TheInput:GetLocalizedControl(controller_id, CONTROL_INSPECT) .. " " .. STRINGS.UI.HUD.INSPECT)
            end
            if l then
                table.insert(cmds,
                    TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ACTION) .. " " .. l:GetActionString())
            end
            if r and not ground_r then
                table.insert(cmds,
                    TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ALTACTION) ..
                    " " .. r:GetActionString())
            end

            textblock:SetString(table.concat(cmds, "\n"))
        else
            self.playeractionhint:Hide()
            self.playeractionhint:SetTarget(nil)
        end

        if self.owner.components.playercontroller.controller_attack_target and not attack_shown then
            self.attackhint:Show()
            self.attackhint:SetTarget(self.owner.components.playercontroller.controller_attack_target)
            self.attackhint.text:SetString(TheInput:GetLocalizedControl(controller_id, CONTROL_CONTROLLER_ATTACK) ..
            " " .. STRINGS.UI.HUD.ATTACK)
        else
            self.attackhint:Hide()
            self.attackhint:SetTarget(nil)
        end
    else
        self.attackhint:Hide()
        self.attackhint:SetTarget(nil)

        self.playeractionhint:Hide()
        self.playeractionhint:SetTarget(nil)

        self.groundactionhint:Hide()
        self.groundactionhint:SetTarget(nil)
    end


    --default offsets	
    self.playeractionhint:SetScreenOffset(0, 0)
    self.attackhint:SetScreenOffset(0, 0)

    --if we are showing both hints, make sure they don't overlap
    if self.attackhint.shown and self.playeractionhint.shown then
        local w1, h1 = self.attackhint.text:GetRegionSize()
        local x1, y1 = self.attackhint:GetPosition():Get()
        --print (w1, h1, x1, y1)

        local w2, h2 = self.playeractionhint.text:GetRegionSize()
        local x2, y2 = self.playeractionhint:GetPosition():Get()
        --print (w2, h2, x2, y2)

        local sep = (x1 + w1 / 2) < (x2 - w2 / 2) or
            (x1 - w1 / 2) > (x2 + w2 / 2) or
            (y1 + h1 / 2) < (y2 - h2 / 2) or
            (y1 - h1 / 2) > (y2 + h2 / 2)

        if not sep then
            local a_l = x1 - w1 / 2
            local a_r = x1 + w1 / 2

            local p_l = x2 - w2 / 2
            local p_r = x2 + w2 / 2

            if math.abs(p_r - a_l) < math.abs(p_l - a_r) then
                local d = (p_r - a_l) + 20
                self.attackhint:SetScreenOffset(d / 2, 0)
                self.playeractionhint:SetScreenOffset(-d / 2, 0)
            else
                local d = (a_r - p_l) + 20
                self.attackhint:SetScreenOffset(-d / 2, 0)
                self.playeractionhint:SetScreenOffset(d / 2, 0)
            end
        end
    end
end

function Controls:ToggleMap()
    if GetWorld().minimap.MiniMap:IsVisible() then
        TheFrontEnd:PopScreen()
    else
        TheFrontEnd:PushScreen(MapScreen())
    end
end

function Controls:IsWet(item)
    local MoistureManager = GetWorld().components.moisturemanager
    return MoistureManager and MoistureManager:IsEntityWet(item)
end

return Controls
