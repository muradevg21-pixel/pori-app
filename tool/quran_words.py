"""Helpers to locate example words in the bundled (verified) Quran data."""
import json, re
from pathlib import Path

_STRIP = re.compile('[ً-ٰٟۖ-ۭـ]')


def norm(s):
    return _STRIP.sub('', s).replace('ٱ', 'ا').replace('أ', 'ا') \
        .replace('إ', 'ا').replace('آ', 'ا')


_cache = {}


def words(ref):
    s, a = map(int, ref.split(':'))
    if s not in _cache:
        _cache[s] = json.loads(Path(f'assets/quran/surah/{s:03d}.json').read_text())['v']
    return [w[0] for w in _cache[s][a - 1]['w']]


def locate(ref, target):
    """1-based word positions in verse `ref` whose plain letters match `target`
    (space separated, written without diacritics)."""
    ws = [norm(w) for w in words(ref)]
    t = [norm(x) for x in target.split()]
    for i in range(len(ws) - len(t) + 1):
        if all(ws[i + j].endswith(t[j]) if j == 0 else ws[i + j].startswith(t[j])
               for j in range(len(t))) and (len(t) > 1 or ws[i] == t[0] or ws[i].endswith(t[0])):
            return list(range(i + 1, i + len(t) + 1))
    raise ValueError(f'{target!r} not found in {ref}: {words(ref)}')
