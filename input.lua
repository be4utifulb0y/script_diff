require "events"
local Text = require "widgets/text"

Input = Class(function(self)
    self.onkey = EventProcessor()     -- all keys, down and up, with key param
    self.onkeyup = EventProcessor()   -- specific key up, no parameters
    self.onkeydown = EventProcessor() -- specific key down, no parameters
    self.onmouseup = EventProcessor()
    self.onmousedown = EventProcessor()
    
    self.ontouch = EventProcessor()

    self.position = EventProcessor()
    self.oncontrol = EventProcessor()
    self.ontextinput = EventProcessor()
    self.ongesture = EventProcessor()
    self.ontapgesture = EventProcessor()
    
    self.hoverinst = nil
    self.enabledebugtoggle = true

    self.numtouches = 0

	if PLATFORM == "PS4" then     
        self.mouse_enabled = false
    else
        self.mouse_enabled = true
    end

    self:DisableAllControllers()
end)

function Input:DisableAllControllers()
    for i = 1, TheInputProxy:GetInputDeviceCount() do
        if TheInputProxy:IsInputDeviceEnabled(i) then
            TheInputProxy:EnableInputDevice(i, false)
        end
    end
end

function Input:EnableAllControllers()
    for i = 1, TheInputProxy:GetInputDeviceCount() do
      --if TheInputProxy:IsInputDeviceConnected(i) then
      TheInputProxy:EnableInputDevice(i, true)
      --end
    end
end

function Input:EnableMouse(enable)
    self.mouse_enabled = enable
end

function Input:GetControllerID()
    local device_id = 0
    for i = 1, TheInputProxy:GetInputDeviceCount() do
      if TheInputProxy:GetInputDeviceName(i) == "GameController" and 
         TheInputProxy:IsInputDeviceEnabled(i) and
         TheInputProxy:IsInputDeviceConnected(i) then
        device_id = i
      end
    end
  return device_id
end

function Input:ControllerAttached()
	if PLATFORM == "PS4" then
		return true	
	elseif PLATFORM == "NACL" then
		return false
  else
		--need to take enabled into account
    for i = 1, TheInputProxy:GetInputDeviceCount() do
      --print("Blit - Input:ControllerAttached =", TheInputProxy:IsInputDeviceEnabled(i), " - ", TheInputProxy:IsInputDeviceConnected(i))
      if TheInputProxy:GetInputDeviceName(i) == "GameController" and 
          TheInputProxy:IsInputDeviceEnabled(i) and
          TheInputProxy:IsInputDeviceConnected(i) then
         --print ("DEVICE", i, "of", TheInputProxy:GetInputDeviceCount(), "IS ENABLED")
        return true
      end
    end
    return false
	end
end

function Input:ControllerConnected()
	if PLATFORM == "PS4" then
		return true	
	elseif PLATFORM == "NACL" then
		return false
	else
		--need to take enabled into account
    for i = 1, TheInputProxy:GetInputDeviceCount() do
      if TheInputProxy:GetInputDeviceName(i) == "GameController" and 
         TheInputProxy:IsInputDeviceConnected(i) then
        --print ("DEVICE", i, "of", TheInputProxy:GetInputDeviceCount(),  TheInputProxy:GetInputDeviceName(i),  "IS CONNECTED")
        return true
      end
    end
    return false
	end
end


-- Get a list of connected input devices and their ids
function Input:GetInputDevices()
  local numDevices = TheInputProxy:GetInputDeviceCount()
  local devices = {}
  for i = 1, numDevices do
    if TheInputProxy:IsInputDeviceConnected(i) then
      local device_type = TheInputProxy:GetInputDeviceType(i)
      table.insert(devices, {text=STRINGS.UI.CONTROLSSCREEN.INPUT_NAMES[device_type+1], data=i})
    end
  end
  return devices
end


function Input:AddTextInputHandler( fn )
    return self.ontextinput:AddEventHandler("text", fn)
end

function Input:AddKeyUpHandler( key, fn )
    return self.onkeyup:AddEventHandler(key, fn)
end

function Input:AddKeyDownHandler( key, fn )
    return self.onkeydown:AddEventHandler(key, fn)
end

function Input:AddKeyHandler( fn )
    return self.onkey:AddEventHandler("onkey", fn)
end

function Input:AddMouseButtonHandler( button, down, fn)
    if down then
        return self.onmousedown:AddEventHandler(button, fn)
    else
        return self.onmouseup:AddEventHandler(button, fn)
    end
end

function Input:AddTouchStartHandler(fn)
    return self.ontouch:AddEventHandler("touchstart", fn)
end

function Input:AddTouchMoveHandler(fn)
    return self.ontouch:AddEventHandler("touchmove", fn)
end

function Input:AddTouchEndHandler(fn)
    return self.ontouch:AddEventHandler("touchend", fn)
end

function Input:AddTouchCancelHandler(fn)
    return self.ontouch:AddEventHandler("touchcancel", fn)
end

function Input:AddMoveHandler( fn )
    return self.position:AddEventHandler("move", fn)
end

function Input:AddControlHandler(control, fn)
    return self.oncontrol:AddEventHandler(control, fn)
end

function Input:AddGeneralControlHandler(fn)
    return self.oncontrol:AddEventHandler("oncontrol", fn)
end

function Input:AddControlMappingHandler(fn)
    return self.oncontrol:AddEventHandler("onmap", fn)
end

function Input:AddGestureHandler( gesture, fn )
    return self.ongesture:AddEventHandler(gesture, fn)
end

function Input:AddTapGestureHandler( fn )
    return self.ontapgesture:AddEventHandler("ontapgesture", fn )
end

function Input:UpdatePosition(x,y)
    --print("Input:UpdatePosition", x, y)
    if self.mouse_enabled then
		self.position:HandleEvent("move", x, y)
	end
end

function Input:OnControl(control, digitalvalue, analogvalue)
    
    if (control == CONTROL_PRIMARY or control == CONTROL_SECONDARY) and not self.mouse_enabled then return end
    if not Profile:IsToggleControllerEnabled() then return end
    if not TheFrontEnd:OnControl(control, digitalvalue) then
        self.oncontrol:HandleEvent(control, digitalvalue, analogvalue)
        self.oncontrol:HandleEvent("oncontrol", control, digitalvalue, analogvalue)
    end
end

function Input:OnMouseMove(x,y)
	if self.mouse_enabled then
		TheFrontEnd:OnMouseMove(x,y)
	end
end

function Input:OnMouseButton(button, down, x,y)
	if self.mouse_enabled then
		TheFrontEnd:OnMouseButton(button, down, x,y)
	end
end

function Input:OnRawKey(key, down)
	self.onkey:HandleEvent("onkey", key, down)

	if down then
		self.onkeydown:HandleEvent(key)
	else
		self.onkeyup:HandleEvent(key)
	end
end

function Input:OnText(text)
	--print("Input:OnText", text)
	self.ontextinput:HandleEvent("text", text)
end

function Input:OnTouchStart(id,x,y)
    TheFrontEnd:OnTouchStart(id,x,y)
    self.ontouch:HandleEvent("touchstart", id, x, y)
    self.numtouches = self.numtouches + 1
end

function Input:OnTouchMove(id,x,y)
    self.ontouch:HandleEvent("touchmove", id, x, y)
    TheFrontEnd:OnTouchMove(id,x,y)
end

function Input:OnTouchEnd(id)
    TheFrontEnd:OnTouchEnd(id)
    self.ontouch:HandleEvent("touchend", id)
    self.numtouches = self.numtouches - 1
end

function Input:OnTouchCancel(id)
    TheFrontEnd:OnTouchCancel(id)
    self.ontouch:HandleEvent("touchcancel", id)
    self.numtouches = self.numtouches - 1
end

function Input:OnGesture(gesture, value, velocity, state, x0, y0, x1, y1)
    self.ongesture:HandleEvent(gesture, value, velocity, state, x0, y0, x1, y1)
    TheFrontEnd:OnGesture(gesture, value, velocity, state, x0, y0, x1, y1)
end

function Input:OnTapGesture(gesture, x, y)
    self.ontapgesture:HandleEvent("ontapgesture", gesture, x, y)
    TheFrontEnd:OnTapGesture(gesture, x, y)
end

function Input:OnControlMapped(deviceId, controlId, inputId, hasChanged)
    self.oncontrol:HandleEvent("onmap", deviceId, controlId, inputId, hasChanged)
end

function Input:OnFrameStart()
    self.hoverinst = nil
    self.hovervalid = false
end

function Input:GetScreenPosition()
    local x, y = TheSim:GetPosition()
    return Vector3(x,y,0)
end

function Input:GetWorldPosition()
    local x,y,z = TheSim:ProjectScreenPos(TheSim:GetPosition())
    if x and y and z then
        return Vector3(x,y,z)
    end
end

function Input:GetAllEntitiesUnderMouse()
    if self.mouse_enabled then 
		return self.entitiesundermouse or {}
	end
	return {}
end

function Input:GetWorldEntityUnderMouse()
    if self.mouse_enabled then
		if self.hoverinst and self.hoverinst.Transform then
	        return self.hoverinst 
	    end
	end
end


function Input:EnableDebugToggle(enable)
    self.enabledebugtoggle = enable
end

function Input:IsDebugToggleEnabled()
    return self.enabledebugtoggle
end

function Input:GetHUDEntityUnderMouse()
	if self.mouse_enabled then
		if self.hoverinst and not self.hoverinst.Transform then
	        return self.hoverinst 
	    end
	end
end

function Input:IsMouseDown(button)
    return TheSim:GetMouseButtonState(button)
end

function Input:IsKeyDown(key)
    return TheSim:IsKeyDown(key)
end

function Input:IsTouchDown()
    return self.numtouches > 0
end

function Input:IsOnGesture()
    return self.isOnGesture
end

function Input:IsControlPressed(control)
    if not Profile:IsToggleControllerEnabled() then
        return false
    end
    if self.controlDisabled then
        return false
    end
    return TheSim:GetDigitalControl(control)
end

function Input:GetAnalogControlValue(control)
    if not Profile:IsToggleControllerEnabled() then return 0 end
    if self.controlDisabled then
        return 0
    end
    return TheSim:GetAnalogControl(control)
end

local function GetSortedEntitiesAtScreenPoint()
    local function cmp(a, b)
        if a == nil then return false end 
        if b == nil then return true end 
        return a.prefab ~= "fishinhole" and b.prefab == "fishinhole"
    end

    --print("GetSortedEntitiesAtScreenPoint before")
    local ents = TheSim:GetEntitiesAtScreenPoint(TheSim:GetPosition())
    --dumptable(ents, 1, 1)
    table.insert(ents, nil)
    table.sort(ents, cmp)
    --print("after")
    --dumptable(ents, 1, 1)
    return ents
end

function Input:OnUpdate()
	if PLATFORM == "PS4" then return end

	if self.mouse_enabled then
		self.entitiesundermouse = GetSortedEntitiesAtScreenPoint() --TheSim:GetEntitiesAtScreenPoint(TheSim:GetPosition())
	    
		local inst = self.entitiesundermouse[1]
		if inst ~= self.hoverinst then
	        
			if inst and inst.Transform then
				inst:PushEvent("mouseover")
			end

			if self.hoverinst and self.hoverinst.Transform then
				self.hoverinst:PushEvent("mouseout")
			end
	        
			self.hoverinst = inst
		end
	end
end


function Input:OnAndroidBackButton()
    TheFrontEnd:ManageAndroidBack()
end


function Input:GetLocalizedControl(deviceId, controlId, use_default_mapping)
    
    if nil == use_default_mapping then
        -- default mapping not specified so don't use it
        use_default_mapping = false
    end
    
    local device, numInputs, input1, input2, input3, input4, intParam = TheInputProxy:GetLocalizedControl(deviceId, controlId, use_default_mapping)
    local inputs = {
        [1] = input1,
        [2] = input2,
        [3] = input3,
        [4] = input4,
    }
    local text = ""
    if nil == device then
        text = STRINGS.UI.CONTROLSSCREEN.INPUTS[6][1]
    else
        -- concatenate the inputs
        for idx = 1, numInputs do
            local inputId = inputs[idx]
            text = text .. STRINGS.UI.CONTROLSSCREEN.INPUTS[device][inputs[idx]]
            if idx < numInputs then
                text = text .. " + "
            end
        end
        
        -- process string format params if there are any
        if not (nil == intParam) then
            text = string.format(text, intParam)
        end
    end
    --print ("Input Text:" .. tostring(text))
    return text;
end

function Input:GetControlIsMouseWheel(controlId)
    if self:ControllerAttached() then
        return false
    end
    local localized = self:GetLocalizedControl(0, controlId)
    local stringtable = STRINGS.UI.CONTROLSSCREEN.INPUTS[1]
    return localized == stringtable[1003] or localized == stringtable[1004]
end

function Input:GetTouchYOffset()
    return 0
end

---------------- Globals

TheInput = Input()

function OnPosition(x, y)
    TheInput:UpdatePosition(x,y)
end

function OnControl(control, digitalvalue, analogvalue)
    TheInput:OnControl(control, digitalvalue, analogvalue)
end

function OnMouseButton(button, is_up, x, y)
    TheInput:OnMouseButton(button, is_up, x,y)
end

function OnMouseMove(x, y)
    TheInput:OnMouseMove(x, y)
end

function OnTouchStart(id, x, y)
    TheInput:OnUpdate()
    TheInput:UpdatePosition(x,y)
    TheInput:OnTouchStart(id, x, y)
end

function OnTouchMove(id, x, y)
    TheInput:OnTouchMove(id, x, y)
end

function OnTouchEnd(id)
    TheInput:OnTouchEnd(id)
end

function OnTouchCancel(id)
    TheInput:OnTouchCancel(id)
end

function OnInputKey(key, is_up)
    TheInput:OnRawKey(key, is_up)
end

function OnInputText(text)
    TheInput:OnText(text)
end

function OnGesture(gesture, value, velocity, state, x0, y0, x1, y1)
    if not TheInput:ControllerAttached() then
       TheInput:OnGesture(gesture, value, velocity, state, x0, y0, x1, y1)
    end
end

function OnTapGesture(gesture, x, y)
    if not TheInput:ControllerAttached() then
        TheInput:OnTapGesture(gesture, x, y)
    end
end

function OnControlMapped(deviceId, controlId, inputId, hasChanged)
    TheInput:OnControlMapped(deviceId, controlId, inputId, hasChanged)
end


function OnAndroidBackButton()
    TheInput:OnAndroidBackButton()
end


return Input
