function Invoke-SystemAndPartitionsMenu {
    Clear-Host # Add this line here
    Show-WMToolkitHeader -Title "1. Gestion du système & partitions"
    Write-Host "🔹 Lister les disques et partitions" -ForegroundColor White
    Write-Host "🔹 Vérification des erreurs (CHKDSK)" -ForegroundColor White
    Write-Host "🔹 Vérifier l’état SMART des disques" -ForegroundColor White
    Write-Host ""

    Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
    Write-Host "1. Lister les disques et partitions" -ForegroundColor Green
    Write-Host "2. Lancer CHKDSK sur une partition (ex: C:)" -ForegroundColor Green
    Write-Host "3. Vérifier l'état SMART des disques" -ForegroundColor Green
    Write-Host "0. Retour" -ForegroundColor Red
    Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

    $subChoice = Read-Host "Entrez votre choix"

    switch ($subChoice) {
        "1" {
            # Appel à la fonction complète pour lister disques et partitions
            Get-DiskAndPartitionDetails
        }
        "2" {
            Write-Host "`n--- Lancement de CHKDSK ---" -ForegroundColor Yellow # Added a title here for consistency
            $driveLetter = Read-Host "Entrez la lettre de lecteur à vérifier (ex: C)"
            if ($driveLetter -match "^[A-Za-z]$") {
                Write-Host "`n--- Lancement de CHKDSK sur $($driveLetter.ToUpper()): ---" -ForegroundColor Yellow
                Start-Process cmd.exe -ArgumentList "/c chkdsk $($driveLetter.ToUpper()): /f /r & pause" -Verb RunAs -Wait
            } else {
                Write-Warning "Lettre de lecteur invalide."
                Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray # Added pause for invalid input
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
        "3" {
            Write-Host "`n--- Vérification de l'état SMART ---" -ForegroundColor Yellow
            try {
                Get-WmiObject -Class MSStorageDriver_FailurePredictStatus -Namespace "root\wmi" | ForEach-Object {
                    $disk = Get-WmiObject -Class Win32_DiskDrive | Where-Object DeviceID -eq $_.InstanceName.Substring(0,$_.InstanceName.LastIndexOf("_"))
                    Write-Host "Disque: $($disk.Caption)" -ForegroundColor White
                    if ($_.PredictFailure) {
                        Write-Host "   Statut SMART: Echec Prédit (Problème détecté!)" -ForegroundColor Red
                    } else {
                        Write-Host "   Statut SMART: OK" -ForegroundColor Green
                    }
                }
            } catch {
                Write-Error "Erreur lors de la vérification SMART: $($_.Exception.Message)"
                Write-Warning "Assurez-vous d'exécuter PowerShell en tant qu'administrateur."
            }
            Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "0" { return }
        default {
            Write-Warning "Choix invalide."
            Start-Sleep -Seconds 1
        }
    }
    Invoke-SystemAndPartitionsMenu # Loop back to sub-menu until '0' is chosen
}

# --- Début de la nouvelle fonction Get-DiskAndPartitionDetails ---
function Get-DiskAndPartitionDetails {
    param(
        [switch]$ShowAllDisks # Add this parameter if you want to show all disks, even offline or hidden ones
    )

    Write-Host "`n--- Informations Détaillées sur les Disques et Partitions ---" -ForegroundColor Yellow
    Write-Host "Collecte des informations, veuillez patienter..." -ForegroundColor DarkGray

    try {
        # Get all physical disks
        $disks = Get-Disk -ErrorAction Stop
        if ($ShowAllDisks.IsPresent) {
            # No filtering, show all disks found
        } else {
            # By default, filter out RAW/Unknown disks or disks with no partitions, common for USBs not formatted or specific scenarios
            $disks = $disks | Where-Object { $_.PartitionStyle -ne "RAW" -and $_.IsSystem -eq $true -or $_.IsBoot -eq $true -or ($_.OperationalStatus -eq "Online" -and ($_.PartitionStyle -eq "GPT" -or $_.PartitionStyle -eq "MBR")) }
        }

        if (-not $disks) {
            Write-Warning "Aucun disque physique pertinent détecté. Assurez-vous que les disques sont branchés et accessibles."
            return
        }

        foreach ($disk in $disks) {
            Write-Host "`n----- Disque $($disk.Number) : $($disk.FriendlyName) -----" -ForegroundColor Cyan
            Write-Host "  Numéro de Disque    : $($disk.Number)" -ForegroundColor White
            Write-Host "  Nom Amical          : $($disk.FriendlyName)" -ForegroundColor Green
            Write-Host "  Modèle              : $($disk.Path)" -ForegroundColor Green
            Write-Host "  Taille Totale       : $([Math]::Round($disk.Size / 1GB, 2)) GB" -ForegroundColor Green
            Write-Host "  Style de Partition  : $($disk.PartitionStyle)" -ForegroundColor Green
            Write-Host "  Statut Opérationnel : $($disk.OperationalStatus)" -ForegroundColor Green
            Write-Host "  Est un disque système : $($disk.IsSystem)" -ForegroundColor Green
            Write-Host "  Est un disque de démarrage : $($disk.IsBoot)" -ForegroundColor Green

            # Get partitions for the current disk
            $partitions = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue

            if ($partitions) {
                Write-Host "`n  --- Partitions sur le Disque $($disk.Number) ---" -ForegroundColor Yellow
                foreach ($partition in $partitions) {
                    Write-Host "    Partition $($partition.PartitionNumber):" -ForegroundColor White
                    Write-Host "      Type              : $($partition.Type)" -ForegroundColor Green
                    Write-Host "      Taille            : $([Math]::Round($partition.Size / 1GB, 2)) GB" -ForegroundColor Green
                    Write-Host "      Statut Opérationnel : $($partition.OperationalStatus)" -ForegroundColor Green
                    
                    # Get the associated volume for this partition, if any
                    $volume = Get-Volume -Partition $partition -ErrorAction SilentlyContinue

                    if ($volume) {
                        Write-Host "      Lettre de lecteur : $($volume.DriveLetter):" -ForegroundColor Green
                        Write-Host "      Système de fichiers : $($volume.FileSystem)" -ForegroundColor Green
                        Write-Host "      Libellé           : $($volume.FileSystemLabel)" -ForegroundColor Green
                        Write-Host "      Taille Libre      : $([Math]::Round($volume.SizeRemaining / 1GB, 2)) GB" -ForegroundColor Green
                        Write-Host "      Pourcentage Libre : $([Math]::Round(($volume.SizeRemaining / $volume.Size) * 100, 2))%" -ForegroundColor Green
                    } else {
                        Write-Warning "      Aucun volume associé trouvé pour cette partition (peut être une partition de récupération ou système sans lettre de lecteur)."
                    }
                }
            } else {
                Write-Warning "  Aucune partition détectée sur le Disque $($disk.Number)."
            }
        }
    }
    catch {
        Write-Error "Une erreur est survenue lors de la récupération des informations du disque : $($_.Exception.Message)"
        Write-Warning "Assurez-vous d'exécuter PowerShell en tant qu'administrateur."
    }

    Write-Host "`n------------------------------------------------------------" -ForegroundColor DarkYellow
    Write-Host "Détails des disques et partitions affichés." -ForegroundColor White
    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") # Pause for user to read
}
# --- Fin de la nouvelle fonction Get-DiskAndPartitionDetails ---

Export-ModuleMember -Function Invoke-SystemAndPartitionsMenu