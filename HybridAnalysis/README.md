# HybridAnalysis

### SYNOPSIS
  Get information from Hybrid-Analysis.com sandbox using its free API
  
  About [Hybrid Analysis API](https://www.hybrid-analysis.com/docs/api/v2#).
  
  

### DESCRIPTION

 This script retrieves samples information from Hybrid-Analysis.com using its free API.
  A free account with Hybrid-Analysis is required to get the API key.


### ROADMAP

 - [ ] Improve Error handling
 - [ ] Improve Reports query capabilities. Currently downloaded as Misp XML report. To be added as optional parameter.
 - [ ] Improve hash input detection
 - [ ] Add functionalities to query API (such as URL query)


### PARAMETERS 

    -hash <hash_value> : Search for a single hash value (md5,sha256,sha1)
    -hashes <path_to_file> : Search for a list of hashes in a TXT file
    -term <term_value> : Search for the value of a specified term
        >> You can find the list of terms using command: HA -term help
    -url <url_value> : TBD 


### NOTES

  - Version:        0.0.6
  - Author:         Nicolas Fernandez Osinaga
  - Creation Date:  05.10.2018
  - Purpose/Change: Initial script development

  Thanks to these two blogs for understanding of psobjects handling:
  - https://www.gngrninja.com/script-ninja/2016/6/18/powershell-getting-started-part-12-creating-custom-objects#add
  - https://learn-powershell.net/2014/01/24/avoiding-system-object-or-similar-output-when-using-export-csv/


### EXAMPLES

    Search for a single hash (Malicious Nemucod JS sample)
    * HA -hash 3ea1112ba44f600227f4f1fbb650b3e68fe3c0a5ea02f9c2c2c165eded825b92 

    Search for a list of hashes (md5,sha1,sha256)
    * HA -hashes ./hashes.txt

    Search for the value of a HA term and list the results:
    * HA -term vx_family


