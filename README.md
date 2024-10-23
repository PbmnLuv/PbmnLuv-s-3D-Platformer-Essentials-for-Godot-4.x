# PbmnLuv's 3D Platformer Essentials for Godot 4.x
 A project template for anyone wanting a faster and proper way of handling 3D platformer Camera and Player 
 
 This project is sample/skeleton project for anyone who wants to make a 3D Platformer in Godot 4.x with ease. All important variables and modes are able to be set on the editor through the inspector!

 HOW TO INSTALL:

    Download and unzip the file. Go to Godot 4.x and import the project file.

 
 It features:

-> Player Script:
  - Needs a reference for the Camera.
  - Basic moving scripts, with acceleration, maximum velocity, separate break speed.  
  - Control the number of possible jumps.
  -> 3 different modes for Coyote Time:
    - Zero (no coyote time)
    - Inifinite (inifinite amount of time to perform the jumps)
    - Timing (perform the jump withing the specified time in milliseconds)
  - Has a Smooth Turn toggle option!
    
-> Camera Script:
  - Needs a reference for the Player Node and Target Node.
  - Has lots of variables for controlling everything through the inspector, like the automatic sensitivity separate from the manual sensitivity, invert x toggle, invert y toggle, max camera speed, accelerations, break speed etc.
  - Has 5 different modes:
	 - Tank: fixed camera behind the player.
     - Manual: full manual camera, no automation.
	 - Automatic: full automatic camera, no manual input.
	 - Hybrid: both manual and camera inputs.
	 - Retro: retro style 3D camera movement.
  - Has 3 different jump follow types:
	 - Total: full jump follow.
	 - Percentage: follows the player height by a percentage.
	 - Zero: no jump follow at all.
  
  - Has Occlusion Detection toggle option:
	 - Enable or disable the camera to get out of bad situations where the player is occluded by some object (objects in the layer 8)

  
