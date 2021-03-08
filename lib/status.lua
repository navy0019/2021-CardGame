local TableFunc = require('lib.tableFunc')
local StatusHandle = {}
local Status = {
	poison={
		status={name='poison',value=4,round=4},
		update=function(target,status,battle)
			StatusHandle.effect(target,status,battle)
		end,
		effect=function (target,status,battle)
			target:GetHit((status.value)*-1,true,false,battle)
			status.round=status.round-1
			status.value=status.round
		end,
		add=function ( target,status,card  )
			for k,v in pairs(target.data.Status.before) do
				if v.name == status.name then
					v.round =v.round+2*(card.level-1)+4
					v.value =v.round
					return k
				end
			end
			local s = TableFunc.copy(status)
			s.round = 2*(card.level-1)+4
			s.value=s.round
			table.insert(target.data.Status.before,s)
		end,
		remove=function(target,status)

		end
	},
	aerolite={
		status={name='aerolite',value=30,round=2},
		update=function(target,status,battle)
			StatusHandle.effect(target,status,battle)
		end,
		effect=function (target,status,battle)
			status.round=status.round-1
			if status.round<=0 then
				target:GetHit((status.value)*-1,false,false,battle)
			end

		end,
		add=function ( target,status,card  )
			local s = TableFunc.copy(status)
			table.insert(target.data.Status.after,s)
	
			
		end,
		remove=function(target,status,battle)

		end
	},
	avoid={
		status={name='avoid',value=0,round=1},
		update=function(target,status,battle)
			status.round=0
		end,
		effect=function (target,status,battle,num)
			local ran = _G.rng:random(1,10)
			if ran <= 5 then
				return true
			else
				target:GetHit((num)*-1,false,true,battle)
			end
			status.round=status.round-1
		end,
		add=function ( target,status,card )
			for k,v in pairs(target.data.Status.before) do
				if v.name == status.name then
					v.value =v.value+card.level
					return k
				end
			end
			local s = TableFunc.copy(status)
			s.value=card.level
			table.insert(target.data.Status.before,s)
			
		end,
		remove=function(target,status)

		end
	},
	shield={
		status={name='shield',value=0,round=1},
		update=function(target,status,battle)
			status.round=0
		end,
		effect=function (target,status,battle)
			--status.value=target.data.def	
		end,
		add=function ( target,status,num)
			for k,v in pairs(target.data.Status.before) do
				if v.name == status.name then
					--print('add in for')
					v.value =v.value+num
					target.data.shield=v.value
					return k
				end
			end
			--print('add new')
			local s = TableFunc.copy(status)
			s.value=num
			target.data.shield=s.value+target.originData.shield
			table.insert(target.data.Status.before,s)
		end,
		remove=function(target,status)
			target.data.shield =0
		end
	},
	angry={
		status={name='angry',value=1,round=2},
		update=function(target,status,battle,card)
			StatusHandle.effect(target,status,battle,card)
		end,
		effect=function (target,status,battle,card)
			if card.type =='atk' then
				status.round=status.round-1
				if status.round <= 0 then
					--[[target.data.atk =target.originData.atk
					local p=TableFunc.find(target.data.Status.always,'angry','name')
					table.remove(target.data.Status.always,p)]]
					StatusHandle.Remove( target,status,target.data.Status.always,battle)
				end
			end
		end,
		add=function ( target,status ,card  )
			for k,v in pairs(target.data.Status.always) do
				if v.name == status.name then
					
					v.round =v.round+card.level+status.round
					target.data.atk =target.originData.atk+ v.value
					return k
				end
			end

			local s = TableFunc.copy(status)
			s.round=s.round+card.level
			target.data.atk =target.originData.atk+ s.value
			table.insert(target.data.Status.always,s)
			card.battle:CardWordUpdate()
		end,
		remove=function(target,status,battle)
			target.data.atk =target.originData.atk
			battle:CardWordUpdate()
		end
	},
	weak={
		status={name='weak',value=0.6,round=2},
		update=function(target,status,battle)
			status.round=status.round-1
		end,
		effect=function (target,status,battle)
			
		end,
		add=function ( target,status ,card  )
			for k,v in pairs(target.data.Status.before) do
				if v.name == status.name then					
					v.round =v.round+card.level+status.round
					target.data.atk =math.floor(target.data.atk* v.value)
					return k
				end
			end

			local s = TableFunc.copy(status)
			s.round=s.round+card.level
			target.data.atk =math.floor(target.data.atk * s.value)
			table.insert(target.data.Status.before,s)
		end,
		remove=function(target,status)
			target.data.atk =math.floor(target.data.atk/status.value) 
		end
	},
	improveShield={
		status={name='improveShield',value=2,round=1},
		update=function(target,status,battle)
			
		end,
		effect=function (target,status,battle)
			status.round=status.round-1
		end,
		add=function ( target,status ,card  )
			for k,v in pairs(target.data.Status.before) do
				if v.name == status.name then					
					v.round =v.round+status.round
					return k
				end
			end

			local s = TableFunc.copy(status)
			table.insert(target.data.Status.before,s)
		end,
		remove=function(target,status)

		end
	},
}

function StatusHandle.effect(target,status,battle,...)
	local args = {...}
	Status[status.name].effect(target,status,battle,unpack(args))
end
function StatusHandle.Find(target,key,name)
	for k,v in pairs(target.data.Status[key]) do
		if v.name == name then
			return k
		end
	end
	return false
end
function StatusHandle.Add(target,key,...)
	local args = {...}
	Status[key].add(target,Status[key].status,unpack(args))

end
function StatusHandle.Update( target,statusTab,battle ,...)
	local args = {...}
	for i=#statusTab,1,-1 do
		local s = statusTab[i]
		if s and s.round>0 then
			Status[s.name].update(target,s,battle,unpack(args))
		end
		if s and (s.round <=0 or s.value <=0) then
			local name = s.name
			Status[name].remove(target,s,battle,unpack(args))
			table.remove(statusTab,i)
		end
	end
end
function StatusHandle.Remove( target,status,statusTab,battle ,...)
	local args = {...}
	Status[status.name].remove(target,status,battle,unpack(args))
	local p=TableFunc.find(statusTab,status)
	table.remove(statusTab,p)
end
function StatusHandle.RemoveAll( target,statusTab,battle ,...)
	local args = {...}
	for i=#statusTab,1,-1 do
		local s = statusTab[i]
		local name = s.name
		Status[name].remove(target,s,battle,unpack(args))
		table.remove(statusTab,i)
	end
end


return StatusHandle