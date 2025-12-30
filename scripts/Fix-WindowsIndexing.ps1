# Fix-WindowsIndexing.ps1
#
# Ce script aide à diagnostiquer et résoudre les problèmes courants liés
# à l'indexation de Windows (Windows Search).
# Nécessite des privilèges administrateur.

param(
    [switch]$AutoRun # Permet d'exécuter directement la réinitialisation si le script est appelé avec -AutoRun
)

# --- MODIFIED: Added signature to the header function ---
function Show-ScriptHeader {
    param([string]$Title)
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "    $Title" -ForegroundColor Cyan
    Write-Host "              By DemonDeV-tech                      " -ForegroundColor DarkCyan
    Write-Host "====================================================" -ForegroundColor Cyan

}
# --- END MODIFIED ---

Show-ScriptHeader -Title "Résolution des problèmes d'indexation Windows"

Write-Host "Ce script va vous aider à gérer le service d'indexation de Windows (Windows Search)." -ForegroundColor White
Write-Host "Assurez-vous d'exécuter PowerShell en tant qu'administrateur." -ForegroundColor Yellow
Write-Host ""

$ContinueScript = $true

do {
    Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
    Write-Host "Options de diagnostic et réparation de l'indexation :" -ForegroundColor White
    Write-Host "1. Vérifier le statut du service Windows Search" -ForegroundColor Green
    Write-Host "2. Redémarrer le service Windows Search" -ForegroundColor Green
    Write-Host "3. Lancer l'outil de dépannage Windows Search" -ForegroundColor Green
    Write-Host "4. Reconstruire l'index de recherche (avancé, peut prendre du temps)" -ForegroundColor Red
    Write-Host "5. Activer le service Windows Search (Automatique) " -ForegroundColor Green
    Write-Host "0. Retour au menu précédent" -ForegroundColor Red
    Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow

    $choice = Read-Host "Entrez votre choix"

    switch ($choice) {
        "1" { # Check Service Status
            Clear-Host
            Write-Host "`n--- Statut du service Windows Search ---" -ForegroundColor Yellow
            try {
                $service = Get-Service -Name "WSearch" -ErrorAction Stop
                Write-Host "Service 'Windows Search' (Nom: WSearch):" -ForegroundColor White
                Write-Host "  Statut: $($service.Status)" -ForegroundColor Cyan
                Write-Host "  Démarrage: $($service.StartType)" -ForegroundColor Cyan
                if ($service.Status -ne "Running") {
                    Write-Warning "Le service Windows Search n'est pas en cours d'exécution ou est désactivé. Les recherches peuvent être lentes ou ne pas fonctionner."
                    if ($service.StartType -eq "Disabled") {
                        Write-Host "Considérez l'Option 5 pour l'activer." -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "Le service Windows Search est en cours d'exécution." -ForegroundColor Green
                }
            } catch {
                Write-Error "Erreur: Impossible de récupérer le statut du service Windows Search. $($_.Exception.Message)"
                Write-Warning "Le service pourrait être désactivé, corrompu, ou PowerShell n'a pas les permissions suffisantes."
            }
            Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "2" { # Restart Service
            Clear-Host
            Write-Host "`n--- Redémarrage du service Windows Search ---" -ForegroundColor Yellow
            Write-Host "Cela peut résoudre les blocages temporaires de l'indexation." -ForegroundColor White
            Write-Warning "Les recherches peuvent être temporairement indisponibles pendant le redémarrage du service. Continuer ? (O/N)"
            $confirm = Read-Host
            if ($confirm -eq "O" -or $confirm -eq "o") {
                try {
                    $service = Get-Service -Name "WSearch" -ErrorAction Stop
                    if ($service.StartType -eq "Disabled") {
                        Write-Warning "Le service est actuellement DÉSACTIVÉ. Il ne peut pas être redémarré directement."
                        Write-Host "Considérez d'abord l'Option 5 pour le définir sur 'Automatique'." -ForegroundColor Yellow
                    } else {
                        Write-Host "Arrêt du service 'Windows Search'..." -ForegroundColor Yellow
                        Restart-Service -InputObject $service -Force -ErrorAction Stop # Use -Force for dependent services
                        Write-Host "Service 'Windows Search' redémarré avec succès." -ForegroundColor Green
                    }
                } catch {
                    Write-Error "Erreur lors du redémarrage du service Windows Search: $($_.Exception.Message)"
                    Write-Warning "Vérifiez que PowerShell est exécuté en tant qu'administrateur et que le service existe."
                }
            } else {
                Write-Host "Opération annulée." -ForegroundColor Yellow
            }
            Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "3" { # Launch Troubleshooter
            Clear-Host
            Write-Host "`n--- Lancement de l'outil de dépannage Windows Search ---" -ForegroundColor Yellow
            Write-Host "Ceci va ouvrir l'utilitaire de résolution des problèmes intégré de Windows pour la recherche." -ForegroundColor White
            Write-Host "Suivez les instructions à l'écran dans la fenêtre qui va apparaître." -ForegroundColor Cyan
            try {
                # This command opens the troubleshooter UI for search and indexing issues
                Start-Process -FilePath "msdt.exe" -ArgumentList "-id SearchDiagnostic" -Wait -NoNewWindow -ErrorAction Stop
                Write-Host "`nOutil de dépannage lancé. Suivez les instructions à l'écran." -ForegroundColor Green
            } catch {
                Write-Error "Erreur lors du lancement de l'outil de dépannage: $($_.Exception.Message)"
                Write-Warning "L'outil de dépannage n'a pas pu être lancé."
            }
            Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "4" { # Rebuild Index
            Clear-Host
            Write-Host "`n--- Reconstruire l'index de recherche ---" -ForegroundColor Yellow
            Write-Warning "ATTENTION: Cette opération est invasive et peut prendre BEAUCOUP DE TEMPS (plusieurs heures) selon la taille de votre disque et le nombre de fichiers."
            Write-Warning "Les résultats de recherche peuvent être incomplets jusqu'à ce que la reconstruction soit terminée."
            Write-Host "Ceci supprime et recrée la base de données d'indexation." -ForegroundColor Red
            Write-Host "CONFIRMATION REQUISE: Pour confirmer la reconstruction, tapez 'RECONSTRUIRE' (en majuscules) et appuyez sur Entrée. Toute autre entrée annulera l'opération."
            $confirm = Read-Host

            if ($confirm -eq "RECONSTRUIRE") {
                try {
                    Write-Host "Arrêt du service Windows Search..." -ForegroundColor Yellow
                    Stop-Service -Name "WSearch" -Force -ErrorAction Stop

                    Write-Host "Suppression de la base de données d'indexation..." -ForegroundColor White
                    # Default location of the search index database
                    $indexPath = "$env:ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb"
                    if (Test-Path $indexPath) {
                        Remove-Item $indexPath -Force -ErrorAction SilentlyContinue
                        Write-Host "Base de données d'indexation supprimée." -ForegroundColor Green
                    } else {
                        Write-Warning "Base de données d'indexation non trouvée à l'emplacement par défaut ou déjà supprimée."
                    }

                    Write-Host "Redémarrage du service Windows Search pour reconstruire l'index..." -ForegroundColor Yellow
                    Start-Service -Name "WSearch" -ErrorAction Stop
                    Write-Host "Service Windows Search redémarré. La reconstruction de l'index a commencé en arrière-plan." -ForegroundColor Green
                    Write-Host "`nLe processus de reconstruction peut prendre du temps. Vous pouvez vérifier l'état dans les Options d'indexation du Panneau de configuration." -ForegroundColor DarkGray
                } catch {
                    Write-Error "Erreur lors de la reconstruction de l'index: $($_.Exception.Message)"
                    Write-Warning "Assurez-vous que PowerShell est exécuté en tant qu'administrateur."
                }
            } else {
                Write-Host "Opération annulée." -ForegroundColor Yellow
            }
            Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "5" { # NEW OPTION: Enable Windows Search Service (Set to Automatic and Start)
            Clear-Host
            Write-Host "`n--- Activer le service Windows Search (Automatique) ---" -ForegroundColor Yellow
            Write-Host "Cette option définit le service Windows Search sur 'Automatique' et tente de le démarrer." -ForegroundColor White
            Write-Host "Ceci est recommandé si vos recherches Windows sont lentes et que le service est désactivé." -ForegroundColor Green
            Write-Warning "Cette opération va modifier le type de démarrage du service. Continuer ? (O/N)"
            $confirm = Read-Host

            if ($confirm -eq "O" -or $confirm -eq "o") {
                try {
                    $service = Get-Service -Name "WSearch" -ErrorAction Stop
                    Write-Host "Statut actuel: $($service.Status) (Démarrage: $($service.StartType))" -ForegroundColor Cyan

                    if ($service.StartType -ne "Automatic") {
                        Write-Host "Définition du type de démarrage sur 'Automatique'..." -ForegroundColor Yellow
                        Set-Service -Name "WSearch" -StartupType Automatic -ErrorAction Stop
                        Write-Host "Type de démarrage défini sur 'Automatique' avec succès." -ForegroundColor Green
                        $service = Get-Service -Name "WSearch" # Refresh service object
                    } else {
                        Write-Host "Le service est déjà en mode 'Automatique'." -ForegroundColor DarkGray
                    }

                    if ($service.Status -ne "Running") {
                        Write-Host "Tentative de démarrage du service Windows Search..." -ForegroundColor Yellow
                        Start-Service -Name "WSearch" -ErrorAction Stop
                        Write-Host "Service Windows Search démarré avec succès." -ForegroundColor Green
                    } else {
                        Write-Host "Le service Windows Search est déjà en cours d'exécution." -ForegroundColor DarkGray
                    }
                    Write-Host "`nLe service Windows Search est maintenant activé et démarré (si ce n'était pas le cas)." -ForegroundColor Green
                } catch {
                    Write-Error "Erreur lors de l'activation du service Windows Search: $($_.Exception.Message)"
                    Write-Warning "Assurez-vous que PowerShell est exécuté en tant qu'administrateur."
                }
            } else {
                Write-Host "Opération annulée." -ForegroundColor Yellow
            }
            Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "0" {
            Write-Host "`nRetour au menu précédent..." -ForegroundColor White
            $ContinueScript = $false
        }
        default {
            Write-Warning "Choix invalide. Veuillez entrer un numéro entre 0 et 5."
            Start-Sleep -Seconds 1
        }
    }
} while ($ContinueScript)

Write-Host "`nScript de résolution des problèmes d'indexation terminé." -ForegroundColor Green
Start-Sleep -Seconds 1