if ($null -eq $global:WMToolkitLogPath) {
    $global:WMToolkitLogPath = Join-Path $PSScriptRoot "logs_module_fallback" # A different fallback to avoid conflicts
    if (-not (Test-Path $global:WMToolkitLogPath -PathType Container)) {
        try { New-Item -ItemType Directory -Path $global:WMToolkitLogPath -ErrorAction SilentlyContinue | Out-Null } catch {}
    }
}

# --- MODIFIED: Write-ToolkitLog relies on global path set by main script ---
function Write-ToolkitLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$LogType = "INFO"
    )

    # Use the global log path set by Start-WMToolkit.psm1.
    $logFolderPath = $global:WMToolkitLogPath
    if ($null -eq $logFolderPath) {
        $logFolderPath = Join-Path $env:TEMP "WMToolkit_Logs_Emergency" # A distinct emergency fallback
        if (-not (Test-Path $logFolderPath -PathType Container)) {
            try { New-Item -ItemType Directory -Path $logFolderPath -Force -ErrorAction SilentlyContinue | Out-Null } catch {}
        }
    }

    # Final check to ensure the folder exists before writing
    if (-not (Test-Path $logFolderPath -PathType Container)) {
        Write-Warning "Impossible de créer le dossier de logs final à $($logFolderPath). La journalisation est désactivée."
        return
    }

    $logFileName = "ToolkitLog_$(Get-Date -Format 'yyyy-MM-dd').log"
    $logFilePath = Join-Path $logFolderPath $logFileName
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp][$LogType] $Message"

    try {
        Add-Content -Path $logFilePath -Value $logEntry -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "Impossible d'écrire dans le fichier de log à $($logFilePath): $($_.Exception.Message)"
    }
}
# --- END MODIFIED Write-ToolkitLog ---


# --- MODIFIED: Show-WMToolkitHeader for flexible titles and optional author ---
function Show-WMToolkitHeader {
    param (
        [string]$Title = "Toolkit",
        [string]$Author = "", # Optional: Set to "By DemonDeV-tech" for main menu/specific scripts
        [int]$BarLength = 50 # Length of the decorative bars
    )
    Clear-Host # Clear the host for a fresh display

    # Calculate padding for dynamic centering of the title
    $titlePadding = ($BarLength - $Title.Length) / 2
    $leftTitlePadding = [math]::Floor($titlePadding)
    $rightTitlePadding = [math]::Ceiling($titlePadding)
    $centeredTitle = (" " * $leftTitlePadding) + $Title + (" " * $rightTitlePadding)

    Write-Host ("=" * $BarLength) -ForegroundColor Cyan
    Write-Host $centeredTitle -ForegroundColor Cyan
    Write-Host ("=" * $BarLength) -ForegroundColor Cyan

    if (-not [string]::IsNullOrEmpty($Author)) {
        $authorPadding = ($BarLength - $Author.Length) / 2
        $leftAuthorPadding = [math]::Floor($authorPadding)
        $rightAuthorPadding = [math]::Ceiling($authorPadding)
        $centeredAuthor = (" " * $leftAuthorPadding) + $Author + (" " * $rightAuthorPadding)
        
        Write-Host $centeredAuthor -ForegroundColor Yellow
        Write-Host ("=" * $BarLength) -ForegroundColor Cyan
    }
    Write-Host "" # Add a blank line for spacing after the header
}


function Format-Number {
    param(
        [Parameter(Mandatory=$true)]
        [double]$Value,
        [string]$Format = "N2" # N2 for 2 decimal places
    )
    return ($Value).ToString($Format)
}


# --- NOUVELLE FONCTION : Chiffrement RSA avec Clé Publique (pour petits blocs) ---
function Encrypt-StringWithPublicKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DataToEncrypt, # La chaîne à chiffrer (ex: ID du PC, infos système)

        [Parameter(Mandatory=$true)]
        [string]$PublicKeyXml # La clé publique RSA au format XML
    )

    try {
        $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
        $rsa.FromXmlString($PublicKeyXml)

        # Convertir la chaîne en octets
        $bytesToEncrypt = [System.Text.Encoding]::UTF8.GetBytes($DataToEncrypt)

        # Chiffrer les octets. RSA ne peut chiffrer que de petits blocs de données (taille de la clé - padding).
        # Pour une clé de 2048 bits, la taille max est ~245 octets.
        # Le paramètre $false pour le padding OAEP (PKCS#1 v1.5) doit correspondre au déchiffrement.
        $encryptedBytes = $rsa.Encrypt($bytesToEncrypt, $false)

        # Convertir les octets chiffrés en chaîne Base64 pour le transport
        $base64EncryptedString = [System.Convert]::ToBase64String($encryptedBytes)
        return $base64EncryptedString

    } catch {
        Write-Warning "Erreur lors du chiffrement RSA: $($_.Exception.Message)"
        return $null # Retourne null en cas d'échec
    } finally {
        if ($rsa) { $rsa.Clear() } # Effacer l'objet RSA de la mémoire
    }
}
# --- FIN Encrypt-StringWithPublicKey ---


# --- NOUVELLE FONCTION : Chiffrement Hybride de Fichier (AES + RSA) ---
function Protect-FileWithPublicKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePathToEncrypt, # Chemin du fichier à chiffrer

        [Parameter(Mandatory=$true)]
        [string]$PublicKeyXml # La clé publique RSA au format XML
    )

    $encryptedOutput = $null
    $aesKey = $null
    $aesIV = $null

    try {
        # 1. Générer une clé AES et un IV aléatoires
        $aes = New-Object System.Security.Cryptography.AesManaged
        $aes.GenerateKey()
        $aes.GenerateIV()
        $aesKey = $aes.Key # Clé AES (bytes)
        $aesIV = $aes.IV   # Vecteur d'initialisation (bytes)

        # 2. Chiffrer le contenu du fichier avec AES
        $fileBytes = [System.IO.File]::ReadAllBytes($FilePathToEncrypt)
        $encryptor = $aes.CreateEncryptor($aes.Key, $aes.IV)
        $encryptedFileBytes = $encryptor.TransformFinalBlock($fileBytes, 0, $fileBytes.Length)

        # 3. Chiffrer la clé AES et l'IV avec la clé publique RSA
        $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
        $rsa.FromXmlString($PublicKeyXml)

        # Concaténer la clé AES et l'IV pour le chiffrement RSA
        # RSA peut chiffrer environ 245 octets pour une clé de 2048 bits avec padding.
        # AES Key (32 bytes) + AES IV (16 bytes) = 48 bytes. C'est bien dans la limite.
        $aesKeyAndIV = $aesKey + $aesIV
        $encryptedAesKeyAndIV = $rsa.Encrypt($aesKeyAndIV, $false) # $false pour OAEP padding (PKCS#1 v1.5)

        # 4. Combiner les données chiffrées : Clé AES chiffrée + IV chiffré + Contenu du fichier chiffré
        $encryptedAesKeyAndIVLength = [System.BitConverter]::GetBytes($encryptedAesKeyAndIV.Length)
        
        $encryptedOutputBytes = $encryptedAesKeyAndIVLength + $encryptedAesKeyAndIV + $encryptedFileBytes
        $encryptedOutput = [System.Convert]::ToBase64String($encryptedOutputBytes)

        return $encryptedOutput

    } catch {
        Write-Warning "Erreur lors du chiffrement hybride du fichier '$FilePathToEncrypt': $($_.Exception.Message)"
        return $null 
    } finally {
        if ($aes) { $aes.Clear() }
        if ($rsa) { $rsa.Clear() }
    }
}


Export-ModuleMember -Function Show-WMToolkitHeader, Format-Number, Write-ToolkitLog, Encrypt-StringWithPublicKey, Protect-FileWithPublicKey, Unprotect-FileWithPrivateKey