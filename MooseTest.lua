-- #1 测试ZONE_UNIT功能,是否offset绑定的触发区可以跟随单位转动而变化
-- #1 result: 会跟随机头变化
-- UnitName = 飞行员姓名
-- local unit = UNIT:FindByName("fp1-1")
-- local zoneUnit_Test = ZONE_UNIT:New("test", unit, 5, {
--     rho = 100,
--     theta = 180,
--     relative_to_unit = true
-- })
-- local timer = TIMER:New(function()
--     zoneUnit_Test:FlareZone(FLARECOLOR.Red, 6)
-- end):Start(nil, 1)
-- #1 result:OK
-- #2 测试爆炸功能是否会造成本单位的毁伤
-- #2 result: Delay参数只改变延时,但还是在飞机位置发生爆炸
-- #2 result: Explode(100)  会炸毁A10C,飞行员弹射
-- #2 result: Explode(1)    会炸伤A10C,效果未知
-- #2 result: Explode(1)    会炸伤F18,航电全部消失,飞控通道全部损坏
-- #2 result: Explode(1,1)  会炸伤F18,飞行员阵亡
-- #2 result: Explode(0.001)    不会炸伤飞机,但是有爆炸火光
-- #2 result: Explode(0.01) 不会炸伤飞机,但是有爆炸火光
-- #2 result: Explode(0.1)  不会炸伤飞机,但是有爆炸火光
-- #2 result: Explode(0.9)  航电全部消失,飞控通道全部损坏
-- #2 result: Explode(0.5)  MFD全部消失,飞控通道全部损坏,有爆炸火光和音效
-- #2 result: Explode(0.3)  MFD全部消失,飞控通道全部损坏,有爆炸火光和音效
-- #2 result: Explode(0.2)  MFD全部消失,显示STANDBY,飞控通道损坏部分,有爆炸火光和音效 --0.2当量对比18比较理想
-- #2 result: Explode(0.2)  16 通讯天线损坏
-- #2 result: Explode(0.25) 上同
-- #2 result: Explode(0.4)  上同
-- #2 result: Explode(0.5)  上同+供氧系统
-- #2 result: Explode(0.6)  上同+供氧系统
-- #2 result: Explode(0.7)  上同+供氧系统 推荐当量0.7
-- #2 result: Explode(0.75)  人没了
-- #2 result: Explode(0.8)  人没了  
-- #2 result: Explode(0.8)  15e 仅外观受损
-- #2 result: Explode(1)  15e 上同
-- #2 result: Explode(4)  15e 人没了
-- #2 result: Explode(2)  15e MFD消失,单侧引擎停转,后座人没了
-- #2 result: Explode(1.5) 15e 单侧引擎停转  推荐当量1.5
-- #2 result: Explode(0.5)  17 动力没了,MFD还在
-- #2 result: Explode(0.2)  17 动力没了,MFD还在
-- #2 result: Explode(0.1)  17 坏了一些部件,但动力还在
-- #2 result: Explode(0.15)  17 坏的东西更多了,但动力还在 推荐当量0.15
-- local unit2 = UNIT:FindByName("fp-2-1")
-- local timer2 = TIMER:New(function()
--     unit2:Explode(0.15)
-- end):Start(2)
-- #2 test finished
-- done:
-- #1 测试SHIELD_UNIT类是否工作正常
-- #2 测试连续爆炸是否会导致机体受损
-- local unit2 = UNIT:FindByName("fp-2-1")
-- local su = SHIELD_UNIT:New(unit2)
-- local t = TIMER:New(function()
--     su.Unit:MessageToAll(su.ShieldHealth .. "|" .. su:GetState())
-- end):Start(nil, 1)
-- su:SetShieldHealth(60)
-- -- remark: FSM:__Event() 是异步方法,可以再程序中序列添加
-- su:__ExitSafeZone(2) -- OK
-- su:ExitSafeZone(2) -- Not work
-- local t2 = TIMER:New(function()
--    su.Unit:MessageToAll("Exit Safe Zone")
--    su:__ExitSafeZone(2)
-- end):Start(2)
-- 结果
-- #1 基础通过
-- #2 测试加速爆炸40次不会(问题: CheckStatus状态不对)
-- local unit2 = UNIT:FindByName("fp-2-4")
-- env.info("debug:" .. unit2:GetUnitCategory())
-- remark:静态目标无法使用UNIT类
-- #1 remark:测试ZONE_UNIT功能,是否offset绑定的触发区可以跟随单位转动而变化
-- #1 remark:result: 会跟随机头变化
-- #2 remark:爆炸的目标会报错找不到单位(Object doesn't exist)
-- UnitName = 飞行员姓名
-- local unit = UNIT:FindByName("fp-2-4")
-- local zoneUnit_Test = ZONE_UNIT:New("test", unit, 25)
-- local timer = TIMER:New(function()
--     zoneUnit_Test:FlareZone(FLARECOLOR.Red, 6)    
-- end):Start(nil, 1)
-- unit:Explode(100, 5)
-- 
-- 测试STORM-STRIKE
local st = SOLAR_STORM:New()
local table_f = {"ff"}
local table_s = {"sf"}
st.TableShieldUnitNamePrefixes = table_s
st.TableFortressNamePrefixes = table_f
st.IsDebugMode = true
st:Strike()

-- local t1 = TIMER:New(function ()
--     st:Stop()    
-- end):Start(25)
--
-- test set unit
-- local su = SET_UNIT:New():FilterPrefixes("ff"):FilterStart()
-- local timer = TIMER:New(function()
--     MESSAGE:New(tostring(su:CountAlive()), 1):ToAll()
-- end):Start(0, 1)
-- result: worked as planned
