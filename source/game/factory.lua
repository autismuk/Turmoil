--- ************************************************************************************************************************************************************************
---
---				Name : 		factory.lua
---				Purpose :	Code for spawning enemies, keeps track of those killed.
---				Created:	4 August 2014
---				Updated:	4 August 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

local EnemyFactory = Framework:createClass("game.enemyFactory")

EnemyFactory.TYPE_COUNT = 7 

--//	Create a new enemy factory, using the level to decide how many bad guys.
--//	@info 	[table]	constructor information

function EnemyFactory:constructor(info)
	self.m_enemyTotals = {} 																	-- count of enemies to kill of each type.
	self.m_level = Framework.fw.status:getLevel()												-- get current level from status object.
	self.m_enemyCount = math.floor(math.min(self.m_level * 2 + 9,32)) 							-- number of bad guys in each level.

	-- self.m_enemyCount = 1 print("Level count fudge in")											-- testing thing.

	for i = 1,EnemyFactory.TYPE_COUNT do self.m_enemyTotals[i] = 0 end 							-- clear individual count
	for i = 1,self.m_enemyCount do 																-- add them distributed randomly.
		local n = math.random(1,EnemyFactory.TYPE_COUNT)
		self.m_enemyTotals[n] = self.m_enemyTotals[n] + 1
	end 
	self:createEnemyQueue() 																	-- reset the queue of enemies
	self:tag("enemyFactory")
	self.m_started = false
	self:name("enemyFactory")
end

--//	Tidy up.

function EnemyFactory:destructor() 
end 

--//	Rebuild the queue from the counts - these are monsters not killed, so moving them out via spawn does not affect the
--//	totals

function EnemyFactory:createEnemyQueue()
	self.m_enemyQueue = {} 																		-- queue of enemies to spawn.
	self.m_nextQueueItem = 1 																	-- number of next to spawn.
	for i = 1,#self.m_enemyTotals do 															-- work through all the enemy totals.
		for j = 1,self.m_enemyTotals[i] do 														-- add an enemy for each count of enemies.
			self.m_enemyQueue[#self.m_enemyQueue+1] = i 										-- use the number as an ID.
		end
	end 
	if #self.m_enemyQueue > 1 then 																-- randomise it by shuffling simply.
		for i = 1,#self.m_enemyQueue do 
			local j = math.random(1,#self.m_enemyQueue)
			local t = self.m_enemyQueue[i] 
			self.m_enemyQueue[i] = self.m_enemyQueue[j]
			self.m_enemyQueue[j] = t 
		end
	end
 end 

--//	Handle an enemy being killed.
--//	@typeID 		[number]		enemy type that was killed.

function EnemyFactory:killedEnemy(typeID)
	self.m_enemyTotals[typeID] = self.m_enemyTotals[typeID] - 1 								-- reduce one for the totals for this type
	self.m_enemyCount = self.m_enemyCount - 1 													-- and the overall total.
	if self.m_enemyCount == 0 then 																-- killed everything ?
			self:sendMessageLater("gameSpace","endLevel",nil,1)									-- send an 'end level' message after one second.
			self:playSound("levelcomplete")
	end
end 

--//	Check to see if there is anything left to spawn
--//	@return 	[boolean]			true if the queue is empty

function EnemyFactory:isQueueEmpty()
	return self.m_nextQueueItem > #self.m_enemyQueue 
end 

--//	Spawn a new enemy from the front of the queue.
--//	@sceneRef 	[scene]				scene to add it to
--//	@gameSpace 	[gamespace]			game space it belongs in.

function EnemyFactory:spawn(sceneRef,gameSpace)
	if not gameSpace:isAnyChannelAvailable() then return end 									-- exit if no space available for spawning.
	if not self.m_started then return end 														-- check actually going.
	if self:isQueueEmpty() then return end 														-- nothing to spawn.
	local tID = self.m_enemyQueue[self.m_nextQueueItem] 										-- get the next one to spawn.

	-- tID = 6 print("Type fudge in")															-- uncomment this to force a specific enemy type.

	self.m_nextQueueItem = self.m_nextQueueItem + 1 											-- bump the queue.
	sceneRef:new("game.enemy.type"..tID,{ gameSpace = gameSpace, type = tID,level = self.m_level }) 	-- spawn one.																					
	self:playSound("appear")
end 

function EnemyFactory:getEnemyCount()
	return self.m_enemyCount 
end 

function EnemyFactory:onMessage(sender,message,data)
	if message == "spawn" then 
		self:spawn(data.scene,data.gameSpace)
	end 
	if message == "kill" then 
		self:killedEnemy(data.type)
	end
	if message == "start" then 
		self.m_started = true
		self:createEnemyQueue()
	end
	if message == "stop" then 
		self.m_started = false 
	end
end 

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		04-Aug-14	0.1 		Initial version of file
		14-Aug-14 	1.0 		Advance to releasable version 1.0

--]]
--- ************************************************************************************************************************************************************************
