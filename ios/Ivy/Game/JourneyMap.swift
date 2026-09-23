import SwiftUI

// Natural Earth 1:110m geometry, bundled offline. See art/memories/README.md.
enum ChinaGeometry {
    static let rings: [[CGPoint]] = [
        [CGPoint(x: 109.4752, y: 18.1977), CGPoint(x: 108.6552, y: 18.5077), CGPoint(x: 108.6262, y: 19.3679), CGPoint(x: 109.1191, y: 19.8210), CGPoint(x: 110.2116, y: 20.1013), CGPoint(x: 110.7866, y: 20.0775), CGPoint(x: 111.0101, y: 19.6959), CGPoint(x: 110.5706, y: 19.2559), CGPoint(x: 110.3392, y: 18.6784), CGPoint(x: 109.4752, y: 18.1977)],
        [CGPoint(x: 80.2600, y: 42.3500), CGPoint(x: 80.1801, y: 42.9201), CGPoint(x: 80.8662, y: 43.1804), CGPoint(x: 79.9661, y: 44.9175), CGPoint(x: 81.9471, y: 45.3170), CGPoint(x: 82.4589, y: 45.5397), CGPoint(x: 83.1805, y: 47.3300), CGPoint(x: 85.1643, y: 47.0010), CGPoint(x: 85.7205, y: 47.4530), CGPoint(x: 85.7682, y: 48.4558), CGPoint(x: 86.5988, y: 48.5492), CGPoint(x: 87.3600, y: 49.2150), CGPoint(x: 87.7513, y: 49.2972), CGPoint(x: 88.0138, y: 48.5995), CGPoint(x: 88.8543, y: 48.0691), CGPoint(x: 90.2808, y: 47.6935), CGPoint(x: 90.9708, y: 46.8881), CGPoint(x: 90.5858, y: 45.7197), CGPoint(x: 90.9455, y: 45.2861), CGPoint(x: 92.1339, y: 45.1151), CGPoint(x: 93.4807, y: 44.9755), CGPoint(x: 94.6889, y: 44.3523), CGPoint(x: 95.3069, y: 44.2413), CGPoint(x: 95.7625, y: 43.3194), CGPoint(x: 96.3494, y: 42.7256), CGPoint(x: 97.4518, y: 42.7489), CGPoint(x: 99.5158, y: 42.5247), CGPoint(x: 100.8459, y: 42.6638), CGPoint(x: 101.8330, y: 42.5149), CGPoint(x: 103.3123, y: 41.9075), CGPoint(x: 104.5223, y: 41.9083), CGPoint(x: 104.9650, y: 41.5974), CGPoint(x: 106.1293, y: 42.1343), CGPoint(x: 107.7448, y: 42.4815), CGPoint(x: 109.2436, y: 42.5194), CGPoint(x: 110.4121, y: 42.8712), CGPoint(x: 111.1297, y: 43.4068), CGPoint(x: 111.8296, y: 43.7431), CGPoint(x: 111.6677, y: 44.0732), CGPoint(x: 111.3484, y: 44.4574), CGPoint(x: 111.8733, y: 45.1021), CGPoint(x: 112.4361, y: 45.0116), CGPoint(x: 113.4639, y: 44.8089), CGPoint(x: 114.4603, y: 45.3398), CGPoint(x: 115.9851, y: 45.7272), CGPoint(x: 116.7179, y: 46.3882), CGPoint(x: 117.4217, y: 46.6727), CGPoint(x: 118.8743, y: 46.8054), CGPoint(x: 119.6633, y: 46.6927), CGPoint(x: 119.7728, y: 47.0481), CGPoint(x: 118.8666, y: 47.7471), CGPoint(x: 118.0641, y: 48.0667), CGPoint(x: 117.2955, y: 47.6977), CGPoint(x: 116.3090, y: 47.8534), CGPoint(x: 115.7428, y: 47.7265), CGPoint(x: 115.4853, y: 48.1354), CGPoint(x: 116.1918, y: 49.1346), CGPoint(x: 116.6788, y: 49.8885), CGPoint(x: 117.8792, y: 49.5110), CGPoint(x: 119.2885, y: 50.1429), CGPoint(x: 119.2794, y: 50.5829), CGPoint(x: 120.1821, y: 51.6435), CGPoint(x: 120.7382, y: 51.9641), CGPoint(x: 120.7258, y: 52.5162), CGPoint(x: 120.1771, y: 52.7539), CGPoint(x: 121.0031, y: 53.2514), CGPoint(x: 122.2457, y: 53.4317), CGPoint(x: 123.5715, y: 53.4588), CGPoint(x: 125.0682, y: 53.1610), CGPoint(x: 125.9463, y: 52.7928), CGPoint(x: 126.5644, y: 51.7843), CGPoint(x: 126.9392, y: 51.3539), CGPoint(x: 127.2875, y: 50.7398), CGPoint(x: 127.6574, y: 49.7603), CGPoint(x: 129.3978, y: 49.4406), CGPoint(x: 130.5823, y: 48.7297), CGPoint(x: 130.9873, y: 47.7901), CGPoint(x: 132.5067, y: 47.7890), CGPoint(x: 133.3736, y: 48.1834), CGPoint(x: 135.0263, y: 48.4782), CGPoint(x: 134.5008, y: 47.5784), CGPoint(x: 134.1123, y: 47.2125), CGPoint(x: 133.7696, y: 46.1169), CGPoint(x: 133.0971, y: 45.1441), CGPoint(x: 131.8835, y: 45.3212), CGPoint(x: 131.0252, y: 44.9680), CGPoint(x: 131.2886, y: 44.1115), CGPoint(x: 131.1447, y: 42.9300), CGPoint(x: 130.6339, y: 42.9030), CGPoint(x: 130.6400, y: 42.3950), CGPoint(x: 129.9943, y: 42.9854), CGPoint(x: 129.5967, y: 42.4250), CGPoint(x: 128.0522, y: 41.9943), CGPoint(x: 128.2084, y: 41.4668), CGPoint(x: 127.3438, y: 41.5032), CGPoint(x: 126.8691, y: 41.8166), CGPoint(x: 126.1820, y: 41.1073), CGPoint(x: 125.0799, y: 40.5698), CGPoint(x: 124.2656, y: 39.9285), CGPoint(x: 122.8676, y: 39.6378), CGPoint(x: 122.1314, y: 39.1705), CGPoint(x: 121.0546, y: 38.8975), CGPoint(x: 121.5860, y: 39.3609), CGPoint(x: 121.3768, y: 39.7503), CGPoint(x: 122.1686, y: 40.4224), CGPoint(x: 121.6404, y: 40.9464), CGPoint(x: 120.7686, y: 40.5934), CGPoint(x: 119.6396, y: 39.8981), CGPoint(x: 119.0235, y: 39.2523), CGPoint(x: 118.0427, y: 39.2043), CGPoint(x: 117.5327, y: 38.7376), CGPoint(x: 118.0597, y: 38.0615), CGPoint(x: 118.8782, y: 37.8973), CGPoint(x: 118.9116, y: 37.4485), CGPoint(x: 119.7028, y: 37.1564), CGPoint(x: 120.8235, y: 37.8704), CGPoint(x: 121.7113, y: 37.4811), CGPoint(x: 122.3579, y: 37.4545), CGPoint(x: 122.5200, y: 36.9306), CGPoint(x: 121.1042, y: 36.6513), CGPoint(x: 120.6370, y: 36.1114), CGPoint(x: 119.6646, y: 35.6098), CGPoint(x: 119.1512, y: 34.9099), CGPoint(x: 120.2275, y: 34.3603), CGPoint(x: 120.6204, y: 33.3767), CGPoint(x: 121.2290, y: 32.4603), CGPoint(x: 121.9081, y: 31.6922), CGPoint(x: 121.8919, y: 30.9494), CGPoint(x: 121.2643, y: 30.6763), CGPoint(x: 121.5035, y: 30.1429), CGPoint(x: 122.0921, y: 29.8325), CGPoint(x: 121.9384, y: 29.0180), CGPoint(x: 121.6844, y: 28.2255), CGPoint(x: 121.1257, y: 28.1357), CGPoint(x: 120.3955, y: 27.0532), CGPoint(x: 119.5855, y: 25.7408), CGPoint(x: 118.6569, y: 24.5474), CGPoint(x: 117.2816, y: 23.6245), CGPoint(x: 115.8907, y: 22.7829), CGPoint(x: 114.7638, y: 22.6681), CGPoint(x: 114.1525, y: 22.2238), CGPoint(x: 113.8068, y: 22.5483), CGPoint(x: 113.2411, y: 22.0514), CGPoint(x: 111.8436, y: 21.5505), CGPoint(x: 110.7855, y: 21.3971), CGPoint(x: 110.4440, y: 20.3410), CGPoint(x: 109.8899, y: 20.2825), CGPoint(x: 109.6277, y: 21.0082), CGPoint(x: 109.8645, y: 21.3951), CGPoint(x: 108.5228, y: 21.7152), CGPoint(x: 108.0502, y: 21.5524), CGPoint(x: 107.0434, y: 21.8119), CGPoint(x: 106.5673, y: 22.2182), CGPoint(x: 106.7254, y: 22.7943), CGPoint(x: 105.8112, y: 22.9769), CGPoint(x: 105.3292, y: 23.3521), CGPoint(x: 104.4769, y: 22.8192), CGPoint(x: 103.5045, y: 22.7038), CGPoint(x: 102.7070, y: 22.7088), CGPoint(x: 102.1704, y: 22.4648), CGPoint(x: 101.6520, y: 22.3182), CGPoint(x: 101.8031, y: 21.1744), CGPoint(x: 101.2700, y: 21.2017), CGPoint(x: 101.1800, y: 21.4366), CGPoint(x: 101.1500, y: 21.8500), CGPoint(x: 100.4165, y: 21.5588), CGPoint(x: 99.9835, y: 21.7429), CGPoint(x: 99.2409, y: 22.1183), CGPoint(x: 99.5320, y: 22.9490), CGPoint(x: 98.8987, y: 23.1427), CGPoint(x: 98.6603, y: 24.0633), CGPoint(x: 97.6047, y: 23.8974), CGPoint(x: 97.7246, y: 25.0836), CGPoint(x: 98.6718, y: 25.9187), CGPoint(x: 98.7121, y: 26.7435), CGPoint(x: 98.6827, y: 27.5088), CGPoint(x: 98.2462, y: 27.7472), CGPoint(x: 97.9120, y: 28.3359), CGPoint(x: 97.3271, y: 28.2616), CGPoint(x: 96.2488, y: 28.4110), CGPoint(x: 96.5866, y: 28.8310), CGPoint(x: 96.1177, y: 29.4528), CGPoint(x: 95.4048, y: 29.0317), CGPoint(x: 94.5660, y: 29.2774), CGPoint(x: 93.4133, y: 28.6406), CGPoint(x: 92.5031, y: 27.8969), CGPoint(x: 91.6967, y: 27.7717), CGPoint(x: 91.2589, y: 28.0406), CGPoint(x: 90.7305, y: 28.0650), CGPoint(x: 90.0158, y: 28.2964), CGPoint(x: 89.4758, y: 28.0428), CGPoint(x: 88.8142, y: 27.2993), CGPoint(x: 88.7303, y: 28.0869), CGPoint(x: 88.1204, y: 27.8765), CGPoint(x: 86.9545, y: 27.9743), CGPoint(x: 85.8233, y: 28.2036), CGPoint(x: 85.0116, y: 28.6428), CGPoint(x: 84.2346, y: 28.8399), CGPoint(x: 83.8990, y: 29.3202), CGPoint(x: 83.3371, y: 29.4637), CGPoint(x: 82.3275, y: 30.1153), CGPoint(x: 81.5258, y: 30.4227), CGPoint(x: 81.1113, y: 30.1835), CGPoint(x: 79.7214, y: 30.8827), CGPoint(x: 78.7389, y: 31.5159), CGPoint(x: 78.4584, y: 32.6182), CGPoint(x: 79.1761, y: 32.4838), CGPoint(x: 79.2089, y: 32.9944), CGPoint(x: 78.8111, y: 33.5062), CGPoint(x: 78.9123, y: 34.3219), CGPoint(x: 77.8375, y: 35.4940), CGPoint(x: 76.1928, y: 35.8984), CGPoint(x: 75.8969, y: 36.6668), CGPoint(x: 75.1580, y: 37.1330), CGPoint(x: 74.9800, y: 37.4200), CGPoint(x: 74.8300, y: 37.9900), CGPoint(x: 74.8648, y: 38.3788), CGPoint(x: 74.2575, y: 38.6065), CGPoint(x: 73.9289, y: 38.5058), CGPoint(x: 73.6754, y: 39.4312), CGPoint(x: 73.9600, y: 39.6600), CGPoint(x: 73.8222, y: 39.8940), CGPoint(x: 74.7769, y: 40.3664), CGPoint(x: 75.4678, y: 40.5621), CGPoint(x: 76.5264, y: 40.4279), CGPoint(x: 76.9045, y: 41.0665), CGPoint(x: 78.1872, y: 41.1853), CGPoint(x: 78.5437, y: 41.5822), CGPoint(x: 80.1194, y: 42.1239), CGPoint(x: 80.2600, y: 42.3500)],
        [CGPoint(x: 121.7778, y: 24.3943), CGPoint(x: 121.1756, y: 22.7909), CGPoint(x: 120.7471, y: 21.9706), CGPoint(x: 120.2201, y: 22.8149), CGPoint(x: 120.1062, y: 23.5563), CGPoint(x: 120.6947, y: 24.5385), CGPoint(x: 121.4950, y: 25.2955), CGPoint(x: 121.9512, y: 24.9976), CGPoint(x: 121.7778, y: 24.3943)],
    ]
}

struct JourneyMapView: View {
    @Bindable var store: GameStore
    var height: CGFloat = 260
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flight: CGFloat = 0
    @State private var departing = false
    private func point(_ longitude: Double, _ latitude: Double, _ size: CGSize) -> CGPoint {
        // One scale for both projected axes: the coastline and markers cannot stretch.
        let longitudeScale = cos(35.0 * .pi / 180)
        let mapWidth = 65 * longitudeScale
        let mapHeight = 38.0
        let scale = min(max(0, size.width - 48) / mapWidth, max(0, size.height - 48) / mapHeight)
        return CGPoint(
            x: (size.width - mapWidth * scale) / 2 + (longitude - 72) * longitudeScale * scale,
            y: (size.height - mapHeight * scale) / 2 + (55 - latitude) * scale)

    }
    var body: some View {
        GeometryReader { geometry in
            let controlsWidth: CGFloat = 160
            let gap: CGFloat = 20
            let mapWidth = min(560, max(0, geometry.size.width - controlsWidth - gap))
            HStack(spacing: gap) {
                GeometryReader { g in
                    ZStack(alignment: .topLeading) {
                        Canvas { context, size in
                            for ring in ChinaGeometry.rings {
                                var path = Path()
                                for (index, coordinate) in ring.enumerated() {
                                    let p = point(coordinate.x, coordinate.y, size)
                                    if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
                                }
                                path.closeSubpath()
                                context.fill(path, with: .color(Color(red: 0.38, green: 0.48, blue: 0.35)))
                                context.stroke(path, with: .color(IvyType.cream.opacity(0.65)), lineWidth: 1)
                            }
                            if store.memories.routeCorrect {
                                let start = point(120.1551, 30.2741, size), end = point(114.1694, 22.3193, size)
                                var route = Path(); route.move(to: start); route.addLine(to: end)
                                context.stroke(route, with: .color(IvyType.cream), style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
                            }
                        }
                        ForEach(Array(JourneyCity.all.enumerated()), id: \.element.id) { index, city in
                            Button { store.selectCity(city.name) } label: {
                                ZStack {
                                    Circle().fill(IvyType.ink).frame(width: 22, height: 22)
                                    Circle().fill(store.memories.origin == city.name || store.memories.destination == city.name ? Color(red: 0.82, green: 0.61, blue: 0.29) : IvyType.cream).frame(width: 13, height: 13)
                                    if store.memories.origin == city.name { Text("1").font(IvyType.hand(15)).foregroundStyle(IvyType.ink) }
                                    if store.memories.destination == city.name { Text("2").font(IvyType.hand(15)).foregroundStyle(IvyType.ink) }
                                }.frame(width: 48, height: 48).contentShape(Circle())
                            }.buttonStyle(.plain).position(point(city.longitude, city.latitude, g.size))
                                .accessibilityLabel("City marker \(index + 1)").disabled(departing)
                                .allowsHitTesting(false)
                                .accessibilityAction { if !departing { store.selectCity(city.name) } }
                        }
                        if departing {
                            let start = point(120.1551, 30.2741, g.size), end = point(114.1694, 22.3193, g.size)
                            Image(systemName: "airplane").font(.system(size: 28)).foregroundStyle(.orange)
                                .rotationEffect(.degrees(115))
                                .position(x: start.x + (end.x - start.x) * flight, y: start.y + (end.y - start.y) * flight)
                        }
                    }.contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { tap in
                        guard !departing else { return }
                        let nearest = JourneyCity.all.min { a, b in
                            let pa = point(a.longitude, a.latitude, g.size), pb = point(b.longitude, b.latitude, g.size)
                            return hypot(pa.x - tap.location.x, pa.y - tap.location.y) < hypot(pb.x - tap.location.x, pb.y - tap.location.y)
                        }
                        if let city = nearest {
                            let p = point(city.longitude, city.latitude, g.size)
                            if hypot(p.x - tap.location.x, p.y - tap.location.y) <= 28 { store.selectCity(city.name) }
                        }
                    })
                // Keep the map's geographic projection uniform while allowing the
                // panel to use more of the available stage on wide phones.
                }.frame(width: mapWidth, height: min(300, geometry.size.height))
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        selection(1, selected: store.memories.origin != nil)
                        Image(systemName: "arrow.right").font(.system(size: 17))
                            .foregroundStyle(IvyType.cream.opacity(0.6))
                        selection(2, selected: store.memories.destination != nil)
                    }
                    PuzzleButton(departing ? "on our way…" : "depart") { departing = true }
                        .disabled(!store.canDepart || departing)
                        .opacity(store.canDepart ? 1 : 0.45)
                }.frame(width: controlsWidth, height: min(300, geometry.size.height))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .task(id: departing) {
            guard departing else { return }
            withAnimation(.easeInOut(duration: reduceMotion ? 0 : 1.8)) { flight = 1 }
            do { try await Task.sleep(for: .milliseconds(reduceMotion ? 50 : 1900)) } catch { return }
            store.departFlight()
        }
    }
    private func selection(_ number: Int, selected: Bool) -> some View {
        Text("\(number)")
            .font(IvyType.hand(23))
            .foregroundStyle(selected ? IvyType.ink : IvyType.cream.opacity(0.65))
            .frame(width: 48, height: 48)
            .background(Circle().fill(selected ? IvyType.cream : IvyType.ink.opacity(0.35)))
            .overlay(Circle().stroke(IvyType.cream.opacity(0.45), lineWidth: 1))
            .accessibilityLabel("Selection \(number)")
            .accessibilityValue(selected ? "Selected" : "Empty")
    }

}
