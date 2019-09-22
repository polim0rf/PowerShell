# O365Retriever

### SYNOPSIS
    Retrieve emails automatically from Office 365 and extracts their IOC's

### DESCRIPTION

 This script automatically retrieves all the emails from a given list  (Typically an Office 365 Trace log
  and then parses relevant IOC's from them saving a copy of the emails and attachments in the filesystem.
  List of additional IOC's retrieved:
    -Body URL's
    -Subjects
    -Sender emails
    -Attachment hashes
    -Mail Item folder hierarchy
 
 This script is aiming to help incident responders to retrieve a long list of emails for finding randomized URLs, attachments, etc...


### ROADMAP

 - [ ] Improve Error handling


### PARAMETERS 

    -O365 <path_to_tracelog> : Parameter containing the path to the O365 Trace logs of emails to be retrieved and processed.


### NOTES

  - Version:        2.1
  - Author:         Nicolas Fernandez Osinaga
  - Creation Date:  20.09.2019
  - Purpose/Change: Initial script development


### EXAMPLE

    Search for a single hash (Malicious Nemucod JS sample)
    * O365Retriever.ps1 -O365 .\Trace.log

   
