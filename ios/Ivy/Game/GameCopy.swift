import Foundation

/// Shared game copy and accessible letter text. Keep puzzle answers out of player-facing hints.
enum GameCopy {
    static let wrongAnswer = "Not quite."
    /// Placeholder in the door field. Must not be the answer.
    static let lyricPlaceholder = "a line the house remembers"

    /// Locked door before the mailbox letter is collected. Names the paper, not the puzzle.
    static let doorNeedsLetter = "A letter is still waiting in the mailbox."

    /// Cancel control on the input board.
    static let cancel = "Cancel"
    /// Confirm control on the input board.
    static let confirm = "Enter"
    /// Spoken line on the intro artwork.
    static let introTitle = "Come in from the cold."
    /// Pixel BACK plate on the lyric lock.
    static let lockBack = "Back"
    /// Pixel DEL plate on the lyric lock.
    static let lockDel = "Delete last letter"
    /// Pixel RESET plate on the lyric lock.
    static let lockReset = "Reset"
    /// Pixel ENTER plate on the lyric lock.
    static let lockEnter = "Enter"
    /// Plate ivy covering the mailbox engraving.
    static let plateIvy = "Ivy covering a private line."
    /// Uncovered mailbox engraving. Never names 817.
    static let plaqueEngraving = "the date we became a story"
    /// Letter after the mailbox date. Unrolls once; the letter is the first egg.
    static let letterMemory = "A little house full of us."
    static let rulesEnvelope = "for you, always. " + letterMemory + " with love, in every room."
    static let skyLine = "some things grow quietly."
    static let mailboxTitle = "a little history"
    static let doorTitle = "what the walls remember"
    static let doorInscription = "your ivy grows,\nand now i'm…"
    static let letterCollected = "the first thing i kept."
    static let letterTitle = "for you, always"
    static let letterStanzas = [
        letterMemory
    ]
    static let letterSignature = "with love,\nin every room"
    static let letterClose = "fold this moment away"
    /// Mailbox field placeholder.
    static let plaquePlaceholder = "a date the box keeps"
}
