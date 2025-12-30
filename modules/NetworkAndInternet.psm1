function Invoke-NetworkAndInternetMenu {
    param($Continue = $true) # Default to true for loop continuation

    do {
        Clear-Host # Clears the screen before the menu of this section is displayed.
        Show-WMToolkitHeader -Title "6. Réseau & Internet" -BarLength 50 # Assuming BarLength is default 50
        Write-Host "🔍 DÉTAIL DES SECTIONS" -ForegroundColor White
        Write-Host "---------------------" -ForegroundColor DarkYellow
        Write-Host "🔹 Réinitialiser les paramètres réseau (netsh)" -ForegroundColor White
        Write-Host "🔹 Réparer la connexion (IPv4, IPv6, DNS, etc.)" -ForegroundColor White
        Write-Host "🔹 Lister toutes les interfaces réseau (Wifi + Ethernet)" -ForegroundColor White
        Write-Host "🔹 Redémarrer carte réseau (comme pour Wifi bloqué)" -ForegroundColor White
        Write-Host "🔹 Lister les connexions actives" -ForegroundColor White
        Write-Host "🔹 Test ping / latence / Google DNS" -ForegroundColor White
        Write-Host "🔹 Ouvrir ports spécifiques avec netsh advfirewall" -ForegroundColor White
        Write-Host "🔹 Afficher les réseaux Wifi enregistrés" -ForegroundColor White
        Write-Host ""

        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
        Write-Host "1. Réinitialiser les paramètres réseau (Réinitialisation complète)" -ForegroundColor Red
        Write-Host "2. Réparer la connexion réseau (Flush DNS, Winsock, IP)" -ForegroundColor Green
        Write-Host "3. Lister toutes les interfaces réseau" -ForegroundColor Green
        Write-Host "4. Redémarrer une carte réseau" -ForegroundColor Green
        Write-Host "5. Lister les connexions réseau actives" -ForegroundColor Green
        Write-Host "6. Tester la connexion (Ping/Latence Google DNS)" -ForegroundColor Green
        Write-Host "7. Ouvrir un port spécifique dans le pare-feu" -ForegroundColor Green
        Write-Host "8. Afficher les réseaux Wi-Fi enregistrés" -ForegroundColor Green
        Write-Host "0. Retour au menu principal" -ForegroundColor Red
        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

        $subChoice = Read-Host "Entrez votre choix"

        switch ($subChoice) {
            "1" { # Reset Network
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Réinitialisation complète des paramètres réseau ---" -ForegroundColor Yellow
                Write-Warning "AVERTISSEMENT: Ceci va réinitialiser tous les adaptateurs réseau et leurs paramètres (cartes Wi-Fi, Ethernet, VPN)."
                Write-Warning "Un redémarrage de l'ordinateur sera nécessaire après cette opération."
                $confirm = Read-Host "Êtes-vous ABSOLUMENT CERTAIN de vouloir réinitialiser les paramètres réseau ? (OUI/non)"
                if ($confirm -eq "OUI") {
                    try {
                        Write-Host "Réinitialisation Winsock..." -ForegroundColor White
                        netsh winsock reset | Out-Null
                        Write-Host "Réinitialisation IPv4..." -ForegroundColor White
                        netsh int ipv4 reset | Out-Null
                        Write-Host "Réinitialisation IPv6..." -ForegroundColor White
                        netsh int ipv6 reset | Out-Null
                        Write-Host "Nettoyage du cache DNS..." -ForegroundColor White
                        ipconfig /flushdns | Out-Null
                        Write-Host "Renouvellement des adresses IP..." -ForegroundColor White
                        ipconfig /release | Out-Null
                        ipconfig /renew | Out-Null
                        Write-Host "`nRéinitialisation réseau terminée. Veuillez redémarrer votre ordinateur pour appliquer tous les changements." -ForegroundColor Green
                    } catch {
                        Write-Error "Erreur lors de la réinitialisation réseau: $($_.Exception.Message)"
                    }
                } else {
                    Write-Host "Réinitialisation réseau annulée." -ForegroundColor Yellow
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" { # Repair Connection
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Réparation de la connexion réseau ---" -ForegroundColor Yellow
                Write-Host "Cette option va tenter de réparer les problèmes de connectivité en vidant le cache DNS, en réinitialisant Winsock et en renouvelant l'adresse IP." -ForegroundColor White
                try {
                    Write-Host "Vidage du cache DNS..." -ForegroundColor White
                    ipconfig /flushdns | Out-Null
                    Write-Host "Réinitialisation Winsock..." -ForegroundColor White
                    netsh winsock reset | Out-Null
                    Write-Host "Renouvellement de l'adresse IP..." -ForegroundColor White
                    ipconfig /release | Out-Null
                    ipconfig /renew | Out-Null
                    Write-Host "Réparation de la connexion réseau terminée." -ForegroundColor Green
                    Write-Host "Un redémarrage peut être bénéfique si les problèmes persistent." -ForegroundColor Yellow
                } catch {
                    Write-Error "Erreur lors de la réparation réseau: $($_.Exception.Message)"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" { # List Network Interfaces
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Liste des Interfaces Réseau ---" -ForegroundColor Yellow
                try {
                    # Explicitly select properties, including Index, to ensure they are always displayed.
                    Get-NetAdapter | Select-Object Index, Name, InterfaceDescription, Status, LinkSpeed, MacAddress | Format-Table -AutoSize
                    Write-Host "`nPour plus de détails, utilisez 'ipconfig /all' ou 'Get-NetIPConfiguration'." -ForegroundColor DarkGray
                } catch {
                    Write-Error "Erreur lors de la liste des interfaces réseau: $($_.Exception.Message)"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" { # Restart Network Adapter
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Redémarrer une carte réseau ---" -ForegroundColor Yellow
                Write-Host "Sélectionnez l'interface à redémarrer:" -ForegroundColor White
                Write-Host ""

                try {
                    $netAdapters = Get-NetAdapter -ErrorAction Stop # Get all adapters

                    if ($netAdapters.Count -gt 0) {
                        $displayAdapters = @() # Collection for displaying with selection number
                        for ($i = 0; $i -lt $netAdapters.Count; $i++) {
                            $adapter = $netAdapters[$i]
                            $optionNumber = $i + 1 # Start from 1 for user-friendly numbers
                            $displayAdapters += [PSCustomObject]@{
                                "#" = $optionNumber;
                                Name = $adapter.Name;
                                Description = $adapter.InterfaceDescription;
                                Status = $adapter.Status;
                                OriginalAdapter = $adapter # Store the original adapter object for later use
                            }
                        }

                        # Display the formatted table with the selection number column
                        $displayAdapters | Format-Table -AutoSize -Property '#', Name, Description, Status
                        
                        Write-Host "`nEntrez le numéro de la carte réseau à redémarrer ou '0' pour annuler." -ForegroundColor Yellow
                        $selection = Read-Host

                        if ($selection -eq "0") {
                            Write-Host "Opération annulée." -ForegroundColor Yellow
                        } elseif ($selection -as [int]) {
                            $chosenNumber = [int]$selection
                            # Find the selected adapter using the generated option number
                            $selectedAdapterInfo = $displayAdapters | Where-Object { $_.'#' -eq $chosenNumber }

                            if ($selectedAdapterInfo) {
                                $adapterToRestart = $selectedAdapterInfo.OriginalAdapter
                                Write-Host "Confirmation: Redémarrer la carte '$($adapterToRestart.Name)' ($($adapterToRestart.InterfaceDescription))?" -ForegroundColor Yellow
                                $confirm = Read-Host "(oui/non)"
                                if ($confirm -eq "oui") {
                                    Write-Host "Redémarrage de la carte réseau '$($adapterToRestart.Name)'..." -ForegroundColor Cyan
                                    Disable-NetAdapter -InputObject $adapterToRestart -Confirm:$false -ErrorAction Stop
                                    Start-Sleep -Seconds 2
                                    Enable-NetAdapter -InputObject $adapterToRestart -Confirm:$false -ErrorAction Stop
                                    Write-Host "Carte réseau '$($adapterToRestart.Name)' redémarrée avec succès." -ForegroundColor Green
                                } else {
                                    Write-Host "Redémarrage de la carte réseau annulé." -ForegroundColor Yellow
                                }
                            } else {
                                Write-Warning "Numéro invalide. Veuillez entrer un numéro de la liste."
                            }
                        } else { # User entered something other than a valid number or "0"
                            Write-Warning "Choix invalide. Veuillez entrer un NUMÉRO valide de la liste ou '0'."
                        }
                    } else {
                        Write-Warning "Aucune carte réseau n'a été détectée. Vérifiez votre matériel."
                    }
                } catch {
                    Write-Error "Erreur lors du redémarrage de la carte réseau: $($_.Exception.Message)"
                    Write-Warning "Vérifiez que PowerShell est exécuté en tant qu'administrateur."
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" { # List Active Connections
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Liste des connexions réseau actives (Netstat) ---" -ForegroundColor Yellow
                Write-Host "Ceci affiche les connexions TCP/UDP actives, les ports ouverts et les processus associés." -ForegroundColor White
                try {
                    netstat -ano | Select-String -Pattern "ESTABLISHED|LISTENING" # Only show active and listening connections
                    Write-Host "`nPour plus de détails, utilisez 'netstat -ano'." -ForegroundColor DarkGray
                } catch {
                    Write-Error "Erreur lors de la récupération des connexions actives: $($_.Exception.Message)"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "6" { # Ping/Latency Test
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Test de connexion (Ping/Latence Google DNS) ---" -ForegroundColor Yellow
                $target = "8.8.8.8" # Google DNS
                Write-Host "Test de ping vers $target (Google DNS) 4 fois..." -ForegroundColor White
                try {
                    Test-Connection -ComputerName $target -Count 4
                    Write-Host "`nTest de latence de base terminé." -ForegroundColor Green
                } catch {
                    Write-Error "Erreur lors du test de connexion: $($_.Exception.Message)"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "7" { # Open Specific Port in Firewall
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Ouvrir un port spécifique dans le pare-feu Windows ---" -ForegroundColor Yellow
                Write-Warning "AVERTISSEMENT: L'ouverture de ports peut exposer votre système à des risques de sécurité si elle n'est pas gérée correctement."
                $portNumber = Read-Host "Entrez le numéro du port à ouvrir (ex: 8080)"
                $protocol = Read-Host "Entrez le protocole (TCP/UDP)"
                $ruleName = Read-Host "Entrez un nom pour la règle de pare-feu (ex: MonAppliPort8080)"

                if ($portNumber -as [int] -and ($protocol -eq "TCP" -or $protocol -eq "UDP") -and -not [string]::IsNullOrEmpty($ruleName)) {
                    $confirm = Read-Host "Confirmez-vous la création de la règle de pare-feu '$ruleName' pour le port '$portNumber' ($protocol)? (oui/non)"
                    if ($confirm -eq "oui") {
                        try {
                            netsh advfirewall firewall add rule name="$ruleName" dir=in action=allow protocol=$protocol localport=$portNumber | Out-Null
                            Write-Host "Règle de pare-feu '$ruleName' créée avec succès pour le port '$portNumber' ($protocol)." -ForegroundColor Green
                        } catch {
                            Write-Error "Erreur lors de la création de la règle de pare-feu: $($_.Exception.Message)"
                            Write-Warning "Vérifiez que le port n'est pas déjà ouvert ou que la syntaxe est correcte."
                        }
                    } else {
                        Write-Host "Ouverture de port annulée." -ForegroundColor Yellow
                    }
                } else {
                    Write-Warning "Entrée invalide. Numéro de port, protocole (TCP/UDP) ou nom de règle manquants."
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "8" { # Show Saved Wi-Fi Networks
                Clear-Host # Clear for this option's output
                Write-Host "`n--- Afficher les réseaux Wi-Fi enregistrés ---" -ForegroundColor Yellow
                try {
                    (netsh wlan show profiles) -match ":(.+)$" | ForEach-Object {
                        $profileName = $_.Trim() -replace "All User Profile\s*:\s*", ""
                        Write-Host "Nom du profil: $profileName" -ForegroundColor White
                        Write-Host "--------------------" -ForegroundColor DarkGray
                    }
                    if (-not ((netsh wlan show profiles) -match ":(.+)$")) {
                        Write-Host "Aucun profil Wi-Fi enregistré trouvé." -ForegroundColor Yellow
                    }
                } catch {
                    Write-Error "Erreur lors de l'affichage des profils Wi-Fi: $($_.Exception.Message)"
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
Export-ModuleMember -Function Invoke-NetworkAndInternetMenu