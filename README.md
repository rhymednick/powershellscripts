# Rhy's PowerShell Scripts

This is the project that I'm using to store my PowerShell scripts. They are free to use by anyone.

The profile.ps1 script is my base profile script. The first thing it does is creates a "script" PS drive that makes it easier to access my scripts. I clone this git project into a folder on my hard drive and then the profile allows me to access the scripts using drive notation, like this:

> scripts:\profile.ps1

The rest of the profile script is a small application of sorts that is tied into my command prompt. It creates environment variables based on a local text file in a folder. When the folder is made current, the variables are loaded into the environment and when navigating away from the folder the variables are removed. I created this implementation on my own, but it's not an original concept. It's something a friend showed me on a Linux box he was using. I can't remember what the BASH version was called but if I find it, I'll link to it.

If you have any comments or suggestions, please feel free to share. I'm happy to discuss anything I have here. 

-Rhy