local List = require('lib.linkedList')
local SceneMgr={CurrentScene=nil,PreScene=nil,NextScene=nil,NormalScene={},Adventure=List.new({head=nil,tail=nil,length=0})}


function SceneMgr.AddScene( tableType,sceneName,scene)
	if tableType==SceneMgr.NormalScene then
		tableType[sceneName]=scene
	elseif getmetatable(tableType)==List.metatable  then
		tableType:Append(scene)
	end
end

function SceneMgr.Switch( tableType,sceneName)

	if SceneMgr.CurrentScene ~= nil then
		SceneMgr.CurrentScene.Exit()
	end
	local name = sceneName
	if getmetatable(tableType)==List.metatable  then
		SceneMgr.CurrentScene = sceneName
	elseif tableType==SceneMgr.NormalScene then
		if type(sceneName) == 'table'then
			name= sceneName.name
		end
		SceneMgr.CurrentScene = tableType[name]

	end
	if SceneMgr.CurrentScene ~= nil then
		SceneMgr.CurrentScene.Enter(love.graphics.getWidth(),
		                            love.graphics.getHeight())
	end
end

function SceneMgr.Contain( searchTable,scene )
	for k,v in pairs(searchTable) do
		if v == scene then
			return true
		end
	end
	return false
end

return SceneMgr