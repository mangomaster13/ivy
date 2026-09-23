<!-- impeccable:product-schema 1 -->

# Ivy — Product Requirements

This document is the product source of truth. The game-design and motion notes remain annexes for room layout and animation vocabulary. If they conflict with this document, this document wins.

## Platform

ios

## Stack

SwiftUI, iOS 17+, existing Xcode project. Bundle ID `com.ivy.gift`.

## Users

Primary: one person (the gift recipient), Hangzhou, busy, iPhone, possibly likes rust-lake-style observation games. Plays in landscape, possibly lying down or switching to WeChat mid-session.

Secondary: the author, who ships via TestFlight and supplies leftover observation lines, a prize letter, and an optional photo. Puzzle answers are locked in this document.

---

## Problem Statement

He lives in Hangzhou, works long days, and keeps an iPhone in his pocket. The author wants to give him a house that exists only on that phone: a small 16-bit stone cottage whose hall hides a rabbit hole into a private Hong Kong, where thirteen objects wait in the rooms they belong in, and where the front door only opens if he remembers a line they already share.

A website, an H5 lottery, a map, labelled prev/next rooms, or an App Store page would make this feel public and disposable. Packing many souvenirs into one cottage would make the memories feel like a trophy case. A system keyboard on the front door would make the house feel like a form. He may lie down. He may jump to WeChat and come back. The gift has to survive both without teaching alerts, accounts, or a second layout.

Success is not “content consumed.” Success is: he finishes or leaves safely in one sitting, recognizes several of the thirteen objects without being told, walks the hole without a map, and feels he pushed a cartridge in — not opened a webpage.

## Solution

Ivy is a private landscape iPhone gift. He rotates into a 320×160 night cottage, looks closer, collects, and watches ivy remember him.

The cottage is only two rooms: the yard and the hall. The mailbox is a key, not an egg. Tapping it cuts to a 3×3 assemble plate. Plate ivy covers `the date we met` until he taps it. When the stave is exactly `817` on Enter, the house remembers the date, stays in the yard, and collects nothing. There is no rules envelope. The front door still waits for that paper: before `817` it speaks `A letter is waiting in the box.` and will not open the lyric lock. After `817`, the lyric lock accepts `coveredinyou` on Enter, collects `ivy`, and cuts to the hall.

The hall is ordinary stone: Vuori on a hanger, a rabbit hole in the floor, a dark lottery machine. Tapping the hole drops him into Wonderland Hong Kong. There is no map. He walks a line of rooms by tapping objects that already belong there. Each Hong Kong room holds one egg, except the seaview bedroom, which holds `city` and `rose`. The lottery only lights in the hall when all thirteen bar slots are full; he must climb back out of the hole to claim it. Climbing back is the plane’s return hole, or the taxi’s car door.

The thirteen eggs, in bar order, are: `ivy`, `vuori`, `plane`, `keycard`, `city`, `rose`, `gelato`, `noodle`, `supermarket`, `cinema`, `sunset`, `ferris`, `taxi`.

Hong Kong, in walk order after the hole: plane (arrivals) → hotel corridor → seaview bedroom → gelato stall → Big Top → supermarket → cinema → sunset → ferris → taxi. Cinema EXIT always goes to sunset. He cannot skip to the ferris.

Some rooms are observation. Some are in-world machines in the rusty-lake sense: he does not tap “next” to win them. The corridor wheels accept `1608`. The gelato stall wants pistachio and stracciatella. The taxi meter wants `stay`. The rose uses scheme A: the jellycat close-up has twelve petals; the nightstand holds the thirteenth plush petal; he taps that petal, then the rose, and the house collects `rose`.

The house speaks only when speech is the point. Empty taps on sky, stones, and path stay quiet. Yard vines still deepen a breadcrumb. Assemble misses use a hairline caption, not a teaching family and never `The box does not forget.`

Progress lives on this device. Distribution is TestFlight to one Apple ID. The prize is predetermined.

## User Stories

1. As the gift recipient, I want the house to live only on my iPhone, so that the gift feels addressed to me rather than published.

2. As the gift recipient, I want to open Ivy from a home-screen icon with no account and no network permission, so that I can play immediately.

3. As the gift recipient, I want a portrait hold to tell me to rotate, so that I understand the cartridge is landscape within three seconds.

4. As the gift recipient, I want landscape-left and landscape-right both to work, so that I can hold the phone whichever way is comfortable, including lying down.

5. As the gift recipient, I want the first launch to play a short intro of ivy writing across the house, so that entering feels like putting a cartridge in.

6. As the gift recipient, I want to skip or tap through the intro once the sentence has formed, so that I am not trapped in a title card.

7. As the gift recipient, I want later launches to skip the intro and resume where I left, so that killing the app is not punished with a replay.

8. As the gift recipient, I want Reduce Motion to freeze the intro on the finished sentence, so that the house still greets me without a writing animation.

9. As the gift recipient, I want to land in the yard after the intro, so that the first playable room is the locked front of the house.

10. As the gift recipient, I want a living night in the yard (ivy sway, drifting cloud), so that the house feels inhabited before I have opened the door.

11. As the gift recipient, I want Reduce Motion to freeze sway and cloud while leaving the sky blank readable, so that atmosphere never becomes a barrier.

12. As the gift recipient, I want the sky to show `your ivy grows, ____` without writing the chorus or `817`, so that I am pointed at a remembered line rather than given the password.

13. As the gift recipient, I want tapping the sky, stones, or path to stay quiet, so that looking around is not a chatter of flavor plaques.

14. As the gift recipient, I want tapping either vine to give a spoken breadcrumb that never writes the full lyric or the August digits, so that I can get unstuck without the house taking the puzzle away.

15. As the gift recipient, I want vine hints to deepen across taps and then hold on the strongest line, so that repeated tapping still talks without looping from the weakest hint.

16. As the gift recipient, I want tapping the locked front door before I have entered `817` on the mailbox to stay in the yard and hear `A letter is waiting in the box.`, so that the house points at the paper without teaching me to “unlock the mailbox first.”

17. As the gift recipient, I want that blocked door tap to open no lyric lock, keep no new stave, and shuffle no pad, so that I am not dropped into a puzzle I have not earned.

18. As the gift recipient, I want tapping the same locked door again to speak that same sentence, so that the house does not escalate into an alert, rotate hints, or write `817`.

19. As the gift recipient, I want tapping the mailbox to cut to a 3×3 assemble plate in the same iron language as the door, so that the box feels like part of the house and not a system number pad.

20. As the gift recipient, I want a clump of ivy on that plate to cover the engraving `the date we met` until I tap it, so that the date is a look-closer, not a label.

21. As the gift recipient, I want glyphs to stay tappable while that ivy is still there, so that I am not forced through a wipe before I can try the day.

22. As the gift recipient, I want tapping that plate ivy to recede the vine and show the hairline `The date we met.`, so that the engraving is readable without writing `817`.

23. As the gift recipient, I want Reduce Motion to cut that ivy on the same tap, so that the date is still readable without a recede.

24. As the gift recipient, I want Enter on the mailbox to check the stave, so that typing `817` is not enough until I confirm.

25. As the gift recipient, I want an exact stave of `817` on Enter to remember the date, stay in the yard, and collect no egg, so that the box is a key and not a souvenir.

26. As the gift recipient, I want that mailbox success to add no extra spoken line and unroll no rules envelope, so that success is the door becoming willing, not a tutorial.

27. As the gift recipient, I want a wrong mailbox Enter to keep the digits and show `Punishment is on the way.` every time, so that the sting does not escalate into a second line.

28. As the gift recipient, I want repeating a wrong mailbox Enter to show that same caption, so that fail count never rotates a hint family.

29. As the gift recipient, I want September decoys on the mailbox pad never to open the box, so that `929` is not a secret second day.

30. As the gift recipient, I want tapping the used mailbox after `817` to stay quiet in the yard, so that the box does not become a second door.

31. As the gift recipient, I want idle flash to prefer the mailbox until `817` is accepted, then the door, so that the house points at the next willing object without a quest marker.

32. As the gift recipient, I want tapping the locked door after `817` to cut to a 320×160 lyric lock with a stave and a 4×4 pad of letter plates, so that the chorus is assembled, not typed on a keyboard.

33. As the gift recipient, I want Enter on that lock to check the stave, so that a prefix of the line is quiet until I confirm.

34. As the gift recipient, I want an exact stave of `coveredinyou` on Enter to unlock the door, collect `ivy`, and cut to the hall, so that the first egg is the wall that covered him.

35. As the gift recipient, I want that door success to add no extra spoken line, so that success is the hall, not a toast.

36. As the gift recipient, I want any other door stave after Enter, including `coveredinyou817`, only `817`, only `ivy`, or an old alias, to stay, shake, and show `You know how that line ends.`, so that special cases do not leak teaching.

37. As the gift recipient, I want repeating a wrong door Enter to show that same caption, so that fail count never rotates a hint family.

38. As the gift recipient, I want Backspace to drop the last glyph and Reset to clear the stave while staying on the lock, so that I can correct myself without leaving the plate.

39. As the gift recipient, I want Cancel to return to the yard with the stave kept, so that peeking at the sky does not wipe my line.

40. As the gift recipient, I want interior doors and the rabbit hole never to ask for the lyric again, so that the house knows me after one line.

41. As the gift recipient, I want tapping a filled ivy slot to re-speak the last vine line, so that the bar is memory, not a caption dump.

42. As the gift recipient, I want the hall to feel like ordinary stone, so that Wonderland is a surprise under the floor rather than a labelled second world.

43. As the gift recipient, I want tapping Vuori in the hall to collect `vuori` with a short English input whose default answer is `vuori`, so that the hanger is a private word and not the 4×4 lyric lock.

44. As the gift recipient, I want a wrong Vuori word to stay on that input and sting once without teaching copy, so that guessing is allowed and the chorus is not leaked.

45. As the gift recipient, I want hall furniture that is not Vuori, the hole, or the lottery to stay quiet on tap, so that a stub hall does not lecture about the door.

46. As the gift recipient, I want tapping the rabbit hole in the hall to drop me into the plane (arrivals), so that Hong Kong begins as a fall, not a map pin.

47. As the gift recipient, I want that fall to keep my collected eggs and not reset the house, so that the hole is a door, not a new save.

48. As the gift recipient, I want no room titles, floor list, tabs, or “previous / next” chrome, so that I walk by looking, not by UI.

49. As the gift recipient, I want each Hong Kong room change to swap the plate in the same shell, so that travel feels like the cottage, not a navigation stack.

50. As the gift recipient, I want to walk Hong Kong by tapping diegetic objects, so that the next place is a thing I already recognize.

51. As the gift recipient, I want the plane’s boarding pass to be both the `plane` egg and the DEPART that walks me to the hotel corridor, so that the stub is souvenir and doorway.

52. As the gift recipient, I want to be able to DEPART the plane before I have collected the boarding pass, so that the egg is optional in that room and never a gate.

53. As the gift recipient, I want the plane’s other hole to climb back to the hall, so that I can return the way I fell.

54. As the gift recipient, I want tapping the plane hole labelled as the hole I came through to return to the hall, so that “back” is the arrival void, not a button named Back.

55. As the gift recipient, I want the hotel corridor’s back object to return me to arrivals, so that the elevator / arrivals end of the hall is the way I came.

56. As the gift recipient, I want the corridor to hold an in-world 4-digit wheel lock for the bedroom door, so that the room number is a rusty-lake machine and not a system keyboard.

57. As the gift recipient, I want those wheels to accept only `1608`, never `817`, `13`, or `1313`, so that the mailbox day and the lucky count do not leak into the hotel.

58. As the gift recipient, I want a wrong corridor Enter to keep the wheels and sting with one hairline that does not teach the digits, so that I can try again without a hint family.

59. As the gift recipient, I want a correct corridor code on Enter to open the bedroom door without collecting an egg, so that `keycard` is collected as its own object, not as “the door opened.”

60. As the gift recipient, I want tapping the keycard (or the opened door’s card) to collect `keycard` once the code is known, so that the souvenir is the card, not the hallway.

61. As the gift recipient, I want the corridor’s forward object, after the code, to be the bedroom door into the seaview room, so that I do not walk through a locked plate.

62. As the gift recipient, I want the seaview bedroom to be one room that holds both the harbour window and the jellycat rose, so that city and bed share a hotel night instead of two staged sets.

63. As the gift recipient, I want tapping the harbour window to look closer at the city and collect `city`, so that the view is the souvenir, not a named Hong Kong title on the room.

64. As the gift recipient, I want collecting `city` to require looking, not a password, so that the window is observation.

65. As the gift recipient, I want tapping the jellycat on the bed to look closer at a rose with exactly twelve petals, so that I can see it is incomplete.

66. As the gift recipient, I want a thirteenth plush petal waiting on the nightstand in that same room, so that lucky 13 is a missing piece, not a second number pad.

67. As the gift recipient, I want tapping that nightstand petal to pick it up without filling a bar slot, so that I am holding a petal, not collecting a fourteenth egg.

68. As the gift recipient, I want tapping the rose while holding that petal to attach it and collect `rose`, so that the toy is complete at 13.

69. As the gift recipient, I want tapping the rose without the petal to collect nothing, so that looking at twelve petals is not enough.

70. As the gift recipient, I want that rose completion never to ask me to type 13, unfold 13 times, or spin a dial, so that scheme A stays a petal count I can see.

71. As the gift recipient, I want the bedroom’s back object to return me to the corridor, so that the hotel door is still the way I came.

72. As the gift recipient, I want the bedroom’s forward object to be an umbrella that walks me to the rain gelato stall, so that weather carries me out of the hotel.

73. As the gift recipient, I want to collect `city` and `rose` in either order, so that the window and the toy do not gate each other.

74. As the gift recipient, I want to leave the bedroom without collecting either egg, so that observation souvenirs are never a door.

75. As the gift recipient, I want the gelato stall to show six flavor marks, so that taste is a choice, not a look-only plaque.

76. As the gift recipient, I want exactly two of those six flavors to be correct, so that the stall remembers a shared order, not a single scoop.

77. As the gift recipient, I want a wrong flavor tap to clear the whole selection and show `Not that taste.`, so that a miss cannot be patched by adding the right scoop on top.

78. As the gift recipient, I want two correct flavor taps to collect `gelato` with no extra spoken success line, so that the cup is the souvenir.

79. As the gift recipient, I want the two correct flavors to be pistachio and stracciatella, in either order, against vanilla, matcha, mango, and dark chocolate, so that the stall remembers a shared cup and not a later rewrite.

80. As the gift recipient, I want the gelato stall’s back object to be the wet awning returning to the bedroom, so that rain is the way I came.

81. As the gift recipient, I want the gelato stall’s forward object to be Big Top neon walking me to the noodle room, so that the sign is already a destination.

82. As the gift recipient, I want the noodle room to start with a garbled neon sign, so that the name is hidden until I touch the whole board.

83. As the gift recipient, I want tapping that garbled sign to go dark and then show unlit BIGTOP letters, so that the joke is assembled in the world, not typed.

84. As the gift recipient, I want tapping B, I, G, T, O, P in that order to collect `noodle`, so that the name is the puzzle.

85. As the gift recipient, I want a wrong letter in that order to extinguish the lights and show `The name is the joke.`, so that I start the spelling again without a teaching family.

86. As the gift recipient, I want that neon puzzle to remain BIGTOP, so that the stall keeps its real name.

87. As the gift recipient, I want the noodle room’s back object to be rain on glass returning to the gelato stall, so that weather is still the way I came.

88. As the gift recipient, I want the noodle room’s forward object to be a supermarket entrance, so that the next street is a door I can see.

89. As the gift recipient, I want tapping the supermarket ceiling or shelf to look closer and collect `supermarket`, so that the condom memory is observation, not packaging art.

90. As the gift recipient, I want that supermarket close-up to avoid illustrated packaging, so that the joke stays private and the plate stays the house’s drawing.

91. As the gift recipient, I want the supermarket’s back object to be a goose bag returning to Big Top, so that the shopper’s bag is the way I came.

92. As the gift recipient, I want the supermarket’s forward object to be a movie stub on a receipt walking me to the cinema, so that paper already points at the film.

93. As the gift recipient, I want the cinema kiosk to ask for two lines, `FALL2` and `HOPE`, so that eight years of films are assembled in the world, not typed on a keyboard.

94. As the gift recipient, I want a wrong kiosk Enter to keep the stave and sting once without writing the titles for me, so that I can try again.

95. As the gift recipient, I want a correct kiosk Enter to collect `cinema` with no extra spoken success line, so that the ticket is the souvenir.

96. As the gift recipient, I want the cinema’s back object to be a supermarket bag returning to the shop, so that I retrace the receipt.

97. As the gift recipient, I want the cinema EXIT always to walk me to sunset, so that I cannot skip from the kiosk to the ferris.

98. As the gift recipient, I want tapping the sunset sky to look closer and collect `sunset`, so that the colour is observation.

99. As the gift recipient, I want the sunset’s back object to be cinema doors, so that EXIT is still behind me.

100. As the gift recipient, I want the sunset’s forward object to be the ferris on the skyline, so that the wheel is already in the view.

101. As the gift recipient, I want tapping the night harbour from the ferris to look closer and collect `ferris`, so that the ride is observation.

102. As the gift recipient, I want the ferris’s back object to be orange sky in the glass returning to sunset, so that the last colour is still behind me.

103. As the gift recipient, I want the ferris’s forward object to be a taxi queue walking me to the cab, so that the night ends on the street.

104. As the gift recipient, I want the taxi meter to accept the short English word `stay`, so that the cab is a private line and not the lyric lock.

105. As the gift recipient, I want a wrong meter word to stay on the meter and sting once without teaching, so that I can try again.

106. As the gift recipient, I want a correct meter word to let me look closer at the kiss and collect `taxi`, so that the word opens the souvenir rather than skipping it.

107. As the gift recipient, I want the taxi’s back object to be ferris lights in the rear window, so that the wheel is still behind me.

108. As the gift recipient, I want tapping the taxi’s car door to climb back to the hall, so that the cab is the second way out of Wonderland.

109. As the gift recipient, I want to climb back to the hall from the plane hole or the taxi door even if Hong Kong eggs are still empty, so that return is never gated on collecting.

110. As the gift recipient, I want the hall to still be the cottage when I climb out, so that Wonderland was under the floor, not a replacement house.

111. As the gift recipient, I want each room except the seaview bedroom to hold at most one egg, so that souvenirs do not pile into a hub.

112. As the gift recipient, I want no map, minimap, compass, or room name chrome, so that I never see “Hong Kong” as a title.

113. As the gift recipient, I want place names to live on objects, not on room titles, so that the gift stays private.

114. As the gift recipient, I want a shared bar of thirteen slots, so that I can feel how much of the house still remembers me.

115. As the gift recipient, I want empty slots to stay night silhouettes and filled slots to show a 32-pixel object mark, so that thirteen souvenirs are still readable at a glance.

116. As the gift recipient, I want tapping a filled slot to re-read that object’s last private line or last frame, so that the bar is a pocket, not a toast history.

117. As the gift recipient, I want the lottery machine to stay dark until all thirteen slots are full, so that the prize cannot be claimed early.

118. As the gift recipient, I want the lottery to light only in the hall, so that filling the bar in Hong Kong does not teleport me or pop an alert.

119. As the gift recipient, I want to walk back through the hole’s return (plane or taxi) to claim the prize, so that the last act is climbing out, not a cutscene skip.

120. As the gift recipient, I want the prize to be predetermined, so that the gift does not gamble.

121. As the gift recipient, I want progress to persist on this device, including which room I am in, which eggs I hold, whether `817` is known, whether the door is open, puzzle drafts, and whether I am holding the thirteenth petal, so that a WeChat jump does not rewind the night.

122. As the gift recipient, I want disposable spoken lines not to persist, so that a relaunch does not reopen a sting caption.

123. As the gift recipient, I want assemble overlays, drafts, and pad order to persist if I leave mid-lock, so that Cancel and a kill are not two different punishments.

124. As the gift recipient, I want every spoken player line to use sentence case and end with a period, so that the house has one written voice.

125. As the gift recipient, I want control labels (Back, Enter, Reset, Cancel) to stay Title Case and empty-stave placeholders to stay lowercase, so that chrome is not mistaken for the house speaking.

126. As the gift recipient, I want lock hairline captions only for consequence (wrong Enter, plate ivy, gelato miss, BIGTOP miss, and the other in-world machines), so that help text is not atmosphere.

127. As the gift recipient, I want a correct collect to add no extra spoken line, so that success is the object and the bar, not a toast.

128. As the gift recipient, I want Reduce Motion to keep state changes and skip walk/shake offsets, so that I can still finish the house.

129. As the gift recipient, I want hit targets to stay at least 44pt, including lock plates, wheels, flavor marks, neon letters, bar slots, the hole, and diegetic nav objects, so that landscape play is tappable while lying down.

130. As the gift recipient, I want pixel plates and dialogue boxes to be the interface, so that SF Symbols and system alerts never become how the house speaks.

131. As the gift recipient, I want the hotel, gelato stall, and taxi to already know `1608`, pistachio plus stracciatella, and `stay`, so that those machines are finished puzzles, not blanks for later.

132. As the author, I want to ship via TestFlight to one Apple ID, so that the gift is never an App Store page.

133. As the gift recipient, I want tapping yard vines to still only speak, so that outdoor ivy and plate ivy stay two different objects.

134. As the gift recipient, I want the uncovered mailbox engraving never to write `817`, so that the box still asks me to remember the day.

135. As the gift recipient, I want no finger-drag, dust mask, or scratch-off on the mailbox plate, so that the house does not invent a fourth verb for one breadcrumb.

136. As the gift recipient, I want the blocked-door line to be the house speaking in the yard dialogue plaque, not a lock caption and not a system alert, so that it feels like looking around, not failing a quiz.

137. As the gift recipient, I want that line never to say unlock, first, mailbox, pad, password, or `817`, so that I am pointed at a letter rather than given a quest marker.

138. As the gift recipient, I want a blocked door tap to use the same soft speech haptic as tapping a yard vine, so that it does not feel as if the lock just opened.

139. As the gift recipient, I want dismissing that line to leave me in the yard with the door still locked, so that I can turn to the box.

140. As the gift recipient, I want yard vine density to grow with the mailbox date remembered and `ivy` collected, so that outdoor ivy still answers progress without a letter egg.

141. As the gift recipient, I want whole-house ivy opacity to be allowed to follow total eggs collected, so that the wall can remember him as the bar fills.

142. As the gift recipient, I want the hall lamp to toggle only hall art if a lamp ships, so that light is atmosphere, not a lock on other eggs.

143. As the gift recipient, I want the boarding-pass DEPART stub to stay visible after `plane` is collected, so that collecting the egg does not remove the doorway.

144. As the gift recipient, I want collecting `plane` from the boarding pass not to auto-walk me to the corridor, so that souvenir and travel stay two taps.

145. As the gift recipient, I want the hotel wheels to be four independent digits I can change in the world, so that the corridor is not a 3×3 mailbox clone.

146. As the gift recipient, I want the thirteenth petal to persist as held if I leave the bedroom and return, so that I cannot lose the petal by walking to the window.

147. As the gift recipient, I want holding the petal not to occupy a bar slot, so that lucky 13 is the completed rose, not a temporary item icon.

148. As the gift recipient, I want gelato selection to show which correct flavors I have already tapped until a miss clears them, so that the two-scoop order is readable.

149. As the gift recipient, I want BIGTOP lights that are already correct to go dark with the rest on a miss, so that a wrong letter is a full extinguish, not a partial save.

150. As the gift recipient, I want to re-tap the garbled sign after a BIGTOP miss to begin the unlit letters again, so that the joke can be retried.

151. As the gift recipient, I want cinema `FALL2` and `HOPE` to be two kiosk lines, not one concatenated stave that hides the films, so that both titles are visible as themselves.

152. As the gift recipient, I want observation close-ups (city, supermarket, sunset, ferris) to collect on look, then back to the room, so that those eggs stay two-layer: house, then look-closer.

153. As the gift recipient, I want in-world machines (mailbox, door, wheels, gelato, BIGTOP, kiosk, Vuori, taxi) to stay in the same shell as look-closer, so that navigation depth is never a third stack.

154. As the gift recipient, I want a miss tap in a Hong Kong room that is not a hotspot to stay quiet, so that flavor plaques do not cover the street.

155. As the gift recipient, I want the rabbit hole in the hall to stay tappable after I have climbed out, so that I can fall in again to finish eggs I skipped.

156. As the gift recipient, I want skipped eggs to remain in their rooms, so that I can finish the bar without a checklist UI.

157. As the gift recipient, I want the lottery claim to be allowed to be the longest transition in the gift, so that the prize letter can feel like paper.

158. As the gift recipient, I want VoiceOver on controls to remain labelled even if flavor VoiceOver is still unwritten, so that the house is operable.

159. As the gift recipient, I want killing the app in Wonderland to restore that same Hong Kong room, so that the hole is not a dream that forgets me.

160. As the gift recipient, I want the gift to remain iPhone-only, offline, and unlisted, so that finishing it still feels like a cartridge, not a product.

161. As the gift recipient, I want every room, lock, close-up, and overlay that sits on the house canvas to stay 16-bit world pixels, so that walking into Hong Kong does not suddenly look like a different game.

162. As the gift recipient, I want bar marks to use a 32-pixel HUD grid, so that gelato, rose, and taxi do not collapse into 16×16 candy blobs.

163. As the gift recipient, I want those HUD marks displayed at 32pt with nearest-neighbor scaling, so that extra source pixels actually appear on screen instead of being squashed back into a 16pt hole.

164. As the gift recipient, I want on and off marks for the same egg to share one silhouette, so that an empty slot is the night of the object, not a different drawing.

165. As the gift recipient, I want 32-pixel HUD art never composited into the 320×160 plate, so that a sharper gelato in the bar does not sit as a sticker on the stall.

166. As the gift recipient, I want look-closer plates to stay 320×160 16-bit, so that detail lives in a full-screen night, not in a raised-resolution room.

167. As the gift recipient, I want sprite-sheet frames that play on the house to keep world texel size, so that ivy, envelope, and intro writing do not mix a second grid into the cottage.

168. As the gift recipient, I want no third size (24×24, 48 shown at 16pt, 640×320 rooms), so that authors pick world or HUD and stop.

169. As the gift recipient, I want 16-bit and 32-pixel art to share the night cottage palette (cream, iron, ivy, night navy), so that a finer bar still belongs to the same house.

170. As the gift recipient, I want integer ×3 catalog images for both tracks, so that a 3x phone never shows half-pixels.

171. As the gift recipient, I want SF Symbols and smooth photographs kept off the house and off the bar, so that “more pixels” never means a vector glyph or a camera still.

172. As the author, I want a single SOP that says which track an asset is on before I draw it, so that Wonderland rooms are not accidentally authored like HUD marks.

## Implementation Decisions

- The gift is one SwiftUI iOS 17+ app, iPhone only, offline, no accounts. Landscape left and right are the supported orientations. There is no second portrait layout; a portrait-held phone is asked to rotate.

- Logical playable canvas is 320×160, nearest-neighbor scaled, centered in the night letterbox, kept inside the safe area. Intro art may use a slightly wider first-run plate so vines can reach the landscape edges, then play drops to the 320×160 rooms.

- Art SOP (two tracks only). “16-bit” is the SNES cottage grid, not 16-bit color. Both tracks ship as PNG with alpha as needed. There is no 24×24 middle grid and no 640×320 “32-bit room.”

  - **16-bit world** — everything composited onto the house canvas: room bases, transparent patches, yard vines, cloud, sky blank, lock plates, assemble tiles and glyphs, plate ivy, dialogue plaque art, look-closer plates, hole/taxi cuts, prize letter plate, intro frames (even if the intro plate is slightly wider), and any sprite-sheet cell that plays on that canvas. One source texel equals one world pixel on the 320×160 plate (intro width may exceed 320; texel size stays the same). Author 1x at that pixel size; ship @3x at exact 3× nearest-neighbor. No sub-pixel outlines, no blur, no SDF, no smooth gradient fills that read as illustration.

  - **32-pixel HUD** — inventory bar marks only (on and off for each of the thirteen eggs). Author 32×32; display 32×32 pt; ship @3x at 96×96. Nearest-neighbor. Same silhouette for on/off; on is the colored object, off is the night-navy cutout. Hits stay at least 44pt around the 32pt mark. Thirteen 32pt slots plus spacing still sit in the landscape letterbox.

  - **Assignment test:** if it is drawn inside the 320×160 (or intro) compositor, it is 16-bit world. If it is a collectible mark in the bottom bar, it is 32-pixel HUD. If it is neither (letterbox color, system rotate prompt, short English field chrome), it is not pixel art.

  - **Scale law:** only integer multiples (1× and 3×). Never show a 32×32 mark at 16pt. Never upscale a 16×16 mark to 32pt as a substitute for redrawing. Never drop a 32-pixel HUD drawing onto a room plate, lock, or close-up.

  - **Palette:** both tracks use the cottage night (night navy, iron, cream, ivy). Extra pixels add silhouette and one or two interior marks (two scoops, a petal notch, a taxi lamp), not a new lighting model.

  - **Sheets:** world animations are strips of 16-bit frames whose cell size matches the overlay they replace. HUD marks are not on those sheets.

- Navigation depth is always two: the house, then look-closer or assemble or short input, then back to the house. Room changes swap the plate in the same shell. They are not a navigation stack, tabs, sheets, walk meters, or labelled prev/next.

- Cottage rooms are only `yard` and `hall`. Kitchen, stairs, and a cottage bedroom are retired; those memories live in Hong Kong. Interior cottage doors never lock once the lyric is accepted.

- Wonderland rooms after the hall hole, in order: `plane`, `corridor`, `bedroom`, `gelato`, `noodle`, `supermarket`, `cinema`, `sunset`, `ferris`, `taxi`. Cinema EXIT always walks to `sunset`. No edge walks from cinema to `ferris`.

- Diegetic nav (object → destination), locked:

  - Hall hole → plane. Plane hole → hall. Plane DEPART stub → corridor.
  - Corridor back (arrivals / elevator) → plane. Corridor forward (bedroom door, after code) → bedroom.
  - Bedroom back (hotel door) → corridor. Bedroom forward (umbrella) → gelato.
  - Gelato back (wet awning) → bedroom. Gelato forward (Big Top neon) → noodle.
  - Noodle back (rain on glass) → gelato. Noodle forward (supermarket entrance) → supermarket.
  - Supermarket back (goose bag) → noodle. Supermarket forward (movie stub on receipt) → cinema.
  - Cinema back (supermarket bag) → supermarket. Cinema EXIT → sunset.
  - Sunset back (cinema doors) → cinema. Sunset forward (ferris on skyline) → ferris.
  - Ferris back (orange sky in glass) → sunset. Ferris forward (taxi queue) → taxi.
  - Taxi back (ferris lights in rear window) → ferris. Taxi car door → hall.

- One observable store owns play state: current room, collected eggs, overlays, door-opened, mailbox-opened (`817` accepted), hall lamp, intro-seen, lottery-drawn, lyric and mailbox drafts and pads, whether the mailbox engraving has been uncovered, petal-held, gelato selection, BIGTOP phase and typed prefix, corridor wheels, kiosk drafts, Vuori and taxi drafts, fail/hint counters, and the atmosphere tick. Views call verbs on that store; they do not keep a second source of progress.

- Persist a single on-device snapshot. Coalesce writes; flush when leaving the scene. Do not restore disposable dialogue. Do persist overlays, drafts, pad order, mailbox engraving uncovered, mailbox-opened, petal-held, and puzzle machine state. Intro-seen belongs in that snapshot; a relaunch must not force the title card again.

- The three verbs stay look closer, collect, and the house remembers. Tapping a door or a diegetic nav object is still tap. Assemble and in-world machines are variants of tap, not a fourth verb. Tapping plate ivy is look closer on the mailbox plate.

- Yard order: mailbox date before lyric lock. Mailbox success is not an egg. The first bar slot is `ivy` at the door. The retired `letter` / `sep29` egg is gone. Idle flash prefers the mailbox until `817`, then the door.

- Thirteen eggs in bar order: `ivy`, `vuori`, `plane`, `keycard`, `city`, `rose`, `gelato`, `noodle`, `supermarket`, `cinema`, `sunset`, `ferris`, `taxi`. Drop `letter`, `suitcase`, and `pillow`.

- One egg per room except `bedroom`, which holds `city` (window) and `rose` (jellycat). Nav never requires those eggs.

- Lyric assemble rules:

  - Enter checks the stave. An empty Enter is a no-op.
  - Exact stave `coveredinyou` is correct: unlock, collect `ivy`, cut to hall.
  - A stave that is a prefix of that answer is quiet until Enter; then it is wrong if it is not exact.
  - Any other stave after Enter is wrong: keep the text, warn, show `You know how that line ends.`, do not unlock. Repeat misses use that same line.
  - Aliases (`iamcoveredinyou`, `coveredinyou817`, `8.17`, `0817`, spaces, `929` glued onto the lyric) never count and receive the same caption.
  - Unique pad glyphs are `c d e i n o r u v y` plus decoys `8 1 7 9 a s`.
  - Cap 20. Shuffle on open; freeze while open; do not highlight the next correct plate; do not draw twelve empty slots.

- Both cottage assemble plates check on Enter. Typing the exact answer is not enough. There is no system keyboard on the front door or mailbox.

- Mailbox is not a system number pad. It is a 3×3 assemble plate, exact stave `817`, remember on Enter, stay in the yard, collect nothing, unroll no envelope. Normalization aliases are unnecessary because the pad has neither dot nor zero. September decoys may sit on this pad; they must not open the mailbox. A wrong Enter keeps the digits and shows `Punishment is on the way.` every time. Never `The box does not forget.` After success, further mailbox taps in the yard are quiet.

- Spoken copy is one voice:

  - Sentence case, period at the end, no chorus, no `817`, no unlock / password / “tap the vine first.”
  - Dialogue plaque: blocked door `A letter is waiting in the box.`; yard vines, weakest to strongest — `The ivy keeps finding these stones.` / `What you hummed was never just a name.` / `That song ends on a person. So does this wall.` / `Who it covered. And a day that only August keeps.` The last vine line is also the ivy-slot re-read.
  - Hairline caption: plate ivy `The date we met.`; mailbox miss `Punishment is on the way.`; door miss `You know how that line ends.`; gelato miss `Not that taste.`; BIGTOP miss `The name is the joke.`
  - Success (hall cut, egg collect, lottery) adds no extra spoken line.
  - Control labels stay Title Case. Empty-stave placeholders stay lowercase.
  - Sky, stones, path, unfinished hall furniture, and empty Hong Kong taps do not speak. A miss tap may keep a soft haptic.

- Plate ivy lives on the mailbox scene, composed under the pad as a backdrop over the engraving band. The shared assemble pad does not grow a dust flag. Persist a boolean, not a pixel mask. Reduce Motion cuts the ivy on the same tap.

- Door tap without `817`: stay in the yard. Speak `A letter is waiting in the box.` through the yard dialogue plaque. Do not open the lyric lock. Repeat taps speak that same sentence.

- Hall `vuori` is short English input; the answer is `vuori`. Taxi meter is short English input; the answer is `stay`. These two may use a short system field. They are not the 4×4 lyric lock. Do not convert the whole game into assemble pads.

- Corridor lock is four in-world digit wheels. Exact code `1608`. Forbidden guesses that must never count: `817`, `13`, `1313`. Correct Enter opens the bedroom door; `keycard` collects as its own egg. Wrong Enter keeps wheels and one non-teaching sting.

- Rose is scheme A (from the design lock, not a prototype demo): jellycat close-up shows 12 petals; nightstand holds the 13th plush petal; tap petal to hold; tap rose while holding to collect `rose`. No number pad, no 13-tap unfold, no second dial. Held petal persists in the snapshot and is not a bar slot.

- Gelato: six flavors, exactly two correct. Correct: pistachio and stracciatella, either order. Decoys: vanilla, matcha, mango, dark chocolate. A wrong tap clears the selection and shows `Not that taste.` Two correct taps collect `gelato`.

- Noodle / Big Top: start garbled neon → tap the whole sign → dark unlit BIGTOP letters → tap `B-I-G-T-O-P` in order. A wrong tap extinguishes lights, shows `The name is the joke.`, and clears the prefix. Keep the BIGTOP name.

- Cinema kiosk: two lines `FALL2` and `HOPE`. In-world assemble, Enter checks. Observation eggs `city`, `supermarket`, `sunset`, `ferris` collect on look-closer. `plane` collects from the boarding pass independently of DEPART.

- Yard vine density is `min(2, ivyCollected + mailboxOpened)` and grows both flanks together. Whole-house ivy opacity may still follow total eggs collected.

- Lottery is predetermined and lives in the hall. Thirteen full slots light the machine; they do not teleport or alert. He must be in the hall to claim. Climb out via plane hole or taxi door.

- Feedback: haptics first, then a short layer transition. Room plates always cut frames with animation disabled on the image swap. Pixel atmosphere (yard only) is stepped. System-layer motion is reserved for close-ups, dialogue, the bar punch, plate-ivy recede, the door’s first black cut, the hole fall, and the prize letter.

- Hit targets are at least 44pt, including the 32pt HUD marks sitting inside a 44pt well. Pixel plates and dialogue boxes are the interface. SF Symbols are not the main UI. System alerts are not how the house speaks.

- Prototype reducer shape worth keeping (throwaway HTML; trim is the path and the verbs, not the demo): rooms `yard`, `hall`, then `plane → corridor → bedroom → gelato → noodle → supermarket → cinema → sunset → ferris → taxi`; hole destination is the plane, never a walk that lands back in hall; DEPART and collect are separate plane verbs; cinema EXIT is sunset only.

- Author-supplied content still open: leftover observation lines, prize letter, optional photo. Locked answers: door `coveredinyou`; mailbox `817`; hotel wheels `1608`; gelato pistachio + stracciatella; taxi `stay`; vuori `vuori`; cinema `FALL2` + `HOPE`; BIGTOP order; rose scheme A (12 + 1 petal); sky blank; gelato miss `Not that taste.`; BIGTOP miss `The name is the joke.`; engraving `the date we met`; blocked-door line; mailbox miss; door miss; no App Store listing.

## Testing Decisions

A good test asserts what the player can observe after a verb: which room they are in, which overlay is up, which eggs are in the bar, whether the door is open, whether `817` is known, what the stave or wheels contain, whether the thirteenth petal is held, whether gelato selection cleared, whether BIGTOP lights extinguished, whether a snapshot round-trip restores that, and which spoken line is showing. Tests do not assert SwiftUI structure, asset catalog names, PNG pixel dimensions, animation durations, haptic generator classes, or cloud pixel offsets except where Reduce Motion must leave the sky blank readable. The art SOP is an authoring contract, not a second test module.

**Seam (one):** the store’s public commands — the same verbs the canvas already calls (tap door, tap yard vine, tap mailbox, tap plate ivy, append glyph, submit, backspace, reset, cancel, miss, collect/re-read, walk diegetic object, fall hole, climb out, hold petal, tap flavor, tap neon letter, persist/restore). Matching helpers the store already uses (prefix / exact / wrong for `coveredinyou`; mailbox exact `817`; corridor exact `1608`; taxi exact `stay`; door gated on mailbox-opened; vine stage; engraving uncovered; rose petal-then-rose; gelato pistachio+stracciatella; BIGTOP order) are part of that seam, not a second one. Spoken copy is an observable of those verbs, not a second module.

Do not add view-level tests, snapshot tests of pixels, or a parallel reducer unless the store cannot be driven without the run loop. If persistence must be injected so tests do not share the device defaults, that port still sits under the same store seam.

There is no existing test target. Prior art is none; the first tests should be command-surface tests around the mailbox-as-key gate (no letter egg, no envelope), `coveredinyou` door collecting `ivy`, quiet miss taps, one-line lock captions, persistence, vine stage, hole → plane (not hall), cinema EXIT → sunset, DEPART without collecting `plane`, rose 12+1, corridor `1608`, gelato pistachio+stracciatella with clear-on-wrong, taxi `stay`, BIGTOP extinguish-on-wrong, lottery dark until 13 and only claimable in hall, and snapshot restore in a Wonderland room.

## Out of Scope

- Cottage kitchen, stairs, or bedroom rooms; packing those memories back into the stone house.
- A map, minimap, floor list, tabs, compass, or labelled Previous / Next.
- A letter / `sep29` egg, a rules envelope after `817`, or treating mailbox success as a bar slot.
- A fourteenth egg, a petal bar slot, or a second collectible in any room other than city+rose in the seaview bedroom.
- Interior key-and-door locks in the cottage, walk meters, combat, crafting, death, daily streaks.
- Asking the lyric on the vines as well as the door.
- Opening the lyric lock before `817` is accepted.
- System keyboard, free text, or aliases on the front door or mailbox.
- Auto-collect on a mailbox stave of `817` before Enter.
- Treating `coveredinyou817` or `929` as an accepted stave anywhere.
- Forcing plate ivy to be tapped before mailbox glyphs may be used.
- A finger-drag, dust mask, or scratch-off as the way to read `the date we met`.
- Putting plate ivy, dust, or `the date we met` onto the door pad.
- Next-correct-plate highlighting, length-leaking empty slots, a 36-key alphabet pad, shuffle-in animations.
- Auto-reset on a wrong stave, kicking the player to the yard on a miss, red full-screen flashes, teaching alerts.
- Teaching copy on a blocked door (`unlock the mailbox`, `do this first`, a quest marker, `817`).
- Escalating lock-hint families, `The box does not forget.`, and door captions that teach the mailbox day or the chorus.
- Flavor plaques on sky, stones, path, windows, or unfinished hall furniture.
- Writing the full chorus or `817` into the sky, plates, stave placeholder, or hints.
- Dual portrait/landscape layouts, WKWebView, rotating old portrait frames as rooms.
- Room titles that name Hong Kong or a second city. Place names belong on objects.
- Skipping cinema EXIT to the ferris.
- Gating DEPART, the hole, or the taxi door on collecting that room’s egg.
- Hotel codes `817`, `13`, or `1313`.
- Rose as type-13, unfold-13, or a second number pad.
- Replacing BIGTOP with another name, or dropping the garbled-then-order neon.
- Illustrated condom packaging in the supermarket close-up.
- Whole-house power switch, lamp locking other eggs, two things glowing at once as a puzzle.
- Lottery lighting or claiming inside Wonderland, true-random prize, iCloud, Apple Watch, widgets, push, App Store.
- A third art grid (24×24, 48×48 shown at 16pt, 640×320 rooms) or mixing 32-pixel HUD drawings into the house canvas.
- Treating “32-bit” as photographic color depth, smooth vectors, or SF Symbols for eggs.
- Keeping 16×16 bar icons, or blowing them up to 32pt without redrawing.

## Further Notes

- This rewrite absorbs the old nine-egg cottage sheet, the mailbox-first / envelope change, plate ivy, spoken-copy pass, the 13-egg rabbit-hole / Wonderland HK lock (diegetic nav, merged seaview bedroom, in-world machines, rose scheme A), and the art SOP (16-bit world vs 32-pixel HUD). The motion note still governs how the reveals move; it does not own lock rules, room order, or copy. Scene-by-scene build order lives in the implementation plan.

- Current store gaps against this document, on purpose, so an implementer does not treat the build as the spec: nine `EggId`s including `sep29` / `suitcase` / `pillow`; rooms only yard and a mute hall; mailbox still collects a letter and unrolls a nine-egg envelope; no rabbit hole; no Wonderland rooms or machines; lottery still described as nine slots; bar icons are still 16×16 shown at 16pt. Yard spoken copy, `coveredinyou`, mailbox `817`, plate ivy, and quiet misses may already match this document in the living build — the world structure and HUD mark size do not.

- The shareable logic prototype may still show an older path (split city/keycard/rose rooms, look-only gelato, prev/next labels). It is throwaway. The reducer bits worth keeping are listed under Implementation Decisions.

- VoiceOver copy for flavor lines is still unwritten. Control labels on plates already exist and should stay.

- Reduce Motion is a first-class path, not a polish pass: freeze atmosphere, skip walk/shake offsets, keep state changes, cut plate ivy on tap with no recede, skip hole-fall offsets.
