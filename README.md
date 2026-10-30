# 量子计算：让自然参与计算

面向普通大众的中文科普动画。24 个连续场景覆盖比特、叠加、相位、测量、干涉、纠缠、量子电路、Grover、Shor、后量子密码、量子模拟、硬件、噪声、纠错与能力边界。

- 成片：output/quantum-computing.mp4（1920 × 1080，30 fps，H.264 + AAC）
- 配音：微软云希 zh-CN-YunxiNeural。全片使用同一音色。
- 字幕：烧录中文字幕，附 SRT 与 WebVTT；句子边界按实际音频对齐，句内短字幕按字数分配时长。
- 视觉：原创程序化三维投影、粒子、波形、电路和晶格动画。
- 声音：原创电子氛围音轨与合成提示音，无外部配乐。
- 观看页：output/index.html，经 HTTP 服务打开后可点击章节跳转。
- 文稿与来源：content/narration.md、content/sources.md。

## 远端工作区

本项目的创建、编辑、配音、编译、渲染和导出均在远端完成：

yangshuyun@10.10.10.1:/Users/yangshuyun/workspace/dev/ai-video/ai-video-1030-astra

## 重建

依赖远端已有的 macOS 14 原生框架、Swift 5.9 工具链、Ruby、curl 与 afconvert。无需安装第三方包；不使用 Python，也不修改任何虚拟环境或依赖声明。

在仓库根目录运行：

~~~sh
bash render.sh
~~~

或分步执行：

~~~sh
mkdir -p build output assets/yunxi
swiftc -O -parse-as-library src/EdgeSpeech.swift -o build/edge-speech
ruby -EUTF-8 src/yunxi.rb
swiftc -O src/Media.swift src/Graphics.swift src/Scenes.swift src/Engine.swift src/main.swift -o build/quantum-film
build/quantum-film audio
build/quantum-film preview
caffeinate -i build/quantum-film render
build/quantum-film mux
swiftc -O src/Inspect.swift -o build/inspect
build/inspect
ruby -EUTF-8 src/deliver.rb
~~~

成功音频按内容摘要缓存；重新运行会跳过已有匹配项。云端接口可能随时间改变，重建配音需要网络。

## 配音说明

最初使用用户提供的曼波社区接口，生成了部分配音；接口明确返回每天每个 IP 50 次请求的限制。因此最终统一改用用户同意的云希音色，没有混用两种声音。原曼波缓存保存在 assets/audio/，不会混入成片。

Edge 云希客户端通过 macOS URLSession 实现与 edge-tts 相同的 WebSocket 协议。服务输出 24 kHz MP3，使用系统 afconvert 解码为 48 kHz 单声道 WAV 后混音，最终为双声道 AAC。48 kHz 混音不意味着原始语音具有 48 kHz 录音带宽。

src/edge-token.rb 是 edge-tts token 计算的 Ruby 适配，适用 LGPL-3.0。上游原文、作者信息与许可证保留在 content/vendor/edge-tts/；这部分代码是独立脚本。其余制作代码为本项目原创。

## 文件组织

- content/story.json：分镜、屏幕文字、科学注释、逐句解说。
- src/Graphics.swift、src/Scenes.swift、src/Engine.swift：动态视觉和视频编码。
- src/Media.swift：音频剪裁、时轴、字幕、配乐、混音、封装。
- src/EdgeSpeech.swift、src/yunxi.rb、src/edge-token.rb：云希配音与缓存。
- src/tts.rb：原曼波配音流程，收到限流时停止。
- output/timeline.json、chapters.json：精确成片时轴与章节。
- output/audio-qc.json、video-qc.json、validation.json：输出验证记录。
- output/previews/、contact-sheet.jpg：场景预览。
- output/quantum-computing-source.zip：可编辑源文件包，包含已生成的云希音频缓存，可直接离线重渲染。

## 验证范围

检查最终文件的视频与音频轨、分辨率、帧率、时长、音频峰值、削波样本、字幕顺序和覆盖、全部场景预览，以及最终编码视频中的代表性画面。图示是概念示意，并非真实设备照片或实验测量数据。


## 成片验证结果

最终时长 598.3 秒；1920 × 1080；30 fps；H.264 视频与 AAC 音频。24 个章节均已从最终编码文件解码检查，174 条字幕顺序和范围检查通过；最终音频解码峰值约 -2.22 dBFS，削波样本为 0。完整记录见 output/validation.json 与 output/encoded-qc.json。

## 重新打开观看页面

在远端仓库运行 ruby -EUTF-8 src/serve.rb，可在远端 127.0.0.1:8765 提供观看页。通过 SSH 把本机 8765 端口转发到远端该端口后，打开 http://127.0.0.1:8765/ 。预览服务只监听回环地址；MP4 与工程文件始终保存在远端 output/。


## 完整工程备份与下载

[完整备份 Release](https://github.com/liuyinchu/ai-video-quantum-computing/releases/tag/full-backup-20261030) 包含完整工程快照、最终 MP4、可编辑源工程包、逐文件清单、SHA-256 校验和及恢复说明。

完整快照包括原始 `.git` 历史以及被 `.gitignore` 排除的音频、视频、中间文件与构建日志，共 718 个原始文件。原始工程提交为 `7e2be6bbc1efeb7f2181f9342a60c897de13653f`。快照 SHA-256：`a6de3dc1a1078cdb69ac03179e329f701bd356c486d44fbcaf26152dd6ca5c2a`。

云端已经验证分块、恢复后的原始文件及 Git 历史。跨平台恢复注意事项见 [backup/RESTORE.md](backup/RESTORE.md)，特别是 macOS AppleDouble 元数据在 Linux 上的处理方式。

