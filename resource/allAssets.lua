local Button = require("lib.button")
local Sprite = require('lib.sprite')
local Character = require('lib.character')
local SceneMgr = require('lib.sceneManager')
local Animation = require('lib.animation')
local TableFunc = require('lib.tableFunc')
local Resource = require('resource.Resource')

local Characters = {
	---quad Info & assets path & animation Info
	--hero 20 point
	hero1={ 

		data={hp=12,act=2,def=4,atk=2,shield=0,teamPos=1},--hp=12 def=4
		skill={'r13','r2','r3','r3'},
		advancedSkill={'r1','r4','r1','r1','r1','r1'},
		info='適合當坦',
		equipment={},
		animation={
			idle={x=0,y=0,w=200,h=468,frames=4, column_size=1, fps=5, index=0, timer=0, done=false ,loop =true}	
		},
		space=40
	},

	hero2={

		data={hp=11,act=3,def=0,atk=6,shield=0,teamPos=1},
		skill={'r13','r9','r11','r12'},
		advancedSkill={'r1','r4'},
		info='無防禦能力，但攻擊力高',
		equipment={},
		animation={
			idle={x=0,y=0,w=200,h=468,frames=1, column_size=1, fps=5, index=0, timer=0, done=false ,loop =true}	
		},
		space=40
	},
	
	hero3={
		data={hp=10,act=5,def=0,atk=5,shield=0,teamPos=1},
		skill={'a1','a2','a3','a4'},
		advancedSkill={'r1','r4'},
		info='行動點數多',
		equipment={},
		animation={
			idle={x=0,y=0,w=200,h=468,frames=1, column_size=1, fps=5, index=0, timer=0, done=false ,loop =true}	
		},
		space=40
	},
	hero4={
		data={hp=12,act=3,def=3,atk=2,shield=0,teamPos=1},
		skill={'h3','h2','h2','h3'},
		advancedSkill={'r1','r4'},
		info='補師，可以當半個坦',
		equipment={},
		animation={
			idle={x=0,y=0,w=200,h=468,frames=1, column_size=1, fps=5, index=0, timer=0, done=false ,loop =true}	
		},
		space=40
	},
	hero5={
		data={hp=12,act=3,def=0,atk=5,shield=0,teamPos=1},
		skill={'r5','r7','r8','r13'},
		advancedSkill={'r1','r4'},
		info='攻擊附帶各種效果',
		equipment={},
		animation={
			idle={x=0,y=0,w=200,h=468,frames=1, column_size=1, fps=5, index=0, timer=0, done=false ,loop =true}	
		},
		space=40
	},	
	hero6={
		data={hp=10,act=3,def=0,atk=7,shield=0,teamPos=1},
		skill={'m1','m1','m2','m3'},
		advancedSkill={'r1','r4'},
		equipment={},
		info='脆弱但攻擊力高',
		animation={
			idle={x=0,y=0,w=200,h=468,frames=1, column_size=1, fps=5, index=0, timer=0, done=false ,loop =true}	
		},
		space=40
	}
}
local Monsters = {
	m_mid_1={
		data={hp=1,act=2,def=3,atk=3,shield=0,teamPos=3},--10
		skill={'attack','attack2'},
		animation={
			idle={x=0,y=0,w=200,h=468,frames=1, column_size=1, fps=5, index=0, timer=0, done=false ,loop =true}	
		},
		space=40
	},
	m_mid_2={
		data={hp=1,act=2,def=2,atk=5,shield=0,teamPos=2},--8
		skill={'attack','attack2'},
		animation={
			idle={x=0,y=0,w=200,h=468,frames=1, column_size=1, fps=5, index=0, timer=0, done=false ,loop =true}	
		},
		space=40
	},
	m_small_1={
		data={hp=1,act=3,def=2,atk=2,shield=0,teamPos=3},--5
		skill={'attack','attack2'},
		animation={
			idle={x=0,y=0,w=200,h=468,frames=1, column_size=1, fps=5, index=0, timer=0, done=false ,loop =true}	
		},
		space=40
	},
	m_XL_1={
		data={hp=1,act=2,def=2,atk=4,shield=0,teamPos=4},--13
		skill={'attack','attack2'},
		animation={
			idle={x=0,y=0,w=356,h=468,frames=1, column_size=1, fps=5, index=0, timer=0, done=false ,loop =true}	
		},
		space=76
	}
}
local Images = {}
local Buttons = {}
function Images.instance(key,posx,posy,r,sx,sy,ox,oy)
	assert(Resource[key],key ..'not exist')
	local img = love.graphics.newImage(Resource[key].img)
	local x,y,w,h = unpack(Resource[key].quad)

	local quad=love.graphics.newQuad(x,y,w,h,img:getDimensions())
	local posx, posy = posx  , posy 
	local r = r or 0
	local sx,sy = sx or 1 , sy or 1
	local ox,oy = ox or x+w/2 ,oy or y+h/2

	local obj ={sprite=nil  ,width=w ,height=h ,color={1,1,1,1},motion={}}
	obj.sprite=Sprite.new({altas=img,quad=quad, transform = {position={ x =posx, y =posy }, rotate = r , scale={x= sx ,y= sy}, offset={x=ox ,y=oy} } })
	return obj
end
function Buttons.instance( key,posx,posy )
	assert(Resource[key],key ..' not exist')
	local img = love.graphics.newImage(Resource[key].img)
	local x,y,w,h = unpack(Resource[key].quad)
	local quad=love.graphics.newQuad(x,y,w,h,img:getDimensions())

	function OnClick()	
	end

	local button = Button.new({sprite=nil,width=w,height=h,color={1,1,1,1},normal={1,1,1,1},press={},lock={0.5,0.5,0.5,1},motion={},isLock=false,OnClick=OnClick})
	button.sprite=Sprite.new({altas=img,quad=quad,transform = {position={ x =posx, y =posy }, rotate = 0 , scale={x= 1 ,y= 1}, offset={x=0 ,y=0} } })

	return button
end
function Characters.instance( key,posx,posy)
	local img = love.graphics.newImage(Resource[key].img)
	local x,y,w,h = unpack({0,0,200,468})
	local quad=love.graphics.newQuad(x,y,w,h,img:getDimensions())
	local data = TableFunc.copy(Characters[key].data)

	local character = Character.new(w, h ,data , Characters[key].space , Characters[key].skill,Characters[key].advancedSkill ,Characters[key].equipment ,1 ,'hero',key)
	character.sprite=Sprite.new({altas=img,quad=quad,transform = {position={ x =posx, y =posy }, rotate = 0 , scale={x= 1 ,y= 1}, offset={x=0 ,y=0} },currentAnim='',animations={}})
	character.info=Characters[key].info
	
	local a = Characters[key].animation.idle
	local idleAnim = Animation.new({x=a.x, y=a.y, w=a.w, h=a.h, frames=a.frames, column_size=a.column_size, fps=a.fps, index=a.index, timer=a.timer, done=a.done ,loop =a.loop})
	character.sprite:AddAnimate('idle',idleAnim)
	character.sprite:SetCurrentAnim( 'idle' )

	return character
end

function Monsters.instance( key,posx,posy)

	local img = love.graphics.newImage(Resource[key].img)
	local x,y,w,h = unpack(Resource[key].quad)
	local quad=love.graphics.newQuad(x,y,w,h,img:getDimensions())
	local data = TableFunc.copy(Monsters[key].data)

	local monster = Character.new(w, h ,data , Monsters[key].space , Monsters[key].skill,{} , {} ,-1 ,'enemy',key)
	monster.sprite=Sprite.new({altas=img,quad=quad,transform = {position={ x =posx, y =posy }, rotate = 0 , scale={x= 1 ,y= 1}, offset={x=0 ,y=0} },currentAnim='',animations={}})

	local a = Monsters[key].animation.idle
	local idleAnim = Animation.new({x=a.x, y=a.y, w=a.w, h=a.h, frames=a.frames, column_size=a.column_size, fps=a.fps, index=a.index, timer=a.timer, done=a.done ,loop =a.loop})
	monster.sprite:AddAnimate('idle',idleAnim)
	monster.sprite:SetCurrentAnim( 'idle' )

	return monster
end

return{Buttons=Buttons,Images=Images,Characters=Characters,Monsters=Monsters}

