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

