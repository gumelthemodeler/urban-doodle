-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local UIAuraManager = {}

local RunService = game:GetService("RunService")

local activeConnection = nil
local activeParticles = {}
local ambientGlow = nil

-- [[ ADD YOUR MULTIPLE IDS HERE ]]
-- The script will randomly pick one of these for every particle spawned.
local PARTICLE_IDS = {
	"rbxassetid://14428245156", -- Your flame particle
	"rbxassetid://91391658964497",
	"rbxassetid://17735353017",
	"rbxassetid://101919176010049",
}

function UIAuraManager.ApplyAura(container, auraData)
	UIAuraManager.ClearAura()

	-- Function to find and color the gray UIStroke ring around the Avatar
	local function setAvatarRingColor(color)
		if container.Parent then
			for _, child in ipairs(container.Parent:GetChildren()) do
				if child:IsA("ImageLabel") then -- Finds the AvatarBox
					local stroke = child:FindFirstChildOfClass("UIStroke")
					if stroke then
						stroke.Color = color
					end
				end
			end
		end
	end

	-- If no aura, revert the ring to the default gray color and stop
	if not auraData or auraData.Name == "None" then 
		setAvatarRingColor(Color3.fromRGB(100, 100, 110)) 
		return 
	end

	local c1 = Color3.fromHex((auraData.Color1 or "#FFFFFF"):gsub("#", ""))
	local c2 = Color3.fromHex((auraData.Color2 or "#FFFFFF"):gsub("#", ""))

	-- Color the Avatar's ring to match the primary Aura color!
	setAvatarRingColor(c1)

	-- 1. Create a deep, breathing ambient glow ring
	ambientGlow = Instance.new("ImageLabel", container)
	ambientGlow.Size = UDim2.new(1.15, 0, 1.15, 0)
	ambientGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
	ambientGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	ambientGlow.BackgroundTransparency = 1
	ambientGlow.Image = "rbxassetid://2001828033" -- Soft glowing ring
	ambientGlow.ImageColor3 = c1
	ambientGlow.ImageTransparency = 0.2
	ambientGlow.ZIndex = 1

	local rot = 0
	local lastSpawn = 0

	-- 2. Run the internal particle engine
	activeConnection = RunService.RenderStepped:Connect(function(dt)
		rot = (rot + dt * 45) % 360
		if ambientGlow then ambientGlow.Rotation = rot end

		-- Spawn new particles
		local now = tick()
		if now - lastSpawn > 0.05 then
			lastSpawn = now

			local p = Instance.new("ImageLabel", container)
			p.BackgroundTransparency = 1

			-- Randomly select a particle ID from our table
			p.Image = PARTICLE_IDS[math.random(1, #PARTICLE_IDS)]

			p.ImageColor3 = math.random() > 0.5 and c1 or c2
			p.ZIndex = 2

			local angle = math.rad(math.random(0, 360))
			-- Spawn them in a ring pattern around the avatar
			local radius = (container.AbsoluteSize.X * 0.45) 
			local px = 0.5 + (math.cos(angle) * radius) / math.max(1, container.AbsoluteSize.X)
			local py = 0.5 + (math.sin(angle) * radius) / math.max(1, container.AbsoluteSize.Y)

			p.Position = UDim2.new(px, 0, py, 0)
			p.AnchorPoint = Vector2.new(0.5, 0.5)

			local size = math.random(15, 45)
			p.Size = UDim2.new(0, size, 0, size)

			table.insert(activeParticles, {
				el = p,
				life = 1.5,
				maxLife = 1.5,
				vx = (math.random() - 0.5) * 0.1,
				vy = -math.random(1, 6) * 0.1, -- Float up dynamically
				rot = math.random(-60, 60)
			})
		end

		-- Update existing particles
		for i = #activeParticles, 1, -1 do
			local pd = activeParticles[i]
			pd.life = pd.life - dt

			if pd.life <= 0 then
				if pd.el then pd.el:Destroy() end
				table.remove(activeParticles, i)
			else
				local prog = 1 - (pd.life / pd.maxLife)
				pd.el.Position = pd.el.Position + UDim2.new(pd.vx * dt, 0, pd.vy * dt, 0)
				pd.el.Rotation = pd.el.Rotation + (pd.rot * dt)
				pd.el.ImageTransparency = prog -- Fade out as they float
			end
		end
	end)
end

function UIAuraManager.ClearAura()
	if activeConnection then activeConnection:Disconnect(); activeConnection = nil end
	if ambientGlow then ambientGlow:Destroy(); ambientGlow = nil end
	for _, p in ipairs(activeParticles) do if p.el then p.el:Destroy() end end
	activeParticles = {}
end

return UIAuraManager