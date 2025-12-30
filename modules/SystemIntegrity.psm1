# --- SystemIntegrity.psm1 ---

# Fonction pour vérifier le statut d'activation de Windows
function Test-WindowsActivationStatus {
    <#
    .SYNOPSIS
    Vérifie et affiche le statut d'activation de Windows en utilisant slmgr.
    #>
    [CmdletBinding()]
    param()

    Write-ToolkitLog -Message "Début de la vérification du statut d'activation de Windows."
    Write-Host "--- Vérification de l'activation de Windows ---" -ForegroundColor Cyan

    try {
        # Obtenir les informations du système d'exploitation
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        Write-Host "Version de Windows: $($os.Caption)" -ForegroundColor White
        Write-Host "Numéro de Build: $($os.BuildNumber)" -ForegroundColor White

        # Exécuter slmgr /dli et capturer sa sortie
        # L'option /dli (Display License Information) est normalement celle qu'il faut.
        # Utilisation de Start-Process pour mieux gérer la sortie des exécutables externes comme cscript.
        # Capture stdout et stderr dans un pipeline.
        $slmgrProcess = Start-Process -FilePath "cscript.exe" -ArgumentList "C:\Windows\System32\slmgr.vbs", "/dli" -Wait -NoNewWindow -PassThru -RedirectStandardOutput ([System.IO.Path]::GetTempFileName()) -RedirectStandardError ([System.IO.Path]::GetTempFileName())

        $slmgrOutput = Get-Content $slmgrProcess.StandardOutput -Encoding Default | Out-String
        $slmgrError = Get-Content $slmgrProcess.StandardError -Encoding Default | Out-String

        Remove-Item $slmgrProcess.StandardOutput, $slmgrProcess.StandardError -ErrorAction SilentlyContinue

        if (-not $slmgrOutput) {
            Write-Warning "La commande slmgr /dli n'a pas produit de sortie analysable. ($slmgrError)"
            Write-Host "Assurez-vous d'exécuter le script en tant qu'Administrateur." -ForegroundColor Yellow
            Write-Host "Si une fenêtre pop-up s'est ouverte avec le statut 'avec licence', votre Windows est activé." -ForegroundColor DarkGray
            Write-ToolkitLog -Message "Statut d'activation Windows: Sortie slmgr vide ou inattendue." -LogType "WARN"
        } else {
            # Initialiser le statut d'activation
            $activationStatusText = "Inconnu"
            $isActivated = $false

            # Analyser la sortie de slmgr
            if ($slmgrOutput -match "État de la licence\s*:\s*avec licence") {
                $activationStatusText = "Activé"
                $isActivated = $true
                Write-Host "Statut d'activation: $($activationStatusText) - Votre copie de Windows est légitimement activée." -ForegroundColor Green
                Write-ToolkitLog -Message "Statut d'activation de Windows: Activé." -LogType "INFO"
            }
            elseif ($slmgrOutput -match "État de la licence\s*:\s*non activé") {
                $activationStatusText = "Non activé"
                Write-Host "Statut d'activation: $($activationStatusText) - Windows n'est PAS activé. Vous pourriez rencontrer des limitations." -ForegroundColor Red
                Write-ToolkitLog -Message "Statut d'activation de Windows: Non activé." -LogType "ERROR"
            }
            else {
                # Cas où le statut "avec licence" ou "non activé" n'est pas trouvé spécifiquement.
                # On essaie de capturer la ligne complète de l'état de la licence si présente.
                $licenceStateLine = ($slmgrOutput | Select-String "État de la licence\s*:").ToString()
                if ($licenceStateLine) {
                    $activationStatusText = ($licenceStateLine -split ':')[1].Trim()
                    Write-Warning "Statut d'activation: Indéterminé ou ambigu (Détails bruts: '$activationStatusText')."
                    Write-Host "Si vos paramètres Windows indiquent 'Actif', c'est que tout va bien." -ForegroundColor Yellow
                    Write-ToolkitLog -Message "Statut d'activation de Windows: Indéterminé (Sortie slmgr: '$licenceStateLine')." -LogType "WARN"
                } else {
                    Write-Warning "Statut d'activation: Inconnu. Impossible de trouver l'état de licence dans la sortie de slmgr.vbs."
                    Write-Host "Si vos paramètres Windows indiquent 'Actif', c'est que tout va bien." -ForegroundColor Yellow
                    Write-ToolkitLog -Message "Statut d'activation de Windows: Inconnu (Sortie slmgr non analysable)." -LogType "WARN"
                }
            }
        }
        Write-Host "Pour plus de détails, vous pouvez utiliser 'slmgr /xpr' ou 'slmgr /dli' dans l'Invite de commandes (Admin)." -ForegroundColor DarkGray

    } catch {
        Write-Error "Une erreur s'est produite lors de la vérification de l'activation de Windows: $($_.Exception.Message)"
        Write-ToolkitLog -Message "Erreur lors de la vérification de l'activation Windows: $($_.Exception.Message)" -LogType "CRITICAL"
    }
    Write-Host "" # Ligne vide pour la mise en forme
    Write-ToolkitLog -Message "Fin de la vérification du statut d'activation de Windows."
}

# Votre fonction de menu d'intégrité du système
function Invoke-SystemIntegrityMenu {
    param($Continue = $false)
    do {
        Clear-Host # <--- THIS IS THE NEW LINE YOU NEED TO ADD HERE!
        Show-WMToolkitHeader -Title "3. Vérification de l’intégrité du système"
        Write-Host "🔍 DÉTAIL DES SECTIONS" -ForegroundColor White
        Write-Host "---------------------" -ForegroundColor DarkYellow
        Write-Host "🔹 sfc /scannow → Vérifie les fichiers système" -ForegroundColor White
        Write-Host "🔹 DISM /Online /Cleanup-Image /RestoreHealth → Répare les composants système" -ForegroundColor White
        Write-Host "🔹 Vérifier si Windows est activé/licencié" -ForegroundColor White
        Write-Host "🔹 Vérification des erreurs système dans l’observateur d’événements" -ForegroundColor White
        Write-Host "🔹 Scanner les erreurs de registre (lecture seule)" -ForegroundColor White
        Write-Host ""

        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
        Write-Host "1. Lancer SFC /scannow (Vérification des fichiers système)" -ForegroundColor Green
        Write-Host "2. Lancer DISM /RestoreHealth (Réparation des composants système)" -ForegroundColor Green
        Write-Host "3. Vérifier l'activation de Windows" -ForegroundColor Green
        Write-Host "4. Vérifier les erreurs critiques dans l'Observateur d'événements" -ForegroundColor Green
        Write-Host "5. Scanner les erreurs de registre (Information)" -ForegroundColor Green
        Write-Host "0. Retour au menu principal" -ForegroundColor Red
        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

        $subChoice = Read-Host "Entrez votre choix"
        Write-ToolkitLog -Message "Menu Intégrité Système: Choix '$subChoice'." # Log du choix

        switch ($subChoice) {
            "1" {
                Write-ToolkitLog -Message "Lancement de SFC /scannow."
                Clear-Host # Clears before showing SFC output
                Write-Host "`n--- Lancement de SFC /scannow ---" -ForegroundColor Yellow
                Write-Host "Ceci va vérifier l'intégrité de tous les fichiers système protégés et réparer ceux qui sont corrompus." -ForegroundColor White
                Write-Host "Cela peut prendre quelques minutes..." -ForegroundColor DarkGray
                try {
                    Start-Process sfc -ArgumentList "/scannow" -NoNewWindow -Wait -PassThru | Out-Null
                    Write-Host "`nAnalyse SFC terminée. Pour voir le rapport détaillé, ouvrez C:\Windows\Logs\CBS\CBS.log ou utilisez 'findstr /c:`"[SR]`" %windir%\logs\cbs\cbs.log > `"%userprofile%\Desktop\SFC_Details.txt`"'.`n" -ForegroundColor Green
                    Write-ToolkitLog -Message "SFC /scannow terminé." -LogType "INFO"
                } catch {
                    Write-Error "Erreur lors de l'exécution de SFC: $($_.Exception.Message)"
                    Write-ToolkitLog -Message "Erreur lors de l'exécution de SFC: $($_.Exception.Message)" -LogType "ERROR"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" {
                Write-ToolkitLog -Message "Lancement de DISM /RestoreHealth."
                Clear-Host # Clears before showing DISM output
                Write-Host "`n--- Lancement de DISM /RestoreHealth ---" -ForegroundColor Yellow
                Write-Host "Ceci va réparer l'image de Windows en utilisant les fichiers sources de Windows Update." -ForegroundColor White
                Write-Host "Cela peut prendre du temps (plusieurs minutes) et nécessite une connexion Internet active." -ForegroundColor DarkGray
                try {
                    Start-Process dism -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait -PassThru | Out-Null
                    Write-Host "`nOpération DISM terminée. Vérifiez les détails dans les journaux DISM si des erreurs sont survenues." -ForegroundColor Green
                    Write-ToolkitLog -Message "DISM /RestoreHealth terminé." -LogType "INFO"
                } catch {
                    Write-Error "Erreur lors de l'exécution de DISM: $($_.Exception.Message)"
                    Write-ToolkitLog -Message "Erreur lors de l'exécution de DISM: $($_.Exception.Message)" -LogType "ERROR"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" {
                Clear-Host # Clears before showing activation status
                # Appel de la nouvelle fonction de vérification de l'activation
                Test-WindowsActivationStatus
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" {
                Write-ToolkitLog -Message "Vérification des erreurs critiques dans l'Observateur d'événements."
                Clear-Host # Clears before showing event log output
                Write-Host "`n--- Vérification des Erreurs Critiques dans l'Observateur d'événements ---" -ForegroundColor Yellow
                Write-Host "Cette fonction recherche les erreurs récentes (dernières 24h) dans les journaux système et d'application qui pourraient indiquer des problèmes." -ForegroundColor White

                try {
                    $ErrorEvents = Get-WinEvent -FilterHashtable @{LogName='System', 'Application'; Level=1,2,3; StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue |
                                            Sort-Object TimeCreated -Descending |
                                            Select-Object -First 200 # Limit to 200 events for performance

                    if ($ErrorEvents) {
                        Write-Host "`n--- 200 Événements Critiques/Erreurs/Avertissements les plus récents (24h) ---" -ForegroundColor Yellow
                        $ErrorEvents | Format-Table -AutoSize -Property TimeCreated, LevelDisplayName, ProviderName, Id, Message
                        Write-Host "`nPour une analyse plus approfondie, ouvrez l'Observateur d'événements (eventvwr.msc)." -ForegroundColor DarkGray
                        Write-ToolkitLog -Message "Événements critiques trouvés: $($ErrorEvents.Count) événements." -LogType "INFO"
                    } else {
                        Write-Host "Aucun événement critique/erreur/avertissement trouvé dans les journaux Système et Application des dernières 24 heures." -ForegroundColor Green
                        Write-ToolkitLog -Message "Aucun événement critique trouvé dans les dernières 24h." -LogType "INFO"
                    }
                } catch {
                    Write-Error "Erreur lors de la récupération des événements: $($_.Exception.Message)"
                    Write-Warning "Cela peut se produire si les journaux d'événements sont corrompus ou inaccessibles."
                    Write-ToolkitLog -Message "Erreur lors de la récupération des événements: $($_.Exception.Message)" -LogType "ERROR"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" {
                Write-ToolkitLog -Message "Scan des erreurs de registre (information seulement)."
                Clear-Host # Clears before showing registry info
                Write-Host "`n--- Scanner les erreurs de registre (Lecture seule) ---" -ForegroundColor Yellow
                Write-Host "La "réparation" directe du registre via des scripts PowerShell est fortement déconseillée et risquée, car une modification incorrecte peut rendre le système instable." -ForegroundColor Red
                Write-Host "Les scanners de registre tiers sont également souvent controversés et ne sont généralement pas recommandés par Microsoft." -ForegroundColor Yellow
                Write-Host "Cependant, pour une *lecture seule* et une analyse de certaines clés courantes, vous pouvez:" -ForegroundColor White
                Write-Host "  - Utiliser l'outil intégré 'Regedit.exe' pour explorer manuellement le registre." -ForegroundColor White
                Write-Host "  - Exporter des sections spécifiques du registre pour une analyse textuelle (ex: reg export HKCU\Software %USERPROFILE%\Desktop\SoftwareReg.reg)" -ForegroundColor White
                Write-Host "`nConseil: concentrez-vous sur la résolution des problèmes système via SFC et DISM, qui sont des outils plus sûrs et validés par Microsoft." -ForegroundColor Green
                Write-ToolkitLog -Message "Informations sur le scan de registre affichées." -LogType "INFO"
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "0" {
                Write-ToolkitLog -Message "Retour au menu principal depuis Intégrité Système."
                return
            }
            default {
                Write-Warning "Choix invalide. Veuillez réessayer."
                Write-ToolkitLog -Message "Choix invalide dans le menu Intégrité Système: '$subChoice'." -LogType "WARN"
                Start-Sleep -Seconds 1
            }
        }
    } while ($subChoice -ne "0")
}

# Exportez les fonctions pour qu'elles soient disponibles
Export-ModuleMember -Function Invoke-SystemIntegrityMenu, Test-WindowsActivationStatus