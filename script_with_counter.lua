-- ✅ ตั้งค่า Webhook URL
local webhookURL = "https://discord.com/api/webhooks/1375147331980099594/5758wuuuL-84m7Vw1u1Ztvi9iqlR-40CbS0UtbCTt56fknqZauFZ62AVZ27EX8xvGd2c"

-- ✅ ตั้งค่า GitHub สำหรับอัปเดตไฟล์ usage
local GITHUB_TOKEN = "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"
local REPO_OWNER = "ADMINDOGG"
local REPO_NAME = "key-store"
local USAGE_FILE_PATH = "usage_stats.txt"

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

-- ✅ ฟังก์ชัน Base64 Encode แบบใหม่ (ไม่ใช้ bit32)
local function base64Encode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result = ""
    local padding = ""
    
    for i = 1, #data, 3 do
        local a, b1, c = string.byte(data, i), string.byte(data, i+1) or 0, string.byte(data, i+2) or 0
        local bitmap = a * 65536 + b1 * 256 + c
        
        result = result .. string.sub(b, math.floor(bitmap / 262144) + 1, math.floor(bitmap / 262144) + 1)
        result = result .. string.sub(b, math.floor((bitmap % 262144) / 4096) + 1, math.floor((bitmap % 262144) / 4096) + 1)
        
        if i + 1 <= #data then
            result = result .. string.sub(b, math.floor((bitmap % 4096) / 64) + 1, math.floor((bitmap % 4096) / 64) + 1)
        else
            padding = padding .. "="
        end
        
        if i + 2 <= #data then
            result = result .. string.sub(b, (bitmap % 64) + 1, (bitmap % 64) + 1)
        else
            padding = padding .. "="
        end
    end
    
    return result .. padding
end

-- ✅ ฟังก์ชัน Base64 Decode แบบใหม่ (ไม่ใช้ bit32)
local function base64Decode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    
    local result = ""
    for i = 1, #data, 4 do
        local a, b1, c, d = data:sub(i,i), data:sub(i+1,i+1), data:sub(i+2,i+2), data:sub(i+3,i+3)
        local na = string.find(b, a) - 1
        local nb = string.find(b, b1) - 1
        local nc = (c ~= "=") and (string.find(b, c) - 1) or 0
        local nd = (d ~= "=") and (string.find(b, d) - 1) or 0
        
        local bitmap = na * 262144 + nb * 4096 + nc * 64 + nd
        
        result = result .. string.char(math.floor(bitmap / 65536))
        if c ~= "=" then
            result = result .. string.char(math.floor((bitmap % 65536) / 256))
        end
        if d ~= "=" then
            result = result .. string.char(bitmap % 256)
        end
    end
    
    return result
end

-- ✅ ฟังก์ชันดึงไฟล์ usage จาก GitHub (ปรับปรุงแล้ว)
local function getUsageFile()
    local req = GetRequest()
    if not req then 
        print("❌ No request function available")
        return nil 
    end
    
    local url = string.format("https://api.github.com/repos/%s/%s/contents/%s", REPO_OWNER, REPO_NAME, USAGE_FILE_PATH)
    print("🔍 Fetching usage file from: " .. url)
    
    local success, response = pcall(function()
        return req({
            Url = url,
            Method = "GET",
            Headers = {
                ["Authorization"] = "token " .. GITHUB_TOKEN,
                ["Accept"] = "application/vnd.github.v3+json",
                ["User-Agent"] = "RobloxScript/1.0"
            }
        })
    end)
    
    if success and response and response.Body then
        print("📋 Response received, parsing...")
        local parseSuccess, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(response.Body)
        end)
        
        if parseSuccess and data and data.content then
            print("✅ File content found, decoding...")
            local content = base64Decode(data.content:gsub("\n", ""))
            return {content = content, sha = data.sha}
        else
            print("❌ Failed to parse response or no content found")
        end
    else
        print("❌ Failed to get response")
        if response then
            print("Response Status: " .. tostring(response.StatusCode))
            print("Response Body: " .. tostring(response.Body))
        end
    end
    return nil
end

-- ✅ ฟังก์ชันอัปเดตไฟล์ usage ใน GitHub (ปรับปรุงแล้ว)
local function updateUsageFile(newContent, sha)
    local req = GetRequest()
    if not req then 
        print("❌ No request function for update")
        return false 
    end
    
    local url = string.format("https://api.github.com/repos/%s/%s/contents/%s", REPO_OWNER, REPO_NAME, USAGE_FILE_PATH)
    print("📤 Updating usage file...")
    
    local HttpService = game:GetService("HttpService")
    local base64Content = base64Encode(newContent)
    
    local body = {
        message = "Update usage stats via script",
        content = base64Content,
        sha = sha
    }
    
    local success, response = pcall(function()
        return req({
            Url = url,
            Method = "PUT",
            Headers = {
                ["Authorization"] = "token " .. GITHUB_TOKEN,
                ["Accept"] = "application/vnd.github.v3+json",
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "RobloxScript/1.0"
            },
            Body = HttpService:JSONEncode(body)
        })
    end)
    
    if success and response then
        print("📊 Update response status: " .. tostring(response.StatusCode))
        if response.StatusCode == 200 then
            print("✅ Usage file updated successfully!")
            return true
        else
            print("❌ Update failed: " .. tostring(response.Body))
        end
    else
        print("❌ Failed to send update request")
    end
    
    return false
end

-- ✅ ฟังก์ชันอัปเดตจำนวนการใช้งาน (ปรับปรุงแล้ว)
local function updateUsageCounter(key, playerInfo)
    print("🔄 Starting usage counter update...")
    
    local usageFile = getUsageFile()
    local content = ""
    local sha = nil
    
    if usageFile then
        content = usageFile.content or ""
        sha = usageFile.sha
        print("📂 Existing file loaded")
    else
        print("📂 No existing file, creating new one")
    end
    
    -- แปลงข้อมูลเป็น table เพื่อจัดการง่ายขึ้น
    local usageData = {}
    local totalRuns = 0
    
    -- อ่านข้อมูลเดิม
    for line in content:gmatch("[^\r\n]+") do
        if line and line ~= "" then
            if line:match("^TOTAL_RUNS:") then
                totalRuns = tonumber(line:match("TOTAL_RUNS:(%d+)")) or 0
            elseif line:match("^[A-Z0-9%-]+|%d+|") then
                local keyData, count, lastUser, lastTime = line:match("([^|]+)|(%d+)|([^|]*)|?(.*)")
                if keyData and count then
                    usageData[keyData] = {
                        count = tonumber(count) or 0,
                        lastUser = lastUser or "",
                        lastTime = lastTime or ""
                    }
                end
            end
        end
    end
    
    -- อัปเดตข้อมูลสำหรับ key นี้
    if not usageData[key] then
        usageData[key] = {count = 0, lastUser = "", lastTime = ""}
    end
    
    usageData[key].count = usageData[key].count + 1
    usageData[key].lastUser = playerInfo.username
    usageData[key].lastTime = os.date("%Y-%m-%d %H:%M:%S")
    totalRuns = totalRuns + 1
    
    -- สร้างเนื้อหาใหม่
    local newContent = "=== SCRIPT USAGE STATISTICS ===\n"
    newContent = newContent .. "TOTAL_RUNS:" .. totalRuns .. "\n"
    newContent = newContent .. "LAST_UPDATED:" .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
    newContent = newContent .. "=== KEY USAGE DETAILS ===\n"
    newContent = newContent .. "Format: KEY|COUNT|LAST_USER|LAST_TIME\n\n"
    
    for keyName, data in pairs(usageData) do
        newContent = newContent .. string.format("%s|%d|%s|%s\n", 
            keyName, data.count, data.lastUser, data.lastTime)
    end
    
    print("📝 New content prepared, total runs: " .. totalRuns)
    
    -- อัปเดตไฟล์
    local updateSuccess = updateUsageFile(newContent, sha)
    
    if updateSuccess then
        return usageData[key].count
    else
        return nil
    end
end

-- ✅ ส่งข้อมูลไปยัง Discord พร้อมจำนวนการใช้งาน
local function sendToDiscord(status, key, hwid, playerInfo, executor, ip, country, message, usageCount)
    local HttpService = game:GetService("HttpService")
    local usageText = usageCount and tostring(usageCount) or "Failed to update"
    
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
                { name = "📊 Usage Count", value = "**" .. usageText .. "** times", inline = true },
                { name = "📋 Status", value = "```" .. message .. "```", inline = false },
            },
            ["footer"] = { text = "Script Logger System • Usage Tracking Enabled" },
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

print("🚀 Starting script execution...")
print("👤 User: " .. playerInfo.username)
print("🔑 Key: " .. script_key)
print("💻 HWID: " .. userHWID)

local isValid, message = verifyKeyAndHWID(script_key, userHWID)

if isValid then
    print("✅ Key validation successful!")
    
    -- อัปเดตจำนวนการใช้งานใน GitHub
    local usageCount = updateUsageCounter(script_key, playerInfo)
    local usageStatus = usageCount and ("Updated to " .. usageCount) or "Failed to update"
    
    print("📊 Usage tracking: " .. usageStatus)
    
    -- ส่งข้อมูลสำเร็จไป Discord
    sendToDiscord("success", script_key, userHWID, playerInfo, executor, ip, country, 
        message .. " | Usage tracking: " .. usageStatus, usageCount)
    
    -- โหลด script หลักที่นี่
    pcall(function()
        -- เปลี่ยน URL ตรงนี้เป็น script หลักของคุณ
        -- loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/main_script.lua"))()
        print("🎉 Script loaded successfully! Usage count: " .. tostring(usageCount or "N/A"))
    end)
else
    print("❌ Key validation failed: " .. message)
    
    -- ส่งข้อมูลล้มเหลวไป Discord
    sendToDiscord("failure", script_key, userHWID, playerInfo, executor, ip, country, message, nil)
end
