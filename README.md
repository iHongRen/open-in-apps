# macOS Finder 工具栏应用集

macOS 一键快速操作工具包。精选实用应用，放入 Finder 工具栏，快速处理文件。     

[English README](./README_en.md)

## 应用集

- **open-in-** 系列（20+ app）快速在指定应用中打开文件/目录（VS Code、Terminal、PyCharm 等）
  
- **app-to-dmg**  将 .app 应用/目录打包为 .dmg 镜像文件
  
- **remove_quarantine**  移除应用隔离属性，解决"无法打开"问题
  
- **[TinyImage](https://github.com/iHongRen/TinyImage)**  图片无损压缩，减小文件大小

  
  
## 安装

1. 下载并打开 [apps.dmg](https://github.com/iHongRen/finder-toolbar-apps/releases)，拖拽所需 app 到 Applications/ 
![](./screenshots/apps.png)


2. 按住 `⌘ Command` 键，用鼠标将 `xxx.app` 拖到 Finder 工具栏  

![](./screenshots/guide.gif)

  

3. 打开终端，执行以下命令去除隔离属性，将`xxx` 替换为安装的app名称
   ```bash
   xattr -d com.apple.quarantine /Applications/xxx.app
   ```



## 使用

在Finder中选择需要处理的文件或者文件夹，然后点击工具栏上的app就能快速处理。

