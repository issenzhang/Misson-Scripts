-- by ISSEN / issen.gamming@outlook.com

Table_Pattern_CN = {
    "1-未分类",
    "2-滑行",
    "3-滑跑",
    "4-一边(爬升)",
    "5-一转三",
    "6-三边",
    "7-着陆准备",
    "8-四边",
    "9-五边(进近)",
    "10-着陆",
    "11-滑回",
    "12-结束" }


function append_string(string, append)
    return string .. append .. "\n"
end

L39 =
{
    is_check_climb         = false,
    is_checked_7km         = false,
    is_checked_final_outer = false,
    is_checked_final_inner = false,
}

function L39:New(_unit_name)
    local self      = BASE:Inherit(self, TrainSystem:New(_unit_name))
    self.full_score = 35
    self.pass_score = 28

    self:InitPatternTable(Table_Pattern_CN)
    return self
end

function L39:CheckPattern_Taxi()
    local MAX_GROUND_SPEED = 60
    local MAX_GROUND_TURNING_SPEED = 20
    local groun_speed = self:GetSpeed()

    if self:IsInZone("z-taxi-s-1") or self:IsInZone("z-taxi-s-2") then
        if groun_speed >= MAX_GROUND_SPEED * 0.5 then
            self:AddPenaltyByDetail("taxi_overspeed", 5, "滑行超速50%~", self.current_pattern)
        elseif groun_speed >= MAX_GROUND_SPEED * 0.25 then
            self:AddPenaltyByDetail("taxi_overspeed", 2, "滑行超速25%~50%", self.current_pattern)
        elseif groun_speed >= MAX_GROUND_SPEED then
            self:AddPenaltyByDetail("taxi_overspeed", 1, "滑行超速0%~25%", self.current_pattern)
        end
    end

    if self:IsInZone("z-taxi-s-1") and self:IsNotInZone("z-taxi-s-c-1") then
        self:AddPenaltyByDetail("taxi_notcenter", 5, "滑行未压中线", self.current_pattern)
    end

    if self:IsInZone("z-taxi-s-2") and self:IsNotInZone("z-taxi-s-c-2") then
        self:AddPenaltyByDetail("taxi_notcenter", 5, "滑行未压中线", self.current_pattern)
    end

    if self:IsInZone("z-taxi-turning") then
        if groun_speed >= MAX_GROUND_TURNING_SPEED * 0.5 then
            self:AddPenaltyByDetail("taxi_overspeed", 5, "滑行超速50%~(转弯)", self.current_pattern)
        elseif groun_speed >= MAX_GROUND_TURNING_SPEED * 0.25 then
            self:AddPenaltyByDetail("taxi_overspeed", 2, "滑行超速25%~50%(转弯)", self.current_pattern)
        elseif groun_speed >= MAX_GROUND_TURNING_SPEED then
            self:AddPenaltyByDetail("taxi_overspeed", 1, "滑行超速0%~25%(转弯)", self.current_pattern)
        end
    end

    if groun_speed >= 200 then
        self:AddPenaltyByDetail("taxi_not_rolling_takeoff", 35, "非标准起飞", self.current_pattern)
    end
    return self
end

function L39:CheckPattern_Rolling()
    --起飞俯仰检测起始值
    local SPEED_ROLLING_PITCH = 120

    --最大滑跑速度
    local SPEED_ROLLING_MAX = 210

    local speed = self:GetSpeed()
    local pitch = self:GetPitch()

    if speed >= SPEED_ROLLING_PITCH then
        if pitch >= 15 then
            self:AddPenaltyByDetail("rolling_pitch", 3, "滑跑迎角≥15°", self.current_pattern)
        elseif pitch >= 10 then
            self:AddPenaltyByDetail("rolling_pitch", 1, "滑跑迎角≥10°", self.current_pattern)
        end
    end

    local ZONE_ROLLING_2 = "z-rolling-2"
    local ZONE_ROLLING_1 = "z-rolling-1"

    if self:IsNotInZone(ZONE_ROLLING_2) == true then
        self:AddPenaltyByDetail("rolling_angle", 2, "滑跑偏航≥5°", self.current_pattern)
    elseif self:IsNotInZone(ZONE_ROLLING_1) == true then
        self:AddPenaltyByDetail("rolling_angle", 1, "滑跑偏航≥3°", self.current_pattern)
    end

    --非正式监测项目
    if speed >= SPEED_ROLLING_MAX then
        self.temp_penalty_rolling_pitch:Instead(3, "滑跑超速或襟翼位置不正确", self.current_pattern)
    end
    return self
end

function L39:CheckPattern_Upwind()
    if self:IsInZone("z-takeoff-check") then
        if self:IsNotInZone("z-takeoff-2") == true then
            self:AddPenaltyByDetail("takeoff_angle", 2, "起飞偏航≥5°", self.current_pattern)
        elseif self:IsNotInZone("z-takeoff-1") == true then
            self:AddPenaltyByDetail("takeoff_angle", 1, "起飞偏航≥3°", self.current_pattern)
        end
    end

    local height = self:GetAltitude(true) -- 用雷达高度替代
    -- 起飞超高不转向
    local HEIGHT_TAKEOFF_MAX = 460
    if height > HEIGHT_TAKEOFF_MAX then
        self:AddPenaltyByDetail("takeoff_height", 2, "高度450m仍未转向", self.current_pattern)
    end

    -- 起飞反复接地
    if self._unit:InAir() == false then
        self:AddPenaltyByDetail("takeoff_touchground", 5, "起飞反复接地", self.current_pattern)
    end
    return self
end

function L39:CheckPattern_Crosswind()
    -- 一转三坡度
    local roll = self:GetRoll()
    local ROLL_MAX_2 = 45
    local ROLL_MAX_1 = 35
    if roll >= ROLL_MAX_2 then
        self:AddPenaltyByDetail("upwind_roll", 2, "一转三坡度≥45°", self.current_pattern)
    elseif roll >= ROLL_MAX_1 then
        self:AddPenaltyByDetail("upwind_roll", 1, "一转三坡度≥35", self.current_pattern)
    end
    return self
end

function L39:CheckPattern_Climb()
    local vv = self:GetVV()
    if vv <= -1 then
        self:AddPenaltyByDetail("climb_error", 35, "爬升阶段中掉高", self.current_pattern)
    end
end

function L39:CheckPattern_Downwind()
    local ias = self:GetIAS()
    if ias <= 350 then
        self:AddPenaltyByDetail("downwind_lowspeed", 3, "三边空速≤350Km/h", self.current_pattern)
    elseif ias <= 380 then
        self:AddPenaltyByDetail("downwind_lowspeed", 1, "三边空速≤380Km/h", self.current_pattern)
    end

    if ias >= 450 then
        self:AddPenaltyByDetail("downwind_overspeed", 3, "三边空速≥450Km/h", self.current_pattern)
    elseif ias >= 420 then
        self:AddPenaltyByDetail("downwind_overspeed", 1, "三边空速≥420Km/h", self.current_pattern)
    end

    local height = self:GetGetAltitude(true)
    if height >= 650 then
        self:AddPenaltyByDetail("downwind_toohigh", 3, "三边高度≥650m", self.current_pattern)
    elseif height >= 620 then
        self:AddPenaltyByDetail("downwind_toohigh", 1, "三边高度≥620m", self.current_pattern)
    end

    if height <= 550 then
        self:AddPenaltyByDetail("downwind_toolow", 3, "三边高度≤550m", self.current_pattern)
    elseif height <= 580 then
        self:AddPenaltyByDetail("downwind_toolow", 1, "三边高度≤580m", self.current_pattern)
    end

    local heading = self._unit:GetHeading(true)
    local heading_delta = math.abs(277 - heading)
    if heading_delta > 5 then
        self:AddPenaltyByDetail("downwind_angle", 2, "三边偏航>5°", self.current_pattern)
    elseif heading_delta > 3 then
        self:AddPenaltyByDetail("downwind_angle", 1, "三边偏航>3°", self.current_pattern)
    end

    return self
end

function L39:CheckPattern_PreBase()
    local heading = self._unit:GetHeading(true)
    local heading_delta = math.abs(277 - heading)
    if heading_delta > 5 then
        self:AddPenaltyByDetail("prebase_angle", 2, "减速过程偏航>5°", self.current_pattern)
    elseif heading_delta > 3 then
        self:AddPenaltyByDetail("prebase_angle", 1, "减速过程偏航>3°", self.current_pattern)
    end

    local height = self._unit:GetAltitude(true)
    if height >= 650 then
        self:AddPenaltyByDetail("prebase_toohigh", 3, "减速过程高度≥650m", self.current_pattern)
    elseif height >= 620 then
        self:AddPenaltyByDetail("prebase_toohigh", 1, "减速过程高度≥620m", self.current_pattern)
    end

    if height <= 550 then
        self:AddPenaltyByDetail("prebase_toolow", 3, "减速过程高度≤550m", self.current_pattern)
    elseif height <= 580 then
        self:AddPenaltyByDetail("prebase_toolow", 1, "减速过程高度≤580m", self.current_pattern)
    end

    local speed = self:GetSpeed()
    local ZONE_GEARDOWN = "z-geardown"
    if self:IsInZone(ZONE_GEARDOWN) and speed >= 380 then
        self:AddPenaltyByDetail("prebase_toolong", 3, "NDB过250°未减速", self.current_pattern)
    end
    return self
end

function L39:CheckPattern_Base()
    local ias = self:GetSpeed()
    if ias >= 300 then
        self:AddPenaltyByDetail("base_overspeed", 3, "二转空速≥300Km/h", self.current_pattern)
    elseif ias <= 280 then
        self:AddPenaltyByDetail("base_overspeed", 1, "二转空速≤200Km/h", self.current_pattern)
    end

    local climb = self:GetVV()
    if climb > 1.0 then
        self:AddPenaltyByDetail("base_climb", 35, "二转出现爬升", self.current_pattern)
    end

    local height = self:GetAltitude(true)
    local distance = self._unit:GetCoordinate():Get2DDistance(ZONE:New("z-10km"):GetCoordinate())
    if height <= 300 and distance > 10000 then
        self:AddPenaltyByDetail("base_toolow", 35, "二转过低(<300m)", self.current_pattern)
    end
    return self
end

function L39:CheckPattern_Final()
    local ias = self:GetIAS()
    if ias >= 300 then
        self:AddPenaltyByDetail("final_overspeed", 3, "进近空速≥300Km/h", self.current_pattern)
    elseif ias <= 280 then
        self:AddPenaltyByDetail("final_overspeed", 1, "进近空速≤200Km/h", self.current_pattern)
    end

    local climb = self:GetVV()
    if climb > 1.0 then
        self:AddPenaltyByDetail("final_climb", 35, "进近出现爬升", self.current_pattern)
    end

    local height = self:GetAltitude(true)
    local distance = self._unit:GetCoordinate():Get2DDistance(ZONE:New("z-10km"):GetCoordinate())
    if height <= 300 and distance > 10000 then
        self:AddPenaltyByDetail("final_10km_toolow", 35, "10km进近过低(<300m)", self.current_pattern)
    end

    if self:IsInZone("z-final-7km") and self.is_checked_7km == false then
        if self:IsInZone("z-7km-aim") == true then
            self:AddPenaltyByDetail("final-7km", 3, "7km未对准跑道", self.current_pattern)
        end
        self.is_checked_7km = true
    end

    if self:IsInZone("z-final-outer") and self.is_checked_final_outer == false then
        MESSAGE:New("远台高度: " .. height .. "m", 20):ToClient(self._client)
        if height >= 230 then
            self:AddPenaltyByDetail("final_outer_high", 2, "远台高度≥230m", self.current_pattern)
        elseif height <= 120 then
            self:AddPenaltyByDetail("final_outer_low", 2, "远台高度≤120m", self.current_pattern)
        end
        self.is_checked_final_outer = true
    end

    if self:IsInZone("z-final-inner") and self.is_checked_final_inner == false then
        MESSAGE:New("近台高度: " .. height .. "m", 20):ToClient(self._client)
        if height >= 110 then
            self:AddPenaltyByDetail("final_inner_high", 2, "近台高度≥110m", self.current_pattern)
        elseif height <= 40 then
            self:AddPenaltyByDetail("final_inner_low", 2, "近台高度≤40m", self.current_pattern)
        end
        self.is_checked_final_inner = true
    end

    --拉漂判断
    return self
end

--触地判断
function L39:CheckPattern_Landing()
    if self:IsNotInZone("z-landing-aim") then
        self:AddPenaltyByDetail("landing_not_in_area", 3, "着陆超出接地区", self.current_pattern)
    end

    if self:IsNotInZone("z-rolling-center") then
        self:AddPenaltyByDetail("landing_not_aim_center", 35, "着陆未压中线", self.current_pattern)
    end
    return self
end

function L39:CheckPattern_AfterLanding()
    if self._unit:InAir() == true then
        self:AddPenaltyByDetail("repeat_landing", 3, "着陆弹跳", self.current_pattern)
    end

    if self:IsNotInZone("z-rolling-center") == true then
        self:AddPenaltyByDetail("landing_center", 35, "接地,滑行未保持中线", self.current_pattern)
    end
    return self
end

function L39:CheckPattern_TaxiBack()
    local ground_speed = self._unit:GetVelocityKMH()
    local MAX_GROUND_SPEED = 60

    if ground_speed >= MAX_GROUND_SPEED * 0.5 then
        self:AddPenaltyByDetail("taxi_back_overspeed", 5, "滑行超速50%~", self.current_pattern)
    elseif ground_speed >= MAX_GROUND_SPEED * 0.25 then
        self:AddPenaltyByDetail("taxi_back_overspeed", 2, "滑行超速25%~50%", self.current_pattern)
    elseif ground_speed >= MAX_GROUND_SPEED then
        self:AddPenaltyByDetail("taxi_back_overspeed", 1, "滑行超速0%~25%", self.current_pattern)
    end

    if self:IsInZone("z-miss-exit") == true then
        self:AddPenaltyByDetail("miss_exit", 3, "错过滑行道", self.current_pattern)
    end
    return self
end

function L39:CheckOutBound()
    if self:CheckTrainning() == true
    then
        if self:IsNotInZone("z-trainning") then
            self:AddPenaltyByDetail("outbound", 35, "离开训练区域", self.current_pattern)
            self:TrainStop()
        end
    end
    return self
end

function L39:ControlStatus_Taxi()
    self:CheckPattern_Taxi()

    local ground_speed = self._unit:GetVelocityKMH()
    if self:IsInZone("z-pre-takeoff") and ground_speed < 3 then
        self.current_pattern = 3
        return true
    end
    return false
end

function L39:ControlStatus_Rolling()
    self:CheckPattern_Taxi()

    if self._unit:InAir() == true then
        self.current_pattern = 4
        self.check_climb = true
        return true
    end
    return false
end

function L39:ControlStatus_Upwind()
    self:CheckPattern_Upwind()

    local height = self:GetAltitude(true)
    local ias = self:GetIAS()
    local roll = self:GetRoll()

    if height > 350 and ias > 350 and roll > 5 then
        self.current_pattern = 5
        return true
    end
    return false
end

function L39:ControlStatus_Climb()
    if self.check_climb == true then
        self:CheckPattern_Climb()
    end

    local height = self:GetAltitude(true)
    if self.current_pattern == 4 or self.current_pattern == 5 or self.current_pattern == 6 then
        if height > 560 then
            self.check_climb = false
        end
    end
end

function L39:ControlStatus_CrossWind()
    self:CheckPattern_Crosswind()

    local height = self:GetAltitude(true)
    local roll = self:GetRoll()

    if height >= 580 and roll <= 5 then
        self.current_pattern = 6
        return true
    end
    return false
end

function L39:ControlStatus_DownWind()
    self:CheckPattern_Downwind()

    if self:IsInZone("z-pre-landing") then
        self.current_pattern = 7
        return true
    end
    return false
end

function L39:ControlStatus_PreBase()
    self:CheckPattern_PreBase()

    local roll = self._unit:GetRoll()
    if roll >= 12 then
        self.current_pattern = 8
        return true
    end
    return false
end

function L39:ControlStatus_Base()
    self:CheckPattern_Base()

    local roll = self._unit:GetRoll()
    local heading = self._unit:GetHeading()
    local heading_delta = math.abs(87 - heading)
    if roll <= 10 and heading_delta <= 10 and self:IsInZone("z-final") then
        self.current_pattern = 9
        return true
    end
    return false
end

function L39:ControlStatus_Final()
    self:CheckPattern_Final()

    if self._unit:IsAir() == false then
        self.current_pattern = 10

        --检查着陆点位置以及接地姿态(仅瞬时检测一次)
        self:CheckPattern_Landing()
        return true
    end
    return false
end

function L39:ControlStatus_AfterLanding()
    self:CheckPattern_AfterLanding()

    local ground_speed = self._unit:GetVelocityKMH()

    if ground_speed <= 55 then
        self.current_pattern = 11
        return true
    end
    return false
end

function L39:ControlStatus_TaxiBack()
    self:CheckPattern_TaxiBack()

    if self:IsInZone("z-end") == true then
        self.current_pattern = 12
        return true
    end
    return false
end

function L39:ShowDebugData()
    if self._debug_mode == true then
        local msg = self:ToStringData()
        MESSAGE:New(msg, 1):Clear():ToAll()
    end
    return self
end

function L39:CheckTrainning()
    if self.current_pattern >= 2 and self.current_pattern <= 11 then
        return true
    else
        return false
    end
end

function L39:CallStatus()
    -- if self._debug_mode == true then
    --     self:ShowDebugData()
    -- end

    self:ShowDebugData()

    if self.current_pattern == 2 then
        self:ControlStatus_Taxi()
    elseif self.current_pattern == 3 then
        self:ControlStatus_Rolling()
    elseif self.current_pattern == 4 then
        self:ControlStatus_Upwind()
    elseif self.current_pattern == 5 then
        self:ControlStatus_CrossWind()
    elseif self.current_pattern == 6 then
        self:ControlStatus_Base()
    elseif self.current_pattern == 7 then
        self:ControlStatus_PreBase()
    elseif self.current_pattern == 3 then
        self:ControlStatus_Base()
    elseif self.current_pattern == 9 then
        self:ControlStatus_Final()
    elseif self.current_pattern == 10 then
        self:ControlStatus_AfterLanding()
    elseif self.current_pattern == 11 then
        self:ControlStatus_TaxiBack()
    elseif self.current_pattern == 12 then
        self:TrainStop()
    end

    if self.check_climb == true then
        self:CheckPattern_Climb()
    end

    return self
end

function L39:TrainStart()
    local msg = ""
    if self.current_pattern == 1 or self.current_pattern == 12 then
        msg = append_string(msg, self._unit:GetPlayerName() .. "开始五边模拟考核,祝次次压中线")
        MESSAGE:New(msg, 30, nil, true):ToClient(self._client)
        self.current_pattern = 2
        self.timer_train = TIMER:New(self.CallStatus, self):Start(0, self.main_timer_detla_time)
        self:SetDebugMode(true)
        return self
    else
        msg = append_string(msg, self._client.Name() " .. 已经在考试阶段中(状态:" ..
            self:GetCurrentPattern() .. ")")
        return self
    end
end

function L39:TrainStop()
    self.timer_train:Stop()
    local msg = ""
    msg = append_string(msg, self._client .. "考核结束!")
    msg = append_string(msg, self:GetReport())
    self.timer_train:Stop()
    MESSAGE:New(msg, 60, nil, true):ToAll()
end

local set_clients = SET_CLIENT:New():FilterActive():FilterCategories("plane"):FilterStart()
local set_inTraining = SET_CLIENT:New()

function init_test(client)
    if set_inTraining:IsNotInSet(client) then
        set_inTraining:AddClientsByName(client:GetName())
        local l39 = L39:New(client:GetName())
        l39:TrainStart()
    end
end

-- local timer_mission = TIMER:New(
--     function()
--         set_clients:ForEachClientInZone(ZONE:New("z-init"), init_test)
--     end):Start(0, 1)

local timer_mission = TIMER:New(
    function()
        local clients = set_clients:GetSetObjects()
        for _, v in ipairs(clients) do
            if v:IsInZone(ZONE:New("z-init")) == true then
                init_test(v)
            end
        end
    end):Start(0, 1)
