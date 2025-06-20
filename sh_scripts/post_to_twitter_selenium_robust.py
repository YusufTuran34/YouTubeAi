#!/usr/bin/env python3
# post_to_twitter_selenium_robust.py - Robust Twitter automation with Selenium

import time
import json
import os
import sys
from pathlib import Path
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import TimeoutException, NoSuchElementException, ElementClickInterceptedException

def load_config():
    """Load Twitter credentials from channels.env"""
    script_dir = Path(__file__).parent
    env_file = script_dir / "channels.env"
    
    if not env_file.exists():
        print("❌ channels.env dosyası bulunamadı")
        sys.exit(1)
    
    # Load environment variables
    with open(env_file, 'r') as f:
        content = f.read()
    
    # Extract JSON config
    start = content.find('export CHANNEL_CONFIGS=\'[')
    if start == -1:
        print("❌ CHANNEL_CONFIGS bulunamadı")
        sys.exit(1)
    
    start = content.find('[', start)
    end = content.find(']', start) + 1
    
    config_json = content[start:end]
    config = json.loads(config_json)
    
    # Get default channel
    default_channel = None
    for channel in config:
        if channel.get('name') == 'default':
            default_channel = channel
            break
    
    if not default_channel:
        print("❌ Default channel bulunamadı")
        sys.exit(1)
    
    twitter_config = default_channel.get('twitter', {})
    
    return {
        'username': twitter_config.get('USERNAME'),
        'password': twitter_config.get('PASSWORD')
    }

def get_tweet_message():
    """Get tweet message from generated files"""
    script_dir = Path(__file__).parent
    
    title = ""
    description = ""
    
    title_file = script_dir / "generated_title.txt"
    desc_file = script_dir / "generated_description.txt"
    
    if title_file.exists():
        with open(title_file, 'r') as f:
            title = f.read().strip()
    
    if desc_file.exists():
        with open(desc_file, 'r') as f:
            description = f.read().strip()
    
    if title or description:
        message = f"{title} {description}".strip()
    else:
        message = f"Automated tweet from robust Selenium - {os.popen('date').read().strip()}"
    
    # Twitter 280 character limit
    if len(message) > 280:
        message = message[:277] + "..."
    
    return message

def setup_driver():
    """Setup Chrome driver with robust options"""
    chrome_options = Options()
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=1400,900")
    chrome_options.add_argument("--start-maximized")
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option('useAutomationExtension', False)
    
    # User agent
    chrome_options.add_argument("--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    
    print("🔧 Chrome driver başlatılıyor...")
    try:
        driver = webdriver.Chrome(options=chrome_options)
        driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
        print("✅ Chrome driver başlatıldı!")
        return driver
    except Exception as e:
        print(f"❌ Chrome driver başlatılamadı: {e}")
        sys.exit(1)

def wait_and_find_element(driver, by, value, timeout=30, retries=3):
    """Wait for element with retries"""
    for attempt in range(retries):
        try:
            element = WebDriverWait(driver, timeout).until(
                EC.presence_of_element_located((by, value))
            )
            return element
        except TimeoutException:
            if attempt < retries - 1:
                print(f"⚠️ Element bulunamadı, {timeout} saniye bekleniyor... (Deneme {attempt + 1}/{retries})")
                time.sleep(timeout)
            else:
                print(f"❌ Element bulunamadı: {value}")
                return None
    return None

def safe_click(driver, element, timeout=10):
    """Safely click element without retries"""
    try:
        # Scroll to element
        driver.execute_script("arguments[0].scrollIntoView(true);", element)
        time.sleep(2)
        
        # Click
        element.click()
        return True
    except Exception as e:
        print(f"❌ Tıklama başarısız: {e}")
        return False

def find_button_by_text(driver, text_options, timeout=10):
    """Find button by multiple text options"""
    for text in text_options:
        try:
            # Try different XPath patterns
            xpath_patterns = [
                f"//span[text()='{text}']",
                f"//span[contains(text(), '{text}')]",
                f"//div[@role='button']//span[text()='{text}']/..",
                f"//div[@role='button']//span[contains(text(), '{text}')]/..",
                f"//button//span[text()='{text}']/..",
                f"//button//span[contains(text(), '{text}')]/.."
            ]
            
            for xpath in xpath_patterns:
                try:
                    button = driver.find_element(By.XPATH, xpath)
                    if button.is_displayed() and button.is_enabled():
                        print(f"✅ Buton bulundu: '{text}' ({xpath})")
                        return button
                except:
                    continue
        except:
            continue
    
    return None

def handle_security_verification(driver, username):
    """Handle Twitter security verification page"""
    print("🔒 Güvenlik doğrulaması sayfası tespit edildi...")
    
    try:
        # Wait for verification input field with specific data-testid
        print("📱 Güvenlik doğrulama alanı aranıyor...")
        verification_field = wait_and_find_element(driver, By.CSS_SELECTOR, 'input[data-testid="ocfEnterTextTextInput"]', timeout=20)
        
        if not verification_field:
            # Fallback to general username input
            verification_field = wait_and_find_element(driver, By.CSS_SELECTOR, 'input[autocomplete="username"]', timeout=10)
        
        if verification_field:
            print("📱 Kullanıcı adı (LofiAiRadio) giriliyor...")
            verification_field.clear()
            time.sleep(1)
            verification_field.send_keys("LofiAiRadio")  # Use the specific username
            time.sleep(2)
            
            # Find and click continue button using data-testid
            print("➡️ Devam butonu aranıyor...")
            continue_button = wait_and_find_element(driver, By.CSS_SELECTOR, 'button[data-testid="ocfEnterTextNextButton"]', timeout=10)
            
            if continue_button:
                print("➡️ Devam butonuna tıklanıyor...")
                if not safe_click(driver, continue_button):
                    print("⚠️ Tıklama başarısız, Enter tuşu deneniyor...")
                    verification_field.send_keys(Keys.RETURN)
                time.sleep(5)
            else:
                print("⚠️ Devam butonu bulunamadı, Enter tuşu deneniyor...")
                verification_field.send_keys(Keys.RETURN)
                time.sleep(5)
            
            return True
        else:
            print("❌ Doğrulama alanı bulunamadı")
            return False
            
    except Exception as e:
        print(f"❌ Güvenlik doğrulaması hatası: {e}")
        return False

def check_for_security_page(driver):
    """Check if we're on a security verification page"""
    try:
        # Check for security verification text
        security_texts = [
            "Telefon numaranı veya kullanıcı adını gir",
            "Enter your phone number or username",
            "Hesabında olağan dışı bir giriş etkinliği",
            "Unusual login activity detected"
        ]
        
        page_text = driver.page_source.lower()
        for text in security_texts:
            if text.lower() in page_text:
                return True
        
        return False
    except:
        return False

def login_to_twitter(driver, username, password):
    """Login to Twitter with robust error handling"""
    print("🔐 Twitter'a giriş yapılıyor...")
    
    try:
        # Go to Twitter login page
        print("🌐 Login sayfası açılıyor...")
        driver.get("https://twitter.com/i/flow/login")
        time.sleep(8)  # Longer wait for page load
        
        # Wait for username field
        print("👤 Kullanıcı adı alanı aranıyor...")
        username_field = wait_and_find_element(driver, By.CSS_SELECTOR, 'input[autocomplete="username"]', timeout=30)
        if not username_field:
            print("❌ Kullanıcı adı alanı bulunamadı")
            return False
        
        # Enter username
        print("👤 Kullanıcı adı giriliyor...")
        username_field.clear()
        time.sleep(1)
        username_field.send_keys(username)
        time.sleep(3)
        
        # Doğrudan Enter'a bas (İleri butonuna basmadan)
        print("⏎ Enter tuşuna basılıyor...")
        username_field.send_keys(Keys.RETURN)
        time.sleep(8)  # Güvenlik sayfasının yüklenmesi için daha uzun bekle
        
        # Check if we're on security verification page
        if check_for_security_page(driver):
            print("🔒 Güvenlik doğrulaması sayfası tespit edildi...")
            if not handle_security_verification(driver, username):
                print("❌ Güvenlik doğrulaması başarısız")
                return False
            time.sleep(5)
        
        # Check for second page button before password field
        print("🔍 İkinci sayfa butonu kontrol ediliyor...")
        second_button = wait_and_find_element(driver, By.CSS_SELECTOR, 'button[data-testid="ocfEnterTextNextButton"]', timeout=5)
        if second_button:
            print("➡️ İkinci sayfa butonuna tıklanıyor...")
            if not safe_click(driver, second_button):
                print("⚠️ İkinci sayfa butonu tıklanamadı")
            time.sleep(5)
        
        # Wait for password field with specific attributes
        print("🔑 Şifre alanı aranıyor...")
        password_field = wait_and_find_element(driver, By.CSS_SELECTOR, 'input[name="password"][autocomplete="current-password"]', timeout=30)
        if not password_field:
            # Fallback to general password input
            password_field = wait_and_find_element(driver, By.CSS_SELECTOR, 'input[name="password"]', timeout=10)
        
        if not password_field:
            print("❌ Şifre alanı bulunamadı")
            return False
        
        # Enter password
        print("🔑 Şifre giriliyor...")
        password_field.clear()
        time.sleep(1)
        password_field.send_keys(password)
        time.sleep(3)
        
        # Find and click Login button using data-testid
        print("🚀 Login butonu aranıyor...")
        login_button = wait_and_find_element(driver, By.CSS_SELECTOR, 'button[data-testid="LoginForm_Login_Button"]', timeout=10)
        
        if login_button:
            print("🚀 Login butonuna tıklanıyor...")
            if not safe_click(driver, login_button):
                print("⚠️ Tıklama başarısız, Enter tuşu deneniyor...")
                password_field.send_keys(Keys.RETURN)
        else:
            print("⚠️ Login butonu bulunamadı, Enter tuşu deneniyor...")
            password_field.send_keys(Keys.RETURN)
        
        # Wait for login to complete
        print("⏳ Giriş tamamlanıyor...")
        time.sleep(15)  # Longer wait for login
        
        # Check if login was successful
        current_url = driver.current_url
        print(f"📍 Mevcut URL: {current_url}")
        
        if "home" in current_url or "twitter.com" in current_url:
            print("✅ Twitter'a başarıyla giriş yapıldı!")
            return True
        else:
            print("❌ Twitter girişi başarısız")
            print("💡 Manuel olarak giriş yapmayı deneyin")
            return False
            
    except Exception as e:
        print(f"❌ Login hatası: {e}")
        return False

def post_tweet(driver, message):
    """Post tweet with robust error handling"""
    print("📤 Tweet gönderiliyor...")
    
    try:
        # Go to Twitter home page
        print("🏠 Ana sayfa açılıyor...")
        driver.get("https://twitter.com/home")
        time.sleep(8)
        
        # Wait for tweet compose box
        print("📝 Tweet kutusu aranıyor...")
        tweet_box = None
        
        # Try multiple selectors for tweet box
        tweet_selectors = [
            '[data-testid="tweetTextarea_0"]',
            '[data-testid="tweetTextarea"]',
            'div[role="textbox"]',
            'div[contenteditable="true"]'
        ]
        
        for selector in tweet_selectors:
            tweet_box = wait_and_find_element(driver, By.CSS_SELECTOR, selector, timeout=30)
            if tweet_box:
                print(f"✅ Tweet kutusu bulundu: {selector}")
                break
        
        if not tweet_box:
            print("❌ Tweet kutusu bulunamadı")
            return False
        
        # Clear and enter tweet text
        print("📝 Tweet metni giriliyor...")
        tweet_box.clear()
        time.sleep(2)
        tweet_box.send_keys(message)
        time.sleep(5)
        
        # Find and click post button
        print("🚀 Tweet butonu aranıyor...")
        post_button = None
        
        # Try multiple selectors for post button
        post_selectors = [
            '[data-testid="tweetButton"]',
            '[data-testid="tweetButtonInline"]',
            'div[data-testid="tweetButton"]',
            'div[data-testid="tweetButtonInline"]'
        ]
        
        for selector in post_selectors:
            try:
                buttons = driver.find_elements(By.CSS_SELECTOR, selector)
                for button in buttons:
                    if button.is_displayed() and button.is_enabled():
                        text = button.text.lower()
                        if 'tweet' in text or 'post' in text or 'send' in text or not text:
                            post_button = button
                            break
                if post_button:
                    break
            except:
                continue
        
        # Try XPath selectors if CSS selectors failed
        if not post_button:
            xpath_selectors = [
                "//span[contains(text(), 'Tweet')]/parent::div",
                "//span[contains(text(), 'Post')]/parent::div",
                "//div[@role='button']//span[contains(text(), 'Tweet')]/..",
                "//div[@role='button']//span[contains(text(), 'Post')]/.."
            ]
            
            for xpath in xpath_selectors:
                try:
                    buttons = driver.find_elements(By.XPATH, xpath)
                    for button in buttons:
                        if button.is_displayed() and button.is_enabled():
                            post_button = button
                            break
                    if post_button:
                        break
                except:
                    continue
        
        if post_button:
            print("🚀 Tweet gönderiliyor...")
            if safe_click(driver, post_button):
                time.sleep(8)
                print("✅ Tweet başarıyla gönderildi!")
                return True
            else:
                print("❌ Tweet butonuna tıklanamadı")
                return False
        else:
            print("❌ Tweet butonu bulunamadı")
            print("💡 Manuel olarak tweet göndermeyi deneyin")
            return False
            
    except Exception as e:
        print(f"❌ Tweet gönderme hatası: {e}")
        return False

def main():
    print("🐦 TWITTER ROBUST SELENIUM POST BAŞLATILIYOR")
    print("=" * 60)
    
    # Load configuration
    config = load_config()
    
    # Check credentials
    if not config.get('username') or not config.get('password'):
        print("❌ Twitter kullanıcı adı veya şifre eksik")
        print("💡 channels.env dosyasında USERNAME ve PASSWORD ekleyin")
        sys.exit(1)
    
    print("✅ Twitter bilgileri mevcut")
    
    # Get tweet message
    message = get_tweet_message()
    print(f"📝 Tweet mesajı: {message}")
    
    # Setup driver
    driver = setup_driver()
    
    try:
        # Login to Twitter
        if not login_to_twitter(driver, config['username'], config['password']):
            print("❌ Twitter girişi başarısız oldu")
            print("💡 Manuel olarak giriş yapmayı deneyin")
            input("Giriş yaptıktan sonra Enter'a basın...")
        
        # Post tweet
        if not post_tweet(driver, message):
            print("❌ Tweet gönderilemedi")
            sys.exit(1)
        
        print("🎉 İşlem başarıyla tamamlandı!")
        
    except KeyboardInterrupt:
        print("\n⚠️ İşlem kullanıcı tarafından durduruldu")
    except Exception as e:
        print(f"❌ Beklenmeyen hata: {e}")
    finally:
        # Keep browser open for 20 seconds to see the result
        print("🔍 Sonucu görmek için 20 saniye bekleniyor...")
        time.sleep(20)
        driver.quit()

if __name__ == "__main__":
    main() 