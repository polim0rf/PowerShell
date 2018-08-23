# ISEReader

### SYNOPSIS
  Get the information extracted from CISCO ISE CSV exports.
  
  About [CISCO ISE](https://www.cisco.com/c/en/us/products/security/identity-services-engine/index.html).
  
  

### DESCRIPTION

 This script queries the ISE CSV file using MS Access driver, in order to query information "Database-style"
 instead of going through each line through PS. The scripts needs both drivers below to run properly, as well as
 running in Powershell x86:
 
 * http://www.microsoft.com/download/en/details.aspx?id=13255
 
 * http://www.microsoft.com/download/en/confirmation.aspx?id=23734

 This script reads a file called "ISE.csv" located at "C:\ISEreader". Change the name and path as needed.


### ROADMAP

 - [ ] For some reason queries by hostname are not properly resolved. To be worked on.
 - [ ] Need to continue testing in case there are duplicate entries.
 - [ ] Usernames can be in different columns than the "Username" column in ISE exports. An enhancement could be to query 
 other columns as well. To be tested.


### PARAMETERS 

    -username
    -computername
    -macaddress
    -hostname (TBD)   


### NOTES

  - Version:        1.1.0
  - Author:         polim0rf
  - Creation Date:  26.06.2018
  - Purpose/Change: Initial script development


### EXAMPLES

 * ISEreader -macaddress 00-1E-65-02-A5-74
 * ISEreader -ipaddress 10.10.10.10
 * ISEreader -username john.doe

   TBD:
 * ISEreader -hostname < hostname >

