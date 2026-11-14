local SALT         = "zkz-ollie-fridge-6767-banana-cheia-$Lk9m!PxVn@2026"
local SHORT_URL    = "https://link-hub.net/8789843/FRSCqUrAq5LC"
local KEY_PAGE     = "https://zekkz121.github.io/getkey/"
local PAYLOAD_URL  = "https://raw.githubusercontent.com/zekkz121/banana/main/bf_main_paid.lua"
local CACHE_FILE   = "bf_free_key.txt"
local PAYLOAD_FILE = "bf_free_payload.lua"
local CACHE_TTL    = 24 * 60 * 60

-- helpers --------------------------------------------------------------
local g = (getgenv and getgenv()) or _G

local function hwid()
    for _, f in ipairs({
        function() return gethwid and gethwid() end,
        function() return syn and syn.get_hwid and syn.get_hwid() end,
        function() return get_hwid and get_hwid() end,
        function() return Fluxus and Fluxus.get_hwid and Fluxus.get_hwid() end,
        function() return game:GetService("RbxAnalyticsService"):GetClientId() end,
    }) do
        local ok, id = pcall(f)
        if ok and type(id) == "string" and #id > 4 then return id end
    end
    return "unknown"
end

-- FNV-1a 32-bit, bate exato com o JS do getkey.html ---------------------
local band, bxor, lshift = bit32.band, bit32.bxor, bit32.lshift
local function fnv32(s)
    local h = 2166136261
    for i = 1, #s do
        h = bxor(h, s:byte(i))
        h = band(h * 16777619, 0xFFFFFFFF)
    end
    return ("%08x"):format(h)
end

local function derive_key(id, yyyymmdd)
    return fnv32(id.."::"..yyyymmdd.."::"..SALT.."::1")
        .. fnv32(id.."::"..yyyymmdd.."::"..SALT.."::2")
        .. fnv32(id.."::"..yyyymmdd.."::"..SALT.."::3")
end

local function today()
    return os.date("!%Y%m%d")  -- UTC, mesmo que o JS Date getUTC*
end

-- cache ----------------------------------------------------------------
local function read_cache()
    if not (readfile and isfile) then return nil end
    local ok, raw = pcall(isfile, CACHE_FILE)
    if not ok or not raw then return nil end
    local body = pcall(readfile, CACHE_FILE) and readfile(CACHE_FILE) or nil
    if not body then return nil end
    local ts, key = body:match("^(%d+)|(%x+)$")
    if not ts then return nil end
    if (os.time() - tonumber(ts)) > CACHE_TTL then return nil end
    return key
end

local function write_cache(key)
    if writefile then pcall(writefile, CACHE_FILE, os.time().."|"..key) end
end

-- clipboard + prompt ---------------------------------------------------
local function setclip(txt)
    local fns = {setclipboard, (syn and syn.write_clipboard), toclipboard, set_clipboard}
    for _, f in ipairs(fns) do
        if type(f) == "function" then pcall(f, txt); return true end
    end
    return false
end

local function wipe_caches()
    for _, f in ipairs({CACHE_FILE, PAYLOAD_FILE}) do
        if isfile and isfile(f) and delfile then pcall(delfile, f) end
    end
end

local function deny(id, reason)
    wipe_caches()
    -- clipboard formatado: user cola em qualquer lugar (notes/whatsapp/etc) e tem as duas coisas
    local clip_payload = ("1) LINK:\n%s\n\n2) HWID (cola na pagina):\n%s"):format(SHORT_URL, id)
    setclip(clip_payload)
    warn("[bf_free] "..reason)
    warn("[bf_free] LINK + HWID copiados pro clipboard")
    warn("[bf_free] cola no notepad/whatsapp/bloco de notas pra ver os dois:")
    warn("    LINK:  "..SHORT_URL)
    warn("    HWID:  "..id)
    warn("[bf_free] depois roda:")
    warn("    getgenv().__BF_KEY = \"<sua key>\"")
    warn("    loadstring(game:HttpGet(\"https://raw.githubusercontent.com/zekkz121/banana/main/bf_free.lua\"))()")
    local p = game:GetService("Players").LocalPlayer
    if p then
        pcall(function()
            p:Kick(
                "\n[Banana Cat Free]\n"..
                "Sem key valida.\n\n"..
                "LINK + HWID ja no CLIPBOARD\n"..
                "(cola em qualquer lugar pra ver os 2)\n\n"..
                "LINK:\n"..SHORT_URL.."\n\n"..
                "HWID:\n"..id.."\n\n"..
                "1) cola LINK no navegador -> passa linkvertise\n"..
                "2) cola HWID na pagina -> pega a KEY\n"..
                "3) volta aqui e roda com __BF_KEY = <key>"
            )
        end)
    end
    error("[bf_free] sem key — kick disparado", 0)
end

-- fluxo ----------------------------------------------------------------
local id = hwid()
local expected = derive_key(id, today())

local cached = read_cache()
if cached == expected then
    print("[bf_free] key cacheada OK ("..id:sub(1,8)..")")
elseif g.__BF_KEY and tostring(g.__BF_KEY):lower() == expected then
    print("[bf_free] key aceita, cacheando 24h")
    write_cache(expected)
elseif g.__BF_KEY then
    deny(id, "key invalida pra esse HWID")
else
    deny(id, "nenhuma key fornecida")
end

-- load payload ---------------------------------------------------------
g.Key           = "210f2a8d17fc90111c92514d"
g.key           = g.Key
g.script_key    = g.Key
g.Whitelisted   = true
g.Verified      = true
g.Authenticated = true
g.KeyValid      = true
g.Premium       = true
g.Lifetime      = true
g.__BANANA_SCRIPT_ROUTE = "bf_main"

-- payload: tenta cache local, senao baixa + salva
local src
if isfile and isfile(PAYLOAD_FILE) then
    local ok, body = pcall(readfile, PAYLOAD_FILE)
    if ok and type(body) == "string" and #body > 100000 then
        src = body
        print("[bf_free] payload cacheado ("..#src.." bytes)")
    end
end
if not src then
    print("[bf_free] baixando payload (primeira vez, ~1.4 MB)...")
    local ok, body = pcall(game.HttpGet, game, PAYLOAD_URL)
    if not ok or type(body) ~= "string" or #body < 100000 then
        error("[bf_free] falhou baixar payload de "..PAYLOAD_URL..": "..tostring(body):sub(1,120), 0)
    end
    src = body
    if writefile then pcall(writefile, PAYLOAD_FILE, src); print("[bf_free] payload cacheado em "..PAYLOAD_FILE) end
end

-- noise filter do 16_final_runtime
local hf, nmc = hookfunction or replaceclosure, newcclosure or function(f) return f end
if hf then
    for _, name in ipairs({"print","warn"}) do
        local tgt = g[name]
        if type(tgt) == "function" then
            local holder = {fn = tgt}
            local wrap = nmc(function(...)
                local s = tostring((...))
                if #s >= 20 and s:find("invalid argument",1,true) and s:find("'next'",1,true) then return end
                return holder.fn(...)
            end)
            local ok, orig = pcall(hf, tgt, wrap)
            if ok and type(orig)=="function" then holder.fn = orig end
        end
    end
end

print("[bf_free] carregando bf_main_paid ("..#src.." bytes)")
loadstring(src, "bf:free")()
