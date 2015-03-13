# dmc-gesture

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "dmc-gesture"
	include: "../DMC-Corona-Library/snakemake/Snakefile"

module_config = {
	"name": "dmc-gesture",
	"module": {
		"dir": "dmc_corona",
		"files": [
			"dmc_gesture.lua",
			"dmc_gesture/core/gesture.lua",
			"dmc_gesture/core/continuous_gesture.lua",
			"dmc_gesture/core/discrete_gesture.lua",
			"dmc_gesture/gesture_manager.lua",
			"dmc_gesture/pinch_gesture.lua",
			"dmc_gesture/tap_gesture.lua",
		],
		"requires": [
			"dmc-corona-boot",
			"DMC-Lua-Library",
			"dmc-objects",
			"dmc-utils",
			#"dmc-touchmanager"
		]
	},
	"examples": {
		"base_dir": "examples",
		"apps": [
			{
				"exp_dir": "gesture-tap-basic",
				"requires": []
			}
		]
	},
	"tests": {
		"files": [],
		"requires": []
	}
}

register( "dmc-gesture", module_config )

