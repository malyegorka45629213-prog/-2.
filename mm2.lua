-- ═══════════════════════════════════════════════════════════
--  MM2 Coin Autofarm · [egor745top6] · ПОЛНЫЙ СКРИПТ
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local visitedPositions = {}
local isActive = false
local flySpeed = 15
local collected = 0
local startTime = 0
local antiAFK = false
local isMurderer = false
local isSheriff = false
local bagFull = false
local farmStopped = false
local espEnabled = false
local espHighlights = {}

local MAX_BAG = 40

-- ЗВУКИ
local collectSound = Instance.new("Sound")
collectSound.SoundId = "rbxassetid://12221967"
collectSound.Volume = 1

local killSound = Instance.new("Sound")
killSound.SoundId = "rbxassetid://9120392731"
killSound.Volume = 0.8

local deathSound = Instance.new("Sound")
deathSound.SoundId = "rbxassetid://9120392731"
deathSound.Volume = 0.6

-- ПРОВЕРКА РОЛИ
local function getPlayerRole(p)
    if p.Character then
        if p.Character:FindFirstChild("Knife") or p.Character:FindFirstChild("MurdererSword") then return "Murderer" end
        if p.Character:FindFirstChild("Gun") or p.Character:FindFirstChild("SheriffGun") then return "Sheriff" end
    end
    if p:FindFirstChild("Backpack") then
        local bp = p.Backpack
        if bp:FindFirstChild("Knife") or bp:FindFirstChild("MurdererSword") then return "Murderer" end
        if bp:FindFirstChild("Gun") or bp:FindFirstChild("SheriffGun") then return "Sheriff" end
    end
    local leaderstats = p:FindFirstChild("leaderstats")
    if leaderstats then
        local rv = leaderstats:FindFirstChild("Role")
        if rv and rv.Value then return rv.Value end
    end
    local rv = p:FindFirstChild("Role")
    if rv and rv:IsA("StringValue") then return rv.Value end
    local ps = p:FindFirstChild("playerstats")
    if ps then
        local rv2 = ps:FindFirstChild("Role")
        if rv2 and rv2.Value then return rv2.Value end
    end
    return "Innocent"
end

local function checkRole()
    local role = getPlayerRole(player)
    isMurderer = (role == "Murderer")
    isSheriff = (role == "Sheriff")
end

-- ТЕМА
local COL = {
    bg = Color3.fromRGB(15, 10, 25),
    card = Color3.fromRGB(28, 18, 45),
    cardHov = Color3.fromRGB(38, 25, 60),
    off = Color3.fromRGB(40, 30, 55),
    border = Color3.fromRGB(60, 40, 80),
    text = Color3.fromRGB(230, 220, 245),
    muted = Color3.fromRGB(140, 120, 170),
    white = Color3.fromRGB(255, 255, 255),
}
local ACCENT = {
    base = Color3.fromRGB(155, 60, 255),
    dim = Color3.fromRGB(60, 20, 100),
    light = Color3.fromRGB(200, 140, 255),
}

local function corner(obj, r)
    local c = Instance.new("UICorner", obj)
    c.CornerRadius = UDim.new(0, r)
    return c
end

local function stroke(obj, color, th)
    local s = Instance.new("UIStroke", obj)
    s.Color = color
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

local function tw(obj, props, t, style)
    TweenService:Create(obj, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- Очистка старого GUI
do
    local pg = player:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("AutoFarmGui")
    if old then old:Destroy() end
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

collectSound.Parent = gui
killSound.Parent = gui
deathSound.Parent = gui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 520)
frame.Position = UDim2.new(0.5, -170, 0.5, -260)
frame.BackgroundColor3 = COL.bg
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui
corner(frame, 14)
stroke(frame, COL.border, 1.5)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundTransparency = 1
titleBar.Active = true
titleBar.ZIndex = 2
titleBar.Parent = frame

local dotColors = {Color3.fromRGB(255, 95, 86), Color3.fromRGB(255, 189, 46), Color3.fromRGB(39, 201, 63)}
for i = 1, 3 do
    local d = Instance.new("Frame")
    d.Size = UDim2.new(0, 12, 0, 12)
    d.Position = UDim2.new(0, 14 + (i - 1) * 20, 0, 15)
    d.BackgroundColor3 = dotColors[i]
    d.BorderSizePixel = 0
    d.ZIndex = 3
    d.Parent = titleBar
    corner(d, 6)
end

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -40, 1, 0)
titleLbl.Position = UDim2.new(0, 40, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "[egor745top6] Coin Farm"
titleLbl.TextColor3 = COL.text
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 14
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 2
titleLbl.Parent = titleBar

do
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            local delta = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local body = Instance.new("ScrollingFrame")
body.Size = UDim2.new(1, 0, 1, -42)
body.Position = UDim2.new(0, 0, 0, 42)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 4
body.ScrollBarImageColor3 = ACCENT.base
body.CanvasSize = UDim2.new(0, 0, 0, 0)
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.ScrollingEnabled = true
body.ZIndex = 2
body.Parent = frame

do
    local p = Instance.new("UIPadding", body)
    p.PaddingLeft = UDim.new(0, 14)
    p.PaddingRight = UDim.new(0, 14)
    p.PaddingTop = UDim.new(0, 8)
    p.PaddingBottom = UDim.new(0, 14)
    local l = Instance.new("UIListLayout", body)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, 8)
end

-- КНОПКИ
local function toggleCard(order, label, onToggle)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 44)
    card.BackgroundColor3 = COL.card
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 2
    card.Parent = body
    corner(card, 10)
    local cs = stroke(card, COL.border, 1)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -90, 1, 0)
    t.Position = UDim2.new(0, 14, 0, 0)
    t.BackgroundTransparency = 1
    t.Text = label
    t.TextColor3 = COL.text
    t.Font = Enum.Font.GothamSemibold
    t.TextSize = 14
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 2
    t.Parent = card

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 52, 0, 24)
    pill.Position = UDim2.new(1, -66, 0.5, -12)
    pill.BackgroundColor3 = COL.off
    pill.BorderSizePixel = 0
    pill.ZIndex = 2
    pill.Parent = card
    corner(pill, 12)
    local ps = stroke(pill, COL.border, 1)

    local pl = Instance.new("TextLabel")
    pl.Size = UDim2.new(1, 0, 1, 0)
    pl.BackgroundTransparency = 1
    pl.Text = "OFF"
    pl.TextColor3 = COL.muted
    pl.Font = Enum.Font.GothamBold
    pl.TextSize = 11
    pl.ZIndex = 2
    pl.Parent = pill

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 3
    btn.Parent = card

    local currentState = false

    local function updateVisual()
        if currentState then
            tw(card, {BackgroundColor3 = ACCENT.dim})
            tw(cs, {Color = ACCENT.base})
            tw(pill, {BackgroundColor3 = ACCENT.base})
            tw(ps, {Color = ACCENT.base})
            pl.Text = "ON"
            tw(pl, {TextColor3 = COL.white})
        else
            tw(card, {BackgroundColor3 = COL.card})
            tw(cs, {Color = COL.border})
            tw(pill, {BackgroundColor3 = COL.off})
            tw(ps, {Color = COL.border})
            pl.Text = "OFF"
            tw(pl, {TextColor3 = COL.muted})
        end
    end

    btn.MouseButton1Click:Connect(function()
        currentState = not currentState
        updateVisual()
        if onToggle then onToggle(currentState) end
    end)

    btn.MouseEnter:Connect(function() if not currentState then tw(card, {BackgroundColor3 = COL.cardHov}) end end)
    btn.MouseLeave:Connect(function() if not currentState then tw(card, {BackgroundColor3 = COL.card}) end end)

    return {
        setState = function(v) currentState = v updateVisual() end,
        getState = function() return currentState end
    }
end

local function statRow(order, name)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.ZIndex = 2
    row.Parent = body

    local n = Instance.new("TextLabel")
    n.Size = UDim2.new(0.62, 0, 1, 0)
    n.BackgroundTransparency = 1
    n.Text = name
    n.TextColor3 = COL.muted
    n.Font = Enum.Font.Gotham
    n.TextSize = 13
    n.TextXAlignment = Enum.TextXAlignment.Left
    n.ZIndex = 2
    n.Parent = row

    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.38, -2, 1, 0)
    v.Position = UDim2.new(0.62, 0, 0, 0)
    v.BackgroundTransparency = 1
    v.Text = "0"
    v.TextColor3 = ACCENT.light
    v.Font = Enum.Font.GothamBold
    v.TextSize = 13
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.ZIndex = 2
    v.Parent = row
    return v
end

local function sectionLabel(order, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = COL.muted
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order
    l.ZIndex = 2
    l.Parent = body
end

sectionLabel(5, "STATS")
local counterVal = statRow(6, "Coins Collected")
local timerVal = statRow(7, "Time Active")
local rateVal = statRow(8, "Coins / Hour")

sectionLabel(9, "ROLE INFO")
local roleVal = statRow(10, "Your Role")

sectionLabel(11, "BAG STATUS")
local bagVal = statRow(12, "Bag Full")

function updateRoleUI()
    checkRole()
    if isMurderer then
        roleVal.Text = "🔪 Murderer"
        roleVal.TextColor3 = Color3.fromRGB(255, 50, 50)
    elseif isSheriff then
        roleVal.Text = "⭐ Sheriff"
        roleVal.TextColor3 = Color3.fromRGB(50, 150, 255)
    else
        roleVal.Text = "👤 Innocent"
        roleVal.TextColor3 = Color3.fromRGB(50, 255, 50)
    end
end

function updateBagUI()
    if farmStopped then
        bagVal.Text = "🛑 STOPPED"
        bagVal.TextColor3 = Color3.fromRGB(255, 80, 80)
    elseif bagFull then
        bagVal.Text = "✅ FULL"
        bagVal.TextColor3 = Color3.fromRGB(255, 200, 0)
    else
        bagVal.Text = collected .. "/" .. MAX_BAG
        bagVal.TextColor3 = Color3.fromRGB(100, 100, 100)
    end
end

-- ОСТАНОВКА ФАРМА
function stopFarming()
    farmStopped = true
    updateBagUI()
    print("🛑 ФАРМ ОСТАНОВЛЕН!")
end

-- 🔪 УБИЙЦА УБИВАЕТ ВСЕХ
function cinematicMurdererKill()
    print("🔪 === УБИЙЦА УБИВАЕТ ВСЕХ ===")
    killSound:Play()
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        print("❌ Нет HumanoidRootPart!")
        return 
    end
    
    -- Нож
    local knife = Instance.new("Tool")
    knife.Name = "MurdererKnife"
    knife.TextureId = "rbxassetid://189130411"
    knife.GripPos = Vector3.new(0, -0.5, 0)
    knife.Parent = character
    
    -- Красная вспышка
    local flash = Instance.new("Part")
    flash.Size = Vector3.new(30, 30, 30)
    flash.Position = hrp.Position
    flash.Anchored = true
    flash.CanCollide = false
    flash.Material = Enum.Material.Neon
    flash.Color = Color3.fromRGB(255, 0, 0)
    flash.Transparency = 0.7
    flash.Parent = workspace
    Debris:AddItem(flash, 2)
    
    local light = Instance.new("PointLight")
    light.Brightness = 20
    light.Range = 50
    light.Color = Color3.fromRGB(255, 0, 0)
    light.Parent = flash
    
    task.wait(0.3)
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
            if targetHrp then
                hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
                task.wait(0.08)
                
                local hitEffect = Instance.new("Part")
                hitEffect.Size = Vector3.new(2, 2, 2)
                hitEffect.Position = targetHrp.Position
                hitEffect.Anchored = true
                hitEffect.CanCollide = false
                hitEffect.Material = Enum.Material.Neon
                hitEffect.Color = Color3.fromRGB(255, 50, 50)
                hitEffect.Transparency = 0.3
                hitEffect.Parent = workspace
                Debris:AddItem(hitEffect, 0.5)
                
                p.Character.Humanoid.Health = 0
                print("💀 Убит:", p.Name)
            end
        end
    end
    
    task.wait(0.3)
    hrp.CFrame = CFrame.new(hrp.Position)
    knife:Destroy()
    
    bagFull = false
    collected = 0
    counterVal.Text = "0"
    print("🔪 === КОНЕЦ УБИЙСТВА ===")
end

-- 🚀 ВЫБРОС МАРДЕРА В КОСМОС (С ОТЛАДКОЙ)
function throwMurdererToSpace()
    print("🚀 === НАЧАЛО ВЫБРОСА МАРДЕРА ===")
    deathSound:Play()
    
    local murdererPlayer = nil
    print("🔍 Ищем мардера среди", #Players:GetPlayers(), "игроков...")
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local role = getPlayerRole(p)
            print("  Игрок:", p.Name, "→ Роль:", role)
            if role == "Murderer" then
                murdererPlayer = p
                print("  ✅ НАЙДЕН МАРДЕР:", p.Name)
                break
            end
        end
    end
    
    if murdererPlayer then
        print("🎯 Мардер найден:", murdererPlayer.Name)
        
        if murdererPlayer.Character and murdererPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local murdererHrp = murdererPlayer.Character.HumanoidRootPart
            local murdererHum = murdererPlayer.Character:FindFirstChild("Humanoid")
            
            -- 1. Отключаем управление мардеру
            if murdererHum then
                murdererHum.PlatformStand = true
                print("  ✅ PlatformStand установлен")
            end
            
            -- 2. Мгновенно телепортируем мардера высоко в небо
            local spacePosition = murdererHrp.Position + Vector3.new(0, 5000, 0)
            murdererHrp.CFrame = CFrame.new(spacePosition)
            print("  ✅ Телепортирован на высоту 5000")
            
            -- 3. Добавляем BodyVelocity
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.Velocity = Vector3.new(0, 10000, 0)
            bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVel.Parent = murdererHrp
            Debris:AddItem(bodyVel, 10)
            print("  ✅ BodyVelocity добавлен")
            
            -- 4. Добавляем BodyAngularVelocity для вращения
            local bodyAng = Instance.new("BodyAngularVelocity")
            bodyAng.AngularVelocity = Vector3.new(50, 50, 50)
            bodyAng.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bodyAng.Parent = murdererHrp
            Debris:AddItem(bodyAng, 10)
            print("  ✅ BodyAngularVelocity добавлен")
            
            -- 5. Отключаем коллизии
            for _, part in ipairs(murdererPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            print("  ✅ Коллизии отключены")
            
            -- 6. Визуальный эффект (фиолетовый след)
            task.spawn(function()
                for i = 1, 30 do
                    task.wait(0.1)
                    if murdererHrp.Parent then
                        local trail = Instance.new("Part")
                        trail.Size = Vector3.new(2, 2, 2)
                        trail.Position = murdererHrp.Position
                        trail.Anchored = true
                        trail.CanCollide = false
                        trail.Material = Enum.Material.Neon
                        trail.Color = Color3.fromRGB(155, 60, 255)
                        trail.Transparency = 0.3
                        trail.Parent = workspace
                        Debris:AddItem(trail, 1.5)
                    end
                end
            end)
            print("  ✅ Визуальный эффект запущен")
            
            -- 7. Фиолетовая вспышка
            local flash = Instance.new("Part")
            flash.Size = Vector3.new(15, 15, 15)
            flash.Position = murdererHrp.Position - Vector3.new(0, 5000, 0)
            flash.Anchored = true
            flash.CanCollide = false
            flash.Material = Enum.Material.Neon
            flash.Color = Color3.fromRGB(155, 60, 255)
            flash.Transparency = 0.5
            flash.Parent = workspace
            Debris:AddItem(flash, 2)
            
            local light = Instance.new("PointLight")
            light.Brightness = 15
            light.Range = 40
            light.Color = Color3.fromRGB(155, 60, 255)
            light.Parent = flash
            print("  ✅ Вспышка создана")
            
            print("🚀", murdererPlayer.Name, "улетел в космос!")
        else
            print("❌ У мардера нет HumanoidRootPart!")
        end
    else
        print("❌ МАРДЕР НЕ НАЙДЕН!")
        print("💡 Возможно, роль определяется иначе. Попробую альтернативный поиск...")
        
        -- Альтернативный поиск через leaderstats
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local ls = p:FindFirstChild("leaderstats")
                if ls then
                    for _, v in ipairs(ls:GetChildren()) do
                        if v.Value == "Murderer" or v.Value == "murderer" or v.Value == "MURDERER" then
                            murdererPlayer = p
                            print("✅ НАЙДЕН через leaderstats:", p.Name)
                            break
                        end
                    end
                end
                if murdererPlayer then break end
            end
        end
        
        if murdererPlayer and murdererPlayer.Character and murdererPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local murdererHrp = murdererPlayer.Character.HumanoidRootPart
            local murdererHum = murdererPlayer.Character:FindFirstChild("Humanoid")
            
            if murdererHum then murdererHum.PlatformStand = true end
            
            local spacePosition = murdererHrp.Position + Vector3.new(0, 5000, 0)
            murdererHrp.CFrame = CFrame.new(spacePosition)
            
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.Velocity = Vector3.new(0, 10000, 0)
            bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVel.Parent = murdererHrp
            Debris:AddItem(bodyVel, 10)
            
            local bodyAng = Instance.new("BodyAngularVelocity")
            bodyAng.AngularVelocity = Vector3.new(50, 50, 50)
            bodyAng.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bodyAng.Parent = murdererHrp
            Debris:AddItem(bodyAng, 10)
            
            for _, part in ipairs(murdererPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            print("🚀", murdererPlayer.Name, "улетел в космос (альтернативный поиск)!")
        else
            print("❌ МАРДЕР ТАК И НЕ НАЙДЕН!")
        end
    end
    
    print("🔄 Сбрасываем счётчик...")
    bagFull = false
    collected = 0
    counterVal.Text = "0"
    print("🚀 === КОНЕЦ ВЫБРОСА МАРДЕРА ===")
end

function flyTo(pos, speed)
    if not rootPart or farmStopped then return false end
    local distance = (pos - rootPart.Position).Magnitude
    local duration = math.max(0.1, distance / speed)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(pos)})
    tween:Play()
    local cancelled = false
    local timeout = task.delay(duration + 2, function()
        cancelled = true
        tween:Cancel()
    end)
    tween.Completed:Wait()
    if not cancelled then task.cancel(timeout) end
    return not cancelled
end

function startFarming()
    collected = 0
    startTime = tick()
    visitedPositions = {}
    bagFull = false
    farmStopped = false
    
    counterVal.Text = "0"
    timerVal.Text = "0s"
    rateVal.Text = "0"
    updateRoleUI()
    updateBagUI()
    
    print("🚀 ФАРМ ЗАПУЩЕН!")

    task.spawn(function()
        while isActive do
            local elapsed = tick() - startTime
            timerVal.Text = math.floor(elapsed) .. "s"
            local rate = elapsed > 0 and math.floor((collected / elapsed) * 3600) or 0
            rateVal.Text = tostring(rate)
            task.wait(0.1)
        end
    end)

    task.spawn(function()
        while isActive do
            if farmStopped then
                task.wait(1)
                continue
            end

            character = player.Character or player.CharacterAdded:Wait()
            rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then task.wait(0.5) continue end

            checkRole()

            local closest, shortest = nil, math.huge
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name == "Coin_Server" then
                    if obj.Parent and obj:IsDescendantOf(workspace) and not visitedPositions[obj] then
                        local dist = (obj.Position - rootPart.Position).Magnitude
                        if dist < shortest and dist < 300 then
                            closest = obj
                            shortest = dist
                        end
                    end
                end
            end

            if closest then
                local coinPos = closest.Position
                visitedPositions[closest] = true
                
                if farmStopped then continue end
                
                local arrived = flyTo(coinPos, flySpeed)

                if farmStopped then continue end

                if arrived then
                    task.wait(0.3)
                    
                    if closest.Parent and closest:IsDescendantOf(workspace) then
                        local distToCoin = (closest.Position - rootPart.Position).Magnitude
                        if distToCoin < 5 then
                            collected = collected + 1
                            counterVal.Text = tostring(collected)
                            collectSound:Play()
                            updateBagUI()
                            print("✅ Собрано:", collected, "/", MAX_BAG)
                            
                            -- 🔥 ПРОВЕРКА ПОЛНОГО МЕШКА С ОТЛАДКОЙ
                            if collected >= MAX_BAG and not farmStopped then
                                print("🎒 === МЕШОК ПОЛОН! ===")
                                print("  Собрано:", collected, "/", MAX_BAG)
                                print("  farmStopped:", farmStopped)
                                
                                bagFull = true
                                farmStopped = true
                                updateBagUI()
                                checkRole()
                                
                                print("  isMurderer:", isMurderer)
                                print("  isSheriff:", isSheriff)

                                if isMurderer then
                                    print("🔪 Вызываем cinematicMurdererKill()...")
                                    cinematicMurdererKill()
                                else
                                    print("🚀 Вызываем throwMurdererToSpace()...")
                                    throwMurdererToSpace()
                                end
                                
                                print("🛑 Вызываем stopFarming()...")
                                stopFarming()
                                print("🎒 === КОНЕЦ ОБРАБОТКИ ПОЛНОГО МЕШКА ===")
                            end
                        else
                            print("⚠️ Монета существует, но мы далеко — пропускаем")
                        end
                    else
                        print("❌ Монета исчезла (собрал кто-то другой)")
                    end
                end
            else
                if next(visitedPositions) then
                    visitedPositions = {}
                end
                task.wait(1)
            end

            task.wait(0.1)
        end
    end)
end

-- КНОПКИ
local farmToggle = toggleCard(1, "Auto Farm", function(state)
    isActive = state
    print("🎮 Auto Farm:", state and "ВКЛ" or "ВЫКЛ")
    if state then startFarming() end
end)

local afkToggle = toggleCard(2, "Anti-AFK", function(state)
    antiAFK = state
    print("🛡️ Anti-AFK:", state and "ВКЛ" or "ВЫКЛ")
end)

local espToggle = toggleCard(3, "ESP Roles", function(state)
    espEnabled = state
    print("👁️ ESP:", state and "ВКЛ" or "ВЫКЛ")
    updateESP()
end)

-- Скорость
local speedCard = Instance.new("Frame")
speedCard.Size = UDim2.new(1, 0, 0, 44)
speedCard.BackgroundColor3 = COL.card
speedCard.BorderSizePixel = 0
speedCard.LayoutOrder = 4
speedCard.ZIndex = 2
speedCard.Parent = body
corner(speedCard, 10)
stroke(speedCard, COL.border, 1)
do
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -90, 1, 0)
    t.Position = UDim2.new(0, 14, 0, 0)
    t.BackgroundTransparency = 1
    t.Text = "Farm Speed"
    t.TextColor3 = COL.text
    t.Font = Enum.Font.GothamSemibold
    t.TextSize = 14
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 2
    t.Parent = speedCard
end
local speedPillLbl
do
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 52, 0, 24)
    pill.Position = UDim2.new(1, -66, 0.5, -12)
    pill.BackgroundColor3 = ACCENT.dim
    pill.BorderSizePixel = 0
    pill.ZIndex = 2
    pill.Parent = speedCard
    corner(pill, 12)
    stroke(pill, ACCENT.base, 1)
    speedPillLbl = Instance.new("TextLabel")
    speedPillLbl.Size = UDim2.new(1, 0, 1, 0)
    speedPillLbl.BackgroundTransparency = 1
    speedPillLbl.Text = tostring(flySpeed)
    speedPillLbl.TextColor3 = ACCENT.light
    speedPillLbl.Font = Enum.Font.GothamBold
    speedPillLbl.TextSize = 12
    speedPillLbl.ZIndex = 2
    speedPillLbl.Parent = pill
end
local speedBtn = Instance.new("TextButton")
speedBtn.Size = UDim2.new(1, 0, 1, 0)
speedBtn.BackgroundTransparency = 1
speedBtn.Text = ""
speedBtn.ZIndex = 3
speedBtn.Parent = speedCard
speedBtn.MouseButton1Click:Connect(function()
    flySpeed = flySpeed + 5
    if flySpeed > 50 then flySpeed = 10 end
    speedPillLbl.Text = tostring(flySpeed)
end)

-- Лимит
do
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 44)
    card.BackgroundColor3 = COL.card
    card.BorderSizePixel = 0
    card.LayoutOrder = 13
    card.ZIndex = 2
    card.Parent = body
    corner(card, 10)
    stroke(card, COL.border, 1)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0.6, 0, 1, 0)
    t.Position = UDim2.new(0, 14, 0, 0)
    t.BackgroundTransparency = 1
    t.Text = "Bag Limit:"
    t.TextColor3 = COL.text
    t.Font = Enum.Font.GothamSemibold
    t.TextSize = 14
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ZIndex = 2
    t.Parent = card

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 72, 0, 30)
    pill.Position = UDim2.new(0.75, 0, 0.5, -15)
    pill.BackgroundColor3 = ACCENT.base
    pill.BorderSizePixel = 0
    pill.ZIndex = 2
    pill.Parent = card
    corner(pill, 8)
    stroke(pill, ACCENT.light, 1)

    local pillLabel = Instance.new("TextLabel")
    pillLabel.Size = UDim2.new(1, 0, 1, 0)
    pillLabel.BackgroundTransparency = 1
    pillLabel.Text = tostring(MAX_BAG) .. " 🪙"
    pillLabel.TextColor3 = COL.white
    pillLabel.Font = Enum.Font.GothamBold
    pillLabel.TextSize = 14
    pillLabel.ZIndex = 2
    pillLabel.Parent = pill

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 3
    btn.Parent = card

    btn.MouseButton1Click:Connect(function()
        if MAX_BAG == 40 then MAX_BAG = 50 else MAX_BAG = 40 end
        pillLabel.Text = tostring(MAX_BAG) .. " 🪙"
        tw(pill, {Size = UDim2.new(0, 80, 0, 34)}, 0.1)
        task.wait(0.1)
        tw(pill, {Size = UDim2.new(0, 72, 0, 30)}, 0.1)
    end)
end

-- Reset
do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = COL.card
    btn.Text = "Reset & Resume"
    btn.TextColor3 = COL.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.LayoutOrder = 14
    btn.ZIndex = 2
    btn.Parent = body
    corner(btn, 10)
    stroke(btn, COL.border, 1)
    btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3 = COL.cardHov}) end)
    btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3 = COL.card}) end)
    btn.MouseButton1Click:Connect(function()
        collected = 0
        startTime = tick()
        counterVal.Text = "0"
        timerVal.Text = "0s"
        rateVal.Text = "0"
        bagFull = false
        farmStopped = false
        visitedPositions = {}
        updateBagUI()
        print("🔄 Сброс!")
    end)
end

-- Кнопка 💎
local menuButton = Instance.new("TextButton")
menuButton.Size = UDim2.new(0, 65, 0, 65)
menuButton.Position = UDim2.new(0, 15, 1, -85)
menuButton.BackgroundColor3 = ACCENT.base
menuButton.Text = "💎"
menuButton.TextColor3 = COL.white
menuButton.TextSize = 28
menuButton.Font = Enum.Font.GothamBold
menuButton.ZIndex = 10
menuButton.Parent = gui
corner(menuButton, 32)
stroke(menuButton, ACCENT.light, 2)
menuButton.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- ESP
function updateESP()
    for _, highlight in pairs(espHighlights) do
        if highlight then highlight:Destroy() end
    end
    espHighlights = {}
    if not espEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local role = getPlayerRole(p)
            local color
            if role == "Murderer" then color = Color3.fromRGB(255, 50, 50)
            elseif role == "Sheriff" then color = Color3.fromRGB(50, 150, 255)
            else color = Color3.fromRGB(50, 255, 50) end
            
            local highlight = Instance.new("Highlight")
            highlight.FillColor = color
            highlight.OutlineColor = color
            highlight.FillTransparency = 0.7
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = p.Character
            espHighlights[p] = highlight
        end
    end
end

task.spawn(function()
    while true do
        if espEnabled then updateESP() end
        task.wait(2)
    end
end)

-- СИСТЕМНЫЕ СОБЫТИЯ
player.CharacterAdded:Connect(function(char)
    character = char
    rootPart = char:WaitForChild("HumanoidRootPart")
    visitedPositions = {}
    farmStopped = false
    task.wait(1.5)
    checkRole()
    updateRoleUI()
end)

player.Idled:Connect(function()
    if antiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

RunService.Stepped:Connect(function()
    if isActive and character and not farmStopped then
        for _, v in ipairs(character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

updateRoleUI()
updateBagUI()

print("✅ [egor745top6] Coin Farm ГОТОВ!")
print("🔍 Открой консоль (F9) чтобы видеть отладку!")
