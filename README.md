# Rustory

> 🚀 **轻量级本地版本管理工具** - 用 Rust 编写的高性能版本控制系统

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Rust](https://img.shields.io/badge/rust-1.70+-orange.svg)](https://www.rust-lang.org)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)](https://github.com/uselibrary/rustory)

## ✨ 项目简介

Rustory 是一个基于 Rust 的版本控制工具，旨在帮助开发者轻松管理项目的快照、历史记录和配置。它提供了类似于 Git 的功能，但更专注于简单易用性。Rustory 是一款轻量级本地版本管理工具，支持 Linux、macOS 和 Windows 等多平台，无需依赖外部命令或脚本解释器，即可跟踪、快照和还原项目文件变更。

> **重要说明**: Rustory 是一个专注于本地版本管理的工具，**不是 Git 的替代品**。它主要面向个人开发者和简单项目的版本控制需求，不支持分布式开发、远程仓库、分支合并等高级功能。如果您需要团队协作、开源项目管理或复杂的版本控制工作流，我们建议继续使用 Git。

### 🎯 设计目标
- **本地优先**: 专为个人开发者和脚本作者设计，无需分布式协作
- **轻量高效**: 纯 Rust 实现，无外部依赖，启动快速
- **简单易用**: 直观的命令行界面，快速上手
- **存储优化**: 内容去重 + 压缩存储，节省磁盘空间

### 🏗️ 核心特性
- ✅ **快照管理**: 快速创建和恢复项目快照
- ✅ **差异比较**: 智能的文件差异检测和显示
- ✅ **标签系统**: 为重要快照添加描述性标签
- ✅ **忽略规则**: Git 风格的文件忽略模式
- ✅ **垃圾回收**: 自动清理过期数据，优化存储空间
- ✅ **完整性验证**: 数据完整性检查和修复
- ✅ **丰富统计**: 详细的仓库使用统计信息

## 📦 安装指南

### 方式一：下载预编译二进制文件 (推荐)

从 [GitHub Releases](https://github.com/uselibrary/rustory/releases) 页面下载适合您系统的预编译二进制文件：

#### 支持的平台
- **Windows**: x64、ARM64
- **macOS**: x64 (Intel)、ARM64 (Apple Silicon)
- **Linux**: x64、ARM64

#### 下载和校验
1. 访问 [最新发布页面](https://github.com/uselibrary/rustory/releases/latest)
2. 根据您的系统选择相应的文件：
   - Windows: `rustory-x86_64-pc-windows-msvc.zip` 或 `rustory-aarch64-pc-windows-msvc.zip`
   - macOS: `rustory-x86_64-apple-darwin.tar.gz` 或 `rustory-aarch64-apple-darwin.tar.gz`
   - Linux: `rustory-x86_64-unknown-linux-gnu.tar.gz` 或 `rustory-aarch64-unknown-linux-gnu.tar.gz`

3. **文件完整性校验** (推荐)：
   ```bash
   # macOS/Linux
   shasum -a 256 rustory-*.tar.gz
   
   # Windows (PowerShell)
   Get-FileHash -Algorithm SHA256 rustory-*.zip
   ```
   对比下载页面提供的 SHA256 值确保文件完整性。

4. **解压并安装**：
   ```bash
   # Linux/macOS
   tar -xzf rustory-*.tar.gz
   sudo mv rustory /usr/local/bin/
   
   # Windows: 解压 ZIP 文件，将 rustory.exe 移动到 PATH 中的目录
   ```

### 方式二：从源码编译

#### 前置要求
- **Rust 版本**: 1.70 或更高
- **操作系统**: Linux、macOS 或 Windows

#### 编译步骤

1. **确保已安装 Rust 环境**
   ```bash
   # 安装 Rust (如果尚未安装)
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **克隆并构建项目**
   ```bash
   git clone https://github.com/uselibrary/rustory/releases.git
   cd rustory
   cargo build --release
   ```

3. **安装到系统路径 (可选)**
   ```bash
   # Linux/macOS
   sudo cp target/release/rustory /usr/local/bin/
   
   # Windows - 添加到 PATH 环境变量
   copy target\release\rustory.exe C:\Windows\System32\
   ```

4. **验证安装**
   ```bash
   rustory --version
   ```

## 🏛️ 系统架构

### 存储结构
Rustory 在工作目录下创建 `.rustory` 文件夹，包含以下内容：

```
.rustory/
├── config.toml           # 用户配置：忽略规则、输出格式、备份策略等
├── ignore                # 忽略规则文件（Git 样式）
├── objects/              # 按 SHA-1 哈希存储内容
│   ├── ab/               # 使用哈希前两位作为子目录
│   │   └── cdef123...    # 压缩的文件内容
│   └── ...
├── index.json            # 当前工作区文件与哈希映射
├── history.log           # 快照日志：ID、时间、改动统计、备注
└── snapshots/            # 快照元数据 JSON 文件
    ├── abc123.json
    └── ...
```

### 核心概念

1. **对象存储**: 将文件内容写为二进制对象，文件名为其 SHA-1 哈希，实现内容去重
2. **索引管理**: 记录工作区文件路径与对应哈希，用于快速检测变更
3. **快照系统**: 保存一次索引状态，元数据存于 `snapshots/`，并记录在 `history.log`
4. **压缩存储**: 使用 gzip 压缩算法减少存储空间占用

### 存储优化
- **去重存储**: 相同内容的文件只存储一份
- **压缩算法**: 所有对象使用 gzip 压缩
- **目录分散**: 使用哈希前缀避免单目录文件过多
- **大文件限制**: 可配置的文件大小上限，默认 100MB

## 🚀 快速开始

### 初始化项目
```bash
# 在当前目录初始化
rustory init

# 在指定目录初始化
rustory init /path/to/project
```

### 基本工作流
```bash
# 1. 查看当前状态
rustory status

# 2. 创建快照
rustory commit -m "初始版本"

# 3. 查看历史
rustory history

# 4. 比较差异
rustory diff

# 5. 回滚更改
rustory rollback abc123
```

## 📋 命令详解

### 核心命令

#### `rustory init` - 初始化仓库
```bash
rustory init [path]
```
- **功能**: 创建新的 Rustory 仓库
- **参数**: `[path]` - 可选，指定初始化路径，默认当前目录
- **效果**: 创建 `.rustory` 目录结构，生成默认配置

#### `rustory commit` - 创建快照
```bash
rustory commit -m "提交信息" [--json]
```
- **功能**: 保存当前工作目录状态为新快照
- **参数**: 
  - `-m, --message <MSG>` - 快照描述信息
  - `--json` - 以 JSON 格式输出结果
- **示例**:
  ```bash
  rustory commit -m "修复解析器错误"
  # 输出: [snapshot ab12cd] 2025-06-18T15:30:00  added=2 modified=1 deleted=0
  ```

#### `rustory status` - 查看状态
```bash
rustory status [--verbose] [--json]
```
- **功能**: 显示工作目录相对于最新快照的变更
- **参数**:
  - `--verbose` - 显示详细信息（文件大小、修改时间）
  - `--json` - JSON 格式输出
- **示例输出**:
  ```
  已修改: src/lib.rs (1.2KB)
  已新增: tests/test_api.rs (0.8KB)
  已删除: docs/old.md
  ```

#### `rustory history` - 查看历史
```bash
rustory history [--json]
```
- **功能**: 显示所有快照的历史记录
- **示例输出**:
  ```
  ID       时间                     +  ~  -  消息
  ab12cd   2025-06-18T15:30:00      2  1  0  "修复解析器错误"
  ef34gh   2025-06-17T10:15:30      5  0  2  "添加新功能"
  ```

#### `rustory diff` - 比较差异
```bash
rustory diff [snapshot1] [snapshot2]
```
- **功能**: 显示文件差异
- **用法**:
  - 无参数: 当前状态与最新快照比较
  - 一个参数: 指定快照与当前状态比较
  - 两个参数: 两个快照之间比较
- **输出**: 彩色的行级差异显示

#### `rustory rollback` - 回滚更改
```bash
rustory rollback <snapshot_id> [--restore] [--keep-index]
```
- **功能**: 恢复到指定快照状态
- **参数**:
  - `<snapshot_id>` - 目标快照 ID 或标签
  - `--restore` - 直接恢复到工作目录（先备份当前状态）
  - `--keep-index` - 不更新索引文件
- **安全机制**: 默认导出到 `backup-<timestamp>/` 目录

### 管理命令

#### `rustory tag` - 标签管理
```bash
rustory tag <tag_name> <snapshot_id>
```
- **功能**: 为快照添加描述性标签
- **示例**: 
  ```bash
  rustory tag v1.0 ab12cd
  rustory rollback v1.0  # 使用标签回滚
  ```

#### `rustory ignore` - 忽略规则
```bash
rustory ignore [show|edit]
```
- **功能**: 管理文件忽略规则
- **规则格式**: 支持 Git 风格的 glob 模式
- **示例规则**:
  ```
  *.log
  temp/
  node_modules/
  target/
  ```

#### `rustory config` - 配置管理
```bash
rustory config get <key>           # 获取配置
rustory config set <key> <value>   # 设置配置
```
- **常用配置项**:
  - `output_format`: 输出格式 (table/json)
  - `max_file_size_mb`: 文件大小限制 (默认 100MB)
  - `gc_keep_days`: GC 保留天数 (默认 30 天)
  - `gc_keep_snapshots`: GC 保留快照数 (默认 50 个)
  - `gc_auto_enabled`: 自动 GC 开关 (默认 false)

### 工具命令

#### `rustory gc` - 垃圾回收
```bash
rustory gc [--dry-run] [--aggressive] [--prune-expired]
```
- **功能**: 清理不需要的对象和过期快照
- **参数**:
  - `--dry-run`: 预览模式，显示将删除的内容
  - `--aggressive`: 执行更激进的优化：
    - 对象重新压缩和重复检测
    - 深度碎片和临时文件清理
    - 索引文件优化和冗余条目清理
    - 快照分析和优化建议
    - 存储结构重组和空目录清理
  - `--prune-expired`: 包含过期快照清理
- **清理策略**: 基于配置的时间和数量限制

#### `rustory stats` - 统计信息
```bash
rustory stats [--json]
```
- **功能**: 显示仓库详细统计
- **包含信息**:
  - 仓库大小和压缩比
  - 文件类型分布
  - 快照数量和对象数量
  - 存储使用情况

#### `rustory verify` - 完整性验证
```bash
rustory verify [--fix]
```
- **功能**: 验证仓库数据完整性
- **检查项目**:
  - 快照文件格式验证
  - 对象文件可读性检查
  - 索引一致性验证
- **参数**: `--fix` - 尝试修复发现的问题

## 🔧 高级功能

### 垃圾回收策略

Rustory 提供灵活的垃圾回收机制来管理存储空间：

```bash
# 配置保留策略
rustory config set gc_keep_days 14      # 保留 14 天内的快照
rustory config set gc_keep_snapshots 20 # 最多保留 20 个快照

# 启用自动垃圾回收
rustory config set gc_auto_enabled true

# 手动运行垃圾回收
rustory gc --dry-run    # 预览清理内容
rustory gc              # 执行清理
```

### 批量操作

```bash
# 批量提交多个更改
find . -name "*.rs" -newer .rustory/index.json | rustory commit -m "批量更新"

# 基于模式的快照清理
rustory gc --prune-expired --pattern "temp-*"
```

### 配置优化

```bash
# 性能优化配置
rustory config set max_file_size_mb 50          # 限制大文件
rustory config set compression_level 6          # 调整压缩级别
rustory config set parallel_threads 4           # 并行处理线程数

# 输出格式配置
rustory config set output_format json           # 默认 JSON 输出
rustory config set colored_output true          # 彩色输出
```

## 🔍 故障排除

### 常见问题

#### 快照创建失败
```bash
# 检查磁盘空间
df -h .

# 检查文件权限
ls -la .rustory/

# 验证忽略规则
rustory ignore show

# 检查大文件
rustory status --verbose | grep "large"
```

#### 回滚冲突
```bash
# 保存当前工作后回滚
rustory commit -m "临时保存"
rustory rollback <target_snapshot>

# 或使用备份模式
rustory rollback <target_snapshot> --restore
```

#### 存储空间问题
```bash
# 检查仓库统计
rustory stats

# 运行垃圾回收
rustory gc --dry-run
rustory gc --prune-expired

# 清理大文件历史
rustory config set max_file_size_mb 10
rustory gc --aggressive
```

### 数据恢复

如果遇到数据损坏：

```bash
# 验证仓库完整性
rustory verify

# 尝试自动修复
rustory verify --fix

# 手动恢复（最后手段）
cp .rustory/snapshots/*.json backup/
rustory init --force
```

## 🚀 性能优化

### 存储优化建议

1. **定期垃圾回收**
   ```bash
   # 设置自动清理
   rustory config set gc_auto_enabled true
   rustory config set gc_keep_days 30
   ```

2. **文件大小限制**
   ```bash
   # 避免跟踪大文件
   rustory config set max_file_size_mb 50
   ```

3. **忽略规则优化**
   ```bash
   # 排除构建产物和临时文件
   echo "target/" >> .rustory/ignore
   echo "*.tmp" >> .rustory/ignore
   echo "node_modules/" >> .rustory/ignore
   ```

### 性能监控

```bash
# 查看操作耗时
time rustory commit -m "性能测试"

# 监控存储使用
rustory stats | grep "Size"

# 检查压缩效率
rustory stats | grep "Compression"
```

## 🛠️ 集成与扩展

### 编辑器集成

#### VS Code
```json
// settings.json
{
  "rustory.autoCommit": true,
  "rustory.commitInterval": 3600,
  "rustory.showStatus": true
}
```

#### Vim
```vim
" .vimrc
autocmd BufWritePost * silent! !rustory commit -m "Auto save"
```

### CI/CD 集成

#### GitHub Actions
```yaml
name: Rustory Snapshot
on: [push]
jobs:
  snapshot:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Create snapshot
        run: |
          rustory init
          rustory commit -m "CI Build ${{ github.run_number }}"
```

#### Shell 脚本集成
```bash
#!/bin/bash
# 自动化部署脚本
set -e

echo "创建部署前快照..."
rustory commit -m "Pre-deploy snapshot $(date)"

echo "执行部署..."
./deploy.sh

echo "创建部署后快照..."
rustory commit -m "Post-deploy snapshot $(date)"
```

## 🎯 与其他工具对比

### Rustory vs Git - 关键区别

**Rustory 不是 Git 的替代品**，两者有本质上的不同定位：

#### 🎯 设计哲学差异
- **Rustory**: 专注于**本地快照管理**，为个人开发者提供简单直观的版本控制
- **Git**: 设计为**分布式版本控制系统**，支持复杂的团队协作和项目管理

#### 🔧 功能对比

| 功能特性 | Rustory | Git | 适用场景 |
|----------|---------|-----|----------|
| **本地快照** | ✅ 优化 | ✅ 支持 | 个人项目版本管理 |
| **启动速度** | ✅ 极快 | ⚠️ 较慢 | 频繁的小改动跟踪 |
| **学习成本** | ✅ 极低 | ❌ 较高 | 版本控制入门 |
| **存储效率** | ✅ 高度优化 | ✅ 良好 | 磁盘空间敏感环境 |
| **二进制文件** | ✅ 原生支持 | ⚠️ 有限支持 | 多媒体文件管理 |
| **远程仓库** | ❌ 不支持 | ✅ 核心功能 | 团队协作开发 |
| **分支管理** | ❌ 不支持 | ✅ 强大 | 复杂功能开发 |
| **合并冲突** | ❌ 不涉及 | ✅ 完整支持 | 多人并行开发 |
| **提交历史** | ✅ 线性历史 | ✅ 有向无环图 | 项目历史追踪 |
| **标签系统** | ✅ 简单标签 | ✅ 带签名标签 | 版本发布管理 |

#### 🚀 Rustory 的优势场景
- **个人项目**: 脚本、配置文件、文档的版本管理
- **快速原型**: 实验性代码的快照保存
- **学习环境**: 版本控制概念的学习和实践
- **轻量需求**: 不需要复杂工作流的小型项目
- **二进制文件**: 图片、视频、数据文件的版本跟踪

#### 💼 Git 的优势场景
- **团队协作**: 多人同时开发同一项目
- **开源项目**: 社区贡献和代码审查
- **企业开发**: 复杂的分支策略和发布流程
- **CI/CD集成**: 与 GitHub、GitLab 等平台深度集成
- **代码审查**: Pull Request 和 Merge Request 工作流

### 使用建议

#### 🎯 何时选择 Rustory
```bash
# 个人脚本版本管理
cd ~/scripts
rustory init
rustory commit -m "添加备份脚本"

# 配置文件快照
cd ~/.config
rustory init
rustory commit -m "系统配置基线"

# 快速实验原型
cd ~/experiments/ml-model
rustory init
rustory commit -m "初始模型版本"
```

#### 🎯 何时选择 Git
```bash
# 团队项目开发
git clone https://github.com/team/project.git
git checkout -b feature/new-api
git commit -m "实现新API接口"
git push origin feature/new-api

# 开源贡献
git fork https://github.com/opensource/project.git
git commit -m "修复内存泄漏问题"
git pull-request
```

#### 🔄 两者可以共存
在某些情况下，您可以在同一项目中同时使用两个工具：
```bash
# 使用 Git 进行主要的版本控制
git commit -m "完成新功能开发"

# 使用 Rustory 进行频繁的本地快照
rustory commit -m "临时保存：调试中间状态"
```

### 迁移指南

#### 从 Git 迁移到 Rustory
适用于不再需要远程协作的项目：
```bash
# 导出 Git 历史快照
git log --oneline | while read commit; do
    git checkout $commit
    rustory commit -m "迁移：$commit"
done
```

#### 从 Rustory 迁移到 Git
当项目需要扩展到团队协作时：
```bash
# 初始化 Git 仓库
git init

# 基于 Rustory 快照创建初始提交
rustory rollback <latest_snapshot> --restore
git add .
git commit -m "从 Rustory 迁移的初始版本"
```

| 工具 | 最佳使用场景 | 学习难度 | 性能 | 协作支持 |
|------|-------------|----------|------|----------|
| **Rustory** | 个人项目、快速原型 | ⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ |
| **Git** | 团队开发、开源项目 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **SVN** | 企业集中式开发 | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |

## 📈 项目路线图

### 当前版本 (v0.1.3)
- ✅ 核心版本控制功能
- ✅ 基础存储优化
- ✅ 垃圾回收机制
- ✅ 配置系统

### 下一版本 (v0.2.0)
- 🚧 并行处理优化
- 🚧 增量备份功能

### 未来版本
- 📋 同步支持
- 📋 API 接口
- 📋 插件系统基础



### 开发环境设置
```bash
# 克隆仓库
git clone https://github.com/uselibrary/rustory.git
cd rustory

# 安装开发依赖
cargo install cargo-watch
cargo install cargo-tarpaulin

# 运行测试
cargo test

# 代码格式化
cargo fmt

# 代码检查
cargo clippy
```

### 代码规范
- 使用 `rustfmt` 格式化代码
- 通过 `clippy` 检查代码质量
- 为新功能添加测试
- 更新相关文档

## 📄 许可证

本项目采用 [GNU General Public License v3.0](LICENSE) 许可证。

## 🙏 致谢

感谢以下优秀的 Rust 库使项目成为可能：
- [clap](https://crates.io/crates/clap) - 命令行参数解析
- [serde](https://crates.io/crates/serde) - 序列化/反序列化
- [walkdir](https://crates.io/crates/walkdir) - 目录遍历
- [flate2](https://crates.io/crates/flate2) - 压缩算法
- [sha1](https://crates.io/crates/sha1) - 哈希计算
- [chrono](https://crates.io/crates/chrono) - 时间处理
- [colored](https://crates.io/crates/colored) - 彩色输出

---

<div align="center">

**[⬆ 回到顶部](#rustory)**

Made with ❤️ by the Rustory Team
