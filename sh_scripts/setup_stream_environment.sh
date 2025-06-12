# setup_stream_environment.sh
echo ">> Gerekli araçlar kuruluyor..."
sudo apt update -y
sudo apt install -y ffmpeg jq python3-pip coreutils
pip3 install --break-system-packages gdown
echo ">> Kurulum tamamlandı."