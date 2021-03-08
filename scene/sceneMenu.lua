local Scene = require('lib.scene')
local SceneMgr = require('lib.sceneManager')
local Motion = require("lib.motion")
local Label = require("lib.Label")
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Word = require('lib.word')
local TeamData = require('lib.teamData')

local MapGenerator = require('scene.mapProducer')

local SaveFileMgr=require('save.saveManager')

local Assets = require('resource.allAssets')
local s2 = require('scene.advSceneStart')

local scene = Scene.new({Drawable={},CheckRange={},Altas={},Print={},TempPrint={},Motion={},AllLabels={},firstLoad=true,name='Menu'})
local function SetMotion( scene,datas )
	for k,v in pairs(datas) do
		for j,motion in pairs(v.motion) do
			table.insert(scene.Motion,motion)
		end
	end
end

local function MakeLabel(w,h)
	local characterLabel = Label.new("character",{Drawable={},Altas={}})
	local imgLabel = Label.new("img",{Drawable={}})

	local BG=Assets.Images.instance('makeTeamBG',0,0,0,1,1,0,0)
	table.insert(imgLabel.label.Drawable,BG)

	return {characterLabel=characterLabel,imgLabel=imgLabel}
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
		{state=NormalState,to='NormalState'}
	}
})

CutSceneState.DoOnEnter=function(self,w,h)
	self.stack={}
	self.waitTime=3
	self.w=w
	self.h=h

	self.dark = Assets.Buttons.instance("choose_pop_BG",0,0,0,1,1,0,0)
	self.dark.color={1,1,1,1}
	self.dark.isLock=true
	Motion.NewTable(self.dark.motion,Motion.new({0 ,1 ,0 ,0.4},'inQuad' ,function(motion,dt) self.dark.color[4]  = Motion.Lerp(motion,dt)end))
	self.dark.OnClick=function()
		scene.UIMachine:TransitionTo('NormalState',self.w,self.h)
	end

	self.passAny = Word.new( _G.engPixelFont, 'Pass Any Button', w/2, h*0.7)
	self.passAny.transform.scale={x=3,y=3}
	self.passAny.transform.position.x=self.passAny.transform.position.x-self.passAny.width/3*0.5
	self.passAny.limit=self.passAny.width
	Motion.NewTable(self.passAny.motion,Motion.new({0 ,0.2 ,1 ,2.8},'linear' ,function(motion,dt) self.passAny.color[4]  = Motion.Mirror(motion,dt)end))

	local darkLabel = Label.new("dark",{Drawable={self.passAny,self.dark},Motion={self.passAny,self.dark},CheckRange={self.dark}})

	local labels = MakeLabel(w,h)

	table.insert(self.stack,labels.imgLabel )
	table.insert(self.stack,labels.characterLabel)

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
	if self.currentTime >= 1 then
		self.dark.isLock=false
	end
	if self.currentTime >= self.waitTime then
		self.currentTime=0
		Motion.NewTable(self.passAny.motion,Motion.new({0 ,0.2 ,1 ,2.8},'linear' ,function(motion,dt) self.passAny.color[4]  = Motion.Mirror(motion,dt)end))
	end
end

NormalState.DoOnEnter=function(self,w,h)
	self.stack={}
	self.w=w
	self.h=h
	local buttonlabel = Label.new("button",{Drawable={},CheckRange={}})
	local half = w/2
	
	for k=1,2 do
		local file = love.filesystem.getInfo('save/savedata_'..k..'.json')
		local button = Assets.Buttons.instance('saveDataButton',half,(0.65+(k-1)*0.12)*h)
		button.sprite.transform.position.x=button.sprite.transform.position.x-button.width/2
		local x,y = button.sprite.transform.position.x ,button.sprite.transform.position.y

		--draw save info		
		if file then
			local saveData = SaveFileMgr.Load('savedata_'..k)
			button.OnClick=function ()
				SaveFileMgr.CurrentSave=saveData
				TeamData.UpdateFromSaveFile()
				if type(saveData.CurrentScene)=='string' and saveData.CurrentScene~='advStart'then
					scene.switchingScene = saveData.CurrentScene
				else
					MapGenerator.func.Load(w,h)
					scene.switchingScene = SceneMgr.Adventure:MoveTo(saveData.CurrentScene)
					if scene.switchingScene.events and #scene.switchingScene.events.door >0 then
						SceneMgr.Adventure.head=scene.switchingScene
					end
				end				
			end
			
			--draw Current Team			
			for i,hero in pairs(saveData.CurrentTeam) do
				local img = Assets.Images.instance('head_72_'..hero,x,y)
				img.sprite.transform.position.x=x+img.width*0.5+8+(i-1)*img.width+(i-1)*8
				img.sprite.transform.position.y=y+img.height*0.5+(button.height-img.height)*0.5
				table.insert(buttonlabel.label.Drawable,img)
			end
			local deleteButton = Assets.Buttons.instance('x',self.w*0.73,y+button.height/2)
			deleteButton.sprite.transform.position.y=deleteButton.sprite.transform.position.y-deleteButton.height/2
			deleteButton.OnClick=function()
				local path = love.filesystem.getRealDirectory("/save/savedata_"..k..".json")
				os.remove(path..'/save/savedata_'..k..'.json')
				scene.UIMachine:TransitionTo('NormalState',self.w,self.h)	
			end
			local sceneName = Word.new( _G.engPixelFont, 'CurrentScene: '..saveData.CurrentScene, x+button.width*0.6, y+button.height*0.1)
			sceneName.limit=1000
			table.insert(buttonlabel.label.Drawable,sceneName)

			table.insert(buttonlabel.label.Drawable,deleteButton)
			table.insert(buttonlabel.label.CheckRange,deleteButton)
		else
			--if Empty then click to add new saveFile
			local word = Word.new( _G.engPixelFont, 'Empty', x+button.width/2, y+button.height/2)
			word.limit=word.width
			word.align='center'
			word.transform.position.x=word.transform.position.x-word.width*0.3
			word.transform.scale= {x=2,y=2}
			table.insert(buttonlabel.label.Drawable,word)
			button.OnClick=function ()
				local newFile = SaveFileMgr.NewSaveFile(k)

				SaveFileMgr.CurrentSave=newFile
				SaveFileMgr.Save(newFile)
				TeamData.UpdateFromSaveFile()
				scene.switchingScene = newFile.CurrentScene				
			end		
		end
		table.insert(buttonlabel.label.Drawable,button)
		table.insert(buttonlabel.label.CheckRange,button)
	end
	local labels = MakeLabel(w,h)

	table.insert(self.stack,labels.imgLabel )
	table.insert(self.stack,labels.characterLabel)
	table.insert(self.stack,buttonlabel)
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
function scene.Enter(win_width,win_height)
	scene.UIMachine:TransitionTo('CutSceneState',win_width,win_height)
end
function scene.Exit()
	scene.Clear(scene)
end
function scene.Update(dt,mx,my,leftClick,preClick)
	scene:MouseAct(mx,my,leftClick,preClick)
	scene:PlayAltas(dt)
	scene.UIMachine:Update(dt,scene)
end
function scene.debugDraw()
end
return scene