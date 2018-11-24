# URLcategory

### SYNOPSIS
  Get and submit BlueCoat category information for URL's
  
  About [BlueCoat URL Submissions page](http://sitereview.bluecoat.com/#/).
  

### DESCRIPTION

 This script retrieves category information for a list of URLs, and submit to Sitereview the ones that are still Unrated.


### PARAMETERS 

    -url: URL to categorize
    -cat: Integer number indicating possible category
    -comment: Required comment
    -list: List of URLs in TXT file   


### NOTES

  - Version:        1.0.0
  - Author:         polim0rf
  - Creation Date:  23.11.2018
  - Purpose/Change: Initial script development

  DISCLAIMER: Please be aware that querying SiteReview.com via scripts 
  is against their ToS. This script POC is only for educational purposes.


### EXAMPLES

   - Query single URL:
   URLcategory -cat 18 -comment Phishing -url https://mmmmkool.godaddysites.com 

   - Query list of URL from TXT file:
   URLcategory -cat 18 -comment Phishing -list ./list.txt

   - Type below command to see current list of categories:
   Show-Categories

