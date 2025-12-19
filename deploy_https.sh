#!/bin/bash
# 一键部署冬瓜TV + PM2 + Nginx + HTTPS

read -p "请输入你的域名 (如 tv.example.com)：" DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "域名不能为空，脚本退出"
  exit 1
fi

# 1️⃣ 更新系统 & 安装依赖
apt update -y
apt install -y curl git build-essential nginx certbot python3-certbot-nginx ufw

# 2️⃣ 安装 Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# 3️⃣ 安装 PM2
npm install -g pm2

# 4️⃣ 克隆或更新冬瓜TV项目
if [ -d "$HOME/dongguaTV" ]; then
  echo "dongguaTV 目录已存在，拉取最新代码..."
  cd "$HOME/dongguaTV" && git pull
else
  git clone https://github.com/hikarugoin/dongguaTV.git "$HOME/dongguaTV"
  cd "$HOME/dongguaTV"
fi

# 5️⃣ 安装依赖
npm install

# 6️⃣ 启动 Node 服务并用 PM2 管理
pm2 start server.js --name dongguaTV
pm2 save
pm2 startup systemd -u $USER --hp $HOME | tail -n 1 | bash

# 7️⃣ 配置防火墙
ufw allow 'Nginx Full'
ufw allow 3000
ufw --force enable

# 8️⃣ 配置 Nginx 反向代理
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
cat > $NGINX_CONF <<EOL
server {
    listen 80;
    server_name $DOMAIN;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# 9️⃣ 自动申请 HTTPS
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

# 10️⃣ 提示用户配置 TMDb API Key
echo ""
echo "⚠️ 请编辑 public/index.html，将 TMDb API Key 替换为你自己的："
echo "   const TMDB_API_KEY = \"你的_TMDB_API_KEY\";"
echo "然后执行： pm2 restart dongguaTV"
echo ""
echo "部署完成！现在可以通过 https://$DOMAIN 访问冬瓜TV"
