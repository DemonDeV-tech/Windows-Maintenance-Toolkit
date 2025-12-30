function Invoke-WindowsServicesMenu {
    param($Continue = $false)

    do {
        Clear-Host # Add this line here
        Show-WMToolkitHeader -Title "5. Services Windows"
        Write-Host "🔍 DÉTAIL DES SECTIONS" -ForegroundColor White
        Write-Host "---------------------" -ForegroundColor DarkYellow
        Write-Host "🔹 Lister tous les services actifs/inactifs" -ForegroundColor White
        Write-Host "🔹 Démarrer/Arrêter/Reconfigurer un service" -ForegroundColor White
        Write-Host "🔹 Restaurer services critiques Windows" -ForegroundColor White
        Write-Host "🔹 Désactiver les services inutiles connus (option à activer à part pour sécurité)" -ForegroundColor White
        Write-Host ""

        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
        Write-Host "1. Lister tous les services" -ForegroundColor Green
        Write-Host "2. Démarrer, Arrêter ou Redémarrer un service" -ForegroundColor Green
        Write-Host "3. Changer le type de démarrage d'un service" -ForegroundColor Green
        Write-Host "4. Restaurer les services Windows par défaut (ATTENTION !)" -ForegroundColor Red
        Write-Host "5. Désactiver les services Windows inutiles connus (ATTENTION !)" -ForegroundColor Red
        Write-Host "0. Retour au menu principal" -ForegroundColor Red
        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

        $subChoice = Read-Host "Entrez votre choix"

        switch ($subChoice) {
            "1" { # List Services
                Write-Host "`n--- Liste de tous les services Windows ---" -ForegroundColor Yellow
                Write-Host "Trié par statut (Running/Stopped) et Nom." -ForegroundColor White
                try {
                    Get-Service | Sort-Object Status, DisplayName | Format-Table -AutoSize -Property Status, Name, DisplayName
                } catch {
                    Write-Error "Erreur lors de la liste des services: $($_.Exception.Message)"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" { # Start/Stop/Restart Service
                Write-Host "`n--- Démarrer, Arrêter ou Redémarrer un service ---" -ForegroundColor Yellow
                $serviceName = Read-Host "Entrez le nom du service (ex: 'Spooler' pour le spouleur d'impression)"
                if ([string]::IsNullOrEmpty($serviceName)) {
                    Write-Warning "Nom de service vide. Annulation."
                    Start-Sleep -Seconds 1
                    break
                }

                try {
                    $service = Get-Service -Name $serviceName -ErrorAction Stop
                    Write-Host "Service trouvé: $($service.DisplayName) (Nom: $($service.Name)) - Statut actuel: $($service.Status)" -ForegroundColor White
                    Write-Host "Actions disponibles: (1) Démarrer, (2) Arrêter, (3) Redémarrer, (0) Annuler"
                    $actionChoice = Read-Host "Entrez votre choix d'action"

                    switch ($actionChoice) {
                        "1" { # Start
                            if ($service.Status -eq "Stopped") {
                                Start-Service -Name $serviceName -ErrorAction Stop
                                Write-Host "Service '$($serviceName)' démarré avec succès." -ForegroundColor Green
                            } else {
                                Write-Host "Le service '$($serviceName)' est déjà en cours d'exécution." -ForegroundColor Yellow
                            }
                        }
                        "2" { # Stop
                            if ($service.Status -eq "Running") {
                                Stop-Service -Name $serviceName -ErrorAction Stop
                                Write-Host "Service '$($serviceName)' arrêté avec succès." -ForegroundColor Green
                            } else {
                                Write-Host "Le service '$($serviceName)' est déjà arrêté." -ForegroundColor Yellow
                            }
                        }
                        "3" { # Restart
                            if ($service.CanPauseAndContinue -or $service.CanStop) { # Check if restart is generally possible
                                Restart-Service -Name $serviceName -ErrorAction Stop
                                Write-Host "Service '$($serviceName)' redémarré avec succès." -ForegroundColor Green
                            } else {
                                Write-Warning "Le service '$($serviceName)' ne peut pas être redémarré via PowerShell directement ou n'est pas dans un état approprié."
                            }
                        }
                        "0" { Write-Host "Action annulée." -ForegroundColor Yellow }
                        default { Write-Warning "Choix d'action invalide." }
                    }
                } catch {
                    Write-Error "Impossible de trouver ou d'interagir avec le service '$serviceName': $($_.Exception.Message)"
                    Write-Warning "Vérifiez le nom du service et si vous avez les permissions nécessaires."
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" { # Change Startup Type
                Write-Host "`n--- Changer le type de démarrage d'un service ---" -ForegroundColor Yellow
                $serviceName = Read-Host "Entrez le nom du service"
                if ([string]::IsNullOrEmpty($serviceName)) {
                    Write-Warning "Nom de service vide. Annulation."
                    Start-Sleep -Seconds 1
                    break
                }
                
                try {
                    $service = Get-Service -Name $serviceName -ErrorAction Stop
                    Write-Host "Service: $($service.DisplayName) (Nom: $($service.Name))" -ForegroundColor White
                    Write-Host "Type de démarrage actuel: $((Get-WmiObject Win32_Service | Where-Object Name -eq $serviceName).StartMode)" -ForegroundColor White
                    
                    Write-Host "Types de démarrage possibles:"
                    Write-Host "  1. Automatique (démarrage automatique au boot)" -ForegroundColor White
                    Write-Host "  2. Automatique (Démarrage différé)" -ForegroundColor White
                    Write-Host "  3. Manuel (démarrage à la demande)" -ForegroundColor White
                    Write-Host "  4. Désactivé (ne démarre pas)" -ForegroundColor White
                    Write-Host "0. Annuler"
                    
                    $startupChoice = Read-Host "Choisissez le nouveau type de démarrage (1-4, 0 pour annuler)"

                    $newStartupType = ""
                    switch ($startupChoice) {
                        "1" { $newStartupType = "Automatic" }
                        "2" { $newStartupType = "Automatic (Delayed Start)" } # Special case, often set via UI, not direct Set-Service parameter
                        "3" { $newStartupType = "Manual" }
                        "4" { $newStartupType = "Disabled" }
                        "0" { Write-Host "Modification annulée." -ForegroundColor Yellow; break }
                        default { Write-Warning "Choix invalide. Annulation."; break }
                    }

                    if ($newStartupType -ne "") {
                        $confirm = Read-Host "Confirmez-vous le changement du type de démarrage de '$serviceName' à '$newStartupType'? (oui/non)"
                        if ($confirm -eq "oui") {
                            # Set-Service can directly set Automatic, Manual, Disabled
                            if ($newStartupType -eq "Automatic (Delayed Start)") {
                                # This requires WMI for delayed start
                                $wmiService = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
                                if ($wmiService) {
                                    $wmiService.ChangeStartMode("Automatic") | Out-Null
                                    # Set delayed start property via WMI, not directly by StartMode
                                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$serviceName" -Name "DelayedAutostart" -Value 1 -Force
                                    Write-Host "Service '$serviceName' configuré en 'Automatique (Démarrage différé)'." -ForegroundColor Green
                                } else {
                                    Write-Error "Impossible de configurer le démarrage différé pour '$serviceName'."
                                }
                            } else {
                                Set-Service -Name $serviceName -StartupType $newStartupType -ErrorAction Stop
                                Write-Host "Type de démarrage de '$serviceName' changé en '$newStartupType' avec succès." -ForegroundColor Green
                            }
                        } else {
                            Write-Host "Modification du type de démarrage annulée." -ForegroundColor Yellow
                        }
                    }
                } catch {
                    Write-Error "Erreur lors de la modification du type de démarrage: $($_.Exception.Message)"
                    Write-Warning "Vérifiez le nom du service et si vous avez les permissions nécessaires."
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" { # Restore Critical Services
                Write-Host "`n--- Restaurer les services Windows par défaut ---" -ForegroundColor Red
                Write-Warning "AVERTISSEMENT CRITIQUE: Cette opération est TRÈS RISQUÉE et ne doit être utilisée qu'en cas de problèmes graves liés aux services système."
                Write-Warning "Elle tente de réinitialiser le type de démarrage de services Windows essentiels à leurs valeurs par défaut."
                Write-Warning "UNE EXÉCUTION INCORRECTE PEUT RENDRE VOTRE SYSTÈME INSTABLE OU INUTILISABLE."
                Write-Host "`nCette fonctionnalité nécessite une liste prédéfinie et vérifiée de services critiques et leurs valeurs par défaut." -ForegroundColor Yellow
                Write-Host "Pour l'instant, elle n'est pas automatisée car la maintenance d'une telle liste exhaustive et à jour est complexe et variable selon les versions de Windows." -ForegroundColor White
                Write-Host "OPTION À DÉVELOPPER AVEC PRUDENCE: Nécessite une base de données fiable des services par défaut." -ForegroundColor Cyan
                $confirm = Read-Host "Voulez-vous vraiment tenter de restaurer un service manuellement (non recommandé sans expertise) ? (oui/non)"
                if ($confirm -eq "oui") {
                    $serviceName = Read-Host "Entrez le nom du service à restaurer (Ex: 'wuauserv' pour Windows Update). Annuler pour quitter."
                    if ([string]::IsNullOrEmpty($serviceName) -or $serviceName -eq "annuler") {
                        Write-Host "Opération annulée." -ForegroundColor Yellow
                    } else {
                        Write-Warning "Vous êtes sur le point de modifier manuellement un service. Connaissez-vous le type de démarrage par défaut pour '$serviceName' ?"
                        $defaultType = Read-Host "Entrez le type de démarrage par défaut (Automatic, Manual, Disabled). Annuler pour quitter."
                        if ([string]::IsNullOrEmpty($defaultType) -or $defaultType -eq "annuler") {
                            Write-Host "Opération annulée." -ForegroundColor Yellow
                        } elseif ($defaultType -in @("Automatic", "Manual", "Disabled")) {
                            $confirmFinal = Read-Host "Confirmez-vous la restauration de '$serviceName' à '$defaultType'? (OUI/non)"
                            if ($confirmFinal -eq "OUI") {
                                try {
                                    Set-Service -Name $serviceName -StartupType $defaultType -ErrorAction Stop
                                    Write-Host "Service '$serviceName' restauré à '$defaultType' avec succès." -ForegroundColor Green
                                } catch {
                                    Write-Error "Erreur lors de la restauration du service: $($_.Exception.Message)"
                                    Write-Warning "Vérifiez le nom du service et si vous avez les permissions. Certains services peuvent être protégés."
                                }
                            } else {
                                Write-Host "Opération annulée." -ForegroundColor Yellow
                            }
                        } else {
                            Write-Warning "Type de démarrage invalide. Veuillez entrer 'Automatic', 'Manual' ou 'Disabled'."
                        }
                    }
                } else {
                    Write-Host "Restauration des services critiques annulée." -ForegroundColor Yellow
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" { # Disable Useless Services
                Write-Host "`n--- Désactiver les services Windows inutiles connus ---" -ForegroundColor Red
                Write-Warning "AVERTISSEMENT CRITIQUE: La désactivation de services peut avoir des conséquences inattendues sur les fonctionnalités de Windows ou d'applications tierces."
                Write-Warning "Cette option est fournie à titre expérimental et doit être utilisée avec une extrême prudence et connaissance de cause."
                Write-Host "`nListe de services à désactiver (liste non exhaustive et potentiellement risquée si non comprise):" -ForegroundColor Yellow
                Write-Host "  - Fax (Fax) : Si vous n'utilisez pas de télécopieur."
                Write-Host "  - Connected Devices Platform User Service_<id> (CDPUserSvc) : Peut être désactivé si pas de périphériques connectés intelligents."
                Write-Host "  - Geolocation Service (lfsvc) : Si vous n'utilisez pas les services de localisation."
                Write-Host "  - Windows Connect Now - Config Registrar (Wcmsvc) : Pour les connexions Wi-Fi rapides."
                Write-Host "  - Fonctionnalité Expérience utilisateur avec des applications connectées (DusmSvc): Collecte de données et télémétrie."
                Write-Host "  - Service de routage et d’accès distant (RemoteAccess): Si vous n'avez pas besoin d'accès VPN ou dial-up."
                Write-Host ""
                Write-Host "Note: Certains de ces services sont déjà en mode manuel par défaut ou n'existent pas sur toutes les versions de Windows." -ForegroundColor DarkGray

                $confirm = Read-Host "Êtes-vous ABSOLUMENT CERTAIN de vouloir tenter de désactiver ces services ? (OUI/non)"
                if ($confirm -eq "OUI") {
                    $servicesToDisable = @(
                        "Fax",
                        "CDPUserSvc", # Placeholder, requires finding dynamic ID
                        "lfsvc",
                        "Wcmsvc",
                        "DusmSvc", # Also often has a dynamic ID
                        "RemoteAccess"
                    )

                    foreach ($svcName in $servicesToDisable) {
                        try {
                            # Handle dynamic service names like CDPUserSvc_<id> or DusmSvc_<id>
                            if ($svcName -eq "CDPUserSvc" -or $svcName -eq "DusmSvc") {
                                $dynamicServices = Get-Service -Name "${svcName}_*" -ErrorAction SilentlyContinue
                                if ($dynamicServices) {
                                    foreach ($dService in $dynamicServices) {
                                        Write-Host "Tentative de désactivation du service dynamique '$($dService.Name)' ($($dService.DisplayName))..." -ForegroundColor Yellow
                                        Set-Service -Name $dService.Name -StartupType Disabled -ErrorAction SilentlyContinue
                                        Stop-Service -Name $dService.Name -ErrorAction SilentlyContinue
                                        Write-Host "  Service '$($dService.Name)' désactivé et arrêté (si possible)." -ForegroundColor Green
                                    }
                                } else {
                                    Write-Host "Service dynamique '$svcName'_* non trouvé." -ForegroundColor DarkGray
                                }
                            } else {
                                $service = Get-Service -Name $svcName -ErrorAction SilentlyContinue
                                if ($service) {
                                    Write-Host "Tentative de désactivation du service '$svcName' ($($service.DisplayName))..." -ForegroundColor Yellow
                                    Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
                                    Stop-Service -Name $svcName -ErrorAction SilentlyContinue
                                    Write-Host "  Service '$svcName' désactivé et arrêté (si possible)." -ForegroundColor Green
                                } else {
                                    Write-Host "Service '$svcName' non trouvé." -ForegroundColor DarkGray
                                }
                            }
                        } catch {
                            Write-Warning "  Impossible de désactiver '$svcName': $($_.Exception.Message)"
                        }
                        Start-Sleep -Milliseconds 200 # Small delay for display
                    }
                    Write-Host "`nTentative de désactivation des services inutiles terminée." -ForegroundColor Green
                    Write-Warning "Un redémarrage peut être nécessaire pour que tous les changements prennent effet."
                } else {
                    Write-Host "Désactivation des services inutiles annulée." -ForegroundColor Yellow
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "0" { return }
            default {
                Write-Warning "Choix invalide. Veuillez réessayer."
                Start-Sleep -Seconds 1
            }
        }
    } while ($subChoice -ne "0")
}
Export-ModuleMember -Function Invoke-WindowsServicesMenu