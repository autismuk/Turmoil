--- ************************************************************************************************************************************************************************
---
---				Name : 		enemies.lua
---				Purpose :	Enemy Classes
---				Created:	4 August 2014
---				Updated:	4 August 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************


local Sprites = require("images.sprites")
require("utils.particle")

local EnemyBase = Framework:createClass("game.enemybase")

--//	Construct a new enemy - requires gameSpace in, factory, type ID.
--//	@info 	[table]		Constructor information

function EnemyBase:constructor(info)

	self.m_gameSpace = info.gameSpace 															-- remember game space
	self.m_enemyType = info.type 																-- type reference.
	self.m_sprite = Sprites:newSprite() 														-- sprite for this enemy
	self.m_sprite:setSequence(self:getSpriteSequence()) 										-- set sequence and play
	self.m_sprite:play()
	self.m_speedScalar = math.min(1 + (Framework.fw.status:getLevel() - 1) / 8,3)
	self.m_channel = self.m_gameSpace:assignChannel(self,info.preferred) 						-- assign it to a channel, possible preference
	self.m_xPosition = 0 self.m_xDirection = 1 													-- start on left
	if math.random(1,2) == 1 then  																-- or right, random choice
		self.m_xPosition = 100 self.m_xDirection = -1 
	end
	self.m_elapsedTime = 0 																		-- object life timer
	self:reposition() 																			-- draw initial position.

end 

--//	Delete enemy.

function EnemyBase:destructor()
	self.m_gameSpace:deassignChannel(self) 														-- remove from channel
	self.m_sprite:removeSelf() 																	-- remove sprite and null references
	self.m_sprite = nil self.m_gameSpace = nil
end

--//	Get display objects
--//	@return 	[list]	list with the sprite in it

function EnemyBase:getDisplayObjects()
	return { self.m_sprite }
end 

--//	move enemy base
--//	@deltaTime 	[number]	elapsed time.

function EnemyBase:onUpdate(deltaTime)
	self.m_elapsedTime = self.m_elapsedTime + deltaTime  										-- update object life timer
	local adjSpeed = math.min(200,self:getSpeed() * self.m_speedScalar)
	self.m_xPosition = self.m_xPosition + adjSpeed * self.m_xDirection * deltaTime 				-- new position
	if self.m_xPosition < 0 or self.m_xPosition > 100 then  									-- off left or right ?
		self.m_xPosition = math.min(100,math.max(0,self.m_xPosition)) 							-- put in 0-100 limit
		self:bounce() 																			-- and bounce.
	end
	self:reposition() 																			-- redraw.
end 

--//	This kills, as opposed to deletes an object. The game space is notified the channel is empty, and points may
--//	be accumulated.

function EnemyBase:kill()
	self:sendMessage("enemyFactory","kill", { type = self.m_enemyType })						-- tell the factory it has died
	Framework:new("graphics.particle.short", { emitter = "explosion",x = self.m_sprite.x,y = self.m_sprite.y,time = 0.5, scale = 0.35 } )
	Framework.fw.status:addScore(self:getScore())
	self:delete()																				-- and kill object.
end 

--//	What happens when we reach the end of a channel.

function EnemyBase:bounce() 
	self.m_xDirection = -self.m_xDirection 														-- reverse horizontal direction.
end 

--//	Update screen position.

function EnemyBase:reposition()
	if not self:isAlive() then return end
	local x,y = self.m_gameSpace:getPos(self.m_xPosition,self.m_channel) 						-- get physical position
	self.m_sprite.x,self.m_sprite.y = x,y 														-- update position
	self.m_sprite.xScale = self.m_gameSpace:getSpriteSize()/64									-- reset sprite size
	self.m_sprite.yScale = self.m_gameSpace:getSpriteSize()/64
	if self.m_xDirection < 0 then self.m_sprite.xScale = -self.m_sprite.xScale end 				-- adjust for right-left movement
end 

--//	Is the object grabbable
--//	@return 	[boolean]		true if it is.

function EnemyBase:isGrabbable() return false end 

--//	Is the object shootable
--//	@return 	[boolean]		true if it is.

function EnemyBase:isShootable() return true end 

--//	Does the object at the given horizontal position collide with this enemy (note, this does not test the channel)
--//	@xPosition 	[number]		Position horizontally
--//	@return 	[boolean]		True if collides.

function EnemyBase:collide(xPosition)
	return math.abs(xPosition - self.m_xPosition) < 4
end 

--//	Get the object's horizontal position 
--//	@return 	[number]		logical position 0..100

function EnemyBase:getX() return self.m_xPosition end 

local Enemy1,SuperClass = Framework:createClass("game.enemy.type1","game.enemybase") 			-- Enemy 1 slows down in the middle			
function Enemy1:getSpriteSequence() return "enemy1" end 

function Enemy1:getSpeed() 																	
	local n = math.abs(50-self.m_xPosition)/50
	return math.sin(n*1.6) * 24 + 6
end

function Enemy1:getScore()
	return (50-math.abs(50-math.floor(self.m_xPosition))) * 10
end 

local Enemy2,SuperClass = Framework:createClass("game.enemy.type2","game.enemybase") 			-- Enemy 2 changes speed every time it turns round.
function Enemy2:getSpriteSequence() return "enemy2" end 

function Enemy2:getSpeed() 
	if self.m_speed == nil then self.m_speed = math.random(6,36) end
	return self.m_speed 
end

function Enemy2:getScore()
	return self:getSpeed() * 10 
end

function Enemy2:bounce()
	SuperClass.bounce(self)
	self.m_speed = nil 
end 

local Enemy3,SuperClass = Framework:createClass("game.enemy.type3","game.enemybase") 			-- Enemy 3 speeds up with every bounce.
function Enemy3:getSpriteSequence() return "enemy3" end 

function Enemy3:getSpeed() 
	self.m_speed = self.m_speed or 8 
	return self.m_speed
end

function Enemy3:bounce()
	SuperClass.bounce(self)
	self.m_speed = math.min(128,self.m_speed * 2)
end

function Enemy3:getScore()
	return self:getSpeed() * 10 
end

local Enemy4,SuperClass = Framework:createClass("game.enemy.type4","game.enemybase") 			-- Enemy 4 is fast one way, slow the other
function Enemy4:getSpriteSequence() return "enemy4" end 

function Enemy4:getSpeed() 
	if self.m_orientation == nil then
		self.m_orientation = math.random(1,2) * 2 - 3
	end
	return (self.m_orientation * self.m_xDirection) > 0 and 12 or 52 
end

function Enemy4:getScore()
	return self:getSpeed() * 10 
end

local Enemy5,SuperClass = Framework:createClass("game.enemy.type5","game.enemybase") 			-- Enemy 5 is just dull.
function Enemy5:getSpriteSequence() return "enemy5" end 
function Enemy5:getSpeed() return 14 end

function Enemy5:getScore() return 100 end 

local Enemy6,SuperClass = Framework:createClass("game.enemy.type6","game.enemybase") 			-- the prize class (can be picked up)

Enemy6.WAIT_TIME = 4 																			-- time before pinging.

function Enemy6:constructor(info)
	SuperClass.constructor(self,info)															-- superconstructor
	self.m_hasStarted = false  																	-- set to true when has started pinging
	self.m_startTime = Enemy6.WAIT_TIME 														-- when it starts pinging (seconds)
end 

function Enemy6:getSpriteSequence() 
	return "prize" 
end 

function Enemy6:isGrabbable()
	return not self.m_hasStarted 
end 

function Enemy6:getSpeed() 
	return self.m_hasStarted and 100 or 0 														-- stationary until it starts pinging
end

function Enemy6:onUpdate(deltaTime)
	SuperClass.onUpdate(self,deltaTime) 														-- super update
	if self.m_elapsedTime > self.m_startTime then 												-- has it reached pinging time
		self.m_hasStarted = true 																-- if so, mark as such.
		self.m_sprite:setSequence("smallprize") 												-- only use the small sprite image.
	end 
	if self.m_elapsedTime < self.m_startTime then 
		local speedScalar = 0.5 + 2 * self.m_elapsedTime / self.m_startTime
		self.m_sprite.timeScale = speedScalar
	end
end 

function Enemy6:isShootable() 																	-- can only be shot when in motion.
	return self.m_hasStarted 
end

function Enemy6:getScore()
	return self.m_hasStarted and 50 or 500 
end 

local Enemy7,SuperClass = Framework:createClass("game.enemy.type7","game.enemybase") 			-- the arrow to tank class.

function Enemy7:constructor(info)
	SuperClass.constructor(self,info) 															-- superconstructor
	self.m_isTank = false 																		-- true if tank
end 

function Enemy7:bounce()
	SuperClass.bounce(self) 																	-- still bounce
	if not self.m_isTank then 																	-- but if arrow, make a tank on bounce.
		self.m_isTank = true 
		self.m_sprite:setSequence("tank")
		self.m_sprite:play()
	end
end 

function Enemy7:kill() 																			-- tanks can only be killed from behind.
	if self.m_isTank then 																		-- if it is a tank.
		if self.m_xDirection * (self.m_xPosition - 50) < 0 then 								-- and it is shot face on.
			self.m_xPosition = self.m_xPosition - self.m_xDirection * 10 						-- throw it backwards
			self.m_xPosition = math.min(99,math.max(self.m_xPosition,1))						-- force into range.
			return 
		end 
	end
	SuperClass.kill(self)																		-- call normal kill method
end 

function Enemy7:getSpriteSequence() 
	return "arrow" 
end 

function Enemy7:getSpeed() 
	return self.m_isTank and 6 or 11 															-- tanks are slower.
end

function Enemy7:getScore()
	return self.m_isTank and 500 or 50
end 

local EnemyGhost,SuperClass = Framework:createClass("game.enemy.ghost","game.enemybase")		-- ghost enemy (indestructable)

function EnemyGhost:getSpriteSequence() return "ghost" end 

function EnemyGhost:getSpeed() return 13 end 

function EnemyGhost:bounce() self:delete() end 													-- deletes self on bounce.

function EnemyGhost:isShootable() return false end  											-- cannot be shot.

function EnemyGhost:kill() return end 															-- cannot be killed.

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		04-Aug-14	0.1 		Initial version of file
		14-Aug-14 	1.0 		Advance to releasable version 1.0

--]]
--- ************************************************************************************************************************************************************************
