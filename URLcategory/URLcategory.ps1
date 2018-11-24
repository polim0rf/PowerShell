<#
.SYNOPSIS

  Get and submit BlueCoat category information for URL's

.DESCRIPTION

  This script retrieves category information for a list of URLs, and submit to Sitereview the ones 
  that are still Unrated.

.PARAMETER

    -url: URL to categorize
    -cat: Integer number indicating possible category
    -comment: Required comment
    -list: List of URLs in TXT file
    
.NOTES

  Version:        1.0.0
  Author:         polim0rf
  Creation Date:  23.11.2018
  Purpose/Change: Initial script development

  DISCLAIMER: Please be aware that querying SiteReview.com via scripts 
  is against their ToS. This script POC is only for educational purposes.
  
.EXAMPLE

    Query single URL:
    URLcategory -cat 18 -comment Phishing -url https://mmmmkool.godaddysites.com 

    Query list of URL from TXT file:
    URLcategory -cat 18 -comment Phishing -list ./list.txt

    Type below command to see current list of categories:
    Show-Categories

#>



Function URLcategory {

    param (
    
        [string]$url,
        [string]$cat,
        [string]$comment,
        [string]$referrer,
        [string]$list

    )

    ### LINES BELOW SHOULD BE MODIFIED AT FIRST SCRIPT EXECUTION
    $email1 = ""
    $email2 = ""
    $sendEmail = "false"
    $referrer = "bluecoatsg" #Default > Blue Coat SG

    #Referrer Keyword list:
    #Blue Coat CachFlow Appliance   = cacheflow
    #Blue Coat K9 Safe Search       = k9search
    #Blue Coat K9 Web Protection    = k9webprotection
    #Blue Coat PacketShaper         = bcps
    #Blue Coat ProxyClient          = bcproxyclient
    #Blue Coat Security Analytics   = bcsa
    #Blue Coat SSL Visibility       = bcsslv
    #Blue Coat Unified Agent        = bcunifiedagent
    #Blue Coat Web Security Service = bccloud
    #Global Security One            = gs1
    #etc...


    ### LINES BELOW SHALL NOT BE MODIFIED
    $outputfolder = test-path .\Output
    If ($outputfolder -like 'false') { $outputfolder = New-Item -ItemType directory -Path .\Output}
    $Headers = @{ 'Accept' = 'application/json'; 'Content-Type' = 'application/json; charset=UTF-8'; 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36'; }

    #Categories
    $categ = Invoke-RestMethod -Method 'GET' -uri "http://sitereview.bluecoat.com/rest/categoryList?alpha=true" -H $Headers
    #$categ | Sort-Object -Property 'num'

    if (($list -eq $null) -or ($list -eq "")) {
        Categorize
    }
    Else {
        [array]$list = Get-content $list
        $list | ForEach-Object {
            $url = $_
            Categorize
        }
    }
}

filter Categorize {

    $Payload = ""
    $Payload = @{url = $url ; captcha = ""; }
    $json = $Payload | ConvertTo-Json

    Write-Host "`r"
    Write-Host -Fore Green 'Getting current category for:' $url
    Write-Host "`r"

    $po = Invoke-RestMethod -Method 'POST' -uri "http://sitereview.bluecoat.com/resource/lookup" -H $Headers -Body $json -SessionVariable myWebSession

    If ($po.unrated -eq 'True') {
 
        Write-host -Fore DarkYellow '    This url was not previously categorized. Starting submission...'
        $Payload = @{comments = $comment ; email1 = $email1; email2 = $email2; cat1 = $cat; referrer = $referrer; sendEmail = $sendEmail; trackid = ""}
        $json = $Payload | ConvertTo-Json

        $response = Invoke-WebRequest -Method 'POST' -uri "http://sitereview.bluecoat.com/resource/submitCategorization" -H $Headers -Body $json -WebSession $myWebSession
        $jsonResponse = $response.Content | ConvertFrom-Json
        Write-Host -Fore DarkCyan '   '$jsonResponse.message

        $response | Add-Member -type NoteProperty -Name 'URL' -Value $url
        $Export = $response | ParseData
        $Export | Export-Csv -Path .\Output\Pending_Category.csv -NoType -Encoding UTF8 -Append -Force

    }
    Else {
        
        $item = New-Object PSObject
        Write-Host -Fore Cyan 'Url already categorized as:'
        Write-Host '*******************************'
        $po.securityCategoryIds | foreach {
            $secCat = $_
            $out = $categ | Where-Object {$_.'num' -like $secCat} | Select-Object 'name'
            Write-Host -Fore DarkCyan '   '$out.name
            $item | Add-Member -type NoteProperty -Name $secCat -Value $out.name
            
        }
        Write-Host '*******************************'

        $po | Add-Member -type NoteProperty -Name 'TranslatedCategory' -Value $item
        $Export = $po | ParseData
        $Export | Export-Csv -Path .\Output\Categorized.csv -NoType -Encoding UTF8 -Append -Force
    }

}

filter ParseData {

     #Parse JSON response to adapt it for an export to CSV
     $Tablevalues = @()

     $namelist = $_ | Get-Member -MemberType *property
     $Tablevalues += $namelist.Name #Get first column values of the hashtable (Name)
     $subcount = 0
     [hashtable]$TableProperty = @{}
     For ($i=0;$i -lt $Tablevalues.count;$i++) {     
  
        $stringvalue = ($_.($Tablevalues[$subcount]) | Out-String).Trim()
        $val = $stringvalue.replace("`n","") #Remove newline character (for CSV export)
        $val = $val -replace(" +"," ") #Remove excess of whitespaces
        $TableProperty.Add( $Tablevalues[$subcount], $val )
                
        $subcount ++
     }
     $Table = New-Object -TypeName psobject -Property $TableProperty
     Return $Table 

}

Function Show-Categories {
    #Categories
    $categ = Invoke-RestMethod -Method 'GET' -uri "http://sitereview.bluecoat.com/rest/categoryList?alpha=true" -H $Headers
    $categ | Sort-Object -Property 'num'
}
