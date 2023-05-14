QBCore = exports['qb-core']:GetCoreObject()

local queue = {}

local function IsPlayerInQueue(pSource)
    for k,v in pairs(queue) do
        for i=1, #v.players do
            if v.players[i] == pSource then return true end
        end
    end
    return false
end

local function DropFromQueue(pSource)
    for k,v in pairs(queue) do
        for i=1, #v.players do
            if v.players[i] == pSource then
                if not v.subJobs then
                    table.remove(v.players, i)
                    print("Removed player " .. tostring(pSource) .. " from job " .. tostring(k))
                else
                    table.remove(v.players, i)
                    print("Removed player " .. tostring(pSource) .. " from job " .. tostring(k))

                    for subK,subV in pairs(v.subJobs) do
                        for subI=1, #subV.players do
                            if subV.players[i] == pSource then
                                table.remove(subV.players, subI)
                                print("Removed player " .. tostring(pSource) .. " from subjob " .. tostring(subK))
                            end
                        end
                    end
                end
            end
        end
    end
end

local function GetFreeSubJobs(pSubJobsQueue)
    local freeSubJobs = {}

    for k,v in pairs(pSubJobsQueue) do
        if #v.players < v.maxSize then
            freeSubJobs[#freeSubJobs + 1] = k
        end
    end

    return freeSubJobs
end

local function AddToSubJob(pSource, pSubJobsQueue, pJobName, pSubJobNum)
    local freeSubJobs = GetFreeSubJobs(pSubJobsQueue)

    if #freeSubJobs > 0 then
        local subJobIndex

        if pSubJobNum == nil then
            subJobIndex = math.random(1, #freeSubJobs)
        else
            subJobIndex = pSubJobNum
        end

        local subJobKey = freeSubJobs[subJobIndex]
        local subJob = queue[pJobName].subJobs[subJobKey]

        tPrint(freeSubJobs)
        print(subJobIndex)
        print(tostring(subJob))

        subJob.players[#subJob.players + 1] = pSource

        return subJobKey
    else
        return nil
    end
end

local function AssignJob(pJobName, pSubJobs, pSource)

    if #queue[pJobName].players < 1 then
        print("Unable to assign job: No players in job queue")
        return
    end

    for k,v in pairs(pSubJobs) do
        tPrint(v)
        if v.players[1] == pSource then
            print("Sending job to client")
            TriggerClientEvent('hiype-jobqueue:client:receive-job', pSource, pJobName, k)
            return
        end
    end
    print("Error assigning job: Something went wrong")
end

-- ADD JOB
RegisterNetEvent('hiype-jobqueue:server:add-job', function(pJobName, pQueueMaxSize, pCooldownTime)
    if queue[pJobName] then
        print("Unable to add job: Job " .. pJobName ..  " already exists")
        return
    end

    queue[pJobName] = {
        maxSize = pQueueMaxSize,
        cooldown = pCooldownTime,
        timer = pCooldownTime,
        players = {}
    }
end)

-- ADD SUB JOB
RegisterNetEvent('hiype-jobqueue:server:add-subjob', function(pJobName, pSubJobName, pQueueMaxSize)
    if not queue[pJobName] then
        print("Unable to add sub job: Job " .. pJobName ..  " doesnt exist")
        return
    end

    if not queue[pJobName].subJobs then
        queue[pJobName].subJobs = {}
    end

    if queue[pJobName].subJobs[pSubJobName] then
        print("Unable to add sub job: Sub job " .. pSubJobName ..  " already exists")
        return
    end

    queue[pJobName].subJobs[pSubJobName] = {
        maxSize = pQueueMaxSize,
        players = {}
    }
end)

-- LEAVE QUEUE
RegisterNetEvent('hiype-jobqueue:server:leave-queue', function()
    if CountTableElements(queue) < 1 then
        print("Unable to leave queue: No jobs are present")
        return
    end

    DropFromQueue(source)
end)

RegisterNetEvent('hiype-jobqueue:server:print-queue', function()
    tPrint(queue)
end)

-- JOIN QUEUE
QBCore.Functions.CreateCallback('hiype-jobqueue:server:join-queue',function(source, cb, pJobName, pSubJobNum)
    local src = source
    local jobQueue = queue[pJobName]

    if pJobName == nil then
        print("Unable to join queue: No job name provided")
        cb(nil)
        return
    end

    if CountTableElements(queue) < 1 then
        print("Unable to join queue: No jobs are present")
        cb(nil)
        return
    end

    if not jobQueue then
        print("Unable to join queue: No such job exists: " .. tostring(pJobName))
        cb(nil)
        return
    end

    if IsPlayerInQueue(src) then
        print("Unable to join queue: Player is already in queue")
        cb(nil)
        return
    end

    local subJobsQueue = jobQueue.subJobs

    if #jobQueue.players < jobQueue.maxSize then
        jobQueue.players[#jobQueue.players + 1] = src
        print("Player " .. tostring(src) .. " joined queue for job " .. pJobName)
        if subJobsQueue then
            local subJobKey = AddToSubJob(src, subJobsQueue, pJobName, pSubJobNum)

            print("Current queue: ")
            tPrint(queue, 3)

            if subJobKey then
                print("Player " .. tostring(src) .. " joined queue for sub job " .. subJobKey)
                cb(subJobKey)
            else
                print("Unable to join queue:" .. pJobName .. " all subjobs were full")
                cb(-2)
            end
        else
            cb(1)
            print("Current queue: ")
            tPrint(queue, 3)
        end
    else
        print("Unable to join queue: " .. pJobName .. " is full")
        cb(-1)
    end
end)

CreateThread(function()
    while true do
        local Players = QBCore.Functions.GetQBPlayers()
        
        for i,v in ipairs(Players) do
            if not v.PlayerData.LoggedIn then
                DropFromQueue(v.PlayerData.source)
            end
        end

        Wait(Config.QueueCheckRate)
    end
end)

CreateThread(function()
    local reducedTime = Config.JobAssignerRate

    while true do
        for k,v in pairs(queue) do
            if v.timer >= reducedTime then
                v.timer = v.timer - reducedTime
            else
                print("Assigning job next step")
                AssignJob(k, v.subJobs, v.players[1])
                table.remove(v.players, 1)
                v.timer = v.cooldown
            end
        end

        Wait(reducedTime)
    end
end)