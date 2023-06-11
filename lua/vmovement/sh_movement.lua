
local CPlayer = FindMetaTable("Player")
local CEntity = FindMetaTable("Entity")

if SERVER then
	util.AddNetworkString("VMovement_ClimbStart")
	util.AddNetworkString("VMovement_ClimbCancel")
	util.AddNetworkString("NW.EXT.VECTOR")
end

sound.Add({
	name = "vmovement_slide",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 40,
	pitch = {90, 110},
	sound = "physics/body/body_medium_scrape_smooth_loop1.wav"
})

VMovement.CustomSpeeds = {
	["vmovement_walkspeed"] = "SetWalkSpeed",
	["vmovement_runspeed"] = "SetRunSpeed",
	["vmovement_jumppower"] = "SetJumpPower"
}

local function VersitileMovementSetup(ply)
	if not VMovement.Enabled_CustomSpeed then return end
	for cvar, funcname in pairs(VMovement.CustomSpeeds) do
		ply[funcname](ply, GetConVar(cvar):GetInt())
	end
end

local isDebugging = true
local function debug_print(...)
	if not isDebugging then return end

	print(...)
end

function CPlayer:PreventAirForce(bypass)
	if bypass then return end
	timer.Create("PreventAirForce_"..self:SteamID64(), 0.1, 1, function()
		if not IsValid(self) then return end
		if self:IsOnGround() then return end
		if not self:Alive() then return end
		self:SetVelocity(-self:GetVelocity())
	end)
end

--[[-------------------------------------------------------------------------
Bypassing default NW library because it doesn't update our data on every change
---------------------------------------------------------------------------]]
function CEntity:SetLocalNetVector(id, var)
	if !isvector(var) then
		return
	end

	if not self:IsPlayer() then
		return
	end

	self:SetNWVector(id, var)

	if CLIENT then return end

	if (self.NextNWUpdate or 0) < CurTime() then
		self.NextNWUpdate = CurTime() + 0.1
		net.Start("NW.EXT.VECTOR")
			net.WriteEntity(self)
			net.WriteString(id)
			net.WriteVector(var)
		net.Send(self)
	end
end

local dash_force = 1000

local function PlayerHandleDashEvent(ply, dir)
	ply:SetVelocity(ply:GetVelocity() + dir)
	ply:PreventAirForce(canBypass)
	ply.NextDashTime = CurTime() + 0.5
	ply.NextSlideTime = CurTime() + 0.5

	local viewPunchMultiply = 0.005
	local zPunch = dir.z * viewPunchMultiply * 3
	ply:ViewPunch(Angle(dir.x * viewPunchMultiply, dir.y * viewPunchMultiply, math.random(-zPunch, zPunch)))
end

local function PlayerDashKeyPressHandler(ply, key)
	local isDoubletapSet = VMovement.Enabled_Dash_Doubletap

	if not IsValid(ply) then
		return
	end

	if not VMovement.Enabled then
		return
	end

	if not VMovement.Enabled_Dash then
		return
	end

	if VMovement.Enabled_Dash_Doubletap then
		return
	end

	local ang = ply:GetAngles()

	local dashKey = GetConVar("vmovement_dash_button"):GetInt()
	if key != dashKey then
		return
	end

	if not ply:Alive() then
		return
	end

	local tmrEraseID = "EraseLastPressedKey_"..ply:SteamID64()

	timer.Remove(tmrEraseID)

	if (ply.NextDashTime or 0) >= CurTime() then
		return
	end

	if (not ply:IsOnGround() and key != IN_JUMP) or ply:Crouching() or ply:Climbing() then
		return
	end

	local currentDashDirection = ply:GetVelocity() * dash_force / 200
	PlayerHandleDashEvent(ply, currentDashDirection)
end


local function PlayerDashDoubletapHandler(ply, key)
	local isDoubletapSet = VMovement.Enabled_Dash_Doubletap

	if not IsValid(ply) then
		return
	end

	if not VMovement.Enabled then
		return
	end

	if not VMovement.Enabled_Dash then
		return
	end

	if not VMovement.Enabled_Dash_Doubletap then
		return
	end

	local ang = ply:GetAngles()
	local key_handlers = {
		[IN_FORWARD] = function()
			return ang:Forward() * dash_force
		end,
		[IN_BACK] = function()
			return ang:Forward() * -dash_force
		end,
		[IN_MOVERIGHT] = function()
			return ang:Right() * dash_force
		end,
		[IN_MOVELEFT] = function()
			return ang:Right() * -dash_force
		end,
	}

	if not key_handlers[key] then
		return
	end

	if not ply:Alive() then
		return
	end

	local tmrEraseID = "EraseLastPressedKey_"..ply:SteamID64()
	timer.Remove(tmrEraseID)

	if ply.LastPressedKey then
		if ply.LastPressedKey != key then
			ply.LastPressedKey = key
			return
		end
	else
		ply.LastPressedKey = key
		-- debug_print("FIRST KEY PRESS")
		local timeToClear = 0.25
		timer.Create(tmrEraseID, timeToClear, 1, function()
			if not IsValid(ply) then return end
			-- debug_print("DROP AFTER TIME")
			ply.LastPressedKey = nil
		end)
		return
	end

	if (ply.NextDashTime or 0) >= CurTime() then
		return
	end

	if (not ply:IsOnGround() and key != IN_JUMP) or ply:Crouching() or ply:Climbing() then
		return
	end

	local handler = key_handlers[ply.LastPressedKey]
	local currentDashDirection, canBypass = handler()
	PlayerHandleDashEvent(ply, currentDashDirection)
end

local function PlayerDashKeyReleaseHandler(ply, key)
	if VMovement.Enabled_Dash_Doubletap then
		return
	end

	-- if key == ply.LastPressedKey then
	-- 	ply.LastPressedKey = nil;
	-- end
end

function CPlayer:Sliding()
	return self:GetNWBool("IsSliding")
end

function CPlayer:SlideCancel(bypass)
	if not self:Sliding() then
		return
	end
	
	self.IsSliding = false
	self:SetNWBool("IsSliding", false)
	if self.ActiveCSP then
		local fTime = 0.25
		self.ActiveCSP:FadeOut(fTime)
		timer.Simple(fTime, function()
			if not IsValid(self) then return end
			self.ActiveCSP:Stop()
		end)
	end
	if self.SlideAcceleration <= 0 or bypass then
		self.IsSlideKeyReleased = true
	end
end

local function PlayerSlideMoveHandler(ply, mvd, cmd)
	local slide_acceleration = 200

	if not IsValid(ply) then
		return
	end

	if not VMovement.Enabled then
		return
	end

	if not VMovement.Enabled_Slide then
		return
	end

	local isDuck, isMovementPressed = mvd:KeyDown(IN_DUCK), mvd:KeyDown(IN_FORWARD) and mvd:KeyDown(IN_SPEED)
	local plyVelocityLength = mvd:GetVelocity():Length()
	local plyPos, plyAng = mvd:GetOrigin(), mvd:GetAngles()

	if not isDuck then
		ply.IsSlideKeyReleased = true
	end

	local scale = 0.5

	if ply.IsSliding then
		if not ply:IsOnGround() or ply.SlideAcceleration <= 0 or not isDuck or ply:GetVelocity():Length() <= 10 then
			ply:SlideCancel(not ply:IsOnGround())
			return
		end

		if (ply.NextSlideProcess or 0) >= CurTime() then
			return
		end

		ply.NextSlideProcess = CurTime() + 0.075 * scale

		local alterScale = 2
		local accelerationFall = ply.SlideMaxAcceleration / (20 * alterScale) / GetConVar("vmovement_slide_duration"):GetFloat()
		local pOrigin = ply:EyePos() + plyAng:Forward() * 5
		local nextPlayerPoint = util.TraceLine({
			start = pOrigin,
			endpos = pOrigin - Vector(0, 0, 100),
			filter = ply,
			MASK = MASK_ALL
		})

		local heightDiff = plyPos.z - nextPlayerPoint.HitPos.z

		if heightDiff > 5 then
			accelerationFall = ply.SlideMaxAcceleration / (100 * alterScale)
		end

		if ply:GetVelocity():Length() < 50 then
			accelerationFall = ply.SlideMaxAcceleration / (5 * alterScale)
		end

		ply.SlideAcceleration = math.max(ply.SlideAcceleration - accelerationFall, 0)
		mvd:SetVelocity(mvd:GetVelocity() + ply.SlideAngle:Forward() * ply.SlideAcceleration * 0.5)

		return
	else
		if not isDuck or (not isMovementPressed and plyVelocityLength < slide_acceleration) or (isMovementPressed and plyVelocityLength < 50) or not ply:IsOnGround() or ply:WaterLevel() > 0 or ply:GetMoveType() == MOVETYPE_NOCLIP or not ply:Alive() then
			return
		end
	end

	if not ply.IsSlideKeyReleased then
		return
	end

	ply.IsSlideKeyReleased = false

	if (ply.NextSlideTime or 0) >= CurTime() then
		return
	end

	local saved_velocity = GetConVar("vmovement_slide_savevelocity"):GetBool() and plyVelocityLength * scale or 0

	ply.IsSliding = true
	ply.SlideAngle = mvd:GetVelocity():Angle()
	ply.SlideAcceleration = math.max(slide_acceleration, saved_velocity)
	ply.SlideMaxAcceleration = ply.SlideAcceleration
	ply.NextSlideTime = CurTime() + 1
	ply:SetNWBool("IsSliding", true)
	-- ply:EmitSound("vmovement_slide")
	if VMovement.Enabled_ClimbSounds then
		local CSP_SlideSound = CreateSound(ply, "physics/body/body_medium_scrape_smooth_loop1.wav")
		CSP_SlideSound:Play()
		CSP_SlideSound:ChangeVolume(0.1)
		ply.ActiveCSP = CSP_SlideSound
	end
	local activeWep = ply:GetActiveWeapon()
	if not IsValid(activeWep) or activeWep.HoldType == "normal" then
		ply:GiveAnimSWEP("brojou_moment_slide")
	end
end

local function PlayerSlideRemoveStep(ply)
	if not ply:Sliding() then
		return
	end

	return true
end

local SlideFOVLerp, SlideAngLerp, ClimbVectorLerp
local function VMovementCalcView(ply, pos, ang, fov)
	SlideFOVLerp = SlideFOVLerp or fov
	SlideAngLerp = SlideAngLerp or ang
	ClimbVectorLerp = ClimbVectorLerp or ply:EyePos()

	if ply:Climbing() then
		ClimbVectorLerp = LerpVector(FrameTime() * 15, ClimbVectorLerp, ply:EyePos() + Vector(0, 0, 0))
	else
		ClimbVectorLerp = nil;
	end

	local plyActiveWep = ply:GetActiveWeapon()
	local isValidWep = IsValid(plyActiveWep)

	if isValidWep then
		local wepClass = plyActiveWep:GetClass()
		if not wepClass:find("brojou") and plyActiveWep.Primary and not ply:Climbing() then
			return
		end
	else
		if not ply:Sliding() and math.abs(SlideFOVLerp - fov) < 0.1 then
			return
		end
	end

	if not ply:Sliding() and math.abs(SlideFOVLerp - fov) < 0.1 and not ply:Climbing() then
		return
	end

	if (plyActiveWep.GetRoll and plyActiveWep:GetRoll() != 0) then
		ang.Roll = plyActiveWep:GetRoll()
	end

	local lerpVal = FrameTime() * 10
	SlideFOVLerp = Lerp(lerpVal, SlideFOVLerp, ply:GetNWBool("IsSliding", false) and fov + 10 or fov)
	SlideAngLerp = LerpAngle(lerpVal, SlideAngLerp, ang)

	local view = {
		origin = ClimbVectorLerp,
		angles = ang,
		fov = SlideFOVLerp,
		drawviewer = false
	}

	ply.VMovementPos = view.origin
	ply.VMovementAng = view.angles

	return view
end

local function VMovementHideVM(vm, ply)
	-- if ply:Climbing() then
	-- 	return true
	-- end
end

function CPlayer:Climbing()
	return self.ClimbData
end

function CPlayer:ClimbCancel()
	debug_print("climb cancel")
	self:SetMoveType(MOVETYPE_WALK)
	self.ShouldDisableJump = false
	self.PreparedToClimb = false
	-- self:PreventAirForce()
	if self:Climbing() and self:Climbing().velocity then
		self:SetVelocity(self:GetAngles():Forward() * self:Climbing().velocity:Length() / 2)
	end
	self.ClimbData = nil

	if SERVER then
		self:RemoveAnimSWEP("brojou_moment")
		net.Start("VMovement_ClimbCancel")
		net.Send(self)
	end
end

function CPlayer:GiveAnimSWEP(class)
	if CLIENT then return end
	self:SetSuppressPickupNotices(true)
	self.VMovementPreviousWep = self:GetActiveWeapon()
	self:SetActiveWeapon(NULL)
	self:Give(class)
	self:SelectWeapon(class)
	self:SetSuppressPickupNotices(false)
end

function CPlayer:RemoveAnimSWEP(class)
	if IsValid(self.VMovementPreviousWep) then
		self:SelectWeapon(self.VMovementPreviousWep:GetClass())
	end
	self:StripWeapon(class)
end

function getHeightDiff(posa, posb)
	return math.abs(posa.z - posb.z)
end

local maxClimbEndDistance = 50000
local maxStartClimbDistance = 50 -- с какой дальности можно начать взбираться на выступ
local minHeightStartClimb = 30 -- минимальная высота выступа
local function PlayerClimbKeyPress(ply, mvd, cmd)
	local SP = game.SinglePlayer()
	if CLIENT and SP then return end

	local maxHeightClimb = 100 * GetConVar("vmovement_climb_maxheight"):GetFloat() -- максимальная высота выступа
	maxClimbEndDistance =  maxClimbEndDistance * GetConVar("vmovement_climb_maxheight"):GetFloat()

	if not IsValid(ply) then
		return
	end

	if not VMovement.Enabled then
		return
	end

	if not VMovement.Enabled_Climb then
		return
	end

	local plyMoveType = ply:GetMoveType()

	if plyMoveType == MOVETYPE_NOCLIP or plyMoveType == MOVETYPE_LADDER then
		return
	end

	if (ply.NextClimbTime or 0) >= CurTime() then
		return
	end

	local plyPos, plyAng, plyVelocity = mvd:GetOrigin(), mvd:GetAngles(), mvd:GetVelocity()
	local climbEndOffsetPos = 1 -- как далеко подавать персонажа вперед после вскарабкивания

	if ply:IsSprinting() then
		climbEndOffsetPos = 20
	end

	local WT_Callback = function(wallTrace)
		ply:SetLocalNetVector("StartPos", wallTrace.HitPos)

		if not wallTrace.Hit then
			debug_print("cant find wall")
			return
		end

		if bit.band(wallTrace.Contents, CONTENTS_WATER) == CONTENTS_WATER then
			return
		end

		local wallObjectEntity = wallTrace.Entity
		if IsValid(wallObjectEntity) and (wallObjectEntity:IsNPC() or wallObjectEntity:IsPlayer() or wallObjectEntity:IsNextBot() or wallObjectEntity:IsPlayerHolding() or wallObjectEntity:GetVelocity():LengthSqr() > 100) then
			return
		end

		local unitsPerIteration = 1
		local groundTrace, climbStartTrace;
		for i = minHeightStartClimb / unitsPerIteration, maxHeightClimb / unitsPerIteration do
			local groundOffsetZ = 0 -- отступ от земли, чтобы избежать застревания в текстурах
			local unit = i * unitsPerIteration
			local climbStartTrace = util.TraceLine({
				start = wallTrace.HitPos,
				endpos = wallTrace.HitPos + Vector(0, 0, unit),
				filter = {ply, wallTrace.Entity},
				mask = MASK_ALL
			})

			local climbHookPos = Vector()
			climbHookPos.x = climbStartTrace.HitPos.x
			climbHookPos.y = climbStartTrace.HitPos.y
			climbHookPos.z = climbStartTrace.HitPos.z - unitsPerIteration
			ply:SetLocalNetVector("ClimbHook", climbHookPos)

			local climbOffset = unit <= 30 and climbEndOffsetPos * 2 or climbEndOffsetPos;
			local climbEndTrace = util.TraceLine({
				start = climbStartTrace.HitPos,
				endpos = climbStartTrace.HitPos + plyAng:Forward() * climbOffset,
				filter = ply,
				mask = MASK_ALL
			})

			if climbEndTrace.HitPos:DistToSqr(climbStartTrace.HitPos) > 1500 then
				debug_print("climb pos is too far")
				continue
			end

			local realGroundTrace = util.QuickTrace(climbEndTrace.HitPos, Vector(0, 0, -32), ply)
			if IsValid(realGroundTrace.Entity) or realGroundTrace.HitNormal.z < 1 then
				debug_print("climbing on entity or not straight surface")
				groundOffsetZ = groundOffsetZ + 10
			end

			ply:SetLocalNetVector("ClimbPos", climbEndTrace.HitPos)

			if not climbEndTrace.Hit then
				realGroundTrace.HitPos = realGroundTrace.HitPos + Vector(0, 0, groundOffsetZ)

				groundTrace = realGroundTrace
				break
			end
		end

		return groundTrace
	end


	local wallTraceSP = plyPos + Vector(0, 0, minHeightStartClimb)
	local climbAng = Angle()
	climbAng.p = 0
	climbAng.y = plyAng.y
	climbAng.r = plyAng.r
	local wallTrace = util.TraceLine({
		start = wallTraceSP,
		endpos = wallTraceSP + climbAng:Forward() * maxStartClimbDistance,
		filter = ply,
		mask = MASK_ALL
	})

	local groundTrace = WT_Callback(wallTrace)
	if not groundTrace then
		local trEyeposSP = ply:EyePos()
		wallTrace = util.TraceHull({
			start = trEyeposSP,
			endpos = trEyeposSP + plyAng:Forward() * maxStartClimbDistance * 1.25,
			mins = Vector(-10, -10, -10),
			maxs = Vector(10, 10, 10),
			filter = ply
		})
		if getHeightDiff(plyPos, wallTrace.HitPos) < minHeightStartClimb then
			return
		end
		groundTrace = WT_Callback(wallTrace)
		if not groundTrace then
			return
		end
	end

	local climbPos = groundTrace.HitPos
	local traceHull = function(pos)
		local trace = util.TraceHull({
			start = pos,
			endpos = pos,
			mins = ply:OBBMins(),
			maxs = ply:OBBMaxs(),
			filter = ply
		})
		return trace
	end

	if traceHull(climbPos).Hit then
		debug_print("pushing player futher")
		local fwdMove = ply:OBBMaxs().x * 2
		climbPos = climbPos + plyAng:Forward() * (climbEndOffsetPos + fwdMove)

		if traceHull(climbPos).Hit then
			climbPos = climbPos + Vector(0, 0, 5)
			if traceHull(climbPos).Hit then
				debug_print("Cant climb, not enough empty space")
				return
			end
		else
			local adjustUp = Vector(0, 0, 15)
			local traceLine = util.TraceLine({start = ply:GetNWVector("ClimbHook") + adjustUp, endpos = climbPos + adjustUp, filter = ply})
			ply:SetLocalNetVector("tr.Start", traceLine.StartPos)
			ply:SetLocalNetVector("tr.Hit", traceLine.HitPos)
			if traceLine.Hit then
				debug_print("Cant climb, line is hitting object")
				return
			end
		end
	end

	if plyPos:DistToSqr(climbPos) > maxClimbEndDistance then
		debug_print("climb is too far")
		return
	end

	ply.NextJumpStart = CurTime() + 1
	ply.ShouldDisableJump = true

	timer.Simple(0.01, function()
		if not IsValid(ply) then return end
		local punchAmplitude = math.min(math.abs(plyPos.z - climbPos.z) * 0.25, 20)
		ply:ViewPunch(Angle(math.random(-punchAmplitude, punchAmplitude), math.random(-punchAmplitude, punchAmplitude), math.random(-punchAmplitude, punchAmplitude)))
		ply.ClimbData = {startpos = plyPos, endpos = climbPos, ang = ply:GetAngles(), velocity = plyVelocity}
		ply:SetVelocity(-ply:GetVelocity())
		ply:SetMoveType(MOVETYPE_NOCLIP)
		ply:GiveAnimSWEP("brojou_moment")
		debug_print("climb started")
		if SERVER then
			net.Start("VMovement_ClimbStart")
				net.WriteTable(ply.ClimbData)
			net.Send(ply)
		end
	end)

	-- mvd:SetOrigin(climbPos)

	return true
end

local function PlayerClimbMoveHandler(ply, mvd, cmd)
	if not IsValid(ply) then
		return
	end

	local plyClimbData = ply:Climbing()
	local KEY_JUMP = IN_JUMP

	if not plyClimbData then
		if not mvd:KeyDown(KEY_JUMP) then
			return
		end

		if (ply.NextJumpStart or 0) >= CurTime() then
			return
		end

		cmd:RemoveKey(IN_JUMP)

		local processed = PlayerClimbKeyPress(ply, mvd, cmd)

		if processed then
			ply.NextJumpStart = CurTime() + 0.5
		else
			cmd:AddKey(IN_JUMP)
		end
		return
	end

	-- if (ply.NextClimbProcess or 0) >= CurTime() then
	-- 	return
	-- end

	-- ply.NextClimbProcess = CurTime() + 0.01

	local climbStart, climbEnd, climbAng = plyClimbData.startpos, plyClimbData.endpos, plyClimbData.ang
	local plyPos = mvd:GetOrigin()
	local plyDistToClimb = plyPos:DistToSqr(climbEnd)
	local heightDiff = math.abs(climbEnd.z - plyPos.z)
	local speedMultiply = 0.3 * GetConVar("vmovement_climb_speed"):GetFloat()
	local up_speed, forward_speed = 15, 15
	local climbUpSpeed, climbForwardSpeed = up_speed, forward_speed

	-- debug_print("distance:", plyDistToClimb)
	-- debug_print("height diff:", heightDiff)

	if plyDistToClimb > 1 then
		if plyDistToClimb < maxClimbEndDistance then
			local ledgePos = ply:GetNWVector("ClimbHook")
			local heightDiff = getHeightDiff(ledgePos, plyPos) 
			-- debug_print(heightDiff)
			if heightDiff > 20 and not plyClimbData.ledgeClimbed then
				climbEnd = ledgePos
				climbForwardSpeed = 0.1
				climbUpSpeed = climbUpSpeed * 0.5
			else
				plyClimbData.ledgeClimbed = true
			end

			if not ply.PreparedToClimb then
				climbEnd = ply:GetNWVector("StartPos") + ply:GetAngles():Forward() * -10
				climbForwardSpeed = forward_speed
				climbUpSpeed = up_speed
				if plyPos:DistToSqr(climbEnd) < 100 then
					ply.PreparedToClimb = true
				end
			end

			local x = math.Approach(plyPos.x, climbEnd.x, climbForwardSpeed * speedMultiply)
			local y = math.Approach(plyPos.y, climbEnd.y, climbForwardSpeed * speedMultiply)
			local z = math.Approach(plyPos.z, climbEnd.z, climbUpSpeed * speedMultiply)
			mvd:SetOrigin(Vector(x, y, z))
		else
			ply:ClimbCancel()
		end
	else
		debug_print("finished climbing")
		-- ply:EmitSound("npc/combine_soldier/gear"..math.random(1, 6)..".wav", 100)
		ply:ClimbCancel()
	end
end

local function PlayerClimbBlockMovement(ply, cmd)
	if not IsValid(ply) then
		return
	end

	if not ply:Climbing() then
		return
	end

	cmd:ClearMovement()
	cmd:RemoveKey(IN_JUMP)
	cmd:RemoveKey(IN_DUCK)
	cmd:RemoveKey(IN_SPEED)
	cmd:RemoveKey(IN_ALT1)
	cmd:RemoveKey(IN_ALT2)
	cmd:RemoveKey(IN_WALK)
end

-- local function PlayerModifyMovementDamage(ent, CTDI)
-- 	local attacker = CTDI:GetAttacker()

-- 	if not IsValid(attacker) or not attacker:IsPlayer() then
-- 		return
-- 	end

-- 	if not attacker:IsOnGround() then
-- 		CTDI:ScaleDamage(3)
-- 	end

-- 	if attacker:Sliding() then
-- 		CTDI:ScaleDamage(5)
-- 	end
-- end

local mColor = Material( "pp/colour" )
local lerpAlpha = 0
local function VMovementScreenEffects()
	local ply = LocalPlayer()

	lerpAlpha = Lerp(FrameTime() * 5, lerpAlpha, ply:Sliding() and 1 or 0)
	render.UpdateScreenEffectTexture()

  	DrawSharpen( 2 * lerpAlpha, 0.3 )
  	DrawToyTown( 10 * lerpAlpha, ScrH() / 3 )
end

local function VMovementDebug()
	local ply = LocalPlayer()
	debugoverlay.Cross(ply:GetNWVector("StartPos"), 4, 1, Color( 0, 255, 0 ), true)
	debugoverlay.Cross(ply:GetNWVector("ClimbHook"), 8, 1, Color( 0, 0, 255 ), true)
	debugoverlay.Cross(ply:GetNWVector("ClimbPos"), 16, 1, Color( 255, 0, 0 ), true)

	debugoverlay.Line(ply:GetNWVector("tr.Start"), ply:GetNWVector("tr.Hit"), 1, Color(255, 255, 0), true)
end

local function VMovementDisableWeapons(name)
	if name == "CHudWeaponSelection" and LocalPlayer():Climbing() then
		return false
	end
end

if CLIENT then
	net.Receive("VMovement_ClimbStart", function()
		local climbPayload = net.ReadTable()

		LocalPlayer().ClimbData = climbPayload
		-- debug_print("client received start")
	end)

	net.Receive("VMovement_ClimbCancel", function()
		LocalPlayer():ClimbCancel()
		-- debug_print("client received end")
	end)

	net.Receive("NW.EXT.VECTOR", function(len)
		local ent = net.ReadEntity()
		local id = net.ReadString()
		local var = net.ReadVector()

		if IsValid(ent) then
			ent:SetNWVector(id, var)
		end
	end)
end

hook.Add("PlayerLoadout", "VersitileMovementSetup", VersitileMovementSetup)

hook.Add("PlayerButtonDown", "PlayerDashKeyPressHandler", PlayerDashKeyPressHandler)
hook.Add("KeyPress", "PlayerDashDoubletapHandler", PlayerDashDoubletapHandler)
hook.Add("KeyRelease", "PlayerDashKeyReleaseHandler", PlayerDashKeyReleaseHandler)

hook.Add("CalcView", "VMovementCalcView", VMovementCalcView)

hook.Add("PreDrawViewModel", "VMovementHideVM", VMovementHideVM)

hook.Add("SetupMove", "PlayerSlideMoveHandler", PlayerSlideMoveHandler)
hook.Add("SetupMove", "PlayerClimbMoveHandler", PlayerClimbMoveHandler)

hook.Add("PlayerFootstep", "PlayerSlideRemoveStep", PlayerSlideRemoveStep)

hook.Add("StartCommand", "VMovementStartCommand", PlayerClimbBlockMovement)

hook.Add("HUDPaint", "VMovementDebug", VMovementDebug)

hook.Add("RenderScreenspaceEffects", "VMovementScreenEffects", VMovementScreenEffects)

hook.Add("HUDShouldDraw", "VMovementDisableWeapons", VMovementDisableWeapons)