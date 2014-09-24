--- ************************************************************************************************************************************************************************
---
---				Name : 		main_sprite.lua
---				Purpose :	Test for image packing library
---				Created:	29 July 2014
---				Updated:	30 July 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

local demoSprites = require("images.sprites")													-- library which has been generated

local imageSheet = demoSprites:getImageSheet()													-- get an image sheet

for i = 1,60 do 																				-- display all images.
	local d = demoSprites:newImage(i)															-- create an image
	d.x = (i - 1) % 10 * 40																		-- position it etc.
	d.y = math.floor((i - 1) / 10) * 40		
	d.anchorX,d.anchorY = 0,0
	d.width,d.height = 40,40
end

local anim = { "enemy1","enemy2","enemy3","enemy4","enemy5","tank","prize","player","bullet","ghost","arrow" }
local h = display.contentHeight/8
for i = 1,11 do
	local animation = demoSprites:newSprite()														-- new sprite
	animation.x,animation.y = i*h,display.contentHeight-64 										-- move to correct place
	animation:setSequence(anim[i])																	-- select and play an animation.
	animation:play()
	animation.xScale = h/64
	animation.yScale = h/64
end

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		29-Jul-14	0.1 		Initial version of file

--]]
--- ************************************************************************************************************************************************************************
