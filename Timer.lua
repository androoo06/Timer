-- Timer class by Shaggward

--[[

This clock can be used for counting up or down, can switch directions mid-count, and
allows for custom value formatting (appropriately using "%.Xf")

Other functionalities include:
* custom increment value
* timer.Changed & timer.Ended events
* multiple method aliases

Basic use cases:
* countdown gameclocks
* regeneration / ability duration timer
* timeout clock
* any other reason to use a clock lol

API: 

-- Constructor -- 
Timer.new(StartValue, EndValue, IncrementValue, DisableEvents, Format) :Timer
* creates a new timer instance with given parameters
* all parameters optional (defaults: 60, 0, 1, false, "%.1f")

-- Setters -- 
Timer:SetStartValue(value)
Timer:SetEndValue(value)
Timer:SetIncrement(value)
Timer:SetDirection(value)
	- accepts timer Enum's direction. Ex:
	  myTimer:SetDirection(Timer.Directions.UP)
Timer:SetFormat(value)
    - recommended to keep the string format of ("%.Xf") Ex:
      myTimer:SetFormat("%.2f")

-- Getters -- 
Timer:GetValue() -> returns the current value
Timer:GetState() -> returns the state of the timer

-- Methods -- 
Timer:Start() :Void -- Aliased with Timer:Play()
* starts a timer from StartValue to EndValue using IncrementValue
	- Direction is predetermined by Start&End Values

Timer:Resume() :Void -- Aliased with Timer:Unpause()
* starts a timer from the CurrentValue to EndValue

Timer:Stop() :Void -- Aliased with Timer:Pause()
* stops the timer's countdown, preserves the CurrentValue

Timer:Destroy() :Void
* destroys and cleans up the timer (no re-use after this)

-- Events --

Timer.Changed
* fires when the current value or state changes on a timer
* params = {[Number] CurrentValue, [TimerState] State}
  ex:
	myTimer.Changed:Connect(function(val,state)
		print("clock has a current value of",val,"and its running state is",(state==Timer.States.ON))
	end)

Timer.Ended
* fires when Timer:End() or Timer:Destroy() are used, or when the timer's value reaches
  or exceeds a bound (whether it be upper or lower bound)
* params = {}  
  ex:
	myTimer.Ended:Connect(function()
		print("my timer ended!")
	end)
]]

local function resetConnections(connection)
	if (connection) then
		connection:Disconnect()
		connection = nil
	end
end

local function getDirection(origin,target)
	return (if (target>origin) then -1 else 1)
end

local function inBetween(c,s,e)
	-- c = current, s = start, e = end, d = direction
	local d = getDirection(s,e)
	if (d == 1) then
		return ((c<s) and (c>e))
	else
		return ((c>s) and (c<e))
	end
end

local Timer = {}
Timer.__index = Timer

Timer.States = {
	OFF = 0;
	ON  = 1;
}

Timer.Directions = {
	UP = -1;
	DOWN = 1;
}

function Timer.new(StartValue,EndValue,Increment,DisableEvents,Format)
	assert(StartValue~=EndValue,"StartValue cannot equal EndValue")
	
	local self = setmetatable({},Timer)
	self.State = self.States.OFF
	self.Direction = getDirection(StartValue,EndValue)
	if not (DisableEvents) then
		self.ChangedBindable = Instance.new("BindableEvent")
		self.EndedBindable = Instance.new("BindableEvent")
		self.Changed = self.ChangedBindable.Event -- newTimer.Changed:Connect(func)
		self.Ended   = self.EndedBindable.Event
	end
	self.Runtime = Instance.new("BindableEvent")
	self.Listener = nil
	self.StartValue = (StartValue) or 60
	self.EndValue = (EndValue) or 0
	self.CurrentValue = self.StartValue
	self.Increment = math.max(0.1,(Increment or 1))
	self.Destroyed = false
	self.EventsEnabled = not DisableEvents
	self.Format = Format or "%.1f"
	self.KEY = 0
		
	return self
end

function Timer:SetStartValue(val)
	self.StartValue = val
end

function Timer:SetEndValue(val)
	self.EndValue = val
end

function Timer:SetIncrement(val)
	self.Increment = val
end

function Timer:SetDirection(val)
	if not (val == self.Direction) then
		self.Direction = val
		-- swapping the two values so the timer keeps the bounds but goes
		-- in the opposite direction
		local temp = self.StartValue
		self.StartValue = self.EndValue
		self.EndValue = temp
	end
end

function Timer:SetFormat(val)
	self.Format = val
end

function Timer:GetState()
	print(self.State)
	return self.State
end

function Timer:GetValue()
	return self.CurrentValue
end

-- @Alias Timer:Play()
function Timer:Start(resume)
	if not (resume) then
		self.CurrentValue = self.StartValue
	end
	self.State = self.States.ON
	self:LifeCycle()
	self.Runtime:Fire(self.KEY)
end

-- @Alias Timer:Unpause()
function Timer:Resume()
	self:Start((self.CurrentValue>0))
end

-- @Alias Timer:Pause()
function Timer:Stop()
	self.State = self.States.OFF
	self.KEY += 1
	self:Change(true) -- state only
end

function Timer:End()
	self:Stop()
	self.CurrentValue = self.EndValue
	if (self.EventsEnabled) then
		self.EndedBindable:Fire()
	end
end

function Timer:Destroy()
	self:End()
	self.Destroyed = true
	if (self.EventsEnabled) then
		self.ChangedBindable:Destroy()
		self.EndedBindable:Destroy()
	end
	self.Runtime:Destroy()
	for _,item in pairs(self) do
		item = nil
	end
	self = nil
end

-- "PRIVATE" METHODS
function Timer:Change(StateOnly)
	if not (StateOnly) then
		local newVal = self.CurrentValue-(self.Increment*self.Direction)
		if (self.Direction == self.Directions.UP) then
			newVal = math.min(newVal,self.EndValue) 
		else 
			newVal = math.max(newVal,self.EndValue)	
		end
		self.CurrentValue = newVal
		self.CurrentValue = tonumber(string.format(self.Format,tostring(self.CurrentValue)))
	end
	if (self.EventsEnabled) then
		self.ChangedBindable:Fire(self.CurrentValue,self.State)
	end
end

function Timer:LifeCycle()
	self.KEY += 1
	resetConnections(self.Listener)
	self.Listener = self.Runtime.Event:Connect(function(key)
		if not (key == self.KEY) then return end
		self:Change()
		local c,s,e = self.CurrentValue,self.StartValue,self.EndValue
		if not inBetween(c,s,e) then
			self.CurrentValue = self.EndValue
			self:End()
		end
		task.wait(self.Increment)
		if (self.State == self.States.ON) then
			self.Runtime:Fire(key)
		end	
	end)
end

-- ALIASES
Timer.Play    = Timer.Start
Timer.Pause   = Timer.Stop
Timer.Unpause = Timer.Resume

return Timer
