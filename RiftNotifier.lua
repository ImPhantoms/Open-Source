--[[
    Hello, this is an open-source BGSI Rift Webhook Notifier that you can use free of charge.
    If you use this in a public script, credit is appreciated but not required.
    I added comments so new scripters can understand what they're looking at and hopefully learn something, enjoy!

    Discord; @rPhantoms
]]

if not rawequal(typeof(getgenv().RiftNotifier), 'table') then --// This is to make sure the script only runs once to prevent multiple webhook notifications
    --> Configuration
    getgenv().RiftNotifier = {
        EggWebhook = 'PUT WEBHOOK LINK HERE', -- // Eggs
        OtherWebhook = 'PUT WEBHOOK LINK HERE', -- // Chests, 250x Sell, ETC

        NotifyOnly25X = true, -- // Change to false if you want it to notify for all multipliers, keep true if you want it to only notify for x25
        MinimumTime = 3, -- // This ensures it only notifies if the time left is above this number. (For example, if set to 5, it will only notify when the egg has 5 or more minutes remaining.)
    }

    --> Services
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local HttpService = game:GetService('HttpService')

    --> Variables
    local Rifts = workspace.Rendered.Rifts
    local Data = require(ReplicatedStorage.Shared.Data.Rifts)

    --> Tables
    local Others = {
        ['golden-chest'] = 'Golden Chest',
        ['royal-chest'] = 'Royal Chest',

        ['bubble-rift'] = '250x Sell Area',
        ['gift-rift'] = 'Gift',
    }

    --> Functions
    local function Notify(Name: string, Time: number, Height: number, RiftType: string, Luck: number)
        if Time < getgenv().RiftNotifier.MinimumTime then
            return
        end

        local JoinCode = `{"```lua\n"}game:GetService("TeleportService"):TeleportToPlaceInstance({game.PlaceId}, "{game.JobId}"){"```"}`
        local JoinLink = `https://www.roblox.com/games/start?placeId={game.PlaceId}&launchData={game.PlaceId}/{game.JobId}`

        local Data = {
            ["embeds"] = {
                {
                    ["title"] = "New Rift",
                    ["description"] = `# {Name} has spawned!\n\n**🌍 Join Code**:\n{JoinCode}\n**🔗 Join Link**: [**Click me to join.**]({JoinLink})\n\n**⌚ Time Left**: {Time} minutes\n**☁️ Height**: {math.round(Height)}\n{(Luck and `**🍀 Luck**: {Luck}` or "")}`,
                    ["color"] = 16777215
                }
            }
        }

        request({Url = getgenv().RiftNotifier[`{rawequal(RiftType, 'Egg') and RiftType or 'Other'}Webhook`], Method = "POST",Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(Data)})
    end

    local function AddRift(Rift: Model)
        local EggData = Data[Rift.Name]

        if EggData then
            local RiftType = rawequal(EggData.Type, 'Egg') and EggData.Type or 'Other'
            local TimeLeft = math.floor((Rift:GetAttribute('DespawnAt') - os.time()) / 60)

            local Icon = Rift:WaitForChild('Display').SurfaceGui:FindFirstChild('Icon')
            local Luck = Icon and Icon:FindFirstChild("Luck") and Icon.Luck.Text or nil
            
            if (Luck and getgenv().RiftNotifier.NotifyOnly25X and not rawequal(Luck, 'x25')) then
                return
            end

            Notify(EggData.Egg or Others[Rift.Name] or Rift.Name, TimeLeft, Rift.Display.Position.Y, RiftType, Luck)
        end
    end

    --> Listeners
    for _, Rift in next, Rifts:GetChildren() do -- // This accounts for existing rifts
        AddRift(Rift)
    end

    Rifts.ChildAdded:Connect(function(Child: Model) -- // This accounts for rifts that are added
        AddRift(Child)
    end)
end
