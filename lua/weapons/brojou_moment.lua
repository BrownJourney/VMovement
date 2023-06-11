
SWEP.BounceWeaponIcon  = false

SWEP.PrintName		= "parkour"
SWEP.Author			= "brojuo"
SWEP.Contact		= ""
SWEP.Purpose		= ""
SWEP.Instructions	= ""

SWEP.ViewModel		= "models/govnojuy_parkour_c_hands.mdl"
SWEP.WorldModel		= "models/weapons/w_357.mdl"

SWEP.HoldType		= "normal"

SWEP.Category		= "Brojou moment"

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.Primary.Recoil			= 0.5

SWEP.Primary.Damage			= 40  
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.2

SWEP.Primary.Delay			= 0.1

SWEP.Primary.Force			= 3

SWEP.Primary.ClipSize		= 30
SWEP.Primary.TakeAmmo		= 1
SWEP.Primary.DefaultClip	= 30
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= nil;

SWEP.ProjectileVelocity		= 10000
SWEP.Throwable				= false
SWEP.Melee					= false
SWEP.MeleeRange				= 64

SWEP.HitSoundMaxRand = 6
SWEP.HitSoundFormat = ".wav"

SWEP.UseHands = true

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.PrimarySound			= ""

if SERVER then

	SWEP.Weight				= 5
	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false

end

if CLIENT then

	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= false
	SWEP.ViewModelFOV		= 90
	SWEP.ViewModelFlip		= false
	
end

function SWEP:SetupDataTables()
	
end

function SWEP:DrawWorldModel()
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
	local vm = self.Owner:GetViewModel()
	vm:SetPlaybackRate(1)
	local sequence = vm:LookupSequence("huyjuy_climb_zaloop")
	vm:SendViewModelMatchingSequence(sequence)
end

function SWEP:Reload()
	
end

function SWEP:CanReload()
	return false
end

function SWEP:SecondaryAttack()	

end

function SWEP:CanPrimaryAttack()
	return false
end

SWEP.Sounds = {
	["huyjuy_climb_zaloop"] = {
		"physics/cardboard/cardboard_box_impact_soft1.wav",
		"physics/cardboard/cardboard_box_impact_soft2.wav",
		"physics/cardboard/cardboard_box_impact_soft3.wav",
		"physics/cardboard/cardboard_box_impact_soft4.wav",
		"physics/cardboard/cardboard_box_impact_soft5.wav",
		"physics/cardboard/cardboard_box_impact_soft6.wav",
		"physics/cardboard/cardboard_box_impact_soft7.wav"
	},
	["huyjuy_climb_cum"] = {
		"npc/combine_soldier/gear1.wav",
		"npc/combine_soldier/gear2.wav",
		"npc/combine_soldier/gear3.wav",
		"npc/combine_soldier/gear4.wav",
		"npc/combine_soldier/gear5.wav",
		"npc/combine_soldier/gear6.wav"
	}
}
function SWEP:Think()
	local vm = self.Owner:GetViewModel()

	self.NextAnim = "huyjuy_climb_zaloop"

	if not self.Climbed then
		local ledgePos = self.Owner:GetNWVector("ClimbHook")

		if getHeightDiff(self.Owner:GetPos(), ledgePos) < 60 then
			self.NextAnim = "huyjuy_climb_cum"
			self.Climbed = true
			self.NextSequence = 0
		end
	end

	if self.Owner:Climbing() and (self.NextSequence or 0) < CurTime() then
		if self.NoAnims then
			if SERVER then
				self:Remove()
			end
		else
			local sequence = vm:LookupSequence(self.NextAnim)
			self.NextSequence = CurTime() + vm:SequenceDuration(sequence)
			vm:SendViewModelMatchingSequence(sequence)
			local sndData = self.Sounds[self.NextAnim]
			if sndData and CLIENT and GetConVar("vmovement_climb_sounds"):GetBool() then
				self:EmitSound(sndData[math.random(1, #sndData)], 50)
			end

			if self.Climbed then
				self.NoAnims = true
			end
		end
	end
end

local aimlerp = 0

function SWEP:GetViewModelPosition( pos, ang )

	if not CLIENT then return end

	local ply = self.Owner

	if not ply.VMovementPos then return end

	pos = ply.VMovementPos + ang:Forward() * 1
	ang = ply.VMovementAng

	return pos, ang
	
end

function SWEP:Holster(wep)
	if not IsFirstTimePredicted() then return end

	return true
end

function SWEP:OnRemove()

end

function SWEP:DrawHUD()

end

function SWEP:PreDrawViewModel(vm, wep, ply)

end

function SWEP:TranslateFOV( current_fov )

end

function SWEP:ResetBones()

	-- local vm = self.Owner:GetViewModel()
	-- if not IsValid(vm) then return end
	
	-- if (!vm:GetBoneCount()) then return end
	
	-- for i = 0, vm:GetBoneCount() do
	-- 	vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
	-- 	vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
	-- 	vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
	-- end
	
end
