import Foundation

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

    var aligned: Bool { filmInserted && !flipped && abs(x) <= 3 && abs(y) <= 3 }
    var complete: Bool { aligned && seats == [12, 13] }

    mutating func sanitize() {
        x = x.isFinite ? min(55, max(-55, x)) : 32
        y = y.isFinite ? min(35, max(-35, y)) : -24
        seats = Set(seats.filter { (0..<20).contains($0) }.sorted().prefix(2))
        if filmInserted { filmTaken = true }
        if filmTaken { caseOpened = true }
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

    func removeCinemaFilm() {
        guard cinemaActive, overlay == .memory(.cinemaProjector), cinema.filmInserted,
              !cinema.solved else { return }
        cinema.filmInserted = false
        acquire(.cinemaFilm)
        persistNow()
    }

    func moveCinemaFilm(x: Double, y: Double) {
        guard cinemaActive, overlay == .memory(.cinema), cinema.filmInserted,
              !cinema.solved, x.isFinite, y.isFinite else { return }
        cinema.x = min(55, max(-55, x))
        cinema.y = min(35, max(-35, y))
        dismissSceneHint()
        schedulePersist()
    }

    func flipCinemaFilm() {
        guard cinemaActive, overlay == .memory(.cinema), cinema.filmInserted, !cinema.solved else { return }
        cinema.flipped.toggle()
        dismissSceneHint()
        persistNow()
    }

    func selectCinemaSeat(_ seat: Int) {
        guard cinemaActive, overlay == .memory(.cinema), cinema.filmInserted,
              !cinema.solved, (0..<20).contains(seat) else { return }
        if cinema.seats.contains(seat) { cinema.seats.remove(seat) }
        else if cinema.seats.count < 2 { cinema.seats.insert(seat) }
        dismissSceneHint()
        persistNow()
    }

    func submitCinemaSeats() {
        guard cinemaActive, overlay == .memory(.cinema), !cinema.solved else { return }
        guard cinema.complete else {
            showInputError("The picture is still in pieces.")
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
            progress = CinemaProgress(caseOpened: true, filmTaken: true, filmInserted: true,
                                      flipped: false, x: 0, y: 0, seats: [12, 13], solved: true, exitUnlocked: true)
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
