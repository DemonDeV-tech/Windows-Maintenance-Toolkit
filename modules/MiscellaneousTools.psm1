function Invoke-MiscellaneousToolsMenu {
    param($Continue = $true)

    do {
        Clear-Host
        Show-WMToolkitHeader -Title "10. Outils divers"
        Write-Host "🔍 DÉTAIL DES SECTIONS" -ForegroundColor White
        Write-Host "---------------------" -ForegroundColor DarkYellow
        Write-Host "🔹 Générer un rapport système (msinfo32)" -ForegroundColor White
        Write-Host "🔹 Créer un point de restauration système" -ForegroundColor White
        Write-Host "🔹 Lancer le gestionnaire de périphériques" -ForegroundColor White
        Write-Host "🔹 Réinitialiser l’explorateur Windows (utile si figé)" -ForegroundColor White
        Write-Host "🔹 Réparer les autorisations de fichiers" -ForegroundColor White
        Write-Host "🔹 Lancer des scripts personnalisés sauvegardés dans un dossier" -ForegroundColor White
        Write-Host ""

        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
        Write-Host "1. Générer et afficher un rapport système (msinfo32)" -ForegroundColor Green
        Write-Host "2. Créer un point de restauration système" -ForegroundColor Green
        Write-Host "3. Lancer le Gestionnaire de périphériques" -ForegroundColor Green
        Write-Host "4. Réinitialiser l'Explorateur Windows" -ForegroundColor Green
        Write-Host "5. Réparer les autorisations de fichiers (Options avancées)" -ForegroundColor Green
        Write-Host "6. Lancer un script personnalisé" -ForegroundColor Green
        Write-Host "0. Retour au menu principal" -ForegroundColor Red
        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

        $subChoice = Read-Host "Entrez votre choix"

        switch ($subChoice) {
            "1" { # System Report (msinfo32)
                Clear-Host
                Write-Host "`n--- Génération et affichage du rapport système (msinfo32) ---" -ForegroundColor Yellow
                Write-Host "Ceci va ouvrir la fenêtre d'informations système." -ForegroundColor White
                try {
                    Start-Process msinfo32.exe -Wait
                    Write-Host "Rapport système affiché." -ForegroundColor Green
                } catch {
                    Write-Error "Erreur lors de l'ouverture de msinfo32: $($_.Exception.Message)"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" { # Create Restore Point
                Clear-Host
                Write-Host "`n--- Création d'un point de restauration système ---" -ForegroundColor Yellow
                Write-Host "Cela peut prendre quelques minutes. Assurez-vous que la protection du système est activée." -ForegroundColor White
                $description = Read-Host "Entrez une description pour le point de restauration (ex: 'Avant maintenance du JJ-MM-AAAA')"
                if ([string]::IsNullOrEmpty($description)) {
                    Write-Warning "Description vide. Veuillez réessayer."
                    Start-Sleep -Seconds 1
                    break
                }
                try {
                    $srRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
                    $srStatusValue = $null

                    try {
                        $srKey = Get-Item -Path $srRegistryPath -ErrorAction Stop
                        $srStatusValue = $srKey.GetValue("SystemRestorePointCreationFrequency")
                    } catch {}
                    
                    if ($null -eq $srStatusValue -or $srStatusValue -eq 0) {
                        Write-Warning "La protection du système semble DÉSACTIVÉE."
                        Write-Host "Impossible de créer un point de restauration si la protection du système n'est pas activée." -ForegroundColor Red
                        Write-Host "Pour l'activer: Panneau de configuration > Système et sécurité > Système > Protection du système." -ForegroundColor Yellow
                        Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        break
                    }

                    Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                    Write-Host "Point de restauration '$description' créé avec succès." -ForegroundColor Green
                } catch {
                    Write-Error "Erreur lors de la création du point de restauration: $($_.Exception.Message)"
                    Write-Warning "Assurez-vous d'exécuter en tant qu'administrateur et que la protection du système est activée (Panneau de configuration > Système et sécurité > Système > Protection du système)."
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" { # Launch Device Manager
                Clear-Host
                Write-Host "`n--- Lancement du Gestionnaire de périphériques ---" -ForegroundColor Yellow
                try {
                    Start-Process devmgmt.msc -Wait
                    Write-Host "Gestionnaire de périphériques lancé." -ForegroundColor Green
                } catch {
                    Write-Error "Erreur lors de l'ouverture du Gestionnaire de périphériques: $($_.Exception.Message)"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" { # Reset Explorer
                Clear-Host
                Write-Host "`n--- Réinitialiser l'Explorateur Windows ---" -ForegroundColor Yellow
                Write-Host "Ceci va fermer et redémarrer le processus explorer.exe, utile si l'explorateur est figé." -ForegroundColor White
                $confirm = Read-Host "Confirmez-vous la réinitialisation de l'Explorateur Windows ? (oui/non)"
                if ($confirm -eq "oui") {
                    try {
                        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 2
                        Start-Process explorer.exe -ErrorAction Stop
                        Write-Host "Explorateur Windows redémarré avec succès." -ForegroundColor Green
                    } catch {
                        Write-Error "Erreur lors de la redémarrage de l'Explorateur: $($_.Exception.Message)"
                    }
                } else {
                    Write-Host "Réinitialisation de l'Explorateur Windows annulée." -ForegroundColor Yellow
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" { # Repair File Permissions
                Clear-Host
                Write-Host "`n--- Réparer les autorisations de fichiers (Options avancées) ---" -ForegroundColor Yellow
                Write-Warning "AVERTISSEMENT: La modification des autorisations de fichiers est une opération AVANCÉE et peut rendre votre système instable si elle est mal exécutée."
                Write-Host "Cette fonction ne procède PAS à une réparation automatique et générique." -ForegroundColor Red
                Write-Host "Elle fournit des options pour réinitialiser les permissions sur des dossiers spécifiques." -ForegroundColor White
                Write-Host "`nActions possibles:"
                Write-Host "  1. Réinitialiser les permissions du dossier utilisateur (recommandé si problème avec votre profil)" -ForegroundColor Green
                Write-Host "  2. Réinitialiser les permissions d'un dossier spécifique (expertise requise)" -ForegroundColor Cyan
                Write-Host "0. Annuler"
                
                $permChoice = Read-Host "Votre choix"
                switch ($permChoice) {
                    "1" {
                        Write-Host "`nRéinitialisation des permissions du dossier utilisateur ($env:USERPROFILE)..." -ForegroundColor Yellow
                        Write-Warning "Ceci peut prendre du temps et doit être fait avec précaution. Assurez-vous d'avoir sauvegardé vos données importantes."
                        $confirm = Read-Host "Confirmez-vous cette opération ? (OUI/non)"
                        if ($confirm -eq "OUI") {
                            try {
                                Start-Process -FilePath "icacls.exe" -ArgumentList "$env:USERPROFILE", "/T", "/C", "/Q", "/GRANT", "`"$env:USERNAME`:(F)`"", "/inheritance:e" -Wait -NoNewWindow -ErrorAction Stop | Out-Null
                                Write-Host "Tentative de réinitialisation des permissions du dossier utilisateur terminée." -ForegroundColor Green
                                Write-Host "Les permissions ont été réinitialisées pour que l'utilisateur actuel ait un contrôle total sur son profil." -ForegroundColor White
                            } catch {
                                Write-Error "Erreur lors de la réinitialisation des permissions: $($_.Exception.Message)"
                            }
                        } else {
                            Write-Host "Opération annulée." -ForegroundColor Yellow
                        }
                    }
                    "2" {
                        $folderPath = Read-Host "Entrez le chemin complet du dossier à réinitialiser les permissions"
                        if (Test-Path $folderPath) {
                            Write-Warning "Vous êtes sur le point de modifier les permissions de '$folderPath'. Une erreur peut rendre le dossier inaccessible."
                            $confirm = Read-Host "Confirmez-vous cette opération ? (OUI/non)"
                            if ($confirm -eq "OUI") {
                                try {
                                    Start-Process -FilePath "icacls.exe" -ArgumentList "$folderPath", "/T", "/C", "/Q", "/GRANT", "`"$env:USERNAME`:(F)`"", "/inheritance:e" -Wait -NoNewWindow -ErrorAction Stop | Out-Null
                                    Write-Host "Tentative de réinitialisation des permissions pour '$folderPath' terminée." -ForegroundColor Green
                                } catch {
                                    Write-Error "Erreur lors de la réinitialisation des permissions pour '$folderPath': $($_.Exception.Message)"
                                }
                            } else {
                                Write-Host "Opération annulée." -ForegroundColor Yellow
                            }
                        } else {
                            Write-Warning "Chemin du dossier invalide ou non trouvé."
                        }
                    }
                    "0" { Write-Host "Opération annulée." -ForegroundColor Yellow }
                    default { Write-Warning "Choix invalide." }
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "6" {
                $currentDir = $PSScriptRoot
                if (-not $currentDir) { $currentDir = Get-Location }
                $toolkitRootPath = if ($currentDir -like "*modules*") { Split-Path $currentDir -Parent } else { $currentDir }
                $scriptsFolder = Join-Path $toolkitRootPath "scripts"
                
                if (-not (Test-Path $scriptsFolder)) {
                    New-Item -ItemType Directory -Path $scriptsFolder -Force | Out-Null
                }

                $refresh = $true
                while ($refresh) {
                    Clear-Host
                    Write-Host "`n--- Lancer un script personnalisé ---" -ForegroundColor Yellow
                    Write-Host "Dossier : $scriptsFolder" -ForegroundColor Gray
                    
                    $availableScripts = Get-ChildItem -Path $scriptsFolder -Filter "*.ps1" -ErrorAction SilentlyContinue

                    if ($availableScripts.Count -gt 0) {
                        Write-Host "`nScripts disponibles :" -ForegroundColor Yellow
                        for ($i = 0; $i -lt $availableScripts.Count; $i++) {
                            Write-Host "$($i+1). $($availableScripts[$i].Name)" -ForegroundColor White
                        }
                    } else {
                        Write-Host "`nAucun script .ps1 trouvé." -ForegroundColor Yellow
                    }

                    Write-Host "`n[R]. Rafraîchir la liste" -ForegroundColor Cyan
                    Write-Host "[0]. Retour" -ForegroundColor Red
                    
                    $scriptChoice = Read-Host "`nEntrez un numéro ou 'R'"
                    
                    if ($scriptChoice -eq "r") {
                        continue
                    } elseif ($scriptChoice -eq "0") {
                        $refresh = $false
                    } elseif ($scriptChoice -as [int] -and $scriptChoice -gt 0 -and $scriptChoice -le $availableScripts.Count) {
                        $selectedScript = $availableScripts[$scriptChoice - 1]
                        if ((Read-Host "Lancer $($selectedScript.Name) ? (oui/non)") -eq "oui") {
                            try {
                                Write-Host "`nExécution..." -ForegroundColor Cyan
                                & $selectedScript.FullName
                                Write-Host "`nTerminé." -ForegroundColor Green
                            } catch {
                                Write-Error "Erreur : $($_.Exception.Message)"
                            }
                            Write-Host "`nAppuyez sur une touche..." -ForegroundColor DarkGray
                            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        }
                    }
                }
            }
            # Option 7 (Send Log Reports by Email) is removed from the menu display and switch case
            "0" { return }
            default {
                Write-Warning "Choix invalide. Veuillez entrer un numéro entre 0 et 6." # Mise à jour du message
                Start-Sleep -Seconds 1
            }
        }
    } while ($subChoice -ne "0") 
}
Export-ModuleMember -Function Invoke-MiscellaneousToolsMenu