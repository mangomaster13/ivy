# 第一批成套状态素材

2026-09-24：用户批准对照稿并要求「替换吧」。六组场景、七个承载面、22 张独立 2:1 生产图；不是从设计板裁出的图片。生成记录见 `generation.json`，原稿在 `source/`，导出入口是 `scripts/export_object_states.swift`。

每张原稿为 1774×887；1x/2x/3x 分别直接导出为 590×295、1180×590、1770×885，没有放大原图。取走态由对应有物态编辑，移除道具及接触阴影；不宣称生成式编辑逐像素一致。提示记录保留实际请求，包括部分派生态请求意外带入的 `undefined` 前缀；选用结果经过直接看图审阅。

## 状态与实物锚点

坐标均为 320×160 画布。全景和热点共用 aspect-fit 变换，触控区域至少 48 pt；库存图标不再充当这些场景中的摆放态。

| 承载面 | 资源前缀与状态 | 状态依据 | 道具实际占地／承托 |
| --- | --- | --- | --- |
| Big Top 抽屉 | bt-state：closed / menu / empty | menuDrawerOpen、menuTaken | 菜单 x117…172、y105…125，木底承托与前沿遮挡；四轮符号仍独立交互 |
| Yard 石台 | pot-state：covered / key / empty | opened.pot、picked.brassKey | 钥匙 x145…182、y70…96，苔痕内平放；移盆后位置固定 |
| Hall 抽屉 | drawer-state：closed / eraser / empty | opened.drawer、picked.eraser | 橡皮 x101…137、y71…96，布衬承托；关闭时锁孔位于 x160、y57.5 |
| Plane 书页 | book-state：ticket / empty | picked.ticket | 票 x169…273、y50…94，右页承托及翻角遮挡 |
| Bedroom 礼盒 | box-state：closed / both / petal / token / empty | opened.wholeBox、rose.found、collected.rose、picked.coin | 花瓣 x112…145、y88…114；代币 x171…204、y91…113；任一取走不重排另一件 |
| Gelato 工具柜 | cabinet-state：closed / scoop / empty | opened.dispenser、picked.scoop | 勺 x140…165、y42…110，由柜背挂夹承托；取走后挂夹保留 |
| Gelato 出杯台 | gelato-state：empty / served / tasted | flavorSolved、collected.gelato | 杯 x244…272、y85…119，落在托碟内；试吃态保留杯子及花朵 |

## 相机、文字与范围

- Big Top 的服务侧景和锁近景共用整张生产图及裁切；近景相机范围 x92、y103、135×54。其余本批替换为道具近景，远景中的关门／合书入口沿用现有素材，不声称完成全游戏远近景重绘。
- 礼盒关闭态保留既有「左盒、右输入」解谜排布，打开后进入较近的盒内检查机位。右侧桌布 x.55…96、y.23…80 留给共享原生输入槽；盒盖题字 `i love u` 已画入纸面，不叠第二份文字。聚焦时继续使用既有居中输入方式。
- 每组沿用当前场景的物件身份、相机方向、家具和灯光，参考职责与生成器原始路径可在 JSON 追溯。Yard 风格参照使用当前 checkout 可用的现用 @3x 图，缺失的历史源图没有被冒充使用。
- 沿用现有打开、领取、消耗和收藏方法；画面读取已领取事实，不按当前库存是否仍持有判断，避免消耗后重新出现。无新增存档字段、重置或收藏位变更。

## 交付证据

已直接查看生成原稿并导出资源；状态入口和热点按源码审阅。`WonderlandTests` 留有领取／消耗／恢复存档及礼盒领取顺序的回归检查，未执行。按照用户测试政策，没有运行测试、校验脚本、游戏构建、设备或截图检查；设备显示与实际手势仍待用户实测。
