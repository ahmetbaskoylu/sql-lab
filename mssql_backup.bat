@echo off
chcp 1254 >nul
setlocal EnableDelayedExpansion

REM ============================
REM AHMET BAŞKÖYLÜ - 2026
REM MSSQL Backup Alma + ZIP Sıkıştırma + Paylaşım Z Sürücüsüne Kopyalama + Backup Log Tutma + Ayrı Error Log Tutma
REM SADECE DEĞİŞKEN ARALIĞINI DEĞİŞTİRİN, DEĞİŞKEN ADINA VE DİĞER KODLARA DOKUNMAYIN.
REM ÜCRETSİZ OLARAK DAĞITILMIŞTIR.
REM ============================

REM ----------------------------
REM DEĞİŞKEN BAŞLANGICI

set "SQL_KLASORU_KAYNAK=C:\zirvenet\zirvedata"
set "YEDEK_KLASORU=E:\Zirve_Yedekleri"

set "LOGDOSYASI=%YEDEK_KLASORU%\BackupLog.txt"
set "HATALOGDOSYASI=%YEDEK_KLASORU%\BackupLog_Error.txt"

set "SQLSERVISI=MSSQL$ZRV2019EXP"
set "APPSERVISI1=srvczirvesunucu_srv_zirve_zrv2019exp"
set "APPSERVISI2=zirve_sunucusu"



set "NASPAYLASIM=\\10.10.10.11\Backup"
set "NASALTKLASOR=Zirve"
set "SURUCU=Z:"
set "KULLADI=backup"
set "KULLADI_PASS=12345678"

REM DEĞİŞKEN SONU
REM ---------------------------

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value ^| find "="') do set "datetime=%%I"
set "datepart=%datetime:~0,8%"
set "timepart=%datetime:~8,4%"
set "FOLDERNAME=%datepart%_%timepart%"

set "BACKUPFOLDER=%YEDEK_KLASORU%\Backup_%FOLDERNAME%"
set "ZIPFILE=%YEDEK_KLASORU%\Backup_%FOLDERNAME%.zip"
set "NASZIP=%SURUCU%\%NASALTKLASOR%\Backup_%FOLDERNAME%.zip"

if not exist "%YEDEK_KLASORU%" mkdir "%YEDEK_KLASORU%"

call :Log "============================================================"
call :Log "YEDEKLEME BASLADI"
call :Log "Kaynak klasor      : %SQL_KLASORU_KAYNAK%"
call :Log "Lokal backup root  : %YEDEK_KLASORU%"
call :Log "Yedek klasoru      : %BACKUPFOLDER%"
call :Log "Zip dosyasi        : %ZIPFILE%"
call :Log "NAS share          : %NASPAYLASIM%"
call :Log "NAS alt klasor     : %NASALTKLASOR%"
call :Log "NAS surucu         : %SURUCU%"

REM ---------------------------
REM SERVISLERI DURDUR
REM ---------------------------

call :Log "SQL servisi durduruluyor..."
net stop "%SQLSERVISI%" >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
if errorlevel 1 (
    call :LogError "SQL servisi durdurulamadi! Backup iptal edildi."
    goto END
) else (
    call :Log "SQL servisi durduruldu."
)

call :Log "APP1 servisi durduruluyor..."
net stop "%APPSERVISI1%" >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
if errorlevel 1 (
    call :LogError "APP1 servisi durdurulamadi! Backup devam edecek."
) else (
    call :Log "APP1 servisi durduruldu."
)

call :Log "APP2 servisi durduruluyor..."
net stop "%APPSERVISI2%" >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
if errorlevel 1 (
    call :LogError "APP2 servisi durdurulamadi! Backup devam edecek."
) else (
    call :Log "APP2 servisi durduruldu."
)

REM ---------------------------
REM YEDEK KLASORUNU OLUSTUR
REM ---------------------------
call :Log "Yedek klasoru olusturuluyor..."
mkdir "%BACKUPFOLDER%" >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
if errorlevel 1 (
    call :LogError "Yedek klasoru olusturulamadi!"
    goto STARTSERVICES
) else (
    call :Log "Yedek klasoru olusturuldu."
)

REM ---------------------------
REM KOPYALAMA
REM ---------------------------
call :Log "Kopyalama basladi..."
robocopy "%SQL_KLASORU_KAYNAK%" "%BACKUPFOLDER%" /E /COPY:DAT /R:2 /W:2 /NP /LOG+:"%LOGDOSYASI%"
set "RC=%ERRORLEVEL%"

if %RC% GEQ 8 (
    call :LogError "Robocopy hata verdi! Kod=%RC%"
    goto STARTSERVICES
) else (
    call :Log "Kopyalama tamamlandi. Robocopy Kod=%RC%"
)

REM ---------------------------
REM SERVISLERI BASLAT
REM ---------------------------
:STARTSERVICES
call :Log "SQL servisi baslatiliyor..."
net start "%SQLSERVISI%" >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
if errorlevel 1 (
    call :LogError "SQL servisi baslatilamadi!"
) else (
    call :Log "SQL servisi baslatildi."
)

call :Log "APP1 servisi baslatiliyor..."
net start "%APPSERVISI1%" >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
if errorlevel 1 (
    call :LogError "APP1 servisi baslatilamadi!"
) else (
    call :Log "APP1 servisi baslatildi."
)

call :Log "APP2 servisi baslatiliyor..."
net start "%APPSERVISI2%" >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
if errorlevel 1 (
    call :LogError "APP2 servisi baslatilamadi!"
) else (
    call :Log "APP2 servisi baslatildi."
)

if not exist "%BACKUPFOLDER%" (
    call :LogError "Backup klasoru bulunamadi, ZIP islemi iptal edildi!"
    goto END
)

REM ---------------------------
REM ZIP OLUSTUR
REM ---------------------------
call :Log "Zip sikistirma baslatiliyor..."
powershell -NoProfile -Command ^
"try { Compress-Archive -Path '%BACKUPFOLDER%\*' -YEDEK_KLASORUPath '%ZIPFILE%' -Force; exit 0 } catch { exit 1 }" >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"

if errorlevel 1 (
    call :LogError "ZIP olusturma hatasi!"
    goto END
)

if not exist "%ZIPFILE%" (
    call :LogError "ZIP dosyasi olusmadi!"
    goto END
) else (
    call :Log "ZIP basariyla olustu."
)

REM ---------------------------
REM NAS SURUCUSUNU BAGLA
REM ---------------------------
call :Log "Eski %SURUCU% baglantisi varsa kaldiriliyor..."
net use %SURUCU% /delete /y >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"

call :Log "NAS surucusu baglaniyor: %SURUCU% -> %NASPAYLASIM%"
net use %SURUCU% "%NASPAYLASIM%" /user:"%KULLADI%" "%KULLADI_PASS%" /persistent:no >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
if errorlevel 1 (
    call :LogError "NAS surucusu baglanamadi! %SURUCU% -> %NASPAYLASIM%"
    goto END
) else (
    call :Log "NAS surucusu basariyla baglandi."
)

if not exist "%SURUCU%\" (
    call :LogError "NAS surucusu gorunmuyor: %SURUCU%"
    goto DISCONNECTNAS
)

REM ---------------------------
REM NAS HEDEF KLASOR
REM ---------------------------
if not exist "%SURUCU%\%NASALTKLASOR%" (
    call :Log "NAS hedef klasoru olusturuluyor: %SURUCU%\%NASALTKLASOR%"
    mkdir "%SURUCU%\%NASALTKLASOR%" >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
    if errorlevel 1 (
        call :LogError "NAS hedef klasoru olusturulamadi!"
        goto DISCONNECTNAS
    ) else (
        call :Log "NAS hedef klasoru olusturuldu."
    )
) else (
    call :Log "NAS hedef klasoru zaten mevcut."
)

REM ---------------------------
REM ZIP DOSYASINI NAS'A KOPYALA
REM ---------------------------
call :Log "ZIP dosyasi NAS cihazina kopyalaniyor..."
copy /Y "%ZIPFILE%" "%SURUCU%\%NASALTKLASOR%\" >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
if errorlevel 1 (
    call :LogError "NAS kopyalama hatasi!"
    goto DISCONNECTNAS
)

if not exist "%NASZIP%" (
    call :LogError "NAS uzerinde ZIP dosyasi gorunmuyor: %NASZIP%"
    goto DISCONNECTNAS
) else (
    call :Log "ZIP dosyasi NAS cihazina basariyla kopyalandi."
)

:DISCONNECTNAS
call :Log "NAS surucusu kaldiriliyor: %SURUCU%"
net use %SURUCU% /delete /y >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
if errorlevel 1 (
    call :LogError "NAS surucusu kaldirilamadi: %SURUCU%"
) else (
    call :Log "NAS surucusu kaldirildi."
)

REM ---------------------------
REM GECICI YEDEK KLASORUNU SIL
REM ---------------------------
if exist "%BACKUPFOLDER%" (
    call :Log "Gecici backup klasoru siliniyor..."
    rmdir /S /Q "%BACKUPFOLDER%" >> "%LOGDOSYASI%" 2>> "%HATALOGDOSYASI%"
    if errorlevel 1 (
        call :LogError "Gecici backup klasoru silinemedi!"
    ) else (
        call :Log "Gecici backup klasoru silindi."
    )
)

:END
call :Log "YEDEKLEME TAMAMLANDI"
call :Log "============================================================"
exit /b

:Log
echo [%date% %time%] INFO  - %~1
>> "%LOGDOSYASI%" echo [%date% %time%] INFO  - %~1
exit /b

:LogError
echo [%date% %time%] ERROR - %~1
>> "%LOGDOSYASI%" echo [%date% %time%] ERROR - %~1
>> "%HATALOGDOSYASI%" echo [%date% %time%] ERROR - %~1
exit /b