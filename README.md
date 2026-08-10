# PotPlayer Subtitle Translate - DeepSeek

PotPlayer 实时字幕翻译插件，基于 DeepSeek V4 API（OpenAI 兼容接口），为 PotPlayer 提供 AI 实时字幕翻译。

## 特性

- 使用 DeepSeek V4 模型实时翻译字幕（默认 `deepseek-v4-flash`）
- API 地址支持 Base URL 或完整 URL，自动补全 `/chat/completions`
- 对 DeepSeek 接口关闭 thinking 模式，翻译更快更稳定
- 错误信息会直接显示在翻译结果中，便于排查问题

## 文件

- `SubtitleTranslate - DeepSeek.as`：翻译插件脚本
- `SubtitleTranslate - DeepSeek.ico`：插件图标

## 安装

1. 完全退出 PotPlayer；
2. 将以上两个文件复制到 PotPlayer 安装目录下的 `Extension\Subtitle\Translate` 文件夹；
3. 重新打开 PotPlayer。

## 配置

1. 播放任意视频，右键 → **字幕 → 实时字幕翻译 → 实时字幕翻译设置**（也可以通过 **选项 → 扩展功能 → 实时字幕翻译** 打开）；
2. 将翻译引擎选择为 **DeepSeek 翻译**；
3. 点击 **账户设置**：
   - **账户名**：`deepseek-v4-flash|https://api.deepseek.com`（格式为 `模型名|API地址`，也可以只填模型名或只填地址，缺省部分自动补全）；
   - **密码**：你的 DeepSeek API Key；
   - 确定后提示配置成功；
4. **源语言**选择"自动检测"，**目标语言**选择"简体中文"（或你需要的语言）；
5. 点击 **测试** 按钮验证翻译是否生效。

## 使用

- 播放带**外挂字幕**（`.srt` / `.ass` 文件）的视频；
- 右键 → **字幕 → 实时字幕翻译**，勾选"总是使用"；
- 字幕即会被替换为翻译结果；如需同时显示原文与译文，可在设置中开启"双语字幕"。

## 常见问题

### 视频上不显示翻译

- 确认字幕是**外挂字幕文件**。PotPlayer 实时字幕翻译仅支持外挂字幕，**内嵌字幕轨和硬字幕无法翻译**；
- 确认播放时已勾选"实时字幕翻译 → 总是使用"；
- 确认翻译引擎已选择 DeepSeek 翻译，且目标语言不是"自动"。

### 测试显示"翻译失败: ..."

错误信息会直接显示在翻译结果中，常见原因：

- `HTTP 401`：API Key 无效；
- `HTTP 402`：账户余额不足；
- 提示模型不存在：模型名错误，或使用了已停用的 `deepseek-chat` / `deepseek-reasoner`（已于 2026-07-24 停用），请改用 `deepseek-v4-flash` 或 `deepseek-v4-pro`。

## 模型

| 模型名 | 说明 |
| --- | --- |
| `deepseek-v4-flash` | 默认，速度快、成本低 |
| `deepseek-v4-pro` | 更强，速度稍慢 |

更换模型时，只需在账户设置中修改模型名即可，API 地址保持不变。

## 注意事项

- 登录成功仅表示配置已保存，脚本不会在登录时校验 API Key 有效性，请以"测试"按钮的结果为准；
- 实时翻译为逐句调用，会持续消耗 DeepSeek API 额度，请留意用量；
- 本插件仅供个人学习交流使用，请遵守 DeepSeek 服务条款。
