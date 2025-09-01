#!/bin/bash
#
# 这是一个通用的 Bash 环境配置脚本，可以自动适配 root 或普通用户。
# 不再依赖特定的 Linux 发行版软件包管理器。
#
set -e

echo "=== 正在开始配置 Bash 环境 ==="
echo "脚本将自动备份你的 .bashrc 和 .bash_aliases"
echo "------------------------------"

cd ~

# 备份现有的 .bashrc 和 .bash_aliases
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
if [ -f "$HOME/.bashrc" ]; then
    mv "$HOME/.bashrc" "$HOME/.bashrc.bak_$TIMESTAMP"
    echo "✔ 备份 ~/.bashrc 为 ~/.bashrc.bak_$TIMESTAMP"
fi
if [ -f "$HOME/.bash_aliases" ]; then
    mv "$HOME/.bash_aliases" "$HOME/.bash_aliases.bak_$TIMESTAMP"
    echo "✔ 备份 ~/.bash_aliases 为 ~/.bash_aliases.bak_$TIMESTAMP"
fi
echo "------------------------------"

# --- 检查用户类型并设置安装逻辑 ---
if [[ "$EUID" -eq 0 ]]; then
    echo "▶ 检测到当前用户为 root。所有安装命令将直接运行。"
    SUDO=""
else
    echo "▶ 检测到当前为普通用户。安装命令将使用 sudo 运行。"
    SUDO="sudo"
    
    echo "▶ 正在配置 sudo 免密码..."
    CURRENT_USER=$(whoami)
    echo "$CURRENT_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-$CURRENT_USER > /dev/null
    echo "✔ sudo 免密码配置成功！"
fi
echo "------------------------------"

# --- 1. 安装 Oh-My-Bash ---
echo "▶ 正在安装 Oh-My-Bash..."
if [ ! -d "$HOME/.oh-my-bash" ]; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended
    echo "✔ Oh-My-Bash 安装成功！"
else
    echo "✔ Oh-My-Bash 已经安装，跳过安装。"
fi
echo "------------------------------"

# --- 2. 安装 Starship ---
echo "▶ 正在安装 Starship..."
if ! command -v starship &> /dev/null
then
    STARSHIP_INSTALL_YES=true curl -sS https://starship.rs/install.sh | sh
    echo "✔ Starship 安装成功！"
else
    echo "✔ Starship 已经安装，跳过安装。"
fi
echo "------------------------------"

# --- 3. 配置 Starship ---
echo "▶ 正在配置 Starship 预设..."
starship preset gruvbox-rainbow -o ~/.config/starship.toml
echo "✔ Starship 预设配置成功！"
echo "------------------------------"

# --- 4. 安装核心工具: Fzf, Zoxide, Ripgrep, eza, Bat ---
echo "▶ 正在安装核心工具 (zoxide, fzf, ripgrep, eza, bat)..."

# Zoxide
if ! command -v zoxide &> /dev/null; then
    echo "▶ 正在安装 zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    echo "✔ zoxide 安装成功。"
else
    echo "✔ zoxide 已经安装，跳过。"
fi

# Fzf
if ! command -v fzf &> /dev/null; then
    echo "▶ 正在安装 fzf..."
    mkdir -p ~/.fzf
    cd ~/.fzf
    yes "" | bash -c "$(curl -fsSL https://raw.githubusercontent.com/junegunn/fzf/master/install)"
    cd ~
    echo "✔ fzf 安装成功。"
else
    echo "✔ fzf 已经安装，跳过。"
fi

# eza
if ! command -v eza &> /dev/null; then
    echo "▶ 正在安装 eza..."
    # 使用 curl 和 tar 从 releases 下载
    mkdir -p /tmp/eza_install
    curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp/eza_install
    $SUDO mv /tmp/eza_install/eza /usr/local/bin/eza
    $SUDO chmod +x /usr/local/bin/eza
    $SUDO chown root:root /usr/local/bin/eza
    rm -rf /tmp/eza_install

    # 替换或创建 exa 的软连接
    if [ -f "/usr/local/bin/exa" ]; then
        $SUDO rm -f /usr/local/bin/exa
    fi
    $SUDO ln -s /usr/local/bin/eza /usr/local/bin/exa

    echo "✔ eza 安装成功。"
else
    echo "✔ eza 已经安装，跳过。"
fi

# Ripgrep
if ! command -v rg &> /dev/null; then
    echo "▶ 正在安装 ripgrep..."
    # 动态获取最新版本号
    RG_LATEST_VERSION=$(curl -sSL "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest" | grep "tag_name" | cut -d'"' -f4)
    if [ -z "$RG_LATEST_VERSION" ]; then
        echo "✖ 无法获取 ripgrep 最新版本号。请手动安装。"
        exit 1
    fi
    RG_URL="https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep-${RG_LATEST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    
    mkdir -p /tmp/ripgrep_install
    curl -fsSL "$RG_URL" | tar xz -C /tmp/ripgrep_install
    $SUDO mv /tmp/ripgrep_install/ripgrep-*/rg /usr/local/bin/
    $SUDO rm -rf /tmp/ripgrep_install

    echo "✔ ripgrep 安装成功。"
else
    echo "✔ ripgrep 已经安装，跳过。"
fi

# Bat
if ! command -v bat &> /dev/null; then
    echo "▶ 正在安装 bat..."
    # 动态获取最新版本号
    BAT_LATEST_VERSION=$(curl -sSL "https://api.github.com/repos/sharkdp/bat/releases/latest" | grep "tag_name" | cut -d'"' -f4)
    if [ -z "$BAT_LATEST_VERSION" ]; then
        echo "✖ 无法获取 ripgrep 最新版本号。请手动安装。"
        exit 1
    fi
    BAT_URL="https://github.com/sharkdp/bat/releases/latest/download/bat-${BAT_LATEST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    mkdir -p /tmp/bat_install
    curl -fsSL "$BAT_URL" | tar xz -C /tmp/bat_install
    $SUDO mv /tmp/bat_install/bat-*/bat /usr/local/bin/
    $SUDO rm -rf /tmp/bat_install

    echo "✔ bat 安装成功。"
else
    echo "✔ bat 已经安装，跳过。"
fi

echo "✔ 所有核心工具安装完毕。"
echo "------------------------------"

# --- 5. 下载并替换 .bashrc 和 .bash_aliases ---
echo "▶ 正在下载你的自定义点文件 (.bashrc & .bash_aliases)..."
curl -sSL https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/.bashrc -o "$HOME/.bashrc"
curl -sSL https://raw.githubusercontent.com/eallion/dotfile/refs/heads/main/.bash_aliases -o "$HOME/.bash_aliases"
echo "✔ 自定义点文件下载并替换成功！"
echo "------------------------------"

echo "=== 配置完成！==="
echo "请重启你的终端或运行 'source ~/.bashrc' 以应用所有更改。"