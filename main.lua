-- ==========================================
-- F1 Fantasy Game - 2026 Persistent Edition
-- With Manual Export & Constructor Fix
-- ==========================================
local love = require("love")
local fantasyData = { teams = {} }
local state = "menu"
local feedbackMsg, feedbackTimer = "", 0
local activeInput = nil

local DATABASE_FILE = "teams_database.lua"
local EXPORT_FILE = "F1_Fantasy_Results.txt"

local inputs = {
    friend = "",
    d1 = "",
    d2 = "",
    d3 = "",
    d4 = "",
    captain = "",
    constructor = "",
    p_pole = "",
    p_1st = "",
    p_2nd = "",
    p_3rd = "",
    p_last = "",
    p_fastest = "",
    circuitName = "",
    resultStr = "",
    fastestLap = "",
    dnfs = ""
}

local colors = {
    bg = { 0.1, 0.1, 0.12 },
    btn = { 0.8, 0.1, 0.1 },
    btnHover = { 0.9, 0.2, 0.2 },
    text = { 1, 1, 1 },
    inputBg = { 0.2, 0.2, 0.25 },
    inputActive = { 0.3, 0.3, 0.4 }
}

local pointsMap = {
    Practice = { 1 },
    Shootout = { 4, 3, 2, 1 },
    Sprint = { 8, 7, 6, 5, 4, 3, 2, 1 },
    Quali = { 12, 10, 8, 7, 6, 5, 4, 3, 2, 2, 1, 1, 1, 1, 1 },
    Main = { 25, 18, 15, 12, 10, 8, 6, 4, 2, 1 }
}

local driverToConstructor = {
    ["VER"] = "Red Bull",
    ["HAD"] = "Red Bull",
    ["LEC"] = "Ferrari",
    ["HAM"] = "Ferrari",
    ["NOR"] = "McLaren",
    ["PIA"] = "McLaren",
    ["RUS"] = "Mercedes",
    ["ANT"] = "Mercedes",
    ["ALO"] = "Aston Martin",
    ["STR"] = "Aston Martin",
    ["GAS"] = "Alpine",
    ["COL"] = "Alpine",
    ["SAI"] = "Williams",
    ["ALB"] = "Williams",
    ["LAW"] = "Racing Bulls",
    ["LIN"] = "Racing Bulls",
    ["HUL"] = "Audi",
    ["BOR"] = "Audi",
    ["PER"] = "Cadillac",
    ["BOT"] = "Cadillac",
    ["OCO"] = "Haas",
    ["BEA"] = "Haas"
}

local teamLayout = {
    { label = "Friend's Name:", key = "friend", x = 300, y = 80, w = 200, h = 30 },
    { label = "Driver 1:",    key = "d1",   x = 150, y = 160, w = 200, h = 30 }, { label = "Driver 2:", key = "d2", x = 150, y = 230, w = 200, h = 30 },
    { label = "Driver 3:", key = "d3",  x = 150, y = 300, w = 200, h = 30 }, { label = "Driver 4:", key = "d4", x = 150, y = 370, w = 200, h = 30 },
    { label = "Captain:", key = "captain", x = 150, y = 440, w = 200, h = 30 }, { label = "Constructor:", key = "constructor", x = 150, y = 510, w = 200, h = 30 },
    { label = "Pred: Pole",    key = "p_pole", x = 450, y = 160, w = 200, h = 30 }, { label = "Pred: 1st Place", key = "p_1st", x = 450, y = 230, w = 200, h = 30 },
    { label = "Pred: 2nd Place", key = "p_2nd", x = 450, y = 300, w = 200, h = 30 }, { label = "Pred: 3rd Place", key = "p_3rd", x = 450, y = 370, w = 200, h = 30 },
    { label = "Pred: Last Place", key = "p_last", x = 450, y = 440, w = 200, h = 30 }, { label = "Pred: Fastest Lap", key = "p_fastest", x = 450, y = 510, w = 200, h = 30 },
}

-- ==========================================
-- FILE HANDLING (Save/Load/Export)
-- ==========================================
local function tableToString(t)
    local s = "{"
    for k, v in pairs(t) do
        local key = type(k) == "string" and string.format("[%q]", k) or "[" .. k .. "]"
        s = s .. key .. " = "
        if type(v) == "table" then
            s = s .. tableToString(v) .. ","
        elseif type(v) == "string" then
            s = s .. string.format("%q", v) .. ","
        else
            s = s .. tostring(v) .. ","
        end
    end
    return s .. "}"
end

local function saveDatabase()
    love.filesystem.write(DATABASE_FILE, "return " .. tableToString(fantasyData.teams))
end

local function loadDatabase()
    if love.filesystem.getInfo(DATABASE_FILE) then
        local chunk = love.filesystem.load(DATABASE_FILE)
        if chunk then
            fantasyData.teams = chunk()
            return true
        end
    end
    return false
end

local function exportToTextFile()
    local lines = {}
    local allCircuits = {}
    for _, team in pairs(fantasyData.teams) do
        for circ, _ in pairs(team.circuitData) do allCircuits[circ] = true end
    end

    for circ, _ in pairs(allCircuits) do
        table.insert(lines, "circuit:" .. circ)
        for fname, t in pairs(fantasyData.teams) do
            local cd = t.circuitData[circ]
            if cd then
                table.insert(lines, fname)
                local driversInfo = string.format("%s, %s, %s, %s", t.d1, t.d2, t.d3, t.d4)
                local predsInfo = string.format("Pole:%s 1st:%s 2nd:%s 3rd:%s Last:%s FL:%s", t.preds.pole, t.preds
                .first, t.preds.second, t.preds.third, t.preds.last, t.preds.fastest)
                local pointsString = cd.isSprint and
                    string.format("P1: %g, Shoot: %g, Spr: %g, Quali: %g, Race: %g", cd.p1, cd.shootout, cd.sprint,
                        cd.quali, cd.main) or
                    string.format("P1: %g, P2: %g, P3: %g, Quali: %g, Race: %g", cd.p1, cd.p2, cd.p3, cd.quali, cd.main)
                table.insert(lines,
                    string.format("%s, %s, %s, %s, %s", driversInfo, t.captain, t.constructor, predsInfo, pointsString))
            end
        end
        table.insert(lines, "")
    end
    love.filesystem.write(EXPORT_FILE, table.concat(lines, "\n"))
    return love.filesystem.getSaveDirectory() .. "/" .. EXPORT_FILE
end

-- ==========================================
-- LOVE CORE
-- ==========================================
function love.load()
    love.filesystem.setIdentity("F1FantasyApp")
    loadDatabase()
    love.window.setTitle("F1 Fantasy Manager")
    love.window.setMode(800, 700)
    love.keyboard.setKeyRepeat(true)
    font = love.graphics.setNewFont(14)
    titleFont = love.graphics.setNewFont(24)
end

function love.update(dt)
    if feedbackTimer > 0 then
        feedbackTimer = feedbackTimer - dt
        if feedbackTimer <= 0 then feedbackMsg = "" end
    end
end

local function formatDriver(str)
    if not str or str == "" then return "" end
    return string.upper(str:match("^%s*(.-)%s*$"))
end

local function drawButton(text, x, y, w, h, mx, my)
    local isHover = mx > x and mx < x + w and my > y and my < y + h
    love.graphics.setColor(isHover and colors.btnHover or colors.btn)
    love.graphics.rectangle("fill", x, y, w, h, 5, 5)
    love.graphics.setColor(colors.text)
    love.graphics.printf(text, x, y + (h / 2) - 8, w, "center")
    return isHover
end

local function drawInput(label, key, x, y, w, h, mx, my)
    love.graphics.setColor(colors.text)
    love.graphics.print(label, x, y - 18)
    local isHover = mx > x and mx < x + w and my > y and my < y + h
    love.graphics.setColor(activeInput == key and colors.inputActive or colors.inputBg)
    love.graphics.rectangle("fill", x, y, w, h, 3, 3)
    love.graphics.setColor(colors.text)
    local displayText = inputs[key] ..
    (activeInput == key and (math.floor(love.timer.getTime() * 2) % 2 == 0 and "|" or "") or "")
    love.graphics.setScissor(x, y, w, h)
    local textW = font:getWidth(displayText)
    if textW > w - 10 then
        love.graphics.print(displayText, x + w - textW - 5, y + 8)
    else
        love.graphics.print(displayText, x + 5, y + 8)
    end
    love.graphics.setScissor()
    return isHover
end

function love.draw()
    love.graphics.setBackgroundColor(colors.bg)
    local mx, my = love.mouse.getPosition()
    love.graphics.setFont(titleFont)
    love.graphics.print("F1 Fantasy Manager", 20, 20)
    love.graphics.setFont(font)

    if feedbackMsg ~= "" then
        love.graphics.setColor(0, 1, 0); love.graphics.print(feedbackMsg, 320, 25)
    end

    if state == "menu" then
        drawButton("1. Create Team", 300, 150, 200, 50, mx, my)
        drawButton("2. Update Team", 300, 220, 200, 50, mx, my)
        drawButton("3. Load Results & Points", 300, 290, 200, 50, mx, my)
        drawButton("4. View Standings", 300, 360, 200, 50, mx, my)
    elseif state == "create" or state == "update" then
        love.graphics.print(state == "create" and "--- CREATE NEW TEAM ---" or "--- UPDATE TEAM ---", 320, 40)
        for _, box in ipairs(teamLayout) do drawInput(box.label, box.key, box.x, box.y, box.w, box.h, mx, my) end
        drawButton(state == "create" and "Save Team" or "Update", 300, 600, 100, 40, mx, my)
        drawButton("Cancel", 410, 600, 100, 40, mx, my)
    elseif state == "results" then
        love.graphics.print("--- LOAD WEEKEND RESULTS ---", 280, 50)
        drawInput("Circuit Name:", "circuitName", 100, 150, 600, 30, mx, my)
        drawInput("Result String:", "resultStr", 100, 230, 600, 30, mx, my)
        drawInput("Fastest Lap (Driver Code):", "fastestLap", 100, 310, 200, 30, mx, my)
        drawInput("DNFs (Comma Separated Codes):", "dnfs", 350, 310, 350, 30, mx, my)
        drawButton("Process Points", 300, 380, 120, 40, mx, my)
        drawButton("Cancel", 440, 380, 90, 40, mx, my)
    elseif state == "standings" then
        love.graphics.print("--- CHAMPIONSHIP STANDINGS (Leaderboard) ---", 20, 80)
        -- Sorting teams by points
        local sorted = {}
        for name, t in pairs(fantasyData.teams) do table.insert(sorted, { name = name, p = t.points }) end
        table.sort(sorted, function(a, b) return a.p > b.p end)

        local y = 120
        for i, team in ipairs(sorted) do
            local t = fantasyData.teams[team.name]
            love.graphics.print(
            string.format("%d. %s | Points: %g | Const: %s | Capt: %s", i, team.name, team.p, t.constructor, t.captain),
                20, y)
            y = y + 30
        end
        drawButton("Export to TXT", 200, 600, 180, 40, mx, my)
        drawButton("Back", 400, 600, 180, 40, mx, my)
    end
end

-- ==========================================
-- CALCULATION LOGIC
-- ==========================================
local function processResults()
    if inputs.circuitName == "" then return false, "Please enter a Circuit Name!" end
    local sRaw, sStr = string.match(inputs.resultStr, "^%s*([^:]+)%s*:%s*(.*)$")
    if not sRaw then return false, "Invalid format!" end

    local s = string.lower(sRaw)
    local session, sKey = "", ""
    if s:find("p1") then
        session = "Practice"; sKey = "p1"
    elseif s:find("p2") then
        session = "Practice"; sKey = "p2"
    elseif s:find("p3") then
        session = "Practice"; sKey = "p3"
    elseif s:find("shoot") then
        session = "Shootout"; sKey = "shootout"
    elseif s:find("sprint") then
        session = "Sprint"; sKey = "sprint"
    elseif s:find("quali") then
        session = "Quali"; sKey = "quali"
    elseif s:find("main") or s:find("race") then
        session = "Main"; sKey = "main"
    else
        session = "Practice"; sKey = "p1"
    end

    local standings = {}
    if session == "Main" or session == "Sprint" then
        for item in string.gmatch(sStr, "([^,]+)") do
            local d, dlt = item:match("^%s*(.-)%s*%(([-+]?%d+)%)%s*$")
            if d then table.insert(standings, { name = formatDriver(d), posGained = tonumber(dlt) }) end
        end
    else
        for item in string.gmatch(sStr, "([^,]+)") do
            local d = formatDriver(item)
            if d ~= "" then table.insert(standings, { name = d, posGained = 0 }) end
        end
    end

    local dnfMap = {}
    for d in string.gmatch(inputs.dnfs, "([^,]+)") do
        local cl = formatDriver(d)
        if cl ~= "" then dnfMap[cl] = true end
    end
    local flDr = formatDriver(inputs.fastestLap)
    local driverPoints = {}
    local seenConstructor = {}

    local function calcTeammate(dn)
        local c = driverToConstructor[dn]
        if not c then return 0 end
        if not seenConstructor[c] then
            seenConstructor[c] = dn; return (session == "Main") and 2 or 1
        else
            return (session == "Main") and -1 or -0.5
        end
    end

    for pos, obj in ipairs(standings) do
        local pts = (pointsMap[session] and pointsMap[session][pos]) or 0
        pts = pts + (obj.posGained * 0.5)
        if session == "Main" or session == "Sprint" then pts = pts + calcTeammate(obj.name) end
        driverPoints[obj.name] = (driverPoints[obj.name] or 0) + pts
    end

    for dn in pairs(dnfMap) do
        local pts = (session == "Main") and -15 or -5
        if session == "Main" or session == "Sprint" then pts = pts + calcTeammate(dn) end
        driverPoints[dn] = (driverPoints[dn] or 0) + pts
    end

    if flDr ~= "" then
        local flPts = (session == "Main") and 3 or (session == "Sprint") and 1 or 0
        driverPoints[flDr] = (driverPoints[flDr] or 0) + flPts
    end

    local circ = inputs.circuitName
    for _, team in pairs(fantasyData.teams) do
        if not team.circuitData[circ] then team.circuitData[circ] = { p1 = 0, p2 = 0, p3 = 0, shootout = 0, sprint = 0, quali = 0, main = 0, isSprint = false } end
        if sKey == "sprint" or sKey == "shootout" then team.circuitData[circ].isSprint = true end
        local earned = 0
        local function addDr(dn)
            if not dn or dn == "" then return end
            local pts = driverPoints[dn] or 0
            if team.captain == dn then pts = pts * 2 end
            earned = earned + pts
        end
        addDr(team.d1); addDr(team.d2); addDr(team.d3); addDr(team.d4)
        if team.constructor ~= "" then
            for dn, cn in pairs(driverToConstructor) do
                -- Case-Insensitive Constructor Match
                if string.lower(cn) == string.lower(team.constructor) then earned = earned + (driverPoints[dn] or 0) end
            end
        end
        if session == "Main" then
            if standings[1] and team.preds.first == standings[1].name then earned = earned + 5 end
            if standings[2] and team.preds.second == standings[2].name then earned = earned + 5 end
            if standings[3] and team.preds.third == standings[3].name then earned = earned + 5 end
            if standings[#standings] and team.preds.last == standings[#standings].name then earned = earned + 2 end
            if flDr == team.preds.fastest then earned = earned + 3 end
        elseif session == "Quali" then
            if standings[1] and team.preds.pole == standings[1].name then earned = earned + 3 end
        end
        team.points = team.points + earned
        team.circuitData[circ][sKey] = team.circuitData[circ][sKey] + earned
    end
    saveDatabase()
    return true, "Points calculated!"
end

-- ==========================================
-- INPUTS
-- ==========================================
function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    activeInput = nil
    local showMsg = function(msg) feedbackMsg = msg; feedbackTimer = 3 end
    if state == "menu" then
        if x > 300 and x < 500 and y > 150 and y < 200 then
            state = "create"; for k in pairs(inputs) do inputs[k] = "" end
        end
        if x > 300 and x < 500 and y > 220 and y < 270 then
            state = "update"; for k in pairs(inputs) do inputs[k] = "" end
        end
        if x > 300 and x < 500 and y > 290 and y < 340 then
            state = "results"; inputs.circuitName = ""; inputs.resultStr = ""; inputs.fastestLap = ""; inputs.dnfs = ""
        end
        if x > 300 and x < 500 and y > 360 and y < 410 then state = "standings" end
    elseif state == "create" or state == "update" then
        for _, box in ipairs(teamLayout) do if x > box.x and x < box.x + box.w and y > box.y and y < box.y + box.h then activeInput =
                box.key end end
        if x > 300 and x < 400 and y > 600 and y < 640 then
            local fn = inputs.friend
            if state == "create" then
                fantasyData.teams[fn] = {
                    d1 = formatDriver(inputs.d1),
                    d2 = formatDriver(inputs.d2),
                    d3 = formatDriver(inputs.d3),
                    d4 = formatDriver(inputs.d4),
                    captain = formatDriver(inputs.captain),
                    constructor = inputs.constructor,
                    preds = { pole = formatDriver(inputs.p_pole), first = formatDriver(inputs.p_1st), second = formatDriver(inputs.p_2nd), third = formatDriver(inputs.p_3rd), last = formatDriver(inputs.p_last), fastest = formatDriver(inputs.p_fastest) },
                    points = 0,
                    circuitData = {}
                }
                showMsg("Team Created!"); state = "menu"; saveDatabase()
            elseif fantasyData.teams[fn] then
                local t = fantasyData.teams[fn]
                if inputs.d1 ~= "" then t.d1 = formatDriver(inputs.d1) end; if inputs.d2 ~= "" then t.d2 = formatDriver(
                    inputs.d2) end
                if inputs.d3 ~= "" then t.d3 = formatDriver(inputs.d3) end; if inputs.d4 ~= "" then t.d4 = formatDriver(
                    inputs.d4) end
                if inputs.captain ~= "" then t.captain = formatDriver(inputs.captain) end; if inputs.constructor ~= "" then t.constructor =
                    inputs.constructor end
                if inputs.p_pole ~= "" then t.preds.pole = formatDriver(inputs.p_pole) end; if inputs.p_1st ~= "" then t.preds.first =
                    formatDriver(inputs.p_1st) end
                if inputs.p_2nd ~= "" then t.preds.second = formatDriver(inputs.p_2nd) end; if inputs.p_3rd ~= "" then t.preds.third =
                    formatDriver(inputs.p_3rd) end
                if inputs.p_last ~= "" then t.preds.last = formatDriver(inputs.p_last) end; if inputs.p_fastest ~= "" then t.preds.fastest =
                    formatDriver(inputs.p_fastest) end
                showMsg("Updated!"); state = "menu"; saveDatabase()
            end
        end
        if x > 410 and x < 510 and y > 600 and y < 640 then state = "menu" end
    elseif state == "results" then
        if x > 100 and x < 700 and y > 150 and y < 180 then activeInput = "circuitName" end
        if x > 100 and x < 700 and y > 230 and y < 260 then activeInput = "resultStr" end
        if x > 100 and x < 300 and y > 310 and y < 340 then activeInput = "fastestLap" end
        if x > 350 and x < 700 and y > 310 and y < 340 then activeInput = "dnfs" end
        if x > 300 and x < 420 and y > 380 and y < 420 then
            local s, msg = processResults(); showMsg(msg); if s then state = "menu" end
        end
        if x > 440 and x < 530 and y > 380 and y < 420 then state = "menu" end
    elseif state == "standings" then
        if x > 200 and x < 380 and y > 600 and y < 640 then
            exportToTextFile(); showMsg("TXT Exported!")
        end
        if x > 400 and x < 580 and y > 600 and y < 640 then state = "menu" end
    end
end

function love.textinput(t) if activeInput then inputs[activeInput] = inputs[activeInput] .. t end end

function love.keypressed(key)
    if key == "backspace" and activeInput then
        local t = inputs[activeInput]; if #t > 0 then inputs[activeInput] = t:sub(1, -2) end
    elseif key == "v" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") or love.keyboard.isDown("lgui") or love.keyboard.isDown("rgui")) then
        if activeInput then inputs[activeInput] = inputs[activeInput] ..
            (love.system.getClipboardText():gsub("\n", ""):gsub("\r", "")) end
    elseif key == "return" then
        activeInput = nil
    elseif key == "o" then
        love.system.openURL("file://" .. love.filesystem.getSaveDirectory())
    elseif key == "escape" then
        love.event.quit()
    end
end