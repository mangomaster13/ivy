# Taxi artwork

The approved Taxi camera stays in the rear seat of a right-hand-drive cab. The two side windows show the road and pavement beside the car. At the end, the same camera faces the opening Yard cottage on the left side of the road.

All five source images in `source/` are 1774×887. Each is exported directly to its matching 1x, 2x and 3x asset, without scaling up an existing catalog image.

| Source | Runtime image | Physical state |
| --- | --- | --- |
| `departure-card-present.png` | `later-taxi-interior-background` | Route card sits in the right front seat pocket. |
| `departure-card-taken.png` | `later-taxi-interior-card-taken` | Route card is removed; map remains in the pocket. |
| `route-board.png` | `later-taxi-map-background` | Blank mounted route board on the front seat back; graph and player line are separate layers. |
| `arrived-receipt-ready.png` | `later-taxi-interior-arrived` | Cab has reached the cottage; receipt remains in the meter. |
| `arrived-receipt-out.png` | `later-taxi-interior-receipt-out` | Receipt extends from the meter and may be taken. |

The existing `later-taxi-route-card`, `later-taxi-route-graph-overlay`, and `later-taxi-receipt-stay` retain the authored wording and are reused as independent closeup art. The card is evidence, the graph is the route surface, and the receipt is the thirteenth keepsake.
