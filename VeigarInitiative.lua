if GetObjectName(GetMyHero()) ~= "Veigar" then return end

local version = "1"

function AutoUpdate(data)
    if tonumber(data) > tonumber(version) then
        print("New version found! " .. data)
        print("Downloading update, please wait...")
        DownloadFileAsync("https://raw.githubusercontent.com/JuanScripting/LoLScripts/master/VeigarInitiative.lua", SCRIPT_PATH .. "VeigarInitiative.lua", function() print("Update Complete, please 2x F6!") return end)
    end
end

GetWebResultAsync("https://raw.githubusercontent.com/JuanScripting/LoLScripts/master/Version/VeigarInitiative.version", AutoUpdate)

print ("Veigar Initiative v." .. version .. " Script Loaded")
require ("OpenPredict")
require ("DamageLib")

local VeigarMenu = Menu("Veigar", "Veigar")
VeigarMenu:SubMenu("Config", "Options")
VeigarMenu.Config:Boolean("showKilleable", "Show Combo for kill", true)
VeigarMenu.Config:Boolean("showFarm", "Show Q Farm", true)
VeigarMenu:SubMenu("Harass", "Harass Skills")
VeigarMenu.Harass:Boolean("Q", "Use Q", true)
VeigarMenu.Harass:Boolean("W", "Use W", false)


local Spells = {
 Q = {range = 950, delay = 0.25, speed = 2000, width = 30},
 W = {range = 900, delay = 0.25, speed = 1300, width = 112},
 R = {range = 650, delay = 0.25, speed = math.huge, width = 30}
}


function getMode()
	if _G.IOW_Loaded and IOW:Mode() then
		return IOW:Mode()
	elseif _G.PW_Loaded and PW:Mode() then
		return PW:Mode()
	elseif _G.DAC_Loaded and DAC:Mode() then
		return DAC:Mode()
	elseif _G.AutoCarry_Loaded and DACR:Mode() then
		return DACR:Mode()
	elseif _G.SLW_Loaded and SLW:Mode() then
		return SLW:Mode()
	end
end


OnTick(function()
	target = GetCurrentTarget()
	
	if VeigarMenu.Config.showKilleable:Value() then
		SHOW_KILLEABLE_COMBO()
		Combo()
	end
	if VeigarMenu.Config.showFarm:Value() then
		ShowFarm()
	end
	
	Harass()
end)


function VeigarQ(enemy)
	if Ready(_Q) and ValidTarget(enemy, Spells.Q.range) then
		local QPred = GetPrediction(enemy, Spells.Q)
		if QPred.hitChance > 0.4 then
			CastSkillShot(_Q, QPred.castPos)
			return true
		end
	end
	return false
end   

function VeigarW(enemy)
	if Ready(_W) and ValidTarget(enemy, Spells.W.range) then
		local WPred = GetPrediction(enemy, Spells.W)
		if WPred.hitChance > 0.3 then
			CastSkillShot(_W, WPred.castPos)
			return true
		end
	end
	return false
end   

function VeigarR(enemy)
	if Ready(_R) and ValidTarget(enemy, Spells.R.range) then
		CastTargetSpell(enemy, _R)
	end
end

local forKill=''

function spawnTextFunction(text, obj)
	drawpos = WorldToScreen(1,GetOrigin(obj).x, GetOrigin(obj).y, GetOrigin(obj).z)
	DrawText(text, 20, drawpos.x-60, drawpos.y, ARGB(255, 255, 255, 255))
end

function markForKillFunction(combo, _) 
	forKill=combo 
end

function Combo()
	if getMode() == "Combo" then
		makeDamageCalculations(target, markForKillFunction)
		if forKill=='Q' then
			VeigarQ(target)
		end
		
		if forKill=='R' then
			VeigarR(target)
		end
		
		if forKill=='Q+R' then
			if VeigarQ(target) then
				VeigarR(target)
			end
		end
		
		if forKill=='Q+W' then
			if VeigarQ(target) then
				VeigarW(target)
			end
		end
		
		if forKill=='W' then
			VeigarW(target)
		end
		
		if forKill=='W+R' then
			if VeigarW(target) then
				VeigarR(target)
			end
		end
		
		if forKill=='Q+W+R' then
			if VeigarQ(target) then
				if VeigarW(target) then
					VeigarR(target)
				end
			end
		end
	end
	forKill=''
end

function Harass()
	if getMode() == "Harass" then
		if VeigarMenu.Harass.Q:Value() then
			VeigarQ(target)
		end
		if VeigarMenu.Harass.W:Value() then
			VeigarW(target)
		end
	end
end

function ShowFarm()
	for _, minion in pairs(minionManager.objects) do
		if GetTeam(minion) ~= MINION_ALLY then
			if ValidTarget(minion, 1500) then
				if GetCurrentHP(minion) < getdmg("AA", minion, myHero) then
					DrawCircle(GetOrigin(minion), 50, 3, 8, GoS.Cyan)
				else
					if GetCurrentHP(minion) < getdmg("Q", minion, myHero) then
						DrawCircle(GetOrigin(minion), 50, 2, 8, GoS.Green)
					end
				end
			end
		end
	end
end

function GET_R_DAMAGE(enemy, dmgRecivedBefore)
	Rlvl = myHero:GetSpellData(_R).level
	if Rlvl>0 then
		if dmgRecivedBefore==nil then
			dmgRecivedBefore=0
		end
		ownAp = myHero.ap
		enemyMaxHealth = enemy.maxHealth
		enemyCurHealth = enemy.health - dmgRecivedBefore
		damage= ((100+75*Rlvl)+0.75*ownAp ) *  getMin(2, -1/67 * ((enemyCurHealth/enemyMaxHealth)*100) + 2.49)
		return myHero:CalcMagicDamage(enemy,damage)
	end
	return 0
end

function getMin(x, y)
	if x<y then
		return x
	end
	return y
end


function SHOW_KILLEABLE_COMBO()
	if IsObjectAlive(myHero) then
		for _, enemy in pairs(GetEnemyHeroes()) do
			makeDamageCalculations(enemy, spawnTextFunction)
		end
	end
end

function makeDamageCalculations(enemy, func)
	if IsObjectAlive(enemy) then
		QDmg= 0
		WDmg= 0
		RDmg= 0
		QDmg= getdmg("Q", enemy, myHero)
		WDmg= getdmg("W", enemy, myHero)
		RDmg= getdmg("R", enemy, myHero)		
		
		if Ready(_Q) and GetCurrentHP(enemy) < QDmg then
			DrawCircle(GetOrigin(enemy), 100, 5, 8, GoS.Green)
			func('Q', enemy)
			return
		end
		
		if Ready(_R) and GetCurrentHP(enemy) < RDmg then
			DrawCircle(GetOrigin(enemy), 100, 5, 8, GoS.Cyan)
			func('R', enemy)
			return
		end
		
		if Ready(_Q) and Ready(_R) and GetCurrentHP(enemy) < GET_R_DAMAGE(enemy, QDmg)+QDmg then
			DrawCircle(GetOrigin(enemy), 100, 5, 8, GoS.Blue)
			func('Q+R', enemy)
			return
		end

		if Ready(_W) and GetCurrentHP(enemy) < WDmg then
			DrawCircle(GetOrigin(enemy), 100, 5, 8, GoS.Red)
			func('W', enemy)
			return
		end
		
		if Ready(_Q) and Ready(_W) and GetCurrentHP(enemy) < QDmg+WDmg then
			DrawCircle(GetOrigin(enemy), 100, 5, 8, GoS.Blue)
			func('Q+W', enemy)
			return
		end
		
		if Ready(_W) and Ready(_R) and GetCurrentHP(enemy) < GET_R_DAMAGE(enemy, WDmg)+WDmg then
			DrawCircle(GetOrigin(enemy), 100, 5, 8, GoS.Blue)
			func('W+R', enemy)
			return
		end
		
		if Ready(_Q) and Ready(_W) and Ready(_R) and GetCurrentHP(enemy) < GET_R_DAMAGE(enemy, QDmg+WDmg)+QDmg+WDmg then
			DrawCircle(GetOrigin(enemy), 100, 5, 8, GoS.Blue)
			func('Q+W+R', enemy)
			return
		end
	end
end
