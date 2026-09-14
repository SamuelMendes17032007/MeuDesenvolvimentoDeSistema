-- Script: Bola Interativa (Chute + Condução)
-- Coloque este Script dentro da Part da bola

local ball = script.Parent
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Configurações (pode ajustar)
local KICK_FORCE = 80          -- Força do chute (quanto maior, mais longe vai)
local DRIBBLE_FORCE = 25       -- Força da condução (mais baixo = mais controlável)
local MAX_SPEED = 60           -- Velocidade máxima da bola
local TOUCH_COOLDOWN = 0.15    -- Tempo mínimo entre interações (evita spam)
local DRIBBLE_RANGE = 6        -- Distância para conduzir a bola

-- Garante que a bola tem física boa
ball.CustomPhysicalProperties = PhysicalProperties.new(
	0.7,   -- Density (peso)
	0.4,   -- Friction
	0.5,   -- Elasticity (quique)
	1,     -- FrictionWeight
	1      -- ElasticityWeight
)

local lastTouch = {}
local connections = {}

-- Função principal de aplicar força
local function applyForce(direction, force, player)
	if not direction or direction.Magnitude == 0 then return end
	
	direction = direction.Unit
	local velocity = direction * force
	
	-- Limita velocidade máxima
	if ball.AssemblyLinearVelocity.Magnitude > MAX_SPEED then
		ball.AssemblyLinearVelocity = ball.AssemblyLinearVelocity.Unit * MAX_SPEED
	end
	
	ball:ApplyImpulse(velocity * ball.AssemblyMass)
	
	-- Efeito visual opcional (pode remover se quiser)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 200, 50)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.7
	highlight.Parent = ball
	Debris:AddItem(highlight, 0.3)
end

-- Detecta quando o jogador toca na bola (chute)
local function onTouched(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not root or humanoid.Health <= 0 then return end
	
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end
	
	-- Cooldown por jogador
	local now = tick()
	if lastTouch[player.UserId] and now - lastTouch[player.UserId] < TOUCH_COOLDOWN then
		return
	end
	lastTouch[player.UserId] = now
	
	-- Direção do chute = direção que o personagem está olhando + um pouco para cima
	local lookVector = root.CFrame.LookVector
	local kickDirection = (lookVector + Vector3.new(0, 0.35, 0)).Unit
	
	-- Força maior se o jogador estiver correndo
	local speedMultiplier = math.clamp(root.AssemblyLinearVelocity.Magnitude / 16, 1, 1.8)
	
	applyForce(kickDirection, KICK_FORCE * speedMultiplier, player)
end

-- Sistema de condução (dribbling) - roda continuamente
local function updateDribble()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then continue end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		
		if not humanoid or not root or humanoid.Health <= 0 then continue end
		if humanoid.MoveDirection.Magnitude < 0.1 then continue end -- só conduz se estiver se movendo
		
		local distance = (root.Position - ball.Position).Magnitude
		
		if distance <= DRIBBLE_RANGE then
			-- Direção da condução = direção que o jogador está andando
			local moveDir = humanoid.MoveDirection
			
			-- Empurra a bola suavemente na direção do movimento do jogador
			local dribbleDirection = (moveDir + Vector3.new(0, 0.1, 0)).Unit
			local force = DRIBBLE_FORCE * (1 - (distance / DRIBBLE_RANGE)) -- mais forte quanto mais perto
			
			applyForce(dribbleDirection, force, player)
		end
	end
end

-- Conecta eventos
ball.Touched:Connect(onTouched)

-- Loop de condução (mais leve que Heartbeat puro)
local dribbleConnection = RunService.Heartbeat:Connect(function()
	updateDribble()
end)

-- Limpeza quando a bola for destruída
ball.AncestryChanged:Connect(function(_, parent)
	if not parent then
		dribbleConnection:Disconnect()
		table.clear(lastTouch)
	end
end)

print("Bola interativa carregada! Chute e conduza normalmente.")