VMovement = VMovement or {}

if SERVER then
	include("vmovement/sh_settings.lua")
	AddCSLuaFile("vmovement/sh_settings.lua")

	include("vmovement/sh_movement.lua")
	AddCSLuaFile("vmovement/sh_movement.lua")

	AddCSLuaFile("vmovement/cl_numslider.lua")
end

if CLIENT then
	include("vmovement/sh_settings.lua")
	AddCSLuaFile("vmovement/sh_settings.lua")

	include("vmovement/sh_movement.lua")
	AddCSLuaFile("vmovement/sh_movement.lua")

	include("vmovement/cl_numslider.lua")
	AddCSLuaFile("vmovement/cl_numslider.lua")
end