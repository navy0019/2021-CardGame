local Scene = require('lib.scene')
local SceneMgr = require('lib.sceneManager')
local Word = require('lib.word')
local Label = require("lib.Label")
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Motion = require("lib.motion")

local MapGenerator = require('scene.mapProducer')

local Assets = require('resource.allAssets')

local SaveFileMgr=require('save.saveManager')

local scene = Scene.new({Drawable={},CheckRange={},Altas={},Print={},TempPrint={},Motion={},AllLabels={},firstLoad=true,name='advStart',next=nil,previous=nil})
local function SetMotion( scene,datas )
	for k,v in pairs(datas) do
		for j,motion in pairs(v.motion) do
			table.insert(scene.Motion,motion)
		end
	end
end

local function MakeLabel(w,h)
	local characterLabel = Label.new("character",{Drawable={},Altas={}})
	local imgLabel = Label.new("omg",{Drawable={}})
	local buttonlabel = Label.new("button",{Drawable={},CheckRange={}})

	for k,hero in ipairs(MapGenerator.characterData) do
		if hero ~='empty' then
			hero.sprite.transform.position.x=693-hero.width*k+hero.space*(k-1)
			hero.sprite.transform.position.y=472-hero.height
			table.insert(characterLabel.label.Drawable,hero)
			table.insert(characterLabel.label.Altas,hero)
		end
	end

	local BG=Assets.Images.instance('bg_adv01',0,0,0,1,1,0,0)
	table.insert(imgLabel.label.Drawable,BG)

	local UILabel = {}
	local nextRoom=Assets.Buttons.instance('nextRoom',843,121)
	nextRoom.OnClick=function ()
		MapGenerator.data.stepFromDoor=MapGenerator.data.stepFromDoor+1
		scene.switchingScene = scene.next
	end

	local preRoom=Assets.Buttons.instance('preRoom',479,121)
	preRoom.OnClick=function ()
		if  scene == SceneMgr.Adventure.head then
			MapGenerator.func.ResetMap()
			scene.switchingScene = 'Main'
			MapGenerator.func.Save()
		end
	end
	table.insert(buttonlabel.label.Drawable,nextRoom)
	table.insert(buttonlabel.label.Drawable,preRoom)
	table.insert(buttonlabel.label.CheckRange,nextRoom)
	table.insert(buttonlabel.label.CheckRange,preRoom)

	return {characterLabel=characterLabel,imgLabel=imgLabel,buttonlabel=buttonlabel}
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

CutSceneState.DoOnEnter=function(self,w,h)
	self.stack={}
	self.w=w
	self.h=h
	self.waitTime=0.4
	local dark = Assets.Images.instance("choose_pop_BG",0,0,0,1,1,0,0)
	dark.color={1,1,1,1}
	Motion.NewTable(dark.motion,Motion.new({self.currentTime ,1 ,0 ,self.waitTime},'inQuad' ,function(motion,dt) dark.color[4]  = Motion.Lerp(motion,dt)end))
	local darkLabel = Label.new("dark",{Drawable={dark},Motion={dark}})

	local labels = MakeLabel(w,h)

	table.insert(self.stack,labels.imgLabel )
	table.insert(self.stack,labels.characterLabel)
	table.insert(self.stack,labels.buttonlabel)
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
		scene.UIMachine:TransitionTo('NormalState',self.w,self.h)	
	end
end
NormalState.DoOnEnter=function(self,w,h)
	self.stack={}
	local labels = MakeLabel(w,h)

	table.insert(self.stack,labels.imgLabel )
	table.insert(self.stack,labels.characterLabel)
	table.insert(self.stack,labels.buttonlabel)
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
function scene.Init( ... )
	MapGenerator.originHead=scene
end
function scene.Enter(win_width,win_height)
	MapGenerator.func.Save()
	scene.UIMachine:TransitionTo('CutSceneState',win_width,win_height)
end
function scene.Exit()
	scene.Clear(scene)
end
function scene.Update(dt,mx,my,leftClick,preClick,win_width,win_height)
	MapGenerator.func.Check(win_width,win_height)
	scene:MouseAct(mx,my,leftClick,preClick)
	scene:PlayAltas(dt)
	scene.UIMachine:Update(dt,scene)
end
function scene.debugDraw()

end
return scene