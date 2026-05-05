@echo off
echo ============================================
echo  Stash + CommunityScrapers Setup
echo ============================================
echo.

echo [1/4] Installing Python dependencies for scrapers...
python -m pip install --upgrade pip
python -m pip install stashapp-tools requests cloudscraper beautifulsoup4 lxml
python -m pip install python-dateutil pillow

echo.
echo [2/4] Reloading Stash Docker container...
cd /d C:\stash
docker compose up -d

echo.
echo [3/4] Waiting for Stash to start...
timeout /t 10 /nobreak >nul

echo.
echo [4/4] Opening Stash in browser...
start http://localhost:9999

echo.
echo ============================================
echo  SETUP COMPLETE
echo  Stash:        http://localhost:9999
echo  Scrapers:     C:\stash\scrapers (967 files)
echo  Config:       C:\stash\config\config.yml
echo  Chrome CDP:   http://localhost:9222
echo.
echo  To start:     cd C:\stash ^&^& docker compose up -d
echo  To stop:      cd C:\stash ^&^& docker compose down
echo ============================================
pause
