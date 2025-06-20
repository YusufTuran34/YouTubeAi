#!/usr/bin/env python3
# post_to_twitter_simple.py - Simple Twitter automation with manual login

import time
import os
import json
import subprocess
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.keys import Keys

def load_channel_config():
    """Load channel configuration from channels.env"""
    try:
        # Source the channels.env file and get the environment variable
        result = subprocess.run(['bash', '-c', 'source channels.env && echo "$CHANNEL_CONFIGS"'], 
                              capture_output=True, text=True, cwd=os.getcwd())
        
        if result.returncode == 0 and result.stdout.strip():
            configs = json.loads(result.stdout.strip())
            if configs and len(configs) > 0:
                twitter_config = configs[0].get('twitter', {})
                return {
                    'username': twitter_config.get('USERNAME', ''),
                    'password': twitter_config.get('PASSWORD', ''),
                    'twitter_username': twitter_config.get('TWITTER_USERNAME', '')
                }
    except Exception as e:
        print(f"⚠️ channels.env yüklenemedi: {e}")
    
    return {'username': '', 'password': '', 'twitter_username': ''}

def setup_driver():
    """Setup Chrome driver with human-like options"""
    chrome_options = Options()
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--window-size=1400,900")
    chrome_options.add_argument("--start-maximized")
    
    # Use regular mode (not incognito) for persistent session
    # chrome_options.add_argument("--incognito")  # REMOVED
    
    # Keep cache and cookies for persistent login
    # chrome_options.add_argument("--disable-application-cache")  # REMOVED
    # chrome_options.add_argument("--disable-cache")  # REMOVED
    # chrome_options.add_argument("--disable-offline-load-stale-cache")  # REMOVED
    # chrome_options.add_argument("--disk-cache-size=0")  # REMOVED
    
    # Keep extensions for better compatibility
    # chrome_options.add_argument("--disable-extensions")  # REMOVED
    # chrome_options.add_argument("--disable-plugins")  # REMOVED
    # chrome_options.add_argument("--disable-images")  # REMOVED
    
    # Make it look more human
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option('useAutomationExtension', False)
    
    # Real user agent
    chrome_options.add_argument("--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    
    print("🔧 Chrome driver başlatılıyor (normal mod)...")
    try:
        driver = webdriver.Chrome(options=chrome_options)
        driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
        
        # Don't clear cookies/storage - keep session
        # driver.delete_all_cookies()  # REMOVED
        # driver.execute_script("window.localStorage.clear();")  # REMOVED
        # driver.execute_script("window.sessionStorage.clear();")  # REMOVED
        
        print("✅ Chrome driver başlatıldı (kalıcı oturum)!")
        return driver
    except Exception as e:
        print(f"❌ Chrome driver başlatılamadı: {e}")
        return None

def get_tweet_message():
    """Get tweet message from generate_tweet.sh script"""
    try:
        # Run the generate_tweet.sh script to get SEO-friendly tweet text
        result = subprocess.run(['bash', 'generate_tweet.sh'], 
                              capture_output=True, text=True, cwd=os.getcwd())
        
        if result.returncode == 0 and result.stdout.strip():
            message = result.stdout.strip()
            print(f"📝 ChatGPT ile oluşturulan tweet: {message}")
            return message
        else:
            print(f"⚠️ generate_tweet.sh çalıştırılamadı: {result.stderr}")
    except Exception as e:
        print(f"⚠️ generate_tweet.sh hatası: {e}")
    
    # Fallback to old method if script fails
    print("📝 Fallback tweet metni oluşturuluyor...")
    title = ""
    description = ""
    video_url = ""
    
    if os.path.exists("generated_title.txt"):
        with open("generated_title.txt", 'r') as f:
            title = f.read().strip()
    
    if os.path.exists("generated_description.txt"):
        with open("generated_description.txt", 'r') as f:
            description = f.read().strip()
    
    if os.path.exists("latest_video_url.txt"):
        with open("latest_video_url.txt", 'r') as f:
            video_url = f.read().strip()
    
    # Build message
    if title and description:
        message = f"{title} {description}"
    elif title:
        message = title
    elif description:
        message = description
    else:
        message = f"Automated tweet from simple Selenium - {os.popen('date').read().strip()}"
    
    # Add video URL if available
    if video_url:
        message = f"{message} {video_url}"
    
    if len(message) > 280:
        # Truncate and add video URL at the end
        if video_url:
            max_title_length = 280 - len(video_url) - 4  # 4 for " ..."
            message = f"{message[:max_title_length]}... {video_url}"
        else:
            message = message[:277] + "..."
    
    return message

def detect_field_type(driver):
    """Detect if the current field is username or password by checking input element"""
    try:
        # First try to find any input element on the page
        input_elements = driver.find_elements(By.TAG_NAME, "input")
        
        for input_elem in input_elements:
            try:
                input_type = input_elem.get_attribute("type")
                input_name = input_elem.get_attribute("name")
                input_autocomplete = input_elem.get_attribute("autocomplete")
                
                # Check if it's a password field
                if input_type == "password":
                    return 'password'
                
                # Check if it's a username field
                if (input_type == "text" and 
                    (input_name == "text" or 
                     input_autocomplete == "username" or
                     input_autocomplete == "on")):
                    return 'username'
                    
            except:
                continue
        
        # If no clear input found, check page text as fallback
        page_text = driver.page_source.lower()
        
        # Check for password-related text
        password_indicators = ['şifre', 'password', 'parola', 'şifrenizi girin']
        for indicator in password_indicators:
            if indicator in page_text:
                return 'password'
        
        # Check for username-related text
        username_indicators = ['kullanıcı adı', 'username', 'kullanıcı', 'kullanıcı adınız']
        for indicator in username_indicators:
            if indicator in page_text:
                return 'username'
        
        return 'unknown'
    except:
        return 'unknown'

def manual_login(driver):
    """Handle manual login process"""
    print("🔐 MANUEL GİRİŞ SÜRECİ BAŞLIYOR")
    print("=" * 40)
    
    # Load credentials from channels.env
    config = load_channel_config()
    username = config.get('username', '')
    password = config.get('password', '')
    twitter_username = config.get('twitter_username', '')
    
    if not username or not password:
        print("❌ Kullanıcı adı veya şifre bulunamadı!")
        return False
    
    try:
        # Go to Twitter login page
        print("🌐 Twitter giriş sayfası açılıyor...")
        driver.get("https://twitter.com/i/flow/login")
        time.sleep(5)
        
        # STEP 1: Enter email address
        print(f"📧 Email adresi giriliyor: {username}")
        
        # Try multiple selectors for email field
        email_selectors = [
            'input[autocomplete="username"]',
            'input[name="text"]',
            'input[type="text"]',
            'input[autocapitalize="sentences"]'
        ]
        
        email_field = None
        for selector in email_selectors:
            try:
                email_field = WebDriverWait(driver, 10).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, selector))
                )
                print(f"✅ Email alanı bulundu: {selector}")
                break
            except:
                continue
        
        if not email_field:
            print("❌ Email alanı bulunamadı!")
            return False
        
        email_field.clear()
        time.sleep(1)
        email_field.send_keys(username)
        time.sleep(2)
        
        # Click Next/İleri button
        print("➡️ Enter tuşu ile devam ediliyor...")
        email_field.send_keys(Keys.RETURN)
        time.sleep(5)  # Increased wait time
        
        # STEP 2: Check what field appears next (username or password)
        print("🔍 Sonraki alan tespit ediliyor...")
        
        # First detect what type of field we have
        field_type = detect_field_type(driver)
        print(f"🔍 Tespit edilen alan tipi: {field_type}")
        
        if field_type == 'password':
            # Direct password field found (2-step login)
            print("🔐 Şifre alanı tespit edildi, şifre giriliyor...")
            
            # Try to find password field
            password_selectors = [
                'input[type="password"]',
                '//input[@type="password"]',
                'input[name="password"]',
                '//input[@name="password"]',
                'input[autocomplete="current-password"]',
                'input[dir="auto"]',
                'input[autocorrect="on"]',
                'input[spellcheck="true"]'
            ]
            
            password_field = None
            for selector in password_selectors:
                try:
                    if selector.startswith('//'):
                        password_field = WebDriverWait(driver, 10).until(
                            EC.presence_of_element_located((By.XPATH, selector))
                        )
                    else:
                        password_field = WebDriverWait(driver, 10).until(
                            EC.presence_of_element_located((By.CSS_SELECTOR, selector))
                        )
                    print(f"✅ Şifre alanı bulundu: {selector}")
                    break
                except:
                    continue
            
            if password_field:
                print("🔐 Şifre otomatik olarak giriliyor...")
                password_field.clear()
                time.sleep(1)
                password_field.send_keys(password)
                time.sleep(2)
                
                # STEP 3: Click Login button
                print("🚀 Enter tuşu ile giriş yapılıyor...")
                password_field.send_keys(Keys.RETURN)
                time.sleep(5)
            else:
                print("❌ Şifre alanı bulunamadı!")
                return False
                
        elif field_type == 'username':
            # Username field found (3-step login)
            print("👤 Kullanıcı adı alanı tespit edildi, kullanıcı adı giriliyor...")
            
            username_selectors = [
                'input[type="text"]',
                'input[name="text"]',
                '//input[@type="text"]',
                '//input[@name="text"]',
                'input[autocomplete="username"]',
                'input[autocapitalize="sentences"]'
            ]
            
            username_field = None
            for selector in username_selectors:
                try:
                    username_field = WebDriverWait(driver, 10).until(
                        EC.presence_of_element_located((By.CSS_SELECTOR, selector))
                    )
                    print(f"✅ Kullanıcı adı alanı bulundu: {selector}")
                    break
                except:
                    continue
            
            if username_field:
                print(f"👤 Twitter kullanıcı adı giriliyor: {twitter_username}")
                username_field.clear()
                time.sleep(1)
                username_field.send_keys(twitter_username)
                time.sleep(2)
                
                # Press Enter to continue
                print("➡️ Enter tuşu ile devam ediliyor...")
                username_field.send_keys(Keys.RETURN)
                time.sleep(5)
                
                # Now try to find password field
                print("🔑 Şifre alanı aranıyor...")
                password_selectors = [
                    'input[type="password"]',
                    '//input[@type="password"]',
                    'input[name="password"]',
                    '//input[@name="password"]',
                    'input[autocomplete="current-password"]',
                    'input[dir="auto"]',
                    'input[autocorrect="on"]',
                    'input[spellcheck="true"]'
                ]
                
                password_field = None
                for selector in password_selectors:
                    try:
                        if selector.startswith('//'):
                            password_field = WebDriverWait(driver, 15).until(
                                EC.presence_of_element_located((By.XPATH, selector))
                            )
                        else:
                            password_field = WebDriverWait(driver, 15).until(
                                EC.presence_of_element_located((By.CSS_SELECTOR, selector))
                            )
                        print(f"✅ Şifre alanı bulundu: {selector}")
                        break
                    except:
                        continue
                
                if password_field:
                    print("🔐 Şifre otomatik olarak giriliyor...")
                    password_field.clear()
                    time.sleep(1)
                    password_field.send_keys(password)
                    time.sleep(2)
                    
                    # STEP 3: Click Login button
                    print("🚀 Enter tuşu ile giriş yapılıyor...")
                    password_field.send_keys(Keys.RETURN)
                    time.sleep(5)
                else:
                    print("❌ Şifre alanı bulunamadı!")
                    return False
            else:
                print("❌ Kullanıcı adı alanı bulunamadı!")
                return False
        else:
            print("❌ Alan tipi tespit edilemedi!")
            return False
        
        print("✅ Giriş süreci tamamlandı!")
        return True
        
    except Exception as e:
        print(f"❌ Giriş sürecinde hata: {e}")
        return False

def post_tweet(driver, message):
    """Post tweet after manual login"""
    print("📤 Tweet gönderiliyor...")
    
    try:
        # Go to Twitter home page
        print("🏠 Ana sayfa açılıyor...")
        driver.get("https://twitter.com/home")
        time.sleep(5)
        
        # Wait for tweet compose box with multiple selectors
        print("📝 Tweet kutusu aranıyor...")
        tweet_box_selectors = [
            '[data-testid="tweetTextarea_0"]',
            '[data-testid="tweetTextarea"]',
            'div[role="textbox"]',
            'div[contenteditable="true"]',
            '//div[@data-testid="tweetTextarea_0"]',
            '//div[@data-testid="tweetTextarea"]',
            '//div[@role="textbox"]'
        ]
        
        tweet_box = None
        for selector in tweet_box_selectors:
            try:
                if selector.startswith('//'):
                    tweet_box = WebDriverWait(driver, 10).until(
                        EC.presence_of_element_located((By.XPATH, selector))
                    )
                else:
                    tweet_box = WebDriverWait(driver, 10).until(
                        EC.presence_of_element_located((By.CSS_SELECTOR, selector))
                    )
                print(f"✅ Tweet kutusu bulundu: {selector}")
                break
            except:
                continue
        
        if not tweet_box:
            print("❌ Tweet kutusu bulunamadı!")
            print("🔍 Sayfa kaynağını kontrol ediliyor...")
            page_source = driver.page_source
            if "tweet" in page_source.lower():
                print("✅ Sayfada tweet kelimesi bulundu, manuel tweet bekleniyor...")
                print("📝 Tweet'i manuel olarak yazın ve gönderin...")
                input("Tweet gönderildikten sonra Enter'a basın...")
                return True
            else:
                return False
        
        # Enter tweet text
        print("📝 Tweet metni giriliyor...")
        tweet_box.clear()
        time.sleep(1)
        
        # Simple text input method
        tweet_box.send_keys(message)
        time.sleep(3)
        
        # Verify the text was entered correctly
        entered_text = tweet_box.get_attribute('value') or tweet_box.text
        print(f"📝 Girilen metin: {entered_text}")
        
        # Find and click post button with multiple selectors
        print("🚀 Tweet butonu aranıyor...")
        post_button_selectors = [
            '[data-testid="tweetButtonInline"]',  # Primary selector
            '[data-testid="tweetButton"]',
            '//span[text()="Tweet"]',
            '//span[text()="Tweetle"]',
            '//span[text()="Post"]',
            '//span[text()="Gönder"]',
            'button[type="submit"]',
            '//button[@data-testid="tweetButton"]',
            '//button[@data-testid="tweetButtonInline"]',
            '//div[@data-testid="tweetButton"]',
            '//span[contains(text(), "Tweet")]',
            '//span[contains(text(), "Tweetle")]',
            '//span[contains(text(), "Post")]',
            '//span[contains(text(), "Gönder")]',
            'button[data-testid="tweetButton"]',
            'button[data-testid="tweetButtonInline"]',
            'div[data-testid="tweetButton"]',
            '//button[contains(., "Post")]',
            '//button[contains(., "Tweet")]'
        ]
        
        post_button = None
        for selector in post_button_selectors:
            try:
                if selector.startswith('//'):
                    post_button = WebDriverWait(driver, 10).until(
                        EC.element_to_be_clickable((By.XPATH, selector))
                    )
                else:
                    post_button = WebDriverWait(driver, 10).until(
                        EC.element_to_be_clickable((By.CSS_SELECTOR, selector))
                    )
                print(f"✅ Tweet butonu bulundu: {selector}")
                break
            except:
                continue
        
        if post_button:
            print("🚀 Tweet gönderiliyor...")
            post_button.click()
            time.sleep(3)
            
            # Check if popup appeared and find the actual tweet button
            print("🔍 Popup kontrol ediliyor...")
            
            # First, let's see what buttons are available in the popup
            try:
                all_buttons = driver.find_elements(By.TAG_NAME, "button")
                print(f"🔍 Popup'ta {len(all_buttons)} buton bulundu")
                for i, btn in enumerate(all_buttons[:5]):  # Show first 5 buttons
                    try:
                        btn_text = btn.text
                        btn_testid = btn.get_attribute("data-testid")
                        print(f"  Buton {i+1}: text='{btn_text}', testid='{btn_testid}'")
                    except:
                        pass
            except:
                print("🔍 Buton listesi alınamadı")
            
            actual_tweet_selectors = [
                '[data-testid="tweetButtonInline"]',  # Primary selector for popup
                '//button[@data-testid="tweetButtonInline"]',
                'button[data-testid="tweetButtonInline"]',
                '[data-testid="tweetButton"]',
                '//button[@data-testid="tweetButton"]',
                'button[data-testid="tweetButton"]',
                '//span[text()="Tweet"]',
                '//span[text()="Post"]',
                '//span[text()="Tweetle"]',
                '//button[contains(., "Tweet")]',
                '//button[contains(., "Post")]',
                '//button[contains(., "Tweetle")]',
                'button[type="submit"]',
                '//button[@type="submit"]'
            ]
            
            actual_tweet_button = None
            for selector in actual_tweet_selectors:
                try:
                    if selector.startswith('//'):
                        actual_tweet_button = WebDriverWait(driver, 5).until(
                            EC.element_to_be_clickable((By.XPATH, selector))
                        )
                    else:
                        actual_tweet_button = WebDriverWait(driver, 5).until(
                            EC.element_to_be_clickable((By.CSS_SELECTOR, selector))
                        )
                    print(f"✅ Popup'ta tweet butonu bulundu: {selector}")
                    break
                except:
                    continue
            
            if actual_tweet_button:
                print("🚀 Popup'tan tweet gönderiliyor...")
                actual_tweet_button.click()
                time.sleep(5)
                print("✅ Tweet başarıyla gönderildi!")
                return True
            else:
                print("⚠️ Popup'ta tweet butonu bulunamadı, ilk buton tweet olmuş olabilir...")
                time.sleep(5)
                print("✅ Tweet başarıyla gönderildi!")
                return True
        else:
            print("❌ Tweet butonu bulunamadı!")
            return False
        
    except Exception as e:
        print(f"❌ Tweet gönderme hatası: {e}")
        return False

def main():
    print("🐦 TWITTER SIMPLE SELENIUM POST BAŞLATILIYOR")
    print("=" * 50)
    
    # Setup driver
    driver = setup_driver()
    if not driver:
        return
    
    try:
        # Manual login process
        if not manual_login(driver):
            print("❌ Giriş başarısız!")
            return
        
        # Get tweet message
        message = get_tweet_message()
        print(f"📝 Tweet mesajı: {message}")
        
        # Post tweet
        if post_tweet(driver, message):
            print("🎉 İşlem başarıyla tamamlandı!")
        else:
            print("❌ Tweet gönderilemedi")
        
        # Wait to see result
        print("🔍 Sonucu görmek için 20 saniye bekleniyor...")
        time.sleep(20)
        
    except Exception as e:
        print(f"❌ Hata: {e}")
    finally:
        print("🔒 Browser kapatılıyor...")
        driver.quit()

if __name__ == "__main__":
    main() 