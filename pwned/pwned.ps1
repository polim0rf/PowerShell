
<#
.SYNOPSIS
  Get information from haveibeenpwned website regarding compromised emails.

.DESCRIPTION
  Yet another simple script for querying Have I Been Pwned? database, from Troy Hunt.

.PARAMETER UserName
    "-email" : Email address to check 
    
.NOTES
  Version:        1.0.0
   Author:        Nicolas Fernandez Osinaga
  Creation Date:  16/08/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  pwned? -email <email_address>

#>

function pwned? {

    param (
        [string]$email
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    try {
        $object = Invoke-restmethod -Uri "https://haveibeenpwned.com/api/v2/breachedaccount/$email" -Method Get -ErrorVariable errorRequest
    }
    catch {
        $http_response = $_.Exception.Response
    }

    if ($http_response.Statuscode -like "Notfound") {

        Write-Output  "";
        Write-Host  -ForegroundColor Green "Email account $email NOT pwned, as far as we know..."
    }
    Else {
        Write-Output  "";
        Write-Host  -ForegroundColor Red "Email account $email was PWNED!!!"
        $object
    }
}
