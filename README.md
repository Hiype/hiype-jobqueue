# <b>Job queue system for QBCore</b>

Simple custom made queue system for and upcoming project jobs.

<br>

## <b>Adding job</b>
<br>

### Single job (Server-side) <i>Recommended</i>
```lua
TriggerEvent('hiype-jobqueue:server:add-job', pJobName, pMaxQueueSize, pWaitTime)
```

### Single job (Client-side)
```lua
TriggerServerEvent('hiype-jobqueue:server:add-job', pJobName, pMaxQueueSize, pWaitTime)
```

### Multiple jobs
```lua
for k,v in pairs(pJobArray) do
    TriggerEvent('hiype-jobqueue:server:add-job', k, pMaxQueueSize, pWaitTime)
end
```

### Parameters
<b>pJobArray</b> <i>(Array)</i> - Used QBCore job formatting for testing which can be found at qb-core->shared->jobs<br>
<b>pJobName</b> <i>(String)</i> - Name of the job that you wish to add<br>
<b>pMaxQueueSize</b> <i>(Unsigned integer > 0)</i> - Amount of players allowed to be in queue<br>
<b>pWaitTime</b> <i>(unsigned integer)</i> - Time before next player gets assigned a job in the queue

<br>
<hr>
<br>

## <b>Adding sub job</b>
<br>

### Single sub job
```lua
TriggerEvent('hiype-jobqueue:server:add-subjob', pJobName, pSubJobName, pWaitTime)
```

### Multiple sub jobs
```lua
for k, v in pairs(pSubJobArray) do
    TriggerEvent('hiype-jobqueue:server:add-subjob', k, v.name, pWaitTime)
end
```

### Parameters
<b>pJobName</b> <i>(String)</i> - Name of the job that you wish to add the sub job to<br>
<b>pWaitTime</b> <i>(unsigned integer)</i> - Time before next player gets assigned a job in the queue

<br>
<hr>
<br>

## <b>Adding job with sub jobs</b>
### Example
```Lua
for k,v in pairs(pJobArray) do
    TriggerEvent('hiype-jobqueue:server:add-job', k, pMaxQueueSize, pWaitTime)

    for subK, subV in pairs(Config.TrashLocations) do
        TriggerEvent('hiype-jobqueue:server:add-subjob', k, subV.name, pMaxQueueSize2)
    end
end
```

<br>
<hr>
<br>

## <b>Join queue</b>
```lua
QBCore.Functions.TriggerCallback('hiype-jobqueue:server:join-queue', function(result)
    print("Received janitor job to: " .. tostring(result))
end, pJobName)
```

### Parameters
<b>pJobName</b> <i>(String)</i> - Name of the job that you wish to join queue to<br>

<br>
<hr>
<br>

## <b>Leave queue</b>
```lua
TriggerServerEvent('hiype-jobqueue:server:leave-queue')
```