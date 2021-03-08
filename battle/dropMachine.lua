local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local DropMachine={}
function DropMachine.new(passButton)
	DropMachine.passButton=passButton
	local DropEmpty = State.new('DropEmpty')
	DropEmpty.waitTime=0

	local DropNum = State.new('DropNum')
	DropNum.cardNum=1

	local DropData = State.new("DropData")
	DropData.waitTime=1.2

	local DropUnLockButton = State.new("DropUnLockButton")

	local dropMachine=Machine.new({
		initial=DropEmpty,
		states={DropEmpty ,DropNum, DropData ,DropUnLockButton },
		events={

			{state=DropEmpty,to='DropNum'},

			{state=DropNum,to='DropEmpty'},
			{state=DropNum,to='DropData'},

			{state=DropData,to='DropUnLockButton'},
			{state=DropUnLockButton,to='DropEmpty'}

		}
	})
	DropEmpty.Do=function(self,dt,battle)
		if #battle.battleData.tempDrop > 0 then
			DropMachine.passButton:Lock()
			dropMachine:TransitionTo('DropNum',battle)
		end
	end
	DropNum.Do=function(self,dt,battle)
		local length = #battle.battleData.tempDrop
		if self.cardNum <= length then
			
			local card = battle.battleData.tempDrop[self.cardNum]
			card.parentTab=battle.battleData.tempDrop
			battle.battleData[card.dropTo..'Size']=battle.battleData[card.dropTo..'Size']+1

			self.cardNum=self.cardNum+1
			dropMachine:TransitionTo('DropEmpty')
		else
			self.cardNum=self.cardNum-1
			dropMachine:TransitionTo('DropData')			
		end
	end
	DropData.Do=function(self,dt,battle)
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0

			for i=dropMachine.states.DropNum.cardNum, 1,-1  do
				local targetTab = battle.battleData[battle.battleData.tempDrop[i].dropTo]
				table.insert(targetTab , 1 ,battle.battleData.tempDrop[i])
				battle.battleData.tempDrop[i].parentTab=targetTab
				table.remove(battle.battleData.tempDrop ,i)
			end
			dropMachine:TransitionTo('DropUnLockButton')
		end
	end
	DropData.DoOnLeave=function(self,battle)
		dropMachine.states.DropNum.cardNum=1
		self.waitTime= 1
	end
	DropUnLockButton.Do=function(self,dt,battle)
		DropMachine.passButton.CheckUnlockButton(battle)
		dropMachine:TransitionTo('DropEmpty')
	end

	return dropMachine
end
return DropMachine