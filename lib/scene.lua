local Mouse = require('other.mouse')

local function Enter( ... )
end
local function Update( ... )
end
local function Exit( ... )
end
local function Init( ... )
end
local function MouseAct( self,mx,my,leftClick,preClick,choose,characterData,...)
	if #self.CheckRange>0 then
		for k,v in pairs(self.CheckRange[#self.CheckRange]) do
			if Mouse.current.name == 'OnClick' then
				if v:Check(mx,my) and v.isLock==false  then v:OnClick() end

			elseif Mouse.current.name == 'OnHold' then
				if v:Check(mx,my) and v.isLock==false    then 
					v:OnHold(mx,my,choose)
				end 
				if choose ~= nil then
					choose:OnHold(mx,my,characterData)
				end

			elseif Mouse.current.name == 'OnRelease' then
				if choose ~= nil then
					choose:OnRelease()
				end
			end
		end
	end
end
local function PlayAltas( self,dt )
	for k,label in pairs(self.Altas) do --animation
		for i,v in pairs(label) do
			v.sprite:Play(dt)
			v.sprite.quad:setViewport(
				v.sprite.animations[ v.sprite.currentAnim ].x ,
				v.sprite.animations[ v.sprite.currentAnim ].y ,
				v.sprite.animations[ v.sprite.currentAnim ].w ,
				v.sprite.animations[ v.sprite.currentAnim ].h )
		end
	end
end

function Clear(scene)
	scene.Drawable={}
	scene.AllLabels={}
	scene.CheckRange={}
	scene.Altas={}
	scene.Print={}
	scene.TempPrint={}
end
local Scene={}
Scene.default={Drawable={},CheckRange={},Altas={},Print={},TempPrint={},Motion={},AllLabels={},firstLoad=true,name=nil,
				Enter=Enter,Update=Update,Exit=Exit,Clear=Clear,MouseAct=MouseAct,PlayAltas=PlayAltas,Init=Init}



Scene.metatable={}
function Scene.new(o)
	o.scale={x=1,y=1}
	setmetatable(o,Scene.metatable)
	return o
end
Scene.metatable.__index=function (table,key) return Scene.default[key] end

return Scene