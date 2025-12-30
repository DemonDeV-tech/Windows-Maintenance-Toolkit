# Start-WMToolkit.ps1
#
# Ce script est le point d'entrée principal du WMToolkit.
# Il charge les modules, gère l'ID unique du PC et affiche le menu principal.
#
# REQUIERT : PowerShell 5.1 ou ultérieur.
# EXÉCUTION : Doit être exécuté en tant qu'administrateur.
# DISTRIBUTION : Ce script doit être dans un dossier avec les sous-dossiers 'modules', 'scripts', 'utils'.

# --- GLOBAL INITIALIZATION ---

# --- Emergency Logging Function (MUST BE DEFINED FIRST) ---
# This ensures we can log critical errors from the very beginning of the script.
$logFallbackPath = Join-Path $env:TEMP "WMToolkit_Logs_Fallback"
if (-not (Test-Path $logFallbackPath -PathType Container)) {
    try { New-Item -ItemType Directory -Path $logFallbackPath -ErrorAction SilentlyContinue | Out-Null } catch {}
}
function _EmergencyLog {
    param(
        [string]$Message,
        [string]$LogType = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp][$LogType] (EMERGENCY) $Message"
    $logFileName = "ToolkitLog_$(Get-Date -Format 'yyyy-MM-dd').log"
    $fullLogPath = Join-Path $logFallbackPath $logFileName
    try { Add-Content -Path $fullLogPath -Value $logEntry -ErrorAction SilentlyContinue } catch {}
}
# --- END _EmergencyLog Definition ---

# --- Define the base directory of the toolkit (root folder) ---
# $PSScriptRoot est une variable automatique qui contient le chemin du répertoire du script en cours d'exécution.
# C'est la méthode la plus fiable pour obtenir le chemin de base en distribution dossier.
$ToolkitBaseDir = $PSScriptRoot 

# Journalise le répertoire de base déterminé
_EmergencyLog -Message "Répertoire de base du Toolkit déterminé : '$ToolkitBaseDir'"

# --- Vérification critique du répertoire de base ---
if ([string]::IsNullOrEmpty($ToolkitBaseDir)) {
    Write-Error "Erreur critique : Impossible de déterminer le répertoire de base du toolkit. Le programme ne peut pas continuer."
    _EmergencyLog -Message "Critique : Le répertoire de base du Toolkit est vide au démarrage." -LogType "CRITICAL"
    Read-Host "Appuyez sur une touche pour quitter."
    exit
}

# --- Unique PC ID Management (Généré, Stocké en Base64 - PAS DE CHIFFREMENT RSA) ---
function Get-UniquePCID {
    # Stocke le fichier d'ID à côté du script principal dans un fichier caché.
    $idFilePath = Join-Path $ToolkitBaseDir "pcid.dat"
    $uniqueId = $null

    if (Test-Path $idFilePath) {
        try {
            # Lire l'ID depuis le fichier (attendu encodé en Base64)
            $encodedId = [System.IO.File]::ReadAllText($idFilePath, [System.Text.Encoding]::UTF8)
            $decodedBytes = [System.Convert]::FromBase64String($encodedId)
            $uniqueId = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
            _EmergencyLog -Message "ID unique du PC chargé depuis le fichier."
        } catch {
            _EmergencyLog -Message "Échec du décodage/lecture de l'ID du PC depuis le fichier : $($_.Exception.Message)" -LogType "WARN"
            $uniqueId = $null # Force la régénération si la lecture/le décodage échoue
        }
    }

    if ($null -eq $uniqueId) {
        # Génère un nouvel ID si non trouvé ou si la lecture a échoué
        $uniqueId = (New-Guid).ToString() # Génère un nouveau GUID
        try {
            # Stocke l'ID sous forme de chaîne encodée en Base64
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($uniqueId)
            $encodedId = [System.Convert]::ToBase64String($bytes)
            [System.IO.File]::WriteAllText($idFilePath, $encodedId, [System.Text.Encoding]::UTF8)
            
            # Rend le fichier caché (optionnel, mais bon pour les fichiers "système")
            (Get-Item $idFilePath).Attributes = 'Hidden' -bor (Get-Item $idFilePath).Attributes

            _EmergencyLog -Message "Nouvel ID unique du PC généré et sauvegardé (Base64)."
        } catch {
            _EmergencyLog -Message "Échec de l'encodage/sauvegarde du nouvel ID du PC : $($_.Exception.Message)" -LogType "ERROR"
        }
    }
    return $uniqueId
}
# --- FIN Get-UniquePCID ---


$global:UniquePCID = Get-UniquePCID # Stocke l'ID unique globalement pour les autres modules
_EmergencyLog -Message "Toolkit initialisé avec l'ID du PC : $global:UniquePCID"

# --- Clé Publique pour le Chiffrement RSA (SUPPRIMÉE) ---
# La variable $global:PublicKeyXml n'est plus nécessaire car le chiffrement RSA est retiré.


# --- Chemin Global des Logs (Persistant dans AppData) ---
# Cela garantit que les logs sont stockés dans un emplacement cohérent et persistant pour l'utilisateur.
$global:WMToolkitLogPath = Join-Path $env:APPDATA "WMToolkit_Logs"
if (-not (Test-Path $global:WMToolkitLogPath -PathType Container)) {
    try { New-Item -ItemType Directory -Path $global:WMToolkitLogPath -ErrorAction SilentlyContinue | Out-Null }
    catch { _EmergencyLog -Message "Échec de la création du dossier de logs persistant : $($_.Exception.Message)"; $global:WMToolkitLogPath = $null }
}
_EmergencyLog -Message "Chemin global des logs persistant défini sur : $global:WMToolkitLogPath"


# --- Importation de GlobalFunctions.psm1 (CRUCIAL) ---
# Ce module est censé se trouver dans le dossier 'utils' à côté du script principal.
$utilsPath = Join-Path $ToolkitBaseDir "utils"
$globalFunctionsModule = Join-Path $utilsPath "GlobalFunctions.psm1"
if (Test-Path $globalFunctionsModule) {
    try {
        Import-Module $globalFunctionsModule -Force -ErrorAction Stop
        Write-ToolkitLog -Message "Module utilitaire 'GlobalFunctions.psm1' chargé."
    } catch {
        _EmergencyLog -Message "Critique : Échec du chargement de GlobalFunctions.psm1 : $($_.Exception.Message)" -LogType "CRITICAL"
        Write-Error "ÉCHEC du chargement du module utilitaire 'GlobalFunctions.psm1' : $($_.Exception.Message)"
        $_ | Format-List -Force
        Read-Host "Appuyez sur une touche pour quitter."
        exit
    }
} else {
    Write-Error "Le module utilitaire 'GlobalFunctions.psm1' est introuvable à '$globalFunctionsModule'."
    Write-Host "Assurez-vous que le dossier 'utils' et le fichier 'GlobalFunctions.psm1' existent à côté du script principal." -ForegroundColor Red
    _EmergencyLog -Message "Dossier 'utils' introuvable à '$globalFunctionsModule'." -LogType "ERROR"
    Read-Host "Appuyez sur une touche pour quitter."
    exit
}


# --- Logique du script principal ---
# Importe tous les modules de fonctionnalités spécifiques depuis le sous-dossier 'modules'
Write-ToolkitLog -Message "Tentative de chargement des modules principaux..."

$modulesPath = Join-Path $ToolkitBaseDir "modules" # Les modules sont censés se trouver dans le dossier 'modules' à côté du script principal
if (Test-Path $modulesPath) {
    $moduleList = @(
        "SystemAndPartitions",
        "SystemUpdates",
        "SystemIntegrity",
        "CleaningAndOptimization",
        "WindowsServices",
        "NetworkAndInternet",
        "AdvancedSystemInfo",
        "BIOSUpdateCheck",
        "BluetoothTools",
        "MiscellaneousTools"
    )
    foreach ($moduleName in $moduleList) {
        try {
            # Importe par chemin complet, car PSModulePath pourrait ne pas être entièrement fiable pour les sous-dossiers dans certains contextes
            Import-Module (Join-Path $modulesPath "$moduleName.psm1") -Force -ErrorAction Stop
            Write-ToolkitLog -Message "Module '$moduleName.psm1' chargé."
        } catch {
            Write-ToolkitLog -Message "Critique : Échec du chargement du module '$moduleName.psm1' : $($_.Exception.Message)" -LogType "CRITICAL"
            Write-Error "ÉCHEC du chargement de '$moduleName.psm1' : $($_.Exception.Message)"
            $_ | Format-List -Force
            Read-Host "Appuyez sur une touche pour quitter."
            exit
        }
    }
    Write-ToolkitLog -Message "Tous les modules principaux ont été chargés."
} else {
    Write-Error "Le dossier 'modules' est introuvable à '$modulesPath'."
    Write-Host "Assurez-vous que le dossier 'modules' existe à côté du script principal." -ForegroundColor Red
    _EmergencyLog -Message "Dossier 'modules' introuvable à '$modulesPath'." -LogType "ERROR"
    Read-Host "Appuyez sur une touche pour quitter."
    exit
}

# --- Boucle du menu principal ---
do {
    Clear-Host
    Show-WMToolkitHeader -Title "Outil d'Optimisation/Maintenance Windows" -Author "By DemonDeV-tech" -BarLength 50

    Write-Host "🧰 MENU PRINCIPAL" -ForegroundColor White
    Write-Host "---------------------" -ForegroundColor DarkYellow
    Write-Host "1. Gestion du système & partitions" -ForegroundColor Green
    Write-Host "2. Mise à jour du système & logiciels" -ForegroundColor Green
    Write-Host "3. Vérification de l’intégrité du système" -ForegroundColor Green
    Write-Host "4. Nettoyage & optimisation" -ForegroundColor Green
    Write-Host "5. Services Windows" -ForegroundColor Green
    Write-Host "6. Réseau & Internet" -ForegroundColor Green
    Write-Host "7. Informations système avancées" -ForegroundColor Green
    Write-Host "8. Vérification de mise à jour BIOS (lecture seule)" -ForegroundColor Green
    Write-Host "9. Outils Bluetooth" -ForegroundColor Green
    Write-Host "10. Outils divers" -ForegroundColor Green
    Write-Host "0. Quitter" -ForegroundColor Red
    Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

    $mainChoice = Read-Host "Entrez votre choix"

    Write-ToolkitLog -Message "Menu principal : Choix '$mainChoice'."

    switch ($mainChoice) {
        "1" { Invoke-SystemAndPartitionsMenu }
        "2" { Invoke-SystemUpdatesMenu }
        "3" { Invoke-SystemIntegrityMenu }
        "4" { Invoke-CleaningAndOptimizationMenu }
        "5" { Invoke-WindowsServicesMenu }
        "6" { Invoke-NetworkAndInternetMenu }
        "7" { Invoke-SystemInfoMenu }
        "8" { Invoke-BIOSCheckMenu }
        "9" { Invoke-BluetoothToolsMenu }
        "10" { Invoke-MiscellaneousToolsMenu }
        "0" { # Quitter
            Write-Host "`nMerci d'avoir utilisé l'outil. Au revoir !" -ForegroundColor Yellow
            Write-ToolkitLog -Message "Application quittée."
            Start-Sleep -Seconds 1
        }
        default {
            Write-Warning "Choix invalide. Veuillez réessayer."
            Write-ToolkitLog -Message "Choix invalide dans le menu principal : '$mainChoice'." -LogType "WARN"
            Start-Sleep -Seconds 1
        }
    }
} while ($mainChoice -ne "0")