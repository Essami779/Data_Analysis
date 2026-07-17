@echo off
title SASP Laravel Backend Server
echo [SASP] Starting Laravel Backend Server on 0.0.0.0...
cd SASP_Dashbord_API
php artisan serve --host=0.0.0.0
pause
