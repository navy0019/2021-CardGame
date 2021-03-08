local TableFunc = require("lib.tableFunc")

local function AddTransition(self,event)
	local name = event.state.name
	self.states[name].to = self.states[name].to or {}
	assert(not TableFunc.find(self.states[name].to , event.to) ,name.." already contain "..event.to)
	table.insert(self.states[name].to,event.to)
	
end
local function DelTransition(self,state,ToName)
	local name = state.name
	local p = TableFunc.find(self.states[name].to,ToName)
	if p then
		table.remove(self.states[name].to,p)
	end

end
local function TransitionTo(self,ToName,...)
	local name = self.current.name
	assert(self.states[name].to ,name.." doesn't have table ")
	assert(TableFunc.find(self.states[name].to,ToName) ,name.." can't trans to "..ToName)
	self.current:DoOnLeave(...)
	self.pre=self.current
	self.current=self.states[ToName]
	self.current:DoOnEnter(...)
end

local function Update(self,...)
	self.current:Do(...)
end
local FSMmachine={Update=Update,AddTransition=AddTransition,DelTransition=DelTransition,TransitionTo=TransitionTo}
FSMmachine.__index=FSMmachine

function FSMmachine.new(options)
	local fsm = {}
	setmetatable(fsm, FSMmachine)
	fsm.current = options.initial or 'Nothing'
	fsm.pre=nil 
	fsm.states={}
	fsm.events={}
	for k, state in pairs(options.states) do
		local name = state.name
		fsm.states[name]=state
	end
	for k, event in pairs(options.events) do
		fsm:AddTransition(event)
	end
	return fsm
end


return FSMmachine
