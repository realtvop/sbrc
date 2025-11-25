# sbrc

更适合中国宝宝体质的shell rc

用于防止忘记关闭中文输入法时的尴尬情况

## 安装

(for zsh)
```sh
cd ~
git clone https://github.com/realtvop/sbrc.git
echo 'source ~/sbrc/.sbrc' >> ~/.zshrc
```

Or use the bundled `init.sh` script to detect your current shell and add the source line automatically:

```sh
cd ~
git clone https://github.com/realtvop/sbrc.git
cd sbrc
./init.sh    # prompts you to confirm where to add the source
# or
./init.sh -y # run without confirmation
```