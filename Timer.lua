-- timer class by shaggward

-- can be used for any countdown clock, including:
-- personal throwclocks
-- gameclocks
-- team shotclocks

local function resetConnections(connection)
	if (connection) then
		connection:Disconnect()
		connection = nil
	end
end

local Timer = {}
Timer.__index = Timer

Timer.State = {
	OFF = 0;
	ON  = 1;
}

function Timer.new(StartValue,Increment)
	local self = setmetatable({},Timer)
	self.OwnState = self.State.OFF
	self.ChangedBindable = Instance.new("BindableEvent")
	self.EndedBindable = Instance.new("BindableEvent")
	self.Runtime = Instance.new("BindableEvent")
	self.Listener = nil
	self.Changed = self.ChangedBindable.Event -- newTimer.Changed:Connect(func)
	self.Ended   = self.EndedBindable.Event
	self.StartValue = (StartValue) or 60
	self.CurrentValue = self.StartValue
	self.Increment = math.max(0.1,(Increment or 1))
	self.Destroyed = false
	self.KEY = 0
	return self
end

function Timer:LifeCycle()
	self.KEY += 1
	resetConnections(self.Listener)
	self.Listener = self.Runtime.Event:Connect(function(key)
		if not (key == self.KEY) then return end
		self.CurrentValue = math.max(self.CurrentValue-self.Increment,0)
		self.CurrentValue = tonumber(string.format("%.1f",tostring(self.CurrentValue)))
		self.ChangedBindable:Fire(self.CurrentValue,"On")
		if (self.CurrentValue <= 0) then
			self:Stop()
			self.CurrentValue = 0
			self.EndedBindable:Fire()
		end
		task.wait(self.Increment)
		if (self.OwnState == self.State.ON) then	
			self.Runtime:Fire(key)
		end	
	end)
end

function Timer:SetStartValue(val)
	self.StartValue = val
end

function Timer:SetIncrement(val)
	self.Increment = val
end

function Timer:Start(resume)
	if not (resume) then
		self.CurrentValue = self.StartValue
	end
	self.OwnState = self.State.ON
	self:LifeCycle()
	self.Runtime:Fire(self.KEY)
end

function Timer:Resume()
	self:Start((self.CurrentValue>0))
end

function Timer:Stop()
	self.OwnState = self.State.OFF
	self.KEY += 1
end

function Timer:End()
	self:Stop()
	self.CurrentValue = 0
	self.EndedBindable:Fire()
end

function Timer:Destroy()
	self.Destroyed = true
	self.ChangedBindable:Destroy()
	self.EndedBindable:Destroy()
	for _,item in pairs(self) do
		item = nil
	end
	self = nil
end

return Timer
