#!/bin/bash

# 1️⃣ 更新系统
sudo apt update -y
sudo apt install -y curl git build-essential

# 2️⃣ 安装 Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 3️⃣ 安装 PM2
sudo npm install -g pm2

# 4️⃣ 克隆冬瓜TV仓库（如果存在则更新）
if [ -d "$HOME/dongguaTV" ]; then
  echo "dongguaTV 目录已存在，拉取最新代码..."
  cd "$HOME/dongguaTV" && git pull
else
  git clone https://github.com/hikarugoin/dongguaTV.git "$HOME/dongguaTV"
  cd "$HOME/dongguaTV"
fi

# 5️⃣ 安装依赖
npm install

# 6️⃣ 启动服务并用 PM2 管理
pm2 start server.js --name dongguaTV
pm2 save
pm2 startup systemd -u $USER --hp $HOME | tail -n 1 | bash

# 7️⃣ 提示用户配置 TMDb API Key
echo ""
echo "⚠️ 请编辑 public/index.html，将 TMDb API Key 替换为你自己的："
echo "   const TMDB_API_KEY = \"你的_TMDB_API_KEY\";"
echo ""
echo "部署完成！服务已后台运行，访问 http://服务器IP:3000"
echo "使用 pm2 list 查看状态，pm2 logs dongguaTV 查看日志"
