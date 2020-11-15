Import-Module ActiveDirectory
 
# All of the properties you'd like to pull from Get-ADUser
$properties=@(
    'description',
    'cn',
    'created',
    'emailaddress',
    'displayname',
    'lastlogondate',
    'lockedout',
    'memberof',
    'passwordneverexpires',
    'passwordexpired',
    'passwordnotrequired',
	'passwordlastset',
	'SamAccountName',
    'OtherName',
    'DistinguishedName'
    )
 
 
# All of the expressions you want with all of the filtering .etc you'd like done to them
$expressions=@(
    @{Expression={$_.Description};Label="description"},
    @{Expression={$_.CN};Label="cn"},
    @{Expression={$_.Created};Label="created_date"},
    @{Expression={$_.EmailAddress};Label="email"},
    @{Expression={$_.DisplayName};Label="display_name"},
    @{Expression={$_.LastLogonDate};Label="last_logon"},
    @{Expression={$_.LockedOut};Label="locked_out"},
    @{Expression={$_.MemberOf -join ";"};Label="member_of"},
    @{Expression={$_.PasswordNeverExpires};Label="no_pass_expiration"},
    @{Expression={$_.PasswordExpired};Label="password_expired"},
    @{Expression={$_.PasswordNotRequired};Label="password_not_required"},
	@{Expression={$_.PasswordLastSet};Label="password_last_set"},
	@{Expression={$_.SamAccountName};Label="acct_name"},
	@{Expression={$_.OtherName};Label="other_name"},
	@{Expression={$_.DistinguishedName};Label="dn"}
    )
 
$path_to_file = ".\domain-users.csv"
$path_to_file2 = ".\domain-users_full.csv"

Get-ADUser -Filter 'enabled -eq $true' -Properties $properties | select $expressions | Export-CSV $path_to_file -notypeinformation -Encoding UTF8
