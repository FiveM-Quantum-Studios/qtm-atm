local transactionCache = {}

local function cacheTransaction(identifier, transactionType, amount)
    if not transactionCache[identifier] then
        transactionCache[identifier] = {}
    end

    table.insert(transactionCache[identifier], {
        identifier = identifier,
        transactionType = transactionType,
        amount = amount,
        date = os.date("%Y-%m-%d %H:%M:%S")
    })
end

local function flushUserTransactionsToDatabase(identifier)
    if transactionCache[identifier] and #transactionCache[identifier] > 0 then
        local insertQuery = [[
            INSERT INTO qtm_transactions (identifier, transaction_date, transaction_type, amount)
            VALUES (?, ?, ?, ?)
        ]]

        for _, transaction in ipairs(transactionCache[identifier]) do
            MySQL.query.await(insertQuery, {
                transaction.identifier,
                transaction.date,
                transaction.transactionType,
                transaction.amount
            })
        end

        transactionCache[identifier] = nil
    end
end

lib.callback.register('qtm:server:awaitHistory', function(source)
    local src = source
    local identifier = qtm.Framework.GetIdentifier(src)

    flushUserTransactionsToDatabase(identifier)
    Wait(100) -- Delay just in case 
    local query = [[
        SELECT transaction_date, transaction_type, amount
        FROM qtm_transactions
        WHERE identifier = ?
        ORDER BY transaction_date DESC
    ]]

    local result = MySQL.query.await(query, { identifier })
    local history = {}

    if result and #result > 0 then
        for _, row in ipairs(result) do
            table.insert(history, {
                date = row.transaction_date,
                type = row.transaction_type,
                amount = row.amount,
            })
        end
    end

    return history
end)


AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for identifier, _ in pairs(transactionCache) do
            flushUserTransactionsToDatabase(identifier)
        end
    end
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining == 120 then
        for identifier, _ in pairs(transactionCache) do
            flushUserTransactionsToDatabase(identifier)
        end
    end
end)

local function generateRandomCardNumber()
    local cardNum = ""
    for i = 1, 16 do
        cardNum = cardNum .. tostring(math.random(0, 9))
        if i == 4 or i == 8 or i == 12 then
            cardNum = cardNum .. " " 
        end
    end
    return cardNum
end

local function generateRandomExpiryDate()
    local month = math.random(1, 12)  
    local year = math.random(25, 30)  
    
    return string.format("%02d/%02d", month, year)
end

local function generateRandomCVV()
    local cvv = ""
    for i = 1, 3 do
        cvv = cvv .. tostring(math.random(0, 9)) 
    end
    return cvv
end

local function insertCCData(identifier, longNum, name, expiry, cvv, correctPin)
    local insertQuery = [[
        INSERT INTO qtm_card_details (identifier, long_num, name, expiry, cvv, correct_pin)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            long_num = VALUES(long_num),
            name = VALUES(name),
            expiry = VALUES(expiry),
            cvv = VALUES(cvv),
            correct_pin = VALUES(correct_pin)
    ]]

    MySQL.query.await(insertQuery, { identifier, longNum, name, expiry, cvv, correctPin })
end


RegisterNetEvent('qtm:server:setUserPIN')
AddEventHandler('qtm:server:setUserPIN', function(pinCode)
    local src = source
    local identifier = qtm.Framework.GetIdentifier(src)
    local name = qtm.Framework.GetChar(src).fullname

    local longNum = generateRandomCardNumber()
    local expiry = generateRandomExpiryDate()
    local cvv = generateRandomCVV()
    
    insertCCData(identifier, longNum, name, expiry, cvv, pinCode)
end)


lib.callback.register('qtm:server:awaitccData', function(source)
    local src = source
    local identifier = qtm.Framework.GetIdentifier(src)

    local query = [[
        SELECT long_num, name, expiry, cvv, correct_pin
        FROM qtm_card_details
        WHERE identifier = ?
    ]]

    local result = MySQL.query.await(query, { identifier })

    if result and #result > 0 then
        return {
            longNum = result[1].long_num,
            name = result[1].name,
            expiry = result[1].expiry,
            cvv = result[1].cvv,
            correctPin = result[1].correct_pin,
        }
    else
        if Config.Debug then print("Invalid user data: "..result) end
        return false
    end
end)

lib.callback.register('qtm:server:awaitBalance', function(source)
    local src = source

    local balance = qtm.Framework.GetBank(src)
    return balance or 0
end)

lib.callback.register('qtm:server:awaitDeposit', function(source, depositAmount)
    local src = source
    local identifier = qtm.Framework.GetIdentifier(src)

    if depositAmount and depositAmount > 0 then
        qtm.Framework.AddMoney(src, depositAmount, "bank")
        cacheTransaction(identifier, "Deposit", depositAmount)

        local currentBalance = qtm.Framework.GetBank(src) or 0
        local newBalance = currentBalance + depositAmount
        return newBalance
    else
        if Config.Debug then print("Invalid deposit amount: ".. depositAmount) end
        return false
    end
end)

lib.callback.register('qtm:server:awaitWithdrawal', function(source, withdrawalAmount)
    local src = source
    local identifier = qtm.Framework.GetIdentifier(src)
    
    local currentBalance = qtm.Framework.GetBank(src) or 0

    if withdrawalAmount and withdrawalAmount > 0 and withdrawalAmount <= currentBalance then
        qtm.Framework.RemoveMoney(src, withdrawalAmount, "bank")
        cacheTransaction(identifier, "Withdraw", withdrawalAmount)

        local newBalance = currentBalance - withdrawalAmount
        return newBalance
    else
        if Config.Debug then print("Invalid withdrawal amount or insufficient funds. Withdrawal Amount: "..withdrawalAmount.." Current Balance: " .. currentBalance) end
        return false
    end
end)
