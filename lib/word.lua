local tableFunc = require("lib.tableFunc")
local function Update( self,tab,dt)
	self.t = self.t + dt
	if self.t > self.life then
		local num = tableFunc.find(tab,self)
		table.remove(tab,num)
	end
end


local Word = {Update=Update}
Word.__index=Word
function Word.GetPixelSize(font,text)
	local w = font:getWidth(tostring(text))
	local h = font:getHeight(tostring(text))
	return w,h
end

function Word.new(font,str,x,y,r,sx,sy,ox,oy,t,life)
	local w,h = Word.GetPixelSize(font,str)
	local x,y = x  , y 
	local r = r or 0
	local sx,sy = sx or 1 , sy or 1
	local ox,oy = ox or x+w/2 ,oy or y+h/2
	local t , life = t or 0 , life or math.huge
	local limit = 156
	local align = 'left'
	if ox > 0 or oy > 0 then
		x= -w/2
		y= -h/2
	end

	local o = { font=font,text=str,width=w,height=h, t=t ,life=life,color={1,1,1,1},limit=limit,align=align,
		textInsert={},transform = { position={x=x, y=y},rotate= r ,scale={x= sx ,y= sy} } , translate={x=ox, y=oy},motion={}}
	setmetatable(o,Word)
	return o
end



return Word

