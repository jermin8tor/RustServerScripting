##  REQUIRED VARIABLEs - edit below to match your environment
$ServiceName = 'TheNameOfYourService'
$GetService = Get-Service -Name $ServiceName
$ServerPath = "C:\PathToYourRustServer"
$UpdateLog = "C:\PathToSaveLogFiles\RustUpdates.log"
$Now = Get-Date
$DLSource = 'https://umod.org/games/rust/download?tag=public'
$DLDest = 'C:\PathToSaveOxideDownload\OxideUpdate_TEMP.zip'
$RustDedicatedData = 'C:\PathToYourRustServerROOT-DIRECTORY\RustDedicated_Data'
## This Variable is for parsing the UMod.Org RUST RSS Feed
$UModRSS = Invoke-WebRequest -Uri "https://umod.org/games/rust.rss" -UseBasicParsing -ContentType "application/xml"
If ($UModRSS.StatusCode -ne "200") {
    # Feed failed to respond.
    Write-Host "Message: $($UModRSS.StatusCode) $($UModRSS.StatusDescription) - Please confirm the URL for RSS Feeds is correct!"
	Break
}
$FeedXML = [xml]$UModRSS.Content
## OPTIONAL VARIABLES (for emailed results) - Remove the '#' before them and edit them to match your environment if they will be used
#$SendTo = Your@email.address
#$SendFrom = Someone@Somewhere.Something
#$Subject = "RUST Server UPDATED - Automated Script Results for $(Get-Date)"
#$emailserver = Your.Mail.Server
## BE SURE TO ALSO REMOVE THE '#' BLOCKING OUT THE SECTION OF CODE THAT TRIGGERS THE EMAIL AS WELL!

Start-Transcript -path $UpdateLog -append -NoClobber -IncludeInvocationHeader #This basically captures everything into a separate (different) txt file in case something doesn't work so you can see all the steps as they played out

##Checking for updates and, if available, stops RUST Server, executes core updates + downloads, extracts, and then deletes the latest Oxide plugin, and fires everything back up.

ForEach ($Entry in $FeedXML.feed.entry) {

    If (($Now - [datetime]$Entry.updated).TotalHours -ile 4) {
		if ($GetService.status -ne 'Stopped'){
			while ($GetService.status -eq 'Running'){
				Stop-Service $ServiceName
				write-host $GetService.Status
				write-host "$($ServiceName) Stopping..."
				Start-Sleep -Seconds 10
				$GetService.Refresh()
				if ($GetService.Status -eq 'Stopped'){
				write-host "$($ServiceName) stopped successfully!"}
			}
		}
		elseif ($GetService.status -ne 'Running'){
		write-host "$($ServiceName) is not currently running. Skipping to server update steps."
		}
		& "C:\SteamCMD\steamcmd.exe +login anonymous +force_install_dir c:\rust +app_update 258550 +quit"
		Invoke-WebRequest -Uri $DLSource -OutFile $DLDest | Write-Host "Downloading the latest version of Oxide for RUST to $($DLDest)"
		Expand-Archive -LiteralPath $DLDest -DestinationPath $RustDedicatedData -Force
		while ($GetService.status -ne 'Running'){
			Start-Service $ServiceName
			write-host $GetService.Status
			write-host $ServiceName ' Starting Up...'
			Start-Sleep -Seconds 10
			$GetService.Refresh()
			if ($GetService.Status -eq 'Running'){
			write-host "$($ServiceName) started successfully!"}
			}
		#$MailParams = @{
		#	'To' = $SendTo
		#	'From' = $SendFrom
		#	'Subject' = $Subject
		#	'Body' = "$($Now) :: RUST Server (and OXIDE) UPDATE HAS BEEN PERFORMED"
		#	'SmtpServer' = $emailserver
		#	}
		#Send-MailMessage @MailParams
	}
	elseif (($Now - [datetime]$Entry.updated).TotalHours -ige 4){
	write-host "There are no recent matching updates for $($ServiceName)."
	}
}
Stop-Transcript