--[=[
	@class CutsceneModule
	
	Simple Cutscene module that is character based and modular
	© 2025 Shellworks Development
	Licensed under MIT
]=]

local CutsceneModule = {}
local RunService = game:GetService("RunService")
local UtilTypes = require(script.UtilTypes)

--- Not really necessary to document, gonna leave it to you
type ActorR6 = {
	Character: UtilTypes.CharacterR6,
	Animation: Animation
}

--- Not really necessary to document, gonna leave it to you
type ActorR15 = {
	Character: UtilTypes.CharacterR15,
	Animation: Animation
}

--[=[
	Union for Actors

	@type Actor | CharacterR6 | Animation | CharacterR15
	@within CutsceneModule
]=]
type Actor = ActorR6 | ActorR15

--[=[
	Abstract for Cutscene camears

	@type CutsceneCamera BasePart | Animation | Animator
	@within CutsceneModule
]=]
type CutsceneCamera = {
	CameraPart: BasePart,
	CameraAnimation: Animation,
	Animator: Animator
}

--[=[
	Handles cutscene management, and stops it if necessary

	@type CutsceneHandler Cutscene | (self) -> ()
	@within CutsceneModule
]=]
export type CutsceneHandler = {
	ActiveTracks: {AnimationTrack},
	CutsceneOrigin: Cutscene,
	Stop: (self: CutsceneHandler) -> ()
}

--[=[
	Abstract for all cutscenes
	What a joke

	@type Cutscene boolean | ((Cutscene) -> ())? | ((Cutscene) -> ())? | {Actor} | CutsceneCamera | (Cutscene) -> (CutsceneHandler)
	@within CutsceneModule
]=]
export type Cutscene = {
	CutsceneRunning: boolean,
	StartHook: ((self: Cutscene) -> ())?,
	EndHook: ((self: Cutscene) -> ())?,
	CutsceneActors: { Actor },
	CutsceneCamera: CutsceneCamera,
	Start: (self: Cutscene) -> CutsceneHandler
}

--[=[
	Defines an Actor. I actually don't know why I... okay whatever.
	Also.... I HATE Moonwave.
	
	@within CutsceneModule
	@param Character Model
	@param Animation Animation
	@return Actor
]=]
function CutsceneModule:DefineActor(Character: UtilTypes.CharacterR6 | UtilTypes.CharacterR15, Animation: Animation): Actor
	local Actor: Actor = {
		Character = Character,
		Animation = Animation,
	}
	
	return Actor
end

--[=[
	Defines a Camera. I actually don't know why I... okay whatever.
	
	@within CutsceneModule
	@param CameraPart BasePart
	@param Animation Animation
	@return CutsceneCamera
]=]
function CutsceneModule:DefineCamera(CameraPart: BasePart, Animation: Animation, Animator: Animator): CutsceneCamera
	local Camera: CutsceneCamera = {
		CameraPart = CameraPart,
		CameraAnimation = Animation,
		Animator = Animator,
	}
	
	return Camera
end

--[=[
	Ends a cutscene with self. Not a method because "typechecking"
	
	@within CutsceneModule
	@private
	@param self CutsceneHandler
]=]
function CutsceneModule.Stop(self: CutsceneHandler)
	print("Stopped cutscene")
	self.CutsceneOrigin.CutsceneRunning = false
end

--[=[
	Starts a cutscene, with self. Shouldn't be used standalone.
	We use a function instead of a method because of typechecking.
	
	Please beware that is function is poorly written and you should not modify it
	unless you are aware of the consequences of caffiene conmsumption.
	It is also heavily unoptimized. Reap the consequences.
	
	@within CutsceneModule
	@private
	@param self Cutscene
	@return CutsceneHandler
]=]
function CutsceneModule.Start(self: Cutscene): CutsceneHandler
	--- StartHook exists, run StartHook as it is priority
	if self.StartHook then
		self.StartHook(self)
	end
	
	--- Init the variables
	local CurrentCamera = workspace.CurrentCamera
	local OriginalCameraType = CurrentCamera.CameraType
	local CameraAnimator = self.CutsceneCamera.Animator
	local CutsceneTracks = {}
	
	if OriginalCameraType ~= Enum.CameraType.Scriptable then
		CurrentCamera.CameraType = Enum.CameraType.Scriptable
	end
	
	for _, Actor in self.CutsceneActors do
		--- Theoretically, there will be an animator since that is the standard with Roblox
		--- If not, don't insert the track for that actor
		
		local Animator = Actor.Character.Humanoid:FindFirstChildWhichIsA("Animator")
		
		if Animator then
			table.insert(CutsceneTracks, Animator:LoadAnimation(Actor.Animation))
		else
			warn(script.Name..": No Animator in "..Actor.Character:GetFullName()..", ensure that there is an Animator inside Humanoid and that it is not getting destroyed!")
		end
	end
	
	local CameraTrack = CameraAnimator:LoadAnimation(self.CutsceneCamera.CameraAnimation)
	table.insert(CutsceneTracks, CameraTrack)
	
	self.CutsceneRunning = true
	
	task.spawn(function()
		for _, AnimationTrack in CutsceneTracks do
			AnimationTrack:Play()
		end
	end)
	
	RunService:BindToRenderStep("CutsceneRun", Enum.RenderPriority.Camera.Value, function()
		CurrentCamera.CFrame = self.CutsceneCamera.CameraPart.CFrame
	end)
	
	task.spawn(function()
		while task.wait() do
			if not self.CutsceneRunning then
				for _, AnimationTrack in CutsceneTracks do
					AnimationTrack:Stop()
					AnimationTrack:Destroy()
				end
				RunService:UnbindFromRenderStep("CutsceneRun")
				CameraTrack:Stop()
				CameraTrack:Destroy()
				CurrentCamera.CameraType = OriginalCameraType
				--- If EndHook exists, run endhook
				if self.EndHook then
					self.EndHook(self)
				end
			end
		end
	end)
	
	task.spawn(function()
		CameraTrack.Ended:Connect(function()
			self.CutsceneRunning = false
			print("Cutscene ended")
		end)
	end)
	
	local CutsceneHandler: CutsceneHandler = {
		CutsceneOrigin = self,
		ActiveTracks = CutsceneTracks,
		Stop = nil --- Assign stop later, because "typechecking"
	}
	
	--- Actually assign stop
	CutsceneHandler.Stop = function()
		CutsceneModule.Stop(CutsceneHandler)
	end
	
	return CutsceneHandler
end

--[=[
	Creates a cutscene. Takes a lot of arguments but StartHook and EndHook are optional.
	Please do not try to comprehend.
	
	@within CutsceneModule
	@param CutsceneCamera
	@return CutsceneHandler
]=]
function CutsceneModule.DefineCutscene(CutsceneCamera: CutsceneCamera, CutsceneActors: {Actor}, StartHook: ((Cutscene) -> ())?, EndHook: ((Cutscene) -> ())?)
	local Cutscene: Cutscene = {
		CutsceneRunning = false,
		StartHook = StartHook,
		EndHook = EndHook,
		CutsceneActors = CutsceneActors,
		CutsceneCamera = CutsceneCamera,
		Start = nil --- Assign later, because "typechecking"
	}
	
	--- Actually assign start (catch my drift?)
	Cutscene.Start = function()
		CutsceneModule.Start(Cutscene)
	end
	
	return Cutscene
end