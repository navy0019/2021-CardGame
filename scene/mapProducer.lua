local Scene = require('lib.scene')
local SceneMgr = require('lib.sceneManager')

local Battle = require('lib.battle')
local Motion = require("lib.motion")
local Word = require('lib.word')
local MonsterGenerator = require("lib.monsterGenerator")
local TableFunc = require("lib.tableFunc")
local Label = require("lib.Label")
local Curve = require('lib.curve')
local Graph = require('lib.graph')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local Assets = require('resource.allAssets')

local SaveFileMgr=require('save.saveManager')

local Mouse = require('other.mouse')

local MapGenerator ={func={},events={},
					characterData={},originHead=nil,
					data={stepFromDoor=0,money=0,passedRoom=0,dropItem=1,sceneList={},randomSeed=nil}
					}
local battleUse={}

local function SetMotion( scene,datas )
	for k,v in pairs(datas) do
		for j,motion in pairs(v.motion) do
			table.insert(scene.Motion,motion)
		end
	end
end
local function DrawStatus(scene,characterData,imgtab)
	for k,v in pairs(characterData) do
		if v.state.current.name ~= 'Death' then
			--status
			local count=0
			for j,tab in pairs(v.data.Status) do
				for i,status in pairs(tab) do
					count=count+1
					local x,y = v.sprite.transform.position.x, v.sprite.transform.position.y
					local img,word

					if status.name == 'shield' and v.data.shield>0 then
						img = Assets.Images.instance(status.name, x+v.space+(count-1)*32 ,y+v.height+12,0 ,0.8,0.8)
						word = Word.new( _G.engPixelFont, v.data.shield, x+v.space+(count-1)*32, y+v.height+12)
						table.insert(imgtab,img)
						table.insert(imgtab,word)

					elseif status.name ~= 'shield' then
						img = Assets.Images.instance(status.name, x+v.space+(count-1)*32 ,y+v.height+12,0 ,0.8,0.8)
						word = Word.new( _G.engPixelFont, status.round, x+v.space+(count-1)*32, y+v.height+12)
						table.insert(imgtab,img)
						table.insert(imgtab,word)
					end
				end
			end
			
			local x,y = v.sprite.transform.position.x , v.sprite.transform.position.y
			local step = (v.width-80) / v.originData.hp
			if v.data.hp > 0 then
				local blood = Graph.new('rectangle','fill',x+v.space-8 , y+v.height+32 ,v.data.hp*step ,12)
				local bloodoutline = Graph.new('rectangle','fill',blood.x-4 , blood.y-4 ,v.data.hp*step+8 ,20)
				bloodoutline.color={0,0,0,1}
				table.insert(imgtab,bloodoutline)
				table.insert(imgtab,blood)

				local hpword = Word.new( _G.engPixelFont, v.data.hp.." / "..v.originData.hp , x+v.width/2-40, blood.y-2 )
				table.insert(imgtab,hpword)
			end
		end
	end
end
local function DrawCard(scene,cardTab,drawable,buttons,cardmotion)
	for k,v in pairs(cardTab) do
		if v then
			local x ,sx , y , sy = v.sprite.transform.position.x ,v.sprite.transform.scale.x ,v.sprite.transform.position.y ,v.sprite.transform.scale.y
			local topLeftX,topLeftY = x-(v.width*sx/2) , y-(v.height*sy)
			if v.sprite.transform.offset.y<v.height then
				topLeftY=y-(v.height*sy/2)
			end
			local wordw ,costw =_G.pixelFont:getWidth( v.name ),_G.pixelFont:getWidth( v.cost )
			local infow = 153/2--word width limit
			local name = Word.new( _G.pixelFont, v.name   , topLeftX+v.width*sx*0.5-(wordw/2), topLeftY+v.height*sy*0.13  ,0,sx*1.5,sy*1.5 )
			local cost = Word.new( _G.engPixelFont, v.cost, topLeftX+v.width*sx*0.1 , topLeftY+v.height*sy*0.08  ,0,sx*1.5,sy*1.5 )
			name.color={0,0,0,1}
			local info = Word.new( _G.pixelFont, v.info, topLeftX+v.width*sx*0.5-infow+4 , topLeftY+v.height*sy*0.71 ,0,sx*1.2,sy*1.2 )
			if not TableFunc.find(cardmotion,v) then
				table.insert(cardmotion,v)
			end
			table.insert(drawable,v)

			if v.motionMachine.current.name~="Drop" then
				table.insert(drawable,name)
				table.insert(drawable,cost)
				table.insert(drawable,info)
			end
			table.insert(buttons,v)
		end
	end
end	
function MapGenerator.func.ResetHeroData()
	for k,v in pairs(MapGenerator.characterData) do
		v.data=TableFunc.copy(v.originData)
		v.data.Status={before={}, after={}, always={}}
	end
end
function MapGenerator.func.ResetMap()
	SceneMgr.Adventure:Clear()
	SceneMgr.AddScene(SceneMgr.Adventure ,MapGenerator.originHead.name ,MapGenerator.originHead)

	MapGenerator.data.stepFromDoor=0
	MapGenerator.data.money=0
	MapGenerator.data.passedRoom=0
	MapGenerator.data.dropItem=1
	MapGenerator.data.sceneList={}

end
local function GenerateMapEvent()

	local newSeed = os.time()
	_G.rng:setSeed(newSeed)

	local eventWord={door={},eventImg={},eventButton={},isBattle=false,ranState=nil,ranSeed=nil}
	local safeEvent = {'blackSmith','campfire','potionTable'}

	eventWord.ranState = _G.rng:getState()
	eventWord.ranSeed = _G.rng:getSeed()

	-----1st chance-----
	local ran = _G.rng:random(1,10)
	if MapGenerator.data.stepFromDoor > 6 and ran < MapGenerator.data.stepFromDoor then
		table.insert(eventWord.door,'exitDoor')
	end
	-----2nd chance-----
	ran = _G.rng:random(1,10)----put random safe event
	if ran > 5 then
		local event = safeEvent[_G.rng:random(#safeEvent)]
		local eventImg = Assets.Images.instance(event,550,122,0,1,1,0,0)			
		local eventButton = Assets.Buttons.instance('button_'..event,663,96)

		table.insert(eventWord.eventImg,event)
		table.insert(eventWord.eventButton,'button_'..event)

	end

	-----3rd chance-----
	ran = _G.rng:random(1,10)--decide event or battle
	if ran > 5 then	
		local ran2 = _G.rng:random(1,10)
		if ran2 > 5 then
			----battle
			eventWord.isBattle=true
		end	
		
	else
		---event
		local eventButton = Assets.Buttons.instance('button_event',663,96)
		table.insert(eventWord.eventButton,'button_event')				
	end

	return eventWord
end
function MapGenerator.func.initScene(scene)

	local eventsNormal = {}
	local eventsButton = {}

	local battleUI = Assets.Images.instance('battle_UI',0,0,0,1,1,0,0)
	local BG = Assets.Images.instance('bg_adv01',0,0,0,1,1,0,0)
	local dark = Assets.Images.instance("choose_pop_BG",0,0,0,1,1,0,0)

	local heros = MapGenerator.characterData
	for k,hero in pairs(heros) do
		if hero ~='empty' then
			hero.sprite.transform.position.x=693-hero.width*k+hero.space*(k-1)
			hero.sprite.transform.position.y=472-hero.height
		end
	end
	if #scene.events.door >0 then
		local door = Assets.Images.instance('exitDoor',100,103,0,1,1,0,0)
		table.insert(eventsNormal,door)

	end
	for k,v in pairs(scene.events.eventImg) do
		local img=Assets.Images.instance(v,550,122,0,1,1,0,0)
		table.insert(eventsNormal,img)
	end
	for k,v in pairs(scene.events.eventButton) do
		local img=Assets.Buttons.instance(v,663,96)
		if #scene.events.eventButton>1 then		
			img.sprite.transform.position.x=663 + (img.width*0.6) * math.pow(-1,k)
		end
		
		table.insert(eventsNormal,img)
		table.insert(eventsButton,img)
	end

	--------normalUI---------------
	local nextRoom=Assets.Buttons.instance('nextRoom',843,121)
	nextRoom.OnClick=function () 
		MapGenerator.data.stepFromDoor=MapGenerator.data.stepFromDoor+1 
		scene.switchingScene = scene.next
	end

	local preRoom=Assets.Buttons.instance('preRoom',479,121)
	preRoom.OnClick=function ()
		if  scene == SceneMgr.Adventure.head then 
			MapGenerator.func.ResetMap()
			MapGenerator.func.ResetHeroData()

			MapGenerator.func.Save()
			scene.switchingScene = 'Main'
		else
			MapGenerator.data.stepFromDoor=MapGenerator.data.stepFromDoor-1
			scene.switchingScene = scene.previous
		end
	end
	local normalButtons={nextRoom,preRoom,unpack(eventsButton)}

	--------battleUI---------------
	if scene.events.isBattle then 
		local pRound = Assets.Images.instance('playerRound', 713.5 ,276,0,1.5,1.5)
		pRound.color={1,1,1,0}
		local eRound = Assets.Images.instance('enemyRound', 713.5 ,276,0,1.5,1.5)
		eRound.color={1,1,1,0}

		local passButton = Assets.Buttons.instance('pass',1215,570)

		local passBWord =Word.new( _G.pixelFont,'結束回合',passButton.sprite.transform.position.x ,passButton.sprite.transform.position.y)
		passBWord.transform.position.x=passBWord.transform.position.x+passBWord.width/2
		passBWord.transform.position.y=passBWord.transform.position.y+passBWord.height/2 +8

		local vicBoard = Assets.Images.instance('vic_board', 713 ,350)
		local vicWord = Assets.Images.instance('vic_Word', 713 ,120)
		local vicButton = Assets.Buttons.instance('vic_Button',636,556)

		local loseWord = Assets.Images.instance('lose_Word', 713 ,120)
		local loseButton = Assets.Buttons.instance('lose_Button',636,556)

		battleUse={playerRound=pRound,enemyRound=eRound,passButton=passButton,passBWord=passBWord,dark=dark,vicBoard=vicBoard,vicButton=vicButton,vicWord=vicWord,loseWord=loseWord,loseButton=loseButton}

	end

	scene.AllLabels.basicImg  =Label.new("basicImg"		,{Drawable={BG},Motion={BG}} )
	scene.AllLabels.battleImg =Label.new("battleImg"	,{Drawable={battleUI}} )
	scene.AllLabels.normalImg =Label.new("normalImg"	,{Drawable=eventsNormal})
	scene.AllLabels.normalButtons=Label.new("normalButtons"	,{Drawable=normalButtons,CheckRange=normalButtons})

	local EmptyState = State.new("EmptyState")
	local CutSceneState = State.new("CutSceneState")
	local NormalState = State.new("NormalState")
	local BattleState = State.new("BattleState")

	local character = Label.new("character"	,{Drawable=MapGenerator.characterData,Altas=MapGenerator.characterData,Motion=MapGenerator.characterData})

	scene.UIMachine = Machine.new({
		initial=EmptyState,
		states={
			EmptyState , CutSceneState, NormalState , BattleState
		},
		events={
			{state=EmptyState,to='CutSceneState'},
			{state=CutSceneState,to='NormalState'},
			{state=CutSceneState,to='BattleState'},
			{state=NormalState,to='CutSceneState'},
			{state=NormalState,to='BattleState'},
			{state=BattleState,to='NormalState'}
		}
	})
	
	CutSceneState.DoOnEnter=function(self,scene)
		self.stack={}
		self.waitTime=0.4
		
		dark.color={1,1,1,1}
		Motion.NewTable(dark.motion,Motion.new({self.currentTime ,1 ,0 ,self.waitTime},'inQuad' ,function(motion,dt) dark.color[4]  = Motion.Lerp(motion,dt)end))
		local darkLabel = Label.new("dark",{Drawable={dark},Motion={dark}})

		table.insert(self.stack, scene.AllLabels.basicImg  )
		table.insert(self.stack,character)
		table.insert(self.stack,darkLabel)
	end

	CutSceneState.Do=function(self,dt,scene,battle)
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
			if scene.events.isBattle then 
				scene.UIMachine:TransitionTo('BattleState',scene,battle)
			elseif scene.events.isBattle==false then
				scene.UIMachine:TransitionTo('NormalState',scene)
			end
		end
	end
	NormalState.DoOnEnter=function(self,scene)
		self.stack={}
		table.insert(self.stack,scene.AllLabels.basicImg  )
		table.insert(self.stack,scene.AllLabels.normalImg )
		table.insert(self.stack,character)
		table.insert(self.stack,scene.AllLabels.normalButtons)
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
	BattleState.DoOnEnter=function(self,scene,battle)
		self.stack={}
		table.insert(self.stack,scene.AllLabels.basicImg  )
		table.insert(self.stack,scene.AllLabels.battleImg )
		table.insert(self.stack,character)
		table.insert(self.stack,Label.new("monster",{Drawable=battle.characterData.monsterData ,Altas=battle.characterData.monsterData ,Motion= battle.characterData.monsterData}) )
		table.insert(self.stack,Label.new("tempprint",{Drawable=scene.TempPrint}))

		local passButton,passBWord,pRound,eRound = battle.label.passButton ,battle.label.passBWord ,battle.label.playerRound ,battle.label.enemyRound
		table.insert(self.stack,Label.new("battleUse",{ Drawable={pRound,eRound,passButton,passBWord} ,Motion={pRound,eRound}  }))

		local actPoint = Word.new( _G.engPixelFont, battle.battleData.actPoint, 124 , 626, 0 ,2 ,2 )
		local deckSize = Word.new( _G.engPixelFont, battle.battleData.deckSize, 80  , 732, 0 ,3 ,3 )
		local dropSize = Word.new( _G.engPixelFont, battle.battleData.dropSize, 1300, 732, 0 ,3 ,3 )	
		local disappearSize = Word.new( _G.engPixelFont, battle.battleData.disappearSize, 1352, 652, 0 ,2 ,2 )	
		local battleWords=Label.new("battleWords",{Drawable={actPoint,deckSize,dropSize,disappearSize}})
		battleWords.Update=function()
			actPoint.text = battle.battleData.actPoint
			deckSize.text = battle.battleData.deckSize
			dropSize.text = battle.battleData.dropSize
			disappearSize.text = battle.battleData.disappearSize
		end
		table.insert(self.stack,battleWords)

		local status ={} 
		DrawStatus(scene,battle.characterData.heroData,status)
		DrawStatus(scene,battle.characterData.monsterData,status)
		local statusLabel = Label.new("status",{Drawable=status})
		table.insert(self.stack,statusLabel)
		statusLabel.Update=function(self)
			status ={} 
			DrawStatus(scene,battle.characterData.heroData,status)
			DrawStatus(scene,battle.characterData.monsterData,status)
			self.label={Drawable=status}
		end

		local cards ={}
		local cardmotion = {}
		DrawCard(scene, battle.battleData.hand ,cards,buttons,cardmotion)
		DrawCard(scene, battle.battleData.tempDrop,cards,buttons,cardmotion)
		DrawCard(scene, battle.battleData.tempDeal,cards,buttons,cardmotion)
		local cardLabel = Label.new("card",{Drawable=cards , Motion=cardmotion ,CheckRange=buttons})
		cardLabel.Update=function(self)
			local buttons = {passButton}
			cards ={}
			cardmotion = {}
			DrawCard(scene, battle.battleData.hand ,cards,buttons,cardmotion)
			DrawCard(scene, battle.battleData.tempDrop,cards,buttons,cardmotion)
			DrawCard(scene, battle.battleData.tempDeal,cards,buttons,cardmotion)
			self.label={Drawable=cards , Motion=cardmotion ,CheckRange=buttons}
		end
		table.insert(self.stack,cardLabel)

	end
	BattleState.Do=function(self,dt,scene,battle)
		scene.Drawable={}
		scene.CheckRange={}
		scene.Altas={}
		scene.Motion={}

		for k,v in pairs(self.stack) do
			v:Update()
			for key,tab in pairs(v.label) do			
				if key =="Motion" then
					SetMotion(scene,tab)
				else
					table.insert(scene[key],v.label[key])
				end				
			end
		end

		if battle.choose.curve~= nil then
			table.insert(scene.Drawable,{battle.choose.curve})
		end

		if scene.events.isBattle==false then
			scene.UIMachine:TransitionTo('NormalState',scene)
		end
	end

end

function MapGenerator.func.AddNewScene(win_width,win_height,name,events)
	local name = name or SceneMgr.Adventure.length
	local nextScene = Scene.new({Drawable={},CheckRange={},Altas={},Print={},TempPrint={},Motion={},AllLabels={},events={},battle=nil,firstLoad=true,next=nil,previous=nil,name=name})
	nextScene.events = events or GenerateMapEvent(nextScene)
	SceneMgr.AddScene(SceneMgr.Adventure,nextScene.name,nextScene)	

	table.insert(MapGenerator.data.sceneList,{name=nextScene.name,events=nextScene.events})

	MapGenerator.func.initScene(nextScene)

	nextScene.Enter=function(win_width,win_height)
		if #nextScene.events.door >0 and SceneMgr.Adventure.head~=nextScene then
			MapGenerator.data.stepFromDoor=0
			local scene=SceneMgr.Adventure:MoveTo(SceneMgr.CurrentScene.name)
			SceneMgr.Adventure.head=scene
			local head={name=SceneMgr.Adventure.head.name,events=SceneMgr.Adventure.head.events}
			MapGenerator.data.sceneList={head}
			enterTri=true
		end
		if nextScene.events.isBattle then
			nextScene.battle=Battle.new(MapGenerator,battleUse,nextScene)
		end
		MapGenerator.func.Save()		
		nextScene.UIMachine:TransitionTo('CutSceneState',nextScene)
		
	end
	nextScene.Update=function(dt,mx,my,leftClick,preClick,win_width,win_height)
		MapGenerator.func.Check(win_width,win_height)
		nextScene:PlayAltas(dt)
		if nextScene.events.isBattle then
			nextScene:MouseAct(mx,my,leftClick,preClick ,nextScene.battle.choose ,nextScene.battle.characterData)
			nextScene.battle:Update(dt)
		else
			nextScene:MouseAct(mx,my,leftClick,preClick)
		end
		nextScene.UIMachine:Update(dt,nextScene,nextScene.battle)
	end
	nextScene.Exit=function()

	end
	nextScene.debugDraw=function()
		--[[if nextScene.battle then
			love.graphics.print('hand'..#nextScene.battle.battleData.hand,5,25)
			love.graphics.setFont(_G.pixelFont)
			for k,v in pairs(nextScene.battle.battleData.hand) do
				love.graphics.print(v.name,5,40+(k-1)*17)
			end
			love.graphics.setFont(_G.defaultFont)
		end]]
	end

end
function MapGenerator.func.Save()
	local saveData = SaveFileMgr.CurrentSave

	saveData.MapData = MapGenerator.data
	saveData.CurrentTeamData={}
	for k,v in pairs(MapGenerator.characterData) do
		if v ~= 'empty' then
			table.insert(saveData.CurrentTeamData,v.data)
		end
	end
	saveData.CurrentScene=SceneMgr.CurrentScene.name
	SaveFileMgr.Save(saveData)
		
end
function MapGenerator.func.Load(win_width,win_height)
	MapGenerator.func.ResetMap()
	MapGenerator.func.SetAdvData()
	local saveData = SaveFileMgr.CurrentSave
	MapGenerator.data=saveData.MapData

	local list = TableFunc.copy(saveData.MapData.sceneList)
	saveData.MapData.sceneList={}
	MapGenerator.data.sceneList={}
	
	for k,v in pairs(list) do
		if type(v.name)=='number' then
			MapGenerator.func.AddNewScene(win_width,win_height,v.name,v.events)
		elseif v.name=='advStart' then
			SceneMgr.AddScene(SceneMgr.Adventure ,MapGenerator.originHead.name ,MapGenerator.originHead)
		end
	end
	
end
function MapGenerator.func.Check(win_width,win_height)
	if SceneMgr.Adventure:Contain(SceneMgr.CurrentScene) and SceneMgr.CurrentScene.next == nil then
		MapGenerator.func.AddNewScene(win_width ,win_height)
	end
end
function MapGenerator.func.SetAdvData()
	MapGenerator.characterData={}
	for k,v in pairs(SaveFileMgr.CurrentSave.CurrentTeam) do
		if v ~= 'empty' then
			local hero = Assets.Characters.instance(v , 0 ,-24)
			if SaveFileMgr.CurrentSave.CurrentTeamData[k] then
				hero.data=SaveFileMgr.CurrentSave.CurrentTeamData[k]
			end
			hero.data.teamPos=k
			table.insert(MapGenerator.characterData,hero)
		else
			table.insert(MapGenerator.characterData,'empty')
		end
	end
end
return MapGenerator