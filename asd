-- Simple Key Verification Loader with Discord Webhook Logging
-- ใช้งาน: script_key="YOUR_KEY_HERE"; loadstring(game:HttpGet("URL"))()

local webhookURL = "https://discord.com/api/webhooks/1375147331980099594/5758wuuuL-84m7Vw1u1Ztvi9iqlR-40CbS0UtbCTt56fknqZauFZ62AVZ27EX8xvGd2c"

-- ตรวจสอบว่าผู้ใช้ใส่ script_key หรือไม่
if not script_key then
    warn("❌ กรุณาใส่ script_key ก่อนรันสคริปต์นี้")
    warn("ตัวอย่าง: script_key=\"BQ27-FK38-MZN2\"; loadstring(game:HttpGet(\"URL\"))()")
    return
end

-- ฟังก์ชันดึง HWID
local function getHWID()
    local hwid = ""
    local success = pcall(function()
        hwid = game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return success and hwid or "UNKNOWN"
end

-- ฟังก์ชันดึงข้อมูลผู้เล่น
local function getPlayerInfo()
    local player = game:GetService("Players").LocalPlayer
    local playerInfo = {
        username = player and player.Name or "Unknown",
        displayName = player and player.DisplayName or "Unknown",
        userId = player and tostring(player.UserId) or "Unknown",
        accountAge = player and tostring(player.AccountAge) or "Unknown"
    }
    return playerInfo
end

-- ฟังก์ชันดึง IP (ผ่าน API ภายนอก)
local function getIPAddress()
    local success, ip = pcall(function()
        local response = game:HttpGet("https://api.ipify.org?format=text")
        return response
    end)
    return success and ip or "Unknown"
end

-- ฟังก์ชันดึงข้อมูลเกม
local function getGameInfo()
    return {
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown Game",
        gameId = tostring(game.PlaceId),
        jobId = game.JobId
    }
end

-- ฟังก์ชันส่งข้อมูลไป Discord Webhook
local function sendToWebhook(status, key, hwid, playerInfo, ip, gameInfo, message)
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    
    local embed = {
        title = status == "success" and "✅ Script Executed Successfully" or "❌ Script Execution Failed",
        color = status == "success" and 65280 or 16711680, -- Green for success, Red for failure
        fields = {
            {
                name = "🔑 Key Used",
                value = "```" .. key .. "```",
                inline = true
            },
            {
                name = "💻 HWID",
                value = "```" .. hwid .. "```",
                inline = true
            },
            {
                name = "🌐 IP Address",
                value = "```" .. ip .. "```",
                inline = true
            },
            {
                name = "👤 Player Info",
                value = "**Username:** " .. playerInfo.username .. 
                       "\n**Display Name:** " .. playerInfo.displayName ..
                       "\n**User ID:** " .. playerInfo.userId ..
                       "\n**Account Age:** " .. playerInfo.accountAge .. " days",
                inline = false
            },
            {
                name = "🎮 Game Info",
                value = "**Game:** " .. gameInfo.gameName ..
                       "\n**Place ID:** " .. gameInfo.gameId ..
                       "\n**Job ID:** " .. gameInfo.jobId,
                inline = false
            },
            {
                name = "📋 Status Message",
                value = "```" .. message .. "```",
                inline = false
            }
        },
        timestamp = timestamp,
        footer = {
            text = "Script Logger System"
        }
    }
    
    local payload = {
        username = "Script Logger",
        avatar_url = "https://cdn.discordapp.com/emojis/1234567890123456789.png",
        embeds = {embed}
    }
    
    pcall(function()
        local jsonPayload = game:GetService("HttpService"):JSONEncode(payload)
        game:HttpPost(webhookURL, jsonPayload, Enum.HttpContentType.ApplicationJson)
    end)
end

-- ฟังก์ชันตรวจสอบ Key และ HWID
local function verifyKeyAndHWID(inputKey, userHWID)
    local success, keysData = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/ADMINDOGG/key-store/refs/heads/main/keys.txt")
    end)
    
    if not success then
        warn("❌ ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้")
        return false, "ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้"
    end
    
    -- แยกข้อมูลแต่ละบรรทัด
    for line in keysData:gmatch("[^\r\n]+") do
        if line and line ~= "" then
            -- แยก parts ด้วย :
            local key, hwid, userid = line:match("([^:]+):([^:]+):?(.*)")
            
            if key and hwid then
                -- ลบ whitespace
                key = key:gsub("^%s*(.-)%s*$", "%1")
                hwid = hwid:gsub("^%s*(.-)%s*$", "%1")
                
                -- ถ้า Key ตรงกัน
                if key == inputKey then
                    -- ถ้า HWID ตรงกัน
                    if hwid == userHWID then
                        return true, "✅ Key และ HWID ถูกต้อง!"
                    else
                        return false, "❌ HWID ไม่ตรงกัน!\nHWID ที่ลงทะเบียน: " .. hwid .. "\nHWID ปัจจุบัน: " .. userHWID
                    end
                end
            end
        end
    end
    
    return false, "❌ Key ไม่ถูกต้องหรือยังไม่ได้ลงทะเบียน"
end

-- เริ่มต้นการตรวจสอบ
local userHWID = getHWID()
local playerInfo = getPlayerInfo()
local ipAddress = getIPAddress()
local gameInfo = getGameInfo()

local isValid, message = verifyKeyAndHWID(script_key, userHWID)

if isValid then
    -- ส่งข้อมูลไป Discord (สำเร็จ)
    sendToWebhook("success", script_key, userHWID, playerInfo, ipAddress, gameInfo, "Script executed successfully")
    
    -- โหลด script จริงที่นี่
    local mainScriptSuccess = pcall(function()
        -- เปลี่ยน URL ตรงนี้เป็น script หลักของคุณ
        -- loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/main_script.lua"))()
        print("DONE")
    end)
    
    if not mainScriptSuccess then
        sendToWebhook("failure", script_key, userHWID, playerInfo, ipAddress, gameInfo, "Failed to load main script")
    end
else
    -- ส่งข้อมูลไป Discord (ล้มเหลว)
    sendToWebhook("failure", script_key, userHWID, playerInfo, ipAddress, gameInfo, message)
end
