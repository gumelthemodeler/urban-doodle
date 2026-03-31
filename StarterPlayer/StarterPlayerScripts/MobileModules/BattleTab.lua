-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local BattleTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")

local player = Players.LocalPlayer
local MainFrame, TopNav, ContentArea
local SubTabs, SubBtns = {}, {}
local ModesCarousel
local TransitionOverlay, TransitionText

local function PlayTransition(text, callback)
	if TransitionOverlay.Visible then return end
	TransitionOverlay.Visible = true
	TransitionText.Text = text

	local tIn = TweenService:Create(TransitionOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 0})
	local ttIn = TweenService:Create(TransitionText, TweenInfo.new(0.4), {TextTransparency = 0})
	tIn:Play(); ttIn:Play()

	tIn.Completed:Connect(function()
		-- Fire the server remote while the screen is black
		callback()
		task.wait(0.6) -- Give the server time to load the arena

		local tOut = TweenService:Create(TransitionOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 1})
		local ttOut = TweenService:Create(TransitionText, TweenInfo.new(0.5), {TextTransparency = 1})
		tOut:Play(); ttOut:Play()

		tOut.Completed:Connect(function() TransitionOverlay.Visible = false end)
	end)
end

function BattleTab.Init(parentFrame)
	-- [[ 0. TRANSITION OVERLAY ]]
	TransitionOverlay = Instance.new("Frame", parentFrame.Parent)
	TransitionOverlay.Name = "BattleTransition"
	TransitionOverlay.Size = UDim2.new(1, 0, 1, 0)
	TransitionOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	TransitionOverlay.BackgroundTransparency = 1
	TransitionOverlay.ZIndex = 1000
	TransitionOverlay.Visible = false

	TransitionText = Instance.new("TextLabel", TransitionOverlay)
	TransitionText.Size = UDim2.new(1, 0, 0, 50)
	TransitionText.Position = UDim2.new(0, 0, 0.5, -25)
	TransitionText.BackgroundTransparency = 1
	TransitionText.Font = Enum.Font.GothamBlack
	TransitionText.TextColor3 = Color3.fromRGB(255, 215, 100)
	TransitionText.TextSize = 22
	TransitionText.TextTransparency = 1

	-- [[ 1. MAIN FRAME & NAVIGATION ]]
	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Name = "BattleFrame"
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.BackgroundTransparency = 1
	MainFrame.Visible = false

	TopNav = Instance.new("Frame", MainFrame)
	TopNav.Size = UDim2.new(1, 0, 0, 50)
	TopNav.BackgroundTransparency = 1
	local navLayout = Instance.new("UIListLayout", TopNav)
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Padding = UDim.new(0, 15)

	ContentArea = Instance.new("Frame", MainFrame)
	ContentArea.Size = UDim2.new(1, 0, 1, -50)
	ContentArea.Position = UDim2.new(0, 0, 0, 50)
	ContentArea.BackgroundTransparency = 1

	local function CreateSubNavBtn(name, text)
		local btn = Instance.new("TextButton", TopNav)
		btn.Size = UDim2.new(0, 150, 0, 36)
		btn.Font = Enum.Font.GothamBlack
		btn.TextColor3 = Color3.fromRGB(150, 150, 150)
		btn.TextSize = 14
		btn.Text = text
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			for k, v in pairs(SubBtns) do 
				v.TextColor3 = Color3.fromRGB(150, 150, 150)
				v.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			end
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)

			for k, frame in pairs(SubTabs) do frame.Visible = (k == name) end
		end)
		SubBtns[name] = btn
		return btn
	end

	CreateSubNavBtn("Campaign", "CAMPAIGN")
	CreateSubNavBtn("Modes", "MODES")

	-- ==========================================
	-- [[ 2. CAMPAIGN TAB (Linear Story) ]]
	-- ==========================================
	SubTabs["Campaign"] = Instance.new("ScrollingFrame", ContentArea)
	SubTabs["Campaign"].Size = UDim2.new(1, 0, 1, 0)
	SubTabs["Campaign"].BackgroundTransparency = 1
	SubTabs["Campaign"].ScrollBarThickness = 0
	SubTabs["Campaign"].Visible = true

	local CampContainer = Instance.new("Frame", SubTabs["Campaign"])
	CampContainer.Size = UDim2.new(0.95, 0, 0, 350)
	CampContainer.Position = UDim2.new(0.025, 0, 0, 20)
	CampContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Instance.new("UICorner", CampContainer).CornerRadius = UDim.new(0, 12)
	Instance.new("UIStroke", CampContainer).Color = Color3.fromRGB(60, 60, 70)

	local CampImage = Instance.new("ImageLabel", CampContainer)
	CampImage.Size = UDim2.new(1, 0, 0.5, 0)
	CampImage.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	CampImage.Image = "rbxassetid://0" 
	Instance.new("UICorner", CampImage).CornerRadius = UDim.new(0, 12)

	local CampTitle = Instance.new("TextLabel", CampContainer)
	CampTitle.Size = UDim2.new(1, -30, 0, 30)
	CampTitle.Position = UDim2.new(0, 15, 0.5, 15)
	CampTitle.BackgroundTransparency = 1
	CampTitle.Font = Enum.Font.GothamBlack
	CampTitle.TextSize = 22
	CampTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	CampTitle.TextXAlignment = Enum.TextXAlignment.Left
	CampTitle.Text = "CONTINUE STORY"

	local CampDesc = Instance.new("TextLabel", CampContainer)
	CampDesc.Size = UDim2.new(1, -30, 0, 50)
	CampDesc.Position = UDim2.new(0, 15, 0.5, 45)
	CampDesc.BackgroundTransparency = 1
	CampDesc.Font = Enum.Font.GothamMedium
	CampDesc.TextSize = 14
	CampDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
	CampDesc.TextXAlignment = Enum.TextXAlignment.Left
	CampDesc.TextYAlignment = Enum.TextYAlignment.Top
	CampDesc.TextWrapped = true
	CampDesc.Text = "Pick up right where you left off. The fate of the walls depends on your next move."

	local PlayCampBtn = Instance.new("TextButton", CampContainer)
	PlayCampBtn.Size = UDim2.new(0.9, 0, 0, 50)
	PlayCampBtn.Position = UDim2.new(0.5, 0, 1, -15)
	PlayCampBtn.AnchorPoint = Vector2.new(0.5, 1)
	PlayCampBtn.Font = Enum.Font.GothamBlack
	PlayCampBtn.TextSize = 20
	PlayCampBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	PlayCampBtn.Text = "DEPLOY"
	PlayCampBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
	Instance.new("UICorner", PlayCampBtn).CornerRadius = UDim.new(0, 6)

	PlayCampBtn.MouseButton1Click:Connect(function()
		PlayTransition("DEPLOYING TO STORY...", function()
			Network:WaitForChild("CombatAction"):FireServer("EngageStory")
		end)
	end)

	player.AttributeChanged:Connect(function(attr)
		if attr == "CurrentPart" then
			local chapter = player:GetAttribute("CurrentPart") or 1
			CampTitle.Text = "CHAPTER " .. chapter .. ": CONTINUE STORY"
		end
	end)

	-- ==========================================
	-- [[ 3. GAME MODES TAB (Valorant Style Cards) ]]
	-- ==========================================
	SubTabs["Modes"] = Instance.new("Frame", ContentArea)
	SubTabs["Modes"].Size = UDim2.new(1, 0, 1, 0)
	SubTabs["Modes"].BackgroundTransparency = 1
	SubTabs["Modes"].Visible = false

	ModesCarousel = Instance.new("ScrollingFrame", SubTabs["Modes"])
	ModesCarousel.Size = UDim2.new(1, 0, 1, -20)
	ModesCarousel.Position = UDim2.new(0, 0, 0, 10)
	ModesCarousel.BackgroundTransparency = 1
	ModesCarousel.ScrollingDirection = Enum.ScrollingDirection.X
	ModesCarousel.ScrollBarThickness = 0

	local carouselLayout = Instance.new("UIListLayout", ModesCarousel)
	carouselLayout.FillDirection = Enum.FillDirection.Horizontal
	carouselLayout.SortOrder = Enum.SortOrder.LayoutOrder
	carouselLayout.Padding = UDim.new(0, 20)
	carouselLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	carouselLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	local function CreateModeCard(name, desc, imgId, layoutOrder, transitionText, onClickFunc)
		local card = Instance.new("TextButton", ModesCarousel)
		card.Size = UDim2.new(0.6, 0, 0.85, 0)
		card.LayoutOrder = layoutOrder
		card.Text = ""
		card.AutoButtonColor = false
		card.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
		card.ClipsDescendants = true

		local aspect = Instance.new("UIAspectRatioConstraint", card)
		aspect.AspectRatio = 0.65 

		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
		local stroke = Instance.new("UIStroke", card)
		stroke.Color = Color3.fromRGB(60, 60, 70)
		stroke.Thickness = 2

		local bgImg = Instance.new("ImageLabel", card)
		bgImg.Size = UDim2.new(1, 0, 1, 0)
		bgImg.BackgroundTransparency = 1
		bgImg.Image = imgId
		bgImg.ScaleType = Enum.ScaleType.Crop

		local gradFrame = Instance.new("Frame", card)
		gradFrame.Size = UDim2.new(1, 0, 0.6, 0)
		gradFrame.Position = UDim2.new(0, 0, 0.4, 0)
		gradFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		gradFrame.BorderSizePixel = 0
		local grad = Instance.new("UIGradient", gradFrame)
		grad.Rotation = 90
		grad.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 0.2), NumberSequenceKeypoint.new(1, 0)}

		local title = Instance.new("TextLabel", card)
		title.Size = UDim2.new(1, -30, 0, 30)
		title.Position = UDim2.new(0, 15, 1, -80)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 22
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = name

		local descLbl = Instance.new("TextLabel", card)
		descLbl.Size = UDim2.new(1, -30, 0, 40)
		descLbl.Position = UDim2.new(0, 15, 1, -50)
		descLbl.BackgroundTransparency = 1
		descLbl.Font = Enum.Font.GothamBold
		descLbl.TextSize = 12
		descLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.TextYAlignment = Enum.TextYAlignment.Top
		descLbl.TextWrapped = true
		descLbl.Text = desc

		card.MouseButton1Click:Connect(function()
			PlayTransition(transitionText, onClickFunc)
		end)
	end

	CreateModeCard("NIGHTMARE HUNTS", "Face corrupted Titans to obtain legendary Cursed Weapons.", "rbxassetid://0", 1, "ENTERING NIGHTMARE HUNT...", function()
		Network:WaitForChild("DungeonAction"):FireServer("StartHunt")
	end)

	CreateModeCard("EXPEDITIONS", "Explore beyond the walls to scavenge vital resources.", "rbxassetid://0", 2, "DEPARTING ON EXPEDITION...", function()
		Network:WaitForChild("CombatAction"):FireServer("EngageEndless")
	end)

	CreateModeCard("THE PATHS", "Traverse the endless desert of Ymir to unlock stat points.", "rbxassetid://0", 3, "CONNECTING TO THE COORDINATE...", function()
		Network:WaitForChild("CombatAction"):FireServer("EngagePaths")
	end)

	CreateModeCard("PVP ARENA", "Test your ODM combat skills against other players.", "rbxassetid://0", 4, "QUEUEING FOR PVP ARENA...", function()
		Network:WaitForChild("PvPAction"):FireServer("JoinQueue")
	end)

	-- [[ MULTIPLAYER RAID (Wired to RaidManager) ]]
	CreateModeCard("MULTIPLAYER RAID", "Deploy your party to take down Colossal threats.", "rbxassetid://0", 5, "DEPLOYING PARTY TO RAID...", function()
		Network:WaitForChild("RaidAction"):FireServer("DeployParty", { RaidId = 1 })
	end)

	-- [[ WORLD BOSS (Wired to CombatManager) ]]
	CreateModeCard("WORLD BOSS", "A catastrophic threat has appeared. Intercept immediately.", "rbxassetid://0", 6, "ENGAGING WORLD BOSS...", function()
		Network:WaitForChild("CombatAction"):FireServer("EngageWorldBoss", { BossId = 1 })
	end)

	carouselLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ModesCarousel.CanvasSize = UDim2.new(0, carouselLayout.AbsoluteContentSize.X + 40, 0, 0)
	end)

	-- Init Defaults
	SubBtns["Campaign"].TextColor3 = Color3.fromRGB(255, 255, 255)
	SubBtns["Campaign"].BackgroundColor3 = Color3.fromRGB(80, 80, 90)
end

function BattleTab.Show()
	if MainFrame then MainFrame.Visible = true end
end

return BattleTab