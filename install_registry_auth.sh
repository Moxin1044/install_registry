#!/bin/bash

set -e

# 设置镜像源
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

# 卸载旧 Docker
echo "卸载旧版本 Docker..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y "$pkg" || true
done

# 安装 Docker
echo "安装 Docker..."
sudo apt install -y ca-certificates curl gnupg apache2-utils
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu noble stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 配置 Docker 镜像加速器
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

# 部署带认证的 Registry
echo "部署带认证的 Docker 私有仓库..."

REGISTRY_AUTH_DIR="/opt/registry/auth"
sudo mkdir -p "$REGISTRY_AUTH_DIR"

USERNAME="admin"
PASSWORD=$(openssl rand -base64 12)

echo "生成随机密码：$PASSWORD"

# 创建 htpasswd 文件
sudo htpasswd -Bbn "$USERNAME" "$PASSWORD" | sudo tee "$REGISTRY_AUTH_DIR/htpasswd" > /dev/null

# 创建存储目录
sudo mkdir -p /opt/registry/data

# 启动 Registry 容器
sudo docker rm -f registry >/dev/null 2>&1 || true
sudo docker run -d \
  --name registry \
  -p 5000:5000 \
  -v /opt/registry/data:/var/lib/registry \
  -v "$REGISTRY_AUTH_DIR:/auth" \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
  --restart unless-stopped \
  registry:2

LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "私有仓库已部署：$LOCAL_IP:5000（需身份认证）"

# 提示客户端配置
cat <<EOF

=====================================
✅ 客户端配置指引：

1. 编辑 /etc/docker/daemon.json 添加：
{
  ...
  "insecure-registries": ["$LOCAL_IP:5000"]
}

2. 重启 Docker：
   sudo systemctl restart docker

3. 登录私有仓库：
   docker login http://$LOCAL_IP:5000
   用户名：$USERNAME
   密码：$PASSWORD

4. 上传镜像示例：
   docker tag your-image $LOCAL_IP:5000/your-image
   docker push $LOCAL_IP:5000/your-image

=====================================
✅ 用户名：admin
✅ 密码：$PASSWORD
=====================================

EOF

echo "安装与配置完成！"
