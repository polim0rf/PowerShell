
.SYNOPSIS
 Automates queries to SolarWinds given a list of IP addresses.

.DESCRIPTION
 This script queries the SolarWinds API (SolarWinds Framework) in order to automate the DB queries 
 given a list of IP addresses from a txt file.
 It is necessary to run the script with Admin credentials and to have the SWISS Powershell module 
 installed. (Check SolarWinds API documentation)

 This script will gather all data from a solarwinds database called 'IPMan', given an IP from a list.

.NOTES
  Version:        1.1.0
   Author:        Nicolas Fernandez Osinaga
  Creation Date:  19.07.2018
  Purpose/Change: Initial script development

.EXAMPLE
  Just run the script.
  Modify first the Initial variables and sql_query
