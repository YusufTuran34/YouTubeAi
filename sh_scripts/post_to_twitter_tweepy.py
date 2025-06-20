#!/usr/bin/env python3
# post_to_twitter_tweepy.py - Tweet using Tweepy (Twitter API v1.1)

import tweepy
import json
import os
import sys
from pathlib import Path

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
        'api_key': twitter_config.get('API_KEY'),
        'api_secret': twitter_config.get('API_SECRET'),
        'access_token': twitter_config.get('ACCESS_TOKEN'),
        'access_secret': twitter_config.get('ACCESS_SECRET')
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
        message = f"Automated tweet from Python Tweepy - {os.popen('date').read().strip()}"
    
    # Twitter 280 character limit
    if len(message) > 280:
        message = message[:277] + "..."
    
    return message

def main():
    print("🐦 TWITTER TWEEPY POST BAŞLATILIYOR")
    
    # Load configuration
    config = load_config()
    
    # Check credentials
    required_fields = ['api_key', 'api_secret', 'access_token', 'access_secret']
    for field in required_fields:
        if not config.get(field):
            print(f"❌ Eksik Twitter bilgisi: {field}")
            sys.exit(1)
    
    print("✅ Twitter API bilgileri mevcut")
    
    # Get tweet message
    message = get_tweet_message()
    print(f"📤 Tweet gönderiliyor: {message}")
    
    try:
        # Initialize Tweepy
        auth = tweepy.OAuthHandler(config['api_key'], config['api_secret'])
        auth.set_access_token(config['access_token'], config['access_secret'])
        
        api = tweepy.API(auth)
        
        # Post tweet
        tweet = api.update_status(message)
        
        print("✅ Tweet başarıyla gönderildi!")
        print(f"🆔 Tweet ID: {tweet.id}")
        print(f"👤 Kullanıcı: @{tweet.user.screen_name}")
        print(f"📝 Mesaj: {tweet.text}")
        print(f"🔗 Link: https://twitter.com/{tweet.user.screen_name}/status/{tweet.id}")
        
    except tweepy.errors.Unauthorized as e:
        print(f"❌ Yetkilendirme hatası: {e}")
        print("💡 API anahtarları geçersiz veya süresi dolmuş")
        sys.exit(1)
    except tweepy.errors.Forbidden as e:
        print(f"❌ Erişim reddedildi: {e}")
        print("💡 API erişim izni yok veya hesap kısıtlanmış")
        sys.exit(1)
    except tweepy.errors.TweepyException as e:
        print(f"❌ Tweet gönderme hatası: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Beklenmeyen hata: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 