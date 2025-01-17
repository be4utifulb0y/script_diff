local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"

local num_name_page_types = 5



local internal_names =
{
    {x=300,y=30, bg=1, build="credits", bank="credits", anim="1", names=true},
    {x=-220,y=30, bg=3, build="credits", bank="credits", anim="2", names=true},
    {x=-325,y=30, bg=2, build="credits", bank="credits", anim="3", names=true},
    {x=260,y=30, bg=1, build="credits", bank="credits", anim="4", names=true},
    {x=-300,y=30, bg=2, build="credits", bank="credits", anim="5", names=true},
}

local pc_pages=
{

    {x=260, y=-20, tx=260, ty=200, bg=3, build="credits", title = STRINGS.UI.CREDITS.CAPY.TITLE, bank="credits", anim="4", capy_names=true},
    {x=-220, y=-20, tx=-220, ty=200, bg=2, build="credits", title = STRINGS.UI.CREDITS.CAPY.TITLE, bank="credits", anim="2", capy_names=true},

    --{x=300,y=30, bg=3, tx=300,ty=200,  title =STRINGS.UI.CREDITS.CAPY.TITLE, build="credits", bank="credits", anim="1", capy_names = true},    -- EXTRA THANKS 
    --{x=-220,y=30, bg=1, tx=-220,ty=200,  title =STRINGS.UI.CREDITS.CAPY.TITLE, build="credits", bank="credits", anim="2", flavour = STRINGS.UI.CREDITS.CAPY.NAMES},    -- EXTRA THANKS 
    
    {x=220,y=0, bg=3, tx=220,ty=200,  title =STRINGS.UI.CREDITS.THANKYOU, build="credits", bank="credits", anim="6", flavour = STRINGS.UI.CREDITS.EXTRA_THANKS},    -- EXTRA THANKS 
    {x=-260,y=0, bg=2, tx=-260,ty=200, title =STRINGS.UI.CREDITS.THANKYOU, build="credits", bank="credits", anim="7", flavour = STRINGS.UI.CREDITS.EXTRA_THANKS_2},    -- EXTRA THANKS - STEAM
    {x=0,y=0, bg=1, tx=0,ty=200, title =STRINGS.UI.CREDITS.ALTGAMES.TITLE, build="credits2", bank="credits2", anim="8", flavour = table.concat(STRINGS.UI.CREDITS.ALTGAMES.NAMES, "\n")},    -- ALTGAME
    {x=0,y=60, bg=3, flavour = STRINGS.UI.CREDITS.FMOD, build="credits2", bank="credits2", anim="9"},    -- FMOD
    {x=0,y=180, bg=2, tx=0,ty=180, title =STRINGS.UI.CREDITS.THANKYOU, thanks=true, delay=10, build="credits2", bank="credits2", anim="10"},      -- THANKS
    {x=0,y=180, bg=1, build="credits2", bank="credits2", anim="11", klei=true},      -- KLEI
}

local ps4_pages =
{
    {x=220,y=0, bg=1, tx=220,ty=200,  title =STRINGS.UI.CREDITS.THANKYOU, build="credits", bank="credits", anim="6", flavour = STRINGS.UI.CREDITS.EXTRA_THANKS},    -- GOOGLE 
    {x=-260,y=0, bg=3, tx=-260,ty=200, title =STRINGS.UI.CREDITS.THANKYOU, build="credits", bank="credits", anim="7", flavour = STRINGS.UI.CREDITS.EXTRA_THANKS_2},    -- STEAM
    {x=220,y=0, bg=2, tx=220,ty=200,  title =STRINGS.UI.CREDITS.THANKYOU, build="credits", bank="credits", anim="1", flavour = STRINGS.UI.CREDITS.SONY_THANKS},    -- SONY 
    {x=-260,y=0, bg=1, tx=-260, ty=200, title =STRINGS.UI.CREDITS.THANKYOU, build="credits", bank="credits", anim="3", flavour = table.concat(STRINGS.UI.CREDITS.ALTGAMES.NAMES, "\n")},    -- ALTGAMES
    {x=-220,y=0, bg=3, x2 = 260, y2 = 0, tx=20,ty=250, title = STRINGS.UI.CREDITS.BABEL.TITLE, build="credits2", bank="credits2", anim="8", flavour =table.concat(STRINGS.UI.CREDITS.BABEL.NAMES1, "\n"), flavour2 =table.concat(STRINGS.UI.CREDITS.BABEL.NAMES2, "\n")},    -- BABEL  
    {x=-220,y=0, bg=3, x2 = 260, y2 = 0, tx=20,ty=250, title = STRINGS.UI.CREDITS.BABEL.TITLE, build="credits2", bank="credits2", anim="9", flavour =table.concat(STRINGS.UI.CREDITS.BABEL.NAMES1, "\n"), flavour2 =table.concat(STRINGS.UI.CREDITS.BABEL.NAMES2, "\n")},    -- BABEL  
	{x=-100,y=60, bg=2, flavour = STRINGS.UI.CREDITS.FMOD, build="credits", bank="credits", anim="2"},    -- FMOD    
    {x=0,y=180, bg=1, build="credits2", bank="credits2", anim="11", klei=true},      -- KLEI
}

local names_per_page = 6
local PS4CREDITS = PLATFORM == "PS4"

local CreditsScreen = Class(Screen, function(self)
	Screen._ctor(self, "CreditsScreen")
 
    self.bg = self:AddChild(Image("images/ui.xml", "bg_plain.tex"))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)

    self.bgcolors = 
    {
        BGCOLOURS.RED,
        BGCOLOURS.YELLOW,
        BGCOLOURS.PURPLE,
        BGCOLOURS.TEAL,
    }
    self.bg:SetTint(self.bgcolors[1][1],self.bgcolors[1][2],self.bgcolors[1][3], 1)


    self.klei_img = self:AddChild(Image("images/ui.xml", "klei_new_logo.tex"))
    self.klei_img:SetVAnchor(ANCHOR_MIDDLE)
    self.klei_img:SetHAnchor(ANCHOR_MIDDLE)
    self.klei_img:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.klei_img:SetPosition( -175, 25, 0)

    self.CAPY_img = self:AddChild(Image("images/ui.xml", "logo_CAPY.tex"))
    self.CAPY_img:SetVAnchor(ANCHOR_MIDDLE)
    self.CAPY_img:SetHAnchor(ANCHOR_MIDDLE)
    self.CAPY_img:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.CAPY_img:SetPosition( 175, 25, 0)

    self.center_root = self:AddChild(Widget("root"))
    self.center_root:SetVAnchor(ANCHOR_MIDDLE)
    self.center_root:SetHAnchor(ANCHOR_MIDDLE)
    self.center_root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.bottom_root = self:AddChild(Widget("root"))
    self.bottom_root:SetVAnchor(ANCHOR_BOTTOM)
    self.bottom_root:SetHAnchor(ANCHOR_MIDDLE)
    self.bottom_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    
    self.worldanim = self.bottom_root:AddChild(UIAnim())
    self.worldanim:GetAnimState():SetBuild("credits")
    self.worldanim:GetAnimState():SetBank("credits")
    self.worldanim:GetAnimState():PlayAnimation("1", true)

    self.flavourtext = self.center_root:AddChild(Text(TITLEFONT, 70))
    self.flavourtext2 = self.center_root:AddChild(Text(TITLEFONT, 70))
    if not IPHONE_VERSION then
        self.thankyoutext = self.center_root:AddChild(Text(BODYTEXTFONT, 36))
    else
        self.thankyoutext = self.center_root:AddChild(Text(BODYTEXTFONT, 34))
    end
    self.thankyoutext:SetString(STRINGS.UI.CREDITS.THANKS)
    self.thankyoutext:Hide()

    TheFrontEnd:DoFadeIn(2)
    
    self.credit_names = deepcopy(STRINGS.UI.CREDITS.NAMES)
    self.CAPY_names = deepcopy(STRINGS.UI.CREDITS.CAPY.NAMES)


    if PS4CREDITS then
        table.insert(self.credit_names, "Auday Hussein")
    end

    shuffleArray(self.credit_names)
    shuffleArray(self.CAPY_names)
   
    -- for _, name in ipairs(self.CAPY_names) do
    --     table.insert(self.credit_names, name)
    -- end

    local num_credit_pages = math.floor(#self.credit_names / (names_per_page-1))
    self.num_leftover_names = #self.credit_names - num_credit_pages* (names_per_page-1)
    
    self.credit_name_idx = 1
    self.capy_credit_name_idx = 1

    self.pages = {}
    for k = 1, num_credit_pages do
        table.insert(self.pages, internal_names[1+ (k-1) % num_name_page_types])
    end
	for k,v in ipairs( PS4CREDITS and ps4_pages or pc_pages) do
        table.insert(self.pages, v)
	end


    self.titletext = self.center_root:AddChild(Text(TITLEFONT, 70))
    self.titletext:SetPosition(0, 180, 0)
    self.titletext:SetString(STRINGS.UI.CREDITS.THANKYOU)
    self.titletext:Hide()


    self.page_order_idx = 1
    self:ShowNextPage()
    

    if not TheInput:ControllerAttached() then
        --local right_pos_x = -150
        local left_pos_x = 110
        if not IPHONE_VERSION then
            left_pos_x = 240
        end

        self.OK_button = self:AddChild(ImageButton())
        if not IPHONE_VERSION then
            self.OK_button:SetScale(1.5,1.5,1.5)
        else
            self.OK_button:SetScale(.8,.8,.8)
        end
        self.OK_button:SetText(STRINGS.UI.MAINSCREEN.EXIT)
        self.OK_button:SetOnClick( function() TheFrontEnd:PopScreen(self) end )
        self.OK_button:SetVAnchor(ANCHOR_MIDDLE)
        self.OK_button:SetHAnchor(ANCHOR_MIDDLE)
        
        local yPos = -280
        if PLATFORM == "PS4" then
    		-- Safe Zone, move this up a bit, the default position is kind of low
            yPos = -240
        elseif not IPHONE_VERSION then
            yPos = -600
        end

        local xPos 
        if PLATFORM == "iOS" or PLATFORM == "Android" then
            self.OK_button:SetVAnchor(ANCHOR_BOTTOM)
            self.OK_button:SetHAnchor(ANCHOR_RIGHT)
            yPos = 95
            if IPHONE_VERSION then
                yPos = 35
            end
        --yPos = -100
            xPos = -150
        end


        print(RESOLUTION_Y)

        self.OK_button:SetPosition(xPos , yPos, 0)

        if PLATFORM ~= "PS4" then
            self.FB_button = self:AddChild(ImageButton())
            if not IPHONE_VERSION then
                self.FB_button:SetScale(1.5,1.5,1.5)
            else
                self.FB_button:SetScale(.8,.8,.8)
            end
            self.FB_button:SetText(STRINGS.UI.CREDITS.FACEBOOK)
            self.FB_button:SetOnClick( function() VisitURL("http://facebook.com/kleientertainment") end )
            self.FB_button:SetHAnchor(ANCHOR_LEFT)
            self.FB_button:SetVAnchor(ANCHOR_BOTTOM)
            self.TWIT_button = self:AddChild(ImageButton())
            if not IPHONE_VERSION then
                self.FB_button:SetPosition( left_pos_x, 105*2, 0)
                self.TWIT_button:SetScale(1.5,1.5,1.5)
            else
                self.FB_button:SetPosition( left_pos_x, 55*2, 0)
                self.TWIT_button:SetScale(.8,.8,.8)
            end
            self.TWIT_button:SetText(STRINGS.UI.CREDITS.TWITTER)
            self.TWIT_button:SetOnClick( function() VisitURL("http://twitter.com/klei", true) end )
            self.TWIT_button:SetHAnchor(ANCHOR_LEFT)
            self.TWIT_button:SetVAnchor(ANCHOR_BOTTOM)
            self.THANKS_button = self:AddChild(ImageButton())
            if not IPHONE_VERSION then
                self.TWIT_button:SetPosition( left_pos_x, 105, 0)
                self.THANKS_button:SetScale(1.5,1.5,1.5)
            else
                self.TWIT_button:SetPosition( left_pos_x, 55, 0)
                self.THANKS_button:SetScale(.8,.8,.8)
            end
            self.THANKS_button:SetText(STRINGS.UI.CREDITS.THANKYOU)
            self.THANKS_button:SetOnClick( function() VisitURL("http://www.dontstarvegame.com/Thank-You") end )
            self.THANKS_button:SetHAnchor(ANCHOR_LEFT)
            self.THANKS_button:SetVAnchor(ANCHOR_BOTTOM)
            if not IPHONE_VERSION then
                self.THANKS_button:SetPosition( left_pos_x, 105*3, 0)
            else
                self.THANKS_button:SetPosition( left_pos_x, 55*3, 0)
            end
            
            if PLATFORM == "iOS" or PLATFORM == "Android" then
                if IPHONE_VERSION then
                    self.THANKS_button:SetPosition( left_pos_x+400, 35, 0)
                    self.FB_button:SetPosition( left_pos_x+200, 35, 0)
                    self.TWIT_button:SetPosition( left_pos_x, 35, 0)
                    local sc = 1
                    self.THANKS_button:SetScale(sc)
                    self.FB_button:SetScale(sc)
                    self.TWIT_button:SetScale(sc)
                    self.OK_button:SetScale(sc)
                elseif PLATFORM == "iOS" and TheSim:IsUnsupportedDevice() then
                    self.THANKS_button:SetPosition( left_pos_x-75, 50*3, 0)
                    self.FB_button:SetPosition( left_pos_x-75, 50*2, 0)
                    self.TWIT_button:SetPosition( left_pos_x-75, 50, 0)
                    self.OK_button:SetPosition( xPos+70, 50, 0)
                    local sc = 0.7
                    self.THANKS_button:SetScale(sc)
                    self.FB_button:SetScale(sc)
                    self.TWIT_button:SetScale(sc)
                    self.OK_button:SetScale(sc)
                end
            end

            --focus crap
            self.OK_button:SetFocusChangeDir(MOVE_LEFT, self.TWIT_button)
            self.TWIT_button:SetFocusChangeDir(MOVE_RIGHT, self.OK_button)
            self.TWIT_button:SetFocusChangeDir(MOVE_UP, self.FB_button)
            self.FB_button:SetFocusChangeDir(MOVE_DOWN, self.TWIT_button)
            self.FB_button:SetFocusChangeDir(MOVE_UP, self.THANKS_button)
            self.THANKS_button:SetFocusChangeDir(MOVE_DOWN, self.FB_button)
        end
    end
end)


function CreditsScreen:OnBecomeActive()
    CreditsScreen._base.OnBecomeActive(self)
    TheFrontEnd:GetSound():PlaySound("dontstarve/music/gramaphone_ragtime", "creditsscreenmusic")    
end

function CreditsScreen:OnBecomeInactive()
    CreditsScreen._base.OnBecomeInactive(self)

    TheFrontEnd:GetSound():KillSound("creditsscreenmusic")    
    TheFrontEnd:GetSound():PlaySound("dontstarve_DLC002/music/music_FE","FEMusic")
end

function CreditsScreen:OnControl(control, down)
    if Screen.OnControl(self, control, down) then return true end
    if not down and control == CONTROL_CANCEL then
        TheFrontEnd:PopScreen(self)
        return true
    end
end


function CreditsScreen:ShowNextPage()
    local page = self.pages[self.page_order_idx]

    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/creditpage_flip", "flippage")   
    local bgidx = page.bg or 1
    self.bg:SetTint(self.bgcolors[page.bg][1],self.bgcolors[page.bg][2],self.bgcolors[page.bg][3], 1)

    self.worldanim:Show()
    self.worldanim:GetAnimState():SetBuild(page.build)
    self.worldanim:GetAnimState():SetBank(page.bank)
    self.worldanim:GetAnimState():PlayAnimation(page.anim, true)

    if page.title then
        self.titletext:Show()
        self.titletext:SetPosition(page.tx or 0, page.ty or 0, 0)
        self.titletext:SetString(page.title)
    else
        self.titletext:Hide()
    end
    
    if page.klei then
        self.klei_img:Show()
        self.CAPY_img:Show()
    else
        self.klei_img:Hide()
        self.CAPY_img:Hide()
    end

    if page.thanks then
        self.thankyoutext:Show()
    else
        self.thankyoutext:Hide()
    end

	self.flavourtext:Hide()
    if page.flavour then
        self.flavourtext:Show()
        self.flavourtext:SetPosition(page.x or 0, page.y or 0, 0)
        self.flavourtext:SetString(page.flavour)
	end
    
    if page.flavour2 then
        self.flavourtext2:Show()
        self.flavourtext2:SetPosition(page.x2 or 0, page.y2 or 0, 0)
        self.flavourtext2:SetString(page.flavour2)
	else
		self.flavourtext2:Hide()
	end
	
	
	        
    if page.names then
        self.flavourtext:Show()
        self.flavourtext:SetPosition(page.x or 0, page.y or 0, 0)

        local names_to_show = names_per_page-1
        if self.page_order_idx <= self.num_leftover_names then
            names_to_show = names_to_show + 1
        end

        local str = {}
        for k = 1, names_to_show do
            local name = self.credit_names[1 + (self.credit_name_idx -1) % #self.credit_names]
            table.insert(str, name)
            self.credit_name_idx = self.credit_name_idx + 1
        end
        --print (str)
        self.flavourtext:SetString(table.concat(str, "\n"))
    end

    if page.capy_names then
        self.flavourtext:Show()
        self.flavourtext:SetPosition(page.x or 0, page.y or 0, 0)

        local names_to_show = #self.CAPY_names / 2

        local str = {}
        for k = 1, names_to_show do
            local name = self.CAPY_names[1 + (self.capy_credit_name_idx -1) % #self.CAPY_names]
            table.insert(str, name)
            self.capy_credit_name_idx = self.capy_credit_name_idx + 1
        end
        --print (str)
        self.flavourtext:SetString(table.concat(str, "\n"))
    end


    self.page_order_idx = self.page_order_idx + 1
    if self.page_order_idx > #self.pages then
        self.page_order_idx = 1
    end

    local delay = page.delay or 3.3
	self.inst:DoTaskInTime(delay, function() self:ShowNextPage() end)
end



function CreditsScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    return TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK
end


return CreditsScreen
