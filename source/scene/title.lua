--- ************************************************************************************************************************************************************************
---
---				Name : 		title.lua
---				Purpose :	Title Page
---				Created:	12 August 2014
---				Updated:	12 August 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

require("utils.gui")
require("utils.buttons")

local TitleMain = Framework:createClass("scene.titleScene.main")

--//	Create the title screen main objects
--//	@info 	[table]			Constructor information

function TitleMain:constructor(info)
	self.m_group = display.newGroup()															-- put everything in a group
	local txt = display.newText(self.m_group,ApplicationVersion,0,								-- version number bottom left
													0,native.systemFont,14)
	txt.anchorX,txt.anchorY = 0,0
	display.newBitmapText(self.m_group,"Turmoil",												-- main text
						display.contentWidth/2,display.contentHeight/6,"grapple",118):setTintColor(1,1,0)
	display.newBitmapText(self.m_group,"(c) Paul Robson 2014",
						display.contentWidth/2,display.contentHeight*0.37,"grapple",40):setTintColor(0,1,1)

	local highScore = Framework.fw.status:getHighScore()
	display.newBitmapText(self.m_group,"Best-" .. ("0000000" .. highScore):sub(-7),
						display.contentWidth/2,display.contentHeight*0.52,"grapple",44):setTintColor(1,0.5,0)
end 

--// 	Tidy up

function TitleMain:destructor()
	self.m_group:removeSelf() 																	-- remove group and contents and null refs
	self.m_group = nil
end 

function TitleMain:getDisplayObjects()
	return { self.m_group }
end

--//	Main title scene class

local titleScene = Framework:createClass("scene.titleScene","game.sceneManager")				-- extends Scene Manager class

--//	Before opening a main scene, create it.

function titleScene:preOpen(manager,data,resources)
	local scene = Framework:new("game.scene") 													-- create a new scene
	scene:new("scene.titleScene.main",data)														-- add title text
	scene:new("gui.icon.pulsing", { image = "images/go.png", 									-- add pulsing icon.
					width = 14, x = 90, y = 90, listener = self, message = "start" })
	scene:new("gui.text.list", { x = 50, y = 68, listener = nil, message = "active" , 			-- add clickable switching text lists
								 tint = { 1,0.8,0.5 },font = { name = "grapple", size = 40 },key = "startlevel",
								 items = { "Start at Level 1","Start at Level 5","Start at Level 10"} } ):name("startLevel")
	scene:new("gui.text.list", { x = 50, y = 82, listener = nil,
								 tint = { 1,0.8,0.5}, font = { name = "grapple",size = 40 },key = "channelcount",
								 items = { "7 Channels","9 Channels","11 Channels","5 Channels"}}):name("channelCount")
	scene:new("control.audio", { r = 173/255,g = 1,b = 47/255 })
	return scene
end 

--//	Received a message from one of the buttons.

function titleScene:onMessage(sender,message,data)
	local startLevel = Framework.fw.startLevel:getSelected() 									-- get the start level from the clickable switching list
	startLevel = math.max(1,(startLevel-1) * 5) 												-- convert to 1,5,10
	Framework.fw.status:setStartLevel(startLevel) 												-- update the start level value
	local channelCount = Framework.fw.channelCount:getSelected() 								-- get channelcount index
	if channelCount == 4 then channelCount = 5 else channelCount = channelCount * 2 + 5 end 	-- convert to an actual number
	Framework.fw.status:setChannelCount(channelCount) 											-- store it.
	Framework.fw.status:reset() 																-- reset the game
	if Framework.fw.enemyFactory ~= nil then Framework.fw.enemyFactory:delete() end  			-- delete any left over factory
	Framework:new("game.enemyFactory") 															-- create a new factory
	self:performGameEvent("start") 																-- and start (go to the display level and score page)
end 

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		12-Aug-2014	0.1 		Initial version of file
		14-Aug-14 	1.0 		Advance to releasable version 1.0

--]]
--- ************************************************************************************************************************************************************************