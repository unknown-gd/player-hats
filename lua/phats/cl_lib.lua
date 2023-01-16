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

    -- Color
    function meta:SetColor( color )
        self:SetAlpha( color['a'] / 255 )
        self.Color = color:ToVector()
        return self
    end

    function meta:GetColor()
        return self.Color[1], self.Color[2], self.Color[3]
    end

    -- Size
    function meta:SetSize( size, delay )
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
        return self.AttachmentName or 'eyes'
    end

    -- Filters
    function meta:AddSteamID( sid )
        table.insert( self.SteamIDs, sid )
        return self
    end

    function meta:AddSteamID64( sid64 )
        table.insert( self.SteamIDs, util.SteamIDFrom64( sid64 ) )
        return self
    end

    function meta:AddModel( mdl )
        table.insert( self.Models, string.lower( mdl ) )
        return self
    end

    function meta:AddHasWeapon( class )
        table.insert( self.Weapons, class )
        return self
    end

    function meta:CanWear( ply )
        if ply:Alive() then
            local hasSteamID = false
            if table.IsEmpty( self.SteamIDs ) then
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

            local hasWeapon = false
            if table.IsEmpty( self.Weapons ) then
                hasWeapon = true
            else
                for _, class in ipairs( self.Weapons ) do
                    if ply:HasWeapon( class ) then
                        hasWeapon = true
                        break
                    end
                end
            end

            return hasSteamID and hasModel and hasWeapon
        end

        return false
    end

    function meta:CalcPosition( ply )
        local attachmentID = ply:LookupAttachment( self:GetAttachment() )
        if (attachmentID > 0) then
            local data = ply:GetAttachment( attachmentID )
            if (data) then
                return LocalToWorld( self:GetPos(), self:GetAngles(), data.Pos, data.Ang )
            end
        end

        return LocalToWorld( self:GetPos(), self:GetAngles(), ply:EyePos(), ply:EyeAngles() )
    end

    -- Entity
    function meta:GetEntity()
        return self.Entity
    end

    function meta:SetEntity( ent )
        self.Entity = ent
    end

    -- Remove
    function meta:Remove()
        local ent = self:GetEntity()
        if IsValid( ent ) then
            ent:Remove()
        end
    end

    -- Think
    function meta:Think( ent )
        ent:SetModelScale( self:GetSize(), 0 )
        ent:SetModel( self:GetModel() )
    end

    -- Draw
    function meta:Draw( ply, flags )
        local ent = self:GetEntity()
        if IsValid( ent ) then
            local r, g, b = render.GetColorModulation()
            render.SetColorModulation( self:GetColor() )
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

        function Register( name, model )
            UnRegister( name )

            local ent = ents.CreateClientProp( model )
            ent:SetNoDraw( true )
            ent:SetupBones()

            local new = setmetatable({
                ['Model'] = Model( model ),
                ['Entity'] = ent,
                ['Name'] = name,
                ['SteamIDs'] = {},
                ['Weapons'] = {},
                ['Players'] = {},
                ['Models'] = {},
            }, meta)

            hook.Add('Think', ent, function( self )
                new:Think( self )
            end)

            new:SetColor( Color( 255, 255, 255 ) )
            table.insert( hats, new )
            return new
        end

        hook.Add('PostPlayerDraw', 'pHats - Render', function( ply, flags )
            for _, hat in ipairs( hats ) do
                if hat.Players[ ply ] then
                    hat:Draw( ply, flags )
                end
            end
        end)

        hook.Add('PlayerPostThink', 'pHats - Think', function( ply )
            for _, hat in ipairs( hats ) do
                hat.Players[ ply ] = hat:CanWear( ply )
            end
        end)

    end

end