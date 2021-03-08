
local json = require('save.json')
local tableFunc = require('lib.tableFunc')

local SaveMgr={CurrentSave=nil}
local filepaths = love.filesystem.getSource( )

local saveData = {}
saveData.metatable={}
function saveData.new(saveNum)
	local o ={
		Enable=false,
		FileName='savedata_'..saveNum,
		CurrentTeam={"hero1" ,"hero2" ,"hero3" ,"hero4"},
		DefaultTeam={"hero1" ,"hero2" ,"hero3" ,"hero4"},
		CurrentTeamData={},
		CurrentScene='Main'
	}
	setmetatable(o,saveData.metatable)
	return o
end
saveData.metatable.__index=function (table,key) return saveData.metatable[key] end


function SaveMgr.Save(data)
	data.Enable=true
	local file = io.open(filepaths..'/save/'..data.FileName..'.json','w+')
	file:write('{\n')
	--file:write(jsonPaser.encodeSaveData(data))
	local str=''
	local len = tableFunc.countTable(data)
	local index=0
	for key,value in pairs(data) do
		index=index+1
		local dataType = type(value)
		if index<len then
			str=str..'"'..key..'"'..":"..json.encode(value)..','..'\n'
		else
			str=str..'"'..key..'"'..":"..json.encode(value)
		end
	end
	file:write(str)
	file:write('\n}')
	file:close()

end
function SaveMgr.Load(filename)
	
	local file = io.open(filepaths..'/save/'..filename..'.json','r')
	local content = file:read('*all')
	--local data = jsonPaser.decodeSaveData(content)
	local data = json.decode(content)
	file:close()
	return data
end
function SaveMgr.NewSaveFile(saveNum)
	local data = saveData.new(saveNum)
	return data
end
function SaveMgr.CheckTableType(tab)
	if #tab==0 then
		for k,v in pairs(tab) do
			if k then return 'Dic' end
		end		
	end
	return 'Arr'
end
return SaveMgr