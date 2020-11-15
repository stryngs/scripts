Get-ADComputer -Filter 'enabled -eq $true' -Property * | Select-Object Name, Description, DistinguishedName, OperatingSystem | Export-CSV domain-nodes.csv -NoTypeInformation -Encoding UTF8
