local Health = Class(function(self,inst)
self.inst=inst
self.maxhealth=100
self.minhealth=0
self.currenthealth=self.maxhealth
self.invincible=false
self.vulnerabletoheatdamage=true
self.takingfiredamage=false
self.takingfiredamagetime=0
self.fire_damage_scale=1
self.vulnerabletopoisondamage=true
self.poison_damage_scale=1
self.nofadeout=false
self.penalty=0
self.absorb=0
self.destroytime=nil
self.canmurder=true
self.canheal=true
local function CreateLabel(inst,parent)inst.persists=false if not inst.Transform then inst.entity:AddTransform() end inst.Transform:SetPosition( parent.Transform:GetWorldPosition() ) return inst end local function CreateDamageIndicator(parent, amount) local inst=CreateLabel(CreateEntity(), parent) local label=inst.entity:AddLabel() label:SetFont(NUMBERFONT) label:SetFontSize( 40 ) label:SetPos(0, 4, 0) local color if amount<0 then color={ r=0.7, g=0, b=0}else color={ r=0, g=0.7, b=0}end label:SetColour(color.r, color.g, color.b) local format="%.1f" label:SetText(string.format(format, amount)) label:Enable(true) inst:StartThread(function() local label=inst.Label local t=0 local t_max=1 local dt=0.01 local y=4 local dy=0.05 local ddy=0.0 local side=0.0 local dside=0.1 local ddside=0.0 if math.random()>0.5 then dside=-dside end while inst:IsValid() and t<t_max do ddy=-0.1 dy=dy+ddy y=y+dy if y<0 then y=-y dy=-dy*0.9 end ddside=0 dside=dside+ddside side=side+dside local headingtarget=45%180 if headingtarget==0 then label:SetPos(0, y, side) elseif headingtarget==45 then label:SetPos(side, y, -side) elseif headingtarget==90 then label:SetPos(side, y, 0) elseif headingtarget==135 then label:SetPos(side, y, side) end t=t+dt label:SetFontSize( 40*math.sqrt(1-t/t_max)) Sleep(dt) end inst:Remove() end) return inst end inst:ListenForEvent("healthdelta", function(inst, data) if inst.components.health then local amount=(data.newpercent-data.oldpercent)*inst.components.health.maxhealth if math.abs(amount)>0.1 then if not (false and amount>0) then CreateDamageIndicator(inst, amount) end end end end)
end)
function Health:SetInvincible(val)self.invincible=val
self.inst:PushEvent("invincibletoggle",{invincible=val})end
function Health:OnSave()return 
{minhealth=self.minhealth,health=self.currenthealth,penalty=self.penalty>0 and self.penalty or nil}end


function Health:RecalculatePenalty()
if SaveGameIndex:CanUseExternalResurector()==false then
self.penalty=0
for k,v in pairs(Ents)do
if v.components.resurrector and v.components.resurrector.penalty then
self.penalty=self.penalty+v.components.resurrector.penalty
end
end
else
self.penalty=SaveGameIndex:GetResurrectorPenalty()end
self:DoDelta(0,nil,"resurrection_penalty")end
function Health:OnLoad(data)self.penalty=data.penalty or self.penalty
if data.minhealth then
self:SetMinHealth(data.minhealth)end
if data.health then
self:SetVal(data.health,"file_load")self:DoDelta(0)elseif data.percent then
self:SetPercent(data.percent,"file_load")self:DoDelta(0)
end
end
local FIRE_TIMEOUT=.5
local FIRE_TIMESTART=1.0
function Health:DoFireDamage(amount,doer,instant)
if not self.invincible and self.fire_damage_scale>0 then
if not self.takingfiredamage then
self.takingfiredamage=true
self.takingfiredamagestarttime=GetTime()self.inst:StartUpdatingComponent(self)self.inst:PushEvent("startfiredamage")ProfileStatsAdd("onfire")end
local time=GetTime()self.lastfiredamagetime=time
if(instant or time-self.takingfiredamagestarttime>FIRE_TIMESTART)and amount>0 then
self:DoDelta(-amount*self.fire_damage_scale,false,"fire")self.inst:PushEvent("firedamage")end
end
end
function Health:DoPoisonDamage(amount,doer)
if not self.invincible and self.vulnerabletopoisondamage and self.poison_damage_scale>0 then
if amount>0 then
self:DoDelta(-amount*self.poison_damage_scale,false,"poison")
end
end
end
function Health:OnUpdate(dt)local time=GetTime()local shouldstop=false
if self.lastfiredamagetime and (time-self.lastfiredamagetime>FIRE_TIMEOUT)then
self.takingfiredamage=false
shouldstop=true
self.inst:PushEvent("stopfiredamage")ProfileStatsAdd("fireout")end
if shouldstop then
self.inst:StopUpdatingComponent(self)end
end
function Health:DoRegen()if not self:IsDead()then
self:DoDelta(self.regen.amount,true,"regen")else
end
end
function Health:StartRegen(amount,period,interruptcurrentregen)
if interruptcurrentregen==nil or interruptcurrentregen==true then
self:StopRegen()end
if not self.regen then
self.regen={}
end
self.regen.amount=amount
self.regen.period=period
if not self.regen.task then
self.regen.task = self.inst:DoPeriodicTask(self.regen.period,function()self:DoRegen()end)end
end
function Health:SetAbsorptionAmount(amount)self.absorb=amount
end
function Health:StopRegen()if self.regen then
if self.regen.task then
self.regen.task:Cancel()
self.regen.task = nil
end
self.regen=nil
end
end
function Health:GetPenaltyPercent()
return (self.penalty*TUNING.EFFIGY_HEALTH_PENALTY)/self.maxhealth
end
function Health:GetPercent()return self.currenthealth/self.maxhealth
end
function Health:IsInvincible()return self.invincible
end

function Health:GetDebugString()
local s=string.format("%2.2f / %2.2f - (%2.2f)",self.currenthealth,self.maxhealth-self.penalty*TUNING.EFFIGY_HEALTH_PENALTY,self.minhealth)
if self.regen then
s = s .. string.format(", regen %.2f every %.2fs",self.regen.amount,self.regen.period)
end
if self.invincible then
s = s .. ", invincible"
end
return s
end
function Health:SetMaxHealth(amount)
self.maxhealth=amount
self.currenthealth=amount
end
function Health:SetMinHealth(amount)
self.minhealth=amount
end
function Health:IsHurt()
return self.currenthealth<(self.maxhealth-self.penalty*TUNING.EFFIGY_HEALTH_PENALTY)
end
function Health:GetMaxHealth()
return (self.maxhealth-self.penalty*TUNING.EFFIGY_HEALTH_PENALTY)
end
function Health:Kill(cause)
if self.currenthealth>0 then
self:SetVal(0,cause)end
end
function Health:IsDead()return self.currenthealth<=0
end
local function destroy(inst)local time_to_erode=1
local tick_time=TheSim:GetTickTime()if inst.DynamicShadow then
inst.DynamicShadow:Enable(false)end
inst:StartThread(function()
local ticks=0
while ticks*tick_time<time_to_erode do
local erode_amount=ticks*tick_time / time_to_erode
inst.AnimState:SetErosionParams(erode_amount,0.1,1.0)
ticks=ticks+1
Yield()
end
inst:Remove()
end)
end
function Health:SetPercent(percent,cause)   self:SetVal(self.maxhealth*percent,cause)self:DoDelta(0)end
function Health:OnProgress()self.penalty=0
end
function Health:SetVal(val,cause)local old_percent=self:GetPercent()self.currenthealth=val
if self.currenthealth>self:GetMaxHealth()then
self.currenthealth=self:GetMaxHealth()end
if self.minhealth and self.currenthealth<self.minhealth then
self.currenthealth=self.minhealth
self.inst:PushEvent("minhealth",{cause=cause})end
if self.currenthealth<0 then
self.currenthealth=0
end
local new_percent=self:GetPercent()if old_percent > 0 and new_percent<= 0 or self:GetMaxHealth()<= 0 then
self.inst:PushEvent("death",{cause=cause})GetWorld():PushEvent("entity_death",{inst=self.inst,cause=cause})if not self.nofadeout then
self.inst:AddTag("NOCLICK")self.inst.persists=false
self.inst:DoTaskInTime(self.destroytime or 2,destroy)end
end
end
function Health:DoDelta(amount,overtime,cause,ignore_invincible)if self.redirect then
self.redirect(self.inst,amount,overtime,cause)return
end
if not ignore_invincible and(self.invincible or self.inst.is_teleporting==true)then
return
end
if amount<0 then
amount=amount-(amount*self.absorb)end
local old_percent=self:GetPercent()self:SetVal(self.currenthealth+amount,cause)local new_percent=self:GetPercent()
self.inst:PushEvent("healthdelta",{oldpercent=old_percent,newpercent=self:GetPercent(),overtime=overtime,cause=cause})
if METRICS_ENABLED and self.inst==GetPlayer()and cause and cause ~= "debug_key"then
if amount > 0 then
ProfileStatsAdd("healby_" .. cause,math.floor(amount))FightStat_Heal(math.floor(amount))end
end
if self.ondelta then
self.ondelta(self.inst,old_percent,self:GetPercent())end
end
function Health:Respawn(health)self:DoDelta(health or 10,false,"resurrector",true)self.inst:PushEvent("respawn",{})end
function Health:CollectInventoryActions(doer,actions)if self.canmurder then
table.insert(actions,ACTIONS.MURDER)end
end

return Health
