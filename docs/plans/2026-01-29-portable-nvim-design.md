# Portable Neovim All-in-One 设计文档

## 概述

创建一个便携式 Neovim 配置，用于客户场景。目标是携带自己的 nvim 0.11.4 二进制和一个独立的 init.lua，无需任何插件依赖，在任何环境下获得完美的编辑体验。

## 需求

- 混合编辑需求：代码、配置文件、日志、文本处理
- 极简文件结构：nvim 二进制 + init.lua + 启动脚本
- 终端兼容：自动检测 true color / 256 色，两种都要支持
- 功能完整：尽量复刻现有配置中不依赖插件的功能
- 环境隔离：不污染客户的 vim/nvim 配置

## 文件结构

```
nvim                  # 0.11.4 二进制（用户自备）
init.lua              # all-in-one 配置
pnvim                 # 启动脚本
```

## 启动方式

### 启动脚本 pnvim

```bash
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
NVIM_APPNAME=pnvim exec "$DIR/nvim" --clean -u "$DIR/init.lua" "$@"
```

### 使用方式

```bash
./pnvim file.txt
./pnvim -d file1 file2        # diff 模式
./pnvim -p *.conf             # 多 tab 打开
./pnvim -O log1.txt log2.txt  # 垂直分屏
```

## 技术设计

### 1. 终端颜色检测

```lua
local function has_truecolor()
  local term = vim.env.TERM or ""
  local colorterm = vim.env.COLORTERM or ""
  if colorterm:match("truecolor") or colorterm:match("24bit") then
    return true
  end
  if term:match("256color") or term:match("kitty") or term:match("alacritty") then
    return true
  end
  return false
end
```

- True color 支持时：启用 termguicolors，使用内嵌 onedark 配色
- 256 色时：使用 nvim 内置配色方案（habamax 或 slate）

### 2. 基础选项

从现有 options.lua 提取：

- `number = true` 行号
- `cursorline = true` 当前行高亮
- `expandtab = true, shiftwidth = 4, tabstop = 4` 缩进
- `smartindent = true` 智能缩进
- `ignorecase = true, smartcase = true` 智能搜索
- `signcolumn = "yes"` 符号列
- `splitbelow = true, splitright = true` 分屏方向
- `mouse = ""` 禁用鼠标
- `wrap = false` 禁用换行
- `timeoutlen = 400, updatetime = 250`

额外的便携场景选项：

- `swapfile = false` 禁用 swap（避免在客户环境留下文件）
- `undofile` 条件启用（仅当目录可写）

### 3. 纯 Lua 状态栏

显示格式：
```
 NORMAL │ init.lua [+] │ lua │ utf-8 │ 42:15 │ 75%
```

组件：
- 模式指示（带颜色区分）
- 文件名 + 修改标记
- 文件类型
- 编码
- 行:列
- 百分比位置

### 4. 注释切换功能

快捷键：
- `gcc` 切换当前行注释
- `gc{motion}` 切换区域注释（如 `gcip` 注释段落）
- Visual 模式 `gc` 注释选中区域

支持的注释格式：
- `//` - c, cpp, java, javascript, typescript, go, rust
- `#` - python, ruby, bash, sh, zsh, yaml, toml
- `--` - lua, sql, haskell
- `"` - vim
- `;` - lisp, clojure, asm
- `%` - tex, matlab

### 5. 自动括号配对

配对字符：`()`, `[]`, `{}`, `""`, `''`, ` `` `

行为：
- 输入开括号自动补闭括号，光标在中间
- 输入闭括号时，如果下一个字符就是该闭括号，跳过而非插入
- Backspace 删除开括号时，如果后面紧跟闭括号，一起删除

### 6. 增强文本对象

- `ii` / `ai` - 相同缩进块（inner/around）
- `ie` / `ae` - 整个文件

### 7. 快捷键映射

Leader 键：`\`（保持 nvim 默认）

基础操作：
- `<leader>w` 保存
- `<leader>q` 退出
- `<leader>h` 清除搜索高亮

Buffer 操作：
- `<leader>bn` 下一个 buffer
- `<leader>bp` 上一个 buffer
- `<leader>bd` 删除 buffer

窗口导航：
- `<C-h>` 左窗口
- `<C-j>` 下窗口
- `<C-k>` 上窗口
- `<C-l>` 右窗口

Tab 操作：
- `<leader>tn` 新 tab
- `<leader>tc` 关闭 tab
- `<leader>to` 只保留当前 tab

### 8. 内嵌 Onedark 配色

简化版 onedark 配色，约 50 个 highlight 定义，覆盖：
- 基础语法（Comment, String, Number, Keyword 等）
- UI 元素（StatusLine, CursorLine, LineNr 等）
- Diff 高亮
- 搜索高亮

### 9. 运行时数据隔离

通过 `NVIM_APPNAME=pnvim`：
- shada 文件存到 `~/.local/state/pnvim/`
- undo 文件存到 `~/.local/state/pnvim/undo/`
- 完全不影响客户的 vim/nvim 配置

如果 `~/.local/state/pnvim/` 不可写：
- 禁用 shada
- 禁用 undofile

## 预估规模

- init.lua: 约 350-400 行
- pnvim: 3 行

## 实现计划

1. 创建 `portable/init.lua` 基础框架
2. 实现终端检测和基础选项
3. 实现内嵌 onedark 配色
4. 实现纯 Lua 状态栏
5. 实现注释切换功能
6. 实现自动括号配对
7. 实现增强文本对象
8. 添加快捷键映射
9. 创建 `portable/pnvim` 启动脚本
10. 测试验证
