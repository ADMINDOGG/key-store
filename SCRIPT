-- ✅ ตั้งค่า Webhook URL
local webhookURL = "https://discord.com/api/webhooks/1375147331980099594/5758wuuuL-84m7Vw1u1Ztvi9iqlR-40CbS0UtbCTt56fknqZauFZ62AVZ27EX8xvGd2c"

-- ตรวจสอบว่าผู้ใช้ใส่ script_key หรือไม่
if not script_key then
    return
end

-- ✅ ฟังก์ชันดึง Executor
local function getExecutor()
    if identifyexecutor then return identifyexecutor() end
    if KRNL_LOADED then return "Krnl" end
    if isexecutorclosure then return "Script-Ware" end
    if fluxus then return "Fluxus" end
    return "Unknown"
end

-- ✅ ฟังก์ชันดึง HWID
local function getHWID()
    if syn and syn.crypt and syn.crypt.hash then
        return syn.crypt.hash("HWID_" .. tostring(game:GetService("RbxAnalyticsService"):GetClientId()))
    elseif gethwid then
        return gethwid()
    elseif identifyexecutor and identifyexecutor():lower():find("fluxus") then
        return "fluxus_" .. tostring(game:GetService("RbxAnalyticsService"):GetClientId())
    else
        return "fallback_" .. tostring(game:GetService("RbxAnalyticsService"):GetClientId())
    end
end

-- ✅ ฟังก์ชันเลือก Request
local function GetRequest()
    if syn and syn.request then return syn.request end
    if http and http.request then return http.request end
    if http_request then return http_request end
    if fluxus and fluxus.request then return fluxus.request end
    if request then return request end
    return nil
end

-- ✅ ดึง IP Address
local function getIP()
    local req = GetRequest()
    if not req then return "Unknown" end
    local success, res = pcall(function()
        return req({ Url = "https://api.ipify.org", Method = "GET" })
    end)
    return success and res and res.Body or "Unknown"
end

-- ✅ ดึงประเทศจาก IP
local function getCountry(ip)
    local req = GetRequest()
    if not req then return "Unknown" end
    local success, res = pcall(function()
        return req({ Url = "http://ip-api.com/json/" .. ip, Method = "GET" })
    end)
    if success and res and res.Body then
        local data = game:GetService("HttpService"):JSONDecode(res.Body)
        return data.country or "Unknown"
    end
    return "Unknown"
end

-- ✅ ส่งข้อมูลไปยัง Discord
local function sendToDiscord(status, key, hwid, playerInfo, executor, ip, country, message)
    local HttpService = game:GetService("HttpService")
    local embed = {
        ["username"] = status == "success" and "✅ Key Success" or "❌ Key Failed",
        ["embeds"] = {{
            ["title"] = status == "success" and "✅ Script Executed Successfully" or "❌ Script Execution Failed",
            ["color"] = status == "success" and 65280 or 16711680,
            ["fields"] = {
                { name = "👤 Username", value = playerInfo.username, inline = true },
                { name = "📛 Display Name", value = playerInfo.displayName, inline = true },
                { name = "🆔 User ID", value = playerInfo.userId, inline = true },
                { name = "🔑 Key Used", value = "```" .. key .. "```", inline = false },
                { name = "💻 HWID", value = "```" .. hwid .. "```", inline = false },
                { name = "🛠️ Executor", value = executor, inline = true },
                { name = "🌍 Country", value = country, inline = true },
                { name = "🌐 IP Address", value = ip, inline = true },
                { name = "📋 Status", value = "```" .. message .. "```", inline = false },
            },
            ["footer"] = { text = "Script Logger System" },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        GetRequest()({
            Url = webhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(embed)
        })
    end)
end

-- ฟังก์ชันตรวจสอบ Key และ HWID
local function verifyKeyAndHWID(inputKey, userHWID)
    local success, keysData = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/ADMINDOGG/key-store/refs/heads/main/keys.txt")
    end)
    
    if not success then
        return false, "ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้"
    end
    
    for line in keysData:gmatch("[^\r\n]+") do
        if line and line ~= "" then
            local key, hwid, userid = line:match("([^:]+):([^:]+):?(.*)")
            
            if key and hwid then
                key = key:gsub("^%s*(.-)%s*$", "%1")
                hwid = hwid:gsub("^%s*(.-)%s*$", "%1")
                
                if key == inputKey then
                    if hwid == userHWID then
                        return true, "Key และ HWID ถูกต้อง"
                    else
                        return false, "HWID ไม่ตรงกัน - ลงทะเบียน: " .. hwid .. " | ปัจจุบัน: " .. userHWID
                    end
                end
            end
        end
    end
    
    return false, "Key ไม่ถูกต้องหรือยังไม่ได้ลงทะเบียน"
end

-- เริ่มต้นการตรวจสอบ
local player = game:GetService("Players").LocalPlayer
local playerInfo = {
    username = player.Name,
    displayName = player.DisplayName,
    userId = tostring(player.UserId)
}

local userHWID = getHWID()
local executor = getExecutor()
local ip = getIP()
local country = getCountry(ip)

local isValid, message = verifyKeyAndHWID(script_key, userHWID)

if isValid then
    -- ส่งข้อมูลสำเร็จไป Discord
    sendToDiscord("success", script_key, userHWID, playerInfo, executor, ip, country, message)
    
    -- โหลด script หลักที่นี่
    pcall(function()
        -- เปลี่ยน URL ตรงนี้เป็น script หลักของคุณ
        -- loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/main_script.lua"))()
    end)
else
    -- ส่งข้อมูลล้มเหลวไป Discord
    sendToDiscord("failure", script_key, userHWID, playerInfo, executor, ip, country, message)
end
