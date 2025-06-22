# Content Configuration System

Bu sistem, tweet içerik türlerini, prompt'larını ve **AI video generation ayarlarını** JSON formatında yönetmenizi sağlar. Artık yeni kategoriler eklemek, video background'larını customize etmek veya mevcut olanları düzenlemek için benden yardım istemenize gerek yok!

## 📁 Dosya Yapısı

- `content_configs.json` - Ana konfigürasyon dosyası (tweet + video generation)
- `manage_content_configs.sh` - Konfigürasyon yönetim aracı
- `generate_tweet_advanced.sh` - JSON konfigürasyonunu kullanan tweet üretim script'i
- `post_to_twitter_simple.py` - JSON konfigürasyonunu kullanan Python script'i
- `generate_ai_video_background.sh` - **YENİ**: ChatGPT + DALL-E ile video background üretimi
- `generate_video.sh` - Ana video generation script'i (güncellenmiş)

## 🚀 Hızlı Başlangıç

### 1. Mevcut İçerik Türlerini Listele
```bash
./manage_content_configs.sh list
```

### 2. Belirli Bir İçerik Türünün Detaylarını Gör
```bash
./manage_content_configs.sh show lofi
```

### 3. Yeni İçerik Türü Ekle
```bash
./manage_content_configs.sh add tech
```

### 4. Konfigürasyonu Doğrula
```bash
./manage_content_configs.sh validate
```

## 📋 JSON Konfigürasyon Yapısı

### İçerik Türü Yapısı
```json
{
  "content_types": {
    "lofi": {
      "name": "LoFi Radio",
      "description": "LoFi focus music for study, work, and relaxation",
      "hashtags": ["#LoFi", "#FocusMusic", "#StudyMusic"],
      "emojis": ["🎵", "📚", "☕"],
      "tone": "calm and relaxing",
      "video_related": true,
      "requires_zodiac": false,
      "prompts": {
        "video": "Create a tweet about this LoFi video: '{VIDEO_TITLE}'...",
        "general": "Create a calming LoFi tweet about focus music..."
      }
    }
  }
}
```

### Alan Açıklamaları

| Alan | Açıklama | Örnek |
|------|----------|-------|
| `name` | İçerik türünün görünen adı | "LoFi Radio" |
| `description` | İçerik türünün açıklaması | "LoFi focus music..." |
| `hashtags` | Kullanılacak hashtag'ler | `["#LoFi", "#FocusMusic"]` |
| `emojis` | Kullanılacak emoji'ler | `["🎵", "📚"]` |
| `tone` | İçeriğin tonu | "calm and relaxing" |
| `video_related` | Video ile ilgili mi? | `true` veya `false` |
| `requires_zodiac` | Burç bilgisi gerekiyor mu? | `true` veya `false` |
| `prompts` | ChatGPT prompt'ları | `{"video": "...", "general": "..."}` |

### Prompt Türleri

1. **`general`** - Genel tweet'ler için
2. **`video`** - Video ile ilgili tweet'ler için (sadece `video_related: true` olan türler için)
3. **`daily`** - Günlük içerikler için (sadece `requires_zodiac: true` olan türler için)

### Placeholder'lar

Prompt'larda kullanabileceğiniz placeholder'lar:

- `{VIDEO_TITLE}` - Video başlığı (video prompt'ları için)
- `{ZODIAC_SIGN}` - Burç adı (horoscope prompt'ları için)

## 🛠️ Yönetim Komutları

### İçerik Türü Ekleme
```bash
./manage_content_configs.sh add <tür_adı>
```

Örnek:
```bash
./manage_content_configs.sh add tech
```

### İçerik Türü Silme
```bash
./manage_content_configs.sh remove <tür_adı>
```

### Yedekleme ve Geri Yükleme
```bash
# Yedek oluştur
./manage_content_configs.sh backup

# Yedekten geri yükle
./manage_content_configs.sh restore <yedek_dosyası>
```

## 📝 Örnek Kullanım Senaryoları

### 1. Yeni Bir Fitness Kategorisi Ekleme

```bash
./manage_content_configs.sh add fitness
```

Sorulara şu şekilde cevap verin:
- Name: Fitness & Wellness
- Description: Fitness tips, workout motivation, and health advice
- Tone: energetic and motivational
- Video Related: false
- Requires Zodiac: false
- Hashtags: #Fitness, #Workout, #Health, #Motivation
- Emojis: 💪 🔥 🏃 💯
- General prompt: Create an energetic fitness tweet about workouts, motivation, or health tips. Make it inspiring and actionable. Include relevant hashtags and emojis. Keep it under 280 characters.

### 2. Mevcut Bir Kategoriyi Düzenleme

JSON dosyasını doğrudan düzenleyebilir veya yeni bir tür ekleyip eskisini silebilirsiniz:

```bash
# Eski türü sil
./manage_content_configs.sh remove fitness

# Yeni türü ekle
./manage_content_configs.sh add fitness_new
```

## 🔧 Teknik Detaylar

### Script'lerin JSON Kullanımı

1. **`generate_tweet_advanced.sh`**:
   - JSON dosyasından konfigürasyonu okur
   - İçerik türünü doğrular
   - Uygun prompt'u seçer
   - Placeholder'ları değiştirir

2. **`post_to_twitter_simple.py`**:
   - JSON dosyasından konfigürasyonu okur
   - İçerik türünü ve burç bilgisini doğrular
   - Shell script'ini çağırır

### Hata Yönetimi

- Geçersiz içerik türü → Hata mesajı + mevcut türler listesi
- Geçersiz burç → Hata mesajı + mevcut burçlar listesi
- Eksik JSON dosyası → Hata mesajı
- Geçersiz JSON → Hata mesajı

## 🎯 Avantajlar

1. **Esneklik**: Yeni kategoriler kolayca eklenebilir
2. **Tutarlılık**: Tüm script'ler aynı konfigürasyonu kullanır
3. **Yönetilebilirlik**: Merkezi konfigürasyon yönetimi
4. **Güvenlik**: Yedekleme ve geri yükleme özellikleri
5. **Doğrulama**: JSON yapısı otomatik doğrulanır

## 🚨 Önemli Notlar

1. **jq Gereksinimi**: `manage_content_configs.sh` script'i `jq` komut satırı aracını gerektirir
2. **UTF-8 Encoding**: JSON dosyası UTF-8 encoding ile kaydedilmelidir
3. **Yedekleme**: Büyük değişikliklerden önce mutlaka yedek alın
4. **Test**: Yeni kategoriler ekledikten sonra test edin

## 🔍 Sorun Giderme

### JSON Dosyası Bulunamıyor
```bash
ls -la content_configs.json
```

### jq Yüklü Değil
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### Geçersiz JSON
```bash
./manage_content_configs.sh validate
```

## 🎬 AI Video Generation Sistemi

### Hızlı Kullanım
```bash
# Content type'a göre AI video background üret
./generate_ai_video_background.sh lofi
./generate_ai_video_background.sh meditation  
./generate_ai_video_background.sh horoscope

# Ana video generation sistemini çalıştır
export TAG=lofi
./generate_video.sh
```

### Video Generation Ayarları
Her content type için özel video generation ayarları bulunur:

```json
"video_generation": {
  "visual_tags": ["tag1", "tag2"],        // ChatGPT için visual keywords
  "background_prompt": "Detaylı prompt",  // DALL-E için base prompt  
  "animation_style": "smooth",            // Animasyon stili
  "color_palette": "warm colors",         // Renk paleti
  "mood": "peaceful"                      // Genel atmosfer
}
```

### Global Video Settings
```json
"video_generation": {
  "enabled": true,                        // Video generation aktif mi?
  "use_ai_generation": true,              // AI üretimi kullansın mı?
  "fallback_to_google_drive": true,       // Fallback olarak Google Drive
  "ai_model": "dall-e-3",                // DALL-E model versiyonu
  "frame_count": 4,                       // Kaç frame üretilsin
  "output_format": "gif"                  // Çıkış formatı (gif/mp4)
}
```

### Çalışma Prensibi
1. 🤖 **ChatGPT**: Content type'a göre frame açıklamaları üretir
2. 🎨 **DALL-E 3**: Her frame için high-quality görsel oluşturur  
3. 🎬 **FFmpeg**: Frame'leri birleştirip GIF/MP4 yapar
4. 📁 **Fallback**: AI başarısız olursa Google Drive'dan dosya alır

Bu sistem sayesinde artık tweet içerik türlerinizi ve video background'larınızı tamamen bağımsız olarak yönetebilirsiniz! 🎉 