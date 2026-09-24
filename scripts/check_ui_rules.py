from pathlib import Path
import re
swift=list(Path('ios/Ivy').rglob('*.swift'))
fields = [p for p in swift if re.search(r'\b(TextField|TextEditor|UITextField|UITextView)\s*\(', p.read_text())]
assert fields == [Path('ios/Ivy/Locks/AssemblePad.swift')], fields
input_source = fields[0].read_text()
assert 'IvyType.script(' in input_source and 'GameTextInputFocusKey' in input_source
assert not any('SuppliedKeyGrid(' in p.read_text() for p in swift)
for p in swift:
 for line in p.read_text().splitlines():
  if re.search('[\u4e00-\u9fff]',line):
   raise AssertionError((p, line))
whole = Path('ios/Ivy/Game/MemoryCloseups.swift').read_text()
later = Path('ios/Ivy/Game/LaterMemories.swift').read_text()
assert re.search(r'wholeDraft,\s*limit: 10', whole)
assert re.search(r'taxiDraft,\s*limit: 4', later)
vuori = Path('ios/Ivy/Game/VuoriPuzzle.swift').read_text()
letters = re.search(r'static let letters = Array\("([a-z]+)"\)', vuori).group(1)
assert len(letters) == len(set(letters)) == 9 and set('vuori') <= set(letters)
print('PASS: shared Juniper system input; all player copy is English; answer limits and Vuori path present')

# Inspection/puzzle layouts must fit a landscape screen. World inventory may scroll.
for name in ['MemoryCloseups.swift', 'JourneyMap.swift', 'IvyMessages.swift', 'GelatoCloseups.swift', 'VuoriViews.swift']:
 source = Path('ios/Ivy/Game', name).read_text()
 assert not re.search(r'\bScrollView\s*(?:\(|\{)', source), f'{name}: scrolling is forbidden in puzzle/inspection UI'
source = Path('ios/Ivy/Game/ExplorationViews.swift').read_text().split('struct AdventurePanelView: View', 1)[1]
assert not re.search(r'\bScrollView\s*(?:\(|\{)', source), 'Adventure panels must use fixed layout or explicit pages'
print('PASS: puzzle, closeup and feedback layouts contain no scroll views')
