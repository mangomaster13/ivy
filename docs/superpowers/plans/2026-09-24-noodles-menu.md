# Noodles Menu Implementation Plan

**Goal:** 接入已批准的双工具找菜单谜题及十项固定随机点单。
**Architecture:** 沿用 BigTopProgress、GameStore 操作守卫、MemoryPanel 返回链与 Notes；不增加依赖或通用机关层。
**Tech Stack:** SwiftUI、Codable、现有资源导出用 CoreGraphics / CoreText。
**Spec:** art/noodles-menu-design/README.md。

按用户授权在当前 main 内联执行，不另开分支，不运行测试、校验构建或设备。允许分阶段提交推送，禁止夹带既有其他改动。

- [ ] 生产素材：从批准图生成可分层柜台、空白菜单、独立工具/图案、显影纸与镜子安装近景；从高清源导出资源与 Juniper 菜名。记录支撑坐标、资源映射和生成提示。目视审稿后提交素材阶段。
- [ ] 状态接入：FoodAndFragrance.swift 增加可缺省锁草稿、发现状态、十项旧 ID 排列；在 Exploration.swift 增加独立工具/线索，保持旧 pencil 为 eraser。旧菜单持有/放置、已开抽屉、已完成订单与下游通行映射优先。
- [ ] 场景接入：BigTopViews.swift / FoodAndFragranceWorld.swift 共用柜台物件坐标；MemoryJourney.swift / MemoryCloseups.swift / ExplorationLayout.swift 接入口与返回；Notes 展示同一证据。移除旧纸轨机关与菜单翻页操作，保留符号锁整组反馈。
- [ ] 窄范围源码审阅：更新已有过时 BigTop 测试为新版完整旅程与旧档兼容的可运行检查，但不执行；检查枚举分支、资源身份、状态守卫及旧 ID。同步权威规则。仅提交本任务差异并推送，交付注明未实测。
