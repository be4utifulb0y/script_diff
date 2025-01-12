local assets =
{
  --FE

    Asset("ANIM", "anim/credits.zip"),
    Asset("ANIM", "anim/credits2.zip"),

    Asset("ATLAS", "bigportraits/locked.xml"),
    Asset("IMAGE", "bigportraits/locked.tex"),

    Asset("IMAGE", "images/customisation.tex" ),
    Asset("ATLAS", "images/customisation.xml" ),
    Asset("IMAGE", "images/customization_shipwrecked.tex" ),
    Asset("ATLAS", "images/customization_shipwrecked.xml" ),
    
	Asset("ATLAS", "images/selectscreen_portraits.xml"),
	Asset("IMAGE", "images/selectscreen_portraits.tex"),
    Asset("ATLAS", "images/selectscreen_portraits.xml"),
    Asset("IMAGE", "images/selectscreen_portraits.tex"),
	
    Asset("ANIM", "anim/portrait_frame.zip"),

    --Asset("ANIM", "anim/build_status.zip"),
	Asset("ANIM",  "anim/corner_dude_sw.zip"),    
    Asset("ANIM", "anim/savetile.zip"),
    Asset("ANIM", "anim/savetile_small.zip"),
}

if PLATFORM == "PS4" then
    table.insert(assets, Asset("ATLAS", "images/ps4_dlc0001.xml"))
    table.insert(assets, Asset("IMAGE", "images/ps4_dlc0001.tex"))
    table.insert(assets, Asset("ATLAS", "images/ps4_controllers.xml"))
    table.insert(assets, Asset("IMAGE", "images/ps4_controllers.tex"))
    table.insert(assets, Asset("ANIM", "anim/animated_title.zip"))
    table.insert(assets, Asset("ANIM", "anim/title_fire.zip"))
end

if PLATFORM == "iOS" or PLATFORM == "Android" then
    table.insert(assets, Asset("ATLAS", "images/ios_langscreen.xml"))
    table.insert(assets, Asset("IMAGE", "images/ios_langscreen.tex"))
    table.insert(assets, Asset("ATLAS", "images/ps4_dlc0002.xml"))
    table.insert(assets, Asset("IMAGE", "images/ps4_dlc0002.tex"))
    table.insert(assets, Asset("ATLAS", "images/iphone4_menu.xml"))
    table.insert(assets, Asset("IMAGE", "images/iphone4_menu.tex"))
    if IPHONE_VERSION then
        table.insert(assets, Asset("ANIM", "anim/animated_title_mainmenu_iphone.zip"))
    else
        table.insert(assets, Asset("ANIM", "anim/animated_title.zip"))
    end

    table.insert(assets, Asset("ANIM", "anim/sw_title_shield.zip"))
    table.insert(assets, Asset("ATLAS", "images/blit_ios.xml"))
    table.insert(assets, Asset("IMAGE", "images/blit_ios.tex"))
end

-- Add all the characters by name
local charlist = GetActiveCharacterList and GetActiveCharacterList() or JoinArrays(MAIN_CHARACTERLIST, SHIPWRECKED_CHARACTERLIST)
for i,char in ipairs(charlist) do
    table.insert(assets, Asset("ATLAS", "bigportraits/"..char..".xml"))
    table.insert(assets, Asset("IMAGE", "bigportraits/"..char..".tex"))
	--table.insert(assets, Asset("IMAGE", "images/selectscreen_portraits/"..char..".tex"))
	--table.insert(assets, Asset("IMAGE", "images/selectscreen_portraits/"..char.."_silho.tex"))
end

--we don't actually instantiate this prefab. It's used for controlling asset loading
local function fn(Sim)
    return CreateEntity()
end

return Prefab( "UI/interface/frontend", fn, assets) 
