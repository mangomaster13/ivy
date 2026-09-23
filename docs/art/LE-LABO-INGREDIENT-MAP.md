# Le Labo 原料素材与固定槽位

本表只列新玩家可见的 20 种原料。源图在 `art/big-top-le-labo/source/ingredients-v3/`，每项的 `manifest.json` 记录裁切格与 alpha 边界；运行导出在 `ios/Ivy/Assets.xcassets/Scenes/LeLabo/<asset>.imageset/`。辨识同时依赖原料外观和对应的 `ll4-label-<ID>` 柜沿题字。槽位坐标来自 `IngredientShelfLayout`，基准画布 320×160，格式为 `(中心 x, 支撑底 y, 宽, 高)`；所有素材底边贴在相应搁板或托盘上。拿走后保留空槽，不重新排布。

| ID | 运行素材 | 可见辨识证据 | 固定柜位与承载面 | 世界 / 近景槽位 |
| --- | --- | --- | --- | --- |
| `gaiacWood` | `ll3-ingredient-gaiacWood` | 木条在黄铜圆罐 | 木脂柜上层左 | `(92,42,18,17)` / `(74,67,52,43)` |
| `cedar` | `ll3-ingredient-cedar` | 浅木条及雪松纸袋 | 木脂柜上层中 | `(126,42,17,20)` / `(160,67,50,49)` |
| `incense` | `ll3-ingredient-incense` | 金色树脂与翻盖铜盒 | 木脂柜上层右 | `(92,64,18,16)` / `(246,67,52,41)` |
| `oakmoss` | `ll3-ingredient-oakmoss` | 灰绿地衣与玻璃钵 | 木脂柜下层左 | `(126,64,18,17)` / `(74,129,52,43)` |
| `patchouli` | `ll3-ingredient-patchouli` | 叶片与牛皮纸袋 | 木脂柜下层中 | `(92,87,17,19)` / `(160,129,48,48)` |
| `vetiver` | `ll3-ingredient-vetiver` | 捆扎的细根 | 木脂柜下层右 | `(126,87,17,20)` / `(246,129,48,49)` |
| `bergamot` | `ll3-ingredient-bergamot` | 青果剖面与玻璃碗 | 植物柜上层左 | `(65,76,9,11)` / `(60,66,45,39)` |
| `grapefruit` | `ll3-ingredient-grapefruit` | 红色柚瓣与玻璃罐 | 植物柜上层中左 | `(75,76,9,11)` / `(121,66,45,39)` |
| `petitgrain` | `ll3-ingredient-petitgrain` | 小枝叶与棕玻璃罐 | 植物柜上层中右 | `(85,76,9,13)` / `(183,66,43,43)` |
| `orangeBlossom` | `ll3-ingredient-orangeBlossom` | 白花枝与透明瓶 | 植物柜上层右 | `(95,76,9,13)` / `(246,66,42,43)` |
| `iris` | `ll3-ingredient-iris` | 紫鸢尾标签与陶罐 | 植物柜下层左 | `(105,76,9,12)` / `(60,124,43,43)` |
| `violet` | `ll3-ingredient-violet` | 紫花与蓝白陶盒 | 植物柜下层中左 | `(115,76,9,9)` / `(121,124,45,36)` |
| `jasmine` | `ll3-ingredient-jasmine` | 白茉莉与透明瓶 | 植物柜下层中右 | `(125,76,9,13)` / `(183,124,43,43)` |
| `cinnamon` | `ll3-ingredient-cinnamon` | 扎束桂皮 | 香料抽屉左 | 仅近景 `(59,86,46,52)` |
| `pimentoBay` | `ll3-ingredient-pimentoBay` | 叶片与金色滴管瓶 | 香料抽屉中左 | 仅近景 `(126,86,46,55)` |
| `pinkPepper` | `ll3-ingredient-pinkPepper` | 粉红椒粒玻璃罐 | 香料抽屉中右 | 仅近景 `(193,86,46,42)` |
| `cardamom` | `ll3-ingredient-cardamom` | 豆蔻荚与浅色小碗 | 香料抽屉右 | 仅近景 `(260,86,46,39)` |
| `musk` | `ll3-ingredient-musk` | 球塞浅色香液瓶 | 实验柜上层左 | `(56,36,18,23)` / `(104,67,55,47)` |
| `crystalMoss` | `ll3-ingredient-crystalMoss` | 绿色晶体方瓶 | 实验柜上层右 | `(89,36,18,23)` / `(215,67,55,47)` |
| `clearwood` | `ll3-ingredient-clearwood` | 琥珀色锥形瓶 | 实验柜下层左 | `(56,73,18,27)` / `(104,129,55,49)` |

旧存档的 `ambroxyde` ID、素材和已持有状态继续解码；新玩家货架使用 `PerfumeIngredient.world` 排除它。`manifest.json` 内部分原料的 `sheet` 是当时拼版来源，不代表游戏柜别；上表以 `PerfumeIngredient.cabinet` 和实际固定槽位为准。配方笔记给出核心与辅助特征，柜沿标签和实物外观用于辨认，不要求清空柜子。
