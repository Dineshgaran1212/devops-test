# Add target.example.com to hosts file
# Must be run as Administrator

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$entry = "127.0.0.1 target.example.com"

# Check if entry already exists
$content = Get-Content $hostsPath
if ($content -contains $entry) {
    Write-Host "✅ Entry already exists in hosts file"
} else {
    Add-Content -Path $hostsPath -Value "`n$entry"
    Write-Host "✅ Added 'target.example.com' to hosts file"
}

Write-Host ""
Write-Host "Hosts file entry:"
Get-Content $hostsPath | Select-String "target.example.com"
