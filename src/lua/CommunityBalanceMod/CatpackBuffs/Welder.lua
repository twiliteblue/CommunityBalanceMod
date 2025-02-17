
local PrioritizeDamagedFriends = debug.getupvaluex(Welder.PerformWeld, "PrioritizeDamagedFriends")


function Welder:PerformWeld(player)

    local attackDirection = player:GetViewCoords().zAxis
    local success = false
    -- prioritize friendlies
    local didHit, target, endPoint, direction, surface

    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    local startPoint = player:GetEyePos()
    local endPoint = startPoint + viewCoords.zAxis * self:GetRange()

    -- Filter ourself out of the trace so that we don't hit ourselves.
    -- Filter also clogs out for the ray check because they ray "detection" box is somehow way bigger than the visual model
    local filter = EntityFilterTwo(player, self)
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, filter)

    -- Perform a Ray trace first, otherwise fallback to a regular melee capsule
    if (trace.entity) then
        didHit = true
        target = trace.entity
        endPoint = trace.endPoint
        direction = viewCoords.zAxis
        surface = trace.surface
    else
        didHit, target, endPoint, direction, surface = CheckMeleeCapsule(self, player, 0, self:GetRange(), nil, true, 1, PrioritizeDamagedFriends, nil, PhysicsMask.Flame)
    end

    if didHit and target and HasMixin(target, "Live") then
        
        local timeSinceLastWeld = self.welding and Shared.GetTime() - self.timeLastWeld or 0
        
        if GetAreEnemies(player, target) then
            self:DoDamage(kWelderDamagePerSecond * timeSinceLastWeld, target, endPoint, attackDirection)
            success = true     
        elseif player:GetTeamNumber() == target:GetTeamNumber() and HasMixin(target, "Weldable") then
        
            if target:GetHealthScalar() < 1 then
                
                local prevHealthScalar = target:GetHealthScalar()
                local prevHealth = target:GetHealth()
                local prevArmor = target:GetArmor()
                target:OnWeld(self, timeSinceLastWeld, player)
                success = prevHealthScalar ~= target:GetHealthScalar()
                
                if success then
                
                    local addAmount = (target:GetHealth() - prevHealth) + (target:GetArmor() - prevArmor)
                    player:AddContinuousScore("WeldHealth", addAmount, Welder.kAmountHealedForPoints, Welder.kHealScoreAdded)
                    
                    local oldArmor = player:GetArmor()
                    
                    -- weld owner as well
                    player:SetArmor(oldArmor + kWelderFireDelay * kSelfWeldAmount)

                    if player.OnArmorWelded and oldArmor < player:GetArmor() then
                        player:OnArmorWelded(self)
                    end
                    
                end
                
            end
            
            if HasMixin(target, "Construct") and target:GetCanConstruct(player) then

                --Balance mod
                if player:isa("Marine") and player:GetHasCatPackBoost() then 
                    target:Construct(timeSinceLastWeld * 0.875, player) -- Reduce time between welds by 12.5%
                else 
                    target:Construct(timeSinceLastWeld, player)
                end
            end
            
        end
        
    end
    
    if success then    
        return endPoint
    end
    
end

