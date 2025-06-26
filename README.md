# Docker Registry 自动化安装脚本
这个仓库提供了一个简单的 Bash 脚本来自动化安装和配置一个私有 Docker Registry（镜像仓库），适合用于本地开发、测试或私有部署。
# 📥 项目简介
该脚本会自动完成以下操作：
- 安装必要的依赖
- 创建用于存储镜像的本地目录
- 配置默认自启动
# 🛠️ 使用方式
## 1. 直接运行远程脚本安装
你可以直接使用以下命令来运行远程脚本进行安装：
```bash
curl -O https://raw.githubusercontent.com/Moxin1044/install_registry/refs/heads/main/install_registry.sh
chmod +x install_registry.sh
sudo ./install_registry.sh
```
或者一行命令执行：
```bash
curl -sSL https://raw.githubusercontent.com/Moxin1044/install_registry/refs/heads/main/install_registry.sh | sudo bash
```
## 2. 可选参数
目前脚本默认使用以下设置：

- 端口：`5000`
- 存储路径：`/opt/registry/data`

如需自定义，请参考脚本内容并修改相关变量部分。
# 🧹 卸载
要卸载 Docker Registry，可以运行以下命令：
```bash
docker stop registry && docker rm registry
sudo rm -rf /opt/registry
```