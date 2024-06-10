#Define the script block to be executed via runCommand
$runCommandPayload = {
 
    #5 Minute warning
    msg * "This server will be rebooted in 5 minutes. Please save your work."
 
    #Wait for 4 minutes before sending the next notification
    Start-Sleep -Seconds 240
 
    #1 Minute warning
    msg * "This server will be rebooted in 1 minute. Please save your work."
 
    #Wait for 1 minute before rebooting
    Start-Sleep -Seconds 60
 
    #Reboot the remote server
    Restart-Computer -Force
}
 
#Connect to Azure for VMs
try
{
    Connect-AzAccount -Identity
}
catch
{
    Write-Error $_
    throw $_
}

$farm = $farm.toLower()

#Get List of VMs and list out VMs that are found
$vms = Get-AzVm | Where-Object {($_.name.toLower()).contains("$farm")}
Write-Output "Found VMs!"
$vms | select name

#Iterate through each server in the list and start a job for each
$runCommandName = "NightlyReboot$(Get-Date -Format yyyyMMdd)"
foreach ($vm in $vms)
{
    $runCommands = @(Get-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name)
    $runCommandNames = $runCommands.name
    foreach($runCommandName in $runCommandNames)
    {
        Remove-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -RunCommandName $runCommandName -ErrorAction SilentlyContinue
    }
    Write-Output "Sending restart command to $($vm.name)"
    Set-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -RunCommandName $runCommandName -Location $vm.Location -SourceScript $runCommandPayload -NoWait
}
