-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local BattleTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))

local player = Players.LocalPlayer
local MainFrame, TopNav, ContentArea
local SubTabs, SubBtns = {}, {}
local ModesContainer, ModesCarousel
local SelectionContainer, SelectionCarousel, SelectionTitle, BackBtn
local PartyContainer, PartyToggleBtn
local TransitionOverlay, TransitionText
local pMemScroll 

local function PlayTransition(text, callback)
	if TransitionOverlay.Visible then return end
	TransitionOverlay.Visible = true
	TransitionText.Text = text

	local tIn = TweenService:Create(TransitionOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 0})
	local ttIn = TweenService:Create(TransitionText, TweenInfo.new(0.4), {TextTransparency = 0})
	tIn:Play(); ttIn:Play()

	tIn.Completed:Connect(function()
		callback()
		task.wait(0.6) 
		local tOut = TweenService:Create(TransitionOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 1})
		local ttOut = TweenService:Create(TransitionText, TweenInfo.new(0.5), {TextTransparency = 1})
		tOut:Play(); ttOut:Play()
		tOut.Completed:Connect(function() TransitionOverlay.Visible = false end)
	end)
end

local function FadeSwitch(fromGroup, toGroup)
	TweenService:Create(fromGroup, TweenInfo.new(0.2), {GroupTransparency = 1}):Play()
	task.wait(0.2)
	fromGroup.Visible = false
	toGroup.GroupTransparency = 1
	toGroup.Visible = true
	TweenService:Create(toGroup, TweenInfo.new(0.2), {GroupTransparency = 0}):Play()
end

local function ApplyButtonGradient(btn, topColor, botColor, strokeColor)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.AutoButtonColor = false 
	local grad = btn:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", btn); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, topColor), ColorSequenceKeypoint.new(1, botColor)}; grad.Rotation = 90
	local corner = btn:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", btn); corner.CornerRadius = UDim.new(0, 6)
	if strokeColor then
		local stroke = btn:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", btn); stroke.Color = strokeColor; stroke.Thickness = 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	if not btn:GetAttribute("GradientTextFixed") then
		btn:SetAttribute("GradientTextFixed", true)
		local textLbl = Instance.new("TextLabel", btn); textLbl.Name = "BtnTextLabel"; textLbl.Size = UDim2.new(1, 0, 1, 0); textLbl.BackgroundTransparency = 1; textLbl.Font = btn.Font; textLbl.TextSize = btn.TextSize; textLbl.TextScaled = btn.TextScaled; textLbl.RichText = btn.RichText; textLbl.TextWrapped = btn.TextWrapped; textLbl.TextXAlignment = btn.TextXAlignment; textLbl.TextYAlignment = btn.TextYAlignment; textLbl.ZIndex = btn.ZIndex + 1
		local tConstraint = btn:FindFirstChildOfClass("UITextSizeConstraint"); if tConstraint then tConstraint.Parent = textLbl end
		btn.ChildAdded:Connect(function(child) if child:IsA("UITextSizeConstraint") then task.delay(0, function() child.Parent = textLbl end) end end)
		textLbl.Text = btn.Text; textLbl.TextColor3 = btn.TextColor3; btn.Text = ""
		btn:GetPropertyChangedSignal("Text"):Connect(function() if btn.Text ~= "" then textLbl.Text = btn.Text; btn.Text = "" end end)
		btn:GetPropertyChangedSignal("TextColor3"):Connect(function() textLbl.TextColor3 = btn.TextColor3 end)
	end
end

local function SwitchToPvPMenu(parentFrame)
	PlayTransition("ENTERING UNDERGROUND ARENA...", function()
		MainFrame.Visible = false
		local pvpLobby = parentFrame:FindFirstChild("PvPLobby")
		if pvpLobby then pvpLobby.Visible = true end
	end)
end

function BattleTab.Init(parentFrame)
	local DECALS = { Modes = { Nightmare="rbxassetid://90132878979603", Expeditions="rbxassetid://114506098039778", Paths="rbxassetid://90938848776194", PvP="rbxassetid://100826303284945", Raid="rbxassetid://119392967268687", WorldBoss="rbxassetid://129655150803684" }, Bosses = { ["Frenzied Beast"]="rbxassetid://126246803477895", ["Abyssal Armored"]="rbxassetid://75593809803541", ["Doomsday Apparition"]="rbxassetid://114493300912789", ["Raid_Part1"]="rbxassetid://118182722089835", ["Raid_Part2"]="rbxassetid://127437496013300", ["Raid_Part3"]="rbxassetid://95511063358417", ["Raid_Part4"]="rbxassetid://92481334765869", ["Raid_Part5"]="rbxassetid://77055155553118", ["Raid_Part8"]="rbxassetid://82958903182689", ["Rod Reiss Titan"]="rbxassetid://119392967268687", ["Lara Tybur"]="rbxassetid://92481334765869", ["Doomsday Titan"]="rbxassetid://77055155553118", ["Ymir Fritz"]="rbxassetid://129655150803684" } }

	TransitionOverlay = Instance.new("Frame", parentFrame.Parent); TransitionOverlay.Name = "BattleTransition"; TransitionOverlay.Size = UDim2.new(1, 0, 1, 0); TransitionOverlay.BackgroundColor3 = Color3.new(0, 0, 0); TransitionOverlay.BackgroundTransparency = 1; TransitionOverlay.ZIndex = 1000; TransitionOverlay.Visible = false
	TransitionText = Instance.new("TextLabel", TransitionOverlay); TransitionText.Size = UDim2.new(1, 0, 0, 50); TransitionText.Position = UDim2.new(0, 0, 0.5, -25); TransitionText.BackgroundTransparency = 1; TransitionText.Font = Enum.Font.GothamBlack; TransitionText.TextColor3 = Color3.fromRGB(255, 215, 100); TransitionText.TextSize = 22; TransitionText.TextTransparency = 1

	MainFrame = Instance.new("Frame", parentFrame); MainFrame.Name = "BattleFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false
	TopNav = Instance.new("Frame", MainFrame); TopNav.Size = UDim2.new(1, 0, 0, 50); TopNav.BackgroundTransparency = 1; local navLayout = Instance.new("UIListLayout", TopNav); navLayout.FillDirection = Enum.FillDirection.Horizontal; navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; navLayout.VerticalAlignment = Enum.VerticalAlignment.Center; navLayout.Padding = UDim.new(0, 15)

	ContentArea = Instance.new("Frame", MainFrame); ContentArea.Size = UDim2.new(1, 0, 1, -50); ContentArea.Position = UDim2.new(0, 0, 0, 50); ContentArea.BackgroundTransparency = 1

	local function CreateSubNavBtn(name, text)
		local btn = Instance.new("TextButton", TopNav); btn.Size = UDim2.new(0, 150, 0, 36); btn.Font = Enum.Font.GothamBlack; btn.TextColor3 = Color3.fromRGB(150, 150, 150); btn.TextSize = 14; btn.Text = text; btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35); Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		btn.MouseButton1Click:Connect(function()
			for k, v in pairs(SubBtns) do v.TextColor3 = Color3.fromRGB(150, 150, 150); v.BackgroundColor3 = Color3.fromRGB(30, 30, 35) end
			btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
			for k, frame in pairs(SubTabs) do frame.Visible = (k == name) end
			if name == "Modes" and SelectionContainer.Visible then SelectionContainer.Visible = false; ModesContainer.Visible = true; ModesContainer.GroupTransparency = 0 elseif name == "Campaign" then if PartyContainer then PartyContainer.Visible = false end end
		end)
		SubBtns[name] = btn; return btn
	end

	CreateSubNavBtn("Campaign", "CAMPAIGN"); CreateSubNavBtn("Modes", "MODES")

	-- [[ FIX: 100% Relative Sizing for Campaign so it never clips or scrolls ]]
	SubTabs["Campaign"] = Instance.new("Frame", ContentArea); SubTabs["Campaign"].Size = UDim2.new(1, 0, 1, 0); SubTabs["Campaign"].BackgroundTransparency = 1; SubTabs["Campaign"].Visible = true

	local CampContainer = Instance.new("Frame", SubTabs["Campaign"]); CampContainer.Size = UDim2.new(0.92, 0, 0.9, 0); CampContainer.Position = UDim2.new(0.5, 0, 0.5, 0); CampContainer.AnchorPoint = Vector2.new(0.5, 0.5); CampContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Instance.new("UICorner", CampContainer).CornerRadius = UDim.new(0, 12); Instance.new("UIStroke", CampContainer).Color = Color3.fromRGB(60, 60, 70)
	local CampImage = Instance.new("ImageLabel", CampContainer); CampImage.Size = UDim2.new(1, 0, 0.45, 0); CampImage.BackgroundColor3 = Color3.fromRGB(15, 15, 18); CampImage.Image = "rbxassetid://80153476985849"; CampImage.ScaleType = Enum.ScaleType.Crop; Instance.new("UICorner", CampImage).CornerRadius = UDim.new(0, 12)

	local CampTitle = Instance.new("TextLabel", CampContainer); CampTitle.Size = UDim2.new(1, -30, 0.15, 0); CampTitle.Position = UDim2.new(0, 15, 0.45, 5); CampTitle.BackgroundTransparency = 1; CampTitle.Font = Enum.Font.GothamBlack; CampTitle.TextSize = 20; CampTitle.TextColor3 = Color3.fromRGB(255, 255, 255); CampTitle.TextScaled = true; CampTitle.TextXAlignment = Enum.TextXAlignment.Left; CampTitle.Text = "CONTINUE STORY"
	local tConstraint = Instance.new("UITextSizeConstraint", CampTitle); tConstraint.MaxTextSize = 20; tConstraint.MinTextSize = 14

	local CampDesc = Instance.new("TextLabel", CampContainer); CampDesc.Size = UDim2.new(1, -30, 0.25, 0); CampDesc.Position = UDim2.new(0, 15, 0.6, 0); CampDesc.BackgroundTransparency = 1; CampDesc.Font = Enum.Font.GothamMedium; CampDesc.TextSize = 13; CampDesc.TextColor3 = Color3.fromRGB(180, 180, 180); CampDesc.TextXAlignment = Enum.TextXAlignment.Left; CampDesc.TextYAlignment = Enum.TextYAlignment.Top; CampDesc.TextWrapped = true; CampDesc.Text = "Pick up right where you left off. The fate of the walls depends on your next move."

	local PlayCampBtn = Instance.new("TextButton", CampContainer); PlayCampBtn.Size = UDim2.new(0.9, 0, 0.12, 0); PlayCampBtn.Position = UDim2.new(0.5, 0, 0.95, 0); PlayCampBtn.AnchorPoint = Vector2.new(0.5, 1); PlayCampBtn.Font = Enum.Font.GothamBlack; PlayCampBtn.TextSize = 18; PlayCampBtn.TextColor3 = Color3.fromRGB(255, 255, 255); PlayCampBtn.Text = "DEPLOY"; ApplyButtonGradient(PlayCampBtn, Color3.fromRGB(60, 140, 60), Color3.fromRGB(30, 80, 30), Color3.fromRGB(40, 100, 40))
	PlayCampBtn.MouseButton1Click:Connect(function() PlayTransition("DEPLOYING TO STORY...", function() Network:WaitForChild("CombatAction"):FireServer("EngageStory") end) end)

	player.AttributeChanged:Connect(function(attr) if attr == "CurrentPart" then CampTitle.Text = "CHAPTER " .. (player:GetAttribute("CurrentPart") or 1) .. ": CONTINUE STORY" end end)

	SubTabs["Modes"] = Instance.new("Frame", ContentArea); SubTabs["Modes"].Size = UDim2.new(1, 0, 1, 0); SubTabs["Modes"].BackgroundTransparency = 1; SubTabs["Modes"].Visible = false
	ModesContainer = Instance.new("CanvasGroup", SubTabs["Modes"]); ModesContainer.Size = UDim2.new(1, 0, 1, 0); ModesContainer.BackgroundTransparency = 1
	SelectionContainer = Instance.new("CanvasGroup", SubTabs["Modes"]); SelectionContainer.Size = UDim2.new(1, 0, 1, 0); SelectionContainer.BackgroundTransparency = 1; SelectionContainer.Visible = false

	BackBtn = Instance.new("TextButton", SelectionContainer); BackBtn.Size = UDim2.new(0, 120, 0, 35); BackBtn.Position = UDim2.new(0, 15, 0, 10); BackBtn.Font = Enum.Font.GothamBold; BackBtn.TextSize = 12; BackBtn.TextColor3 = Color3.fromRGB(255, 255, 255); BackBtn.Text = "<- BACK"; ApplyButtonGradient(BackBtn, Color3.fromRGB(60, 60, 70), Color3.fromRGB(30, 30, 40), Color3.fromRGB(80, 80, 90))
	BackBtn.MouseButton1Click:Connect(function() FadeSwitch(SelectionContainer, ModesContainer) end)

	SelectionTitle = Instance.new("TextLabel", SelectionContainer); SelectionTitle.Size = UDim2.new(1, -150, 0, 35); SelectionTitle.Position = UDim2.new(0, 140, 0, 10); SelectionTitle.BackgroundTransparency = 1; SelectionTitle.Font = Enum.Font.GothamBlack; SelectionTitle.TextSize = 22; SelectionTitle.TextColor3 = Color3.fromRGB(255, 215, 100); SelectionTitle.TextXAlignment = Enum.TextXAlignment.Left

	SelectionCarousel = Instance.new("ScrollingFrame", SelectionContainer); SelectionCarousel.Size = UDim2.new(1, 0, 1, -55); SelectionCarousel.Position = UDim2.new(0, 0, 0, 55); SelectionCarousel.BackgroundTransparency = 1; SelectionCarousel.ScrollingDirection = Enum.ScrollingDirection.Y; SelectionCarousel.ScrollBarThickness = 0
	local sGridLayout = Instance.new("UIGridLayout", SelectionCarousel); sGridLayout.CellSize = UDim2.new(0.46, 0, 0, 240); sGridLayout.CellPadding = UDim2.new(0.04, 0, 0, 15); sGridLayout.SortOrder = Enum.SortOrder.LayoutOrder; sGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local sPad = Instance.new("UIPadding", SelectionCarousel); sPad.PaddingTop = UDim.new(0, 5); sPad.PaddingBottom = UDim.new(0, 20)
	sGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SelectionCarousel.CanvasSize = UDim2.new(0, 0, 0, sGridLayout.AbsoluteContentSize.Y + 30) end)

	local function OpenSelectionMenu(titleText, dataTable, onPlayFunc)
		SelectionTitle.Text = titleText
		for _, child in ipairs(SelectionCarousel:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
		local sortedKeys = {}; for k in pairs(dataTable) do table.insert(sortedKeys, k) end; table.sort(sortedKeys)
		local layoutOrder = 1
		for _, key in ipairs(sortedKeys) do
			local data = dataTable[key]
			local card = Instance.new("TextButton", SelectionCarousel); card.BackgroundColor3 = Color3.fromRGB(15, 15, 18); card.LayoutOrder = layoutOrder; card.ClipsDescendants = true; Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", card).Color = Color3.fromRGB(60, 60, 70)
			local bgImg = Instance.new("ImageLabel", card); bgImg.Size = UDim2.new(1, 0, 1, 0); bgImg.BackgroundTransparency = 1; bgImg.Image = DECALS.Bosses[key] or "rbxassetid://0"; bgImg.ScaleType = Enum.ScaleType.Crop
			local gradFrame = Instance.new("Frame", card); gradFrame.Size = UDim2.new(1, 0, 1, 0); gradFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0); gradFrame.BorderSizePixel = 0; local grad = Instance.new("UIGradient", gradFrame); grad.Rotation = 90; grad.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 1), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 0)}

			local nLbl = Instance.new("TextLabel", card); nLbl.Size = UDim2.new(1, -10, 0, 25); nLbl.Position = UDim2.new(0, 5, 1, -125); nLbl.BackgroundTransparency = 1; nLbl.Font = Enum.Font.GothamBlack; nLbl.TextColor3 = Color3.fromRGB(255, 255, 255); nLbl.TextSize = 14; nLbl.TextScaled = true; nLbl.TextXAlignment = Enum.TextXAlignment.Left; nLbl.Text = data.Name or key
			local rLbl = Instance.new("TextLabel", card); rLbl.Size = UDim2.new(1, -10, 0, 20); rLbl.Position = UDim2.new(0, 5, 1, -100); rLbl.BackgroundTransparency = 1; rLbl.Font = Enum.Font.GothamBold; rLbl.TextColor3 = Color3.fromRGB(200, 200, 200); rLbl.TextSize = 10; rLbl.TextXAlignment = Enum.TextXAlignment.Left; rLbl.Text = "Req: Pres. " .. (data.Req or 0)
			local dLbl = Instance.new("TextLabel", card); dLbl.Size = UDim2.new(1, -10, 0, 40); dLbl.Position = UDim2.new(0, 5, 1, -80); dLbl.BackgroundTransparency = 1; dLbl.Font = Enum.Font.GothamMedium; dLbl.TextColor3 = Color3.fromRGB(180, 180, 180); dLbl.TextSize = 9; dLbl.TextXAlignment = Enum.TextXAlignment.Left; dLbl.TextYAlignment = Enum.TextYAlignment.Top; dLbl.TextWrapped = true; local descText = data.Desc or ("HP: " .. (data.Health or "Unknown")); if data.Drops then descText = descText .. "\nRewards: +" .. (data.Drops.Dews or 0) .. " Dews" end; dLbl.Text = descText

			local pBtn = Instance.new("TextButton", card); pBtn.Size = UDim2.new(0.9, 0, 0, 30); pBtn.Position = UDim2.new(0.5, 0, 1, -5); pBtn.AnchorPoint = Vector2.new(0.5, 1); pBtn.Font = Enum.Font.GothamBlack; pBtn.TextSize = 14; pBtn.TextColor3 = Color3.fromRGB(255, 255, 255); pBtn.Text = "DEPLOY"; ApplyButtonGradient(pBtn, Color3.fromRGB(200, 60, 60), Color3.fromRGB(100, 30, 30), Color3.fromRGB(80, 20, 20)); pBtn.ZIndex = 5
			pBtn.MouseButton1Click:Connect(function() PlayTransition("DEPLOYING...", function() onPlayFunc(key) end) end)
			layoutOrder += 1
		end
		FadeSwitch(ModesContainer, SelectionContainer)
	end

	ModesCarousel = Instance.new("ScrollingFrame", ModesContainer); ModesCarousel.Size = UDim2.new(1, 0, 1, 0); ModesCarousel.Position = UDim2.new(0, 0, 0, 0); ModesCarousel.BackgroundTransparency = 1; ModesCarousel.ScrollingDirection = Enum.ScrollingDirection.Y; ModesCarousel.ScrollBarThickness = 0
	local carouselLayout = Instance.new("UIGridLayout", ModesCarousel); carouselLayout.CellSize = UDim2.new(0.46, 0, 0, 220); carouselLayout.CellPadding = UDim2.new(0.04, 0, 0, 15); carouselLayout.SortOrder = Enum.SortOrder.LayoutOrder; carouselLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local cPad = Instance.new("UIPadding", ModesCarousel); cPad.PaddingTop = UDim.new(0, 10)
	cPad.PaddingBottom = UDim.new(0, 60) -- [[ FIX: Extra padding to prevent Party Button from obscuring cards ]]

	local function CreateModeCard(name, desc, imgId, layoutOrder, onClickFunc)
		local card = Instance.new("TextButton", ModesCarousel); card.LayoutOrder = layoutOrder; card.Text = ""; card.AutoButtonColor = false; card.BackgroundColor3 = Color3.fromRGB(15, 15, 18); card.ClipsDescendants = true; Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10); local stroke = Instance.new("UIStroke", card); stroke.Color = Color3.fromRGB(60, 60, 70); stroke.Thickness = 2
		local bgImg = Instance.new("ImageLabel", card); bgImg.Size = UDim2.new(1, 0, 1, 0); bgImg.BackgroundTransparency = 1; bgImg.Image = imgId; bgImg.ScaleType = Enum.ScaleType.Crop
		local gradFrame = Instance.new("Frame", card); gradFrame.Size = UDim2.new(1, 0, 1, 0); gradFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0); gradFrame.BorderSizePixel = 0; local grad = Instance.new("UIGradient", gradFrame); grad.Rotation = 90; grad.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 1), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 0)}
		local title = Instance.new("TextLabel", card); title.Size = UDim2.new(1, -10, 0, 30); title.Position = UDim2.new(0, 5, 1, -75); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack; title.TextSize = 14; title.TextColor3 = Color3.fromRGB(255, 255, 255); title.TextScaled = true; title.TextXAlignment = Enum.TextXAlignment.Center; title.Text = name
		local descLbl = Instance.new("TextLabel", card); descLbl.Size = UDim2.new(1, -10, 0, 40); descLbl.Position = UDim2.new(0, 5, 1, -45); descLbl.BackgroundTransparency = 1; descLbl.Font = Enum.Font.GothamBold; descLbl.TextSize = 9; descLbl.TextColor3 = Color3.fromRGB(180, 180, 180); descLbl.TextXAlignment = Enum.TextXAlignment.Center; descLbl.TextYAlignment = Enum.TextYAlignment.Top; descLbl.TextWrapped = true; descLbl.Text = desc
		card.MouseButton1Click:Connect(onClickFunc)
	end

	CreateModeCard("NIGHTMARE HUNTS", "Obtain legendary Weapons.", DECALS.Modes.Nightmare, 1, function() OpenSelectionMenu("SELECT NIGHTMARE", EnemyData.NightmareHunts, function(bossId) Network:WaitForChild("CombatAction"):FireServer("EngageNightmare", { BossId = bossId }) end) end)
	CreateModeCard("EXPEDITIONS", "Scavenge vital resources.", DECALS.Modes.Expeditions, 2, function() PlayTransition("DEPARTING ON EXPEDITION...", function() Network:WaitForChild("CombatAction"):FireServer("EngageEndless") end) end)
	CreateModeCard("THE PATHS", "Unlock stat points.", DECALS.Modes.Paths, 3, function() PlayTransition("CONNECTING TO COORDINATE...", function() Network:WaitForChild("CombatAction"):FireServer("EngagePaths") end) end)
	CreateModeCard("PVP ARENA", "Combat other players.", DECALS.Modes.PvP, 4, function() SwitchToPvPMenu(parentFrame) end)
	CreateModeCard("RAIDS", "Deploy your party against Giants.", DECALS.Modes.Raid, 5, function() OpenSelectionMenu("SELECT RAID", EnemyData.RaidBosses, function(raidId) Network:WaitForChild("RaidAction"):FireServer("DeployParty", { RaidId = raidId }) end) end)
	CreateModeCard("WORLD BOSS", "Intercept catastrophic threats.", DECALS.Modes.WorldBoss, 6, function() OpenSelectionMenu("SELECT WORLD BOSS", EnemyData.WorldBosses, function(bossId) Network:WaitForChild("CombatAction"):FireServer("EngageWorldBoss", { BossId = bossId }) end) end)
	carouselLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ModesCarousel.CanvasSize = UDim2.new(0, 0, 0, carouselLayout.AbsoluteContentSize.Y + 80) end)

	-- [[ FIX: Party Button is now a discreet floating button in the bottom right ]]
	PartyToggleBtn = Instance.new("TextButton", ModesContainer); PartyToggleBtn.Size = UDim2.new(0, 120, 0, 35); PartyToggleBtn.Position = UDim2.new(1, -10, 1, -10); PartyToggleBtn.AnchorPoint = Vector2.new(1, 1); PartyToggleBtn.Font = Enum.Font.GothamBlack; PartyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); PartyToggleBtn.TextSize = 12; PartyToggleBtn.Text = "PARTY"
	PartyToggleBtn.ZIndex = 100
	ApplyButtonGradient(PartyToggleBtn, Color3.fromRGB(80, 80, 90), Color3.fromRGB(40, 40, 50), Color3.fromRGB(60, 60, 70))

	-- [[ FIX: Slimmed down Party Container so it fits cleanly on mobile ]]
	PartyContainer = Instance.new("Frame", SubTabs["Modes"]); PartyContainer.Size = UDim2.new(0, 280, 0, 360); PartyContainer.Position = UDim2.new(0.5, 0, 0.5, 0); PartyContainer.AnchorPoint = Vector2.new(0.5, 0.5); PartyContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25); PartyContainer.Visible = false; PartyContainer.ZIndex = 500; PartyContainer.Active = true 
	Instance.new("UICorner", PartyContainer).CornerRadius = UDim.new(0, 12); Instance.new("UIStroke", PartyContainer).Color = Color3.fromRGB(80, 120, 200); Instance.new("UIStroke", PartyContainer).Thickness = 2

	local pHeader = Instance.new("TextLabel", PartyContainer); pHeader.Size = UDim2.new(1, 0, 0, 40); pHeader.BackgroundTransparency = 1; pHeader.Font = Enum.Font.GothamBlack; pHeader.TextColor3 = Color3.fromRGB(255, 215, 100); pHeader.TextSize = 16; pHeader.Text = "PARTY MANAGEMENT"
	local closePartyBtn = Instance.new("TextButton", PartyContainer); closePartyBtn.Size = UDim2.new(0, 30, 0, 30); closePartyBtn.Position = UDim2.new(1, -10, 0, 5); closePartyBtn.AnchorPoint = Vector2.new(1, 0); closePartyBtn.BackgroundTransparency = 1; closePartyBtn.Font = Enum.Font.GothamBlack; closePartyBtn.TextColor3 = Color3.fromRGB(255, 100, 100); closePartyBtn.TextSize = 20; closePartyBtn.Text = "X"
	local createBtn = Instance.new("TextButton", PartyContainer); createBtn.Size = UDim2.new(0.9, 0, 0, 35); createBtn.Position = UDim2.new(0.05, 0, 0, 45); createBtn.Font = Enum.Font.GothamBold; createBtn.TextColor3 = Color3.fromRGB(255, 255, 255); createBtn.TextSize = 14; createBtn.Text = "CREATE PARTY"; ApplyButtonGradient(createBtn, Color3.fromRGB(60, 140, 60), Color3.fromRGB(30, 80, 30), Color3.fromRGB(40, 100, 40))
	local leaveBtn = Instance.new("TextButton", PartyContainer); leaveBtn.Size = UDim2.new(0.9, 0, 0, 35); leaveBtn.Position = UDim2.new(0.05, 0, 0, 85); leaveBtn.Font = Enum.Font.GothamBold; leaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255); leaveBtn.TextSize = 14; leaveBtn.Text = "LEAVE PARTY"; ApplyButtonGradient(leaveBtn, Color3.fromRGB(160, 60, 60), Color3.fromRGB(100, 30, 30), Color3.fromRGB(120, 40, 40))
	local invBox = Instance.new("TextBox", PartyContainer); invBox.Size = UDim2.new(0.6, 0, 0, 35); invBox.Position = UDim2.new(0.05, 0, 0, 130); invBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18); invBox.Font = Enum.Font.GothamMedium; invBox.TextColor3 = Color3.fromRGB(255, 255, 255); invBox.TextSize = 14; invBox.PlaceholderText = "Player Name..."; Instance.new("UICorner", invBox).CornerRadius = UDim.new(0, 4)
	local invBtn = Instance.new("TextButton", PartyContainer); invBtn.Size = UDim2.new(0.28, 0, 0, 35); invBtn.Position = UDim2.new(0.67, 0, 0, 130); invBtn.Font = Enum.Font.GothamBold; invBtn.TextColor3 = Color3.fromRGB(255, 255, 255); invBtn.TextSize = 14; invBtn.Text = "INVITE"; ApplyButtonGradient(invBtn, Color3.fromRGB(60, 100, 180), Color3.fromRGB(30, 50, 100), Color3.fromRGB(40, 60, 120))

	pMemScroll = Instance.new("ScrollingFrame", PartyContainer); pMemScroll.Size = UDim2.new(0.9, 0, 1, -175); pMemScroll.Position = UDim2.new(0.05, 0, 0, 170); pMemScroll.BackgroundTransparency = 1; pMemScroll.ScrollBarThickness = 0; local pmListLayout = Instance.new("UIListLayout", pMemScroll); pmListLayout.Padding = UDim.new(0, 5)

	createBtn.MouseButton1Click:Connect(function() Network:WaitForChild("PartyAction"):FireServer("Create") end)
	leaveBtn.MouseButton1Click:Connect(function() Network:WaitForChild("PartyAction"):FireServer("Leave") end)
	invBtn.MouseButton1Click:Connect(function() if invBox.Text ~= "" then Network:WaitForChild("PartyAction"):FireServer("Invite", invBox.Text); invBox.Text = "" end end)
	PartyToggleBtn.MouseButton1Click:Connect(function() PartyContainer.Visible = true; PartyContainer.Position = UDim2.new(0.5, 0, 0.5, 50); TweenService:Create(PartyContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play() end)
	closePartyBtn.MouseButton1Click:Connect(function() PartyContainer.Visible = false end)

	TweenService:Create(SubBtns["Campaign"], TweenInfo.new(0), {TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(80, 80, 90)}):Play()

	Network:WaitForChild("PartyUpdate").OnClientEvent:Connect(function(action, data)
		if action == "UpdateList" then
			for _, child in ipairs(pMemScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
			for _, mem in ipairs(data) do
				local row = Instance.new("Frame", pMemScroll); row.Size = UDim2.new(1, -10, 0, 30); row.BackgroundColor3 = Color3.fromRGB(30, 30, 35); Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
				local lbl = Instance.new("TextLabel", row); lbl.Size = UDim2.new(1, -10, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextColor3 = Color3.new(1,1,1); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = mem.Name .. (mem.IsLeader and " (LEADER)" or "")
				if mem.IsLeader then lbl.TextColor3 = Color3.fromRGB(255, 215, 100) end
			end
			pMemScroll.CanvasSize = UDim2.new(0, 0, 0, #data * 35 + 5)
		elseif action == "Disbanded" then
			for _, child in ipairs(pMemScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
			pMemScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		elseif action == "IncomingInvite" then
			local senderName = data
			local AOT_UI = player.PlayerGui:WaitForChild("AOT_Interface")
			if AOT_UI:FindFirstChild("PartyInvite_" .. senderName) then return end

			local prompt = Instance.new("Frame", AOT_UI); prompt.Name = "PartyInvite_" .. senderName; prompt.Size = UDim2.new(0, 300, 0, 120); prompt.Position = UDim2.new(0.5, 0, 0.85, 0); prompt.AnchorPoint = Vector2.new(0.5, 0.5); prompt.BackgroundColor3 = Color3.fromRGB(20, 20, 25); prompt.Active = true; Instance.new("UICorner", prompt).CornerRadius = UDim.new(0, 8); local stroke = Instance.new("UIStroke", prompt); stroke.Color = Color3.fromRGB(150, 255, 150); stroke.Thickness = 2
			local lbl = Instance.new("TextLabel", prompt); lbl.Size = UDim2.new(1, 0, 0, 50); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBlack; lbl.TextColor3 = Color3.fromRGB(255, 255, 255); lbl.TextSize = 14; lbl.Text = senderName .. " invited you to a Party!"
			local accBtn = Instance.new("TextButton", prompt); accBtn.Size = UDim2.new(0.4, 0, 0, 40); accBtn.Position = UDim2.new(0.05, 0, 1, -50); accBtn.Font = Enum.Font.GothamBlack; accBtn.TextColor3 = Color3.fromRGB(150, 255, 150); accBtn.Text = "ACCEPT"; accBtn.TextSize = 14; ApplyButtonGradient(accBtn, Color3.fromRGB(20, 40, 20), Color3.fromRGB(10, 20, 10), Color3.fromRGB(80, 180, 80))
			local decBtn = Instance.new("TextButton", prompt); decBtn.Size = UDim2.new(0.4, 0, 0, 40); decBtn.Position = UDim2.new(0.55, 0, 1, -50); decBtn.Font = Enum.Font.GothamBlack; decBtn.TextColor3 = Color3.fromRGB(255, 150, 150); decBtn.Text = "DECLINE"; decBtn.TextSize = 14; ApplyButtonGradient(decBtn, Color3.fromRGB(40, 20, 20), Color3.fromRGB(20, 10, 10), Color3.fromRGB(180, 80, 80))

			accBtn.MouseButton1Click:Connect(function() Network.PartyAction:FireServer("AcceptInvite", senderName); prompt:Destroy() end)
			decBtn.MouseButton1Click:Connect(function() prompt:Destroy() end)
			task.delay(15, function() if prompt and prompt.Parent then prompt:Destroy() end end)
		end
	end)
end

function BattleTab.Show() if MainFrame then MainFrame.Visible = true end end
return BattleTab