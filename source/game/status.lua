--- ************************************************************************************************************************************************************************
---
---				Name : 		status.lua
---				Purpose :	Game Status Object
---				Created:	8 August 2014
---				Updated:	8 August 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

local StatusObject = Framework:createClass("game.status")

--//	Initialise Status Object
--//	@info 	[table]			Constructor information

function StatusObject:constructor(info)
	self.m_highScore = 0 																		-- Current HS
	self.m_defaultLives = info.lives or 4 														-- lives you start with
	self.m_defaultLevel = info.level or 1 														-- levels you start with
	self.m_channels = info.channel or 7 														-- game channels.
	self:reset() 																				-- reset the game
	self:name("status") 																		-- accessible singleton.
end 

--//	Reset the status object to 'new game' state
function StatusObject:reset()
	self.m_lives = self.m_defaultLives 															-- reset lives, start level
	self.m_level = self.m_defaultLevel
	self.m_score = 0 																			-- zero score
end 

function StatusObject:destructor() end

--//	Simple Accessors

function StatusObject:getLives() return self.m_lives end 
function StatusObject:getScore() return self.m_score end 
function StatusObject:getHighScore() return self.m_highScore end 
function StatusObject:getLevel() return self.m_level end 
function StatusObject:getChannels() return self.m_channels end 

--//	Add to score
--//	@score 	[number]		value to add to score

function StatusObject:addScore(score)
	self.m_score = self.m_score + score
	self.m_highScore = math.max(self.m_highScore,self.m_score)
end

--//	Add to lives
--//	@count 	[number]		value to add to lives, defaults to 1.

function StatusObject:addLife(count)
	self.m_lives = math.max(0,self.m_lives + (count or 1))
end

--//	Advance to next level
--//	@return 	[number]	number of next level

function StatusObject:nextLevel()
	self.m_level = self.m_level + 1
end 

--//	Set the start level
--//	@n 	[number]		level to start from

function StatusObject:setStartLevel(n)
	self.m_defaultLevel = n 
end

--//	Set the channel count
--//	@n 	[number]		new channel count

function StatusObject:setChannelCount(n)
	self.m_channels = n 
end 

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		08-Aug-2014	0.1 		Initial version of file
		14-Aug-14 	1.0 		Advance to releasable version 1.0

--]]
--- ************************************************************************************************************************************************************************

