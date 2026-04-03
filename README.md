# MSSQL Klasör Yedekleme Scripti

- MSSQL tabanlı uygulamalar için servis kontrollü ve otomatik yedekleme işlemi yapar.
- ZIP sıkıştırma işlemi yapar
- Ağ paylaşım alanına kopyalama işlemi yapar
- Detaylı loglama özelliklerini içerir.
- Bunların hepsini tek bir dosya ile sağlar.



## 🚀 Özellikler

- SQL ve uygulama servislerini durdurarak güvenli yedek alma yapar.
- robocopy ile hızlı ve güvenilir kopyalama yapar.
- Yedekleri .zip formatında sıkıştırma yapar.
- Paylaşım alanına otomatik kopyalama yapar.
- Tek log dosyası ve ayrı hata log dosyası tutar.
- Görev Zamanlayıcısı ile kullanılabilir.


## ⚙️ Nasıl Çalışır?

1. Öncelikle SQL servisini durdurur.
2. Eğer varsa uygulama servislerini durdurur.
3. Yedek klasörünü belirlediğiniz yere oluşturur.
4. Verileri belirlediğiniz yere kopyalar.
5. Durdurulan SQL ve uygulama servislerini tekrar başlatır  
6. Kopyalanan SQL klasörünü ZIP ile sıkıştırır. 
7. Ağ üzerinde paylaşım alanına kopyalar.
8. Geçici alınan yedek klasörünü temizler.  
9. Yapılan bütün işlemlerin log kayıtlarını oluşturur.


## 📁 Yapılandırma

Sadece scriptte yer alan aşağıdaki değişkenleri düzenlemeniz yeterlidir:

```bat

SQL_KLASORU_KAYNAK=C:\zirvenet\zirvedata
YEDEK_KLASORU=E:\Zirve_Yedekleri

SQLSERVISI=MSSQL$ZRV2019EXP
APPSERVISI1=srvczirvesunucu_srv_zirve_zrv2019exp
APPSERVISI2=zirve_sunucusu

NASPAYLASIM=\\10.10.10.11\Backup
NASALTKLASOR=Zirve
SURUCU=Z:
KULLADI=backup
KULLADI_PASS=12345678

```

---

## 📦 Çıktılar

Backup_YYYYMMDD_HHMM.zip  
BackupLog.txt  
BackupLog_Error.txt  


Task Scheduler ile çalıştırılmasını sağlayabilirsiniz.

- Aktif olmayan bir saatte (gece vakti) çalıştırılması önerilir. 
- Yüksek Ayrıcalıklarla çalışması gerekir.
- System hesabı ile çalıştırın.


## ⚠️ Notlar

- Script Administrator olarak çalıştırılmalıdır
- Paylaşım alanına yedeğin sadece zip dosyası kopyalanır.
- Paylaşım bağlantısı Z sürücüsü olarak geçici olarak oluşturulur. Yedeğin kopyalaması bittiğinde bağlantıyı kapatır.
- Robocopy dönüş kodları:
- 0–7 → başarılı
- 8+ → hata
- SQL servisi durdurulamazsa yedekleme iptal edilir

## 🛠️ Sorun Giderme

❌ ZIP oluşmuyor
- Disk dolu olabilir
- Yetki problemi olabilir

❌ Paylaşım alanına kopyalama hatası alırsanız aşağıdaki durumları kontrol ediniz.
- Kullanıcı adı / şifre yanlış olabilir
- Share yolu hatalı olabilir
- Firewall engelliyor olabilir

Paylaşım alanını erişim testi için aşağıdaki kod parçasını CMD ile çalıştırıp test edebilirsiniz.

```cmd
net use Z: \\192.168.1.100\Backup /user:username password
dir Z:
dir Z:\ProjectName
net use Z: /delete /y
```

## ✍️ Geliştirici

Ahmet Başköylü  
2026
