local love = require("love")
-- ==========================================
-- F1 Fantasy Game - 2026 Persistent Edition
-- Added: Teammate DNS Rule & Global Constructor Session Logging
-- ==========================================

local fantasyData = { teams = {}, results = {} }
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
    fastestLap = "",
    leader = "",
    dnfs = "",
    p1 = "",
    p2 = "",
    p3 = "",
    shootout = "",
    sprint = "",
    quali = "",
    main = "",
    bulk_input = "",
    bulk_teams = ""
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
    Quali = { 10, 8, 6, 5, 4, 3, 2, 1 },
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
    { label = "Friend's Name:", key = "friend", x = 300, y = 80,  w = 200, h = 30 },
    { label = "Driver 1:",      key = "d1",     x = 150, y = 160, w = 200, h = 30 }, { label = "Driver 2:", key = "d2", x = 150, y = 230, w = 200, h = 30 },
    { label = "Driver 3:", key = "d3",      x = 150, y = 300, w = 200, h = 30 }, { label = "Driver 4:", key = "d4", x = 150, y = 370, w = 200, h = 30 },
    { label = "Captain:",  key = "captain", x = 150, y = 440, w = 200, h = 30 }, { label = "Constructor:", key = "constructor", x = 150, y = 510, w = 200, h = 30 },
    { label = "Pred: Pole",      key = "p_pole", x = 450, y = 160, w = 200, h = 30 }, { label = "Pred: 1st Place", key = "p_1st", x = 450, y = 230, w = 200, h = 30 },
    { label = "Pred: 2nd Place", key = "p_2nd",  x = 450, y = 300, w = 200, h = 30 }, { label = "Pred: 3rd Place", key = "p_3rd", x = 450, y = 370, w = 200, h = 30 },
    { label = "Pred: Last Place", key = "p_last", x = 450, y = 440, w = 200, h = 30 }, { label = "Pred: Fastest Lap", key = "p_fastest", x = 450, y = 510, w = 200, h = 30 },
}

local resultsLayout = {
    { label = "Circuit Name:",                                             key = "circuitName", x = 30,  y = 100, w = 180, h = 30 },
    { label = "Leader:",                                                   key = "leader",      x = 30,  y = 170, w = 180, h = 30 },
    { label = "Fastest Lap:",                                              key = "fastestLap",  x = 30,  y = 240, w = 180, h = 30 },
    { label = "DNFs (Comma Sep):",                                         key = "dnfs",        x = 30,  y = 310, w = 180, h = 30 },

    { label = "P1:",                                                       key = "p1",          x = 240, y = 100, w = 250, h = 30 },
    { label = "P2:",                                                       key = "p2",          x = 240, y = 170, w = 250, h = 30 },
    { label = "P3:",                                                       key = "p3",          x = 240, y = 240, w = 250, h = 30 },
    { label = "Shootout:",                                                 key = "shootout",    x = 240, y = 310, w = 250, h = 30 },

    { label = "Sprint:",                                                   key = "sprint",      x = 520, y = 100, w = 250, h = 30 },
    { label = "Quali:",                                                    key = "quali",       x = 520, y = 170, w = 250, h = 30 },
    { label = "Main Race:",                                                key = "main",        x = 520, y = 240, w = 250, h = 30 },

    { label = "Bulk Input (Paste multi-session text here to Auto-Fill!):", key = "bulk_input",  x = 30,  y = 400, w = 740, h = 30 }
}

-- ==========================================
-- FILE HANDLING & UTILS
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
    local dataToSave = { teams = fantasyData.teams, results = fantasyData.results }
    love.filesystem.write(DATABASE_FILE, "return " .. tableToString(dataToSave))
end

local function loadDatabase()
    if love.filesystem.getInfo(DATABASE_FILE) then
        local chunk = love.filesystem.load(DATABASE_FILE)
        if chunk then
            local data = chunk()
            if data.teams then
                fantasyData.teams = data.teams
                fantasyData.results = data.results or {}
            else
                fantasyData.teams = data
                fantasyData.results = {}
            end
            return true
        end
    end
    return false
end

local function getOrdinal(n)
    local suffix = "th"
    if n % 10 == 1 and n % 100 ~= 11 then
        suffix = "st"
    elseif n % 10 == 2 and n % 100 ~= 12 then
        suffix = "nd"
    elseif n % 10 == 3 and n % 100 ~= 13 then
        suffix = "rd"
    end
    return n .. suffix
end

local function exportToTextFile()
    local lines = {}
    local allCircuits = {}
    for _, team in pairs(fantasyData.teams) do
        for circ, _ in pairs(team.circuitData) do allCircuits[circ] = true end
    end

    local orderedCircuits = {}
    for circ, _ in pairs(allCircuits) do table.insert(orderedCircuits, circ) end

    for _, circ in ipairs(orderedCircuits) do
        table.insert(lines, "================================================================================")
        table.insert(lines, "CIRCUIT: " .. string.upper(circ))
        table.insert(lines, "================================================================================")
        table.insert(lines, "")

        for fname, team in pairs(fantasyData.teams) do
            local cd = team.circuitData[circ]
            if cd then
                table.insert(lines, "--------------------------------------------------------------------------------")
                table.insert(lines, "TEAM: " .. fname)
                table.insert(lines, "--------------------------------------------------------------------------------")
                local r = cd.roster or team
                table.insert(lines, string.format("Roster: %s, %s, %s, %s", r.d1, r.d2, r.d3, r.d4))
                table.insert(lines, string.format("Captain: %s | Constructor: %s", r.captain, r.constructor))

                local totalPoints = 0
                for _, sKey in ipairs({ "p1", "p2", "p3", "shootout", "sprint", "quali", "main" }) do
                    totalPoints = totalPoints + (cd[sKey] or 0)
                end
                table.insert(lines, string.format("Total Circuit Points: %g", totalPoints))
                table.insert(lines, "")

                local sessions = {
                    { name = "Practice 1",      key = "p1" },
                    { name = "Practice 2",      key = "p2" },
                    { name = "Practice 3",      key = "p3" },
                    { name = "Sprint Shootout", key = "shootout" },
                    { name = "Sprint Race",     key = "sprint" },
                    { name = "Qualifying",      key = "quali" },
                    { name = "Main Race",       key = "main" }
                }

                for _, s in ipairs(sessions) do
                    local sDetails = cd.details and cd.details[s.key]
                    if sDetails then
                        table.insert(lines,
                            string.format("  === SESSION: %s (Earned: %g pts) ===", string.upper(s.name), cd[s.key] or 0))

                        -- 1. Display Drivers
                        if sDetails.drivers and next(sDetails.drivers) then
                            table.insert(lines, "    [DRIVERS]")
                            for dn, logs in pairs(sDetails.drivers) do
                                local isCap = (r.captain == dn)
                                local capLabel = isCap and " [CAPTAIN - 2x]" or ""
                                local drTotal = 0
                                for _, e in ipairs(logs) do drTotal = drTotal + e.final end
                                table.insert(lines, string.format("    * %s (Total: %g pts)%s", dn, drTotal, capLabel))
                                for _, e in ipairs(logs) do
                                    if isCap then
                                        table.insert(lines,
                                            string.format("      - %s: %+g (Base: %+g)", e.label, e.final, e.base))
                                    else
                                        table.insert(lines, string.format("      - %s: %+g", e.label, e.final))
                                    end
                                end
                            end
                        end

                        -- 2. Display Constructor
                        if sDetails.constructor and next(sDetails.constructor) then
                            local constTotal = 0
                            for dn, logs in pairs(sDetails.constructor) do
                                for _, e in ipairs(logs) do constTotal = constTotal + e.final end
                            end
                            table.insert(lines,
                                string.format("    [CONSTRUCTOR: %s] (Total: %g pts)", r.constructor, constTotal))
                            for dn, logs in pairs(sDetails.constructor) do
                                local constDrTotal = 0
                                for _, e in ipairs(logs) do constDrTotal = constDrTotal + e.final end
                                table.insert(lines, string.format("    * %s (Total: %g pts)", dn, constDrTotal))
                                for _, e in ipairs(logs) do
                                    table.insert(lines, string.format("      - %s: %+g", e.label, e.final))
                                end
                                if #logs == 0 then
                                    table.insert(lines, "      - No points scored: +0")
                                end
                            end
                        end
                        
                        -- 3. Display Predictions
                        if sDetails.predictions and next(sDetails.predictions) then
                            table.insert(lines, "    [PREDICTIONS]")
                            for _, e in ipairs(sDetails.predictions) do
                                table.insert(lines, string.format("      - %s: %+g", e.label, e.final))
                            end
                        end
                        table.insert(lines, "")
                    end
                end
            end
        end
    end
    love.filesystem.write(EXPORT_FILE, table.concat(lines, "\n"))
end

local function showMsg(msg)
    feedbackMsg = msg
    feedbackTimer = 3
end

local function formatDriver(str)
    if not str or str == "" then return "" end
    return string.upper(str:match("^%s*(.-)%s*$"))
end

-- ==========================================
-- LÖVE CORE
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
        drawButton("1. Add/Edit Single Team", 300, 150, 200, 50, mx, my)
        drawButton("2. Bulk Import Teams", 300, 220, 200, 50, mx, my)
        drawButton("3. Load Results & Points", 300, 290, 200, 50, mx, my)
        drawButton("4. View Standings", 300, 360, 200, 50, mx, my)
        drawButton("5. Reset All Points", 300, 430, 200, 50, mx, my)
    elseif state == "team_single" then
        love.graphics.print("--- ADD / EDIT SINGLE TEAM ---", 300, 40)
        for _, box in ipairs(teamLayout) do drawInput(box.label, box.key, box.x, box.y, box.w, box.h, mx, my) end
        drawButton("Save Team", 300, 600, 100, 40, mx, my)
        drawButton("Cancel", 410, 600, 100, 40, mx, my)
    elseif state == "team_bulk" then
        love.graphics.print("--- BULK IMPORT TEAMS ---", 280, 50)
        love.graphics.print("Paste your teams separated by commas (1 Team per line).", 100, 100)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("Format: Name, D1, D2, D3, D4, Captain, Const, Pole, 1st, 2nd, 3rd, Last, FastestLap", 100,
            130)

        love.graphics.setColor(activeInput == "bulk_teams" and colors.inputActive or colors.inputBg)
        love.graphics.rectangle("fill", 100, 170, 600, 80, 3, 3)
        love.graphics.setColor(colors.text)
        local displayText = "Click here and press Ctrl+V to paste your list..."
        if inputs.bulk_teams ~= "" then displayText = "Loaded " .. #inputs.bulk_teams .. " characters. Ready to import!" end
        love.graphics.print(displayText, 120, 200)

        drawButton("Import Teams", 280, 300, 120, 40, mx, my)
        drawButton("Cancel", 420, 300, 100, 40, mx, my)
    elseif state == "results" then
        love.graphics.print("--- LOAD WEEKEND RESULTS ---", 280, 50)
        for _, box in ipairs(resultsLayout) do drawInput(box.label, box.key, box.x, box.y, box.w, box.h, mx, my) end
        drawButton("Process Points", 300, 480, 120, 40, mx, my)
        drawButton("Clear Fields", 440, 480, 100, 40, mx, my)
        drawButton("Cancel", 560, 480, 90, 40, mx, my)
    elseif state == "standings" then
        love.graphics.print("--- CHAMPIONSHIP STANDINGS (Leaderboard) ---", 20, 80)
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
-- SMART BULK PARSERS
-- ==========================================
local function parseBulkTeams(text)
    local lines = {}
    for line in text:gmatch("[^\r\n]+") do table.insert(lines, line) end

    local addedCount = 0
    for _, line in ipairs(lines) do
        line = line:gsub(":", ","):gsub("%-", ",")
        local parts = {}
        for part in string.gmatch(line, "([^,]+)") do
            table.insert(parts, part:match("^%s*(.-)%s*$"))
        end

        if #parts >= 13 then
            local fn = parts[1]
            fantasyData.teams[fn] = {
                d1 = formatDriver(parts[2]),
                d2 = formatDriver(parts[3]),
                d3 = formatDriver(parts[4]),
                d4 = formatDriver(parts[5]),
                captain = formatDriver(parts[6]),
                constructor = parts[7],
                preds = {
                    pole = formatDriver(parts[8]),
                    first = formatDriver(parts[9]),
                    second = formatDriver(parts[10]),
                    third = formatDriver(parts[11]),
                    last = formatDriver(parts[12]),
                    fastest = formatDriver(parts[13])
                },
                points = fantasyData.teams[fn] and fantasyData.teams[fn].points or 0,
                circuitData = fantasyData.teams[fn] and fantasyData.teams[fn].circuitData or {}
            }
            addedCount = addedCount + 1
        end
    end
    return addedCount
end

local function populateFromBulk(text)
    local s = text:gsub("\r", " ")
    local sLower = " " .. s:lower() .. " end:"
    local prefixes = {
        { k = "p1",       pat = "p1%s*:" }, { k = "p2", pat = "p2%s*:" }, { k = "p3", pat = "p3%s*:" },
        { k = "shootout", pat = "shootout%s*:" }, { k = "sprint", pat = "sprint%s*:" },
        { k = "quali", pat = "quali%s*:" }, { k = "main", pat = "main%s*:" }, { k = "main", pat = "race%s*:" }
    }

    for _, prefix in ipairs(prefixes) do
        local startIdx, endIdx = sLower:find(prefix.pat)
        if startIdx then
            local nextIdx = #sLower
            for _, p2 in ipairs(prefixes) do
                local s2 = sLower:find(p2.pat, endIdx)
                if s2 and s2 < nextIdx then nextIdx = s2 end
            end
            local endToken = sLower:find("end:", endIdx)
            if endToken and endToken < nextIdx then nextIdx = endToken end

            local content = s:sub(endIdx + 1, nextIdx - 1)
            inputs[prefix.k] = string.upper(content:match("^%s*(.-)%s*$"))
        end
    end
end

-- ==========================================
-- SESSION PROCESSOR (With Breakdown Logger)
-- ==========================================
local function processSingleSession(session, sKey, sStr, circ, dnfMap, flDr, leaderDr)
    local standings = {}
    for item in string.gmatch(sStr, "([^,]+)") do
        local d, manualPos = item:match("^%s*(.-)%s*%(([-+]?%d+)%)%s*$")
        if not d then
            d = item:match("^%s*(.-)%s*$")
            manualPos = nil
        end
        d = formatDriver(d)
        if d ~= "" then table.insert(standings, { name = d, manualPos = manualPos }) end
    end

    local currentSessionDrivers = {}
    for pos, obj in ipairs(standings) do
        table.insert(currentSessionDrivers, obj.name)
        if obj.manualPos then
            obj.posGained = tonumber(obj.manualPos)
        else
            local pGained = 0
            if session == "Main" or session == "Sprint" then
                local refSession = (session == "Main") and "Quali" or "Shootout"
                local grid = fantasyData.results[circ][refSession]
                if grid then
                    for gPos, gName in ipairs(grid) do
                        if gName == obj.name then
                            pGained = gPos - pos
                            break
                        end
                    end
                end
            end
            obj.posGained = pGained
        end
    end
    fantasyData.results[circ][session] = currentSessionDrivers

    local driverPoints, constPoints, seenConstructor, teammatePoints = {}, {}, {}, {}
    local driverLogs, constLogs = {}, {}

    for dn, cn in pairs(driverToConstructor) do
        constLogs[cn] = constLogs[cn] or {}
        constLogs[cn][dn] = constLogs[cn][dn] or {}
    end
    
    local function addLog(dn, label, basePts)
        driverLogs[dn] = driverLogs[dn] or {}
        table.insert(driverLogs[dn], { label = label, base = basePts })
    end

    local function addConstLog(c, dn, label, basePts)
        constLogs[c] = constLogs[c] or {}
        constLogs[c][dn] = constLogs[c][dn] or {}
        table.insert(constLogs[c][dn], { label = label, base = basePts })
    end

    local function hasDriverFailedInSession(dn, s, dm)
        if not dm[dn] then return false end
        local dtype = dm[dn]
        if dtype:find("QUALI") and s ~= "Quali" then return false end
        if dtype:find("MAIN") and s ~= "Main" then return false end
        if dtype:find("SPRINT") and s ~= "Sprint" then return false end
        if dtype:find("SHOOTOUT") and s ~= "Shootout" then return false end
        return true
    end

    local positions = {}
    for pos, obj in ipairs(standings) do
        positions[obj.name] = pos
    end

    -- H2H TEAMMATE BATTLES (Both must finish. No points if teammate DNF'd, DNS'd, or DSQ'd)
    if session == "Main" then
        for _, obj in ipairs(standings) do
            local dn = obj.name
            local c = driverToConstructor[dn]
            if c then
                local teammate = nil
                for d, constr in pairs(driverToConstructor) do
                    if constr == c and d ~= dn then
                        teammate = d
                        break
                    end
                end

                if teammate then
                    local dnFailed = hasDriverFailedInSession(dn, "Main", dnfMap)
                    local teammateFailed = hasDriverFailedInSession(teammate, "Main", dnfMap)

                    if not dnFailed and not teammateFailed then -- BOTH MUST FINISH
                        local posA = positions[dn]
                        local posB = positions[teammate]
                        if posA and posB then
                            if posA < posB then
                                teammatePoints[dn] = 2
                                addLog(dn, "Ahead of teammate", 2)
                            elseif posA > posB then
                                teammatePoints[dn] = -1
                                addLog(dn, "Behind teammate", -1)
                            else
                                teammatePoints[dn] = 0
                            end
                        else
                            teammatePoints[dn] = 0
                        end
                    else
                        teammatePoints[dn] = 0
                        if not dnFailed and teammateFailed then
                            addLog(dn, "Teammate DNF/DNS - No H2H points", 0)
                        end
                    end
                else
                    teammatePoints[dn] = 0
                end
            end
        end
    end

    local leaderPosInSession = nil
    if (session == "Main" or session == "Sprint") and leaderDr ~= "" then
        for pos, obj in ipairs(standings) do
            if obj.name == leaderDr then
                leaderPosInSession = pos; break
            end
        end
    end
    local leaderIsDNF = (dnfMap[leaderDr] ~= nil)
    local lastDriver = #standings > 0 and standings[#standings].name or nil

    for pos, obj in ipairs(standings) do
        local isDNS = false
        if dnfMap[obj.name] then
            local status = dnfMap[obj.name]
            if status:find("DNS") then
                local applyDNS = true
                if status:find("QUALI") and session ~= "Quali" then applyDNS = false end
                if status:find("MAIN") and session ~= "Main" then applyDNS = false end
                if status:find("SPRINT") and session ~= "Sprint" then applyDNS = false end
                if status:find("SHOOTOUT") and session ~= "Shootout" then applyDNS = false end
                if applyDNS then isDNS = true end
            end
        end

        if isDNS then
            -- Driver DNS'd! Force 0 points to override any position points
            driverPoints[obj.name] = 0
            constPoints[obj.name] = 0
        else
            -- Normal processing
            local pts = (pointsMap[session] and pointsMap[session][pos]) or 0
            if pts > 0 then
                addLog(obj.name, string.format("%s place", getOrdinal(pos)), pts)
                local c = driverToConstructor[obj.name]
                if c then addConstLog(c, obj.name, string.format("%s place", getOrdinal(pos)), pts) end
            end

            if session == "Main" or session == "Sprint" then
                local gainPts = obj.posGained * 0.5
                if gainPts ~= 0 then
                    -- Check if this driver DNF'd in this specific session
                    local isDNF = false
                    if dnfMap[obj.name] then
                        local status = dnfMap[obj.name]
                        local applyDNF = true
                        if status:find("QUALI") and session ~= "Quali" then applyDNF = false end
                        if status:find("MAIN") and session ~= "Main" then applyDNF = false end
                        if status:find("SPRINT") and session ~= "Sprint" then applyDNF = false end
                        if status:find("SHOOTOUT") and session ~= "Shootout" then applyDNF = false end
                        if applyDNF and not status:find("DNS") then isDNF = true end
                    end

                    -- Bypasses the penalty if the driver DNF'd and lost positions, AND prevents gaining points if DNF'd
                    if not (isDNF and gainPts < 0) and not (isDNF and gainPts > 0) then
                        local label = gainPts > 0 and "Position gained" or "Position lost"
                        addLog(obj.name, label, gainPts)
                        local c = driverToConstructor[obj.name]
                        if c then addConstLog(c, obj.name, label, gainPts) end
                        pts = pts + gainPts
                    end
                end
            end

            if (session == "Main" or session == "Sprint") and leaderDr ~= "" and leaderDr ~= obj.name then
                local isAhead = false
                if leaderPosInSession and pos < leaderPosInSession then
                    isAhead = true
                elseif leaderIsDNF then
                    isAhead = true
                end
                if isAhead and not dnfMap[obj.name] then
                    local aolPts = (session == "Main") and 1 or 0.5
                    addLog(obj.name, "Ahead of leader", aolPts)
                    local c = driverToConstructor[obj.name]
                    if c then addConstLog(c, obj.name, "Ahead of leader", aolPts) end
                    pts = pts + aolPts
                end
            end

            if session == "Quali" then
                if pos <= 10 then
                    pts = pts + 2
                    addLog(obj.name, "Qualified to Q2", 1)
                    addLog(obj.name, "Qualified to Q3", 1)
                    local c = driverToConstructor[obj.name]
                    if c then
                        addConstLog(c, obj.name, "Qualified to Q2", 1)
                        addConstLog(c, obj.name, "Qualified to Q3", 1)
                    end
                elseif pos <= 16 then
                    pts = pts + 1
                    addLog(obj.name, "Qualified to Q2", 1)
                    local c = driverToConstructor[obj.name]
                    if c then addConstLog(c, obj.name, "Qualified to Q2", 1) end
                end
            end

            if obj.name == lastDriver and not hasDriverFailedInSession(obj.name, session, dnfMap) and (session == "Main" or session == "Quali" or session == "Sprint") then
                pts = pts - 1
                addLog(obj.name, "Last position", -1)
                local c = driverToConstructor[obj.name]
                if c then addConstLog(c, obj.name, "Last position", -1) end
            end

            constPoints[obj.name] = (constPoints[obj.name] or 0) + pts
            local tmPts = teammatePoints[obj.name] or 0
            driverPoints[obj.name] = (driverPoints[obj.name] or 0) + pts + tmPts
        end
    end

    -- Process DNFs & DNSs (Applies standard DNF/DNS/DSQ retirement/non-start penalties)
    for dn, dtype in pairs(dnfMap) do
        local applyDNF = true
        if dtype:find("QUALI") and session ~= "Quali" then applyDNF = false end
        if dtype:find("MAIN") and session ~= "Main" then applyDNF = false end
        if dtype:find("SPRINT") and session ~= "Sprint" then applyDNF = false end
        if dtype:find("SHOOTOUT") and session ~= "Shootout" then applyDNF = false end

        if applyDNF then
            local pts = 0
            local label = "Retirement (DNF)"
            if dtype:find("DSQ") then
                label = "Disqualification (DSQ)"
                if session == "Main" then
                    pts = -25
                elseif session == "Sprint" then
                    pts = -15
                elseif session == "Quali" or session == "Shootout" then
                    pts = -10
                end
            elseif dtype:find("DNS") then
                label = "Did Not Start (DNS)"
                if session == "Main" then
                    pts = -15
                elseif session == "Sprint" or session == "Quali" then
                    pts = -5
                end
            else
                if session == "Main" then
                    pts = -15
                elseif session == "Sprint" or session == "Quali" then
                    pts = -5
                end
            end
            constPoints[dn] = (constPoints[dn] or 0) + pts
            driverPoints[dn] = (driverPoints[dn] or 0) + pts

            addLog(dn, label, pts)
            local c = driverToConstructor[dn]
            if c then addConstLog(c, dn, label, pts) end
        end
    end

    if flDr ~= "" then
        local flPts = (session == "Main") and 3 or (session == "Sprint") and 1 or 0
        driverPoints[flDr] = (driverPoints[flDr] or 0) + flPts
        addLog(flDr, "Fastest lap", flPts)

        constPoints[flDr] = (constPoints[flDr] or 0) + flPts
        local c = driverToConstructor[flDr]
        if c then addConstLog(c, flDr, "Fastest lap", flPts) end
    end

    -- Distribute Points to User Teams
    for _, team in pairs(fantasyData.teams) do
        if not team.circuitData[circ] then team.circuitData[circ] = { p1 = 0, p2 = 0, p3 = 0, shootout = 0, sprint = 0, quali = 0, main = 0, isSprint = false } end
        if sKey == "sprint" or sKey == "shootout" then team.circuitData[circ].isSprint = true end

        -- Create a Snapshot if one doesn't exist
        if not team.circuitData[circ].roster then
            team.circuitData[circ].roster = {
                d1 = team.d1,
                d2 = team.d2,
                d3 = team.d3,
                d4 = team.d4,
                captain = team.captain,
                constructor = team.constructor,
                preds = { pole = team.preds.pole, first = team.preds.first, second = team.preds.second, third = team.preds.third, last = team.preds.last, fastest = team.preds.fastest }
            }
        end

        local r = team.circuitData[circ].roster

        -- Build details breakdown map
        team.circuitData[circ].details = team.circuitData[circ].details or {}
        local details = { drivers = {}, constructor = {}, predictions = {} }

        -- 1. Grab Driver Logs
        for _, dn in ipairs({ r.d1, r.d2, r.d3, r.d4 }) do
            if dn ~= "" and driverLogs[dn] then
                details.drivers[dn] = {}
                for _, entry in ipairs(driverLogs[dn]) do
                    local finalPts = entry.base
                    if r.captain == dn then finalPts = finalPts * 2 end
                    table.insert(details.drivers[dn], { label = entry.label, base = entry.base, final = finalPts })
                end
            end
        end

        -- 2. Grab Constructor Logs (Ensured for all sessions + Case Insensitive Fix)
        if r.constructor ~= "" then
            local cName = r.constructor
            details.constructor = {}

            -- Find the actual capitalized key in constLogs
            local actualKey = nil
            for k, _ in pairs(constLogs) do
                if string.lower(k) == string.lower(cName) then
                    actualKey = k
                    break
                end
            end

            for dn, cn in pairs(driverToConstructor) do
                if string.lower(cn) == string.lower(cName) then
                    details.constructor[dn] = {}
                    local logs = actualKey and constLogs[actualKey] and constLogs[actualKey][dn]
                    if logs then
                        for _, entry in ipairs(logs) do
                            table.insert(details.constructor[dn],
                                { label = entry.label, base = entry.base, final = entry.base })
                        end
                    end
                end
            end
        end
        
        -- 3. Grab Predictions Logs
        if session == "Main" then
            if standings[1] and r.preds.first == standings[1].name then table.insert(details.predictions,
                    { label = "Winner prediction", final = 5 }) end
            if standings[2] and r.preds.second == standings[2].name then table.insert(details.predictions,
                    { label = "2nd place prediction", final = 5 }) end
            if standings[3] and r.preds.third == standings[3].name then table.insert(details.predictions,
                    { label = "3rd place prediction", final = 5 }) end
            if standings[#standings] and r.preds.last == standings[#standings].name then table.insert(
                details.predictions, { label = "Last place prediction", final = 2 }) end
            if flDr == r.preds.fastest then table.insert(details.predictions,
                    { label = "Fastest lap prediction", final = 3 }) end
        elseif session == "Quali" then
            if standings[1] and r.preds.pole == standings[1].name then table.insert(details.predictions,
                    { label = "Pole prediction", final = 3 }) end
        end

        team.circuitData[circ].details[sKey] = details

        -- Calculate final points
        local earned = 0
        local function addDr(dn)
            if not dn or dn == "" then return end
            local pts = driverPoints[dn] or 0
            if r.captain == dn then pts = pts * 2 end
            earned = earned + pts
        end

        addDr(r.d1); addDr(r.d2); addDr(r.d3); addDr(r.d4)

        if r.constructor ~= "" then
            for dn, cn in pairs(driverToConstructor) do
                if string.lower(cn) == string.lower(r.constructor) then
                    earned = earned + (constPoints[dn] or 0)
                end
            end
        end

        -- Accumulate prediction points to the session
        for _, e in ipairs(details.predictions) do earned = earned + e.final end

        local previousEarned = team.circuitData[circ][sKey] or 0
        team.points = team.points - previousEarned + earned
        team.circuitData[circ][sKey] = earned
    end
end

local function processResults()
    if inputs.circuitName == "" then return false, "Please enter a Circuit Name!" end
    local circ = inputs.circuitName
    fantasyData.results[circ] = fantasyData.results[circ] or {}

    local dnfMap = {}
    for item in string.gmatch(inputs.dnfs, "([^,]+)") do
        local d, dtype = item:match("^%s*(.-)%s*%((.-)%)%s*$")
        if not d then d = item end
        local cl = formatDriver(d)
        if cl ~= "" then dnfMap[cl] = dtype and dtype:upper() or "DNF" end
    end

    local flDr = formatDriver(inputs.fastestLap)
    local leaderDr = formatDriver(inputs.leader)

    local sessionsToProcess = {
        { sName = "Practice", key = "p1",       input = inputs.p1 },
        { sName = "Practice", key = "p2",       input = inputs.p2 },
        { sName = "Practice", key = "p3",       input = inputs.p3 },
        { sName = "Shootout", key = "shootout", input = inputs.shootout },
        { sName = "Quali",    key = "quali",    input = inputs.quali },
        { sName = "Sprint",   key = "sprint",   input = inputs.sprint },
        { sName = "Main",     key = "main",     input = inputs.main }
    }

    local anyProcessed = false
    for _, sData in ipairs(sessionsToProcess) do
        if sData.input ~= "" then
            anyProcessed = true
            processSingleSession(sData.sName, sData.key, sData.input, circ, dnfMap, flDr, leaderDr)
        end
    end

    if not anyProcessed then return false, "No session strings provided!" end
    saveDatabase()
    return true, "Points calculated!"
end

-- ==========================================
-- INPUTS
-- ==========================================
function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    activeInput = nil

    if state == "menu" then
        if x > 300 and x < 500 and y > 150 and y < 200 then
            state = "team_single"; for k in pairs(inputs) do inputs[k] = "" end
        end
        if x > 300 and x < 500 and y > 220 and y < 270 then
            state = "team_bulk"; inputs.bulk_teams = ""
        end
        if x > 300 and x < 500 and y > 290 and y < 340 then
            state = "results"
            for _, box in ipairs(resultsLayout) do inputs[box.key] = "" end
        end
        if x > 300 and x < 500 and y > 360 and y < 410 then state = "standings" end
        if x > 300 and x < 500 and y > 430 and y < 480 then
            for _, team in pairs(fantasyData.teams) do
                team.points = 0
                team.circuitData = {}
            end
            fantasyData.results = {}
            saveDatabase()
            showMsg("All Points Reset to 0!")
        end
    elseif state == "team_single" then
        for _, box in ipairs(teamLayout) do if x > box.x and x < box.x + box.w and y > box.y and y < box.y + box.h then activeInput =
                box.key end end
        if x > 300 and x < 400 and y > 600 and y < 640 then
            local fn = inputs.friend
            if fn == "" then
                showMsg("Need a Friend's Name!"); return
            end
            if not fantasyData.teams[fn] then
                fantasyData.teams[fn] = {
                    d1 = "",
                    d2 = "",
                    d3 = "",
                    d4 = "",
                    captain = "",
                    constructor = "",
                    preds = { pole = "", first = "", second = "", third = "", last = "", fastest = "" },
                    points = 0,
                    circuitData = {}
                }
            end
            local t = fantasyData.teams[fn]
            if inputs.d1 ~= "" then t.d1 = formatDriver(inputs.d1) end
            if inputs.d2 ~= "" then t.d2 = formatDriver(inputs.d2) end
            if inputs.d3 ~= "" then t.d3 = formatDriver(inputs.d3) end
            if inputs.d4 ~= "" then t.d4 = formatDriver(inputs.d4) end
            if inputs.captain ~= "" then t.captain = formatDriver(inputs.captain) end
            if inputs.constructor ~= "" then t.constructor = inputs.constructor:match("^%s*(.-)%s*$") end
            if inputs.p_pole ~= "" then t.preds.pole = formatDriver(inputs.p_pole) end
            if inputs.p_1st ~= "" then t.preds.first = formatDriver(inputs.p_1st) end
            if inputs.p_2nd ~= "" then t.preds.second = formatDriver(inputs.p_2nd) end
            if inputs.p_3rd ~= "" then t.preds.third = formatDriver(inputs.p_3rd) end
            if inputs.p_last ~= "" then t.preds.last = formatDriver(inputs.p_last) end
            if inputs.p_fastest ~= "" then t.preds.fastest = formatDriver(inputs.p_fastest) end

            showMsg("Team Saved!"); saveDatabase(); state = "menu"
        end
        if x > 410 and x < 510 and y > 600 and y < 640 then state = "menu" end
    elseif state == "team_bulk" then
        if x > 100 and x < 700 and y > 170 and y < 250 then activeInput = "bulk_teams" end
        if x > 280 and x < 400 and y > 300 and y < 340 then
            local added = parseBulkTeams(inputs.bulk_teams)
            if added > 0 then
                showMsg(added .. " Teams Imported Successfully!")
                saveDatabase(); state = "menu"
            else
                showMsg("Error: Invalid format or no teams found.")
            end
        end
        if x > 420 and x < 520 and y > 300 and y < 340 then state = "menu" end
    elseif state == "results" then
        for _, box in ipairs(resultsLayout) do
            if x > box.x and x < box.x + box.w and y > box.y and y < box.y + box.h then activeInput = box.key end
        end
        if x > 300 and x < 420 and y > 480 and y < 520 then
            local s, msg = processResults(); showMsg(msg); if s then state = "menu" end
        end
        if x > 440 and x < 540 and y > 480 and y < 520 then
            for _, box in ipairs(resultsLayout) do inputs[box.key] = "" end
        end
        if x > 560 and x < 650 and y > 480 and y < 520 then state = "menu" end
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
        if activeInput then
            local clipboard = love.system.getClipboardText()
            if activeInput == "bulk_input" then
                populateFromBulk(clipboard)
                inputs.bulk_input = "Parsed successfully! Review the fields above."
            elseif activeInput == "bulk_teams" then
                inputs.bulk_teams = clipboard
            else
                clipboard = clipboard:gsub("\n", ""):gsub("\r", "")
                inputs[activeInput] = inputs[activeInput] .. clipboard
            end
        end
    elseif key == "return" then
        activeInput = nil
    elseif key == "1" then
        love.system.openURL("file://" .. love.filesystem.getSaveDirectory())
    elseif key == "escape" then
        love.event.quit()
    end
end