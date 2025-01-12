local LootDropper = Class(function(self, inst)
	self.inst = inst
	self.numrandomloot = nil
	self.randomloot = nil
	self.chancerandomloot = nil
	self.totalrandomweight = nil
	self.chanceloot = nil
	self.ifnotchanceloot = nil
	self.droppingchanceloot = false
	self.loot = nil
	self.chanceloottable = nil
	self.trappable = true
	self.speed = nil
end)

LootTables = {}
function SetSharedLootTable(name, table)
	LootTables[name] = table
end

function LootDropper:SetChanceLootTable(name)
	self.chanceloottable = name
end

function LootDropper:SetLoot( loots )
	self.loot = loots
	self.chanceloot = nil
	self.randomloot = nil
	self.numrandomloot = nil
end

function LootDropper:AddLoot(prefab)
	if not self.loot then
		self.loot = {}
	end
	table.insert(self.loot, prefab)
end

function LootDropper:AddRandomLoot( prefab, weight)
	if not self.randomloot then
		self.randomloot = {}
		self.totalrandomweight = 0
	end
	
	table.insert(self.randomloot, {prefab=prefab,weight=weight} )
	self.totalrandomweight = self.totalrandomweight + weight
end

function LootDropper:AddChanceLoot( prefab, chance)
	if not self.chanceloot then
		self.chanceloot = {}
	end
	table.insert(self.chanceloot, {prefab=prefab,chance=chance} )
end

function LootDropper:AddIfNotChanceLoot(prefab)
	if not self.ifnotchanceloot then
		self.ifnotchanceloot = {}
	end
	table.insert(self.ifnotchanceloot, {prefab=prefab})
end

function LootDropper:PickRandomLoot()
	if self.totalrandomweight and self.totalrandomweight > 0 and self.randomloot then
		local rnd = math.random()*self.totalrandomweight
		for k,v in pairs(self.randomloot) do
			rnd = rnd - v.weight
			if rnd <= 0 then
				return v.prefab
			end
		end
	end
end

function LootDropper:GenerateLoot()
	local loots = {}
	
	if self.numrandomloot and math.random() <= (self.chancerandomloot or 1) then
		for k = 1, self.numrandomloot do
			local loot = self:PickRandomLoot()
			if loot then
				table.insert(loots, loot)
			end
		end
	end
	
	if self.chanceloot then
		for k,v in pairs(self.chanceloot) do
			if math.random() < v.chance then
				table.insert(loots, v.prefab)
				self.droppingchanceloot = true
			end
		end
	end

	if self.chanceloottable then
		local loot_table = LootTables[self.chanceloottable]
		if loot_table then
			for i, entry in ipairs(loot_table) do
				local prefab = entry[1]
				local chance = entry[2]
				if math.random() <= chance then
					table.insert(loots, prefab)
					self.droppingchanceloot = true
				end
			end
		end
	end

	if not self.droppingchanceloot and self.ifnotchanceloot then
		self.inst:PushEvent("ifnotchanceloot")
		for k,v in pairs(self.ifnotchanceloot) do
			table.insert(loots, v.prefab)
		end
	end


	
	if self.loot then
		for k,v in ipairs(self.loot) do
			table.insert(loots, v)
		end
	end
	
	local recipe = GetRecipe(self.inst.prefab)

	if recipe then
		local percent = 1

		if self.lootpercentoverride then
			percent = self.lootpercentoverride(self.inst)
		elseif self.inst.components.finiteuses then
			percent = self.inst.components.finiteuses:GetPercent()
		end

		for k,v in ipairs(recipe.ingredients) do
			local amt = math.ceil( (v.amount * TUNING.HAMMER_LOOT_PERCENT) * percent)
			if self.inst:HasTag("burnt") then
				amt = math.ceil( (v.amount * TUNING.BURNT_HAMMER_LOOT_PERCENT) * percent)
			end
			for n = 1, amt do
				table.insert(loots, v.type)
			end
		end

		if self.inst:HasTag("burnt") and math.random() < .4 then
			table.insert(loots, "charcoal") -- Add charcoal to loot for burnt structures
		end
	end
	
	return loots
end

function LootDropper:DropLootPrefab(loot, pt)
	if loot then
		if not pt then
			pt = Point(self.inst.Transform:GetWorldPosition())
		end

		if self.inst.components.poisonable and self.inst.components.poisonable:IsPoisoned() and loot.components.perishable then
			loot.components.perishable:ReducePercent(TUNING.POISON_PERISH_PENALTY)
		end
		
		loot.Transform:SetPosition(pt.x,pt.y,pt.z)

		self.inst:ApplyInheritedMoisture(loot)
		
		if loot.Physics and not self.nojump then
		
			local angle = math.random()*2*PI
			local speed = self.speed or 1
			speed = speed * math.random()
			loot.Physics:SetVel(speed*math.cos(angle), GetRandomWithVariance(8, 4), speed*math.sin(angle))

			if loot and loot.Physics and self.inst and self.inst.Physics then
				pt = pt + Vector3(math.cos(angle), 0, math.sin(angle))*((loot.Physics:GetRadius() or 1) + (self.inst.Physics:GetRadius() or 1))
				loot.Transform:SetPosition(pt.x,pt.y,pt.z)
			end
		end
		if loot.components.inventoryitem then 
			loot.components.inventoryitem:OnLootDropped()
		end 
		
		return loot
	end
end

function LootDropper:SpawnLootPrefab(lootprefab, pt)
	if lootprefab then
		local loot = SpawnPrefab(lootprefab)
		return self:DropLootPrefab(loot, pt)
	end
end

function LootDropper:CheckBurnable(prefabs)
	-- check burnable
	if not self.inst.components.fueled and self.inst.components.burnable and self.inst.components.burnable:IsBurning() then
		for k,v in pairs(prefabs) do
			local cookedAfter = v.."_cooked"
			local cookedBefore = "cooked"..v
			if PrefabExists(cookedAfter) then
				prefabs[k] = cookedAfter
			elseif PrefabExists(cookedBefore) then
				prefabs[k] = cookedBefore
			else
				prefabs[k] = "ash"
			end
		end
	end	
end

function LootDropper:DropLoot(pt, loots)
	local prefabs = loots
	if prefabs == nil then
		prefabs = self:GenerateLoot()
	end
	self:CheckBurnable(prefabs)
	for k,v in pairs(prefabs) do
		self:SpawnLootPrefab(v, pt)
	end
end

function LootDropper:ExplodeLoot(pt, speed, loots)
	local prefabs = loots
	if prefabs == nil then
		prefabs = self:GenerateLoot()
	end
	self:CheckBurnable(prefabs)
	self.speed = speed or 1
	for k,v in pairs(prefabs) do
		local newprefab = self:SpawnLootPrefab(v, pt)
		local vx, vy, vz = newprefab.Physics:GetVelocity()
		newprefab.Physics:SetVel(vx, 35, vz)
	end
	self.speed = 1
end

return LootDropper
