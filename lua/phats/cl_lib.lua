local string_lower = string.lower
local IsValid = IsValid
local ipairs = ipairs
local Vector = Vector
local Model = Model
local table = table

local vector_zero = Vector()
local angle_zero = Angle()

do

    local meta = {}
    meta.__index = meta

    function meta:__tostring()
        return 'pHat [' .. self.Name .. '][' .. self:GetModel() .. ']'
    end

    -- Model
    function meta:GetModel()
        return self.Model
    end

    function meta:SetModel( mdl )
        self.Model = Model( mdl )
    end

    -- Position
    function meta:GetPos()
        local pos = self.Position
        if (pos) then
            return pos
        end

        return vector_zero
    end

    function meta:SetPos( pos )
        self.Position = pos
    end

    -- Angles
    function meta:GetAngles()
        local ang = self.Angle
        if (ang) then
            return ang
        end

        return angle_zero
    end

    function meta:SetAngles( ang )
        self.Angle = ang
    end

    -- Alpha
    function meta:SetAlpha( alpha )
        self.Alpha = alpha
    end

    function meta:GetAlpha()
        return self.Alpha or 1
    end

    -- Use player color
    function meta:GetUsePlayerColor()
        return self.UsePlayerColor
    end

    function meta:SetUsePlayerColor( bool )
        self.UsePlayerColor = bool == true
    end

    -- Color
    function meta:GetColor()
        return self.Color[1], self.Color[2], self.Color[3]
    end

    function meta:SetColor( color )
        self:SetAlpha( color['a'] / 255 )
        self:SetUsePlayerColor( false )
        self.Color = color:ToVector()
        return self
    end

    -- Size
    function meta:SetSize( size )
        self.Size = size
        return self
    end

    function meta:GetSize()
        return self.Size or 1
    end

    -- Attachment
    function meta:SetAttachment( attachmentName )
        self.AttachmentName = attachmentName
        return self
    end

    function meta:GetAttachment()
        return self.AttachmentName
    end

    -- Bone
    function meta:SetBoneName( boneName )
        self.BoneName = boneName
        return self
    end

    function meta:GetBoneName()
        return self.BoneName
    end

    -- Filters
    function meta:AddSteamID( sid )
        table.insert( self.SteamIDs, sid )
        return self
    end

    do
        local util_SteamIDFrom64 = util.SteamIDFrom64
        function meta:AddSteamID64( sid64 )
            table.insert( self.SteamIDs, util_SteamIDFrom64( sid64 ) )
            return self
        end
    end

    function meta:AddModel( mdl )
        table.insert( self.Models, string_lower( mdl ) )
        return self
    end

    function meta:AddHasWeapon( class )
        table.insert( self.Weapons, class )
        return self
    end

    function meta:AddActiveWeapon( class )
        table.insert( self.ActiveWeapons, class )
        return self
    end

    function meta:CanWear( ply )
        if ply:Alive() then
            local hasSteamID = false
            if ply:IsBot() or table.IsEmpty( self.SteamIDs ) then
                hasSteamID = true
            else
                local steamID = ply:SteamID()
                for _, sid in ipairs( self.SteamIDs ) do
                    if (sid == steamID) then
                        hasSteamID = true
                        break
                    end
                end
            end

            local hasModel = false
            if table.IsEmpty( self.Models ) then
                hasModel = true
            else
                local model = ply:GetModel()
                for _, mdl in ipairs( self.Models ) do
                    if (mdl == model) then
                        hasModel = true
                        break
                    end
                end
            end

            local activeWeapon, activeWeaponClass = ply:GetActiveWeapon(), nil
            if IsValid( activeWeapon ) then
                activeWeaponClass = activeWeapon:GetClass()
            end

            local hasWeapon = false
            if table.IsEmpty( self.Weapons ) then
                hasWeapon = true
            else
                for _, class in ipairs( self.Weapons ) do
                    if ply:HasWeapon( class ) then
                        if (class == activeWeaponClass) then continue end
                        hasWeapon = true
                        break
                    end
                end
            end

            local hasActiveWeapon = false
            if (activeWeaponClass == nil) or table.IsEmpty( self.ActiveWeapons ) then
                hasActiveWeapon = true
            else
                for _, class in ipairs( self.ActiveWeapons ) do
                    if (class == activeWeaponClass) then
                        hasActiveWeapon = true
                        break
                    end
                end
            end

            return hasSteamID and hasModel and hasWeapon and hasActiveWeapon
        end

        return false
    end

    do
        local LocalToWorld = LocalToWorld
        function meta:CalcPosition( ply )
            local attachmentName = self:GetAttachment()
            if (attachmentName) then
                local attachmentID = ply:LookupAttachment( attachmentName )
                if (attachmentID > 0) then
                    local data = ply:GetAttachment( attachmentID )
                    if (data) then
                        return LocalToWorld( self:GetPos(), self:GetAngles(), data.Pos, data.Ang )
                    end
                end
            end

            local boneName = self:GetBoneName()
            if (boneName) then
                local boneIndex = ply:LookupBone( boneName )
                if (boneIndex >= 0) then
                    local bonePos, boneAng = ply:GetBonePosition( boneIndex )
                    if (bonePos == ply:GetPos()) then
                        local matrix = ply:GetBoneMatrix( boneIndex )
                        if (matrix) then
                            bonePos = matrix:GetTranslation()
                        end
                    end

                    return LocalToWorld( self:GetPos(), self:GetAngles(), bonePos, boneAng )
                end
            end

            return LocalToWorld( self:GetPos(), self:GetAngles(), ply:EyePos(), ply:EyeAngles() )
        end
    end

    -- Entity
    do
        local ents_CreateClientside = ents.CreateClientside
        function meta:GetEntity()
            local old = self.Entity
            if IsValid( old ) then
                return old
            end

            local new = ents_CreateClientside( 'prop_phat' )
            self.Entity = new

            new:SetModel( self:GetModel() )
            new:DrawShadow( false )
            new:SetNoDraw( true )
            new:SetupBones()
            new:Spawn()

            return new
        end
    end

    -- Remove
    function meta:Remove()
        local ent = self:GetEntity()
        if IsValid( ent ) then
            ent:Remove()
        end
    end

    -- Think
    do
        local player_GetAll = player.GetAll
        function meta:Think()
            for __, ply in ipairs( player_GetAll() ) do
                self.Players[ ply ] = self:CanWear( ply )
            end

            local ent = self:GetEntity()
            if IsValid( ent ) then
                ent:SetModelScale( self:GetSize(), 0 )
                ent:SetModel( self:GetModel() )
            end
        end
    end

    -- Draw
    do

        local render = render

        function meta:Draw( ply, flags )
            local ent = self.Entity
            if IsValid( ent ) then
                local r, g, b = render.GetColorModulation()
                    if self:GetUsePlayerColor() then
                        local color = ply:GetPlayerColor()
                        render.SetColorModulation( color[1], color[2], color[3] )
                    else
                        render.SetColorModulation( self:GetColor() )
                    end

                    local alpha = render.GetBlend()
                    render.SetBlend( self:GetAlpha() )

                    local pos, ang = self:CalcPosition( ply )
                    ent:SetRenderOrigin( pos )
                    ent:SetRenderAngles( ang )
                    ent:DrawModel( flags )

                    render.SetBlend( alpha )
                render.SetColorModulation( r, g, b )
            end
        end

    end

    do

        module( 'phats', package.seeall )
        hats = hats or {}

        function UnRegister( name )
            for num, hat in ipairs( hats ) do
                if (hat.Name == name) then
                    table.remove( hats, num )
                    hat:Remove()
                    break
                end
            end
        end

        do
            local setmetatable = setmetatable
            function Register( name, model )
                UnRegister( name )

                local new = {
                    ['AttachmentName'] = 'eyes',
                    ['UsePlayerColor'] = false,
                    ['ActiveWeapons'] = {},
                    ['SteamIDs'] = {},
                    ['Weapons'] = {},
                    ['Players'] = {},
                    ['Models'] = {}
                }

                new.Color = Vector( 1, 1, 1 )
                new.Model = Model( model )
                new.Name = name

                local hat = setmetatable( new, meta )
                table.insert( hats, hat )
                return hat
            end
        end

        hook.Add('PostPlayerDraw', 'pHats - Render', function( ply, flags )
            for _, hat in ipairs( hats ) do
                if hat.Players[ ply ] then
                    hat:Draw( ply, flags )
                end
            end
        end)

        hook.Add('Think', 'pHats - Think', function()
            for _, hat in ipairs( hats ) do
                hat:Think()
            end
        end)

    end

end

hook.Run( 'pHats - Initialized' )
