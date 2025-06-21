#!/usr/bin/env python3
"""post_to_twitter_api.py - Tweet posting via Twitter API without Selenium.

This script loads tweet content from the existing generation pipeline and
posts it using the Twitter API. Credentials are read from environment
variables or the JSON-based `channels.env` configuration.
The script mimics the configuration driven style of `post_to_twitter_simple.py`
but avoids browser automation.
"""

import json
import os
import subprocess
import sys
from typing import Tuple

import tweepy


CONTENT_CONFIG_FILE = "content_configs.json"
GENERATED_TWEET_FILE = "generated_tweet.txt"


def load_content_config():
    """Load tweet content configuration from JSON."""
    try:
        if not os.path.exists(CONTENT_CONFIG_FILE):
            print(f"❌ Configuration file not found: {CONTENT_CONFIG_FILE}")
            return None
        with open(CONTENT_CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as exc:
        print(f"❌ Error loading content config: {exc}")
        return None


def validate_content_type(content_type: str, config: dict) -> bool:
    if not config:
        return False
    valid = list(config.get("content_types", {}).keys())
    if content_type not in valid:
        print(f"❌ Invalid content type: {content_type}")
        print(f"✅ Available types: {', '.join(valid)}")
        return False
    return True


def validate_zodiac_sign(zodiac_sign: str, config: dict) -> bool:
    if not config:
        return False
    signs = config.get("zodiac_signs", [])
    if zodiac_sign not in signs:
        print(f"❌ Invalid zodiac sign: {zodiac_sign}")
        print(f"✅ Available signs: {', '.join(signs)}")
        return False
    return True


def _parse_channels_env() -> Tuple[str, str, str, str]:
    """Extract Twitter credentials from channels.env if available."""
    if not os.path.exists("channels.env"):
        return "", "", "", ""
    try:
        with open("channels.env", "r") as f:
            content = f.read()
        if "CHANNEL_CONFIGS=" not in content:
            return "", "", "", ""
        start = content.find("'[")
        end = content.rfind("]'")
        if start == -1 or end == -1:
            return "", "", "", ""
        json_str = content[start + 1 : end + 1]
        data = json.loads(json_str)
        if not data:
            return "", "", "", ""
        twitter = data[0].get("twitter", {})
        return (
            twitter.get("API_KEY", ""),
            twitter.get("API_SECRET", ""),
            twitter.get("ACCESS_TOKEN", ""),
            twitter.get("ACCESS_SECRET", ""),
        )
    except Exception as exc:
        print(f"⚠️ channels.env parse error: {exc}")
        return "", "", "", ""


def load_credentials() -> Tuple[str, str, str, str]:
    """Load Twitter API credentials from env or channels.env."""
    api_key = os.getenv("TWITTER_API_KEY", "")
    api_secret = os.getenv("TWITTER_API_SECRET", "")
    access_token = os.getenv("TWITTER_ACCESS_TOKEN", "")
    access_secret = os.getenv("TWITTER_ACCESS_SECRET", "")

    if api_key and api_secret and access_token and access_secret:
        print("✅ Credentials loaded from environment variables")
        return api_key, api_secret, access_token, access_secret

    env_creds = _parse_channels_env()
    if all(env_creds):
        print("✅ Credentials loaded from channels.env")
        return env_creds

    print("❌ Twitter API credentials not found!")
    return "", "", "", ""


def generate_tweet(content_type: str, zodiac_sign: str) -> str:
    """Generate tweet text using existing shell script."""
    try:
        cmd = f"bash generate_tweet_advanced.sh {content_type} {zodiac_sign}"
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, cwd=os.getcwd()
        )
        if result.returncode != 0:
            print(f"❌ Tweet generation failed: {result.stderr}")
            return ""
        if os.path.exists(GENERATED_TWEET_FILE):
            with open(GENERATED_TWEET_FILE, "r", encoding="utf-8") as f:
                text = f.read().strip()
            print(f"✅ Tweet generated ({len(text)} chars)")
            return text
        print("❌ Generated tweet file not found")
        return ""
    except Exception as exc:
        print(f"❌ Tweet generation error: {exc}")
        return ""


def post_tweet(api_key: str, api_secret: str, access_token: str, access_secret: str, text: str):
    """Send tweet via Tweepy."""
    try:
        auth = tweepy.OAuth1UserHandler(api_key, api_secret, access_token, access_secret)
        api = tweepy.API(auth)
        status = api.update_status(status=text)
        print("✅ Tweet posted successfully!")
        print(f"🌐 https://twitter.com/user/status/{status.id}")
    except tweepy.TweepyException as exc:
        print(f"❌ Twitter API error: {exc}")
        print(
            "⚠️ Your account may not have API access or the credentials are invalid."
        )


def main():
    config = load_content_config()
    if not config:
        return

    content_type = sys.argv[1] if len(sys.argv) > 1 else config["settings"].get("default_content_type", "lofi")
    zodiac_sign = sys.argv[2] if len(sys.argv) > 2 else config["settings"].get("default_zodiac", "aries")

    if not validate_content_type(content_type, config):
        return

    ct_config = config["content_types"][content_type]
    requires_zodiac = ct_config.get("requires_zodiac", False)
    if requires_zodiac and not validate_zodiac_sign(zodiac_sign, config):
        return

    creds = load_credentials()
    if not all(creds):
        return

    tweet_text = generate_tweet(content_type, zodiac_sign)
    if not tweet_text:
        return

    post_tweet(*creds, tweet_text)


if __name__ == "__main__":
    main()
