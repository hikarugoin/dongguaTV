#!/bin/bash
# 一键部署 dongguaTV on Debian
# 作者: ChatGPT
# 用法: sudo bash deploy_dongguaTV.sh

# ==========================
# 配置部分
# ==========================
DOMAIN="donggua.hikarugoin.dynv6.net"
PROJECT_DIR="/opt/dongguaTV"
PORT=3000
TMDB_API_KEY="9e6642a0e7c7d18289407452f461e988"

# ==========================
# 更新系统 & 安装依赖
# ==========================
echo "更新系统并安装依赖..."
apt update && apt upgrade -y
apt install -y git curl build-essential nginx certbot python3-certbot-nginx

# 安装 Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs
echo "Node.js 版本: $(node -v), npm 版本: $(npm -v)"

# 安装 pm2
npm install -g pm2

# ==========================
# 克隆项目 & 安装依赖
# ==========================
echo "部署项目到 $PROJECT_DIR ..."
if [ -d "$PROJECT_DIR" ]; then
    echo "项目目录已存在，拉取最新代码..."
    cd "$PROJECT_DIR"
    git pull
else
    git clone https://github.com/hikarugoin/dongguaTV.git "$PROJECT_DIR"
    cd "$PROJECT_DIR"
fi

echo "安装项目依赖..."
npm install

# ==========================
# 配置环境变量
# ==========================
echo "配置环境变量..."
cat > "$PROJECT_DIR/.env" <<EOL
TMDB_API_KEY=$TMDB_API_KEY
PORT=$PORT
HOST=0.0.0.0
EOL

# ==========================
# 使用 PM2 启动项目并自启动
# ==========================
echo "启动项目并设置自启动..."
pm2 start npm --name "dongguaTV" -- start
pm2 save
pm2 startup systemd -u $USER --hp $HOME

# ==========================
# 配置 Nginx 反向代理
# ==========================
echo "配置 Nginx..."
cat > /etc/nginx/sites-available/dongguaTV <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

ln -sf /etc/nginx/sites-available/dongguaTV /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# ==========================
# 配置 HTTPS (可选)
# ==========================
echo "尝试获取 HTTPS 证书..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

echo "部署完成！"
echo "访问: http://$DOMAIN 或 https://$DOMAIN"
pm2 status
