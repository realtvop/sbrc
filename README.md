# sbrc

更适合中国宝宝体质的shell rc

用于防止忘记关闭中文输入法时的尴尬情况

## 安装

推荐使用 `install.sh` 自动完成克隆和初始化：

克隆后在本地运行（交互式）：
```sh
git clone https://github.com/realtvop/sbrc.git ~/sbrc
cd ~/sbrc
./install.sh
```

非交互式（默认安装到 `~/sbrc` 并自动应用）：
```sh
./install.sh -y
```

可选择通过网络直接运行（注意：从网络执行脚本会有安全风险）：
```sh
curl -fsSL https://raw.githubusercontent.com/realtvop/sbrc/main/install.sh | bash -s -- -y
```

如果需要指定安装目录或仓库分支：
```sh
./install.sh --dest ~/my_sbrc --repo https://github.com/realtvop/sbrc.git --branch main
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