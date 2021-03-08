defaultFont=nil
defaultFontSize=nil
pixelFont = love.graphics.newFont("assets/FZBitmap-GBK-11X12-2.ttf",20)
engPixelFont=love.graphics.newFont("assets/Minecraft.ttf",20)
defaultFont2 = love.graphics.newFont("assets/STHeiti_Light.ttc",14)
rng = love.math.newRandomGenerator()

local SceneMgr = require('lib.sceneManager')
local Word = require('lib.word')
local Curve = require('lib.curve')
local Graph = require('lib.graph')
local Motion = require("lib.motion")
local TableFunc = require("lib.tableFunc")

local SaveFileMgr=require('save.saveManager')

local menu = require('scene.sceneMenu')
local s1 = require('scene.sceneMain')
local s2 = require('scene.advSceneStart')
local MapGenerator = require('scene.mapProducer')
local makeTeam = require('scene.sceneMakeTeam')

local Mouse = require('other.mouse')

local win_width
local win_height
local leftClick
local preClick =false
local mx,my
local CurrentScene
local firstLoad = true

local isClick = false

function love.load()
	pixelFont:setFilter('nearest','nearest')
	engPixelFont:setFilter('nearest','nearest')
	defaultFont2:setFilter('nearest','nearest')

	love.graphics.setDefaultFilter('nearest','nearest')
	defaultFont=love.graphics.getFont()
	defaultFontSize = defaultFont:getHeight("h")
	win_width=love.graphics.getWidth()
	win_height=love.graphics.getHeight()

	SceneMgr.AddScene(SceneMgr.NormalScene,menu.name,menu)
	SceneMgr.AddScene(SceneMgr.NormalScene,s1.name,s1)
	SceneMgr.AddScene(SceneMgr.NormalScene,makeTeam.name,makeTeam)
	SceneMgr.AddScene(SceneMgr.Adventure,s2.name,s2)

	SceneMgr.CurrentScene = { name = 'stab',
							  switchingScene = 'Menu',
							  Exit = function() end }

	--初始化一些場景資料
	s2:Init()

end

function love.update( dt )
	
	mx,my = love.mouse.getPosition()
	leftClick = love.mouse.isDown(1)

	-- 在這裡處理切換場景
	-- 保證只在這裡呼叫 SceneMgr.Switch, SceneMgr.Enter, SceneMgr.Exit
	-- 而不會在任何其他地方呼叫以上函數, 也保證按照順序只呼叫一次
	if SceneMgr.CurrentScene ~= nil and SceneMgr.CurrentScene.switchingScene ~= nil then
		local switchingScene = SceneMgr.CurrentScene.switchingScene
		SceneMgr.CurrentScene.switchingScene = nil
		if type(switchingScene) == 'string' and switchingScene~='advStart' then
			SceneMgr.Switch(SceneMgr.NormalScene, switchingScene)
		else
			SceneMgr.Switch(SceneMgr.Adventure, switchingScene)
		end
	end

	Mouse:Update(mx,my,leftClick,preClick)	
	SceneMgr.CurrentScene.Update(dt,mx,my,leftClick,preClick,win_width,win_height)
	preClick=leftClick

	for k,v in pairs(SceneMgr.CurrentScene.Motion) do
		Motion.HeadUpdate(v,dt)
	end
	for i=#SceneMgr.CurrentScene.TempPrint,1,-1 do
		local word = SceneMgr.CurrentScene.TempPrint[i]
		word:Update(SceneMgr.CurrentScene.TempPrint,dt)
	end

end

function love.draw()
	love.graphics.setLineWidth(5)
	love.graphics.setLineStyle( 'smooth' )
	love.graphics.setBackgroundColor(0.3, 0.3, 0, 1)

	for k,label in pairs(SceneMgr.CurrentScene.Drawable) do
		if label.stencil then label.stencil.StancilBegin() 	end
		
		for i,v in pairs(label) do
			if getmetatable(v)==Word then
				love.graphics.push()
				love.graphics.setColor(unpack(v.color))
				love.graphics.setFont(v.font)
				love.graphics.translate( v.translate.x , v.translate.y )
				love.graphics.rotate(v.transform.rotate)
				love.graphics.scale(v.transform.scale.x , v.transform.scale.y)
				love.graphics.printf(v.text, v.transform.position.x, v.transform.position.y , v.limit, v.align, v.r, v.sx, v.sy, v.ox, v.oy)
				love.graphics.pop()
			elseif getmetatable(v)== Curve then
				love.graphics.setColor(unpack(v.color))
				love.graphics.line(v.curve:renderSegment(0, 1,v.segmant))
			elseif getmetatable(v)== Graph and v.type=='rectangle' then
				love.graphics.setColor(unpack(v.color))
				love.graphics.rectangle(v.mode , v.x , v.y , v.width , v.height)
			elseif v.sprite then
				assert(v.sprite,type(v)..[[don't have sprite ]])
				love.graphics.setColor(unpack(v.color))
				love.graphics.draw(
					v.sprite.altas,
					v.sprite.quad,
					v.sprite.transform.position.x ,
					v.sprite.transform.position.y ,
					v.sprite.transform.rotate ,
					v.sprite.transform.scale.x ,
					v.sprite.transform.scale.y ,
					v.sprite.transform.offset.x ,
					v.sprite.transform.offset.y )

			end
		end
		if label.stencil then label.stencil.StancilEnd() end
	end

	love.graphics.setFont(defaultFont)
	love.graphics.setColor(1,1,0,1)
	SceneMgr.CurrentScene.debugDraw(mx,my)
	--love.graphics.print('head: '..SceneMgr.Adventure.head.name,5,15)
	--love.graphics.print('current: '..SceneMgr.CurrentScene.name,5,30)
	love.graphics.setLineWidth(1)

end
