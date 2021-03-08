local SceneMgr = require('lib.sceneManager')

local Motion = require("lib.motion")
local Word = require("lib.word")
local Card = require("lib.card")
local TableFunc = require("lib.tableFunc")
local StatusHandle = require("lib.status")
local Choose = require("lib.choose")
local Signal = require("lib.hump.signal")
local MonsterGenerator = require("lib.monsterGenerator")
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local Assets = require('resource.allAssets')
local CardAssets = require("resource.cardAssets")

local BattleUIMachine = require("battle.battleUIMachine")
local StatusMachine=require("battle.statusMachine")

local Battle={}

local BattleMachine = {}
local LoopMachine = {}
function LoopMachine.new()
	local Empty = State.new("Empty")
	local InitData = State.new("InitData")
	local Wait = State.new("Wait")
	local Dofunc = State.new("Dofunc")
	local loopMachine = Machine.new({
		initial=Empty,
		states={Empty,InitData,Dofunc,Wait},
		events={
			{state=Empty,to='InitData'},
			{state=InitData,to='Dofunc'},
			{state=Dofunc,to='Empty'},
			{state=Dofunc,to='Wait'},
			{state=Wait,to='Dofunc'}
		}
	})

	InitData.DoOnEnter=function(self,waitTime,loopNum,argTab,func)
		self.argTab=argTab
		self.func=func
		self.loopNum=loopNum
		self.count = 0
		Wait.waitTime=waitTime
	end
	InitData.Do=function(self,dt)
		loopMachine:TransitionTo('Dofunc')
	end
	Dofunc.Do=function (self,dt)
		if InitData.count< InitData.loopNum then
			InitData.func(InitData.argTab)
			InitData.count=InitData.count+1
			loopMachine:TransitionTo('Wait')
		else
			loopMachine:TransitionTo('Empty')
		end
	end
	Wait.Do=function(self,dt)
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0
			loopMachine:TransitionTo('Dofunc')
		end
	end
	return loopMachine
end

function BattleMachine.new(label)	
	local Empty = State.new("Empty")
	local StartRound = State.new("StartRound")
	local Statusbefore = State.new("Statusbefore")
	local PlayerAct = State.new("PlayerAct")
	local MonsterAct = State.new("MonsterAct")
	MonsterAct.waitTime=0
	local Statusafter = State.new("Statusafter")
	local RoundEnd = State.new("RoundEnd")
	local WaitEnding = State.new("WaitEnding")

	local battleMachine = Machine.new({
		initial=Empty,
		states={
			Empty ,StartRound  ,Statusbefore ,MonsterAct,PlayerAct,Statusafter,RoundEnd,WaitEnding
		},
		events={
			--[[  WaitEnding(global)

			      						/-->PlayerAct --\							
			StartRound--> Statusbefore--                 -->Statusafter--> RoundEnd 
										\-->MonsterAct--/       					 				]]

			{state=Empty,to='StartRound'},
			{state=StartRound,to='Statusbefore'},

			{state=Statusbefore,to='PlayerAct' },	
			{state=Statusbefore,to='MonsterAct'},

			{state=PlayerAct,to='Statusafter' },
			{state=MonsterAct,to='Statusafter'},

			{state=Statusafter,to="RoundEnd"},
			{state=RoundEnd,to='StartRound' },

			{state=Statusbefore,to='WaitEnding' },
			{state=Statusafter,to='WaitEnding'},
			{state=PlayerAct,to='WaitEnding' },
			{state=MonsterAct,to='WaitEnding' }

		}
	})

	battleMachine.UIMachine = BattleUIMachine.new(label)
	battleMachine.statusMachine=StatusMachine.new(battle)
	Empty.Do=function(self,dt,battle)
		battleMachine.UIMachine:TransitionTo('StartRound',dt,battle)
		battleMachine:TransitionTo('StartRound',dt,battle)
	end
	StartRound.DoOnEnter=function(self,dt,battle)
		self.waitTime=2
		Battle.ClearDeath(battle)

		label.passButton:Lock()

	end
	StartRound.Do=function(self,dt,battle)
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0
			battleMachine.UIMachine:TransitionTo('Statusbefore',dt,battle)
			battleMachine:TransitionTo('Statusbefore',dt,battle)
		end
	end
	Statusbefore.DoOnEnter=function(self,dt,battle)
		if battle.battleData.round % 2 == 0 then
			battleMachine.statusMachine:addUpdate(battle,'monsterData' ,'before')
			self.waitTime=Battle.CountAlive(battle.characterData.monsterData)*0.2
		else
			battleMachine.statusMachine:addUpdate(battle,'heroData' ,'before')
			self.waitTime=0
		end
	end
	Statusbefore.Do=function(self,dt,battle)
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0
			if battle.battleData.round % 2 == 0 then
				battleMachine.UIMachine:TransitionTo('MonsterAct',dt,battle)
				battleMachine:TransitionTo('MonsterAct',dt,battle)
			else
				battleMachine.UIMachine:TransitionTo('PlayerAct',dt,battle)
				battleMachine:TransitionTo('PlayerAct',dt,battle)
			end
		end
	end
	PlayerAct.DoOnEnter=function(self,dt,battle)
		battle.battleData.actPoint =0
		for k,hero in pairs(battle.characterData.heroData) do
			battle.battleData.actPoint = battle.battleData.actPoint+hero.data.act
		end
		Battle.DealProcess(battle)
	end
	PlayerAct.Do=function(self,dt,battle)
	end
	PlayerAct.DoOnLeave=function()

	end
	MonsterAct.DoOnEnter=function(self,dt,battle)
		local Empty = State.new("Empty")
		Empty.waitTime=0.5
		local Act = State.new("Act")
		Act.index=1

		local mAct=Machine.new({
			initial=Empty,
			states={Empty ,Act  },
			events={
				{state=Empty,to='Act'},
				{state=Act,to='Empty'},	
			}			
		})
		Empty.Do=function(self,dt,battle)
			self.currentTime = self.currentTime+dt
			if self.currentTime >= self.waitTime then
				self.currentTime=0
				if Act.index <= #battle.characterData.monsterData then					
					mAct:TransitionTo('Act',dt,battle)
				end
			end
		end

		Act.Do=function(self,dt,battle)
			local m = battle.characterData.monsterData[Act.index]
			if m.state.current.name ~= "Death" then
				m.state:Update( m ,battle)
				Empty.waitTime=0.7
				mAct:TransitionTo('Empty',dt,battle)
			else
				Empty.waitTime=0				
			end
			MonsterAct.waitTime=MonsterAct.waitTime+Empty.waitTime
			Act.index=Act.index+1
		end
		self.Act=mAct
	end
	MonsterAct.Do=function(self,dt,battle)
		self.currentTime = self.currentTime+dt
		self.Act:Update(dt,battle)
		if self.Act.states.Act.index > #battle.characterData.monsterData and self.currentTime >= self.waitTime then
			self.currentTime=0
			battleMachine.UIMachine:TransitionTo('Statusafter',dt,battle)
			battleMachine:TransitionTo('Statusafter',dt,battle)
		end
	end
	MonsterAct.DoOnLeave=function(self,dt,battle)
		self.Act.states.Act.index=1
		self.Act.states.Empty.waitTime=0.5
		self.waitTime=0
	end
	Statusafter.DoOnEnter=function(self,dt,battle)
		local time
		if battle.battleData.round % 2 == 0 then
			battleMachine.statusMachine:addUpdate(battle,'monsterData' ,'after')
			local buffNum = Battle.CountBuff(battle.characterData.monsterData ,'after')
			if buffNum >0 then
				time=0.2*buffNum+Battle.CountAlive(battle.characterData.monsterData)*0.2
			else
				time=0
			end
			
		else
			battleMachine.statusMachine:addUpdate(battle,'heroData' ,'after',battle)
			local buffNum = Battle.CountBuff(battle.characterData.heroData ,'after')
			if buffNum >0 then
				time=0.2*Battle.CountBuff(battle.characterData.heroData ,'after')+Battle.CountAlive(battle.characterData.heroData)*0.2
			else
				time=0
			end
		end
		if battle.battleData.round % 2 ~= 0 and #battle.battleData.hand > 0 then
			battle:DropProcess(battle.battleData.hand , battle.battleData.hand )
			self.waitTime=math.max(time ,0.5 ) 		
		end
	end
	Statusafter.Do=function(self,dt,battle)	
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0
			battleMachine.UIMachine:TransitionTo("RoundEnd",dt,battle)
			battleMachine:TransitionTo('RoundEnd',dt,battle)
		end
	end
	RoundEnd.DoOnEnter=function(self,dt,battle)
	self.waitTime =0
		battle.battleData.round = battle.battleData.round+1

	end
	RoundEnd.Do=function(self,dt,battle)
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0
			battleMachine.UIMachine:TransitionTo('StartRound',dt,battle)
			battleMachine:TransitionTo('StartRound',dt,battle)
		end
	end
	WaitEnding.DoOnEnter=function(self,dt,battle,nextState)
		self.nextState=nextState
		if nextState=='Victory'  then
			for k,v in pairs(battle.battleData.hand) do
				v.isLock=true
			end
		end
		for k,char in pairs(battle.characterData.heroData) do
			char:ClearStatus(battle)
		end
	end
	WaitEnding.Do=function(self,dt,battle)
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.waitTime=math.huge
			battleMachine.UIMachine:TransitionTo(self.nextState,dt,battle)
		end
	end

	battleMachine.Update=function(self,...)
		self.current:Do(...)
		battleMachine.UIMachine:Update(...)
		battleMachine.statusMachine:Update(...)
	end

	return battleMachine
end

local function InitBattleData(battle)
	_G.rng:setState(battle.scene.events.ranState)
	_G.rng:setSeed(battle.scene.events.ranSeed)
	battle.characterData.heroData=battle.MapGenerator.characterData
	battle.characterData.monsterData=MonsterGenerator.RandomMonster(battle.MapGenerator.data.passedRoom)
	for k,hero in pairs(battle.characterData.heroData) do
		battle.battleData.actPoint = battle.battleData.actPoint+hero.data.act
	 	for i,name in pairs(hero.skill) do
	 		local card = CardAssets.instance( name,0,0,hero,battle.battleData.deck,battle )
	 		table.insert(battle.battleData.deck,card)
	 	end
	end
	TableFunc.upset(battle.battleData.deck)
	battle.battleData.deckSize= #battle.battleData.deck

	battle.label.passButton.Lock=function()
		battle.label.passButton.isLock=true 
		battle.label.passButton.color={0.5,0.5,0.5,1}
		battle.label.passBWord.color={0.7,0.7,0.7,1}
	end
	battle.label.passButton.Unlock=function()
		battle.label.passButton.isLock=false 
		battle.label.passButton.color={1,1,1,1} 
		battle.label.passBWord.color={1,1,1,1}
	end
	battle.label.passButton.CheckUnlockButton=function(battle)
		if battle.battleData.round % 2 == 0 then
			battle.label.passButton.Lock()
		else
			if #battle.battleData.tempDrop<=0 then
				battle.label.passButton.Unlock()				
			else
				battle.label.passButton.Lock()
			end
		end
	end
	battle.label.passButton.OnClick=function() 
		battle.battleMachine:TransitionTo('Statusafter',0,battle)
		battle.battleMachine.UIMachine:TransitionTo('Statusafter',0,battle)
		battle.label.passButton:Lock()
	end
	battle.label.vicButton.OnClick=function()
		SceneMgr.CurrentScene.events.isBattle = false
	end
	battle.label.loseButton.OnClick=function()
		battle.MapGenerator.func.ResetMap()
		SceneMgr.CurrentScene.switchingScene = 'Main'
	end
end
local function CardWordUpdate(self)--InfoUpdate
	for k,v in pairs(self.battleData.deck) do
		v:Update()
	end
	for k,v in pairs(self.battleData.hand) do
		v:Update()
	end
	for k,v in pairs(self.battleData.tempDrop) do
		v:Update()
	end
	for k,v in pairs(self.battleData.drop) do
		v:Update()
	end
	for k,v in pairs(self.battleData.disappear) do
		v:Update()
	end
end
local function DropProcess(self,originTab,card)
	for k,v in pairs(card) do
		v.motionMachine:TransitionTo("Drop",v)
	end
	self:DropCard(originTab,card)

end
local function DropCard(self,originTab,card)
	if getmetatable(card)==Card.metatable then
		card.isLock=true

		table.insert(self.battleData.tempDrop,card)

		local p = TableFunc.find(originTab,card)
		table.remove(originTab,p)
		for k,v in pairs(self.battleData.hand) do
			v.handPos=k
		end		
		
	else
		local cards = TableFunc.copy(card)
		for k,v in pairs(cards) do
			v.isLock=true	
			table.insert(self.battleData.tempDrop ,v)

			local p=TableFunc.find(originTab,v)
			table.remove(originTab,p)
		end

	end
end 
local function Update( self,dt  )
	self.battleMachine:Update(dt,self)
	self.loopMachine:Update(dt)
	self:CardWordUpdate()
end
local function Reset( self )
	self.characterData={heroData={},monsterData={}}
	self.battleData={round=1,actPoint=0,dealNum=5,deckSize=0,dropSize=0,disappearSize=0,deck={},hand={},drop={},disappear={},tempDrop={},tempDeal={}}
	self.choose=Choose.new()
end
Battle.default={Reset=Reset,Update=Update, InitBattleData=InitBattleData ,DropProcess=DropProcess,DropCard=DropCard ,CardWordUpdate=CardWordUpdate}
Battle.metatable={}
function Battle.initMachine(battle,label)
	battle.battleMachine=BattleMachine.new(label)
	
end
function Battle.new(MapGenerator,label,scene)
	local o ={characterData={heroData={},monsterData={}},
		battleData={round=1,actPoint=0,dealNum=5,deckSize=0,dropSize=0,disappearSize=0,
		deck={},hand={},drop={},disappear={},tempDrop={},tempDeal={}},choose=Choose.new(),signal=nil,MapGenerator=MapGenerator,
		label={},scene=scene,loopMachine = LoopMachine.new()
	}

	o.label=label
	InitBattleData(o)
	o.battleMachine=BattleMachine.new(o.label)

	o.signal=Signal.new()
	o.signal:register('CheckLife',function()
		function CheckLife(datas)
			for k,v in pairs(datas) do
				if v.state.current.name ~= 'Death' then
					return false
				end
			end
			return true
		end
		local heros = CheckLife(o.characterData.heroData)
		local monsters = CheckLife(o.characterData.monsterData)

		if heros then
			--lose
			o.battleMachine:TransitionTo('WaitEnding',0,o,'Lose')

		elseif monsters then
			o.battleMachine:TransitionTo('WaitEnding',0,o,'Victory')
		end
	end)
	o.signal:register('RemoveDeathCard',function(char)
		for k,skill in pairs(char.skill) do
			if TableFunc.find(o.battleData.deck ,char,'master') then
				local p = TableFunc.find(o.battleData.deck ,char,'master')
				o.battleData.deckSize=o.battleData.deckSize-1
				table.remove(o.battleData.deck , p)

			elseif TableFunc.find(o.battleData.hand ,char,'master') then
				local p = TableFunc.find(o.battleData.hand ,char,'master')

				table.remove(o.battleData.hand , p)

			elseif TableFunc.find(o.battleData.drop ,char,'master') then
				local p = TableFunc.find(o.battleData.drop ,char,'master')
				o.battleData.dropSize=o.battleData.dropSize-1
				table.remove(o.battleData.drop , p)
			end
		end
	end)
	o.signal:register('Act',function(char,card)
		o.battleMachine.statusMachine:addUpdate(o,'heroData' ,'always',card)
		o.battleMachine.statusMachine:addUpdate(o,'monsterData' ,'always',card)

	end)
	setmetatable(o,Battle.metatable)
	return o
end

function Battle.CountAlive(datas)
	local num
	local deadCount = 0
	for k,m in pairs(datas) do
		if m.state.current.name =='Death' then
			deadCount=deadCount+1			
		end
		num=k-deadCount
	end
	return num
end
function Battle.CountBuff(datas,key)
	local num=0
	for k,v in pairs(datas) do
		for j,s in pairs(v.data.Status[key]) do
			num=num+1
		end
		
	end
	return num
end

function Battle.MonsterAct(self)
	local num=0
	local deadCount = 0
	for k,m in pairs(self.characterData.monsterData) do
		if m.state.current.name =='Death' then
			deadCount=deadCount+1			
		end
		num=k-deadCount
		m.state:Update( m ,self ,num)
	end
end

function Battle.ClearDeath(self)
	for i=#self.characterData.heroData,1,-1 do
		if self.characterData.heroData[i].state.current.name =='Death' then
			table.remove(self.characterData.heroData,i)
		end
	end
	for i=#self.characterData.monsterData,1,-1 do
		if self.characterData.monsterData[i].state.current.name =='Death' then
			table.remove(self.characterData.monsterData,i)
		end
	end
end

function Battle.Backfill(self)
	function backFill(argTab)
		argTab.deckSize =argTab.deckSize+1 
		argTab.dropSize =argTab.dropSize-1
	end
	self.loopMachine:TransitionTo('InitData',0.01,#self.battleData.drop,self.battleData,backFill)--loopnum,argTab,func
	for i=1,#self.battleData.drop do
		table.insert(self.battleData.deck,self.battleData.drop[1])
		table.remove(self.battleData.drop,1)
	end

end
function Battle.Deal(battleData)
	table.insert(battleData.tempDeal,battleData.deck[1])
	table.remove(battleData.deck,1)
end
function Battle.DealProcess(self)
	local dealNum = math.min(#self.battleData.deck,self.battleData.dealNum) 
	for i=1,dealNum do
		Battle.Deal(self.battleData)	
	end
	if dealNum < self.battleData.dealNum then
		Battle.Backfill(self)
		for i=1,self.battleData.dealNum-dealNum do
			Battle.Deal(self.battleData)	
		end
	end
end 

Battle.metatable.__index=function (table,key) return Battle.default[key] end

return Battle