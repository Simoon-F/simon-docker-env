# =============================================
# switch-version.ps1 - PHP/MySQL Version Switcher (Windows)
#
# PHP: Dynamically managed containers, instant switching
#   Add new version:  .\switch-version.ps1 php 8.5.0   (auto-build)
#   Switch version:   .\switch-version.ps1 php 8.4.1   (instant)
#   View status:      .\switch-version.ps1 php
#
# MySQL: Update .env + rebuild
# =============================================

param (
    [string]$type,
    [string]$version
)

$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$NginxConfDir = Join-Path $ProjectDir "nginx\conf.d"
$ImageName = "simon-php"
$Network = "simon-docker-env_simon_network"

# Load .env
$envFile = Join-Path $ProjectDir ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
            [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), "Process")
        }
    }
}

function Show-Status {
    Write-Host "=== PHP Version Status ==="
    Write-Host ""

    # Read current active version from nginx config
    $defaultConf = Join-Path $NginxConfDir "default.conf"
    if (Test-Path $defaultConf) {
        $match = Select-String -Path $defaultConf -Pattern 'set \$php_upstream (simon_php[\d]+:\d+)' | Select-Object -First 1
        if ($match) {
            $active = $match.Matches[0].Groups[1].Value
            $ver = $active -replace 'simon_php', '' -replace ':.*', '' -replace '(\d)', '$1.'
            Write-Host "Active: PHP $ver"
        } else {
            Write-Host "Active: none"
        }
    }

    Write-Host ""
    Write-Host "Installed versions:"

    $images = docker images --format '{{.Tag}}' $ImageName 2>$null
    if ($images) {
        $images | Sort-Object { [version]$_ } | ForEach-Object {
            $tag = $_
            $container = "simon_php$($tag -replace '\.', '')"
            $status = docker inspect -f '{{.State.Running}}' $container 2>$null
            if ($status -eq "true") {
                Write-Host "  $tag  [running]"
            } else {
                Write-Host "  $tag  [stopped]"
            }
        }
    } else {
        Write-Host "  (none - run: .\switch-version.ps1 php <version>)"
    }
}

function Build-PhpImage {
    param([string]$Version)

    $imageTag = "${ImageName}:${Version}"
    Write-Host "Building PHP $Version image (one-time)..."

    $useChinaMirror = if ($env:USE_CHINA_MIRROR) { $env:USE_CHINA_MIRROR } else { "false" }
    $useFfmpeg = if ($env:USE_FFMPEG) { $env:USE_FFMPEG } else { "false" }

    docker build `
        --build-arg "PHP_VERSION=$Version" `
        --build-arg "USE_CHINA_MIRROR=$useChinaMirror" `
        --build-arg "USE_FFMPEG=$useFfmpeg" `
        -t $imageTag `
        -f (Join-Path $ProjectDir "php\Dockerfile") `
        (Join-Path $ProjectDir "php")

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed!" -ForegroundColor Red
        exit 1
    }

    Write-Host "Image $imageTag built successfully" -ForegroundColor Green
}

function Start-PhpContainer {
    param([string]$Version)

    $versionCompact = $Version -replace '\.', ''
    $container = "simon_php$versionCompact"
    $imageTag = "${ImageName}:${Version}"

    # Check if already running
    $running = docker inspect -f '{{.State.Running}}' $container 2>$null
    if ($running -eq "true") {
        Write-Host "Container $container is already running" -ForegroundColor Green
        return
    }

    # Remove stopped container
    docker rm -f $container 2>$null | Out-Null

    Write-Host "Starting PHP $Version container..."
    $wwwroot = Join-Path $ProjectDir "..\wwwroot"
    $customIni = Join-Path $ProjectDir "php\custom.ini"

    docker run -d `
        --name $container `
        --network $Network `
        --restart unless-stopped `
        -v "${wwwroot}:/var/www/html" `
        -v "${customIni}:/usr/local/etc/php/conf.d/custom.ini" `
        -e "PHP_VERSION=$Version" `
        -e "REDIS_HOST=simon_redis" `
        -e "REDIS_PORT=6379" `
        $imageTag

    Write-Host "Container $container started" -ForegroundColor Green
}

function Update-Nginx {
    param([string]$Version)

    $versionCompact = $Version -replace '\.', ''
    $container = "simon_php$versionCompact"

    # Update all nginx configs
    Get-ChildItem -Path $NginxConfDir -Filter "*.conf" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -match 'set \$php_upstream') {
            $content = $content -replace 'set \$php_upstream [^;]+;', "set `$php_upstream ${container}:9000;"
            Set-Content -Path $_.FullName -Value $content
        }
    }

    # Reload nginx
    docker exec simon_nginx nginx -s reload 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Nginx reloaded" -ForegroundColor Green
    } else {
        Write-Host "Nginx not running yet (will use new config on start)" -ForegroundColor Yellow
    }
}

function Stop-OldPhp {
    param([string]$NewVersion)

    $newCompact = $NewVersion -replace '\.', ''
    docker ps --format '{{.Names}}' 2>$null | Where-Object { $_ -match '^simon_php' } | ForEach-Object {
        if ($_ -ne "simon_php$newCompact") {
            Write-Host "Stopping old container: $_"
            docker stop $_ 2>$null | Out-Null
        }
    }
}

# ========== Main ==========

if (-not $type) {
    Show-Status
    exit 0
}

if ($type -eq "php") {
    if (-not $version) {
        Show-Status
        exit 0
    }

    # Check if image exists, build if not
    $exists = docker image inspect "${ImageName}:${version}" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Build-PhpImage $version
    }

    # Start container
    Start-PhpContainer $version

    # Update nginx
    Update-Nginx $version

    # Stop old containers
    Stop-OldPhp $version

    Write-Host ""
    Write-Host "Switched to PHP $version" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verify:  docker exec simon_php$($version -replace '\.', '') php -v"

} elseif ($type -eq "mysql") {
    if (-not $version) {
        Write-Host "Usage: .\switch-version.ps1 mysql <version>"
        exit 1
    }

    # Update .env
    (Get-Content $envFile) -replace 'MYSQL_VERSION=.*', "MYSQL_VERSION=${version}" | Set-Content $envFile
    Write-Host "Switched MySQL to version $version"

    docker compose down
    docker compose build --no-cache mysql
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed!" -ForegroundColor Red
        exit 1
    }
    docker compose up -d
    Write-Host "MySQL switched to $version" -ForegroundColor Green

} else {
    Write-Host "Usage:"
    Write-Host "  .\switch-version.ps1 php [version]    Switch/view PHP version"
    Write-Host "  .\switch-version.ps1 mysql <version>  Switch MySQL version"
    exit 1
}
