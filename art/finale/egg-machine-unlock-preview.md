# 彩蛋机解锁 GIF · 概念预览

这是一段 6.8 秒的循环预览；游戏内使用由同组关键帧导出的独立场景图和纪念物图，不播放 GIF。设备交互仍待用户验收。

- 构图和机器造型参考：`ios/Ivy/Assets.xcassets/Scenes/Hall/story-hall.imageset/story-hall.png`。近景保留大厅右侧青绿黄铜机身、右侧手柄、前方出纸口和木柜支撑。
- 画风参考：`ios/Ivy/Assets.xcassets/Scenes/Yard/story-yard-base.imageset/story-yard-base.png`。使用清楚的深色轮廓、成组色块、克制的阶梯笔触及局部暖光。
- 信封参考：`ios/Ivy/Assets.xcassets/Scenes/Yard/story-envelope.imageset/story-envelope.png`。
- 生成提示依次限定五个状态：未启动的机器；只压下右侧手柄；信封半出；信封完全滑出、灯点亮起；玻璃窗中心显出心形。各状态保持相同相机、家具、光线和机器结构，不加入文字、角色或随机奖品。
- 动画使用现有 13 个收藏 ID 顺序，让各自现有图案在玻璃窗中依次显影。每件图案都放在同一枚 `egg-container.png` 黄铜玻璃徽章内，按素材的可见边界缩放居中，并完整限制在内侧玻璃椭圆中，不覆盖黄铜边；外框的位置与尺寸始终相同。香水使用现有 Gaiac 10 瓶身图案。

实现位置：`ios/Ivy/Game/HallScene.swift` 驱动拉杆、13 枚徽章、出信封与拆信；`ios/Ivy/Assets.xcassets/Scenes/Hall/lottery-machine-*.imageset` 和 `lottery-token-*.imageset` 是运行素材；`art/finale/source/` 保存关键帧及徽章源图。机器玻璃上的黄铜灯点只是装饰，13 枚收藏由逐一出现的徽章表达。
