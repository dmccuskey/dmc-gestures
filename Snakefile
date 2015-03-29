# dmc-gestures

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "dmc-gestures"
	include: "../DMC-Corona-Library/snakemake/Snakefile"

module_config = {
	"name": "dmc-gestures",
	"module": {
		"dir": "dmc_corona",
		"files": [
			"dmc_gestures.lua",
			"dmc_gestures/core/gesture.lua",
			"dmc_gestures/core/continuous_gesture.lua",
			"dmc_gestures/gesture_constants.lua",
			"dmc_gestures/gesture_manager.lua",
			"dmc_gestures/longpress_gesture.lua",
			"dmc_gestures/pan_gesture.lua",
			"dmc_gestures/pinch_gesture.lua",
			#"dmc_gestures/swipe_gesture.lua",
			"dmc_gestures/tap_gesture.lua",
		],
		"requires": [
			"dmc-corona-boot",
			"DMC-Lua-Library",
			"dmc-objects",
			"dmc-utils",
			"dmc-touchmanager"
		]
	},
	"examples": {
		"base_dir": "examples",
		"apps": [
			{
				"exp_dir": "gesture-longpress-basic",
				"requires": []
			},
			{
				"exp_dir": "gesture-multigesture-basic",
				"requires": []
			},
			{
				"exp_dir": "gesture-pan-basic",
				"requires": []
			},
			{
				"exp_dir": "gesture-pan-move",
				"requires": []
			},
			{
				"exp_dir": "gesture-pinch-basic",
				"requires": []
			},
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

register( "dmc-gestures", module_config )

