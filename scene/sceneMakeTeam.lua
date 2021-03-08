local Scene = require('lib.scene')
local SceneMgr = require('lib.sceneManager')
local Word = require('lib.word')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Motion = require("lib.motion")
local Label = require("lib.Label")
local TableFunc = require("lib.tableFunc")
local MathExtend = require("lib.math")
local Card = require("lib.card")
local TeamData = require('lib.teamData')

local Assets = require('resource.allAssets')
local CardAssets = require("resource.cardAssets")

local SaveFileMgr=require('save.saveManager')

local scene = Scene.new({Drawable={},CheckRange={},Altas={},Motion={},TempPrint={},AllLabels={},Other={},firstLoad=true,name='MakeTeam'})
local width,height

local BG=Assets.Images.instance('makeTeamBG',0,0,0,1,1,0,0)
local basicImg  =Label.new("basicImg"		,{Drawable={BG}} )
local backButton=Assets.Buttons.instance('teamBack',56,700)
local saveTeam = Assets.Buttons.instance('saveTeam',1172,700)
local resetTeam = Assets.Buttons.instance('resetTeam',1172,612)

backButton.OnClick=function () 
	local empty=TeamData.CheckEmpty() 
	if empty==false then
		scene.switchingScene = 'Main'
	else
		local word = Word.new( _G.defaultFont, "Team must have 4 people", 40, 676 )
		word.t=0
		word.life=1.2
		word.color={1,0,0,1}
		local y = word.transform.position.y
		Motion.NewTable( scene.Motion , Motion.new({0,y, y-20, 0.4} ,'outCubic' ,function(self,dt) word.transform.position.y = Motion.Lerp(self,dt) end ))
		table.insert(scene.TempPrint,word) 	
	end
end
resetTeam.OnClick=function () TeamData.ResetTeam() scene.UIMachine.reMakeStack(scene.UIMachine.current)  end 
saveTeam.OnClick=function () TeamData.SaveTeam() SaveFileMgr.Save(SaveFileMgr.CurrentSave)  end

local function SetMotion( scene,datas )
	for k,v in pairs(datas) do
		for j,motion in pairs(v.motion) do
			table.insert(scene.Motion,motion)
		end
	end
end

local function MakeLabel()
	local characterLabel = Label.new("character",{Drawable={},Altas={}})
	local shadowLabel = Label.new("shadow",{Drawable={}})
	local infoLabel = Label.new("info",{Drawable={}})
	local buttonlabel = Label.new("button",{Drawable={},CheckRange={}})
	local gridbuttonLabel = Label.new("gridbutton",{Drawable={},CheckRange={}})

	--hero & hero info draw
	for k,v in ipairs(SaveFileMgr.CurrentSave.CurrentTeam) do
		if v ~='empty' then
			local hero = Assets.Characters.instance(v , 0 ,-24)
			hero.sprite.transform.position.x=873-180*(k-1)
			hero.sprite.transform.position.y=-24
			local shadow = Assets.Images.instance('shadow',hero.sprite.transform.position.x  ,hero.sprite.transform.position.y+hero.height-36,0,1,1,0,0)
			table.insert(characterLabel.label.Drawable,hero)
			table.insert(characterLabel.label.Altas,hero)
			table.insert(shadowLabel.label.Drawable,shadow)

			--heroInfo head
			local heroHead = Assets.Images.instance('head_88_'..v , 56 ,112+(k-1)*130,0,1,1,0,0)
			table.insert(infoLabel.label.Drawable,heroHead)
			
			local hpWord  = Word.new(_G.pixelFont, hero.data.hp , 196 , 107+(k-1)*130  , 0 ,1 ,1 ,0 ,0)
			local atkWord = Word.new(_G.pixelFont, hero.data.atk, 196 , 131+(k-1)*130  , 0 ,1 ,1 ,0 ,0)
			local defWord = Word.new(_G.pixelFont, hero.data.def, 196 , 155+(k-1)*130  , 0 ,1 ,1 ,0 ,0)
			local actWord = Word.new(_G.pixelFont, hero.data.act, 196 , 179+(k-1)*130  , 0 ,1 ,1 ,0 ,0)
			table.insert(infoLabel.label.Drawable, hpWord)
			table.insert(infoLabel.label.Drawable, atkWord)
			table.insert(infoLabel.label.Drawable, defWord)
			table.insert(infoLabel.label.Drawable, actWord)

		end
	end

	--hero grid 
	for i=1,2 do
		local x = 364
		local y = 576
		local num = 1
		if i >1 then
			y=y+88
			num=9
		end
		for k=1,8 do
			--draw grid & button
			local grid =Assets.Buttons.instance('heroGrid',x,y,0,1,1,0,0)
			table.insert(gridbuttonLabel.label.Drawable,grid)
			table.insert(gridbuttonLabel.label.CheckRange,grid)

			--put head image & onClick on grid
			if TeamData.AllHeros[num].lock == false then
				local head72 = Assets.Images.instance('head_72_hero'..num , x+4 ,y+4,0,1,1,0,0)
				table.insert(gridbuttonLabel.label.Drawable,head72)
			else
				local lock = Assets.Images.instance('lock' ,x+4 ,y+4,0,1,1,0,0)
				table.insert(gridbuttonLabel.label.Drawable,lock)
			end
			--put selected image
			if TeamData.AllHeros[num].selected == true then
				local tick = Assets.Images.instance('select' , x+4 ,y+4,0,1,1,0,0)
				table.insert(gridbuttonLabel.label.Drawable,tick)
			end
			x=x+88
			num=num+1
		end
	end

	table.insert(buttonlabel.label.Drawable,saveTeam)
	table.insert(buttonlabel.label.Drawable,backButton)
	table.insert(buttonlabel.label.Drawable,resetTeam)

	table.insert(buttonlabel.label.CheckRange,saveTeam)
	table.insert(buttonlabel.label.CheckRange,backButton)
	table.insert(buttonlabel.label.CheckRange,resetTeam)

	--hero pop info
	local infoBG   = Assets.Images.instance('choose_pop_BG',0,0,0,1,1,0,0)
	infoBG.color[4]=0.85
	local infoData = Assets.Images.instance('choose_pop_Info',76,594)
	local infoBack = Assets.Buttons.instance('teamBack',56,700)

	infoBack.OnClick=function()
		table.remove(scene.UIMachine.current.stack,#scene.UIMachine.current.stack) 
	end
	for i=1,4 do
		local info = Assets.Images.instance('heroInfo',56,80 +(i-1)*130,0,1,1,0,0)
		local button = Assets.Buttons.instance('heroInfoButton',200,82+(i-1)*130)
		table.insert(infoLabel.label.Drawable,info)
		table.insert(buttonlabel.label.CheckRange,button)
		button.OnClick=function()
			if SaveFileMgr.CurrentSave.CurrentTeam[i]~='empty' then
				local popLabel= Label.new("pop",{Drawable={infoBG,infoData,infoBack},Altas={},CheckRange={infoBack}})

				local hero = Assets.Characters.instance(SaveFileMgr.CurrentSave.CurrentTeam[i] , 0 ,-24)
				hero.sprite.transform.position.x=48
				hero.sprite.transform.position.y=-24
				table.insert(popLabel.label.Drawable,hero)
				table.insert(popLabel.label.Altas,hero)

				local infoWord= Word.new(_G.pixelFont, hero.info    , 52  , 444+8   , 0 ,1 ,1 ,0 ,0)
				local hpWord  = Word.new(_G.pixelFont, hero.data.hp , 100 , 551     , 0 ,1 ,1 ,0 ,0)
				local atkWord = Word.new(_G.pixelFont, hero.data.atk, 100 , 551+20  , 0 ,1 ,1 ,0 ,0)
				local defWord = Word.new(_G.pixelFont, hero.data.def, 100 , 551+40  , 0 ,1 ,1 ,0 ,0)
				local actWord = Word.new(_G.pixelFont, hero.data.act, 100 , 551+60  , 0 ,1 ,1 ,0 ,0)
				table.insert(popLabel.label.Drawable ,hero   ) 
				table.insert(popLabel.label.Drawable ,hpWord )
				table.insert(popLabel.label.Drawable ,atkWord) 
				table.insert(popLabel.label.Drawable ,defWord)
				table.insert(popLabel.label.Drawable ,actWord) 
				table.insert(popLabel.label.Drawable ,infoWord)

				
				local bar = Assets.Images.instance("choose_pop_roll",width*0.9,height*0.05+30,0,1,1,0,0)
				local drag = Assets.Buttons.instance("choose_pop_bar",width*0.9,height*0.05+30,0,1,1,0,0)
				local x,y = drag.sprite.transform.position.x ,drag.sprite.transform.position.y
				local basicTitle = Word.new(_G.pixelFont, '基礎牌組'    , width*0.22  , y   , 0 ,1 ,1 ,0 ,0)
				local advTitle = Word.new(_G.pixelFont, '進階牌組'    , width*0.22  , y+300   , 0 ,1 ,1 ,0 ,0)

				local cards={}
				for k,name in pairs(hero.skill) do
					local card=CardAssets.instance( name,width*0.22+(k-1)*196,y+30,hero,cards )
					card.sprite.transform.scale={x= 0.7 ,y= 0.7}
					card.sprite.transform.offset={x=0,y=0}

					local x ,sx , y , sy = card.sprite.transform.position.x ,card.sprite.transform.scale.x ,card.sprite.transform.position.y ,card.sprite.transform.scale.y
					local name = Word.new( _G.pixelFont, card.name, x+(card.width*sx)/2-20 , y+28 ,0,1,1,0,0 )
					name.color={0,0,0,1}					
					local cost = Word.new( _G.engPixelFont, card.cost, x+18 , y+16)
					local info = Word.new( _G.pixelFont, card.info, x+28 , y+(card.height*sy)/2+48,0, 0.9,0.9)

					table.insert(cards,card)
					table.insert(cards,name)
					table.insert(cards,cost)
					table.insert(cards,info)
				end

				local row = 1
				local count = 1
				for k,name in pairs(hero.advancedSkill) do
					if #hero.advancedSkill > 4 and count >4 then
						row = row+1
						count=1
					end 
					local card=CardAssets.instance( name,width*0.22+(count-1)*196,y+330+(row-1)*(330*0.7),hero,cards )
					card.sprite.transform.scale={x= 0.7 ,y= 0.7}
					card.sprite.transform.offset={x=0,y=0}
					local x ,sx , y , sy = card.sprite.transform.position.x ,card.sprite.transform.scale.x ,card.sprite.transform.position.y ,card.sprite.transform.scale.y
					local w=_G.pixelFont:getWidth( card.name )
					local name = Word.new( _G.pixelFont, card.name, x+(card.width*sx)/2-(w/2)+2 , y+28 ,0,1,1 )
					name.color={0,0,0,1}					
					local cost = Word.new( _G.engPixelFont, card.cost, x+18 , y+16)
					local info = Word.new( _G.pixelFont, card.info, x+28 , y+(card.height*sy)/2+48,0, 0.9,0.9)

					table.insert(cards,card)
					table.insert(cards,name)
					table.insert(cards,cost)
					table.insert(cards,info)

					count=count+1
				end
				drag.OnHold=function(self,mx,my)
					local prePos = drag.sprite.transform.position.y
					drag.sprite.transform.position.y=MathExtend.clamp(my-40,height*0.05+30,height*0.05-40+720)
					
					local moveDir = prePos-drag.sprite.transform.position.y
					basicTitle.transform.position.y = basicTitle.transform.position.y+moveDir
					advTitle.transform.position.y = advTitle.transform.position.y+moveDir
					for k,v in pairs(cards) do
						if getmetatable(v)==Word then
							v.transform.position.y = v.transform.position.y+moveDir	/ v.transform.scale.y					
						else
							v.sprite.transform.position.y = v.sprite.transform.position.y+moveDir
						end
					end
				end
				TableFunc.merge(popLabel.label.Drawable,cards)

				local mask=Assets.Images.instance("chooseMask",0,0,0,1,1,0,0)
				popLabel:SetStancil(mask)
				table.insert(popLabel.label.Drawable ,basicTitle)
				table.insert(popLabel.label.Drawable ,advTitle)
				table.insert(popLabel.label.Drawable ,bar)
				table.insert(popLabel.label.Drawable ,drag)
				table.insert(popLabel.label.CheckRange ,drag)


				table.insert(scene.UIMachine.current.stack,popLabel)
			end
		end
	end
	return {characterLabel=characterLabel,shadowLabel=shadowLabel,infoLabel=infoLabel,gridbuttonLabel=gridbuttonLabel,buttonlabel=buttonlabel}	
end

local EmptyState = State.new("EmptyState")
local CutSceneState = State.new("CutSceneState")
local NormalState = State.new("NormalState")
scene.UIMachine = Machine.new({
	initial=EmptyState,
	states={
		EmptyState , CutSceneState, NormalState 
	},
	events={
		{state=EmptyState,to='CutSceneState'},
		{state=CutSceneState,to='NormalState'},
		{state=NormalState,to='CutSceneState'},
	}
})
scene.UIMachine.reMakeStack=function(state)
	state.stack={}
	local labels = MakeLabel()
	--set OnClick
	for k,v in pairs(TeamData.AllHeros) do
		if v.lock == false then
			labels.gridbuttonLabel.label.CheckRange[k].OnClick=function () TeamData.Switch(v) scene.UIMachine.reMakeStack(scene.UIMachine.current) end --reMakeStack(scene.UIMachine.current )
		end
	end
	local allButtonLabel = Label.merge("allButton",labels.gridbuttonLabel,labels.buttonlabel)
	table.insert(state.stack,basicImg  )
	table.insert(state.stack,labels.shadowLabel)
	table.insert(state.stack,labels.characterLabel)
	table.insert(state.stack,allButtonLabel)
	table.insert(state.stack,labels.infoLabel)
end
CutSceneState.DoOnEnter=function(self)
	self.stack={}
	self.waitTime=0.4
	local dark = Assets.Images.instance("choose_pop_BG",0,0,0,1,1,0,0)
	dark.color={1,1,1,1}
	Motion.NewTable(dark.motion,Motion.new({self.currentTime ,1 ,0 ,self.waitTime},'inQuad' ,function(motion,dt) dark.color[4]  = Motion.Lerp(motion,dt)end))
	local darkLabel = Label.new("dark",{Drawable={dark},Motion={dark}})

	local labels = MakeLabel()

	--merge buttonlabel
	local allButtonLabel = Label.merge("allButton",labels.gridbuttonLabel,labels.buttonlabel)
	for k,v in pairs(allButtonLabel.label.CheckRange) do
		v.isLock=true
	end

	table.insert(self.stack,basicImg  )
	table.insert(self.stack,labels.shadowLabel)
	table.insert(self.stack,labels.characterLabel)
	table.insert(self.stack,allButtonLabel)
	table.insert(self.stack,labels.infoLabel)
	table.insert(self.stack,darkLabel)
end

CutSceneState.Do=function(self,dt,scene)
	scene.Drawable={}
	scene.CheckRange={}
	scene.Altas={}
	scene.Motion={}

	for k,v in pairs(self.stack) do
		for key,tab in pairs(v.label) do
			if key =="Motion" then
				SetMotion(scene,tab)
			else
				table.insert(scene[key],v.label[key])
			end				
		end
	end
	self.currentTime = self.currentTime+dt
	if self.currentTime >= self.waitTime then
		self.currentTime=0
		scene.UIMachine:TransitionTo('NormalState')
	end
end
CutSceneState.DoOnLeave=function (self)
	for k,Label in pairs(self.stack) do
		if Label.name=="allButton" then
			for i,button in pairs(Label.label.CheckRange) do
				button.isLock=false
			end
		end
	end
end
NormalState.DoOnEnter=function(self)
	self.stack={}

	local labels = MakeLabel()
		--set OnClick
	for k,v in pairs(TeamData.AllHeros) do
		if v.lock == false then
			labels.gridbuttonLabel.label.CheckRange[k].OnClick=function () TeamData.Switch(v) scene.UIMachine.reMakeStack(scene.UIMachine.current) end --reMakeStack(scene.UIMachine.current )
		end
	end
	--merge buttonlabel
	local allButtonLabel = Label.merge("allButton",labels.gridbuttonLabel,labels.buttonlabel)

	table.insert(self.stack,basicImg  )
	table.insert(self.stack,labels.shadowLabel)
	table.insert(self.stack,labels.characterLabel)
	table.insert(self.stack,allButtonLabel)
	table.insert(self.stack,labels.infoLabel)
end
NormalState.Do=function (self,dt,scene)
	scene.Drawable={}
	scene.CheckRange={}
	scene.Altas={}
	scene.Motion={}

	for k,v in pairs(self.stack) do
		for key,tab in pairs(v.label) do
			if key =="Motion" then
				SetMotion(scene,tab)
			else
				table.insert(scene[key],v.label[key])
			end				
		end
	end

end
scene.UIMachine.Update=function(self,dt,scene,...)
	self.current:Do(dt,scene,...)

end	
function scene.Enter(win_width,win_height)
	width=win_width
	height=win_height
	TeamData.init()
	scene.UIMachine:TransitionTo('CutSceneState')

end
function scene.Exit()
	SaveFileMgr.Save(SaveFileMgr.CurrentSave)
	scene.Clear(scene)
end

function scene.Update(dt,mx,my,leftClick,preClick)
	scene:MouseAct(mx,my,leftClick,preClick)
	scene:PlayAltas(dt)
	scene.UIMachine:Update(dt,scene)
end

function scene.debugDraw(mx,my)

end
return scene