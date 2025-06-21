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
        
        # Fallback to channels.env file
        if os.path.exists('channels.env'):
            with open('channels.env', 'r') as f:
                for line in f:
                    if line.strip() and not line.startswith('#'):
                        key, value = line.strip().split('=', 1)
                        if key == 'TWITTER_USERNAME':
                            username = value.strip('"')
                        elif key == 'TWITTER_PASSWORD':
                            password = value.strip('"')
                        elif key == 'TWITTER_HANDLE':
                            handle = value.strip('"')
            
            if username and password:
                print(f"✅ channels.env'den yüklendi: {username}")
                return username, password, handle
        
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
    print("=" * 50)
    
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
    
    # Setup Chrome options
    chrome_options = Options()
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option('useAutomationExtension', False)
    
    # Initialize driver
    print("🔧 Chrome driver başlatılıyor (normal mod)...")
    driver = webdriver.Chrome(options=chrome_options)
    driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
    print("✅ Chrome driver başlatıldı (kalıcı oturum)!")
    
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
        tweet_textarea.clear()
        tweet_textarea.send_keys(tweet_text)
        print(f"📝 Girilen metin: {tweet_text}")
        
        # Find and click tweet button
        print("🚀 Tweet butonu aranıyor...")
        tweet_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, '[data-testid="tweetButtonInline"]'))
        )
        print("✅ Tweet butonu bulundu: [data-testid=\"tweetButtonInline\"]")
        
        print("🚀 Tweet gönderiliyor...")
        tweet_button.click()
        
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