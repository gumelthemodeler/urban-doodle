-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local PrestigeTab = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

local player = Players.LocalPlayer
local MainFrame
local PointsLabel
local DetailPanel, DTitle, DDesc, DCost, DReq, UnlockBtn
local SelectedNodeId = nil
local NodeGuis = {}

local function ApplyGradient(label, color1, color2)
	local grad = Instance.new("UIGradient", label)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}; grad.Rotation = 90
end

function PrestigeTab.Init(parentFrame)
	MainFrame = Instance.new("Frame", parentFrame)
	MainFrame.Name = "PrestigeFrame"; MainFrame.Size = UDim2.new(1, 0, 1, 0); MainFrame.BackgroundTransparency = 1; MainFrame.Visible = false

	local Title = Instance.new("TextLabel", MainFrame)
	Title.Size = UDim2.new(1, 0, 0, 40); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBlack; Title.TextColor3 = Color3.fromRGB(255, 215, 100); Title.TextSize = 22; Title.Text = "PRESTIGE TALENTS"
	ApplyGradient(Title, Color3.fromRGB(255, 215, 100), Color3.fromRGB(255, 150, 50))

	PointsLabel = Instance.new("TextLabel", MainFrame)
	PointsLabel.Size = UDim2.new(1, 0, 0, 20); PointsLabel.Position = UDim2.new(0, 0, 0, 35); PointsLabel.BackgroundTransparency = 1; PointsLabel.Font = Enum.Font.GothamBold; PointsLabel.TextColor3 = Color3.fromRGB(150, 255, 150); PointsLabel.TextSize = 14; PointsLabel.Text = "AVAILABLE POINTS: 0"

	local TreeScroll = Instance.new("ScrollingFrame", MainFrame)
	TreeScroll.Size = UDim2.new(1, 0, 1, -200); TreeScroll.Position = UDim2.new(0, 0, 0, 60); TreeScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 18); TreeScroll.ScrollBarThickness = 0; TreeScroll.BorderSizePixel = 0
	Instance.new("UICorner", TreeScroll).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", TreeScroll).Color = Color3.fromRGB(80, 60, 40)

	DetailPanel = Instance.new("Frame", MainFrame)
	DetailPanel.Size = UDim2.new(1, 0, 0, 130); DetailPanel.Position = UDim2.new(0, 0, 1, -135); DetailPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25); DetailPanel.Visible = false
	Instance.new("UICorner", DetailPanel).CornerRadius = UDim.new(0, 8); Instance.new("UIStroke", DetailPanel).Color = Color3.fromRGB(100, 80, 50)

	DTitle = Instance.new("TextLabel", DetailPanel); DTitle.Size = UDim2.new(1, -20, 0, 25); DTitle.Position = UDim2.new(0, 10, 0, 5); DTitle.BackgroundTransparency = 1; DTitle.Font = Enum.Font.GothamBlack; DTitle.TextColor3 = Color3.fromRGB(255, 255, 255); DTitle.TextSize = 16; DTitle.TextXAlignment = Enum.TextXAlignment.Left
	DDesc = Instance.new("TextLabel", DetailPanel); DDesc.Size = UDim2.new(1, -20, 0, 40); DDesc.Position = UDim2.new(0, 10, 0, 30); DDesc.BackgroundTransparency = 1; DDesc.Font = Enum.Font.GothamMedium; DDesc.TextColor3 = Color3.fromRGB(180, 180, 190); DDesc.TextSize = 12; DDesc.TextWrapped = true; DDesc.TextXAlignment = Enum.TextXAlignment.Left; DDesc.TextYAlignment = Enum.TextYAlignment.Top
	DCost = Instance.new("TextLabel", DetailPanel); DCost.Size = UDim2.new(0.5, 0, 0, 20); DCost.Position = UDim2.new(0, 10, 1, -55); DCost.BackgroundTransparency = 1; DCost.Font = Enum.Font.GothamBold; DCost.TextColor3 = Color3.fromRGB(150, 255, 150); DCost.TextSize = 12; DCost.TextXAlignment = Enum.TextXAlignment.Left
	DReq = Instance.new("TextLabel", DetailPanel); DReq.Size = UDim2.new(0.5, 0, 0, 20); DReq.Position = UDim2.new(0, 10, 1, -35); DReq.BackgroundTransparency = 1; DReq.Font = Enum.Font.GothamBold; DReq.TextColor3 = Color3.fromRGB(255, 100, 100); DReq.TextSize = 12; DReq.TextXAlignment = Enum.TextXAlignment.Left

	UnlockBtn = Instance.new("TextButton", DetailPanel)
	UnlockBtn.Size = UDim2.new(0.4, 0, 0, 40); UnlockBtn.Position = UDim2.new(0.95, 0, 1, -45); UnlockBtn.AnchorPoint = Vector2.new(1, 0); UnlockBtn.Font = Enum.Font.GothamBlack; UnlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255); UnlockBtn.TextSize = 14; UnlockBtn.Text = "UNLOCK"
	Instance.new("UICorner", UnlockBtn).CornerRadius = UDim.new(0, 6)
	local ubGrad = Instance.new("UIGradient", UnlockBtn); ubGrad.Rotation = 90

	UnlockBtn.MouseButton1Click:Connect(function()
		if SelectedNodeId then Network.UnlockPrestigeNode:FireServer(SelectedNodeId) end
	end)

	local drawnLines = {}
	for id, node in pairs(GameData.PrestigeNodes) do
		if node.Req and GameData.PrestigeNodes[node.Req] then
			local reqNode = GameData.PrestigeNodes[node.Req]
			local line = Instance.new("Frame", TreeScroll)
			line.Size = UDim2.new(0, 4, node.Pos.Y.Scale - reqNode.Pos.Y.Scale, 0); line.Position = UDim2.new(node.Pos.X.Scale, 0, reqNode.Pos.Y.Scale, 0); line.AnchorPoint = Vector2.new(0.5, 0)
			line.BackgroundColor3 = Color3.fromRGB(40, 40, 50); line.BorderSizePixel = 0; line.ZIndex = 1
			drawnLines[id] = line
		end

		local btn = Instance.new("TextButton", TreeScroll)
		btn.Size = UDim2.new(0, 45, 0, 45); btn.Position = node.Pos; btn.AnchorPoint = Vector2.new(0.5, 0.5); btn.Text = ""; btn.ZIndex = 2
		local corner = Instance.new("UICorner", btn); corner.CornerRadius = UDim.new(1, 0)
		local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(60, 60, 70); stroke.Thickness = 2
		local inner = Instance.new("Frame", btn); inner.Size = UDim2.new(1, -6, 1, -6); inner.Position = UDim2.new(0.5, 0, 0.5, 0); inner.AnchorPoint = Vector2.new(0.5, 0.5); inner.BackgroundColor3 = Color3.fromRGB(20, 20, 25); inner.ZIndex = 3
		Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)

		btn.MouseButton1Click:Connect(function()
			SelectedNodeId = id
			DetailPanel.Visible = true; DTitle.Text = node.Name; DTitle.TextColor3 = Color3.fromHex(node.Color:gsub("#", ""))
			DDesc.Text = node.Desc; DCost.Text = "COST: " .. node.Cost .. " PTS"

			local isOwned = player:GetAttribute("PrestigeNode_" .. id)
			local hasReq = node.Req == nil or player:GetAttribute("PrestigeNode_" .. node.Req)

			if isOwned then DReq.Text = "OWNED"; DReq.TextColor3 = Color3.fromRGB(100, 255, 100); UnlockBtn.Text = "OWNED"; ubGrad.Color = ColorSequence.new(Color3.fromRGB(40, 100, 40), Color3.fromRGB(20, 50, 20)); UnlockBtn.Active = false
			elseif not hasReq then DReq.Text = "REQUIRES: " .. GameData.PrestigeNodes[node.Req].Name; DReq.TextColor3 = Color3.fromRGB(255, 100, 100); UnlockBtn.Text = "LOCKED"; ubGrad.Color = ColorSequence.new(Color3.fromRGB(100, 40, 40), Color3.fromRGB(50, 20, 20)); UnlockBtn.Active = false
			else DReq.Text = "AVAILABLE TO UNLOCK"; DReq.TextColor3 = Color3.fromRGB(200, 200, 200); UnlockBtn.Text = "UNLOCK"; ubGrad.Color = ColorSequence.new(Color3.fromHex(node.Color:gsub("#", "")), Color3.fromRGB(40, 40, 40)); UnlockBtn.Active = true end
		end)
		NodeGuis[id] = { Btn = btn, Inner = inner, Stroke = stroke, Line = drawnLines[id], BaseColor = Color3.fromHex(node.Color:gsub("#", "")) }
	end

	local function UpdateUI()
		local pts = player:GetAttribute("PrestigePoints") or 0
		PointsLabel.Text = "AVAILABLE POINTS: " .. pts

		for id, gui in pairs(NodeGuis) do
			local isOwned = player:GetAttribute("PrestigeNode_" .. id)
			local node = GameData.PrestigeNodes[id]
			local hasReq = node.Req == nil or player:GetAttribute("PrestigeNode_" .. node.Req)

			if isOwned then
				gui.Inner.BackgroundColor3 = gui.BaseColor; gui.Stroke.Color = Color3.fromRGB(255, 255, 255)
				if gui.Line then gui.Line.BackgroundColor3 = gui.BaseColor end
			elseif hasReq then
				gui.Inner.BackgroundColor3 = Color3.fromRGB(40, 40, 50); gui.Stroke.Color = gui.BaseColor
				if gui.Line then gui.Line.BackgroundColor3 = Color3.fromRGB(60, 60, 70) end
			else
				gui.Inner.BackgroundColor3 = Color3.fromRGB(20, 20, 25); gui.Stroke.Color = Color3.fromRGB(40, 40, 50)
				if gui.Line then gui.Line.BackgroundColor3 = Color3.fromRGB(30, 30, 40) end
			end
		end

		if SelectedNodeId then
			local node = GameData.PrestigeNodes[SelectedNodeId]
			local isOwned = player:GetAttribute("PrestigeNode_" .. SelectedNodeId)
			local hasReq = node.Req == nil or player:GetAttribute("PrestigeNode_" .. node.Req)
			if isOwned then DReq.Text = "OWNED"; DReq.TextColor3 = Color3.fromRGB(100, 255, 100); UnlockBtn.Text = "OWNED"; ubGrad.Color = ColorSequence.new(Color3.fromRGB(40, 100, 40), Color3.fromRGB(20, 50, 20)); UnlockBtn.Active = false
			elseif not hasReq then DReq.Text = "REQUIRES: " .. GameData.PrestigeNodes[node.Req].Name; DReq.TextColor3 = Color3.fromRGB(255, 100, 100); UnlockBtn.Text = "LOCKED"; ubGrad.Color = ColorSequence.new(Color3.fromRGB(100, 40, 40), Color3.fromRGB(50, 20, 20)); UnlockBtn.Active = false
			else DReq.Text = "AVAILABLE TO UNLOCK"; DReq.TextColor3 = Color3.fromRGB(200, 200, 200); UnlockBtn.Text = "UNLOCK"; ubGrad.Color = ColorSequence.new(Color3.fromHex(node.Color:gsub("#", "")), Color3.fromRGB(40, 40, 40)); UnlockBtn.Active = true end
		end
	end

	player.AttributeChanged:Connect(function(attr) if string.find(attr, "Prestige") then UpdateUI() end end)
	UpdateUI()
end

function PrestigeTab.Show() if MainFrame then MainFrame.Visible = true end end

return PrestigeTab