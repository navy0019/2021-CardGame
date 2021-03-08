local tableFunc = {}
function tableFunc.upset(tab)
	local nt = {}
	for i=1,#tab do
		local r = _G.rng:random(1,#tab)
		local v = tab[r]
		table.insert(nt,v)
		table.remove(tab,r)
	end
	for k,v in pairs(nt) do
		table.insert(tab,v)
	end

end
function tableFunc.find(tab,target,key)
	key=key or nil
	if key then
		for k,v in pairs(tab) do
			if v[key] == target then
				return k
			end
		end
	else
		for k,v in pairs(tab) do
			if v == target then
				return k
			end
		end
	end
	return false
end

function tableFunc.copy( tab )
	local nt = {}
	for k,v in pairs(tab) do
		nt[k]=v
	end
	return nt
end
function tableFunc.randomPick( tab ,num)
	local nt = {}
	for i=1,num do
		table.insert(nt , tab[_G.rng:random(#tab)])
	end
	return nt
end
function tableFunc.contains( tab,target )
	for k,v in pairs(tab) do
		if v == target then
			return true
		end
	end
	return false
end
function tableFunc.swap( tab,pos1,pos2 )
	local temp = tab[pos1]
	tab[pos1]=tab[pos2]
	tab[pos2]=temp
end

function tableFunc.merge(targetTab, tab )
	for k,v in pairs(tab) do
		table.insert(targetTab,v)
	end
end
function tableFunc.countTable(tab)
	local index=0
	for k,v in pairs(tab) do
		index=index+1
	end
	return index
end
return tableFunc


