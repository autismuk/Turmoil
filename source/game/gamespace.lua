--- ************************************************************************************************************************************************************************
---
---				Name : 		gamespace.lua
---				Purpose :	Object representing play area
---				Created:	2 August 2014
---				Updated:	2 August 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

local GameSpace = Framework:createClass("game.gamespace")

--//	Constructor - requires enemy factory, scene, level number.

function GameSpace:constructor(info)
	self.m_headerSize = info.header or 0 														-- extract out parameters.
	self.m_scene = info.scene 																	-- owning scene
	self.m_channelCount = Framework.fw.status:getChannels() 									-- get the number of channels
	self.m_currentLevel = Framework.fw.status:getLevel()										-- game level.
	self.m_borderSize = 2 																		-- width of border.
	self.m_borderList = {} 																		-- list of border objects
	self:addBorder(0,display.contentWidth,0) 													-- top and bottom borders.
	self:addBorder(0,display.contentWidth,display.contentHeight - 				
												self.m_headerSize - 1 - self.m_borderSize)
	self.m_channelSize = math.floor((display.contentHeight - self.m_borderSize 					-- size of each channel
												- self.m_headerSize) / self.m_channelCount)
	self.m_spriteSize = self.m_channelSize - self.m_borderSize 									-- size of each sprite (w and h)
	self.m_channelObjects = {} 																	-- object in each channel, or nil if empty.
	self.m_channelObjectCount = 0 																-- number of objects in channels in total.

	self.m_fireTimer = 0 																		-- timer for creating new enemies
	self.m_fireTimerRate = math.max(0.5,2.5 - self.m_currentLevel/4)							-- how often they ping out.
	for c = 1,self.m_channelCount-1 do  														-- create channels.
		local y = self.m_borderSize + self.m_channelSize * c 
		self:addBorder(0,display.contentWidth/2-self.m_channelSize,y)
		self:addBorder(display.contentWidth,display.contentWidth/2+self.m_channelSize,y)
	end
	display.getCurrentStage():addEventListener("tap",self)										-- listen for taps.
	self:tag("gameSpace")
end

--//	Tidy up

function GameSpace:destructor()
	display.getCurrentStage():removeEventListener("tap",self)									-- stop listening for taps.
	for c = 1,self.m_channelCount do 															-- delete any objects that haven't been deleted.
		if self.m_channelObjects[c] ~= nil then 
			self.m_channelObjects[c]:delete()
		end 
	end 
	for _,ref in ipairs(self.m_borderList) do ref:removeSelf() end 								-- remove all borders
	self.m_borderList = nil self.m_scene = nil 													-- null references
end 

--//	Auto spawn object code on update
--//	@deltaTime 	[number]	Elapsed time.

function GameSpace:onUpdate(deltaTime)
	self.m_fireTimer = self.m_fireTimer + deltaTime 											-- elapsed time.
	if self.m_fireTimer > self.m_fireTimerRate or self.m_channelObjectCount == 0 then 			-- if time out, or no enemies at all visible.
		if self:isAnyChannelAvailable() then 													-- if there is space, spawn a facory
			self:sendMessage("enemyFactory","spawn", { scene = self.m_scene, gameSpace = self })
		end
		self.m_fireTimer = 0 																	-- reset the timer.
	end
end 

--//	Add a single border part to the gamespace - this is purely visual.
--//	@x1 	[number]		horizontal position
--//	@x2 	[number]		horizontal position
--//	@y 		[number]		vertical position (advert space is added)

function GameSpace:addBorder(x1,x2,y)
	local line = display.newLine(x1,y+self.m_headerSize,x2,y+self.m_headerSize) 				-- create line, offset for advert
	line:setStrokeColor(0,0,1) line.strokeWidth = 2 											-- set it up.
	self.m_borderList[#self.m_borderList+1] = line  											-- add it to the object list.
end 

--//	Get a list of display objects in this scene.
--//	@return [list]			list of display objects.

function GameSpace:getDisplayObjects() 
	return self.m_borderList 
end 

--//	Assign an object to a random channel.
--//	@object  	[enemy object]	object to assign.
--// 	@preferred  [number]		channel to try first (optional)
--//	@return 	[number]		channel number or nil if cannot assign.

function GameSpace:assignChannel(object,preferred)
	if self.m_channelObjectCount == self.m_channelCount then return nil end 					-- return nil if no space available.
	local c
	repeat  																					-- find an empty channel.
		c = math.random(1,self.m_channelCount) 													-- pick one randomly.
		if preferred ~= nil then c = preferred preferred = nil end 								-- if preferred channel, use that first time.
	until self.m_channelObjects[c] == nil 			 											-- keep going until empty slot found.
	self.m_channelObjects[c] = object 															-- put object in channel.
	self.m_channelObjectCount = self.m_channelObjectCount + 1 									-- bump count of objects
	return c 																					-- return channel number.
end 

--//	Deassign an object from its channel
--//	@object 	[enemyObject]	object to remove.

function GameSpace:deassignChannel(object)
	for i = 1,self.m_channelCount do 															-- work through all channels.
		if self.m_channelObjects[i] == object then 												-- found the relevant object ?
			self.m_channelObjects[i] = nil 														-- mark channel as empty.
			self.m_channelObjectCount = self.m_channelObjectCount - 1 							-- reduce count of objects
			return 																				-- and exit
		end 
	end 
	error("Cannot deassign gamespace channel")													-- object was not found.
end 

--//	Launch a 'ghost' enemy which cannot be destroyed
--//	@channel [number] 	channel to launch it in.

function GameSpace:launchGhostEnemy(channel)
	if self:isChannelInUse(channel) then return end 											-- exit if channel in use.
	self.m_scene:new("game.enemy.ghost", { gameSpace = self, 									-- create a special instance (not via factory)
													type = nil, preferred = channel, level = self.m_currentLevel })
end 

--//	Get the reference of an object in the channel
--//	@channel 	[number]	channel to access
--//	@return 	[object]	object reference in channel, or nil if empty.

function GameSpace:fetchObject(channel)
	return self.m_channelObjects[channel]
end 

--//	Check to see if a channel is occupied
--//	@channel 	[number]		Channel number
--//	@return 	[boolean]		true if channel is occupied.

function GameSpace:isChannelInUse(channel)
	return self.m_channelObjects[channel] ~= nil 
end 

--//	Check to see if any channel is available, e.g. the game space is not full.
--//	@return 	[boolean]		true if there is at least one empty channel.

function GameSpace:isAnyChannelAvailable()
	return self.m_channelObjectCount < self.m_channelCount 
end 

--//	Convert logical position to physical position.
--//	@xPercent 	[number]		Percentage across l->r
--//	@yChannel 	[number]		Channel Number
--//	@return 	[number,number]	Physical coordinates.

function GameSpace:getPos(xPercent,yChannel)
	return xPercent * display.contentWidth / 100, self.m_channelSize * (yChannel - 0.5)+ self.m_headerSize + self.m_borderSize / 2
end 

--//	Convert physical vertical position to channel number, or nil if not definitely 'in' channel.
--//	@yPos 		[number]		Vertical sprite position.
--//	@return 	[number]		channel number or nil

function GameSpace:physicalToLogical(yPos)
	yPos = yPos - self.m_headerSize - self.m_borderSize / 2 									-- Convert to a channel position
	yPos = yPos / self.m_channelSize + 1
	local frac = yPos - math.floor(yPos) 														-- what position in channel
	if frac < 0.25 or frac > 0.75 then return nil end 											-- if not roughly central return nil.
	return math.floor(yPos) 																	-- return integer channel number.
end 

--//	Handle tap messages, convert to the logical system.
--//	@event 		[event]			Event Data
--//	@return 	[boolean]		True as processed.

function GameSpace:tap(event)
	local x = math.min(100,math.max(0,event.x / display.contentWidth * 100))					-- Work out logical X
	local y = event.y - self.m_borderSize - self.m_headerSize  									-- Work out y offset
	if y >= 0 then  																			-- if in game area
		y = math.min(math.floor(y/self.m_channelSize)+1,self.m_channelCount) 					-- work out channel.
		self:sendMessage("taplistener","tap",{ x = x, y = y })									-- tell all listeners about it.
		return true 																			-- message processed.
	end
	return false
end

--//	Get the game space size - the number of horizontal channels
--//	@return 	[number]		Number of channels.

function GameSpace:getSize()
	return self.m_channelCount 
end 

--//	Get the sprite size in pixels to fit a channel.
--//	@return 	[number]		Sprite size in pixels.

function GameSpace:getSpriteSize()
	return self.m_spriteSize 
end 

--//	Receive end level message ?

function GameSpace:onMessage(sender,message,data)
	assert(message == "endLevel")																-- only know this message.
	local factory = Framework.fw.enemyFactory 													-- get current factory.
	self:sendMessage(factory,"stop")															-- stop it from spawning.
	if factory:getEnemyCount() == 0 then 														-- destroyed everything in this level 
		factory:delete() 																		-- delete the factory that was in use.
		Framework.fw.status:nextLevel() 														-- go to the next level
		Framework.fw.status:addLife(1) 															-- gain one life for completing the level. 
		Framework:new("game.enemyFactory") 														-- create a new factory for the next level.
	end 

	if Framework.fw.status:getLives() == 0 then  												-- if lives zero, then exit else continue.
		self:performGameEvent("lost")
	else 
		self:performGameEvent("continue")
	end 
end

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		2-Aug-14	0.1 		Initial version of file
		14-Aug-14 	1.0 		Advance to releasable version 1.0

--]]
--- ************************************************************************************************************************************************************************
