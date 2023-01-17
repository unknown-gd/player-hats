# pHats
Simple hats addon...

## Properties
- :SetAttachment( `string` attachmentName ) - Hat Attachment (`eyes`, `chest`, `lefthand`, `righthand`, `anim_attachment_RH`, `anim_attachment_LH`)
- :SetAlpha( `number` alpha ) - Hat Transparency
- :SetColor( `color` color ) - Hat Color
- :SetSize( `number` size ) - Hat Size
- :SetAngles( `angle` ang ) - Hat Angle
- :SetModel( `string` mdl ) - Hat Model
- :SetPos( `vector` pos ) - Hat Local Position

## Checkups
- :AddSteamID64( `string` sid64 ) - Player SteamID64
- :AddHasWeapon( `string` class ) - Weapon ClassName
- :AddSteamID( `string` sid ) - Player SteamID
- :AddModel( `string` mdl ) - Path to player model

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
