#!/usr/bin/env python3
# post_to_twitter_simple.py - Advanced Twitter automation with JSON configuration support

import time
import os
import json
import subprocess
import sys
import site; site.addsitedir('/Users/yusuf-mini/Downloads/YouTubeAi/.venv/lib/python3.13/site-packages')
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service
import uuid
from selenium.common.exceptions import ElementClickInterceptedException
from selenium.webdriver.remote.webelement import WebElement
import shutil

# Performance optimizations
FAST_MODE = True  # Enable speed optimizations
HEADLESS_MODE = os.getenv('HEADLESS', 'false').lower() == 'true'
REUSE_PROFILE = True  # Reuse Chrome profile for faster login

def load_content_config():
    """Load content configuration from JSON file"""
    try:
        config_file = "content_configs.json"
        if not os.path.exists(config_file):
            print(f"❌ Configuration file not found: {config_file}")
            return None
        
        with open(config_file, 'r', encoding='utf-8') as f:
            config = json.load(f)
        
        return config
    except Exception as e:
        print(f"❌ Error loading content config: {e}")
        return None

def validate_content_type(content_type, config):
    """Validate content type against JSON configuration"""
    if not config:
        return False
    
    valid_types = list(config.get('content_types', {}).keys())
    if content_type not in valid_types:
        print(f"❌ Invalid content type: {content_type}")
        print(f"✅ Available types: {', '.join(valid_types)}")
        return False
    
    return True

def validate_zodiac_sign(zodiac_sign, config):
    """Validate zodiac sign against JSON configuration"""
    if not config:
        return False
    
    valid_signs = config.get('zodiac_signs', [])
    if zodiac_sign not in valid_signs:
        print(f"❌ Invalid zodiac sign: {zodiac_sign}")
        print(f"✅ Available signs: {', '.join(valid_signs)}")
        return False
    
    return True

def load_channel_config():
    """Load channel configuration from channels.env or environment variables"""
    try:
        # First try to get from environment variables (when running from Spring Boot)
        username = os.environ.get('TWITTER_USERNAME', '')
        password = os.environ.get('TWITTER_PASSWORD', '')
        handle = os.environ.get('TWITTER_HANDLE', '')
        channel_name = os.environ.get('CHANNEL', 'default')  # CHANNEL parameter for profile selection
        
        if username and password:
            print(f"✅ Environment variables'den yüklendi: {username} (Channel: {channel_name})")
            return username, password, handle, channel_name
        
        # Fallback to channels.env file (JSON format)
        if os.path.exists('channels.env'):
            try:
                with open('channels.env', 'r') as f:
                    content = f.read()
                    # Extract JSON from the export statement
                    if 'CHANNEL_CONFIGS=' in content:
                        json_start = content.find("'[")
                        json_end = content.rfind("]'")
                        if json_start != -1 and json_end != -1:
                            json_str = content[json_start+1:json_end+1]
                            config = json.loads(json_str)
                            if config and len(config) > 0:
                                twitter_config = config[0].get('twitter', {})
                                username = twitter_config.get('USERNAME', '')
                                password = twitter_config.get('PASSWORD', '')
                                handle = twitter_config.get('TWITTER_USERNAME', '')
                                
                                if username and password:
                                    print(f"✅ channels.env'den yüklendi: {username} (Channel: default)")
                                    return username, password, handle, 'default'
            except Exception as e:
                print(f"⚠️ channels.env parse error: {e}")
        
        # Final fallback to test credentials
        print("⚠️ Using test credentials")
        return "yusuf.ai.2025.01@gmail.com", "159357asd!", "LofiRadioAi", "default"
        
    except Exception as e:
        print(f"❌ Configuration loading error: {e}")
        return None, None, None, None

def get_latest_video_url():
    """Get the latest video URL from file"""
    try:
        if os.path.exists('latest_video_url.txt'):
            with open('latest_video_url.txt', 'r') as f:
                url = f.read().strip()
                if url:
                    print(f"📹 Video URL bulundu: {url}")
                    return url
        print("⚠️ Video URL bulunamadı")
        return None
    except Exception as e:
        print(f"❌ Video URL okuma hatası: {e}")
        return None

def generate_tweet(content_type="lofi", zodiac_sign="aries"):
    """Generate tweet using the advanced script"""
    try:
        print(f"📝 Advanced tweet generation başlatılıyor...")
        
        # Call the advanced tweet generation script
        cmd = f"bash generate_tweet_advanced.sh {content_type} {zodiac_sign}"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=os.getcwd())
        
        if result.returncode == 0:
            print("✅ Advanced tweet generation başarılı!")
            
            # Read the generated tweet
            if os.path.exists('generated_tweet.txt'):
                with open('generated_tweet.txt', 'r') as f:
                    tweet_text = f.read().strip()
                
                # VIDEO_TITLE placeholder'ını değiştir
                video_title = ""
                if os.path.exists('generated_title.txt'):
                    with open('generated_title.txt', 'r') as f:
                        video_title = f.read().strip()
                
                # Placeholder'ı doğru video title ile değiştir
                if video_title and '{VIDEO_TITLE}' in tweet_text:
                    tweet_text = tweet_text.replace('{VIDEO_TITLE}', video_title)
                    print(f"✅ VIDEO_TITLE placeholder değiştirildi: {video_title}")
                elif '{VIDEO_TITLE}' in tweet_text:
                    # Fallback: placeholder'ı kaldır
                    tweet_text = tweet_text.replace('{VIDEO_TITLE}', '')
                    print("⚠️ Video title bulunamadı, placeholder kaldırıldı")
                
                # Check if we have a video URL to append
                video_url = get_latest_video_url()
                if video_url:
                    # Add video URL to tweet if there's space
                    url_text = f"\n\n🎥 Watch: {video_url}"
                    if len(tweet_text) + len(url_text) <= 280:
                        tweet_text += url_text
                        print("📹 Video URL tweet'e eklendi")
                    else:
                        print("⚠️ Tweet çok uzun, video URL eklenmedi")
                
                # Read content type for logging
                content_type_used = content_type
                if os.path.exists('last_content_type.txt'):
                    with open('last_content_type.txt', 'r') as f:
                        content_type_used = f.read().strip()
                
                print(f"🎯 Content Type: {content_type_used}")
                print(f"📊 Tweet uzunluğu: {len(tweet_text)} karakter")
                print(f"📝 Tweet mesajı: {tweet_text}")
                
                return tweet_text
            else:
                print("❌ Generated tweet file not found")
                return None
        else:
            print(f"❌ Tweet generation failed: {result.stderr}")
            return None
            
    except Exception as e:
        print(f"❌ Tweet generation error: {e}")
        return None

def get_persistent_profile_dir(channel_name, username):
    """Get persistent Chrome profile directory for the account"""
    import hashlib
    # Create a stable hash from username for consistent profiling
    account_hash = hashlib.md5(f"{channel_name}_{username}".encode()).hexdigest()[:8]
    
    # Use a permanent directory instead of /tmp
    profile_base_dir = os.path.expanduser("~/.twitter_profiles")
    profile_dir = f"{profile_base_dir}/chrome_profile_{channel_name}_{account_hash}"
    
    # Create directory if it doesn't exist
    os.makedirs(profile_dir, exist_ok=True)
    
    print(f"📁 KALICI profil dizini oluşturuldu: {profile_dir}")
    print(f"🔐 Hesap hash: {account_hash} (Channel: {channel_name})")
    print(f"👤 Username: {username}")
    
    return profile_dir

def cleanup_chrome_processes():
    """Clean up any leftover Chrome/ChromeDriver processes"""
    try:
        import subprocess
        # Kill any leftover Chrome processes
        subprocess.run(['pkill', '-f', 'chromedriver'], capture_output=True)
        subprocess.run(['pkill', '-f', 'Chrome.*--user-data-dir'], capture_output=True)
        print("🧹 Chrome processes cleaned up")
    except Exception as e:
        print(f"⚠️ Chrome cleanup warning: {e}")

def main():
    print("🐦 TWITTER SIMPLE SELENIUM POST BAŞLATILIYOR")
    print("==================================================")
    
    # Clean up any leftover processes first
    cleanup_chrome_processes()
    
    # Load content configuration
    content_config = load_content_config()
    if not content_config:
        print("❌ Content configuration could not be loaded!")
        sys.exit(1)
    
    # Get content type and zodiac sign from command line arguments
    content_type = sys.argv[1] if len(sys.argv) > 1 else content_config['settings']['default_content_type']
    zodiac_sign = sys.argv[2] if len(sys.argv) > 2 else content_config['settings']['default_zodiac']
    
    # Validate content type
    if not validate_content_type(content_type, content_config):
        sys.exit(1)
    
    # Check if content type requires zodiac sign
    content_type_config = content_config['content_types'][content_type]
    requires_zodiac = content_type_config.get('requires_zodiac', False)
    
    if requires_zodiac:
        if not validate_zodiac_sign(zodiac_sign, content_config):
            sys.exit(1)
        print(f"🔮 Zodiac Sign: {zodiac_sign}")
    
    print(f"🎯 Content Type: {content_type}")
    print(f"📝 Name: {content_type_config['name']}")
    print(f"🔮 Video Related: {content_type_config['video_related']}")
    print(f"🌟 Requires Zodiac: {requires_zodiac}")
    
    # Load configuration
    config_result = load_channel_config()
    if config_result is None or None in config_result:
        print("❌ Kullanıcı adı veya şifre bulunamadı!")
        print("❌ Giriş başarısız!")
        sys.exit(1)
        
    if len(config_result) == 4:
        username, password, handle, channel_name = config_result
    else:
        username, password, handle = config_result[:3]
        channel_name = "default"
    
    # Generate tweet
    tweet_text = generate_tweet(content_type, zodiac_sign)
    if not tweet_text:
        print("❌ Tweet oluşturulamadı!")
        sys.exit(1)
    
    print("📤 Tweet gönderiliyor...")
    
    # Chrome driver başlatma - KALICI PROFİL SİSTEMİ
    print("🔧 Chrome driver başlatılıyor (KALICI PROFİL MOD)...")
    import time
    
    # Hesap-bazlı kalıcı profil dizini - ARTIK GEÇİCİ DEĞİL!
    profile_dir = get_persistent_profile_dir(channel_name, username)
    print(f"🔐 KALICI PROFİL KULLANILIYOR: {profile_dir}")
    
    chrome_options = Options()
    # Anti-detection ayarları
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-blink-features=AutomationControlled')
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option('useAutomationExtension', False)
    chrome_options.add_argument('--disable-web-security')
    chrome_options.add_argument('--allow-running-insecure-content')
    chrome_options.add_argument('--disable-extensions')
    
    # KALICI profil dizini - aynı hesap her zaman aynı profile kullanacak
    chrome_options.add_argument(f'--user-data-dir={profile_dir}')
    
    # Consistent browser fingerprint için
    chrome_options.add_argument('--disable-features=VizDisplayCompositor')
    chrome_options.add_argument('--disable-default-apps')
    chrome_options.add_argument('--disable-component-extensions-with-background-pages')
    
    # HIZLI MOD optimizasyonları (JavaScript'i disable etmeyelim çünkü Twitter için gerekli)
    if FAST_MODE:
        print("🚀 HIZLI MOD aktif - Dengeli optimizasyonlar uygulanıyor...")
        chrome_options.add_argument('--disable-images')
        chrome_options.add_argument('--disable-plugins')
        chrome_options.add_argument('--no-first-run')
        chrome_options.add_argument('--disable-default-apps')
        chrome_options.add_argument('--disable-background-timer-throttling')
        chrome_options.add_argument('--disable-renderer-backgrounding')
        chrome_options.add_argument('--disable-backgrounding-occluded-windows')
    else:
        print("🐌 YAVAS MOD aktif - Maksimum güvenlik optimizasyonları...")
        chrome_options.add_argument('--disable-gpu')
        chrome_options.add_argument('--disable-software-rasterizer')
        chrome_options.add_argument('--disable-background-timer-throttling')
        chrome_options.add_argument('--disable-renderer-backgrounding')
        chrome_options.add_argument('--disable-backgrounding-occluded-windows')
        chrome_options.add_argument('--disable-features=TranslateUI')
        chrome_options.add_argument('--disable-ipc-flooding-protection')
        chrome_options.add_argument('--no-first-run')
        chrome_options.add_argument('--disable-default-apps')
    
    # Headless mode if requested  
    if HEADLESS_MODE:
        chrome_options.add_argument("--headless")
        print("👻 Headless mode aktif!")
        
    # Reuse profile for faster login
    if REUSE_PROFILE:
        print("🔄 Profile yeniden kullanılıyor (hızlı login)...")
    
    # Final anti-detection settings
    chrome_options.add_argument("--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
    
    # Initialize driver with timing and WebDriver Manager
    mode_text = "HIZLI MOD" if FAST_MODE else "normal mod"
    print(f"🔧 Chrome driver başlatılıyor ({mode_text})...")
    start_time = time.time()
    
    driver = None
    try:
        # Use WebDriver Manager to automatically download and manage ChromeDriver
        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service, options=chrome_options)
        driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
        print("✅ ChromeDriver WebDriver Manager ile başarıyla başlatıldı!")
    except Exception as e:
        print(f"❌ ChromeDriver başlatma hatası: {e}")
        print("🔄 Fallback: Sistem ChromeDriver'ı deneniyor...")
        try:
            driver = webdriver.Chrome(options=chrome_options)
            driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
            print("✅ Sistem ChromeDriver ile başarıyla başlatıldı!")
        except Exception as e2:
            print(f"❌ Sistem ChromeDriver da başarısız: {e2}")
            print("💡 ChromeDriver kurulumu gerekiyor:")
            print("   brew install chromedriver")
            print("   veya https://chromedriver.chromium.org/ adresinden indirin")
            # Clean up profile directory if created
            if os.path.exists(profile_dir):
                try:
                    shutil.rmtree(profile_dir)
                    print(f"🗑️ Başarısız session profil dizini temizlendi: {profile_dir}")
                except:
                    pass
            sys.exit(1)
    
    # Set faster timeouts for speed
    if FAST_MODE:
        driver.implicitly_wait(3)  # Reduced from default 10
        driver.set_page_load_timeout(10)  # Reduced from default 30
    
    setup_time = time.time() - start_time
    print(f"✅ Chrome driver başlatıldı! Süre: {setup_time:.1f}s")
    
    try:
        # Login process
        print("🔐 MANUEL GİRİŞ SÜRECİ BAŞLIYOR")
        print("=" * 40)
        
        print("🌐 Twitter giriş sayfası açılıyor...")
        driver.get("https://twitter.com/login")
        time.sleep(3)
        
        # Enter email
        print(f"📧 Email adresi giriliyor: {username}")
        print("🔍 Email alanı aranıyor...")
        email_selectors = [
            'input[autocomplete="username"]',
            'input[name="text"]',
            'input[type="email"]',
            'input[placeholder*="email"]',
            'input[data-testid*="email"]',
            'input[autocomplete="email"]',
            'input[name="session[username_or_email]"]',
            'input[name="username"]'
        ]
        email_field = None
        for selector in email_selectors:
            try:
                print(f"🔍 Email selector deneniyor: {selector}")
                email_field = WebDriverWait(driver, 5).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, selector))
                )
                print(f"✅ Email alanı bulundu: {selector}")
                break
            except Exception as e:
                print(f"❌ Email selector başarısız: {selector}")
                continue
        if not email_field:
            print("❌ Hiçbir email selector'ı çalışmadı!")
            driver.quit()
            sys.exit(1)
        print("📝 Email alanı temizleniyor...")
        email_field.clear()
        print("📝 Email alanı temizlendi")
        email_field.send_keys(str(username) if username else "")
        print("📧 Email adresi yazıldı")
        print("➡️ Enter tuşu ile devam ediliyor...")
        email_field.send_keys(Keys.RETURN)
        print("✅ Enter tuşu gönderildi")
        print("⏳ 2 saniye bekleniyor...")
        time.sleep(2)
        print("✅ Bekleme tamamlandı")
        
        # Check if username field is required
        print("🔍 Sonraki alan tespit ediliyor...")
        try:
            print("🔍 Username alanı aranıyor...")
            username_field = WebDriverWait(driver, 5).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, 'input[type="text"]'))
            )
            print("🔍 Tespit edilen alan tipi: username")
            print("👤 Kullanıcı adı alanı tespit edildi, kullanıcı adı giriliyor...")
            print(f"✅ Kullanıcı adı alanı bulundu: input[type=\"text\"]")
            username_field.clear()
            print("📝 Username alanı temizlendi")
            username_field.send_keys(str(handle) if handle else "")
            print(f"👤 Twitter kullanıcı adı giriliyor: {handle}")
            print("➡️ Enter tuşu ile devam ediliyor...")
            username_field.send_keys(Keys.RETURN)
            print("✅ Username Enter tuşu gönderildi")
            print("⏳ 2 saniye bekleniyor...")
            time.sleep(2)
            print("✅ Username bekleme tamamlandı")
        except Exception as e:
            print(f"🔍 Username alanı gerekli değil: {e}")
            print("🔍 Şifre alanına geçiliyor...")
        
        # Enter password
        print("🔑 Şifre alanı aranıyor...")
        password_field = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'input[type="password"]'))
        )
        print("✅ Şifre alanı bulundu: input[type=\"password\"]")
        password_field.clear()
        print("📝 Şifre alanı temizlendi")
        password_field.send_keys(password)
        print("🔐 Şifre otomatik olarak giriliyor...")
        print("🚀 Enter tuşu ile giriş yapılıyor...")
        password_field.send_keys(Keys.RETURN)
        print("✅ Şifre Enter tuşu gönderildi")
        print("⏳ 5 saniye bekleniyor...")
        time.sleep(5)
        print("✅ Login bekleme tamamlandı")
        print("🔄 Login sonrası işlemler başlıyor...")
        # Her durumda compose/post'a git
        print("🌐 https://x.com/compose/post adresine yönlendiriliyor...")
        print("🔄 driver.get() çağrısı yapılıyor...")
        try:
            driver.get("https://x.com/compose/post")
            print("✅ driver.get() başarılı!")
        except Exception as e:
            print(f"❌ driver.get() hatası: {e}")
            raise e
        print("⏳ 3 saniye bekleniyor...")
        time.sleep(3)
        print("✅ Bekleme tamamlandı!")
        print(f"🌐 Aktif URL: {driver.current_url}")
        print(f"🌐 Sayfa başlığı: {driver.title}")
        print("🔄 Aktif element alınıyor...")
        # Tweet kutusu bulma
        active = driver.switch_to.active_element
        print(f"🟢 Aktif element: tag={active.tag_name}, class={active.get_attribute('class')}, id={active.get_attribute('id')}, aria-label={active.get_attribute('aria-label')}")
        tweet_box = None
        try:
            # Önce aktif element deneyelim
            if active.get_attribute('contenteditable') == 'true':
                tweet_box = active
                print("✅ Tweet kutusu aktif element olarak bulundu.")
        except Exception as e:
            print(f"⚠️ Aktif element ile tweet kutusu bulunamadı: {e}")
        if not tweet_box:
            # Fallback: CSS selector ile dene
            try:
                tweet_box = driver.find_element(By.CSS_SELECTOR, 'div[role="textbox"][contenteditable="true"]')
                print("✅ Tweet kutusu CSS selector ile bulundu.")
            except Exception as e:
                print(f"❌ Tweet kutusu CSS selector ile de bulunamadı: {e}")
        if not tweet_box:
            print("❌ Tweet kutusu hiçbir şekilde bulunamadı! Tweet atılamaz.")
            driver.quit()
            sys.exit(1)
        # Tweet metni gir (Unicode karakterleri temizle - ChromeDriver BMP sorunu için)
        import re
        # Remove non-BMP characters (emojis) that ChromeDriver can't handle
        clean_tweet = re.sub(r'[^\u0000-\uFFFF]', '', tweet_text)
        # Replace problematic Unicode characters
        clean_tweet = clean_tweet.replace('\u2013', '-').replace('\u2014', '-').replace('\u2018', "'").replace('\u2019', "'").replace('\u201c', '"').replace('\u201d', '"')
        print(f"📝 Girilen metin: {clean_tweet}")
        
        # Tweet box'a metin gir
        tweet_box.clear()
        tweet_box.send_keys(clean_tweet)
        
        # Metni girdikten sonra kısa bir süre bekle
        time.sleep(2)
        print("⏳ Tweet butonu aktif olması için bekleniyor...")
        
        # Tweet gönderme butonunu bul ve aktif olmasını bekle
        tweet_button = None
        button_selectors = [
            '[data-testid="tweetButtonInline"]',
            '[data-testid="tweetButton"]',
            'div[data-testid="tweetButtonInline"] button',
            'button[aria-label="Post"]'
        ]
        
        for selector in button_selectors:
            try:
                # Butonu bul ve aktif olmasını bekle
                tweet_button = WebDriverWait(driver, 10).until(
                    EC.element_to_be_clickable((By.CSS_SELECTOR, selector))
                )
                print(f"✅ Tweet butonu bulundu ve aktif: {selector}")
                break
            except Exception as e:
                print(f"❌ Tweet butonu aktif değil: {selector}")
                continue
        
        if not tweet_button:
            print("❌ Aktif tweet gönderme butonu bulunamadı!")
            # Klavye kısayolu deneyelim
            print("🔄 Klavye kısayolu deneniyor: Ctrl+Enter (Mac: Cmd+Enter)")
            try:
                actions = ActionChains(driver)
                actions.key_down(Keys.COMMAND).send_keys(Keys.RETURN).key_up(Keys.COMMAND).perform()
                print("✅ Klavye kısayolu gönderildi!")
                time.sleep(3)
            except Exception as e:
                print(f"❌ Klavye kısayolu da başarısız: {e}")
                driver.quit()
                sys.exit(1)
        else:
            # Butona tıkla
            try:
                # JavaScript ile tıklama deneyelim
                driver.execute_script("arguments[0].click();", tweet_button)
                print("🚀 Tweet gönderme butonuna JavaScript ile tıklandı!")
            except Exception as e:
                print(f"❌ JavaScript tıklama başarısız: {e}")
                # Normal tıklama deneyelim
                try:
                    tweet_button.click()
                    print("🚀 Tweet gönderme butonuna normal tıklama ile tıklandı!")
                except Exception as e2:
                    print(f"❌ Normal tıklama da başarısız: {e2}")
                    # Son çare: ActionChains ile tıklama
                    try:
                        actions = ActionChains(driver)
                        actions.move_to_element(tweet_button).click().perform()
                        print("🚀 Tweet gönderme butonuna ActionChains ile tıklandı!")
                    except Exception as e3:
                        print(f"❌ ActionChains tıklama da başarısız: {e3}")
                        driver.quit()
                        sys.exit(1)
        time.sleep(5)
        print(f"🔄 5sn sonra URL: {driver.current_url}")
        time.sleep(15)
        
    except Exception as e:
        print(f"❌ Tweet gönderme hatası: {e}")
        print("🔍 Sonucu görmek için 5 saniye bekleniyor...")
        time.sleep(5)
        print("🔒 Browser kapatılıyor...")
        if driver:
            try:
                driver.quit()
            except:
                pass
        sys.exit(1)
    
    finally:
        print("🔒 Browser kapatılıyor...")
        if 'driver' in locals():
            try:
                driver.quit()
                print("✅ Chrome driver kapatıldı")
            except Exception as e:
                print(f"⚠️ Chrome driver kapatma hatası: {e}")
        
        # KALICI PROFİL SİSTEMİ - Profil dizinini ASLA SİLME!
        print(f"📁 Kalıcı profil korundu: {profile_dir}")
        print("🔄 Aynı hesap bir sonraki tweet'te AYNI PROFİLİ kullanacak")
        print("✅ Anti-bot detection için browser fingerprint korundu!")
        
        # Final cleanup of any remaining Chrome processes (but not profile data)
        cleanup_chrome_processes()

if __name__ == "__main__":
    main() 