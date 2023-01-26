# pHats
Simple hats addon...

## Properties
- hat:SetAttachment( `string` attachmentName ) - Hat Attachment (`eyes`, `chest`, `lefthand`, `righthand`, `anim_attachment_RH`, `anim_attachment_LH`)
- hat:SetBoneName( `string` boneName ) - Bone name relative to which the hat will be rendered.
- hat:SetAlpha( `number` alpha ) - Hat Transparency
- hat:SetColor( `color` color ) - Hat Color
- hat:SetSize( `number` size ) - Hat Size
- hat:SetAngles( `angle` ang ) - Hat Angle
- hat:SetModel( `string` mdl ) - Hat Model
- hat:SetPos( `vector` pos ) - Hat Local Position
- hat:SetUsePlayerColor( `boolean` bool ) - Hat will use the player's color

## Checkups
- hat:AddActiveWeapon( `string` class ) - Weapon ClassName
- hat:AddSteamID64( `string` sid64 ) - Player SteamID64
- hat:AddHasWeapon( `string` class ) - Weapon ClassName
- hat:AddModel( `string` mdl ) - Path to player model
- hat:AddSteamID( `string` sid ) - Player SteamID

## Examples (`config.lua`):
```lua
-- PrikolMen
do

    local hat = phats.Register( 'prikolmen', 'models/player/items/humans/top_hat.mdl' )
    hat:AddModel( 'models/player/Group03/female_02.mdl' )
    hat:AddSteamID( 'STEAM_0:1:70096775' )
    hat:SetPos( Vector( -3, 0, -3 ) )

end

-- Saw
do

    local hat = phats.Register( 'saw', 'models/props_junk/sawblade001a.mdl' )
    hat:SetAttachment( 'chest' )
    hat:SetPos( Vector( -10, 0, -1 ) )
    hat:SetAngles( Angle( 90, 0, 0 ) )

end

-- Pistol
do

    local hat = phats.Register( 'pistol', 'models/weapons/w_pistol.mdl' )
    hat:AddActiveWeapon( 'weapon_pistol' )
    hat:SetAttachment( 'anim_attachment_LH' )
    hat:SetAngles( Angle( -10, 180, 0 ) )
    hat:SetPos( Vector( 4, 1, 2 ) )

end

-- SMG
do

    local hat = phats.Register( 'smg', 'models/weapons/w_smg1.mdl' )
    hat:AddHasWeapon( 'weapon_smg1' )
    hat:SetAttachment( false )
    hat:SetBoneName( 'ValveBiped.Bip01_R_Thigh' )
    hat:SetAngles( Angle( 0, 0, 90 ) )
    hat:SetPos( Vector( 10, 0, -4 ) )

end
```
