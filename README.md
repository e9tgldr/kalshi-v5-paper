
# kalshi-v5-paper

A paper-trading bot for Kalshi BTC 15-minute prediction markets, ported to run on plain AutoHotkey v1.1 with no Nightshark app and no account.

## Credits and scope

The strategy and much of the original script come from the Process Over Profit video series:
https://code.processoverprofit.blog/docs/youtube-code/video-14-kalshi-v5/

What this port does is replace the Nightshark-specific built-ins (`Log`, `LogStream`, `HttpGet`, `GetKalshiPrice`, `stopCode`, `RunCMD`) with free shims at the bottom of `kalshi-v5-paper.ahk`, so the bot runs on a stock AutoHotkey install. The original expects the commercial Nightshark app; this does not.

No account, no API keys, and nothing is ever sent to Kalshi. Every trade is simulated.

## Install

AutoHotkey v1.1 is required and is not bundled here (it is GPL, so the binaries are not redistributable). Install v1.1 from the official site and put it anywhere on PATH.

## Run

- Start: `.un-paper.ps1` (or the desktop shortcut)
- Start with a time limit: `.un-paper.ps1 -Minutes 50`
- Stop: `.un-paper.ps1 -Stop`
- Watch live: `.iew-paper.ps1` — console dashboard refreshing every second

The bot runs in the tray with no visible window.

## The strategy

BTC 15-minute markets on Kalshi (`KXBTC15M`), on real market data:

- **Entry** — only in the last 8 minutes of a 15-minute window, when UP or DOWN trades between 0.75 and 0.85; buys one paper contract
- **Stop loss** — exit if the position price falls below 0.40
- **Take profit** — exit at entry + 0.10
- **Paper balance** — starts at a fake $1000
- **Daily stop** — halts at +$400 or -$600 on closed trades

Tweak any of these at the top of `kalshi-v5-paper.ahk`.

## Watching it

| File | Contents |
|---|---|
| `kalshi-streams.txt` | Live numbers: balance, P&L, wins, BTC price, open price, live delta, contract prices. Rewritten every loop (~0.7s). |
| `kalshi-paper.log` | Event log: starts, sessions, entries, exits, stops. |

Both refresh in place, so `Get-Content .\kalshi-paper.log -Wait -Tail 20` works.
