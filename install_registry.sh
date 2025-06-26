# 服务器端配置脚本
#!/bin/bash

set -e

# 设置镜像源（可根据需要更换）
echo "配置国内APT源..."
cat <<EOF | sudo tee /etc/apt/sources.list
deb https://mirrors.cernet.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.cernet.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.cernet.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb https://mirrors.cernet.edu.cn/ubuntu/ noble-security main restricted universe multiverse
EOF

# 更新系统
echo "更新系统依赖..."
sudo apt update
sudo apt upgrade -y

# 卸载可能冲突的软件包
echo "卸载已安装的旧版本Docker..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y "$pkg" || true
done

# 安装Docker依赖和Docker
echo "安装Docker..."
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu noble stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 配置镜像加速器
echo "配置 Docker 镜像加速器..."
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.1panel.live",
    "https://docker.ketches.cn"
  ]
}
EOF

sudo systemctl daemon-reexec
sudo systemctl restart docker

# 部署私有仓库
echo "部署本地 Docker 仓库..."
sudo mkdir -p /opt/registry/data
sudo docker run -d \
  --name registry \
  -p 5000:5000 \
  -v /opt/registry/data:/var/lib/registry \
  registry:2

echo "仓库已部署，监听地址为 0.0.0.0:5000"
# 获取本机内网 IP 地址
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "检测到内网 IP 地址为: $LOCAL_IP"


# 提示客户端配置
cat <<EOF

# 提示客户端配置
cat <<EOF

客户端配置：
1. 编辑 /etc/docker/daemon.json 添加以下字段：
{
  ...
  "insecure-registries": ["$LOCAL_IP:5000"]
}
2. 重启 Docker：
   sudo systemctl restart docker

3. 登录（随便输用户名密码）：
   docker login http://$LOCAL_IP:5000

4. 上传镜像前需要打标签：
   docker tag your-image-name $LOCAL_IP:5000/your-image-name
   docker push $LOCAL_IP:5000/your-image-name

EOF


echo "安装与配置完成！"