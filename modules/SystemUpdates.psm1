function Invoke-SystemUpdatesMenu {
    param($Continue = $true) # Default to true for loop continuation

    # Helper function to get browser path from registry (HKLM then HKCU)
    # This makes the detection more robust for per-user installations
    function Get-BrowserRegistryPath {
        param (
            [string]$ExeName
        )
        $path = $null
        try {
            # Try HKLM (All Users) first
            $path = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$ExeName" -ErrorAction SilentlyContinue).'(Default)'
        } catch {} # Ignore errors
        
        if ($null -eq $path) { # Only try HKCU if HKLM failed
            try {
                # Try HKCU (Current User)
                $path = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$ExeName" -ErrorAction SilentlyContinue).'(Default)'
            } catch {} # Ignore errors
        }
        return $path
    }

    do {
        Clear-Host # Clears the screen before the menu of this section is displayed.
        Show-WMToolkitHeader -Title "2. Mise à jour du système & logiciels" -BarLength 50
        Write-Host "🔍 DÉTAIL DES SECTIONS" -ForegroundColor White
        Write-Host "---------------------" -ForegroundColor DarkYellow
        Write-Host "🔹 Lancer PSWindowsUpdate (afficher les mises à jour disponibles, laisser l’utilisateur choisir)" -ForegroundColor White
        Write-Host "🔹 Vérifier et mettre à jour Winget" -ForegroundColor White
        Write-Host "🔹 Vérifier si les navigateurs (Chrome, Edge, Firefox, Opera GX) sont à jour" -ForegroundColor White
        Write-Host "🔹 Mise à jour automatique des logiciels via winget upgrade --all" -ForegroundColor White
        Write-Host "🔹 Vérifier si l’antivirus est actif et à jour" -ForegroundColor White
        Write-Host "🔹 (Option future) Interface Winget graphique simplifiée" -ForegroundColor DarkGray
        Write-Host ""

        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
        Write-Host "1. Lancer PSWindowsUpdate (Recherche & Installation)" -ForegroundColor Green
        Write-Host "2. Mettre à jour Winget et tous les logiciels" -ForegroundColor Green
        Write-Host "3. Vérifier la mise à jour des navigateurs (Chrome, Edge, Firefox, Opera GX)" -ForegroundColor Green
        Write-Host "4. Vérifier l'état de l'antivirus" -ForegroundColor Green
        Write-Host "0. Retour au menu principal" -ForegroundColor Red
        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

        $subChoice = Read-Host "Entrez votre choix"

        switch ($subChoice) {
            "1" {
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Lancement de PSWindowsUpdate ---" -ForegroundColor Yellow
                Write-Host "Recherche et affichage des mises à jour Windows disponibles..." -ForegroundColor White
                if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
                    Write-Host "Le module PSWindowsUpdate n'est pas installé. Tentative d'installation..." -ForegroundColor Yellow
                    try {
                        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -AllowClobber -Confirm:$false
                        Write-Host "PSWindowsUpdate installé avec succès." -ForegroundColor Green
                        # Pour s'assurer que les cmdlets sont disponibles immédiatement après l'installation dans la même session
                        Import-Module -Name PSWindowsUpdate -ErrorAction Stop
                    } catch {
                        Write-Error "Échec de l'installation de PSWindowsUpdate: $($_.Exception.Message). Veuillez l'installer manuellement (Install-Module PSWindowsUpdate)."
                        Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        break # Exit this case if installation fails
                    }
                }
                
                try {
                    # Recherche les mises à jour sans les installer directement
                    # Suppression du paramètre -List car il n'est pas supporté par toutes les versions du module
                    $availableUpdates = Get-WindowsUpdate -ErrorAction Stop

                    # Correction de la ligne 51 : $null à gauche pour une meilleure comparaison
                    if ($null -eq $availableUpdates -or $availableUpdates.Count -eq 0) {
                        Write-Host "`n✅ Aucune mise à jour Windows disponible n'a été trouvée." -ForegroundColor Green
                    } else {
                        Write-Host "`n--- Mises à jour disponibles ---" -ForegroundColor Cyan
                        # Affiche les mises à jour trouvées dans un format lisible
                        $availableUpdates | Format-Table -AutoSize

                        Write-Host "`n" # Ligne vide pour la lisibilité
                        $confirm = Read-Host "Voulez-vous installer toutes les mises à jour disponibles maintenant? (oui/non)"
                        if ($confirm -eq "oui" -or $confirm -eq "o") { # Ajout de 'o' pour flexibilité
                            Write-Host "`nInstallation des mises à jour... Cela-peut prendre du temps et nécessiter un redémarrage." -ForegroundColor Yellow
                            Install-WindowsUpdate -AcceptAll -AutoReboot -Confirm:$false -ErrorAction Stop
                            Write-Host "`n✅ Installation des mises à jour terminée." -ForegroundColor Green
                        } else {
                            Write-Host "Installation des mises à jour annulée." -ForegroundColor Yellow
                        }
                    }
                } catch {
                    Write-Error "Erreur lors de la recherche/installation des mises à jour Windows: $($_.Exception.Message)"
                    Write-Warning "Si Get-WindowsUpdate/Install-WindowsUpdate ne fonctionne pas, le module PSWindowsUpdate pourrait nécessiter un redémarrage de PowerShell."
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" { # Mettre à jour Winget et tous les logiciels
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Mise à jour de Winget et des logiciels ---" -ForegroundColor Yellow
                if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                    Write-Warning "Winget n'est pas trouvé. Assurez-vous qu'il est installé via le Microsoft Store (App Installer)."
                    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    break
                }
                
                # --- NOUVEAU: Message de confirmation pour Winget ---
                Write-Host "Cette option va mettre à jour Winget lui-même, puis tous les logiciels installés via Winget." -ForegroundColor White
                Write-Warning "Cela peut prendre du temps et nécessiter des redémarrages de logiciels. Voulez-vous continuer ? (O/N)"
                $confirmWinget = Read-Host
                if ($confirmWinget -eq "O" -or $confirmWinget -eq "o") {
                    try {
                        Write-Host "Mise à jour du client Winget lui-même..." -ForegroundColor White
                        # Ensure winget is fully updated before using it for other apps
                        Start-Process winget -ArgumentList "upgrade Microsoft.Winget.Client --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait -PassThru | Out-Null
                        Write-Host "Mise à jour de tous les logiciels installés via Winget (cela peut prendre du temps)..." -ForegroundColor White
                        Start-Process winget -ArgumentList "upgrade --all --silent --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait -PassThru | Out-Null
                        Write-Host "Mise à jour Winget et des logiciels terminée." -ForegroundColor Green
                    } catch {
                        Write-Error "Erreur lors de la mise à jour Winget/logiciels: $($_.Exception.Message)"
                        Write-Warning "Assurez-vous que Winget a les permissions nécessaires."
                    }
                } else {
                    Write-Host "Mise à jour Winget et des logiciels annulée." -ForegroundColor Yellow
                }
                # --- FIN NOUVEAU ---

                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" {
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Vérification des navigateurs (Chrome, Edge, Firefox, Opera GX) ---" -ForegroundColor Yellow

                # --- Google Chrome ---
                Write-Host "Vérification de Google Chrome..." -ForegroundColor White
                try {
                    $chromePath = Get-BrowserRegistryPath "chrome.exe"
                    if ($null -ne $chromePath -and (Test-Path $chromePath)) {
                        $chromeVersion = (Get-Item $chromePath).VersionInfo.ProductVersion
                        Write-Host "  Chrome trouvé. Version: $chromeVersion" -ForegroundColor Green
                        Write-Host "  Vérification de la mise à jour: Ouvrez Chrome et allez dans Aide > À propos de Google Chrome." -ForegroundColor DarkGray
                    } else {
                        Write-Warning "  Google Chrome non installé ou non détecté."
                    }
                } catch {
                    Write-Error "  Erreur lors de la vérification de Chrome: $($_.Exception.Message)"
                }

                # --- Microsoft Edge ---
                Write-Host "Vérification de Microsoft Edge..." -ForegroundColor White
                try {
                    $edgePath = Get-BrowserRegistryPath "msedge.exe"
                    if ($null -ne $edgePath -and (Test-Path $edgePath)) {
                        $edgeVersion = (Get-Item $edgePath).VersionInfo.ProductVersion
                        Write-Host "  Edge trouvé. Version: $edgeVersion" -ForegroundColor Green
                        Write-Host "  Vérification de la mise à jour: Ouvrez Edge et allez dans Paramètres et plus > Aide et commentaires > À propos de Microsoft Edge." -ForegroundColor DarkGray
                    } else {
                        Write-Warning "  Microsoft Edge non installé ou non détecté."
                    }
                } catch {
                    Write-Error "  Erreur lors de la vérification d'Edge: $($_.Exception.Message)"
                }

                # --- Mozilla Firefox ---
                Write-Host "Vérification de Mozilla Firefox..." -ForegroundColor White
                try {
                    $firefoxPath = Get-BrowserRegistryPath "firefox.exe"
                    if ($null -ne $firefoxPath -and (Test-Path $firefoxPath)) {
                        $firefoxVersion = (Get-Item $firefoxPath).VersionInfo.ProductVersion
                        Write-Host "  Firefox trouvé. Version: $firefoxVersion" -ForegroundColor Green
                        Write-Host "  Vérification de la mise à jour: Ouvrez Firefox et allez dans Aide > À propos de Firefox." -ForegroundColor DarkGray
                    } else {
                        Write-Warning "  Mozilla Firefox non installé ou non détecté."
                    }
                } catch {
                    Write-Error "  Erreur lors de la vérification de Firefox: $($_.Exception.Message)"
                }

                # --- Opera GX ---
                Write-Host "Vérification d'Opera GX..." -ForegroundColor White
                try {
                    $foundOperaGxPath = $null

                    # Attempt 1: Common LOCALAPPDATA path
                    $tempPath = "$env:LOCALAPPDATA\Programs\Opera GX\launcher.exe"
                    if ($null -ne $tempPath -and (Test-Path $tempPath)) {
                        $foundOperaGxPath = $tempPath
                    }

                    # Attempt 2: Registry specific to Opera GX
                    if ($null -eq $foundOperaGxPath) {
                        $tempPath = Get-BrowserRegistryPath "operagx.exe" # Check specifically for Opera GX App Path
                        if ($null -ne $tempPath -and (Test-Path $tempPath)) {
                            $foundOperaGxPath = $tempPath
                        }
                    }
                    # Attempt 3: Registry generic "opera.exe" but check if it leads to GX path
                    if ($null -eq $foundOperaGxPath) {
                        $tempPath = Get-BrowserRegistryPath "opera.exe"
                        if ($null -ne $tempPath -and (Test-Path $tempPath) -and ($tempPath -like "*Opera GX*")) {
                            $foundOperaGxPath = $tempPath
                        }
                    }

                    # Attempt 4: Program Files path
                    if ($null -eq $foundOperaGxPath) {
                        $tempPath = "$env:PROGRAMFILES\Opera GX\launcher.exe"
                        if ($null -ne $tempPath -and (Test-Path $tempPath)) {
                            $foundOperaGxPath = $tempPath
                        }
                    }
                    
                    if ($null -ne $foundOperaGxPath -and (Test-Path $foundOperaGxPath)) { # Final validation
                        $operaGxVersion = (Get-Item $foundOperaGxPath).VersionInfo.FileVersion
                        Write-Host "  Opera GX trouvé. Version actuelle : $operaGxVersion" -ForegroundColor Green

                        if (Get-Command winget -ErrorAction SilentlyContinue) {
                            Write-Host "  Recherche de mises à jour Opera GX via Winget..." -ForegroundColor White
                            $wingetOperaGxOutput = winget list --id Opera.OperaGX -Source winget -Exact | Out-String 
                            if ($wingetOperaGxOutput -match 'Available') { 
                                Write-Warning "  Une mise à jour pour Opera GX est disponible via Winget!"
                                Write-Host "  Pour mettre à jour, exécutez dans un terminal administrateur : winget upgrade --id Opera.OperaGX" -ForegroundColor DarkGray
                            } else {
                                Write-Host "  Opera GX est à jour (via Winget)." -ForegroundColor Green
                            }
                        } else {
                            Write-Host "  Winget n'est pas installé ou n'est pas dans le PATH. Veuillez vérifier les mises à jour Opera GX manuellement via les paramètres du navigateur." -ForegroundColor DarkGray
                        }
                    } else {
                        Write-Warning "  Opera GX non installé ou non détecté."
                    }
                } catch {
                    Write-Error "  Erreur lors de la récupération de la version d'Opera GX: $($_.Exception.Message)"
                    Write-Host "  Veuillez vérifier Opera GX manuellement." -ForegroundColor DarkGray
                }

                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" {
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Vérification de l'Antivirus ---" -ForegroundColor Yellow
                try {
                    $Antivirus = Get-WmiObject -Namespace root\SecurityCenter2 -Class AntivirusProduct
                    if ($Antivirus) {
                        $Antivirus | ForEach-Object {
                            Write-Host "Nom: $($_.DisplayName)" -ForegroundColor White
                            # Mappage ProductState (simplifié pour les états courants, consultez la documentation Microsoft pour la liste complète)
                            # 262144 : Le produit est activé et à jour
                            # 266240 : Le produit est activé mais n’est peut-être pas à jour (protection souvent toujours active)
                            # Autres : handicapé/obsolète/snoozed
                            $activeStatus = if ($_.ProductState -eq 262144 -or $_.ProductState -eq 266240) {"Actif et à jour (ou presque)"} else {"Inactif ou Problème"}
                            Write-Host "Statut : $activeStatus" -ForegroundColor White
                            Write-Host "Chemin du fichier principal : $($_.pathToSignedProductBinary)" -ForegroundColor White
                            Write-Host "--------------------" -ForegroundColor DarkGray
                        }
                    } else {
                        Write-Host "Aucun produit antivirus détecté par Security Center ou Security Center est désactivé." -ForegroundColor Yellow
                    }
                } catch {
                    Write-Error "Erreur lors de la vérification de l'antivirus: $($_.Exception.Message)"
                    Write-Warning "Cela peut arriver si le service Security Center est désactivé ou bloqué."
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
Export-ModuleMember -Function Invoke-SystemUpdatesMenu