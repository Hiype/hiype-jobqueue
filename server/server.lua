QBCore = exports['qb-core']:GetCoreObject()

local loggingEnabled = Config.DebugLogs

local queue = {}

local function IsPlayerInQueue(pSource)
    for _,v in pairs(queue) do
        for i=1, CountTableElements(v.players) do
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

                    if loggingEnabled then
                        print("Removed player " .. tostring(pSource) .. " from job " .. tostring(k))
                    end
                    return
                else
                    table.remove(v.players, i)

                    for subK,subV in pairs(v.subJobs) do
                        for subI=1, #subV.players do
                            if subV.players[i] == pSource then
                                table.remove(subV.players, subI)

                                if loggingEnabled then
                                    print("Removed player " .. tostring(pSource) .. " from subjob " .. tostring(subK) .. " in job " .. tostring(k))
                                end

                                return
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

local function AddToSubJob(pSource, pSubJobsQueue, pJobName, pSubJobNum, pPreviousSubJob)
    local freeSubJobs = GetFreeSubJobs(pSubJobsQueue)

    if pPreviousSubJob ~= nil then
        if #freeSubJobs > 1 then
            for i=1, #freeSubJobs do
                if freeSubJobs[i] == pPreviousSubJob then
                    table.remove(freeSubJobs, i)
                    break
                end
            end
        end
    end

    if #freeSubJobs > 0 then
        local subJobIndex

        if pSubJobNum == nil then
            subJobIndex = math.random(1, #freeSubJobs)
        else
            subJobIndex = pSubJobNum
        end

        local subJobKey = freeSubJobs[subJobIndex]
        local subJob = queue[pJobName].subJobs[subJobKey]

        subJob.players[#subJob.players + 1] = pSource

        return subJobKey
    else
        return nil
    end
end

local function AssignJob(pJobName, pSubJobs, pSource)
    if #queue[pJobName].players < 1 then
        if loggingEnabled then print("Unable to assign job: No players in job queue") end
        return
    end

    for k,v in pairs(pSubJobs) do
        if v.players[1] == pSource then
            if loggingEnabled then
                print("Sending job to client params: " .. tostring(pSource) .. " " .. tostring(pJobName) .. " " .. tostring(k))
            end

            TriggerClientEvent('hiype-jobqueue:client:receive-job', pSource, pJobName, k)
            DropFromQueue(pSource)
            return
        end
    end

    if loggingEnabled then
        if loggingEnabled then print("Error assigning job: Something went wrong") end
    end
end

-- ADD JOB
RegisterNetEvent('hiype-jobqueue:server:add-job', function(pJobName, pQueueMaxSize, pCooldownTime)
    if queue[pJobName] then
        if loggingEnabled then print("Unable to add job: Job " .. pJobName ..  " already exists") end
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
        if loggingEnabled then print("Unable to add sub job: Job " .. pJobName ..  " doesnt exist") end
        return
    end

    if not queue[pJobName].subJobs then
        queue[pJobName].subJobs = {}
    end

    if queue[pJobName].subJobs[pSubJobName] then
        if loggingEnabled then print("Unable to add sub job: Sub job " .. pSubJobName ..  " already exists") end
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
        if loggingEnabled then print("Unable to leave queue: No jobs are present") end
        return
    end

    DropFromQueue(source)
end)

-- JOIN QUEUE
QBCore.Functions.CreateCallback('hiype-jobqueue:server:join-queue',function(source, cb, pJobName, pSubJobNum, pPreviousSubJob)
    local src = source
    local jobQueue = queue[pJobName]

    if pJobName == nil then
        if loggingEnabled then print("Unable to join queue: No job name provided") end
        cb(nil)
        return
    end

    if CountTableElements(queue) < 1 then
        if loggingEnabled then print("Unable to join queue: No jobs are present") end
        cb(nil)
        return
    end

    if not jobQueue then
        if loggingEnabled then print("Unable to join queue: No such job exists: " .. tostring(pJobName)) end
        cb(nil)
        return
    end

    if IsPlayerInQueue(src) then
        if loggingEnabled then print("Unable to join queue: Player is already in queue") end
        cb(nil)
        return
    end

    local subJobsQueue = jobQueue.subJobs

    if #jobQueue.players < jobQueue.maxSize then
        if loggingEnabled then print("Player " .. tostring(src) .. " joined queue for job " .. pJobName) end
        if subJobsQueue then
            local subJobKey = AddToSubJob(src, subJobsQueue, pJobName, pSubJobNum, pPreviousSubJob)
            if subJobKey ~= nil then
                if loggingEnabled then print("Player " .. tostring(src) .. " joined queue for sub job " .. subJobKey) end
                jobQueue.players[#jobQueue.players + 1] = src
                cb(subJobKey)
            else
                if loggingEnabled then print("Unable to join queue:" .. pJobName .. " all subjobs were full") end
                
                cb(-2)
            end
        else
            jobQueue.players[#jobQueue.players + 1] = src
            cb(1)
        end
    else
        if loggingEnabled then print("Unable to join queue: " .. pJobName .. " is full") end
        cb(-1)
    end
end)

if Config.EnableQueuePrintCommand then
    QBCore.Commands.Add('queue', 'Prints queue content in server logs', {}, false, function(source, args)
        tPrint(queue)
    end, Config.CommandPermissionLevel)
end

CreateThread(function()
    while true do
        for k,v in pairs(queue) do
            for i=1, #v.players do
                local player = v.players[i]
                if QBCore.Functions.GetPlayer(player) == nil then
                    DropFromQueue(player)
                end
            end
        end

        Wait(Config.QueueCheckRate)
    end
end)

CreateThread(function()
    local reducedTime = Config.JobAssignerRate

    while true do
        for k,v in pairs(queue) do
            if #v.players > 0 then
                if v.timer >= reducedTime then
                    v.timer = v.timer - reducedTime
                else
                    AssignJob(k, v.subJobs, v.players[1])
                    v.timer = v.cooldown
                end
            end
        end

        Wait(reducedTime)
    end
end)