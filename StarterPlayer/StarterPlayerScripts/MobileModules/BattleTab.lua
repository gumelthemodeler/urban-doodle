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
local ModesCarousel, LobbyFrame
local currentSelectedMode = ""

function BattleTab.Init(parentFrame)
	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Name = "BattleFrame"
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.BackgroundTransparency = 1
	MainFrame.Visible = false

	-- [[ 1. TOP NAVIGATION ]]
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

			if name == "Modes" and LobbyFrame then
				LobbyFrame.Visible = false
				ModesCarousel.Visible = true
			end
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
		if Network:FindFirstChild("StartCampaign") then
			Network.StartCampaign:FireServer()
		end
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

	-- [[ 3A. DYNAMIC LOBBY VIEW (Mobile) ]]
	LobbyFrame = Instance.new("Frame", SubTabs["Modes"])
	LobbyFrame.Size = UDim2.new(0.95, 0, 0.95, 0)
	LobbyFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	LobbyFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	LobbyFrame.BackgroundTransparency = 1
	LobbyFrame.Visible = false

	local BackBtn = Instance.new("TextButton", LobbyFrame)
	BackBtn.Size = UDim2.new(0, 120, 0, 30)
	BackBtn.Position = UDim2.new(0, 0, 0, 0)
	BackBtn.Font = Enum.Font.GothamBold
	BackBtn.TextSize = 12
	BackBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	BackBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	BackBtn.Text = "<- BACK"
	Instance.new("UICorner", BackBtn).CornerRadius = UDim.new(0, 6)

	BackBtn.MouseButton1Click:Connect(function()
		LobbyFrame.Visible = false
		ModesCarousel.Visible = true
	end)

	local LobbyImage = Instance.new("ImageLabel", LobbyFrame)
	LobbyImage.Size = UDim2.new(1, 0, 0.45, 0)
	LobbyImage.Position = UDim2.new(0, 0, 0, 45)
	LobbyImage.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	LobbyImage.ScaleType = Enum.ScaleType.Crop
	Instance.new("UICorner", LobbyImage).CornerRadius = UDim.new(0, 12)

	local LobbyTitle = Instance.new("TextLabel", LobbyFrame)
	LobbyTitle.Size = UDim2.new(1, 0, 0, 40)
	LobbyTitle.Position = UDim2.new(0, 0, 0.45, 55)
	LobbyTitle.BackgroundTransparency = 1
	LobbyTitle.Font = Enum.Font.GothamBlack
	LobbyTitle.TextSize = 28
	LobbyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	LobbyTitle.TextXAlignment = Enum.TextXAlignment.Left

	local LobbyDesc = Instance.new("TextLabel", LobbyFrame)
	LobbyDesc.Size = UDim2.new(1, 0, 0, 80)
	LobbyDesc.Position = UDim2.new(0, 0, 0.45, 95)
	LobbyDesc.BackgroundTransparency = 1
	LobbyDesc.Font = Enum.Font.GothamMedium
	LobbyDesc.TextSize = 14
	LobbyDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
	LobbyDesc.TextXAlignment = Enum.TextXAlignment.Left
	LobbyDesc.TextYAlignment = Enum.TextYAlignment.Top
	LobbyDesc.TextWrapped = true

	local MatchmakeBtn = Instance.new("TextButton", LobbyFrame)
	MatchmakeBtn.Size = UDim2.new(1, 0, 0, 60)
	MatchmakeBtn.Position = UDim2.new(0.5, 0, 1, 0)
	MatchmakeBtn.AnchorPoint = Vector2.new(0.5, 1)
	MatchmakeBtn.Font = Enum.Font.GothamBlack
	MatchmakeBtn.TextSize = 22
	MatchmakeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	MatchmakeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	Instance.new("UICorner", MatchmakeBtn).CornerRadius = UDim.new(0, 8)

	MatchmakeBtn.MouseButton1Click:Connect(function()
		if Network:FindFirstChild("JoinQueue") then
			Network.JoinQueue:FireServer(currentSelectedMode)
			MatchmakeBtn.Text = "SEARCHING..."
			MatchmakeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		else
			warn("CRITICAL: You must create a RemoteEvent named 'JoinQueue' inside ReplicatedStorage.Network!")
			MatchmakeBtn.Text = "ERROR"
		end
	end)

	-- [[ 3B. THE CAROUSEL ]]
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

	local function CreateModeCard(name, desc, imgId, layoutOrder, isLocked)
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

		if isLocked then
			bgImg.ImageColor3 = Color3.fromRGB(100, 100, 100)
			local lockIcon = Instance.new("ImageLabel", card)
			lockIcon.Size = UDim2.new(0, 40, 0, 40)
			lockIcon.Position = UDim2.new(0.5, -20, 0.5, -20)
			lockIcon.BackgroundTransparency = 1
			lockIcon.Image = "rbxassetid://3926305904"
			lockIcon.ImageRectOffset = Vector2.new(132, 204)
			lockIcon.ImageRectSize = Vector2.new(36, 36)
			title.TextColor3 = Color3.fromRGB(120, 120, 120)
		end

		card.MouseButton1Click:Connect(function()
			if isLocked then return end

			currentSelectedMode = name
			LobbyTitle.Text = name
			LobbyDesc.Text = desc
			LobbyImage.Image = imgId
			MatchmakeBtn.Text = "ENTER MATCHMAKING"
			MatchmakeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)

			ModesCarousel.Visible = false
			LobbyFrame.Visible = true
		end)
	end

	CreateModeCard("NIGHTMARE HUNTS", "Face corrupted Titans to obtain legendary Cursed Weapons.", "rbxassetid://0", 1, false)
	CreateModeCard("EXPEDITIONS", "Explore beyond the walls to scavenge vital resources.", "rbxassetid://0", 2, false)
	CreateModeCard("PVP ARENA", "Test your ODM combat skills against other players.", "rbxassetid://0", 3, false)
	CreateModeCard("RAIDS", "Team up with other regiments to take down Colossal threats.", "rbxassetid://0", 4, true)

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