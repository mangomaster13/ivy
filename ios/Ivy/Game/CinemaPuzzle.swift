import Foundation
import CoreGraphics

struct CinemaFilmPosition: Codable, Equatable {
    var x: Double
    var y: Double
    var flipped: Bool
}

struct CinemaProgress: Codable, Equatable {
    var caseOpened = false
    var filmTaken = false
    var filmInserted = false
    var flipped = true
    // Offsets use the projection artwork's 591 × 296 reference canvas.
    var x = 32.0
    var y = -24.0
    var seats: Set<Int> = []
    var solved = false
    var exitUnlocked = false
    // Optional additions preserve the shipped one-film save format.
    var films: [CinemaFilmPosition]? = nil
    var activeFilm: Int? = nil
    var projectionRevealed: Bool? = nil

    var layers: [CinemaFilmPosition] {
        get {
            films ?? [CinemaFilmPosition(x: x, y: y, flipped: flipped),
                      CinemaFilmPosition(x: -39, y: 21, flipped: false),
                      CinemaFilmPosition(x: 17, y: 31, flipped: true)]
        }
        set { films = newValue }
    }
    var selectedFilm: Int { min(2, max(0, activeFilm ?? 0)) }
    var projectionReady: Bool { projectionRevealed == true || solved }
    var projectionOffset: CGPoint {
        guard projectionReady else { return .zero }
        return CGPoint(x: layers.map(\.x).reduce(0, +) / 3,
                       y: layers.map(\.y).reduce(0, +) / 3)
    }

    var aligned: Bool {
        let placed = layers
        guard filmInserted, placed.count == 3,
              placed.allSatisfy({ !$0.flipped && $0.x.isFinite && $0.y.isFinite }) else { return false }
        // There is no stationary answer layer: any common translation is valid.
        return placed.map(\.x).max()! - placed.map(\.x).min()! <= 3
            && placed.map(\.y).max()! - placed.map(\.y).min()! <= 3
    }
    var complete: Bool { filmInserted && projectionReady && seats == [12, 13] }

    mutating func sanitize() {
        x = x.isFinite ? min(55, max(-55, x)) : 32
        y = y.isFinite ? min(35, max(-35, y)) : -24
        seats = Set(seats.filter { (0..<20).contains($0) }.sorted().prefix(2))
        if filmInserted { filmTaken = true }
        if filmTaken { caseOpened = true }
        var restored = layers
        let fallback = CinemaProgress().layers
        restored = (0..<3).map { index in
            guard index < restored.count else { return fallback[index] }
            var layer = restored[index]
            layer.x = layer.x.isFinite ? min(55, max(-55, layer.x)) : fallback[index].x
            layer.y = layer.y.isFinite ? min(35, max(-35, layer.y)) : fallback[index].y
            return layer
        }
        layers = restored
        activeFilm = selectedFilm
        if projectionReady {
            filmInserted = true
            filmTaken = true
            caseOpened = true
            projectionRevealed = true
            if !aligned {
                layers = Array(repeating: CinemaFilmPosition(x: 0, y: 0, flipped: false), count: 3)
            }
        }
    }
}

extension GameStore {
    var cinema: CinemaProgress {
        get { memories.cinema ?? CinemaProgress() }
        set { memories.cinema = newValue }
    }

    private var cinemaActive: Bool {
        room == .cinema && !isIntro && !isHallTransitioning && collectingEgg == nil
    }

    func openCinemaCase() {
        guard cinemaActive, overlay == .memory(.cinemaCase), !cinema.caseOpened else { return }
        cinema.caseOpened = true
        persistNow()
    }

    func takeCinemaFilm() {
        guard cinemaActive, overlay == .memory(.cinemaCase), cinema.caseOpened,
              !cinema.filmTaken, !cinema.solved else { return }
        cinema.filmTaken = true
        acquire(.cinemaFilm)
        persistNow()
    }

    func insertCinemaFilm() {
        guard cinemaActive, overlay == .memory(.cinemaProjector), !cinema.solved,
              cinema.filmTaken, !cinema.filmInserted, use(.cinemaFilm) else { return }
        cinema.filmInserted = true
        exploration.tools.remove(.cinemaFilm)
        dismissSceneHint()
        persistNow()
        openMemory(.cinema)
    }

    func moveCinemaFilm(x: Double, y: Double) {
        guard cinemaActive, overlay == .memory(.cinema), cinema.filmInserted,
              !cinema.projectionReady, x.isFinite, y.isFinite else { return }
        let index = cinema.selectedFilm
        cinema.layers[index].x = min(55, max(-55, x))
        cinema.layers[index].y = min(35, max(-35, y))
        dismissSceneHint()
        schedulePersist()
    }

    func flipCinemaFilm() {
        guard cinemaActive, overlay == .memory(.cinema), cinema.filmInserted, !cinema.projectionReady else { return }
        let index = cinema.selectedFilm
        cinema.layers[index].flipped.toggle()
        dismissSceneHint()
        persistNow()
    }

    func selectCinemaFilm(_ index: Int) {
        guard cinemaActive, overlay == .memory(.cinema), cinema.filmInserted,
              !cinema.projectionReady, (0..<3).contains(index) else { return }
        cinema.activeFilm = index
        dismissSceneHint()
        persistNow()
    }

    func submitCinemaProjection() {
        guard cinemaActive, overlay == .memory(.cinema), cinema.filmInserted,
              !cinema.projectionReady else { return }
        guard cinema.aligned else {
            showWrongAnswer()
            return
        }
        // Keep the player's assembled picture in place; only reveal the heart.
        cinema.projectionRevealed = true
        dismissSceneHint()
        persistNow()
    }

    func selectCinemaSeat(_ seat: Int) {
        guard cinemaActive, overlay == .memory(.cinema), cinema.filmInserted,
              cinema.projectionReady, !cinema.solved, (0..<20).contains(seat) else { return }
        if cinema.seats.contains(seat) { cinema.seats.remove(seat) }
        else if cinema.seats.count < 2 { cinema.seats.insert(seat) }
        dismissSceneHint()
        persistNow()
    }

    func submitCinemaSeats() {
        guard cinemaActive, overlay == .memory(.cinema), !cinema.solved else { return }
        guard cinema.complete else {
            showWrongAnswer()
            return
        }
        cinema.solved = true
        cinema.exitUnlocked = true
        memories.opened.insert("cinema")
        collected.insert(.cinema)
        toolsVisible = false
        consume(.cinemaFilm)
        persistNow()
        replayKeepsake(.cinema)
    }

    func migrateCinema() {
        var progress = cinema
        progress.sanitize()
        if memories.cinema == nil {
            progress.exitUnlocked = [.dictionary, .ferris, .taxi].contains(room)
                || !collected.isDisjoint(with: [.dictionary, .ferris, .taxi])
                || ["dictionary", "ferris", "taxi"].contains { exploration.views[$0] != nil }
        }
        if collected.contains(.cinema) || memories.opened.contains("cinema") || progress.solved {
            let savedLayers = progress.projectionReady ? progress.layers : nil
            progress = CinemaProgress(caseOpened: true, filmTaken: true, filmInserted: true,
                                      flipped: false, x: 0, y: 0, seats: [12, 13], solved: true, exitUnlocked: true,
                                      films: Array(repeating: CinemaFilmPosition(x: 0, y: 0, flipped: false), count: 3),
                                      activeFilm: 0, projectionRevealed: true)
            if let savedLayers { progress.layers = savedLayers }
            memories.opened.insert("cinema")
            collected.insert(.cinema)
            memories.used.insert(.cinemaFilm)
        }
        if progress.filmTaken { memories.picked.insert(.cinemaFilm) }
        if progress.filmInserted || progress.solved {
            exploration.tools.remove(.cinemaFilm)
            if selectedTool == .cinemaFilm { selectedTool = nil }
        } else if progress.filmTaken {
            exploration.tools.insert(.cinemaFilm)
        }
        cinema = progress
    }
}
