TF_TRAINZONE = {
    ClassName = "TF_TRAINZONE"
}

--- Parameters ---

TF_TRAINZONE.IsDebugMessage = true
TF_TRAINZONE.TimerStep = 5

-- NOTES: Default Spawn settings is for tac-acm train
TF_TRAINZONE.IsSpawnEmeny = ture
TF_TRAINZONE.IsEndlessMode = false
TF_TRAINZONE.MaxTrainWavesFinished = 3

-- TF_TRAINZONE.EnemyTemplateName = "EnemyTemplate"
TF_TRAINZONE.TableEnemyTemplate = {"enemy-f5-highvis", "enemy-f5-lowvis", "enemy-f16-highvis", "enemy-f16-lowvis"}
TF_TRAINZONE.TableSpawnAlt = {1000, 15000, 30000} -- spawn enemy alt (meters)
TF_TRAINZONE.TableSpawnBRA = {0, 45, 90, 120, 180}
-- spawn distance = abs(spawn_bra-180) * SpawnDistance_K + SpawnDistance_At180
TF_TRAINZONE.SpawnDistance_At180 = 8 -- spawn distance when @cold
TF_TRAINZONE.SpawnDistance_At0 = 20 -- spawn distance when @hot
TF_TRAINZONE.SpawnDistance_K = (self.SpawnDistance_At0 - self.SpawnDistance_At180) / 180
TF_TRAINZONE.SpawnDelayMin = 10
TF_TRAINZONE.SpawnDelayMax = 30

TF_TRAINZONE.EnemyDestoryDelay = 30
TF_TRAINZONE.EnemyEmissionOpenDelay = 30

---  Parameters End---

--- values ---

TF_TRAINZONE.GroupTrain = nil
TF_TRAINZONE.GroupEnemy = nil

TF_TRAINZONE.TimerTraining = nil
TF_TRAINZONE.TrainWavesFinished = nil

TF_TRAINZONE.SpawnTicker = 0
TF_TRAINZONE.SpawnTickerTrigger = 0

--- values end ---

--- functions ---
function TF_TRAINZONE:ShowMessage(Message, Duration, isClean, isToAll, ToGroup)
    local msg = MESSAGE:New(self:GetState() .. Message, Duration or 15, nil, true)

    if isToAll or self.IsDebugMessage then
        msg:ToAll()
    else
        if ToGroup then
            msg:ToGroup(ToGroup)
        else
            msg:ToGroup(self.GroupTrain)
        end

    end
end

function TF_TRAINZONE:New(ZoneName)
    local self = BASE:Inherit(self, FSM:New())

    self.ZoneTraining = ZONE:New(ZoneName)

    self.TrainWavesFinished = 0

    self:SetStartState("ZoneClearUp")

    self:AddTransition("Idle", "EnterZone", "Training")
    self:AddTransition("Training", "EnemySpawn", "ThreatSpawned")
    self:AddTransition("ThreatSpawned", "EnemyDisarm", "Training")
    self:AddTransition({"Training", "ThreatSpawned"}, "AbortOrFinish", "ZoneClearUp")
    self:AddTransition("ZoneClearUp", "ZoneClear", "Idle")

    self.TimerTraining = TIMER:New(function()
        self:Status()
    end):Start(0, 5)

    return self
end

function TF_TRAINZONE:Status()

    if self:Is("Idle") then
        local groups = SET_GROUP:New():FilterCoalitions("blue"):FilterCategoryAirplane()
            :FilterZones({self.ZoneTraining}):FilterOnce():GetSetObjects()

        if groups then
            for _, group in ipairs(groups) do
                if not group:CountAliveUnits() == 2 or group:IsCompletelyInZone(self.ZoneTraining) then
                    self:ShowMessage("导演部: 单机队必须2人同时进入该空域, 才能启动训练", nil,
                        nil, nil, group)
                else
                    -- start training                    
                    self.GroupTrain = group
                    self:EnterZone()

                    -- reset train waves
                    self.TrainWavesFinished = 0

                    -- register hit event
                    self.GroupTrain:HandleEvent(EVENTS.Hit, function()
                        self:ShowMessage("导演部: 你机队被命中,训练终止.")
                        self:AbortOrFinish()
                    end)
                end
            end
        end
    end

    -- check outbound
    if self:Is("Training") or self:Is("ThreatSpawned") then
        if not self.GroupTrain.IsCompletelyInZone(self.ZoneTraining) then
            self:ShowMessage("导演部: 你机队出界,训练终止.")
            self:AbortOrFinish()
        end
    end

    -- spawn enemy
    if self:Is("Training") then
        if self.IsSpawnEmeny then
            self.SpawnTicker = self.SpawnTicker + self.TimerStep
            if (self.SpawnTicker >= self.SpawnTickerTrigger) then
                self.SpawnTicker = 0
                self:EnemySpawn()
            end
        end
    end

    -- check cleanup
    if self:Is("ZoneClearUp") then
        local count = SET_GROUP:New():FilterCoalitions("blue"):FilterCategoryAirplane():FilterZones({self.ZoneTraining})
            :FilterOnce():CountAlive()
        if count == 0 then
            self:ZoneClear()
        else
            self:ShowMessage("导演部: " .. self.ZoneTraining:GetName() ..
                                 " 空域尚未清空, 所有机组请先退出该空域.", false, true)
        end
    end

    return self
end

function TF_TRAINZONE:OnEnterIdle(From, Event, To)
    self:ShowMessage("导演部: " .. self.ZoneTraining:GetName() .. " 净空, 可以进入机组训练", false, true)
    self.ZoneTraining:SetFillColor({1, 1, 1}, 0.5)
    return true
end

function TF_TRAINZONE:OnEnterTraining(From, Event, To)

    self.ZoneTraining:SetFillColor({1, 0, 0}, 0.5)

    -- set train group Immortal
    self.GroupTrain:SetCommandImmortal(true)
    if self.TrainWavesFinished == 0 then
        msg = "导演部: 训练开始. .." .. tostring(self.TrainWavesFinished)

        self:ShowMessage()

        -- set enemy spawn countdown
        -- 太菜 用不来异步方法 废弃
        -- self:__EnemySpawn(math.random(self.SpawnDelayMin, self.SpawnDelayMax))
        if self.IsSpawnEmeny then
            self.SpawnTicker = 0
            self.SpawnTickerTrigger = math.random(self.SpawnDelayMin, self.SpawnDelayMax)
        end

        return true
    end
end

function TF_TRAINZONE:OnBeforeEnemySpawn(From, Event, To)

    -- ref
    -- https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/Wrapper.Group.html
    -- https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/Core.Spawn.html    

    -- do spawm enemy parameters

    local bra_degree = GetRandomTableElement(self.TableSpawnBRA)
    if math.random(2) == 1 then
        local bra_degree = 360 - bra_degree
    end

    local distance_spawn = self.SpawnDistance_At180 + math.abs(bra_degree - 180) * self.SpawnDistance_K
    local alt_spawn = GetRandomTableElement(self.TableSpawnAlt)

    local zoneSpawn = ZONE_UNIT:New("spawn", self.GroupTrain:GetUnits()[1], 10, {
        rho = distance_spawn * 1800,
        theta = bra_degree,
        relative_to_unit = true
    })

    local pos_group = self.GroupTrain:GetCoordinate()
    local pos_zone = zoneSpawn:GetCoordinate()
    local heading_spawn = pos_zone:HeadingTo(pos_group)

    local type_spawn = GetRandomTableElement(self.TableEnemyTemplate)

    self.GroupEnemy = SPAWN:New(type_spawn):InitHeading(heading_spawn):InitSkill("Excellent"):SpawnInZone(zoneSpawn,
        alt_spawn, alt_spawn + 1000)
        
    -- delay enemy radar open
    if self.EnemyEmissionOpenDelay > 0 then
        self.GroupEnemy:EnableEmission(false)
        local timer_emssion = TIMER:New(function()
            self.GroupEnemy:EnableEmission(true)
        end):Start(self.EnemyEmissionOpenDelay)
    end

    -- register crash event
    self.GroupEnemy:HandleEvent(EVENTS.Crash, function()
        self:ShowMessage("GoodKill~ GoodKill~")
        self.TrainWavesFinished = self.TrainWavesFinished + 1
        if self.IsEndlessMode or self.TrainWavesFinished < self.MaxTrainWavesFinished then
            self:EmenyDisArm()
        elseif self.TrainWavesFinished >= self.MaxTrainWavesFinished then
            self:ShowMessage("你机队已经完成训练.")
            self:AbortOrFinish()
        end
    end)

    -- add task
    self.GroupEnemy:TaskAttackGroup(self.GroupTrain)



    return true
end

function TF_TRAINZONE:OnBeforeAbortOrFinish(From, Event, To)
    self:ShowMessage("退出训练空域以重置训练, 或直接返回机场")

    if self.GroupEnemy then
        self.GroupEnemy:Destroy(false, self.EnemyDestoryDelay)
    end

    -- do some cleanup
    self.TrainWavesFinished = 0
    self.GroupTrain:SetCommandImmortal(false)
    self.GroupTrain = nil

    return true
end

function GetRandomTableElement(table)
    math.random()
    math.random()
    math.random()

    return table[math.random(#table)]
end

