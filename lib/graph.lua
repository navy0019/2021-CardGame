local Graph={}
Graph.__index=Graph
function Graph.new(t,mode,x,y,w,h)
	local o = {type=t,mode=mode,x=x,y=y,width=w,height=h,color={1,0,0,1}}
	setmetatable(o,Graph)
	return o
end
return Graph