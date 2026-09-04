
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, HelpMessage="Drive letter of mounted Windows 11 ISO (e.g., E)")]
    [ValidatePattern('^[c-zC-Z]$')]
    [string]$ISO,

    [Parameter(Mandatory=$false, HelpMessage="Windows image index (1=Home, 6=Pro, etc.). If omitted, you will be prompted.")]
    [int]$INDEX = 0,

    [Parameter(Mandatory=$false, HelpMessage="Scratch disk drive letter (defaults to script directory)")]
    [ValidatePattern('^[c-zC-Z]$')]
    [string]$SCRATCH,

    [Parameter(Mandatory=$false, HelpMessage="Skip cleanup of temporary files")]
    [switch]$SkipCleanup,

    [Parameter(Mandatory=$false, HelpMessage="Preserve winre.wim instead of deleting it.")]
    [switch]$PreserveWinRE,

    [Parameter(Mandatory=$false, HelpMessage="Enable ESD (LZMS) compression for a smaller ISO.")]
    [switch]$ESD
)





Write-Host "Initializing sequence $(Get-Random -Minimum 1000 -Maximum 9999)..." -ForegroundColor Cyan
Write-Host "Initializing sequence $(Get-Random -Minimum 1000 -Maximum 9999)..." -ForegroundColor Cyan
Write-Host "Initializing sequence $(Get-Random -Minimum 1000 -Maximum 9999)..." -ForegroundColor Cyan

$global:RemoveDefender = $true
$global:RemoveEdgeAndOneDrive = $true
$global:AggressiveDebloat = $true
$global:RemoveDrivers = $false # Keep essential drivers for Nano

if (-not $SCRATCH) {
    $ScratchDisk = $PSScriptRoot -replace '[\\]+$', ''
} else {
    $ScratchDisk = $SCRATCH + ":"
}

$DriveLetter = $ISO + ":"
$wimFilePath = "$ScratchDisk\TejOS_temp\sources\install.wim"
$scratchDir = "$ScratchDisk\scratchdir"
$nano11Dir = "$ScratchDisk\TejOS_temp"
$outputISO = "$PSScriptRoot\TejOS-Nano.iso"
$logFile = "$PSScriptRoot\TejOS-Nano-$(Get-Date -Format yyyyMMdd_HHmmss).log"

try {
    $adminSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $adminGroup = $adminSID.Translate([System.Security.Principal.NTAccount])
} catch {
    Write-Warning "Failed to resolve Administrator group SID. Defaulting to 'Administrators'."
    $adminGroup = [PSCustomObject]@{ Value = "Administrators" }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Output $logMessage
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
}

function Set-RegistryValue {
    param (
        [string]$path,
        [string]$name,
        [string]$type,
        [string]$value
    )
    try {
        if ($name) {
            $output = & 'reg' 'add' $path '/v' $name '/t' $type '/d' $value '/f' 2>&1
        } else {
            $output = & 'reg' 'add' $path '/ve' '/t' $type '/d' $value '/f' 2>&1
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        } else {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        }
    } catch {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
    }
}

function Remove-RegistryKey {
    param([string]$path)
    try {
        & 'reg' 'delete' $path '/f' 2>&1 | Out-Null
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    } catch {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
    }
}

function Remove-RegistryValue {



    param([string]$path)
    $lastSlash = $path.LastIndexOf('\')
    if ($lastSlash -lt 0) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        return
    }
    $keyPath = $path.Substring(0, $lastSlash)
    $valueName = $path.Substring($lastSlash + 1)
    try {
        & 'reg' 'delete' $keyPath '/v' $valueName '/f' 2>&1 | Out-Null
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    } catch {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
    }
}

function Test-Prerequisites {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

    if (-not $myWindowsPrincipal.IsInRole($adminRole)) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "ERROR"
        throw "Administrative privileges required"
    }

    if (-not (Test-Path "$DriveLetter\sources\boot.wim")) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "ERROR"
        throw "Invalid Windows 11 ISO mount point"
    }

    if (-not (Test-Path "$DriveLetter\sources\install.wim") -and -not (Test-Path "$DriveLetter\sources\install.esd")) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "ERROR"
        throw "Windows installation files not found"
    }

    $disk = Get-PSDrive -Name $ScratchDisk[0] -ErrorAction SilentlyContinue
    if ($disk) {
        $freeGB = [math]::Round($disk.Free / 1GB, 2)
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        if ($freeGB -lt 30) {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        }
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Initialize-Directories {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Add-MpPreference -ExclusionPath $PSScriptRoot -ErrorAction SilentlyContinue
    if ($ScratchDisk -ne $PSScriptRoot) {
        Add-MpPreference -ExclusionPath $ScratchDisk -ErrorAction SilentlyContinue
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    New-Item -ItemType Directory -Force -Path "$nano11Dir\sources" | Out-Null
    New-Item -ItemType Directory -Force -Path $scratchDir | Out-Null
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Convert-ESDToWIM {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $esdPath = "$DriveLetter\sources\install.esd"
    $tempWimPath = "$nano11Dir\sources\install.wim"

    $images = Get-WindowsImage -ImagePath $esdPath
    $validIndices = $images.ImageIndex

    if ($INDEX -notin $validIndices) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "ERROR"
        throw "Image index $INDEX not found in install.esd"
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Export-WindowsImage -SourceImagePath $esdPath -SourceIndex $INDEX `
        -DestinationImagePath $tempWimPath -CompressionType Maximum -CheckIntegrity

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Copy-WindowsFiles {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Copy-Item -Path "$DriveLetter\*" -Destination $nano11Dir -Recurse -Force -ErrorAction SilentlyContinue

    if (Test-Path "$nano11Dir\sources\install.esd") {
        Remove-Item "$nano11Dir\sources\install.esd" -Force -ErrorAction SilentlyContinue
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Resolve-ImageIndex {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    
    $sourceImagePath = ""
    if (Test-Path "$DriveLetter\sources\install.wim") {
        $sourceImagePath = "$DriveLetter\sources\install.wim"
    } elseif (Test-Path "$DriveLetter\sources\install.esd") {
        $sourceImagePath = "$DriveLetter\sources\install.esd"
    } else {
        throw "Windows installation files not found on ISO"
    }
    
    $images = Get-WindowsImage -ImagePath $sourceImagePath
    $validIndices = $images.ImageIndex
    
    if ($INDEX -eq 0) {
        Write-Host "Initializing sequence $(Get-Random -Minimum 1000 -Maximum 9999)..." -ForegroundColor Cyan
        Write-Host "Initializing sequence $(Get-Random -Minimum 1000 -Maximum 9999)..." -ForegroundColor Cyan
        Write-Host "Initializing sequence $(Get-Random -Minimum 1000 -Maximum 9999)..." -ForegroundColor Cyan
        Write-Host "Initializing sequence $(Get-Random -Minimum 1000 -Maximum 9999)..."
        Write-Host ""
        foreach ($img in $images) {
            Write-Host "Initializing sequence $(Get-Random -Minimum 1000 -Maximum 9999)..."
        }
        Write-Host ""
        $choice = Read-Host "Enter the index number"
        if ([int]::TryParse($choice, [ref]$script:INDEX)) {
            if ($script:INDEX -notin $validIndices) {
                Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "ERROR"
                throw "User selected an invalid index."
            }
        } else {
            throw "Invalid input."
        }
    } else {
        if ($INDEX -notin $validIndices) {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "ERROR"
            $images | ForEach-Object { Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." }
            throw "Image index $INDEX not found"
        }
        $script:INDEX = $INDEX
    }
    
    $selectedImage = $images | Where-Object { $_.ImageIndex -eq $script:INDEX }
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $script:DetectedImageName = $selectedImage.ImageName
    $script:DetectedFullVersion = ""
    try {
        $detailedImage = Get-WindowsImage -ImagePath $sourceImagePath -Index $script:INDEX
        if ($detailedImage -and ($detailedImage.PSObject.Properties.Match('Version').Count -gt 0)) {
            $script:DetectedFullVersion = $detailedImage.Version
        } else {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        }
    } catch {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
    }

    if ($script:DetectedFullVersion -match '(\d+\.\d+)$') {
        $script:DetectedBuildNumber = $Matches[1]
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    } else {
        $script:DetectedBuildNumber = ""
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
    }
}

function Mount-WindowsImageFile {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & takeown /F $wimFilePath /A | Out-Null
    & icacls $wimFilePath /grant "$($adminGroup.Value):(F)" | Out-Null
    Set-ItemProperty -Path $wimFilePath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue

    & dism /English "/mount-image" "/imagefile:$wimFilePath" "/index:$INDEX" "/mountdir:$scratchDir"
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Take-OwnershipOfFolders {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    
    $foldersToOwn = @(
        "$scratchDir\Windows\System32\DriverStore\FileRepository",
        "$scratchDir\Windows\Fonts",
        "$scratchDir\Windows\Web",
        "$scratchDir\Windows\Help",
        "$scratchDir\Windows\Cursors",
        "$scratchDir\Program Files (x86)\Microsoft",
        "$scratchDir\Program Files\WindowsApps",
        "$scratchDir\Windows\System32\Microsoft-Edge-Webview",
        "$scratchDir\Windows\System32\Recovery",
        "$scratchDir\Windows\WinSxS",
        "$scratchDir\Windows\assembly",
        "$scratchDir\ProgramData\Microsoft\Windows Defender",
        "$scratchDir\Windows\System32\InputMethod",
        "$scratchDir\Windows\Speech",
        "$scratchDir\Windows\Temp"
    )
    
    $filesToOwn = @(
        "$scratchDir\Windows\System32\OneDriveSetup.exe"
    )
    
    foreach ($folder in $foldersToOwn) {
        if (Test-Path $folder) {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            & takeown.exe /F $folder /R /D Y 2>$null | Out-Null
            & icacls.exe $folder /grant "$($adminGroup.Value):(F)" /T /C 2>$null | Out-Null
        }
    }
    
    foreach ($file in $filesToOwn) {
        if (Test-Path $file) {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            & takeown.exe /F $file 2>$null | Out-Null
            & icacls.exe $file /grant "$($adminGroup.Value):(F)" /C 2>$null | Out-Null
        }
    }
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Get-ImageMetadata {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $imageIntl = & dism /English /Get-Intl "/Image:$scratchDir"
    $languageLine = $imageIntl -split '\n' | Where-Object { $_ -match 'Default system UI language : ([a-zA-Z]{2}-[a-zA-Z]{2})' }

    if ($languageLine) {
        $script:languageCode = $Matches[1]
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    } else {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        $script:languageCode = "en-US"
    }

    $imageInfo = & dism /English /Get-WimInfo "/wimFile:$wimFilePath" "/index:$INDEX"
    $lines = $imageInfo -split '\r?\n'

    foreach ($line in $lines) {
        if ($line -like '*Architecture : *') {
            $script:architecture = $line -replace 'Architecture : ', ''
            if ($script:architecture -eq 'x64') {
                $script:architecture = 'amd64'
            }
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            break
        }
    }

    if (-not $script:architecture) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        $script:architecture = 'amd64'
    }
}

function Remove-BloatwareApps {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $packagesToRemove = Get-AppxProvisionedPackage -Path $scratchDir | Where-Object {
        $name = $_.PackageName
        
        $remove = ($name -like '*Zune*' -or
                   $name -like '*Bing*' -or
                   $name -like '*Clipchamp*' -or
                   $name -like '*Xbox*' -or
                   $name -like '*Gaming*' -or
                   $name -like '*People*' -or
                   $name -like '*PowerAutomate*' -or
                   $name -like '*Teams*' -or
                   $name -like '*Todos*' -or
                   $name -like '*YourPhone*' -or
                   $name -like '*Solitaire*' -or
                   $name -like '*FeedbackHub*' -or
                   $name -like '*Maps*' -or
                   $name -like '*OfficeHub*' -or
                   $name -like '*Help*' -or
                   $name -like '*Family*' -or
                   $name -like '*CommunicationsApps*' -or
                   $name -like '*Copilot*' -or
                   $name -like '*DevHome*' -or
                   $name -like '*QuickAssist*' -or
                   $name -like '*Recall*' -or
                   $name -like '*WebExperience*' -or
                   $name -like '*StorePurchaseApp*' -or
                   $name -like '*WindowsAI*' -or
                   $name -like '*CrossDevice*' -or
                   $name -like '*RemoteDesktop*' -or
                   $name -like '*Windows365*' -or
                   $name -like '*CloudPC*' -or
                   $name -like '*OutlookForWindows*' -or
                   $name -like '*WindowsAppRuntime*' -or
                   $name -like '*MicrosoftWindows.Client*' -or
                   $name -like '*StartExperiences*' -or
                   $name -like '*Calculator*' -or
                   $name -like '*SoundRecorder*' -or
                   $name -like '*Alarms*' -or
                   $name -like '*MicrosoftStickyNotes*' -or
                   $name -like '*Photos*' -or
                   $name -like '*ScreenSketch*' -or
                   $name -like '*Camera*' -or
                   $name -like '*Paint*' -or
                   $name -like '*Notepad*' -or
                   $name -like '*Terminal*' -or
                   $name -like '*AV1VideoExtension*' -or
                   $name -like '*AVCEncoderVideoExtension*' -or
                   $name -like '*HEIFImageExtension*' -or
                   $name -like '*HEVCVideoExtension*' -or
                   $name -like '*VP9VideoExtensions*' -or
                   $name -like '*WebpImageExtension*' -or
                   $name -like '*MPEG2VideoExtension*' -or
                   $name -like '*WebMediaExtensions*' -or
                   $name -like '*RawImageExtension*' -or
                   $name -like '*SecHealthUI*')

        return $remove
    }

    $removeCount = 0
    foreach ($package in $packagesToRemove) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        try {
            Remove-AppxProvisionedPackage -Path $scratchDir -PackageName $package.PackageName -ErrorAction Stop | Out-Null
            $removeCount++
        } catch {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        }
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    foreach ($package in $packagesToRemove) {
        $folderPath = Join-Path "$scratchDir\Program Files\WindowsApps" $package.PackageName
        if (Test-Path $folderPath) {
            Remove-Item $folderPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Remove-SystemPackages {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $packagePatterns = @(
        "Microsoft-Windows-LanguageFeatures-Handwriting-$($script:languageCode)-Package~",
        "Microsoft-Windows-LanguageFeatures-OCR-$($script:languageCode)-Package~",
        "Microsoft-Windows-LanguageFeatures-Speech-$($script:languageCode)-Package~",
        "Microsoft-Windows-LanguageFeatures-TextToSpeech-$($script:languageCode)-Package~",
        "Microsoft-Windows-Printing-PMCPPC-FoD-Package~",
        "Microsoft-Windows-WebcamExperience-Package~",
        "Microsoft-Media-MPEG2-Decoder-Package~",
        "UserExperience-Recall-Package~",
        "Microsoft-Windows-AppManagement-AppV-Package~",
        "Microsoft-Windows-InternetExplorer-Optional-Package~",
        "Microsoft-Windows-MediaPlayer-Package~",
        "Microsoft-Windows-WordPad-FoD-Package~",
        "Microsoft-Windows-StepsRecorder-Package~",
        "Microsoft-Windows-MSPaint-FoD-Package~",
        "Microsoft-Windows-SnippingTool-FoD-Package~",
        "Microsoft-Windows-TabletPCMath-Package~",
        "Microsoft-Windows-Xps-Xps-Viewer-Opt-Package~",
        "Microsoft-Windows-PowerShell-ISE-FOD-Package~",
        "OpenSSH-Client-Package~",
        "Microsoft-Windows-Search-Engine-Client-Package~",
        "Microsoft-Windows-Kernel-LA57-FoD-Package~",
        "Microsoft-Windows-Hello-Face-Package~",
        "Microsoft-Windows-Hello-BioEnrollment-Package~",
        "Microsoft-Windows-BitLocker-DriveEncryption-FVE-Package~",
        "Microsoft-Windows-TPM-WMI-Provider-Package~",
        "Microsoft-Windows-Narrator-App-Package~",
        "Microsoft-Windows-Magnifier-App-Package~",
        "Windows-Defender-Client-Package~"
    )

    $allPackages = & dism /image:$scratchDir /Get-Packages /Format:Table
    $allPackages = $allPackages -split "`n" | Select-Object -Skip 1

    $removeCount = 0
    foreach ($packagePattern in $packagePatterns) {
        $packagesToRemove = $allPackages | Where-Object { $_ -like "$packagePattern*" }
        foreach ($package in $packagesToRemove) {
            $packageIdentity = ($package -split "\s+")[0]
            if ($packageIdentity) {
                Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
                & dism /image:$scratchDir /Remove-Package /PackageName:$packageIdentity /Quiet /NoRestart 2>$null | Out-Null
                $removeCount++
            }
        }
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & dism.exe /Image:"$scratchDir" /Remove-Package /PackageName:Microsoft-Windows-Wallpaper-Content-Extended-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1 /NoRestart 2>$null | Out-Null
    & dism.exe /Image:"$scratchDir" /Remove-Package /PackageName:Microsoft-Windows-Wallpaper-Content-Extended-FoD-Package~31bf3856ad364e35~amd64~~10.0.29648.1000 /NoRestart 2>$null | Out-Null
}

function Remove-NativeImages {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $nativeImagesPath = "$scratchDir\Windows\assembly\NativeImages_*"
    Remove-Item -Path $nativeImagesPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Slim-DriverStore {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    
    $driverRepo = "$scratchDir\Windows\System32\DriverStore\FileRepository"
    
    $patternsToRemove = @(
        'prn*',      # Printer drivers
        'scan*',     # Scanner drivers
        'wscsmd.inf*', # Smartcard readers
        'tapdrv*',   # Tape drives
        'tdibth.inf*', # Bluetooth Personal Area Network
        'mdm*',      # Modem / Fax drivers
        'flp*',      # Floppy disk drivers
        'bda*',      # TV Tuner / Broadcasting drivers
        'nvda*',     # NVIDIA massive OEM display drivers (OS will fallback to MS Basic Display)
        'amda*',     # AMD massive OEM display drivers
        'igdlh*'     # Intel massive OEM display drivers
    )

    $removeCount = 0
    Get-ChildItem -Path $driverRepo -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $driverFolder = $_.Name
        
        if ($driverFolder -match "synpd|etd|ps2|i8042prt|i2c|hidi2c|hid") {
            return
        }

        foreach ($pattern in $patternsToRemove) {
            if ($driverFolder -like $pattern) {
                Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                $removeCount++
                break
            }
        }
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Reduce-Fonts {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    
    $fontsPath = "$scratchDir\Windows\Fonts"
    if (Test-Path $fontsPath) {

        Get-ChildItem -Path $fontsPath -Exclude "segoe*.*", "tahoma*.*", "marlett.ttf", "8541oem.fon", "segui*.*", "consol*.*", "lucon*.*", "calibri*.*", "arial*.*", "times*.*", "cou*.*", "8*.*", "nirmala*.*", "mangal*.*", "mingli*", "msjh*", "msyh*", "malgun*", "meiryo*", "yugoth*" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}



function Remove-MiscellaneousFiles {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    
    Remove-Item -Path "$scratchDir\Windows\Speech" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$scratchDir\ProgramData\Microsoft\Windows\WER" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$scratchDir\ProgramData\Microsoft\Windows Defender\Definition Updates" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$scratchDir\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue




    Remove-Item -Path "$scratchDir\Windows\Help" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$scratchDir\Windows\Cursors" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Remove-Item -Path "$scratchDir\Windows\System32\usoclient.exe" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$scratchDir\Windows\System32\UsoApiAll.dll" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$scratchDir\Windows\System32\UsoApi.dll" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$scratchDir\Windows\System32\UpdatePolicy.dll" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$scratchDir\Windows\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Remove-EdgeAndOneDrive {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    Remove-Item -Path "$scratchDir\Program Files (x86)\Microsoft\Edge*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$scratchDir\Windows\System32\Microsoft-Edge-Webview" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $mstscPaths = @(
        "$scratchDir\Windows\System32\mstsc.exe",
        "$scratchDir\Windows\System32\mstscax.dll",
        "$scratchDir\Windows\SysWOW64\mstsc.exe",
        "$scratchDir\Windows\SysWOW64\mstscax.dll"
    )
    foreach ($path in $mstscPaths) {
        if (Test-Path $path) {
            & takeown.exe /f $path /a 2>&1 | Out-Null
            & icacls.exe $path /grant "$($adminGroup.Value):(F)" /T /C 2>&1 | Out-Null
            Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $oneDrivePaths = @(
        "$scratchDir\Windows\System32\OneDriveSetup.exe",
        "$scratchDir\Windows\SysWOW64\OneDriveSetup.exe"
    )
    foreach ($path in $oneDrivePaths) {
        if (Test-Path $path) {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            & takeown.exe /f $path /a | Out-Null
            & icacls.exe $path /grant "$($adminGroup.Value):(F)" /T /C | Out-Null
            Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $otherRemnants = @(
        "$scratchDir\Windows\GameBarPresenceWriter",
        "$scratchDir\Windows\System32\SettingsHandlers_Copilot.dll"
    )
    foreach ($path in $otherRemnants) {
        if (Test-Path $path) {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            & takeown.exe /f $path /a | Out-Null
            & icacls.exe $path /grant "$($adminGroup.Value):(F)" /T /C | Out-Null
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Optimize-WinRE {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $winRE = "$scratchDir\Windows\System32\Recovery\winre.wim"
    
    if (-not (Test-Path $winRE)) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        return
    }
    
    $winreMount = "$ScratchDisk\winre_temp"
    New-Item -ItemType Directory -Path $winreMount -Force | Out-Null
    
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & dism.exe /Mount-Image /ImageFile:$winRE /Index:1 /MountDir:$winreMount 2>$null | Out-Null
    
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & dism.exe /Image:$winreMount /Cleanup-Image /StartComponentCleanup /ResetBase 2>$null | Out-Null
    
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & dism.exe /Unmount-Image /MountDir:$winreMount /Commit 2>$null | Out-Null
    
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $winreTempPath = "$scratchDir\Windows\System32\Recovery\winre_opt.wim"
    & dism.exe /Export-Image /SourceImageFile:$winRE /SourceIndex:1 /DestinationImageFile:$winreTempPath /Compress:recovery 2>$null | Out-Null
    
    Remove-Item $winRE -Force
    Rename-Item $winreTempPath -NewName "winre.wim"
    
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Remove-WinRE {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $winRE = "$scratchDir\Windows\System32\Recovery\winre.wim"
    if (Test-Path $winRE) {
        Remove-Item -Path $winRE -Force -ErrorAction SilentlyContinue
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    } else {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
    }
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Patch-ReAgentXml {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $reagentXmlPath = "$scratchDir\Windows\System32\Recovery\ReAgent.xml"

    $cleanXml = @'
<?xml version='1.0' encoding='utf-8'?>
<WindowsRE version="2.0">
  <WinreBCD id="{00000000-0000-0000-0000-000000000000}"/>
  <WinreLocation path="" id="0" offset="0" guid="{00000000-0000-0000-0000-000000000000}"/>
  <ImageLocation path="" id="0" offset="0" guid="{00000000-0000-0000-0000-000000000000}"/>
  <PBRImageLocation path="" id="0" offset="0" guid="{00000000-0000-0000-0000-000000000000}" index="0"/>
  <PBRCustomImageLocation path="" id="0" offset="0" guid="{00000000-0000-0000-0000-000000000000}" index="0"/>
  <InstallState state="0"/>
  <OsInstallAvailable state="0"/>
  <CustomImageAvailable state="0"/>
  <IsAutoRepairOn state="0"/>
  <WinREStaged state="0"/>
  <OperationParam path=""/>
  <OemTool path=""/>
</WindowsRE>
'@

    try {
        $recoveryDir = "$scratchDir\Windows\System32\Recovery"
        if (-not (Test-Path $recoveryDir)) {
            New-Item -ItemType Directory -Force -Path $recoveryDir | Out-Null
        }

        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($reagentXmlPath, $cleanXml.TrimStart(), $utf8NoBom)

        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    } catch {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
    }
}

function Create-DesktopAppInstaller {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    
    $desktopPath = "$scratchDir\Users\Default\Desktop"
    if (-not (Test-Path $desktopPath)) {
        New-Item -ItemType Directory -Force -Path $desktopPath | Out-Null
    }
    
    $scriptContent = @'
@echo off
echo ====================================================
echo      TejOS Nano - Essential Apps Installer
echo ====================================================
echo.
echo Downloading Brave Browser...
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://referrals.brave.com/latest/BraveBrowserSetup.exe' -OutFile '%TEMP%\BraveBrowserSetup.exe'"
if exist "%TEMP%\BraveBrowserSetup.exe" (
    echo Installing Brave Browser...
    start /wait "" "%TEMP%\BraveBrowserSetup.exe"
)

echo Downloading IObit Driver Booster...
powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://cdn.iobit.com/dl/driver_booster_setup.exe' -OutFile '%TEMP%\driver_booster_setup.exe'"
if exist "%TEMP%\driver_booster_setup.exe" (
    echo Installing Driver Booster...
    start /wait "" "%TEMP%\driver_booster_setup.exe"
)

echo.
echo Installation complete! This script will now self-destruct.
del "%~f0"
exit
'@
    
    $scriptPath = "$desktopPath\Install_Essentials.bat"
    $scriptContent | Out-File -FilePath $scriptPath -Encoding ASCII -Force
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Optimize-WinSxS {
    Write-Host "Initializing sequence $(Get-Random -Minimum 1000 -Maximum 9999)..." -ForegroundColor Yellow
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $sourceDirectory = "$scratchDir\Windows\WinSxS"
    $destinationDirectory = "$scratchDir\Windows\WinSxS_edit"

    New-Item -Path $destinationDirectory -ItemType Directory -Force | Out-Null

    $dirsToCopy = @()

    if ($script:architecture -eq "amd64") {
        $dirsToCopy = @(
            "x86_microsoft.windows.common-controls_6595b64144ccf1df_*",
            "x86_microsoft.windows.gdiplus_6595b64144ccf1df_*",
            "x86_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*",
            "x86_microsoft.windows.isolationautomation_6595b64144ccf1df_*",
            "x86_microsoft-windows-s..ngstack-onecorebase_31bf3856ad364e35_*",
            "x86_microsoft-windows-s..stack-termsrv-extra_31bf3856ad364e35_*",
            "x86_microsoft-windows-servicingstack_31bf3856ad364e35_*",
            "x86_microsoft-windows-servicingstack-inetsrv_*",
            "x86_microsoft-windows-servicingstack-onecore_*",
            "amd64_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*",
            "amd64_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*",
            "amd64_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*",
            "amd64_microsoft.windows.common-controls_6595b64144ccf1df_*",
            "amd64_microsoft.windows.gdiplus_6595b64144ccf1df_*",
            "amd64_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*",
            "amd64_microsoft.windows.isolationautomation_6595b64144ccf1df_*",
            "amd64_microsoft-windows-s..stack-inetsrv-extra_31bf3856ad364e35_*",
            "amd64_microsoft-windows-s..stack-msg.resources_31bf3856ad364e35_*",
            "amd64_microsoft-windows-s..stack-termsrv-extra_31bf3856ad364e35_*",
            "amd64_microsoft-windows-servicingstack_31bf3856ad364e35_*",
            "amd64_microsoft-windows-servicingstack-inetsrv_31bf3856ad364e35_*",
            "amd64_microsoft-windows-servicingstack-msg_31bf3856ad364e35_*",
            "amd64_microsoft-windows-servicingstack-onecore_31bf3856ad364e35_*",
            "amd64_microsoft-windows-net*",
            "amd64_microsoft-windows-network*",
            "amd64_microsoft-windows-i2c*",
            "amd64_dual_hidi2c.inf*",
            "amd64_dual_mshidkmdf.inf*",
            "amd64_dual_net*.inf*",
            "amd64_microsoft-windows-c..g-controls-network_*",
            "Catalogs",
            "FileMaps",
            "Fusion",
            "InstallTemp",
            "Manifests",
            "x86_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*",
            "x86_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*",
            "x86_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*"
        )
    } elseif ($script:architecture -eq "arm64") {
        $dirsToCopy = @(
            "arm64_microsoft-windows-servicingstack-onecore_31bf3856ad364e35_*",
            "Catalogs",
            "FileMaps",
            "Fusion",
            "InstallTemp",
            "Manifests",
            "SettingsManifests",
            "Temp",
            "x86_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*",
            "x86_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*",
            "x86_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*",
            "x86_microsoft.windows.common-controls_6595b64144ccf1df_*",
            "x86_microsoft.windows.gdiplus_6595b64144ccf1df_*",
            "arm_microsoft.windows.common-controls_6595b64144ccf1df_*",
            "arm64_microsoft.windows.common-controls_6595b64144ccf1df_*",
            "arm64_microsoft-windows-servicingstack_31bf3856ad364e35_*"
        )
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    foreach ($dir in $dirsToCopy) {
        $sourceDirs = Get-ChildItem -Path $sourceDirectory -Filter $dir -Directory -ErrorAction SilentlyContinue
        foreach ($sourceDir in $sourceDirs) {
            $destDir = Join-Path -Path $destinationDirectory -ChildPath $sourceDir.Name
            & robocopy $sourceDir.FullName $destDir /E /NFL /NDL /NJH /NJS /MT:8 | Out-Null
        }
    }

    $matchedCount = (Get-ChildItem -Path $destinationDirectory).Count
    if ($matchedCount -lt 5) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "ERROR"
        throw "WinSxS optimization verification failed - Aborting to prevent broken image"
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & takeown.exe /F $sourceDirectory /R /D Y 2>$null | Out-Null
    & icacls.exe $sourceDirectory /grant "$($adminGroup.Value):(F)" /T /C 2>$null | Out-Null

    $emptyDir = "$ScratchDisk\empty_temp"
    New-Item -Path $emptyDir -ItemType Directory -Force | Out-Null
    & robocopy $emptyDir $sourceDirectory /MIR /R:0 /W:0 /NFL /NDL /NJH /NJS | Out-Null
    Remove-Item -Path $emptyDir -Force
    Remove-Item -Path $sourceDirectory -Recurse -Force
    Rename-Item -Path $destinationDirectory -NewName "WinSxS"

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Inject-CustomWallpaper {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $customWallpaper1 = "$PSScriptRoot\WallpaperDefault.jpg"
    $customWallpaper2 = "$PSScriptRoot\Wallpaper_Default.jpg"
    $customWallpaper3 = "$PSScriptRoot\WallpaperDefault.png"
    $customWallpaper4 = "$PSScriptRoot\Wallpaper_Default.png"
    $selectedWallpaper = ""

    if (Test-Path $customWallpaper1) { $selectedWallpaper = $customWallpaper1 }
    elseif (Test-Path $customWallpaper2) { $selectedWallpaper = $customWallpaper2 }
    elseif (Test-Path $customWallpaper3) { $selectedWallpaper = $customWallpaper3 }
    elseif (Test-Path $customWallpaper4) { $selectedWallpaper = $customWallpaper4 }

    if ($selectedWallpaper) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        
        $WebDir = Join-Path $scratchDir "Windows\Web"
        if (Test-Path $WebDir) {
            & takeown.exe /F $WebDir /R /D Y 2>$null | Out-Null
            & icacls.exe $WebDir /grant "$($adminGroup.Value):(F)" /T /C 2>$null | Out-Null
            
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            Get-ChildItem -Path $WebDir -Recurse -File | ForEach-Object {
                if ($_.IsReadOnly) { $_.IsReadOnly = $false }
            }
            
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            $allJpgs = Get-ChildItem -Path $WebDir -Filter "*.jpg" -Recurse
            foreach ($file in $allJpgs) { Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue }
            $allPngs = Get-ChildItem -Path $WebDir -Filter "*.png" -Recurse
            foreach ($file in $allPngs) { Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue }
            
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            $destImg0 = "$WebDir\Wallpaper\Windows\img0.jpg"
            $destImg19 = "$WebDir\Wallpaper\Windows\img19.jpg"
            if (-not (Test-Path (Split-Path $destImg0))) { New-Item -ItemType Directory -Path (Split-Path $destImg0) -Force | Out-Null }
            Copy-Item -Path $selectedWallpaper -Destination $destImg0 -Force -ErrorAction SilentlyContinue
            Copy-Item -Path $selectedWallpaper -Destination $destImg19 -Force -ErrorAction SilentlyContinue
            
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            foreach ($file in $allJpgs) {
                if ($file.FullName -match "4K\\Wallpaper\\Windows") {
                    Copy-Item -Path $selectedWallpaper -Destination $file.FullName -Force -ErrorAction SilentlyContinue
                }
            }
            foreach ($file in $allPngs) {
                if ($file.FullName -match "4K\\Wallpaper\\Windows") {
                    Copy-Item -Path $selectedWallpaper -Destination $file.FullName -Force -ErrorAction SilentlyContinue
                }
            }
            
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            $ThemeDir = Join-Path $scratchDir "Windows\Resources\Themes"
            if (Test-Path $ThemeDir) {
                & takeown.exe /F $ThemeDir /R /D Y 2>$null | Out-Null
                & icacls.exe $ThemeDir /grant "$($adminGroup.Value):(F)" /T /C 2>$null | Out-Null
                $ThemesToDelete = @("spotlight.theme", "themeA.theme", "themeB.theme", "themeC.theme", "themeD.theme")
                foreach ($theme in $ThemesToDelete) {
                    $themePath = Join-Path $ThemeDir $theme
                    if (Test-Path $themePath) { Remove-Item -Path $themePath -Force -ErrorAction SilentlyContinue }
                }
            }
            
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            $cbsSpotlightDir = Get-ChildItem -Path "$scratchDir\Windows\SystemApps" -Filter "MicrosoftWindows.Client.CBS_*" -Directory | Select-Object -First 1
            if ($cbsSpotlightDir) {
                $spotlightAssets = Join-Path $cbsSpotlightDir.FullName "DesktopSpotlight\Assets\Images"
                if (Test-Path $spotlightAssets) {
                    & takeown.exe /F $spotlightAssets /R /D Y 2>$null | Out-Null
                    & icacls.exe $spotlightAssets /grant "$($adminGroup.Value):(F)" /T /C 2>$null | Out-Null
                    Get-ChildItem -Path $spotlightAssets -Filter "*.*" -Include "*.jpg", "*.png" | ForEach-Object {
                        if ($_.IsReadOnly) { $_.IsReadOnly = $false }
                        Copy-Item -Path $selectedWallpaper -Destination $_.FullName -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            
            $winSxS = Join-Path $scratchDir "Windows\WinSxS"
            $wallpaperPackages = @()
            $wallpaperPackages += Get-ChildItem -Path $winSxS -Filter "*wallpaper-spotlight*" -Directory
            $wallpaperPackages += Get-ChildItem -Path $winSxS -Filter "*wallpaper-windows*" -Directory
            $wallpaperPackages += Get-ChildItem -Path $winSxS -Filter "*wallpaper-theme*" -Directory
            $wallpaperPackages += Get-ChildItem -Path $winSxS -Filter "*nbackgrounds-client*" -Directory
            
            foreach ($pkg in $wallpaperPackages) {
                & takeown.exe /F $pkg.FullName /R /D Y 2>$null | Out-Null
                & icacls.exe $pkg.FullName /grant "$($adminGroup.Value):(F)" /T /C 2>$null | Out-Null
                Get-ChildItem -Path $pkg.FullName -Filter "*.*" -Include "*.jpg", "*.png" -Recurse | ForEach-Object {
                    if ($_.IsReadOnly) { $_.IsReadOnly = $false }
                    Copy-Item -Path $selectedWallpaper -Destination $_.FullName -Force -ErrorAction SilentlyContinue
                }
            }
        }
    } else {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        Remove-Item -Path "$scratchDir\Windows\Web" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Load-RegistryHives {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    reg load HKLM\zCOMPONENTS "$scratchDir\Windows\System32\config\COMPONENTS" 2>$null | Out-Null
    reg load HKLM\zDEFAULT "$scratchDir\Windows\System32\config\default" 2>$null | Out-Null
    reg load HKLM\zNTUSER "$scratchDir\Users\Default\ntuser.dat" 2>$null | Out-Null
    reg load HKLM\zSOFTWARE "$scratchDir\Windows\System32\config\SOFTWARE" 2>$null | Out-Null
    reg load HKLM\zSYSTEM "$scratchDir\Windows\System32\config\SYSTEM" 2>$null | Out-Null

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Unload-RegistryHives {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    Start-Sleep -Seconds 3

    reg unload HKLM\zCOMPONENTS 2>$null | Out-Null
    reg unload HKLM\zDEFAULT 2>$null | Out-Null
    reg unload HKLM\zNTUSER 2>$null | Out-Null
    reg unload HKLM\zSOFTWARE 2>$null | Out-Null
    reg unload HKLM\zSYSTEM 2>$null | Out-Null

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Apply-RegistryTweaks {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassCPUCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassRAMCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassStorageCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassTPMCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'

    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'OemPreInstalledAppsEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'ContentDeliveryAllowed' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start' 'ConfigureStartPins' 'REG_SZ' '{"pinnedList": [{}]}'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'FeatureManagementEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEverEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContentEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-310093Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338389Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338393Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353694Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353696Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\PushToInstall' 'DisablePushToInstall' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\MRT' 'DontOfferThroughWUAU' 'REG_DWORD' '1'

    Remove-RegistryKey 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions'
    Remove-RegistryKey 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps'

    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableCloudOptimizedContent' 'REG_DWORD' '1'

    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' 'BypassNRO' 'REG_DWORD' '1'

    $nanoAutoUnattend = Join-Path $PSScriptRoot "autounattend-nano.xml"
    if (Test-Path $nanoAutoUnattend) {
        $xmlContent = Get-Content -Path $nanoAutoUnattend -Raw
        $xmlContent = $xmlContent -replace '<ComputerName>.*?</ComputerName>', '<ComputerName>TejOS</ComputerName>'
        $xmlContent | Out-File -FilePath "$scratchDir\Windows\System32\Sysprep\autounattend.xml" -Encoding UTF8 -Force
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    }

    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' 'ShippedWithReserves' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\BitLocker' 'PreventDeviceEncryption' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat' 'ChatIcon' 'REG_DWORD' '3'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 'REG_DWORD' '0'

    Remove-RegistryKey 'HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge'
    Remove-RegistryKey 'HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update'
    Remove-RegistryKey 'HKLM\zSOFTWARE\Classes\DesktopBackground\Shell\TejOSInfo'
    Remove-RegistryKey 'HKLM\zSOFTWARE\Classes\DesktopBackground\Shell\Nano11Info'

    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSyncNGSC' 'REG_DWORD' '1'
    Remove-RegistryValue "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Run\OneDriveSetup"
    Remove-RegistryValue "HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Run\OneDriveSetup"

    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Input\TIPC' 'Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice' 'Start' 'REG_DWORD' '4'

    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate' 'workCompleted' 'REG_DWORD' '1'
    Remove-RegistryKey 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'
    Remove-RegistryKey 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'

    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' 'HubsSidebarEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 'REG_DWORD' '1'

    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'TurnOffWindowsAI' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 'REG_DWORD' '1'
    
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' 'DoNotShowFeedbackNotifications' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowDeviceNameInTelemetry' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack' 'ShowedToastAtLevel' 'REG_DWORD' '1'
    
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\DirectDraw' 'EmulationOnly' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Direct3D' 'DisableVidMemVBs' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\GraphicsDrivers' 'DpiMapIommuContiguous' 'REG_DWORD' '1'

    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Teams' 'DisableInstallation' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Mail' 'PreventRun' 'REG_DWORD' '1'

    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' 'StopWUPostOOBE1' 'REG_SZ' 'net stop wuauserv'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' 'StopWUPostOOBE2' 'REG_SZ' 'sc stop wuauserv'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' 'StopWUPostOOBE3' 'REG_SZ' 'sc config wuauserv start= disabled'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' 'DisbaleWUPostOOBE1' 'REG_SZ' 'reg add HKLM\SYSTEM\CurrentControlSet\Services\wuauserv /v Start /t REG_DWORD /d 4 /f'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' 'DisbaleWUPostOOBE2' 'REG_SZ' 'reg add HKLM\SYSTEM\ControlSet001\Services\wuauserv /v Start /t REG_DWORD /d 4 /f'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'DoNotConneSysIntoWindowsUpdateInternetLocations' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'DisableWindowsUpdateAccess' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'WUServer' 'REG_SZ' 'localhost'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'WUStatusServer' 'REG_SZ' 'localhost'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'UpdateServiceUrlAlternate' 'REG_SZ' 'localhost'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'UseWUServer' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'NoAutoUpdate' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' 'DisableOnline' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\wuauserv' 'Start' 'REG_DWORD' '4'

    Remove-RegistryKey 'HKLM\zSYSTEM\ControlSet001\Services\WaaSMedicSVC'
    Remove-RegistryKey 'HKLM\zSYSTEM\ControlSet001\Services\UsoSvc'

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $servicePaths = @("WinDefend", "WdNisSvc", "WdNisDrv", "WdFilter", "Sense")
    foreach ($path in $servicePaths) {
        Set-RegistryValue "HKLM\zSYSTEM\ControlSet001\Services\$path" "Start" "REG_DWORD" "4"
    }

    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\WinRE' 'WinREEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'SettingsPageVisibility' 'REG_SZ' 'hide:virus;windowsupdate'

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    try {
        $defaultControlSet = [int](Get-ItemProperty -Path "HKLM:\zSYSTEM\Select" -Name Default -ErrorAction Stop).Default
        $controlSet = "ControlSet{0:D3}" -f $defaultControlSet
    } catch {
        $controlSet = "ControlSet001"
    }
    Set-RegistryValue "HKLM\zSYSTEM\$controlSet\Control\ComputerName\ComputerName" 'ComputerName' 'REG_SZ' 'TejOS'
    Set-RegistryValue "HKLM\zSYSTEM\$controlSet\Control\ComputerName\ActiveComputerName" 'ComputerName' 'REG_SZ' 'TejOS'
    Set-RegistryValue "HKLM\zSYSTEM\$controlSet\Services\Tcpip\Parameters" 'Hostname' 'REG_SZ' 'TejOS'
    Set-RegistryValue "HKLM\zSYSTEM\$controlSet\Services\Tcpip\Parameters" 'NV Hostname' 'REG_SZ' 'TejOS'

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\Tcpip6\Parameters' 'DisabledComponents' 'REG_DWORD' '255'

    Set-RegistryValue 'HKLM\zNTUSER\Control Panel\Desktop' 'PaintDesktopVersion' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\Desktop' 'PaintDesktopVersion' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows' 'DisplayNotGenuine' 'REG_DWORD' '0'

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $SysIntServices = @('DiagTrack','SysMain','WSearch','DPS','WdiServiceHost','WdiSystemHost','CDPUserSvc','OneSyncSvc','PimIndexMaintenanceSvc','UserDataSvc','UnistoreSvc','BcastDVRUserService','DoSvc','lfsvc','TabletInputService','RetailDemo','WbioSrvc','SEMgrSvc','PhoneSvc','MapsBroker','icssvc','wisvc','WpcMonSvc','SCardSvr','ScDeviceEnum','SCPolicySvc','AssignedAccessManagerSvc','AJRouter','FrameServer','stisvc','WFDSConMgrSvc','MixedRealityOpenXRSvc','SharedRealitySvc')
    foreach ($svc in $SysIntServices) {
        Set-RegistryValue "HKLM\zSYSTEM\ControlSet001\Services\$svc" 'Start' 'REG_DWORD' '4'
    }
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search' 'DisableWebSearch' 'REG_DWORD' '1'

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion' 'DisplayVersion' 'REG_SZ' '27H2'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'legalnoticecaption' 'REG_SZ' 'TejOS Nano'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'legalnoticetext' 'REG_SZ' 'This image was built using TejOS Nano Builder. Enjoy your lightweight Windows experience!'

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarEndTask' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' 'FolderType' 'REG_SZ' 'NotSpecified'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' 'Value' 'REG_SZ' 'Deny'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' '' 'REG_SZ' ''
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\Session Manager' 'DisableWpbtExecution' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 'REG_DWORD' '2'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'HubMode' 'REG_DWORD' '1'
    Remove-RegistryKey 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace_36354489\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Razer\Synapse3' 'DisableAutoInstall' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 'REG_DWORD' '2'

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Apply-PerformanceTweaks {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\Session Manager\Memory Management' 'DisablePagingExecutive'  'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\Session Manager\Memory Management' 'LargeSystemCache'        'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\Session Manager\Memory Management' 'ClearPageFileAtShutdown' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters' 'EnablePrefetcher' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters' 'EnableSuperfetch' 'REG_DWORD' '0'

    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\PriorityControl' 'Win32PrioritySeparation' 'REG_DWORD' '38'

    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 'REG_DWORD' '0xffffffff'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness'   'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'GPU Priority'        'REG_DWORD' '8'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Priority'            'REG_DWORD' '6'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Scheduling Category' 'REG_SZ'    'High'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'SFIO Priority'       'REG_SZ'    'High'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Latency Sensitive'   'REG_SZ'    'True'

    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\FileSystem' 'NtfsDisable8dot3NameCreation' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\FileSystem' 'NtfsDisableLastAccessUpdate'  'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\FileSystem' 'NtfsMemoryUsage'              'REG_DWORD' '2'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\FileSystem' 'DisableDeleteNotification'    'REG_DWORD' '0'

    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\Tcpip\Parameters' 'TcpTimedWaitDelay' 'REG_DWORD' '30'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\Tcpip\Parameters' 'MaxUserPort'       'REG_DWORD' '65534'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\Tcpip\Parameters' 'Tcp1323Opts'       'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\Tcpip\Parameters' 'DefaultTTL'        'REG_DWORD' '64'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\Tcpip\Parameters' 'EnableWsd'         'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' 'PerfTuneNagle' 'REG_SZ' `
        'powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Get-ChildItem HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces | ForEach-Object { Set-ItemProperty $_.PSPath TCPNoDelay 1 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty $_.PSPath TcpAckFrequency 1 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty $_.PSPath TCPDelAckTicks 0 -Type DWord -ErrorAction SilentlyContinue }"'

    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\GraphicsDrivers' 'HwSchMode'   'REG_DWORD' '2'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\GraphicsDrivers' 'TdrDelay'    'REG_DWORD' '10'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\GraphicsDrivers' 'TdrDdiDelay' 'REG_DWORD' '10'
    Set-RegistryValue 'HKLM\zNTUSER\SYSTEM\GameConfigStore' 'GameDVR_Enabled'                        'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SYSTEM\GameConfigStore' 'GameDVR_FSEBehaviorMode'                'REG_DWORD' '2'
    Set-RegistryValue 'HKLM\zNTUSER\SYSTEM\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode'       'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\SYSTEM\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible'  'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\SYSTEM\GameConfigStore' 'GameDVR_EFSEBehaviorMode'               'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\GameBar' 'AllowAutoGameMode'   'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\GameBar' 'AutoGameModeEnabled' 'REG_DWORD' '1'

    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'StartupDelayInMSec' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\Session Manager' 'AutoChkTimeOut' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\Session Manager\Power' 'HiberbootEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\CrashControl' 'AutoReboot' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' 'PerfTuneBCD' 'REG_SZ' `
        'powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& bcdedit /set timeout 5 2>$null | Out-Null; & bcdedit /set disabledynamictick yes 2>$null | Out-Null; & bcdedit /set useplatformtick yes 2>$null | Out-Null"'

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Remove-ScheduledTasks {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $tasksPath = "$scratchDir\Windows\System32\Tasks"
    $tasksToRemove = @(
        "$tasksPath\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "$tasksPath\Microsoft\Windows\Customer Experience Improvement Program",
        "$tasksPath\Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "$tasksPath\Microsoft\Windows\Chkdsk\Proxy",
        "$tasksPath\Microsoft\Windows\Windows Error Reporting\QueueReporting"
    )

    foreach ($task in $tasksToRemove) {
        if (Test-Path $task) {
            Remove-Item -Path $task -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Remove-Services {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    reg load HKLM\zSYSTEM "$scratchDir\Windows\System32\config\SYSTEM" 2>$null | Out-Null

    $servicesToRemove = @(
        'Spooler',
        'PrintNotify',
        'Fax',
        'RemoteRegistry',
        'diagsvc',
        'WerSvc',
        'PcaSvc',
        'MapsBroker',
        'WalletService',
        'BthAvctpSvc',
        'BluetoothUserService',
        'wuauserv',
        'UsoSvc',
        'WaaSMedicSvc'
    )

    foreach ($service in $servicesToRemove) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        try {
            & 'reg' 'delete' "HKLM\zSYSTEM\ControlSet001\Services\$service" /f 2>$null | Out-Null
        } catch {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        }
    }

    reg unload HKLM\zSYSTEM 2>$null | Out-Null
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Optimize-WindowsImage {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & dism.exe /Image:$scratchDir /Cleanup-Image /StartComponentCleanup /ResetBase 2>$null | Out-Null
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Dismount-AndExport {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & dism /English /unmount-image "/mountdir:$scratchDir" /commit

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $tempWim = "$nano11Dir\sources\install2.wim"
    & Dism.exe /English /Export-Image /SourceImageFile:$wimFilePath /SourceIndex:$INDEX /DestinationImageFile:$tempWim /Compress:max


    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Stop-Process -Name "wimserv" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $deleted = $false
    for ($i = 1; $i -le 20; $i++) {
        & cmd.exe /c "del /f /q `"$wimFilePath`" >nul 2>nul"
        if (-not (Test-Path $wimFilePath)) {
            $deleted = $true
            break
        }
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        Stop-Process -Name "wimserv" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }
    if (-not $deleted) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        & cmd.exe /c "ren `"$wimFilePath`" install_old.wim >nul 2>nul"
    }

    Rename-Item -Path $tempWim -NewName "install.wim" -ErrorAction SilentlyContinue

    $oldWim = Join-Path (Split-Path $wimFilePath) "install_old.wim"
    if (Test-Path $oldWim) {
        & cmd.exe /c "del /f /q `"$oldWim`" >nul 2>nul"
    }
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Process-BootImage {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $bootWimPath = "$nano11Dir\sources\boot.wim"
    $bootMountDir = "$scratchDir-boot"

    if (Test-Path $bootMountDir) {
        Remove-Item -Path $bootMountDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $bootMountDir -Force | Out-Null

    & takeown /F $bootWimPath /A 2>$null | Out-Null
    & icacls $bootWimPath /grant "$($adminGroup.Value):(F)" 2>$null | Out-Null
    Set-ItemProperty -Path $bootWimPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $newBootWimPath = "$nano11Dir\sources\boot_new.wim"
    & dism /English /Export-Image /SourceImageFile:$bootWimPath /SourceIndex:2 /DestinationImageFile:$newBootWimPath

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & dism /English /mount-image "/imagefile:$newBootWimPath" /index:1 "/mountdir:$bootMountDir"

    reg load HKLM\zDEFAULT "$bootMountDir\Windows\System32\config\default" 2>$null | Out-Null
    reg load HKLM\zNTUSER "$bootMountDir\Users\Default\ntuser.dat" 2>$null | Out-Null
    reg load HKLM\zSOFTWARE "$bootMountDir\Windows\System32\config\SOFTWARE" 2>$null | Out-Null
    reg load HKLM\zSYSTEM "$bootMountDir\Windows\System32\config\SYSTEM" 2>$null | Out-Null

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassCPUCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassRAMCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassStorageCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassTPMCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\BitLocker' 'PreventDeviceEncryption' 'REG_DWORD' '1'

    reg unload HKLM\zNTUSER 2>$null | Out-Null
    reg unload HKLM\zDEFAULT 2>$null | Out-Null
    reg unload HKLM\zSOFTWARE 2>$null | Out-Null
    reg unload HKLM\zSYSTEM 2>$null | Out-Null

    Start-Sleep -Seconds 5

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & dism /English /unmount-image "/mountdir:$bootMountDir" /commit

    Stop-Process -Name "wimserv" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    for ($i = 1; $i -le 20; $i++) {
        & cmd.exe /c "del /f /q `"$bootWimPath`" >nul 2>nul"
        if (-not (Test-Path $bootWimPath)) { break }
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        Stop-Process -Name "wimserv" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }
    $finalBootWimPath = "$nano11Dir\sources\boot_final.wim"
    & dism /English /Export-Image /SourceImageFile:$newBootWimPath /SourceIndex:1 /DestinationImageFile:$finalBootWimPath /Compress:max
    Stop-Process -Name "wimserv" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    for ($i = 1; $i -le 20; $i++) {
        & cmd.exe /c "del /f /q `"$newBootWimPath`" >nul 2>nul"
        if (-not (Test-Path $newBootWimPath)) { break }
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        Stop-Process -Name "wimserv" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }
    Rename-Item -Path $finalBootWimPath -NewName "boot.wim" -ErrorAction SilentlyContinue

    if (Test-Path $bootMountDir) {
        Remove-Item -Path $bootMountDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Convert-ToESD {
    Write-Host "Initializing sequence $(Get-Random -Minimum 1000 -Maximum 9999)..." -ForegroundColor Red
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $esdPath = "$nano11Dir\sources\install.esd"
    & dism /Export-Image /SourceImageFile:$wimFilePath /SourceIndex:1 /DestinationImageFile:$esdPath /Compress:recovery
    Stop-Process -Name "wimserv" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    & cmd.exe /c "del /f /q `"$wimFilePath`" >nul 2>nul"
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Clean-IsoRoot {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    
    $keepList = @("boot", "efi", "sources", "bootmgr", "bootmgr.efi", "setup.exe", "autounattend.xml")
    Get-ChildItem -Path $nano11Dir | Where-Object { $_.Name -notin $keepList } | ForEach-Object {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Create-NanoISO {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $autounattendXml = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <UserData>
                <AcceptEula>true</AcceptEula>
            </UserData>
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassStorageCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>5</Order>
                    <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassCPUCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>6</Order>
                    <Path>reg add HKLM\SYSTEM\Setup\MoSetup /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ComputerName>TejOS</ComputerName>
        </component>
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Path>reg add HKLM\SYSTEM\CurrentControlSet\Control\BitLocker /v PreventDeviceEncryption /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale></InputLocale>
            <SystemLocale></SystemLocale>
            <UILanguage></UILanguage>
            <UserLocale></UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <ProtectYourPC>3</ProtectYourPC>
                <HideEULAPage>true</HideEULAPage>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Name>TejOS</Name>
                        <Group>Administrators</Group>
                        <Password>
                            <Value></Value>
                            <PlainText>true</PlainText>
                        </Password>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Username>TejOS</Username>
                <Enabled>true</Enabled>
                <LogonCount>1</LogonCount>
                <Password>
                    <Value></Value>
                    <PlainText>true</PlainText>
                </Password>
            </AutoLogon>
        </component>
    </settings>
</unattend>
'@
    $autounattendXml | Out-File -FilePath "$nano11Dir\autounattend.xml" -Encoding UTF8 -Force
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    $bootFiles = @(
        "$nano11Dir\boot\etfsboot.com",
        "$nano11Dir\efi\microsoft\boot\efisys.bin"
    )
    foreach ($bootFile in $bootFiles) {
        if (-not (Test-Path $bootFile)) {
            throw "Required boot file not found: $bootFile"
        }
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    $EiCfgPath = Join-Path $nano11Dir "sources\ei.cfg"
    $EiCfgContent = @"
[EditionID]

[Channel]
Retail

[VL]
0
"@
    Set-Content -Path $EiCfgPath -Value $EiCfgContent -Encoding ASCII

    $hostArchitecture = $Env:PROCESSOR_ARCHITECTURE
    $ADKDepTools = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$hostArchitecture\Oscdimg"
    $localOSCDIMGPath = "$PSScriptRoot\oscdimg.exe"

    if (Test-Path "$ADKDepTools\oscdimg.exe") {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        $OSCDIMG = "$ADKDepTools\oscdimg.exe"
    } else {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        $url = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/3D44737265000/oscdimg.exe"
        if (-not (Test-Path $localOSCDIMGPath)) {
            Invoke-WebRequest -Uri $url -OutFile $localOSCDIMGPath -UseBasicParsing
        }
        $OSCDIMG = $localOSCDIMGPath
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & $OSCDIMG '-m' '-o' '-u2' '-udfver102' `
        "-bootdata:2#p0,e,b$nano11Dir\boot\etfsboot.com#pEF,e,b$nano11Dir\efi\microsoft\boot\efisys.bin" `
        $nano11Dir $outputISO

    if (Test-Path $outputISO) {
        $isoSize = [math]::Round((Get-Item $outputISO).Length / 1GB, 2)
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    } else {
        throw "ISO creation failed"
    }
}

function Write-BuildInfo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    try {
        $buildInfo = @{
            windows_build = $script:DetectedBuildNumber
            full_version  = $script:DetectedFullVersion
            image_name    = $script:DetectedImageName
            image_index   = $INDEX
            generated_at  = (Get-Date -Format 'o')
        }
        $buildInfo | ConvertTo-Json | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    } catch {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
    }
}

function Force-Cleanup {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & dism /English /Cleanup-Wim 2>$null | Out-Null
    
    if (Test-Path $scratchDir) {
        & dism /English /unmount-image "/mountdir:$scratchDir" /discard 2>$null | Out-Null
    }

    $dirsToClean = @($nano11Dir, $scratchDir)
    foreach ($dir in $dirsToClean) {
        if (Test-Path $dir) {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
            & takeown /f $dir /r /d y 2>$null | Out-Null
            & icacls $dir /grant "$($adminGroup.Value):(F)" /t /c /q 2>$null | Out-Null
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

function Invoke-Cleanup {
    if ($SkipCleanup) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
        return
    }
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    & dism /English /unmount-image "/mountdir:$scratchDir" /discard 2>$null | Out-Null

    Remove-Item -Path $nano11Dir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $scratchDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$PSScriptRoot\oscdimg.exe" -Force -ErrorAction SilentlyContinue

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Remove-MpPreference -ExclusionPath $PSScriptRoot -ErrorAction SilentlyContinue
    if ($ScratchDisk -ne $PSScriptRoot) {
        Remove-MpPreference -ExclusionPath $ScratchDisk -ErrorAction SilentlyContinue
    }

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
}

try {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "INFO"
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."

    Force-Cleanup
    Test-Prerequisites
    Initialize-Directories

    Resolve-ImageIndex

    if (Test-Path "$DriveLetter\sources\install.esd") {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        Convert-ESDToWIM
        Copy-WindowsFiles
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        $script:INDEX = 1
    } else {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
        Copy-WindowsFiles
    }

    Mount-WindowsImageFile
    Take-OwnershipOfFolders
    Get-ImageMetadata

    Remove-BloatwareApps
    Remove-SystemPackages
    Remove-NativeImages
    Slim-DriverStore
    Reduce-Fonts
    Remove-MiscellaneousFiles
    Remove-EdgeAndOneDrive
    
    if ($PreserveWinRE) {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "INFO"
        Optimize-WinRE
    } else {
        Remove-WinRE
        Patch-ReAgentXml
    }

    Load-RegistryHives
    Apply-RegistryTweaks
    Apply-PerformanceTweaks
    Remove-ScheduledTasks
    Unload-RegistryHives

    Remove-Services

    Create-DesktopAppInstaller

    Optimize-WinSxS

    Inject-CustomWallpaper

    Dismount-AndExport
    Process-BootImage
    
    if ($ESD) {
        Convert-ToESD
    }
    
    Clean-IsoRoot
    Create-NanoISO
    Write-BuildInfo -OutputPath "$PSScriptRoot\TejOS-Nano-buildinfo.json"

    Invoke-Cleanup

    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "INFO"
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..."
    exit 0

} catch {
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "ERROR"
    Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "ERROR"

    try {
        Get-WindowsImage -Mounted | ForEach-Object {
            Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "WARN"
            Dismount-WindowsImage -Path $_.Path -Discard -ErrorAction SilentlyContinue
        }

        @("zCOMPONENTS", "zDEFAULT", "zNTUSER", "zSOFTWARE", "zSYSTEM") | ForEach-Object {
            reg unload "HKLM\$_" 2>$null
        }
    } catch {
        Write-Log "Executing system routine at offset $(Get-Random -Minimum 1000 -Maximum 9999)..." "ERROR"
    }

    exit 1
}



