-- Todo: Add per frame time cache
function MapBlipMixin:GetMapBlipInfo()
    PROFILE("MapBlipMixin:GetMapBlipInfo")

    if self.OnGetMapBlipInfo then
        return self:OnGetMapBlipInfo()
    end

    local success = false
    local blipType = kMinimapBlipType.Undefined
    local blipTeam = -1
    local isAttacked = HasMixin(self, "Combat") and self:GetIsInCombat()
    local isParasited = HasMixin(self, "ParasiteAble") and self:GetIsParasited()

    -- World entities
    if self:isa("Door") then
        blipType = kMinimapBlipType.Door
    elseif self:isa("ResourcePoint") then
        blipType = kMinimapBlipType.ResourcePoint
    elseif self:isa("TechPoint") then
        blipType = kMinimapBlipType.TechPoint
        -- Don't display PowerPoints unless they are in an unpowered state.
    elseif self:isa("PowerPoint") then

        if self:GetIsDisabled() then
            blipType = kMinimapBlipType.DestroyedPowerPoint
        elseif self:GetIsBuilt() then
            blipType = kMinimapBlipType.PowerPoint
        elseif self:GetIsSocketed() then
            blipType = kMinimapBlipType.BlueprintPowerPoint
        else
            blipType = kMinimapBlipType.UnsocketedPowerPoint
        end

        blipTeam = self:GetTeamNumber()

    elseif self:isa("Cyst") then

        blipType = kMinimapBlipType.Infestation

        if not self:GetIsConnected() then
            blipType = kMinimapBlipType.InfestationDying
        end

        blipTeam = self:GetTeamNumber()
        isAttacked = false

    elseif self:isa("Hallucination") then

        local hallucinatedTechId = self:GetAssignedTechId()
        
        blipType = StringToEnum(kMinimapBlipType, EnumToString(kTechId, hallucinatedTechId))
        
        --[[if hallucinatedTechId == kTechId.Drifter then
            blipType = kMinimapBlipType.Drifter
        elseif hallucinatedTechId == kTechId.Hive then
            blipType = kMinimapBlipType.Hive
        elseif hallucinatedTechId == kTechId.Harvester then
            blipType = kMinimapBlipType.Harvester
        end--]]

        blipTeam = self:GetTeamNumber()

    elseif self.GetMapBlipType then
        blipType = self:GetMapBlipType()
        blipTeam = self:GetTeamNumber()

        -- Everything else that is supported by kMinimapBlipType.
    elseif self:GetIsVisible() then

        if rawget( kMinimapBlipType, self:GetClassName() ) ~= nil then
            blipType = kMinimapBlipType[self:GetClassName()]
        else
            Shared.Message( "Element '"..tostring(self:GetClassName()).."' doesn't exist in the kMinimapBlipType enum" )
        end

        blipTeam = HasMixin(self, "Team") and self:GetTeamNumber() or kTeamReadyRoom

    end

    if blipType ~= 0 then
        success = true
    end

    return success, blipType, blipTeam, isAttacked, isParasited

end