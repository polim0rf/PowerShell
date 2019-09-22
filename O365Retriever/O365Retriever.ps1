<#
.SYNOPSIS
  Retrieve emails and extract their IOC's

.DESCRIPTION
  This script automatically retrieves all the emails from a given list  (Typically an Office 365 Trace log
  and then parses relevant IOC's from them saving a copy of the emails and attachments in the filesystem.
  List of additional IOC's retrieved:
    -Body URL's
    -Subjects
    -Sender emails
    -Attachment hashes
    -Mail Item folder hierarchy

.PARAMETER O365
    -O365 : Indicates a previously exported Office 365 Trace log (CSV)
    
.NOTES
  Version:        1.9
   Author:        polim0rf
  Creation Date:  20.09.2019
  Purpose/Change: Initial script development

  
.EXAMPLE
  Retrieve_Extract.ps1 -O365 .\Trace.csv
#>


############# FUNCTIONS DECLARATION FOR EMAIL RETRIEVAL CODE #############


# Create logging function that will handle text output in the command prompt and also record activities in log file (mode 1 = warning, mode 2 = error, default = normal)
Function WriteLog([string]$logstring, [int]$mode) {
    $logTime = [DateTime]::UtcNow.ToString('u')
    Switch ($mode) {
        Default { Add-content $logFile -value $($logTime.Substring(0, $logTime.Length - 1) + " UTC : " + $logString); Write-Host $logString }
        1 { Add-content $logFile -value $($logTime.Substring(0, $logTime.Length - 1) + " UTC :    WARNING - " + $logString); Write-Warning $logString }
        2 { Add-content $logFile -value $($logTime.Substring(0, $logTime.Length - 1) + " UTC :    ERROR - " + $logString); $Host.UI.WriteErrorLine($("ERROR: " + $logString)) }
    }
}

function RetrieveAll () {

    param (
        [string]$O365
    )   

    $TimeNow = Get-Date
    $execDate = $TimeNow -f "MMddyy HH:mm:ss"
    $execDate = $TimeNow.ToUniversalTime().ToString("yyyy-MM-dd HHmmss")
    
    ### ---------------------------------------------------------------------- LINES BELOW MAY BE TUNED FOR EACH INCIDENT ---------------------------------------------------------------------- ###
    [string]$O365AdminAccount = "YOURDOMAIN\youradmin@acme.com"
    $global:TargetMailbox = "yourmailaddress@acme.com" 
    $outputFolder = "D:\O365Retriever\$execDate\"

    ### --------------------------------------------------------------------------- LINES BELOW SHALL NOT BE MODIFIED --------------------------------------------------------------------------- ###
    # Set no script execution restrictions, capture script execution date/time (this will be used in the name of output files produced, as well as for UnifiedAuditLog's SessionID) and configure log file to be used

    [string]$logFile = $((Get-Item $PSCommandPath).DirectoryName + "\" + (Get-Item $PSCommandPath).BaseName + ".log")

    # Initiate logging
    Add-content $logFile -value "`n"; Write-Host "`r"; WriteLog "-------------------------------------------------"; WriteLog "      RETRIEVE_&_EXTRACT SCRIPT - v1.9"; WriteLog "-------------------------------------------------"
    WriteLog $("Script execution timestamp = " + $execDate + " (UTC)"); WriteLog $("Script output path = " + $outputFolder); WriteLog "-------------------------------------------------"
    Write-Output "`n";

    # Check if Office365 session already exits. If yes, drop them.
    Get-PSSession | Remove-PSSession

    # Keep prompting user for ADMIN credentials until valid data is submitted, or until user cancels the authentication process
    While (!(Get-PSSession | Where { $_.ConfigurationName -eq "Microsoft.Exchange" -And $_.State -eq "Opened" })) {
        WriteLog "Authentication required, please enter your ADMIN account's password when prompted." 1
        try { $CORPCreds = Get-Credential -credential $O365AdminAccount }
        catch { WriteLog "Prompt was cancelled, stopping script execution.`n" 1; Write-Host "`r"; exit }
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $CORPCreds -Authentication Basic -AllowRedirection -ErrorAction SilentlyContinue -ErrorVariable ErrorOccurred
        If ($ErrorOccurred) { WriteLog "Authentication failed, please try again." 2 }
        Else {
            Import-PSSession $Session -DisableNameChecking -ErrorAction Stop | Out-Null
            WriteLog "Connection to Office365 successful"
        }
    }

    $Emails_list = { }

    If (($O365 -ne $null) -and ($O365 -ne "")) {
        Write-Output "`n";
        Write-Host -Fore Green "Retrieving emails from O365 Trace logs..."

        #To know what is your culture CSV separator:
        $mydelimiter = (Get-Culture).TextInfo.ListSeparator
        $Emails_list = Import-Csv -Path $O365 -Delimiter ";"

        $Emails_list | ForEach-Object {

            [string]$Identity = $_."RecipientAddress"
            [string]$Subject = $_."Subject"
            [string]$StartDate = $_."StartDate"
            [string]$EndDate = $_."EndDate"
            $global:TargetFolder = $execDate

            [datetime]$StartDate = [datetime]::parse($StartDate, $culture_pl)
            [datetime]$EndDate = [datetime]::parse($EndDate, $culture_pl)
            $Start = Get-Date $StartDate -Format "dd\/MM\/yyyy HH\:mm\:ss"
            $End = Get-Date $EndDate -Format "dd\/MM\/yyyy HH\:mm\:ss"

            $SearchQuery = 'Subject:"' + $Subject + '" AND Received:"' + $Start + '..' + $End + '"'
            write-host -Fore DarkGreen "$SearchQuery AND Identity: $Identity"

            #"PSComputerName","RunspaceId","PSShowComputerName","Organization","MessageId","Received","SenderAddress","RecipientAddress","Subject","Status","ToIP","FromIP","Size","MessageTraceId","StartDate","EndDate","Index"
            Search-Mailbox -Identity $Identity -SearchQuery $SearchQuery -TargetMailbox $TargetMailbox -TargetFolder $TargetFolder -LogLevel Full  | Out-Null

        }

    }
    else {
        ##### TBD - For other kind of logs ####
    }

    #Remove the O365 session
    Get-PSSession | Remove-PSSession

    ######## INITIATE IOC EXTRACTION ########
    Extract_iocs($global:TargetFolder)

    WriteLog "-------------------------------------------------"; WriteLog "      RETRIEVE_&_EXTRACT execution COMPLETED"; WriteLog "-------------------------------------------------`n";
    
}



############# FUNCTIONS DECLARATION FOR IOC EXTRACTION CODE #############

Function Remove-InvalidFileNameChars() {
    #Removes invalid Characters for file names from a string input and outputs the clean string
    #Similar to VBA CleanString() Method
    #Currently set to replace all illegal characters with a hyphen (-)
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$Name
    )

    return [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), ' ')
}


function Release-Ref($ref) {
    #Releases the COM object
    while ([System.Runtime.Interopservices.Marshal]::ReleaseComObject($ref) -gt 0) { Write-Debug "Releasing a COM instance" }
    #This two next commands might be not needed: Let GC decide when its better to finalize the release
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}

Filter Parse_items($folder) {
    #Parser function getting the COM object linked to every email found in each folder

    $folderpath = $folder.FullFolderPath
    
    $folder.items | foreach {

        ### ADD HERE A WRITELOG FOR ADDING EVERY EMAIL PARSED TO THE LOG

        #Checks if SenderType is 'EX' or 'SMTP'
        $SendEmailType = $_.SenderEmailType
        If ($SendEmailType -eq "EX") {
            $SendEmail = ($_.Sender.GetExchangeUser()).PrimarySmtpAddress
        }
        else {
            $SendEmail = $_.SenderEmailAddress
        }
        $global:Sender_email += $SendEmail

        #Get email's subject and date
        [string]$subject = $_.Subject
        [string]$sentOn = $_.SentOn

        $global:Subject_name += $subject

        #Strip subject and date of illegal characters, add .msg extension, and combine
        $fileName = Remove-InvalidFileNameChars($subject + " [" + $sentOn + "].msg")

        $_.attachments | foreach {
            #$global:Attach_list += $_.filename
            $Attach_name = $_.filename

            If ($Attach_name.Contains("csv.zip")) {
                $_.saveasfile((Join-Path $logsfilepath "$logscount - $Attach_name"))
                $logscount++
            }
            else {
                $_.saveasfile((Join-Path $attachmentsfilepath "$attachscount - $Attach_name"))
                $attachscount++
            }

            $val1 = ($_.filename).replace("`n","") #Remove newline character (for CSV export)
            $val1 = $val1.replace("`r","") #Remove retun character (for CSV export)
            $val1 = $val1 -replace(" +"," ") #Remove excess of whitespaces
            $global:Attach_list+= $val1
        }

        if ($_.Class -eq $olClass::olMail) {
            #Save email
            $dest = $emailsfilepath + "\" + "$emailcount - $fileName"
            $_.SaveAs($dest, $olSaveType::olMSG)

            #Save body (to parse URLs)
            $val2 = ($_.Body).replace("`n","") #Remove newline character (for CSV export)
            $val2 = $val2.replace("`r","") #Remove retun character (for CSV export)
            $val2 = $val2 -replace(" +"," ") #Remove excess of whitespaces
            $global:bodies += $val2
            $global:emailcount++
        }

        $global:Email_iocs += "$folderpath;$SendEmail;$Subject;$SentOn;$Attach_list;$bodies"
    }
}

function Get-MailboxFolder($folder) {
    #Iterates over each COM object and for each email found it calls the parser function
    Add-content -path $MailboxHierarchy "$prefix $($folder.name) -> $($folder.items.count)"
    $prefix += "-" #Extend prefix for each subsequent level of subfolder
    if ($folder.items.count -ne 0) {
        Parse_items($folder)
    }
    foreach ($f in $folder.folders) {
        Get-MailboxFolder $f
    } 
} 


Function Extract_iocs($TargetFolder) {
    # Main IOC extraction function. Referenced from 'RetrieveAll' function

    ############# INITIALIZE VARIABLES AND INITIATE PARSER #############

    $global:logscount = 0
    $global:emailcount = 0
    $global:attachscount = 0
    [array]$hash_list = @()
    [array]$export = @()
    [array]$hashes = @()
    [array]$URLs = @()
    [array]$Unique_URLs = @()
    $global:Attach_name = @()
    $global:Sender_email = @()
    $global:Subject_name = @()
    $global:Attach_list = @()
    $global:bodies = @()
    $global:Email_iocs = @()

    ############# INITIALIZE SCRIPT #############

    WriteLog "-------------------------------------------------"; WriteLog "      Mail & IOCs extraction started"; WriteLog "-------------------------------------------------";
    #Write-Host -Fore Green "========== Email Parser ==========";
    Write-Output "`r";
    Write-Host -Fore DarkCyan "Creating output folders...";

    #Initialize Output folders
    $filepath = "D:\Retrieve_Extract\$global:TargetFolder\"
    $logsfilepath = "D:\Retrieve_Extract\$global:TargetFolder\logs"
    $attachmentsfilepath = "D:\Retrieve_Extract\$global:TargetFolder\attachs"
    $emailsfilepath = "D:\Retrieve_Extract\$global:TargetFolder\emails"
    $iocspath = "D:\Retrieve_Extract\$global:TargetFolder\iocs\"
    $MailboxHierarchy = "D:\Retrieve_Extract\$global:TargetFolder\MailboxHierarchy.txt"
    $global:Email_iocs += "FullFolderPath;SenderEmail;Subject;SentOn;Attach_list;Bodies"

    if (-not(Test-Path $filepath )) {
        New-Item -Path $filepath -ItemType "directory"  | Out-Null
    }
    if (-not(Test-Path $logsfilepath )) {
        New-Item -Path $filepath -Name "logs" -ItemType "directory"  | Out-Null
    }
    if (-not(Test-Path $attachmentsfilepath)) {
        New-Item -Path $filepath -Name "attachs" -ItemType "directory"  | Out-Null
    }
    if (-not(Test-Path $emailsfilepath )) {
        New-Item -Path $filepath -Name "emails" -ItemType "directory"  | Out-Null
    }
    if (-not(Test-Path $iocspath )) {
        New-Item -Path $filepath -Name "iocs" -ItemType "directory"  | Out-Null
    }

    Write-Output "`r";
    Write-Host -Fore DarkCyan "Parsing email items...(this may take a while)";

    #Add Interop Assembly 
    Add-type -AssemblyName "Microsoft.Office.Interop.Outlook" | Out-Null 
 
    #Type declaration for Outlook Enumerations
    #$olFolders = "Microsoft.Office.Interop.Outlook.olDefaultFolders" -as [type] 
    $olSaveType = "Microsoft.Office.Interop.Outlook.OlSaveAsType" -as [type] 
    $olClass = "Microsoft.Office.Interop.Outlook.OlObjectClass" -as [type] 
    $olSyncType = "Microsoft.Office.Interop.Outlook.SyncObject" -as [type] 

    $o = New-Object -comobject outlook.application
    $n = $o.GetNamespace("MAPI")
    Start-Sleep (5)

    $n.Logon()
    #$n.Logon("", "", "False", "True")

    $n.SendAndReceive("True")
    Start-Sleep (5)

    #$sycs = $n.SyncObjects
    #$f.Sync
    #$f = $n.PickFolder() #>>> Nice method to ask the user to pick up a folder
    
    #Select here the folder to be browsed
    #$myfolder = "test"
    $f = $n.Folders.Item($global:TargetMailbox).Folders.Item($global:TargetFolder)
    $subfolders = $f.Folders

    Add-content -path $MailboxHierarchy "`r================ $global:TargetFolder ==================`r"
    $prefix = "" #Reset prefix for toplevel folder
    foreach ($folder in $subfolders) {
        Get-MailboxFolder ($folder)
        Add-content -path $MailboxHierarchy "`n"
    } 



    ################## EXPORT THE RESULTS ##################

    #Export extracted IOC's
    Write-Output "`r";
    Write-Host -Fore DarkCyan "RESULTS:";
    Write-Host -Fore DarkCyan ">> Extracted $attachscount attachments out of $emailcount emails retrieved!";

    $Sender_email = $global:Sender_email | select -Unique
    $Sender_email | foreach {
        $_ | Out-File -FilePath $($iocspath + "sender_list.txt") -Append -Force
    }

    $Subject_name = $global:Subject_name | select -Unique
    $Subject_name | foreach {
        $_ | Out-File -FilePath $($iocspath + "subject_name.txt") -Append -Force
    }

    $Attach_name = $global:Attach_list | select -Unique
    $Attach_name | foreach {
        $_ | Out-File -FilePath $($iocspath + "attach_name.txt") -Append -Force
    }

    $global:Email_iocs | foreach {
        $_ | Out-File -FilePath $($iocspath + "Emails_iocs.csv") -Encoding UTF8  -Append
    }    

    #Calculate hashes of exported attachments
    $hash_list = ls $attachmentsfilepath | Get-FileHash -Algorithm SHA256
    $hash_list | foreach {
        $filehashname = Split-Path $_.'Path' -leaf 
        $filehashname = $filehashname -replace '(.*?) - ', ''
        $hashes += $_.'Hash'
        $export += $_.'Hash' + "," + $filehashname
    }
    $UniqueHashes = $hashes | select -Unique
    $export = $export | select -Unique
    $export | out-file -FilePath $($iocspath + "hash_list.csv") -Encoding UTF8 -Append 

    #Parse the URL's from email bodies
    $global:bodies | foreach {
        $URLs += $_ | select-string -AllMatches '\b(?:(?:https?|ftp|file)://|www\.|ftp\.)(?:\([-A-Z0-9+&@#/%=~_|$?!:,.]*\)|[-A-Z0-9+&@#/%=~_|$?!:,.])*(?:\([-A-Z0-9+&@#/%=~_|$?!:,.]*\)|[A-Z0-9+&@#/%=~_|$])' | % { $_.Matches } | % { $_.Value }
    }
    $Unique_URLs = $URLs | select -Unique
    $Unique_URLs | select -Unique | Out-File -FilePath $($iocspath + "unique_urls.csv") -Append -Force

    $SenderCount = $Sender_email.Count
    $SubjectCount = $Subject_name.Count
    $UniqueHashesCount = $UniqueHashes.Count
    $UniqueURLsCount = $Unique_URLs.Count

    Write-Host -Fore DarkCyan ">> Extracted $SenderCount unique Sender(s) out of $emailcount emails retrieved!";
    Write-Host -Fore DarkCyan ">> Extracted $SubjectCount unique Subject(s) out of $emailcount emails retrieved!";
    Write-Host -Fore DarkCyan ">> Extracted $UniqueHashesCount unique Attachment Hash(es) out of the $attachscount attachments extracted!";
    Write-Host -Fore DarkCyan ">> Extracted $UniqueURLsCount unique URL(s) out of the $emailcount emails retrieved!";
    #Write-Output "`r";
    #Write-Host -Fore Green "========== Email Parser Concluded ==========";
    Write-Output "`n";

    $o.Quit()
    Release-Ref($o)
    Remove-Variable f
    Remove-Variable n
    Remove-Variable o

    Start-Sleep(1)

}
