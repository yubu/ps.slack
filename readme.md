## This module compliments the psbbix

##### Compatibility
- Tested with Powershell 5+ only 

### Why Slack? 
- Read [here](https://ramblingcookiemonster.github.io/PSSlack/) - I can't explain better  

### Prerequisites
1. Module find-string for better help: install-module find-string -force
2. [slackAuthToken](<https://api.slack.com/web>)
3. [slackWebHook](<https://api.slack.com/incoming-webhooks>), if you want to use webhook

### Limitations
- Sometimes, working with few APIs and using different auth and tokens in the same powershell session may result weird results
- Example: after login to Zabbix, you can't use PowershellGallery (find-module etc. doesn't work) in the same powershell session
- Workaround: use different powershell session for different API sessions and use copy/paste: dir | clip; get-clipboard | out-string | Send-slackMessage -channel "#BlackFriday" 
- [ConEmu](<https://conemu.github.io/>) and/or [Console2](<https://sourceforge.net/projects/console/>) are your best friends 

### Example: Windows
- If you're working with VWAT stack (VMware/Windows/Apache/Tomcat - say VeeWAT)
- Running from PowerCLI (VMware) + ps.slack:
```powershell
(get-vm | ? powerstate -match on | ? name -match "vmname|vmname" | get-vmguest | select @{n="IPAddress";e={$_.IPAddress -match "10.20.10"}}).ipaddress | New-PSSession
or 
(get-vm | ? powerstate -match on | ? name -match "vmname|vmname" | Get-VMGuest).hostname | New-Pssession -usessl
invoke-command -Session (get-pssession) {hostname; gc -tail 200 c:\var\logs\app\error.log} | sls "ERROR" | out-string |  Send-slackMessage -channel "#BlackFriday" 
```
### Example: Linux
- Running from PowerCLI (VMware) + SSH module + ps.slack:
```powershell
(get-vm | ? powerstate -match on | ? name -match "vmname|vmname" | get-vmguest | select @{n="IPAddress";e={$_.IPAddress -match "10.20.10"}}).ipaddress | New-SSHSession
Get-SshSession | Invoke-SshCommand -command {hostname; dstat -lvn 1 2} | out-string | Send-slackMessage -channel "#BlackFriday"
```

### Example: Webhook: Monitor Postfix from powershell
```powershell
if ($body=(Invoke-SSHCommand -ComputerName IPAddress -ScriptBlock {tail -n200 /var/log/maillog | egrep -i "error|deferred|bounced|blocked"} -Credential $Credential) | select -ExpandProperty result) {send-webhook -url 'https://hooks.slack.com/services/...' -channel '#smtp' -text $body -emoji ":exclamation:" -username myBot}
```

### Example: psbbix (module for Zabbix API)
```powershell
Get-ZabbixAlert @zabSessionParams | ? sendto -match yubu | select @{n="Time(UTC+1)";e={(convertfrom-epoch $_.clock).addhours(1)}},alertid,subject | Out-String | Send-slackMessage -channel "#BlackFriday"

Get-ZabbixHost @zabSessionParams | ? name -match "hostName" | Get-ZabbixGraph @zabSessionParams | ? name -match 'CPU utilization' | Save-ZabbixGraph -verbose -fileFullPath c:\graph.png
Send-slackFilesCurl -channels "#BlackFriday" -file c:\graph.png
# curl.exe should be in the path (download from here https://curl.haxx.se/download.html)
# and delete curl alias for invoke-webrequest: if (dir alias:curl -ea 0) {del alias:curl -force}
```

### Installation
1. unzip to $env:userprofile\Documents\WindowsPowerShell\Modules
2. import-module ps.slack

### Help
```powershell
Get-SlackHelp -list
Get-SlackHelp
gskh -alias
gskh message -p zabbix
gskh mess* -p zabbix -short
gskh message -p "get-vm"
gskh channels
gskh chan* -p oldest -short
Get-slackChannelsHistory
```

### Examples
```powershell
# Send Message to channel
Send-slackMessage -channel "@username" -text "text"
Send-slackMessage -channel "#BlackFriday" -text (gc c:\errors.log | out-string)

# Send message to user
Send-slackMessage -channel "@name.lastname" -text "Hello!"
Get-slackUsers | ? presence -match active | select id,name,status,real_name,is_admin,is_bot,presence | ? name -match username | Send-SlackMessage -text "text"

# Edit message
Search-slack -query "query" | select -ExpandProperty messages | select -ExpandProperty matches | Set-slackMessage -text "New message here" -channel {$_.channel.id}

# Search
Search-slack -query "powershell" | select @{n="MsgTotal"; e={$_.messages.total}}, @{n="FilesTotal";e={$_.files.total}},@{n="PostsTotal";e={$_.posts.total}}
Search-slack -query "powershell" | select -ExpandProperty files | select -ExpandProperty matches | ft -a
Search-slack -query "powershell" | select -ExpandProperty posts | select -ExpandProperty matches | ft -a

# Get messages from channel
Get-slackChannels | ? name -match channelName | Get-slackChannelsHistory | select username,bot_id,type,text
Get-slackChannels | ? name -match channelName | gskchhist | ? text -match "text1|text2"

# Remove messages
Get-slackChannels | ? name -match test | Get-slackChannelsHistory | ? text -match hello | Remove-slackMessage -id (Get-slackChannels | ? name -match test).id

# Get users
Get-slackUsers | select id,name,status,real_name,is_admin,is_bot,presence | ft -a

# Get channels
Get-slackChannels | elect id,name,@{n="created";e={(convertFrom-epoch $_.created).addhours(-5)}},@{n="creator";e={(Get-slackUsers | ? id -eq $_.creator).name}},num_members | sort created -desc | ft -a

# Get channels creation info
Get-slackChannels | ? name -match "" | Get-slackChannelsInfo | select id,name,@{n='creator';e={(gskusrs | ? id -match $_.creator).name}},@{n="created";e={convertfrom-epoch $_.created}} | sort creator | ft -a

# Send content of text file
Send-slackFiles -content (Get-Clipboard | out-string) -channels "#BlackFriday"
Send-slackFiles -content (gc c:\log.log | out-string) -channels "#BlackFriday"

# Send file, using curl.exe  (https://curl.haxx.se/download.html)
Send-slackFilesCurl -channels "#BlackFriday" -file C:\graph.png -filename graph.png -filetype auto -title Zabbix -verbose

# Post alerts from Zabbix
Get-ZabbixAlert @zabSessionParams | ? sendto -match yubu | select @{n="Time(UTC+1)";e={(convertfrom-epoch $_.clock).addhours(1)}},alertid,subject | Out-String | Send-slackMessage -channel "#BlackFriday"

# Open direct IM channel
Get-slackUsers | ? name -match user | Start-slackIM

# Get direct messages for the user, time in UTC+1
Get-slackIM | select id,@{n="user";e={(gskusrs | ? id -eq $_.user).name}} | Get-slackIMHistory | select type,@{n="user";e={(gskusrs | ? id -eq $_.user).name}},bot_id,@{n='time';e={(convertfrom-epoch ($_.ts).split(".")[0]).addhours(1)}},text | ft -a
```

### List of Commands
```powershell
Add-slackReminders          
Close-slackGroups           
Complete-slackReminders     
Disconnect-slack            
Disconnect-slackGroups      
Get-slackBots               
Get-slackChannels           
Get-slackChannelsHistory    
Get-slackChannelsInfo       
Get-slackEmoji              
Get-slackFiles              
Get-slackFilesInfo          
Get-slackGroups             
Get-slackGroupsHistory      
Get-slackGroupsInfo         
Get-slackHelp               
Get-slackIM                 
Get-slackIMHistory          
Get-slackPins               
Get-slackReactionsFile      
Get-slackReactionsUser      
Get-slackReminders          
Get-slackRemindersInfo      
Get-slackTeamAccessLogs     
Get-slackTeamBillableInfo   
Get-slackTeamDND            
Get-slackTeamInfo           
Get-slackTeamIntegrationLogs
Get-slackUserDND            
Get-slackUsers              
Get-slackUsersIdentity      
Get-slackUsersPresence      
New-slackChannels           
New-slackGroups             
New-slackGroupsInvite       
Open-slackGroups            
Remove-slackFiles           
Remove-slackGroupsUser      
Remove-slackMessage         
Remove-slackPins            
Remove-slackReactionsFile   
Remove-slackReminders       
Rename-slackChannels        
Rename-slackGroups          
Revoke-slackAuthToken       
Search-slack                
Send-slackFiles             
Send-slackFilesCurl         
Send-slackMessage           
Send-slackMessageAsBot      
Send-slackWebhook           
Set-slackAuthToken          
Set-slackChannelsArchive    
Set-slackChannelsInvite     
Set-slackChannelsUnArchive  
Set-slackFilesPrivate       
Set-slackFilesPublic        
Set-slackGroupsArchive      
Set-slackGroupsPurpose      
Set-slackGroupsTopic        
Set-slackGroupsUnArchive    
Set-slackMessage            
Set-slackPins               
Set-slackReactionsFile      
Show-slackAuthToken         
Start-slackIM               
Stop-slackIM                
Test-slackAPI               
Test-slackAuthToken         
```