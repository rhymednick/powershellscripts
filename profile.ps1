# If the scripts drive is not mapped, then attempt to map it to the named folder in the users Dropbox. 
If (!(Test-Path scripts:))
{
    New-PSDrive -name scripts -PSProvider FileSystem -Root 'C:\git\powershellscripts'
}


$ErrorActionPreference = "Continue"
$WarningPreference = "Continue"

function GetCacheFromEnvironment
{
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

function CleanupEnvironment
{
    $cachedItems = GetCacheFromEnvironment
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

function LoadLocalEnvironment 
{
    # Check for the local variables
    if (Test-Path "local_env.txt") 
    {
        $global:statusTag = "Custom"

        # Read them into an array
        $variables = (Get-Content "local_env.txt")

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

function ShowCache 
{
    $cache = GetCacheFromEnvironment
    if ($cache.Length -ne 0) 
    {
        foreach ($cacheItem in $cache)
        {
            Write-Warning ($cacheItem.Name + ":" + $cacheItem.Value)
        }
    }
}

function IsNewFolder 
{
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
        CleanupEnvironment
        LoadLocalEnvironment
    }

    "PS [$global:statusTag] $PWD> "
}