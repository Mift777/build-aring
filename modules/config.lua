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
    env.FertilizerTypes = {"Bee Fertilizer","Normal Fertilizer","Scrappy Fertilizer","Strong Fertilizer","Super Fertilizer"}
    env.SprayTypes      = {"Autumn Spray","Cosmic Spray","Frozen Spray","Radioactive Spray","Rainbow Spray","Trucker Spray","Void Spray","Wet Spray"}

    -- Core farming
    _G.AutoSellCrates                 = false
    _G.AutoUnlockFarmPlots            = false
    _G.AutoExpandFarmPlot             = false
    _G.SkipMoneyCheck                 = false
    _G.SelectedSeedTrueName           = "None"
    _G.IsDiscarding                   = false

    -- Auto upgrade powerups
    _G.AutoUpgradePowerups            = false
    _G.TargetPowerups                 = {}

    -- Floor 1 auto plant
    _G.F1_AutoPlantByRarity           = false
    _G.F1_TargetAutoPlantRarities     = {}

    -- Floor 2 auto plant
    _G.F2_AutoPlantByRarity           = false
    _G.F2_TargetAutoPlantRarities     = {}

    -- Floor 3 auto plant
    _G.F3_AutoPlantByRarity           = false
    _G.F3_TargetAutoPlantRarities     = {}

    -- Per-floor upgrade config
    _G.FloorUpgradeConfig = {
        [1] = {AutoUpgrade=false, AutoAll=false, TargetPlantNames={}, MaxLevel=10},
        [2] = {AutoUpgrade=false, AutoAll=false, TargetPlantNames={}, MaxLevel=10},
        [3] = {AutoUpgrade=false, AutoAll=false, TargetPlantNames={}, MaxLevel=10},
    }

    -- Per-floor fertilize config
    _G.FloorFertilizeConfig = {
        [1] = {AutoFertilize=false, AutoAll=false, TargetPlantNames={}, TargetFertilizerTypes={}},
        [2] = {AutoFertilize=false, AutoAll=false, TargetPlantNames={}, TargetFertilizerTypes={}},
        [3] = {AutoFertilize=false, AutoAll=false, TargetPlantNames={}, TargetFertilizerTypes={}},
    }

    -- Floor 2 compost
    _G.F2_AutoCompostSelected         = false
    _G.F2_AutoCompostByRarity         = false
    _G.F2_TargetCompostSeeds          = {}
    _G.F2_TargetCompostRarities       = {}
    _G.F2_MaxCompostInsertAmount      = 0
    _G.F2_CompostInsertDelay          = 60
    _G.F2_AutoPullLever               = false
    _G.F2_PullLeverDelay              = 60

    -- Floor 3 compost
    _G.F3_AutoCompostSelected         = false
    _G.F3_AutoCompostByRarity         = false
    _G.F3_TargetCompostSeeds          = {}
    _G.F3_TargetCompostRarities       = {}
    _G.F3_MaxCompostInsertAmount      = 0
    _G.F3_CompostInsertDelay          = 60
    _G.F3_AutoPullLever               = false
    _G.F3_PullLeverDelay              = 60

    -- Events
    _G.AutoCollectQueenBeeHoneycomb   = false
    _G.AutoPlantRush                  = false
    _G.AutoClaimPlantRushBossDrop     = false
    _G.AutoSubmitQueenBeeHoneyToken   = false
    _G.AutoSubmitSeedToCollector      = false
    _G.AutoSubmitAllSeedsToCollector  = false
    _G.TargetSeedCollectorSubmitSeeds = {}

    -- Rewards
    _G.AutoClaimDailyReward           = false
    _G.AutoClaimPlaytimeReward        = false
    _G.AutoSpinWheel                  = false

    -- Shop / gacha
    _G.AutoBuyAllGears                = false
    _G.AutoBuySelectedGears           = false
    _G.TargetBuyGears                 = {}
    _G.AutoUnlockEggSlots             = false
    _G.SessionUnlockedEggSlots        = {}
    _G.AutoBuyAllEggs                 = false
    _G.AutoBuySelectedEggs            = false
    _G.TargetEggShopEggs              = {}
    _G.AutoRollAndBuyAll              = false
    _G.AutoRollAndBuySelected         = false
    _G.AutoRollAndBuyByRarity         = false
    _G.TargetGachaSeeds               = {}
    _G.TargetGachaRarities            = {}

    -- Pets
    _G.AutoFeedPets                   = false
    _G.TargetPetTreatNames            = {}
    _G.AutoUpgradePets                = false
    _G.TargetPetUpgradeLevel          = 10
    _G.AutoSellPets                   = false
    _G.TargetPetSellNames             = {}

    -- Utilities
    _G.HideOtherPlots                 = false
    _G.MuteAndHideAlerts              = false
end
