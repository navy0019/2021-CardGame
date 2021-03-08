local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local StatusHandle = require("lib.status")

local StatusMachine={}

local function Check(self)
	for k,v in pairs(self.tab) do
		if v.current.name=='Empty' then
			return k
		end
	end
	return false
end
local function newMachine(battle,charkey,statuskey,...)
	local Empty = State.new('Empty')
	local Wait = State.new('Wait')
	Wait.waitTime=0.2
	local SingleUpdate = State.new('SingleUpdate')
	local ForeachMachine = Machine.new({
		initial=Empty,
		states={Empty,Wait ,SingleUpdate},
		events={
			{state=Empty,to='Wait'},
			{state=Wait,to='SingleUpdate'},
			{state=Wait,to='Empty'},
			{state=SingleUpdate,to='Wait'},
			{state=SingleUpdate,to='Empty'}
		}
	})
	ForeachMachine.initData=function(battle,charkey,statuskey,...)
		ForeachMachine.battle = battle
		ForeachMachine.index = 1
		ForeachMachine.charkey=charkey
		ForeachMachine.statuskey=statuskey
		ForeachMachine.args = {...}
	end
	Empty.DoOnLeave=function()
		StatusMachine.allStatusTime=math.huge
	end
	Wait.Do=function(self,dt)
		local index = ForeachMachine.index
		local characters = ForeachMachine.battle.characterData[ForeachMachine.charkey]
		local key = ForeachMachine.statuskey
		local args = ForeachMachine.args

		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime and characters[index].state.current.name ~= 'Death' then
			self.currentTime=0
			ForeachMachine:TransitionTo('SingleUpdate')
		elseif self.currentTime >= self.waitTime and characters[index].state.current.name == 'Death' and index+1 <= #characters then
			ForeachMachine.index=index+1
			self.currentTime=0
			ForeachMachine:TransitionTo('SingleUpdate')
		elseif characters[index].state.current.name == 'Death' and index+1 > #characters then
			self.currentTime=0
			ForeachMachine:TransitionTo('Empty')
		end
	end
	SingleUpdate.DoOnEnter=function(self)
		local index = ForeachMachine.index
		local characters = ForeachMachine.battle.characterData[ForeachMachine.charkey]
		local key = ForeachMachine.statuskey
		local args = ForeachMachine.args

		local char = characters[index]
		StatusHandle.Update(char,char.data.Status[key],battle,unpack(args)) 
		if char.data.hp>0 and char.data.def>0 and key=='before' then 
			StatusHandle.Add(char,'shield',char.originData.def)
		end
		ForeachMachine.index=index+1
	end
	SingleUpdate.Do=function(self,dt)
		local index = ForeachMachine.index
		local characters = ForeachMachine.battle.characterData[ForeachMachine.charkey]
		if index <= #characters then
			ForeachMachine:TransitionTo('Wait')
		elseif index+1 > #characters then
			ForeachMachine:TransitionTo('Empty')
		end

	end
	return ForeachMachine
end
local function addUpdate(m,battle,charkey,statuskey,...)
	local p = m:Check()
	if not p then
		local machine = newMachine(battle,charkey,statuskey,...)
		table.insert(m.tab,machine)
		local len =#m.tab
		m.tab[len].initData(battle,charkey,statuskey,...)
		m.tab[len]:TransitionTo('Wait')
	else
		m.tab[p].initData(battle,charkey,statuskey,...)
		m.tab[p]:TransitionTo('Wait')
	end
	
end

local Update=function(self,...)
	for k,v in pairs(self.tab) do
		v:Update(...)
	end
end
StatusMachine.default={Check=Check,addUpdate=addUpdate,newMachine=newMachine,Update=Update}
StatusMachine.metatable={}

function StatusMachine.new( battle )
	local o = {tab={},battle=battle,allStatusTime=math.huge}
	setmetatable(o,StatusMachine.metatable)
	return o
end
StatusMachine.metatable.__index=function (table,key) return StatusMachine.default[key] end
return StatusMachine