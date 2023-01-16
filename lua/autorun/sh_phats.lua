if (SERVER) then
    AddCSLuaFile( 'phats/config.lua' )
    AddCSLuaFile( 'phats/cl_lib.lua' )
end

if (CLIENT) then
    include( 'phats/cl_lib.lua' )
    include( 'phats/config.lua' )
end