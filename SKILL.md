---
name: office-advanced-skills
description: 传米科技 OpenClaw 办公高级合集一键安装器。包含全网搜索、AI编码、图表生成、抖音热榜、微信公众号工具、去AI味润色、研究分析、PPT生成、网站爬虫、文档OCR、内容摘要、飞书画板、叙事风格共13个高级办公技能。触发词："安装办公高级合集"、"安装高级技能"、"office advanced"。
---

# 办公高级合集

传米科技 OpenClaw 办公高级技能合集，覆盖内容创作、研究分析、文档处理、可视化等场景。

## 包含技能（11个）

### workspace skills（~/.openclaw/workspace/skills/）
| 技能 | 功能 |
|------|------|
| agent-reach | 全网搜索：Twitter/X、小红书、抖音、B站、微博、YouTube等16个平台 |
| claude-code | Claude Code AI编码集成 |
| diagram-generator | 图表生成：流程图、架构图、ER图、思维导图（draw.io/Mermaid/Excalidraw） |
| douyin-hot-trend | 抖音热榜/热搜实时数据 |
| wechat-toolkit | 微信公众号工具：搜索文章、下载内容、AI洗稿改写、推送草稿箱 |
| elatia-humanizer-zh | 去AI味润色：去除文本AI生成痕迹，优化写作风格 |
| research-analyzer | 综合研究分析，生成研究报告 |
| skywork-ppt | AI PPT生成与编辑（基于Nano Banana 2） |
| feishu-help-crawler | 通用网站爬虫（Playwright） |
| paddleocr-doc-parsing | PDF/文档图片OCR解析，支持表格、公式、印章 |
| summarize | URL/文件摘要（网页、PDF、图片、音频、YouTube） |

### global skills（~/.openclaw/skills/）
| 技能 | 功能 |
|------|------|
| feishu-cli-board | 飞书画板：架构图、流程图、看板，支持Mermaid导入 |
| narrative-voice | 叙事风格：日常会话输出富有故事感、有温度的回应 |

## 安装方式

### 本地安装
```bash
bash ~/.openclaw/workspace/skills/office-advanced-skills/scripts/install-office-advanced.sh
```

### SSH 远程安装
```bash
ssh user@remote-host 'bash -s' < ~/.openclaw/workspace/skills/office-advanced-skills/scripts/install-office-advanced.sh
```

### curl 一行安装
```bash
curl -fsSL https://raw.githubusercontent.com/transiglobal/office-advanced-skills/main/scripts/install-office-advanced.sh | bash
```

## Agent 调用指南

当用户说"安装办公高级合集"、"安装高级技能"时：

1. 询问是本地安装还是远程 SSH 安装
2. 本地安装：直接执行脚本
3. 远程安装：询问 SSH 连接信息（user@host），然后执行远程命令
4. 安装完成后提示用户重启 OpenClaw 会话

## 注意事项

- 需要能访问 github.com（国内可能需要代理）
- 已存在的技能会自动跳过，不会覆盖
- skywork-ppt 需要 Python 3 (>=3.8)
- paddleocr-doc-parsing 需要 PaddleOCR 环境
- 安装完成后需重启 OpenClaw 会话才能加载新技能
