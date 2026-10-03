
; =====================================================================
; NIGHTSHARK BUILT-IN SHIMS (standalone replacement - free, no Nightshark)
; =====================================================================
Log(msg) {
    global LogFile
    FormatTime, ts, %A_Now%, yyyy-MM-dd HH:mm:ss
    FileAppend, [%ts%] %msg%`n, %LogFile%, UTF-8
}

stopCode() {
    Log("Bot stopped.")
    ExitApp
}

LogStream(label, value) {
    WriteLogStream(label, value, true)
}

LogStreamRemove(label) {
    WriteLogStream(label, "", false)
}

WriteLogStream(label, value, keep) {
    global gLogStreams, gLogStreamsFile
    if (keep)
        gLogStreams[label] := value
    else
        gLogStreams.Delete(label)
    text := ""
    for k, v in gLogStreams
        text .= k ": " v "`n"
    FileDelete, %gLogStreamsFile%
    FileAppend, %text%, %gLogStreamsFile%, UTF-8
}

HttpGet(url) {
    static httpObj
    if !IsObject(httpObj)
        httpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    httpObj.Option(9) := 10240
    httpObj.SetTimeouts(3000, 3000, 5000, 5000)
    httpObj.Open("GET", url, false)
    httpObj.SetRequestHeader("User-Agent", "Mozilla/5.0")
    try httpObj.Send()
    if (httpObj.Status = 200)
        return httpObj.ResponseText
    return ""
}

; Underlying spot price + current 15-minute open for the asset.
; Used for the LIVE DELTA stream and the Delta entry filter.
; Source 1: Coinbase public API. Source 2 fallback: Binance public API.
GetKalshiPrice(asset) {
    cbSym := asset . "-USD"
    bnSym := asset . "USDT"
    price := ""
    open15m := ""

    body := HttpGet("https://api.exchange.coinbase.com/products/" cbSym "/candles?granularity=900")
    if (body != "") {
        ; newest candle first: [time, low, high, open, close, volume]
        if RegExMatch(body, "\[\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?),\s*(\d+(?:\.\d+)?)\s*\]", m)
            open15m := m4
    }

    body := HttpGet("https://api.coinbase.com/v2/prices/" cbSym "/spot")
    if (body != "") {
        amt := JsonField(body, "amount")
        if (amt != "")
            price := amt
    }

    if (price = "" || open15m = "") {
        body := HttpGet("https://api.binance.com/api/v3/ticker/price?symbol=" bnSym)
        if (body != "") {
            p := JsonField(body, "price")
            if (p != "" && price = "")
                price := p
        }
        body := HttpGet("https://api.binance.com/api/v3/klines?symbol=" bnSym "&interval=15m&limit=1")
        if (body != "" && open15m = "") {
            if RegExMatch(body, "\[\[\s*\d+\s*,\s*""([\d.]+)""\s*,\s*""([\d.]+)""\s*,\s*""([\d.]+)""", k)
                open15m := k3
        }
    }

    if (price = "" && open15m = "")
        return ""
    obj := {}
    obj.price := price
    obj.open15m := open15m
    return obj
}

RunCMD(command, workdir := "") {
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(ComSpec . " /C " . command)
    out := ""
    try out := exec.StdOut.ReadAll()
    return out
}
