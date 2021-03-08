local Card = require("lib.card")
local Sprite = require('lib.sprite')
local Character = require('lib.character')
local StatusHandle = require('lib.Status')
local TableFunc = require('lib.tableFunc')

local Resource = require('resource.Resource')

local CardsHandle = {}

local function instance(card,target,key)
	local character ,parentTab ,key,battle = card.master , target , key , card.battle
	--key,posx,posy,character,parentTab,battle
	local o = CardsHandle.instance( key,0,0,character,parentTab,card.battle )

	return o
end
local function InfoInsert(targetTab,selfTab,card)
	for k,v in pairs(selfTab) do
		local color , str = v[1].color,v[1].string(card)
		table.insert(targetTab, v[2]+(k-1)*2   ,color)
		table.insert(targetTab, v[2]+(k-1)*2+1 ,str)
	end
end
local Cards={
	m3={
		effectOn='enemy',
		targetNum=4,
		dropTo='drop',
		type='atk',
		name='隕石術',
		cost=5,
		motionType="scale",
		updateWord={ {{color={0.9,0,0,1}, string=function(card) return card.level*10+20 end},3} },
		info={{0,0,0,1},'三回合後對所有敵人造成 ',{0,0,0,1},' 傷害'},
		textInsert=function(card)
			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			for k,v in pairs(target) do
				StatusHandle.Add(v,'aerolite')
			end
		end
	},
	r10={

		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='atk',
		name='捨身攻擊',
		cost=3,
		motionType="hit",
		updateWord={ {{color={0.9,0,0,1}, string=function(card) return card.master.data.atk+card.level*2 end},3},
					 {{color={0.9,0,0,1}, string=function(card) return card.master.data.atk-1 end},5}},

		info={{0,0,0,1},'對目標造成 ',{0,0,0,1},' 傷害，對自身造成 ',{0,0,0,1},' 傷害'},
		textInsert=function(card)
			--[[local c1 = {0.9,0,0,1}
			local s1 = card.master.data.atk+card.level*2
			local s2 = card.master.data.atk-1]]
			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			target:GetHit((card.master.data.atk+card.level*2)*-1,false,true,card.battle)
			card.master:GetHit((card.master.data.atk-1)*-1,false,true,card.battle)
		end
	},
	r11={
		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='atk',
		name='擲斧',
		cost=4,
		motionType="hit",
		updateWord={ {{color={0.9,0,0,1}, string=function(card) return card.master.data.atk+2*(card.level-1)+1 end},3} },

		info={{0,0,0,1},'對目標造成 ',{0,0,0,1},' 傷害'},
		textInsert=function(card)
			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			target:GetHit((card.master.data.atk+2*(card.level-1)+1)*-1,false,true,card.battle)
		end
	},
	a1={
		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='atk',
		name='毒箭',
		cost=2,
		motionType="hit",
		updateWord={ {{color={0.9, 0, 0 ,1}, string=function(card) return card.master.data.atk+2*(card.level-1)+1 end},3},
					{{color={0.1, 0.5 ,0 ,1},string=function(card) return 2*(card.level-1)+4 end},5} },

		info={{0,0,0,1},'對目標造成 ',{0,0,0,1},' 傷害、',{0.1 ,0.5 ,0 ,1},' 層中毒'},
		textInsert=function(card)
			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			target:GetHit((card.master.data.atk+2*(card.level-1)+1)*-1,false,true,card.battle)
			StatusHandle.Add(target,'poison',card)
		end
	},
	m2={
		effectOn='hero',
		targetNum=1,
		dropTo='drop',
		type='skill',
		name='火花',
		cost=3,
		motionType="scale",
		updateWord={ },

		info={{0,0,0,1},'增加一張火球術到牌堆'},
		textInsert=function(card)

		end,
		Effect=function (card,target)
			local o =instance(card,card.battle.battleData.deck,'m1')
			table.insert(card.battle.battleData.deck , _G.rng:random(#card.battle.battleData.deck),o)
			card.battle.battleData.deckSize=card.battle.battleData.deckSize+1
		end
	},
	a3={
		effectOn='hero',
		targetNum=4,
		dropTo='drop',
		type='skill',
		name='迴避',
		cost=2,
		motionType="heal",
		updateWord={ {{color={0, 0, 0.9 ,1}, string=function(card) return card.level end},3} },

		info={{0,0,0,1},'對隊伍施加 ',{0,0,0.9,1},' 層迴避(未實作)'},
		textInsert=function(card)
			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)

		end
	},
	r13={
		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='atk',
		name='攻擊',
		cost=4,
		motionType="hit",
		updateWord={ {{color={0.9,0,0,1}, string=function(card) return card.master.data.atk+(card.level-1) end},3} },

		info={{0,0,0,1},'對目標造成 ',{0,0,0,1},' 傷害'},
		textInsert=function(card)

			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			target:GetHit((card.master.data.atk+(card.level-1))*-1,false,true,card.battle)
		end
	},
	r12={
		effectOn='hero',
		targetNum=1,
		dropTo='drop',
		type='skill',
		name='憤怒',
		cost=4,
		motionType="heal",
		updateWord={ {{color={0.7, 0.3, 0 ,1}, string=function(card) return card.level+2 end},3} },

		info={{0,0,0,1},'對目標施加 ',{0.7, 0.3,0,1},' 層憤怒'},
		textInsert=function(card)

			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			StatusHandle.Add(target,'angry',card)
		end
	},
	a2={

		effectOn='enemy',
		targetNum=4,
		dropTo='drop',
		type='atk',
		name='箭雨',
		cost=3,
		motionType="hit",
		updateWord={ {{color={0.9,0,0,1}, string=function(card) return math.floor((card.master.data.atk+card.level)/2) end},3} },

		info={{0,0,0,1},'對敵方全體造成   ',{0,0,0,1},' 傷害'},
		textInsert=function(card)

			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			for k,v in pairs(target) do
				if v.data.hp > 0 then
				v:GetHit((math.floor((card.master.data.atk+card.level)/2))*-1,false,true,card.battle)
				end
			end	
		end
	},
	m1={

		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='atk',
		name='火球術',
		cost=5,
		motionType="hit",
		updateWord={ {{color={0.9,0,0,1}, string=function(card) return card.master.data.atk+(card.level+1) end},3} },

		info={{0,0,0,1},'對目標造成 ',{0,0,0,1},' 傷害，打出後消耗'},
		textInsert=function(card)
			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			target:GetHit((card.master.data.atk+(card.level+1))*-1,false,true,card.battle)
			card.dropTo='disappear'
		end
	},
	m4={

		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='skill',
		name='冥想',
		cost=1,
		motionType="heal",
		updateWord={  },

		info={{0,0,0,1},'未定義 '},
		textInsert=function(card)

		end,
		Effect=function (card,target)
			
		end
	},
	a4={

		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='atk',
		name='飛踢',
		cost=2,
		motionType="hit",
		updateWord={ {{color={0.9,0,0,1}, string=function(card) return card.master.data.atk+(card.level+1) end},3} },

		info={{0,0,0,1},'對目標造成 ',{0,0,0,1},' 傷害'},
		textInsert=function(card)

			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			target:GetHit((card.master.data.atk+(card.level+1))*-1,false,true,card.battle)
		end
	},
	r2={

		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='atk',
		name='盾擊',
		cost=4,
		motionType="hit",
		updateWord={ {{color={0.9,0,0,1}, string=function(card) return card.master.data.shield+(card.level-1) end},3} },

		info={{0,0,0,1},'根據格擋值對目標造成 ',{0,0,0,1},' 傷害'},
		textInsert=function(card)

			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			target:GetHit((card.master.data.shield+(card.level-1))*-1,false,true,card.battle)
		end
	},
	r3={

		effectOn='hero',
		targetNum=4,
		dropTo='drop',
		type='def',
		name='防禦',
		cost=4,
		motionType="heal",
		updateWord={ {{color={0.3, 0.3, 0.7 ,1}, string=function(card) return card.master.data.def end},3} },

		info={{0,0,0,1},'對隊伍施加 ',{0.3, 0.3, 0.7,1},' 格擋'},
		textInsert=function(card)

			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			for k,v in pairs(target) do
				StatusHandle.Add(v,'shield',card.master.data.def)
			end	
		end
	},
	r1={

		effectOn='enemy',
		targetNum=2,
		dropTo='drop',
		type='atk',
		name='刺擊',
		cost=4,
		motionType="hit",
		updateWord={ {{color={0.9,0,0,1}, string=function(card) return card.master.data.atk+(card.level) end},3} },

		info={{0,0,0,1},'對敵方隊伍前兩位造成 ',{0,0,0,1},' 傷害'},
		textInsert=function(card)

			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			if #target >=2 then
				for i=1,2 do
					target[i]:GetHit((card.master.data.atk+(card.level)-2)*-1,false,true,card.battle)
				end
			end
			
		end
	},
	r4={

		effectOn='enemy',
		targetNum=4,
		dropTo='drop',
		type='skill',
		name='士氣提升',
		cost=2,
		motionType="scale",
		updateWord={},

		info={{0,0,0,1},'下一張防禦卡格擋值x2'},
		textInsert=function(card)
		end,
		Effect=function (card,target)

		end
	},
	r5={

		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='atk',
		name='骨折',
		cost=2,
		motionType="hit",
		updateWord={ {{color={0.9, 0, 0 ,1}, string=function(card) return card.master.data.atk+2*(card.level-1)+1 end},3},
					{{color={0.5, 0.9 ,0.8 ,1}, string=function(card) return card.level end},5}},

		info={{0,0,0,1},'對目標造成 ',{0,0,0,1},' 傷害，並且施加',{0.5, 0.9 ,0.8 ,1},'層虛弱'},
		textInsert=function(card)

			local tab=card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			target:GetHit((card.master.data.atk+2*(card.level-1)+1)*-1,false,true,card.battle)
			StatusHandle.Add(target,'weak',card)
		end
	},
	r7={
		effectOn='hero',
		targetNum=1,
		dropTo='drop',
		type='skill',
		name='反擊',
		cost=2,
		motionType="hit",
		updateWord={ {{color={0.9, 0, 0 ,1}, string=function(card) return card.master.data.atk/2+card.level end},3}},

		info={{0,0,0,1},'當目標被攻擊時對攻擊者造成 ',{0,0,0,1},' 傷害(未實作)'},
		textInsert=function(card)

			local tab=card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
		end
	},
	r6={
		effectOn='enemy',
		targetNum=4,
		dropTo='drop',
		type='atk',
		name='範圍打擊',
		cost=4,
		motionType="hit",
		updateWord={ {{color={0.9, 0, 0 ,1}, string=function(card) return card.master.data.atk end},3}},

		info={{0,0,0,1},'對敵方隊伍造成 ',{0,0,0,1},' 傷害，傷害隨著敵方隊伍人數遞減'},
		textInsert=function(card)

			local tab=card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			local  value = card.master.data.atk
			for k,v in pairs(target) do
				v:GetHit((value)*-1, false,true,card.battle)
				value=value-1
			end	
		end
	},
	h5={
		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='atk',
		name='射線',
		cost=1,
		motionType="hit",
		updateWord={ {{color={0.9, 0, 0 ,1}, string=function(card) return card.master.data.atk+(card.leve-1) end},3}},

		info={{0,0,0,1},'對目標造成 ',{0,0,0,1},' 傷害'},
		textInsert=function(card)
	
			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			target:GetHit((card.master.data.atk+(card.leve-1))*-1, false,true,card.battle)
		end
	},
	h4={
		effectOn='hero',
		targetNum=1,
		dropTo='drop',
		type='skill',
		name='加速',
		cost=2,
		motionType="heal",
		updateWord={ },
		info={{0,0,0,1},'未定義'},
		textInsert=function(card)

		end,
		Effect=function (card,target)
			--target:GetHit(card.master.data.atk)
		end
	},
	r8={
		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='atk',
		name='破防',
		cost=2,
		motionType="hit",
		updateWord={ {{color={0.9, 0, 0 ,1}, string=function(card) return card.master.data.atk+2*(card.level-1)+1 end},3}},

		info={{0,0,0,1},'對目標造成目標格擋值 + ',{0,0,0,1},' 傷害'},
		textInsert=function(card)

			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			target:GetHit((card.master.data.atk+2*(card.level-1)+1+target.data.shield)*-1, false,true,card.battle)
		end
	},
	r9={
		effectOn='enemy',
		targetNum=1,
		dropTo='drop',
		type='atk',
		name='撕裂',
		cost=4,
		motionType="hit",
		updateWord={ {{color={0.9, 0, 0 ,1}, string=function(card) return card.master.data.atk+card.level+2 end},3}},
		info={{0,0,0,1},'對目標造成 ',{0,0,0,1},' 傷害'},
		textInsert=function(card)

			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			target:GetHit((card.master.data.atk+card.level+2)*-1 , false,true,card.battle)
		end
	},
	h3={
		effectOn='hero',
		targetNum=1,
		dropTo='drop',
		type='skill',
		name='治療',
		cost=3,
		motionType="hit",
		updateWord={ {{color={0,0.6,0.5,1}, string=function(card) return 3+card.level+card.master.data.atk end},3}},
		info={{0,0,0,1},'對目標回復 ',{0,0,0,1},' 點生命'},
		textInsert=function(card)

			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
		target:GetHit(3+card.level+card.master.data.atk , true,false,card.battle)
			
		end
	},
	h2={

		effectOn='hero',
		targetNum=4,
		dropTo='drop',
		type='def',
		name='防禦',
		cost=3,
		motionType="heal",
		updateWord={ {{color={0.3, 0.3, 0.7 ,1}, string=function(card) return card.master.data.def end},3}},
		info={{0,0,0,1},'對隊伍施加 ',{0.3, 0.3, 0.7,1},' 格擋'},
		textInsert=function(card)

			local tab = card.updateWord
			InfoInsert(card.info , tab , card)
		end,
		Effect=function (card,target)
			for k,v in pairs(target) do
				StatusHandle.Add(v,'shield',card.master.data.def)
			end	
		end
	},
	h1={

		effectOn='hero',
		targetNum=1,
		dropTo='drop',
		type='skill',
		name='包紮',
		cost=1,
		motionType="heal",
		updateWord={ },
		info={{0,0,0,1},'移除目標隨機一個debuff(未實作)'},
		textInsert=function(card)
		end,
		Effect=function (card,target)
			local debuff = {}
		end
	}
}


function CardsHandle.instance( key,posx,posy,character,parentTab,battle)
	local img = love.graphics.newImage(Resource[key].img)
	local x,y,w,h = unpack(Resource[key].quad)
	local quad=love.graphics.newQuad(x,y,w,h,img:getDimensions())
	local func=Cards[key].func

	function OnClick()	
	end
	--new(w,h,effectOn,targetNum,master,parentTab,Effect,name,numbering,info,battle)
	local info = TableFunc.copy(Cards[key].info)
	local card = Card.new(w, h, Cards[key].effectOn ,Cards[key].targetNum , character , 
							parentTab , Cards[key].Effect, Cards[key].name , key,info,battle,
							Cards[key].dropTo , Cards[key].type , Cards[key].cost,Cards[key].motionType)
	card.sprite=Sprite.new({altas=img,quad=quad,transform = {position={ x =posx, y =posy }, rotate = 0 , scale={x= 1 ,y= 1}, offset={x=w/2 ,y=h} } })

	if Cards[key].updateWord ~=nil then card.updateWord = Cards[key].updateWord end
	Cards[key].textInsert(card)
	return card
end
return CardsHandle