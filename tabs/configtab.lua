return function(env)
    -- SaveManager/ThemeManager UI is built in main.lua via BuildConfigSection+ApplyToTab
    -- This module just adds the About section to UISettingsTab

    local InfoBox = env.UISettingsTab:AddLeftGroupbox('About')
    InfoBox:AddLabel('Build A Ring Farm')
    InfoBox:AddLabel('Script by Arkham Hub')
    InfoBox:AddLabel('UI: LinoriaLib')
    InfoBox:AddSeparator()
    InfoBox:AddLabel('Configs saved to: Arkham Hub/configs/')
end
