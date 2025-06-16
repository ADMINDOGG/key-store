-- Simple Key Verification Loader
-- ใช้งาน: script_key="YOUR_KEY_HERE"; loadstring(game:HttpGet("URL"))()

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
print("🔍 กำลังตรวจสอบ Key: " .. script_key)

local userHWID = getHWID()
print("💻 HWID ของคุณ: " .. userHWID)

local isValid, message = verifyKeyAndHWID(script_key, userHWID)

if isValid then
    print(message)
    print("🚀 กำลังโหลด Script หลัก...")
    
    -- โหลด script จริงที่นี่
    local mainScriptSuccess = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/main_script.lua"))() -- เปลี่ยน URL นี้
    end)
    
    if mainScriptSuccess then
        print("✅ โหลด Script สำเร็จ!")
    else
        warn("❌ เกิดข้อผิดพลาดในการโหลด Script หลัก")
    end
else
    warn(message)
    warn("🔑 หากต้องการลงทะเบียน Key ใหม่ ให้ติดต่อแอดมิน")
end
