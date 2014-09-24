--- ************************************************************************************************************************************************************************
---
---				Name : 		info.lua
---				Purpose :	Information Scene.
---				Created:	11 August 2014
---				Updated:	11 August 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

local InfoMain = Framework:createClass("scene.infoScene.main")

require("utils.particle")

local Sprites = require("images.sprites")

--//	Create the Information Screen
--//	@info 	[table]			Constructor information

function InfoMain:constructor(info)
	local msg = info.message 																	-- provided message
	if msg == nil then 																			-- otherwise display level message
		msg = "Level ".. Framework.fw.status:getLevel()
	end 

	self.m_group = display.newGroup() 															-- containing group
	display.newBitmapText(self.m_group, 														-- message text
						  msg,
						  display.contentWidth/2,
						  display.contentHeight*0.3,
						  "grapple",72):setTintColor(1,0.5,0)

	self.m_score = {} 																			-- score digits
	for i = 1,7 do 
		self.m_score[i] = display.newBitmapText(self.m_group, 									-- create each one
										 "-",
										 display.contentWidth/2 + i * 36-125-18,
										 display.contentHeight*0.55,
										 "grapple",64):setTintColor(0,1,1)
		self.m_score[i].yScale = 1.7
	end

	if Framework.fw.status:getLives() > 0 then
		local yPos = display.contentHeight * 0.8 												-- lives display
		local sprite = Sprites:newImage("player")
		sprite.x,sprite.y = display.contentWidth * 0.35, yPos
		self.m_group:insert(sprite)

		display.newBitmapText(self.m_group,
							  "x "..Framework.fw.status:getLives(),
							  display.contentWidth * 0.6,yPos,
							  "grapple",64):setTintColor(0,1,0.5)
	end 

	self.m_requiredScore = ("0000000" .. Framework.fw.status:getScore()):sub(-7) 				-- final score display
	self.m_displayedScore = "0000000"															-- current display
	self.m_currentDigit = 1 																	-- current digit rolled in
	self.m_digitTime = 0 																		-- roll in timer.

	display.getCurrentStage():addEventListener("tap",self) 										-- add event listeners

	self.m_emitter = Framework:new("graphics.particle",{ emitter = "stars"})					-- starfield effect
	self.m_emitter:start(display.contentWidth/2,display.contentHeight/2)
	self.m_group:insert(self.m_emitter.emitter)
	self.m_emitter.emitter:toBack()
end 

--//	Tidy up

function InfoMain:destructor() 
	display.getCurrentStage():removeEventListener("tap",self)									-- remove listeners
	self.m_emitter:delete()
	self.m_group:removeSelf() 																	-- remove graphics
	self.m_score = nil 																			-- null references.
	self.m_group = nil 
	self.m_homeIcon = nil
end 

function InfoMain:tap(event)
	self:performGameEvent("start") 																-- and run it
end 

function InfoMain:getDisplayObjects() return { self.m_group } end

function InfoMain:onUpdate(deltaTime)
	if self.m_currentDigit > 7 then return end 													-- end if displayed all digits
	self.m_digitTime = self.m_digitTime + deltaTime 											-- bump counter
	local d = self.m_currentDigit
	if self.m_digitTime > 0.15 and 																-- time up and right digit displayed
					self.m_displayedScore:sub(d,d) == self.m_requiredScore:sub(d,d) then 
		self.m_currentDigit = self.m_currentDigit + 1 											-- go to next
		self.m_digitTime = 0 																	-- reset counter
	else 
		local c = (self.m_displayedScore:sub(d,d) * 1 + 1) % 10 								-- otherwise rotate digit.
		self.m_displayedScore = self.m_displayedScore:sub(1,d-1) .. c .. self.m_displayedScore:sub(d+1)
		self.m_score[d]:setText(c.."")
	end 
end 


local InfoScene = Framework:createClass("scene.infoScene","game.sceneManager")

--//	Before opening a main scene, create it.

function InfoScene:preOpen(manager,data,resources)
	local scene = Framework:new("game.scene")
	local adIDs = { ios = "ca-app-pub-8354094658055499/1659828014", 							-- admob identifiers.
					android = "ca-app-pub-8354094658055499/7706361613" }
	scene.m_advertObject = scene:new("ads.admob",adIDs)											-- create a new advert object
	local headerSpace = scene.m_advertObject:getHeight() 										-- get the advert object height
	scene:new("scene.infoScene.main",data)
	scene:new("gui.icon.pulsing", { image = "images/home.png", width = 17, x = 87, y = 87, listener = self, message = "home" })
	return scene
end 

function InfoScene:onMessage(sender,message,body)
	self:performGameEvent("exit") 																-- and run it
end 

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		11-Aug-2014	0.1 		Initial version of file
		14-Aug-14 	1.0 		Advance to releasable version 1.0

--]]
--- ************************************************************************************************************************************************************************