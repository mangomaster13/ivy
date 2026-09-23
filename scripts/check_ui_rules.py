from pathlib import Path
import re
swift=list(Path('ios/Ivy').rglob('*.swift'))
assert not any(re.search(r'\b(TextField|TextEditor|UITextField|UITextView)\s*\(',p.read_text()) for p in swift)
for p in swift:
 for line in p.read_text().splitlines():
  if re.search('[\u4e00-\u9fff]',line):
   raise AssertionError((p, line))
configs=[]
for p in swift:
 configs+=re.findall(r'glyphs: "([a-z]+)", limit: (\d+)',p.read_text())
for answer in ['as a whole','hope','stay']:
 assert any(len(answer)<=int(n) and set(answer.replace(' ',''))<=set(g) for g,n in configs), answer
vuori = Path('ios/Ivy/Game/VuoriPuzzle.swift').read_text()
letters = re.search(r'static let letters = Array\("([a-z]+)"\)', vuori).group(1)
assert len(letters) == len(set(letters)) == 9 and set('vuori') <= set(letters)
print('PASS: no free input; all player copy is English; text answers and Vuori path reachable from supplied tiles')

# Inspection/puzzle layouts must fit a landscape screen. World inventory may scroll.
for name in ['MemoryCloseups.swift', 'JourneyMap.swift', 'IvyMessages.swift', 'GelatoCloseups.swift', 'VuoriViews.swift']:
 source = Path('ios/Ivy/Game', name).read_text()
 assert not re.search(r'\bScrollView\s*(?:\(|\{)', source), f'{name}: scrolling is forbidden in puzzle/inspection UI'
source = Path('ios/Ivy/Game/ExplorationViews.swift').read_text().split('struct AdventurePanelView: View', 1)[1]
assert not re.search(r'\bScrollView\s*(?:\(|\{)', source), 'Adventure panels must use fixed layout or explicit pages'
print('PASS: puzzle, closeup and feedback layouts contain no scroll views')
