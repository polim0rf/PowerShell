<#
.SYNOPSIS
  Convert a list of IP addresses/Subnet mask pairs in CIDR notation

.DESCRIPTION
  From a column named 'IP' and another 'Mask', this script converts these pairs into CIDR notation, exporting the results into a .txt file 'out.txt'
  Columns are ";" separated.

.PARAMETER file
  Indicates the location of the CSV file with the columns of addresses to convert.

.NOTES
  Version:        1.0.2
  Author:         Nicolas Fernandez Osinaga
  Creation Date:  09.04.2018
  Purpose/Change: Initial script development

.EXAMPLES
  GetNetworkID -file .\Netmon.csv
#>


Clear-Host

#Initiate exported file
"Network" | Out-file .\out.txt

Function GetNetworkID {

    #Parameters definition

    param (
        [string]$file
    )   

    $netmon = Import-Csv -delimiter ";" $file 
    $netmon | ForEach-Object {

        [string]$myip = $_.IP
        [string]$mymask = $_.Mask


        $ipBinary = toBinary $myip
        $smBinary = toBinary $mymask
    
        #how many bits are the network ID
        $netBits = $smBinary.indexOf("0")

        #validate the subnet mask
        if (($smBinary.length -ne 32)) {
            "Network ID: $myip Invalid SubnetMask"
            $Output = "$myip Invalid SubnetMask"
            $Output | Out-file .\out.txt -Append

        }
        #Validate if submask is 32
        Elseif ($mymask -eq '255.255.255.255') {
            #write output
            "Network ID: $myip/32"
            $Output = "$myip/32"
            $Output | Out-file .\out.txt -Append
        }
        #validate IP address
        Elseif (($ipBinary.length -ne 32) -or ($ipBinary.substring($netBits) -eq "00000000") -or ($ipBinary.substring($netBits) -eq "11111111")) {
            "Network ID: $myip Invalid IPaddress"
        }
        Else {
            #identify subnet boundaries
            $networkID = toDottedDecimal $($ipBinary.substring(0, $netBits).padright(32, "0"))

            #write CIDR/Network ID output
            "Network ID: $networkID/$netBits"
            $Output = "$networkID/$netBits"
            $Output | Out-file .\out.txt -Append
            
        }

    }

}

function toBinary ($dottedDecimal) {
    $dottedDecimal.split(".") | % {$binary = $binary + $([convert]::toString($_, 2).padleft(8, "0"))}
    return $binary
}
function toDottedDecimal ($binary) {
    do {$dottedDecimal += "." + [string]$([convert]::toInt32($binary.substring($i, 8), 2)); $i += 8 } while ($i -le 24)
    return $dottedDecimal.substring(1)
}