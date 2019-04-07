Function Get-slackHelp {
    <# 
    .Synopsis
        Get fast help for most useful examples for every function
    .Description
        Get fast help for most useful examples for every function
    .Example
        Get-slackHelp help
        Get help on help
    .Example
        gskh -list
        Get list of module commands
    .Example
        gskh -alias
        Get list of aliases for the ps.slack module
    .Example
        gskh message
        Get examples for all slackMessage commands
    .Example
        gskh mess* -p zabbix -short
        Get examples for lackMessage look for string zabbix
    .Example
        gskh -zverb get
        Get examples of all get commands
    .Example
        gskh message set
        Get examples for Set-slackMessage
    .Example
        gskh message -p set
        Get examples for *-slackMessage and look for "set""
    #>
    
    [CmdletBinding()]
    [Alias("gskh")]
    Param ($znoun,$zverb,[switch]$list,$pattern,[switch]$short,[switch]$alias)
    
    if ($list) {dir function:\*-slack* | select name | sort name }
    elseif ($alias) {gcm -Module ps.slack | %{gal -Definition $_.name -ea 0}}
    elseif (!$znoun -and $pattern -and $short) {gskh | %{foreach ($i in $_) {$i | Select-String -Pattern $pattern -AllMatches | Out-ColorMatchInfo -onlyShowMatches}}}
    elseif (!$znoun -and $pattern -and !$short) {gskh | out-string | Select-String -Pattern $pattern -AllMatches | Out-ColorMatchInfo -onlyShowMatches}
    elseif ($znoun -and $pattern -and !$short) {gskh $znoun | out-string | Select-String -Pattern $pattern -AllMatches | Out-ColorMatchInfo -onlyShowMatches}
    elseif ($znoun -and $pattern -and $short) {gskh $znoun | %{foreach ($i in $_) {$i | Select-String -Pattern $pattern -AllMatches | Out-ColorMatchInfo -onlyShowMatches}}}
    elseif ($zverb -and !$znoun) {dir function:\$zverb-slack* | %{write-host $_.Name -f yellow; get-help -ex $_.Name | out-string | Remove-EmptyLines}}
    elseif ($znoun -and !$zverb) {dir function:\*slack$znoun | %{write-host $_.Name -f yellow; get-help -ex $_.Name | out-string | Remove-EmptyLines}}
    elseif ($zverb -and $znoun) {dir function:\$zverb-slack$znoun | %{write-host $_.Name -f yellow; get-help -ex $_.Name | out-string | Remove-EmptyLines}}
    else {dir function:\*slack* | %{write-host $_.Name -f yellow; get-help -ex $_.Name | out-string | Remove-EmptyLines}}
}

function Remove-EmptyLines {
	<#
	.Synopsis
		Remove empty lines from file, string or variable
	.Description
		Remove empty lines from file, string or variable
	.Example
		Remove-EmptyLines -in (gc c:\file.txt)
	.Example
		$var | Remove-EmptyLines
	.Example
		help -ex Remove-EmptyLines | Remove-EmptyLines 
	.Example
		gc c:\*.txt | rmel
	.Example
		Get-ClipBoard | rmel
	.Example
		dir | oss | rmel
	#>
	
	[cmdletbinding()]
    [Alias("rmel")]
    param ([Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)][array]$in)
	
	process {
		if (!$psboundparameters.count) {
			help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines
			return
		}
		
		$in.split("`r`n") | ? {$_.trim() -ne ""}
	}
}

function Set-slackAuthToken {
    <# 
    .Synopsis
        Set slack authentication token
    .Description
        Set slack authentication token 
    .Example
        Set-slackAuthToken
        Set slack authentication token
    #>

    [CmdletBinding()]
    param(
        [switch]$force,
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$global:slackToken,
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$global:slackTokenIdentity
    )
   
    if (!$global:slackToken) {$global:slackToken=read-host "Input the slack user authentication token"; write-verbose "Slack user token: $global:slackToken"} 
    else {write-host "`nSlack user token already exists." -f green; write-host "Want to set new one, use -force`n" -f yellow; write-verbose "Slack user token: $global:slackToken"}
    if (!$global:slackTokenIdentity) {$global:slackTokenIdentity=read-host "Input the slack identity scope authentication token"; write-verbose "Slack user token: $global:slackTokenIdentity"} 
    else {write-host "`nSlack identity scope token already exists." -f green; write-host "Want to set new one, use -force`n" -f yellow; write-verbose "Slack user token: $global:slackTokenIdentity"}
    # elseif (!$force) {write-host "`nSlack user token already exists." -f green; write-host "Want to set new one, use -force`n" -f yellow; write-verbose "Slack user token: $global:slackToken"}
    if ($force) {
        if ($global:slackToken) {$global:slackToken=read-host "Input the slack user authentication token"; write-verbose "Slack user token: $global:slackToken"}
        if ($global:slackTokenIdentity) {$global:slackTokenIdentity=read-host "Input the slack identity scope authentication token"; write-verbose "Slack user token: $global:slackTokenIdentity"}
    }
}

function Test-slackAuthToken {
    <# 
    .Synopsis
        Test slack authentication token with slack API endpoint
    .Description
        Test slack authentication token with slack API endpoint
    .Example
        Test-slackAuthToken
        Test slack token
    #>
    
    [CmdletBinding()]
    [Alias("tskauth","shskauth")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][ValidateSet('user','identity','bot')][string]$scope="user",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="auth.test"
    )
    
    if (!$psboundparameters.count -and !$global:slackToken) {write-host "`nSlack authentication token is not set!`n" -f red; return}

	$boundparams=$PSBoundParameters | out-string
	write-verbose "($boundparams)"

    switch -wildcard ($scope) {
        user {$token=$global:slackToken}
        bot {$token=$global:slackToken}
        identity {$token=$global:slackTokenIdentity}
    }

    $Body = @{
        token = $token
    }
        
    write-verbose "Slack user token: $global:slackToken"
    write-verbose ($body | ConvertTo-Json)
    $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
    $a
}

function Show-slackAuthToken {
    <# 
    .Synopsis
        Show slack authentication token
    .Description
        Show slack authentication token
    .Example
        Show-slackAuthToken
        Show slack authentication token
    #>

    [CmdletBinding()]
    [Alias("testskconn")]
    Param ()

    if ($global:slackToken -or $global:slackTokenIdentity) {
        "token user scopes: $global:slackToken"
        "token identity scopes: $global:slackTokenIdentity"
    } 
    else {
        write-host "`nSlack authentication tokens are not set!`n" -f red; Set-slackAuthToken
    }
}

function Revoke-slackAuthToken {
    <# 
    .Synopsis
        Revoke slack authentication token from Slack API service. New token should be generated
    .Description
        Revoke slack authentication token from Slack API service. New token should be generated
    .Example
        Revoke-slackAuthToken
        Revoke slack authentication token from Slack API service. New token should be generated
    #>
    
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
    [Alias("Revoke-slackAuthToken")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="auth.revoke"
    )
    
    if (Test-slackAuthToken) {
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
        }
            
        write-verbose ($body | ConvertTo-Json)
        if ([bool]$WhatIfPreference.IsPresent) {}
        if ($PSCmdlet.ShouldProcess($token,"Revoke the authentication token, i.e. delete from Slack service! You'll need to generate the new token then.)")) {  
            $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
            $global:slackToken=""
        }
            $a
    }
}

function Test-slackAPI {
    <# 
    .Synopsis
        Test slack API
    .Description
        Test slack API
    .Example
        Test-slackAPI
        Test slack API
    #>
    
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="api.test"
    )
    
    if (Test-slackAuthToken) {
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
        }
        
        write-verbose ($body | ConvertTo-Json)
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        $a
    }
}

function Disconnect-slack {
     <# 
    .Synopsis
        Disconnect from slack, unset the local authentication token
    .Description
        Disconnect from slack, unset the local authentication token
    .Example
        Disconnect-slack
        Disconnect from slack, unset the local authentication token
    #>

    [CmdletBinding()]
    Param ()
    
    if ($global:slackToken) {$global:slackToken=""} 
}

function Send-slackWebhook {
    <# 
    .Synopsis
        Post messages to slack via webhook
    .Description
        Post messages to slack via webhook
    .Example
        Send-Webhook -url 'https://hooks.slack.com/services/...' -channel '#test' -text "http://www.emoji-cheat-sheet.com/"
        Post URL
    .Example
        Send-Webhook -url 'https://hooks.slack.com/services/...' -channel '@username' -text "This is my hook" -emoji ":yum:" -username myBot
        Post message
    .Example
        "NO", "YES" | %{send-webhook -text $_ -channel "#test" -URL "https://hooks.slack.com/services/..."}
        Post two messages
    .Example
        Send-Webhook -url 'https://hooks.slack.com/services/...' -channel '#smtp' -text ((Invoke-SSHCommand -ComputerName 10.10.20.10 -ScriptBlock {tail -n500 /var/log/maillog | egrep -i "sent"} -Credential $cred) | select -ExpandProperty result) -emoji ":exclamation:" -username myBot
        Post from Postfix's maillog
    .Example
        if ((($body=(Invoke-SSHCommand -ComputerName SMTPserver -ScriptBlock {tail -n100 /var/log/maillog | egrep -i "error|deferred|bounced|blocked"} -Credential $cred) | select -ExpandProperty result))) {send-webhook -url 'https://hooks.slack.com/services/...' -channel '#smtperrors' -text $body -emoji ":exclamation:" -username myBot} else {write-host "$(get-date -f o)`: SMTP is OK" -f green}
        Post smtp errors grepped from Postfix email server logs
    .Example
        (1..1000) | %{if ((($body=(Invoke-SSHCommand -ComputerName 10.10.20.10 -ScriptBlock {tail -n200 /var/log/maillog | egrep -i "error|deferred|bounced|blocked"} -Credential $cred) | select -ExpandProperty result))) {send-webhook -url 'https://hooks.slack.com/services/...' -channel '#smtp' -text $body -emoji ":exclamation:" -username myBot; sleep (10*60)} else {write-host "$_ - $(get-date -f o)`: SMTP is OK" -f green; sleep (30*60)}}
        Post smtp errors grepped from Postfix email server logs, if error will occur
    #>

    [CmdletBinding()]
    [Alias("Send-Webhook","sskweb")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$text,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channel,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$username="myWebhookBot",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$emoji=":exclamation:"
    )
    
    process {
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        if ($text.contains("http")) {$text="<$text>"}
        
        $Body = @{
            channel = $channel
            username = $username
            text = $text
            icon_emoji = $emoji
            unfurl_links = "true"
        }
        
        write-verbose ($body | ConvertTo-Json)
        $BodyJSON = ConvertTo-Json $Body
        
        $a = Invoke-RestMethod "$URL" -ContentType "application/x-www-form-urlencoded" -Body $BodyJSON -Method Post
        $a
    }
}

function Send-slackMessage {
    <# 
    .Synopsis
        Post messages to slack
    .Description
        Post messages to slack
    .Example
        Send-slackMessage -text "Post text to slack" -channel "#test" -Verbose 
        Post slack message
    .Example
        sskmsg -channel "#test" -text "Hello world"
        Post message
    .Example
        sskmsg -channel "@name.lastname" -text "Hello!"
        Post message to user
    .Example
        Get-slackUsers | ? presence -match active | select id,name,status,real_name,is_admin,is_bot,presence | ? name -match name | sskmsg -text "Hello"
        Post message to user    
    .Example
        Get-slackChannels | ? name -match test | sskmsg -text "Hello world"
        Post message
    .Example
        sskmsg -channel "#BlackFriday" -text (gc c:\errors.log | out-string)
        Post message 
    .Example
        Get-Clipboard | out-string | Send-slackMessage -channel "#test"
        Paste and send the message
    .Example
        Get-slackIM | select id,@{n="user";e={(gskusrs | ? id -eq $_.user).name}} | ? user -match user | Send-slackMessage -text "Direct IM message"
        Send direct IM message
    .Example
        (get-vm | ? powerstate -match on | ? name -match centos | get-vmguest | select @{n="IPAddress";e={$_.IPAddress -like "10.10.20.*"}}).ipaddress | new-sshsession
        Get-SshSession | Invoke-SshCommand -command {hostname; df -h} | oss | Send-slackMessage -channel "#test"
        1. Connect to multiple Linux boxes, using VMware PowerCLI and SSH module
        2. Get disk information from all machines and post to slack
        3. Every machine info will be posted as separate message
    .Example
        (get-vm | ? powerstate -match on | ? name -match centos | get-vmguest | select @{n="IPAddress";e={$_.IPAddress -like "10.10.20.*"}}).ipaddress | new-sshsession
        Get-SshSession | Invoke-SshCommand -command {hostname; df -h} | out-string | Send-slackMessage -channel "#test"
        Same as previous example, but all text will be posted as single message
    .Example
        gskusrs | ? name -match name | startskim | sskmsg -text "text"
        Send private message
    .Example
        Get-ZabbixAlert | ? sendto -match yubu | select @{n="Time(UTC+1)";e={(convertfrom-epoch $_.clock).addhours(1)}},alertid,subject | Out-String | sskmsg -channel "#BlackFriday"
        Get Zabbix alerts for last 5 hours (default) and post to slack
    #>

    [CmdletBinding()]
    [Alias("sskmsg")]
    Param (
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channel,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)][string]$text,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$username,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$emoji,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$parse="full",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$attachments,

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="chat.postMessage"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

		$boundparams=$PSBoundParameters | out-string
		write-verbose "($boundparams)"
            
        $Body = @{
            token = $token
            channel = $channel
            username = $username
            text = $text
            icon_emoji = $emoji
            unfurl_links = "true"
            unfurl_media = "true"
            as_user = "true"
            parse = "true"
            attachments = $attachments
        }
    
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        $a    
    }
}

function Send-slackMessageAsBot {
    <# 
    .Synopsis
        Post messages as bot
    .Description
        Post messages as a bot. All users in the chanel will get notification 
    .Example
        Send-slackMessageAsBot -text "Post text to slack" -channel "#test" -username alertBot -emoji ":thumbsup:"
        Post slack message as a bot, named alertBot
    .Example
        sskmsgab -channel "#BlackFriday" -text (gc c:\errors.log | out-string) -username alertBot -emoji ":exclamation:"
        Post message as a bot
    .Example
        Get-Clipboard | out-string | Send-slackMessageAsBot -channel "#test" -username systemAlertBot
        Paste and send the message as a bot, named systemAlertBot
    .Example
        (get-vm | ? powerstate -match on | ? name -match centos | get-vmguest | select @{n="IPAddress";e={$_.IPAddress -like "10.10.20.*"}}).ipaddress | new-sshsession
        Get-SshSession | Invoke-SshCommand -command {hostname; df -h} | oss | Send-slackMessageAsBot -channel "#alerts" alertBot -emoji ":exclamation:"
        1. Connect to multiple Linux boxes, using VMware PowerCLI and SSH module
        2. Get disk information from all machines and post to slack
        3. Every machine info will be posted as separate message
    .Example
        (get-vm | ? powerstate -match on | ? name -match centos | get-vmguest | select @{n="IPAddress";e={$_.IPAddress -like "10.10.20.*"}}).ipaddress | new-sshsession
        Get-SshSession | Invoke-SshCommand -command {hostname; dstat -lvn 1 2} | out-string | Send-slackMessageAsBot -channel "#BlackFriday" -user alertBot -emoji ":exclamation:"
        Same as previous example, but all text will be posted as single message
    .Example
        Get-ZabbixAlert | ? sendto -match user | select @{n="Time(UTC+1)";e={(convertfrom-epoch $_.clock).addhours(1)}},alertid,subject | Out-String | sskmsgab -channel "#BlackFriday" alertBot -emoji ":boom:"
        Get Zabbix alerts for last 5 hours (default) and post to slack
    #>

    [CmdletBinding()]
    [Alias("sskmsgab")]
    Param (
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channel,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)][string]$text,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$username,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$emoji,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$parse="full",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$attachments,

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="chat.postMessage"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"
            
        $Body = @{
            token = $token
            channel = $channel
            username = $username
            text = $text
            icon_emoji = $emoji
            unfurl_links = "true"
            unfurl_media = "true"
            as_user = "false"
            parse = "true"
            attachments = $attachments
        }
    
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        $a    
    }
}

function Set-slackMessage {
    <# 
    .Synopsis
        Edit slack messages
    .Description
        Edit slack messages
    .Example
        Search-slack -query "query" | select -ExpandProperty messages | select -ExpandProperty matches | Set-slackMessage -text "New message here" -channel {$_.channel.id}
        Will replace existing message text with new one, in every occurrence
    .Example
        Search-slack -query "query" | select -ExpandProperty messages | select -ExpandProperty matches  | ? channel -match test | Set-slackMessage -text "EDIT MESSAGE" -channel {$_.channel.id}
        Will replace messages by query and in channel by match
    .Example
        Search-slack -query "query" | select -ExpandProperty messages | select -ExpandProperty matches  | ? channel -match test | select -skip 1 | Set-slackMessage -text {"$($_.text) Additional text"} -channel {$_.channel.id}
        Will edit message by appending new text to existing one
    #>

    [CmdletBinding()]
    [Alias("Edit-slackMessage","editskmsg")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channel,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$ts,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$parse="full",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$link_names=1,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$text,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$as_user="true",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="chat.update"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            # "channel": "@username".
            token = $token
            channel = $channel
            ts = $ts
            text = $text
            parse = $parse
            link_numbers = $link_numbers
            as_user = $as_user
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        $a
    }
}

function Remove-slackMessage {
    <# 
    .Synopsis
        Delete messages from slack
    .Description
        Delete messages from slack
    .Example
        Get-slackChannels | ? name -match test | Get-slackChannelsHistory | ? text -match hello | rmskmsg -id (Get-slackChannels | ? name -match test).id
        Delete messages from the channel by text match
    .Example
        Get-slackChannels | ? name -match test | delskmsg -ts (Get-slackChannels | ? name -match test | gskchhist | ? text -match "hello" | select -first 1).ts
        Delete messages from channel #test. Will delete only one message
    #>

    [CmdletBinding()]
    [Alias("Delete-slackMessage","delskmsg","rmskmsg")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$ts,

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="chat.delete"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
            ts = $ts
            as_user = "true"
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        $a
    }    
}

function Get-slackEmoji {
    <# 
    .Synopsis
        Get emoji list from slack
    .Description
        Get emoji list from slack
    .Example
        gskemoji
        Get slack emoji list
    .Example
        chrome --incognito http://www.emoji-cheat-sheet.com/
        chrome --incognito http://www.webpagefx.com/tools/emoji-cheat-sheet/
        Get emoji cheat sheet
    #>

    [CmdletBinding()]
    [Alias("gskemoji")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="emoji.list"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process { 
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        $a.emoji
    }    
}

function Search-slack {
    <# 
    .Synopsis
        Search slack messages and files
    .Description
        Search slack messages and files
    .Example
        Search-slack -query "powershell"
        Search slack 
    .Example
        Search-slack -query "powershell" | select @{n="MsgTotal"; e={$_.messages.total}}, @{n="FilesTotal";e={$_.files.total}},@{n="PostsTotal";e={$_.posts.total}}
        Get total messages, files and posts for query
    .Example
        Search-slack -query "powershell" | select -ExpandProperty files | select -ExpandProperty matches | ft -a
        Search slack files
    .Example
        Search-slack -query "powershell" | select -ExpandProperty messages | select -ExpandProperty matches | ft -a
        Search slack messages 
    .Example
        Search-slack -query "powershell" | select -ExpandProperty files | select -ExpandProperty matches | select @{n="created";e={convertfrom-epoch $_.created}},name,title,url_private_download 
        Search slack files
    .Example
        Search-slack -query "powershell" | select -ExpandProperty posts | select -ExpandProperty matches | ft -a
        Search posts
    .Example
        Search-slack -query "powershell" | select -ExpandProperty messages | select -ExpandProperty matches | ? channel -match test | select text,@{n="PrevText";e={$_.previous.text}} | fl *
        View edited messages previous version, if exist
    #>

    [CmdletBinding()]
    [Alias("ssk")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$sort_dir,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$query,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$count="1000",
        
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="search.all"
    )
    
   begin {if (!(Test-slackAuthToken)) {break}}

   process {
    
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            query = $query
            sort = "timestamp"
            sort_dir = $sort_dir
            count = $count
            highlight = "1"
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        $a
   }   
}

function Get-slackPins {
    <# 
    .Synopsis
        Get pinned items for channel
    .Description
        Get pinned items for channel
    .Example
        Get-slackChannels | ? name -match "" | Get-slackPins
        Get pinned messages for channels
    .Example
        gskch | ? name -match "" | gskpins | select @{n="channel";e={(gskch | ? id -Match $_.channel).name}} -ExpandProperty message
        Get pinned messages for channels
    #>

    [CmdletBinding()]
    [Alias("gskpins")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$ID,

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="pins.list"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $ID
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.items} else {$a}
    }  
}

function Set-slackPins {
    <# 
    .Synopsis
        Pin item to channel
    .Description
        Pin item to channel
    .Example
        Search-slack -query "Some text" | select -ExpandProperty messages | select -ExpandProperty matches | select -first 1 | Set-slackPins -channel {$_.channel.id}
        Pin message to channel
    .Example
        gskch | ? name -match "" | gskpins | select @{n="channel";e={(gskch | ? id -Match $_.channel).name}} -ExpandProperty message
        Get pinned messages for channels
    #>

    [CmdletBinding()]
    [Alias("sskpins")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channel,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$file,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$ts,

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="pins.add"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $channel
            file = $file
            timestamp = $ts
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.items} else {$a}
    }  
}

function Remove-slackPins {
    <# 
    .Synopsis
        Remove pin from item
    .Description
        Remove pin from item
    .Example
        Get-slackChannels | ? name -match "" | Get-slackPins | select channel -ExpandProperty message | Remove-slackPins
        Unpin message
    #>

    [CmdletBinding()]
    [Alias("Delete-slackPins")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channel,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$file,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$ts,

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="pins.remove"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $channel
            file = $file
            timestamp = $ts
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}
    }  
}

function Get-slackChannels {
    <# 
    .Synopsis
        Get slack channels
    .Description
        Get slack channels
    .Parameter exclude_archived
        exclude_archived=1 is default, Set to 0, to include also archived in list
    .Example
        Get-slackChannels | select id,name,num_members | sort num_members -desc
        Get list of channels and their members count
    .Example
        gskch | select id,name,@{n="created";e={(convertFrom-epoch $_.created).addhours(-5)}},@{n="creator";e={(gskusrs | ? id -eq $_.creator).name}},num_members | sort created -desc | ft -a
        Get list of channels, display time in UTC-5
    .Example
        gskch -exclude_archived 0 | ? is_archived | select id,name,@{n="created";e={(convertFrom-epoch $_.created).addhours(-5)}}
        Get archived channels
    .Example
        Get-slackChannel | ? name -match chanelName
        Get channels by name match
    .Example
        gskch | select id,name,num_members
        Get channels
    .Example
        gskch | ? name -match channelName | gskpins
        Get pinned messages for channel
    #>

    [CmdletBinding()]
    [Alias("gskch")]
    Param (
        $exclude_archived=1,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="channels.list"
    )
		
    begin {if (!(Test-slackAuthToken)) {break}}

    process { 

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            exclude_archived = $exclude_archived
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.channels} else {$a}    
    }
}

function Get-slackChannelsInfo {
    <# 
    .Synopsis
        Get slack channel info
    .Description
        Get slack channel info
    .Example
        Get-slackChannels | ? name -match "" | Get-slackChannelsInfo
        Get channel info
    .Example
        Get-slackChannels | ? name -match "" | Get-slackChannelsInfo | select id,name -ExpandProperty latest -ea silent
        Get latest post in channel
    .Example
        Get-slackChannels | ? name -match "channelName" | Get-slackChannelsInfo | select -ExpandProperty members | select @{n="Members";e={(gskusrs | ? id -match $_)}} | select -ExpandProperty members | select id,team_id,name,real_name,presence,is_admin,is_owner | sort name | ft -a
        Get channel members
    .Example
        Get-slackChannels | ? name -match "" | Get-slackChannelsInfo | select id,name,@{n='creator';e={(gskusrs | ? id -match $_.creator).name}},@{n="created";e={convertfrom-epoch $_.created}} | sort creator | ft -a
        Get channels creation info
    #>

    [CmdletBinding()]
    [Alias("gskchi")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="channels.info"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process { 
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.channel} else {$a}    
    }
}

function New-slackChannels {
    <# 
    .Synopsis
        Join slack channel. If the channel does not exist, it will be created
    .Description
        Join slack channel. If the channel does not exist, it will be created
    .Example
        New-slackChannels -name New-Channel
        Join slack channel. If the channel does not exist, it will be created
    .Example
        joinskch -name channelName
        Join slack channel. If the channel does not exist, it will be created
    #>
    
    [CmdletBinding()]
    [Alias("Join-slackChannel","joinskch")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$name,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="channels.join"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process { 
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            name = $name
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.channel} else {$a}     
    }
}

function Rename-slackChannels {
    <# 
    .Synopsis
        Rename slack channel
    .Description
        Rename slack channel
    .Example
        Get-slackChannels | ? name -match "currentChannelName" | Rename-slackChannels -name "newChannelName"
        Rename slack channel
    #>

    [CmdletBinding()]
    [Alias("renskch")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$name,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="channels.rename"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process { 
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
            name = $name
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.channel} else {$a}    
    }
}

function Set-slackChannelsArchive {
    <# 
    .Synopsis
        Archive slack channels
    .Description
        Archive slack channels
    .Example
        Get-slackChannels | ? name -match "currentChannelName" | Set-slackChannelsArchive 
        Archive slack channels
    #>

    [CmdletBinding()]
    [Alias("Archive-slackChannels","arcskch")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$name,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="channels.archive"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process { 
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
            name = $name
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}    
    }
}

function Set-slackChannelsUnArchive {
    <# 
    .Synopsis
        Unarchive slack channels
    .Description
        Unarchive slack channels
    .Example
        Get-slackChannels -exclude_archived 0 |  ? name -match "channelName" | UnArchive-slackChannels
        Unarchive slack channels
    #>

    [CmdletBinding()]
    [Alias("UnArchive-slackChannels","unarcskch")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$name,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="channels.unarchive"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process { 
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
            name = $name
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}    
    }
}


function Set-slackChannelsInvite {
    <# 
    .Synopsis
        Invite user to channels
    .Description
        Invite user to channels
    .Example
        Get-slackChannels | ? name -match channelName | Set-slackChannelsInvite -userid (Get-slackUsers | ? name -match username).id
        Set/Invite user to slack channel.
    #>
    
    [CmdletBinding()]
    [Alias("InviteTo-slackChannel","skchinvite")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$userid,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="channels.invite"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process { 
        
       if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return} 
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
            user = $userid
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.channel} else {$a}   
    }
}

function Get-slackChannelsHistory {
    <# 
    .Synopsis
        Get channel history
    .Description
        Get channel history
    .Example
        Get-slackChannels | ? name -match channelName | gskchhist
        Get channel history
    .Example
        Get-slackChannels | ? name -match channelName | gskchhist | ? text -match "text1|text2"
        Get messages for channel
    .Example
        Get-slackChannels | ? name -match channelName | gskchhist | select username,bot_id,type,text
        Get messages from the channel
    .Example
        Get-slackChannels | ? name -match "" | gskchhist -oldest (convertto-epoch (((get-date).AddDays(-5)).ToUniversalTime())) | ? type -Match "message" | ? subtype -NotMatch "channel_join|channel_leave" | select @{n='time';e={(convertfrom-epoch ($_.ts.split('.')[0])).addhours(+1)}},user,@{n="name";e={(gskusrs | ? id -match $_.user).name}},text | ? name -match ""    
        Get messages, where oldest message was 5 hours ago. Display time UTC+1
    .Example
        Get-slackChannels | ? name -match channelName | gskchhist | select @{n='time';e={(convertfrom-epoch ($_.ts.split('.')[0])).addhours(+3)}},@{n="name";e={(gskusrs | ? id -match $_.user).name}},text | ft -a
        Get messages for the channel 
    .Example
        gskch | ? name -match channelName | gskchhist -oldest (convertto-epoch (((get-date).AddDays(-360)).ToUniversalTime())) | ? subtype -notmatch channel_join | ft -a @{n='time';e={(convertfrom-epoch ($_.ts.split('.')[0])).addhours(+1)}},@{n="name";e={(gskusrs | ? id -match $_.user).name}},text
        Get messages for channel from 360 days ago till now, sorted by time descending. Display time UTC+1   
    #>

    [CmdletBinding()]
    [Alias("gskchhist")]
    Param (
        # [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channel,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$latest,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$oldest,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$inclusive=1,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$count="1000",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$unreads,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="channels.history"
    )
    
   begin {if (!(Test-slackAuthToken)) {break}}

   process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return} 

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            # channel = $channel
            channel = $id
            latest = $latest
            oldest = $oldest
            count = $MaximumAliasCount
            unreads	= $unreads
            inclusive = $inclusive
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.messages} else {$a} 
   }   
}

function Get-slackUsers {
    <# 
    .Synopsis
        Get slack users
    .Description
        Get slack users
    .Example
        Get-slackUsers | select id,name,status,real_name,is_admin,is_bot,presence | ft -a
        Get users
    .Example
        gskusrs | ? presence -match active | select id,name,status,real_name,is_admin,is_bot,presence | ft -a
        Get users, who are online
    .Example
        gskusrs | select name -ExpandProperty profile
        Get user name and profile
    .Example
        gskusrs | select id,name,status,real_name,is_admin,is_bot,presence,@{n="mail";e={$_.profile.email}} | ft -a
        Get users
    #>

    [CmdletBinding()]
    [Alias("gskusrs")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$presence="1",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="users.list"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            presence = $presence
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.members} else {$a} 
   }
}



function Get-slackTeamDND {
        <# 
    .Synopsis
        Get DND status for users on a team
    .Description
        Get DND status for users on a team
    .Example
        Get-slackTeamDND | fl *
        Get DND status for users on a team
        #>

    [CmdletBinding()]
    [Alias("gskteamdnd")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="dnd.teamInfo"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {
        
        # if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            users = $id
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.users} else {$a} 
   }
}

function Get-slackUserDND {
    <# 
    .Synopsis
        Get user DND info
    .Description
        Get user DND info
    .Example
        Get-slackUsers | ? name -match userName | Get-slackUserDND
        Get user DND status
    .Example
        Get-slackUserDND -id (gskusrs | ? name -match userName).id
        Get user DND status
    #>
    
    [CmdletBinding()]
    [Alias("gskusrdnd")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="dnd.info"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            user = $id
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        $a
   }
}


function Get-slackUsersPresence {
    <# 
    .Synopsis
        Get users presence
    .Description
        Get users presence
    .Example
        Get-slackUsersPresence user.name
        Get user presence
    .Example
        Get-slackUsers | ? name -match user | Get-slackUsersPresence
        Get user presence
    .Example
        gskusrs | select id,name,status,real_name,is_admin,is_bot,presence,@{n="mail";e={$_.profile.email}} | ft -a
        Get user presence
    #>

    [CmdletBinding()]
    [Alias("gskusrpres")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="users.getPresence"
    )
    
   begin {if (!(Test-slackAuthToken)) {break}}

   process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            user = $id
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a} 
   }
}

function Get-slackUsersIdentity {
    <# 
    .Synopsis
        Get users identity
    .Description
        Get users identity
    .Example
        Get-slackUsersIdentity
        Get user identity
    #>

    [CmdletBinding()]
    [Alias("gskusrid")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackTokenIdentity,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="users.identity"
    )
    
   begin {
       if (!(Test-slackAuthToken)) {break}
       elseif (!$global:slackTokenIdentity) {write-host "`nERROR: slackTokenIdentity not exist. You need token with identity.basic scope. Look here for details: https://api.slack.com/scopes`n" -f red; break} 
    }

   process {
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        # $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Get -ContentType "application/x-www-form-urlencoded"
        if ($a.ok) {$a.user} else {$a}
   }
}

function Get-slackFiles {
    <# 
    .Synopsis
        Get file list
    .Description
        Get file list
    .Example
        Get-slackFiles -types pdfs | select id,@{n="created";e={(convertFrom-epoch $_.created).addhours(+1)}},filetype,name | ft -a
        Get .pdf files (file creation time in UTC+1)
    .Example
        Get-slackFiles | select id,@{n="created";e={(convertFrom-epoch $_.created).addhours(+1)}},name,title,filetype | ft -a
        Get files (file creation time in UTC+1)
    .Example
        Get-slackFiles -channelid (Get-slackChannels | ? name -match channelName).id -count 3 -page 2 | select id,name,paging
        Get files (file creation time in UTC+1), from channel by channel name. Pull every 3 files and display page 2 (files from 4 to 6) 
    .Example
        Get-slackFiles | select id,@{n="created";e={(convertFrom-epoch $_.created).addhours(+1)}},@{n="createdBy";e={(gskusrs | ? id -eq $_.user).name}},@{n="inChanel";e={(gskch | ? id -eq $_.channels).name}},title,name,filetype,size | ft -a
        Get files (file creation time in UTC+1)
    .Example
        gskfiles -channelid (Get-slackChannels | ? name -match channelName).id -ts_from (convertTo-epoch ((get-date).AddDays(-50))) -Verbose | select id,name,@{n="created";e={(convertFrom-epoch $_.created).addhours(+1)}},paging
        Get files from 50 days ago from the certain channel (file creation time in UTC+1)
    .Example
        gskfiles | ? name -match errors | select preview  | fl *
        Preview content of the files
    .Example
        gskfiles | ? filetype -match "text" | ? name -match errors.log | select preview | fl * 
        Preview content of the files
    #>

    [CmdletBinding()]
    [Alias("gskfiles")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$queryparams="",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$userid,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channelid,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$page,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$ts_from,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$ts_to,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$count,
        # all - All files; spaces - Posts; snippets - Snippets; images - Image files; gdocs - Google docs; zips - Zip files; pdfs - PDF files
        # https://api.slack.com/types/file#file_types
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][ValidateSet('all','spaces','snippets','images','gdocs','zips','pdfs')][string]$types,
        
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="files.list"
    )
    
   begin {if (!(Test-slackAuthToken)) {break}}

   process {
    
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
        }
        
        $queryparams="?token=$token"
        if ($userid) {$queryparams+="`&user=$userid"}
        if ($channelid) {$queryparams+="`&channel=$channelid"}
        if ($ts_from) {$queryparams+="`&ts_from=$ts_from"}
        if ($ts_to) {$queryparams+="`&ts_to=$ts_to"}
        if ($count) {$queryparams+="`&count=$count"}
        if ($types) {$queryparams+="`&types=$types"}
        if ($page) {$queryparams+="`&page=$page"}
        $queryparams+='&pretty=1'

        write-verbose "Body: $($body | ConvertTo-Json)"
        write-verbose "QueryParams: $queryparams"
        write-verbose "URL: $URL/$method$queryparams -Method Get"

        $a = Invoke-RestMethod "$URL/$method$queryparams" -Body $Body -Method Get -ContentType "application/x-www-form-urlencoded"
        if ($a.ok) {$a | select paging -ExpandProperty files } else {$a}
   }   
}

function Get-slackFilesInfo {
    <#
    .Synopsis
        Get file list
    .Description
        Get file list
    .Example
        Get-slackFiles | ? name -match "txt" | select -first 3 | Get-slackFilesInfo | select id,created,name,title,filetype,size,lines,content,comments | ft -a
        Get files detailed info
    .Example
        Get-slackFiles | ? filetype -match "pdf|txt" | select -first 3 | Get-slackFilesInfo | select id,@{n="created";e={(convertFrom-epoch $_.created).addhours(+1)}},name,title,filetype,size,lines,content,comments
        Get files detailed info, time in UTC+1
    .Example
        Get-slackFiles | Get-slackFilesInfo | select id,@{n="created";e={(convertFrom-epoch $_.created).addhours(+1)}},name,content
        Get files detailed info, time in UTC+1
    #>

    [CmdletBinding()]
    [Alias("gskfilesinfo")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$page,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$count="1000",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="files.info"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {
    
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            file = $id
            page = $page
            count = $count
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Get -ContentType "application/x-www-form-urlencoded"
        if ($a.ok) {$a.file} else {$a}
   }   
}

function Send-slackFiles {
    <# 
    .Synopsis
        Upload file content
    .Description
        Upload file content
    .Example
        Send-slackFiles -content (gc c:\errors.log | out-string) -channels "#test" -filename errors.log -filetype text -title Cluster1
        Send content of text file
    .Example
        Get-slackChannels | ? name -match slackChannel | Send-slackFiles -content (gc C:\errors.log -Raw) -filename errors.log -filetype text -title Cluster1
        Send content of text file
    .Example
        gskch | ? name -match "channel1|channel2" | Send-slackFiles -content (gc C:\errors.log -Raw) -filename errors.log -filetype text 
        Send content of file to multiple channels
    .Example
        Send-slackFiles -content (Get-Clipboard | out-string) -channels "#test" -filename errors.log -filetype text -title "URGENT"
        Send text from clipboard
    #>
    
    [CmdletBinding()]
    [Alias("sskfile","upskfile","Upload-slackFiles")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$file,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$filePath,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$content,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$filename,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$title,
        # all - All files; spaces - Posts; snippets - Snippets; images - Image files; gdocs - Google docs; zips - Zip files; pdfs - PDF files
        # https://api.slack.com/types/file#file_types
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][ValidateSet('all','spaces','snippets','images','gdocs','zips','pdfs')][string]$filetype,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$initial_comment,
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channels,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="files.upload"
    )
    
   begin {if (!(Test-slackAuthToken)) {break}}

   process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        if (!$filePath) {
            $Body = @{
                token = $token
                content = $content
                file = $file
                filename = $filename
                filetype = $filetype
                title = $title
                initial_comment = $initial_comment
                channels = $channels
            }
        }
        elseif ($filePath) {
            $queryparams="?token=$token"
            if ($file) {$queryparams+="`&user=$file"}
            if ($channels) {$queryparams+="`&channels=$channels"}
            if ($filename) {$queryparams+="`&filename=$filename"}
            if ($filetype) {$queryparams+="`&filetype=$filetype"}
            if ($initial_comment) {$queryparams+="`&initial_comment=$initial_comment"}
            if ($title) {$queryparams+="`&title=$title"}
            # if ($page) {$queryparams+="`&page=$page"}
            $queryparams+='&pretty=1'
        }
        
        if ($body) {write-verbose ($body | ConvertTo-Json)}

        if (!$filePath) {$a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post -ContentType "application/x-www-form-urlencoded"}
        elseif ($filePath) {$a = Invoke-RestMethod "$URL/$method$queryparams" -Method Post -ContentType "multipart/form-data" -InFile $filePath}
        
        if ($a.ok) {$a.file} else {$a}
   }   
}

function Send-slackFilesCurl {
    <# 
    .Synopsis
        Upload files with curl.exe
    .Description
        Upload files with curl.exe
    .Example
        Send-slackFilesCurl -channels "#test" -file C:\graph-2222.png
        Send file, using curl.exe (https://curl.haxx.se/download.html)
    .Example
        Send-slackFilesCurl -channels "#test" -file C:\graph.png -filename graph.png -filetype auto -title Zabbix -verbose
        Send file, using curl.exe  (https://curl.haxx.se/download.html)
    .Example
        dir C:\books\*.pdf | Send-slackFilesCurl -channels "#books" -filetype pdfs
        Upload .pdf files to slack
    .Example
        Get-ZabbixHost | ? name -match "server" | Get-ZabbixGraph | ? name -match 'CPU utilization' | Save-ZabbixGraph -verbose -show
        Send-slackFilesCurl -channels "#BlackFriday" -file C:\graph-1111.png
        Save graph from Zabbix and post it to the slack  
    #>

    [CmdletBinding()]
    [Alias("sskfileCurl","upskfileCurl","Upload-slackFilesCurl")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline,ValueFromPipelineByPropertyName=$true)][string]$file,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$filename,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$title,
        # all - All files; spaces - Posts; snippets - Snippets; images - Image files; gdocs - Google docs; zips - Zip files; pdfs - PDF files
        # https://api.slack.com/types/file#file_types
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string][ValidateSet('all','spaces','snippets','images','gdocs','zips','pdfs')]$filetype,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$initial_comment,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channels,
        
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="files.upload"
    )
    
   begin {if (!(Test-slackAuthToken)) {break}}

   process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        if (!((gcm curl).name).contains("exe")) {write-host "`nCan't run the command. Need curl.exe in the path. Download from here: https://curl.haxx.se/download.html`n" -f red ; return}
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"
        
        $a = curl -F file=@$file -F channels=$channels -F token=$token  -F filename=$filename -F filetype=$filetype -F title=$title -F initial_comment=$initial_comment "$URL/$method" --insecure -s
        if (($a | ConvertFrom-Json).ok) {($a | ConvertFrom-Json).file} else {($a | ConvertFrom-Json)}
   }   
}

function Save-slackFiles {
    <# 
   .Synopsis
       Download files
   .Description
       Download files
   .Example
       Save-slackFiles -url_private_download url_private_download -name c:\temp\file.pdf
       Download file
   .Example
       Get-slackFiles -types pdfs | ? name -match name | Save-slackFiles
       Download files to the current dir
   #>
   [CmdletBinding()]
   [Alias("saveskfiles","downskfiles","Download-slackFiles")]
   Param (
       [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$url_private_download,
       [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$public_url_shared,
       [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$is_public,
       [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$name,
       [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken
   )

   begin {if (!(Test-slackAuthToken)) {break}}

   process {
       
       if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}
       if (!$name) {Write-Host "`nERROR: Missing parameters. Provide -name (filename/path to save the file)`n" -f red; return} 
       if (!((gcm curl).name).contains("exe")) {write-host "`nCan't run the command. Need curl.exe in the path. Download from here: https://curl.haxx.se/download.html`n" -f red ; return}
       
       $boundparams=$PSBoundParameters | out-string
       write-verbose "($boundparams)"
       
       Invoke-WebRequest -Headers @{"Authorization"="Bearer $token"} -URI $url_private_download -OutFile $name
  }
}

function Save-slackFilesCurl {
     <# 
    .Synopsis
        Download files with curl.exe
    .Description
        Download files with curl.exe
    .Example
        Get-slackFilesCurl -url_private_download url_private_download
        Download file to current dir, using curl.exe (https://curl.haxx.se/download.html)
    .Example
        gskfiles -filetype pdfs | ? name -match fileName | Get-slackFilesCurl
        Download files to current dir, using curl.exe (https://curl.haxx.se/download.html)
    #>
    [CmdletBinding()]
    [Alias("saveskfilesCurl","downskfilesCurl","Download-slackFilesCurl")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$url_private_download,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$public_url_shared,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$is_public,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken
        # [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        # [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="files.upload"
    )

    begin {if (!(Test-slackAuthToken)) {break}}

    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        if (!((gcm curl).name).contains("exe")) {write-host "`nCan't run the command. Need curl.exe in the path. Download from here: https://curl.haxx.se/download.html`n" -f red ; return}
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"
        
        curl.exe -H "Authorization: Bearer $token" -L -C - -J -O "$url_private_download"
   }
}

function Set-slackFilesPublic {
    <# 
    .Synopsis
        Make files public
    .Description
        Make files public
    .Example
        Get-slackFiles | ? name -match name | select -first 2 | Set-slackFilesPublic
        Set file publicly available (permalink)
    .Example
        gskfiles | ? name -match name | sskfilepub
        Make file publicly available (permalink)
    #>

    [CmdletBinding()]
    [Alias("sskfilepub")]
    Param (
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$file,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="files.sharedPublicURL"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"
        
        $Body = @{
            token = $token
            file = $file
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.file | select name,public_url_shared,permalink_public} else {$a} 
   }   
}

function Set-slackFilesPrivate {
    <# 
    .Synopsis
        Make files private
    .Description
        Make files private
    .Example
        Get-slackFiles | ? name -match errors.log | select -first 1 | Set-slackFilesPrivate
        Set public files private
    #>
    
    [CmdletBinding()]
    [Alias("sskfileprv")]
    Param (
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$file,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="files.revokePublicURL"
    )

    begin {if (!(Test-slackAuthToken)) {break}}

    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            file = $file
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.file | select name,public_url_shared,permalink_public} else {$a} 
   }   
}


function Remove-slackFiles {
    <# 
    .Synopsis
        Remove files
    .Description
        Remove files
    .Example
        Get-slackFiles | ? name -match "-.txt" | Remove-slackFiles
        Delete files
    .Example
        gskfiles | ? name -match "name" | delskfiles
        Delete files
    .Example
        gskfiles -filetype pdfs | ? name -match name | Remove-slackFiles
        Delete files
    #>
    
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
    [Alias("Delete-slackFiles","delskfiles","rmskfiles")]
    Param (
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$file,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$name,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="files.delete"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"
             
        $Body = @{
            token = $token
            file = $file
        }
            
        write-verbose ($body | ConvertTo-Json)

        if ([bool]$WhatIfPreference.IsPresent) {}
        if ($PSCmdlet.ShouldProcess("$file`: $name","Remove file(s)")) {     
            $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        }
        
        if ($a.ok) {$a} else {$a}
   }   
}

function Get-slackReactionsFile {
    <# 
    .Synopsis
        Get reactions for a file
    .Description
        Get reactions for a file
    .Example
        Get-slackFiles | get-slackReactionsFile | ? reactions | select @{n="fileName";e={$_.name}},filetype,size -ExpandProperty reactions  | ft -a
        Get reactions for the files
    .Example
        gskfiles | ? name -match errors | get-slackReactionsFile | ? reactions | select @{n="fileName";e={$_.name}},filetype,size -ExpandProperty reactions  | ft -a
        Get reactions for the files
    #>

    [CmdletBinding()]
    [Alias("gskimhist")]
    Param (
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$file,
        # [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channel,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$timestamp,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$full="true",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="reactions.get"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"
    
        $Body = @{
            token = $token
            # channel = $channel
            file = $file
            full = $full
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.file} else {$a}  
        # if ($a.ok) {$a.file.reactions.name} else {$a}  
   }   
}

function Get-slackReactionsUser {
    <# 
    .Synopsis
        Get reactions, created by user
    .Description
        Get reactions, created by user
    .Example
        Get-slackUsers | ? name -match user | Get-slackReactionsUser
        Get reactions
    .Example
        Get-slackUsers | ? name -match user | Get-slackReactionsUser | select file -Unique | select -ExpandProperty file | select @{n="filename";e={$_.name}},type,size -ExpandProperty reactions | ft -a
        Get reactions for files
    .Example
        Get-slackUsers | ? name -match user | Get-slackReactionsUser | select message -Unique | select -ExpandProperty message 
        Get user reactions for messages
    #>

    [CmdletBinding()]
    [Alias("gskimhist")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$page,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$count=1000,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$full="true",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="reactions.list"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"
    
        $Body = @{
            token = $token
            user = $id
            count = $count
            full = $full
            page = $page
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.Items} else {$a}  
        $a
   }   
}

function Set-slackReactionsFile {
    <# 
    .Synopsis
        Set reactions for the files
    .Description
        Set reactions for the files
    .Example
        Get-slackFiles | ? title -match cluster1 | Set-slackReactionsFile -emojiname "boom"
        Set reactions for the files
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$emojiName,
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$file,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$full="true",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="reactions.add"
    )
    
   begin {if (!(Test-slackAuthToken)) {break}}

   process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            file = $file
            name = $emojiName
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

function Remove-slackReactionsFile {
    <# 
    .Synopsis
        Remove reactions from the files
    .Description
        Remove reactions from the files
    .Example
        Get-slackFiles | ? title -match fileName | Remove-slackReactionsFile -emojiname "boom"
        Remove reactions from the files
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$emojiName,
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$file,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$full="true",

        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="reactions.remove"
    )
    
   begin {if (!(Test-slackAuthToken)) {break}}

   process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     
        
        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            file = $file
            name = $emojiName
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

function Get-slackBots {
    <# 
    .Synopsis
        Get bots
    .Description
        Get bots
    .Example
        Get-slackBots
        Test bots
    #>
    
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="bots.info"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
        }
            
        write-verbose ($body | ConvertTo-Json)
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Get -ContentType "application/x-www-form-urlencoded"
        $a
    }
}

function Get-slackGroups {
    <# 
    .Synopsis
        Get a list of all im channels that the user has
    .Description
        Get a list of all im channels that the user has
    .Example
        Get-slackGroups
        Get a list of all im channels that the user has
    #>

    [CmdletBinding()]
    [Alias("gskgrp")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.list"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Get -ContentType "application/x-www-form-urlencoded"
        if ($a.ok) {$a.groups} else {$a}  
   }   
}

function New-slackGroups {
    <# 
    .Synopsis
        Creates a new private channel
    .Description
        Creates a new private channel
    .Example
        New-slackGroups -name groupName
        Creates a new private channel
    #>

    [CmdletBinding()]
    [Alias("nskgrp")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$name,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$validate="$true",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.create"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            name = $name
            validate = $validate
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.group} else {$a}  
   }   
}

function New-slackGroupsInvite {
    <# 
    .Synopsis
        Invites a user to a private channel
    .Description
        Invites a user to a private channel
    .Example
        Get-slackUsers | ? name -match user | New-slackGroupsInvite -channel (Get-slackGroups | ? name -match groupName).id
        Invite user to private channel
    .Example
        gskusrs | ? name -match user | New-slackGroupsInvite -channel (gskgrp | ? name -match groupName).id
        Invite user to private channel
    #>

    [CmdletBinding()]
    # [Alias("invskusr")]
    Param (
		[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channel,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.invite"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $channel
            user = $id
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.group} else {$a}  
   }   
}

function Get-slackGroupsInfo {
    <# 
    .Synopsis
        Get information about a private channel
    .Description
        Get information about a private channel
    .Example
        Get-slackGroups | ? name -match groupName | Get-slackGroupsInfo
        Get information about a private channel
    #>

    [CmdletBinding()]
    [Alias("gskgrpInfo")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.info"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.group} else {$a}  
   }   
}

function Get-slackGroupsHistory {
    <# 
    .Synopsis
        Get messages/events from the specified private channel
    .Description
        Get messages/events from the specified private channel
    .Example
        Get-slackGroups | ? name -match slackGroup | Get-slackGroupsHistory
        Get private channel history
    .Example
        Get-slackGroups | ? name -match slackGroup | gskgrphist | ? text -match "text1|text2"
        Get group message history
    .Example
        Get-slackGroups | ? name -match "" | gskgrphist -oldest (convertto-epoch (((get-date).AddDays(-5)).ToUniversalTime())) | ? type -Match "message" | ? subtype -NotMatch "channel_join|channel_leave" | select @{n='time';e={(convertfrom-epoch ($_.ts.split('.')[0])).addhours(+1)}},user,@{n="name";e={(gskusrs | ? id -match $_.user).name}},text | ? name -match ""    
        Get messages for private channel, where oldest message was 5 hours ago, time in UTC+1
    .Example
        Get-slackGroups | ? name -match slackGroup | gskgrphist | select @{n='time';e={(convertfrom-epoch ($_.ts.split('.')[0])).addhours(+3)}},@{n="name";e={(gskusrs | ? id -match $_.user).name}},text | ft -a
        Get messages for private channel
    .Example
        gskgrp | ? name -match test | gskgrphist -oldest (convertto-epoch (((get-date).AddDays(-360)).ToUniversalTime())) | ? subtype -notmatch channel_join | ft -a @{n='time';e={(convertfrom-epoch ($_.ts.split('.')[0])).addhours(+1)}},@{n="name";e={(gskusrs | ? id -match $_.user).name}},text
        Get messages for group from 360 days ago till now, sorted by time descending, time in UTC+1   
    #>

    [CmdletBinding()]
    [Alias("gskgrphist")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$latest,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$oldest,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$inclusive=1,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$count="1000",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$unreads=1,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.history"
    )
    
   begin {if (!(Test-slackAuthToken)) {break}}

   process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return} 

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
            latest = $latest
            oldest = $oldest
            count = $count
            unreads	= $unreads
            inclusive = $inclusive
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.messages} else {$a} 
   }   
}

function Get-slackGroupsReplies {
    <#
    .Synopsis
        Rename private channel
    .Description
        Rename private channel
    .Example
        Get-slackGroups | ? name -match group | Get-slackGroupsReplies -name newName
        Rename private channel
    #>

    [CmdletBinding()]
    [Alias("gskgrprepl")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$name,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$thread_ts,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.replies"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
            name = $name
            thread_ts = $thread_ts
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.channel} else {$a}  
   }   
}

function Set-slackGroupsArchive {
    <# 
    .Synopsis
        Archive/Disconnect private channel
    .Description
        Archive/Disconnect private channel
    .Example
        get-slackGroups | ? name -match group | Remove-slackGroups
        Archive private channel
    #>

    [CmdletBinding()]
    [Alias("Archive-slackGroups","clskgrps")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.archive"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

function Open-slackGroups {
    <# 
    .Synopsis
        Open private channel
    .Description
        Open private channel
    .Example
        get-slackGroups | ? name -match group | Open-slackGroups
        Close private channel
    #>

    [CmdletBinding()]
    [Alias("Connect-slackGroup","opnsskgrp")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.open"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

function Set-slackGroupsPurpose {
    <# 
    .Synopsis
        Sets the purpose for a private channel
    .Description
        Sets the purpose for a private channel
    .Example
        Get-slackGroups | ? name -match group | Set-slackGroupsPurpose -purpose "The test private channel"
        Sets the purpose for a private channel
    #>

    [CmdletBinding()]
    [Alias("sgrppurp")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$purpose,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.setPurpose"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
            purpose = $purpose
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.purpose} else {$a}  
   }   
}

function Set-slackGroupsTopic {
    <#
    .Synopsis
        Sets the topic for a private channel
    .Description
        Sets the topic for a private channel
    .Example
        Get-slackGroups | ? name -match group | Set-slackGroupsTopic -topic "The topic fot the test private channel"
        Sets the topic for a private channel
    #>

    [CmdletBinding()]
    [Alias("sgrppurp")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$topic,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.setTopic"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
            topic = $topic
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.topic} else {$a}  
   }   
}

function Rename-slackGroups {
    <#
    .Synopsis
        Rename private channel
    .Description
        Rename private channel
    .Example
        Get-slackGroups | ? name -match group | Rename-slackGroups -name newName
        Rename private channel
    #>

    [CmdletBinding()]
    [Alias("rengrp")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$name,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.rename"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
            name = $name
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.channel} else {$a}  
   }   
}



function Disconnect-slackGroups {
    <# 
    .Synopsis
        Leave a private channel
    .Description
        Leave a private channel
    .Example
        get-slackGroups | ? name -match group | Disconnect-slackGroups
        Leave a private channel
    #>

    [CmdletBinding()]
    [Alias("Leave-slackGroups","rmgrp")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.leave"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

function Remove-slackGroupsUser {
    <# 
    .Synopsis
        Removes a user from a private channel
    .Description
        Removes a user from a private channel
    .Example
        Get-slackGroups | ? name -match group | Remove-slackGroups
        Removes a user from a private channel
    #>

    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
    [Alias("Kick-slackGroupsUser","rmgrpusr")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$channel,
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$user,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.kick"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $channel
            user = $id
        }
            
        write-verbose ($body | ConvertTo-Json)

        if ([bool]$WhatIfPreference.IsPresent) {}
        if ($PSCmdlet.ShouldProcess($id,"Remove user from private channel.")) { 
            $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        }

        if ($a.ok) {$a} else {$a}  
   }   
}

function Set-slackGroupsArchive {
    <#
    .Synopsis
        Archive a private channel
    .Description
        Archive a private channel
    .Example
        Get-slackGroups | ? name -match group | Set-slackGroupsArchive
        Archive a private channel
    #>

    [CmdletBinding()]
    [Alias("skgrpArch")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.archive"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

function Set-slackGroupsUnArchive {
    <#
    .Synopsis
        Unarchive a private channel
    .Description
        Unarchive a private channel
    .Example
        Get-slackGroups | ? name -match group | Set-slackGroupsUnArchive
        Unarchive a private channel
    #>

    [CmdletBinding()]
    [Alias("skgrpUnArch","UnArchive-slackGroups")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="groups.unarchive"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}

    process {

        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

Function Start-slackIM {
    <#
    .Synopsis
        Opens a direct message channel with another member of Slack team
    .Description
        Opens a direct message channel with another member of Slack team
    .Example
        Get-slackUsers | ? name -match user | Start-slackIM
        Open direct IM channel
    #>

    [CmdletBinding()]
    [Alias("startskim")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$user,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="im.open"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            user = $user
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

Function Get-slackIM {
    <# 
    .Synopsis
        Get a direct message channels
    .Description
        Get a direct message channels
    .Example
        Get-slackIM
        Get direct message channels
    .Example
        Get-slackIM | select id,@{n="user";e={(gskusrs | ? id -eq $_.user).name}},@{n="created";e={(convertFrom-epoch $_.created).addhours(1)}}
        Get direct message channels, time in UTC+1 
    .Example
        Get-slackIM | select id,@{n="user";e={(gskusrs | ? id -eq $_.user).name}} | ? user -match user | Send-slackMessage -text "Direct IM message"
        Send direct IM message
        #>

    [CmdletBinding()]
    [Alias("getskim")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="im.list"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        # if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.ims} else {$a}  
   }   
}


Function Stop-slackIM {
    <# 
    .Synopsis
        Close a direct message channel with another member of Slack team
    .Description
        Close a direct message channel with another member of Slack team
    .Example
        Get-slackIM | Stop-slackIM
        Close all IM channels
        #>

    [CmdletBinding()]
    [Alias("stopskim")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$channel,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="im.close"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $channel
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

function Get-slackIMHistory {
    <# 
    .Synopsis
        Get messages/events from the direct channel
    .Description
        Get messages/events from direct channel
    .Example
        Get-slackIM | ? name -match slackGroup | Get-slackIMHistory
        Get direct channel history
    .Example
        Get-slackIM | select id,@{n="user";e={(gskusrs | ? id -eq $_.user).name}} | Get-slackIMHistory | select type,@{n="user";e={(gskusrs | ? id -eq $_.user).name}},bot_id,@{n='time';e={(convertfrom-epoch ($_.ts).split(".")[0]).addhours(3)}},text | ft -a
        Get direct message history
    .Example
        Get-slackIM | select id,@{n="user";e={(gskusrs | ? id -eq $_.user).name}} | ? user -match user | Get-slackIMHistory | select type,@{n="user";e={(gskusrs | ? id -eq $_.user).name}},bot_id,@{n='time';e={(convertfrom-epoch ($_.ts).split(".")[0]).addhours(1)}},text | ft -a
        Get direct messages for the user, time in UTC+1
    .Example
        Get-slackIM | select id,@{n="user";e={(gskusrs | ? id -eq $_.user).name}} | Get-slackIMHistory | select type,@{n="user";e={(gskusrs | ? id -eq $_.user).name}},bot_id,@{n='time';e={(convertfrom-epoch ($_.ts).split(".")[0]).addhours(1)}},text | ? text -match "string1|string2"    
        Get direct messages for the user, time in UTC+1
        #>

    [CmdletBinding()]
    [Alias("gskimhist")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$id,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$latest,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$oldest,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$inclusive=1,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$count="1000",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$unreads=1,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="im.history"
    )
    
   begin {if (!(Test-slackAuthToken)) {break}}

   process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return} 

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            channel = $id
            latest = $latest
            oldest = $oldest
            count = $count
            unreads	= $unreads
            inclusive = $inclusive
        }
        
        write-verbose ($body | ConvertTo-Json)
        
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.messages} else {$a} 
   }   
}

Function Add-slackReminders {
    <# 
    .Synopsis
        Add reminders
    .Description
        Add reminders
    .Example
        Add-slackReminders -text "Eat banana" -time (convertto-epoch ((get-date).AddMinutes(25)).ToUniversalTime())
        Create reminder, time is UTC
    .Example
        Add-slackReminders -text "Eat banana" -time ((get-date -date "10/15/2016 15:48").ToUniversalTime() | convertTo-epoch)
        Add reminder, time is UTC
    .Example
        Get-slackUsers | ? name -match user | Add-slackReminders -text "Eat banana" -time (convertto-epoch ((get-date).AddHours(12)).ToUniversalTime())
        Create reminder for user, time is UTC
        #>

    [CmdletBinding()]
    [Alias("addskreminders")]
    Param (
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$user,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$text,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$time,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="reminders.add"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            text = $text
            time = $time
            user = $user
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.reminder} else {$a}  
   }   
}

Function Get-slackReminders {
    <# 
    .Synopsis
        Get reminders
    .Description
        Get reminders
    .Example
        Get-slackReminders | ft -a
        Get all reminders
    .Example
        Get-slackReminders | ? text -match text | ft -a
        Get reminders
    .Example
        Get-slackReminders | select id,@{n="creator";e={(gskusrs | ? id -eq $_.creator).name}},@{n="user";e={(gskusrs | ? id -eq $_.user).name}},recurring,@{n="time";e={(convertFrom-epoch $_.time).addhours(-5)}},@{n="complete";e={(convertFrom-epoch $_.complete_ts).addhours(-5)}},complete_ts,text | ft -a
        Get reminders, time in UTC-5
        #>

    [CmdletBinding()]
    [Alias("gskreminders")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="reminders.list"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        # if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.reminders} else {$a}  
   }   
}

Function Get-slackRemindersInfo {
    <# 
    .Synopsis
        Get reminders information
    .Description
        Get reminders information
    .Example
        Get-slackReminders | Get-slackRemindersInfo
        Get reminders information
    .Example
        Get-slackReminders | ? text -match banana | Get-slackRemindersInfo
        Get reminders information reminders
    #>

    [CmdletBinding()]
    [Alias("Delete-slackReminders","rmskreminders")]
    Param (
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$reminder,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="reminders.info"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            reminder = $reminder
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.reminder} else {$a}  
   }   
}

Function Remove-slackReminders {
    <# 
    .Synopsis
        Delete reminders
    .Description
        Delete reminders
    .Example
        Get-slackReminders | Remove-slackReminders
        Delete all reminders
    .Example
        Get-slackReminders | ? text -match banana | select -first 1 | Remove-slackReminders
        Delete reminders
    #>

    [CmdletBinding()]
    [Alias("Delete-slackReminders","rmskreminders")]
    Param (
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$reminder,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="reminders.delete"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            reminder = $reminder
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

Function Complete-slackReminders {
    <# 
    .Synopsis
        Complete reminders
    .Description
        Complete reminders
    .Example
        Get-slackReminders | Complete-slackReminders
        Complete all reminders
    .Example
        Get-slackReminders | ? text -match banana | select -first 1 | Complete-slackReminders
        Complete reminders
    #>

    [CmdletBinding()]
    [Alias("Delete-slackReminders","rmskreminders")]
    Param (
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$reminder,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="reminders.complete"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            reminder = $reminder
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

Function Get-slackTeamInfo {
        <# 
    .Synopsis
        Get team info
    .Description
        Get team info
    .Example
        Get-slackTeamInfo
        Get team info
    #>

    [CmdletBinding()]
    [Alias("gskteaminfo")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="team.info"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        # if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.team} else {$a}  
   }   
}

Function Get-slackTeamBillableInfo {
    <# 
    .Synopsis
        Get team billable info
    .Description
        Get team billable info
    .Example
        Get-slackTeamBillableInfo
        Get team billable info
    .Example
        Get-slackUsers | ? name -match user | Get-slackTeamBillableInfo
        Get user billable info
    #>

    [CmdletBinding()]
    [Alias("gskteambillinfo")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$user,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="team.billableInfo"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        # if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            user = $user
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.billable_info} else {$a}  
   }   
}

Function Get-slackTeamAccessLogs {
    <# 
    .Synopsis
        Get team access logs
    .Description
        Get team access logs
    .Example
        Get-slackTeamBillableInfo
        Get team access logs
    #>

    [CmdletBinding()]
    [Alias("gskteamacslogs")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$page,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$count="1000",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="team.accessLogs"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        # if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            user = $user
            page = $page
            count = $count
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

Function Get-slackTeamIntegrationLogs {
    <# 
    .Synopsis
        Get the integration logs for the current team
    .Description
        Get the integration logs for the current team
    .Example
        Get-slackTeamBIntegrationLogs
        Get the integration logs for the current team
    .Example
        Get-slackUsers | ? name -match user | Get-slackTeamIntegrationLogs
        Filter logs generated by this user's actions
    #>

    [CmdletBinding()]
    [Alias("gskteamIntLogs")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Alias("id")][Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$user,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$page,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$count="1000",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="team.integrationLogs"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            service_id = $service_id
            app_id = $app_id
            user = $user
            page = $page
            count = $count
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a} else {$a}  
   }   
}

Function Get-slackTeamProfile {
    <# 
    .Synopsis
        Get team's profile
    .Description
        Get team's profile
    .Example
        Get-slackTeamProfile
        Get team's profile
    .Example
        Get-slackTeamProfile
        Get team's profile
    #>

    [CmdletBinding()]
    [Alias("gskteamProf")]
    Param (
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$token=$global:slackToken,
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$visibility="all",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$URL="https://slack.com/api",
        [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$true)][string]$method="team.profile.get"
    )
    
    begin {if (!(Test-slackAuthToken)) {break}}
    
    process {
        
        # if (!$psboundparameters.count) {Get-Help -ex $PSCmdlet.MyInvocation.MyCommand.Name | out-string | Remove-EmptyLines; return}     

        $boundparams=$PSBoundParameters | out-string
        write-verbose "($boundparams)"

        $Body = @{
            token = $token
            visibility = $visibility
        }
            
        write-verbose ($body | ConvertTo-Json)
            
        $a = Invoke-RestMethod "$URL/$method" -Body $Body -Method Post
        if ($a.ok) {$a.profile.fields} else {$a}  
   }   
}
