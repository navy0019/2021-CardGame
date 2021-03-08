local Anim = require('lib.animation')

function AddAnimate(self,animName,animObj)
	assert(getmetatable(animObj) == Anim.metatable,'animObj not type of animation object')
	self.animations[animName]=animObj
end
function SetCurrentAnim( self,animName )
	if self.currentAnim ~= animName and self.animations[animName] ~= nil then
		self.currentAnim = animName
		self.animations[animName]:Reset()
	end
end
function Play( self,dt )
	self.animations[self.currentAnim]:Play(dt)
end

local Sprite = {}
Sprite.default={altas=nil,quad=nil,transform = {position={ x =0, y =0 }, rotate = 0 , scale={x= 1 ,y= 1} , offset={x=0 ,y=0} },currentAnim='',animations={},AddAnimate=AddAnimate,SetCurrentAnim = SetCurrentAnim,Play=Play}
Sprite.metatable={}
function Sprite.new(o)
	setmetatable(o,Sprite.metatable)
	return o
end
Sprite.metatable.__index=function (table,key) return Sprite.default[key] end

return Sprite