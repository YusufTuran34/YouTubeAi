#!/usr/bin/env python3
# test_chrome.py - Simple ChromeDriver test

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service
import time

def test_chrome():
    print("🧪 ChromeDriver Test Başlatılıyor...")
    
    # Setup Chrome options
    chrome_options = Options()
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    
    try:
        # Use WebDriver Manager
        print("📥 ChromeDriver indiriliyor/güncelleniyor...")
        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service, options=chrome_options)
        
        print("✅ ChromeDriver başarıyla başlatıldı!")
        
        # Test basic functionality
        print("🌐 Google'a gidiliyor...")
        driver.get("https://www.google.com")
        time.sleep(3)
        
        print(f"📄 Sayfa başlığı: {driver.title}")
        
        # Test Twitter login page (without logging in)
        print("🐦 Twitter login sayfası test ediliyor...")
        driver.get("https://twitter.com/login")
        time.sleep(5)
        
        print(f"📄 Twitter sayfa başlığı: {driver.title}")
        
        # Check if page loaded successfully
        if "twitter" in driver.title.lower() or "login" in driver.current_url:
            print("✅ Twitter sayfası başarıyla yüklendi!")
        else:
            print("⚠️ Twitter sayfası beklendiği gibi yüklenmedi")
        
        driver.quit()
        print("✅ Test başarıyla tamamlandı!")
        return True
        
    except Exception as e:
        print(f"❌ Test başarısız: {e}")
        return False

if __name__ == "__main__":
    test_chrome() 