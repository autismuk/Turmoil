--- ************************************************************************************************************************************************************************
---
---				Name : 		main.lua
---				Purpose :	Top level code "Turmoil"
---				Created:	2 August 2014
---				Updated:	2 August 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	Copyright Paul Robson (c) 2014+
---
--- ************************************************************************************************************************************************************************

ApplicationDescription = { 																		-- application description.
	appName = 		"Turmoil",
	version = 		"1.1",
	developers = 	{ "Paul Robson" },
	email = 		"paul@robsons.org.uk",
	fqdn = 			"uk.org.robsons.turmoil", 													-- must be unique for each application.
    admobIDs = 		{ 																			-- admob Identifiers.
    					ios = "ca-app-pub-8354094658055499/1659828014", 							
						android = "ca-app-pub-8354094658055499/7706361613" 
					},
	showDebug = 	true 																		-- show debug info and adverts.
}

display.setStatusBar(display.HiddenStatusBar)													-- hide status bar.
require("strict")																				-- install strict.lua to track globals etc.
require("framework.framework")																	-- framework.
require("utils.sound")
require("game.status")
require("scene.title")
require("scene.info")
require("scene.mainscene")

Framework:new("audio.sound",																	-- create sounds object
					{ sounds = { "dead", "move","prize","shoot","levelcomplete","bomb","appear" } })
Framework:new("game.status") 																	-- create game status object.

Framework.fw.status:reset()

local manager = Framework:new("game.manager") 													-- Create a new game manager and add states.

manager:addManagedState("start",																-- Title Page
						Framework:new("scene.titleScene"), 
						{ start = "info" })														-- title page (and options)

manager:addManagedState("info", 																-- Scene before starting, no exit.
						Framework:new("scene.infoScene", { }),
						{ start = "main", exit = "start" }) 									-- Level nn [complete] , Score, play on or go back.

manager:addManagedState("main",																	-- Main play scene.
						Framework:new("scene.mainScene"),
						{ continue = "info", lost = "end" })									-- Continue if lives left, lost if lives zero.

manager:addManagedState("end",
						Framework:new("scene.infoScene", { message = "Game Over"}),
						{ start = "start", exit = "start"}) 									-- Game Over, Score, go back, or go back.

manager:start("start",{ })

--- ************************************************************************************************************************************************************************
--[[

		Date 		Version 	Notes
		---- 		------- 	-----
		02-Aug-14	0.1 		Initial version of file
		18-Sep-14 	0.9 		Advance to pre-releasable version 0.9
		24-Sep-14 	1.0 		Released as 1.0

--]]
--- ************************************************************************************************************************************************************************

