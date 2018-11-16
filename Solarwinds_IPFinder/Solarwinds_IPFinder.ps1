<#
.SYNOPSIS
 Automates queries to SolarWinds given a list of IP addresses.

.DESCRIPTION
 This script queries the SolarWinds API (SolarWinds Framework) in order to automate the DB queries 
 given a list of IP addresses from a txt file.
 It is necessary to run the script with Admin credentials and to have the SWISS Powershell module 
 installed. (Check SolarWinds API documentation)

 This script will gather all data from a solarwinds database called 'IPMan', given an IP from a list.

.NOTES
  Version:        1.1.0
   Author:        Nicolas Fernandez Osinaga
  Creation Date:  19.07.2018
  Purpose/Change: Initial script development

.EXAMPLE
  Just run the script.
  Modify first the Initial variables and sql_query

#>
          
#Start counter
$elapsed = [System.Diagnostics.Stopwatch]::StartNew() 
Write-Host "Starting new search..." -ForegroundColor Green
Write-Output "`r";

### THIS LINES SHOULD BE MODIFIED ON FIRST SCRIPT EXECUTION. VALUES GIVEN AS EXAMPLES:
$IPlist = get-content .\IP.txt
Import-Module 'C:\Program Files (x86)\WindowsPowerShell\Modules\SwisPowerShell\2.3.0.108\SwisPowerShell'
$swis = Connect-Swis -Hostname <servername>
$sql_query = 'SELECT IPAddress,IpNodeId,DnsBackward,IPAddressN,MAC,SubnetId,DisplayName FROM IPMan.IPNode Where IPAddress=@IPAddress'

### NEXT LINES SHOULD NOT BE MODIFIED
$IPlist | foreach {
    $IP = $_
    $results = Get-SwisData $swis $sql_query -Parameters @{ IPAddress = $IP }
    if ($results) {
        Write-host "Found $IP in SolarWinds!" -ForegroundColor Magenta
        Write-host "$results"
        Write-Output "`r";
        $results | Export-Csv .\Netmonfinder-Output.csv -Append -Force
    }
    else {
        [string]$notfound = "$IP, not found in SolarWinds"
        Write-host "$IP, not found in SolarWinds..." -ForegroundColor Red
        Write-Output "`r";
        $notfound | Out-file .\Not_found_SolarWinds.csv -Append
    }
    $results = ""

}
#Total Time:
$totaltime = [math]::Round($elapsed.Elapsed.TotalSeconds, 2)

Write-Host "Total Elapsed Time: $totaltime seconds." -ForegroundColor Green
