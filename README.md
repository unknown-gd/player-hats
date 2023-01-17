# pHats
Simple hats addon...

## Properties
- hat:SetAttachment( `string` attachmentName ) - Hat Attachment (`eyes`, `chest`, `lefthand`, `righthand`, `anim_attachment_RH`, `anim_attachment_LH`)
- hat:SetAlpha( `number` alpha ) - Hat Transparency
- hat:SetColor( `color` color ) - Hat Color
- hat:SetSize( `number` size ) - Hat Size
- hat:SetAngles( `angle` ang ) - Hat Angle
- hat:SetModel( `string` mdl ) - Hat Model
- hat:SetPos( `vector` pos ) - Hat Local Position

## Checkups
- hat:AddActiveWeapon( `string` class ) - Weapon ClassName
- hat:AddSteamID64( `string` sid64 ) - Player SteamID64
- hat:AddHasWeapon( `string` class ) - Weapon ClassName
- hat:AddModel( `string` mdl ) - Path to player model
- hat:AddSteamID( `string` sid ) - Player SteamID

## Example Hat (`config.lua`):
```lua
-- PrikolMen
do

    local hat = phats.Register( 'prikolmen', 'models/player/items/humans/top_hat.mdl' )
    hat:AddModel( 'models/player/Group03/female_02.mdl' )
    hat:AddSteamID( 'STEAM_0:1:70096775' )
    hat:SetPos( Vector( -3, 0, -3 ) )

end
```
