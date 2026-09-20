--// Aura Futebol - ALL-IN-ONE (v12 - Detecção inteligente)
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

-- ===== RESTAURAR 7x TURBO =====
local function restaurarControles()
    for i = 1, 7 do
        pcall(function() forcarVisivel(PlayerGui) end)
        pcall(function() forcarVisivel(game:GetService("CoreGui")) end)
        task.wait(0.02)
    end
    print("[Restaurar] Concluído (7x turbo)")
end

-- ===== DETECÇÃO INTELIGENTE DE POSSE =====
local function temPosseReal(bola, hrp)
    local distVoce = (bola.Position - hrp.Position).Magnitude
    
    -- Se tá longe, não tem posse
    if distVoce > DISTANCIA_POSSE then return false end
    
    -- Verifica se algum OUTRO jogador tá mais perto da bola
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
    
    -- Se outro jogador tá mais perto, você NÃO tem posse
    if outroMaisPerto then
        return false
    end
    
    -- Se ninguém tá mais perto, você tem posse
    return true
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
    
    -- Botão flutuante
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
    
    local cA = Instance.new("UICorner")
    cA.CornerRadius = UDim.new(1, 0)
    cA.Parent = botaoAbrir
    
    local strokeA = Instance.new("UIStroke")
    strokeA.Color = Color3.fromRGB(0, 200, 255)
    strokeA.Thickness = 2
    strokeA.Parent = botaoAbrir
    
    -- Menu
    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(0, 400, 0, 520)
    menu.Position = UDim2.new(0.5, -200, 0.5, -260)
    menu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    menu.BorderSizePixel = 0
    menu.Visible = false
    menu.Active = true
    menu.Draggable = true
    menu.Parent = gui
    
    local cM = Instance.new("UICorner")
    cM.CornerRadius = UDim.new(0, 14)
    cM.Parent = menu
    
    local strokeM = Instance.new("UIStroke")
    strokeM.Color = Color3.fromRGB(0, 200, 255)
    strokeM.Thickness = 2
    strokeM.Parent = menu
    
    -- Título
    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, 0, 0, 42)
    titulo.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
    titulo.BorderSizePixel = 0
    titulo.Text = "by: @willnzx.mt"
    titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
    titulo.Font = Enum.Font.GothamBold
    titulo.TextSize = 15
    titulo.Parent = menu
    
    local cT = Instance.new("UICorner")
    cT.CornerRadius = UDim.new(0, 14)
    cT.Parent = titulo
    
    -- Status de posse
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
    
    local cSP = Instance.new("UICorner")
    cSP.CornerRadius = UDim.new(0, 6)
    cSP.Parent = statusPosseLabel
    
    -- ===== ABAS =====
    local abaWidth = 0.185
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
    
    local cAb1 = Instance.new("UICorner")
    cAb1.CornerRadius = UDim.new(0, 8)
    cAb1.Parent = btnAbaMain
    
    local btnAbaOrb = Instance.new("TextButton")
    btnAbaOrb.Size = UDim2.new(abaWidth, 0, 0, 32)
    btnAbaOrb.Position = UDim2.new(0.215, 0, 0, 50)
    btnAbaOrb.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    btnAbaOrb.Text = "🌀"
    btnAbaOrb.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAbaOrb.Font = Enum.Font.GothamBold
    btnAbaOrb.TextSize = 16
    btnAbaOrb.BorderSizePixel = 0
    btnAbaOrb.Parent = menu
    
    local cAb2 = Instance.new("UICorner")
    cAb2.CornerRadius = UDim.new(0, 8)
    cAb2.Parent = btnAbaOrb
    
    local btnAbaEsp = Instance.new("TextButton")
    btnAbaEsp.Size = UDim2.new(abaWidth, 0, 0, 32)
    btnAbaEsp.Position = UDim2.new(0.41, 0, 0, 50)
    btnAbaEsp.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    btnAbaEsp.Text = "🌪️"
    btnAbaEsp.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAbaEsp.Font = Enum.Font.GothamBold
    btnAbaEsp.TextSize = 16
    btnAbaEsp.BorderSizePixel = 0
    btnAbaEsp.Parent = menu
    
    local cAb3 = Instance.new("UICorner")
    cAb3.CornerRadius = UDim.new(0, 8)
    cAb3.Parent = btnAbaEsp
    
    local btnAbaSteal = Instance.new("TextButton")
    btnAbaSteal.Size = UDim2.new(abaWidth, 0, 0, 32)
    btnAbaSteal.Position = UDim2.new(0.605, 0, 0, 50)
    btnAbaSteal.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    btnAbaSteal.Text = "🦶"
    btnAbaSteal.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAbaSteal.Font = Enum.Font.GothamBold
    btnAbaSteal.TextSize = 16
    btnAbaSteal.BorderSizePixel = 0
    btnAbaSteal.Parent = menu
    
    local cAb4 = Instance.new("UICorner")
    cAb4.CornerRadius = UDim.new(0, 8)
    cAb4.Parent = btnAbaSteal
    
    local btnAbaRest = Instance.new("TextButton")
    btnAbaRest.Size = UDim2.new(abaWidth, 0, 0, 32)
    btnAbaRest.Position = UDim2.new(0.80, 0, 0, 50)
    btnAbaRest.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    btnAbaRest.Text = "🔄"
    btnAbaRest.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAbaRest.Font = Enum.Font.GothamBold
    btnAbaRest.TextSize = 16
    btnAbaRest.BorderSizePixel = 0
    btnAbaRest.Parent = menu
    
    local cAb5 = Instance.new("UICorner")
    cAb5.CornerRadius = UDim.new(0, 8)
    cAb5.Parent = btnAbaRest
    
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
    
    local cSB = Instance.new("UICorner")
    cSB.CornerRadius = UDim.new(0, 12)
    cSB.Parent = btnSeguir
    
    local infoMain = Instance.new("TextLabel")
    infoMain.Size = UDim2.new(0.9, 0, 0, 80)
    infoMain.Position = UDim2.new(0.05, 0, 0, 125)
    infoMain.BackgroundTransparency = 1
    infoMain.Text = "Teleporta pra bola a cada 0.1s.\n\n✅ Pausa APENAS se você tiver posse\n(se outro jogador tiver, continua ativo)"
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
    labelTituloOrb.Text = "🌀 ORBITAL BALL"
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
    
    local cOB = Instance.new("UICorner")
    cOB.CornerRadius = UDim.new(0, 10)
    cOB.Parent = btnOrbital
    
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
    
    local cR1 = Instance.new("UICorner")
    cR1.CornerRadius = UDim.new(0, 8)
    cR1.Parent = btnRaioMaisOrb
    
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
    
    local cR2 = Instance.new("UICorner")
    cR2.CornerRadius = UDim.new(0, 8)
    cR2.Parent = btnRaioMenosOrb
    
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
    
    local cV1 = Instance.new("UICorner")
    cV1.CornerRadius = UDim.new(0, 8)
    cV1.Parent = btnVelMaisOrb
    
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
    
    local cV2 = Instance.new("UICorner")
    cV2.CornerRadius = UDim.new(0, 8)
    cV2.Parent = btnVelMenosOrb
    
    local infoOrb = Instance.new("TextLabel")
    infoOrb.Size = UDim2.new(0.9, 0, 0, 40)
    infoOrb.Position = UDim2.new(0.05, 0, 0, 228)
    infoOrb.BackgroundTransparency = 1
    infoOrb.Text = "Gira em círculo ao redor da bola.\nPausa só se VOCÊ tiver posse."
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
    
    local cE = Instance.new("UICorner")
    cE.CornerRadius = UDim.new(0, 10)
    cE.Parent = btnEspiral
    
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
    
    local cRE1 = Instance.new("UICorner")
    cRE1.CornerRadius = UDim.new(0, 8)
    cRE1.Parent = btnRaioMaisEsp
    
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
    
    local cRE2 = Instance.new("UICorner")
    cRE2.CornerRadius = UDim.new(0, 8)
    cRE2.Parent = btnRaioMenosEsp
    
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
    
    local cVE1 = Instance.new("UICorner")
    cVE1.CornerRadius = UDim.new(0, 8)
    cVE1.Parent = btnVelMaisEsp
    
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
    
    local cVE2 = Instance.new("UICorner")
    cVE2.CornerRadius = UDim.new(0, 8)
    cVE2.Parent = btnVelMenosEsp
    
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
    
    local cAP1 = Instance.new("UICorner")
    cAP1.CornerRadius = UDim.new(0, 8)
    cAP1.Parent = btnAproxMaisEsp
    
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
    
    local cAP2 = Instance.new("UICorner")
    cAP2.CornerRadius = UDim.new(0, 8)
    cAP2.Parent = btnAproxMenosEsp
    
    local infoEsp = Instance.new("TextLabel")
    infoEsp.Size = UDim2.new(0.9, 0, 0, 35)
    infoEsp.Position = UDim2.new(0.05, 0, 0, 275)
    infoEsp.BackgroundTransparency = 1
    infoEsp.Text = "Aproxima da bola em espiral.\nPausa só se VOCÊ tiver posse."
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
    
    local cSt = Instance.new("UICorner")
    cSt.CornerRadius = UDim.new(0, 10)
    cSt.Parent = btnSteal
    
    local infoSteal = Instance.new("TextLabel")
    infoSteal.Size = UDim2.new(0.9, 0, 0, 100)
    infoSteal.Position = UDim2.new(0.05, 0, 0, 120)
    infoSteal.BackgroundTransparency = 1
    infoSteal.Text = "Aperta Q automaticamente\nquando a bola tá perto (6 studs).\n\n✅ NUNCA pausa (é o objetivo)\n⚠️ Buga os botões mobile.\nUse a aba RESTAURAR depois."
    infoSteal.TextColor3 = Color3.fromRGB(150, 150, 170)
    infoSteal.Font = Enum.Font.Gotham
    infoSteal.TextSize = 11
    infoSteal.TextWrapped = true
    infoSteal.Parent = abaSteal
    
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
    
    local cRP = Instance.new("UICorner")
    cRP.CornerRadius = UDim.new(0, 12)
    cRP.Parent = btnRestaurar
    
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
    
    local cAv = Instance.new("UICorner")
    cAv.CornerRadius = UDim.new(0, 8)
    cAv.Parent = avisoRest
    
    local infoRest = Instance.new("TextLabel")
    infoRest.Size = UDim2.new(0.9, 0, 0, 70)
    infoRest.Position = UDim2.new(0.05, 0, 0, 170)
    infoRest.BackgroundTransparency = 1
    infoRest.Text = "Toca quando os botões sumirem.\nForça TUDO visível 7x turbo (0.02s).\n✅ Nunca pausa (é independente)."
    infoRest.TextColor3 = Color3.fromRGB(150, 150, 170)
    infoRest.Font = Enum.Font.Gotham
    infoRest.TextSize = 11
    infoRest.TextWrapped = true
    infoRest.Parent = abaRest
    
    -- Fechar
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
    
    local cF = Instance.new("UICorner")
    cF.CornerRadius = UDim.new(0, 8)
    cF.Parent = btnFechar
    
    -- ===== LÓGICA DAS ABAS =====
    local function mudarAba(abaAtiva)
        abaMain.Visible = (abaAtiva == 1)
        abaOrb.Visible = (abaAtiva == 2)
        abaEsp.Visible = (abaAtiva == 3)
        abaSteal.Visible = (abaAtiva == 4)
        abaRest.Visible = (abaAtiva == 5)
        
        btnAbaMain.BackgroundColor3 = (abaAtiva == 1) and Color3.fromRGB(0, 150, 220) or Color3.fromRGB(60, 60, 90)
        btnAbaOrb.BackgroundColor3 = (abaAtiva == 2) and Color3.fromRGB(140, 60, 200) or Color3.fromRGB(60, 60, 90)
        btnAbaEsp.BackgroundColor3 = (abaAtiva == 3) and Color3.fromRGB(200, 140, 60) or Color3.fromRGB(60, 60, 90)
        btnAbaSteal.BackgroundColor3 = (abaAtiva == 4) and Color3.fromRGB(200, 100, 50) or Color3.fromRGB(60, 60, 90)
        btnAbaRest.BackgroundColor3 = (abaAtiva == 5) and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(60, 60, 90)
    end
    
    btnAbaMain.MouseButton1Click:Connect(function() mudarAba(1) end)
    btnAbaOrb.MouseButton1Click:Connect(function() mudarAba(2) end)
    btnAbaEsp.MouseButton1Click:Connect(function() mudarAba(3) end)
    btnAbaSteal.MouseButton1Click:Connect(function() mudarAba(4) end)
    btnAbaRest.MouseButton1Click:Connect(function() mudarAba(5) end)
    
    -- Toggle Seguir
    local seguirOn = false
    btnSeguir.MouseButton1Click:Connect(function()
        seguirOn = not seguirOn
        AUTO_SEGUIR = seguirOn
        btnSeguir.Text = "🎯 SEGUIR BOLA\n" .. (seguirOn and "✅ ON" or "❌ OFF")
        btnSeguir.BackgroundColor3 = seguirOn and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(180, 50, 50)
    end)
    
    -- Toggle Orbital
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
    
    -- Toggle Espiral
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
    
    -- Toggle Steal
    local stealOn = false
    btnSteal.MouseButton1Click:Connect(function()
        stealOn = not stealOn
        AUTO_STEAL = stealOn
        btnSteal.Text = "🦶 AUTO STEAL\n" .. (stealOn and "✅ ON" or "❌ OFF")
        btnSteal.BackgroundColor3 = stealOn and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(180, 50, 50)
    end)
    
    -- Abrir/fechar
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

-- ===== DETECÇÃO DA BOLA =====
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

-- ===== STEAL (VirtualInputManager) =====
local function executarSteal()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
    end)
end

-- ===== LOOP PRINCIPAL =====
RunService.Heartbeat:Connect(function(deltaTime)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bola, dist = encontrarBola()
    if not bola then return end

    -- ===== DETECÇÃO INTELIGENTE DE POSSE =====
    local TEM_BOLA = temPosseReal(bola, hrp)
    
    -- Atualiza o status na GUI
    if statusPosseLabel then
        if TEM_BOLA then
            statusPosseLabel.Text = "✅ Status: COM BOLA (funções pausadas)"
            statusPosseLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            statusPosseLabel.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
        else
            statusPosseLabel.Text = "⚽ Status: SEM BOLA"
            statusPosseLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
            statusPosseLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        end
    end

    -- ===== SEGUIR BOLA (pausa só se VOCÊ tem posse) =====
    if AUTO_SEGUIR and not TEM_BOLA then
        if tick() - ULTIMO_TP >= COOLDOWN_TP then
            ULTIMO_TP = tick()
            hrp.CFrame = CFrame.new(bola.Position + Vector3.new(0, 3, 0))
        end
    end

    -- ===== ORBITAL (pausa só se VOCÊ tem posse) =====
    if ORBITAL_ATIVO and not TEM_BOLA then
        ANGULO_ORB = ANGULO_ORB + VELOCIDADE_ORB * deltaTime
        local offsetX = math.cos(ANGULO_ORB) * RAIO_ORB
        local offsetZ = math.sin(ANGULO_ORB) * RAIO_ORB
        local novaPosicao = bola.Position + Vector3.new(offsetX, ALTURA_ORB, offsetZ)
        hrp.CFrame = CFrame.new(novaPosicao, bola.Position)
    end

    -- ===== ESPIRAL (pausa só se VOCÊ tem posse) =====
    if ESPIRAL_ATIVO and not TEM_BOLA then
        ANGULO_ESP = ANGULO_ESP + VELOCIDADE_ESP * deltaTime
        RAIO_ATUAL = RAIO_ATUAL - VELOCIDADE_APROX * deltaTime * 3
        
        if RAIO_ATUAL < 2 then
            RAIO_ATUAL = RAIO_INICIAL
            ANGULO_ESP = 0
        end
        
        local offsetX = math.cos(ANGULO_ESP) * RAIO_ATUAL
        local offsetZ = math.sin(ANGULO_ESP) * RAIO_ATUAL
        local novaPosicao = bola.Position + Vector3.new(offsetX, ALTURA_ESP, offsetZ)
        hrp.CFrame = CFrame.new(novaPosicao, bola.Position)
    end

    -- ===== AUTO STEAL (NUNCA pausa) =====
    if AUTO_STEAL and dist <= DISTANCIA_STEAL then
        if tick() - ULTIMO_STEAL >= COOLDOWN_STEAL then
            ULTIMO_STEAL = tick()
            executarSteal()
        end
    end
end)

-- ===== GUI NÃO SOME =====
task.spawn(function()
    while task.wait(2) do
        if not gui or not gui.Parent then
            criarGUI()
        end
    end
end)

print("===========================================")
print("SCRIPT BY: @willnzx.mt")
print("===========================================")
print("🎯 Aba MAIN → Seguir Bola (pausa se VOCÊ tem posse)")
print("🌀 Aba ORBITAL → Orbital Ball (pausa se VOCÊ tem posse)")
print("🌪️ Aba ESPIRAL → Espiral Ball (pausa se VOCÊ tem posse)")
print("🦶 Aba STEAL → Auto Steal (NUNCA pausa)")
print("🔄 Aba REST → Restaurar (NUNCA pausa)")
print("===========================================")
print("🧠 Detecção inteligente ativa:")
print("   Só pausa se VOCÊ tem posse REAL")
print("   (se outro jogador tiver, continua ativo)")
print("===========================================")
