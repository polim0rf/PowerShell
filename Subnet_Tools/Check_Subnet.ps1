<#
.SYNOPSIS
  Looks up for the subnets where a given IP address is present.

.DESCRIPTION
  Having an input CSV file with a list of Network addresses (taken from "Subnet_calculator_list.ps1" for example), this scripts checks in which subnets a given IP address can be present.
  The script looks for the presence of the 'Network' column within the CSV file.
  The results are exported into .\Searcher-output.csv

.PARAMETER file
  Indicates the location of the CSV file with the columns of addresses to convert.

.NOTES
  Version:        1.0.2
  Creation Date:  09.04.2018
  Purpose/Change: Initial script development

.EXAMPLES
  Check in which networks (subnets) from Netmon.csv can the IP address 196.4.69.7 be present:
  checksubnet -addr1 196.4.69.7 -file .\Netmon.csv
#>

function checkSubnet ()
{

    param (
        [string]$addr1,
        [string]$file
    )   

    # Separate the network address and lenght
    $network1, [int]$subnetlen1 = $addr1.Split('/')

    $data = Import-Csv -delimiter ";" $file
    
    $data.'Network' | foreach {
        [string]$addr2 = $_

        # Separate the network address and lenght
        $network2, [int]$subnetlen2 = $addr2.Split('/')

        #Convert network address to binary
        [uint32] $unetwork1 = NetworkToBinary $network1
        [uint32] $unetwork2 = NetworkToBinary $network2

        #Check if subnet length exists and is less then 32(/32 is host, single ip so no calculation needed) if so convert to binary
        if($subnetlen2 -lt 32){
            [uint32] $mask2 = SubToBinary $subnetlen2
        }

        #Compare the results
        If($mask2){
            # If first input is address and second input is subnet check if it belongs
            return CheckNetworkToSubnet $unetwork2 $mask2 $unetwork1
        }
    }
}

function CheckNetworkToSubnet ([uint32]$un2, [uint32]$ma2, [uint32]$un1)
{
    $ReturnArray = "" | Select-Object -Property Condition,Subnet
    if($un2 -eq ($ma2 -band $un1)){
        $ReturnArray.Condition = $True
        $ReturnArray.Subnet = "$network2/$subnetlen2"
        
        $out = Import-CSV -delimiter ";" $file | Where-Object {$ReturnArray.Subnet -eq $_.'Network'}
        $out | Export-Csv .\Searcher-output.csv -NoTypeInformation

        return $ReturnArray
    }  
}

function SubToBinary ([int]$sub)
{
    return ((-bnot [uint32]0) -shl (32 - $sub))
}

function NetworkToBinary ($network)
{
    $a = [uint32[]]$network.split('.')
    return ($a[0] -shl 24) + ($a[1] -shl 16) + ($a[2] -shl 8) + $a[3]
}
