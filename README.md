# captainci-apt
CaptainCI interface for APT (Advanced Package Tool) 


wget -O - https://github.com/erikni/captainci-apt/setup.sh | bash


sudo make -f Makefile.debian build
for file in `ls ../captainci-apt_*_all.deb`; do sudo dpkg -i $file; done


captainci-apt build
