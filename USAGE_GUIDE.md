# 🚀 YouTubeAI Proje Yönetim Kılavuzu

## 🎯 **Hızlı Başlangıç**

### 1. **Proje Başlatma** (En Sık Kullanılan)
```bash
./project_manager.sh clean    # Sistem temizliği
./project_manager.sh start    # Proje başlat
```

### 2. **Hızlı Test** (Geliştirme Sırasında)
```bash
./project_manager.sh test config     # Config kontrolü
./project_manager.sh test tweet      # Tweet generation
./project_manager.sh test horoscope  # Horoscope test
./project_manager.sh test lofi       # LoFi test
```

### 3. **Sorun Giderme** (Problem Olduğunda)
```bash
./project_manager.sh status    # Durum kontrol
./project_manager.sh clean     # Temizlik
./project_manager.sh restart   # Yeniden başlat
```

## 🔧 **Detaylı Komutlar**

### Proje Yönetimi
| Komut | Açıklama | Ne Zaman Kullan |
|-------|----------|-----------------|
| `./project_manager.sh start` | Temizlik + Spring Boot başlat | İlk başlatma |
| `./project_manager.sh restart` | Yeniden başlat | Sorun olduğunda |
| `./project_manager.sh clean` | Sistem temizliği | Çakışma olduğunda |
| `./project_manager.sh status` | Durum kontrolü | Problem tespit |

### Test Sistemleri
| Komut | Açıklama | Süre |
|-------|----------|------|
| `./project_manager.sh test config` | API key kontrolü | 5sn |
| `./project_manager.sh test tweet` | Tweet generation | 15sn |
| `./project_manager.sh test horoscope` | Horoscope + Twitter | 45sn |
| `./project_manager.sh test lofi` | LoFi + Twitter | 45sn |
| `./project_manager.sh test all` | Tüm testler | 2dk |

## 🚨 **Yaygın Sorunlar ve Çözümler**

### 1. **ChromeDriver Hatası**
```
❌ user-data-dir already in use
✅ Çözüm: ./project_manager.sh clean
```

### 2. **Port 8080 Çakışması**
```
❌ Port 8080 was already in use
✅ Çözüm: ./project_manager.sh clean
```

### 3. **OpenAI API Hatası**
```
❌ OpenAI API key not found
✅ Çözüm: ./project_manager.sh test config
```

### 4. **Tweet "null" Hatası**
```
❌ Tweet içeriği "null"
✅ Çözüm: ./project_manager.sh test tweet
```

## 📊 **İş Akışı Örnekleri**

### Scenario 1: Yeni Gün Başlangıcı
```bash
./project_manager.sh status     # Durum kontrol
./project_manager.sh clean      # Temizlik
./project_manager.sh start      # Başlat
```

### Scenario 2: Bug Fix Test
```bash
./project_manager.sh clean      # Temizlik
./project_manager.sh test all   # Tüm testler
./project_manager.sh start      # Başlat
```

### Scenario 3: Hızlı Feature Test
```bash
./project_manager.sh test config    # Config OK?
./project_manager.sh test tweet     # Tweet OK?
# Eğer OK ise Spring Boot'a gerek yok
```

### Scenario 4: Production Deployment
```bash
./project_manager.sh clean
./project_manager.sh test all
./project_manager.sh status
./project_manager.sh start
```

## 🎯 **AI için Özel Kurallar**

### ✅ **Her Zaman Yap**
1. Problem çözümünde önce `./project_manager.sh status`
2. Değişiklik sonrası `./project_manager.sh test config`
3. Spring Boot başlatmadan önce `./project_manager.sh clean`

### ❌ **Asla Yapma**
1. Direkt `./gradlew bootRun` çalıştırma
2. Manuel `pkill` komutları
3. Config kontrolü olmadan test etme

## 🔄 **Performans Metrikleri**

| İşlem | Hedef Süre | Başarı Oranı |
|-------|------------|---------------|
| Temizlik | < 10sn | %100 |
| Config Test | < 5sn | %100 |
| Tweet Test | < 15sn | %95 |
| Full Test | < 2dk | %90 |
| Başlatma | < 60sn | %95 |

## 📋 **Kontrol Listesi**

### Günlük Çalışma Öncesi
- [ ] `./project_manager.sh status` - Durum kontrol
- [ ] `./project_manager.sh clean` - Temizlik
- [ ] `./project_manager.sh test config` - Config kontrol
- [ ] `./project_manager.sh start` - Başlat

### Problem Çözümü Sonrası
- [ ] `./project_manager.sh test all` - Tüm testler
- [ ] `./project_manager.sh status` - Final kontrol
- [ ] Browser'da http://localhost:8080 kontrol

### Geliştirme Sonrası
- [ ] `./project_manager.sh test [specific]` - İlgili test
- [ ] `./project_manager.sh test config` - Config kontrol
- [ ] Manual test via web interface

Bu kılavuzu takip ederek çok daha verimli çalışabiliriz! 🎉 