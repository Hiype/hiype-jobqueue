# <b>Job queue system for QBCore</b>

Simple custom made queue system for an upcoming project of mine but could also be used in any other job scripts too.<br>
This script is an early version so if you have any suggestions, fixes or issues - please post them in the Issues section or contribute using pull requests.<br>
Thank you in advance! :)

<br>

## <b>Adding job</b>

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

<hr>

## <b>Adding sub job</b>

### Single sub job (Server-side) <i>Recommended</i>
```lua
TriggerEvent('hiype-jobqueue:server:add-subjob', pJobName, pSubJobName, pWaitTime)
```

### Single sub job (Client-side)
```lua
TriggerServerEvent('hiype-jobqueue:server:add-subjob', pJobName, pSubJobName, pWaitTime)
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

<hr>

## <b>Adding jobs with sub jobs</b>
### Example
```lua
for k,_ in pairs(pJobArray) do
    TriggerEvent('hiype-jobqueue:server:add-job', k, pMaxQueueSize, pWaitTime)

    for _, subV in pairs(pSubJobArray) do
        TriggerEvent('hiype-jobqueue:server:add-subjob', k, subV.name, pMaxQueueSize2)
    end
end
```

<hr>

## <b>Join queue</b>
```lua
QBCore.Functions.TriggerCallback('hiype-jobqueue:server:join-queue', function(result)
    print("Received janitor job to: " .. tostring(result))
end, pJobName, pSubJobNum, pPreviousSubJob)
```

### Parameters
<b>pJobName</b> <i>(String)</i> - Name of the job that you wish to join queue to<br>

<hr>

## <b>Leave queue</b>
```lua
TriggerServerEvent('hiype-jobqueue:server:leave-queue')
```

<hr>

## <b>Configurations</b>
<b>Config.QueueCheckRate</b> <i>(unsigned int = msec)</i> - How often to check in msec if a player that is in queue has gone offline to remove the player<br>
<b>Config.JobAssignerRate</b> <i>(unsigned int = msec)</i> - Amount timer time is reduced by in msec (also used in Wait time)<br>
<b>Config.DebugLogs</b> <i>(boolean)</i> - Enables some logging for the queue system<br>
<b>Config.EnableQueuePrintCommand</b> <i>(boolean)</i> - Enables registration of a command for players to print queue in server logs<br>
<b>Config.CommandPermissionLevel</b> <i>(String)</i> - Level of permission required to use the command if enabled

<hr>

## <b>Commands</b>
<b>/queue</b> - Prints queue contents in server logs if enabled in config file