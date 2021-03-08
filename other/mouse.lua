local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local Nothing = State.new("Nothing")
local OnClick = State.new("OnClick")
local OnHold  = State.new("OnHold")
local OnRelease = State.new("OnRelease")

local mouse=Machine.new({
	initial=Nothing,
	states={
		Nothing ,OnClick ,OnHold ,OnRelease
	},
	events={
		{state=Nothing,to='OnClick'},
		{state=Nothing,to='OnHold'},
		{state=OnClick,to='Nothing'},
		{state=OnClick,to='OnHold'},
		{state=OnHold,to='OnRelease'},
		{state=OnRelease,to='Nothing'},

	}
})

Nothing.CheckCondition=function(mx,my,leftClick,preClick)
	if preClick == false and leftClick == true then
		mouse:TransitionTo('OnClick')
	elseif preClick == true and leftClick == true then
		mouse:TransitionTo('OnHold')
	elseif	preClick == true and leftClick == false then
	elseif	preClick == false and leftClick == false then
	end
end
Nothing.Do=function(self,mx,my,leftClick,preClick) self.CheckCondition(mx,my,leftClick,preClick) end

OnClick.Do=function(self) mouse:TransitionTo('Nothing') end

OnHold.CheckCondition=function(mx,my,leftClick,preClick) 
	if	preClick == false and leftClick == false then 
		mouse:TransitionTo('OnRelease')
	end 
end
OnHold.Do=function(self,mx,my,leftClick,preClick) self.CheckCondition(mx,my,leftClick,preClick) end

OnRelease.Do=function(self) mouse:TransitionTo('Nothing') end

return mouse
