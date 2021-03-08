local Easing=require("lib.easing")
local Motion = {}

local function Update(self,tab,dt)
	self.argTab[1] = self.argTab[1] + dt
	if self.argTab[1] > self.argTab[4] then
		table.remove(tab,1)
	end
	self:func(dt)
end
Motion.FindEmpty=function( tab )
	for k,v in pairs(tab) do
		if #v == 0 then
			return k
		end
	end
	return false
end
Motion.NewTable=function( tab , motion)
	local p = Motion.FindEmpty( tab )
	if p ==false then
		table.insert(tab, { motion })
	else
		table.insert(tab[p],motion)
	end
end
Motion.LinkTable=function( tab, num , motion)
	if #tab > 0 then
		table.insert(tab[num],motion)
	else
		NewTable( tab , motion)
	end
end
Motion.HeadUpdate=function(queue ,dt )
	if #queue > 0 then
		local v = queue[1]
		v:Update(queue,dt)
	end
end
Motion.default={func=function()end,Update=Update}
Motion.metatable={}
function Motion.new(argTab,funcName,func)
	o={argTab=argTab,funcName=funcName,func=func}
	setmetatable(o,Motion.metatable)
	return o
end
Motion.metatable.__index=function (table,key) return Motion.default[key] end

--transform = { position={x=0, y=0},rotate= 0 ,scale={x= 1 ,y= 1} }
--target: {x=0, y=0}
--tab:{obj = o, target={x,y},transformation='position' ,'outCirc' , t=0 , d=1 }
function Motion.Lerp(motion,dt)
	local t = motion.argTab[1]
	local b = motion.argTab[2]
	local c = motion.argTab[3]-b
	local d = motion.argTab[4]

	return Easing[motion.funcName](t,b,c,d)
end

function Motion.Mirror(motion ,dt )
	local t = motion.argTab[1]
	local b = motion.argTab[2]
	local c = motion.argTab[3]-b
	local d = motion.argTab[4]

	if t < d/2 then
		return Easing[motion.funcName](2*t,b,c,d)
	else
		return Easing[motion.funcName](2*d-2*t,b,c,d)
	end

end
function Motion.MoveWithCurve( obj,curve, t)
	
end

return Motion