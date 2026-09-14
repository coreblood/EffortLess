-- EffortLess - one press: deposit all eligible items to the Uncapped Vault, then log out.
-- 3.3.5a (Interface 30300). No C_Timer; timing via OnUpdate. Author: Mhortai.

local ADDON = "EffortLess"

-- Wire: the custom Uncapped Vault is addressed by verb over the REAGENTBANK
-- transport (same path SmallThings uses to stash single slots). VLTDEPALL banks
-- every deposit-eligible bag item in one server-side call; the server refuses the
-- rest (quest / bound / kept-rule items) and prints its own reason. No banker or
-- open vault window is needed - deposits work anywhere.
local TRANSPORT = "REAGENTBANK"
local VERB = "VLTDEPALL"

-- Logout settle timing: after the deposit send, wait until bags stop changing
-- (deposits landed) before logging out, capped so a noisy bag never blocks it.
local SETTLE = 1.2   -- seconds of no bag change = deposits settled
local CAP    = 6.0   -- hard ceiling before logout fires regardless

-- Armed auto-run: on login, wait this long (Cancel window; also lets the
-- REAGENTBANK pipe come up - a send racing login is silently dropped) then run.
local LOGIN_DELAY = 6.0

local defaults = { confirm = true, minimap = true, armed = false, mm = nil }
local db

-- forward declarations (locals used inside earlier-built closures)
local panel
local OpenOptions
local UpdateMinimapButton
local CancelArmed

-- ---------------------------------------------------------------------------
-- Deposit + logout sequence
-- ---------------------------------------------------------------------------
local seq = CreateFrame("Frame")
local running = false
local settle, cap = 0, 0

local function Msg(text)
	DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff" .. ADDON .. ":|r " .. text)
end

local function Send(verb)
	local me = UnitName("player")
	-- Prefer the realm addon's own send if present, else the proven raw path.
	local uv = _G.UncappedVault
	if uv and type(uv.Send) == "function" then
		local ok = pcall(uv.Send, verb)
		if ok then return end
	end
	SendAddonMessage(TRANSPORT, verb, "WHISPER", me)
end

local function FinishAndLogout()
	running = false
	seq:SetScript("OnUpdate", nil)
	seq:UnregisterEvent("BAG_UPDATE")
	Msg("deposited eligible items - logging out.")
	Logout()
end

seq:SetScript("OnEvent", function(self, event)
	if event == "BAG_UPDATE" and running then
		settle = 0 -- bags changed, a deposit landed - restart the settle window
	end
end)

local function Activate()
	if running then return end
	running = true
	settle, cap = 0, 0
	Send(VERB)
	seq:RegisterEvent("BAG_UPDATE")
	seq:SetScript("OnUpdate", function(self, elapsed)
		settle = settle + elapsed
		cap = cap + elapsed
		if settle >= SETTLE or cap >= CAP then
			FinishAndLogout()
		end
	end)
end

-- Confirmation gate (default on).
StaticPopupDialogs["EFFORTLESS_CONFIRM"] = {
	text = "Deposit ALL eligible items to the Vault and log out?",
	button1 = YES,
	button2 = NO,
	OnAccept = function() Activate() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	showAlert = true,
	preferredIndex = 3,
}

local function Trigger(skipConfirm)
	if running then return end
	if db.confirm and not skipConfirm then
		StaticPopup_Show("EFFORTLESS_CONFIRM")
	else
		Activate()
	end
end

-- ---------------------------------------------------------------------------
-- Armed auto-run on login (6s cancellable countdown)
-- ---------------------------------------------------------------------------
local armFrame, armLeft
local function BuildArmFrame()
	if armFrame then return end
	local f = CreateFrame("Frame", "EffortLessArmFrame", UIParent)
	f:SetWidth(300); f:SetHeight(70)
	f:SetPoint("TOP", UIParent, "TOP", 0, -160)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, edgeSize = 14,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	f:SetBackdropColor(0, 0, 0, 0.85)
	f:SetBackdropBorderColor(0.5, 0.35, 1)

	local txt = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	txt:SetPoint("TOP", 0, -12)
	txt:SetWidth(280); txt:SetJustifyH("CENTER")
	f.txt = txt

	local cancel = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	cancel:SetWidth(120); cancel:SetHeight(22)
	cancel:SetPoint("BOTTOM", 0, 10)
	cancel:SetText("Cancel this login")
	cancel:SetScript("OnClick", function() CancelArmed(true) end)

	f:Hide()
	armFrame = f
end

local function StartArmedCountdown()
	if running then return end
	BuildArmFrame()
	armLeft = LOGIN_DELAY
	armFrame.txt:SetText(ADDON .. ": armed - depositing all & logging out")
	armFrame:Show()
	armFrame:SetScript("OnUpdate", function(self, elapsed)
		armLeft = armLeft - elapsed
		if armLeft <= 0 then
			self:SetScript("OnUpdate", nil)
			self:Hide()
			Msg("armed auto-run - depositing all & logging out.")
			Activate() -- full action; armed skips the confirm dialog by design
		else
			self.txt:SetText(string.format(
				"%s: armed - deposit all & log out in %d ... (Cancel below or /el cancel)",
				ADDON, math.ceil(armLeft)))
		end
	end)
end

-- Cancel the pending armed countdown. thisLoginOnly=true keeps armed set.
CancelArmed = function(thisLoginOnly)
	if armFrame then
		armFrame:SetScript("OnUpdate", nil)
		armFrame:Hide()
	end
	if armLeft ~= nil then
		armLeft = nil
		Msg("armed auto-run cancelled" ..
			(db.armed and " (still armed - runs again next login; /el arm off to stop)." or "."))
	end
end

-- ---------------------------------------------------------------------------
-- Minimap button (free-drag, saves exact point; zero dependency)
-- ---------------------------------------------------------------------------
local mmbtn
local function BuildMinimapButton()
	if mmbtn then return end
	local b = CreateFrame("Button", "EffortLessMinimapButton", Minimap)
	b:SetWidth(31); b:SetHeight(31)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(8)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")
	b:SetMovable(true)
	b:SetClampedToScreen(true)

	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
	icon:SetWidth(20); icon:SetHeight(20)
	icon:SetPoint("CENTER", 0, 1)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local border = b:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetWidth(53); border:SetHeight(53)
	border:SetPoint("TOPLEFT")

	b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local function place()
		b:ClearAllPoints()
		if db.mm and db.mm.p then
			b:SetPoint(db.mm.p, UIParent, db.mm.rp or db.mm.p, db.mm.x or 0, db.mm.y or 0)
		else
			b:SetPoint("CENTER", Minimap, "CENTER", 54, -54)
		end
	end
	place()

	b:SetScript("OnDragStart", function(self) self:StartMoving() end)
	b:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local p, _, rp, x, y = self:GetPoint()
		db.mm = { p = p, rp = rp, x = x, y = y }
	end)

	b:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			OpenOptions()
		else
			Trigger(false)
		end
	end)

	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine(ADDON)
		GameTooltip:AddLine("Left-click: deposit all to Vault & log out.", 1, 1, 1)
		GameTooltip:AddLine("Right-click: options.", 1, 1, 1)
		GameTooltip:AddLine("Drag: move button.", 0.7, 0.7, 0.7)
		if db.armed then
			GameTooltip:AddLine("ARMED: auto-runs ~6s after every login.", 1, 0.5, 0.5)
		end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)

	mmbtn = b
end

function UpdateMinimapButton()
	if db.minimap then
		BuildMinimapButton()
		if mmbtn then mmbtn:Show() end
	elseif mmbtn then
		mmbtn:Hide()
	end
end

-- ---------------------------------------------------------------------------
-- Options panel (Interface -> AddOns -> EffortLess)
-- ---------------------------------------------------------------------------
local cbConfirm, cbMinimap, cbArm
local function BuildOptionsPanel()
	if panel then return end
	panel = CreateFrame("Frame", "EffortLessOptionsPanel", UIParent)
	panel.name = ADDON

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("EffortLess")

	local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	sub:SetWidth(360); sub:SetJustifyH("LEFT")
	sub:SetText("One press: deposit all eligible items to the Vault, then log out.")

	local function makeCheck(key, label, tip, y, onToggle)
		local cb = CreateFrame("CheckButton", "EffortLessOpt" .. key, panel,
			"InterfaceOptionsCheckButtonTemplate")
		cb:SetPoint("TOPLEFT", 16, y)
		_G[cb:GetName() .. "Text"]:SetText(label)
		cb.tooltipText = tip
		cb:SetScript("OnClick", function(self)
			onToggle(self:GetChecked() and true or false)
		end)
		return cb
	end

	cbConfirm = makeCheck("Confirm", "Confirm before depositing & logging out",
		"When on, a Yes/No prompt appears before EffortLess acts.", -60,
		function(v) db.confirm = v end)

	cbMinimap = makeCheck("Minimap", "Show minimap button",
		"The draggable bag icon on the minimap rim.", -90,
		function(v) db.minimap = v; UpdateMinimapButton() end)

	cbArm = makeCheck("Armed", "Auto-run on login (armed)",
		"When on, EffortLess deposits all & logs out ~6s after every login.", -120,
		function(v)
			db.armed = v
			if not v then CancelArmed() end
		end)

	local warn = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	warn:SetPoint("TOPLEFT", 40, -144)
	warn:SetWidth(340); warn:SetJustifyH("LEFT")
	warn:SetTextColor(1, 0.5, 0.5)
	warn:SetText("While armed, EVERY login logs you out after a 6s countdown. " ..
		"Cancel that login with the button or /el cancel; untick this or /el arm off to stop. " ..
		"To break it from the desktop, delete the EffortLess folder or its SavedVariables.")

	local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", 16, -200)
	hint:SetWidth(360); hint:SetJustifyH("LEFT")
	hint:SetText("Slash: /el - /el now - /el confirm on|off - /el button - /el arm on|off - /el cancel - /el options")

	local foot = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	foot:SetPoint("BOTTOMLEFT", 16, 16)
	foot:SetText("by Mhortai")

	panel.refresh = function()
		if cbConfirm then cbConfirm:SetChecked(db.confirm) end
		if cbMinimap then cbMinimap:SetChecked(db.minimap) end
		if cbArm then cbArm:SetChecked(db.armed) end
	end
	panel:SetScript("OnShow", function() panel.refresh() end)

	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(panel)
	end
end

OpenOptions = function()
	if not panel then BuildOptionsPanel() end
	if InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(panel)
		InterfaceOptionsFrame_OpenToCategory(panel) -- 3.3.5a: call twice to land on it
	end
end

-- ---------------------------------------------------------------------------
-- Slash commands
-- ---------------------------------------------------------------------------
SLASH_EFFORTLESS1 = "/effortless"
SLASH_EFFORTLESS2 = "/el"
SlashCmdList["EFFORTLESS"] = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	local cmd, arg = msg:match("^(%S*)%s*(.-)$")
	if cmd == "" then
		Trigger(false)
	elseif cmd == "now" then
		Trigger(true)
	elseif cmd == "cancel" then
		CancelArmed(true)
	elseif cmd == "arm" then
		if arg == "on" then db.armed = true; if cbArm then cbArm:SetChecked(true) end
			Msg("ARMED - deposits all & logs out ~6s after every login. /el cancel skips one login, /el arm off stops.")
		elseif arg == "off" then db.armed = false; if cbArm then cbArm:SetChecked(false) end; CancelArmed()
			Msg("disarmed - no auto-run on login.")
		else Msg("armed is " .. (db.armed and "ON" or "OFF") .. " (/el arm on|off).") end
	elseif cmd == "options" or cmd == "config" or cmd == "opt" then
		OpenOptions()
	elseif cmd == "confirm" then
		if arg == "on" then db.confirm = true; Msg("confirmation ON.")
		elseif arg == "off" then db.confirm = false; Msg("confirmation OFF.")
		else Msg("confirmation is " .. (db.confirm and "ON" or "OFF") .. " (/el confirm on|off).") end
	elseif cmd == "button" then
		db.minimap = not db.minimap
		UpdateMinimapButton()
		Msg("minimap button " .. (db.minimap and "shown" or "hidden") .. ".")
	else
		Msg("/el = deposit all & log out | /el now = skip confirm | /el confirm on|off | /el button | /el arm on|off | /el cancel | /el options")
	end
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function(self, event, name)
	if event == "ADDON_LOADED" and name == ADDON then
		if type(EffortLessDB) ~= "table" then EffortLessDB = {} end
		db = EffortLessDB
		for k, v in pairs(defaults) do
			if db[k] == nil then db[k] = v end
		end
		BuildOptionsPanel()
	elseif event == "PLAYER_LOGIN" then
		UpdateMinimapButton()
		if db.armed then StartArmedCountdown() end
	end
end)
