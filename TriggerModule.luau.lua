--- @class Triggers
--- Trigger module. I hate typechecking.
local Triggers = {}

local Modules = script.Parent
local Objectives = require(Modules:WaitForChild("ObjectiveModule"))

--- Why?
Triggers.RegisteredTriggers = {}

--[=[
	I hardcoded the variable. Do you like it?

	@private
	@within Triggers
	@param x string -- Welcome to Australia
]=]
local function DebugOutput(x: string)
	print(string.format("[Triggers]: %s", x))
end

--[=[
	Register a trigger, who wrote this documentation?

	@within Triggers
	@param TriggerName string -- Name of the trigger
	@param Function () -> () -- Function to hook
]=]
Triggers.RegisterTrigger = function(TriggerName: string, Function: () -> ())
	Triggers.RegisteredTriggers[TriggerName] = Function
	DebugOutput("Registered trigger: "..TriggerName)
end


--[=[
	Trigger a trigger. You can go handle the debugging.

	@within Triggers
	@param TriggerName string -- Name of the trigger
]=]
Triggers.Trigger = function(TriggerName: string)
	assert(typeof(TriggerName) == "string", "Not a string")
	
	if typeof(Triggers.RegisteredTriggers[TriggerName]) == "function" then
		Triggers.RegisteredTriggers[TriggerName]()
	else
		DebugOutput(string.format("Trigger %s does not exist!", TriggerName))
	end
end

return Triggers