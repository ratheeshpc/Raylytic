sudo cp /tmp/install.sh /root/
sudo cp /tmp/uninstall.sh /root/
sudo sed -i 's/\r//g' /root/install.sh
sudo sed -i 's/\r//g' /root/uninstall.sh
apt update
apt install -y docker.io
sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod 755 /usr/local/bin/docker-compose
apt install git
apt install make