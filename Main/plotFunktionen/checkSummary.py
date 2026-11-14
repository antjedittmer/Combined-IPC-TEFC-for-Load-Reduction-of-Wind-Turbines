"""Check that the summary tables of the thesis follow from the wind speed tables.

Recomputes the IPC (tab:IPC_summary) and AALC (tabone) summary tables of the
thesis chapter from IPCAALCtables/tab_IPC_windspeeds.tex and
tab_AALC_windspeeds.tex (makeIPCAALC_WindSpeedTables) and compares them at
two decimals:
- C_DEL_b, C_DEL_t, C_DEL_tt, C_P, C_dP: mean of the wind speeds of the range
- C_Act: sum of P_Act / sum of P_Act,0 over the wind speeds of the range
Differences of one in the last digit come from the rounded values in the
wind speed tables (e.g. the actuator powers with one decimal) and are only
reported as rounding.

Usage: python checkSummary.py [chapter.tex]
"""
import os
import re
import sys

here = os.path.dirname(os.path.abspath(__file__))
tabDir = os.path.join(here, 'IPCAALCtables')
chap = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    here, '..', '..', '..', 'thesis_DLR_20260630', 'chapters', '04_WindTurbineControl_02_notBold.tex')
crit = ['C_DEL_b', 'C_DEL_t', 'C_DEL_tt', 'C_P', 'C_dP', 'C_Act']


def perWindSpeed(f, aalc):
    """Rows (dataset, ws, 5 criteria, P_Act0, P_Act) of a wind speed table."""
    rows, ds = [], None
    for line in open(f, encoding='utf-8'):
        c = [x.strip() for x in line.strip().rstrip('\\').split('&')]
        if len(c) < 10 or not re.fullmatch(r'\d+', c[2]):
            continue
        ds = c[0] or ds
        v = c[3 + 2 + aalc:]  # after dataset, class, wind speed and the 2 (IPC) or 3 (AALC) gains
        rows.append((ds, int(c[2]), [float(x) for x in v[:5]], float(v[5]), float(v[6])))
    return rows


def summary(lines):
    """Rows (range, dataset, 6 criteria) of a summary table in the chapter."""
    rows, rng = [], None
    for line in lines:
        c = [x.strip() for x in line.strip().rstrip('\\').split('&')]
        if len(c) != 9 or c[1] == 'Dataset':
            continue
        if c[0]:
            m = re.search(r'(\d+)--(\d+)|(\d+)\\,m/s', c[0])
            rng = (int(m[1]), int(m[2])) if m[1] else (int(m[3]), int(m[3]))
        rows.append((rng, c[1], [None if x == '--' else float(x) for x in c[3:]]))
    return rows


txt = open(chap, encoding='utf-8').read().splitlines()
tabs = {}
for name, label in [('IPC', r'\label{tab:IPC_summary}'), ('AALC', r'\label{tabone}')]:
    # table environment that contains the (uncommented) label
    i = next(k for k, l in enumerate(txt) if label in l and not l.lstrip().startswith('%'))
    a = max(k for k in range(i + 1) if r'\begin{table}' in txt[k])
    b = next(k for k in range(i, len(txt)) if r'\end{table}' in txt[k])
    tabs[name] = summary(txt[a:b])

ok = True
for name, aalc in [('IPC', 0), ('AALC', 1)]:
    W = perWindSpeed(os.path.join(tabDir, 'tab_%s_windspeeds.tex' % name), aalc)
    print('%s: %d wind speed rows, %d summary rows' % (name, len(W), len(tabs[name])))
    for rng, ds, ref in tabs[name]:
        sel = [w for w in W if w[0] == ds and rng[0] <= w[1] <= rng[1]]
        val = [sum(w[2][j] for w in sel) / len(sel) for j in range(5)]
        val.append(sum(w[4] for w in sel) / sum(w[3] for w in sel))
        for j, (v, r) in enumerate(zip(val, ref)):
            if r is None:
                continue
            d = abs(round(v, 2) - r)
            if d > 0.01 + 1e-9:
                ok = False
                print('  DIFF %-5s %-9s %-8s from tables %.4f -> %.2f, thesis %.2f'
                      % ('%d-%d' % rng, ds, crit[j], v, round(v, 2), r))
            elif d > 1e-9:
                print('  rounding %-5s %-9s %-8s from tables %.4f, thesis %.2f'
                      % ('%d-%d' % rng, ds, crit[j], v, r))
print('all entries reproduced' if ok else 'differences found')
