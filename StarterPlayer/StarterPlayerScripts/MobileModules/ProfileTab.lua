-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local ProfileTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local CosmeticData = require(ReplicatedStorage:WaitForChild("CosmeticData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))

local NotificationManager = require(script.Parent.Parent:WaitForChild("UIModules"):WaitForChild("NotificationManager"))
local UIAuraManager = require(script.Parent.Parent:WaitForChild("UIModules"):WaitForChild("UIAuraManager"))
local UIHelpers = require(script.Parent.Parent:WaitForChild("UIModules"):WaitForChild("UIHelpers"))

local player = Players.LocalPlayer
local MainFrame, ContentArea
local SubTabs, SubBtns = {}, {}

local InvGrid
local wpnLabel, accLabel, titanLabel, clanLabel, regimentLabel
local titanAwakenBtn, clanAwakenBtn, prestigeBtn
local RadarContainer, regIcon, AvatarBox, AvatarAuraGlow, AvatarTitle
local toggleStatsBtn
local prestigeValLbl, eloValLbl
local InvTitle 
local isShowingTitanStats = false
local MAX_INVENTORY_CAPACITY = 50

local currentInvFilter = "All"
local FilterBtns = {}

local SkillSlotsMid = {}
local selectedLibrarySkill = nil
local skillPreviewTitle, skillPreviewDesc, skillPreviewCost

local RarityColors = { ["Common"] = "#AAAAAA", ["Uncommon"] = "#55FF55", ["Rare"] = "#5588FF", ["Epic"] = "#CC44FF", ["Legendary"] = "#FFD700", ["Mythical"] = "#FF3333", ["Transcendent"] = "#FF55FF" }
local RarityOrder = { Transcendent = 0, Mythical = 1, Legendary = 2, Epic = 3, Rare = 4, Uncommon = 5, Common = 6 }
local SellValues = { Common = 10, Uncommon = 25, Rare = 75, Epic = 200, Legendary = 500, Mythical = 1500, Transcendent = 0 }

local TEXT_COLORS = { PrestigeYellow = "#FFD700", EloBlue = "#55AAFF", DefaultGreen = "#55FF55" }
local REG_COLORS = { ["Garrison"] = "#FF5555", ["Military Police"] = "#55FF55", ["Scout Regiment"] = "#55AAFF" }

local UnlockedCosmeticsCache = { Titles = {}, Auras = {} }
local CosmeticUIUpdaters = {}

task.spawn(function()
	player:WaitForChild("leaderstats", 10)
	for key, data in pairs(CosmeticData.Titles) do UnlockedCosmeticsCache.Titles[key] = CosmeticData.CheckUnlock(player, data.ReqType, data.ReqValue) end
	for key, data in pairs(CosmeticData.Auras) do UnlockedCosmeticsCache.Auras[key] = CosmeticData.CheckUnlock(player, data.ReqType, data.ReqValue) end
end)

local function EvaluateCosmeticUnlocks()
	for key, data in pairs(CosmeticData.Titles) do
		if not UnlockedCosmeticsCache.Titles[key] and CosmeticData.CheckUnlock(player, data.ReqType, data.ReqValue) then
			UnlockedCosmeticsCache.Titles[key] = true
			if NotificationManager then NotificationManager.Show("New Title Unlocked: " .. data.Name, "Success") end
		end
	end
	for key, data in pairs(CosmeticData.Auras) do
		if not UnlockedCosmeticsCache.Auras[key] and CosmeticData.CheckUnlock(player, data.ReqType, data.ReqValue) then
			UnlockedCosmeticsCache.Auras[key] = true
			if NotificationManager then NotificationManager.Show("New Aura Unlocked: " .. data.Name, "Success") end
		end
	end
	for _, updater in ipairs(CosmeticUIUpdaters) do updater() end
end

local function RenderRadarChart()
	if not RadarContainer or RadarContainer.Parent == nil then return end
	local w = RadarContainer.AbsoluteSize.X; local h = RadarContainer.AbsoluteSize.Y
	if w == 0 then return end 
	for _, child in ipairs(RadarContainer:GetChildren()) do if not child:IsA("UIAspectRatioConstraint") then child:Destroy() end end

	local ls = player:FindFirstChild("leaderstats"); local p = ls and ls:FindFirstChild("Prestige")
	local maxVal = GameData.GetStatCap(p and p.Value or 0)
	local stats = isShowingTitanStats and 
		{ {Name = "POW", Val = player:GetAttribute("Titan_Power_Val") or 1}, {Name = "SPD", Val = player:GetAttribute("Titan_Speed_Val") or 1}, {Name = "HRD", Val = player:GetAttribute("Titan_Hardening_Val") or 1}, {Name = "END", Val = player:GetAttribute("Titan_Endurance_Val") or 1}, {Name = "STM", Val = player:GetAttribute("Titan_Precision_Val") or 1}, {Name = "POT", Val = player:GetAttribute("Titan_Potential_Val") or 1} } 
		or 
		{ {Name = "HP", Val = player:GetAttribute("Health") or 1}, {Name = "STR", Val = player:GetAttribute("Strength") or 1}, {Name = "DEF", Val = player:GetAttribute("Defense") or 1}, {Name = "SPD", Val = player:GetAttribute("Speed") or 1}, {Name = "GAS", Val = player:GetAttribute("Gas") or 1}, {Name = "RES", Val = player:GetAttribute("Resolve") or 1} }

	toggleStatsBtn.Text = isShowingTitanStats and "VIEW HUMAN STATS" or "VIEW TITAN STATS"

	local angles = {-90, -30, 30, 90, 150, 210}; local centerX, centerY = w/2, h/2; local maxRadius = math.min(w, h) * 0.35
	for ring = 1, 3 do 
		local r = maxRadius * (ring / 3) 
		for i = 1, 6 do 
			local nextI = i % 6 + 1; 
			UIHelpers.DrawLineScale(RadarContainer, centerX + r*math.cos(math.rad(angles[i])), centerY + r*math.sin(math.rad(angles[i])), centerX + r*math.cos(math.rad(angles[nextI])), centerY + r*math.sin(math.rad(angles[nextI])), Color3.fromRGB(60, 60, 70), 1, 1) 
		end 
	end

	for i = 1, 6 do 
		local rad = math.rad(angles[i]); local px = centerX + maxRadius * math.cos(rad); local py = centerY + maxRadius * math.sin(rad)
		UIHelpers.DrawLineScale(RadarContainer, centerX, centerY, px, py, Color3.fromRGB(60, 60, 70), 1, 1)
		local lbl = Instance.new("TextLabel", RadarContainer); lbl.Size = UDim2.new(0, 30, 0, 15); lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0, centerX + (maxRadius + 15) * math.cos(rad), 0, centerY + (maxRadius + 15) * math.sin(rad)); lbl.AnchorPoint = Vector2.new(0.5, 0.5); lbl.Font = Enum.Font.GothamBold; lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.TextSize = 9; lbl.Text = stats[i].Name .. "\n" .. stats[i].Val
	end

	local statColor = isShowingTitanStats and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
	local pts = {}
	for i = 1, 6 do 
		local r1 = maxRadius * math.clamp(stats[i].Val / maxVal, 0.05, 1); 
		table.insert(pts, Vector2.new(centerX + r1 * math.cos(math.rad(angles[i])), centerY + r1 * math.sin(math.rad(angles[i])))) 
	end

	for i = 1, 6 do 
		local nextI = i % 6 + 1; 
		UIHelpers.DrawLineScale(RadarContainer, pts[i].X, pts[i].Y, pts[nextI].X, pts[nextI].Y, statColor, 2, 5); 
		UIHelpers.DrawUITriangle(RadarContainer, Vector2.new(centerX, centerY), pts[i], pts[nextI], statColor, 0.5, 3) 
	end
end

function ProfileTab.Init(parentFrame, tooltipMgr)
	local cachedTooltipMgr = tooltipMgr
	MainFrame = Instance.new("ScrollingFrame", parentFrame)
	MainFrame.Name = "ProfileFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false
	MainFrame.ScrollBarThickness = 0; MainFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local mLayout = Instance.new("UIListLayout", MainFrame)
	mLayout.SortOrder = Enum.SortOrder.LayoutOrder; mLayout.Padding = UDim.new(0, 15); mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local mPad = Instance.new("UIPadding", MainFrame); mPad.PaddingTop = UDim.new(0, 10); mPad.PaddingBottom = UDim.new(0, 30)

	-- ==========================================
	-- [[ TOP COLUMN (SHOWCASE) ]]
	-- ==========================================
	local ShowcaseCard = Instance.new("Frame", MainFrame)
	ShowcaseCard.Size = UDim2.new(0.95, 0, 0, 0); ShowcaseCard.AutomaticSize = Enum.AutomaticSize.Y; ShowcaseCard.BackgroundColor3 = Color3.fromRGB(20, 20, 25); ShowcaseCard.LayoutOrder = 1
	ShowcaseCard.ClipsDescendants = true 
	Instance.new("UICorner", ShowcaseCard).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", ShowcaseCard).Color = Color3.fromRGB(80, 80, 90)

	local scLayout = Instance.new("UIListLayout", ShowcaseCard)
	scLayout.SortOrder = Enum.SortOrder.LayoutOrder; scLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; scLayout.Padding = UDim.new(0, 10)
	local scPad = Instance.new("UIPadding", ShowcaseCard); scPad.PaddingTop = UDim.new(0, 20); scPad.PaddingBottom = UDim.new(0, 35) 

	AvatarTitle = Instance.new("TextLabel", ShowcaseCard)
	AvatarTitle.Size = UDim2.new(1, 0, 0, 25); AvatarTitle.BackgroundTransparency = 1; AvatarTitle.Font = Enum.Font.GothamBlack; AvatarTitle.TextColor3 = Color3.fromRGB(255, 255, 255); AvatarTitle.TextSize = 16; AvatarTitle.Text = "104TH CADET"; AvatarTitle.LayoutOrder = 1; AvatarTitle.ZIndex = 10

	local AvatarRow = Instance.new("Frame", ShowcaseCard)
	AvatarRow.Size = UDim2.new(1, 0, 0, 120); AvatarRow.BackgroundTransparency = 1; AvatarRow.LayoutOrder = 2
	local arLayout = Instance.new("UIListLayout", AvatarRow); arLayout.FillDirection = Enum.FillDirection.Horizontal; arLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; arLayout.VerticalAlignment = Enum.VerticalAlignment.Center; arLayout.Padding = UDim.new(0, 20)

	local AvatarContainer = Instance.new("Frame", AvatarRow)
	AvatarContainer.Size = UDim2.new(0, 120, 0, 120); AvatarContainer.BackgroundTransparency = 1
	Instance.new("UIAspectRatioConstraint", AvatarContainer).AspectRatio = 1.0

	AvatarAuraGlow = Instance.new("Frame", AvatarContainer)
	AvatarAuraGlow.Size = UDim2.new(1, 0, 1, 0); AvatarAuraGlow.Position = UDim2.new(0.5, 0, 0.5, 0); AvatarAuraGlow.AnchorPoint = Vector2.new(0.5, 0.5); AvatarAuraGlow.BackgroundTransparency = 1; AvatarAuraGlow.ZIndex = 1

	AvatarBox = Instance.new("ImageLabel", AvatarContainer)
	AvatarBox.Size = UDim2.new(1, 0, 1, 0); AvatarBox.Position = UDim2.new(0.5, 0, 0.5, 0); AvatarBox.AnchorPoint = Vector2.new(0.5, 0.5); AvatarBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	AvatarBox.Image = "rbxthumb://type=AvatarBust&id="..player.UserId.."&w=420&h=420"; AvatarBox.ZIndex = 5
	Instance.new("UICorner", AvatarBox).CornerRadius = UDim.new(1, 0); Instance.new("UIStroke", AvatarBox).Color = Color3.fromRGB(100, 100, 110); AvatarBox.UIStroke.Thickness = 2

	regIcon = Instance.new("ImageLabel", AvatarRow)
	regIcon.Size = UDim2.new(0, 85, 0, 85); regIcon.BackgroundTransparency = 1; regIcon.ZIndex = 6; regIcon.ScaleType = Enum.ScaleType.Fit 

	local PlayerNameLbl = Instance.new("TextLabel", ShowcaseCard)
	PlayerNameLbl.Size = UDim2.new(1, 0, 0, 30); PlayerNameLbl.BackgroundTransparency = 1; PlayerNameLbl.Font = Enum.Font.GothamBlack; PlayerNameLbl.TextColor3 = Color3.fromRGB(255, 255, 255); PlayerNameLbl.TextSize = 22; PlayerNameLbl.Text = string.upper(player.Name); PlayerNameLbl.LayoutOrder = 3
	UIHelpers.ApplyGradient(PlayerNameLbl, Color3.fromRGB(255, 215, 100), Color3.fromRGB(255, 150, 50))

	local InfoTextContainer = Instance.new("Frame", ShowcaseCard)
	InfoTextContainer.Size = UDim2.new(1, -20, 0, 0); InfoTextContainer.AutomaticSize = Enum.AutomaticSize.Y; InfoTextContainer.BackgroundTransparency = 1; InfoTextContainer.LayoutOrder = 4
	local itLayout = Instance.new("UIListLayout", InfoTextContainer); itLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; itLayout.Padding = UDim.new(0, 4)

	local function CreateStyledInfoLabel(parent)
		local l = Instance.new("TextLabel", parent); l.Size = UDim2.new(1, 0, 0, 18); l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold; l.TextColor3 = Color3.fromRGB(180, 180, 190); l.TextSize = 14; l.RichText = true
		return l
	end

	prestigeValLbl = CreateStyledInfoLabel(InfoTextContainer)
	eloValLbl = CreateStyledInfoLabel(InfoTextContainer)

	-- ==========================================
	-- [[ MID COLUMN (RADAR & LOADOUT) ]]
	-- ==========================================
	local MidCol = Instance.new("Frame", MainFrame)
	MidCol.Size = UDim2.new(0.95, 0, 0, 420); MidCol.BackgroundColor3 = Color3.fromRGB(20, 20, 25); MidCol.LayoutOrder = 2
	Instance.new("UICorner", MidCol).CornerRadius = UDim.new(0, 12); Instance.new("UIStroke", MidCol).Color = Color3.fromRGB(80, 80, 90)

	local midLayout = Instance.new("UIListLayout", MidCol); midLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; midLayout.SortOrder = Enum.SortOrder.LayoutOrder; midLayout.Padding = UDim.new(0, 10)
	local midPad = Instance.new("UIPadding", MidCol); midPad.PaddingTop = UDim.new(0, 15); midPad.PaddingBottom = UDim.new(0, 15)

	local RadarBG = Instance.new("Frame", MidCol)
	RadarBG.Size = UDim2.new(0.95, 0, 0, 200); RadarBG.BackgroundColor3 = Color3.fromRGB(15, 15, 20); RadarBG.LayoutOrder = 1
	Instance.new("UICorner", RadarBG).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", RadarBG).Color = Color3.fromRGB(60, 60, 70)

	RadarContainer = Instance.new("Frame", RadarBG)
	RadarContainer.Size = UDim2.new(1, 0, 1, 0); RadarContainer.Position = UDim2.new(0.5, 0, 0.5, 0); RadarContainer.AnchorPoint = Vector2.new(0.5, 0.5); RadarContainer.BackgroundTransparency = 1
	Instance.new("UIAspectRatioConstraint", RadarContainer).AspectRatio = 1

	local StatsRect = Instance.new("Frame", MidCol)
	StatsRect.Size = UDim2.new(0.95, 0, 0, 0); StatsRect.AutomaticSize = Enum.AutomaticSize.Y; StatsRect.BackgroundColor3 = Color3.fromRGB(15, 15, 20); StatsRect.LayoutOrder = 2
	Instance.new("UICorner", StatsRect).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", StatsRect).Color = Color3.fromRGB(60, 60, 70)
	local srLayout = Instance.new("UIListLayout", StatsRect); srLayout.Padding = UDim.new(0, 0); srLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	local srPad = Instance.new("UIPadding", StatsRect); srPad.PaddingTop = UDim.new(0, 10); srPad.PaddingBottom = UDim.new(0, 10)

	local function CreateInfoLabel(parent)
		local l = Instance.new("TextLabel", parent); l.Size = UDim2.new(1, 0, 0, 36); l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold; l.TextColor3 = Color3.fromRGB(200, 200, 200); l.TextSize = 12; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true
		local pad = Instance.new("UIPadding", l); pad.PaddingLeft = UDim.new(0, 15)
		return l
	end

	local titanRow = Instance.new("Frame", StatsRect); titanRow.Size = UDim2.new(1, 0, 0, 36); titanRow.BackgroundTransparency = 1
	titanLabel = CreateInfoLabel(titanRow); titanLabel.Size = UDim2.new(1, 0, 1, 0)
	titanAwakenBtn = Instance.new("TextButton", titanRow); titanAwakenBtn.Size = UDim2.new(0.28, 0, 0.8, 0); titanAwakenBtn.Position = UDim2.new(0.68, 0, 0.1, 0)
	titanAwakenBtn.Font = Enum.Font.GothamBold; titanAwakenBtn.TextColor3 = Color3.fromRGB(255, 255, 255); titanAwakenBtn.TextSize = 10; titanAwakenBtn.Text = "AWAKEN"
	UIHelpers.ApplyButtonGradient(titanAwakenBtn, Color3.fromRGB(200, 60, 60), Color3.fromRGB(120, 30, 30), Color3.fromRGB(80, 20, 20)); titanAwakenBtn.Visible = false

	regimentLabel = CreateInfoLabel(StatsRect); regimentLabel.RichText = true

	local clanRow = Instance.new("Frame", StatsRect); clanRow.Size = UDim2.new(1, 0, 0, 36); clanRow.BackgroundTransparency = 1
	clanLabel = CreateInfoLabel(clanRow); clanLabel.Size = UDim2.new(1, 0, 1, 0)
	clanAwakenBtn = Instance.new("TextButton", clanRow); clanAwakenBtn.Size = UDim2.new(0.28, 0, 0.8, 0); clanAwakenBtn.Position = UDim2.new(0.68, 0, 0.1, 0)
	clanAwakenBtn.Font = Enum.Font.GothamBold; clanAwakenBtn.TextColor3 = Color3.fromRGB(255, 255, 255); clanAwakenBtn.TextSize = 10; clanAwakenBtn.Text = "AWAKEN"
	UIHelpers.ApplyButtonGradient(clanAwakenBtn, Color3.fromRGB(200, 60, 60), Color3.fromRGB(120, 30, 30), Color3.fromRGB(80, 20, 20)); clanAwakenBtn.Visible = false

	wpnLabel = CreateInfoLabel(StatsRect); wpnLabel.RichText = true
	accLabel = CreateInfoLabel(StatsRect); accLabel.RichText = true

	local ActionRow = Instance.new("Frame", MidCol)
	ActionRow.Size = UDim2.new(0.95, 0, 0, 40); ActionRow.BackgroundTransparency = 1; ActionRow.LayoutOrder = 3
	local arLayout = Instance.new("UIListLayout", ActionRow); arLayout.FillDirection = Enum.FillDirection.Horizontal; arLayout.Padding = UDim.new(0.02, 0)

	prestigeBtn = Instance.new("TextButton", ActionRow)
	prestigeBtn.Size = UDim2.new(0.49, 0, 1, 0); prestigeBtn.LayoutOrder = 1
	prestigeBtn.Font = Enum.Font.GothamBlack; prestigeBtn.TextColor3 = Color3.fromRGB(255, 255, 255); prestigeBtn.TextSize = 12; prestigeBtn.Text = "PRESTIGE"
	UIHelpers.ApplyButtonGradient(prestigeBtn, Color3.fromRGB(220, 180, 50), Color3.fromRGB(140, 100, 20), Color3.fromRGB(255, 215, 100)); prestigeBtn.Visible = false

	toggleStatsBtn = Instance.new("TextButton", ActionRow)
	toggleStatsBtn.Size = UDim2.new(1, 0, 1, 0); toggleStatsBtn.LayoutOrder = 2
	toggleStatsBtn.Font = Enum.Font.GothamBold; toggleStatsBtn.TextColor3 = Color3.fromRGB(200, 200, 255); toggleStatsBtn.TextSize = 12; toggleStatsBtn.Text = "VIEW TITAN STATS"
	UIHelpers.ApplyButtonGradient(toggleStatsBtn, Color3.fromRGB(60, 60, 80), Color3.fromRGB(30, 30, 40), Color3.fromRGB(100, 100, 150))

	prestigeBtn:GetPropertyChangedSignal("Visible"):Connect(function()
		if prestigeBtn.Visible then toggleStatsBtn.Size = UDim2.new(0.49, 0, 1, 0) else toggleStatsBtn.Size = UDim2.new(1, 0, 1, 0) end
	end)

	local LoadoutTitle = Instance.new("TextLabel", MidCol)
	LoadoutTitle.Size = UDim2.new(0.95, 0, 0, 25); LoadoutTitle.BackgroundTransparency = 1; LoadoutTitle.Font = Enum.Font.GothamBlack; LoadoutTitle.TextColor3 = Color3.fromRGB(255, 215, 100); LoadoutTitle.TextSize = 14; LoadoutTitle.Text = "ACTIVE SKILL LOADOUT"; LoadoutTitle.LayoutOrder = 4

	local LoadoutPanel = Instance.new("Frame", MidCol)
	LoadoutPanel.Size = UDim2.new(0.95, 0, 0, 50); LoadoutPanel.BackgroundTransparency = 1; LoadoutPanel.LayoutOrder = 5
	local loLayout = Instance.new("UIListLayout", LoadoutPanel); loLayout.FillDirection = Enum.FillDirection.Horizontal; loLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; loLayout.Padding = UDim.new(0, 8)

	local RefreshProfile 

	local function HandleSlotClick(slotIndex)
		if selectedLibrarySkill then
			Network:WaitForChild("EquipSkill"):FireServer(slotIndex, selectedLibrarySkill)
			selectedLibrarySkill = nil
			if RefreshProfile then RefreshProfile() end
		else
			if NotificationManager then NotificationManager.Show("Select a skill from the library below first!", "Info") end
		end
	end

	for i = 1, 4 do
		local sBtn = Instance.new("TextButton", LoadoutPanel)
		sBtn.Size = UDim2.new(0, 50, 0, 50); sBtn.Font = Enum.Font.GothamBold; sBtn.TextSize = 10; sBtn.TextWrapped = true; sBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		UIHelpers.ApplyButtonGradient(sBtn, Color3.fromRGB(40, 40, 45), Color3.fromRGB(20, 20, 25), Color3.fromRGB(100, 150, 255))

		local numLbl = Instance.new("TextLabel", sBtn); numLbl.Size = UDim2.new(0, 14, 0, 14); numLbl.Position = UDim2.new(0, 2, 0, 2); numLbl.BackgroundTransparency = 1; numLbl.Font = Enum.Font.GothamBlack; numLbl.TextColor3 = Color3.fromRGB(150, 200, 255); numLbl.Text = tostring(i)

		sBtn.MouseButton1Click:Connect(function() HandleSlotClick(i) end)
		SkillSlotsMid[i] = sBtn
	end

	local manageSkillsBtn = Instance.new("TextButton", MidCol)
	manageSkillsBtn.Size = UDim2.new(0.95, 0, 0, 40)
	manageSkillsBtn.LayoutOrder = 6
	manageSkillsBtn.Font = Enum.Font.GothamBlack
	manageSkillsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	manageSkillsBtn.TextSize = 14
	manageSkillsBtn.Text = "MANAGE SKILL LIBRARY"
	UIHelpers.ApplyButtonGradient(manageSkillsBtn, Color3.fromRGB(60, 100, 160), Color3.fromRGB(30, 50, 80), Color3.fromRGB(80, 120, 200))

	manageSkillsBtn.MouseButton1Click:Connect(function()
		for k, v in pairs(SubBtns) do 
			local cGrad = v:FindFirstChildOfClass("UIGradient")
			if cGrad then UIHelpers.TweenGradient(cGrad, Color3.fromRGB(50, 50, 55), Color3.fromRGB(25, 25, 30), 0.2) end
			TweenService:Create(v, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(180, 180, 180)}):Play() 
		end
		for k, frame in pairs(SubTabs) do frame.Visible = (k == "Skills") end
	end)

	midLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		MidCol.Size = UDim2.new(0.95, 0, 0, midLayout.AbsoluteContentSize.Y + 30) 
	end)

	-- ==========================================
	-- [[ BOTTOM TABS WRAPPER (MOBILE) ]]
	-- ==========================================
	local TopNav = Instance.new("ScrollingFrame", MainFrame)
	TopNav.Size = UDim2.new(0.95, 0, 0, 40); TopNav.BackgroundColor3 = Color3.fromRGB(15, 15, 18); TopNav.ScrollBarThickness = 0; TopNav.ScrollingDirection = Enum.ScrollingDirection.X; TopNav.LayoutOrder = 3
	Instance.new("UICorner", TopNav).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", TopNav).Color = Color3.fromRGB(80, 80, 90)

	local navLayout = Instance.new("UIListLayout", TopNav); navLayout.FillDirection = Enum.FillDirection.Horizontal; navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; navLayout.VerticalAlignment = Enum.VerticalAlignment.Center; navLayout.Padding = UDim.new(0, 10)
	local navPad = Instance.new("UIPadding", TopNav); navPad.PaddingLeft = UDim.new(0, 10); navPad.PaddingRight = UDim.new(0, 10)

	navLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TopNav.CanvasSize = UDim2.new(0, navLayout.AbsoluteContentSize.X + 20, 0, 0) end)

	ContentArea = Instance.new("Frame", MainFrame)
	ContentArea.Size = UDim2.new(0.95, 0, 0, 0); ContentArea.AutomaticSize = Enum.AutomaticSize.Y; ContentArea.BackgroundTransparency = 1; ContentArea.LayoutOrder = 4

	local function CreateSubNavBtn(name, text)
		local btn = Instance.new("TextButton", TopNav)
		btn.Size = UDim2.new(0, 110, 0, 28); btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(180, 180, 180); btn.TextSize = 11; btn.Text = text
		UIHelpers.ApplyButtonGradient(btn, Color3.fromRGB(50, 50, 55), Color3.fromRGB(25, 25, 30), Color3.fromRGB(60, 60, 65))

		btn.MouseButton1Click:Connect(function()
			for k, v in pairs(SubBtns) do 
				local cGrad = v:FindFirstChildOfClass("UIGradient")
				if cGrad then UIHelpers.TweenGradient(cGrad, Color3.fromRGB(50, 50, 55), Color3.fromRGB(25, 25, 30), 0.2) end
				TweenService:Create(v, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(180, 180, 180)}):Play() 
			end
			local grad = btn:FindFirstChildOfClass("UIGradient")
			if grad then UIHelpers.TweenGradient(grad, Color3.fromRGB(200, 150, 40), Color3.fromRGB(120, 80, 15), 0.2) end
			TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()

			for k, frame in pairs(SubTabs) do frame.Visible = (k == name) end
		end)
		SubBtns[name] = btn
		return btn
	end

	CreateSubNavBtn("Inventory", "INVENTORY")
	CreateSubNavBtn("Skills", "SKILL LIBRARY") 
	CreateSubNavBtn("Titles", "TITLES")
	CreateSubNavBtn("Auras", "AURAS")

	SubTabs["Inventory"] = Instance.new("Frame", ContentArea)
	SubTabs["Inventory"].Size = UDim2.new(1, 0, 0, 0); SubTabs["Inventory"].AutomaticSize = Enum.AutomaticSize.Y
	SubTabs["Inventory"].BackgroundColor3 = Color3.fromRGB(20, 20, 25); SubTabs["Inventory"].Visible = true
	Instance.new("UICorner", SubTabs["Inventory"]).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", SubTabs["Inventory"]).Color = Color3.fromRGB(80, 80, 90)

	local invMasterLayout = Instance.new("UIListLayout", SubTabs["Inventory"])
	invMasterLayout.SortOrder = Enum.SortOrder.LayoutOrder; invMasterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local invPad = Instance.new("UIPadding", SubTabs["Inventory"])
	invPad.PaddingTop = UDim.new(0, 10); invPad.PaddingBottom = UDim.new(0, 20)

	InvTitle = Instance.new("TextLabel", SubTabs["Inventory"])
	InvTitle.Size = UDim2.new(1, 0, 0, 40); InvTitle.BackgroundTransparency = 1; InvTitle.Font = Enum.Font.GothamBlack; InvTitle.TextColor3 = Color3.fromRGB(255, 215, 100); InvTitle.TextSize = 18; InvTitle.Text = "INVENTORY (0/50)"; InvTitle.LayoutOrder = 1
	UIHelpers.ApplyGradient(InvTitle, Color3.fromRGB(255, 215, 100), Color3.fromRGB(255, 150, 50))

	local AutoSellFrame = Instance.new("ScrollingFrame", SubTabs["Inventory"])
	AutoSellFrame.Size = UDim2.new(1, 0, 0, 30); AutoSellFrame.BackgroundTransparency = 1; AutoSellFrame.LayoutOrder = 2
	AutoSellFrame.ScrollBarThickness = 0; AutoSellFrame.ScrollingDirection = Enum.ScrollingDirection.X
	local asLayout = Instance.new("UIListLayout", AutoSellFrame); asLayout.FillDirection = Enum.FillDirection.Horizontal; asLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; asLayout.Padding = UDim.new(0, 5)

	local asLabel = Instance.new("TextLabel", AutoSellFrame)
	asLabel.Size = UDim2.new(0, 60, 1, 0); asLabel.BackgroundTransparency = 1; asLabel.Font = Enum.Font.GothamBold; asLabel.TextColor3 = Color3.fromRGB(180, 180, 180); asLabel.TextSize = 11; asLabel.TextXAlignment = Enum.TextXAlignment.Right; asLabel.Text = "Auto-Sell:"

	asLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
		AutoSellFrame.CanvasSize = UDim2.new(0, asLayout.AbsoluteContentSize.X, 0, 0) 
	end)

	local autoSellStates = {}
	local function CreateAutoSell(rarity, color)
		autoSellStates[rarity] = false
		local asBtn = Instance.new("TextButton", AutoSellFrame)
		asBtn.Size = UDim2.new(0, 65, 1, 0); asBtn.Font = Enum.Font.GothamBold; asBtn.TextColor3 = color; asBtn.TextSize = 10; asBtn.Text = rarity
		UIHelpers.ApplyButtonGradient(asBtn, Color3.fromRGB(50, 50, 55), Color3.fromRGB(25, 25, 30), Color3.fromRGB(60, 60, 70))

		asBtn.MouseButton1Click:Connect(function()
			autoSellStates[rarity] = not autoSellStates[rarity]
			if autoSellStates[rarity] then
				UIHelpers.ApplyButtonGradient(asBtn, Color3.fromRGB(80, 180, 80), Color3.fromRGB(40, 100, 40), Color3.fromRGB(60, 120, 60))
				Network.AutoSell:FireServer(rarity)
				if NotificationManager then NotificationManager.Show("Auto-Sell " .. rarity .. " ENABLED", "Info") end
			else
				UIHelpers.ApplyButtonGradient(asBtn, Color3.fromRGB(50, 50, 55), Color3.fromRGB(25, 25, 30), Color3.fromRGB(60, 60, 70))
				if NotificationManager then NotificationManager.Show("Auto-Sell " .. rarity .. " DISABLED", "Info") end
			end
		end)
	end
	CreateAutoSell("Common", Color3.fromRGB(180, 180, 180))
	CreateAutoSell("Uncommon", Color3.fromRGB(100, 255, 100))
	CreateAutoSell("Rare", Color3.fromRGB(100, 100, 255))
	CreateAutoSell("Epic", Color3.fromRGB(204, 68, 255))
	CreateAutoSell("Legendary", Color3.fromRGB(255, 215, 0))
	CreateAutoSell("Mythical", Color3.fromRGB(255, 51, 51))

	local FilterFrame = Instance.new("Frame", SubTabs["Inventory"])
	FilterFrame.Size = UDim2.new(1, 0, 0, 35); FilterFrame.BackgroundTransparency = 1; FilterFrame.LayoutOrder = 3
	local ffLayout = Instance.new("UIListLayout", FilterFrame); ffLayout.FillDirection = Enum.FillDirection.Horizontal; ffLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; ffLayout.Padding = UDim.new(0, 8)
	local ffPad = Instance.new("UIPadding", FilterFrame); ffPad.PaddingTop = UDim.new(0, 10); ffPad.PaddingBottom = UDim.new(0, 10)

	local RefreshProfile 
	local function MakeFilterBtn(id, text)
		local btn = Instance.new("TextButton", FilterFrame)
		btn.Size = UDim2.new(0.31, 0, 1, 0); btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(150, 150, 150); btn.TextSize = 11; btn.Text = text
		UIHelpers.ApplyButtonGradient(btn, Color3.fromRGB(30, 30, 35), Color3.fromRGB(15, 15, 20), Color3.fromRGB(60, 60, 70))

		btn.MouseButton1Click:Connect(function()
			currentInvFilter = id
			for k, v in pairs(FilterBtns) do
				UIHelpers.ApplyButtonGradient(v, Color3.fromRGB(30, 30, 35), Color3.fromRGB(15, 15, 20), Color3.fromRGB(60, 60, 70))
				v.TextColor3 = Color3.fromRGB(150, 150, 150)
			end
			UIHelpers.ApplyButtonGradient(btn, Color3.fromRGB(60, 140, 60), Color3.fromRGB(30, 80, 30), Color3.fromRGB(80, 180, 80))
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			if RefreshProfile then RefreshProfile() end
		end)
		FilterBtns[id] = btn
		return btn
	end

	MakeFilterBtn("All", "ALL")
	MakeFilterBtn("Gear", "GEAR")
	MakeFilterBtn("Items", "ITEMS")
	UIHelpers.ApplyButtonGradient(FilterBtns["All"], Color3.fromRGB(60, 140, 60), Color3.fromRGB(30, 80, 30), Color3.fromRGB(80, 180, 80))
	FilterBtns["All"].TextColor3 = Color3.fromRGB(255, 255, 255)

	InvGrid = Instance.new("Frame", SubTabs["Inventory"])
	InvGrid.Size = UDim2.new(1, -10, 0, 0); InvGrid.AutomaticSize = Enum.AutomaticSize.Y; InvGrid.BackgroundTransparency = 1; InvGrid.BorderSizePixel = 0; InvGrid.LayoutOrder = 4
	local gl = Instance.new("UIGridLayout", InvGrid)
	gl.CellSize = UDim2.new(0, 75, 0, 75); gl.CellPadding = UDim2.new(0, 10, 0, 15); gl.HorizontalAlignment = Enum.HorizontalAlignment.Center; gl.SortOrder = Enum.SortOrder.LayoutOrder
	local glPad = Instance.new("UIPadding", InvGrid); glPad.PaddingTop = UDim.new(0, 10)


	-- [[ SKILL LIBRARY TAB ]]
	SubTabs["Skills"] = Instance.new("Frame", ContentArea)
	SubTabs["Skills"].Size = UDim2.new(1, 0, 0, 0); SubTabs["Skills"].AutomaticSize = Enum.AutomaticSize.Y; SubTabs["Skills"].BackgroundColor3 = Color3.fromRGB(20, 20, 25); SubTabs["Skills"].Visible = false
	Instance.new("UICorner", SubTabs["Skills"]).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", SubTabs["Skills"]).Color = Color3.fromRGB(80, 80, 90)

	local SkillPreviewPanel = Instance.new("Frame", SubTabs["Skills"])
	SkillPreviewPanel.Size = UDim2.new(1, -20, 0, 75); SkillPreviewPanel.Position = UDim2.new(0, 10, 0, 10); SkillPreviewPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	Instance.new("UICorner", SkillPreviewPanel).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", SkillPreviewPanel).Color = Color3.fromRGB(80, 80, 90)

	skillPreviewTitle = Instance.new("TextLabel", SkillPreviewPanel)
	skillPreviewTitle.Size = UDim2.new(1, -10, 0, 20); skillPreviewTitle.Position = UDim2.new(0, 5, 0, 5); skillPreviewTitle.BackgroundTransparency = 1; skillPreviewTitle.Font = Enum.Font.GothamBlack; skillPreviewTitle.TextColor3 = Color3.fromRGB(255, 215, 100); skillPreviewTitle.TextSize = 14; skillPreviewTitle.TextXAlignment = Enum.TextXAlignment.Left; skillPreviewTitle.Text = "SELECT A SKILL"

	skillPreviewDesc = Instance.new("TextLabel", SkillPreviewPanel)
	skillPreviewDesc.Size = UDim2.new(1, -10, 0, 45); skillPreviewDesc.Position = UDim2.new(0, 5, 0, 25); skillPreviewDesc.BackgroundTransparency = 1; skillPreviewDesc.Font = Enum.Font.GothamMedium; skillPreviewDesc.TextColor3 = Color3.fromRGB(180, 180, 180); skillPreviewDesc.TextSize = 11; skillPreviewDesc.TextXAlignment = Enum.TextXAlignment.Left; skillPreviewDesc.TextYAlignment = Enum.TextYAlignment.Top; skillPreviewDesc.TextWrapped = true; skillPreviewDesc.RichText = true; skillPreviewDesc.Text = "Click a skill from the library below, then click an Active Loadout slot above to equip it."

	skillPreviewCost = Instance.new("TextLabel", SkillPreviewPanel)
	skillPreviewCost.Size = UDim2.new(0, 100, 0, 20); skillPreviewCost.AnchorPoint = Vector2.new(1, 0); skillPreviewCost.Position = UDim2.new(1, -5, 0, 5); skillPreviewCost.BackgroundTransparency = 1; skillPreviewCost.Font = Enum.Font.GothamBold; skillPreviewCost.TextColor3 = Color3.fromRGB(150, 255, 150); skillPreviewCost.TextSize = 12; skillPreviewCost.TextXAlignment = Enum.TextXAlignment.Right; skillPreviewCost.Text = ""

	local LibContainer = Instance.new("ScrollingFrame", SubTabs["Skills"])
	LibContainer.Size = UDim2.new(1, -20, 0, 250); LibContainer.Position = UDim2.new(0, 10, 0, 90); LibContainer.BackgroundTransparency = 1; LibContainer.BorderSizePixel = 0; LibContainer.ScrollBarThickness = 4
	local lsLayout = Instance.new("UIListLayout", LibContainer); lsLayout.Padding = UDim.new(0, 10); lsLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local function RenderSkills()
		for _, child in ipairs(LibContainer:GetChildren()) do 
			if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child:Destroy() end 
		end

		local ls = player:FindFirstChild("leaderstats")
		local pPrestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0

		local un_equippables = { ["Basic Slash"]=true, ["Maneuver"]=true, ["Fall Back"]=true, ["Close In"]=true, ["Recover"]=true, ["Retreat"]=true, ["Transform"]=true, ["Eject"]=true, ["Titan Recover"]=true, ["Titan Punch"]=true, ["Titan Kick"]=true, ["Cannibalize"]=true }
		local categories = {}

		for name, data in pairs(SkillData.Skills) do 
			if not data.IsEnemyOnly and data.Requirement ~= "Enemy" and not un_equippables[name] and data.Type ~= "Titan" and data.Type ~= "Transform" then
				if data.Requirement ~= "Ackerman" and data.Requirement ~= "Awakened Ackerman" then
					local cat = tostring(data.Requirement or "Support / Firearms")
					if cat == "ODM" then cat = "Base ODM" elseif cat == "None" then cat = "Support / Firearms" end
					if not categories[cat] then categories[cat] = {} end
					table.insert(categories[cat], {Name = name, Data = data})
				end
			end
		end

		local categoryOrder = { ["Base ODM"] = 1, ["Support / Firearms"] = 2, ["Ultrahard Steel Blades"] = 3, ["Thunder Spears"] = 4, ["Anti-Personnel"] = 5 }
		local sortedCats = {}
		for cat, list in pairs(categories) do
			table.insert(sortedCats, {Category = cat, List = list, Order = categoryOrder[cat] or 99})
			table.sort(list, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)
		end
		table.sort(sortedCats, function(a, b) if a.Order == b.Order then return a.Category < b.Category end return a.Order < b.Order end)

		local layoutOrder = 1

		for _, catData in ipairs(sortedCats) do
			local catName = tostring(catData.Category)
			local skillsList = catData.List

			if #skillsList > 0 then
				local isWeaponCat = (catName ~= "Base ODM" and catName ~= "Support / Firearms")
				local ownsWeapon = true
				if isWeaponCat then
					local safeWpn = string.gsub(catName, "[^%w]", "") .. "Count"
					ownsWeapon = (player:GetAttribute(safeWpn) or 0) > 0
				end

				local hdrText = string.upper(catName)
				if isWeaponCat and not ownsWeapon then hdrText = hdrText .. " <font color='#FF5555'>(LOCKED: REQUIRES WEAPON)</font>" end

				local hdr = Instance.new("TextLabel", LibContainer)
				hdr.Size = UDim2.new(1, 0, 0, 25); hdr.BackgroundTransparency = 1; hdr.Font = Enum.Font.GothamBlack; hdr.TextColor3 = Color3.fromRGB(200, 200, 200); hdr.TextSize = 14; hdr.TextXAlignment = Enum.TextXAlignment.Left; hdr.RichText = true; hdr.Text = hdrText; hdr.LayoutOrder = layoutOrder
				layoutOrder = layoutOrder + 1

				local grid = Instance.new("Frame", LibContainer)
				grid.Size = UDim2.new(1, 0, 0, 0); grid.BackgroundTransparency = 1; grid.LayoutOrder = layoutOrder
				layoutOrder = layoutOrder + 1

				local lg = Instance.new("UIGridLayout", grid)
				lg.CellSize = UDim2.new(0, 75, 0, 75); lg.CellPadding = UDim2.new(0, 10, 0, 10); lg.HorizontalAlignment = Enum.HorizontalAlignment.Center; lg.SortOrder = Enum.SortOrder.LayoutOrder

				for _, sk in ipairs(skillsList) do
					local isUnlocked = true
					local lockReason = ""

					if isWeaponCat and not ownsWeapon then isUnlocked = false; lockReason = "MISSING WPN"
					elseif sk.Data.UnlockPrestige and pPrestige < sk.Data.UnlockPrestige then isUnlocked = false; lockReason = "P" .. sk.Data.UnlockPrestige .. " REQ" end

					local sBtn = Instance.new("TextButton", grid)
					sBtn.Size = UDim2.new(1, 0, 1, 0); sBtn.Text = ""
					Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 6); sBtn.ClipsDescendants = true

					local sStroke = Instance.new("UIStroke", sBtn)
					if selectedLibrarySkill == sk.Name then sStroke.Color = Color3.fromRGB(255, 215, 100); sStroke.Thickness = 2
					elseif isUnlocked then sStroke.Color = Color3.fromRGB(60, 60, 70); sStroke.Thickness = 1
					else sStroke.Color = Color3.fromRGB(255, 50, 50); sStroke.Thickness = 1 end

					sBtn.BackgroundColor3 = isUnlocked and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(20, 15, 15)

					local lbl = Instance.new("TextLabel", sBtn)
					lbl.Size = UDim2.new(1, -4, 1, -4); lbl.Position = UDim2.new(0, 2, 0, 2); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextColor3 = isUnlocked and Color3.fromRGB(230, 230, 230) or Color3.fromRGB(100, 100, 100); lbl.TextSize = 10; lbl.TextWrapped = true; lbl.Text = sk.Name

					if not isUnlocked then
						local lockLbl = Instance.new("TextLabel", sBtn); lockLbl.Size = UDim2.new(1, 0, 0, 14); lockLbl.Position = UDim2.new(0, 0, 1, -14); lockLbl.BackgroundTransparency = 1; lockLbl.Font = Enum.Font.GothamBlack; lockLbl.TextColor3 = Color3.fromRGB(255, 80, 80); lockLbl.TextSize = 9; lockLbl.Text = lockReason
					end

					local synText = ""
					if sk.Data.ComboReq then synText = "\n<font color='#FFD700'>[Synergy: Combos from " .. sk.Data.ComboReq .. "]</font>" end

					sBtn.MouseButton1Click:Connect(function()
						if isUnlocked then
							selectedLibrarySkill = sk.Name
							skillPreviewTitle.Text = string.upper(sk.Name)
							skillPreviewDesc.Text = (sk.Data.Description or "A combat skill.") .. synText
							local costs = {}
							if sk.Data.GasCost then table.insert(costs, sk.Data.GasCost .. " Gas") end
							if sk.Data.EnergyCost then table.insert(costs, sk.Data.EnergyCost .. " Heat") end
							if sk.Data.Cooldown then table.insert(costs, sk.Data.Cooldown .. "T CD") end
							skillPreviewCost.Text = table.concat(costs, " | ")
							RenderSkills()
						else
							if NotificationManager then NotificationManager.Show("Requires: " .. lockReason, "Error") end
						end
					end)

					local tTip = "<b>" .. sk.Name .. "</b>\n<font color='#AAAAAA'>" .. (sk.Data.Description or "") .. "</font>" .. synText
					sBtn.MouseEnter:Connect(function() if cachedTooltipMgr then cachedTooltipMgr.Show(tTip) end end)
					sBtn.MouseLeave:Connect(function() if cachedTooltipMgr then cachedTooltipMgr.Hide() end end)
				end
				lg:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() grid.Size = UDim2.new(1, 0, 0, lg.AbsoluteContentSize.Y) end)
				grid.Size = UDim2.new(1, 0, 0, lg.AbsoluteContentSize.Y) 
			end
		end
		task.delay(0.05, function() LibContainer.CanvasSize = UDim2.new(0, 0, 0, lsLayout.AbsoluteContentSize.Y + 20) end)
	end

	SubTabs["Titles"] = Instance.new("Frame", ContentArea)
	SubTabs["Titles"].Size = UDim2.new(1, 0, 0, 0); SubTabs["Titles"].AutomaticSize = Enum.AutomaticSize.Y; SubTabs["Titles"].BackgroundTransparency = 1; SubTabs["Titles"].Visible = false
	local tLayout = Instance.new("UIListLayout", SubTabs["Titles"]); tLayout.Padding = UDim.new(0, 10); tLayout.SortOrder = Enum.SortOrder.LayoutOrder; tLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local tPad = Instance.new("UIPadding", SubTabs["Titles"]); tPad.PaddingTop = UDim.new(0, 10); tPad.PaddingBottom = UDim.new(0, 20)

	SubTabs["Auras"] = Instance.new("Frame", ContentArea)
	SubTabs["Auras"].Size = UDim2.new(1, 0, 0, 0); SubTabs["Auras"].AutomaticSize = Enum.AutomaticSize.Y; SubTabs["Auras"].BackgroundTransparency = 1; SubTabs["Auras"].Visible = false
	local aLayout = Instance.new("UIListLayout", SubTabs["Auras"]); aLayout.Padding = UDim.new(0, 10); aLayout.SortOrder = Enum.SortOrder.LayoutOrder; aLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local aPad = Instance.new("UIPadding", SubTabs["Auras"]); aPad.PaddingTop = UDim.new(0, 10); aPad.PaddingBottom = UDim.new(0, 20)

	local function BuildCosmeticList(tab, typeKey, dataPool)
		local sorted = {}
		for key, data in pairs(dataPool) do table.insert(sorted, {Key = key, Data = data}) end
		table.sort(sorted, function(a, b) return a.Data.Order < b.Data.Order end)

		for _, item in ipairs(sorted) do
			local card = Instance.new("Frame", tab)
			card.Size = UDim2.new(0.95, 0, 0, 80); card.BackgroundColor3 = Color3.fromRGB(22, 22, 28); card.LayoutOrder = item.Data.Order
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
			local stroke = Instance.new("UIStroke", card); stroke.Color = Color3.fromRGB(60, 60, 70); stroke.Thickness = 1

			local cColor = Color3.fromRGB(255,255,255)
			if typeKey == "Title" then cColor = Color3.fromHex((item.Data.Color or "#FFFFFF"):gsub("#", "")) else cColor = Color3.fromHex((item.Data.Color1 or "#FFFFFF"):gsub("#", "")) end

			local title = Instance.new("TextLabel", card); title.Size = UDim2.new(0.65, 0, 0, 25); title.Position = UDim2.new(0, 15, 0, 10); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack; title.TextColor3 = cColor; title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = item.Data.Name
			local desc = Instance.new("TextLabel", card); desc.Size = UDim2.new(0.65, 0, 0, 30); desc.Position = UDim2.new(0, 15, 0, 35); desc.BackgroundTransparency = 1; desc.Font = Enum.Font.GothamMedium; desc.TextColor3 = Color3.fromRGB(150, 150, 160); desc.TextSize = 13; desc.TextWrapped = true; desc.TextXAlignment = Enum.TextXAlignment.Left; desc.TextYAlignment = Enum.TextYAlignment.Top; desc.Text = item.Data.Desc

			local btn = Instance.new("TextButton", card)
			btn.Size = UDim2.new(0.25, 0, 0, 40); btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, -15, 0.5, 0); btn.Font = Enum.Font.GothamBlack; btn.TextSize = 13; btn.Text = ""

			local function UpdateState()
				local isUnlocked = CosmeticData.CheckUnlock(player, item.Data.ReqType, item.Data.ReqValue)
				local isEquipped = (player:GetAttribute("Equipped" .. typeKey) or (typeKey == "Title" and "Cadet" or "None")) == item.Key

				if isEquipped then
					btn.Text = "EQUIPPED"; UIHelpers.ApplyButtonGradient(btn, Color3.fromRGB(40, 40, 45), Color3.fromRGB(20, 20, 25), Color3.fromRGB(60, 60, 70)); btn.TextColor3 = Color3.fromRGB(150, 150, 150)
					stroke.Color = cColor; stroke.Thickness = 2; stroke.Transparency = 0.2
				elseif isUnlocked then
					btn.Text = "EQUIP"; UIHelpers.ApplyButtonGradient(btn, Color3.fromRGB(40, 100, 40), Color3.fromRGB(20, 50, 20), Color3.fromRGB(60, 150, 60)); btn.TextColor3 = Color3.fromRGB(255, 255, 255)
					stroke.Color = Color3.fromRGB(80, 80, 90); stroke.Thickness = 1; stroke.Transparency = 0
				else
					btn.Text = "LOCKED"; UIHelpers.ApplyButtonGradient(btn, Color3.fromRGB(60, 20, 20), Color3.fromRGB(30, 10, 10), Color3.fromRGB(100, 30, 30)); btn.TextColor3 = Color3.fromRGB(150, 150, 150)
					stroke.Color = Color3.fromRGB(60, 60, 70); stroke.Thickness = 1; stroke.Transparency = 0
				end
			end

			table.insert(CosmeticUIUpdaters, UpdateState)

			btn.MouseButton1Click:Connect(function()
				if CosmeticData.CheckUnlock(player, item.Data.ReqType, item.Data.ReqValue) then Network.EquipCosmetic:FireServer(typeKey, item.Key) end
			end)
			UpdateState()
		end
	end

	BuildCosmeticList(SubTabs["Titles"], "Title", CosmeticData.Titles)
	BuildCosmeticList(SubTabs["Auras"], "Aura", CosmeticData.Auras)

	-- [[ GLOBAL UPDATE LOGIC ]]
	titanAwakenBtn.MouseButton1Click:Connect(function() Network.AwakenAction:FireServer("Titan") end)
	clanAwakenBtn.MouseButton1Click:Connect(function() Network.AwakenAction:FireServer("Clan") end)
	prestigeBtn.MouseButton1Click:Connect(function() Network.PrestigeEvent:FireServer() end)

	RadarContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(RenderRadarChart)
	toggleStatsBtn.MouseButton1Click:Connect(function() isShowingTitanStats = not isShowingTitanStats; RenderRadarChart() end)

	RefreshProfile = function()
		local tName = player:GetAttribute("Titan") or "None"; local cName = player:GetAttribute("Clan") or "None"; local cPart = player:GetAttribute("CurrentPart") or 1
		local regName = player:GetAttribute("Regiment") or "Cadet Corps"

		local hasRegData, regDataModule = pcall(function() return require(game.ReplicatedStorage:WaitForChild("RegimentData")) end)
		local regTextColorHex = REG_COLORS[regName] or TEXT_COLORS.DefaultGreen
		if hasRegData and regDataModule and regDataModule.Regiments[regName] then 
			regIcon.Image = regDataModule.Regiments[regName].Icon 
		else
			regIcon.Image = "" 
		end

		if cName == "Ackerman" or cName == "Awakened Ackerman" then titanLabel.Text = "Titan: <font color='#FF5555'>(Titan Disabled)</font>" else titanLabel.Text = "Titan: <font color='#FF5555'>" .. tName .. "</font>" end
		titanLabel.RichText = true; clanLabel.Text = "Clan: <font color='#55FF55'>" .. cName .. "</font>"; clanLabel.RichText = true

		regimentLabel.Text = "Regiment: <font color='"..regTextColorHex.."'>" .. regName .. "</font>"

		local wpnName = player:GetAttribute("EquippedWeapon") or "None"
		local accName = player:GetAttribute("EquippedAccessory") or "None"

		local wpnRarity = (wpnName ~= "None" and ItemData.Equipment and ItemData.Equipment[wpnName]) and ItemData.Equipment[wpnName].Rarity or "Common"
		local accRarity = (accName ~= "None" and ItemData.Equipment and ItemData.Equipment[accName]) and ItemData.Equipment[accName].Rarity or "Common"

		wpnLabel.Text = "Weapon: <font color='"..(RarityColors[wpnRarity] or "#FFFFFF").."'>" .. wpnName .. "</font>"
		accLabel.Text = "Accessory: <font color='"..(RarityColors[accRarity] or "#FFFFFF").."'>" .. accName .. "</font>"

		if tName == "Attack Titan" and (player:GetAttribute("YmirsClayFragmentCount") or 0) > 0 then titanAwakenBtn.Visible = true else titanAwakenBtn.Visible = false end

		local validClans = {["Ackerman"] = true, ["Yeager"] = true, ["Tybur"] = true, ["Braun"] = true, ["Galliard"] = true}
		if validClans[cName] and (player:GetAttribute("AncestralAwakeningSerumCount") or 0) > 0 then clanAwakenBtn.Visible = true else clanAwakenBtn.Visible = false end

		if cPart > 8 then prestigeBtn.Visible = true else prestigeBtn.Visible = false end

		RenderRadarChart()
		RenderSkills()

		local pTitle = player:GetAttribute("EquippedTitle") or "Cadet"
		local pAura = player:GetAttribute("EquippedAura") or "None"

		local tData = CosmeticData.Titles[pTitle]
		if tData then AvatarTitle.Text = string.upper(tData.Name); AvatarTitle.TextColor3 = Color3.fromHex((tData.Color or "#FFFFFF"):gsub("#", "")) end

		local aData = CosmeticData.Auras[pAura]
		if UIAuraManager then
			UIAuraManager.ApplyAura(AvatarAuraGlow, aData, AvatarBox)
		end

		local ls = player:FindFirstChild("leaderstats")
		local pres = (ls and ls:FindFirstChild("Prestige")) and ls.Prestige.Value or 0
		local elo = (ls and ls:FindFirstChild("Elo")) and ls.Elo.Value or 1000

		prestigeValLbl.Text = "Prestige: <font color='"..TEXT_COLORS.PrestigeYellow.."'>"..pres.."</font>"
		eloValLbl.Text = "Elo: <font color='"..TEXT_COLORS.EloBlue.."'>"..elo.."</font>"

		for i = 1, 4 do
			local eSkill = player:GetAttribute("EquippedSkill_" .. i) or "Empty"
			if SkillSlotsMid[i] then SkillSlotsMid[i].Text = eSkill end
		end

		for _, child in ipairs(InvGrid:GetChildren()) do 
			if child.Name == "ItemCard" then child:Destroy() end 
		end

		local inventoryItems = {}
		local currentSlotsUsed = 0

		for iName, iData in pairs(ItemData.Equipment) do 
			local safeNameBase = string.gsub(iName, "[^%w]", "")
			local count = player:GetAttribute(safeNameBase .. "Count") or 0
			if count > 0 then currentSlotsUsed = currentSlotsUsed + 1 end
			if currentInvFilter == "All" or currentInvFilter == "Gear" then table.insert(inventoryItems, {Name = iName, Data = iData}) end
		end
		for iName, iData in pairs(ItemData.Consumables) do 
			local safeNameBase = string.gsub(iName, "[^%w]", "")
			local count = player:GetAttribute(safeNameBase .. "Count") or 0
			if count > 0 then currentSlotsUsed = currentSlotsUsed + 1 end
			if currentInvFilter == "All" or currentInvFilter == "Items" then table.insert(inventoryItems, {Name = iName, Data = iData}) end
		end

		table.sort(inventoryItems, function(a, b) local rA = RarityOrder[a.Data.Rarity or "Common"] or 7; local rB = RarityOrder[b.Data.Rarity or "Common"] or 7; if rA == rB then return a.Name < b.Name else return rA < rB end end)

		local layoutOrderCounter = 1

		for _, item in ipairs(inventoryItems) do
			local itemName = item.Name; local itemInfo = item.Data; 
			local safeNameBase = string.gsub(itemName, "[^%w]", "")
			local count = player:GetAttribute(safeNameBase .. "Count") or 0

			if count > 0 then
				local card = Instance.new("TextButton", InvGrid)
				card.Name = "ItemCard"
				card.Size = UDim2.new(0, 75, 0, 75)
				card.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
				card.Text = ""
				card.LayoutOrder = layoutOrderCounter
				layoutOrderCounter = layoutOrderCounter + 1
				Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
				card.ClipsDescendants = true

				local rarityKey = itemInfo.Rarity or "Common"
				local awakenedStats = player:GetAttribute(safeNameBase .. "_Awakened")
				if awakenedStats then rarityKey = "Transcendent" end

				local cColor = RarityColors[rarityKey] or "#FFFFFF"
				local rarityRGB = Color3.fromHex(string.gsub(cColor, "#", ""))

				local cStroke = Instance.new("UIStroke", card); cStroke.Color = rarityRGB; cStroke.Thickness = 1; cStroke.Transparency = 0.55; cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				local accentBar = Instance.new("Frame", card); accentBar.Size = UDim2.new(1, 0, 0, 3); accentBar.BackgroundColor3 = rarityRGB; accentBar.BorderSizePixel = 0; accentBar.ZIndex = 2
				local bgGlow = Instance.new("Frame", card); bgGlow.Size = UDim2.new(1, 0, 0.5, 0); bgGlow.Position = UDim2.new(0, 0, 0.5, 0); bgGlow.BackgroundColor3 = rarityRGB; bgGlow.BackgroundTransparency = 0.92; bgGlow.BorderSizePixel = 0; bgGlow.ZIndex = 1

				local countBadge = Instance.new("Frame", card); countBadge.Size = UDim2.new(0, 24, 0, 14); countBadge.AnchorPoint = Vector2.new(1, 0); countBadge.Position = UDim2.new(1, -4, 0, 8); countBadge.BackgroundColor3 = Color3.fromRGB(12, 12, 16); countBadge.BorderSizePixel = 0; countBadge.ZIndex = 3; Instance.new("UICorner", countBadge).CornerRadius = UDim.new(0, 4)
				local countTag = Instance.new("TextLabel", countBadge); countTag.Size = UDim2.new(1, 0, 1, 0); countTag.BackgroundTransparency = 1; countTag.Font = Enum.Font.GothamBlack; countTag.TextColor3 = Color3.fromRGB(210, 210, 210); countTag.TextSize = 10; countTag.Text = "x" .. count; countTag.ZIndex = 4

				local nameLbl = Instance.new("TextLabel", card); nameLbl.Size = UDim2.new(0.88, 0, 0.5, 0); nameLbl.Position = UDim2.new(0.5, 0, 0.5, 2); nameLbl.AnchorPoint = Vector2.new(0.5, 0.5); nameLbl.BackgroundTransparency = 1; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextColor3 = Color3.fromRGB(235, 235, 235); nameLbl.TextScaled = true; nameLbl.TextWrapped = true; nameLbl.Text = itemName; nameLbl.ZIndex = 3
				local tConstraint = Instance.new("UITextSizeConstraint", nameLbl); tConstraint.MaxTextSize = 11; tConstraint.MinTextSize = 7

				local rarityTag = Instance.new("TextLabel", card); rarityTag.Size = UDim2.new(0, 16, 0, 16); rarityTag.Position = UDim2.new(0, 6, 1, -22); rarityTag.BackgroundTransparency = 1; rarityTag.Font = Enum.Font.GothamBlack; rarityTag.TextColor3 = rarityRGB; rarityTag.TextTransparency = 0.3; rarityTag.TextSize = 11; rarityTag.Text = string.sub(rarityKey, 1, 1); rarityTag.ZIndex = 3

				local tTipStr = "<font color='" .. cColor .. "'>[" .. rarityKey .. "]</font> <b>" .. itemName .. "</b>"
				if itemInfo.Bonus then 
					local bList = {}; for k, v in pairs(itemInfo.Bonus) do table.insert(bList, "+" .. v .. " " .. string.upper(string.sub(k, 1, 3))) end; 
					tTipStr = tTipStr .. "\n<font color='#55FF55'>" .. table.concat(bList, "\n") .. "</font>" 
				elseif itemInfo.Desc then 
					local desc = itemInfo.Desc; local wrapped = ""; local lineLen = 0
					for word in string.gmatch(desc, "%S+") do
						if lineLen + #word + 1 > 35 and lineLen > 0 then wrapped = wrapped .. "\n" .. word; lineLen = #word
						else wrapped = wrapped .. (lineLen > 0 and " " or "") .. word; lineLen = lineLen + #word + (lineLen > 0 and 1 or 0) end
					end
					tTipStr = tTipStr .. "\n<font color='#AAAAAA'>" .. wrapped .. "</font>" 
				end
				if awakenedStats then tTipStr = tTipStr .. "\n<font color='#AA55FF'>[Awakened]:\n" .. awakenedStats .. "</font>" end

				local btnCover = Instance.new("TextButton", card); btnCover.Size = UDim2.new(1,0,1,0); btnCover.BackgroundTransparency = 1; btnCover.Text = ""; btnCover.ZIndex = 5
				btnCover.MouseEnter:Connect(function() if cachedTooltipMgr then cachedTooltipMgr.Show(tTipStr) end end)
				btnCover.MouseLeave:Connect(function() if cachedTooltipMgr then cachedTooltipMgr.Hide() end end)

				if itemInfo.IsGift then
					local giftTag = Instance.new("TextLabel", card); giftTag.Size = UDim2.new(1, 0, 0, 14); giftTag.Position = UDim2.new(0, 0, 1, -18); giftTag.BackgroundTransparency = 1; giftTag.Font = Enum.Font.GothamBold; giftTag.TextColor3 = Color3.fromRGB(255, 210, 80); giftTag.TextTransparency = 0.2; giftTag.TextSize = 10; giftTag.Text = "GIFT"; giftTag.ZIndex = 3
				else
					local ActionsOverlay = Instance.new("Frame", card); ActionsOverlay.Name = "ActionsOverlay"; ActionsOverlay.Size = UDim2.new(1, 0, 1, 0); ActionsOverlay.BackgroundColor3 = Color3.fromRGB(10, 10, 14); ActionsOverlay.BackgroundTransparency = 0.05; ActionsOverlay.Visible = false; ActionsOverlay.ZIndex = 10; ActionsOverlay.Active = true; Instance.new("UICorner", ActionsOverlay).CornerRadius = UDim.new(0, 6)
					local actLayout = Instance.new("UIListLayout", ActionsOverlay); actLayout.Padding = UDim.new(0, 4); actLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; actLayout.VerticalAlignment = Enum.VerticalAlignment.Center

					local buttonConsumed = false
					local function MakeOverlayBtn(text, bgColor)
						local obtn = Instance.new("TextButton", ActionsOverlay); obtn.Size = UDim2.new(0.9, 0, 0, 20); obtn.BackgroundColor3 = bgColor; obtn.Font = Enum.Font.GothamBold; obtn.TextColor3 = Color3.fromRGB(255, 255, 255); obtn.TextSize = 9; obtn.Text = text; obtn.ZIndex = 11; Instance.new("UICorner", obtn).CornerRadius = UDim.new(0, 4); return obtn
					end

					local equipBtn = MakeOverlayBtn("EQUIP", Color3.fromRGB(40, 80, 40))
					local sellBtn = MakeOverlayBtn("SELL 1x", Color3.fromRGB(80, 35, 35))
					local sellAllBtn = MakeOverlayBtn("SELL ALL", Color3.fromRGB(120, 30, 30))

					if itemInfo.Type ~= nil then 
						local isEq = (player:GetAttribute("EquippedWeapon") == itemName) or (player:GetAttribute("EquippedAccessory") == itemName)
						if isEq then 
							UIHelpers.ApplyButtonGradient(equipBtn, Color3.fromRGB(200, 80, 80), Color3.fromRGB(120, 40, 40), Color3.fromRGB(80, 20, 20)); equipBtn.Text = "UNEQUIP" 
						else 
							UIHelpers.ApplyButtonGradient(equipBtn, Color3.fromRGB(80, 160, 80), Color3.fromRGB(40, 90, 40), Color3.fromRGB(20, 60, 20)); equipBtn.Text = "EQUIP" 
						end

						equipBtn.MouseButton1Click:Connect(function() 
							buttonConsumed = true; if isEq then Network.EquipItem:FireServer("Unequip_" .. itemInfo.Type) else Network.EquipItem:FireServer(itemName) end; ActionsOverlay.Visible = false
						end)
					elseif itemInfo.Action ~= nil then 
						UIHelpers.ApplyButtonGradient(equipBtn, Color3.fromRGB(140, 80, 200), Color3.fromRGB(80, 40, 140), Color3.fromRGB(60, 20, 100)); equipBtn.Text = "USE"

						if itemInfo.Buff == "Gamepass" and player:GetAttribute("Has" .. (itemInfo.Unlock or "")) then equipBtn.Visible = false
						else
							equipBtn.MouseButton1Click:Connect(function() 
								buttonConsumed = true; if itemInfo.Action == "AwakenTitan" then Network.AwakenAction:FireServer("Titan") elseif itemInfo.Action == "AwakenClan" then Network.AwakenAction:FireServer("Clan") elseif itemInfo.Action == "Consume" or itemInfo.Action == "EquipTitan" then Network.ConsumeItem:FireServer(itemName) end; ActionsOverlay.Visible = false
							end)
						end
					else equipBtn.Visible = false end

					sellBtn.MouseButton1Click:Connect(function() buttonConsumed = true; Network.SellItem:FireServer(itemName, false); ActionsOverlay.Visible = false end)
					sellAllBtn.MouseButton1Click:Connect(function() buttonConsumed = true; Network.SellItem:FireServer(itemName, true); ActionsOverlay.Visible = false end)

					local function CloseAllOverlays() for _, c in ipairs(InvGrid:GetChildren()) do if c.Name == "ItemCard" then local ov = c:FindFirstChild("ActionsOverlay"); if ov then ov.Visible = false end end end end

					btnCover.MouseButton1Click:Connect(function()
						if buttonConsumed then buttonConsumed = false; return end
						if ActionsOverlay.Visible then ActionsOverlay.Visible = false else CloseAllOverlays(); ActionsOverlay.Visible = true end
					end)
				end
			end
		end

		InvTitle.Text = "INVENTORY (" .. currentSlotsUsed .. "/" .. MAX_INVENTORY_CAPACITY .. ")"
		if currentSlotsUsed >= MAX_INVENTORY_CAPACITY then InvTitle.TextColor3 = Color3.fromRGB(255, 100, 100) else InvTitle.TextColor3 = Color3.fromRGB(255, 215, 100) end

		task.delay(0.05, function() InvGrid.CanvasSize = UDim2.new(0, 0, 0, math.ceil(layoutOrderCounter / 6) * 95) end)
	end

	player.AttributeChanged:Connect(function(attr)
		if string.match(attr, "^Ach_") or attr == "Titan" or string.match(attr, "^Equipped") then EvaluateCosmeticUnlocks() end
		RefreshProfile()
	end)

	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 10)
		if leaderstats then
			for _, child in ipairs(leaderstats:GetChildren()) do
				if child:IsA("IntValue") then
					child.Changed:Connect(function()
						if child.Name == "Prestige" or child.Name == "Elo" then EvaluateCosmeticUnlocks() end
						RefreshProfile()
					end)
				end
			end
		end
		RefreshProfile()
	end)

	task.spawn(function()
		local cGrad = SubBtns["Inventory"]:FindFirstChildOfClass("UIGradient")
		if cGrad then UIHelpers.TweenGradient(cGrad, Color3.fromRGB(200, 150, 40), Color3.fromRGB(120, 80, 15), 0) end
		TweenService:Create(SubBtns["Inventory"], TweenInfo.new(0), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
	end)
end

function ProfileTab.Show() if MainFrame then MainFrame.Visible = true end end
return ProfileTab