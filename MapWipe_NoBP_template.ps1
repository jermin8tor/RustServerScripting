#  REQUIRED VARIABLEs - edit below to match your environment
$ServiceName = 'NameOfYourRustServerService'
$GetService = Get-Service -Name $ServiceName
$ServerPath = "C:\PathTo\YourRustServer\Files"
$UpdateLog = "C:\PathTo\YourRustServer\MapWipeLogs\MAPandBP_WIPE.log"
## OPTIONAL VARIABLES (for emailed results) - Remove the '#' before them and edit them to match your environment if they will be used
#$SendTo = Your@email.address
#$SendFrom = Someone@Somewhere.Something
#$Subject = "RUST Server UPDATED - Automated Script Results for $(Get-Date)"
#$emailserver = Your.Mail.Server
## BE SURE TO ALSO REMOVE THE '#' BLOCKING OUT THE SECTION OF CODE THAT TRIGGERS THE EMAIL AS WELL!

Start-Transcript -path $UpdateLog -append -NoClobber -IncludeInvocationHeader #This basically captures everything into a separate (different) txt file in case something doesn't work so you can see all the steps as they played out

##Check if the Server is running currently and stop it; If it is already in a stopped state it moves on to the next part of the script.
if ($GetService.status -ne 'Stopped'){
	while ($GetService.status -eq 'Running'){
		Stop-Service $ServiceName
		write-host $GetService.Status
		write-host "$($ServiceName) Stopping..."
		Start-Sleep -Seconds 10
		$GetService.Refresh()
		if ($GetService.Status -eq 'Stopped'){
		write-host "$($ServiceName) stopped Successfully"}
	}
}
elseif ($GetService.status -eq 'Stopped'){
	write-host "$($ServiceName) is not currently running. Skipping to Server Wipe Functions."
}

## This scans the RUST Server path for the Map / Sav files and deletes them.
## If you want to test this script without actually deleting anything, remove the "#" in front of the -whatif after -Remove-Item below
Get-ChildItem $ServerPath\* -Include "*.map", "*.sav*" -File -OutVariable files | Foreach-Object {
    $_ | Remove-Item -Force #-whatif
}
if ($files) {
    #$MailParams = @{ 'To' = $SendTo
    #                 'From' = $SendFrom
    #                 'Subject' = $Subject
    #                 'Body' = $files.Name | Out-String
    #                 'SmtpServer' = $emailserver
    #}
    #Send-MailMessage @MailParams
	write-host "$($files)"
}

## Time to start the RUST server back up

while ($GetService.status -ne 'Running'){
		Start-Service $ServiceName
		write-host $GetService.Status
		write-host "Starting $($ServiceName); Stand By.."
		Start-Sleep -Seconds 5
		$GetService.Refresh()
		if ($GetService.Status -ne 'Running'){
		write-host "Still waiting for $($ServiceName) to start; Stand By.."}
		elseif ($GetService.Status -eq 'Running'){
		write-host "$($ServiceName) was successfully started."}
}
Stop-Transcript