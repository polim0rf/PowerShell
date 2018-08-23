# Subnet_Tools [Collection]

## 1) Subnet_Calculator_list.ps1:
  Converts a list of IP addresses/Subnet mask pairs into CIDR notation
  
  ##### DESCRIPTION
  From a column named 'IP' and another 'Mask', this script converts these IP/Mask pairs into CIDR notation, exporting the results into a .txt file 'out.txt'.
  
  Columns are ";" separated.
  
  ##### PARAMETER file
  Indicates the location of the CSV file with the columns of addresses to convert.

  ##### NOTES
  * Version:        1.0.2
  * Author:         polim0rf
  * Creation Date:  09.04.2018
  * Purpose/Change: Initial script development

  ##### EXAMPLES
  GetNetworkID -file .\Netmon.csv
  
## 2) Check_Subnet.ps1:
  Looks up for the subnets where a given IP address is present.

  ##### DESCRIPTION
  Having an input CSV file with a list of Network addresses (taken from "Subnet_calculator_list.ps1" for example), this scripts checks in which subnets a given IP address can be present.
  
  The script looks for the presence of the 'Network' column within the CSV file.
  The results are exported into .\Searcher-output.csv

  ##### PARAMETER file
  Indicates the location of the CSV file with the columns of addresses to convert.

  ##### NOTES
  * Version:        1.0.2
  * Author:         polim0rf
  * Creation Date:  09.04.2018
  * Purpose/Change: Initial script development

  ##### EXAMPLES
  Check in which networks (subnets) from Netmon.csv file can the IP address 196.4.69.7 be present:
  
  - checksubnet -addr1 196.4.69.7 -file .\Netmon.csv
  
