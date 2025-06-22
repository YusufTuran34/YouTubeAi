# 🤖 AI Asistan İle Çalışma Kuralları

## 🎯 Genel Çalışma Prensipleri

### 1. **Proaktif Problem Çözme**
- AI asistan her zaman [proje yönetim sistemi][[memory:7891800506981905567]] kullanmalı
- Sorun tespit edildiğinde önce `./project_manager.sh status` çalıştır
- ChromeDriver çakışması durumunda otomatik `./project_manager.sh clean` uygula
- Port 8080 sorunlarında otomatik cleanup yap

### 2. **Standart Komut Sırası**
```bash
# Her problem çözümünde bu sırayı takip et:
1. ./project_manager.sh status      # Durum kontrol
2. ./project_manager.sh clean       # Gerekirse temizlik
3. ./project_manager.sh test config # Config doğrulama
4. ./project_manager.sh start       # Proje başlatma
```

### 3. **Hata Analizi Yaklaşımı**
- **ChromeDriver Hataları**: `user-data-dir already in use` → Otomatik cleanup
- **Port Çakışmaları**: `Port 8080 was already in use` → Process kill
- **OpenAI API Hataları**: Rate limiting → Retry mechanism
- **Twitter Login Sorunları**: Element bulunamama → Multiple selector

## 🔍 Sorun Giderme Protokolü

### Öncelik Sırası
1. **Sistem Temizliği**: Chrome processes, ports, temp files
2. **Config Doğrulama**: Environment variables, API keys
3. **Service Health Check**: Spring Boot, database, scripts
4. **Functional Testing**: Tweet generation, posting

### Hızlı Tanı Komutları
```bash
# Sistem durumu
./project_manager.sh status

# Hızlı testler
./project_manager.sh test config
./project_manager.sh test tweet
./project_manager.sh test horoscope
./project_manager.sh test lofi

# Manuel debug
cd sh_scripts && python3 post_to_twitter_simple.py horoscope aries
cd sh_scripts && ./generate_tweet_advanced.sh lofi
```

## 📋 AI Asistan Görevleri

### 1. **Otomatik Sistem Yönetimi**
- Process monitoring ve cleanup
- Port conflict resolution
- ChromeDriver session management
- Temporary file cleanup

### 2. **Code Quality Assurance**
- Configuration management
- Error handling standardization
- Performance optimization
- Security best practices

### 3. **Documentation Maintenance**
- Code comments güncelleme
- README dosyaları sync
- API documentation
- Troubleshooting guides

## 🚨 Kritik Hatalar ve Müdahaleler

### 1. **ChromeDriver Session Conflicts**
**Belirtiler**: 
- `user-data-dir already in use`
- Selenium timeout errors
- Chrome process accumulation

**Otomatik Müdahale**:
```bash
./project_manager.sh clean
# Eğer devam ederse:
pkill -f chrome
rm -rf /tmp/chrome_profile_*
```

### 2. **Spring Boot Port Conflicts**
**Belirtiler**:
- `Port 8080 was already in use`
- Application startup failure

**Otomatik Müdahale**:
```bash
lsof -ti:8080 | xargs kill -9
./project_manager.sh start
```

### 3. **OpenAI API Issues**
**Belirtiler**:
- "null" tweet content
- API rate limiting
- Authentication errors

**Otomatik Müdahale**:
- Config validation
- API key verification
- Retry mechanism activation

## 🔧 Geliştirme Süreçleri

### Code Changes Workflow
1. **Backup Creation**: Önemli dosyalar için backup
2. **Incremental Testing**: Her değişiklik sonrası test
3. **Rollback Strategy**: Hata durumunda geri alma
4. **Documentation Update**: Değişiklikleri dokümante etme

### Testing Strategy
```bash
# Her kod değişikliği sonrası:
./project_manager.sh test config    # Config integrity
./project_manager.sh test tweet     # Tweet generation
./project_manager.sh test horoscope # Horoscope functionality
./project_manager.sh test lofi      # LoFi functionality
```

### Configuration Management
- **Secrets**: Sadece `channels.env` dosyasında
- **Base Config**: `sh_scripts/configs/base.conf`
- **JSON Config**: `CHANNEL_CONFIGS` environment variable
- **Git Ignore**: Hassas dosyaları commit etme

## 📊 Monitoring ve Alerting

### System Health Indicators
- **Chrome Process Count**: `ps aux | grep chrome | wc -l`
- **Port Availability**: `lsof -i:8080`
- **Disk Space**: `/tmp` directory usage
- **API Response Time**: OpenAI API latency

### Performance Metrics
- **Tweet Generation Time**: < 10 seconds
- **Twitter Posting Time**: < 60 seconds  
- **System Cleanup Time**: < 5 seconds
- **Application Startup**: < 30 seconds

## 🎯 AI Asistan Özel Görevleri

### 1. **Proaktif İzleme**
- Log dosyalarını sürekli analiz et
- Pattern recognition ile sorunları önceden tespit et
- Resource usage monitoring
- Performance degradation detection

### 2. **Otomatik Optimizasyon**
- Chrome driver session optimization
- Memory usage optimization
- API call efficiency improvements
- Error recovery automation

### 3. **Intelligent Troubleshooting**
- Error pattern analysis
- Root cause identification
- Solution recommendation
- Prevention strategy development

## 🔄 Sürekli İyileştirme

### Learning Points
- Her hata durumunda pattern analizi yap
- Çözüm stratejilerini dokümante et
- Prevention mechanisms geliştir
- User experience improvements

### Feedback Loop
- Kullanıcı geri bildirimlerini analiz et
- System performance metrics topla
- Error frequency tracking
- Solution effectiveness measurement

## 📝 AI Asistan Notları

### Context Awareness
- Proje durumunu sürekli track et
- User preferences ve patterns öğren
- Historical data analizi yap
- Predictive maintenance uygula

### Communication Style
- Teknik detayları açık şekilde açıkla
- Problem çözüm adımlarını net listele
- Progress updates düzenli ver
- Success/failure durumlarını net belirt

### Knowledge Base
- Önceki sorunları ve çözümlerini hatırla
- Best practices koleksiyonu oluştur
- Anti-patterns ve pitfalls listesi tut
- Performance optimization techniques

---

**Bu dokuman AI asistan için bir referans kılavuzudur ve sürekli güncellenmektedir.**

**Son Güncelleme**: 21 Haziran 2025
**Versiyon**: 1.0.0 