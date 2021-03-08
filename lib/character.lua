local Signal = require("lib.hump.signal")
local Motion = require("lib.motion")
local Word = require("lib.word")
local StatusHandle = require("lib.status")
local SceneMgr = require('lib.sceneManager')
local TableFunc = require('lib.tableFunc')

local MonsterSkill = require('battle.mSkill')
local MonsterAI = require('battle.monsterAI')

local function clamp(v, minValue, maxValue)  
    if v < minValue then
        return minValue
    end
    if( v > maxValue) then
        return maxValue
    end
    return v 
end
local function GetHit( self , value ,ignoreDef,hasMotion,battle)	
	self.signal:emit('GetHit',self,value,ignoreDef,hasMotion,battle)
	battle.signal:emit('CheckLife')
end

local function DoAct(self,battle)
	self:DecideAct(battle.characterData.heroData)
	if self.act then
		local m ,target ,key = self, self.act.target ,self.act.key
		MonsterSkill[key].func(self,target,battle)

		local cx =self.sprite.transform.position.x
		Motion.NewTable(self.motion , Motion.new({0 ,cx ,cx+40*self.xDir ,0.4},'outCubic' ,function(motion,dt) m.sprite.transform.position.x  = Motion.Mirror(motion,dt)end))
	end
end 
local function DecideAct( self ,charData)
	local ran = _G.rng:random(#self.skill)
	local index = 1
	while charData[index].state.current.name == 'Death' do
		if index+1 <= #charData then
			index=index+1
		else
			self.act=false
		end
	end
	local t = charData[index]
	self.act = {self=self,key=self.skill[ran],target=t}
end
local function ClearStatus(self,battle)
	StatusHandle.RemoveAll(self,self.data.Status.before,battle)
	StatusHandle.RemoveAll(self,self.data.Status.after,battle)
	StatusHandle.RemoveAll(self,self.data.Status.always,battle)
end
local function GrowByRoomNum(self, roomNum )
	local value = math.floor(roomNum/5)
	self.data.hp = self.data.hp + value * 2
	self.data.act = self.data.act + value -1
	self.data.def = self.data.def + value
	self.data.atk = self.data.atk + value
end
local Character = {}

Character.default={GetHit=GetHit,DoAct=DoAct,DecideAct=DecideAct,GrowByRoomNum=GrowByRoomNum,ClearStatus=ClearStatus}
Character.metatable={}
function Character.new(w,h,data,space,skill,advancedSkill,equipment,xDir,race,name)
	local o = {sprite=nil ,width=w ,height=h ,color={1,1,1,1},space=space,xDir=xDir,equipment=equipment,skill=skill,advancedSkill=advancedSkill,act={},motion={},race=race,data=data,state=MonsterAI.new(),name=name}
	o.originData=TableFunc.copy(data)
	o.data.Status={before={}, after={}, always={}}
	o.signal=Signal.new()

	o.signal:register('GetHit',function (self,value,ignoreDef,hasMotion,battle)
		local v 
		if value < 0 then
			v= math.min(value+self.data.shield,0)
		else
			if value+self.data.hp <= self.originData.hp then
				v= value
			else
				v=math.abs(self.originData.hp-self.data.hp)
			end
		end
		
		if ignoreDef then
			self.data.hp =  clamp(self.data.hp + value ,0 , self.originData.hp)
		else
			
			self.data.shield = math.max(self.data.shield+value ,0)
			self.data.hp = clamp(self.data.hp + v ,0, self.originData.hp)
		end 
		--word motion
		local x , y = self.sprite.transform.position.x +self.width/2 , self.sprite.transform.position.y+100
		local hitWord = Word.new( _G.engPixelFont, math.abs(v), x, y, 0 ,2 ,2 )
		hitWord.t ,hitWord.life =0 ,1.3 
		if v > 0 then 
			hitWord.color = {0,1,0,1}
			Motion.NewTable(self.motion , Motion.new({0, hitWord.color[1] ,1,0.9},'inCirc' ,function(self,dt)hitWord.color[1] = Motion.Lerp(self,dt) hitWord.color[3]=hitWord.color[1] end ) ) 
		elseif v < 0  then 
			hitWord.color = {1,0,0,1} 
			Motion.NewTable(self.motion , Motion.new({0, hitWord.color[2] ,1,0.9},'inCirc' ,function(self,dt)hitWord.color[2] = Motion.Lerp(self,dt) hitWord.color[3]=hitWord.color[2] end ) )
		end
		local wx,wy = hitWord.transform.position.x ,hitWord.transform.position.y
		table.insert(SceneMgr.CurrentScene.TempPrint,hitWord)
		Motion.NewTable(self.motion , Motion.new({0,wy+28,wy-20,0.8},'outCirc' ,function(self,dt)hitWord.transform.position.y = Motion.Lerp(self,dt)end) )
		Motion.NewTable(self.motion , Motion.new({0,3,1,0.9},'outInCirc' ,function(self,dt)hitWord.transform.scale.x = Motion.Lerp(self,dt) hitWord.transform.scale.y=hitWord.transform.scale.x end ) ) 
		
		if self.data.hp <=0 then
			self.state:TransitionTo('Death')
			if o.race=='hero' then battle.signal:emit('RemoveDeathCard',o) end
			--self.data.Status={before={}, after={}, always={}, condition={}}
			o:ClearStatus(battle)
			local char = self
			Motion.NewTable(self.motion , Motion.new({0, 1, -1, 0.8},'linear' ,function(self,dt) char.color[4] = Motion.Lerp(self,dt)end) )
		end
		-- get hit motion
		if hasMotion then
			local cx =self.sprite.transform.position.x
			Motion.NewTable(self.motion , Motion.new({0 ,cx ,cx-30*self.xDir ,0.3},'outCubic' ,function(motion,dt) o.sprite.transform.position.x  = Motion.Mirror(motion,dt)end))
		end
	end)

	setmetatable(o,Character.metatable)
	return o
end
Character.metatable.__index=function (table,key) return Character.default[key] end

return Character