function Invoke-BIOSCheckMenu {
    param($Continue = $false)

    do {
        Clear-Host # <--- AJOUTEZ CETTE LIGNE ICI !
        Show-WMToolkitHeader -Title "8. Vérification de mise à jour BIOS (lecture seule)"
        Write-Host "🔍 DÉTAIL DES SECTIONS" -ForegroundColor White
        Write-Host "---------------------" -ForegroundColor DarkYellow
        Write-Host "🔹 Affiche: Marque, Modèle, Version actuelle BIOS, Date BIOS" -ForegroundColor White
        Write-Host "🔹 Fournit lien support constructeur (Dell, HP, Lenovo, etc.)" -ForegroundColor White
        Write-Host "🔹 Ne fait aucune mise à jour (sécurité)" -ForegroundColor White
        Write-Host "🔹 Met en garde: “ne pas mettre à jour sans connaissance”" -ForegroundColor Red
        Write-Host ""

        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
        Write-Host "1. Afficher les informations BIOS et liens support" -ForegroundColor Green
        Write-Host "0. Retour au menu principal" -ForegroundColor Red
        Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

        $subChoice = Read-Host "Entrez votre choix"

        switch ($subChoice) {
            "1" { # Show BIOS Info
                Clear-Host # <--- AJOUTEZ AUSSI CETTE LIGNE POUR NETTOYER AVANT D'AFFICHER LES INFOS BIOS
                Write-Host "`n--- Informations BIOS et Support Fabricateur ---" -ForegroundColor Yellow
                Write-Warning "IMPORTANT: La mise à jour du BIOS est une opération délicate. Une erreur peut rendre votre ordinateur inutilisable."
                Write-Warning "N'effectuez cette mise à jour que si nécessaire et en suivant SCURUPULEUSEMENT les instructions du fabricant."

                try {
                    # --- MODIFICATION CLÉ ICI : Utilisation de Get-CimInstance ---
                    $bios = Get-CimInstance Win32_BIOS
                    $comp = Get-CimInstance Win32_ComputerSystem # Utilisation de Get-CimInstance également pour la cohérence

                    Write-Host "Marque du BIOS: $($bios.Manufacturer)" -ForegroundColor White
                    Write-Host "Version du BIOS: $($bios.SMBIOSBIOSVersion)" -ForegroundColor White
                    
                    # $bios.ReleaseDate est déjà un objet DateTime valide avec Get-CimInstance
                    Write-Host "Date du BIOS: $($bios.ReleaseDate.ToString('dd/MM/yyyy'))" -ForegroundColor White
                    
                    Write-Host "Fabricant du PC: $($comp.Manufacturer)" -ForegroundColor White
                    Write-Host "Modèle du PC: $($comp.Model)" -ForegroundColor White

                    Write-Host "`nLiens de support constructeur (recherchez les mises à jour BIOS pour votre modèle):" -ForegroundColor Yellow
                    switch ($comp.Manufacturer) {
                        "Dell Inc." { Write-Host "  - Dell Support: https://www.dell.com/support" -ForegroundColor Cyan }
                        "HP" { Write-Host "  - HP Support: https://support.hp.com/" -ForegroundColor Cyan }
                        "Lenovo" { Write-Host "  - Lenovo Support: https://pcsupport.lenovo.com/" -ForegroundColor Cyan }
                        "Microsoft Corporation" { Write-Host "  - Microsoft Surface Support: https://support.microsoft.com/surface" -ForegroundColor Cyan }
                        "ASUSTeK COMPUTER INC." { Write-Host "  - Support ASUS: https://www.asus.com/support/" -ForegroundColor Cyan }
                        "MSI" { Write-Host "  - MSI Support: https://www.msi.com/support" -ForegroundColor Cyan }
                        "Acer" { Write-Host "  - Support Acer: https://www.acer.com/support/" -ForegroundColor Cyan }
                        "Gigabyte Technology Co., Ltd." { Write-Host "  - Support Gigabyte: https://www.gigabyte.com/Support" -ForegroundColor Cyan }
                        default { Write-Host "  - Recherchez le support pour '$($comp.Manufacturer)' sur Google." -ForegroundColor Cyan }
                    }
                    Write-Host "`nCeci est à titre informatif UNIQUEMENT. Aucune mise à jour ne sera effectuée par cet outil." -ForegroundColor DarkYellow
                } catch {
                    Write-Error "Erreur lors de la récupération des informations BIOS: $($_.Exception.Message)"
                    Write-Warning "Vérifiez que PowerShell est exécuté en tant qu'administrateur."
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
Export-ModuleMember -Function Invoke-BIOSCheckMenu