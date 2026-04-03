-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
-- Name: UIHelpers
local UIHelpers = {}
local TweenService = game:GetService("TweenService")

function UIHelpers.ApplyGradient(label, color1, color2)
	local grad = label:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", label)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)}
end

function UIHelpers.ApplyButtonGradient(btn, topColor, botColor, strokeColor)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.AutoButtonColor = false 
	local grad = btn:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient", btn)
	grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, topColor), ColorSequenceKeypoint.new(1, botColor)}
	grad.Rotation = 90
	local corner = btn:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 4)
	if strokeColor then
		local stroke = btn:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", btn)
		stroke.Color = strokeColor; stroke.Thickness = 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end

	if not btn:GetAttribute("GradientTextFixed") then
		btn:SetAttribute("GradientTextFixed", true)
		local textLbl = Instance.new("TextLabel", btn)
		textLbl.Name = "BtnTextLabel"
		textLbl.Size = UDim2.new(1, 0, 1, 0)
		textLbl.BackgroundTransparency = 1
		textLbl.Font = btn.Font
		textLbl.TextSize = btn.TextSize
		textLbl.TextScaled = btn.TextScaled
		textLbl.RichText = btn.RichText
		textLbl.TextWrapped = btn.TextWrapped
		textLbl.TextXAlignment = btn.TextXAlignment
		textLbl.TextYAlignment = btn.TextYAlignment
		textLbl.ZIndex = btn.ZIndex + 1

		local tConstraint = btn:FindFirstChildOfClass("UITextSizeConstraint")
		if tConstraint then tConstraint.Parent = textLbl end

		btn.ChildAdded:Connect(function(child) 
			if child:IsA("UITextSizeConstraint") then task.delay(0, function() child.Parent = textLbl end) end 
		end)

		textLbl.Text = btn.Text; textLbl.TextColor3 = btn.TextColor3; btn.Text = ""

		btn:GetPropertyChangedSignal("Text"):Connect(function() 
			if btn.Text ~= "" then textLbl.Text = btn.Text; btn.Text = "" end 
		end)
		btn:GetPropertyChangedSignal("TextColor3"):Connect(function() textLbl.TextColor3 = btn.TextColor3 end)
		btn:GetPropertyChangedSignal("RichText"):Connect(function() textLbl.RichText = btn.RichText end)
	end
end

function UIHelpers.TweenGradient(grad, targetTop, targetBot, duration)
	local startTop = grad.Color.Keypoints[1].Value
	local startBot = grad.Color.Keypoints[#grad.Color.Keypoints].Value
	local val = Instance.new("NumberValue"); val.Value = 0
	local tween = TweenService:Create(val, TweenInfo.new(duration), {Value = 1})
	val.Changed:Connect(function(v) 
		grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, startTop:Lerp(targetTop, v)), ColorSequenceKeypoint.new(1, startBot:Lerp(targetBot, v))} 
	end)
	tween:Play(); tween.Completed:Connect(function() val:Destroy() end)
end

function UIHelpers.DrawLineScale(parent, p1x, p1y, p2x, p2y, color, thickness, zindex)
	local dx = p2x - p1x; local dy = p2y - p1y; local dist = math.sqrt(dx*dx + dy*dy)
	local frame = Instance.new("Frame", parent)
	frame.Size = UDim2.new(0, dist, 0, thickness); frame.Position = UDim2.new(0, (p1x + p2x)/2, 0, (p1y + p2y)/2)
	frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.Rotation = math.deg(math.atan2(dy, dx))
	frame.BackgroundColor3 = color; frame.BorderSizePixel = 0; frame.ZIndex = zindex or 1
	return frame
end

function UIHelpers.DrawUITriangle(parent, p1, p2, p3, color, transp, zIndex)
	local edges = { {p1, p2}, {p2, p3}, {p3, p1} }
	table.sort(edges, function(a, b) return (a[1]-a[2]).Magnitude > (b[1]-b[2]).Magnitude end)
	local a, b = edges[1][1], edges[1][2]; local c = edges[2][1] == a and edges[2][2] or edges[2][1]
	if c == b then c = edges[3][1] == a and edges[3][2] or edges[3][1] end
	local ab = b - a; local ac = c - a; local dir = ab.Unit; local projLen = ac:Dot(dir); local proj = dir * projLen; local h = (ac - proj).Magnitude
	local w1 = projLen; local w2 = ab.Magnitude - projLen
	local t1 = Instance.new("ImageLabel")
	t1.BackgroundTransparency = 1; t1.Image = "rbxassetid://319692171"; t1.ImageColor3 = color; t1.ImageTransparency = transp; t1.ZIndex = zIndex; t1.BorderSizePixel = 0; t1.AnchorPoint = Vector2.new(0.5, 0.5)
	local t2 = t1:Clone(); t1.Size = UDim2.new(0, w1, 0, h); t2.Size = UDim2.new(0, w2, 0, h)
	t1.Position = UDim2.new(0, a.X + proj.X/2, 0, a.Y + proj.Y/2); t2.Position = UDim2.new(0, b.X + (proj.X - ab.X)/2, 0, b.Y + (proj.Y - ab.Y)/2)
	t1.Rotation = math.deg(math.atan2(dir.Y, dir.X)); t2.Rotation = math.deg(math.atan2(-dir.Y, -dir.X))
	t1.Parent = parent; t2.Parent = parent
end

return UIHelpers