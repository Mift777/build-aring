return function(env)
    env.MoneySuffixes = {
        K=1e3,  M=1e6,  B=1e9,  T=1e12,
        QA=1e15, QD=1e15, QI=1e18, QN=1e18,
        SX=1e21, SP=1e24, OC=1e27, O=1e27,
        NO=1e30, N=1e30, DE=1e33, D=1e33,
        UN=1e36, UD=1e36, DD=1e39, TD=1e42,
        QAD=1e45, QID=1e48, SXD=1e51, SPD=1e54,
        OCD=1e57, NOD=1e60, VG=1e63,
    }

    env.PlotUpgrades = {
        SawRange       = {SignName="PlotUpgradeSign", UIFolder="SawRange",       RemoteArg="ExtraSawRange",       Type="plot"},
        SawYield       = {SignName="PlotUpgradeSign", UIFolder="SawYield",       RemoteArg="ExtraYield",          Type="plot"},
        SprinklerRange = {SignName="PlotUpgradeSign", UIFolder="SprinklerRange", RemoteArg="ExtraSprinklerRange", Type="plot"},
        SprinklerPower = {SignName="PlotUpgradeSign", UIFolder="SprinklerPower", RemoteArg="ExtraPower",          Type="plot"},
        SeedLuck       = {SignName="UpgradeSign",     UIFolder="SeedLuck",                                        Type="seedluck"},
        SeedRolls      = {SignName="UpgradeSign",     UIFolder="SeedRolls",                                       Type="seedrolls"},
    }

    env.UpgradeTypes    = {"SawRange","SawYield","SprinklerRange","SprinklerPower","SeedLuck","SeedRolls"}
    env.FertilizerTypes = {"Normal Fertilizer","Strong Fertilizer","Super Fertilizer"}

    _G.AutoSellCrates                     = false
    _G.AutoUnlockFarmPlots                = false
    _G.AutoExpandFarmPlot                 = false
    _G.AutoCollectQueenBeeHoneycomb       = false
    _G.AutoPlantRush                      = false
    _G.AutoClaimPlantRushBossDrop         = false
    _G.AutoSubmitQueenBeeHoneyToken       = false
    _G.AutoSubmitSeedToCollector          = false
    _G.AutoSubmitAllSeedsToCollector      = false
    _G.TargetSeedCollectorSubmitSeeds     = {}
    _G.AutoCompost                        = false
    _G.AutoCompostAllSeeds                = false
    _G.AutoPullComposterLever             = false
    _G.TargetCompostSeeds                 = {}
    _G.TargetCompostMutations             = {}
    _G.MaxCompostInsertAmount             = 0
    _G.CompostFloor                       = 2
    _G.AutoPullComposterLeverDelaySeconds = 2
    _G.AutoClaimDailyReward               = false
    _G.AutoClaimPlaytimeReward            = false
    _G.SelectedSeedTrueName               = "None"
    _G.IsDiscarding                       = false
    _G.AutoBuyAllGears                    = false
    _G.AutoBuySelectedGears               = false
    _G.TargetBuyGears                     = {}
    _G.AutoUnlockEggSlots                 = false
    _G.SessionUnlockedEggSlots            = {}
    _G.AutoBuyAllEggs                     = false
    _G.AutoBuySelectedEggs                = false
    _G.TargetEggShopEggs                  = {}
    _G.SkipMoneyCheck                     = false
    _G.AutoUpgradePlants                  = false
    _G.TargetPlantUpgradeLevel            = 10
    _G.AutoFertilize                      = false
    _G.AutoRollAndBuyAll                  = false
    _G.AutoRollAndBuySelected             = false
    _G.TargetGachaSeeds                   = {}
    _G.AutoUpgradePowerups                = false
    _G.TargetPowerups                     = {}
    _G.TargetUpgradePlantNames            = {}
    _G.TargetUpgradeMutations             = {}
    _G.TargetFertilizePlantNames          = {}
    _G.TargetFertilizeMutations           = {}
    _G.TargetFertilizerTypes              = {}
end
