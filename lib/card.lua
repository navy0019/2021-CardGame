local Character = require('lib.character')
local Choose = require("lib.choose")
local TableFunc = require("lib.tableFunc")
local Motion = require("lib.motion")
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local cardMotionMachine = {}
function cardMotionMachine.new()
	local Empty=State.new("Empty")
	local OnHold=State.new("OnHold")
	local ReleaseBack=State.new("ReleaseBack")
	local Use=State.new("Use")
	local Drop=State.new("Drop")
	local Deal=State.new("Deal")
	local machine= Machine.new({
		initial=Empty,
		states={Empty ,OnHold ,ReleaseBack ,Use ,Drop ,Deal },
		events={
			--[[		 Empty
						/   | \   
					   /    |  \    
					OnHold  |  Deal
					/   |	|    |
				   /    |	|  Empty
			ReleaseBack Use |
			/	|		|   |
		OnHold	Empty	Drop
					    |
					  Empty
			]]
			{state=Empty,to='Deal'},
			{state=Deal,to='Empty'},

			{state=Empty,to='Drop'},

			{state=Empty,to='OnHold'},
			{state=OnHold,to='ReleaseBack'},
			{state=OnHold,to='OnHold'},
			{state=ReleaseBack,to='Empty'},
			{state=ReleaseBack,to='OnHold'},

			{state=OnHold,to='Use'},
			{state=Use,to='Drop'},
			{state=Drop,to='Empty'}
		}
	})
	Empty.DoOnEnter=function(self,dt,card)

	end
	OnHold.Do=function(self,dt,card)
		local mx,my = love.mouse.getPosition()
		local sprite = card.sprite.transform
		local x,y = card.sprite.transform.position.x , card.sprite.transform.position.y

		if my > 500 then
			card.motion={}
			card.sprite.transform.position.x=mx
			card.sprite.transform.position.y=math.max(my,630)+card.height/2
		elseif  (x ~= 713 or y ~= 650+card.height/2) and #card.motion==0  then
			Motion.NewTable(card.motion,Motion.new({0, x ,    713          , 0.5},'outQuint',function(self,dt)sprite.position.x= Motion.Lerp(self,dt)end))
			Motion.NewTable(card.motion,Motion.new({0, y ,650+card.height/2, 0.5},'outQuint',function(self,dt)sprite.position.y= Motion.Lerp(self,dt)end)) 
		end

		
	end
	ReleaseBack.DoOnEnter=function(self,card)
		local sprite = card.sprite.transform
		local x,y = card.sprite.transform.position.x , card.sprite.transform.position.y
		card.motion={}
		Motion.NewTable(card.motion,Motion.new({0, x ,sprite.originPosition.x , 0.5},'outQuint',function(self,dt)sprite.position.x= Motion.Lerp(self,dt) end))
		Motion.NewTable(card.motion,Motion.new({0, y ,sprite.originPosition.y , 0.5},'outQuint',function(self,dt)sprite.position.y= Motion.Lerp(self,dt) end))
	end
	ReleaseBack.Do=function(self,dt,card)
		self.waitTime=0.5
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0
			machine:TransitionTo('Empty',dt,card)
		end
		
	end
	Use.DoOnEnter=function(self,card)
		card.motion={}
		local sprite = card.sprite.transform
		if card.motionType=="hit" then		
			card.sprite.transform.position.x=550
			card.sprite.transform.position.y=550
			local x = card.sprite.transform.position.x
			Motion.NewTable(card.motion,Motion.new({0, 550 ,750 , 0.5},'outQuint',function(self,dt)sprite.position.x= Motion.Lerp(self,dt) end))
		elseif card.motionType=="heal" then
			card.sprite.transform.position.x=876
			card.sprite.transform.position.y=550
			local x = card.sprite.transform.position.x
			Motion.NewTable(card.motion,Motion.new({0, 876 ,676 , 0.5},'outQuint',function(self,dt)sprite.position.x= Motion.Lerp(self,dt) end))
		elseif card.motionType=="scale" then
			card.sprite.transform.position.x=713
			card.sprite.transform.position.y=350
			local w,h = card.width,card.height
			card.sprite.transform.offset={x=w/2 ,y=h/2}
			local x,y = card.sprite.transform.scale.x , card.sprite.transform.scale.y
			Motion.NewTable(card.motion,Motion.new({0, x ,1.3 , 0.5},'outQuint',function(self,dt)sprite.scale.x= Motion.Lerp(self,dt) sprite.scale.y=sprite.scale.x end))
		end
	end
	Use.Do=function(self,dt,card)
		self.waitTime=0.5
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			card.sprite.transform.scale.x=1
			card.sprite.transform.scale.y=1
			self.currentTime=0
			machine:TransitionTo('Drop',card)
		end
	end
	Drop.DoOnEnter=function(self,card)
		local xmotion = Motion.new({0,card.sprite.transform.position.x,1300,0.5},'outQuint' ,function(self,dt)card.sprite.transform.position.x = Motion.Lerp(self,dt)end)
		local ymotion = Motion.new({0,card.sprite.transform.position.y,750 ,0.5},'outQuint' ,function(self,dt)card.sprite.transform.position.y = Motion.Lerp(self,dt)end)
		local scalemotion = Motion.new({0,card.sprite.transform.scale.x ,0 ,0.4},'outQuint' ,function(self,dt)card.sprite.transform.scale.x = Motion.Lerp(self,dt) card.sprite.transform.scale.y=card.sprite.transform.scale.x end)
		Motion.NewTable(card.motion , xmotion )
		Motion.NewTable(card.motion , ymotion )
		Motion.NewTable(card.motion , scalemotion)
	end
	Drop.Do=function(self,dt,card)
		self.waitTime=0.5
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0
			machine:TransitionTo('Empty',dt,card)
		end
	end
	Deal.DoOnEnter=function(self,card,x)
		--card:Lock()
		card.sprite.transform.position.x = 100 
		card.sprite.transform.position.y = 750
		card.sprite.transform.scale.x = 0 
		card.sprite.transform.scale.y = 0

		--card.color={0.5,0.5,0.5,1}
		card.sprite.transform.originPosition={x=x,y=914}

		local xmotion = Motion.new({0,card.sprite.transform.position.x, x  , 0.5} ,'outCubic' ,function(self,dt)card.sprite.transform.position.x= Motion.Lerp(self,dt)  end )
		local ymotion = Motion.new({0,card.sprite.transform.position.y, 914, 0.5} ,'outCubic' ,function(self,dt)card.sprite.transform.position.y= Motion.Lerp(self,dt)  end )
		local scalemotion = Motion.new({0,card.sprite.transform.scale.x   , 1  , 0.3} ,'outCubic' ,function(self,dt)card.sprite.transform.scale.x = Motion.Lerp(self,dt) card.sprite.transform.scale.y=card.sprite.transform.scale.x card.color[4]=card.sprite.transform.scale.x end )
		--local colormotion = Motion.new({0,card.color[1]   , 1  , 0.7},'inQuint' ,function(self,dt)card.color[1] = Motion.Lerp(self,dt) card.color[2]=card.color[1] card.color[3]=card.color[1] end )
		Motion.NewTable(card.motion , xmotion )
		Motion.NewTable(card.motion , ymotion )
		Motion.NewTable(card.motion , scalemotion)
		--QueueMgr.NewTable(card.motion , colormotion)
	end
	Deal.Do=function(self,dt,card)
		self.waitTime=0.4
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0
			machine:TransitionTo('Empty',dt,card)
			--card:Unlock()
		end
	end
	return machine
end


local Card={}
local function FindInfoPos( card )
	local pos = {}
	for k,v in pairs(card.updateWord) do
		table.insert(pos,v[2]+(k-1)*2+1)
	end
	return pos
end 
local function Update(card)
	local p=FindInfoPos(card)
	for k,v in pairs(p) do
		card.info[v]=card.updateWord[k][1].string(card)
	end
end
local function Check( target,mouseX,mouseY)
	if  mouseX >= target.sprite.transform.position.x-target.sprite.transform.offset.x and mouseX <= target.sprite.transform.position.x + target.width -target.sprite.transform.offset.x  and 
		mouseY >= target.sprite.transform.position.y-target.sprite.transform.offset.y and mouseY <= target.sprite.transform.position.y + target.height -target.sprite.transform.offset.y  then
			return true
		else
			return false
		end
end
local function LockSwitch( self)
	if self.isLock then
		self.isLock=false
	else
		self.isLock=true
	end
end
local function Lock( self)
	self.isLock=true
	self.color={0.5,0.5,0.5,1}
end
local function Unlock( self)
	self.isLock=false
	self.color={1,1,1,1}
end
local function OnClick(self)
end
local function OnHold(self,mx,my,choose)
	choose:AddChoose(self)

end

local function MoveDrawOrder(self,num)
	local p = TableFunc.find(self.parentTab,self)
	table.remove(self.parentTab,p)
	table.insert(self.parentTab,num,self)
end
local function CheckTargetRace(self,mx,my,characterData)
	local heroData = characterData.heroData
	local monsterData = characterData.monsterData
	local result = {race=false,instance=nil}
	for k,v in pairs(heroData) do
		if self.Check(v,mx,my) and v.state.current.name~='Death' and self.battle.battleData.actPoint >= self.cost then
			if self.targetNum <=1 then 
				result = {race=v.race,instance=v}
			else 
				result = {race=v.race,instance=heroData}  
			end 
		end
	end
	for k,v in pairs(monsterData) do
		if self.Check(v,mx,my) and v.state.current.name~='Death' and self.battle.battleData.actPoint >= self.cost  then 
			if self.targetNum <=1 then 
				result = {race=v.race,instance=v}
			else 
				result = {race=v.race,instance=monsterData} 
			end  
		end
	end
	if result.race == self.effectOn then 
		return result 
	else
		return {race=false,instance=nil}
	end
end

Card.default={Update=Update,Lock=Lock,Unlock=Unlock,MoveDrawOrder=MoveDrawOrder,Check=Check,LockSwitch=LockSwitch,OnClick=OnClick,OnHold=OnHold,OnRelease=OnRelease,CheckTargetRace=CheckTargetRace}
Card.metatable={}
function Card.new(w,h,effectOn,targetNum,master,parentTab,Effect,name,numbering,info,battle,dropTo,cardtype,cost,motionType)
	local o = {sprite=nil,width=w,height=h,color={1,1,1,1}, effectOn=effectOn, targetNum=targetNum,
		master=master,parentTab=parentTab,handPos=1,motion={},onHold=false ,isLock=false,Effect=Effect,
		name=name,numbering=numbering,info=info,level=1,battle=battle,dropTo=dropTo,type=cardtype,cost=cost,motionType=motionType
	}
	o.motionMachine=cardMotionMachine.new()
	setmetatable(o,Card.metatable)
	return o
end

Card.metatable.__index=function (table,key) return Card.default[key] end

return Card