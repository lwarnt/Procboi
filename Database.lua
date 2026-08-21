local addonName, Procboi = ...

Procboi.Database = {}

local Database = Procboi.Database

local DB_VERSION = 2

--[[
|-- version
+-- items
    +-- craftedItemId
        |-- name
        |-- ahPrice
        |-- craftCost
        │   +-- ingredientItemId
        │       |-- name
        │       |-- ahPrice
        │       +-- count
        +-- sessions
            +-- date
                |-- crafts
                |-- totalProduced
                |-- totalBonus
                +-- results
                    |-- [1]
                    |-- [2]
                    |-- [3]
                    |-- [4]
                    +-- [5]
--]]

--[[
ProcboiDB = {
    version = 2,
    items = {
        [12345] = {
            name = "Example Crafted Item",
            ahPrice = 125000,
            craftCost = {
                [11111] = {
                    id = 11111,
                    name = "Example Reagent",
                    ahPrice = 2500,
                    count = 10,
                },

                [22222] = {
                    id = 22222,
                    name = "Another Reagent",
                    ahPrice = 5000,
                    count = 4,
                },
            },
            sessions = {
                ["2026-08-21"] = {
                    crafts = 10,
                    totalProduced = 14,
                    totalBonus = 4,
                    results = {
                        [1] = 6,
                        [2] = 2,
                        [3] = 1,
                        [4] = 1,
                        [5] = 0,
                    },
                },
            },
        },
    },
}
--]]
local function CreateEmptySession()
    return {
        crafts = 0,
        totalProduced = 0,
        totalBonus = 0,

        results = {
            [1] = 0,
            [2] = 0,
            [3] = 0,
            [4] = 0,
            [5] = 0,
        },
    }
end

local function CreateEmptyItem(itemName)
    return {
        name = itemName,
        ahPrice = 0,
        craftCost = {},
        sessions = {},
    }
end

local function CreateEmptyDatabase()
    return {
        version = DB_VERSION,
        items = {},
    }
end

function Database:Initialize()
    if not ProcboiDB then
        ProcboiDB = CreateEmptyDatabase()
    end

    if not ProcboiDB.version then
        ProcboiDB.version = DB_VERSION
    end

    if not ProcboiDB.items then
        ProcboiDB.items = {}
    end

    self.db = ProcboiDB
end

function Database:Export()
    local output = {
        "ProcboiDB:" .. DB_VERSION,
    }

    for itemID, item in pairs(self.db.items) do
        for date, session in pairs(item.sessions) do
            local results = session.results

            local line = string.format(
                "%s|%s|%d|%d|%d|%d,%d,%d,%d,%d",
                tostring(itemID),
                date,
                session.crafts,
                session.totalProduced,
                session.totalBonus,
                results[1] or 0,
                results[2] or 0,
                results[3] or 0,
                results[4] or 0,
                results[5] or 0
            )

            table.insert(output, line)
        end
    end

    return table.concat(output, "\n")
end

function Database:Import(text)
    if not text or text == "" then
        return false, "Empty import data."
    end

    local lines = {}

    for line in string.gmatch(text, "[^\n]+") do
        line = strtrim(line)

        if line ~= "" then
            table.insert(lines, line)
        end
    end

    local version = string.match(lines[1] or "", "^ProcboiDB:(%d+)$")

    if not version then
        return false, "Invalid Procboi database."
    end

    version = tonumber(version)

    if version ~= DB_VERSION then
        return false, "Unsupported database version: " .. version
    end

    local database = CreateEmptyDatabase()

    for i = 2, #lines do
        local fields = {}

        for field in string.gmatch(lines[i], "[^|]+") do
            table.insert(fields, field)
        end

        if #fields ~= 6 then
            return false, "Invalid data on line " .. i
        end

        local itemID = tonumber(fields[1])
        local dateValue = fields[2]

        local crafts = tonumber(fields[3])
        local totalProduced = tonumber(fields[4])
        local totalBonus = tonumber(fields[5])

        local r1, r2, r3, r4, r5 = string.match(
            fields[6],
            "^(%d+),(%d+),(%d+),(%d+),(%d+)$"
        )

        if not itemID then
            return false, "Invalid item ID on line " .. i
        end

        if not crafts
            or not totalProduced
            or not totalBonus
            or not r1
            or crafts < 1
            or totalProduced < crafts
            or totalBonus ~= totalProduced - crafts
            or (
                tonumber(r1)
                + tonumber(r2)
                + tonumber(r3)
                + tonumber(r4)
                + tonumber(r5)
            ) ~= crafts
        then
            return false, "Invalid session data on line " .. i
        end

        if not database.items[itemID] then
            database.items[itemID] = CreateEmptyItem(
                C_Item.GetItemInfo(itemID)
            )
        end

        database.items[itemID].sessions[dateValue] = {
            crafts = crafts,
            totalProduced = totalProduced,
            totalBonus = totalBonus,

            results = {
                [1] = tonumber(r1),
                [2] = tonumber(r2),
                [3] = tonumber(r3),
                [4] = tonumber(r4),
                [5] = tonumber(r5),
            },
        }
    end

    ProcboiDB = database
    self.db = ProcboiDB

    return true
end

function Database:GetItems()
    return self.db.items
end

function Database:HasItem(itemID)
    return self.db.items[itemID] ~= nil
end

function Database:AddItem(itemID, itemName)
    if not itemID then
        return false
    end

    if self:HasItem(itemID) then
        return false
    end

    self.db.items[itemID] = CreateEmptyItem(itemName)

    return true
end

function Database:DeleteItem(itemID)
    if not self:HasItem(itemID) then
        return false
    end

    self.db.items[itemID] = nil

    return true
end

function Database:GetItem(itemID)
    return self.db.items[itemID]
end

function Database:HasSession(itemID, date)
    local item = self:GetItem(itemID)

    if not item then
        return false
    end

    return item.sessions[date] ~= nil
end

function Database:GetSession(itemID, date)
    local item = self:GetItem(itemID)

    if not item then
        return nil
    end

    return item.sessions[date]
end

function Database:GetOrCreateSession(itemID, date)
    local item = self:GetItem(itemID)

    if not item then
        return nil
    end

    if not item.sessions[date] then
        item.sessions[date] = CreateEmptySession()
    end

    return item.sessions[date]
end

function Database:RecordCraft(itemID, date, quantity)
    if not self:HasItem(itemID) then
        return false
    end

    quantity = tonumber(quantity)

    if not quantity or quantity < 1 then
        return false
    end

    quantity = math.floor(quantity)

    if quantity > 5 then
        return false
    end

    local session = self:GetOrCreateSession(itemID, date)

    if not session then
        return false
    end

    session.crafts = session.crafts + 1
    session.totalProduced = session.totalProduced + quantity
    session.totalBonus = session.totalProduced - session.crafts

    session.results[quantity] = (session.results[quantity] or 0) + 1

    return true
end

function Database:DeleteSession(itemID, date)
    local item = self:GetItem(itemID)

    if not item or not item.sessions[date] then
        return false
    end

    item.sessions[date] = nil

    return true
end

function Database:GetSessionDates(itemID)
    local item = self:GetItem(itemID)

    if not item then
        return {}
    end

    local dates = {}

    for date in pairs(item.sessions) do
        table.insert(dates, date)
    end

    table.sort(dates, function(a, b)
        return a > b
    end)

    return dates
end

function Database:GetItemSummary(itemID)
    local item = self:GetItem(itemID)

    if not item then
        return nil
    end

    local summary = CreateEmptySession()

    for _, session in pairs(item.sessions) do
        summary.crafts = summary.crafts + session.crafts
        summary.totalProduced = summary.totalProduced + session.totalProduced

        for quantity = 1, 5 do
            summary.results[quantity] = summary.results[quantity] + (session.results[quantity] or 0)
        end
    end

    summary.totalBonus =
        summary.totalProduced - summary.crafts

    return summary
end

function Database:GetStatistics(data)
    if not data or data.crafts == 0 then
        return {
            crafts = 0,
            totalProduced = 0,
            totalBonus = 0,
            procs = 0,
            procRate = 0,
            averageYield = 0,

            percentages = {
                [1] = 0,
                [2] = 0,
                [3] = 0,
                [4] = 0,
                [5] = 0,
            },
        }
    end

    local procs =
        data.crafts - (data.results[1] or 0)

    local statistics = {
        crafts = data.crafts,
        totalProduced = data.totalProduced,
        totalBonus = data.totalBonus,

        procs = procs,
        procRate = (procs / data.crafts) * 100,
        averageYield = data.totalProduced / data.crafts,

        percentages = {},
    }

    for quantity = 1, 5 do
        statistics.percentages[quantity] = ((data.results[quantity] or 0) / data.crafts) * 100
    end

    return statistics
end

function Database:SetItemPrice(itemID, ahPrice)
    local item = self:GetItem(itemID)

    if not item then
        return false
    end

    item.ahPrice = ahPrice

    return true
end

function Database:GetItemPrice(itemID)
    local item = self:GetItem(itemID)

    if not item then
        return nil
    end

    return item.ahPrice
end

function Database:SetCraftCost(itemID, craftCost)
    -- Placeholder.
    -- Expected craftCost:
    --
    -- {
    --     [ingredientItemID] = {
    --         name = "...",
    --         ahPrice = 0,
    --         count = 10,
    --     }
    -- }
    --
    return false
end

function Database:GetCraftCost(itemID)
    -- Placeholder.
    return nil
end
