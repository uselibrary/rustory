#!/bin/bash

# Rustory 一键安装脚本
# 适用于 Linux/macOS 系统

set -e

# 脚本版本
SCRIPT_VERSION="1.0.0"

# 项目信息
PROJECT_NAME="rustory"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="rustory"
GITHUB_REPO="uselibrary/rustory"
GITHUB_API_URL="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
Rustory 安装脚本 v${SCRIPT_VERSION}

用法: $0 [选项]

选项:
    install     安装或更新 rustory
    uninstall   卸载 rustory
    --help      显示此帮助信息
    --version   显示脚本版本

示例:
    $0 install      # 安装 rustory
    $0 uninstall    # 卸载 rustory

EOF
}

# 检查操作系统
check_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_info "检测到 Linux 系统"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "检测到 macOS 系统"
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
}

# 检查系统架构
check_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="x86_64"
            ;;
        aarch64|arm64)
            ARCH="aarch64"
            ;;
        *)
            log_error "不支持的系统架构: $ARCH"
            exit 1
            ;;
    esac
    log_info "检测到系统架构: $ARCH"
}

# 检查是否为 root 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "需要 root 权限来安装到 ${INSTALL_DIR}"
        log_info "请使用 sudo 运行此脚本: sudo $0 $1"
        exit 1
    fi
}

# 检查必要的软件
check_dependencies() {
    local deps=("curl" "tar" "gzip" "jq")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少必要的软件: ${missing_deps[*]}"
        log_info "请先安装这些软件:"
        
        if [[ "$OS" == "linux" ]]; then
            if command -v apt-get &> /dev/null; then
                log_info "  sudo apt-get update && sudo apt-get install -y ${missing_deps[*]}"
            elif command -v yum &> /dev/null; then
                log_info "  sudo yum install -y ${missing_deps[*]}"
            elif command -v dnf &> /dev/null; then
                log_info "  sudo dnf install -y ${missing_deps[*]}"
            elif command -v pacman &> /dev/null; then
                log_info "  sudo pacman -S ${missing_deps[*]}"
            fi
        elif [[ "$OS" == "macos" ]]; then
            if command -v brew &> /dev/null; then
                log_info "  brew install ${missing_deps[*]}"
            else
                log_info "  请安装 Homebrew 或手动安装这些软件"
            fi
        fi
        exit 1
    fi
}

# 获取当前安装的版本
get_installed_version() {
    if command -v "$BINARY_NAME" &> /dev/null; then
        local version_output
        version_output=$("$BINARY_NAME" --version 2>/dev/null || echo "")
        if [[ "$version_output" =~ rustory[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+) ]]; then
            echo "${BASH_REMATCH[1]}"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

# 从 GitHub API 获取最新版本
get_latest_version() {
    local response
    response=$(curl -s --connect-timeout 10 --max-time 30 "$GITHUB_API_URL" 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$response" ]]; then
        return 1
    fi
    
    # 检查是否有 jq
    if command -v jq &> /dev/null; then
        local version
        version=$(echo "$response" | jq -r '.tag_name // empty' 2>/dev/null)
        if [[ -n "$version" && "$version" != "null" ]]; then
            # 移除可能的 'v' 前缀
            version=${version#v}
            echo "$version"
            return 0
        fi
    fi
    
    # 如果没有 jq 或解析失败，使用简单的正则表达式
    local version
    version=$(echo "$response" | grep -o '"tag_name":"[^"]*"' | head -1 | sed 's/"tag_name":"//;s/"//')
    if [[ -n "$version" ]]; then
        # 移除可能的 'v' 前缀
        version=${version#v}
        echo "$version"
        return 0
    fi
    
    return 1
}

# 获取指定版本的下载链接
get_download_url() {
    local version="$1"
    local archive_name="$2"
    
    # 构建下载 URL
    echo "https://github.com/${GITHUB_REPO}/releases/download/v${version}/${archive_name}"
}

# 版本比较函数
version_compare() {
    local version1=$1
    local version2=$2
    
    if [[ "$version1" == "$version2" ]]; then
        return 0  # 相等
    fi
    
    local IFS=.
    local i ver1=($version1) ver2=($version2)
    
    # 填充版本号数组
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done
    
    # 比较版本号
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1  # version1 > version2
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2  # version1 < version2
        fi
    done
    return 0  # 相等
}

# 下载并安装 rustory
download_and_install() {
    local latest_version
    latest_version=$(get_latest_version)
    
    if [[ $? -ne 0 || -z "$latest_version" ]]; then
        log_error "无法获取最新版本信息"
        exit 1
    fi
    
    log_info "最新版本: $latest_version"
    
    local archive_name=""
    
    # 根据操作系统和架构确定下载文件名
    if [[ "$OS" == "linux" ]]; then
        if [[ "$ARCH" == "x86_64" ]]; then
            archive_name="rustory-x86_64-unknown-linux-musl.tar.gz"
        elif [[ "$ARCH" == "aarch64" ]]; then
            archive_name="rustory-aarch64-unknown-linux-musl.tar.gz"
        fi
    elif [[ "$OS" == "macos" ]]; then
        if [[ "$ARCH" == "x86_64" ]]; then
            archive_name="rustory-x86_64-apple-darwin.tar.gz"
        elif [[ "$ARCH" == "aarch64" ]]; then
            archive_name="rustory-aarch64-apple-darwin.tar.gz"
        fi
    fi
    
    if [[ -z "$archive_name" ]]; then
        log_error "不支持的系统配置: $OS-$ARCH"
        exit 1
    fi
    
    local download_url
    download_url=$(get_download_url "$latest_version" "$archive_name")
    
    log_info "正在下载 $archive_name..."
    log_debug "下载地址: $download_url"
    
    local temp_dir=$(mktemp -d)
    local archive_path="$temp_dir/$archive_name"
    
    # 下载文件
    if ! curl -L -o "$archive_path" "$download_url" --connect-timeout 10 --max-time 300; then
        log_error "下载失败"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 验证下载的文件
    if [[ ! -f "$archive_path" ]]; then
        log_error "下载的文件不存在"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 检查文件大小
    local file_size
    file_size=$(stat -c%s "$archive_path" 2>/dev/null || stat -f%z "$archive_path" 2>/dev/null || echo "0")
    if [[ "$file_size" -lt 1000 ]]; then
        log_error "下载的文件似乎不完整"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 解压文件
    log_info "正在解压..."
    if ! tar -xzf "$archive_path" -C "$temp_dir"; then
        log_error "解压失败"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 查找二进制文件
    local binary_path
    binary_path=$(find "$temp_dir" -name "$BINARY_NAME" -type f | head -1)
    
    if [[ -z "$binary_path" || ! -f "$binary_path" ]]; then
        log_error "在解压的文件中未找到可执行文件"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 安装二进制文件
    log_info "安装 $BINARY_NAME 到 $INSTALL_DIR..."
    cp "$binary_path" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
    
    # 创建软链接 rty -> rustory
    log_info "创建软链接 rty -> rustory..."
    local symlink_path="$INSTALL_DIR/rty"
    
    # 如果软链接已存在，先删除
    if [[ -L "$symlink_path" || -f "$symlink_path" ]]; then
        rm -f "$symlink_path"
    fi
    
    # 创建新的软链接
    if ln -s "$INSTALL_DIR/$BINARY_NAME" "$symlink_path"; then
        log_info "软链接创建成功: $symlink_path -> $INSTALL_DIR/$BINARY_NAME"
    else
        log_warn "软链接创建失败，但主程序安装成功"
    fi
    
    # 清理临时文件
    rm -rf "$temp_dir"
    
    log_info "安装完成！"
    return 0
}

# 安装函数
install_rustory() {
    log_info "开始安装 rustory..."
    
    # 获取最新版本
    log_info "正在获取最新版本信息..."
    local latest_version
    latest_version=$(get_latest_version)
    
    if [[ $? -ne 0 || -z "$latest_version" ]]; then
        log_error "无法获取最新版本信息"
        exit 1
    fi
    
    log_info "最新可用版本: $latest_version"
    
    # 检查是否已安装
    local installed_version
    installed_version=$(get_installed_version)
    
    if [[ -n "$installed_version" ]]; then
        log_info "检测到已安装版本: $installed_version，将强制安装最新版本 ($latest_version)..."
    else
        log_info "未检测到 rustory，开始安装最新版本 ($latest_version)..."
    fi
    
    download_and_install
    
    # 验证安装
    if command -v "$BINARY_NAME" &> /dev/null; then
        local new_version
        new_version=$("$BINARY_NAME" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        log_info "安装成功！版本: $new_version"
        log_info "使用 '$BINARY_NAME --help' 查看帮助信息"
        
        # 验证软链接
        if command -v "rty" &> /dev/null; then
            log_info "软链接 'rty' 也可正常使用"
        else
            log_warn "软链接 'rty' 验证失败，但主程序工作正常"
        fi
    else
        log_error "安装验证失败"
        exit 1
    fi
}

# 卸载函数
uninstall_rustory() {
    log_info "开始卸载 rustory..."
    
    if [[ ! -f "$INSTALL_DIR/$BINARY_NAME" ]]; then
        log_warn "rustory 未安装或不在预期位置"
        
        # 检查是否只有软链接存在
        local symlink_path="$INSTALL_DIR/rty"
        if [[ -L "$symlink_path" ]]; then
            log_info "发现孤立的软链接，将一并清理"
            rm -f "$symlink_path"
        fi
        
        return 0
    fi
    
    # 确认卸载
    read -p "确定要卸载 rustory 吗? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "取消卸载"
        return 0
    fi
    
    # 删除二进制文件
    rm -f "$INSTALL_DIR/$BINARY_NAME"
    
    # 删除软链接
    local symlink_path="$INSTALL_DIR/rty"
    if [[ -L "$symlink_path" ]]; then
        log_info "删除软链接: $symlink_path"
        rm -f "$symlink_path"
    fi
    
    if [[ ! -f "$INSTALL_DIR/$BINARY_NAME" ]]; then
        log_info "卸载完成！"
    else
        log_error "卸载失败"
        exit 1
    fi
}

# 主函数
main() {
    case "${1:-install}" in
        "install")
            check_os
            check_arch
            check_root "install"
            check_dependencies
            install_rustory
            ;;
        "uninstall")
            check_root "uninstall"
            uninstall_rustory
            ;;
        "--help"|"-h")
            show_help
            ;;
        "--version"|"-v")
            echo "Rustory 安装脚本 v${SCRIPT_VERSION}"
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"