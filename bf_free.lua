-- bf_free.lua  —  built by olivia  —  https://discord.gg/ojailbreaks
-- loader free: hwid -> linkvertise -> key derivada -> bf_main_paid

local SALT         = "zkz-ollie-fridge-6767-banana-cheia-$Lk9m!PxVn@2026"
local SHORT_URL    = "https://link-center.net/8789843/5Qr7GRDMDjE7"
local KEY_PAGE     = "https://zekkz121.github.io/getkey/"
local PAYLOAD_URL  = "https://raw.githubusercontent.com/zekkz121/banana/main/bf_main_paid.lua"
local CACHE_FILE   = "bf_free_key.txt"
local PAYLOAD_FILE = "bf_free_payload.lua"
local LOG_FILE     = "bf_free_log.txt"
local CACHE_TTL    = 24 * 60 * 60

-- Chuoi locked no HWID do Potassium original. Hook gethwid pra enganar.
local MASTER_HWID  = "4cb5a867820ed18a9d27c767afd08d337843891331918650970c9aa6967bdb594eba24cd4bb2b5846ef946ec44582545519766ac16f531f03ed917b68a3acc46"

-- helpers --------------------------------------------------------------
local g = (getgenv and getgenv()) or _G

-- log em arquivo pra executores mobile sem console (Delta etc) ---------
local LOG_BUF = {}
local function log(msg)
    LOG_BUF[#LOG_BUF+1] = ("[%s] %s"):format(os.date("!%H:%M:%S"), tostring(msg))
    warn(msg)
    if writefile then pcall(writefile, LOG_FILE, table.concat(LOG_BUF, "\n")) end
end

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

-- FNV-1a 32-bit, bate EXATO com Math.imul do JS -----------------------
-- Lua number eh double; mult direta estoura 2^53. precisa split hi/lo.
local band, bxor, rshift = bit32.band, bit32.bxor, bit32.rshift
local function imul32(a, b)
    local a_lo = band(a, 0xFFFF)
    local a_hi = rshift(a, 16)
    local b_lo = band(b, 0xFFFF)
    local b_hi = rshift(b, 16)
    local hi = band((a_hi * b_lo + a_lo * b_hi) * 0x10000, 0xFFFFFFFF)
    local lo = a_lo * b_lo
    return band(hi + lo, 0xFFFFFFFF)
end
local function fnv32(s)
    local h = 2166136261
    for i = 1, #s do
        h = bxor(h, s:byte(i))
        h = imul32(h, 16777619)
    end
    return ("%08x"):format(h)
end

local function device_code(id)
    -- hash o hwid pra 8 chars hex — faceis de ver/anotar/digitar
    return fnv32(id.."::DEVICE::"..SALT)
end

local function derive_key(id, yyyymmdd)
    local code = device_code(id)
    return fnv32(code.."::"..yyyymmdd.."::"..SALT.."::1")
        .. fnv32(code.."::"..yyyymmdd.."::"..SALT.."::2")
        .. fnv32(code.."::"..yyyymmdd.."::"..SALT.."::3")
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
    local code = device_code(id)
    -- clipboard formatado: user cola uma vez e tem link + codigo
    setclip(("link: %s\ncodigo: %s"):format(SHORT_URL, code))
    warn("[bf_free] "..reason)
    warn("[bf_free] LINK copiado pro Ctrl+V")
    warn("[bf_free] SEU CODIGO: "..code.."  (cola isso na pagina)")
    warn("[bf_free] depois roda:")
    warn("    getgenv().__BF_KEY = \"<sua key>\"")
    warn("    loadstring(game:HttpGet(\"https://raw.githubusercontent.com/zekkz121/banana/main/bf_free.lua\"))()")
    local p = game:GetService("Players").LocalPlayer
    if p then
        pcall(function()
            p:Kick(
                "\n[Banana Cat Free]\n"..
                "Sem key valida.\n\n"..
                "LINK copiado pro Ctrl+V:\n"..SHORT_URL.."\n\n"..
                "SEU CODIGO (anota ou memoriza):\n\n"..
                "       "..code.."\n\n"..
                "1) cola o LINK no navegador\n"..
                "2) completa o linkvertise\n"..
                "3) cola o CODIGO na pagina -> pega a KEY\n"..
                "4) volta e roda com __BF_KEY = <key>"
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

-- HWID spoof: Chuoi lockou a key paga no MASTER_HWID. Forca gethwid pra
-- retornar sempre o mesmo em qualquer device (PC/mobile/outro executor).
do
    local hf = hookfunction or replaceclosure
    local nmc = newcclosure or function(f) return f end
    local spoofed = function() return MASTER_HWID end
    for _, name in ipairs({"gethwid", "get_hwid"}) do
        local tgt = g[name] or _G[name]
        if type(tgt) == "function" and hf then
            pcall(hf, tgt, nmc(spoofed))
        end
        g[name] = spoofed
        _G[name] = spoofed
    end
    if syn and syn.get_hwid and hf then pcall(hf, syn.get_hwid, nmc(spoofed)) end
    if Fluxus and Fluxus.get_hwid and hf then pcall(hf, Fluxus.get_hwid, nmc(spoofed)) end
    -- RbxAnalyticsService:GetClientId tambem — alguns scripts usam isso
    local ok, RAS = pcall(game.GetService, game, "RbxAnalyticsService")
    if ok and RAS and hf then
        pcall(hf, RAS.GetClientId, nmc(function(self) return MASTER_HWID end))
    end
    log("[bf_free] HWID spoof armado (MASTER_HWID="..MASTER_HWID:sub(1,16)..")")
end

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
