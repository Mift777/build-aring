return function(env)
    if env.buildFloorTab then
        env.buildFloorTab(env, 3, env.Floor3Tab)
    else
        print("[LamduckHub] floorbuilder not loaded")
    end
end
