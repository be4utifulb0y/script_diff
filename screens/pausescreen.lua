local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
local PopupDialogScreen = require "screens/popupdialog"
local ControlsScreen = nil
local OptionsScreen = nil
if PLATFORM == "PS4" then
    ControlsScreen = require "screens/controlsscreen_ps4"
    OptionsScreen = require "screens/optionsscreen_ps4"
elseif PLATFORM == "iOS" then
    ControlsScreen = require "screens/controlsscreen_ios"
    OptionsScreen = require "screens/optionsscreen"
else
    ControlsScreen = require "screens/controlsscreen"
    OptionsScreen = require "screens/optionsscreen"
end

local function ShowLoading()
	if global_loading_widget then 
		global_loading_widget:SetEnabled(true)
	end
end

local function dorestart()

    ShowLoading()
    
	EnableAllDLC()
	local player = GetPlayer()
	local purchased = IsGamePurchased()
	local can_save = player and player:IsValid() and player.components.health and not player.components.health:IsDead() and IsGamePurchased()
	
	local postsavefn = function()
	    TheFrontEnd:HideSavingIndicator()
		if purchased then
			local player = GetPlayer()
			if player then
				player:PushEvent("quit", {})
			else
				StartNextInstance()
			end
		else
			ShowUpsellScreen(true)
			DEMO_QUITTING = true
		end
		
		inGamePlay = false
	end
	
	local ground = GetWorld()
	assert(ground, "Must have some terrain to get the map info.")
		
	local level_number = ground.topology.level_number or 1
	local level_type = ground.topology.level_type or "free"
	local day_number = GetClock().numcycles + 1
	
    if can_save then
        TheFrontEnd:ShowSavingIndicator()		
    end
    
	TheFrontEnd:Fade(false, 1, function() 
		if can_save then
		    TheSystemService:EnableStorage(true)
			SaveGameIndex:SaveCurrent(postsavefn)
		else
			postsavefn()
		end
	end)
end


local PauseScreen = Class(Screen, function(self)
	Screen._ctor(self, "PauseScreen")

	self.active = true
	SetPause(true,"pause")
	
	--darken everything behind the dialog
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.75)	

	self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0,0,0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

    local factor = 1
    if IPHONE_VERSION then
        factor = 1.5
    end

	--throw up the background
    self.bg = self.proot:AddChild(Image("images/globalpanels.xml", "small_dialog.tex"))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
	self.bg:SetScale(1.5*factor,1.5*factor,1.2*factor)
	
	--title	
    self.title = self.proot:AddChild(Text(TITLEFONT, 50*factor))
    self.title:SetPosition(0, 90*factor, 0)
    self.title:SetString(STRINGS.UI.PAUSEMENU.TITLE)

    	self.title:SetHAlign(ANCHOR_MIDDLE)

	if GetPlayer() then
		self.survived = self.proot:AddChild(Widget("Survived"))
		self.survived:SetPosition(-100, 10, 0)

		local days = math.floor(GetPlayer().components.age:GetAge() / TUNING.TOTAL_DAY_TIME)

		self.survived_daytext = self.survived:AddChild(Text(BUTTONFONT, 40))
		self.survived_daytext:SetRegionSize(450, 100)
		self.survived_daytext:SetHAlign(ANCHOR_LEFT)
		self.survived_daytext:SetPosition(300, -5, 0)
		self.survived_daytext:SetString(string.format(STRINGS.UI.PAUSEMENU.SURVIVED_DAYS, tostring(days))) --"Days"

		local survived_portrait_pos = {x = 0, y = 0}
		local survived_portrait_scale = 1.0
		self.survived_portrait_background = self.survived:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))
		self.survived_portrait_background:SetPosition(Vector3(survived_portrait_pos.x, survived_portrait_pos.y, 0))
		self.survived_portrait_background:SetScale(survived_portrait_scale,survived_portrait_scale,survived_portrait_scale)

		local character = GetPlayer().prefab
		local atlas = (table.contains(MODCHARACTERLIST, character) and "images/saveslot_portraits/"..character..".xml") or "images/saveslot_portraits.xml"
		self.survived_portrait = self.survived:AddChild(Image(atlas, character..".tex"))
		self.survived_portrait:SetPosition(Vector3(survived_portrait_pos.x , survived_portrait_pos.y - 1, 0))
		self.survived_portrait:SetScale(survived_portrait_scale,survived_portrait_scale,survived_portrait_scale)
	end



	--create the menu itself
	local player = GetPlayer()
	local can_save = player and player:IsValid() and player.components.health and not player.components.health:IsDead() and IsGamePurchased()
	local button_w = 160
	
	local buttons = {}
	table.insert(buttons, {text=STRINGS.UI.PAUSEMENU.CONTINUE, cb=function() TheFrontEnd:PopScreen(self) if not self.was_paused then SetPause(false) end GetWorld():PushEvent("continuefrompause") end })
	table.insert(buttons, {text=STRINGS.UI.PAUSEMENU.CONTROLS, cb=function() TheFrontEnd:PushScreen( ControlsScreen(true)) end })    	    
    table.insert(buttons, {text=STRINGS.UI.PAUSEMENU.OPTIONS, cb=function() TheFrontEnd:PushScreen( OptionsScreen(true))	end })
    table.insert(buttons, {text=can_save and STRINGS.UI.PAUSEMENU.SAVEANDQUIT or STRINGS.UI.PAUSEMENU.QUIT, cb=function() self:doconfirmquit() end})
    
	self.menu = self.proot:AddChild(Menu(buttons, button_w, true))
	self.menu:SetPosition(-(button_w*(#buttons-1))/2*factor, -95, 0)
	self.menu:SetScale(factor)

    if JapaneseOnPS4() then
		self.menu:SetTextSize(30)
	end

	TheInputProxy:SetCursorVisible(true)
	self.default_focus = self.menu
end)

 function PauseScreen:doconfirmquit()
 	self.active = false
	local player = GetPlayer()
	local can_save = player and player:IsValid() and player.components.health and not player.components.health:IsDead() and IsGamePurchased()
	local function doquit()
        if TheSim:IsRecording() then
            TheSim:StopRecording()
        end
		self.parent:Disable()
		self.menu:Disable()
		dorestart()
	end

	if can_save then
		local confirm = PopupDialogScreen(STRINGS.UI.PAUSEMENU.SAVEANDQUITTITLE, STRINGS.UI.PAUSEMENU.SAVEANDQUITBODY, {{text=STRINGS.UI.PAUSEMENU.SAVEANDQUITYES, cb = doquit},{text=STRINGS.UI.PAUSEMENU.SAVEANDQUITNO, cb = function() TheFrontEnd:PopScreen() end}  }, 560)
	    if JapaneseOnPS4() then
			confirm:SetTitleTextSize(40)
			confirm:SetButtonTextSize(30)
		end
		TheFrontEnd:PushScreen(confirm)
	else
		local confirm = PopupDialogScreen(STRINGS.UI.PAUSEMENU.QUITTITLE, STRINGS.UI.PAUSEMENU.QUITBODY, {{text=STRINGS.UI.PAUSEMENU.QUITYES, cb = doquit},{text=STRINGS.UI.PAUSEMENU.QUITNO, cb = function() TheFrontEnd:PopScreen() end}  })
	    if JapaneseOnPS4() then
			confirm:SetTitleTextSize(40)
			confirm:SetButtonTextSize(30)
		end
		TheFrontEnd:PushScreen( confirm )
	end
end

function PauseScreen:OnControl(control, down)
	if PauseScreen._base.OnControl(self,control, down) then return true end

	if (control == CONTROL_PAUSE or control == CONTROL_CANCEL) and not down then	
		self.active = false
		TheFrontEnd:PopScreen() 
		SetPause(false)
		GetWorld():PushEvent("continuefrompause")
		return true
	end

end

function PauseScreen:OnUpdate(dt)
	if self.active then
		SetPause(true)
	end
end

function PauseScreen:OnBecomeActive()
	PauseScreen._base.OnBecomeActive(self)
	-- Hide the topfade, it'll obscure the pause menu if paused during fade. Fade-out will re-enable it
	TheFrontEnd:HideTopFade()
end

return PauseScreen
