--// Aura Futebol - ALL-IN-ONE (v18 - Orbital Adaptativo)
--// by: @willnzx.mt
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============ CONFIGURAÇÕES ============
-- Seguir
local AUTO_SEGUIR = false
local COOLDOWN_TP = 0.1
local ULTIMO_TP = 0

-- Orbital
local ORBITAL_ATIVO = false
local RAIO_ORB = 5
local VELOCIDADE_ORB = 5
local ALTURA_ORB = 3
local ANGULO_ORB = 0
local VELOCIDADE_MINIMA_BOLA = 1  -- Velocidade mínima pra considerar "andando"

-- Espiral
local ESPIRAL_ATIVO = false
local RAIO_INICIAL = 15
local VELOCIDADE_ESP = 3
local VELOCIDADE_APROX = 0.5
local ALTURA_ESP = 3
local ANGULO_ESP = 0
local RAIO_ATUAL = 15

-- Steal
local AUTO_STEAL = false
local COOLDOWN_STEAL = 0.3
local DISTANCIA_STEAL = 6
local ULTIMO_STEAL = 0

-- Posse
local DISTANCIA_POSSE = 3
local ESTAVA_COM_BOLA = false

-- Suavização
local SUAVIZACAO = 0.2

-- Borda RGB
local BORDA_RGB = true
local VELOCIDADE_RGB = 1

-- ===== VISUAL / INFO =====
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

-- ===== FUNÇÃO FORÇAR VISÍVEL =====
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

-- ===== DETECÇÃO INTELIGENTE DE POSSE =====
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

    if outroMaisPerto then return false end
    return true
end

-- ===== LABELS =====
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
            pcall(function()
                strokeM.Color = Color3.new(r, g, b)
            end)
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
    labelTituloMain.Text = "🎯 SEGUIR BOLA"
    labelTituloMain.TextColor3 = Color3.fromRGB(100, 220, 255)
    labelTituloMain.Font = Enum.Font.GothamBold
    labelTituloMain.TextSize = 14
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
    infoMain.Text = "Teleporta pra bola com suavização.\n\n✅ Pausa se você tiver posse\n✅ Não trava nem gira doidamente"
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
    labelTituloOrb.Text = "🌀 ORBITAL BALL (ADAPTATIVO)"
    labelTituloOrb.TextColor3 = Color3.fromRGB(200, 100, 255)
    labelTituloOrb.Font = Enum.Font.GothamBold
    labelTituloOrb.TextSize = 14
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
    infoOrb.Text = "🌀 ADAPTATIVO:\n• Bola parada → orbita no centro\n• Bola andando → orbita na FRENTE"
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
    btnEspiral.Size =
