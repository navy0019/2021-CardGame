local monsterSkill = {
	attack={
		func=function( self,target,battle)
			target.GetHit(target,self.data.atk*-1,false,true,battle) end,
		},
	attack2={
		func=function (self,target,battle)
			target.GetHit(target,-7,false,true,battle)end}
}
return monsterSkill