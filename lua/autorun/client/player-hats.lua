local _G = _G

local isstring, isnumber, istable, isvector, isangle = _G.isstring, _G.isnumber, _G.istable, _G.isvector, _G.isangle
local player_Iterator = _G.player.Iterator
local hook_Add = _G.hook.Add

-- ULib support ( I really don't like this )
if ( CLIENT or SERVER ) and _G.file.Exists( "ulib/shared/hook.lua", "LUA" ) then
	_G.include( "ulib/shared/hook.lua" )
end

--- Srlion's Hook Library ( https://github.com/Srlion/Hook-Library )
---@diagnostic disable-next-line: undefined-field
local PRE_HOOK = _G.PRE_HOOK or -2

local PLAYER = _G.FindMetaTable( "Player" ) ---@cast PLAYER Player
local ENTITY = _G.FindMetaTable( "Entity" ) ---@cast ENTITY Entity
local ENTITY_IsValid = ENTITY.IsValid

do

	local ENTITY_GetParent = ENTITY.GetParent
	local default_color = _G.Vector( 1, 1, 1 )

	_G.scripted_ents.Register( {
		Type = "anim",
		GetPlayerColor = function( entity )
			if entity.PlayerColorAllowed then
				local parent = ENTITY_GetParent( entity ) ---@cast parent Player
				if ENTITY_IsValid( parent ) then
					return parent:GetPlayerColor()
				end
			end

			return default_color
		end
	}, "prop_player_hat" )

end

local objects, length = {}, 0

local function initializePlayer( ply )
	for index = 1, length, 1 do
		local object = objects[ index ]
		if object:CheckConditions( ply ) then
			object:CreateEntity( ply )
		end
	end
end

local function deInitializePlayer( ply )
	for index = 1, length, 1 do
		objects[ index ]:RemoveEntity( ply )
	end
end

local function refreshPlayer( ply )
	for index = 1, length, 1 do
		local object = objects[ index ]
		if object:CheckConditions( ply ) then
			object:CreateEntity( ply )
		else
			object:RemoveEntity( ply )
		end
	end
end

do

	local pairs, ipairs = _G.pairs, _G.ipairs

	local metatable = {
		__tostring = function( self )
			return _G.string.format( "Player Hat: %p [%s]", self, self.model )
		end,
		RemoveEntity = function( self, parent )
			local entity = parent[ self.full_name ]
			if entity then
				if ENTITY_IsValid( entity ) then
					entity:Remove()
				end

				parent[ self.full_name ] = nil
			end
		end
	}

	do

		local ents_CreateClientside = ents.CreateClientside

		function metatable:CreateEntity( parent )
			if not parent:IsPlayer() then return end

			local entity = parent[ self.full_name ]
			if not ( entity and ENTITY_IsValid( entity ) ) then
				entity = ents_CreateClientside( "prop_player_hat" )
				parent[ self.full_name ] = entity

				entity:SetPos( parent:WorldSpaceCenter() )
				entity:SetParent( parent )
				entity:SetModel( self.model )
				entity:SetNoDraw( true )
				entity:SetupBones()
				entity:Spawn()

				---@diagnostic disable-next-line: inject-field
				entity.PlayerColorAllowed = self.allow_player_color

				---@diagnostic disable-next-line: undefined-field
				if self.allow_player_color and entity.SetPlayerColor then
					---@diagnostic disable-next-line: undefined-field
					entity:SetPlayerColor( parent:GetPlayerColor() )
				end

				entity:SetBodyGroups( self.bodygroups )
				entity:SetMaterial( self.material )
				entity:SetSkin( self.skin )

				for index, material in pairs( self.materials ) do
					entity:SetSubMaterial( index, material )
				end

				entity:DrawShadow( self.allow_shadow )
				entity:SetModelScale( self.scale, 0 )
				entity:AddEffects( self.effects )
			end

			return entity
		end

	end

	do

		local ENTITY_LookupAttachment, ENTITY_GetAttachment, ENTITY_GetBoneMatrix, ENTITY_GetBonePosition, ENTITY_LookupBone = ENTITY.LookupAttachment, ENTITY.GetAttachment, ENTITY.GetBoneMatrix, ENTITY.GetBonePosition, ENTITY.LookupBone
		local LocalToWorld = _G.LocalToWorld

		local VMatrix = _G.FindMetaTable( "VMatrix" )
		local VMatrix_GetTranslation, VMatrix_GetAngles = VMatrix.GetTranslation, VMatrix.GetAngles

		function metatable:GetRenderPosition( entity )
			local attachment_name = self.attachment
			if attachment_name then
				local attachment_index = ENTITY_LookupAttachment( entity, attachment_name )
				if attachment_index and attachment_index > 0 then
					local attachment = ENTITY_GetAttachment( entity, attachment_index )
					return LocalToWorld( self.offset, self.angles, attachment.Pos, attachment.Ang )
				end
			end

			local bone_name = self.bone
			if bone_name then
				local bone_index = ENTITY_LookupBone( entity, bone_name )
				if bone_index and bone_index >= 0 then
					local matrix = ENTITY_GetBoneMatrix( entity, bone_index )
					if matrix then
						return LocalToWorld( self.offset, self.angles, VMatrix_GetTranslation( matrix ), VMatrix_GetAngles( matrix ) )
					end
				end
			end

			return LocalToWorld( self.offset, self.angles, ENTITY_GetBonePosition ( entity, 0 ) )
		end

	end

	do

		local PLAYER_Nick, PLAYER_SteamID64, PLAYER_SteamID, PLAYER_HasWeapon, PLAYER_GetActiveWeapon, PLAYER_IsBot = PLAYER.Nick, PLAYER.SteamID64, PLAYER.SteamID, PLAYER.HasWeapon, PLAYER.GetActiveWeapon, PLAYER.IsBot
		local ENTITY_GetClass, ENTITY_GetModel, ENTITY_GetNW2Var, ENTITY_GetNWBool = ENTITY.GetClass, ENTITY.GetModel, ENTITY.GetNW2Var, ENTITY.GetNWBool
		local string_find = _G.string.find

		local conditions = {
			activeweapon = function( ply, className )
				local weapon = PLAYER_GetActiveWeapon( ply )
				return ENTITY_IsValid( weapon ) and ENTITY_GetClass( weapon ) == className
			end,
			hasweapon = function( ply, className )
				return PLAYER_HasWeapon( ply, className )
			end,
			playermodel = function( ply, modelName )
				return ENTITY_GetModel( ply ) == modelName
			end,
			steamid64 = function( ply, sid64 )
				return not PLAYER_IsBot( ply ) and PLAYER_SteamID64( ply ) == sid64
			end,
			nickname = function( ply, str )
				return string_find( PLAYER_Nick( ply ), str, 1, false ) ~= nil
			end,
			steamid = function( ply, sid )
				return not PLAYER_IsBot( ply ) and PLAYER_SteamID( ply ) == sid
			end,
			nw2 = function( ply, value )
				return ENTITY_GetNW2Var( ply, value )
			end,
			nw = function( ply, value )
				return ENTITY_GetNWBool( ply, value )
			end,
			playercolor = function( ply, color )
				return ply:GetPlayerColor( ) == color
			end,
			weaponcolor = function( ply, color )
				return ply:GetWeaponColor( ) == color
			end
		}

		function metatable:CheckConditions( entity )
			for _, data in ipairs( self.conditions ) do
				local func = conditions[ data[ 1 ] ]
				if func then
					local value = data[ 2 ]
					if istable( value ) then
						local success = false
						for _, variable in ipairs( value ) do
							if func( entity, variable ) then
								success = true
								break
							end
						end

						if not success then
							return false
						end
					elseif not func( entity, value ) then
						return false
					end
				end
			end

			return true
		end

	end

	metatable.__index = metatable

	local util_PrecacheModel = util.PrecacheModel
	local vector_origin = _G.vector_origin
	local angle_zero = _G.angle_zero

	local last_index = 0

	local function new_hat( data )
		last_index = last_index + 1

		local object = {
			index = last_index,
			full_name = "player-hats::" .. last_index
		}

		setmetatable( object, metatable )

		local model = data.model
		if not isstring( model ) then
			print( "[PlayerHats] Invalid hat model: " .. tostring( model ) )
			return
		end

		util_PrecacheModel( model )
		object.model = model

		local offset = data.offset
		object.offset = isvector( offset ) and offset or vector_origin

		local angles = data.angles
		object.angles = isangle( angles ) and angles or angle_zero

		local bone = data.bone
		if isstring( bone ) then
			object.bone = bone
		else
			object.bone = nil
		end

		local attachment = data.attachment
		if isstring( attachment ) then
			object.attachment = attachment
		else
			object.attachment = nil
		end

		local conditions = data.conditions
		if istable( conditions ) then
			object.conditions = conditions
		else
			object.conditions = {}
		end

		local effects = data.effects
		if isnumber( effects ) then
			object.effects = effects
		else
			object.effects = 0
		end

		local material = data.material
		if isstring( material ) then
			object.material = material
		else
			object.material = ""
		end

		local materials = data.materials
		if istable( materials ) then
			local result = {}
			for i = 1, #materials, 1 do
				local path = materials[ i ]
				if isstring( path ) then
					result[ i ] = path
				end
			end

			object.materials = result
		else
			object.materials = {}
		end

		local skin = data.skin
		if isnumber( skin ) then
			object.skin = skin
		else
			object.skin = 0
		end

		local bodygroups = data.bodygroups
		if isstring( bodygroups ) then
			object.bodygroups = bodygroups
		else
			object.bodygroups = ""
		end

		local scale = data.scale
		if isnumber( scale ) then
			object.scale = scale
		else
			object.scale = 1
		end

		object.allow_player_color = data.allow_player_color == true
		object.allow_shadow = data.allow_shadow == true

		local color = data.color
		if color then
			object.red = color.r / 255
			object.green = color.g / 255
			object.blue = color.b / 255
		else
			object.red = 1
			object.green = 1
			object.blue = 1
		end

		local alpha = data.alpha
		if isnumber( alpha ) then
			object.alpha = alpha
		else
			object.alpha = 1
		end

		return object
	end

	net.Receive( "Player Hats - Sync", function()
		for index = 1, length, 1 do
			for _, ply in player_Iterator() do
				objects[ index ]:RemoveEntity( ply )
			end

			objects[ index ] = nil
		end

		length = 0

		for _, data in ipairs( net.ReadTable( true ) ) do
			local object = new_hat( data )
			if object ~= nil then
				length = length + 1
				objects[ length ] = object
			end
		end

		for _, ply in player_Iterator() do
			refreshPlayer( ply )
		end

		print( "[PlayerHats] Received " .. length .. " hats." )
	end )

end

do

	local ENTITY_DrawModel, ENTITY_SetRenderOrigin, ENTITY_SetRenderAngles = ENTITY.DrawModel, ENTITY.SetRenderOrigin, ENTITY.SetRenderAngles
	local render_SetColorModulation, render_SetBlend = render.SetColorModulation, render.SetBlend

	hook_Add( "PostPlayerDraw", "PlayerHats - Draw", function( ply, flags )
		for index = 1, length do
			local object = objects[ index ]

			local entity = ply[ object.full_name ]
			if entity and ENTITY_IsValid( entity ) then
				render_SetColorModulation( object.red, object.green, object.blue )

				local origin, angles = object:GetRenderPosition( ply )
				ENTITY_SetRenderOrigin( entity, origin )
				ENTITY_SetRenderAngles( entity, angles )
				render_SetBlend( object.alpha )
				ENTITY_DrawModel( entity, flags )
			end
		end

		render_SetColorModulation( 1, 1, 1 )
		render_SetBlend( 1 )

		---@diagnostic disable-next-line: redundant-parameter
	end, PRE_HOOK )

	local PLAYER_Alive = PLAYER.Alive

	hook_Add( "PostDrawTranslucentRenderables", "PlayerHats - Ragdolls", function( _, isSkybox )
		if isSkybox then return end

		for _, ply in player_Iterator() do
			if not PLAYER_Alive( ply ) then
				local ragdoll = ply:GetRagdollEntity()
				if ragdoll and ENTITY_IsValid( ragdoll ) then
					for index = 1, length do
						local object = objects[ index ]

						local entity = ply[ object.full_name ]
						if entity and ENTITY_IsValid( entity ) then
							render_SetColorModulation( object.red, object.green, object.blue )

							local origin, angles = object:GetRenderPosition( ragdoll )
							ENTITY_SetRenderOrigin( entity, origin )
							ENTITY_SetRenderAngles( entity, angles )
							render_SetBlend( object.alpha )

							ENTITY_DrawModel( entity, 8 )
						end
					end
				end
			end
		end

		render_SetColorModulation( 1, 1, 1 )
		render_SetBlend( 1 )

		---@diagnostic disable-next-line: redundant-parameter
	end, PRE_HOOK )

end

timer.Create( "PlayerHats - Update", 0.5, 0, function()
	for _, ply in player_Iterator() do
		refreshPlayer( ply )
	end
end )

do

	local timer_Simple = timer.Simple

	hook_Add( "PlayerSwitchWeapon", "PlayerHats - Weapon Switch", function( ply )
		timer_Simple( 0, function()
			if ENTITY_IsValid( ply ) then
				refreshPlayer( ply )
			end
		end )

		---@diagnostic disable-next-line: redundant-parameter
	end, PRE_HOOK )

end

hook_Add( "NotifyShouldTransmit", "Player Hats - PVS", function( entity, shouldtransmit )
	if entity:IsPlayer() then
		if shouldtransmit then
			initializePlayer( entity )
		else
			deInitializePlayer( entity )
		end
	end

	---@diagnostic disable-next-line: redundant-parameter
end, PRE_HOOK )

hook_Add( "EntityRemoved", "Player Hats - Entity Removed", function( entity )
	if entity:IsPlayer() then
		deInitializePlayer( entity )
	end

	---@diagnostic disable-next-line: redundant-parameter
end, PRE_HOOK )
