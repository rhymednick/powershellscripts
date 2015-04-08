<#
	.SYNOPSIS
		Returns the environment variables that are part of the location-specific environment tool cache.
	
	.DESCRIPTION
		This function returns an array of key-value pairs that are associated with the location-specific environment tool cache. 
	
	.EXAMPLE
				PS C:\> Get-CacheFromEnvironment
	
	.NOTES
		
#>
function Get-CacheFromEnvironment
{
	[CmdletBinding()]
	[OutputType([array])]
	param ()
	
	# create a variable to hold our matches and use as a return value for the function
	$cachedItems = @()
	
	# scan the environment for cache items
	foreach ($cacheItem in (Get-ChildItem Env:))
	{
		if ($cacheItem.Name.StartsWith("cache."))
		{
			$cachedItems += $cacheItem
		}
	}
	
	# return the matches
	return $cachedItems
}

<#
	.SYNOPSIS
		Restores the folder-specific environment to its original state.
	
	.DESCRIPTION
		This function removes all changes that were made to provide a folder-specific environment and restores the modified vatiables to their original state.
	
	.EXAMPLE
				PS C:\> Undo-CustomEnvironment
	
	.NOTES
		
#>
function Undo-CustomEnvironment
{
	[CmdletBinding()]
	param ()
	
	$cachedItems = Get-CacheFromEnvironment
	if ($cachedItems.Length -ne 0)
	{
		foreach ($cacheItem in $cachedItems)
		{
			$oldName = $cacheItem.Name
			$newName = ([string]$cacheItem.Name).Substring(6)
			if ("_remove_".CompareTo($cacheItem.Value) -eq 0)
			{
				# We have a match, this needs to be removed from the environment.
				remove-item -Path "env:$newName" -Force
			}
			else
			{
				set-item -Path "env:$newName" -Value $cacheItem.Value
			}
			
			remove-item -Path "env:$oldName" -Force
		}
	}
}

#$ErrorActionPreference = "Continue"
#$WarningPreference = "Continue"

<#
	.SYNOPSIS
		Reads the local environment file and imports it into the active session's environment.
	
	.DESCRIPTION
		This function reads the local environment file and imports it into the active session's environment. Modified environment variables are cached so that they can be restored at a later point in time. 
	
	.PARAMETER localEnvFile
		The name of the file containing the local environment settings.
	
	.EXAMPLE
				PS C:\> Import-LocalEnvironmentFile -localEnvFile 'my_settings.txt'
	
	.NOTES
		
#>
function Import-LocalEnvironmentFile
{
	[CmdletBinding()]
	param
	(
		[string]
		$localEnvFile = "local_env.txt"
	)
	
	# Check for the local variables
	if (Test-Path $localEnvFile)
	{
		# Read them into an array
		[array]$variables = (Get-Content $localEnvFile)
		
		$global:statusTag = [string]::Format("Custom ({0})", $variables.Length)
		
		foreach ($variable in $variables)
		{
			$pair = $variable.Split('=');
			if ($pair.Length -eq 2)
			{
				# rename the values for readability
				$name = $pair[0]
				$value = $pair[1]
				
				if (Test-Path env:$name)
				{
					# rename the existing variable
					$null = rename-item -path env:$name -NewName cache.$name -Force
				}
				else
				{
					# the item doesn't exist already, so put it in there with a tag to have the
					# temporary one removed.
					$null = New-item -Path env: -Name cache.$name -Value "_remove_" -Force
				}
				
				# Now add the new item
				$null = New-Item -Path env: -Name $name -Value $value -Force
			}
		}
	}
	else
	{
		$global:statusTag = "Default"
	}
}

<#
	.SYNOPSIS
		Writes the contents of the local environment cache to the debug console.
	
	.DESCRIPTION
		Writes the contents of the local environment cache to the debug console.
	
	.EXAMPLE
				PS C:\> Trace-LocalEnvironmentCache
	
	.NOTES
		
#>
function Trace-LocalEnvironmentCache
{
	[CmdletBinding()]
	param ()
	$cache = Get-CacheFromEnvironment
	if ($cache.Length -ne 0)
	{
		foreach ($cacheItem in $cache)
		{
			Write-Debug ($cacheItem.Name + ":" + $cacheItem.Value)
		}
	}
}

<#
	.SYNOPSIS
		Indicates if the current folder has changed since the last time the PowerShell prompt was displayed.
	
	.DESCRIPTION
		This function checks if the current folder has changed since the last time the PowerShell prompt was displayed. If so, it returns $True.
	
	.EXAMPLE
				PS C:\> if (IsNewFolder) { Write-Host "new folder" }
	
	.NOTES
		
#>
function IsNewFolder
{
	[OutputType([bool])]
	param ()
	If (Test-Path variable:global:cachedFolder)
	{
		# The variable exists, so we should be looking to see if we're in a new folder.
		if ([string]::Compare($PWD.ToString(), $Global:cachedFolder, $True) -eq 0)
		{
			return $False
		}
	}
	
	$Global:cachedFolder = $PWD
	return $True
}

function prompt
{
	if (IsNewFolder)
	{
		Undo-CustomEnvironment
		Import-LocalEnvironmentFile
	}
	
	"PS [$global:statusTag] $PWD> "
}