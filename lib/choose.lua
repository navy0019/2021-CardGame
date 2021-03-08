local TableFunc = require("lib.tableFunc")
local Motion = require("lib.motion")
local Curve = require('lib.curve')

local function CurveColor(self,mx,my)

end
local function AddChoose(self,obj)
	if #self.choose < self.max then
		table.insert(self.choose,obj)
	end
end
local function CheckRule(self)
	if self.numberRule then
		if  #self.choose == max then
			return true
		else
			return false
		end
	end
	return true
end
local function CheckEmpty(self)
	if #self.choose <  self.max then
		return true
	end
	return false
end  
local function RingAdd(self,obj)
	table.remove(self.choose,#self.choose)
	table.insert(self.choose,obj)
end


local function Clear( self )
	self.choose={}
	self.target={race=false,instance=nil}
end
local function OnClick( self,mx,my)

end
local function OnHold( self,mx,my ,characterData)
	if #self.choose >0 and self.choose[1].isLock==false  then
		local card = self.choose[1]
		local sprite = card.sprite.transform
		local x,y = card.sprite.transform.position.x , card.sprite.transform.position.y

		local p = TableFunc.find(card.parentTab,card)
		if p ~= #card.parentTab then card:MoveDrawOrder(#card.parentTab) end--讓被選中的最後繪製

		card.motionMachine:TransitionTo('OnHold')

		if my > 500 then
			self.curve=nil
		else
			--make curve
			local pos = {x ,y-card.height+8 ,x+(mx-x)*0.3 , my-30, x+(mx-x)*0.6 , my-40,mx,my}
			self.curve = Curve.new(pos,8)
			self.target = card:CheckTargetRace(mx,my,characterData)
			if self.target.race == 'hero'  then self.curve.color = {0,1,0,1}
			elseif self.target.race == 'enemy'  then self.curve.color = {1,0,0,1}
			else self.curve.color = {0.5 ,0.5 ,0.5,1} end

		end
	end
end

local function OnRelease( self )
	if #self.choose >0 then
		local card = self.choose[1]
		if self.target.race == card.effectOn and card.battle.battleData.actPoint >= card.cost then
			if card.motionMachine.current.name~= "Use" then
				card.motionMachine:TransitionTo("Use",card)
			end
			card.battle.signal:emit('Act',card.master,card)
			card:Effect(self.target.instance)			
			card.battle.battleData.actPoint=card.battle.battleData.actPoint-card.cost
			card.battle:DropCard(card.battle.battleData.hand ,card)
		else
			
			local p = TableFunc.find(card.parentTab,card)
			if p ~= card.handPos then card:MoveDrawOrder(card.handPos) end
			card.motionMachine:TransitionTo("ReleaseBack",card)
			sprite = card.sprite.transform
			local x,y = card.sprite.transform.position.x , card.sprite.transform.position.y

		end
		self.onHold = false
		self.curve=nil
		self:Clear() 
	end
end
local Choose={}
Choose.default={Clear=Clear,AddChoose=AddChoose,CheckRule=CheckRule,CheckEmpty=CheckEmpty,
RingAdd=RingAdd,OnClick=OnClick,OnHold=OnHold,OnRelease=OnRelease}
Choose.metatable={}

function Choose.new(max,rule)
	local max ,rule = max or 1 , rule or true
	local o = {choose={},max=max,numberRule=rule,onHold=false,curve=nil,target={race=false,instance=nil}}

	setmetatable(o,Choose.metatable)
	return o
end
Choose.metatable.__index=function (table,key) return Choose.default[key] end

return Choose