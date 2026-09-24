# Asset catalog 分类

本文记录**当前资源目录**，不是玩法验收报告。`Scenes/LeLabo` 对应 `perfume`。Dictionary 已使用 `Scenes/Dictionary` 与 `Keepsakes` 下的 `later-dictionary-*` 分层素材；旧 `Scenes/Sunset` 资源保留为历史文件。英文歌词卡源图及放置约定见 [Dictionary 接入说明](../../art/dictionary/README.md)；旧文档引用的 `art/later-eggs/production/dictionary/` 在当前工作区不存在，以已导入素材为准。目标规则与旧存档迁移见 [游戏总纲](../gameplay/IVY-GUIDE.md)。

`ios/Ivy/Assets.xcassets` 按使用模块放置资源。`Scenes/<地点>` 收纳该地点的主景、近景、纸品、原料及独立物件；`Shared/Tools`、`Shared/Notes`、`Shared/Lock`、`Shared/UI` 收纳跨场景资源。`Keepsakes` 是收藏展示模块，`Intro` 是片头模块。`AppIcon`、`AccentColor` 留在 catalog 根目录，供 Xcode 构建设置直接引用。

地点目录为 `Yard`、`Hall`、`Plane`、`Corridor`、`Bedroom`、`Gelato`、`BigTop`、`LeLabo`、`Cinema`、`Dictionary`、`Sunset`、`Ferris`、`Taxi`。原来的 `Exploration`、`InteractionRefresh`、`FoodAndFragrance`、`Memories`、`Wonderland` 混合目录已按实际使用地点拆分；空的 `Noodle`、`Supermarket` 目录也已移除。

资源的 **imageset 名称不随目录改变**，例如 `bt2-gelato` 仍由 `Image("bt2-gelato")` 读取。各目录的 `Contents.json` 均未启用 namespace；切勿增加同名 imageset。新增素材时，同时更新相应 `scripts/export_*.swift` 或 `art/big-top-le-labo/export*.py` 的输出路径。高分辨率原图仍保存在 `art/`，catalog 中只放运行时导出图。

目录整理和后四站素材导入均未改游戏逻辑、存档键或收藏 ID。Dictionary 素材存在于 catalog 不代表 Dictionary 场景已经接入。
