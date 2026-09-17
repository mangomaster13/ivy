import Foundation

/// Spoken copy for the yard. Lyrics never appear as the typed answer.
enum GameCopy {
    /// Placeholder in the door field. Must not be the answer.
    static let lyricPlaceholder = "a line the house remembers"

    /// Vine breadcrumb, weakest → strongest. Still no full lyric, no 817 digits.
    static let vineHints = [
        "It keeps finding the stones.",
        "What you hummed was never a name for a house.",
        "The last of that song ends the way this wall ends.",
        "Who the green takes — and a day that belongs to August."
    ]

    /// Sky / stars. Names the blank without filling it.
    static let skyFlavor = "A line waits where the clouds part."
    /// Path and grass.
    static let grassFlavor = "The path still holds the cold."
    /// House stones that are not a hotspot.
    static let stoneFlavor = "Only stone. Nothing is written into it."
    /// Hall furniture before those rooms are built.
    static let hallRest = "The other rooms are still asleep. The door already knows your mouth."
    /// Re-read after 9.29 is collected.
    static let plaqueReread = "The ninth month. The twenty-ninth day."
    /// First collect of the mailbox egg.
    static let plaqueCollected = "September twenty-nine. The box will keep it."
    /// Wrong digits on the mailbox.
    static let plaqueWrong = "Not this number. The letters are still asleep."
    /// Chorus tail is right; August day is missing or wrong.
    static let lyricMissingDate = "Half a key. The rest is a day this post does not keep."
    /// They glued on 9.29 from the mailbox.
    static let lyricPlaqueDate = "That date lives on the box. The door wants another."
    /// They typed 817 and nothing of the lyric.
    static let lyricDateOnly = "The day is right. The green still has to say who it took."
    /// They typed the game name.
    static let lyricTooShort = "Too close to a title. The song does not stop at a name."

    /// Cancel control on the input board.
    static let cancel = "Cancel"
    /// Confirm control on the input board.
    static let confirm = "Enter"
    /// Title on the boot card.
    static let introTitle = "Start your adventure"
    /// Pixel ENTER plate on the boot card.
    static let introEnter = "Enter"
    /// Mailbox field placeholder.
    static let plaquePlaceholder = "a date the box keeps"

    /// Escalating generic misses. Index is the fail count after this miss (1...).
    static func lyricHint(forFailCount count: Int) -> String {
        switch count {
        case 1:
            return "Not the name on the roof."
        case 2:
            return "The last words fall on a person. Not the date on the post."
        default:
            return "Who the green takes, and a day in August."
        }
    }
}
