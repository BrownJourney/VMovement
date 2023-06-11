
SWEP.BounceWeaponIcon  = false

SWEP.PrintName		= "slide"
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
	SWEP.ViewModelFOV		= 45
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
	if CLIENT then return end
	local vm = self.Owner:GetViewModel()
	-- local sequence = vm:LookupSequence("huyjuy_slide_start")
	-- vm:SendViewModelMatchingSequence(sequence)
	-- self.NextSequence = CurTime() + 0
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

function SWEP:Think()
	if CLIENT then return end
	local vm = self.Owner:GetViewModel()

	self.NextAnim = "huyjuy_slide_zaloop"

	if not self.Slided then
		if not self.Owner:Sliding() then
			self.NextAnim = "huyjuy_slide_cum"
			self.Slided = true
			self.NextSequence = 0
		end
	end

	if (self.NextSequence or 0) < CurTime() then
		if self.NoAnims then
			if SERVER then
				if IsValid(self.Owner.VMovementPreviousWep) then
					self.Owner:SelectWeapon(self.Owner.VMovementPreviousWep:GetClass())
				end
				self:Remove()
			end
		else
			local sequence = vm:LookupSequence(self.NextAnim)
			self.NextSequence = CurTime() + vm:SequenceDuration(sequence)
			vm:SendViewModelMatchingSequence(sequence)

			if self.Slided then
				self.NoAnims = true
			end
		end
	end

	-- print(self.NextAnim)
end

local aimlerp = 0

function SWEP:GetViewModelPosition( pos, ang )

	if !CLIENT then return end

	pos = pos + ang:Forward() * 15
	
	return pos, ang
	
end

function SWEP:Holster(wep)
	if not IsFirstTimePredicted() then return end

	return true
end

function SWEP:OnRemove()
	if CLIENT then return end
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
