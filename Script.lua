--// Aura Futebol - ALL-IN-ONE (v22 - Detecta Jogadores e NPCs)
--// by: @willnzx.mt
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============ CONFIGURAÇÕES ============
local AUTO_SEGUIR = false
local COOLDOWN_TP = 0.1
local ULTIMO_TP = 0
local DISTANCIA_FRENTE = 5

local ORBITAL_ATIVO = false
local RAIO_ORB = 5
local VELOCIDADE_ORB = 5
local ALTURA_ORB = 3
local ANGULO_ORB = 0

local ESPIRAL_ATIVO = false
local RAIO_INICIAL = 15
local VELOCIDADE_ESP = 3
local VELOCIDADE_APROX = 0.5
local ALTURA_ESP = 3
local ANGULO_ESP = 0
local RAIO_ATUAL = 15

local AUTO_STEAL = false
local COOLDOWN_STEAL = 0.3
local DISTANCIA_STEAL = 6
local ULTIMO_STEAL = 0

local DISTANCIA_POSSE = 3
local ESTAVA_COM_BOLA = false
local SUAVIZACAO = 0.2
local BORDA_RGB = true
local VELOCIDADE_RGB = 1

local BALL_TRACKER = false
local BALL_RADIUS = false
local BALL_HIGHLIGHT = false
local BALL_LINE = false
local BALL_SPEED = false
local BALL_PIN = false
local BALL_MARKER = false
local RAINBOW_BALL = false
local BALL_TRAIL = false
local BALL_COUNTER = false

local ballRadiusPart = nil
local ballHighlight = nil
local ballLine = nil
local ballPin = nil
local ballMarker = nil
local ballTrail = nil
local trackerLabel = nil
local speedLabel = nil
local counterLabel = nil
local counterValor = 0
local ultimoToque = 0
local ANGULO_MARKER = 0
-- ========================================

local function forcarVisivel(pai)
    for _, obj in ipairs(pai:GetChildren()) do
        if obj:IsA("GuiObject") then
            if not obj.Visible or obj.Transparency >= 0.99 then
                pcall(function()
                    obj.Visible = true
                    if obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("TextLabel") or obj:IsA("ImageLabel") then
                        obj.Transparency = 0
                        if obj.BackgroundTransparency ~= nil then
                            obj.BackgroundTransparency = 0
                        end
                    end
                end)
            end
            forcarVisivel(obj)
        end
    end
end

local function restaurarControles()
    for i = 1, 7 do
        pcall(function() forcarVisivel(PlayerGui) end)
        pcall(function() forcarVisivel(game:GetService("CoreGui")) end)
        task.wait(0.02)
    end
end

local function temPosseReal(bola, hrp)
    local distVoce = (bola.Position - hrp.Position).Magnitude
    if distVoce > DISTANCIA_POSSE then return false end

    local menorDist = distVoce
    local outroMaisPerto = false

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local outroHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if outroHrp then
                local d = (bola.Position - outroHrp.Position).Magnitude
                if d < menorDist then
                    menorDist = d
                    outroMaisPerto = true
                end
            end
        end
    end

    if not outroMaisPerto then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Health > 0 and obj.Parent ~= LocalPlayer.Character then
                local npcHrp = obj.Parent:FindFirstChild("HumanoidRootPart")
                if npcHrp then
                    local d = (bola.Position - npcHrp.Position).Magnitude
                    if d < menorDist and d < 5 then
                        menorDist = d
                        outroMaisPerto = true
                    end
                end
            end
        end
    end

    if outroMaisPerto then return false end
    return true
end

local function criarTrackerLabel()
    if trackerLabel then trackerLabel:Destroy() end
    trackerLabel = Instance.new("TextLabel")
    trackerLabel.Size = UDim2.new(0, 200, 0, 35)
    trackerLabel.Position = UDim2.new(0.5, -100, 0, 100)
    trackerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    trackerLabel.BackgroundTransparency = 0.3
    trackerLabel.BorderSizePixel = 0
    trackerLabel.Text = "Bola: 0 studs"
    trackerLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    trackerLabel.Font = Enum.Font.GothamBold
    trackerLabel.TextSize = 16
    trackerLabel.Parent = PlayerGui
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = trackerLabel
    local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(0, 255, 100) s.Thickness = 2 s.Parent = trackerLabel
end

local function criarSpeedLabel()
    if speedLabel then speedLabel:Destroy() end
    speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0, 200, 0, 30)
    speedLabel.Position = UDim2.new(0.5, -100, 0, 140)
    speedLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    speedLabel.BackgroundTransparency = 0.3
    speedLabel.BorderSizePixel = 0
    speedLabel.Text = "Velocidade: 0"
    speedLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    speedLabel.Font = Enum.Font.GothamBold
    speedLabel.TextSize = 14
    speedLabel.Parent = PlayerGui
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = speedLabel
    local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(255, 200, 100) s.Thickness = 2 s.Parent = speedLabel
end

local function criarCounterLabel()
    if counterLabel then counterLabel:Destroy() end
    counterLabel = Instance.new("TextLabel")
    counterLabel.Size = UDim2.new(0, 200, 0, 30)
    counterLabel.Position = UDim2.new(0.5, -100, 0, 175)
    counterLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    counterLabel.BackgroundTransparency = 0.3
    counterLabel.BorderSizePixel = 0
    counterLabel.Text = "Toques: 0"
    counterLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
    counterLabel.Font = Enum.Font.GothamBold
    counterLabel.TextSize = 14
    counterLabel.Parent = PlayerGui
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = counterLabel
    local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(150, 150, 255) s.Thickness = 2 s.Parent = counterLabel
end

local function criarBallRadius(bola)
    if ballRadiusPart then ballRadiusPart:Destroy() end
    ballRadiusPart = Instance.new("Part")
    ballRadiusPart.Name = "BallRadiusVisual"
    ballRadiusPart.Shape = Enum.PartType.Cylinder
    ballRadiusPart.Size = Vector3.new(1, 10, 10)
    ballRadiusPart.Anchored = true
    ballRadiusPart.CanCollide = false
    ballRadiusPart.CanQuery = false
    ballRadiusPart.CanTouch = false
    ballRadiusPart.Transparency = 0.7
    ballRadiusPart.Color = Color3.fromRGB(0, 255, 100)
    ballRadiusPart.Material = Enum.Material.Neon
    ballRadiusPart.CFrame = CFrame.new(bola.Position) * CFrame.Angles(0, 0, math.rad(90))
    ballRadiusPart.Parent = workspace
end

local function criarBallHighlight(bola)
    if ballHighlight then ballHighlight:Destroy() end
    ballHighlight = Instance.new("Highlight")
    ballHighlight.FillColor = Color3.fromRGB(0, 255, 100)
    ballHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    ballHighlight.FillTransparency = 0.5
    ballHighlight.OutlineTransparency = 0
    ballHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    ballHighlight.Adornee = bola
    ballHighlight.Parent = PlayerGui
end

local function criarBallPin()
    if ballPin then ballPin:Destroy() end
    ballPin = Instance.new("TextLabel")
    ballPin.Size = UDim2.new(0, 40, 0, 40)
    ballPin.BackgroundTransparency = 1
    ballPin.Text = "⬆️"
    ballPin.TextColor3 = Color3.fromRGB(0, 255, 100)
    ballPin.TextSize = 30
    ballPin.Font = Enum.Font.GothamBold
    ballPin.Visible = false
    ballPin.Parent = PlayerGui
end

local function criarBallMarker(bola)
    if ballMarker then ballMarker:Destroy() end
    ballMarker = Instance.new("Part")
    ballMarker.Name = "BallMarkerVisual"
    ballMarker.Shape = Enum.PartType.Cylinder
    ballMarker.Size = Vector3.new(0.3, 4, 4)
    ballMarker.Anchored = true
    ballMarker.CanCollide = false
    ballMarker.CanQuery = false
    ballMarker.CanTouch = false
    ballMarker.Transparency = 0.3
    ballMarker.Color = Color3.fromRGB(255, 255, 0)
    ballMarker.Material = Enum.Material.Neon
    ballMarker.CFrame = bola.CFrame
    ballMarker.Parent = workspace
end

local function criarBallTrail(bola)
    if ballTrail then ballTrail:Destroy() end
    ballTrail = Instance.new("Trail")
    local att1 = Instance.new("Attachment", bola)
    local att2 = Instance.new("Attachment", bola)
    att2.Position = Vector3.new(0, 0.5, 0)
    ballTrail.Attachment0 = att1
    ballTrail.Attachment1 = att2
    ballTrail.Lifetime = 0.5
    ballTrail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))
    })
    ballTrail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    ballTrail.Parent = bola
end

-- ===== GUI =====
local gui = nil
local statusPosseLabel = nil

local function criarGUI()
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui")
    gui.Name = "AuraAllInOne"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    gui.Parent = PlayerGui

    local botaoAbrir = Instance.new("TextButton")
    botaoAbrir.Size = UDim2.new(0, 60, 0, 60)
    botaoAbrir.Position = UDim2.new(0, 20, 0.5, -30)
    botaoAbrir.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    botaoAbrir.Text = "⚽"
    botaoAbrir.TextColor3 = Color3.fromRGB(255, 255, 255)
    botaoAbrir.TextSize = 28
    botaoAbrir.Font = Enum.Font.GothamBold
    botaoAbrir.BorderSizePixel = 0
    botaoAbrir.Active = true
    botaoAbrir.Draggable = true
    botaoAbrir.Parent = gui

    local cA = Instance.new("UICorner") cA.CornerRadius = UDim.new(1, 0) cA.Parent = botaoAbrir
    local strokeA = Instance.new("UIStroke") strokeA.Color = Color3.fromRGB(0, 200, 255) strokeA.Thickness = 2 strokeA.Parent = botaoAbrir

    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(0, 420, 0, 520)
    menu.Position = UDim2.new(0.5, -210, 0.5, -260)
    menu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    menu.BorderSizePixel = 0
    menu.Visible = false
    menu.Active = true
    menu.Draggable = true
    menu.Parent = gui

    local cM = Instance.new("UICorner") cM.CornerRadius = UDim.new(0, 14) cM.Parent = menu
    local gradienteMenu = Instance.new("UIGradient")
    gradienteMenu.Rotation = 90
    gradienteMenu.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
    })
    gradienteMenu.Parent = menu

    local strokeM = Instance.new("UIStroke")
    strokeM.Color = Color3.fromRGB(255, 0, 0)
    strokeM.Thickness = 2.5
    strokeM.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    strokeM.Parent = menu

    task.spawn(function()
        local tempo = 0
        while gui and gui.Parent do
            tempo = tempo + (0.05 * VELOCIDADE_RGB)
            local r = math.sin(tempo) * 0.5 + 0.5
            local g = math.sin(tempo + 2) * 0.5 + 0.5
            local b = math.sin(tempo + 4) * 0.5 + 0.5
            pcall(function() strokeM.Color = Color3.new(r, g, b) end)
            task.wait(0.05)
        end
    end)

    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, 0, 0, 42)
    titulo.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
    titulo.BorderSizePixel = 0
    titulo.Text = "by: @willnzx.mt"
    titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
    titulo.Font = Enum.Font.GothamBold
    titulo.TextSize = 15
    titulo.Parent = menu
    local cT = Instance.new("UICorner") cT.CornerRadius = UDim.new(0, 14) cT.Parent = titulo
    local gradienteTitulo = Instance.new("UIGradient")
    gradienteTitulo.Rotation = 90
    gradienteTitulo.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 180, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 80, 150))
    })
    gradienteTitulo.Parent = titulo

    statusPosseLabel = Instance.new("TextLabel")
    statusPosseLabel.Size = UDim2.new(0.9, 0, 0, 22)
    statusPosseLabel.Position = UDim2.new(0.05, 0, 0, 88)
    statusPosseLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    statusPosseLabel.BorderSizePixel = 0
    statusPosseLabel.Text = "⚽ Status: SEM BOLA"
    statusPosseLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    statusPosseLabel.Font = Enum.Font.GothamBold
    statusPosseLabel.TextSize = 11
    statusPosseLabel.Parent = menu
    local cSP = Instance.new("UICorner") cSP.CornerRadius = UDim.new(0, 6) cSP.Parent = statusPosseLabel

    -- ===== ABAS =====
    local abaWidth = 0.15
    local btnAbaMain = Instance.new("TextButton")
    btnAbaMain.Size = UDim2.new(abaWidth, 0, 0, 32)
    btnAbaMain.Position = UDim2.new(0.02, 0, 0, 50)
    btnAbaMain.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
    btnAbaMain.Text = "🎯"
    btnAbaMain.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAbaMain.Font = Enum.Font.GothamBold
    btnAbaMain.TextSize = 16
    btnAbaMain.BorderSizePixel = 0
    btnAbaMain.Parent = menu
    local cAb1 = Instance.new("UICorner") cAb1.CornerRadius = UDim.new(0, 8) cAb1.Parent = btnAbaMain

    local btnAbaOrb = Instance.new("TextButton")
    btnAbaOrb.Size = UDim2.new(abaWidth, 0, 0, 32)
    btnAbaOrb.Position = UDim2.new(0.18, 0, 0, 50)
    btnAbaOrb.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    btnAbaOrb.Text = "🌀"
    btnAbaOrb.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAbaOrb.Font = Enum.Font.GothamBold
    btnAbaOrb.TextSize = 16
    btnAbaOrb.BorderSizePixel = 0
    btnAbaOrb.Parent = menu
    local cAb2 = Instance.new("UICorner") cAb2.CornerRadius = UDim.new(0, 8) cAb2.Parent = btnAbaOrb

    local btnAbaEsp = Instance.new("TextButton")
    btnAbaEsp.Size = UDim2.new(abaWidth, 0, 0, 32)
    btnAbaEsp.Position = UDim2.new(0.34, 0, 0, 50)
    btnAbaEsp.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    btnAbaEsp.Text = "🌪️"
    btnAbaEsp.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAbaEsp.Font = Enum.Font.GothamBold
    btnAbaEsp.TextSize = 16
    btnAbaEsp.BorderSizePixel = 0
    btnAbaEsp.Parent = menu
    local cAb3 = Instance.new("UICorner") cAb3.CornerRadius = UDim.new(0, 8) cAb3.Parent = btnAbaEsp

    local btnAbaSteal = Instance.new("TextButton")
    btnAbaSteal.Size = UDim2.new(abaWidth, 0, 0, 32)
    btnAbaSteal.Position = UDim2.new(0.50, 0, 0, 50)
    btnAbaSteal.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    btnAbaSteal.Text = "🦶"
    btnAbaSteal.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAbaSteal.Font = Enum.Font.GothamBold
    btnAbaSteal.TextSize = 16
    btnAbaSteal.BorderSizePixel = 0
    btnAbaSteal.Parent = menu
    local cAb4 = Instance.new("UICorner") cAb4.CornerRadius = UDim.new(0, 8) cAb4.Parent = btnAbaSteal

    local btnAbaVisual = Instance.new("TextButton")
    btnAbaVisual.Size = UDim2.new(abaWidth, 0, 0, 32)
    btnAbaVisual.Position = UDim2.new(0.66, 0, 0, 50)
    btnAbaVisual.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    btnAbaVisual.Text = "👁️"
    btnAbaVisual.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAbaVisual.Font = Enum.Font.GothamBold
    btnAbaVisual.TextSize = 16
    btnAbaVisual.BorderSizePixel = 0
    btnAbaVisual.Parent = menu
    local cAb5 = Instance.new("UICorner") cAb5.CornerRadius = UDim.new(0, 8) cAb5.Parent = btnAbaVisual

    local btnAbaRest = Instance.new("TextButton")
    btnAbaRest.Size = UDim2.new(abaWidth, 0, 0, 32)
    btnAbaRest.Position = UDim2.new(0.82, 0, 0, 50)
    btnAbaRest.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    btnAbaRest.Text = "🔄"
    btnAbaRest.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAbaRest.Font = Enum.Font.GothamBold
    btnAbaRest.TextSize = 16
    btnAbaRest.BorderSizePixel = 0
    btnAbaRest.Parent = menu
    local cAb6 = Instance.new("UICorner") cAb6.CornerRadius = UDim.new(0, 8) cAb6.Parent = btnAbaRest

    -- ===== ABA MAIN =====

    local abaMain = Instance.new("Frame")
    abaMain.Size = UDim2.new(1, 0, 1, -150)
    abaMain.Position = UDim2.new(0, 0, 0, 115)
    abaMain.BackgroundTransparency = 1
    abaMain.Visible = true
    abaMain.Parent = menu

    local labelTituloMain = Instance.new("TextLabel")
    labelTituloMain.Size = UDim2.new(0.9, 0, 0, 30)
    labelTituloMain.Position = UDim2.new(0.05, 0, 0, 5)
    labelTituloMain.BackgroundTransparency = 1
    labelTituloMain.Text = "🎯 SEGUIR NA FRENTE"
    labelTituloMain.TextColor3 = Color3.fromRGB(100, 220, 255)
    labelTituloMain.Font = Enum.Font.GothamBold
    labelTituloMain.TextSize = 13
    labelTituloMain.Parent = abaMain

    local btnSeguir = Instance.new("TextButton")
    btnSeguir.Size = UDim2.new(0.9, 0, 0, 70)
    btnSeguir.Position = UDim2.new(0.05, 0, 0, 40)
    btnSeguir.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnSeguir.BorderSizePixel = 0
    btnSeguir.Text = "🎯 SEGUIR BOLA\n❌ OFF"
    btnSeguir.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnSeguir.Font = Enum.Font.GothamBold
    btnSeguir.TextSize = 16
    btnSeguir.Parent = abaMain
    local cSB = Instance.new("UICorner") cSB.CornerRadius = UDim.new(0, 12) cSB.Parent = btnSeguir

    local infoMain = Instance.new("TextLabel")
    infoMain.Size = UDim2.new(0.9, 0, 0, 80)
    infoMain.Position = UDim2.new(0.05, 0, 0, 125)
    infoMain.BackgroundTransparency = 1
    infoMain.Text = "Fica NA FRENTE do dono da bola.\n✅ Funciona com jogador E NPC\n✅ Pausa se você tiver posse"
    infoMain.TextColor3 = Color3.fromRGB(150, 150, 170)
    infoMain.Font = Enum.Font.Gotham
    infoMain.TextSize = 11
    infoMain.TextWrapped = true
    infoMain.Parent = abaMain

    -- ===== ABA ORBITAL =====
    local abaOrb = Instance.new("Frame")
    abaOrb.Size = UDim2.new(1, 0, 1, -150)
    abaOrb.Position = UDim2.new(0, 0, 0, 115)
    abaOrb.BackgroundTransparency = 1
    abaOrb.Visible = false
    abaOrb.Parent = menu

    local labelTituloOrb = Instance.new("TextLabel")
    labelTituloOrb.Size = UDim2.new(0.9, 0, 0, 30)
    labelTituloOrb.Position = UDim2.new(0.05, 0, 0, 5)
    labelTituloOrb.BackgroundTransparency = 1
    labelTituloOrb.Text = "🌀 ORBITAL (na frente do dono)"
    labelTituloOrb.TextColor3 = Color3.fromRGB(200, 100, 255)
    labelTituloOrb.Font = Enum.Font.GothamBold
    labelTituloOrb.TextSize = 13
    labelTituloOrb.Parent = abaOrb

    local btnOrbital = Instance.new("TextButton")
    btnOrbital.Size = UDim2.new(0.9, 0, 0, 55)
    btnOrbital.Position = UDim2.new(0.05, 0, 0, 40)
    btnOrbital.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnOrbital.BorderSizePixel = 0
    btnOrbital.Text = "🌀 ORBITAL ATIVO\n❌ OFF"
    btnOrbital.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnOrbital.Font = Enum.Font.GothamBold
    btnOrbital.TextSize = 14
    btnOrbital.Parent = abaOrb
    local cOB = Instance.new("UICorner") cOB.CornerRadius = UDim.new(0, 10) cOB.Parent = btnOrbital

    local labelRaioOrb = Instance.new("TextLabel")
    labelRaioOrb.Size = UDim2.new(0.9, 0, 0, 20)
    labelRaioOrb.Position = UDim2.new(0.05, 0, 0, 105)
    labelRaioOrb.BackgroundTransparency = 1
    labelRaioOrb.Text = "Raio: " .. RAIO_ORB .. " studs"
    labelRaioOrb.TextColor3 = Color3.fromRGB(200, 200, 220)
    labelRaioOrb.Font = Enum.Font.GothamBold
    labelRaioOrb.TextSize = 11
    labelRaioOrb.Parent = abaOrb

    local btnRaioMaisOrb = Instance.new("TextButton")
    btnRaioMaisOrb.Size = UDim2.new(0.42, 0, 0, 30)
    btnRaioMaisOrb.Position = UDim2.new(0.05, 0, 0, 128)
    btnRaioMaisOrb.BackgroundColor3 = Color3.fromRGB(140, 60, 200)
    btnRaioMaisOrb.Text = "➕ RAIO"
    btnRaioMaisOrb.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnRaioMaisOrb.Font = Enum.Font.GothamBold
    btnRaioMaisOrb.TextSize = 11
    btnRaioMaisOrb.BorderSizePixel = 0
    btnRaioMaisOrb.Parent = abaOrb
    local cR1 = Instance.new("UICorner") cR1.CornerRadius = UDim.new(0, 8) cR1.Parent = btnRaioMaisOrb

    local btnRaioMenosOrb = Instance.new("TextButton")
    btnRaioMenosOrb.Size = UDim2.new(0.42, 0, 0, 30)
    btnRaioMenosOrb.Position = UDim2.new(0.53, 0, 0, 128)
    btnRaioMenosOrb.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnRaioMenosOrb.Text = "➖ RAIO"
    btnRaioMenosOrb.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnRaioMenosOrb.Font = Enum.Font.GothamBold
    btnRaioMenosOrb.TextSize = 11
    btnRaioMenosOrb.BorderSizePixel = 0
    btnRaioMenosOrb.Parent = abaOrb
    local cR2 = Instance.new("UICorner") cR2.CornerRadius = UDim.new(0, 8) cR2.Parent = btnRaioMenosOrb

    local labelVelOrb = Instance.new("TextLabel")
    labelVelOrb.Size = UDim2.new(0.9, 0, 0, 20)
    labelVelOrb.Position = UDim2.new(0.05, 0, 0, 165)
    labelVelOrb.BackgroundTransparency = 1
    labelVelOrb.Text = "Velocidade: " .. VELOCIDADE_ORB
    labelVelOrb.TextColor3 = Color3.fromRGB(200, 200, 220)
    labelVelOrb.Font = Enum.Font.GothamBold
    labelVelOrb.TextSize = 11
    labelVelOrb.Parent = abaOrb

    local btnVelMaisOrb = Instance.new("TextButton")
    btnVelMaisOrb.Size = UDim2.new(0.42, 0, 0, 30)
    btnVelMaisOrb.Position = UDim2.new(0.05, 0, 0, 188)
    btnVelMaisOrb.BackgroundColor3 = Color3.fromRGB(140, 60, 200)
    btnVelMaisOrb.Text = "➕ VELOCIDADE"
    btnVelMaisOrb.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnVelMaisOrb.Font = Enum.Font.GothamBold
    btnVelMaisOrb.TextSize = 11
    btnVelMaisOrb.BorderSizePixel = 0
    btnVelMaisOrb.Parent = abaOrb
    local cV1 = Instance.new("UICorner") cV1.CornerRadius = UDim.new(0, 8) cV1.Parent = btnVelMaisOrb

    local btnVelMenosOrb = Instance.new("TextButton")
    btnVelMenosOrb.Size = UDim2.new(0.42, 0, 0, 30)
    btnVelMenosOrb.Position = UDim2.new(0.53, 0, 0, 188)
    btnVelMenosOrb.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnVelMenosOrb.Text = "➖ VELOCIDADE"
    btnVelMenosOrb.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnVelMenosOrb.Font = Enum.Font.GothamBold
    btnVelMenosOrb.TextSize = 11
    btnVelMenosOrb.BorderSizePixel = 0
    btnVelMenosOrb.Parent = abaOrb
    local cV2 = Instance.new("UICorner") cV2.CornerRadius = UDim.new(0, 8) cV2.Parent = btnVelMenosOrb

    local infoOrb = Instance.new("TextLabel")
    infoOrb.Size = UDim2.new(0.9, 0, 0, 60)
    infoOrb.Position = UDim2.new(0.05, 0, 0, 228)
    infoOrb.BackgroundTransparency = 1
    infoOrb.Text = "🌀 Sempre orbita NA FRENTE do dono.\n✅ Jogador: usa direção do olhar\n✅ NPC: usa direção do movimento"
    infoOrb.TextColor3 = Color3.fromRGB(150, 150, 170)
    infoOrb.Font = Enum.Font.Gotham
    infoOrb.TextSize = 10
    infoOrb.TextWrapped = true
    infoOrb.Parent = abaOrb

    -- ===== ABA ESPIRAL =====
    local abaEsp = Instance.new("Frame")
    abaEsp.Size = UDim2.new(1, 0, 1, -150)
    abaEsp.Position = UDim2.new(0, 0, 0, 115)
    abaEsp.BackgroundTransparency = 1
    abaEsp.Visible = false
    abaEsp.Parent = menu

    local labelTituloEsp = Instance.new("TextLabel")
    labelTituloEsp.Size = UDim2.new(0.9, 0, 0, 30)
    labelTituloEsp.Position = UDim2.new(0.05, 0, 0, 5)
    labelTituloEsp.BackgroundTransparency = 1
    labelTituloEsp.Text = "🌪️ ESPIRAL BALL"
    labelTituloEsp.TextColor3 = Color3.fromRGB(255, 200, 100)
    labelTituloEsp.Font = Enum.Font.GothamBold
    labelTituloEsp.TextSize = 14
    labelTituloEsp.Parent = abaEsp

    local btnEspiral = Instance.new("TextButton")
    btnEspiral.Size = UDim2.new(0.9, 0, 0, 50)
    btnEspiral.Position = UDim2.new(0.05, 0, 0, 40)
    btnEspiral.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnEspiral.BorderSizePixel = 0
    btnEspiral.Text = "🌪️ ESPIRAL ATIVA\n❌ OFF"
    btnEspiral.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnEspiral.Font = Enum.Font.GothamBold
    btnEspiral.TextSize = 13
    btnEspiral.Parent = abaEsp
    local cE = Instance.new("UICorner") cE.CornerRadius = UDim.new(0, 10) cE.Parent = btnEspiral

    local labelRaioEsp = Instance.new("TextLabel")
    labelRaioEsp.Size = UDim2.new(0.9, 0, 0, 20)
    labelRaioEsp.Position = UDim2.new(0.05, 0, 0, 100)
    labelRaioEsp.BackgroundTransparency = 1
    labelRaioEsp.Text = "Raio Inicial: " .. RAIO_INICIAL
    labelRaioEsp.TextColor3 = Color3.fromRGB(200, 200, 220)
    labelRaioEsp.Font = Enum.Font.GothamBold
    labelRaioEsp.TextSize = 11
    labelRaioEsp.Parent = abaEsp

    local btnRaioMaisEsp = Instance.new("TextButton")
    btnRaioMaisEsp.Size = UDim2.new(0.42, 0, 0, 28)
    btnRaioMaisEsp.Position = UDim2.new(0.05, 0, 0, 122)
    btnRaioMaisEsp.BackgroundColor3 = Color3.fromRGB(200, 140, 60)
    btnRaioMaisEsp.Text = "➕ RAIO"
    btnRaioMaisEsp.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnRaioMaisEsp.Font = Enum.Font.GothamBold
    btnRaioMaisEsp.TextSize = 11
    btnRaioMaisEsp.BorderSizePixel = 0
    btnRaioMaisEsp.Parent = abaEsp
    local cRE1 = Instance.new("UICorner") cRE1.CornerRadius = UDim.new(0, 8) cRE1.Parent = btnRaioMaisEsp

    local btnRaioMenosEsp = Instance.new("TextButton")
    btnRaioMenosEsp.Size = UDim2.new(0.42, 0, 0, 28)
    btnRaioMenosEsp.Position = UDim2.new(0.53, 0, 0, 122)
    btnRaioMenosEsp.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnRaioMenosEsp.Text = "➖ RAIO"
    btnRaioMenosEsp.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnRaioMenosEsp.Font = Enum.Font.GothamBold
    btnRaioMenosEsp.TextSize = 11
    btnRaioMenosEsp.BorderSizePixel = 0
    btnRaioMenosEsp.Parent = abaEsp
    local cRE2 = Instance.new("UICorner") cRE2.CornerRadius = UDim.new(0, 8) cRE2.Parent = btnRaioMenosEsp

    local labelVelEsp = Instance.new("TextLabel")
    labelVelEsp.Size = UDim2.new(0.9, 0, 0, 20)
    labelVelEsp.Position = UDim2.new(0.05, 0, 0, 158)
    labelVelEsp.BackgroundTransparency = 1
    labelVelEsp.Text = "Velocidade: " .. VELOCIDADE_ESP
    labelVelEsp.TextColor3 = Color3.fromRGB(200, 200, 220)
    labelVelEsp.Font = Enum.Font.GothamBold
    labelVelEsp.TextSize = 11
    labelVelEsp.Parent = abaEsp

    local btnVelMaisEsp = Instance.new("TextButton")
    btnVelMaisEsp.Size = UDim2.new(0.42, 0, 0, 28)
    btnVelMaisEsp.Position = UDim2.new(0.05, 0, 0, 180)
    btnVelMaisEsp.BackgroundColor3 = Color3.fromRGB(200, 140, 60)
    btnVelMaisEsp.Text = "➕ VELOCIDADE"
    btnVelMaisEsp.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnVelMaisEsp.Font = Enum.Font.GothamBold
    btnVelMaisEsp.TextSize = 11
    btnVelMaisEsp.BorderSizePixel = 0
    btnVelMaisEsp.Parent = abaEsp
    local cVE1 = Instance.new("UICorner") cVE1.CornerRadius = UDim.new(0, 8) cVE1.Parent = btnVelMaisEsp

    local btnVelMenosEsp = Instance.new("TextButton")
    btnVelMenosEsp.Size = UDim2.new(0.42, 0, 0, 28)
    btnVelMenosEsp.Position = UDim2.new(0.53, 0, 0, 180)
    btnVelMenosEsp.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnVelMenosEsp.Text = "➖ VELOCIDADE"
    btnVelMenosEsp.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnVelMenosEsp.Font = Enum.Font.GothamBold
    btnVelMenosEsp.TextSize = 11
    btnVelMenosEsp.BorderSizePixel = 0
    btnVelMenosEsp.Parent = abaEsp
    local cVE2 = Instance.new("UICorner") cVE2.CornerRadius = UDim.new(0, 8) cVE2.Parent = btnVelMenosEsp

    local labelAproxEsp = Instance.new("TextLabel")
    labelAproxEsp.Size = UDim2.new(0.9, 0, 0, 20)
    labelAproxEsp.Position = UDim2.new(0.05, 0, 0, 216)
    labelAproxEsp.BackgroundTransparency = 1
    labelAproxEsp.Text = "Aproximação: " .. VELOCIDADE_APROX
    labelAproxEsp.TextColor3 = Color3.fromRGB(200, 200, 220)
    labelAproxEsp.Font = Enum.Font.GothamBold
    labelAproxEsp.TextSize = 11
    labelAproxEsp.Parent = abaEsp

    local btnAproxMaisEsp = Instance.new("TextButton")
    btnAproxMaisEsp.Size = UDim2.new(0.42, 0, 0, 28)
    btnAproxMaisEsp.Position = UDim2.new(0.05, 0, 0, 238)
    btnAproxMaisEsp.BackgroundColor3 = Color3.fromRGB(200, 140, 60)
    btnAproxMaisEsp.Text = "➕ APROXIMAR"
    btnAproxMaisEsp.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAproxMaisEsp.Font = Enum.Font.GothamBold
    btnAproxMaisEsp.TextSize = 11
    btnAproxMaisEsp.BorderSizePixel = 0
    btnAproxMaisEsp.Parent = abaEsp
    local cAP1 = Instance.new("UICorner") cAP1.CornerRadius = UDim.new(0, 8) cAP1.Parent = btnAproxMaisEsp

    local btnAproxMenosEsp = Instance.new("TextButton")
    btnAproxMenosEsp.Size = UDim2.new(0.42, 0, 0, 28)
    btnAproxMenosEsp.Position = UDim2.new(0.53, 0, 0, 238)
    btnAproxMenosEsp.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnAproxMenosEsp.Text = "➖ APROXIMAR"
    btnAproxMenosEsp.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAproxMenosEsp.Font = Enum.Font.GothamBold
    btnAproxMenosEsp.TextSize = 11
    btnAproxMenosEsp.BorderSizePixel = 0
    btnAproxMenosEsp.Parent = abaEsp
    local cAP2 = Instance.new("UICorner") cAP2.CornerRadius = UDim.new(0, 8) cAP2.Parent = btnAproxMenosEsp

    local infoEsp = Instance.new("TextLabel")
    infoEsp.Size = UDim2.new(0.9, 0, 0, 35)
    infoEsp.Position = UDim2.new(0.05, 0, 0, 275)
    infoEsp.BackgroundTransparency = 1
    infoEsp.Text = "Aproxima da bola em espiral.\nCom suavização (não trava)."
    infoEsp.TextColor3 = Color3.fromRGB(150, 150, 170)
    infoEsp.Font = Enum.Font.Gotham
    infoEsp.TextSize = 10
    infoEsp.TextWrapped = true
    infoEsp.Parent = abaEsp

    -- ===== ABA STEAL =====
    local abaSteal = Instance.new("Frame")
    abaSteal.Size = UDim2.new(1, 0, 1, -150)
    abaSteal.Position = UDim2.new(0, 0, 0, 115)
    abaSteal.BackgroundTransparency = 1
    abaSteal.Visible = false
    abaSteal.Parent = menu

    local labelTituloSteal = Instance.new("TextLabel")
    labelTituloSteal.Size = UDim2.new(0.9, 0, 0, 30)
    labelTituloSteal.Position = UDim2.new(0.05, 0, 0, 5)
    labelTituloSteal.BackgroundTransparency = 1
    labelTituloSteal.Text = "🦶 AUTO STEAL (Q)"
    labelTituloSteal.TextColor3 = Color3.fromRGB(255, 150, 100)
    labelTituloSteal.Font = Enum.Font.GothamBold
    labelTituloSteal.TextSize = 14
    labelTituloSteal.Parent = abaSteal

    local btnSteal = Instance.new("TextButton")
    btnSteal.Size = UDim2.new(0.9, 0, 0, 65)
    btnSteal.Position = UDim2.new(0.05, 0, 0, 40)
    btnSteal.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btnSteal.BorderSizePixel = 0
    btnSteal.Text = "🦶 AUTO STEAL\n❌ OFF"
    btnSteal.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnSteal.Font = Enum.Font.GothamBold
    btnSteal.TextSize = 15
    btnSteal.Parent = abaSteal
    local cSt = Instance.new("UICorner") cSt.CornerRadius = UDim.new(0, 10) cSt.Parent = btnSteal

    local infoSteal = Instance.new("TextLabel")
    infoSteal.Size = UDim2.new(0.9, 0, 0, 100)
    infoSteal.Position = UDim2.new(0.05, 0, 0, 120)
    infoSteal.BackgroundTransparency = 1
    infoSteal.Text = "Aperta Q automaticamente\nquando a bola tá perto (6 studs).\n\n✅ NUNCA pausa\n⚠️ Buga os botões mobile."
    infoSteal.TextColor3 = Color3.fromRGB(150, 150, 170)
    infoSteal.Font = Enum.Font.Gotham
    infoSteal.TextSize = 11
    infoSteal.TextWrapped = true
    infoSteal.Parent = abaSteal

    -- ===== ABA VISUAL =====
    local abaVisual = Instance.new("Frame")
    abaVisual.Size = UDim2.new(1, 0, 1, -150)
    abaVisual.Position = UDim2.new(0, 0, 0, 115)
    abaVisual.BackgroundTransparency = 1
    abaVisual.Visible = false
    abaVisual.Parent = menu

    local labelTituloVisual = Instance.new("TextLabel")
    labelTituloVisual.Size = UDim2.new(0.9, 0, 0, 30)
    labelTituloVisual.Position = UDim2.new(0.05, 0, 0, 5)
    labelTituloVisual.BackgroundTransparency = 1
    labelTituloVisual.Text = "👁️ VISUAL / INFO"
    labelTituloVisual.TextColor3 = Color3.fromRGB(100, 255, 200)
    labelTituloVisual.Font = Enum.Font.GothamBold
    labelTituloVisual.TextSize = 14
    labelTituloVisual.Parent = abaVisual

    local scrollV = Instance.new("ScrollingFrame")
    scrollV.Size = UDim2.new(0.9, 0, 1, -50)
    scrollV.Position = UDim2.new(0.05, 0, 0, 40)
    scrollV.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    scrollV.BorderSizePixel = 0
    scrollV.ScrollBarThickness = 6
    scrollV.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollV.Parent = abaVisual
    local cSV = Instance.new("UICorner") cSV.CornerRadius = UDim.new(0, 10) cSV.Parent = scrollV

    local layoutV = Instance.new("UIListLayout")
    layoutV.Padding = UDim.new(0, 5)
    layoutV.SortOrder = Enum.SortOrder.LayoutOrder
    layoutV.Parent = scrollV

    local paddingV = Instance.new("UIPadding")
    paddingV.PaddingTop = UDim.new(0, 5)
    paddingV.PaddingLeft = UDim.new(0, 5)
    paddingV.PaddingRight = UDim.new(0, 5)
    paddingV.Parent = scrollV

    local function criarToggleVisual(texto, ordem, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 45)
        btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        btn.BorderSizePixel = 0
        btn.Text = texto .. "\n❌ OFF"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.LayoutOrder = ordem
        btn.Parent = scrollV

        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = btn

        local estado = false
        btn.MouseButton1Click:Connect(function()
            estado = not estado
            btn.Text = texto .. (estado and "\n✅ ON" or "\n❌ OFF")
            btn.BackgroundColor3 = estado and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(180, 50, 50)
            callback(estado)
        end)
    end

    criarToggleVisual("📏 BALL TRACKER (distância)", 1, function(a)
        BALL_TRACKER = a
        if a then criarTrackerLabel() else
            if trackerLabel then trackerLabel:Destroy() trackerLabel = nil end
        end
    end)

    criarToggleVisual("⭕ BALL RADIUS (círculo no chão)", 2, function(a)
        BALL_RADIUS = a
        if not a and ballRadiusPart then ballRadiusPart:Destroy() ballRadiusPart = nil end
    end)

    criarToggleVisual("🔦 BALL HIGHLIGHT (brilho)", 3, function(a)
        BALL_HIGHLIGHT = a
        if not a and ballHighlight then ballHighlight:Destroy() ballHighlight = nil end
    end)

    criarToggleVisual("🎯 BALL LINE (linha até a bola)", 4, function(a)
        BALL_LINE = a
        if not a and ballLine then ballLine:Destroy() ballLine = nil end
    end)

    criarToggleVisual("📊 BALL SPEED (velocidade)", 5, function(a)
        BALL_SPEED = a
        if a then criarSpeedLabel() else
            if speedLabel then speedLabel:Destroy() speedLabel = nil end
        end
    end)

    criarToggleVisual("📍 BALL PIN (seta)", 6, function(a)
        BALL_PIN = a
        if a then criarBallPin() else
            if ballPin then ballPin:Destroy() ballPin = nil end
        end
    end)

    criarToggleVisual("🖼️ BALL MARKER (anel girando)", 7, function(a)
        BALL_MARKER = a
        if not a and ballMarker then ballMarker:Destroy() ballMarker = nil end
    end)

    criarToggleVisual("🌈 RAINBOW BALL (cor muda)", 8, function(a)
        RAINBOW_BALL = a
    end)

    criarToggleVisual("🌐 BALL TRAIL (rastro)", 9, function(a)
        BALL_TRAIL = a
        if not a and ballTrail then ballTrail:Destroy() ballTrail = nil end
    end)

    criarToggleVisual("🔢 BALL COUNTER (contador)", 10, function(a)
        BALL_COUNTER = a
        if a then
            counterValor = 0
            criarCounterLabel()
        else
            if counterLabel then counterLabel:Destroy() counterLabel = nil end
        end
    end)

    task.wait(0.1)
    scrollV.CanvasSize = UDim2.new(0, 0, 0, layoutV.AbsoluteContentSize.Y + 20)

    -- ===== ABA REST =====
    local abaRest = Instance.new("Frame")
    abaRest.Size = UDim2.new(1, 0, 1, -150)
    abaRest.Position = UDim2.new(0, 0, 0, 115)
    abaRest.BackgroundTransparency = 1
    abaRest.Visible = false
    abaRest.Parent = menu

    local labelTituloRest = Instance.new("TextLabel")
    labelTituloRest.Size = UDim2.new(0.9, 0, 0, 30)
    labelTituloRest.Position = UDim2.new(0.05, 0, 0, 5)
    labelTituloRest.BackgroundTransparency = 1
    labelTituloRest.Text = "🔄 RESTAURAR CONTROLES"
    labelTituloRest.TextColor3 = Color3.fromRGB(100, 255, 100)
    labelTituloRest.Font = Enum.Font.GothamBold
    labelTituloRest.TextSize = 14
    labelTituloRest.Parent = abaRest

    local btnRestaurar = Instance.new("TextButton")
    btnRestaurar.Size = UDim2.new(0.9, 0, 0, 75)
    btnRestaurar.Position = UDim2.new(0.05, 0, 0, 45)
    btnRestaurar.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
    btnRestaurar.BorderSizePixel = 0
    btnRestaurar.Text = "🔄 RESTAURAR\n(turbo 7x)"
    btnRestaurar.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnRestaurar.Font = Enum.Font.GothamBold
    btnRestaurar.TextSize = 15
    btnRestaurar.Parent = abaRest
    local cRP = Instance.new("UICorner") cRP.CornerRadius = UDim.new(0, 12) cRP.Parent = btnRestaurar

    btnRestaurar.MouseButton1Click:Connect(function()
        btnRestaurar.Text = "⏳ RESTAURANDO..."
        btnRestaurar.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        btnRestaurar.Active = false

        task.spawn(function()
            restaurarControles()
            task.wait(0.3)
            btnRestaurar.Text = "🔄 RESTAURAR\n(turbo 7x)"
            btnRestaurar.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
            btnRestaurar.Active = true
        end)
    end)

    local avisoRest = Instance.new("TextLabel")
    avisoRest.Size = UDim2.new(0.9, 0, 0, 30)
    avisoRest.Position = UDim2.new(0.05, 0, 0, 130)
    avisoRest.BackgroundColor3 = Color3.fromRGB(60, 40, 20)
    avisoRest.BorderSizePixel = 0
    avisoRest.Text = "⚠️ Apertar de 3 a 6 vezes pra voltar"
    avisoRest.TextColor3 = Color3.fromRGB(255, 200, 100)
    avisoRest.Font = Enum.Font.GothamBold
    avisoRest.TextSize = 12
    avisoRest.Parent = abaRest
    local cAv = Instance.new("UICorner") cAv.CornerRadius = UDim.new(0, 8) cAv.Parent = avisoRest

    local infoRest = Instance.new("TextLabel")
    infoRest.Size = UDim2.new(0.9, 0, 0, 70)
    infoRest.Position = UDim2.new(0.05, 0, 0, 170)
    infoRest.BackgroundTransparency = 1
    infoRest.Text = "Toca quando os botões sumirem.\nForça TUDO visível 7x turbo.\n✅ Nunca pausa."
    infoRest.TextColor3 = Color3.fromRGB(150, 150, 170)
    infoRest.Font = Enum.Font.Gotham
    infoRest.TextSize = 11
    infoRest.TextWrapped = true
    infoRest.Parent = abaRest

    local btnFechar = Instance.new("TextButton")
    btnFechar.Size = UDim2.new(0.9, 0, 0, 32)
    btnFechar.Position = UDim2.new(0.05, 0, 1, -42)
    btnFechar.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
    btnFechar.Text = "✖ FECHAR"
    btnFechar.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnFechar.Font = Enum.Font.GothamBold
    btnFechar.TextSize = 12
    btnFechar.BorderSizePixel = 0
    btnFechar.Parent = menu
    local cF = Instance.new("UICorner") cF.CornerRadius = UDim.new(0, 8) cF.Parent = btnFechar

    local function mudarAba(abaAtiva)
        abaMain.Visible = (abaAtiva == 1)
        abaOrb.Visible = (abaAtiva == 2)
        abaEsp.Visible = (abaAtiva == 3)
        abaSteal.Visible = (abaAtiva == 4)
        abaVisual.Visible = (abaAtiva == 5)
        abaRest.Visible = (abaAtiva == 6)

        btnAbaMain.BackgroundColor3 = (abaAtiva == 1) and Color3.fromRGB(0, 150, 220) or Color3.fromRGB(60, 60, 90)
        btnAbaOrb.BackgroundColor3 = (abaAtiva == 2) and Color3.fromRGB(140, 60, 200) or Color3.fromRGB(60, 60, 90)
        btnAbaEsp.BackgroundColor3 = (abaAtiva == 3) and Color3.fromRGB(200, 140, 60) or Color3.fromRGB(60, 60, 90)
        btnAbaSteal.BackgroundColor3 = (abaAtiva == 4) and Color3.fromRGB(200, 100, 50) or Color3.fromRGB(60, 60, 90)
        btnAbaVisual.BackgroundColor3 = (abaAtiva == 5) and Color3.fromRGB(50, 180, 150) or Color3.fromRGB(60, 60, 90)
        btnAbaRest.BackgroundColor3 = (abaAtiva == 6) and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(60, 60, 90)
    end

    btnAbaMain.MouseButton1Click:Connect(function() mudarAba(1) end)
    btnAbaOrb.MouseButton1Click:Connect(function() mudarAba(2) end)
    btnAbaEsp.MouseButton1Click:Connect(function() mudarAba(3) end)
    btnAbaSteal.MouseButton1Click:Connect(function() mudarAba(4) end)
    btnAbaVisual.MouseButton1Click:Connect(function() mudarAba(5) end)
    btnAbaRest.MouseButton1Click:Connect(function() mudarAba(6) end)

    local seguirOn = false
    btnSeguir.MouseButton1Click:Connect(function()
        seguirOn = not seguirOn
        AUTO_SEGUIR = seguirOn
        btnSeguir.Text = "🎯 SEGUIR BOLA\n" .. (seguirOn and "✅ ON" or "❌ OFF")
        btnSeguir.BackgroundColor3 = seguirOn and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(180, 50, 50)
    end)

    local orbitalOn = false
    btnOrbital.MouseButton1Click:Connect(function()
        orbitalOn = not orbitalOn
        ORBITAL_ATIVO = orbitalOn
        btnOrbital.Text = "🌀 ORBITAL ATIVO\n" .. (orbitalOn and "✅ ON" or "❌ OFF")
        btnOrbital.BackgroundColor3 = orbitalOn and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(180, 50, 50)
    end)

    btnRaioMaisOrb.MouseButton1Click:Connect(function()
        RAIO_ORB = math.min(RAIO_ORB + 1, 20)
        labelRaioOrb.Text = "Raio: " .. RAIO_ORB .. " studs"
    end)
    btnRaioMenosOrb.MouseButton1Click:Connect(function()
        RAIO_ORB = math.max(RAIO_ORB - 1, 2)
        labelRaioOrb.Text = "Raio: " .. RAIO_ORB .. " studs"
    end)
    btnVelMaisOrb.MouseButton1Click:Connect(function()
        VELOCIDADE_ORB = math.min(VELOCIDADE_ORB + 0.5, 15)
        labelVelOrb.Text = "Velocidade: " .. VELOCIDADE_ORB
    end)
    btnVelMenosOrb.MouseButton1Click:Connect(function()
        VELOCIDADE_ORB = math.max(VELOCIDADE_ORB - 0.5, 0.5)
        labelVelOrb.Text = "Velocidade: " .. VELOCIDADE_ORB
    end)

    local espiralOn = false
    btnEspiral.MouseButton1Click:Connect(function()
        espiralOn = not espiralOn
        ESPIRAL_ATIVO = espiralOn
        if espiralOn then
            RAIO_ATUAL = RAIO_INICIAL
            ANGULO_ESP = 0
        end
        btnEspiral.Text = "🌪️ ESPIRAL ATIVA\n" .. (espiralOn and "✅ ON" or "❌ OFF")
        btnEspiral.BackgroundColor3 = espiralOn and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(180, 50, 50)
    end)

    btnRaioMaisEsp.MouseButton1Click:Connect(function()
        RAIO_INICIAL = math.min(RAIO_INICIAL + 2, 40)
        labelRaioEsp.Text = "Raio Inicial: " .. RAIO_INICIAL
        if ESPIRAL_ATIVO then RAIO_ATUAL = RAIO_INICIAL end
    end)
    btnRaioMenosEsp.MouseButton1Click:Connect(function()
        RAIO_INICIAL = math.max(RAIO_INICIAL - 2, 5)
        labelRaioEsp.Text = "Raio Inicial: " .. RAIO_INICIAL
        if ESPIRAL_ATIVO then RAIO_ATUAL = RAIO_INICIAL end
    end)
    btnVelMaisEsp.MouseButton1Click:Connect(function()
        VELOCIDADE_ESP = math.min(VELOCIDADE_ESP + 0.5, 10)
        labelVelEsp.Text = "Velocidade: " .. VELOCIDADE_ESP
    end)
    btnVelMenosEsp.MouseButton1Click:Connect(function()
        VELOCIDADE_ESP = math.max(VELOCIDADE_ESP - 0.5, 0.5)
        labelVelEsp.Text = "Velocidade: " .. VELOCIDADE_ESP
    end)
    btnAproxMaisEsp.MouseButton1Click:Connect(function()
        VELOCIDADE_APROX = math.min(VELOCIDADE_APROX + 0.5, 10)
        labelAproxEsp.Text = "Aproximação: " .. VELOCIDADE_APROX
    end)
    btnAproxMenosEsp.MouseButton1Click:Connect(function()
        VELOCIDADE_APROX = math.max(VELOCIDADE_APROX - 0.5, 0.1)
        labelAproxEsp.Text = "Aproximação: " .. VELOCIDADE_APROX
    end)

    local stealOn = false
    btnSteal.MouseButton1Click:Connect(function()
        stealOn = not stealOn
        AUTO_STEAL = stealOn
        btnSteal.Text = "🦶 AUTO STEAL\n" .. (stealOn and "✅ ON" or "❌ OFF")
        btnSteal.BackgroundColor3 = stealOn and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(180, 50, 50)
    end)

    local menuAberto = false
    botaoAbrir.MouseButton1Click:Connect(function()
        menuAberto = not menuAberto
        menu.Visible = menuAberto
    end)
    btnFechar.MouseButton1Click:Connect(function()
        menuAberto = false
        menu.Visible = false
    end)
end

criarGUI()

local NOMES_BOLA = {
    ["soccerball"] = true,
    ["ball"] = true,
    ["bola"] = true,
    ["football"] = true,
    ["soccer"] = true,
}

local function encontrarBola()
    local char = LocalPlayer.Character
    if not char then return nil, math.huge end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, math.huge end

    local maisPerto, menorDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nome = obj.Name:lower()
            if NOMES_BOLA[nome] then
                local d = (obj.Position - hrp.Position).Magnitude
                if d < menorDist then
                    menorDist = d
                    maisPerto = obj
                end
            end
        end
    end
    return maisPerto, menorDist
end

local function executarSteal()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
    end)
end

RunService.Heartbeat:Connect(function(deltaTime)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bola, dist = encontrarBola()
    if not bola then return end

    local TEM_BOLA = temPosseReal(bola, hrp)

    if ESTAVA_COM_BOLA and not TEM_BOLA then
        RAIO_ATUAL = RAIO_INICIAL
        ANGULO_ESP = 0
    end
    ESTAVA_COM_BOLA = TEM_BOLA

    if statusPosseLabel then
        if TEM_BOLA then
            statusPosseLabel.Text = "✅ Status: COM BOLA"
            statusPosseLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            statusPosseLabel.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
        else
            statusPosseLabel.Text = "⚽ Status: SEM BOLA"
            statusPosseLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
            statusPosseLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        end
    end

    -- ===== ACHA O DONO E A DIREÇÃO =====
    local donoHrp = nil
    local ehJogador = false
    local menorDistBola = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local outroHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if outroHrp then
                local d = (bola.Position - outroHrp.Position).Magnitude
                if d < menorDistBola then
                    menorDistBola = d
                    donoHrp = outroHrp
                    ehJogador = true
                end
            end
        end
    end

    if not donoHrp then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and obj.Health > 0 then
                local npcChar = obj.Parent
                if npcChar and npcChar ~= LocalPlayer.Character then
                    local npcHrp = npcChar:FindFirstChild("HumanoidRootPart")
                    if npcHrp then
                        local d = (bola.Position - npcHrp.Position).Magnitude
                        if d < menorDistBola and d < 5 then
                            menorDistBola = d
                            donoHrp = npcHrp
                            ehJogador = false
                        end
                    end
                end
            end
        end
    end

    local direcaoFrente = Vector3.new(0, 0, 1)
    if donoHrp then
        if ehJogador then
            direcaoFrente = donoHrp.CFrame.LookVector
        else
            local velNpc = donoHrp.Velocity
            if velNpc.Magnitude > 1 then
                direcaoFrente = Vector3.new(velNpc.X, 0, velNpc.Z).Unit
            else
                direcaoFrente = donoHrp.CFrame.LookVector
            end
        end
    else
        local velBola = bola.Velocity
        if velBola.Magnitude > 1 then
            direcaoFrente = Vector3.new(velBola.X, 0, velBola.Z).Unit
        end
    end

    if not TEM_BOLA then
        local alvoPosicao = nil

        if ESPIRAL_ATIVO then
            ANGULO_ESP = ANGULO_ESP + VELOCIDADE_ESP * deltaTime
            RAIO_ATUAL = RAIO_ATUAL - VELOCIDADE_APROX * deltaTime * 3
            if RAIO_ATUAL < 2 then
                RAIO_ATUAL = RAIO_INICIAL
                ANGULO_ESP = 0
            end
            local offsetX = math.cos(ANGULO_ESP) * RAIO_ATUAL
            local offsetZ = math.sin(ANGULO_ESP) * RAIO_ATUAL
            alvoPosicao = bola.Position + Vector3.new(offsetX, ALTURA_ESP, offsetZ)

        elseif ORBITAL_ATIVO then
            ANGULO_ORB = ANGULO_ORB + VELOCIDADE_ORB * deltaTime
            local centroOrbita = bola.Position + (direcaoFrente * RAIO_ORB)
            local offsetX = math.cos(ANGULO_ORB) * RAIO_ORB
            local offsetZ = math.sin(ANGULO_ORB) * RAIO_ORB
            alvoPosicao = centroOrbita + Vector3.new(offsetX, ALTURA_ORB, offsetZ)

        elseif AUTO_SEGUIR then
            local posicaoFrente = bola.Position + (direcaoFrente * DISTANCIA_FRENTE)
            alvoPosicao = posicaoFrente + Vector3.new(0, 3, 0)
        end

        if alvoPosicao then
            local posAtual = hrp.Position
            local posNova = posAtual:Lerp(alvoPosicao, SUAVIZACAO)
            hrp.CFrame = CFrame.new(posNova) * (hrp.CFrame - hrp.CFrame.Position)
        end
    end

    if AUTO_STEAL and dist <= DISTANCIA_STEAL then
        if tick() - ULTIMO_STEAL >= COOLDOWN_STEAL then
            ULTIMO_STEAL = tick()
            executarSteal()
        end
    end

    if BALL_TRACKER and trackerLabel then
        trackerLabel.Text = string.format("⚽ Bola: %.1f studs", dist)
        if dist <= 5 then
            trackerLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        elseif dist <= 15 then
            trackerLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        else
            trackerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end

    if BALL_RADIUS then
        if not ballRadiusPart or not ballRadiusPart.Parent then
            criarBallRadius(bola)
        else
            ballRadiusPart.CFrame = CFrame.new(bola.Position) * CFrame.Angles(0, 0, math.rad(90))
        end
    end

    if BALL_HIGHLIGHT then
        if not ballHighlight or not ballHighlight.Parent then
            criarBallHighlight(bola)
        else
            ballHighlight.Adornee = bola
        end
    end

    if BALL_LINE then
        if not ballLine or not ballLine.Parent then
            ballLine = Instance.new("Part")
            ballLine.Name = "BallLineVisual"
            ballLine.Anchored = true
            ballLine.CanCollide = false
            ballLine.CanQuery = false
            ballLine.CanTouch = false
            ballLine.Material = Enum.Material.Neon
            ballLine.Color = Color3.fromRGB(0, 255, 100)
            ballLine.Transparency = 0.5
            ballLine.Parent = workspace
        end
        local distancia = (bola.Position - hrp.Position).Magnitude
        local meio = (bola.Position + hrp.Position) / 2
        ballLine.Size = Vector3.new(0.2, 0.2, distancia)
        ballLine.CFrame = CFrame.new(meio, bola.Position)
    end

    if BALL_SPEED and speedLabel then
        local velocidade = bola.Velocity.Magnitude
        speedLabel.Text = string.format("📊 Velocidade: %.1f", velocidade)
    end

    if BALL_PIN and ballPin then
        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(bola.Position)
        if onScreen then
            ballPin.Visible = false
        else
            ballPin.Visible = true
            local viewportSize = workspace.CurrentCamera.ViewportSize
            local centro = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
            local dir = Vector2.new(screenPos.X - centro.X, screenPos.Y - centro.Y).Unit
            ballPin.Position = UDim2.new(0.5, dir.X * 150 - 20, 0.5, dir.Y * 150 - 20)
            local angulo = math.deg(math.atan2(dir.Y, dir.X)) + 90
            ballPin.Rotation = angulo
        end
    end

    if BALL_MARKER then
        if not ballMarker or not ballMarker.Parent then
            criarBallMarker(bola)
        else
            ANGULO_MARKER = ANGULO_MARKER + 2
            ballMarker.CFrame = CFrame.new(bola.Position) * CFrame.Angles(0, 0, math.rad(ANGULO_MARKER))
        end
    end

    if RAINBOW_BALL and bola then
        local tempo = tick()
        local r = math.sin(tempo * 2) * 0.5 + 0.5
        local g = math.sin(tempo * 2 + 2) * 0.5 + 0.5
        local b = math.sin(tempo * 2 + 4) * 0.5 + 0.5
        pcall(function()
            bola.Color = Color3.new(r, g, b)
        end)
    end

    if BALL_TRAIL then
        if not ballTrail or not ballTrail.Parent then
            criarBallTrail(bola)
        end
    end

    if BALL_COUNTER and counterLabel then
        if dist <= 3 and tick() - ultimoToque > 1 then
            ultimoToque = tick()
            counterValor = counterValor + 1
            counterLabel.Text = "🔢 Toques: " .. counterValor
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if not gui or not gui.Parent then
            criarGUI()
        end
    end
end)

print("===========================================")
print("SCRIPT BY: @willnzx.mt | v22")
print("===========================================")
print("🎯 Seguir + 🌀 Orbital: NA FRENTE do dono")
print("✅ Detecta jogadores E NPCs")
print("✅ NPC: usa velocidade pra direção")
print("✅ Jogador: usa olhar (LookVector)")
print("===========================================")
