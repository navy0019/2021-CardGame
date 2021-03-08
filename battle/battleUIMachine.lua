local SceneMgr = require('lib.sceneManager')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Motion = require("lib.motion")
local Label = require("lib.Label")

local Assets = require('resource.allAssets')

local dropMachine = require('battle.dropMachine')
local dealMachine = require('battle.dealMachine')

local BattleUIMachine={}
function BattleUIMachine.new(label)
	BattleUIMachine.label=label
	BattleUIMachine.DropMotionMachine=dropMachine.new(BattleUIMachine.label.passButton)
	BattleUIMachine.DealMotionMachine=dealMachine.new(BattleUIMachine.label.passButton)

	local Empty = State.new("Empty")
	local StartRound = State.new("StartRound")
	local Statusbefore = State.new("Statusbefore")
	local PlayerAct = State.new("PlayerAct")
	local MonsterAct = State.new("MonsterAct")
	local Statusafter = State.new("Statusafter")
	local RoundEnd = State.new("RoundEnd")
	local Victory = State.new("Victory")
	local Lose = State.new("Lose")

	local UIMachine = Machine.new({
		initial=Empty,
		states={
			Empty ,StartRound  ,Statusbefore ,MonsterAct,PlayerAct,Statusafter,RoundEnd,Victory,Lose
		},
		events={
			--[[  Victory ,Lose (global)

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

			{state=Statusbefore,to='Victory' },
			{state=Statusafter,to='Victory'},
			{state=PlayerAct,to='Victory' },
			{state=MonsterAct,to='Victory' },

			{state=Statusbefore,to='Lose' },
			{state=Statusafter,to='Lose'},
			{state=PlayerAct,to='Lose' },
			{state=MonsterAct,to='Lose' }

		}
	})

	StartRound.DoOnEnter=function(self,dt,battle)
		local roundimg
		if battle.battleData.round % 2 == 0 then
			roundimg =BattleUIMachine.label.enemyRound
			BattleUIMachine.label.passBWord.text='敵方回合'	
		else
			roundimg =BattleUIMachine.label.playerRound
			BattleUIMachine.label.passBWord.text='結束回合'
		end

		local ImgEmpty = State.new("ImgEmpty")
		local ImgShow = State.new("ImgShow")
		local ImgVanish = State.new("ImgVanish")

		Act = Machine.new({
			initial=ImgEmpty,
			states={ImgEmpty ,ImgShow ,ImgVanish },
			events={
				{state=ImgEmpty,to='ImgShow'},
				{state=ImgShow,to='ImgVanish'},	
				{state=ImgVanish,to='ImgEmpty'},
			}
		})
		ImgEmpty.Do=function(self,dt,battle)
			self.waitTime=0.1 
			self.currentTime = self.currentTime+dt
			if self.currentTime >= self.waitTime then
				self.currentTime=0
				Act:TransitionTo('ImgShow',dt,battle)
			end
		end
		ImgShow.DoOnEnter=function(self,dt,battle)
			local show    = Motion.new({0,roundimg.color[4] , 1 , 0.9}  ,'outQuint' ,function(self,dt)roundimg.color[4]= Motion.Lerp(self,dt) end )
			local enlarge = Motion.new({0,roundimg.sprite.transform.scale.x , 1 , 0.9},'outQuint' ,function(self,dt)roundimg.sprite.transform.scale.x = Motion.Lerp(self,dt) roundimg.sprite.transform.scale.y=roundimg.sprite.transform.scale.x end )
			Motion.NewTable( roundimg.motion ,  show    )
			Motion.NewTable( roundimg.motion ,  enlarge )
		end
		ImgShow.Do=function(self,dt,battle)
			self.waitTime=1.1
			self.currentTime = self.currentTime+dt
			if self.currentTime >= self.waitTime then
				self.currentTime=0
				Act:TransitionTo('ImgVanish',dt,battle)
			end
		end
		ImgVanish.DoOnEnter=function(self,dt,battle)
			local vanish  = Motion.new({0,roundimg.color[4]  ,0 ,0.8}   ,'outQuint' ,function(self,dt)roundimg.color[4]= Motion.Lerp(self,dt) end )
			local shrink  = Motion.new({0,roundimg.sprite.transform.scale.x ,1.5 ,0.8},'outQuint' ,function(self,dt)roundimg.sprite.transform.scale.x = Motion.Lerp(self,dt) roundimg.sprite.transform.scale.y=roundimg.sprite.transform.scale.x end )
			Motion.NewTable( roundimg.motion ,  vanish )
			Motion.NewTable( roundimg.motion ,  shrink )
		end

		self.startMotion = Act

		BattleUIMachine.label.passButton:Lock()
	end
	StartRound.Do=function(self,dt,battle)
		self.startMotion:Update(dt,battle)
	end
	StartRound.DoOnLeave=function(self,dt,battle)
		self.startMotion:TransitionTo('ImgEmpty')
	end
	PlayerAct.Do=function(self,dt,battle)
		BattleUIMachine.DealMotionMachine:Update(dt,battle)

	end
	PlayerAct.DoOnLeave=function()
	end
	Statusafter.DoOnEnter=function(self,dt,battle)

	end
	Statusafter.Do=function (self,dt,battle )

	end
	Statusafter.DoOnLeave=function (self,dt,battle )
	end
	Victory.DoOnEnter=function(self,dt,battle )
		local bg = BattleUIMachine.label.dark
		local vicBoard = BattleUIMachine.label.vicBoard
		local vicWord = BattleUIMachine.label.vicWord
		local vicButton = BattleUIMachine.label.vicButton

		bg.color={1,1,1,0.7}
		local vic = Label.new("vic",{Drawable={bg,vicBoard,vicWord,vicButton},CheckRange={vicButton}} )

		table.insert(SceneMgr.CurrentScene.UIMachine.current.stack,vic)
	end
	Lose.DoOnEnter=function(self,dt,battle)
		local bg = BattleUIMachine.label.dark
		local board = BattleUIMachine.label.vicBoard
		local loseWord = BattleUIMachine.label.loseWord
		local loseButton = BattleUIMachine.label.loseButton

		bg.color={1,1,1,0.7}
		local lose = Label.new("lose",{Drawable={bg,board,loseWord,loseButton},CheckRange={loseButton}} )

		table.insert(SceneMgr.CurrentScene.UIMachine.current.stack,lose)

	end
	UIMachine.Update=function(self,dt,battle,...)
		self.current:Do(dt,battle,...)
		for k,card in pairs(battle.battleData.hand) do
			card.motionMachine:Update(dt,card)
		end
		for k,card in pairs(battle.battleData.tempDrop) do
			card.motionMachine:Update(dt,card)
		end
		for k,card in pairs(battle.battleData.tempDeal) do
			card.motionMachine:Update(dt,card)
		end
		BattleUIMachine.DropMotionMachine:Update(dt,battle,...)

	end	
	return UIMachine
end
return BattleUIMachine