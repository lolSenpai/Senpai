if GetObjectName(GetMyHero()) ~= "Cassiopeia" then return end
if not pcall( require, "Inspired" ) then PrintChat("You are missing Inspired.lua - Go download it and save it Common!") return end
if not pcall( require, "DamageLib" ) then PrintChat("You are missing DamageLib.lua - Go download it and save it in Common!") return end
if not pcall( require, "DLib" ) then PrintChat("You are missing DLib.lua - Go download it and save it in Common!") return end

d = require 'DLib'

local myHero = GetMyHero()
local IsInDistance = d.IsInDistance
local ValidTarget = d.ValidTarget
local CalcDamage = d.CalcDamage
local GetTarget = d.GetTarget
local GetEnemyHeroes = d.GetEnemyHeroes
local GetDistance = d.GetDistance


local summonerNameOne = GetCastName(myHero,SUMMONER_1)
local summonerNameTwo = GetCastName(myHero,SUMMONER_2)
local Flash = (summonerNameOne:lower():find("summonerflash") and SUMMONER_1 or (summonerNameTwo:lower():find("summonerflash") and SUMMONER_2 or nil))

class "Cassiopeia"

function Cassiopeia:__init()

	OnTick(function(myHero) self:Loop(myHero) end)
	OnDraw(function(myHero) self:Drawings() end)

SenpaiCS = menu.addItem(SubMenu.new("Senpai Cassiopeia"))
KEY = SenpaiCS.addItem(SubMenu.new("Keys"))
	ONFR = KEY.addItem(MenuKeyBind.new("Flash R", string.byte("T")))
	ONHrs = KEY.addItem(MenuKeyBind.new("Harass", string.byte("C")))
	ONLHit = KEY.addItem(MenuKeyBind.new("Last Hit", string.byte("X")))
	ONClr = KEY.addItem(MenuKeyBind.new("Lane & Jungle Clear", string.byte("V")))
	ONCmb = KEY.addItem(MenuKeyBind.new("Combo Key", string.byte(" ")))
ONC = SenpaiCS.addItem(SubMenu.new("Combo"))
	ONQ = ONC.addItem(MenuBool.new("Use Q",true))
	ONW = ONC.addItem(MenuBool.new("Use W",true))
	ONE = ONC.addItem(MenuBool.new("Use E",true))
	EDelay = ONC.addItem(MenuSlider.new("Cast E Delay", 0, 0, 10000, 1))
	ONR = ONC.addItem(MenuBool.new("Use R",true))
FRM = SenpaiCS.addItem(SubMenu.new("Farm"))
	SEP1 = FRM.addItem(MenuSeparator.new("              LastHit"))
	HITE = FRM.addItem(MenuBool.new("LastHit with E",true))
	HITAUTO = FRM.addItem(MenuBool.new("Auto E if pois",true))
	SEP2 = FRM.addItem(MenuSeparator.new(" "))
	SEP3 = FRM.addItem(MenuSeparator.new("          Lane & Jungle Clear"))
	WVQ = FRM.addItem(MenuBool.new("Use Q",true))
	WVW = FRM.addItem(MenuBool.new("Use W",true))
	WVE = FRM.addItem(MenuBool.new("Use E",true))
	WVMana = FRM.addItem(MenuSlider.new("Min Mana %", 30, 1, 100, 1))
ITM = SenpaiCS.addItem(SubMenu.new("Item"))
	IHP = ITM.addItem(MenuBool.new("Use Auto Health Potion",true))
	QSSHP = ITM.addItem(MenuSlider.new("Auto Health Potion %", 50, 1, 100, 1))
	IMP = ITM.addItem(MenuBool.new("Use Auto Mana Potion",true))
	QSSMP = ITM.addItem(MenuSlider.new("Auto Mana Potion %", 50, 1, 100, 1))
	IZY = ITM.addItem(MenuBool.new("Use Auto Zhonya",true))
	QSSZhonya = ITM.addItem(MenuSlider.new("if My Health % use Zhonya", 50, 1, 100, 1))
	ISP = ITM.addItem(MenuBool.new("Use Auto Seraph",true))
	QSSSeraph = ITM.addItem(MenuSlider.new("if My Health % use Seraph", 70, 1, 100, 1))

MSC = SenpaiCS.addItem(SubMenu.new("Misc"))
	ERnd = MSC.addItem(MenuBool.new("Use E Humanizer",false))	
	ctIG = MSC.addItem(MenuBool.new("Auto Ignite",true))
	autoLVL = MSC.addItem(MenuBool.new("Auto Level-up",false))			
	KSQ = MSC.addItem(MenuBool.new("KillSteal with Q",true))
	KSE = MSC.addItem(MenuBool.new("KillSteal with E",true))	
	KSR = MSC.addItem(MenuBool.new("KillSteal with R",true))


Drawings = SenpaiCS.addItem(SubMenu.new("Drawings"))
	DrawAA = Drawings.addItem(MenuBool.new("Draw AA Range",true))
	DrawQ = Drawings.addItem(MenuBool.new("Draw Q & W Range",true))
	DrawE = Drawings.addItem(MenuBool.new("Draw E Range",false))
	SEP4 = Drawings.addItem(MenuSeparator.new(" "))
	DrawLastHitE = Drawings.addItem(MenuBool.new("Draw LastHit for E", false))
end

tick = 0
local lastE = 0
local lastlevel = GetLevel(myHero)-1

OnProcessSpell(function(unit, spell)
    if unit == myHero and spell.name == "CassiopeiaTwinFang" then
    lastE = GetTickCount()
    end
end)

function Cassiopeia:EHumanizer()
	local retE = false
	local HumanizerE = 0

	if ERnd.getValue() then
		HumanizerE = lastE + math.random(1,1500)
	else
		HumanizerE = lastE + (EDelay.getValue() * 100)
	end

	if GetTickCount() > HumanizerE then retE = true end
	return retE
end

function Cassiopeia:Loop(myHero)
	self:Checks()


	-- Combo
	if ONCmb.getValue() then
		self:Combo()
	end

	if ONFR.getValue() then
		self:FlashUlt()
	end

	-- LastHit
	if ONLHit.getValue() and HITE.getValue() then
		self:LastHit()
	end

	if HITAUTO.getValue() then
		for i,mobs in pairs(minionManager.objects) do
            		if GetTeam(mobs) == MINION_ENEMY and CANE then
	      			if IsPoisoned(mobs) and self:EHumanizer() and ValidTarget(mobs, 700) and GetCurrentHP(mobs) < getdmg("E",mobs) then
					CastTargetSpell(mobs, _E)
				end
			end
		end
	end

	-- LaneClear
	if ONClr.getValue() then
		self:LaneClear()
	end

	if ONHrs.getValue() then
		self:Harass()
	end


	if ctIG.getValue() then
		self:CastIgnite()
	end

	if KSQ.getValue() then
		self:Killsteal()
	end

	if IHP.getValue() or IMP.getValue() or IZY.getValue() or ISP.getValue() then
		self:Items()
	end
	
	if autoLVL.getValue() then
		if GetLevel(myHero) > lastlevel then
			leveltable = {_Q, _E, _W, _E, _E, _R, _E, _Q, _E , _Q, _R, _Q, _Q, _W, _W, _R, _W, _W}
			LevelSpell(leveltable[GetLevel(myHero)])
			lastlevel = GetLevel(myHero)
		end
	end


end

function Cassiopeia:Checks()
	
	CANQ = CanUseSpell(myHero, _Q) == READY
	CANW = CanUseSpell(myHero, _W) == READY
	CANE = CanUseSpell(myHero, _E) == READY
	CANR = CanUseSpell(myHero, _R) == READY
end

function Cassiopeia:Drawings()
	self:Killable()

	if DrawAA.getValue() then
		DrawCircle(GetOrigin(myHero).x, GetOrigin(myHero).y, GetOrigin(myHero).z,590,1,100,GoS.Yellow)
	end

	if DrawQ.getValue() then 
		DrawCircle(GetOrigin(myHero).x, GetOrigin(myHero).y, GetOrigin(myHero).z,850,3,100,0xff00FA9A)
	end

	if DrawLastHitE.getValue() then
		for i,mobs in pairs(minionManager.objects) do
            		if GetTeam(mobs) == MINION_ENEMY then
				
				if DrawLastHitE.getValue() and ValidTarget(mobs, 700) and GetCurrentHP(mobs) < getdmg("E",mobs) then
					DrawCircle(GetOrigin(mobs).x, GetOrigin(mobs).y, GetOrigin(mobs).z,70,1,20,GoS.Green)
				end
			end
		end
	end
		
	if DrawE.getValue() then 
		--DrawCircle(GetOrigin(myHero),GetCastRange(myHero, _R),3,1,0xffff0000)
		DrawCircle(GetOrigin(myHero).x, GetOrigin(myHero).y, GetOrigin(myHero).z,700,3,100,0xffff0000)
	end
end

function Cassiopeia:Items()
	local target = GetCurrentTarget()

	if ValidTarget(target,900) then
		if GetItemSlot(myHero,2003) > 0 and IHP.getValue() and 100*GetCurrentHP(myHero)/GetMaxHP(myHero) < QSSHP.getValue() then
        		CastSpell(GetItemSlot(myHero,2003))
       		end

        	if IMP.getValue() and 100*GetCurrentMana(myHero)/GetMaxMana(myHero) < QSSMP.getValue() then
			CastSpell(GetItemSlot(myHero,2004))
		end
	
		if IZY.getValue() and GetItemSlot(myHero,3157) > 0 and 100*GetCurrentHP(myHero)/GetMaxHP(myHero) <= QSSZhonya.getValue()  then
                	CastSpell(GetItemSlot(myHero,3157))
        	end

		if ISP.getValue() and GetItemSlot(myHero,3048) > 0 and 100*GetCurrentHP(myHero)/GetMaxHP(myHero) <= QSSSeraph.getValue()  then
                	CastTargetSpell(myHero, GetItemSlot(myHero,3048))
        	end
	end   
end

function Cassiopeia:CastIgnite()
local Ignite = (GetCastName(myHero,SUMMONER_1):lower():find("summonerdot") and SUMMONER_1 or (GetCastName(myHero,SUMMONER_2):lower():find("summonerdot") and SUMMONER_2 or nil))
	if Ignite then
        for _, d in pairs(GetEnemyHeroes()) do
            if CanUseSpell(myHero, Ignite) == READY and (20*GetLevel(GetMyHero())+50) > GetDmgShield(d)+GetCurrentHP(d)+GetHPRegen(d)*2.5 and ValidTarget(d, 600) then
                CastTargetSpell(d, Ignite)
            end
        end
    end
end

function Cassiopeia:castQ()
	local target = GetTarget(850,DAMAGE_MAGIC)
	if not target then return end

	if IsInDistance(target,850) and CANQ then
		local QPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),850,75,GetCastRange(myHero,_Q),55,false,true)
		if CANQ and ValidTarget(target, GetCastRange(myHero,_Q)) and ONQ.getValue() and QPred.HitChance == 1 then
			CastSkillShot(_Q,QPred.PredPos.x,QPred.PredPos.y,QPred.PredPos.z)
		end
	end	
end

function Cassiopeia:castW()
	local target = GetTarget(850,DAMAGE_MAGIC)
	if not target then return end

	if IsInDistance(target,850) and CANW then
		local WPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),850,125,GetCastRange(myHero,_W),55,false,true)
		if CANW and ValidTarget(target, GetCastRange(myHero,_W)) and ONW.getValue() and WPred.HitChance == 1 then
			CastSkillShot(_W,WPred.PredPos.x,WPred.PredPos.y,WPred.PredPos.z)
		end
	end
end

function IsPoisoned(unit)
	local poisoned = false
	for i=0, 63 do
		if GetBuffCount(unit,i) > 0 and GetBuffName(unit,i):lower():find("poison") then poisoned = true end
	end

	return poisoned
end

function Cassiopeia:castE()
	local target = GetTarget(700,DAMAGE_MAGIC)
	if not target then return end

	local poisoned = IsPoisoned(target)
	
	if CANE and self:EHumanizer() and poisoned and ONE.getValue() then
		CastTargetSpell(target, _E)
	end		
end

function Cassiopeia:castR()
	local target = GetTarget(825,DAMAGE_MAGIC)
	if not target then return end

	if IsInDistance(target,825) and CANR then
		local RPred = GetPredictionForPlayer(GetOrigin(myHero),target,GetMoveSpeed(target),math.huge,550,800,180,false,true)		
		if CANR and ValidTarget(target, 825) and RPred.HitChance == 1 then
			CastSkillShot(_R,RPred.PredPos.x,RPred.PredPos.y,RPred.PredPos.z)				 
		end
	end
end

function Cassiopeia:FlashUlt()
	DrawCircle(GetMousePos().x, GetMousePos().y, GetMousePos().z,70,3,20,GoS.Red)
	MoveToXYZ(GetMousePos())
	if Flash and CANR then
		for _, k in pairs(GetEnemyHeroes()) do
			if ValidTarget(k,850) then
				local pos = GetOrigin(k)
				DelayAction(function() self:castR() end, 0.3)
				CastSkillShot(Flash, pos.x, pos.y, pos.z)
				
			end
		end
	end
end

function Cassiopeia:Killable()
	for i,unit in pairs(GetEnemyHeroes()) do
	if unit ~= myHero then
	local EDmg = getdmg("E",unit)
	local unitPos = GetOrigin(unit)
	local dmg = CalcDamage(myHero, unit, EDmg ,0)
	local hp = GetCurrentHP(unit)
	local hPos = GetHPBarPos(unit)
        if dmg > 0 then 
		DrawText(math.ceil(hp/dmg).." E", 15, hPos.x, hPos.y+20, ARGB(255, 255, 255, 255))
	end
	end	
	end
end

function Cassiopeia:Killsteal()
	for i,enemy in pairs(GetEnemyHeroes()) do
		if CANQ and ValidTarget(enemy, 850) and KSQ.getValue() and GetCurrentHP(enemy) < getdmg("Q",enemy) then 
			self:castQ()
		elseif CANE and ValidTarget(enemy, 700) and KSE.getValue() and GetCurrentHP(enemy) < getdmg("E",enemy) then
			self:castE()
		elseif CANR and ValidTarget(enemy, GetCastRange(myHero, _R)) and KSR.getValue() and GetCurrentHP(enemy) < getdmg("R",enemy) then
			self:castR()
		end
	end
end

--Credits to Maxxxel For IsFacing
local lastattackposition={true,true,true}

function IsFacing(targetFace,range,unit) 
	range=range or 99999
	unit=unit or myHero
	targetFace=targetFace
	if (targetFace and unit)~=nil and (ValidTarget(targetFace,range,unit)) and GetDistance(targetFace,unit)<=range then
		local unitXYZ= GetOrigin(unit)
		local targetFaceXYZ=GetOrigin(targetFace)
		local lastwalkway={true,true,true}
		local walkway = GetPredictionForPlayer(GetOrigin(unit),targetFace,GetMoveSpeed(targetFace),0,1000,2000,0,false,false)

		if walkway.PredPos.x==targetFaceXYZ.x then

		if lastwalkway.x~=nil then

		local d1 = GetDistance(targetFace,unit)
    		local d2 = GetDistance2XYZ(lastwalkway.x,lastwalkway.z,unitXYZ.x,unitXYZ.z)
    		return d2 < d1


    	elseif lastwalkway.x==nil then
    		if lastattackposition.x~=nil and lastattackposition.name==GetObjectName(targetFace) then
			local d1 = GetDistance(targetFace,unit)
    			local d2 = GetDistance2XYZ(lastattackposition.x,lastattackposition.z,unitXYZ.x,unitXYZ.z)
    			return d2 < d1
    		end
    	end
    elseif walkway.PredPos.x~=targetFaceXYZ.x then
    	lastwalkway={x=walkway.PredPos.x,y=walkway.PredPos.y,z=walkway.PredPos.z} 

    	if lastwalkway.x~=nil then
		local d1 = GetDistance(targetFace,unit)
    		local d2 = GetDistance2XYZ(lastwalkway.x,lastwalkway.z,unitXYZ.x,unitXYZ.z)
    		return d2 < d1
    	end
    end
	end
end

function GetDistance2XYZ(x,z,x2,z2)
	if (x and z and x2 and z2)~=nil then
		a=x2-x
		b=z2-z
		if (a and b)~=nil then
			a2=a*a
			b2=b*b
			if (a2 and b2)~=nil then
				return math.sqrt(a2+b2)
			else
				return 99999
			end
		else
			return 99999
		end
	end	
end     		


function Cassiopeia:Combo()
	local target = GetCurrentTarget()
	if CANR and ValidTarget(target,825) and IsFacing(target,825) and GetPercentHP(target) <= 50 and GetPercentMP(myHero) >= 30 then
		self:castR()
	end

	if CANE and ValidTarget(target, 700) then
		self:castE()
	end

	if CANQ and ValidTarget(target,850) then
		self:castQ()
	end

	if CANW and ValidTarget(target,925) and IsPoisoned(target) then
		self:castW()
	end

	-- if missing q..
	if not CANQ and CANW and (not IsPoisoned(target)) and ValidTarget(target,925) then
		self:castW()
	end		
end

function Cassiopeia:Harass()
	local target = GetCurrentTarget()

	if CANE and ValidTarget(target, 700) then
		self:castE()
	end

	if CANQ and ValidTarget(target,850) then
		self:castQ()
	end

	if CANW and ValidTarget(target,925) and IsPoisoned(target) then
		self:castW()
	end

	-- if missing q..
	if not CANQ and CANW and (not IsPoisoned(target)) and ValidTarget(target,925) then
		self:castW()
	end		
end

function Cassiopeia:LastHit()
	for i,mobs in pairs(minionManager.objects) do
            	if GetTeam(mobs) == MINION_ENEMY and CANE then
	      		if ValidTarget(mobs, 700) and GetCurrentHP(mobs) < getdmg("E",mobs) then
				CastTargetSpell(mobs, _E)
			end
		end
	end
end

function Cassiopeia:LaneClear()
	if GetPercentMP(myHero) >= WVMana.getValue() then
		if CANQ and WVQ then
			local BestPos, BestHit = GetFarmPosition(850, 100)
			
			if BestPos and BestHit > 0 then 
				CastSkillShot(_Q,BestPos)
			end
		end

		if CANW and WVW then
			local BestPos, BestHit = GetFarmPosition(925, 90)
			
			if BestPos and BestHit > 0 then 
				CastSkillShot(_W,BestPos)
			end
		end

		for i,mobs in pairs(minionManager.objects) do
			if GetTeam(mobs) == 300 and CANE and self:EHumanizer() and IsPoisoned(mobs) and WVE.getValue() and ValidTarget(mobs, 700) then CastTargetSpell(mobs, _E) end
			if GetTeam(mobs) == MINION_ENEMY and self:EHumanizer() and IsPoisoned(mobs) and WVE.getValue() and ValidTarget(mobs, 700) and GetCurrentHP(mobs) < getdmg("E",mobs) then CastTargetSpell(mobs, _E) end

			if GetTeam(mobs) == MINION_ENEMY and CANE and self:EHumanizer() and IsPoisoned(mobs) and WVE.getValue() and ValidTarget(mobs, 700) then CastTargetSpell(mobs, _E) end
		end

	end
end

if _G[GetObjectName(myHero)] then
  	_G[GetObjectName(myHero)]()
end 

PrintChat("<font color=\"#FFFFFF\">[</font><font color='#ffff0000'>Senpai</font> <font color='#0000ff'>Cassiopeia</font><font color=\"#FFFFFF\">]: Loaded Successful! </font>")
