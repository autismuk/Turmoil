--- ************************************************************************************************************************************************************************
---
---				Name : 		player.lua
---				Purpose :	Player ship code
---				Created:	3 August 2014
---				Updated:	3 August 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

local Sprites = require("images.sprites")

local Player = Framework:createClass("game.player")

--	Players have four states

Player.WAIT_STATE = 0 																			-- state, waiting for command.
Player.MOVE_STATE = 1 																			-- moving to a specific position.
Player.FETCH_STATE = 2 																			-- going to grab a prize
Player.RETURN_STATE = 3 																		-- returning from grabbing a prize.

Player.FIRE_RATE = 0.8 																			-- Player fire delays in seconds.
Player.GHOST_TIME = 3.0 																		-- time after which ghost is sent.
Player.SHIELD_TIME = 5.0 																		-- shield time.

Player.FETCH_SPEED = 125 																		-- Grabbing the grabbable speed.

--//	Create a new player - needs a gameSpace parameter so it knows where it is operating.
--//	@info 	[table]	cosntructor info

function Player:constructor(info)
	self.m_gameSpace = info.gameSpace 															-- space player is operating in.
	self.m_sprite = Sprites:newSprite() 														-- graphic used.
	self.m_spriteShield = Sprites:newSprite()													-- sprite shield.
	self.m_spriteShield:setSequence("shield") self.m_spriteShield.isVisible = false 			-- initially not visible.
	self.m_xPosition = 50 																		-- current position.
	self.m_channel = math.floor(self.m_gameSpace:getSize()/2) 									-- start channel
	self.m_faceRight = true  																	-- facing right
	self.m_playerState = Player.WAIT_STATE  													-- waiting for command
	self:reposition() 																			-- can reposition.
	self:tag("taplistener")																		-- want to listen ?
	self.m_timeToFire = 0 																		-- elapsed time to fire.
	self.m_timeInWait = -5 																		-- time in wait state - initially 5 seconds wait.
	self.m_shield = 0 																			-- if > 0 then shield is visible.
end 

--//	Tidy up

function Player:destructor()
	self.m_sprite:removeSelf() 																	-- remove sprite object
	self.m_gameSpace = nil  																	-- null reference.
end 

--//	Get objects that are part of the scene.
--//	@return 	[list]	List of display objects

function Player:getDisplayObjects() 
	return { self.m_sprite,self.m_spriteShield }
end 

--//	Reposition and put correct sprite up for the current player status

function Player:reposition()
	self.m_sprite:setSequence("player") 														-- set to player sprite (e.g. not moving)
	local x,y = self.m_gameSpace:getPos(self.m_xPosition,self.m_channel) 						-- find out where to draw it
	self.m_sprite.x,self.m_sprite.y = x,y  														-- put it there.
	local s = self.m_gameSpace:getSpriteSize()/64 												-- scale to required size.
	self.m_sprite.yScale = s  																	-- set y scale
	if not self.m_faceRight then s = -s end 													-- facing left ?
	self.m_sprite.xScale = s 																	-- set x scale, sign shows sprite direction.
	self.m_spriteShield.xScale,self.m_spriteShield.yScale = s,s
end

--//	Handle message - listens for control messages
--//	@sender 	[object]	who sent it
--//	@message 	[string]	what it is
--//	@data 		[object]	associated data

function Player:onMessage(sender,message,data)
	if self.m_playerState == Player.RETURN_STATE or 											-- if fetching a prize, can do nothing till
	   self.m_playerState == Player.FETCH_STATE then return end  								-- finished.

	self.m_faceRight = data.x >= 50 															-- set face left/right
	self:reposition() 																			-- and reposition sprite.
	if data.y == self.m_channel then return end 												-- do nothing if same position.

	local _,yNew = self.m_gameSpace:getPos(0,data.y)											-- this is where we are moving to.

	if self.m_playerState == Player.MOVE_STATE then 											-- cancel any current transaction.
		transition.cancel(self.m_transaction)
	end 

	self.m_sprite:setSequence("player_banked")													-- display banked ship graphic.
	if data.y < self.m_channel then self.m_sprite.yScale = -self.m_sprite.yScale end
	self.m_playerState = Player.MOVE_STATE 	 													-- we are now moving.
	self.m_transaction = transition.to(self.m_sprite,{ 	time = 90 * math.abs(data.y - self.m_channel), 
									  					y = yNew,
									  					transition = easing.inOutSine,
									  					onComplete = function() self:endMovement() end })
	self.m_channel = data.y 																	-- update position.
	self:playSound("move")
end 

--//	Called to end movement of player

function Player:endMovement()
	if not self:isAlive() then return end
	self.m_playerState = Player.WAIT_STATE 														-- back to wait state, can fire now.
	self.m_transaction = nil 																	-- forget transaction reference
	local object = self.m_gameSpace:fetchObject(self.m_channel) 								-- get the object in this channel.
	if object ~= nil then  																		-- if there is one
		if object:isGrabbable() then  															-- and it is grabbable.
			self.m_xDirection = -1 																-- make it face the grabbable object.
			if object:getX() > 50 then self.m_xDirection = 1 end 
			self.m_playerState = Player.FETCH_STATE 											-- and switch to the fetch state
		end
	end
	self:reposition() 																			-- tidy up display.
	self.m_timeToFire = Player.FIRE_RATE 														-- immediate fire on arrival.
end 

--//	Handle player update - checks for autofire, checks for ghost creation, auto moves for fetching prie.
--//	@deltaTime 	[number] 		Elapsed time in seconds.

function Player:onUpdate(deltaTime)
	self.m_timeToFire = self.m_timeToFire + deltaTime 											-- update timing.

	if self.m_playerState == Player.WAIT_STATE and self.m_timeToFire > Player.FIRE_RATE then	-- only fire if not moving.
		self:sendMessage("missileManager","fire",												-- fire a missile in given direction and channel.
								{ channel = self.m_channel, direction = self.m_faceRight and 1 or -1 })
		--self:playSound("shoot")																	-- firing sound.s
		self.m_timeToFire = 0 																	-- reset timer.
	end 

	if self.m_playerState == Player.WAIT_STATE then 											-- if in wait state
		self.m_timeInWait = self.m_timeInWait + deltaTime  										-- bump time in wait state
		if self.m_timeInWait > Player.GHOST_TIME then  											-- time to send ghost
			self.m_gameSpace:launchGhostEnemy(self.m_channel)									-- ask the game space to do it.
			self.m_timeInWait = 0 																-- reset waiting counter.
		end
	else 
		self.m_timeInWait = 0 																	-- if not, clear it.
	end 

	if self.m_playerState == Player.FETCH_STATE or 												-- if fetching or returning.
								self.m_playerState == Player.RETURN_STATE then
		local xPrevious = self.m_xPosition 														-- save original x position.
		self.m_xPosition = self.m_xPosition + Player.FETCH_SPEED * deltaTime * self.m_xDirection-- move it out.
		if self.m_xPosition < 0 or self.m_xPosition > 100 then 									-- reached the end 
			local object = self.m_gameSpace:fetchObject(self.m_channel) 						-- get the object
			if object ~= nil and object:isGrabbable() then 
				self:playSound("prize") 														-- play sfx
				object:kill() 																	-- kill it as grabbed
				self.m_shield = Player.SHIELD_TIME 												-- set the shield to be displayed a while
			end 
			self.m_xDirection = -self.m_xDirection 												-- reverse the movement
			self.m_playerState = Player.RETURN_STATE 											-- now returning to the middle.
		end 
		if self.m_playerState == Player.RETURN_STATE then 
			local sign = (self.m_xPosition - 50) * (xPrevious - 50) 							-- will be > 0 if both same side.
			if sign <= 0 then 
				self.m_xPosition = 50 															-- back in the middle
				self.m_playerState = Player.WAIT_STATE 											-- back waiting for commands.
			end 
		end 
		self.m_faceRight = self.m_xDirection > 0 												-- update right facing flag
		self:reposition() 																		-- and redraw.
	end

	if self.m_shield < 0 and self.m_playerState ~= Player.RETURN_STATE then 					-- cannot be hit when the shield is up, or returning.
		local channel = self.m_gameSpace:physicalToLogical(self.m_sprite.y) 					-- get the channel
		if channel ~= nil then 
			local enemyObject = self.m_gameSpace:fetchObject(math.floor(channel)) 				-- get object in channel.
			if enemyObject ~= nil and enemyObject:collide(50) then 								-- collided with object
				Framework.fw.status:addLife(-1) 												-- lose a life.
				enemyObject:kill() 																-- kill the object
				self:sendMessageLater("gameSpace","endLevel",nil,2.5)							-- send an 'end level' message after 2.5 seconds.
				local spr = Sprites:newImage("player") 											-- clone the sprite so we can animate it
				spr.x,spr.y = self.m_sprite.x,self.m_sprite.y 
				spr.xScale,spr.yScale = self.m_sprite.xScale,self.m_sprite.yScale
				transition.to(spr,{ time = 2000, xScale = 10, yScale = 10, alpha = 0.2, 		-- animate it
												rotation = 3600, onComplete = function(o) o:removeSelf() end })
				self:playSound("dead") 															-- death tune
				self:delete() 																	-- remove the player
			end
		end 
	end 

	self.m_spriteShield.x,self.m_spriteShield.y = self.m_sprite.x,self.m_sprite.y 				-- reposition shield

	self.m_clock = (self.m_clock or 0) + deltaTime 												-- animate the shield rotation and alpha.
	self.m_spriteShield.rotation = -self.m_clock * 70
	self.m_spriteShield.alpha = math.abs(math.sin(self.m_clock*3))

	self.m_shield = self.m_shield - deltaTime 													-- shield timer.
	self.m_spriteShield.isVisible = (self.m_shield >= 0)
end 

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		3-Aug-14	0.1 		Initial version of file
		14-Aug-14 	1.0 		Advance to releasable version 1.0

--]]
--- ************************************************************************************************************************************************************************
