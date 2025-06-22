# 🔧 YouTubeAI Sorun Giderme Kılavuzu

## 🚨 Kritik Sorunlar ve Çözümleri

### 1. **ChromeDriver "user-data-dir already in use" Hatası**

**Sorun Açıklaması**:
Chrome WebDriver, aynı user-data-dir'i kullanan başka bir Chrome instance'ı tespit ettiğinde bu hatayı verir.

**Belirtiler**:
```
Message: session not created: probably user data directory is already in use, 
please specify a unique value for --user-data-dir argument, or don't use --user-data-dir
```

**Çözüm Adımları**:
```bash
# 1. Otomatik çözüm
./project_manager.sh clean

# 2. Manuel çözüm
pkill -f chrome
pkill -f chromedriver
rm -rf /tmp/chrome_profile_*

# 3. Sistem kontrolü
ps aux | grep chrome
lsof -i | grep chrome
```

**Önleme Stratejileri**:
- Her job çalıştırması için benzersiz profil dizini kullanımı
- Otomatik cleanup mekanizması
- Process monitoring ve automatic termination

---

### 2. **Port 8080 Çakışması**

**Sorun Açıklaması**:
Spring Boot uygulaması başlatılırken port 8080'in zaten kullanımda olması.

**Belirtiler**:
```
Web server failed to start. Port 8080 was already in use.
```

**Çözüm Adımları**:
```bash
# 1. Port kullanan process'i bul
lsof -i:8080

# 2. Process'i sonlandır
lsof -ti:8080 | xargs kill -9

# 3. Uygulamayı yeniden başlat
./project_manager.sh start
```

**Önleme Stratejileri**:
- Uygulama kapatılırken graceful shutdown
- Startup öncesi port kontrolü
- Alternative port configuration

---

### 3. **OpenAI API "null" Tweet Sorunu**

**Sorun Açıklaması**:
OpenAI API'den gelen yanıt doğru işlenemiyor ve tweet içeriği "null" oluyor.

**Belirtiler**:
```
📝 Tweet mesajı: null
Tweet uzunluğu: 4 karakter
```

**Root Cause Analysis**:
1. **PATH Environment Corruption**: `tr`, `dirname`, `jq` komutları bulunamıyor
2. **OpenAI API Key Loading**: Environment'dan key yüklenemiyor
3. **JSON Parsing Issues**: API yanıtı doğru parse edilemiyor

**Çözüm Adımları**:
```bash
# 1. Config kontrolü
./project_manager.sh test config

# 2. Manuel API test
cd sh_scripts
./generate_tweet_advanced.sh lofi

# 3. Environment fix
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH"
source channels.env
```

**Uygulanan Çözümler**:
- `generate_tweet_advanced.sh`'de explicit PATH setting
- Hardcoded fallback API key (geçici)
- Improved JSON parsing with error handling
- Video title quote removal

---

### 4. **Twitter Login Selenium Hataları**

**Sorun Açıklaması**:
Selenium, Twitter login sayfasındaki elementleri bulamıyor.

**Belirtiler**:
```
❌ Email alanı bulunamadı
❌ Şifre alanı bulunamadı
Element not found exceptions
```

**Çözüm Stratejileri**:
1. **Multiple Selector Strategy**:
```python
# Email selectors
selectors = [
    'input[autocomplete="username"]',
    'input[name="text"]',
    'input[type="email"]'
]
```

2. **Retry Mechanism**:
```python
for attempt in range(3):
    try:
        element = driver.find_element(By.CSS_SELECTOR, selector)
        break
    except NoSuchElementException:
        time.sleep(2)
```

3. **Dynamic Wait Strategy**:
```python
wait = WebDriverWait(driver, 10)
element = wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, selector)))
```

---

### 5. **Spring Boot Application Context Failure**

**Sorun Açıklaması**:
Spring Boot uygulaması başlatılırken context initialization hatası.

**Belirtiler**:
```
ApplicationContextException: Failed to start bean 'webServerStartStop'
```

**Çözüm Adımları**:
```bash
# 1. Clean build
./gradlew clean

# 2. Dependency refresh
./gradlew build --refresh-dependencies

# 3. Configuration check
./project_manager.sh test config

# 4. Database reset
rm -rf build/
./gradlew bootRun
```

---

## 🔍 Tanı Araçları

### Sistem Durumu Kontrolleri
```bash
# Genel sistem durumu
./project_manager.sh status

# Chrome processes
ps aux | grep chrome | grep -v grep

# Port kullanımı
lsof -i:8080
netstat -tulpn | grep 8080

# Disk kullanımı
df -h /tmp
du -sh /tmp/chrome_profile_*

# Memory kullanımı
free -m
top -p $(pgrep java)
```

### Log Analizi
```bash
# Spring Boot logs
tail -f build/logs/spring.log

# Chrome driver logs
ls -la /tmp/chromedriver*

# System logs
dmesg | tail -20
```

### Network Diagnostics
```bash
# OpenAI API connectivity
curl -I https://api.openai.com/v1/chat/completions

# Twitter connectivity
curl -I https://x.com

# DNS resolution
nslookup api.openai.com
```

## 🛠️ Hızlı Çözüm Komutları

### Acil Durum Cleanup
```bash
#!/bin/bash
# Emergency cleanup script

echo "🚨 ACIL DURUM TEMİZLİĞİ"

# Kill all Chrome processes
pkill -f chrome
pkill -f chromedriver

# Clean temp files
rm -rf /tmp/chrome_profile_*
rm -rf /tmp/chromedriver*

# Free up port 8080
lsof -ti:8080 | xargs kill -9 2>/dev/null

# Clean Gradle cache
./gradlew clean

# Restart system services if needed
# sudo systemctl restart docker (if using Docker)

echo "✅ Acil temizlik tamamlandı"
```

### Health Check Script
```bash
#!/bin/bash
# System health check

echo "🏥 SİSTEM SAĞLIK KONTROLÜ"

# Check disk space
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "⚠️ Disk kullanımı yüksek: %$DISK_USAGE"
fi

# Check memory
MEM_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
if [ $MEM_USAGE -gt 90 ]; then
    echo "⚠️ Memory kullanımı yüksek: %$MEM_USAGE"
fi

# Check Chrome processes
CHROME_COUNT=$(ps aux | grep chrome | grep -v grep | wc -l)
if [ $CHROME_COUNT -gt 10 ]; then
    echo "⚠️ Çok fazla Chrome process: $CHROME_COUNT"
fi

# Check port 8080
if lsof -i:8080 > /dev/null; then
    echo "✅ Port 8080 kullanımda"
else
    echo "❌ Port 8080 boş"
fi

echo "🏥 Sağlık kontrolü tamamlandı"
```

## 📊 Performance Monitoring

### Key Metrics
- **Chrome Process Count**: Normal < 5, Kritik > 15
- **Memory Usage**: Normal < 70%, Kritik > 90%
- **Disk Usage**: Normal < 80%, Kritik > 95%
- **API Response Time**: Normal < 5s, Kritik > 30s

### Monitoring Commands
```bash
# Real-time monitoring
watch -n 5 './project_manager.sh status'

# Resource usage
htop
iotop
nethogs

# Application metrics
curl -s http://localhost:8080/actuator/health
curl -s http://localhost:8080/actuator/metrics
```

## 🔄 Maintenance Schedule

### Daily
- [ ] Chrome process cleanup
- [ ] Temp file cleanup
- [ ] Log rotation
- [ ] API health check

### Weekly
- [ ] Full system restart
- [ ] Database optimization
- [ ] Dependency updates
- [ ] Security patches

### Monthly
- [ ] Performance review
- [ ] Capacity planning
- [ ] Backup verification
- [ ] Documentation update

---

**Bu kılavuz, yaşanan sorunlar ve çözümleri temel alınarak oluşturulmuştur.**

**Son Güncelleme**: 21 Haziran 2025
**Versiyon**: 1.0.0 