local function MakePosArray(self)
	local pos = {}
	local step = 1/self.segmant
	local space = 0 
	for i=1,self.segmant,1 do
		local x,y = self.curve:evaluate(space)
		space = math.min(space+step,1)
		table.insert(pos,x)
		table.insert(pos,y)
	end

	return pos
end
local Curve={MakePosArray=MakePosArray}

Curve.__index=Curve
function Curve.new(pointTab,segmant,color)
	local color=color or {1,1,1,1}
	local s = segmant or 5
	local curve = love.math.newBezierCurve(pointTab)
	local o = {curve=curve,segmant=s,color=color,type='curve'}
	setmetatable(o,Curve)
	return o
end

return Curve