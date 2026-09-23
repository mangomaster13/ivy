# Ivy

私人横屏 iPhone 礼物：手绘回忆解谜小屋，厅里地下通道通向 Wonderland 香港，十三颗蛋。

当前文档按产品、玩法、界面、美术和工程分组，入口见 [文档目录](docs/README.md)。后续 agent 工作从 [Ivy 项目 skill](docs/skills/ivy-game/SKILL.md) 开始，由 [AGENTS.md](AGENTS.md) 引用。

用 Xcode 打开 `ios/Ivy.xcodeproj`，最低 iOS 版本与构建配置以工程为准。日常测试由用户负责；agent 设备检查遵循 UI 规则中的测试政策。

- 仅 iPhone，左横/右横（竖握会提示旋转）
- Bundle ID：`com.ivy.gift`
- 交互逻辑画布：320×160；手绘素材使用高质量采样
- 资源：`ios/Ivy/Assets.xcassets`，从高分辨率原稿直接导出设备倍率
- 目标旅程：Yard → Hall → Plane → Corridor → Bedroom → Gelato → Big Top → Le Labo → Cinema → Dictionary → Ferris → Taxi → Hall。当前运行代码仍有待迁移的旧名称与占位玩法；以总纲标注的状态为准。
- 生成脚本：`scripts/`
- 分发：TestFlight 发给一个 Apple ID，不上 App Store
