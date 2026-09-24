#!/usr/bin/env python3
"""Run the production closeup camera math without building or launching the app."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]

def declaration(path, name):
    source = (root / path).read_text()
    start = source.index('enum ' + name + ' {')
    return source[start:source.index('\n}', start) + 2]

source = 'import Foundation\nimport CoreGraphics\n'
source += declaration('ios/Ivy/Game/WonderlandScenes.swift', 'SceneDetailCamera') + '\n'
source += declaration('ios/Ivy/Game/DictionaryViews.swift', 'DictionaryCamera') + '\n'
source += '''
let details = [CGRect(x: 92, y: 108, width: 135, height: 49),
               CGRect(x: 48, y: 59, width: 182, height: 53),
               CGRect(x: 20, y: 24, width: 210, height: 105),
               CGRect(x: 125, y: 95, width: 64, height: 32),
               CGRect(x: 70, y: 110, width: 64, height: 32)]
for height in stride(from: CGFloat(160), through: 480, by: 40) {
    let size = CGSize(width: height * 2, height: height)
    let viewport = CGRect(origin: .zero, size: size)
    for detail in details {
        let camera = SceneDetailCamera.rect(containing: detail, viewport: size)
        assert(abs(camera.width / camera.height - 2) < 0.00001)
        assert(camera.insetBy(dx: -0.001, dy: -0.001).contains(detail))
        assert(CGRect(x: 0, y: 0, width: 320, height: 160).contains(camera))
    }
    for writing in [false, true] {
        let frame = DictionaryCamera.artworkFrame(in: size, writing: writing)
        assert(frame.insetBy(dx: -0.001, dy: -0.001).contains(viewport))
        assert(abs(frame.width / frame.height - 16.0 / 9.0) < 0.00001)
        if writing {
            let ink = CGRect(x: frame.minX + frame.width * 0.49,
                             y: frame.minY + frame.height * 0.29,
                             width: frame.width * 0.31, height: frame.height * 0.30)
            assert(viewport.contains(ink))
            assert(ink.maxY < height - 88, "Ink overlaps actions/feedback")
        }
    }
'''
# Execute the menu's actual layout expressions, not a second copy of the algorithm.
menu = (root / 'ios/Ivy/Game/BigTopViews.swift').read_text()
start = menu.index('                let rows =')
source += menu[start:menu.index('                let order =', start)]
source += '''
    assert(rowHeight >= 48)
    assert(columnWidth >= 48)
    assert(size.height * 0.24 + rowHeight * CGFloat(rows) <= size.height * 0.86 + 0.001)
    assert(columns * rows >= 10)
}
print("PASS: full viewport coverage, preserved camera details, ink clearance, menu row bounds (160–480 pt)")
'''
with tempfile.TemporaryDirectory(prefix='ivy-closeup-check-') as work:
    check = Path(work) / 'check.swift'
    check.write_text(source)
    subprocess.run(['swift', '-module-cache-path', str(Path(work) / 'modules'), str(check)], check=True)
