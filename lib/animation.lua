function Play(anim,dt)
	if anim.timer > 0 then
		anim.timer = anim.timer - dt
        if anim.timer <= 0 then
            anim.timer = 1 / anim.fps
            anim.index = anim.index + 1
            if anim.index > anim.frames-1 then 
                if anim.loop then
                    anim.index = 0
                else
                    anim.index = anim.frames-1
                    anim.timer = 0
                    anim.done = true
                end
            end
            anim.x = anim.w * anim.index
        end
	end
end
function Reset( self )
	self.timer = 1/self.fps
	self.index = 0
	self.done=false

	self.x=0
end

local Animation={}
Animation.default={x=0, y=0, w=0, h=0, frames=0, column_size=0, fps=0, index=0, timer=0, done=false ,loop =false, Play =Play, Reset=Reset }
Animation.metatable={}
function Animation.new(o)
	setmetatable(o,Animation.metatable)
	return o
end
Animation.metatable.__index=function (table,key) return Animation.default[key] end

return Animation