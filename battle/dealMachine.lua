local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Motion = require("lib.motion")

local DealMachine={}

function DealMachine.new(passButton)
	DealMachine.passButton=passButton
	local DealEmpty = State.new('DealEmpty')
	DealEmpty.waitTime=0.1
	local DealMotion = State.new("DealMotion")
	DealMotion.cardNum=0
	local DealUnLockButton = State.new("DealUnLockButton")
	local DealData = State.new("DealData")
	local dealMachine=Machine.new({
		initial=DealEmpty,
		states={DealEmpty ,DealMotion,DealData ,DealUnLockButton },
		events={
		--[[--DealEmpty--> DealMotion--> DealUnLockButton
			^				|
			|---------------|      					]]
			{state=DealEmpty,to='DealMotion'},
			{state=DealMotion,to='DealData'},
			{state=DealMotion,to='DealEmpty'},
			{state=DealData,to='DealUnLockButton'},
			{state=DealUnLockButton,to='DealEmpty'}
		}
	})
	DealEmpty.Do=function(self,dt,battle)
		if #battle.battleData.tempDeal>0 then
			self.currentTime = self.currentTime+dt
			if self.currentTime >= self.waitTime then
				self.currentTime=0
				dealMachine:TransitionTo('DealMotion')
			end
		end
	end
	DealMotion.Do=function(self,dt,battle)
		local length = #battle.battleData.tempDeal
		local deckLength=950
		local deckPos = 238
		local cardSize = 240
		local cardWithShadow = 248
		local cardNeedSize = cardWithShadow * length
		local space = (cardNeedSize-deckLength)/length

		if self.cardNum < length then
			self.cardNum=self.cardNum+1
			DealEmpty.waitTime=0.2
			battle.battleData.deckSize =battle.battleData.deckSize-1

			------init card data
			local card = battle.battleData.tempDeal[self.cardNum]
			local x = (deckPos+cardSize/2)+(cardSize-space-4)*(self.cardNum-1)
			card.sprite.transform.originPosition={x=x,y=914}
			card.sprite.transform.offset={x=card.width/2 ,y=card.height}
			card.sprite.transform.scale={x=1 ,y=1}
			card.parentTab=battle.battleData.tempDeal
			card.handPos=self.cardNum

			card:Lock()
			card.motionMachine:TransitionTo('Deal',card,x)
			dealMachine:TransitionTo('DealEmpty')
		else			
			self.currentTime = self.currentTime+dt
			self.waitTime=0.5
			if self.currentTime >= self.waitTime then
				self.currentTime=0
				dealMachine:TransitionTo('DealData',dt,battle)
			end
		end
	end
	DealData.DoOnEnter=function(self,dt,battle)
		for i=dealMachine.states.DealMotion.cardNum, 1,-1  do
			local targetTab = battle.battleData.hand
			table.insert(targetTab , 1 ,battle.battleData.tempDeal[i])
			battle.battleData.tempDeal[i].parentTab=targetTab
			table.remove(battle.battleData.tempDeal ,i)
		end
		dealMachine:TransitionTo('DealUnLockButton')
	end
	DealUnLockButton.Do=function(self,dt,battle)
		for k,card in pairs(battle.battleData.hand) do
			card:Unlock()
		end
		DealMotion.cardNum=0
		DealMachine.passButton:Unlock()
		dealMachine:TransitionTo('DealEmpty')
	end

	return dealMachine
end
return DealMachine