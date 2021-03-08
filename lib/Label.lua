local Shader = require("lib.shader")
local function Update(self)
end
local function SetStancil(self,img)
	self.stencil=true
	self.label.Drawable.stencil={}

	self.label.Drawable.stencil.StancilBegin=function()
		local function Func()
			love.graphics.setShader(Shader.mask)
			love.graphics.draw(
				img.sprite.altas,
				img.sprite.quad,
				img.sprite.transform.position.x ,
				img.sprite.transform.position.y ,
				img.sprite.transform.rotate ,
				img.sprite.transform.scale.x ,
				img.sprite.transform.scale.y ,
				img.sprite.transform.offset.x ,
				img.sprite.transform.offset.y)

			love.graphics.setShader()	
		end 
		love.graphics.stencil(Func,"replace",1)
		love.graphics.setStencilTest("greater", 0) 
	end
	self.label.Drawable.stencil.StancilEnd=function()
		love.graphics.setStencilTest()
	end
end
local Label={}
Label.default={Update=Update,SetStancil=SetStancil}
Label.metatable={}
Label.metatable.__index=function (table,key) return Label.default[key] end
function Label.new(name,tab)
	local o = {name=name,label=tab,haveShader=false,stencil=false}
	o.StancilBegin=function()end
	o.StancilEnd=function()end
	setmetatable(o,Label.metatable)
	return o
end

function Label.merge( name,tab1,tab2 )
	local o = {name=name,label={},haveShader=false,stencil=false}
	for k,v in pairs(tab1.label) do
		o.label[k]={}
	end
	for k,v in pairs(tab2.label) do
		o.label[k]={}
	end
	for k,v in pairs(tab1.label) do
		for i,obj in pairs(v) do
			table.insert(o.label[k],obj)
		end
	end
	for k,v in pairs(tab2.label) do
		for i,obj in pairs(v) do
			table.insert(o.label[k],obj)
		end
	end
	setmetatable(o,Label.metatable)
	return o
end

return Label