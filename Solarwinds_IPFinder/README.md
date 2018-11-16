# Solarwinds_IPFinder

### SYNOPSIS
  Automates queries to SolarWinds given a list of IP addresses.
  
  About [Solarwinds](https://www.solarwinds.com/).
  About [SWISS PS TOOL](https://github.com/solarwinds/OrionSDK/wiki/About-SWIS).
  
  

### DESCRIPTION

 This script queries the SolarWinds API (SolarWinds Framework) in order to automate the DB queries 
 given a list of IP addresses from a txt file.
 It is necessary to run the script with Admin credentials and to have the SWISS Powershell module 
 installed. (Check SolarWinds API documentation)

 This script will gather all data from a solarwinds database called 'IPAM', given an IP from a list.
 It will create the output on a CSV file: Solarwinds_IPfinder-Output.csv


### ROADMAP

 - [ ] TBD


### PARAMETERS 

 - [ ] TBD


### NOTES

  - Version:        1.1.0
  - Author:         polim0rf
  - Creation Date:  19.07.2018
  - Purpose/Change: Initial script development


### EXAMPLES

 * Just run the script modifying first the Initial variables and the sql_query

