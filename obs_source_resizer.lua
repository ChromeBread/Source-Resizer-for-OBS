--[[
================================================================================
 Source Resizer  -  OBS Studio Lua script (Windows)

 A browser dock for laying out sources: nine-point buttons push the selected
 items flush against the canvas edge, and size buttons set them to classic
 and current resolutions, a custom pixel size, a favorite, the full canvas,
 or dot by dot.

 Author : BlackDream feat. ChromeBread
================================================================================
]]

local obs = obslua

--------------------------------------------------------------------------------
-- Meta
--------------------------------------------------------------------------------
local SCRIPT_NAME = "Source Resizer"
local VERSION     = "1.0.0"
local BUILD_DATE  = { year = 2026, month = 10, day = 31 }
local AUTHOR      = "BlackDream feat. ChromeBread"
local DOCK_HTML   = "obs_source_resizer_dock.html"
local STATE_JS    = "obs_source_resizer_state.js"
local PREFS_FILE  = "obs_source_resizer_prefs.json"
local CMD_SECTION = "SourceResizer"
local CMD_KEY     = "cmd"
local POLL_MS     = 300
local MAX_SIZE    = 16384

local POSITIONS = { "tl", "tc", "tr", "ml", "mc", "mr", "bl", "bc", "br" }
local ANCHOR = {
	tl = { 0, 0 },   tc = { 0.5, 0 },   tr = { 1, 0 },
	ml = { 0, 0.5 }, mc = { 0.5, 0.5 }, mr = { 1, 0.5 },
	bl = { 0, 1 },   bc = { 0.5, 1 },   br = { 1, 1 },
}

--------------------------------------------------------------------------------
-- Localization
--------------------------------------------------------------------------------
local LANGS = { "en", "ja", "ko", "id", "fr", "zh_TW" }
local LANG_NAMES = {
	en = "English", ja = "日本語", ko = "한국어",
	id = "Bahasa Indonesia", fr = "Français", zh_TW = "繁體中文",
}

local I18N = {
	en = {
		desc = "<p>Lay out sources from a dock: nine buttons push the selected items flush against the canvas edge, and size buttons set classic or current resolutions, a custom size, a favorite, the full canvas or dot by dot.</p>",
		version = "Version", build_date = "Build date", author = "Author",
		language = "Language", lang_auto = "Auto (OBS)",
		debug_on = "Debug Mode: ON", debug_off = "Debug Mode: OFF",
		dock_url = "Dock URL",
		dock_howto = "1. Copy the Dock URL.\n2. In OBS: Docks → Custom Browser Docks… → enter a name and paste the URL.\n3. The dock talks to OBS via WebSocket (Tools → WebSocket Server Settings). Enter the port / password in the dock (⚙).",
		hk_move = "Move to: %s", hk_dot = "Dot by dot",
		tl = "Top left", tc = "Top", tr = "Top right", ml = "Left", mc = "Center", mr = "Right", bl = "Bottom left", bc = "Bottom", br = "Bottom right",
	},
	ja = {
		desc = "<p>ドックでソースを配置します。9個のボタンで選択中のアイテムをキャンバスの端にぴったり寄せ、サイズボタンでレトロから現行までの解像度、指定サイズ、お気に入り、キャンバス全体、ドットバイドットに変更できます。</p>",
		version = "バージョン", build_date = "ビルド日", author = "製作者",
		language = "言語", lang_auto = "自動 (OBS)",
		debug_on = "デバッグモード: ON", debug_off = "デバッグモード: OFF",
		dock_url = "ドックURL",
		dock_howto = "1. ドックURLをコピーします。\n2. OBSの「ドック → カスタムブラウザドック…」で名前を入力し、URLを貼り付けます。\n3. ドックは WebSocket（ツール → WebSocketサーバー設定）でOBSと通信します。ドック内（⚙）でポート / パスワードを入力してください。",
		hk_move = "移動: %s", hk_dot = "ドットバイドット",
		tl = "左上", tc = "上", tr = "右上", ml = "左", mc = "中央", mr = "右", bl = "左下", bc = "下", br = "右下",
	},
	ko = {
		desc = "<p>도크에서 소스를 배치합니다. 버튼 9개로 선택한 항목을 캔버스 가장자리에 딱 붙이고, 크기 버튼으로 클래식부터 현행까지의 해상도, 지정 크기, 즐겨찾기, 캔버스 전체, 도트 바이 도트로 바꿀 수 있습니다.</p>",
		version = "버전", build_date = "빌드 날짜", author = "제작자",
		language = "언어", lang_auto = "자동 (OBS)",
		debug_on = "디버그 모드: ON", debug_off = "디버그 모드: OFF",
		dock_url = "도크 URL",
		dock_howto = "1. 도크 URL을 복사합니다.\n2. OBS에서 도크 → 사용자 지정 브라우저 도크… 에 이름을 입력하고 URL을 붙여넣습니다.\n3. 도크는 WebSocket(도구 → WebSocket 서버 설정)으로 OBS와 통신합니다. 도크(⚙)에서 포트 / 비밀번호를 입력하세요.",
		hk_move = "이동: %s", hk_dot = "도트 바이 도트",
		tl = "왼쪽 위", tc = "위", tr = "오른쪽 위", ml = "왼쪽", mc = "가운데", mr = "오른쪽", bl = "왼쪽 아래", bc = "아래", br = "오른쪽 아래",
	},
	id = {
		desc = "<p>Atur sumber dari dock: sembilan tombol menempelkan item terpilih ke tepi kanvas, dan tombol ukuran mengatur resolusi klasik hingga terkini, ukuran khusus, favorit, seluruh kanvas, atau dot by dot.</p>",
		version = "Versi", build_date = "Tanggal build", author = "Pembuat",
		language = "Bahasa", lang_auto = "Otomatis (OBS)",
		debug_on = "Mode Debug: ON", debug_off = "Mode Debug: OFF",
		dock_url = "URL Dock",
		dock_howto = "1. Salin URL Dock.\n2. Di OBS: Dock → Dock Peramban Kustom… → masukkan nama dan tempel URL.\n3. Dock berkomunikasi dengan OBS melalui WebSocket (Alat → Pengaturan Server WebSocket). Masukkan port / kata sandi di dock (⚙).",
		hk_move = "Pindah ke: %s", hk_dot = "Dot by dot",
		tl = "Kiri atas", tc = "Atas", tr = "Kanan atas", ml = "Kiri", mc = "Tengah", mr = "Kanan", bl = "Kiri bawah", bc = "Bawah", br = "Kanan bawah",
	},
	fr = {
		desc = "<p>Disposez vos sources depuis un dock : neuf boutons collent les éléments sélectionnés au bord du canevas, et les boutons de taille appliquent des résolutions rétro ou actuelles, une taille personnalisée, un favori, le canevas entier ou le dot by dot.</p>",
		version = "Version", build_date = "Date de build", author = "Auteur",
		language = "Langue", lang_auto = "Automatique (OBS)",
		debug_on = "Mode débogage : ON", debug_off = "Mode débogage : OFF",
		dock_url = "URL du dock",
		dock_howto = "1. Copiez l'URL du dock.\n2. Dans OBS : Docks → Docks de navigateur personnalisés… → saisissez un nom et collez l'URL.\n3. Le dock communique avec OBS via WebSocket (Outils → Paramètres du serveur WebSocket). Saisissez le port / mot de passe dans le dock (⚙).",
		hk_move = "Déplacer : %s", hk_dot = "Dot by dot",
		tl = "En haut à gauche", tc = "En haut", tr = "En haut à droite", ml = "À gauche", mc = "Centre", mr = "À droite", bl = "En bas à gauche", bc = "En bas", br = "En bas à droite",
	},
	zh_TW = {
		desc = "<p>在 Dock 中配置來源：9 個按鈕可將選取的項目緊貼畫布邊緣，大小按鈕可切換復古到現行的解析度、自訂大小、我的最愛、整個畫布或點對點。</p>",
		version = "版本", build_date = "建置日期", author = "製作者",
		language = "語言", lang_auto = "自動 (OBS)",
		debug_on = "偵錯模式：ON", debug_off = "偵錯模式：OFF",
		dock_url = "Dock 網址",
		dock_howto = "1. 複製 Dock 網址。\n2. 在 OBS 中：停駐視窗 → 自訂瀏覽器停駐視窗… → 輸入名稱並貼上網址。\n3. Dock 透過 WebSocket（工具 → WebSocket 伺服器設定）與 OBS 通訊，請在 Dock（⚙）中輸入連接埠與密碼。",
		hk_move = "移動: %s", hk_dot = "點對點",
		tl = "左上", tc = "上", tr = "右上", ml = "左", mc = "中央", mr = "右", bl = "左下", bc = "下", br = "右下",
	},
}

local MONTHS = {
	en = { "January", "February", "March", "April", "May", "June", "July",
	       "August", "September", "October", "November", "December" },
	fr = { "janvier", "février", "mars", "avril", "mai", "juin", "juillet",
	       "août", "septembre", "octobre", "novembre", "décembre" },
	id = { "Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli",
	       "Agustus", "September", "Oktober", "November", "Desember" },
}

local function format_date(d, lang)
	if lang == "ja" or lang == "zh_TW" then
		return string.format("%d年%d月%d日", d.year, d.month, d.day)
	elseif lang == "ko" then
		return string.format("%d년 %d월 %d일", d.year, d.month, d.day)
	elseif lang == "fr" then
		return (d.day == 1 and "1er" or tostring(d.day)) .. " " .. MONTHS.fr[d.month] .. " " .. d.year
	elseif lang == "id" then
		return d.day .. " " .. MONTHS.id[d.month] .. " " .. d.year
	end
	return MONTHS.en[d.month] .. " " .. d.day .. ", " .. d.year
end

-- Any OBS locale outside the six supported languages falls back to English.
local function map_locale(loc)
	loc = (loc or ""):gsub("_", "-"):lower()
	if loc:find("^ja") then return "ja" end
	if loc:find("^ko") then return "ko" end
	if loc:find("^id") then return "id" end
	if loc:find("^fr") then return "fr" end
	if loc == "zh-tw" or loc == "zh-hk" or loc:find("^zh%-hant") then return "zh_TW" end
	return "en"
end

local function detect_obs_lang()
	local ok, loc = pcall(function() return obs.obs_get_locale() end)
	return map_locale(ok and loc or "en")
end

local lang_setting = "auto" -- "auto" or one of LANGS
local current_lang = "en"

local function T(key)
	local t = I18N[current_lang] or I18N.en
	return t[key] or I18N.en[key] or key
end

local function resolve_lang()
	current_lang = (lang_setting ~= "auto" and I18N[lang_setting]) and lang_setting or detect_obs_lang()
end

local function log(level, msg)
	obs.script_log(level, msg)
end

debug_mode = false

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------
-- Scale that turns a sw*sh source into W*H; with keep, the largest fit inside W*H.
local function compute_scale(sw, sh, W, H, keep)
	local sx, sy = W / sw, H / sh
	if keep then
		local s = math.min(sx, sy)
		return s, s
	end
	return sx, sy
end

-- Top-left of a w*h box at anchor key; a box larger than the canvas is centered on that axis.
local function anchor_pos(w, h, cw, ch, key)
	local a = ANCHOR[key] or ANCHOR.mc
	local fx = w > cw and 0.5 or a[1]
	local fy = h > ch and 0.5 or a[2]
	return (cw - w) * fx, (ch - h) * fy
end

do -- self-check
	local sx, sy = compute_scale(1920, 1080, 640, 480, true)
	assert(sx == sy and sx == 640 / 1920, "keep aspect check failed")
	sx, sy = compute_scale(1920, 1080, 640, 480, false)
	assert(sx == 640 / 1920 and sy == 480 / 1080, "stretch check failed")
	local x, y = anchor_pos(100, 2000, 1920, 1080, "br")
	assert(x == 1820 and y == -460, "anchor check failed")
end

--------------------------------------------------------------------------------
-- Scene items
--------------------------------------------------------------------------------
local favorites = {} -- "WxH" strings

local function canvas_scene()
	if obs.obs_frontend_preview_program_mode_active() then
		return obs.obs_frontend_get_current_preview_scene()
	end
	return obs.obs_frontend_get_current_scene()
end

-- shortcut: top-level items only, walk groups if resizing inside a group is needed
local function for_selected(fn)
	local scene_src = canvas_scene()
	if not scene_src then return 0 end
	local n = 0
	local items = obs.obs_scene_enum_items(obs.obs_scene_from_source(scene_src))
	for _, it in ipairs(items or {}) do
		if obs.obs_sceneitem_selected(it) then
			fn(it, scene_src)
			n = n + 1
		end
	end
	if items then obs.sceneitem_list_release(items) end
	obs.obs_source_release(scene_src)
	return n
end

local function visible_size(item)
	local src = obs.obs_sceneitem_get_source(item)
	local c = obs.obs_sceneitem_crop()
	obs.obs_sceneitem_get_crop(item, c)
	return obs.obs_source_get_width(src) - c.left - c.right,
		obs.obs_source_get_height(src) - c.top - c.bottom
end

-- Flips survive: the sign of the current scale is kept.
local function set_item_scale(item, sx, sy)
	obs.obs_sceneitem_set_bounds_type(item, obs.OBS_BOUNDS_NONE) -- bounds would override the scale
	local v = obs.vec2()
	obs.obs_sceneitem_get_scale(item, v)
	v.x = v.x < 0 and -sx or sx
	v.y = v.y < 0 and -sy or sy
	obs.obs_sceneitem_set_scale(item, v)
end

local function resize_item(item, W, H, keep)
	local sw, sh = visible_size(item)
	if sw <= 0 or sh <= 0 then return end
	set_item_scale(item, compute_scale(sw, sh, W, H, keep))
end

local function item_box(item)
	local m = obs.matrix4()
	obs.obs_sceneitem_get_box_transform(item, m)
	local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
	for _, c in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
		local x = m.x.x * c[1] + m.y.x * c[2] + m.t.x
		local y = m.x.y * c[1] + m.y.y * c[2] + m.t.y
		x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
	end
	return x0, y0, x1, y1
end

-- The box transform covers rotation, crop and bounds, so any arranged item lands flush.
local function move_item(item, scene_src, key)
	local x0, y0, x1, y1 = item_box(item)
	local cw, ch = obs.obs_source_get_width(scene_src), obs.obs_source_get_height(scene_src)
	local tx, ty = anchor_pos(x1 - x0, y1 - y0, cw, ch, key)
	local v = obs.vec2()
	obs.obs_sceneitem_get_pos(item, v)
	v.x, v.y = v.x + tx - x0, v.y + ty - y0
	obs.obs_sceneitem_set_pos(item, v)
end

--------------------------------------------------------------------------------
-- Dock state and preferences
--------------------------------------------------------------------------------
local function script_dir()
	local ok, p = pcall(script_path)
	p = ok and p or ""
	p = p:gsub("\\", "/")
	if p ~= "" and p:sub(-1) ~= "/" then p = p .. "/" end
	return p
end

local function file_url(path)
	path = path:gsub("\\", "/")
	local enc = path:gsub("[^%w%-%._~/:]", function(c) return string.format("%%%02X", c:byte()) end)
	return "file:///" .. enc
end

local function load_prefs()
	local d = obs.obs_data_create_from_json_file(script_dir() .. PREFS_FILE)
	if d then
		local l = obs.obs_data_get_string(d, "language")
		if l == "auto" or I18N[l] then lang_setting = l end
		for f in obs.obs_data_get_string(d, "favorites"):gmatch("%d+x%d+") do
			favorites[#favorites + 1] = f
		end
		obs.obs_data_release(d)
	end
end

local function save_prefs()
	local d = obs.obs_data_create()
	obs.obs_data_set_string(d, "language", lang_setting)
	obs.obs_data_set_string(d, "favorites", table.concat(favorites, ","))
	obs.obs_data_save_json(d, script_dir() .. PREFS_FILE)
	obs.obs_data_release(d)
end

local last_state = nil

local function write_dock_state()
	local count, w, h = 0, 0, 0
	for_selected(function(it)
		count = count + 1
		if count == 1 then
			local x0, y0, x1, y1 = item_box(it)
			w, h = math.floor(x1 - x0 + 0.5), math.floor(y1 - y0 + 0.5)
		end
	end)
	local favs = {}
	for i, f in ipairs(favorites) do favs[i] = '"' .. f .. '"' end
	local st = string.format(
		'srState({"lang":"%s","name":"%s","version":"%s","buildDate":"%s","author":"%s","count":%d,"w":%d,"h":%d,"favs":[%s]});',
		current_lang, SCRIPT_NAME, VERSION, format_date(BUILD_DATE, current_lang), AUTHOR,
		count, w, h, table.concat(favs, ","))
	if st ~= last_state then
		last_state = st
		obs.os_quick_write_utf8_file(script_dir() .. STATE_JS, st, #st, false)
	end
end

local function valid_size(w, h)
	w, h = tonumber(w), tonumber(h)
	if w and h and w >= 1 and h >= 1 and w <= MAX_SIZE and h <= MAX_SIZE then return w, h end
end

local function set_favorite(key, add)
	for i, f in ipairs(favorites) do
		if f == key then
			if add then return end
			table.remove(favorites, i)
			save_prefs()
			return
		end
	end
	if add then
		favorites[#favorites + 1] = key
		save_prefs()
	end
end

-- The dock stores a command in the profile config (obs-websocket SetProfileParameter), then
-- fires the "sr_command" hotkey: hotkeys alone can't carry a width and a height.
local function run_command(cmd)
	local w, h, keep = cmd:match("^size (%d+) (%d+) ([01])$")
	if w then
		w, h = valid_size(w, h)
		if w then for_selected(function(it) resize_item(it, w, h, keep == "1") end) end
		return
	end
	keep = cmd:match("^canvas ([01])$")
	if keep then
		for_selected(function(it, scene_src)
			resize_item(it, obs.obs_source_get_width(scene_src), obs.obs_source_get_height(scene_src), keep == "1")
		end)
		return
	end
	local op
	op, w, h = cmd:match("^fav([+-]) (%d+) (%d+)$")
	if op then
		w, h = valid_size(w, h)
		if w then set_favorite(w .. "x" .. h, op == "+") end
	end
end

local function on_command()
	local cfg = obs.obs_frontend_get_profile_config()
	local cmd = cfg and obs.config_get_string(cfg, CMD_SECTION, CMD_KEY)
	if not cmd or cmd == "" then return end
	if debug_mode then log(obs.LOG_INFO, "[debug] command: " .. cmd) end
	run_command(cmd)
	write_dock_state()
end

load_prefs()
resolve_lang()

--------------------------------------------------------------------------------
-- Script
--------------------------------------------------------------------------------
local script_settings = nil

local function apply_script_props(props)
	for _, k in ipairs({ { "language", "language" }, { "dock_url", "dock_url" }, { "dock_info", "dock_howto" } }) do
		obs.obs_property_set_description(obs.obs_properties_get(props, k[1]), T(k[2]))
	end
	obs.obs_property_set_description(obs.obs_properties_get(props, "debug_toggle"),
		debug_mode and T("debug_on") or T("debug_off"))
end

local function on_language_changed(props, _, settings)
	local l = obs.obs_data_get_string(settings, "language")
	if l ~= lang_setting then
		lang_setting = (l == "auto" or I18N[l]) and l or "auto"
		resolve_lang()
		save_prefs()
		write_dock_state()
	end
	apply_script_props(props)
	return true
end

local function on_debug_toggle(props, _)
	debug_mode = not debug_mode
	if script_settings then obs.obs_data_set_bool(script_settings, "debug_mode", debug_mode) end
	apply_script_props(props)
	return true
end

function script_description()
	return string.format([[<h2>%s</h2>%s<hr/>
<table>
<tr><td><b>%s</b></td><td>&nbsp;&nbsp;%s</td></tr>
<tr><td><b>%s</b></td><td>&nbsp;&nbsp;%s</td></tr>
<tr><td><b>%s</b></td><td>&nbsp;&nbsp;%s</td></tr>
</table>]],
		SCRIPT_NAME, T("desc"),
		T("version"), VERSION,
		T("build_date"), format_date(BUILD_DATE, current_lang),
		T("author"), AUTHOR)
end

function script_properties()
	local props = obs.obs_properties_create()
	local lp = obs.obs_properties_add_list(props, "language", T("language"),
		obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
	obs.obs_property_list_add_string(lp,
		T("lang_auto") .. " - " .. LANG_NAMES[detect_obs_lang()], "auto")
	for _, l in ipairs(LANGS) do obs.obs_property_list_add_string(lp, LANG_NAMES[l], l) end
	obs.obs_property_set_modified_callback(lp, on_language_changed)
	obs.obs_properties_add_text(props, "dock_url", T("dock_url"), obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "dock_info", T("dock_howto"), obs.OBS_TEXT_INFO)
	obs.obs_properties_add_button(props, "debug_toggle", T("debug_off"), on_debug_toggle)
	apply_script_props(props)
	return props
end

function script_defaults(settings)
	obs.obs_data_set_default_string(settings, "language", "auto")
	obs.obs_data_set_default_bool(settings, "debug_mode", false)
end

-- The dock's nine buttons and dot by dot are plain hotkeys, so they work from the keyboard too.
local hotkeys = {}

local function register_hotkeys(settings)
	local function add(name, desc, fn)
		local id = obs.obs_hotkey_register_frontend(name, SCRIPT_NAME .. " - " .. desc,
			function(pressed) if pressed then fn(); write_dock_state() end end)
		local arr = obs.obs_data_get_array(settings, name)
		obs.obs_hotkey_load(id, arr)
		obs.obs_data_array_release(arr)
		hotkeys[name] = id
	end
	for _, k in ipairs(POSITIONS) do
		add("sr_move_" .. k, string.format(T("hk_move"), T(k)), function()
			local n = for_selected(function(it, scene_src) move_item(it, scene_src, k) end)
			if debug_mode then log(obs.LOG_INFO, string.format("[debug] moved %d item(s) to %s", n, k)) end
		end)
	end
	add("sr_dot", T("hk_dot"), function() for_selected(function(it) set_item_scale(it, 1, 1) end) end)
	add("sr_command", "dock", on_command)
end

function script_save(settings)
	for name, id in pairs(hotkeys) do
		local arr = obs.obs_hotkey_save(id)
		obs.obs_data_set_array(settings, name, arr)
		obs.obs_data_array_release(arr)
	end
end

function script_load(settings)
	script_settings = settings
	obs.obs_data_set_string(settings, "language", lang_setting)
	obs.obs_data_set_string(settings, "dock_url", file_url(script_dir() .. DOCK_HTML))
	debug_mode = obs.obs_data_get_bool(settings, "debug_mode")
	register_hotkeys(settings)
	write_dock_state()
	obs.timer_add(write_dock_state, POLL_MS)
	log(obs.LOG_INFO, string.format("%s %s loaded (lang=%s, debug=%s)",
		SCRIPT_NAME, VERSION, current_lang, tostring(debug_mode)))
end

function script_unload()
	obs.timer_remove(write_dock_state)
end
