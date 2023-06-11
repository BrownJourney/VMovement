VMovement.Settings = {}

VMovement.Settings.CVars = {
	{
		name = "vmovement_enabled", def = 1, desc = "Enables/disables whole mod", limits = {0, 1}
	},
	{
		name = "vmovement_customspeed_enabled", def = 1, desc = "Enables/disables custom speed setups", limits = {0, 1}
	},
	{
		name = "vmovement_walkspeed", type = "slider", def = 150, desc = "Sets up player's walk speed", limits = {50, 400}
	},
	{
		name = "vmovement_runspeed", type = "slider", def = 250, desc = "Sets up player's run speed", limits = {100, 800}
	},
	{
		name = "vmovement_jumppower", type = "slider", def = 200, desc = "Sets up player's jump power", limits = {100, 600}
	},
	{
		name = "vmovement_climb_enabled", def = 1, desc = "Enables/disables ability to climb", limits = {0, 1}
	},
	{
		name = "vmovement_climb_sounds", def = 1, desc = "Enables/disables climb sounds", limits = {0, 1}
	},
	{
		name = "vmovement_climb_speed", type = "slider", def = 1, desc = "Scales the speed of climbing", limits = {0.5, 2}
	},
	{
		name = "vmovement_climb_maxheight", type = "slider", def = 1, desc = "Scales the maximum height that player can climb at", limits = {0.5, 2}
	},
	{
		name = "vmovement_slide_enabled", def = 1, desc = "Enables/disables ability to slide", limits = {0, 1}
	},
	{
		name = "vmovement_slide_duration", type = "slider", def = 1, desc = "Scales the duration of sliding", limits = {0.5, 10}
	},
	{
		name = "vmovement_slide_savevelocity", def = 1, desc = "Should slide speed be adjusted by the player current velocity", limits = {0, 1}
	},
	{
		name = "vmovement_dash_enabled", def = 1, desc = "Enables/disables ability to dash", limits = {0, 1}
	},
	{
		name = "vmovement_dash_button", type = "binder", def = KEY_LALT, desc = "Button to perform dash", limits = {0, 160}
	},
	{
		name = "vmovement_dash_doubletap", def = 0, desc = "Should dash be perfomed by doubletapping the key or by pressing the dash button", limits = {0, 1}
	},
}

VMovement.CVars_Localization = {
	["vmovement_enabled"] = {
		["ru"] = "Включение/отключение модификации",
		["en"] = "Enable/disable VMovement mod"
	},
	["vmovement_customspeed_enabled"] = {
		["ru"] = "Включение/отключение настройки скорости передвижения",
		["en"] = "Enable/disable custom speed"
	},
	["vmovement_walkspeed"] = {
		["ru"] = "Скорость ходьбы",
		["en"] = "Walk speed"
	},
	["vmovement_runspeed"] = {
		["ru"] = "Скорость бега",
		["en"] = "Run speed"
	},
	["vmovement_jumppower"] = {
		["ru"] = "Сила прыжка",
		["en"] = "Jump power"
	},
	["vmovement_climb_enabled"] = {
		["ru"] = "Включение/отключение возможности вскрабкивания",
		["en"] = "Enable/disable ability to climb"
	},
	["vmovement_climb_sounds"] = {
		["ru"] = "Включение/отключение звуков при вскрабкивании",
		["en"] = "Enable/disable VMovement mod"
	},
	["vmovement_climb_speed"] = {
		["ru"] = "Скорость вскарабкивания",
		["en"] = "Climb speed"
	},
	["vmovement_climb_maxheight"] = {
		["ru"] = "Максимальная высота, на которую можно залезть",
		["en"] = "Maximum height to climb on"
	},
	["vmovement_slide_enabled"] = {
		["ru"] = "Включение/отключение возможности подкатов",
		["en"] = "Enable/disable ability to slide"
	},
	["vmovement_slide_duration"] = {
		["ru"] = "Длительность подката",
		["en"] = "Enable/disable ability to slide"
	},
	["vmovement_slide_savevelocity"] = {
		["ru"] = "Сохранение инерции при подкате",
		["en"] = "Enable/disable ability to slide"
	},
	["vmovement_dash_enabled"] = {
		["ru"] = "Включение/отключение возможности уклонения",
		["en"] = "Enable/disable ability to dash"
	},
	["vmovement_dash_button"] = {
		["ru"] = "Кнопка для уклонения",
		["en"] = "Dash button"
	},
	["vmovement_dash_doubletap"] = {
		["ru"] = "Использовать двойное нажатие для уклонения",
		["en"] = "Enable/disable doubletapping to dash"
	},
	["button_apply"] = {
		["ru"] = "Применить настройки",
		["en"] = "Apply settings"
	},
	["button_default"] = {
		["ru"] = "Сбросить настройки",
		["en"] = "Drop to defaults"
	}
}

function VMovement.Settings.SetupCVars()
	for k, cvar in pairs(VMovement.Settings.CVars) do
		CreateConVar( cvar.name, cvar.def, cvar.flags or {FCVAR_ARCHIVE, FCVAR_REPLICATED}, cvar.desc, cvar.limits[1], cvar.limits[2] )
	end
end

VMovement.Settings.SetupCVars()

VMovement.Enabled = GetConVar("vmovement_enabled"):GetBool()
VMovement.Enabled_Climb = GetConVar("vmovement_climb_enabled"):GetBool()
VMovement.Enabled_ClimbSounds = GetConVar("vmovement_climb_sounds"):GetBool()
VMovement.Enabled_Slide = GetConVar("vmovement_slide_enabled"):GetBool()
VMovement.Enabled_CustomSpeed = GetConVar("vmovement_customspeed_enabled"):GetBool()
VMovement.Enabled_Dash = GetConVar("vmovement_dash_enabled"):GetBool()
VMovement.Enabled_Dash_Doubletap = GetConVar("vmovement_dash_doubletap"):GetBool()

cvars.AddChangeCallback("vmovement_enabled", function(convar, oldValue, newValue)
	VMovement.Enabled = GetConVar("vmovement_enabled"):GetBool()
end)
cvars.AddChangeCallback("vmovement_climb_enabled", function(convar, oldValue, newValue)
	VMovement.Enabled_Climb = GetConVar("vmovement_climb_enabled"):GetBool()
end)
cvars.AddChangeCallback("vmovement_slide_enabled", function(convar, oldValue, newValue)
	VMovement.Enabled_Slide = GetConVar("vmovement_slide_enabled"):GetBool()
end)
cvars.AddChangeCallback("vmovement_customspeed_enabled", function(convar, oldValue, newValue)
	VMovement.Enabled_CustomSpeed = GetConVar("vmovement_customspeed_enabled"):GetBool()
end)
cvars.AddChangeCallback("vmovement_dash_enabled", function(convar, oldValue, newValue)
	VMovement.Enabled_Dash = GetConVar("vmovement_dash_enabled"):GetBool()
end)
cvars.AddChangeCallback("vmovement_dash_doubletap", function(convar, oldValue, newValue)
	VMovement.Enabled_Dash_Doubletap = GetConVar("vmovement_dash_doubletap"):GetBool()
end)
cvars.AddChangeCallback("vmovement_climb_sounds", function(convar, oldValue, newValue)
	VMovement.Enabled_ClimbSounds = GetConVar("vmovement_climb_sounds"):GetBool()
end)

local function bool_to_number(bool)
	return bool and 1 or 0
end

if CLIENT then

	for i = 2, 64 do
		surface.CreateFont("times_"..i, {
			font = "Times New Roman",
			extended = true,
			size = i,
			weight = 1000,
		})
	end

	function VMovement.Settings.Menu()
		local lang = system.GetCountry():lower() == "ru" and "ru" or "en"

		if IsValid(VMovement.Settings.frame) then
			VMovement.Settings.frame:Remove()
		end

		local w, h = ScrW(), ScrH()
		local frame = vgui.Create("DFrame")
		frame:SetSize(w * 0.4, h * 0.55)
		frame:ShowCloseButton(true)
		frame:SetDraggable(true)
		frame:SetSizable(false)
		frame:SetTitle("VMovement | Settings")
		frame:Center()
		frame:MakePopup()

		VMovement.Settings.frame = frame

		local settings = vgui.Create("DPanel", frame)
		settings:Dock(FILL)
		settings:DockMargin(5, 5, 5, 5)
		settings.Paint = function(self, w, h)

		end

		local scroll = vgui.Create("DScrollPanel", settings)
		scroll:Dock(FILL)
		scroll:DockMargin(5, 5, 5, 5)

		for k, v in pairs(VMovement.Settings.CVars) do
			local setting = vgui.Create("DPanel", scroll)
			setting:Dock(TOP)
			setting:DockMargin(5, 5, 5, 5)
			setting:SetTall(h * 0.075)
			local color_black = Color(0, 0, 0, 240)
			local text = VMovement.CVars_Localization[v.name][lang]
			setting.Paint = function(self, w, h)
				draw.RoundedBox(0, 0, 0, w, h, color_black)
				draw.SimpleText(text, "times_24", 5, 5, color_white)
			end

			local handler = {
				["slider"] = function()
					local slider = vgui.Create("VMovementNumSlider", setting)
					slider:Dock(BOTTOM)
					slider:DockMargin(5, 5, 5, 5)
					slider:SetMinMax(v.limits[1], v.limits[2])
					slider:SetValue(GetConVar(v.name):GetFloat())
					if v.limits[1] < 1 then
						slider:SetDecimals(2)
					end

					return slider
				end,
				["checkbox"] = function()
					local size = setting:GetTall() * 0.4
					local checkbox = vgui.Create("DCheckBox", setting)
					checkbox:SetSize(size, size)
					checkbox:SetPos(5, setting:GetTall() - checkbox:GetTall() - 5)
					checkbox:SetValue(GetConVar(v.name):GetBool())

					return checkbox
				end,
				["binder"] = function()
					local binder = vgui.Create("DBinder", setting)
					binder:SetSize(w * 0.05, setting:GetTall() * 0.45)
					binder:SetPos(5, setting:GetTall() - binder:GetTall() - 5)
					binder:SetValue(GetConVar(v.name):GetInt())

					return binder
				end
			}

			setting.reader = handler[v.type or "checkbox"]()
			setting.reader.id = v.name
			setting.reader.type = v.type
		end

		local defaultButton = vgui.Create("DButton", frame)
		defaultButton:Dock(BOTTOM)
		defaultButton:DockMargin(5, 5, 5, 5)
		defaultButton:SetHeight(h * 0.025)
		defaultButton:SetText(VMovement.CVars_Localization["button_default"][lang])
		defaultButton:SetFont("times_20")
		defaultButton.DoClick = function()
			surface.PlaySound("buttons/button10.wav")
			for k, v in pairs(VMovement.Settings.CVars) do
				RunConsoleCommand(v.name, v.def)
			end

			VMovement.Settings.Menu()
		end

		local applyButton = vgui.Create("DButton", frame)
		applyButton:Dock(BOTTOM)
		applyButton:DockMargin(5, 5, 5, 5)
		applyButton:SetHeight(h * 0.04)
		applyButton:SetText(VMovement.CVars_Localization["button_apply"][lang])
		applyButton:SetFont("times_32")
		applyButton.DoClick = function()
			surface.PlaySound("buttons/blip1.wav")
			for k, v in pairs(scroll:GetCanvas():GetChildren()) do
				if not v.reader then continue end
				local value = v.reader.GetChecked and v.reader:GetChecked() or v.reader:GetValue()
				RunConsoleCommand(v.reader.id, isbool(value) and bool_to_number(value) or value)
			end
		end
	end

	concommand.Add("vmovement_settings", function()
		VMovement.Settings.Menu()
	end)

end