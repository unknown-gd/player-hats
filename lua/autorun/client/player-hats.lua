local isstring, isnumber, istable, isvector, isangle, LocalToWorld, vector_origin, angle_zero, pairs = _G.isstring, _G.isnumber, _G.istable, _G.isvector, _G.isangle, _G.LocalToWorld, _G.vector_origin, _G.angle_zero, _G.pairs
local PrecacheModel = util.PrecacheModel
local Iterator = player.Iterator
local Add = hook.Add
local ENTITY = FindMetaTable("Entity")
local IsValid = ENTITY.IsValid
do
	local GetParent = ENTITY.GetParent
	local defaultColor = Vector(1, 1, 1)
	scripted_ents.Register({
		Type = "anim",
		GetPlayerColor = function(entity)
			if entity.PlayerColorAllowed then
				local parent = GetParent(entity)
				if IsValid(parent) then
					return parent:GetPlayerColor()
				end
			end
			return defaultColor
		end
	}, "prop_player_hat")
end
local GetModel, GetClass, GetBonePosition, GetBoneMatrix, LookupBone, LookupAttachment, GetAttachment, GetNW2Var, GetNWBool = ENTITY.GetModel, ENTITY.GetClass, ENTITY.GetBonePosition, ENTITY.GetBoneMatrix, ENTITY.LookupBone, ENTITY.LookupAttachment, ENTITY.GetAttachment, ENTITY.GetNW2Var, ENTITY.GetNWBool
local Nick, SteamID64, SteamID, HasWeapon, GetActiveWeapon, IsBot, Alive
do
	local _obj_0 = FindMetaTable("Player")
	Nick, SteamID64, SteamID, HasWeapon, GetActiveWeapon, IsBot, Alive = _obj_0.Nick, _obj_0.SteamID64, _obj_0.SteamID, _obj_0.HasWeapon, _obj_0.GetActiveWeapon, _obj_0.IsBot, _obj_0.Alive
end
local GetTranslation, GetAngles
do
	local _obj_0 = FindMetaTable("VMatrix")
	GetTranslation, GetAngles = _obj_0.GetTranslation, _obj_0.GetAngles
end
local CreateClientside = ents.CreateClientside
local find = string.find
local lastIndex = 0
local PlayerHat
do
	local _class_0
	local _base_0 = {
		__tostring = function(self)
			return string.format("Player Hat: %p [%s]", self, self.model)
		end,
		Conditions = {
			["activeweapon"] = function(ply, className)
				local weapon = GetActiveWeapon(ply)
				if IsValid(weapon) then
					return GetClass(weapon) == className
				end
				return false
			end,
			["hasweapon"] = function(ply, className)
				return HasWeapon(ply, className)
			end,
			["playermodel"] = function(ply, modelName)
				return GetModel(ply) == modelName
			end,
			["steamid64"] = function(ply, sid64)
				return not IsBot(ply) and SteamID64(ply) == sid64
			end,
			["nickname"] = function(ply, str)
				return find(Nick(ply), str, 1, false) ~= nil
			end,
			["steamid"] = function(ply, sid)
				return not IsBot(ply) and SteamID(ply) == sid
			end,
			["nw2"] = function(ply, value)
				return GetNW2Var(ply, value)
			end,
			["nw"] = function(ply, value)
				return GetNWBool(ply, value)
			end,
			["playercolor"] = function(ply, color)
				return ply:GetPlayerColor() == color
			end,
			["weaponcolor"] = function(ply, color)
				return ply:GetWeaponColor() == color
			end
		},
		CheckConditions = function(self, entity)
			local funcs = self.Conditions
			local _list_0 = self.conditions
			for _index_0 = 1, #_list_0 do
				local data = _list_0[_index_0]
				local func = funcs[data[1]]
				if func then
					local value = data[2]
					if istable(value) then
						local success = false
						for _index_1 = 1, #value do
							local val = value[_index_1]
							if func(entity, val) then
								success = true
								break
							end
						end
						if not success then
							return false
						end
					elseif not func(entity, value) then
						return false
					end
				end
			end
			return true
		end,
		GetRenderPosition = function(self, entity)
			local attachmentName = self.attachment
			if attachmentName then
				local attachmentID = LookupAttachment(entity, attachmentName)
				if attachmentID and attachmentID > 0 then
					local attachment = GetAttachment(entity, attachmentID)
					return LocalToWorld(self.offset, self.angles, attachment.Pos, attachment.Ang)
				end
			end
			local boneName = self.bone
			if boneName then
				local boneID = LookupBone(entity, boneName)
				if boneID and boneID >= 0 then
					local matrix = GetBoneMatrix(entity, boneID)
					if matrix then
						return LocalToWorld(self.offset, self.angles, GetTranslation(matrix), GetAngles(matrix))
					end
				end
			end
			return LocalToWorld(self.offset, self.angles, GetBonePosition(entity, 0))
		end,
		CreateEntity = function(self, parent)
			if not parent:IsPlayer() then
				return
			end
			local entity = parent[self.full_name]
			if not (entity and IsValid(entity)) then
				entity = CreateClientside("prop_player_hat")
				parent[self.full_name] = entity
				entity:SetPos(parent:WorldSpaceCenter())
				entity:SetParent(parent)
				entity:SetModel(self.model)
				entity:SetNoDraw(true)
				entity:SetupBones()
				entity:Spawn()
				entity.PlayerColorAllowed = self.allow_player_color
				if self.allow_player_color and entity.SetPlayerColor then
					entity:SetPlayerColor(parent:GetPlayerColor())
				end
				entity:SetBodyGroups(self.bodygroups)
				entity:SetMaterial(self.material)
				entity:SetSkin(self.skin)
				entity.DataObject = self
				for index, material in pairs(self.submaterials) do
					entity:SetSubMaterial(index, material)
				end
				entity:DrawShadow(self.allow_shadow)
				entity:SetModelScale(self.scale, 0)
				entity:AddEffects(self.effects)
			end
			return entity
		end,
		RemoveEntity = function(self, parent)
			local entity = parent[self.full_name]
			if entity then
				if IsValid(entity) then
					entity:Remove()
				end
				parent[self.full_name] = nil
			end
		end
	}
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
	_class_0 = setmetatable({
		__init = function(self, data)
			lastIndex = lastIndex + 1
			self.index = lastIndex
			self.full_name = "player-hats::" .. lastIndex
			local model = data.model
			if not isstring(model) then
				print("[PlayerHats] Invalid hat model: " .. tostring(model))
				return
			end
			PrecacheModel(model)
			self.model = model
			local offset = data.offset
			if isvector(offset) then
				self.offset = offset
			else
				self.offset = vector_origin
			end
			local angles = data.angles
			if isangle(angles) then
				self.angles = angles
			else
				self.angles = angle_zero
			end
			local bone = data.bone
			if isstring(bone) then
				self.bone = bone
			else
				self.bone = nil
			end
			local attachment = data.attachment
			if isstring(attachment) then
				self.attachment = attachment
			else
				self.attachment = nil
			end
			local conditions = data.conditions
			if istable(conditions) then
				self.conditions = conditions
			else
				self.conditions = { }
			end
			local effects = data.effects
			if isnumber(effects) then
				self.effects = effects
			else
				self.effects = 0
			end
			local material = data.material
			if isstring(material) then
				self.material = material
			else
				self.material = ""
			end
			local submaterials = data.submaterials
			if istable(submaterials) then
				local tbl = { }
				for index, mat in pairs(submaterials) do
					if isnumber(index) and isstring(mat) then
						tbl[index] = mat
					end
				end
				self.submaterials = tbl
			else
				self.submaterials = { }
			end
			local skin = data.skin
			if isnumber(skin) then
				self.skin = skin
			else
				self.skin = 0
			end
			local bodygroups = data.bodygroups
			if isstring(bodygroups) then
				self.bodygroups = bodygroups
			else
				self.bodygroups = ""
			end
			local scale = data.scale
			if isnumber(scale) then
				self.scale = scale
			else
				self.scale = 1
			end
			self.allow_player_color = data.allow_player_color == true
			self.allow_shadow = data.allow_shadow == true
			local color = data.color
			if color then
				self.red = color.r / 255
				self.green = color.g / 255
				self.blue = color.b / 255
			else
				self.red = 1
				self.green = 1
				self.blue = 1
			end
			local alpha = data.alpha
			if isnumber(alpha) then
				self.alpha = alpha
			else
				self.alpha = 1
			end
			self.initialized = true
			return
		end,
		__base = _base_0,
		__name = "PlayerHat"
	}, {
		__index = _base_0,
		__call = function(cls, ...)
			local _self_0 = setmetatable({ }, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	PlayerHat = _class_0
end
local objects, length = { }, 0
local initializePlayer
initializePlayer = function(ply)
	for index = 1, length do
		local dataObject = objects[index]
		if dataObject:CheckConditions(ply) then
			dataObject:CreateEntity(ply)
		end
	end
end
local deInitializePlayer
deInitializePlayer = function(ply)
	for index = 1, length do
		objects[index]:RemoveEntity(ply)
	end
end
local refreshPlayer
refreshPlayer = function(ply)
	for index = 1, length do
		local dataObject = objects[index]
		if dataObject:CheckConditions(ply) then
			dataObject:CreateEntity(ply)
		else
			dataObject:RemoveEntity(ply)
		end
	end
end
net.Receive("Player Hats - Sync", function()
	for index = 1, length do
		for _, ply in Iterator() do
			objects[index]:RemoveEntity(ply)
		end
		objects[index] = nil
	end
	length = 0
	local _list_0 = net.ReadTable(true)
	for _index_0 = 1, #_list_0 do
		local data = _list_0[_index_0]
		local dataObject = PlayerHat(data)
		if dataObject.initialized then
			length = length + 1
			objects[length] = dataObject
		end
	end
	for _, ply in Iterator() do
		refreshPlayer(ply)
	end
	print("[PlayerHats] Received " .. length .. " hats.")
	return
end)
do
	local DrawModel, SetRenderOrigin, SetRenderAngles = ENTITY.DrawModel, ENTITY.SetRenderOrigin, ENTITY.SetRenderAngles
	local SetColorModulation, SetBlend = render.SetColorModulation, render.SetBlend
	Add("PostPlayerDraw", "PlayerHats - Draw", function(ply, flags)
		for index = 1, length do
			local dataObject = objects[index]
			local entity = ply[dataObject.full_name]
			if entity and IsValid(entity) then
				SetColorModulation(dataObject.red, dataObject.green, dataObject.blue)
				local origin, angles = dataObject:GetRenderPosition(ply)
				SetRenderOrigin(entity, origin)
				SetRenderAngles(entity, angles)
				SetBlend(dataObject.alpha)
				DrawModel(entity, flags)
			end
		end
		SetColorModulation(1, 1, 1)
		SetBlend(1)
		return
	end)
	Add("PostDrawTranslucentRenderables", "PlayerHats - Ragdolls", function(isDepth, isSkybox)
		if isSkybox then
			return
		end
		for _, ply in Iterator() do
			if Alive(ply) then
				goto _continue_0
			end
			local ragdoll = ply:GetRagdollEntity()
			if not (ragdoll and IsValid(ragdoll)) then
				goto _continue_0
			end
			for index = 1, length do
				local dataObject = objects[index]
				local entity = ply[dataObject.full_name]
				if entity and IsValid(entity) then
					SetColorModulation(dataObject.red, dataObject.green, dataObject.blue)
					local origin, angles = dataObject:GetRenderPosition(ragdoll)
					SetRenderOrigin(entity, origin)
					SetRenderAngles(entity, angles)
					SetBlend(dataObject.alpha)
					DrawModel(entity, flags)
				end
			end
			::_continue_0::
		end
		SetColorModulation(1, 1, 1)
		SetBlend(1)
		return
	end)
end
timer.Create("PlayerHats - Update", 0.5, 0, function()
	for _, ply in Iterator() do
		refreshPlayer(ply)
	end
end)
do
	local Simple = timer.Simple
	Add("PlayerSwitchWeapon", "PlayerHats - Weapon Switch", function(ply)
		return Simple(0, function()
			if IsValid(ply) then
				refreshPlayer(ply)
			end
			return
		end)
	end)
end
Add("NotifyShouldTransmit", "Player Hats - PVS", function(entity, shouldtransmit)
	if not entity:IsPlayer() then
		return
	end
	if shouldtransmit then
		initializePlayer(entity)
		return
	end
	deInitializePlayer(entity)
	return
end)
return Add("EntityRemoved", "Player Hats - Entity Removed", function(entity)
	if not entity:IsPlayer() then
		return
	end
	deInitializePlayer(entity)
	return
end)
