--[[
    ================================================================
    [ SCRIPT INFORMATION ]
    Project: Arkham Hub - Key System (Lovecraft theme)
    Author: OYB
    YouTube: https://www.youtube.com/channel/UCAlXXV1Hbvf7WbfXARuVtiQ

    [ TERMS AND CONDITIONS ]
    - You ARE allowed to use and modify this script for your own games.
    - You ARE NOT allowed to re-upload, redistribute, or claim
      ownership of this script.
    - Removing or altering these credits is strictly prohibited.

    Copyright (c) 2026 OYB. All rights reserved.
    ================================================================
]]
local Config = {
    -- [1] PlatoBoost Settings
    ServiceId       = 25664, -- Your PlatoBoost Service ID
    PlatoSecret     = "625a8610-84e0-4484-acd1-344a1f7859aa", -- Your PlatoBoost Secret Key

    -- [2] Anti-Bypass / Global Secret Variable
    Secret          = "92513198",

    -- [3] Scripts & Links
    MainScriptURL   = "https://raw.githubusercontent.com/Mift777/build-aring/refs/heads/main/main.lua",

    -- [4] Social Media Settings
    ShowDiscord     = true,
    DiscordURL      = "https://discord.gg/GMWtZFPfbA",

    ShowInstagram   = false,
    InstagramURL    = "https://www.instagram.com/oyb0i/",

    ShowYoutube     = false,
    YoutubeURL      = "https://www.youtube.com/channel/UCAlXXV1Hbvf7WbfXARuVtiQ",

    -- [5] File System
    KeyFileName     = "Mykey.txt",

    -- [6] GUI Management
    OldGuiName      = "Arkham Hub",
    MainGuiName     = "Arkham Hub",

    -- [7] Hub Information & UI Text
    HubName         = "Arkham Hub",
    HubDescription  = "Forbidden Knowledge",

    -- [8] Theme / FX toggles
    AmbientSoundId  = "rbxassetid://9046850169", -- low eldritch drone
    AmbientVolume   = 0.35,
    EnableSound     = true,
    EnableRunes     = true,
    EnableEntryAnim = true,
}

-------------------------------------------------------------------------------
--! LIBRARIES (JSON & CRYPTOGRAPHY) - DO NOT MODIFY
-------------------------------------------------------------------------------
local a=2^32;local b=a-1;local function c(d,e)local f,g=0,1;while d~=0 or e~=0 do local h,i=d%2,e%2;local j=(h+i)%2;f=f+j*g;d=math.floor(d/2)e=math.floor(e/2)g=g*2 end;return f%a end;local function k(d,e,l,...)local m;if e then d=d%a;e=e%a;m=c(d,e)if l then m=k(m,l,...)end;return m elseif d then return d%a else return 0 end end;local function n(d,e,l,...)local m;if e then d=d%a;e=e%a;m=(d+e-c(d,e))/2;if l then m=n(m,l,...)end;return m elseif d then return d%a else return b end end;local function o(p)return b-p end;local function q(d,r)if r<0 then return lshift(d,-r)end;return math.floor(d%2^32/2^r)end;local function s(p,r)if r>31 or r<-31 then return 0 end;return q(p%a,r)end;local function lshift(d,r)if r<0 then return s(d,-r)end;return d*2^r%2^32 end;local function t(p,r)p=p%a;r=r%32;local u=n(p,2^r-1)return s(p,r)+lshift(u,32-r)end;local v={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}local function w(x)return string.gsub(x,".",function(l)return string.format("%02x",string.byte(l))end)end;local function y(z,A)local x=""for B=1,A do local C=z%256;x=string.char(C)..x;z=(z-C)/256 end;return x end;local function D(x,B)local A=0;for B=B,B+3 do A=A*256+string.byte(x,B)end;return A end;local function E(F,G)local H=64-(G+9)%64;G=y(8*G,8)F=F.."\128"..string.rep("\0",H)..G;assert(#F%64==0)return F end;local function I(J)J[1]=0x6a09e667;J[2]=0xbb67ae85;J[3]=0x3c6ef372;J[4]=0xa54ff53a;J[5]=0x510e527f;J[6]=0x9b05688c;J[7]=0x1f83d9ab;J[8]=0x5be0cd19;return J end;local function K(F,B,J)local L={}for M=1,16 do L[M]=D(F,B+(M-1)*4)end;for M=17,64 do local N=L[M-15]local O=k(t(N,7),t(N,18),s(N,3))N=L[M-2]L[M]=(L[M-16]+O+L[M-7]+k(t(N,17),t(N,19),s(N,10)))%a end;local d,e,l,P,Q,R,S,T=J[1],J[2],J[3],J[4],J[5],J[6],J[7],J[8]for B=1,64 do local O=k(t(d,2),t(d,13),t(d,22))local U=k(n(d,e),n(d,l),n(e,l))local V=(O+U)%a;local W=k(t(Q,6),t(Q,11),t(Q,25))local X=k(n(Q,R),n(o(Q),S))local Y=(T+W+X+v[B]+L[B])%a;T=S;S=R;R=Q;Q=(P+Y)%a;P=l;l=e;e=d;d=(Y+V)%a end;J[1]=(J[1]+d)%a;J[2]=(J[2]+e)%a;J[3]=(J[3]+l)%a;J[4]=(J[4]+P)%a;J[5]=(J[5]+Q)%a;J[6]=(J[6]+R)%a;J[7]=(J[7]+S)%a;J[8]=(J[8]+T)%a end;local function Z(F)F=E(F,#F)local J=I({})for B=1,#F,64 do K(F,B,J)end;return w(y(J[1],4)..y(J[2],4)..y(J[3],4)..y(J[4],4)..y(J[5],4)..y(J[6],4)..y(J[7],4)..y(J[8],4))end;local e;local l={["\\"]="\\",["\""]="\"",["\b"]="b",["\f"]="f",["\n"]="n",["\r"]="r",["\t"]="t"}local P={["/"]="/"}for Q,R in pairs(l)do P[R]=Q end;local S=function(T)return"\\"..(l[T]or string.format("u%04x",T:byte()))end;local B=function(M)return"null"end;local v=function(M,z)local _={}z=z or{}if z[M]then error("circular reference")end;z[M]=true;if rawget(M,1)~=nil or next(M)==nil then local A=0;for Q in pairs(M)do if type(Q)~="number"then error("invalid table: mixed or invalid key types")end;A=A+1 end;if A~=#M then error("invalid table: sparse array")end;for a0,R in ipairs(M)do table.insert(_,e(R,z))end;z[M]=nil;return"["..table.concat(_,",").."]"else for Q,R in pairs(M)do if type(Q)~="string"then error("invalid table: mixed or invalid key types")end;table.insert(_,e(Q,z)..":"..e(R,z))end;z[M]=nil;return"{"..table.concat(_,",").."}"end end;local g=function(M)return'"'..M:gsub('[%z\1-\31\\\"]',S)..'"'end;local a1=function(M)if M~=M or M<=-math.huge or M>=math.huge then error("unexpected number value '"..tostring(M).."'")end;return string.format("%.14g",M)end;local j={["nil"]=B,["table"]=v,["string"]=g,["number"]=a1,["boolean"]=tostring}e=function(M,z)local x=type(M)local a2=j[x]if a2 then return a2(M,z)end;error("unexpected type '"..x.."'")end;local a3=function(M)return e(M)end;local a4;local N=function(...)local _={}for a0=1,select("#",...)do _[select(a0,...)]=true end;return _ end;local L=N(" ","\t","\r","\n")local p=N(" ","\t","\r","\n","]","}",",")local a5=N("\\","/",'"',"b","f","n","r","t","u")local m=N("true","false","null")local a6={["true"]=true,["false"]=false,["null"]=nil}local a7=function(a8,a9,aa,ab)for a0=a9,#a8 do if aa[a8:sub(a0,a0)]~=ab then return a0 end end;return#a8+1 end;local ac=function(a8,a9,J)local ad=1;local ae=1;for a0=1,a9-1 do ae=ae+1;if a8:sub(a0,a0)=="\n"then ad=ad+1;ae=1 end end;error(string.format("%s at line %d col %d",J,ad,ae))end;local af=function(A)local a2=math.floor;if A<=0x7f then return string.char(A)elseif A<=0x7ff then return string.char(a2(A/64)+192,A%64+128)elseif A<=0xffff then return string.char(a2(A/4096)+224,a2(A%4096/64)+128,A%64+128)elseif A<=0x10ffff then return string.char(a2(A/262144)+240,a2(A%262144/4096)+128,a2(A%4096/64)+128,A%64+128)end;error(string.format("invalid unicode codepoint '%x'",A))end;local ag=function(ah)local ai=tonumber(ah:sub(1,4),16)local aj=tonumber(ah:sub(7,10),16)if aj then return af((ai-0xd800)*0x400+aj-0xdc00+0x10000)else return af(ai)end end;local ak=function(a8,a0)local _=""local al=a0+1;local Q=al;while al<=#a8 do local am=a8:byte(al)if am<32 then ac(a8,al,"control character in string")elseif am==92 then _=_..a8:sub(Q,al-1)al=al+1;local T=a8:sub(al,al)if T=="u"then local an=a8:match("^[dD][89aAbB]%x%x\\u%x%x%x%x",al+1)or a8:match("^%x%x%x%x",al+1)or ac(a8,al-1,"invalid unicode escape in string")_=_..ag(an)al=al+#an else if not a5[T]then ac(a8,al-1,"invalid escape char '"..T.."' in string")end;_=_..P[T]end;Q=al+1 elseif am==34 then _=_..a8:sub(Q,al-1)return _,al+1 end;al=al+1 end;ac(a8,a0,"expected closing quote for string")end;local ao=function(a8,a0)local am=a7(a8,a0,p)local ah=a8:sub(a0,am-1)local A=tonumber(ah)if not A then ac(a8,a0,"invalid number '"..ah.."'")end;return A,am end;local ap=function(a8,a0)local am=a7(a8,a0,p)local aq=a8:sub(a0,am-1)if not m[aq]then ac(a8,a0,"invalid literal '"..aq.."'")end;return a6[aq],am end;local ar=function(a8,a0)local _={}local A=1;a0=a0+1;while 1 do local am;a0=a7(a8,a0,L,true)if a8:sub(a0,a0)=="]"then a0=a0+1;break end;am,a0=a4(a8,a0)_[A]=am;A=A+1;a0=a7(a8,a0,L,true)local as=a8:sub(a0,a0)a0=a0+1;if as=="]"then break end;if as~=","then ac(a8,a0,"expected ']' or ','")end end;return _,a0 end;local at=function(a8,a0)local _={}a0=a0+1;while 1 do local au,M;a0=a7(a8,a0,L,true)if a8:sub(a0,a0)=="}"then a0=a0+1;break end;if a8:sub(a0,a0)~='"'then ac(a8,a0,"expected string for key")end;au,a0=a4(a8,a0)a0=a7(a8,a0,L,true)if a8:sub(a0,a0)~=":"then ac(a8,a0,"expected ':' after key")end;a0=a7(a8,a0+1,L,true)M,a0=a4(a8,a0)_[au]=M;a0=a7(a8,a0,L,true)local as=a8:sub(a0,a0)a0=a0+1;if as=="}"then break end;if as~=","then ac(a8,a0,"expected '}' or ','")end end;return _,a0 end;local av={['"']=ak,["0"]=ao,["1"]=ao,["2"]=ao,["3"]=ao,["4"]=ao,["5"]=ao,["6"]=ao,["7"]=ao,["8"]=ao,["9"]=ao,["-"]=ao,["t"]=ap,["f"]=ap,["n"]=ap,["["]=ar,["{"]=at}a4=function(a8,a9)local as=a8:sub(a9,a9)local a2=av[as]if a2 then return a2(a8,a9)end;ac(a8,a9,"unexpected character '"..as.."'")end;local aw=function(a8)if type(a8)~="string"then error("expected argument of type string, got "..type(a8))end;local _,a9=a4(a8,a7(a8,1,L,true))a9=a7(a8,a9,L,true)if a9<=#a8 then ac(a8,a9,"trailing garbage")end;return _ end;
local lEncode, lDecode, lDigest = a3, aw, Z;

-------------------------------------------------------------------------------
--! CORE FUNCTIONS (REQUESTS & VERIFICATION)
-------------------------------------------------------------------------------

local useNonce = true

local function safeRequest(options)
    local req = request or http_request or syn_request or (http and http.request)
    if not req then return nil, "HTTP requests not supported" end
    local success, response = pcall(function() return req(options) end)
    if success and response then return response else return nil, "Connection Error" end
end

local fSetClipboard = setclipboard or toclipboard or function() end
local fStringChar, fToString, fOsTime, fMathRandom, fMathFloor = string.char, tostring, os.time, math.random, math.floor
local fGetHwid = gethwid or function() return game:GetService("RbxAnalyticsService"):GetClientId() end

local cachedLink, cachedTime = "", 0
local host = "https://api.platoboost.com"

local function checkConnectivity()
    local response = safeRequest({Url = host .. "/public/connectivity", Method = "GET"})
    if not response or (response.StatusCode ~= 200 and response.StatusCode ~= 429) then
        host = "https://api.platoboost.net"
    end
end
checkConnectivity()

local function generateNonce()
    local str = ""
    for _ = 1, 16 do str = str .. fStringChar(fMathFloor(fMathRandom() * (122 - 97 + 1)) + 97) end
    return str
end

local function cacheLink()
    if cachedTime + (10 * 60) < fOsTime() then
        local response, err = safeRequest({
            Url = host .. "/public/start",
            Method = "POST",
            Body = lEncode({service = Config.ServiceId, identifier = lDigest(fGetHwid())}),
            Headers = {["Content-Type"] = "application/json"}
        })
        if response and response.StatusCode == 200 then
            local decoded = lDecode(response.Body)
            if decoded.success then
                cachedLink = decoded.data.url
                cachedTime = fOsTime()
                return true, cachedLink
            end
        end
        return false, err or "Server Unreachable"
    end
    return true, cachedLink
end

local function redeemKey(key)
    local nonce = generateNonce()
    local body = {identifier = lDigest(fGetHwid()), key = key}
    if useNonce then body.nonce = nonce end

    local response, err = safeRequest({
        Url = host .. "/public/redeem/" .. fToString(Config.ServiceId),
        Method = "POST",
        Body = lEncode(body),
        Headers = {["Content-Type"] = "application/json"}
    })

    if response and response.StatusCode == 200 then
        local decoded = lDecode(response.Body)
        if decoded.success and decoded.data.valid then
            if useNonce then
                if decoded.data.hash == lDigest("true" .. "-" .. nonce .. "-" .. Config.PlatoSecret) then
                    if writefile then writefile(Config.KeyFileName, key) end
                    return true, "Success"
                end
                return false, "Integrity Check Failed"
            end
            if writefile then writefile(Config.KeyFileName, key) end
            return true, "Success"
        end
        return false, decoded.message or "Invalid Key"
    end
    return false, err or "Server Error"
end

-------------------------------------------------------------------------------
--! GUI & MAIN SCRIPT EXECUTION  (Arkham / Lovecraft theme)
-------------------------------------------------------------------------------

local TweenService = game:GetService("TweenService")

local function StartMainScript()
    local player = game:GetService("Players").LocalPlayer
    local pGui = player:WaitForChild("PlayerGui")
    if pGui:FindFirstChild(Config.OldGuiName) then
        pGui[Config.OldGuiName]:Destroy()
        task.wait(0.1)
    end
    _G[Config.Secret] = true
    loadstring(game:HttpGet(Config.MainScriptURL))()
end

-- ── THEME ────────────────────────────────────────────────────────────────
local Theme = {
    Abyss      = Color3.fromRGB(8, 9, 11),
    Panel      = Color3.fromRGB(14, 16, 18),
    PanelDark  = Color3.fromRGB(10, 11, 13),
    Field      = Color3.fromRGB(20, 23, 26),
    Verdigris  = Color3.fromRGB(86, 171, 140),  -- sickly eldritch green
    Eldritch   = Color3.fromRGB(126, 92, 178),  -- occult purple
    Parchment  = Color3.fromRGB(198, 188, 165), -- aged text
    Muted      = Color3.fromRGB(110, 112, 108),
    Blood      = Color3.fromRGB(150, 42, 42),
    White      = Color3.fromRGB(225, 222, 210),
}
local SERIF = Enum.Font.Garamond
local BOLD  = Enum.Font.GothamBold

-- ── helpers ──────────────────────────────────────────────────────────────
local function corner(p, r) local cc = Instance.new("UICorner", p) cc.CornerRadius = UDim.new(0, r or 8) return cc end
local function stroke(p, col, th) local sk = Instance.new("UIStroke", p) sk.Color = col sk.Thickness = th or 1 sk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border return sk end
local function gradient(p, c1, c2, rot)
    local gg = Instance.new("UIGradient", p)
    gg.Color = ColorSequence.new(c1, c2)
    gg.Rotation = rot or 90
    return gg
end
local function eldritchPulse(sk)
    task.spawn(function()
        while sk and sk.Parent do
            local tt = (tick() % 4) / 4
            local m = (math.sin(tt * math.pi * 2) + 1) / 2
            sk.Color = Theme.Verdigris:Lerp(Theme.Eldritch, m)
            task.wait()
        end
    end)
end

local function CreateGUI()
    local player = game:GetService("Players").LocalPlayer

    -- resolve safest parent (resist CoreGui auto-cleanup)
    local function resolveParent()
        -- 1] gethui(): hidden protected container, survives best
        if typeof(gethui) == "function" then
            local ok, hui = pcall(gethui)
            if ok and hui then return hui end
        end
        -- 2] CoreGui (protect if executor supports it)
        local okC, coreGui = pcall(function() return game:GetService("CoreGui") end)
        if okC and coreGui then return coreGui end
        -- 3] fallback PlayerGui
        return player:WaitForChild("PlayerGui")
    end
    local targetParent = resolveParent()

    if targetParent:FindFirstChild("OYB_KeySystem") then targetParent.OYB_KeySystem:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "OYB_KeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 999
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- protect from anti-cheat sweeps if executor allows
    local protect = (syn and syn.protect_gui) or protect_gui
    if typeof(protect) == "function" then pcall(protect, ScreenGui) end
    ScreenGui.Parent = targetParent

    -- watchdog: re-attach if removed by anti-cheat (unless user closed)
    local userClosed = false
    ScreenGui.AncestryChanged:Connect(function(_, parent)
        if not userClosed and parent == nil then
            task.wait()
            pcall(function()
                if typeof(protect) == "function" then pcall(protect, ScreenGui) end
                ScreenGui.Parent = resolveParent()
            end)
        end
    end)

    -- ambient eldritch drone
    if Config.EnableSound then
        local Ambient = Instance.new("Sound", ScreenGui)
        Ambient.SoundId = Config.AmbientSoundId
        Ambient.Volume = Config.AmbientVolume
        Ambient.Looped = true
        pcall(function() Ambient:Play() end)
        ScreenGui.Destroying:Connect(function() pcall(function() Ambient:Stop() end) end)
    end

    -- main panel
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 360, 0, 440)
    MainFrame.Position = UDim2.new(0.5, -180, 0.5, -220)
    MainFrame.BackgroundColor3 = Theme.Panel
    MainFrame.Active = true
    MainFrame.Draggable = true
    corner(MainFrame, 16)
    gradient(MainFrame, Theme.Panel, Theme.PanelDark, 90)

    local mainStroke = stroke(MainFrame, Theme.Verdigris, 1.5)
    eldritchPulse(mainStroke)

    -- faux outer glow
    local Glow = Instance.new("Frame", MainFrame)
    Glow.Size = UDim2.new(1, 8, 1, 8)
    Glow.Position = UDim2.new(0, -4, 0, -4)
    Glow.BackgroundTransparency = 1
    Glow.ZIndex = 0
    corner(Glow, 18)
    local gStroke = stroke(Glow, Theme.Eldritch, 1)
    gStroke.Transparency = 0.6
    eldritchPulse(gStroke)

    -- corner occult runes
    if Config.EnableRunes then
        local RUNES = { "\u{16A6}", "\u{2625}", "\u{26E7}", "\u{16DE}" }
        local runePos = {
            UDim2.new(0, 8, 1, -26),
            UDim2.new(1, -26, 1, -26),
        }
        for i, pos in ipairs(runePos) do
            local Rune = Instance.new("TextLabel", MainFrame)
            Rune.Size = UDim2.new(0, 20, 0, 20)
            Rune.Position = pos
            Rune.BackgroundTransparency = 1
            Rune.Text = RUNES[i]
            Rune.TextColor3 = Theme.Eldritch
            Rune.Font = SERIF
            Rune.TextSize = 18
            Rune.ZIndex = 5
            task.spawn(function()
                while Rune and Rune.Parent do
                    local m = (math.sin(tick() * 1.5 + i) + 1) / 2
                    Rune.TextTransparency = 0.3 + m * 0.5
                    Rune.TextColor3 = Theme.Verdigris:Lerp(Theme.Eldritch, m)
                    task.wait()
                end
            end)
        end
    end

    -- header
    local Header = Instance.new("Frame", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 78)
    Header.BackgroundColor3 = Theme.PanelDark
    Header.BackgroundTransparency = 0.2
    corner(Header, 16)
    gradient(Header, Theme.PanelDark, Theme.Panel, 90)

    local Sigil = Instance.new("TextLabel", Header)
    Sigil.Size = UDim2.new(0, 40, 0, 40)
    Sigil.Position = UDim2.new(0, 16, 0, 8)
    Sigil.BackgroundTransparency = 1
    Sigil.Text = "\u{2609}"  -- eldritch eye/sun sigil
    Sigil.TextColor3 = Theme.Verdigris
    Sigil.Font = SERIF
    Sigil.TextSize = 30
    task.spawn(function()
        while Sigil and Sigil.Parent do
            Sigil.Rotation = (tick() * 20) % 360
            task.wait()
        end
    end)

    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(1, -70, 0, 34)
    Title.Position = UDim2.new(0, 62, 0, 12)
    Title.BackgroundTransparency = 1
    Title.Text = Config.HubName
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextColor3 = Theme.Parchment
    Title.Font = SERIF
    Title.TextSize = 26

    local Sub = Instance.new("TextLabel", Header)
    Sub.Size = UDim2.new(1, -70, 0, 18)
    Sub.Position = UDim2.new(0, 62, 0, 44)
    Sub.BackgroundTransparency = 1
    Sub.Text = "\u{2014} " .. Config.HubDescription .. " \u{2014}"
    Sub.TextXAlignment = Enum.TextXAlignment.Left
    Sub.TextColor3 = Theme.Muted
    Sub.Font = SERIF
    Sub.TextSize = 15

    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -36, 0, 10)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "\u{2715}"
    CloseBtn.TextColor3 = Theme.Blood
    CloseBtn.Font = BOLD
    CloseBtn.TextSize = 18
    CloseBtn.ZIndex = 10
    CloseBtn.MouseButton1Click:Connect(function() userClosed = true ScreenGui:Destroy() end)

    -- divider
    local Div = Instance.new("Frame", MainFrame)
    Div.Size = UDim2.new(0.86, 0, 0, 1)
    Div.Position = UDim2.new(0.07, 0, 0, 88)
    Div.BorderSizePixel = 0
    Div.BackgroundColor3 = Theme.Verdigris
    Div.BackgroundTransparency = 0.5
    gradient(Div, Theme.Eldritch, Theme.Verdigris, 0)

    -- social button factory
    local currentYOffset = 102
    local function socialButton(label, baseCol, iconId, onClick)
        local Btn = Instance.new("TextButton", MainFrame)
        Btn.Size = UDim2.new(0.86, 0, 0, 36)
        Btn.Position = UDim2.new(0.07, 0, 0, currentYOffset)
        Btn.Text = "        " .. label
        Btn.Font = BOLD
        Btn.TextSize = 14
        Btn.BackgroundColor3 = Theme.Field
        Btn.TextColor3 = Theme.White
        Btn.AutoButtonColor = false
        corner(Btn, 8)
        stroke(Btn, baseCol, 1.2)

        local Icon = Instance.new("ImageLabel", Btn)
        Icon.Size = UDim2.new(0, 20, 0, 20)
        Icon.Position = UDim2.new(0.06, 0, 0.5, -10)
        Icon.BackgroundTransparency = 1
        Icon.Image = iconId
        Icon.ImageColor3 = baseCol

        Btn.MouseEnter:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = baseCol}):Play()
        end)
        Btn.MouseLeave:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Field}):Play()
        end)
        Btn.MouseButton1Click:Connect(onClick)
        currentYOffset = currentYOffset + 44
        return Btn
    end

    local function copyStatus(url, txt, col)
        fSetClipboard(url)
        local Status = MainFrame:FindFirstChild("StatusLabel")
        if Status then Status.Text = txt Status.TextColor3 = col end
    end

    if Config.ShowDiscord then
        socialButton("JOIN DISCORD", Color3.fromRGB(88, 101, 242), "rbxassetid://18505728201", function()
            copyStatus(Config.DiscordURL, "Discord Link Copied!", Color3.fromRGB(88, 101, 242))
            local inviteCode = string.match(Config.DiscordURL, "discord%.gg/([%w-]+)")
            if syn and syn.request and inviteCode then
                syn.request({Url = "http://localhost:1111/discord?invite=" .. inviteCode, Method = "GET"})
            end
        end)
    end
    if Config.ShowInstagram then
        socialButton("FOLLOW INSTAGRAM", Color3.fromRGB(225, 48, 108), "rbxassetid://18355586382", function()
            copyStatus(Config.InstagramURL, "Instagram Link Copied!", Color3.fromRGB(225, 48, 108))
        end)
    end
    if Config.ShowYoutube then
        socialButton("SUBSCRIBE YOUTUBE", Color3.fromRGB(255, 0, 0), "rbxassetid://82532989017804", function()
            copyStatus(Config.YoutubeURL, "YouTube Link Copied!", Color3.fromRGB(255, 0, 0))
        end)
    end

    -- key input
    local KeyInput = Instance.new("TextBox", MainFrame)
    KeyInput.Size = UDim2.new(0.86, 0, 0, 42)
    KeyInput.Position = UDim2.new(0.07, 0, 0, currentYOffset + 14)
    KeyInput.PlaceholderText = "Inscribe thy key..."
    KeyInput.PlaceholderColor3 = Theme.Muted
    KeyInput.Text = ""
    KeyInput.Font = SERIF
    KeyInput.TextSize = 16
    KeyInput.ClearTextOnFocus = false
    KeyInput.BackgroundColor3 = Theme.Field
    KeyInput.TextColor3 = Theme.Parchment
    corner(KeyInput, 8)
    stroke(KeyInput, Theme.Verdigris, 1).Transparency = 0.4

    local VerifyBtn = Instance.new("TextButton", MainFrame)
    VerifyBtn.Size = UDim2.new(0.41, 0, 0, 42)
    VerifyBtn.Position = UDim2.new(0.07, 0, 0, currentYOffset + 66)
    VerifyBtn.Text = "VERIFY"
    VerifyBtn.Font = BOLD
    VerifyBtn.TextSize = 14
    VerifyBtn.BackgroundColor3 = Theme.Verdigris
    VerifyBtn.TextColor3 = Theme.Abyss
    VerifyBtn.AutoButtonColor = false
    corner(VerifyBtn, 8)
    stroke(VerifyBtn, Theme.Verdigris, 1)

    local GetKeyBtn = Instance.new("TextButton", MainFrame)
    GetKeyBtn.Size = UDim2.new(0.41, 0, 0, 42)
    GetKeyBtn.Position = UDim2.new(0.52, 0, 0, currentYOffset + 66)
    GetKeyBtn.Text = "GET KEY"
    GetKeyBtn.Font = BOLD
    GetKeyBtn.TextSize = 14
    GetKeyBtn.BackgroundColor3 = Theme.Field
    GetKeyBtn.TextColor3 = Theme.Parchment
    GetKeyBtn.AutoButtonColor = false
    corner(GetKeyBtn, 8)
    stroke(GetKeyBtn, Theme.Eldritch, 1.2)

    local function hover(btn, hi, base)
        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = hi}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = base}):Play() end)
    end
    hover(VerifyBtn, Theme.Verdigris:Lerp(Theme.White, 0.2), Theme.Verdigris)
    hover(GetKeyBtn, Theme.Eldritch, Theme.Field)

    local Status = Instance.new("TextLabel", MainFrame)
    Status.Name = "StatusLabel"
    Status.Size = UDim2.new(1, 0, 0, 28)
    Status.Position = UDim2.new(0, 0, 0, currentYOffset + 118)
    Status.BackgroundTransparency = 1
    Status.Text = "The Old Ones await thy key..."
    Status.TextColor3 = Theme.Muted
    Status.Font = SERIF
    Status.TextSize = 15

    MainFrame.Size = UDim2.new(0, 360, 0, currentYOffset + 158)

    -- eldritch shake on wrong key
    local function shake()
        local base = MainFrame.Position
        task.spawn(function()
            for i = 1, 8 do
                local dx = (math.random() - 0.5) * 12
                local dy = (math.random() - 0.5) * 12
                MainFrame.Position = base + UDim2.new(0, dx, 0, dy)
                task.wait(0.03)
            end
            MainFrame.Position = base
        end)
    end

    -- logic
    VerifyBtn.MouseButton1Click:Connect(function()
        local key = KeyInput.Text
        if key == "" then Status.Text = "Speak a key, mortal!" Status.TextColor3 = Theme.Blood shake() return end
        Status.Text = "Communing..."
        Status.TextColor3 = Theme.Verdigris
        local success, msg = redeemKey(key)
        if success then
            Status.Text = "The seal accepts you. Loading..."
            Status.TextColor3 = Theme.Verdigris
            task.wait(0.5)
            userClosed = true
            ScreenGui:Destroy()
            StartMainScript()
        else
            Status.Text = msg
            Status.TextColor3 = Theme.Blood
            shake()
        end
    end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        Status.Text = "Summoning link..."
        Status.TextColor3 = Theme.Eldritch
        local success, link = cacheLink()
        if success then
            fSetClipboard(link)
            Status.Text = "Link Copied!"
            Status.TextColor3 = Theme.Verdigris
        else
            Status.Text = "Error: " .. tostring(link)
            Status.TextColor3 = Theme.Blood
        end
    end)

    -- auto saved-key check
    if isfile and isfile(Config.KeyFileName) then
        local savedKey = readfile(Config.KeyFileName)
        if savedKey ~= "" then
            Status.Text = "Found old sigil, verifying..."
            Status.TextColor3 = Theme.Verdigris
            task.spawn(function()
                local success = redeemKey(savedKey)
                if success then
                    Status.Text = "Auto-login success!"
                    Status.TextColor3 = Theme.Verdigris
                    task.wait(0.5)
                    ScreenGui:Destroy()
                    StartMainScript()
                else
                    Status.Text = "Saved sigil faded. Enter anew."
                    Status.TextColor3 = Color3.fromRGB(200, 140, 40)
                end
            end)
        end
    end

    -- entry animation: fade + scale from center
    if Config.EnableEntryAnim then
        local targetSize = MainFrame.Size
        local targetPos  = MainFrame.Position
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        MainFrame.BackgroundTransparency = 1

        local fadeList = {}
        for _, d in ipairs(MainFrame:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                fadeList[d] = { t = d.TextTransparency, b = d.BackgroundTransparency }
                d.TextTransparency = 1
                if d.BackgroundTransparency < 1 then d.BackgroundTransparency = 1 end
            elseif d:IsA("ImageLabel") then
                fadeList[d] = { img = d.ImageTransparency }
                d.ImageTransparency = 1
            end
        end

        local info = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        TweenService:Create(MainFrame, info, {
            Size = targetSize,
            Position = targetPos,
            BackgroundTransparency = 0,
        }):Play()

        task.wait(0.18)
        for d, vv in pairs(fadeList) do
            local goal = {}
            if vv.t   then goal.TextTransparency = vv.t end
            if vv.b   then goal.BackgroundTransparency = vv.b end
            if vv.img then goal.ImageTransparency = vv.img end
            TweenService:Create(d, TweenInfo.new(0.3), goal):Play()
        end
    end
end

-- check if main GUI already open
local player = game:GetService("Players").LocalPlayer
local pGui = player:WaitForChild("PlayerGui")
if pGui:FindFirstChild(Config.MainGuiName) then
    StartMainScript()
    return
end

CreateGUI()
