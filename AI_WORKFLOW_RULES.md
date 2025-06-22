# 🤖 AI İş Akışı Kuralları

## 📋 **Öncelik Sırası**
1. **ChromeDriver Çakışması** - İlk kontrol edilmesi gereken
2. **Port 8080 Durumu** - İkinci kontrol
3. **Config Yükleme** - API key'ler ve environment
4. **Test Execution** - Gerçek işlevsellik

## 🔧 **Standart Komutlar**

### Proje Başlatma
```bash
./project_manager.sh clean    # Önce temizlik
./project_manager.sh start    # Sonra başlat
```

### Hızlı Test
```bash
./project_manager.sh test config    # Config testi
./project_manager.sh test tweet     # Tweet generation
./project_manager.sh test horoscope # Horoscope test
./project_manager.sh test lofi      # LoFi test
```

### Sorun Giderme
```bash
./project_manager.sh status         # Sistem durumu
./project_manager.sh clean          # Temizlik
./project_manager.sh restart        # Yeniden başlat
```

## 🚨 **Sorun Çözüm Adımları**

### 1. ChromeDriver Hatası
- **Belirti**: `user-data-dir already in use`
- **Çözüm**: `./project_manager.sh clean`

### 2. Port 8080 Çakışması
- **Belirti**: `Port 8080 was already in use`
- **Çözüm**: `./project_manager.sh clean`

### 3. OpenAI API Hatası
- **Belirti**: `❌ OpenAI API key not found`
- **Çözüm**: `./project_manager.sh test config`

### 4. Tweet "null" Hatası
- **Belirti**: Tweet'te "null" görünüyor
- **Çözüm**: `./project_manager.sh test tweet`

## 🎯 **AI Kuralları**

### ✅ **YAPILMASI GEREKENLER**
1. Her problem için önce `./project_manager.sh status` çalıştır
2. Sorun varsa `./project_manager.sh clean` ile temizle
3. Test yapmadan önce `./project_manager.sh test config` çalıştır
4. Değişiklik yaptıktan sonra `./project_manager.sh test` ile doğrula
5. Spring Boot başlatmadan önce mutlaka temizlik yap

### ❌ **YAPILMAMASI GEREKENLER**
1. Direkt `./gradlew bootRun` çalıştırma
2. Manuel process kill etme
3. Aynı testi tekrar tekrar çalıştırma
4. Config kontrolü yapmadan test etme
5. Cleanup yapmadan yeniden başlatma

## 📊 **Test Senaryoları**

### Scenario 1: Yeni Özellik Test
```bash
./project_manager.sh clean
./project_manager.sh test config
./project_manager.sh test [specific_feature]
```

### Scenario 2: Bug Fix Doğrulama
```bash
./project_manager.sh clean
./project_manager.sh test all
./project_manager.sh start
```

### Scenario 3: Production Hazırlığı
```bash
./project_manager.sh clean
./project_manager.sh test all
./project_manager.sh status
./project_manager.sh start
```

## 🔄 **Sürekli İyileştirme**

### Performans Metrikleri
- **Temizlik Süresi**: < 10 saniye
- **Test Süresi**: < 30 saniye
- **Başlatma Süresi**: < 60 saniye
- **Hata Oranı**: < %5

### Otomatik Kontroller
- Config validation
- Port availability
- Process cleanup
- Error handling

## 💡 **İpuçları**

1. **Hızlı Debug**: `./project_manager.sh test config` ile başla
2. **Güvenli Restart**: `./project_manager.sh restart` kullan
3. **Durum Kontrolü**: `./project_manager.sh status` ile kontrol et
4. **Log İnceleme**: `./project_manager.sh logs` ile logları gör

Bu kuralları takip ederek daha verimli çalışabiliriz! 🚀 