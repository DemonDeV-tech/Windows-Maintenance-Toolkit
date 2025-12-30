function Invoke-BluetoothToolsMenu {
    param($Continue = $true) # Parameter to control loop behavior, changed to true by default for menu loop

    do {
        Clear-Host # Clears the console for a clean menu display
        # Display the toolkit header for the Bluetooth section
        # Assuming Show-WMToolkitHeader is defined elsewhere in your script
        # I'm adding a placeholder for Show-WMToolkitHeader if it's not defined, as it's called.
        # If you have it defined elsewhere, you can remove this placeholder function.
        if (-not (Get-Command Show-WMToolkitHeader -ErrorAction SilentlyContinue)) {
            function Show-WMToolkitHeader {
                param (
                    [string]$Title = "Toolkit"
                )
                Write-Host "====================================================" -ForegroundColor Cyan
                Write-Host "      $Title" -ForegroundColor Cyan
                Write-Host "====================================================" -ForegroundColor Cyan
                Write-Host ""
            }
        }

        Show-WMToolkitHeader -Title "9. Outils Bluetooth"

        # Detailed description of each menu option for clarity
        Write-Host "🔍 DÉTAIL DES SECTIONS" -ForegroundColor White
        Write-Host "---------------------" -ForegroundColor DarkYellow
        Write-Host "🔹 Lister tous les services Bluetooth (Affiche une liste de tous les services Windows dont le nom ou le nom d'affichage contient 'Bluetooth'.)" -ForegroundColor White
        Write-Host "🔹 Diagnostic Complet & Bilan de Santé Bluetooth (Vérifie l'état général de l'adaptateur, services, pilotes, périphériques et erreurs récentes.)" -ForegroundColor White
        Write-Host "🔹 Réinitialiser l'adaptateur (Désactiver/Activer l'interface réseau Bluetooth pour résoudre les blocages simples.)" -ForegroundColor White
        Write-Host "🔹 Démarrage/Redémarrage les services Bluetooth critiques (Assure que les services essentiels au fonctionnement du Bluetooth sont actifs et stables.)" -ForegroundColor White
        Write-Host "🔹 Gestion Avancée des Pilotes Bluetooth (Désinstalle les pilotes du périphérique ou supprime un package de pilote spécifique.)" -ForegroundColor White # DESCRIPTION MODIFIÉE
        Write-Host "🔹 Lancer l'outil de dépannage Windows Bluetooth (Ouvre l'utilitaire de résolution des problèmes intégré de Windows.)" -ForegroundColor White
        Write-Host "🔹 Lister Détaillé les appareils Bluetooth (Affiche des informations complètes sur tous les périphériques Bluetooth détectés, qu'ils soient connectés ou jumelés.)" -ForegroundColor White
        Write-Host "🔹 Supprimer un appareil Bluetooth Jumelé/Connecté Spécifique (Permet de retirer manuellement un périphérique Bluetooth de la liste des appareils connus pour un nouveau jumelage propre.)" -ForegroundColor White
        Write-Host "🔹 Examiner les erreurs Bluetooth dans l'Observateur d'événements (Recherche et affiche les messages d'erreur et d'avertissement récents liés au Bluetooth dans les journaux système.)" -ForegroundColor White
        Write-Host "🔹 Réinitialisation de la pile Bluetooth (Réinitialise les composants logiciels sous-jacents du Bluetooth, incluant les services et les paramètres réseau. Une mesure plus radicale.)" -ForegroundColor White
        Write-Host "🔹 Générer un Rapport de Diagnostic Bluetooth Détaillé (Collecte toutes les informations pour un dépannage approfondi.)" -ForegroundColor White # NOUVELLE DESCRIPTION
        Write-Host "🔹 Test Approfondi & Gestion Ciblée de l'Adaptateur Bluetooth (Désactive les autres adaptateurs et effectue des tests de base.)" -ForegroundColor White # NOUVELLE DESCRIPTION
        Write-Host ""

        # Main menu options presented to the user
        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
        Write-Host "1. Lister tous les services Bluetooth" -ForegroundColor Green
        Write-Host "2. Diagnostic Complet et Bilan de Santé Bluetooth" -ForegroundColor Green
        Write-Host "3. Réinitialiser l'adaptateur Bluetooth (Interface Réseau)" -ForegroundColor Green
        Write-Host "4. Démarrer/Redémarrer les services Bluetooth" -ForegroundColor Green
        Write-Host "5. Gestion Avancée des Pilotes Bluetooth" -ForegroundColor Green
        Write-Host "6. Lancer l'outil de dépannage Windows Bluetooth" -ForegroundColor Green
        Write-Host "7. Lister Détaillé les appareils Bluetooth" -ForegroundColor Green
        Write-Host "8. Supprimer un appareil Bluetooth Jumelé/Connecté Spécifique" -ForegroundColor Green
        Write-Host "9. Examiner les erreurs Bluetooth dans l'Observateur d'événements" -ForegroundColor Green
        Write-Host "10. Réinitialiser la pile logicielle Bluetooth" -ForegroundColor Green
        Write-Host "11. Générer un Rapport de Diagnostic Bluetooth Détaillé" -ForegroundColor Cyan
        Write-Host "12. Test Approfondi & Gestion Ciblée de l'Adaptateur Bluetooth" -ForegroundColor Cyan
        Write-Host "0. Retour au menu principal" -ForegroundColor Red
        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

        # Get user's choice
        $subChoice = Read-Host "Entrez votre choix"

        # Process user's choice using a switch statement
        switch ($subChoice) {
            "1" {
                Clear-Host
                Write-Host "`n--- Liste de tous les services liés au Bluetooth ---" -ForegroundColor Yellow
                Write-Host "Recherche de tous les services dont le nom ou le nom d'affichage contient 'Bluetooth'..." -ForegroundColor White
                Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

                try {
                    $allBtServices = Get-Service -ErrorAction SilentlyContinue | Where-Object {
                        $_.Name -like "*bluetooth*" -or $_.DisplayName -like "*bluetooth*"
                    } | Sort-Object DisplayName

                    if ($allBtServices.Count -gt 0) {
                        Write-Host "`nServices Bluetooth trouvés :" -ForegroundColor Green
                        $allBtServices | Format-Table -AutoSize DisplayName, Name, Status, StartType
                        Write-Host "`n✅ Si un service est 'Arrêté' ou 'Désactivé', cela pourrait être la cause d'un problème." -ForegroundColor Green
                    } else {
                        Write-Warning "Aucun service contenant 'Bluetooth' n'a été trouvé."
                    }
                } catch {
                    Write-Error "Erreur lors de la récupération des services Bluetooth: $($_.Exception.Message)"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "2" { # Diagnostic Complet et Bilan de Santé Bluetooth
                Clear-Host
                Write-Host "`n--- Lancement du Diagnostic Complet Bluetooth ---" -ForegroundColor Yellow
                Write-Host "Cela peut prendre quelques instants pendant que les vérifications sont effectuées." -ForegroundColor DarkGray
                Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

                # --- Verification 1: Bluetooth Adapter (PNP Device & Driver Details) ---
                Write-Host "`n[1/6] Vérification de l'adaptateur Bluetooth (Matériel et Pilote)..." -ForegroundColor White
                [bool]$isBtAdapterPnpOk = $false # Renamed and initialized
                $btAdapterPnp = $null # Initialized to null

                try {
                    $btAdapterPnp = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*Bluetooth Radio*" -or $_.FriendlyName -like "*Bluetooth Adapter*" }
                    if ($btAdapterPnp) {
                        Write-Host "  ✅ Adaptateur détecté: $($btAdapterPnp.FriendlyName)" -ForegroundColor Green
                        Write-Host "      Statut Général: $($btAdapterPnp.Status)" -ForegroundColor Green
                        Write-Host "      Fabricant: $($btAdapterPnp.Manufacturer)" -ForegroundColor White
                        Write-Host "      ID d'instance: $($btAdapterPnp.InstanceId)" -ForegroundColor White

                        $driverInfo = Get-WmiObject Win32_PnPSignedDriver | Where-Object {$_.DeviceID -eq $btAdapterPnp.DeviceID} | Select-Object -First 1 -ErrorAction SilentlyContinue
                        if ($driverInfo) {
                            Write-Host "      Pilote Fournisseur: $($driverInfo.DriverProviderName)" -ForegroundColor White
                            Write-Host "      Pilote Version: $($driverInfo.DriverVersion)" -ForegroundColor White
                            Write-Host "      Pilote Date: $($driverInfo.DriverDate)" -ForegroundColor White
                            if ($driverInfo.IsSigned) {
                                Write-Host "      Pilote Signature: Valide" -ForegroundColor Green
                            } else {
                                Write-Warning "      Pilote Signature: Non valide ou inconnue. Le pilote pourrait être corrompu ou non officiel."
                            }
                        } else {
                            Write-Warning "      Impossible d'obtenir les détails du pilote signé pour l'adaptateur. Le pilote pourrait être manquant."
                        }

                        if ($btAdapterPnp.Status -ne "OK") {
                            Write-Warning "      Statut non-optimal: L'adaptateur pourrait avoir un problème de pilote ou être désactivé."
                            # --- NOUVEAU: Recommandations spécifiques pour l'état d'erreur ---
                            if ($btAdapterPnp.Status -eq "Error") {
                                Write-Warning "      L'adaptateur est en état 'Erreur'. Cela peut indiquer un problème matériel, un pilote corrompu ou une désactivation BIOS/UEFI."
                                Write-Host "      ACTIONS RECOMMANDÉES:" -ForegroundColor Yellow
                                Write-Host "      1. Tenter l'Option 5 (Gestion Avancée des Pilotes) pour une réinstallation forcée." -ForegroundColor DarkCyan
                                Write-Host "      2. Si le problème persiste, vérifiez les paramètres BIOS/UEFI de votre ordinateur pour vous assurer que le Bluetooth est activé." -ForegroundColor DarkCyan
                                Write-Host "      3. Exécutez une vérification des fichiers système de Windows (sfc /scannow, dism /online /cleanup-image /restorehealth) via l'Option 3 du menu principal." -ForegroundColor DarkCyan
                                Write-Host "      4. Si rien ne fonctionne, l'adaptateur pourrait être défectueux." -ForegroundColor Red
                            }
                            # --- FIN NOUVEAU ---
                        } else {
                            $isBtAdapterPnpOk = $true # Set flag when status is OK
                        }
                    } else {
                        Write-Warning "  ❌ Aucun adaptateur Bluetooth détecté par le système. Cela peut indiquer un problème matériel, un pilote manquant ou un adaptateur désactivé (BIOS/UEFI)."
                        Write-Host "      ACTIONS RECOMMANDÉES:" -ForegroundColor Yellow
                        Write-Host "      1. Vérifiez les paramètres BIOS/UEFI de votre ordinateur pour vous assurer que le Bluetooth est activé." -ForegroundColor DarkCyan
                        Write-Host "      2. Essayez l'Option 5 (Gestion Avancée des Pilotes) pour tenter une détection/réinstallation." -ForegroundColor DarkCyan
                    }
                } catch {
                    Write-Error "  Erreur lors de la vérification matérielle/pilote: $($_.Exception.Message)"
                }

                # --- Verification 2: Bluetooth Radio State (OS Level) ---
                Write-Host "`n[2/6] Vérification de l'état de la radio Bluetooth (Système d'exploitation)..." -ForegroundColor White
                try {
                    # Removed Add-Type -AssemblyName Windows.Devices.Radios to avoid DLL not found error.
                    # Using more compatible methods for radio state check.

                    # Check via Get-NetAdapter for Bluetooth network interfaces
                    $btNetAdapter = Get-NetAdapter -Name "Bluetooth*" -ErrorAction SilentlyContinue
                    if ($btNetAdapter) {
                        Write-Host "  ✅ Adaptateur réseau Bluetooth trouvé: $($btNetAdapter.Name)" -ForegroundColor Green
                        Write-Host "      Statut d'interface: $($btNetAdapter.Status)" -ForegroundColor Green
                        if ($btNetAdapter.Status -ne "Up") {
                            Write-Warning "      L'interface Bluetooth est 'Down'. Tentez de la réinitialiser (Option 3)."
                        }
                    } else {
                        Write-Host "  ℹ️ Aucun adaptateur réseau Bluetooth explicitement détecté. Ceci est parfois normal si votre Bluetooth fonctionne pour les périphériques seulement." -ForegroundColor DarkGray
                    }

                    # Check basic Bluetooth radio presence/enabled status in Device Manager via PnpDevice
                    # Note: PnpDevice Status "OK" implies the radio is functional at a basic level
                    $btRadioPnpForRadioCheck = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*Bluetooth Radio*" -or $_.FriendlyName -like "*Bluetooth Adapter*" }
                    if ($btRadioPnpForRadioCheck -and $btRadioPnpForRadioCheck.Status -eq "OK") {
                        Write-Host "  ✅ Radio Bluetooth détectée et active via PnpDevice (Statut: $($btRadioPnpForRadioCheck.Status))." -ForegroundColor Green
                    } else {
                        Write-Warning "  ❌ La radio Bluetooth n'est pas détectée ou n'est pas 'OK' via PnpDevice. Cela peut indiquer une désactivation ou un problème."
                    }

                    Write-Warning "  Pour une vérification manuelle complète de l'état du Bluetooth, consultez les Paramètres Windows (Bluetooth & appareils)."

                } catch {
                    Write-Error "  Erreur lors de la vérification de l'état de la radio: $($_.Exception.Message)"
                    Write-Warning "  Vérifiez manuellement l'état du Bluetooth dans les Paramètres Windows (Bluetooth & appareils)."
                }

                # --- Verification 3: Bluetooth Services ---
                Write-Host "`n[3/6] Vérification des services Bluetooth critiques..." -ForegroundColor White
                $criticalServices = @(
                    @{ Name = "bthserv"; DisplayName = "Service de support Bluetooth" },
                    @{ Name = "BluetoothUserService*"; DisplayName = "Service de support des utilisateurs du Bluetooth*" } # Critical for Win10/11
                )
                foreach ($serviceInfo in $criticalServices) {
                    try {
                        $service = Get-Service -Name $serviceInfo.Name -ErrorAction SilentlyContinue
                        if ($service) {
                            Write-Host "  Service '$($service.DisplayName)' (Nom: $($serviceInfo.Name)): " -ForegroundColor White
                            Write-Host "    Statut actuel: $($service.Status) (Démarrage: $($service.StartType))" -ForegroundColor Cyan

                            if ($service.StartType -eq "Disabled") {
                                Write-Warning "      Le service est actuellement DÉSACTIVÉ. Tentative de le définir sur 'Automatique'..."
                                Set-Service -Name $serviceInfo.Name -StartupType Automatic -ErrorAction Stop
                                Write-Host "      Type de démarrage défini sur 'Automatique'. Relance du service..." -ForegroundColor Green
                                $service = Get-Service -Name $serviceInfo.Name
                            } elseif ($service.StartType -eq "Manual" -and $service.Status -ne "Running") {
                                Write-Host "      Le service est en démarrage 'Manuel' et arrêté." -ForegroundColor DarkYellow
                                Write-Host "      Voulez-vous le définir sur 'Automatique' et le démarrer maintenant ? (O/N)" -ForegroundColor Cyan
                                $confirmAuto = Read-Host
                                if ($confirmAuto -eq "O" -or $confirmAuto -eq "o") {
                                    Write-Host "      Tentative de définir le type de démarrage sur 'Automatique'..." -ForegroundColor Yellow
                                    Set-Service -Name $serviceInfo.Name -StartupType Automatic -ErrorAction Stop
                                    Write-Host "      Type de démarrage défini sur 'Automatique'. Relance du service..." -ForegroundColor Green
                                    $service = Get-Service -Name $serviceInfo.Name
                                } else {
                                    Write-Host "      Le service restera en mode 'Manuel'." -ForegroundColor DarkGray
                                }
                            }

                            if ($service.Status -ne "Running") {
                                Write-Host "  Tentative de démarrage du service..." -ForegroundColor Yellow
                                Start-Service -Name $serviceInfo.Name -ErrorAction Stop
                                Write-Host "  Statut après tentative de démarrage: $( (Get-Service -Name $serviceInfo.Name).Status )" -ForegroundColor Green
                            } else {
                                Write-Host "  Tentative de redémarrage du service..." -ForegroundColor Yellow
                                Restart-Service -Name $serviceInfo.Name -ErrorAction Stop -Force
                                Write-Host "  Statut après tentative de redémarrage: $( (Get-Service -Name $serviceInfo.Name).Status )" -ForegroundColor Green
                            }
                            Start-Sleep -Seconds 1
                        } else {
                            Write-Warning "Service '$($serviceInfo.Name)' non trouvé. Il pourrait ne pas être installé sur votre version de Windows."
                            $anyServiceFailed = $true
                        }
                    } catch {
                        Write-Error "Erreur critique avec le service '$($serviceInfo.Name)': $($_.Exception.Message)"
                        Write-Warning "Vérifiez que PowerShell est exécuté en tant qu'administrateur et que les services existent/ne sont pas corrompus. Si le service est défini sur 'Manuel' ou 'Désactivé' et refuse de démarrer, l'Option 10 est recommandée."
                        $anyServiceFailed = $true
                        Start-Sleep -Seconds 2
                    }
                }

                Write-Host "`n----------------------------------------------------" -ForegroundColor DarkYellow
                if ($anyServiceFailed) {
                    Write-Host "Opération sur les services Bluetooth terminée avec des erreurs. Revoyez les messages ci-dessus." -ForegroundColor Red
                    Write-Host "ACTION REQUISE: Si vous avez cette erreur alors que Bluetooth est fonctionnel, le service est peut-être déjà démarré ou n'a pas pu être force. Tentez l'Option 10 si le Bluetooth ne fonctionne pas." -ForegroundColor Yellow
                } else {
                    Write-Host "Opération sur les services Bluetooth terminée avec succès." -ForegroundColor Green
                    Write-Host "Vérifiez le statut via le 'Diagnostic Complet' (Option 2) pour confirmer." -ForegroundColor DarkGray
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" { # Réinitialiser l'adaptateur Bluetooth (Interface Réseau)
                Clear-Host
                Write-Host "`n--- Réinitialisation de l'adaptateur Bluetooth (Interface Réseau) ---" -ForegroundColor Yellow
                Write-Host "Cette option désactive puis réactive l'interface réseau Bluetooth. C'est souvent utile pour les blocages logiciels mineurs." -ForegroundColor White
                Write-Warning "CONFIRMATION REQUISE: La connexion Bluetooth sera temporairement coupée. Voulez-vous continuer ? (O/N)"
                $confirm = Read-Host
                if ($confirm -eq "O" -or $confirm -eq "o") {
                    try {
                        $bluetoothNetAdapter = Get-NetAdapter -Name "Bluetooth*" -ErrorAction SilentlyContinue
                        if ($bluetoothNetAdapter) {
                            Write-Host "Désactivation de l'adaptateur Bluetooth '$($bluetoothNetAdapter.Name)'..." -ForegroundColor White
                            Disable-NetAdapter -InputObject $bluetoothNetAdapter -Confirm:$false -ErrorAction Stop
                            Start-Sleep -Seconds 3 # Give time for the adapter to fully disable
                            Write-Host "Activation de l'adaptateur Bluetooth '$($bluetoothNetAdapter.Name)'..." -ForegroundColor White
                            Enable-NetAdapter -InputObject $bluetoothNetAdapter -Confirm:$false -ErrorAction Stop
                            Write-Host "`nRéinitialisation de l'adaptateur Bluetooth terminée." -ForegroundColor Green
                            Write-Host "Vérifiez le statut via le 'Diagnostic Complet' (Option 2) pour confirmer que l'adaptateur est bien revenu en ligne." -ForegroundColor DarkGray
                        } else {
                            Write-Warning "Aucun adaptateur réseau Bluetooth trouvé. Assurez-vous que l'adaptateur est présent et activé dans le Gestionnaire de périphériques."
                        }
                    } catch {
                        Write-Error "Erreur lors de la réinitialisation de l'adaptateur Bluetooth: $($_.Exception.Message)"
                        Write-Warning "Assurez-vous que PowerShell est exécuté en tant qu'administrateur et que l'adaptateur Bluetooth existe."
                    }
                } else {
                    Write-Host "Opération annulée." -ForegroundColor Yellow
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" { # Démarrage/Redémarrage des services Bluetooth
                Clear-Host
                Write-Host "`n--- Démarrage/Redémarrage des services Bluetooth ---" -ForegroundColor Yellow
                Write-Host "Cette option redémarre les services Windows essentiels au fonctionnement du Bluetooth. Utile si les services sont bloqués ou arrêtés." -ForegroundColor White
                Write-Host "ATTENTION: Les connexions Bluetooth actives seront interrompues temporairement. Voulez-vous continuer ? (O/N)" -ForegroundColor Red
                $confirm = Read-Host

                if ($confirm -eq "O" -or $confirm -eq "o") {
                    $bluetoothServices = @(
                        @{ Name = "bthserv"; DisplayName = "Service de support Bluetooth" },
                        @{ Name = "BluetoothUserService*"; DisplayName = "Service de support des utilisateurs du Bluetooth*" } # Critical for Win10/11
                    )
                    $anyServiceFailed = $false

                    foreach ($serviceInfo in $bluetoothServices) {
                        try {
                            $service = Get-Service -Name $serviceInfo.Name -ErrorAction SilentlyContinue
                            if ($service) {
                                Write-Host "  Service '$($service.DisplayName)' (Nom: $($serviceInfo.Name)): " -ForegroundColor White
                                Write-Host "    Statut actuel: $($service.Status) (Démarrage: $($service.StartType))" -ForegroundColor Cyan

                                if ($service.StartType -eq "Disabled") {
                                    Write-Warning "      Le service est actuellement DÉSACTIVÉ. Tentative de le définir sur 'Automatique'..."
                                    Set-Service -Name $serviceInfo.Name -StartupType Automatic -ErrorAction Stop
                                    Write-Host "      Type de démarrage défini sur 'Automatique'. Relance du service..." -ForegroundColor Green
                                    $service = Get-Service -Name $serviceInfo.Name
                                } elseif ($service.StartType -eq "Manual" -and $service.Status -ne "Running") {
                                    Write-Host "      Le service est en démarrage 'Manuel' et arrêté." -ForegroundColor DarkYellow
                                    Write-Host "      Voulez-vous le définir sur 'Automatique' et le démarrer maintenant ? (O/N)" -ForegroundColor Cyan
                                    $confirmAuto = Read-Host
                                    if ($confirmAuto -eq "O" -or $confirmAuto -eq "o") {
                                        Write-Host "      Tentative de définir le type de démarrage sur 'Automatique'..." -ForegroundColor Yellow
                                        Set-Service -Name $serviceInfo.Name -StartupType Automatic -ErrorAction Stop
                                        Write-Host "      Type de démarrage défini sur 'Automatique'. Relance du service..." -ForegroundColor Green
                                        $service = Get-Service -Name $serviceInfo.Name
                                    } else {
                                        Write-Host "      Le service restera en mode 'Manuel'." -ForegroundColor DarkGray
                                    }
                                }

                                if ($service.Status -ne "Running") {
                                    Write-Host "  Tentative de démarrage du service..." -ForegroundColor Yellow
                                    Start-Service -Name $serviceInfo.Name -ErrorAction Stop
                                    Write-Host "  Statut après tentative de démarrage: $( (Get-Service -Name $serviceInfo.Name).Status )" -ForegroundColor Green
                                } else {
                                    Write-Host "  Tentative de redémarrage du service..." -ForegroundColor Yellow
                                    Restart-Service -Name $serviceInfo.Name -ErrorAction Stop -Force
                                    Write-Host "  Statut après tentative de redémarrage: $( (Get-Service -Name $serviceInfo.Name).Status )" -ForegroundColor Green
                                }
                                Start-Sleep -Seconds 1
                            } else {
                                Write-Warning "Service '$($serviceInfo.Name)' non trouvé. Il pourrait ne pas être installé sur votre version de Windows."
                                $anyServiceFailed = $true
                            }
                        } catch {
                            Write-Error "Erreur critique avec le service '$($serviceInfo.Name)': $($_.Exception.Message)"
                            Write-Warning "Vérifiez que PowerShell est exécuté en tant qu'administrateur et que les services existent/ne sont pas corrompus. Si le service est défini sur 'Manuel' ou 'Désactivé' et refuse de démarrer, l'Option 10 est recommandée."
                            $anyServiceFailed = $true
                            Start-Sleep -Seconds 2
                        }
                    }

                    Write-Host "`n----------------------------------------------------" -ForegroundColor DarkYellow
                    if ($anyServiceFailed) {
                        Write-Host "Opération sur les services Bluetooth terminée avec des erreurs. Revoyez les messages ci-dessus." -ForegroundColor Red
                        Write-Host "ACTION REQUISE: Si vous avez cette erreur alors que Bluetooth est fonctionnel, le service est peut-être déjà démarré ou n'a pas pu être force. Tentez l'Option 10 si le Bluetooth ne fonctionne pas." -ForegroundColor Yellow
                    } else {
                        Write-Host "Opération sur les services Bluetooth terminée avec succès." -ForegroundColor Green
                        Write-Host "Vérifiez le statut via le 'Diagnostic Complet' (Option 2) pour confirmer." -ForegroundColor DarkGray
                    }
                    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                } else {
                    Write-Host "Opération annulée." -ForegroundColor Yellow
                    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
            "5" { # Gestion Avancée des Pilotes Bluetooth (MODIFIED)
                Clear-Host
                Write-Host "`n--- Gestion Avancée des Pilotes Bluetooth ---" -ForegroundColor Yellow
                Write-Host "Cette option permet de désinstaller les pilotes d'un périphérique Bluetooth ou de supprimer un package de pilote spécifique." -ForegroundColor White
                Write-Warning "ATTENTION DANGEREUX: Ces opérations peuvent temporairement désactiver votre Bluetooth et sont DANGEREUSES si vous ne savez pas ce que vous faites."
                Write-Warning "Un REDÉMARRAGE de l'ordinateur est FORTEMENT RECOMMANDÉ après la suppression d'un package de pilote."
                Write-Host "`nActions possibles:" -ForegroundColor White
                Write-Host "  1. Désinstaller le pilote du périphérique Bluetooth principal (tente une réinstallation automatique)." -ForegroundColor Green
                Write-Host "  2. Supprimer un package de pilote Bluetooth spécifique (requiert le nom du package, ex: 'oemXX.inf')." -ForegroundColor Red
                Write-Host "0. Annuler"
                $driverActionChoice = Read-Host "Votre choix"

                switch ($driverActionChoice) {
                    "1" { # Désinstaller le pilote du périphérique Bluetooth principal
                        Write-Host "`n--- Désinstallation du pilote du périphérique Bluetooth principal ---" -ForegroundColor Yellow
                        Write-Host "Recherche des adaptateurs Bluetooth pour désinstallation des pilotes..." -ForegroundColor White
                        # Find the primary Bluetooth radio adapter
                        $bluetoothAdapters = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*Bluetooth Radio*" -or $_.FriendlyName -like "*Bluetooth Adapter*" }

                        if ($bluetoothAdapters) {
                            foreach ($adapter in $bluetoothAdapters) {
                                Write-Host "Désactivation et suppression des pilotes pour: $($adapter.FriendlyName) (Instance ID: $($adapter.InstanceId))..." -ForegroundColor Cyan
                                # Disable the device first to ensure clean removal
                                Disable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction SilentlyContinue

                                # --- MODIFIED: Using pnputil.exe /remove-device ---
                                Write-Host "  Suppression du pilote via pnputil.exe pour: $($adapter.FriendlyName)..." -ForegroundColor Cyan
                                $pnputilOutput = Start-Process -FilePath "pnputil.exe" -ArgumentList "/remove-device", "$($adapter.InstanceId)", "/force" -Wait -NoNewWindow -PassThru | Out-Null
                                if ($pnputilOutput.ExitCode -eq 0) {
                                    Write-Host "  Pilote désinstallé pour '$($adapter.FriendlyName)' via pnputil." -ForegroundColor Green
                                } else {
                                    $stdout = Get-Content $pnputilOutput.StandardOutput
                                    $stderr = Get-Content $pnputilOutput.StandardError
                                    Write-Warning "  Échec de la suppression du pilote avec pnputil.exe pour '$($adapter.FriendlyName)'. Code de sortie: $($pnputilOutput.ExitCode)"
                                    Write-Warning "  Sortie standard: $($stdout | Out-String)"
                                    Write-Warning "  Erreur standard: $($stderr | Out-String)"
                                }
                                Remove-Item $pnputilOutput.StandardOutput, $pnputilOutput.StandardError -ErrorAction SilentlyContinue
                                # --- END MODIFIED ---

                                Start-Sleep -Seconds 2 # Give a moment for the system to register the removal
                            }
                            Write-Host "`nLancement d'un scan des modifications matérielles pour tenter une réinstallation automatique des pilotes..." -ForegroundColor White
                            # Simulate "Scan for hardware changes" from Device Manager
                            # This will prompt Windows to detect the "new" hardware and reinstall drivers
                            $devMgr = New-Object -ComObject "DevMgr.MsDevMgr"
                            $devMgr.RefreshAll()
                            Write-Host "Scan terminé. Windows a tenté de réinstaller les pilotes. Le Bluetooth devrait revenir en ligne sous peu." -ForegroundColor Green
                            Write-Host "`n"
                            Write-Host ">>> RECOMMANDATION TRÈS IMPORTANTE <<<" -ForegroundColor Yellow
                            Write-Host "Pour assurer une réinstallation complète, propre et stable des pilotes Bluetooth, il est FORTEMENT et INSTAMMENT RECOMMANDÉ de REDÉMARRER votre ordinateur MAINTENANT." -ForegroundColor Red
                            Write-Host "Si le problème persiste après le redémarrage, relancez le 'Diagnostic Complet' (Option 2) pour une nouvelle évaluation." -ForegroundColor DarkGray
                        } else {
                            Write-Host "Aucun adaptateur Bluetooth principal trouvé pour la gestion des pilotes. Vérifiez si votre matériel Bluetooth est détecté par Windows." -ForegroundColor Yellow
                        }
                    }
                    "2" { # Supprimer un package de pilote Bluetooth spécifique
                        Write-Host "`n--- Suppression d'un package de pilote Bluetooth spécifique ---" -ForegroundColor Yellow
                        Write-Warning "Ceci va supprimer DÉFINITIVEMENT le package de pilote du Driver Store de Windows."
                        Write-Warning "Cela est utile pour les pilotes corrompus, mais peut rendre le périphérique inutilisable si le bon pilote n'est plus disponible."
                        Write-Host "`nListe des packages de pilotes Bluetooth installés (recherchez les noms 'oemXX.inf'):" -ForegroundColor White
                        
                        # List Bluetooth driver packages
                        try {
                            $bluetoothDriverPackages = (pnputil.exe /enum-drivers) | Select-String -Pattern "Published name|Provider|Class" | Out-String
                            Write-Host $bluetoothDriverPackages -ForegroundColor White
                            Write-Host "`nEntrez le 'Published name' du package de pilote à supprimer (ex: 'oem123.inf') ou 'annuler'." -ForegroundColor Yellow
                            $driverPackageName = Read-Host
                            
                            if ($driverPackageName -eq "annuler") {
                                Write-Host "Opération annulée." -ForegroundColor Yellow
                            } elseif (-not [string]::IsNullOrEmpty($driverPackageName) -and $driverPackageName -like "oem*.inf") {
                                Write-Warning "Confirmez-vous la suppression du package de pilote '$driverPackageName'? (CONFIRMER/non)"
                                $confirmDelete = Read-Host
                                if ($confirmDelete -eq "CONFIRMER") {
                                    try {
                                        # pnputil /delete-driver oemXX.inf /force
                                        Start-Process pnputil.exe -ArgumentList "/delete-driver", "$driverPackageName", "/force" -NoNewWindow -Wait -PassThru | Out-Null
                                        Write-Host "`nPackage de pilote '$driverPackageName' supprimé avec succès." -ForegroundColor Green
                                        Write-Host "RECOMMANDATION: Redémarrez votre ordinateur pour que les changements prennent effet." -ForegroundColor Yellow
                                    } catch {
                                        Write-Error "Erreur lors de la suppression du package de pilote: $($_.Exception.Message)"
                                        Write-Warning "Assurez-vous que le nom du package est correct et que PowerShell est exécuté en tant qu'administrateur."
                                    }
                                } else {
                                    Write-Host "Suppression du package de pilote annulée." -ForegroundColor Yellow
                                }
                            } else {
                                Write-Warning "Nom de package invalide. Il doit être au format 'oemXX.inf'."
                            }
                        } catch {
                            Write-Error "Erreur lors de la liste ou de la suppression des packages de pilotes: $($_.Exception.Message)"
                            Write-Warning "Assurez-vous que pnputil.exe est disponible et que PowerShell est exécuté en tant qu'administrateur."
                        }
                    }
                    "0" { Write-Host "Opération annulée." -ForegroundColor Yellow }
                    default { Write-Warning "Choix invalide." }
                }
            }
            "6" { # Lancer l'outil de dépannage Windows Bluetooth
                Clear-Host
                Write-Host "`n--- Lancement de l'outil de dépannage Windows Bluetooth ---" -ForegroundColor Yellow
                Write-Host "Cette option ouvre l'utilitaire de résolution des problèmes intégré de Windows pour le Bluetooth." -ForegroundColor White
                Write-Host "Suivez les instructions à l'écran dans la fenêtre qui va apparaître." -ForegroundColor Cyan
                try {
                    # This command opens the troubleshooter UI for device issues, which includes Bluetooth
                    Start-Process -FilePath "msdt.exe" -ArgumentList "-id DeviceDiagnostic" -Wait -NoNewWindow -PassThru | Out-Null
                    Write-Host "`nOutil de dépannage lancé. Suivez les instructions à l'écran." -ForegroundColor Green
                } catch {
                    Write-Error "Erreur lors du lancement de l'outil de dépannage: $($_.Exception.Message)"
                    Write-Warning "L'outil de dépannage n'a pas pu être lancé. Vous pouvez le trouver manuellement dans Paramètres > Système > Résolution des problèmes > Autres utilitaires de résolution des problèmes > Bluetooth."
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "7" { # Lister Détaillé les appareils Bluetooth
                Clear-Host
                Write-Host "`n--- Liste Détaillée des appareils Bluetooth ---" -ForegroundColor Yellow
                Write-Host "Cette option affiche une liste complète et détaillée de tous les adaptateurs et périphériques Bluetooth actuellement détectés ou jumelés par votre système." -ForegroundColor White
                Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
                try {
                    # List all PnP devices that are Bluetooth, or HID devices (like mice, keyboards) linked to Bluetooth, or Wireless Radios for Bluetooth
                    $allBluetoothDevices = Get-PnpDevice -PresentOnly | Where-Object {
                        $_.Class -eq "Bluetooth" -or ($_.Class -eq "HIDClass" -and $_.FriendlyName -like "*Bluetooth*") -or ($_.Class -eq "WirelessRadio" -and $_.FriendlyName -like "*Bluetooth*")
                    } | Sort-Object FriendlyName

                    if ($allBluetoothDevices) {
                        Write-Host "`nListe complète des périphériques Bluetooth et des périphériques HID liés au Bluetooth:" -ForegroundColor Green
                        $allBluetoothDevices | Format-Table -AutoSize FriendlyName, Status, Class, DeviceID, Manufacturer, DriverVersion
                        Write-Host "`n* 'Status OK' indique un périphérique fonctionnel. Tout autre statut suggère un problème." -ForegroundColor DarkGray
                        Write-Host "* Le 'DeviceID' est un identifiant unique utile pour l'option de suppression spécifique (Option 8)." -ForegroundColor DarkGray
                        Write-Host "* 'Manufacturer' et 'DriverVersion' peuvent aider à identifier les pilotes." -ForegroundColor DarkGray
                    } else {
                        Write-Host "Aucun appareil Bluetooth ou périphérique HID lié au Bluetooth trouvé. Votre adaptateur pourrait ne pas être détecté ou aucun périphérique n'est jumelé." -ForegroundColor DarkYellow
                    }
                } catch {
                    Write-Error "Erreur lors de la récupération des appareils Bluetooth: $($_.Exception.Message)"
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "8" { # Supprimer un appareil Bluetooth Jumelé/Connecté Spécifique (MODIFIED)
                Clear-Host
                Write-Host "`n--- Supprimer un appareil Bluetooth Jumelé/Connecté Spécifique ---" -ForegroundColor Yellow
                Write-Host "Cette option vous permet de choisir un appareil Bluetooth spécifique à retirer de la liste des périphériques connus. Cela peut résoudre des problèmes de connexion si un jumelage est corrompu." -ForegroundColor White
                Write-Warning "ATTENTION DANGEREUX: Ceci va SUPPRIMER l'appareil sélectionné de votre système. Il devra être jumelé à nouveau comme un nouvel appareil si vous souhaitez l'utiliser à l'avenir."
                Write-Warning "CONFIRMATION REQUISE: Pour confirmer la suppression, tapez 'CONFIRMER' (en majuscules) et appuyez sur Entrée. Toute autre entrée annulera l'opération."
                Write-Host "`nListe des appareils Bluetooth détectés (utilisez cette liste pour trouver l'appareil à supprimer):" -ForegroundColor White
                # Use Out-GridView for an interactive selection, which is safer for deleting specific devices
                $removableDevices = Get-PnpDevice -PresentOnly | Where-Object {
                    $_.Class -eq "Bluetooth" -or ($_.Class -eq "HIDClass" -and $_.FriendlyName -like "*Bluetooth*")
                } | Select-Object FriendlyName, DeviceID, InstanceId | Out-GridView -Title "Sélectionnez L'APPAREIL BLUETOOTH À SUPPRIMER (cliquez sur 'OK' après sélection)" -PassThru

                if ($removableDevices) {
                    $selectedInstanceId = $removableDevices.InstanceId
                    $selectedFriendlyName = $removableDevices.FriendlyName

                    Write-Host "`nVous avez sélectionné l'appareil suivant pour suppression:" -ForegroundColor Cyan
                    Write-Host "  Nom: $($selectedFriendlyName)" -ForegroundColor Cyan
                    Write-Host "  ID d'instance: $($selectedInstanceId)" -ForegroundColor Cyan
                    Write-Warning "CONFIRMATION REQUISE: Pour confirmer la suppression, tapez 'CONFIRMER' (en majuscules) et appuyez sur Entrée. Toute autre entrée annulera l'opération."
                    $finalConfirm = Read-Host

                    if ($finalConfirm -eq "CONFIRMER") { # Changed to specific string confirmation
                        try {
                            Write-Host "Tentative de suppression de l'appareil '$selectedFriendlyName'..." -ForegroundColor White
                            # --- MODIFIED: Using pnputil.exe instead of Remove-PnpDevice ---
                            $pnputilOutput = Start-Process -FilePath "pnputil.exe" -ArgumentList "/remove-device", "$($selectedInstanceId)", "/force" -Wait -NoNewWindow -PassThru | Out-Null
                            if ($pnputilOutput.ExitCode -eq 0) {
                                Write-Host "`n✅ Appareil '$selectedFriendlyName' supprimé avec succès via pnputil." -ForegroundColor Green
                                Write-Host "Vous devrez le jumeler à nouveau si vous souhaitez l'utiliser." -ForegroundColor DarkGray
                            } else {
                                $stdout = Get-Content $pnputilOutput.StandardOutput
                                $stderr = Get-Content $pnputilOutput.StandardError
                                Write-Warning "  Échec de la suppression du pilote avec pnputil.exe pour '$($adapter.FriendlyName)'. Code de sortie: $($pnputilOutput.ExitCode)"
                                Write-Warning "  Sortie standard: $($stdout | Out-String)"
                                Write-Warning "  Erreur standard: $($stderr | Out-String)"
                            }
                            Remove-Item $pnputilOutput.StandardOutput, $pnputilOutput.StandardError -ErrorAction SilentlyContinue
                            # --- END MODIFIED ---
                        } catch {
                            Write-Error "Erreur inattendue lors de l'utilisation de pnputil.exe: $($_.Exception.Message)"
                            Write-Warning "Assurez-vous que PowerShell est exécuté en tant qu'administrateur."
                        }
                    } else {
                        Write-Host "Suppression annulée par l'utilisateur." -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "Aucun appareil sélectionné ou opération annulée." -ForegroundColor Yellow
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "9" { # Examiner les erreurs Bluetooth dans l'Observateur d'événements
                Clear-Host
                Write-Host "`n--- Examiner les erreurs Bluetooth dans l'Observateur d'événements ---" -ForegroundColor Yellow
                Write-Host "Cette option ouvre l'Observateur d'événements de Windows et applique un filtre pour afficher les erreurs et avertissements récents liés au Bluetooth." -ForegroundColor White
                Write-Host "Cela vous permettra d'analyser les problèmes en détail." -ForegroundColor Cyan
                try {
                    # Create a custom view in Event Viewer for Bluetooth-related events
                    # This filter looks for events in 'System' and 'Application' logs with specific keywords,
                    # generated in the last 15 minutes (900000 milliseconds).
                    $xmlFilter = @"
<QueryList>
  <Query Id="0" Path="System">
    <Select Path="System">
      *[System[(Level=1 or Level=2 or Level=3) and TimeCreated[Timediff(900000)]]]
      and
      *[EventData[Data and (Data='Bluetooth' or Data='BTHUSB' or Data='BTHENUM' or Data='bthserv' or Data='BTLE')]]
    </Select>
  </Query>
  <Query Id="1" Path="Application">
    <Select Path="Application">
      *[System[(Level=1 or Level=2 or Level=3) and TimeCreated[Timediff(900000)]]]
      and
      *[EventData[Data and (Data='Bluetooth' or Data='BTHUSB' or Data='BTHENUM' or Data='bthserv' or Data='BTLE')]]
    </Select>
  </Query>
</QueryList>
"@ # IMPORTANT: This closing "@ must be flush left, no leading spaces.
                    # Save the filter to a temporary file
                    $tempFilterFile = [System.IO.Path]::GetTempFileName() + ".xml"
                    $xmlFilter | Out-File -FilePath $tempFilterFile -Encoding UTF8

                    Write-Host "Ouverture de l'Observateur d'événements avec le filtre Bluetooth..." -ForegroundColor White
                    Start-Process -FilePath "eventvwr.msc" -ArgumentList "/f:$tempFilterFile" -ErrorAction Stop
                    Write-Host "`nL'Observateur d'événements est ouvert avec un filtre appliqué pour les événements Bluetooth récents (dernières 15 minutes)." -ForegroundColor Green
                    Write-Host "Vous pouvez ajuster le filtre directement dans l'Observateur d'événements." -ForegroundColor DarkGray

                    # Clean up the temporary file (optional, can be done later or by a cleanup script)
                    # Remove-Item $tempFilterFile -ErrorAction SilentlyContinue
                } catch {
                    Write-Error "Erreur lors de l'ouverture de l'Observateur d'événements: $($_.Exception.Message)"
                    Write-Warning "Impossible de lancer l'Observateur d'événements avec le filtre. Veuillez l'ouvrir manuellement (eventvwr.msc) et créer un filtre pour 'Bluetooth' dans les journaux 'Système' et 'Application'."
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "10" { # Réinitialisation de la pile logicielle Bluetooth (MODIFIED)
                Clear-Host
                Write-Host "`n--- Réinitialisation de la pile logicielle Bluetooth ---" -ForegroundColor Yellow
                Write-Host "Cette option effectue une réinitialisation plus profonde de la pile logicielle Bluetooth, incluant l'arrêt des services, la suppression des pilotes, et la réinitialisation des paramètres réseau." -ForegroundColor White
                Write-Host "C'est une mesure plus radicale à utiliser en dernier recours." -ForegroundColor Red
                Write-Warning "ATTENTION: Cette opération est invasive et peut nécessiter un REDÉMARRAGE de l'ordinateur pour être pleinement effective. Toutes les connexions et jumelages Bluetooth seront perdus."
                Write-Warning "CONFIRMATION REQUISE: Pour confirmer la réinitialisation de la pile, tapez 'CONFIRMER' (en majuscules) et appuyez sur Entrée. Toute autre entrée annulera l'opération."
                $confirm = Read-Host
                if ($confirm -eq "CONFIRMER") { # Changed to specific string confirmation
                    try {
                        Write-Host "Étape 1/4: Arrêt des services Bluetooth..." -ForegroundColor White
                        Get-Service -Name "bthserv", "BluetoothUserService", "BluetoothSupportService" -ErrorAction SilentlyContinue | Stop-Service -Confirm:$false -ErrorAction SilentlyContinue -Force # Added -Force
                        Start-Sleep -Seconds 2

                        Write-Host "Étape 2/4: Désactivation de l'adaptateur réseau Bluetooth..." -ForegroundColor White
                        $btNetAdapter = Get-NetAdapter -Name "Bluetooth*" -ErrorAction SilentlyContinue
                        if ($btNetAdapter) {
                            Disable-NetAdapter -InputObject $btNetAdapter -Confirm:$false -ErrorAction SilentlyContinue
                            Start-Sleep -Seconds 2
                        }

                        Write-Host "Étape 3/4: Suppression des pilotes Bluetooth de l'adaptateur principal..." -ForegroundColor White
                        $bluetoothAdapters = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*Bluetooth Radio*" -or $_.FriendlyName -like "*Bluetooth Adapter*" }
                        if ($bluetoothAdapters) {
                            foreach ($adapter in $bluetoothAdapters) {
                                Write-Host "  Suppression des pilotes pour: $($adapter.FriendlyName)..." -ForegroundColor Cyan
                                # --- MODIFIED: Using pnputil.exe instead of Remove-PnpDevice ---
                                $pnputilOutput = Start-Process -FilePath "pnputil.exe" -ArgumentList "/remove-device", "$($adapter.InstanceId)", "/force" -Wait -NoNewWindow -PassThru | Out-Null
                                if ($pnputilOutput.ExitCode -eq 0) {
                                    Write-Host "  Pilote désinstallé pour '$($adapter.FriendlyName)' via pnputil." -ForegroundColor Green
                                } else {
                                    $stdout = Get-Content $pnputilOutput.StandardOutput
                                    $stderr = Get-Content $pnputilOutput.StandardError
                                    Write-Warning "  Échec de la suppression du pilote avec pnputil.exe pour '$($adapter.FriendlyName)'. Code de sortie: $($pnputilOutput.ExitCode)"
                                    Write-Warning "  Sortie standard: $($stdout | Out-String)"
                                    Write-Warning "  Erreur standard: $($stderr | Out-String)"
                                }
                                Remove-Item $pnputilOutput.StandardOutput, $pnputilOutput.StandardError -ErrorAction SilentlyContinue
                                # --- END MODIFIED ---
                                Start-Sleep -Seconds 1
                            }
                        }

                        Write-Host "Étape 4/4: Réinitialisation de la pile réseau (Winsock/IP stack - cela affecte aussi le Bluetooth via le réseau)..." -ForegroundColor White
                        netsh winsock reset | Out-Null
                        netsh int ip reset | Out-Null
                        ipconfig /flushdns | Out-Null
                        Write-Host "  Réinitialisation des composants réseau terminée." -ForegroundColor Green
                        Write-Host "`n"
                        Write-Host ">>> RÉINITIALISATION DE LA PILE BLUETOOTH TERMINÉE <<<" -ForegroundColor Yellow
                        Write-Host "Pour que les changements prennent pleinement effet et que la pile Bluetooth soit reconstruite proprement, il est INDISPENSABLE de REDÉMARRER votre ordinateur MAINTENANT." -ForegroundColor Red
                        Write-Host "Après le redémarrage, Windows réinstallera les pilotes et redémarrera les services." -ForegroundColor DarkGray

                    } catch {
                        Write-Error "Erreur lors de la réinitialisation de la pile Bluetooth: $($_.Exception.Message)"
                        Write-Warning "Assurez-vous que PowerShell est exécuté en tant qu'administrateur. Un redémarrage manuel est recommandé."
                    }
                } else {
                    Write-Host "Opération annulée." -ForegroundColor Yellow
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "11" { # NOUVELLE OPTION: Générer un Rapport de Diagnostic Bluetooth Détaillé
                Clear-Host
                Write-Host "`n--- Génération d'un Rapport de Diagnostic Bluetooth Détaillé ---" -ForegroundColor Yellow
                Write-Host "Ceci va collecter des informations détaillées sur l'état de votre Bluetooth." -ForegroundColor White
                Write-Host "Le rapport sera enregistré dans votre dossier de logs : $($global:WMToolkitLogPath)" -ForegroundColor DarkGray
                
                $reportContent = ""
                $reportContent += "--- Rapport de Diagnostic Bluetooth WMToolkit ---\n"
                $reportContent += "Date du rapport: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')\n"
                $reportContent += "PC ID (Chiffré): $($global:UniquePCID)\n" # Utilise l'ID unique généré au démarrage
                $reportContent += "---------------------------------------------------\n\n"

                # 1. Informations sur l'adaptateur principal
                Write-Host "Collecte des informations sur l'adaptateur principal..." -ForegroundColor White
                try {
                    $btAdapterPnp = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*Bluetooth Radio*" -or $_.FriendlyName -like "*Bluetooth Adapter*" }
                    if ($btAdapterPnp) {
                        $reportContent += "--- Adaptateur Bluetooth Principal ---\n"
                        $reportContent += "Nom: $($btAdapterPnp.FriendlyName)\n"
                        $reportContent += "Statut Général: $($btAdapterPnp.Status)\n"
                        $reportContent += "Fabricant: $($btAdapterPnp.Manufacturer)\n"
                        $reportContent += "ID d'instance: $($btAdapterPnp.InstanceId)\n"
                        $driverInfo = Get-WmiObject Win32_PnPSignedDriver | Where-Object {$_.DeviceID -eq $btAdapterPnp.DeviceID} | Select-Object -First 1 -ErrorAction SilentlyContinue
                        if ($driverInfo) {
                            $reportContent += "Pilote Fournisseur: $($driverInfo.DriverProviderName)\n"
                            $reportContent += "Pilote Version: $($driverInfo.DriverVersion)\n"
                            $reportContent += "Pilote Date: $($driverInfo.DriverDate)\n"
                            $reportContent += "Pilote Signature: $($driverInfo.IsSigned)\n"
                        } else { $reportContent += "Détails du pilote non disponibles.\n" }
                        $reportContent += "--------------------------------------\n\n"
                    } else {
                        $reportContent += "--- Aucun adaptateur Bluetooth principal détecté. ---\n\n"
                    }
                } catch { $reportContent += "Erreur de collecte adaptateur: $($_.Exception.Message)\n\n" }

                # 2. État des services Bluetooth
                Write-Host "Collecte de l'état des services Bluetooth..." -ForegroundColor White
                try {
                    $services = Get-Service -Name "*bluetooth*" -ErrorAction SilentlyContinue | Select-Object DisplayName, Name, Status, StartType
                    $reportContent += "--- Services Bluetooth ---\n"
                    if ($services) { $reportContent += ($services | Out-String) + "\n" } else { $reportContent += "Aucun service Bluetooth trouvé.\n" }
                    $reportContent += "--------------------------\n\n"
                } catch { $reportContent += "Erreur de collecte services: $($_.Exception.Message)\n\n" }

                # 3. Liste détaillée des appareils Bluetooth connectés/jumelés
                Write-Host "Collecte des appareils Bluetooth connectés/jumelés..." -ForegroundColor White
                try {
                    $devices = Get-PnpDevice -PresentOnly | Where-Object { $_.Class -eq "Bluetooth" -or ($_.Class -eq "HIDClass" -and $_.FriendlyName -like "*Bluetooth*") } | Select-Object FriendlyName, Status, Class, DeviceID, Manufacturer, DriverVersion
                    $reportContent += "--- Appareils Bluetooth Détectés ---\n"
                    if ($devices) { $reportContent += ($devices | Out-String) + "\n" } else { $reportContent += "Aucun appareil Bluetooth détecté.\n" }
                    $reportContent += "------------------------------------\n\n"
                } catch { $reportContent += "Erreur de collecte appareils: $($_.Exception.Message)\n\n" }

                # 4. Erreurs récentes dans l'Observateur d'événements
                Write-Host "Collecte des erreurs Bluetooth récentes (Observateur d'événements)..." -ForegroundColor White
                try {
                    $eventLogs = Get-WinEvent -FilterHashtable @{
                        LogName = @('System', 'Application');
                        Level = @(1, 2, 3); # Critical, Error, Warning
                        StartTime = (Get-Date).AddHours(-24) # Last 24 hours
                    } -ErrorAction SilentlyContinue | Where-Object {
                        $_.Message -like '*bluetooth*' -or $_.ProviderName -like '*bluetooth*' -or $_.Id -in @(17, 18, 19, 20, 21) # Common Bluetooth Event IDs
                    } | Select-Object TimeCreated, LevelDisplayName, ProviderName, Id, Message -First 10
                    
                    $reportContent += "--- Erreurs/Avertissements Bluetooth Récents (24h) ---\n"
                    if ($eventLogs) { $reportContent += ($eventLogs | Out-String) + "\n" } else { $reportContent += "Aucune erreur/avertissement Bluetooth récent trouvé.\n" }
                    $reportContent += "-----------------------------------------------------\n\n"
                } catch { $reportContent += "Erreur de collecte événements: $($_.Exception.Message)\n\n" }

                # 5. Contenu du log du toolkit
                Write-Host "Inclusion du log du toolkit..." -ForegroundColor White
                $latestToolkitLog = Get-ChildItem -Path $global:WMToolkitLogPath -Filter "ToolkitLog_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($latestToolkitLog -and (Test-Path $latestToolkitLog.FullName)) {
                    $reportContent += "--- Contenu du Log du Toolkit le plus récent ---\n"
                    $reportContent += (Get-Content $latestToolkitLog.FullName | Out-String)
                    $reportContent += "--------------------------------------------------\n\n"
                } else {
                    $reportContent += "--- Log du Toolkit non trouvé ou vide. ---\n\n"
                }

                # --- Chiffrement et Sauvegarde du Rapport ---
                $encryptedReportBase64 = $null
                $reportFilePath = Join-Path $global:WMToolkitLogPath "BluetoothDiagnosticReport_PCID-$($global:UniquePCID)_$(Get-Date -Format 'yyyyMMdd_HHmmss').encrypted"
                
                if (-not [string]::IsNullOrEmpty($global:PublicKeyXml)) {
                    try {
                        $tempFileForEncryption = [System.IO.Path]::GetTempFileName()
                        [System.IO.File]::WriteAllText($tempFileForEncryption, $reportContent, [System.Text.Encoding]::UTF8)
                        
                        $encryptedReportBase64 = Protect-FileWithPublicKey -FilePathToEncrypt $tempFileForEncryption -PublicKeyXml $global:PublicKeyXml
                        Remove-Item $tempFileForEncryption -ErrorAction SilentlyContinue

                        if ($encryptedReportBase64) {
                            [System.IO.File]::WriteAllText($reportFilePath, $encryptedReportBase64, [System.Text.Encoding]::UTF8)
                            Write-Host "`n✅ Rapport de diagnostic Bluetooth chiffré enregistré: $($reportFilePath)" -ForegroundColor Green
                        } else {
                            Write-Warning "Échec du chiffrement du rapport de diagnostic Bluetooth. Le rapport sera enregistré en clair."
                            $reportFilePath = $reportFilePath -replace "\.encrypted$", ".txt" # Change extension to .txt
                            [System.IO.File]::WriteAllText($reportFilePath, $reportContent, [System.Text.Encoding]::UTF8)
                            Write-Warning "Rapport de diagnostic Bluetooth NON chiffré enregistré: $($reportFilePath)"
                        }
                    } catch {
                        Write-Error "Erreur lors du chiffrement/enregistrement du rapport: $($_.Exception.Message)"
                        Write-Warning "Le rapport de diagnostic Bluetooth ne sera pas chiffré. Il sera enregistré en clair."
                        $reportFilePath = $reportFilePath -replace "\.encrypted$", ".txt" # Change extension to .txt
                        [System.IO.File]::WriteAllText($reportFilePath, $reportContent, [System.Text.Encoding]::UTF8)
                        Write-Warning "Rapport de diagnostic Bluetooth NON chiffré enregistré: $($reportFilePath)"
                    }
                } else {
                    Write-Warning "Clé publique non configurée (\$global:PublicKeyXml est vide). Le rapport de diagnostic Bluetooth ne sera pas chiffré. Il sera enregistré en clair."
                    $reportFilePath = $reportFilePath -replace "\.encrypted$", ".txt" # Change extension to .txt
                    [System.IO.File]::WriteAllText($reportFilePath, $reportContent, [System.Text.Encoding]::UTF8)
                    Write-Warning "Rapport de diagnostic Bluetooth NON chiffré enregistré: $($reportFilePath)"
                }

                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "12" { # NOUVELLE OPTION: Test Approfondi & Gestion Ciblée de l'Adaptateur Bluetooth
                Clear-Host
                Write-Host "`n--- Test Approfondi & Gestion Ciblée de l'Adaptateur Bluetooth ---" -ForegroundColor Yellow
                Write-Host "Cette option vous permet d'isoler et de tester un adaptateur Bluetooth spécifique." -ForegroundColor White
                Write-Warning "ATTENTION: Tous les autres adaptateurs Bluetooth seront temporairement DÉSACTIVÉS pendant le test."
                Write-Warning "Vos connexions Bluetooth existantes seront interrompues."
                
                $confirmTest = Read-Host "Voulez-vous commencer le test approfondi ? (O/N)"
                if ($confirmTest -eq "O" -or $confirmTest -eq "o") {
                    try {
                        # 1. Lister tous les adaptateurs Bluetooth disponibles
                        Write-Host "`nRecherche des adaptateurs Bluetooth..." -ForegroundColor White
                        $allBluetoothAdapters = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*Bluetooth*" }

                        if (-not $allBluetoothAdapters) {
                            Write-Warning "Aucun adaptateur Bluetooth n'a été trouvé sur ce système."
                            Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                            break
                        }

                        # Créer une liste numérotée pour la sélection
                        $adapterSelectionOptions = @()
                        $i = 1
                        foreach ($adapter in $allBluetoothAdapters) {
                            $adapterSelectionOptions += [PSCustomObject]@{
                                Number = $i;
                                FriendlyName = $adapter.FriendlyName;
                                Status = $adapter.Status;
                                InstanceId = $adapter.InstanceId;
                                OriginalAdapter = $adapter # Store original object
                            }
                            $i++
                        }
                        
                        Write-Host "`nSélectionnez l'adaptateur à tester:" -ForegroundColor Yellow
                        $adapterSelectionOptions | Format-Table -AutoSize Number, FriendlyName, Status
                        Write-Host "0. Annuler" -ForegroundColor Red
                        $selection = Read-Host "Entrez le numéro de l'adaptateur (ou 0 pour annuler)"

                        if ($selection -eq "0") {
                            Write-Host "Test annulé." -ForegroundColor Yellow
                            break
                        }

                        $selectedAdapterInfo = $adapterSelectionOptions | Where-Object { $_.Number -eq [int]$selection }
                        if (-not $selectedAdapterInfo) {
                            Write-Warning "Sélection invalide. Test annulé."
                            break
                        }
                        $targetAdapter = $selectedAdapterInfo.OriginalAdapter
                        Write-Host "`nAdaptateur sélectionné pour le test: $($targetAdapter.FriendlyName)" -ForegroundColor Cyan

                        # 2. Désactiver tous les autres adaptateurs
                        Write-Host "Désactivation des autres adaptateurs Bluetooth..." -ForegroundColor Yellow
                        $otherAdapters = $allBluetoothAdapters | Where-Object { $_.InstanceId -ne $targetAdapter.InstanceId }
                        $disabledAdapters = @() # To keep track of what was disabled

                        foreach ($adapter in $otherAdapters) {
                            if ($adapter.Status -eq "OK") { # Only disable if currently OK
                                try {
                                    Disable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction Stop
                                    $disabledAdapters += $adapter # Add to list of disabled
                                    Write-Host "  Désactivé: $($adapter.FriendlyName)" -ForegroundColor DarkGray
                                } catch {
                                    Write-Warning "  Impossible de désactiver $($adapter.FriendlyName): $($_.Exception.Message)"
                                }
                            }
                        }
                        Start-Sleep -Seconds 3

                        # 3. Effectuer des tests de base sur l'adaptateur cible
                        Write-Host "`nTests sur l'adaptateur cible: $($targetAdapter.FriendlyName)..." -ForegroundColor Yellow
                        
                        # Test: Vérifier le statut après isolement
                        $currentStatus = (Get-PnpDevice -InstanceId $targetAdapter.InstanceId -ErrorAction SilentlyContinue).Status
                        Write-Host "  Statut actuel de l'adaptateur cible: $($currentStatus)" -ForegroundColor White
                        if ($currentStatus -eq "OK") {
                            Write-Host "  L'adaptateur semble fonctionnel après isolement." -ForegroundColor Green
                        } else {
                            Write-Warning "  L'adaptateur est toujours en état non-optimal: $($currentStatus)."
                        }

                        # Test: Tenter de le désactiver/réactiver
                        Write-Host "  Tentative de désactivation/réactivation de l'adaptateur cible..." -ForegroundColor White
                        try {
                            Disable-PnpDevice -InstanceId $targetAdapter.InstanceId -Confirm:$false -ErrorAction Stop
                            Start-Sleep -Seconds 2
                            Enable-PnpDevice -InstanceId $targetAdapter.InstanceId -Confirm:$false -ErrorAction Stop
                            Write-Host "  Désactivation/réactivation réussie." -ForegroundColor Green
                        } catch {
                            Write-Warning "  Échec de la désactivation/réactivation de l'adaptateur cible: $($_.Exception.Message)"
                        }
                        
                        # Test: Vérifier les services Bluetooth critiques (s'ils sont liés à cet adaptateur)
                        Write-Host "  Vérification des services Bluetooth (Option 4 peut les redémarrer si besoin)..." -ForegroundColor White
                        Get-Service -Name "bthserv", "BluetoothUserService*" -ErrorAction SilentlyContinue | Format-Table -AutoSize DisplayName, Status


                        Write-Host "`nTests de l'adaptateur cible terminés." -ForegroundColor Green

                    } catch {
                        Write-Error "Erreur lors du test approfondi: $($_.Exception.Message)"
                        Write-Warning "Assurez-vous que PowerShell est exécuté en tant qu'administrateur."
                    } finally {
                        # 4. Réactiver tous les adaptateurs désactivés
                        Write-Host "`nRéactivation de tous les adaptateurs Bluetooth précédemment désactivés..." -ForegroundColor Yellow
                        foreach ($adapter in $disabledAdapters) {
                            try {
                                Enable-PnpDevice -InstanceId $adapter.InstanceId -Confirm:$false -ErrorAction Stop
                                Write-Host "  Réactivé: $($adapter.FriendlyName)" -ForegroundColor DarkGray
                            } catch {
                                Write-Warning "  Impossible de réactiver $($adapter.FriendlyName): $($_.Exception.Message)"
                            }
                        }
                        Write-Host "Réactivation terminée." -ForegroundColor Green
                    }
                } else {
                    Write-Host "Test approfondi annulé." -ForegroundColor Yellow
                }
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "0" {
                Write-Host "`nRetour au menu principal..." -ForegroundColor White
                $Continue = $false # Exit the loop
            }
            default {
                Write-Warning "Choix invalide. Veuillez entrer un numéro entre 0 et 12."
                Start-Sleep -Seconds 1
            }
        }
    } while ($Continue) # Loop continues as long as $Continue is true (i.e., until '0' is chosen)
}
Export-ModuleMember -Function Invoke-BluetoothToolsMenu