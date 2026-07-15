

local SCRIPT_URL  = "https://raw.githubusercontent.com/hash0tobash8/Repo/refs/heads/main/lake.lua"
local LOBBY_ID    = 138381251771774
local DUNGEON_ID  = 124786371598438

local difficulty  = getgenv().farmDifficulty  or "Easy"
local autoHop     = getgenv().farmAutoHop     ~= false  -- default true
local autoExecute = getgenv().farmAutoExecute ~= false  -- default true


local function queueSelf()
    if not autoExecute then return end
    local queueScript = ('loadstring(game:HttpGet("%s"))()'):format(SCRIPT_URL)
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport(queueScript)
    elseif queue_on_teleport then
        queue_on_teleport(queueScript)
    end
end

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
                    TeleportService:TeleportToPlaceInstance(PlaceId, server.id, game.Players.LocalPlayer)
                end)
                task.wait(3)
                return
            end
        end
    end

    TeleportService:Teleport(PlaceId, game.Players.LocalPlayer)
end


if game.PlaceId == LOBBY_ID then
    queueSelf()
    task.wait(1.5)

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
                if touchPart and touchPart:FindFirstChild("TouchInterest") then
                    foundPortal = true

                   
                    firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, touchPart, 0)
                    task.wait(0.3)  
                    pcall(function()
                        game.ReplicatedStorage.VerdantRemotes["VDT_Portal.CreateSetup"]:FireServer({
                            ["Difficulty"] = difficulty,
                            ["MaxPlayers"] = 1
                        })
                    end)

                    task.wait(0.1)
                  
                    firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, touchPart, 1)
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


elseif game.PlaceId == DUNGEON_ID then
    queueSelf()

    local lp   = game.Players.LocalPlayer
    local char = lp.Character or lp.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 10)

    if not root then return end  

    if not getgenv()._farmHookActive then
        getgenv()._farmHookActive = true
        local nc; nc = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and self.Name == "VDT_CutsceneReady" then
                task.delay(0.1, function()
                    pcall(function()
                        game.ReplicatedStorage.VerdantRemotes.VDT_CutsceneVoteSkip:FireServer(...)
                    end)
                end)
            end
            return nc(self, ...)
        end)
    end

    task.wait(0.3)

    
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

        root.CFrame = vault:IsA("Model") and vault:GetPivot() or CFrame.new(vault.Position)
        root.CFrame = root.CFrame + Vector3.new(0, 2, 0)
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
