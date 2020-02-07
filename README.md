# captainci-apt
CaptainCI interface for APT (Advanced Package Tool) 

```
wget -O - https://raw.githubusercontent.com/erikni/captainci-apt/master/setup.sh | bash
```

sudo make -f Makefile.debian build
for file in `ls ../captainci-apt_*_all.deb`; do sudo dpkg -i $file; done


captainci-apt build
