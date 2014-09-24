--- ************************************************************************************************************************************************************************
---
---				Name : 		miscellany.lua
---				Purpose :	Assorted small classes
---				Created:	11 August 2014
---				Updated: 	11 August 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************


require("utils.fontmanager")

local Intro = Framework:createClass("game.intro")

--//	Create the 'go destroy' object which scrolls up and vanishes
--//	@info 	[table]			Constructor information

function Intro:constructor(info)
	self.m_text = display.newBitmapText("Go Destroy !",
										display.contentWidth/2,									-- start in the middle
										display.contentHeight/2,
										"grapple",64)
	self.m_text:setJustification()
	self.m_text:setTintColor(1,1,0)
	self:tag("introText") 																		-- tagged so transition started on postOpen message from scene
end

--//	Tidy up

function Intro:destructor()
	self.m_text:removeSelf() 																	-- delete text object and null references
	self.m_text = nil
end 

function Intro:getDisplayObjects() 
	return { self.m_text }
end

function Intro:onMessage(sender,message,data)
	transition.to(self.m_text,{ time = 1500,y = -320, alpha = 0, 								-- message sent here starts transition up and fade out
					onComplete = function() self:delete() end }) 								-- self delete on end.
end

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		11-Aug-14	0.1 		Initial version of file
		14-Aug-14 	1.0 		Advance to releasable version 1.0

--]]
--- ************************************************************************************************************************************************************************
