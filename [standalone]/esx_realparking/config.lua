--[[ ===================================================== ]]--
--[[         FiveM Real Parking Script by Akkariin         ]]--
--[[ ===================================================== ]]--

Config = {}

-- If you are using ESX 1.2.0 or higher please leave this to false
Config.UsingOldESX = false     		 

-- locale
Config.Locale = 'fr' 									

-- The key to save the car, default key is "E" (horn)
Config.KeyToSave = 86

-- Enable debug mode
Config.debug = true

-- Parking locations
Config.ParkingLocations = {
	parking1 = {
		x      = -327.73,                               -- Central location X, Y, Z of the parking
		y      = -934.12,                               -- Y
		z      = 31.08,                                 -- Z
		size   = 50.0,                                  -- The parking range radius (Horizontal), set to 10000.0 then you can parking anywhere
		height = 10.0,                                  -- The parking range radius (Vertical)
		name   = "Parking public",                      -- The name of the parking (blips)
		fee    = 100,                                  -- How much parking fee per day (Real life time), set 0 or false to disable
		enter  = {x = -279.25, y = -890.39, z = 30.08}, -- The entrance of the parking
		maxcar = 1000,									-- Max vehicles can save on this parking
		notify = true,									-- Display the "Press E to save" notification, set to false can disable it
	},
	parking2 = {
		x      = -340.03,
		y      = 285.19,
		z      = 84.77,
		size   = 15.0,
		height = 10.0,
		name   = "Parking public",
		fee    = 0,
		enter  = {x = -338.57, y = 267.16, z = 85.73},
		maxcar = 15,
		notify = true,
	},
	parking3 = {
		x      = 446.98,
		y      = 246.07,
		z      = 103.86,
		size   = 25.0,
		height = 10.0,
		name   = "Parking public",
		fee    = 800,
		enter  = {x = 467.96, y = 265.07, z = 103.09},
		maxcar = 20,
		notify = true,
	},
	parking4 = {
		x      = 374.35,
		y      = 279.49,
		z      = 103.32,
		size   = 20.0,
		height = 10.0,
		name   = "Parking public",
		fee    = 700,
		enter  = {x = 364.77, y = 298.98, z = 103.5},
		maxcar = 15,
		notify = true,
	},
	parking5 = {
		x 		= -310.3913,
		y 		= -756.3561,
		z 		= 33.8185,
		size 	= 38.0,
		height 	= 30.0,
		name   = "Parking public",
		fee    = 700,
		enter  = {x = -347.3168, y = -820.6603, z = 31.5395},
		maxcar = 100,
		notify = true,
		},
	parking6 = {
		x 		= 237.4224,
		y		= -781.0746,
		z 		= 30.6491,
		size 	= 35,
		height 	= 10,
		name	= "parking central",
		fee		= 100,
		enter	= {x = 213.7355, y = -808.9179, z = 31.0149},
		maxcar = 30,
		notify = true,

	},
	parking7= {
		x = -739.5861,
		y = -68.6738,
		z = 41.7501,
		size = 17,
		height = 10,
		name	= "parking central",
		fee = 100,
		enter = {x = -732.5565, y = -55.9749, z = 41.7540},
		maxcar = 100,
		notify = true,
	},
}
