-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local RaidTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local EffectsManager = require(script.Parent:WaitForChild("EffectsManager")) 

local player = Players.LocalPlayer

local ArenaFrame, HeaderContainer, HeaderText, TimerBar
local PartyListFrame, BossFrame
local BossHPBar, BossHPText, BossNameText, BossStatusBox, BossShieldBar
local eAvatarBox, eAvatarIcon

local LogText, ActionGrid, TargetMenu, LeaveBtn
local currentRaidId = nil
local currentRange = "Close"
local inputLocked = false
local pendingSkillName = nil
local cachedTooltipMgr

local currentTimerTweenSize, currentTimerTweenColor
local PartyUIBars = {} 

local MAX_LOG_MESSAGES = 3
local logMessages = {}

local function AddLogMessage(msgText, append)
	if not msgText or msgText == "" then return end
	if append then 
		table.insert(logMessages, msgText)
		if #logMessages > MAX_LOG_MESSAGES then table.remove(logMessages, 1) end
	else 
		logMessages = {msgText} 
	end
	LogText.Text = table.concat(logMessages, "\n\n")
end

local function ShakeUI(intensity)
	if not intensity or intensity == "None" then return end
	local amount = (intensity == "Heavy") and 15 or 6
	local originalPos = UDim2.new(0.5, 0, 0.5, 0)
	task.spawn(function()
		for i = 1, 10 do
			if not ArenaFrame.Visible then break end
			local xOffset = math.random(-amount, amount); local yOffset = math.random(-amount, amount)
			ArenaFrame.Position = originalPos + UDim2.new(0, xOffset, 0, yOffset)
			task.wait(0.03)
		end
		ArenaFrame.Position = originalPos
	end)
end

local function ApplyGradient(label, color1, color2)
	local grad = Instance.new("UIGradient", label)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}
end

local function ApplyButtonGradient(btn, topColor, botColor, strokeColor)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	local grad = btn:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", btn)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, topColor), ColorSequenceKeypoint.new(1, botColor)}
	grad.Rotation = 90
	local corner = btn:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 4)
	if strokeColor then
		local stroke = btn:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", btn)
		stroke.Color = strokeColor; stroke.Thickness = 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.LineJoinMode = Enum.LineJoinMode.Miter
	end
	if not btn:GetAttribute("GradientTextFixed") then
		btn:SetAttribute("GradientTextFixed", true)
		local textLbl = Instance.new("TextLabel", btn)
		textLbl.Name = "BtnTextLabel"; textLbl.Size = UDim2.new(1, 0, 1, 0); textLbl.BackgroundTransparency = 1
		textLbl.Font = btn.Font; textLbl.TextSize = btn.TextSize; textLbl.TextScaled = btn.TextScaled; textLbl.RichText = btn.RichText; textLbl.TextWrapped = btn.TextWrapped
		textLbl.TextXAlignment = btn.TextXAlignment; textLbl.TextYAlignment = btn.TextYAlignment; textLbl.ZIndex = btn.ZIndex + 1
		local tConstraint = btn:FindFirstChildOfClass("UITextSizeConstraint"); if tConstraint then tConstraint.Parent = textLbl end
		btn.ChildAdded:Connect(function(child) if child:IsA("UITextSizeConstraint") then task.delay(0, function() child.Parent = textLbl end) end end)
		textLbl.Text = btn.Text; textLbl.TextColor3 = btn.TextColor3; btn.Text = ""

		btn:GetPropertyChangedSignal("Text"):Connect(function() if btn.Text ~= "" then textLbl.Text = btn.Text; btn.Text = "" end end)
		btn:GetPropertyChangedSignal("TextColor3"):Connect(function() textLbl.TextColor3 = btn.TextColor3 end)
		btn:GetPropertyChangedSignal("RichText"):Connect(function() textLbl.RichText = btn.RichText end)
	end
end

local function CreateBar(parent, color1, color2, size, labelText, alignRight)
	local container = Instance.new("Frame", parent)
	container.Size = size; container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", container).Color = Color3.fromRGB(60, 60, 70)

	local fill = Instance.new("Frame", container)
	fill.Size = UDim2.new(1, 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
	if alignRight then fill.AnchorPoint = Vector2.new(1, 0); fill.Position = UDim2.new(1, 0, 0, 0) end
	local grad = Instance.new("UIGradient", fill); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}; grad.Rotation = 90

	local text = Instance.new("TextLabel", container)
	text.Size = UDim2.new(1, alignRight and -10 or -10, 1, 0); text.Position = UDim2.new(0, alignRight and 0 or 10, 0, 0); text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold; text.TextColor3 = Color3.fromRGB(255, 255, 255); text.TextSize = 11; text.TextStrokeTransparency = 0.5; text.Text = labelText
	text.TextXAlignment = alignRight and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left; text.ZIndex = 5
	return fill, text, container
end

local function RenderStatuses(container, statuses)
	for _, child in ipairs(container:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	if not statuses then return end

	local function addIcon(iconTxt, bgColor, strokeColor, tooltipText)
		local f = Instance.new("Frame", container)
		f.Size = UDim2.new(0, 24, 0, 18); f.BackgroundColor3 = bgColor; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4); Instance.new("UIStroke", f).Color = strokeColor
		local t = Instance.new("TextLabel", f)
		t.Size = UDim2.new(1, 0, 1, 0); t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBlack; t.Text = iconTxt; t.TextColor3 = Color3.fromRGB(255,255,255); t.TextScaled = true
		t.TextStrokeTransparency = 0 

		local hoverBtn = Instance.new("TextButton", f)
		hoverBtn.Size = UDim2.new(1, 0, 1, 0); hoverBtn.BackgroundTransparency = 1; hoverBtn.Text = ""; hoverBtn.ZIndex = 500
		hoverBtn.MouseEnter:Connect(function() if cachedTooltipMgr then cachedTooltipMgr.Show(tooltipText) end end)
		hoverBtn.MouseLeave:Connect(function() if cachedTooltipMgr then cachedTooltipMgr.Hide() end end)
	end

	if statuses.Dodge and statuses.Dodge > 0 then addIcon("DGE", Color3.fromRGB(30, 60, 120), Color3.fromRGB(60, 100, 200), "Dodge Active: Evades Next Attack") end
	if statuses.Transformed and statuses.Transformed > 0 then addIcon("TTN", Color3.fromRGB(150, 40, 40), Color3.fromRGB(200, 60, 60), "Titan Form Active") end
	for sName, duration in pairs(statuses) do
		if duration > 0 then
			if sName == "Crippled" then addIcon("CRP", Color3.fromRGB(80, 80, 80), Color3.fromRGB(120, 120, 120), "Crippled: Speed Halved (" .. duration .. " turns)")
			elseif sName == "Immobilized" then addIcon("IMB", Color3.fromRGB(40, 120, 40), Color3.fromRGB(80, 200, 80), "Immobilized: 0 Speed (" .. duration .. " turns)")
			elseif sName == "Weakened" then addIcon("WEK", Color3.fromRGB(120, 80, 40), Color3.fromRGB(200, 120, 60), "Weakened: Damage Halved (" .. duration .. " turns)")
			elseif sName == "Blinded" then addIcon("BLD", Color3.fromRGB(40, 40, 40), Color3.fromRGB(80, 80, 80), "Blinded: Target loses their turn! (" .. duration .. " turns)")
			elseif sName == "TrueBlind" then addIcon("TBL", Color3.fromRGB(20, 20, 20), Color3.fromRGB(50, 50, 50), "True Blindness: Target loses their turn! (" .. duration .. " turns)")
			elseif sName == "Buff_Strength" or sName == "Buff_Defense" then addIcon("BUF", Color3.fromRGB(20, 120, 20), Color3.fromRGB(40, 200, 40), "Stat Buff Active (" .. duration .. " turns)")
			elseif sName == "Bleed" then addIcon("BLD", Color3.fromRGB(180, 40, 40), Color3.fromRGB(220, 60, 60), "Bleeding: TAKING DOT (" .. duration .. " turns)")
			elseif sName == "Burn" then addIcon("BRN", Color3.fromRGB(200, 100, 40), Color3.fromRGB(240, 140, 60), "Burning: TAKING DOT (" .. duration .. " turns)")
			end
		end
	end
end

local function StartVisualTimer(endTime)
	if currentTimerTweenSize then currentTimerTweenSize:Cancel() end
	if currentTimerTweenColor then currentTimerTweenColor:Cancel() end

	local remaining = endTime - os.time()
	if remaining < 0 then remaining = 0 end

	TimerBar.Size = UDim2.new(1, 0, 1, 0)
	TimerBar.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 

	local tweenInfo = TweenInfo.new(remaining, Enum.EasingStyle.Linear)
	currentTimerTweenSize = TweenService:Create(TimerBar, tweenInfo, {Size = UDim2.new(0, 0, 1, 0)})
	currentTimerTweenColor = TweenService:Create(TimerBar, tweenInfo, {BackgroundColor3 = Color3.fromRGB(231, 76, 60)}) 

	currentTimerTweenSize:Play(); currentTimerTweenColor:Play()
end

local function LockGridAndWait()
	inputLocked = true
	TargetMenu.Visible = false
	ActionGrid.Visible = true
	for _, b in ipairs(ActionGrid:GetChildren()) do 
		if b:IsA("TextButton") then 
			ApplyButtonGradient(b, Color3.fromRGB(25, 20, 30), Color3.fromRGB(15, 10, 20), Color3.fromRGB(40, 30, 50))
			b.TextColor3 = Color3.fromRGB(120, 120, 120) 
		end 
	end
	AddLogMessage("<font color='#55FFFF'><b>MOVE LOCKED IN. WAITING FOR PARTY...</b></font>", true)
end

function RaidTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr

	ArenaFrame = Instance.new("Frame", parentFrame.Parent)
	ArenaFrame.Name = "RaidArenaFrame"; ArenaFrame.Size = UDim2.new(0, 850, 0, 620); ArenaFrame.Position = UDim2.new(0.5, 0, 0.5, 0); ArenaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	ArenaFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20); ArenaFrame.Visible = false; ArenaFrame.ZIndex = 200
	Instance.new("UICorner", ArenaFrame).CornerRadius = UDim.new(0, 12)
	local outerStroke = Instance.new("UIStroke", ArenaFrame); outerStroke.Thickness = 2; outerStroke.Color = Color3.fromRGB(200, 50, 255); outerStroke.LineJoinMode = Enum.LineJoinMode.Miter

	local arenaLayout = Instance.new("UIListLayout", ArenaFrame); arenaLayout.SortOrder = Enum.SortOrder.LayoutOrder; arenaLayout.Padding = UDim.new(0, 10); arenaLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local arenaPadding = Instance.new("UIPadding", ArenaFrame); arenaPadding.PaddingTop = UDim.new(0, 10); arenaPadding.PaddingBottom = UDim.new(0, 10)

	HeaderContainer = Instance.new("Frame", ArenaFrame); HeaderContainer.Size = UDim2.new(1, 0, 0, 25); HeaderContainer.BackgroundTransparency = 1; HeaderContainer.LayoutOrder = 1
	HeaderText = Instance.new("TextLabel", HeaderContainer); HeaderText.Size = UDim2.new(1, 0, 1, 0); HeaderText.BackgroundTransparency = 1; HeaderText.Font = Enum.Font.GothamBlack; HeaderText.TextColor3 = Color3.fromRGB(200, 50, 255); HeaderText.TextSize = 20; HeaderText.Text = "MULTIPLAYER RAID"; ApplyGradient(HeaderText, Color3.fromRGB(200, 100, 255), Color3.fromRGB(150, 40, 200))
	local TimerBG = Instance.new("Frame", HeaderContainer); TimerBG.Size = UDim2.new(1, -40, 0, 6); TimerBG.Position = UDim2.new(0, 20, 1, 0); TimerBG.BackgroundColor3 = Color3.fromRGB(30, 30, 35); Instance.new("UICorner", TimerBG).CornerRadius = UDim.new(1, 0)
	TimerBar = Instance.new("Frame", TimerBG); TimerBar.Size = UDim2.new(1, 0, 1, 0); TimerBar.BackgroundColor3 = Color3.fromRGB(46, 204, 113); Instance.new("UICorner", TimerBar).CornerRadius = UDim.new(1, 0)

	local CombatantsFrame = Instance.new("Frame", ArenaFrame); CombatantsFrame.Size = UDim2.new(0.96, 0, 0, 180); CombatantsFrame.BackgroundTransparency = 1; CombatantsFrame.LayoutOrder = 2

	PartyListFrame = Instance.new("Frame", CombatantsFrame); PartyListFrame.Size = UDim2.new(0.48, 0, 1, 0); PartyListFrame.BackgroundTransparency = 1
	local pLayout = Instance.new("UIListLayout", PartyListFrame); pLayout.Padding = UDim.new(0, 5)

	local vsLbl = Instance.new("TextLabel", CombatantsFrame); vsLbl.Size = UDim2.new(0.04, 0, 1, 0); vsLbl.Position = UDim2.new(0.48, 0, 0, 0); vsLbl.BackgroundTransparency = 1; vsLbl.Font = Enum.Font.GothamBlack; vsLbl.TextColor3 = Color3.fromRGB(100, 100, 110); vsLbl.TextSize = 24; vsLbl.Text = "VS"

	BossFrame = Instance.new("Frame", CombatantsFrame); BossFrame.Size = UDim2.new(0.48, 0, 1, 0); BossFrame.Position = UDim2.new(0.52, 0, 0, 0); BossFrame.BackgroundTransparency = 1

	eAvatarBox = Instance.new("Frame", BossFrame); eAvatarBox.Size = UDim2.new(0, 120, 0, 120); eAvatarBox.Position = UDim2.new(1, -10, 0.5, 0); eAvatarBox.AnchorPoint = Vector2.new(1, 0.5); eAvatarBox.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	Instance.new("UIStroke", eAvatarBox).Color = Color3.fromRGB(255, 100, 100); Instance.new("UIStroke", eAvatarBox).Thickness = 2; Instance.new("UIStroke", eAvatarBox).LineJoinMode = Enum.LineJoinMode.Miter
	eAvatarIcon = Instance.new("TextLabel", eAvatarBox); eAvatarIcon.Size = UDim2.new(1, 0, 1, 0); eAvatarIcon.BackgroundTransparency = 1; eAvatarIcon.Font = Enum.Font.GothamBlack; eAvatarIcon.TextColor3 = Color3.fromRGB(200, 50, 50); eAvatarIcon.TextScaled = true; eAvatarIcon.Text = "?"

	local eStatsArea = Instance.new("Frame", BossFrame); eStatsArea.Size = UDim2.new(1, -140, 1, 0); eStatsArea.BackgroundTransparency = 1; local eStatsLayout = Instance.new("UIListLayout", eStatsArea); eStatsLayout.SortOrder = Enum.SortOrder.LayoutOrder; eStatsLayout.Padding = UDim.new(0, 4); eStatsLayout.VerticalAlignment = Enum.VerticalAlignment.Center; eStatsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

	BossNameText = Instance.new("TextLabel", eStatsArea); BossNameText.Size = UDim2.new(1, 0, 0, 20); BossNameText.BackgroundTransparency = 1; BossNameText.Font = Enum.Font.GothamBlack; BossNameText.TextColor3 = Color3.fromRGB(255, 120, 120); BossNameText.TextSize = 18; BossNameText.TextScaled = true; BossNameText.TextXAlignment = Enum.TextXAlignment.Right

	local eHpCont
	BossHPBar, BossHPText, eHpCont = CreateBar(eStatsArea, Color3.fromRGB(220, 60, 60), Color3.fromRGB(140, 30, 30), UDim2.new(1, 0, 0, 20), "HP: 100", true)
	BossHPText.TextSize = 14
	BossShieldBar = Instance.new("Frame", eHpCont); BossShieldBar.Size = UDim2.new(0, 0, 1, 0); BossShieldBar.AnchorPoint = Vector2.new(1,0); BossShieldBar.Position = UDim2.new(1,0,0,0); BossShieldBar.BackgroundColor3 = Color3.fromRGB(220, 230, 240); Instance.new("UICorner", BossShieldBar).CornerRadius = UDim.new(0, 4); BossShieldBar.ZIndex = 5; BossHPText.ZIndex = 6

	BossStatusBox = Instance.new("Frame", eStatsArea); BossStatusBox.Size = UDim2.new(1, 0, 0, 20); BossStatusBox.BackgroundTransparency = 1; local bStatusLayout = Instance.new("UIListLayout", BossStatusBox); bStatusLayout.FillDirection = Enum.FillDirection.Horizontal; bStatusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; bStatusLayout.Padding = UDim.new(0, 4)

	local FeedBox = Instance.new("Frame", ArenaFrame); FeedBox.Size = UDim2.new(0.96, 0, 0, 100); FeedBox.BackgroundColor3 = Color3.fromRGB(22, 22, 26); FeedBox.ClipsDescendants = true; FeedBox.LayoutOrder = 3
	Instance.new("UICorner", FeedBox).CornerRadius = UDim.new(0, 6); local fbStroke = Instance.new("UIStroke", FeedBox); fbStroke.Color = Color3.fromRGB(60, 60, 70); fbStroke.Thickness = 1; fbStroke.LineJoinMode = Enum.LineJoinMode.Miter
	LogText = Instance.new("TextLabel", FeedBox); LogText.Size = UDim2.new(1, -20, 1, -10); LogText.Position = UDim2.new(0, 10, 0, 5); LogText.BackgroundTransparency = 1; LogText.Font = Enum.Font.GothamMedium; LogText.TextColor3 = Color3.fromRGB(230, 230, 230); LogText.TextSize = 14; LogText.TextXAlignment = Enum.TextXAlignment.Left; LogText.TextYAlignment = Enum.TextYAlignment.Bottom; LogText.TextWrapped = true; LogText.RichText = true; LogText.Text = ""

	local BottomArea = Instance.new("Frame", ArenaFrame); BottomArea.Size = UDim2.new(0.96, 0, 0, 180); BottomArea.BackgroundTransparency = 1; BottomArea.LayoutOrder = 4

	ActionGrid = Instance.new("ScrollingFrame", BottomArea); ActionGrid.Size = UDim2.new(1, 0, 1, 0); ActionGrid.BackgroundTransparency = 1; ActionGrid.ScrollBarThickness = 0; ActionGrid.BorderSizePixel = 0
	local gridLayout = Instance.new("UIGridLayout", ActionGrid); gridLayout.CellSize = UDim2.new(0, 170, 0, 45); gridLayout.CellPadding = UDim2.new(0, 8, 0, 12); gridLayout.SortOrder = Enum.SortOrder.LayoutOrder; gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	TargetMenu = Instance.new("Frame", BottomArea); TargetMenu.Size = UDim2.new(1, 0, 1, -10); TargetMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 25); TargetMenu.Visible = false
	Instance.new("UICorner", TargetMenu).CornerRadius = UDim.new(0, 6); Instance.new("UIStroke", TargetMenu).Color = Color3.fromRGB(80, 80, 90)

	local InfoPanel = Instance.new("Frame", TargetMenu); InfoPanel.Size = UDim2.new(0.45, 0, 1, 0); InfoPanel.BackgroundTransparency = 1
	local tHoverTitle = Instance.new("TextLabel", InfoPanel); tHoverTitle.Size = UDim2.new(1, -20, 0, 30); tHoverTitle.Position = UDim2.new(0, 20, 0, 15); tHoverTitle.BackgroundTransparency = 1; tHoverTitle.Font = Enum.Font.GothamBlack; tHoverTitle.TextColor3 = Color3.fromRGB(255, 215, 100); tHoverTitle.TextSize = 20; tHoverTitle.TextXAlignment = Enum.TextXAlignment.Left; tHoverTitle.Text = "SELECT TARGET"; ApplyGradient(tHoverTitle, Color3.fromRGB(255, 215, 100), Color3.fromRGB(255, 150, 50))
	local tHoverDesc = Instance.new("TextLabel", InfoPanel); tHoverDesc.Size = UDim2.new(1, -20, 0, 100); tHoverDesc.Position = UDim2.new(0, 20, 0, 60); tHoverDesc.BackgroundTransparency = 1; tHoverDesc.Font = Enum.Font.GothamMedium; tHoverDesc.TextColor3 = Color3.fromRGB(200, 200, 200); tHoverDesc.TextSize = 13; tHoverDesc.TextXAlignment = Enum.TextXAlignment.Left; tHoverDesc.TextYAlignment = Enum.TextYAlignment.Top; tHoverDesc.TextWrapped = true; tHoverDesc.Text = "Hover over a limb to see its tactical advantage."

	local CancelBtn = Instance.new("TextButton", InfoPanel); CancelBtn.Size = UDim2.new(0.7, 0, 0, 40); CancelBtn.Position = UDim2.new(0, 20, 1, -55); CancelBtn.Font = Enum.Font.GothamBlack; CancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CancelBtn.TextSize = 14; CancelBtn.Text = "CANCEL"
	ApplyButtonGradient(CancelBtn, Color3.fromRGB(160, 60, 60), Color3.fromRGB(100, 30, 30), Color3.fromRGB(60, 20, 20))
	CancelBtn.MouseButton1Click:Connect(function() TargetMenu.Visible = false; ActionGrid.Visible = true; pendingSkillName = nil end)

	local BodyContainer = Instance.new("Frame", TargetMenu); BodyContainer.Size = UDim2.new(0.5, 0, 1, -20); BodyContainer.Position = UDim2.new(0.5, 0, 0, 10); BodyContainer.BackgroundTransparency = 1

	local function CreateLimb(name, size, pos, hoverText, baseColor)
		local limb = Instance.new("TextButton", BodyContainer); limb.Size = size; limb.Position = pos; limb.Text = name:upper(); limb.Font = Enum.Font.GothamBlack; limb.TextColor3 = Color3.fromRGB(255, 255, 255); limb.TextSize = 12
		local mTop = Color3.new(math.clamp(baseColor.R * 0.6, 0, 1), math.clamp(baseColor.G * 0.6, 0, 1), math.clamp(baseColor.B * 0.6, 0, 1))
		local mBot = Color3.new(math.clamp(baseColor.R * 0.3, 0, 1), math.clamp(baseColor.G * 0.3, 0, 1), math.clamp(baseColor.B * 0.3, 0, 1))
		ApplyButtonGradient(limb, mTop, mBot, baseColor)

		limb.MouseEnter:Connect(function()
			local hTop = Color3.new(math.clamp(baseColor.R * 1.2, 0, 1), math.clamp(baseColor.G * 1.2, 0, 1), math.clamp(baseColor.B * 1.2, 0, 1))
			local hBot = Color3.new(math.clamp(baseColor.R * 0.8, 0, 1), math.clamp(baseColor.G * 0.8, 0, 1), math.clamp(baseColor.B * 0.8, 0, 1))
			ApplyButtonGradient(limb, hTop, hBot, baseColor)
			tHoverTitle.Text = name:upper(); tHoverTitle.TextColor3 = baseColor
			local grad = tHoverTitle:FindFirstChildOfClass("UIGradient"); if grad then grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, hTop), ColorSequenceKeypoint.new(1, hBot)} end
			tHoverDesc.Text = hoverText
		end)

		limb.MouseLeave:Connect(function()
			ApplyButtonGradient(limb, mTop, mBot, baseColor)
			tHoverTitle.Text = "SELECT TARGET"; tHoverTitle.TextColor3 = Color3.fromRGB(255, 215, 100)
			local grad = tHoverTitle:FindFirstChildOfClass("UIGradient"); if grad then grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 100)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 50))} end
			tHoverDesc.Text = "Hover over a limb to see its tactical advantage."
		end)

		limb.MouseButton1Click:Connect(function()
			if pendingSkillName and not inputLocked then
				EffectsManager.PlaySFX("Click")
				LockGridAndWait()
				Network.RaidAction:FireServer("SubmitMove", { RaidId = currentRaidId, Move = pendingSkillName, Limb = name })
			end
		end)
	end

	local aspect = Instance.new("UIAspectRatioConstraint", BodyContainer); aspect.AspectRatio = 0.8
	CreateLimb("Eyes", UDim2.new(0.24, 0, 0.18, 0), UDim2.new(0.5, 0, 0.08, 0), "Deals 20% Damage. Inflicts Weakness.", Color3.fromRGB(120, 120, 180))
	CreateLimb("Nape", UDim2.new(0.24, 0, 0.06, 0), UDim2.new(0.5, 0, 0.22, 0), "Deals 150% Damage. Low accuracy.", Color3.fromRGB(220, 80, 80))
	CreateLimb("Body", UDim2.new(0.48, 0, 0.38, 0), UDim2.new(0.5, 0, 0.45, 0), "Deals 100% Damage. Standard accuracy.", Color3.fromRGB(80, 160, 80))
	CreateLimb("Arms", UDim2.new(0.22, 0, 0.38, 0), UDim2.new(0.14, 0, 0.45, 0), "Deals 50% Damage. Inflicts Weakened.", Color3.fromRGB(180, 140, 60))
	CreateLimb("Arms", UDim2.new(0.22, 0, 0.38, 0), UDim2.new(0.86, 0, 0.45, 0), "Deals 50% Damage. Inflicts Weakened.", Color3.fromRGB(180, 140, 60))
	CreateLimb("Legs", UDim2.new(0.23, 0, 0.32, 0), UDim2.new(0.37, 0, 0.81, 0), "Deals 50% Damage. Inflicts Crippled.", Color3.fromRGB(80, 140, 180))
	CreateLimb("Legs", UDim2.new(0.23, 0, 0.32, 0), UDim2.new(0.63, 0, 0.81, 0), "Deals 50% Damage. Inflicts Crippled.", Color3.fromRGB(80, 140, 180))
	for _, child in ipairs(BodyContainer:GetChildren()) do if child:IsA("TextButton") then child.AnchorPoint = Vector2.new(0.5, 0.5) end end

	LeaveBtn = Instance.new("TextButton", ArenaFrame); LeaveBtn.Size = UDim2.new(0.6, 0, 0, 45); LeaveBtn.LayoutOrder = 5; LeaveBtn.Font = Enum.Font.GothamBlack; LeaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255); LeaveBtn.TextSize = 16; LeaveBtn.Text = "LEAVE ARENA"; LeaveBtn.Visible = false
	ApplyButtonGradient(LeaveBtn, Color3.fromRGB(80, 180, 80), Color3.fromRGB(40, 100, 40), Color3.fromRGB(20, 80, 20))

	LeaveBtn.MouseButton1Click:Connect(function()
		EffectsManager.PlaySFX("Click")
		ArenaFrame.Visible = false; parentFrame.Visible = true 
		local topGui = parentFrame:FindFirstAncestorOfClass("ScreenGui")
		if topGui then
			if topGui:FindFirstChild("TopBar") then topGui.TopBar.Visible = true end
			if topGui:FindFirstChild("NavBar") then topGui.NavBar.Visible = true end
		end
	end)

	local function RenderParty(partyData)
		if not partyData then return end
		for _, child in ipairs(PartyListFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
		PartyUIBars = {}

		for _, mem in ipairs(partyData) do
			local mFr = Instance.new("Frame", PartyListFrame)
			mFr.Size = UDim2.new(1, 0, 0, 56)
			mFr.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
			Instance.new("UICorner", mFr).CornerRadius = UDim.new(0, 6)

			local strokeColor = (mem.UserId == player.UserId) and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 70)
			local stroke = Instance.new("UIStroke", mFr); stroke.Color = strokeColor; stroke.Thickness = 1

			local avatarBg = Instance.new("Frame", mFr)
			avatarBg.Size = UDim2.new(0, 46, 0, 46); avatarBg.Position = UDim2.new(0, 5, 0, 5); avatarBg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
			Instance.new("UICorner", avatarBg).CornerRadius = UDim.new(0, 6)

			local avatar = Instance.new("ImageLabel", avatarBg)
			avatar.Size = UDim2.new(1, 0, 1, 0); avatar.BackgroundTransparency = 1
			if mem.UserId > 0 then avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. mem.UserId .. "&w=150&h=150"
			else avatar.Image = "rbxassetid://132795247" end 
			Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 6)

			local nLbl = Instance.new("TextLabel", mFr)
			nLbl.Size = UDim2.new(1, -65, 0, 16); nLbl.Position = UDim2.new(0, 60, 0, 4); nLbl.BackgroundTransparency = 1
			nLbl.Font = Enum.Font.GothamBold; nLbl.TextColor3 = (mem.UserId == player.UserId) and Color3.fromRGB(150, 200, 255) or Color3.new(1,1,1)
			nLbl.TextXAlignment = Enum.TextXAlignment.Left; nLbl.TextSize = 14; nLbl.Text = string.upper(mem.Name)

			local hpBg = Instance.new("Frame", mFr)
			hpBg.Size = UDim2.new(1, -65, 0, 14); hpBg.Position = UDim2.new(0, 60, 0, 22); hpBg.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
			Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 4)

			local hpBar = Instance.new("Frame", hpBg)
			hpBar.Size = UDim2.new(math.clamp(mem.HP/mem.MaxHP, 0, 1), 0, 1, 0); hpBar.BackgroundColor3 = Color3.new(1,1,1)
			ApplyGradient(hpBar, Color3.fromRGB(80, 220, 80), Color3.fromRGB(40, 140, 40))
			Instance.new("UICorner", hpBar).CornerRadius = UDim.new(0, 4)

			local hpTxt = Instance.new("TextLabel", hpBg)
			hpTxt.Size = UDim2.new(1, -6, 1, 0); hpTxt.Position = UDim2.new(0, 6, 0, 0); hpTxt.BackgroundTransparency = 1
			hpTxt.Font = Enum.Font.GothamBold; hpTxt.TextColor3 = Color3.new(1,1,1); hpTxt.TextSize = 10; hpTxt.TextXAlignment = Enum.TextXAlignment.Left
			hpTxt.TextStrokeTransparency = 0.5; hpTxt.Text = math.floor(mem.HP) .. " / " .. math.floor(mem.MaxHP)

			local statusBox = Instance.new("Frame", mFr)
			statusBox.Size = UDim2.new(1, -65, 0, 14); statusBox.Position = UDim2.new(0, 60, 0, 38); statusBox.BackgroundTransparency = 1
			local sLayout = Instance.new("UIListLayout", statusBox); sLayout.FillDirection = Enum.FillDirection.Horizontal; sLayout.Padding = UDim.new(0, 4)

			RenderStatuses(statusBox, mem.Statuses)
		end
	end

	local function SyncBoss(bossData)
		if not bossData then return end
		BossNameText.Text = bossData.Name:upper()

		if bossData.MaxGateHP and bossData.MaxGateHP > 0 then
			BossShieldBar.Visible = true
			TweenService:Create(BossShieldBar, TweenInfo.new(0.4), {Size = UDim2.new(math.clamp(bossData.GateHP / bossData.MaxGateHP, 0, 1), 0, 1, 0)}):Play()
			if bossData.GateHP > 0 then
				if bossData.GateType == "Steam" then BossHPText.Text = bossData.GateType:upper() .. ": " .. math.floor(bossData.GateHP) .. " TURNS LEFT"
				else BossHPText.Text = bossData.GateType:upper() .. ": " .. math.floor(bossData.GateHP) .. " / " .. math.floor(bossData.MaxGateHP) end
			else BossHPText.Text = "HP: " .. math.floor(bossData.HP) .. " / " .. math.floor(bossData.MaxHP) end
		else
			BossShieldBar.Visible = false
			BossHPText.Text = "HP: " .. math.floor(bossData.HP) .. " / " .. math.floor(bossData.MaxHP)
		end

		TweenService:Create(BossHPBar, TweenInfo.new(0.4), {Size = UDim2.new(math.clamp(bossData.HP / bossData.MaxHP, 0, 1), 0, 1, 0)}):Play()
		RenderStatuses(BossStatusBox, bossData.Statuses)
	end

	local function UpdateActionGrid(partyData)
		inputLocked = false

		for _, child in ipairs(ActionGrid:GetChildren()) do 
			if child:IsA("TextButton") then child.Visible = false end 
		end

		local myData = nil
		for _, p in ipairs(partyData) do if p.UserId == player.UserId then myData = p; break end end
		if not myData or myData.HP <= 0 then return end 

		local eqWpn = player:GetAttribute("EquippedWeapon") or "None"
		local pStyle = (ItemData.Equipment[eqWpn] and ItemData.Equipment[eqWpn].Style) or "None"
		local pTitan = player:GetAttribute("Titan") or "None"
		local pClan = player:GetAttribute("Clan") or "None"
		local isTransformed = myData.Statuses and myData.Statuses["Transformed"]
		local isODM = (pStyle == "Ultrahard Steel Blades" or pStyle == "Thunder Spears" or pStyle == "Anti-Personnel")

		local function CreateBtn(sName, color, order)
			local sData = SkillData.Skills[sName]
			if not sData then return end
			if sName == "Transform" and (pClan == "Ackerman" or pClan == "Awakened Ackerman") then return end

			local cd = myData.Cooldowns and myData.Cooldowns[sName] or 0
			local energyCost = sData.EnergyCost or 0
			local gasCost = sData.GasCost or 0
			local hasGas = (myData.Gas or 0) >= gasCost
			local hasEnergy = (myData.TitanEnergy or 0) >= energyCost
			local isReady = (cd == 0) and hasGas and hasEnergy

			local btn = ActionGrid:FindFirstChild("Btn_" .. sName)
			if not btn then
				btn = Instance.new("TextButton", ActionGrid)
				btn.Name = "Btn_" .. sName
				btn.RichText = true; btn.Font = Enum.Font.GothamBold; btn.TextSize = 12

				btn.MouseButton1Click:Connect(function()
					local currentMyData
					for _, p in ipairs(partyData) do if p.UserId == player.UserId then currentMyData = p; break end end
					local c_cd = currentMyData and currentMyData.Cooldowns and currentMyData.Cooldowns[sName] or 0
					local c_ready = (c_cd == 0) and ((currentMyData and currentMyData.Gas or 0) >= gasCost)

					if not inputLocked and c_ready then
						EffectsManager.PlaySFX("Click")
						if sName == "Retreat" or sName == "Fall Back" or sName == "Close In" or sData.Effect == "Rest" or sData.Effect == "TitanRest" or sData.Effect == "Eject" or sData.Effect == "Transform" or sData.Effect == "Block" then
							if cachedTooltipMgr then cachedTooltipMgr.Hide() end
							LockGridAndWait()
							Network.RaidAction:FireServer("SubmitMove", { RaidId = currentRaidId, Move = sName, Limb = "Body" })
						else
							if cachedTooltipMgr then cachedTooltipMgr.Hide() end
							pendingSkillName = sName
							ActionGrid.Visible = false
							TargetMenu.Visible = true
						end
					end
				end)

				btn.MouseEnter:Connect(function() if cachedTooltipMgr then cachedTooltipMgr.Show(sData.Description or sName) end end)
				btn.MouseLeave:Connect(function() if cachedTooltipMgr then cachedTooltipMgr.Hide() end end)
			end

			btn.Visible = true
			btn.LayoutOrder = order or 10

			if isReady then
				ApplyButtonGradient(btn, color, Color3.new(color.R*0.7, color.G*0.7, color.B*0.7), color)
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				ApplyButtonGradient(btn, Color3.fromRGB(25, 20, 30), Color3.fromRGB(15, 10, 20), Color3.fromRGB(40, 30, 50))
				btn.TextColor3 = Color3.fromRGB(120, 120, 120)
			end

			local cdStr = isReady and "READY" or "CD: " .. cd
			if cd == 0 then if not hasGas then cdStr = "NO GAS" elseif not hasEnergy then cdStr = "NO HEAT" end end

			btn.Text = sName:upper() .. "\n<font size='10' color='" .. (isReady and "#CCCCCC" or "#FF5555") .. "'>[" .. cdStr .. "]</font>"
		end

		if isTransformed then
			CreateBtn("Titan Recover", Color3.fromRGB(40, 140, 80), 1); CreateBtn("Titan Punch", Color3.fromRGB(120, 40, 40), 2); CreateBtn("Titan Kick", Color3.fromRGB(140, 60, 40), 3); CreateBtn("Eject", Color3.fromRGB(140, 40, 40), 4)
			local orderIndex = 5
			for sName, sData in pairs(SkillData.Skills) do
				if sData.Requirement == pTitan or sData.Requirement == "AnyTitan" or sData.Requirement == "Transformed" then
					if sName ~= "Titan Recover" and sName ~= "Eject" and sName ~= "Titan Punch" and sName ~= "Titan Kick" and sName ~= "Transform" then
						CreateBtn(sName, Color3.fromRGB(60, 40, 60), sData.Order or orderIndex); orderIndex += 1
					end
				end
			end
		else
			CreateBtn("Basic Slash", Color3.fromRGB(120, 40, 40), 1)
			CreateBtn("Maneuver", Color3.fromRGB(40, 80, 140), 2)

			if currentRange == "Long" then
				CreateBtn("Close In", Color3.fromRGB(80, 140, 100), 3)
			else
				CreateBtn("Fall Back", Color3.fromRGB(80, 100, 140), 3)
			end

			CreateBtn("Recover", Color3.fromRGB(40, 140, 80), 4)
			CreateBtn("Retreat", Color3.fromRGB(60, 60, 70), 5)

			if pTitan ~= "None" and pClan ~= "Ackerman" and pClan ~= "Awakened Ackerman" then CreateBtn("Transform", Color3.fromRGB(200, 150, 50), 6) end

			local orderIndex = 7
			for sName, sData in pairs(SkillData.Skills) do
				if sName == "Basic Slash" or sName == "Maneuver" or sName == "Recover" or sName == "Transform" or sName == "Close In" or sName == "Fall Back" or sName == "Retreat" then continue end

				local req = sData.Requirement
				if req == pStyle or req == pClan or (req == "Ackerman" and pClan == "Awakened Ackerman") or (req == "ODM" and isODM) then
					CreateBtn(sName, Color3.fromRGB(45, 40, 60), sData.Order or orderIndex); orderIndex += 1
				end
			end
		end
	end

	Network:WaitForChild("RaidUpdate").OnClientEvent:Connect(function(action, data)
		local safeParty = nil
		local safeBoss = nil
		if type(data) == "table" then
			safeParty = data.PartyData or data.Party
			safeBoss = data.BossData or data.Boss
		end

		if action == "RaidStarted" then
			currentRaidId = data.RaidId; logMessages = {}
			currentRange = data.Range or "Close" 

			local topGui = parentFrame:FindFirstAncestorOfClass("ScreenGui")
			if topGui then
				if topGui:FindFirstChild("TopBar") then topGui.TopBar.Visible = false end
				if topGui:FindFirstChild("NavBar") then topGui.NavBar.Visible = false end
			end

			parentFrame.Visible = false; ArenaFrame.Visible = true; LeaveBtn.Visible = false; TargetMenu.Visible = false; ActionGrid.Visible = true
			AddLogMessage("<font color='#FFD700'><b>RAID COMMENCES! STAY ALIVE!</b></font>", false)

			SyncBoss(safeBoss)
			RenderParty(safeParty)
			UpdateActionGrid(safeParty)
			StartVisualTimer(data.EndTime)

		elseif action == "TurnStrike" then
			ShakeUI(data.ShakeType); AddLogMessage(data.LogMsg, true)
			if data.Range then currentRange = data.Range end

			if data.SkillUsed then 
				local attackerIsLeft = false
				if data.Attacker ~= BossNameText.Text then attackerIsLeft = true end
				EffectsManager.PlayCombatEffect(data.SkillUsed, attackerIsLeft, nil, eAvatarBox, true) 
			end

			if safeParty then RenderParty(safeParty) end
			if safeBoss then SyncBoss(safeBoss) end

		elseif action == "NextTurnStarted" then
			StartVisualTimer(data.EndTime)
			if data.Range then currentRange = data.Range end

			if safeBoss then SyncBoss(safeBoss) end

			local myData = nil
			if safeParty then
				for _, p in ipairs(safeParty) do 
					if p.UserId == player.UserId then myData = p; break end 
				end
			end

			if myData and myData.HP <= 0 then 
				inputLocked = true
				for _, child in ipairs(ActionGrid:GetChildren()) do if child:IsA("TextButton") then child.Visible = false end end
				AddLogMessage("<font color='#FF5555'>You have fallen in battle. Spectating party...</font>", true)
			elseif safeParty then
				UpdateActionGrid(safeParty)
			end

		elseif action == "RaidEnded" then
			if data == true then EffectsManager.PlaySFX("Victory", 1) else EffectsManager.PlaySFX("Defeat", 1) end
			AddLogMessage("<font color='#FF5555'><b>RAID CONCLUDED.</b></font>", true)
			ActionGrid.Visible = false
			LeaveBtn.Visible = true
		end
	end)
end

return RaidTab