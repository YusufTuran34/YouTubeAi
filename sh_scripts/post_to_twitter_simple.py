#!/usr/bin/env python3
# post_to_twitter_simple.py - Advanced Twitter automation with JSON configuration support

import time
import os
import json
import subprocess
import sys
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.keys import Keys
import uuid

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
        
        if username and password:
            print(f"✅ Environment variables'den yüklendi: {username}")
            return username, password, handle
        
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
                                    print(f"✅ channels.env'den yüklendi: {username}")
                                    return username, password, handle
            except Exception as e:
                print(f"⚠️ channels.env parse error: {e}")
        
        # Final fallback to test credentials
        print("⚠️ Using test credentials")
        return "yusuf.ai.2025.01@gmail.com", "159357asd!", "LofiRadioAi"
        
    except Exception as e:
        print(f"❌ Configuration loading error: {e}")
        return None, None, None

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

def main():
    print("🐦 TWITTER SIMPLE SELENIUM POST BAŞLATILIYOR")
    print("==================================================")
    
    # Load content configuration
    content_config = load_content_config()
    if not content_config:
        print("❌ Content configuration could not be loaded!")
        return
    
    # Get content type and zodiac sign from command line arguments
    content_type = sys.argv[1] if len(sys.argv) > 1 else content_config['settings']['default_content_type']
    zodiac_sign = sys.argv[2] if len(sys.argv) > 2 else content_config['settings']['default_zodiac']
    
    # Validate content type
    if not validate_content_type(content_type, content_config):
        return
    
    # Check if content type requires zodiac sign
    content_type_config = content_config['content_types'][content_type]
    requires_zodiac = content_type_config.get('requires_zodiac', False)
    
    if requires_zodiac:
        if not validate_zodiac_sign(zodiac_sign, content_config):
            return
        print(f"🔮 Zodiac Sign: {zodiac_sign}")
    
    print(f"🎯 Content Type: {content_type}")
    print(f"📝 Name: {content_type_config['name']}")
    print(f"🔮 Video Related: {content_type_config['video_related']}")
    print(f"🌟 Requires Zodiac: {requires_zodiac}")
    
    # Load configuration
    username, password, handle = load_channel_config()
    if not username or not password:
        print("❌ Kullanıcı adı veya şifre bulunamadı!")
        return
    
    # Generate tweet
    tweet_text = generate_tweet(content_type, zodiac_sign)
    if not tweet_text:
        print("❌ Tweet oluşturulamadı!")
        return
    
    print("📤 Tweet gönderiliyor...")
    
    # Setup Chrome options with performance optimizations
    chrome_options = Options()
    
    # Performance optimizations for speed
    if FAST_MODE:
        print("🚀 HIZLI MOD aktif - Performance optimizasyonları uygulanıyor...")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--disable-background-timer-throttling")
        chrome_options.add_argument("--disable-renderer-backgrounding")
        chrome_options.add_argument("--disable-features=TranslateUI")
        chrome_options.add_argument("--disable-ipc-flooding-protection")
        chrome_options.add_argument("--no-first-run")
        chrome_options.add_argument("--disable-default-apps")
        chrome_options.add_argument("--disable-extensions")
        chrome_options.add_argument("--disable-plugins")
        chrome_options.add_argument("--disable-images")  # Don't load images for speed
        chrome_options.page_load_strategy = 'eager'  # Don't wait for all resources
    else:
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
    
    # Headless mode if requested  
    if HEADLESS_MODE:
        chrome_options.add_argument("--headless")
        print("👻 Headless mode aktif!")
        
    # Reuse profile for faster login
    if REUSE_PROFILE:
        profile_path = os.path.expanduser("~/.chrome_twitter_profile")
        chrome_options.add_argument(f"--user-data-dir={profile_path}")
        print("🔄 Profile yeniden kullanılıyor (hızlı login)...")
    
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option('useAutomationExtension', False)
    chrome_options.add_argument("--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36")
    
    # Initialize driver with timing
    mode_text = "HIZLI MOD" if FAST_MODE else "normal mod"
    print(f"🔧 Chrome driver başlatılıyor ({mode_text})...")
    start_time = time.time()
    driver = webdriver.Chrome(options=chrome_options)
    driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
    
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
        email_field = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'input[autocomplete="username"]'))
        )
        print("✅ Email alanı bulundu: input[autocomplete=\"username\"]")
        email_field.clear()
        email_field.send_keys(username)
        print("➡️ Enter tuşu ile devam ediliyor...")
        email_field.send_keys(Keys.RETURN)
        time.sleep(2)
        
        # Check if username field is required
        print("🔍 Sonraki alan tespit ediliyor...")
        try:
            username_field = WebDriverWait(driver, 5).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, 'input[type="text"]'))
            )
            print("🔍 Tespit edilen alan tipi: username")
            print("👤 Kullanıcı adı alanı tespit edildi, kullanıcı adı giriliyor...")
            print(f"✅ Kullanıcı adı alanı bulundu: input[type=\"text\"]")
            username_field.clear()
            username_field.send_keys(handle)
            print(f"👤 Twitter kullanıcı adı giriliyor: {handle}")
            print("➡️ Enter tuşu ile devam ediliyor...")
            username_field.send_keys(Keys.RETURN)
            time.sleep(2)
        except:
            print("🔍 Username alanı gerekli değil, şifre alanına geçiliyor...")
        
        # Enter password
        print("🔑 Şifre alanı aranıyor...")
        password_field = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, 'input[type="password"]'))
        )
        print("✅ Şifre alanı bulundu: input[type=\"password\"]")
        password_field.clear()
        password_field.send_keys(password)
        print("🔐 Şifre otomatik olarak giriliyor...")
        print("🚀 Enter tuşu ile giriş yapılıyor...")
        password_field.send_keys(Keys.RETURN)
        time.sleep(5)
        
        print("✅ Giriş süreci tamamlandı!")
        
        # Navigate to home page
        print("🏠 Ana sayfa açılıyor...")
        driver.get("https://twitter.com/home")
        time.sleep(3)
        
        # Find tweet textarea
        print("📝 Tweet kutusu aranıyor...")
        tweet_textarea = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, '[data-testid="tweetTextarea_0"]'))
        )
        print("✅ Tweet kutusu bulundu: [data-testid=\"tweetTextarea_0\"]")
        
        # Enter tweet text
        print("📝 Tweet metni giriliyor...")
        # Clean tweet text to handle BMP character issues
        clean_tweet = tweet_text.encode('ascii', 'ignore').decode('ascii')
        if len(clean_tweet) < len(tweet_text):
            print(f"⚠️ Non-ASCII karakterler temizlendi: {len(tweet_text)} -> {len(clean_tweet)}")
        tweet_textarea.clear()
        tweet_textarea.send_keys(clean_tweet)
        print(f"📝 Girilen metin: {clean_tweet}")
        
        # Find and click tweet button
        print("🚀 Tweet butonu aranıyor...")
        tweet_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, '[data-testid="tweetButtonInline"]'))
        )
        print("✅ Tweet butonu bulundu: [data-testid=\"tweetButtonInline\"]")
        
        print("🚀 Tweet gönderiliyor...")
        # Use JavaScript click to avoid interception
        driver.execute_script("arguments[0].click();", tweet_button)
        
        print("✅ Tweet başarıyla gönderildi!")
        time.sleep(20)
        
    except Exception as e:
        print(f"❌ Tweet gönderme hatası: {e}")
        print("🔍 Sonucu görmek için 20 saniye bekleniyor...")
        time.sleep(20)
    
    finally:
        print("🔒 Browser kapatılıyor...")
        driver.quit()

if __name__ == "__main__":
    main() 