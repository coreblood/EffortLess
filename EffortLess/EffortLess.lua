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

local defaults = { confirm = true, minimap = true, mm = nil }
local db

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
-- Minimap button (free-drag, saves exact point; zero dependency)
-- ---------------------------------------------------------------------------
local mmbtn
local function BuildMinimapButton()
	if mmbtn then return end
	local b = CreateFrame("Button", "EffortLessMinimapButton", Minimap)
	b:SetWidth(31); b:SetHeight(31)
	b:SetFrameStrata("MEDIUM")
	b:SetFrameLevel(8)
	b:RegisterForClicks("LeftButtonUp")
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

	b:SetScript("OnClick", function() Trigger(false) end)

	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine(ADDON)
		GameTooltip:AddLine("Left-click: deposit all to Vault & log out.", 1, 1, 1)
		GameTooltip:AddLine("Drag: move button.", 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)

	mmbtn = b
end

local function UpdateMinimapButton()
	if db.minimap then
		BuildMinimapButton()
		if mmbtn then mmbtn:Show() end
	elseif mmbtn then
		mmbtn:Hide()
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
	elseif cmd == "confirm" then
		if arg == "on" then db.confirm = true; Msg("confirmation ON.")
		elseif arg == "off" then db.confirm = false; Msg("confirmation OFF.")
		else Msg("confirmation is " .. (db.confirm and "ON" or "OFF") .. " (/el confirm on|off).") end
	elseif cmd == "button" then
		db.minimap = not db.minimap
		UpdateMinimapButton()
		Msg("minimap button " .. (db.minimap and "shown" or "hidden") .. ".")
	else
		Msg("/el = deposit all & log out | /el now = skip confirm | /el confirm on|off | /el button = toggle icon")
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
	elseif event == "PLAYER_LOGIN" then
		UpdateMinimapButton()
	end
end)
