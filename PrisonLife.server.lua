local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local TEAM_COLORS = {
	Guard = BrickColor.new("Bright blue"),
	Prisoner = BrickColor.new("Bright orange"),
	Criminal = BrickColor.new("Really red"),
}

local function getOrCreateTeam(name)
	local team = Teams:FindFirstChild(name)
	if not team then
		team = Instance.new("Team")
		team.Name = name
		team.Parent = Teams
	end
	team.TeamColor = TEAM_COLORS[name]
	team.AutoAssignable = false
	return team
end

local guardTeam = getOrCreateTeam("Guard")
local prisonerTeam = getOrCreateTeam("Prisoner")
local criminalTeam = getOrCreateTeam("Criminal")

local function countPlayers(team)
	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team == team then
			count += 1
		end
	end
	return count
end

local function assignTeam(player)
	if countPlayers(guardTeam) < math.max(1, math.floor(#Players:GetPlayers() / 5)) then
		player.Team = guardTeam
	else
		player.Team = prisonerTeam
	end
end

local function moveToSpawn(player, spawnName)
	local spawnFolder = Workspace:FindFirstChild("PrisonSpawns")
	local spawnPart = spawnFolder and spawnFolder:FindFirstChild(spawnName)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and spawnPart and spawnPart:IsA("BasePart") then
		root.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
	end
end

local function spawnNameFor(player)
	if player.Team == guardTeam then
		return "GuardSpawn"
	elseif player.Team == criminalTeam then
		return "CriminalSpawn"
	end
	return "PrisonerSpawn"
end

local function makeArrestPrompt(targetPlayer, character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or root:FindFirstChild("ArrestPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ArrestPrompt"
	prompt.ActionText = "Arrest"
	prompt.ObjectText = targetPlayer.DisplayName
	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(guard)
		if guard.Team ~= guardTeam or targetPlayer == guard then
			return
		end
		if targetPlayer.Team ~= criminalTeam then
			return
		end
		targetPlayer.Team = prisonerTeam
		targetPlayer:LoadCharacter()
	end)
end

local function setupPlayer(player)
	assignTeam(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	local escapes = Instance.new("IntValue")
	escapes.Name = "Escapes"
	escapes.Value = 0
	escapes.Parent = stats

	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.1)
		moveToSpawn(player, spawnNameFor(player))
		makeArrestPrompt(player, character)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

local escapePart = Workspace:FindFirstChild("EscapeDoor")
if escapePart and escapePart:IsA("BasePart") then
	local prompt = escapePart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Escape"
		prompt.ObjectText = "Prison exit"
		prompt.HoldDuration = 3
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = escapePart
	end
	prompt.Triggered:Connect(function(player)
		if player.Team ~= prisonerTeam then
			return
		end
		player.Team = criminalTeam
		local stats = player:FindFirstChild("leaderstats")
		local escapes = stats and stats:FindFirstChild("Escapes")
		if escapes then
			escapes.Value += 1
		end
		moveToSpawn(player, "CriminalSpawn")
	end)
else
	warn("PrisonLife: Add a BasePart named EscapeDoor to Workspace to enable escaping.")
end
