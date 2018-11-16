<#
.SYNOPSIS

  Get information from Hybrid-Analysis.com sandbox using its free API

.DESCRIPTION

  This script retrieves samples information from Hybrid-Analysis.com using its free API.
  A free account with Hybrid-Analysis is required to get the API key.

.PARAMETERS

    -hash <hash_value> : Search for a single hash value (md5,sha256,sha1)
    -hashes <path_to_file> : Search for a list of hashes in a TXT file
    -term <term_value> : Search for the value of a specified term
        >> You can find the list of terms using command: HA -term help
    -url <url_value> : TBD
    
.NOTES

  Version:        0.0.6
  Author:         Nicolas Fernandez Osinaga
  Creation Date:  05.10.2018
  Purpose/Change: Initial script development

  Thanks to these two blogs for understanding of psobjects handling:
  https://www.gngrninja.com/script-ninja/2016/6/18/powershell-getting-started-part-12-creating-custom-objects#add
  https://learn-powershell.net/2014/01/24/avoiding-system-object-or-similar-output-when-using-export-csv/

  
.EXAMPLES

    Search for a single hash (Malicious Nemucod JS sample)
    HA -hash 3ea1112ba44f600227f4f1fbb650b3e68fe3c0a5ea02f9c2c2c165eded825b92 

    Search for a list of hashes (md5,sha1,sha256)
    HA -hashes ./hashes.txt

    Search for the value of a HA term and list the results:
    HA -term vx_family

#>



Function HA {

    param (
    
        [string]$hash,
        [string]$hashes,
        [ValidateSet("filename", "filetype", "filetype_desc", "env_id", "country", "verdict", "av_detect", "vx_family", "tag", "port", "host", "domain", "url", "similar_to", "context", "imp_hash", "ssdeep", "authentihash", "help")]
        [string]$term
        #[string]$download
        #[string]$url

    )

    ### THESE LINES SHOULD BE TUNED AT FIRST SCRIPT EXECUTION ###

    $API = "your_api_key"
    $outputFolder = "./Output/"


    ### LINES BELOW SHOULD NOT BE MODIFIED ###

    $Headers = @{'api-key' = $API; 'Accept' = 'application/json'; 'Content-Type' = 'Application/x-www-form-urlencoded'; 'User-Agent' = 'Falcon'; }
    $Body = ""
    

    #-----------------------------------------------------[Command error handling]------------------------------------------------------

    if (($hash -eq $null) -or ($hashes -eq $null) -or ($term -eq $null)) {

        Write-Host -Fore DarkCyan "Please specify a parameter value:";
        Write-Host -Fore DarkCyan "  * e.g: 'HA -hash <hash_value>'";
        Write-Host -Fore DarkCyan "  * e.g: 'HA -hashes <TXT_hashes_file>'";
        Write-Host -Fore DarkCyan "  * e.g: 'HA -term <term_value>'";
        Write-Host -Fore DarkCyan "  ** e.g: 'HA -term help' > To view term options";
        Write-Output "`r";
        Break           
    }


    ########################################################### [Execution] #############################################################


    #-------------------------------------------------------[Single hash search]--------------------------------------------------------#

    if (($hash -ne $null) -and ($hash -ne "")) {
        Write-Output "`r";
        Write-Host -Fore DarkCyan "Querying hash: $hash";

        $Body = @{ "hash" = $hash }
        
        try {
            $object = Invoke-RestMethod -Method Post -Uri "https://www.hybrid-analysis.com/api/v2/search/hash" -H $Headers -Body $Body -ErrorAction Stop
            $object[0]
        }
        catch {
            #Error handling
            $ErrorMessage = $_.Exception.Message
            $ErrorMessage
            $FailedItem = $_.Exception.ItemName

        }
        if ($object[0] -eq $null) {
            Write-Output "`r";
            Write-Host "Hash $hash not found in Hybrid-Analysis.com"
            Break;
        }
        Else {
            Write-Output "`r";
            Write-Host "Hash $hash found!"
            $Export = $object[0] | ParseData
            $Export | Export-Csv -NoTypeInformation -Path $($outputFolder + "HA_" + $hash + ".csv") -Encoding UTF8 -Delimiter ";"

            ### Download report from HA. Only with Admin priv. (Test undergoing)
            $object[0].job_id | DownloadReport
            
        }
    }


    #-------------------------------------------------------[Hash list search]--------------------------------------------------------#

    elseif (($hashes -ne $null) -and ($hashes -ne "")) {
        [array]$list = Get-content $hashes
        
        $count = 0
        $Body = ""
        $list | ForEach-Object {
            $Body += "hashes%5B%5D=" + $_

            $count++
            If ($count -eq $list.count) {}
            Else {$Body += "&"}

        }
        If ($count -eq "0") {
            Write-Host -Fore DarkCyan "List of hashes is empty!"
            Break;
        }
        #$Body = 'hashes%5B%5D=<md5>&hashes%5B%5D=<sha256>&....'

        Write-Host "`r"
        Write-Host -Fore DarkCyan "Looking for list of hashes in $hashes file..."
        try {
            $object = Invoke-RestMethod -Method Post -Uri "https://www.hybrid-analysis.com/api/v2/search/hashes" -H $Headers -Body $Body -ErrorAction Stop
        }
        catch {
            #Error handling
            $ErrorMessage = $_.Exception.Message
            $ErrorMessage
            $FailedItem = $_.Exception.ItemName
        }

        $total = $count
        for ($i = 0; $i -lt $count; $i++) {
            if ($object[$i] -eq $null) {
                $none = $list[$i - 1]
                Write-Host "Hash $none not found"
                $Export = "$none, Not found"
                $Export | Out-File -FilePath $($outputFolder + "HA_Hashes_Not_Found_in_" + (Get-Item $hashes).basename + ".txt") -Encoding UTF8 -Append -Force
                $total = $total - 1
            }
            Else {
                $object[$i]
                $Export = $object[$i] | ParseData
                $Export | Export-Csv -NoTypeInformation -Path $($outputFolder + "HA_" + "Hashes_" + (Get-Item $hashes).basename + ".csv") -Encoding UTF8 -Delimiter ";" -Append
            }
        }

        write-Host "`r"
        Write-Host -Fore Cyan "Found $total out of $count samples in Hybrid-Analysis.com!!"

    }


    #-------------------------------------------------------[Search for HA terms]--------------------------------------------------------#

    ### Menu Help
    elseif ($term -match "help") {
        Show-Menu
        Break
    }

    ### Query by HA terms
    elseif (($term -ne $null) -and ($term -ne "")) {
        Show-Menu
        Write-Host "`r"
        $termvalue = Read-Host "Please, insert the term value: "
        $Body = "$term=$termvalue"

        try {
            Write-Host "`r"
            Write-Host -Fore Cyan "Searching in HybridAnalysis for $term = $termvalue ..."
            $object = Invoke-RestMethod -Method Post -Uri "https://www.hybrid-analysis.com/api/v2/search/terms" -H $Headers -Body $Body -ErrorAction Stop
        }
        catch {
            #Error handling
            $ErrorMessage = $_.Exception.Message
            $ErrorMessage
            $FailedItem = $_.Exception.ItemName
        }

        $count = $object.count
        
        for ($i = 0; $i -lt $count; $i++) {
            $object.result[$i]
            $Export = $object.result[$i] | ParseData
            $Export | Export-Csv -NoTypeInformation -Path $($outputFolder + "HA_TermSearch_" + $term + "_" + $termvalue + ".csv") -Encoding UTF8 -Delimiter ";" -Append
        }
        Write-Host "`r"
        Write-Host -Fore Cyan "Found $count samples!!"
    }

    elseif (($url -ne $null) -and ($url -ne "")) {
        #TBD
    }

}


function Show-Menu {
    Write-Host "`r"
    Write-Host -Fore DarkCyan "================ HA Terms ================"
    Write-Host "`r"
    Write-Host -Fore DarkCyan "filename      {Filename e.g. invoice.exe}"
    Write-Host -Fore DarkCyan "filetype      {Filetype e.g. docx}"
    Write-Host -Fore DarkCyan "filetype_desc {Filetype description e.g. PE32 executable}"
    Write-Host -Fore DarkCyan "env_id        {Environment Id}"
    Write-Host -Fore DarkCyan "country       {Country (3 digit ISO) e.g. swe}"
    Write-Host -Fore DarkCyan "verdict       {Verdict e.g. 1 (available: 1 'whitelisted’, 2 'no verdict’, 3 'no specific threat’, 4 'suspicious’, 5 ‘malicious’)}"
    Write-Host -Fore DarkCyan "av_detect     {AV Multiscan range e.g. 50-70 (min 0, max 100)}"
    Write-Host -Fore DarkCyan "vx_family     {AV Family Substring e.g. nemucod}"
    Write-Host -Fore DarkCyan "tag           {Hashtag e.g. ransomware}"
    Write-Host -Fore DarkCyan "port          {Port e.g. 8080}"
    Write-Host -Fore DarkCyan "host          {Host e.g. 192.168.0.1}"
    Write-Host -Fore DarkCyan "domain        {Domain e.g. checkip.dyndns.org}"
    Write-Host -Fore DarkCyan "url           {HTTP Request Substring e.g. google}"
    Write-Host -Fore DarkCyan "similar_to    {Similar Samples e.g. <sha256>}"
    Write-Host -Fore DarkCyan "context       {Sample Context e.g. <sha256>}"
    Write-Host -Fore DarkCyan "imp_hash      {Host e.g. 192.168.0.1}"
    Write-Host -Fore DarkCyan "ssdeep        {Domain e.g. checkip.dyndns.org}"
    Write-Host -Fore DarkCyan "authentihash  {HTTP Request Substring e.g. google}"
}

filter ParseData {

    #Parse JSON response to adapt it for an export to CSV
    $Tablevalues = @()

    $namelist = $_ | Get-Member -MemberType *property
    $Tablevalues += $namelist.Name #Get first column values of the hashtable (Name)
    $subcount = 0
    [hashtable]$TableProperty = @{}
    For ($i = 0; $i -lt $Tablevalues.count; $i++) {     
  
        $stringvalue = ($_.($Tablevalues[$subcount]) | Out-String).Trim()
        $val = $stringvalue.replace("`n", "") #Remove newline character (for CSV export)
        $val = $val -replace (" +", " ") #Remove excess of whitespaces
        $TableProperty.Add( $Tablevalues[$subcount], $val )
                
        $subcount ++
    }
    $Table = New-Object -TypeName psobject -Property $TableProperty
    Return $Table 

}

Function Hash_Validator {

    $md5 = [regex] "\b[a-f0-9]{32}"
    $sha1 = [regex] "\b[a-f0-9]{40}"
    $sha256 = [regex] "\b[a-f0-9]{64}"

}

Filter DownloadReport {
    
    write-Host "`r"
    Write-Host -Fore Cyan "Downloading report from HA for job_id: $_"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("user-agent", 'Falcon')
    $headers.Add("api-key", $API)
    $headers.Add("accept",'application/json')

    try {
        $Report = Invoke-RestMethod -Method Get -Uri "https://www.hybrid-analysis.com/api/v2/report/$_/file/misp" -Headers $headers
        $out = WriteXmlToScreen $Report
        $out | Out-file ./report.txt
    }
    catch {
        #Error handling
        $ErrorMessage = $_.Exception.Message
        $ErrorMessage
        $FailedItem = $_.Exception.ItemName

    }

}

function WriteXmlToScreen ([xml]$xml)
{
    $StringWriter = New-Object System.IO.StringWriter;
    $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter;
    $XmlWriter.Formatting = "indented";
    $xml.WriteTo($XmlWriter);
    $XmlWriter.Flush();
    $StringWriter.Flush();
    Write-Output $StringWriter.ToString();
}


Filter DroppedFiles {

    $_
    try {
        Invoke-RestMethod -Method Get -Uri "https://www.hybrid-analysis.com/api/v2/report/$_/dropped-files" -H $Headers -ErrorAction Stop
        #$Report
    }
    catch {
        #Error handling
        $ErrorMessage = $_.Exception.Message
        $ErrorMessage
        $FailedItem = $_.Exception.ItemName

    }

}
