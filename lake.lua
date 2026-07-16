
local SCRIPT_URL = "https://raw.githubusercontent.com/hash0tobash8/Repo/refs/heads/main/lake.lua"
local LOBBY_ID   = 138381251771774
local DUNGEON_ID = 124786371598438

local difficulty  = getgenv().farmDifficulty  or "Easy"
local autoHop     = getgenv().farmAutoHop     ~= false
local autoExecute = getgenv().farmAutoExecute ~= false

getgenv()._farmHookActive = nil

local Players = game:GetService("Players")
local lp
repeat task.wait(0.1) lp = Players.LocalPlayer until lp

local function queueSelf()
    if not autoExecute then return end
    local s = ('getgenv().farmDifficulty=%q;getgenv().farmAutoHop=%s;getgenv().farmAutoExecute=%s;loadstring(game:HttpGet("%s"))()'):format(
        tostring(difficulty),
        tostring(autoHop),
        tostring(autoExecute),
        SCRIPT_URL
    )
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(s)
    elseif queue_on_teleport then
        queue_on_teleport(s)
    end
end

task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    lp.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

local function serverHop()
    local TeleportService = game:GetService("TeleportService")
    local HttpService     = game:GetService("HttpService")
    local PlaceId         = game.PlaceId
    local ok, result = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        )
    end)
    if ok and result and result.data then
        for _, server in ipairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(PlaceId, server.id, lp)
                end)
                task.wait(3)
                return
            end
        end
    end
    TeleportService:Teleport(PlaceId, lp)
end

if game.PlaceId == LOBBY_ID then
    queueSelf()
    task.wait(1.5)

    local char = lp.Character
    if not char then char = lp.CharacterAdded:Wait() end
    local hrp = char:WaitForChild("HumanoidRootPart", 15)

    while task.wait(1) do
        local foundPortal = false

        for _, v in ipairs(workspace:GetChildren()) do
            if v.Name == "Portal" then
                local container = v:FindFirstChild("Billboard")
                    and v.Billboard:FindFirstChild("Container")
                local playerCount = container
                    and container:FindFirstChild("Player")
                    and container.Player:FindFirstChild("PlayerCount")
                local isEmpty = playerCount and (playerCount.Text == "" or playerCount.Text == " " or playerCount.Text == "0")

                if isEmpty then
                    local touchPart = v:FindFirstChild("Touch")
                    if touchPart and hrp then
                        foundPortal = true
                      
                        hrp.CFrame = touchPart.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.5)
                        
                       
                        if touchPart:FindFirstChild("TouchInterest") then
                            firetouchinterest(hrp, touchPart, 0)
                        end
                        
                        task.wait(0.5)
                        pcall(function()
                            game.ReplicatedStorage.VerdantRemotes["VDT_Portal.CreateSetup"]:FireServer({
                                ["Difficulty"] = difficulty,
                                ["MaxPlayers"] = 1
                            })
                        end)
                        
                       
                        task.wait(1)
                        break
                    end
                end
            end
        end

        if not foundPortal then
            if autoHop then
                serverHop()
            end
        end
    end

elseif game.PlaceId == DUNGEON_ID then
    queueSelf()

    local char
    for _ = 1, 80 do
        char = lp.Character
        if char and char:FindFirstChild("HumanoidRootPart") then break end
        task.wait(0.5)
    end
    if not char then return end
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if not root then return end

    if not getgenv()._farmHookActive then
        getgenv()._farmHookActive = true
        local nc; nc = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" then
                if self.Name == "VDT_CutsceneReady" then
                    local args = {...}
                    task.delay(0.1, function()
                        pcall(function()
                            game.ReplicatedStorage.VerdantRemotes.VDT_CutsceneVoteSkip:FireServer(unpack(args))
                        end)
                    end)
                end
            end
            return nc(self, ...)
        end)
    end

    task.spawn(function()
        local remotes = game.ReplicatedStorage:WaitForChild("VerdantRemotes", 5)
        if remotes then
            pcall(function() remotes.VDT_CharacterReady:FireServer() end)
            pcall(function() remotes.VDT_CutsceneComplete:FireServer() end)
        end
        while task.wait(1) do
            pcall(function()
                game.ReplicatedStorage.VerdantRemotes:WaitForChild("VDT_CutsceneSkip", 1):FireServer()
                game.ReplicatedStorage.VerdantRemotes:WaitForChild("VDT_CutsceneVoteSkip", 1):FireServer()
            end)
        end
    end)

    
    local waterCheck = workspace:WaitForChild("Water", 8)
    if not waterCheck then
        if autoHop then serverHop() end
        return
    end

    local chestFolder = workspace:FindFirstChild("Scripted")
        and workspace.Scripted:FindFirstChild("Chests")

    if chestFolder then
        for _, chest in ipairs(chestFolder:GetChildren()) do
            pcall(function()
                local prompt = nil
                for _ = 1, 10 do
                    prompt = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then break end
                    task.wait(0.2)
                end
                if prompt and prompt.Enabled then
                local pivotCF = chest:IsA("Model") and chest:GetPivot() or chest.CFrame
                root.CFrame = pivotCF + Vector3.new(0, 2, 0)
                task.wait(0.15)
                    fireproximityprompt(prompt)
                    task.wait(0.2)
                end
            end)
        end
    end

    pcall(function()
        local vault = workspace.Scripted:WaitForChild("VaultStart", 8)
        if not vault then return end
        local vaultPrompt = vault:FindFirstChildWhichIsA("ProximityPrompt")
            or vault:WaitForChild("ProximityPrompt", 5)
        root.CFrame = (vault:IsA("Model") and vault:GetPivot() or CFrame.new(vault.Position)) + Vector3.new(0, 2, 0)
        task.wait(0.5)
        fireproximityprompt(vaultPrompt)
    end)

    task.wait(1.5)

    pcall(function()
        game.ReplicatedStorage.VerdantRemotes.VDT_ReturnToLobby:FireServer()
    end)
    
    task.wait(3)

    if autoHop then
        serverHop()
    end
end
