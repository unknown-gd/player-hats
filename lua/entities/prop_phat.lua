AddCSLuaFile()
ENT.Type = 'anim'

function ENT:Initialize()
    self:SetModel( 'models/player/items/humans/top_hat.mdl' )
end

do

    local util_PrecacheModel = util.PrecacheModel
    local ENTITY = FindMetaTable( 'Entity' )

    function ENT:SetModel( str )
        util_PrecacheModel( str )
        ENTITY.SetModel( self, str )
    end

end

function ENT:Draw( fl )
    self:DrawModel( fl )
end