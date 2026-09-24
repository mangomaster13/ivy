# Noodles Menu Implementation Plan

**Goal:** 接入已批准的双工具找菜单谜题及十项固定随机点单。
**Architecture:** 沿用 BigTopProgress、GameStore 操作守卫、MemoryPanel 返回链与 Notes；不增加依赖或通用机关层。
**Tech Stack:** SwiftUI、Codable、现有资源导出用 CoreGraphics / CoreText。
**Spec:** art/noodles-menu-design/README.md。

按用户授权在当前 main 内联执行，不另开分支，不运行测试、校验构建或设备。允许分阶段提交推送，禁止夹带既有其他改动。

- [x] 生产素材：批准图已拆分并从高清源导出，独立工具/图案和 Juniper 菜名已制作。素材阶段 2d2eab6 已推送；菜单后续调整为 12:5 以保留触控高度。
- [x] 状态接入：FoodAndFragrance.swift 保存可缺省锁草稿与十项旧 ID 排列；Exploration.swift 增加独立工具/线索，旧 pencil 仍为 eraser。旧菜单持有/放置、已开抽屉、已完成订单及下游通行映射优先。
- [x] 场景接入：BigTopViews.swift / FoodAndFragranceWorld.swift 共用柜台坐标；MemoryJourney.swift / MemoryCloseups.swift / ExplorationLayout.swift 接入口与返回；Notes 保留证据方向。旧纸轨机关与菜单翻页操作已替换，符号锁整组判定。
- [x] 窄范围源码审阅：已更新 BigTop 完整旅程与旧档兼容测试代码，未执行；已阅读枚举分支、资源身份、状态守卫与旧 ID 差异，同步权威规则。仅提交本任务差异，交付明确未构建、未设备实测。
