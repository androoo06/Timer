# Timer
timer class in lua

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
