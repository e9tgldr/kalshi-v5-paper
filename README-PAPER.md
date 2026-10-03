# Kalshi v5 Paper Trading Bot — standalone (no Nightshark, no account, no keys)

Source: https://code.processoverprofit.blog/docs/youtube-code/video-14-kalshi-v5/ (Paper-Trading Code tab)

This is the channel's paper-trading bot made runnable on your machine for free.
The original expects the **Nightshark** app (nightshark.io) — its built-in functions
(`Log`, `LogStream`, `HttpGet`, `GetKalshiPrice`, `stopCode`, `RunCMD`) are replaced here by
free shims at the bottom of `kalshi-v5-paper.ahk`, so plain AutoHotkey v1.1 runs it.

## Start / Stop / Watch

- **Start (unlimited):** double-click the **Kalshi Paper Bot** desktop shortcut (or `.\run-paper.ps1`)
- **Start with a time limit:** `.\run-paper.ps1 -Minutes 50` (auto-stops after 50 min — any number works)
- **Stop:** `.\run-paper.ps1 -Stop`
- **Watch live:** double-click the **Kalshi Paper View** desktop shortcut — a console dashboard refreshes every second with status, countdown, live numbers and the last 10 events
- No window appears for the bot itself — it lives in the tray (`AutoHotkeyU64.exe` icon).

## Where to watch it

| File | What's in it |
|---|---|
| `kalshi-streams.txt` | Live numbers: BALANCE, LIVE PNL, WINS, BTC price, OPEN PRICE, LIVE DELTA, up/down contract prices. Updated every loop (~0.7 s). |
| `kalshi-paper.log` | Event log: starts, sessions, entries, exits, stops. |

Both files refresh in place — just reopen them, or `Get-Content .\kalshi-paper.log -Wait -Tail 20`.

## What it trades

BTC 15-minute prediction markets on Kalshi (`KXBTC15M`), real market data:

- **Entry:** only in the **last 8 min** of each 15-min window, when the UP or DOWN price is between **0.75 and 0.85** — buys 1 paper contract
- **Stop loss:** exit if your side's price falls below **0.40**
- **Take profit:** exit at entry + **0.10**
- **Paper balance:** starts at fake **$1000**; nothing real is ever sent to Kalshi
- **Daily stop:** stops itself after +$400 profit or −$600 loss (closed trades)

## Tweak the strategy

Top of `kalshi-v5-paper.ahk`:

```ahk
initialBalance := 1000        ; fake starting balance
timeDelay := 8                ; enter in last N minutes of the 15m window
EntryRange := [0.75, 0.85]    ; only enter when price is in this band
Exit := 0.40                  ; stop loss
TakeProfitPts := 0.10         ; take profit; set 1 = hold winners to settlement
assets := ["BTC"]             ; ["ETH"], ["SOL"], ["XRP"], ["DOGE"] also work (HYPE/BNB need a price source)
orderSize := 1                ; paper contracts per entry
```

Edit → save → restart the bot (`-Stop`, then start again).

## Requirements / notes

- Needs internet (Kalshi public API + Coinbase spot prices, Binance fallback). No signups anywhere.
- Kalshi itself requires 18+ and identity verification — that's why paper mode is the right (and realistic) playground for now.
- `ahk-v1\` = portable AutoHotkey v1.1.37 (nothing was installed system-wide except AHK v2, which this project does not use).
- The real-money version on the site also needs the paid Nightshark runtime + Kalshi API keys — skip it until you've watched this bot for weeks.

## Files

- `kalshi-v5-paper.ahk` — the bot (original paper code + shims)
- `run-paper.ps1` — start / stop launcher (desktop shortcut runs this)
- `paper-trading-code-0.txt` — pristine extracted source from the site (reference)
- `live-trading-code-1.txt` — the live-money version, for reference only (does NOT run standalone)
- `extract-code.js` — helper used to pull code blocks out of the docs page
- `ahk-v1\` — portable AutoHotkey v1.1.37
