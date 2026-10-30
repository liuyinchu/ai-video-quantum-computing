# 完整工程恢复

下载本 Release 的 ai-video-1030-astra-full-20261030.tar.gz、SHA256SUMS、file-manifest.json 与 verification.json。

1. 对下载的完整快照运行 SHA-256 校验。SHA256SUMS 同时列出视频和源工程包，可分别核对。
2. 解压完整快照：
   `tar -xzf ai-video-1030-astra-full-20261030.tar.gz`
3. 恢复后的 ai-video-1030-astra/ 包含源码、原始 .git 历史、全部配音、成片、预览、中间渲染文件、构建产物与日志。
4. 在恢复目录运行 `git fsck --full`，原始 HEAD 应为 7e2be6bbc1efeb7f2181f9342a60c897de13653f。
5. 完整快照中的项目为 macOS 原生 Swift 制作工程。重新渲染方法见其 README.md。素材缓存已包含，无需重新生成配音。

verification.json 记录 GitHub Actions 对全部原始文件及 Git 历史的检查结果。file-manifest.json 包含逐文件 SHA-256、大小、类型与权限位。macOS 附加属性通过归档自带的 AppleDouble/PAX 元数据保留。

源码可直接从 main 分支获取；完整媒体与中间文件以 Release 快照为准。backup/full-snapshot-20261030 分支保留传输分块，按 backup/manifest.json 顺序串联可再次重组同一归档。


## Linux 解压说明

此 macOS 完整归档含有 AppleDouble（文件名以 ._ 开头）的元数据伴随条目，它们不属于原始工程文件清单。在 Linux 上可用 tar --exclude='*/._*' -xzf ai-video-1030-astra-full-20261030.tar.gz，避免把这些元数据文件当作 Git 引用或对象。macOS 的系统 tar 会自动恢复相应附加属性。云端校验先逐一验证全部原始文件，再从清单中的原始 .git 文件构建独立目录执行 git fsck；完整归档本身没有删减这些元数据。
