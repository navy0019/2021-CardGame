local Assets = require('resource.allAssets')
local SaveFileMgr=require('save.saveManager')

local TeamData={AllHeros={}}
local DefaultTeam = {}

function TeamData.UpdateFromSaveFile()
	TeamData.CurrentTeam=SaveFileMgr.CurrentSave.CurrentTeam
	DefaultTeam=SaveFileMgr.CurrentSave.DefaultTeam
end
function TeamData.UpdateTeam()
	for k,v in pairs(TeamData.AllHeros) do
		v.selected=false
	end

	for k,v in pairs(SaveFileMgr.CurrentSave.CurrentTeam) do
		local num = TeamData.Find(v)
		if num ~= false then
			TeamData.AllHeros[num].selected=true
		end
	end
end
function TeamData.ResetTeam()
	for k,v in pairs(SaveFileMgr.CurrentSave.CurrentTeam) do
		SaveFileMgr.CurrentSave.CurrentTeam[k]=nil
	end
	for k,v in pairs(SaveFileMgr.CurrentSave.DefaultTeam) do
		table.insert(SaveFileMgr.CurrentSave.CurrentTeam,v)
	end
	TeamData.UpdateTeam()
end
function TeamData.SaveTeam()
	for k,v in pairs(SaveFileMgr.CurrentSave.DefaultTeam) do
		SaveFileMgr.CurrentSave.DefaultTeam[k]=nil
	end
	for k,v in pairs(SaveFileMgr.CurrentSave.CurrentTeam) do
		table.insert(SaveFileMgr.CurrentSave.DefaultTeam,v)
	end
	TeamData.UpdateTeam()
end
function TeamData.CheckEmpty()
	for k,v in pairs(SaveFileMgr.CurrentSave.CurrentTeam) do
		if v == 'empty' then
			return k
		end
	end
	return false
end
function TeamData.SetEmpty(obj)
	for k,v in pairs(SaveFileMgr.CurrentSave.CurrentTeam) do
		if v==obj.name then
			SaveFileMgr.CurrentSave.CurrentTeam[k]='empty'
		end
	end
end

function TeamData.Find(name)
	for k,v in pairs(TeamData.AllHeros) do
		if v.name == name then
			return k
		end
	end
	return false
end

function TeamData.Switch(obj)
	if obj.selected==true then
		TeamData.SetEmpty(obj)
		obj.selected=false
	elseif obj.selected==false then
		local p = TeamData.CheckEmpty()
		if p ~=false then
			SaveFileMgr.CurrentSave.CurrentTeam[p]=obj.name
			obj.selected = true
		end
	end
end

function TeamData.init()
	for i=1,16 do
		table.insert(TeamData.AllHeros,{name="hero"..i,selected=false,lock=true})
		if i<7 then
			TeamData.AllHeros[i].lock = false
		end
	end
	TeamData.UpdateTeam()
end

return TeamData