#!/usr/bin/env pwsh
# ==============================================================================
# update_gallery.ps1
# Quick script to update GitHub Pages gallery after running pipeline
# ==============================================================================

Write-Host "`n=== Updating Gallery for GitHub Pages ===" -ForegroundColor Cyan

# Step 1: Copy plot_gallery.html to index.html
Write-Host "`n[1/4] Copying plot_gallery.html to index.html..." -ForegroundColor Yellow
Copy-Item "results\reports\plot_gallery.html" "index.html" -Force
Write-Host "      ✓ index.html updated" -ForegroundColor Green

# Step 2: Stage all changes (HTML reports + plot PNGs)
Write-Host "`n[2/4] Staging files for commit..." -ForegroundColor Yellow
git add index.html
git add results/reports/*.html
git add results/plots/ridgeline/variants/*.png
git add .gitignore
Write-Host "      ✓ Files staged" -ForegroundColor Green

# Step 3: Show what's staged
Write-Host "`n[3/4] Files ready to commit:" -ForegroundColor Yellow
git status --short

# Step 4: Commit and push
Write-Host "`n[4/4] Committing and pushing to GitHub..." -ForegroundColor Yellow
$date = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "Update gallery and plots - $date"
git push

Write-Host "`n=== Done! ===" -ForegroundColor Green
Write-Host "Your gallery will be live at:" -ForegroundColor Cyan
Write-Host "https://sacoleman18-cloud.github.io/COHA_Dispersal/" -ForegroundColor White
Write-Host "(May take 1-2 minutes to deploy)`n" -ForegroundColor Gray
