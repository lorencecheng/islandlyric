# IslandLyric

Apple Music 的**逐句歌词**显示到：iPhone 灵动岛 / 锁屏 / CarPlay / 配对 Apple Watch。

独立 App，不依赖 X Music，也不依赖 Apple Music 的私有能力：读系统 Now Playing 的歌曲信息，去公开歌词库 LRCLIB 匹配逐句时间轴，用 ActivityKit 把当前句推进实时活动。

## 它能做什么

- 播放 Apple Music 时自动上岛（歌词就绪 + 正在播放 + 开关开启，2 秒防抖）
- 灵动岛展开态：歌名 / 当前句 / 下一句 / 整首进度
- 锁屏卡片：`medium` 家族，大字当前句 + 下一句 + 进度条
- CarPlay / Apple Watch 智能叠放：`small` 家族（`supplementalActivityFamilies`）
- 后台保活：静音 PCM 循环播放，锁屏后歌词继续走
- UI：炭黑 + 金色 Material 毛玻璃体系（4 级 SurfaceLevel）

## 目录

```
IslandLyric/             App 源码（SwiftUI）
  Core/                  Now Playing / LRCLIB / LRC 解析 / 保活 / 实时活动 / 状态机
  DesignSystem/          Material 表面、组件、主题
  Shared/                与 Widget 共用的 Attributes 与配色（两份 Target 都编译）
LyricWidget/             Widget Extension（灵动岛 + 锁屏 + small 家族）
project.yml              XcodeGen 工程定义（CI 用它生成 .xcodeproj）
build.sh                 本地打包（需 macOS + Xcode + 已登录 Apple ID）
```

## 云端编译（无需 Mac）

仓库已配置 GitHub Actions：`.github/workflows/ios-build.yml`

推送到 `main` 或手动 `Run workflow` 后，runner 会：

1. 装 XcodeGen、用 `project.yml` 生成工程
2. `xcodebuild` 以 **未签名** 方式编译（`CODE_SIGNING_ALLOWED=NO`）
3. 把 `build.log` 和未签名 `.app` 作为 artifact 上传

这一步只能回答一个问题：**代码能不能编译通过**。它产出的 `.app` 不能装到 iPhone，因为没有任何签名。

## 安装到设备的现实约束

| 方式 | 是否需要 Mac | 成本 | 有效期 |
| --- | --- | --- | --- |
| Xcode 免费 Apple ID 侧载 | 需要 | 0 | 7 天，到期重签 |
| Sideloadly / AltStore | 需要（Windows 也行） | 0 | 7 天，需常开 AltServer |
| 付费开发者账号 + TestFlight | 不需要 | $99/年 | 90 天一轮 |
| 越狱 / TrollStore | 不需要 | 0 | 长期（需匹配系统版本） |

关键限制：免费 Apple ID 可以本地签名安装，但**不能上传 TestFlight**；Widget / Live Activity 扩展必须跟着主 App 一起签名，所以纯 iPad 无 Mac 的路径只剩「付费账号 + TestFlight」或「越狱环境」。

## 本地打包

```bash
./build.sh <10位TEAM_ID>
```

或直接 Xcode 打开 `IslandLyric.xcodeproj`，在 Signing & Capabilities 里选自己的 Team，真机运行。

## 已知边界

- 歌词来自 LRCLIB，冷门歌 / 现场版可能匹配不到
- 系统不暴露 Now Playing 的来源 App，所以不区分 Apple Music 与其它播放器
- CarPlay 是否显示实时活动由系统版本与车机决定，App 只能声明支持
- 后台保活会带来额外耗电，可在设置里关掉（关掉后锁屏歌词会停）
