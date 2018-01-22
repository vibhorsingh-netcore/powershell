## clear console
Clear-Host

## TODO: change  folder path on production
$EDC_PATH = "C:\Users\vibhor\Documents\NEW_EDC\EDC_WIN_SERVICE"
$LOG_PATH = "C:\Users\vibhor\Documents\NEW_EDC\EDC_WIN_SERVICE"
$LOG_FILE = "EDC_PS.log"
$LOG_FILE_FULL_PATH = Join-Path $LOG_PATH $LOG_FILE

## Logging function : https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0
function Write-Log
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path=$LOG_FILE_FULL_PATH,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$Level="Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )

    Begin
    {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process
    {
        
        # If the file already exists and NoClobber was specified, do not write to the log.
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }

        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }

        else {
            # Nothing to see here yet.
            }

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
                }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
                }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
                }
            }
        
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    }
}

## generic function to start EDC
Function startEDC() {
	cd $EDC_PATH
	set-item -path Env:CLASSPATH -value .\lib\* 
	Start-Process -WindowStyle Hidden java -ArgumentList '-Xms400m', '-Xmx500m', 'com.netcore.edc.EDC' -RedirectStandardOutput '.\console.out' -RedirectStandardError '.\console.err'
}

## Print running EDC process details
Function getEDCProcessDetails() {
	Get-WmiObject win32_process -Filter "CommandLine Like '%EDC%'" | Format-Table ProcessName,CreationDate,ProcessId,ParentProcessId,CommandLine -Auto | Out-File -Append $LOG_FILE_FULL_PATH;
}


## Start

Write-Log -Message " "
Write-Log -Message " "
Write-Log -Message " "
Write-Log -Message "++++++++++STARTING+++++++"

## process counter
$running = 0

## count the number of processes of EDC
Get-WmiObject win32_process -Filter "CommandLine Like '%EDC%'" | Select ProcessId | Foreach-Object {
	$running++
}

## Log
Write-Log -Message "Number of EDC instances running: $running"

## If none then run EDC
## If more than 1 kill all and start one
## Else all fine


if ($running -lt 1) {
	Write-Log -Message "No EDC running";
	Write-Log -Message "Starting EDC in background";
	startEDC
	getEDCProcessDetails
	
} elseif ($running -gt 1) {
	Write-Log -Message "More than 1 EDC running";
	
	getEDCProcessDetails
	
	Write-Log -Message "Killing EDC instances"
	
	(Get-WmiObject win32_process -Filter "CommandLine Like '%EDC%'").Terminate();
	
	Write-Log -Message "Starting Single EDC in background"
	startEDC
} else {
	Write-Log -Message "EDC running properly";
	getEDCProcessDetails
}
Exit $LASTEXITCODE
Write-Log -Message "++++++++++ENDING+++++++"

