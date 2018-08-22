<#
.SYNOPSIS
  Get the information extracted from CISCO ISE CSV exports.

.DESCRIPTION
 This script queries the ISE CSV file using MS Access driver, in order to query information "Database-style"
 instead of going through each line through PS. The scripts needs both drivers below to run properly, as well as
 running in Powershell x86:
 http://www.microsoft.com/download/en/details.aspx?id=13255
 http://www.microsoft.com/download/en/confirmation.aspx?id=23734

 This script reads a file called "ISE.csv" located at "C:\ISEreader". Change the name and path as needed.

.ROADMAP
 -For some reason queries by hostname are not properly resolved. To be worked on.
 -Need to continue testing in case there are duplicate entries.
 -Usernames can be in different columns than the "Username" column in ISE exports. An enhancement could be to query 
 other columns as well. To be tested.

.PARAMETER 
    Username,computername,macaddress
    Hostname?    

.NOTES
  Version:        1.1.0
   Author:        polim0rf
  Creation Date:  26.06.2018
  Purpose/Change: Initial script development

.EXAMPLE
  ISEreader -macaddress 00-1E-65-02-A5-74
  ISEreader -ipaddress 10.10.10.10
  ISEreader -username john.doe

  To be researched:
  ISEreader -hostname <hostname>
#>

Function ISEreader {

    param (
        [string]$username,
        [string]$hostname,
        [string]$ipaddress,
        [string]$macaddress
    )

    Clear-Host

    #STart counter
    $elapsed = [System.Diagnostics.Stopwatch]::StartNew() 

    Write-Host "Starting new search..." -ForegroundColor Green

    $conn = New-Object System.Data.OleDb.OleDbConnection("Provider=Microsoft.ACE.OLEDB.12.0;Data Source='C:\ISEreader';Extended Properties='Text;HDR=Yes;FMT=Delimited';")
    $cmd = $conn.CreateCommand()

    #Queries depending on command input:
    If (($username -ne $null) -and ($username -ne "")) {
        $cmd.CommandText = "Select * from ISE.csv where PassiveID_Username like '$username'"
    }
    If (($hostname -ne $null) -and ($hostname -ne "")) {
        $cmd.CommandText = "Select * from ISE.csv where hostname like '$computername'"
    }
    If (($ipaddress -ne $null) -and ($ipaddress -ne "")) {
        $cmd.CommandText = "Select * from ISE.csv where ip like '$ipaddress'"
    }
    If (($macaddress -ne $null) -and ($macaddress -ne "")) {
        $cmd.CommandText = "Select * from ISE.csv where MACAddress like '$macaddress'"
    }
    
    $conn.open()
    $data = $cmd.ExecuteReader()

    # List of available fields in CISCO ISE CSV exports (unmark the ones you desire to be exported)
    $data | ForEach-Object {
        [pscustomobject]@{
            MACAddress                     = $_.GetValue(0) 
            EndPointPolicy                 = $_.GetValue(1) 
            #IdentityGroup                  = $_.GetValue(2)
            #AuthenticationIdentityStore    = $_.GetValue(3)
            #AuthenticationMethod           = $_.GetValue(4)
            #AllowedProtocolMatchedRule     = $_.GetValue(5)
            AuthorizationPolicyMatchedRule = $_.GetValue(6)
            SelectedAuthorizationProfiles  = $_.GetValue(7)
            #Description                    = $_.GetValue(8)
            #DeviceRegistrationStatus       = $_.GetValue(9)
            #BYODRegistration               = $_.GetValue(10)
            DeviceType                     = $_.GetValue(11)
            EmailAddress                   = $_.GetValue(12)
            ip                             = $_.GetValue(13)
            #ipv6                           = $_.GetValue(14)
            #FirstName                      = $_.GetValue(15)
            hostname                       = $_.GetValue(16)
            #LastName                       = $_.GetValue(17)
            #LogicalProfile                 = $_.GetValue(18)
            #TotalCertaintyFactor           = $_.GetValue(19)
            #MDMCompliant                   = $_.GetValue(20)
            #MDMCompliantFailureReason      = $_.GetValue(21)
            #MDMDiskEncrypted               = $_.GetValue(22)
            #MDMJailBroken                  = $_.GetValue(23)
            #MDMPinLockSet                  = $_.GetValue(24)
            #MDMServerID                    = $_.GetValue(25)
            #MDMServerName                  = $_.GetValue(26)
            #MDMEnrolled                    = $_.GetValue(27)
            NADAddress                     = $_.GetValue(28)
            Location                       = $_.GetValue(29)
            NAS_IP_Address                 = $_.GetValue(30)
            #NAS_IPv6_Address               = $_.GetValue(31)
            NAS_Port_Id                    = $_.GetValue(32)
            UserName                       = $_.GetValue(33)
            NetworkDeviceName              = $_.GetValue(34)
            #OS                             = $_.GetValue(35)
            #OS_result                      = $_.GetValue(36)
            #PostureOS                      = $_.GetValue(37)
            #OSVersion                      = $_.GetValue(38)
            #OUI                            = $_.GetValue(39)
            #PortalUser                     = $_.GetValue(40)
            #PosturePolicyMatched           = $_.GetValue(41)
            #PostureStatus                  = $_.GetValue(42)
            #User_Name                      = $_.GetValue(43)
            #StaticAssignment               = $_.GetValue(44)
            #StaticGroupAssignment          = $_.GetValue(45)
            #UpdateTime                     = $_.GetValue(46)
            #MessageCode                    = $_.GetValue(47)
            #FailureReason                  = $_.GetValue(48)
            #UserType                       = $_.GetValue(49)
            #EndpointIdentityGroup          = $_.GetValue(50)
            #EndpointOperatingSystem        = $_.GetValue(51)
            #MDMOSVersion                   = $_.GetValue(52)
            #PortalUserFirstName            = $_.GetValue(53)
            #PortalUserLastName             = $_.GetValue(54)
            PortalUserEmailAddress         = $_.GetValue(55)
            #PortalUserPhoneNumber          = $_.GetValue(56)
            #PortalUserGuestType            = $_.GetValue(57)
            #PortalUserGuestStatus          = $_.GetValue(58)
            #PortalUserLocation             = $_.GetValue(59)
            #PortalUserGuestSponsor         = $_.GetValue(60)
            #PortalUserCreationType         = $_.GetValue(61)
            #AUPAccepted                    = $_.GetValue(62)
            #EndPointGroup                  = $_.GetValue(63)
            #EndPointProfilerServer         = $_.GetValue(64)
            #ctssecuritygroup               = $_.GetValue(65)
            #AntiVirusInstalled             = $_.GetValue(66)
            #AntiSpywareInstalled           = $_.GetValue(67)
            #Failure_Reason                 = $_.GetValue(68)
            #PassiveID_Username             = $_.GetValue(69)
            #DeviceCompliance               = $_.GetValue(70)
            #ADOperatingSystem              = $_.GetValue(71)
            #CertificateExpirationDate      = $_.GetValue(72)
            #CertificateIssueDate           = $_.GetValue(73)
            #CertificateIssuerName          = $_.GetValue(74)
            #UserFetchDepartment            = $_.GetValue(75)
            #UserFetchTelephone             = $_.GetValue(76)
            #UserFetchJobTitle              = $_.GetValue(77)
            #UserFetchOrganizationalUnit    = $_.GetValue(78)
            #UserFetchCountryName           = $_.GetValue(79)
            #UserFetchLocalityName          = $_.GetValue(80)
            #UserFetchStateOrProvinceName   = $_.GetValue(81)
            #UserFetchStreetAddress         = $_.GetValue(82)
            #UserFetchFirstName             = $_.GetValue(83)
            #UserFetchEmail                 = $_.GetValue(84)
            #UserFetchLastName              = $_.GetValue(85)
            #SSID                           = $_.GetValue(86)
            #DTLSSupport                    = $_.GetValue(87)
            #PortalName                     = $_.GetValue(88)
            #RegistrationTimeStamp          = $_.GetValue(89)
            #AnomalousBehaviour             = $_.GetValue(90)
            #PhoneID                        = $_.GetValue(91)
            #posturePassCondition           = $_.GetValue(92)
            #postureFailCondition           = $_.GetValue(93)
        }
    }

    $cmd.Dispose()
    $conn.Dispose()

    #Total Time:
    $totaltime = [math]::Round($elapsed.Elapsed.TotalSeconds, 2)

    Write-Host "Total Elapsed Time: $totaltime seconds." -ForegroundColor Green

}
