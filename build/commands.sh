sudo cp /tmp/install.sh /root/
sudo cp /tmp/uninstall.sh /root/
sudo sed -i 's/\r//g' /root/install.sh
sudo sed -i 's/\r//g' /root/uninstall.sh