param (
    [string]$type,
    [string]$version
)

if (-not $type -or -not $version) {
    Write-Host "Usage: .\switch-version.ps1 <php|mysql> <version>"
    exit 1
}

if ($type -eq "php") {
    # 更新 PHP 版本
    (Get-Content .env) -replace 'PHP_VERSION=.*', "PHP_VERSION=${version}" | Set-Content .env
    Write-Host "Switched PHP to version ${version}"
} elseif ($type -eq "mysql") {
    # 更新 MySQL 版本
    (Get-Content .env) -replace 'MYSQL_VERSION=.*', "MYSQL_VERSION=${version}" | Set-Content .env
    Write-Host "Switched MySQL to version ${version}"
} else {
    Write-Host "Invalid type. Use 'php' or 'mysql'."
    exit 1
}

# 重启容器
docker compose down
docker compose build php
docker compose up -d