--- ************************************************************************************************************************************************************************
---
---				Name : 		missiles.lua
---				Purpose :	Missiles and Missile manager code.
---				Created:	6 August 2014
---				Updated:	6 August 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

local Sprites = require("images.sprites")

local Missile = Framework:createClass("game.missile")

Missile.SPEED = 40

--//	Create a new object - no parameters as initialise() used for caching objects.

function Missile:constructor(info)
	self.m_sprite = Sprites.newSprite()															-- create a new object
	self.m_sprite:setSequence("bullet")															-- set its graphic
	self.m_sprite.isVisible = false 															-- can't be seen
	self.m_sprite.inUse = false 																-- not in use
end

--//	Tidy up

function Missile:destructor()
	self.m_sprite:removeSelf()																	-- remove sprite object
	self.m_sprite = nil  self.m_gameSpace = nil self.m_owner = nil 								-- null references
end 

--//	Get List of Display Objects
--//	@return 	[list]		List of display objects

function Missile:getDisplayObjects()
	return { self.m_sprite } 																	-- just the sprite
end

--//	Re-initialise a missile - they are recirculated
--//	@channel 	[number]	Channel number
--//	@direction 	[number]	direction, -1 or 1
--//	@gameSpace 	[object]	gamespace object
--//	@owner 		[object]	Missile Cache object

function Missile:initialise(channel,direction,gameSpace,owner)
	self.m_xPosition = 50+direction*6 self.m_xDirection = direction 							-- initialise and save everything
	self.m_gameSpace = gameSpace self.m_channel = channel self.m_owner = owner
	self.m_sprite.isVisible = true 																-- make it visible
	self.m_sprite.inUse = true 																	-- mark as in use
	self:reposition() 																			-- set position.
end 

--//	Return missile to cache

function Missile:returnToCache()
	self.m_sprite.isVisible = false self.m_sprite.x = -400  									-- hide and move off screen
	self.m_sprite.inUse = false 																-- no longer in use
	self.m_owner:addToCache(self) 																-- return to the external cache.
end 

--//	Handle updates
--//	@deltaTime 	[number] 		elapsed time

function Missile:onUpdate(deltaTime)
	if not self.m_sprite.inUse then return end 													-- if in cache do nothing
	self.m_xPosition = self.m_xPosition + self.m_xDirection * deltaTime * Missile.SPEED 		-- move missile
	self:reposition() 																			-- redraw
	if self.m_xPosition < 0 or self.m_xPosition > 100 then 										-- if off screen return to cache
		self:returnToCache() 
	else 
		local object = self.m_gameSpace:fetchObject(self.m_channel) 							-- get object in channel.
		if object ~= nil and object:collide(self.m_xPosition) and object:isShootable() then  	-- if exists and collides with
			object:kill() 																		-- kill it 
			self:playSound("bomb")
			self:returnToCache()																-- return missile to cache.
		end
	end 			
end 

--//	Reposition sprite graphic

function Missile:reposition()
	local x,y = self.m_gameSpace:getPos(self.m_xPosition,self.m_channel)						-- convert logical to physical
	self.m_sprite.x,self.m_sprite.y = x,y 														-- move sprite
	local s = self.m_gameSpace:getSpriteSize()/64 												-- scale to correct size
	self.m_sprite.xScale,self.m_sprite.yScale = s,s
end 

local MissileManager = Framework:createClass("game.missilemanager")								-- manages collections.

--//	Create a manager, requires a scene and game space
--//	@info 	[table]		constructor data

function MissileManager:constructor(info)
	self.m_gameSpace = info.gameSpace 															-- remember the game space and scene
	self.m_scene = info.scene 		
	self:tag("missileManager") 																	-- tag object
	self.m_missileList = {} 																	-- list of missile objects available.
end

--//	Delete a manager

function MissileManager:destructor()
	self.m_gameSpace = nil 																		-- clear refs
	for _,ref in ipairs(self.m_missileList) do ref:delete() end  								-- delete any missiles in the cache.
	self.m_missileList = nil 																	-- null the list
end

--//	Return a missile to the cache
--//	@missile 	[object] 	missile to be recached

function MissileManager:addToCache(missile)
	self.m_missileList[#self.m_missileList+1] = missile 
end

--//	Handle messages (telling the system to fire)

function MissileManager:onMessage(sender,message,data)
	if #self.m_missileList == 0 then 															-- if there are no cached missiles
		self.m_missileList[1] = self.m_scene:new("game.missile") 								-- create one
	end 
	local missile = self.m_missileList[#self.m_missileList]										-- get the last on the cache list
	self.m_missileList[#self.m_missileList] = nil 												-- and reduce list size by 1.
	missile:initialise(data.channel,data.direction,self.m_gameSpace,self) 						-- reinitialise it.
end

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		6-Aug-14	0.1 		Initial version of file
		14-Aug-14 	1.0 		Advance to releasable version 1.0

--]]
--- ************************************************************************************************************************************************************************
