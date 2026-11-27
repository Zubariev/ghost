# S2-03 spider ecology — balance run (shipped `spider.json`, 2026-11-27)

Headless scratch script (not kept): `SpiderEcology` and `SpiderWeb` with the shipped values, one trade
(6 flies) on a fixed rhythm for 20 game days, 1-hour steps. Logic only; nothing here is seen in a window.

| Trade every | Trades taken | Refused (hostile/recovering) | First hostile | Days hostile of 20 | Biggest size | At day 20 |
|---|---|---|---|---|---|---|
| 0.5 day | 10 | 30 | day 1.5 | 9.0 | 1.60 | friendly |
| 1 day | 10 | 10 | day 4.0 (5th trade) | 6.0 | 1.60 | friendly |
| 1.5 days | 11 | 3 | day 12.0 | 3.0 | 1.60 | friendly |
| 2 days | 10 | 0 | never | 0 | 1.20 | friendly |
| 3 days | 7 | 0 | never | 0 | 1.20 | friendly |

- Overfed once: friendly again after 5.3 game days (3 hostile + 2.3 recovering).
- Consequence: about 10 nests per 20 days whatever the rhythm; feeding faster only buys hostile days.
  Before sprint 002 nests were limited only by flies (up to ~10 trades a day from the kitchen).
- Web, 5 real minutes in the attic with a hostile spider: a ghost standing still takes 4 hits = 40 energy
  (the daily cap; a deep contact costs 35); a ghost moving at its slowest speed takes 0.
- Data tests guard the targets: `tests/integration/data/spider_data_test.gd` (a mutation to
  `decay_per_day: 20` failed "every other day never hostile", then restored).
