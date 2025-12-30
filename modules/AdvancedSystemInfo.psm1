function Invoke-SystemInfoMenu {
    param($Continue = $false)

    do {
        Clear-Host # <--- ADD THIS LINE HERE!
        Show-WMToolkitHeader -Title "7. Informations système avancées"
        Write-Host "🔍 DÉTAIL DES SECTIONS" -ForegroundColor White
        Write-Host "---------------------" -ForegroundColor DarkYellow
        Write-Host "🔹 Fabricant / Modèle PC" -ForegroundColor White
        Write-Host "🔹 Version de Windows / Build" -ForegroundColor White
        Write-Host "🔹 Infos RAM installée" -ForegroundColor White
        Write-Host "🔹 Nom de l’ordinateur" -ForegroundColor White
        Write-Host "🔹 Espace libre / total des disques" -ForegroundColor White
        Write-Host "🔹 Version PowerShell installée" -ForegroundColor White
        Write-Host "🔹 Adresse IP / MAC" -ForegroundColor White
        Write-Host "🔹 État de la batterie (si portable)" -ForegroundColor White
        Write-Host "🔹 État Bitlocker" -ForegroundColor White
        Write-Host ""

        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
        Write-Host "1. Afficher toutes les informations système" -ForegroundColor Green
        Write-Host "0. Retour au menu principal" -ForegroundColor Red
        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

        $subChoice = Read-Host "Entrez votre choix"

        switch ($subChoice) {
            "1" { # Show All System Info
                Clear-Host # <--- ADD THIS LINE HERE TO CLEAR BEFORE SHOWING INFO
                Write-Host "`n--- Informations Système Détaillées ---" -ForegroundColor Yellow
                try {
                    # PC Manufacturer / Model
                    $cs = Get-ComputerInfo
                    Write-Host "Fabricant du PC: $($cs.CsManufacturer)" -ForegroundColor White
                    Write-Host "Modèle du PC: $($cs.CsModel)" -ForegroundColor White

                    # Windows Version / Build
                    Write-Host "Version de Windows: $($cs.WindowsProductName)" -ForegroundColor White
                    Write-Host "Build de Windows: $($cs.WindowsBuildNumber)" -ForegroundColor White
                    Write-Host "Architecture: $($cs.OsArchitecture)" -ForegroundColor White

                    # RAM Info
                    $ram = Get-CimInstance Win32_ComputerSystem
                    Write-Host "RAM installée: $([math]::Round($ram.TotalPhysicalMemory / 1GB, 2)) Go" -ForegroundColor White
                    Get-CimInstance Win32_PhysicalMemory | ForEach-Object {
                        Write-Host "  - Slot $($_.DeviceLocator): $([math]::Round($_.Capacity / 1GB, 2)) Go $($_.Speed) MHz $($_.Manufacturer)" -ForegroundColor DarkGray
                    }

                    # Computer Name
                    Write-Host "Nom de l'ordinateur: $($env:COMPUTERNAME)" -ForegroundColor White

                    # Free / Total Disk Space
                    Write-Host "Espace Disque:" -ForegroundColor White
                    Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
                        $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                        $totalGB = [math]::Round($_.Size / 1GB, 2)
                        $percentFree = [math]::Round(($freeGB / $totalGB) * 100, 2)
                        Write-Host "  - Disque $($_.Caption): Libre: ${freeGB} Go / Total: ${totalGB} Go (${percentFree}% libre)" -ForegroundColor White
                    }

                    # PowerShell Version
                    Write-Host "Version PowerShell: $($PSVersionTable.PSVersion.ToString())" -ForegroundColor White

                    # IP / MAC Address
                    Write-Host "Adresses Réseau:" -ForegroundColor White
                    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
                        Write-Host "  - Interface: $($_.Name)" -ForegroundColor Green
                        Write-Host "    MAC: $($_.MacAddress)" -ForegroundColor White
                        Get-NetIPAddress -InterfaceIndex $_.IfIndex -ErrorAction SilentlyContinue | ForEach-Object {
                            Write-Host "    IP: $($_.IPAddress) (Famille: $($_.AddressFamily))" -ForegroundColor White
                        }
                    }

                    # Battery Status (if portable)
                    Write-Host "État de la Batterie (si portable):" -ForegroundColor White
                    $battery = Get-WmiObject Win32_Battery -ErrorAction SilentlyContinue
                    if ($battery) {
                        Write-Host "  Statut: $($battery.BatteryStatus)" -ForegroundColor White
                        Write-Host "  Pourcentage de charge: $($battery.EstimatedChargeRemaining)%" -ForegroundColor White
                        Write-Host "  Temps restant (minutes): $($battery.EstimatedRunTime)" -ForegroundColor White
                    } else {
                        Write-Host "  Pas de batterie détectée (système de bureau ou batterie absente/déconnectée)." -ForegroundColor Yellow
                    }

                    # BitLocker Status
                    Write-Host "État BitLocker:" -ForegroundColor White
                    try {
                        Get-BitLockerVolume -ErrorAction SilentlyContinue | ForEach-Object {
                            Write-Host "  - Volume $($_.MountPoint):" -ForegroundColor White
                            Write-Host "    Protection: $($_.VolumeStatus)" -ForegroundColor White
                            Write-Host "    Chiffrement: $($_.EncryptionMethod)" -ForegroundColor White
                            Write-Host "    Clé: $($_.KeyProtector)" -ForegroundColor White
                        }
                        if (-not (Get-BitLockerVolume -ErrorAction SilentlyContinue)) {
                            Write-Host "  Aucun volume BitLocker détecté ou BitLocker non activé." -ForegroundColor Yellow
                        }
                    } catch {
                        Write-Warning "  Impossible de récupérer l'état BitLocker (peut nécessiter des droits élevés ou module non chargé)."
                    }
                } catch {
                    Write-Error "Erreur lors de la récupération des informations système: $($_.Exception.Message)"
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
Export-ModuleMember -Function Invoke-SystemInfoMenu