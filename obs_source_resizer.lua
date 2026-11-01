--[[
================================================================================
 Source Resizer  -  OBS Studio Lua script (Windows)

 A browser dock for laying out sources: nine-point buttons push the selected
 items flush against the canvas edge, and size buttons set them to classic
 and current resolutions, a custom pixel size, a favorite, the full canvas,
 or dot by dot.

 Author : ChromeBread feat. BlackDream
================================================================================
]]

local obs = obslua

--------------------------------------------------------------------------------
-- Meta
--------------------------------------------------------------------------------
local SCRIPT_NAME = "Source Resizer"
local VERSION     = "1.1.0"
local BUILD_DATE  = { year = 2026, month = 11, day = 1 }
local AUTHOR      = "ChromeBread feat. BlackDream"
local DOCK_HTML   = "obs_source_resizer_dock.html"
local STATE_JS    = "obs_source_resizer_state.js"
local PREFS_FILE  = "obs_source_resizer_prefs.json"
local CMD_SECTION = "SourceResizer"
local CMD_KEY     = "cmd"
local POLL_MS     = 300
local MAX_SIZE    = 16384
local MAX_FAVORITES = 48

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
		ws_host = "WebSocket host", ws_port = "WebSocket port", ws_password = "WebSocket password",
		dock_show = "Show Dock URL", dock_hide = "Hide Dock URL",
		uninstall_info = "<b>Uninstall</b><br>1. Export your settings below if you want to keep them.<br>2. Tools → Scripts: select this script and press −.<br>3. Run Safe_Uninstaller.bat from the folder below. To remove files by hand, delete only these and leave the folder itself:<br><br>%s<br>%s",
		backup_export_file = "Export settings to", backup_export = "Export settings",
		backup_import_file = "Import settings from", backup_import = "Import settings",
		backup_no_file = "Choose a file first.", backup_failed = "The file could not be read or written.",
		backup_wrong_app = "This file belongs to a different script.",
		backup_exported = "Settings exported.", backup_imported = "Settings imported. Hotkeys apply after restarting OBS.",
		desc = "<p>Lay out sources from a dock: nine buttons push the selected items flush against the canvas edge, and size buttons set classic or current resolutions, a custom size, a favorite, the full canvas or dot by dot.</p>",
		version = "Version", build_date = "Build date", author = "Author",
		language = "Language", lang_auto = "Auto (OBS)",
		debug_on = "Debug Mode: ON", debug_off = "Debug Mode: OFF",
		dock_url = "Dock URL",
		dock_howto = "1. Copy the Dock URL.\n2. In OBS: Docks → Custom Browser Docks… → enter a name and paste the URL.\n3. The dock talks to OBS via WebSocket (Tools → WebSocket Server Settings). Enter the same port / password below.",
		hk_move = "Move to: %s", hk_dot = "Dot by dot",
		tl = "Top left", tc = "Top", tr = "Top right", ml = "Left", mc = "Center", mr = "Right", bl = "Bottom left", bc = "Bottom", br = "Bottom right",
	},
	ja = {
		ws_host = "WebSocket ホスト", ws_port = "WebSocket ポート", ws_password = "WebSocket パスワード",
		dock_show = "ドックURLを表示", dock_hide = "ドックURLを隠す",
		uninstall_info = "<b>アンインストール</b><br>1. 設定を残す場合は、下の項目で書き出します。<br>2. ツール → スクリプト でこのスクリプトを選び、− を押します。<br>3. 下のフォルダにある Safe_Uninstaller.bat を実行します。手動で消す場合は次のファイルだけを削除し、フォルダ自体は消さないでください。<br><br>%s<br>%s",
		backup_export_file = "設定の書き出し先", backup_export = "設定を書き出す",
		backup_import_file = "設定の読み込み元", backup_import = "設定を読み込む",
		backup_no_file = "先にファイルを選んでください。", backup_failed = "ファイルを読み書きできませんでした。",
		backup_wrong_app = "別のスクリプトのファイルです。",
		backup_exported = "設定を書き出しました。", backup_imported = "設定を読み込みました。ホットキーはOBSの再起動後に反映されます。",
		desc = "<p>ドックでソースを配置します。9個のボタンで選択中のアイテムをキャンバスの端にぴったり寄せ、サイズボタンでレトロから現行までの解像度、指定サイズ、お気に入り、キャンバス全体、ドットバイドットに変更できます。</p>",
		version = "バージョン", build_date = "ビルド日", author = "製作者",
		language = "言語", lang_auto = "自動 (OBS)",
		debug_on = "デバッグモード: ON", debug_off = "デバッグモード: OFF",
		dock_url = "ドックURL",
		dock_howto = "1. ドックURLをコピーします。\n2. OBSの「ドック → カスタムブラウザドック…」で名前を入力し、URLを貼り付けます。\n3. ドックは WebSocket（ツール → WebSocketサーバー設定）でOBSと通信します。同じポートとパスワードを下の欄に入力します。",
		hk_move = "移動: %s", hk_dot = "ドットバイドット",
		tl = "左上", tc = "上", tr = "右上", ml = "左", mc = "中央", mr = "右", bl = "左下", bc = "下", br = "右下",
	},
	ko = {
		ws_host = "WebSocket 호스트", ws_port = "WebSocket 포트", ws_password = "WebSocket 비밀번호",
		dock_show = "도크 URL 표시", dock_hide = "도크 URL 숨기기",
		uninstall_info = "<b>제거</b><br>1. 설정을 유지하려면 아래 항목에서 내보내세요.<br>2. 도구 → 스크립트에서 이 스크립트를 선택하고 − 를 누르세요.<br>3. 아래 폴더의 Safe_Uninstaller.bat을 실행하세요. 직접 지울 때는 다음 파일만 삭제하고 폴더 자체는 지우지 마세요.<br><br>%s<br>%s",
		backup_export_file = "설정 내보내기 위치", backup_export = "설정 내보내기",
		backup_import_file = "설정 가져오기 파일", backup_import = "설정 가져오기",
		backup_no_file = "먼저 파일을 선택하세요.", backup_failed = "파일을 읽거나 쓸 수 없습니다.",
		backup_wrong_app = "다른 스크립트의 파일입니다.",
		backup_exported = "설정을 내보냈습니다.", backup_imported = "설정을 가져왔습니다. 단축키는 OBS를 다시 시작하면 적용됩니다.",
		desc = "<p>도크에서 소스를 배치합니다. 버튼 9개로 선택한 항목을 캔버스 가장자리에 딱 붙이고, 크기 버튼으로 클래식부터 현행까지의 해상도, 지정 크기, 즐겨찾기, 캔버스 전체, 도트 바이 도트로 바꿀 수 있습니다.</p>",
		version = "버전", build_date = "빌드 날짜", author = "제작자",
		language = "언어", lang_auto = "자동 (OBS)",
		debug_on = "디버그 모드: ON", debug_off = "디버그 모드: OFF",
		dock_url = "도크 URL",
		dock_howto = "1. 도크 URL을 복사합니다.\n2. OBS에서 도크 → 사용자 지정 브라우저 도크… 에 이름을 입력하고 URL을 붙여넣습니다.\n3. 도크는 WebSocket(도구 → WebSocket 서버 설정)으로 OBS와 통신합니다. 같은 포트와 비밀번호를 아래 칸에 입력하세요.",
		hk_move = "이동: %s", hk_dot = "도트 바이 도트",
		tl = "왼쪽 위", tc = "위", tr = "오른쪽 위", ml = "왼쪽", mc = "가운데", mr = "오른쪽", bl = "왼쪽 아래", bc = "아래", br = "오른쪽 아래",
	},
	id = {
		ws_host = "Host WebSocket", ws_port = "Port WebSocket", ws_password = "Kata sandi WebSocket",
		dock_show = "Tampilkan URL Dock", dock_hide = "Sembunyikan URL Dock",
		uninstall_info = "<b>Hapus instalasi</b><br>1. Ekspor pengaturan di bawah jika ingin menyimpannya.<br>2. Alat → Skrip: pilih skrip ini lalu tekan −.<br>3. Jalankan Safe_Uninstaller.bat dari folder di bawah. Untuk menghapus manual, hapus hanya file berikut dan jangan hapus foldernya:<br><br>%s<br>%s",
		backup_export_file = "Ekspor pengaturan ke", backup_export = "Ekspor pengaturan",
		backup_import_file = "Impor pengaturan dari", backup_import = "Impor pengaturan",
		backup_no_file = "Pilih file terlebih dahulu.", backup_failed = "File tidak dapat dibaca atau ditulis.",
		backup_wrong_app = "File ini milik skrip lain.",
		backup_exported = "Pengaturan diekspor.", backup_imported = "Pengaturan diimpor. Hotkey berlaku setelah OBS dimulai ulang.",
		desc = "<p>Atur sumber dari dock: sembilan tombol menempelkan item terpilih ke tepi kanvas, dan tombol ukuran mengatur resolusi klasik hingga terkini, ukuran khusus, favorit, seluruh kanvas, atau dot by dot.</p>",
		version = "Versi", build_date = "Tanggal build", author = "Pembuat",
		language = "Bahasa", lang_auto = "Otomatis (OBS)",
		debug_on = "Mode Debug: ON", debug_off = "Mode Debug: OFF",
		dock_url = "URL Dock",
		dock_howto = "1. Salin URL Dock.\n2. Di OBS: Dock → Dock Peramban Kustom… → masukkan nama dan tempel URL.\n3. Dock berkomunikasi dengan OBS melalui WebSocket (Alat → Pengaturan Server WebSocket). Masukkan port / kata sandi yang sama di bawah.",
		hk_move = "Pindah ke: %s", hk_dot = "Dot by dot",
		tl = "Kiri atas", tc = "Atas", tr = "Kanan atas", ml = "Kiri", mc = "Tengah", mr = "Kanan", bl = "Kiri bawah", bc = "Bawah", br = "Kanan bawah",
	},
	fr = {
		ws_host = "Hôte WebSocket", ws_port = "Port WebSocket", ws_password = "Mot de passe WebSocket",
		dock_show = "Afficher l'URL du dock", dock_hide = "Masquer l'URL du dock",
		uninstall_info = "<b>Désinstallation</b><br>1. Exportez vos réglages ci-dessous si vous voulez les garder.<br>2. Outils → Scripts : sélectionnez ce script et cliquez sur −.<br>3. Lancez Safe_Uninstaller.bat depuis le dossier ci-dessous. Pour supprimer à la main, effacez uniquement ces fichiers, sans toucher au dossier :<br><br>%s<br>%s",
		backup_export_file = "Exporter les réglages vers", backup_export = "Exporter les réglages",
		backup_import_file = "Importer les réglages depuis", backup_import = "Importer les réglages",
		backup_no_file = "Choisissez d'abord un fichier.", backup_failed = "Impossible de lire ou d'écrire le fichier.",
		backup_wrong_app = "Ce fichier appartient à un autre script.",
		backup_exported = "Réglages exportés.", backup_imported = "Réglages importés. Les raccourcis s'appliquent après le redémarrage d'OBS.",
		desc = "<p>Disposez vos sources depuis un dock : neuf boutons collent les éléments sélectionnés au bord du canevas, et les boutons de taille appliquent des résolutions rétro ou actuelles, une taille personnalisée, un favori, le canevas entier ou le dot by dot.</p>",
		version = "Version", build_date = "Date de build", author = "Auteur",
		language = "Langue", lang_auto = "Automatique (OBS)",
		debug_on = "Mode débogage : ON", debug_off = "Mode débogage : OFF",
		dock_url = "URL du dock",
		dock_howto = "1. Copiez l'URL du dock.\n2. Dans OBS : Docks → Docks de navigateur personnalisés… → saisissez un nom et collez l'URL.\n3. Le dock communique avec OBS via WebSocket (Outils → Paramètres du serveur WebSocket). Saisissez le même port / mot de passe ci-dessous.",
		hk_move = "Déplacer : %s", hk_dot = "Dot by dot",
		tl = "En haut à gauche", tc = "En haut", tr = "En haut à droite", ml = "À gauche", mc = "Centre", mr = "À droite", bl = "En bas à gauche", bc = "En bas", br = "En bas à droite",
	},
	zh_TW = {
		ws_host = "WebSocket 主機", ws_port = "WebSocket 連接埠", ws_password = "WebSocket 密碼",
		dock_show = "顯示 Dock 網址", dock_hide = "隱藏 Dock 網址",
		uninstall_info = "<b>解除安裝</b><br>1. 若要保留設定，請先在下方匯出。<br>2. 在 工具 → 腳本 中選取此腳本並按 −。<br>3. 執行下方資料夾中的 Safe_Uninstaller.bat。若要手動刪除，請只刪除下列檔案，不要刪除資料夾本身。<br><br>%s<br>%s",
		backup_export_file = "設定匯出至", backup_export = "匯出設定",
		backup_import_file = "設定匯入來源", backup_import = "匯入設定",
		backup_no_file = "請先選擇檔案。", backup_failed = "無法讀取或寫入檔案。",
		backup_wrong_app = "此檔案屬於其他腳本。",
		backup_exported = "已匯出設定。", backup_imported = "已匯入設定。快速鍵會在重新啟動 OBS 後套用。",
		desc = "<p>在 Dock 中配置來源：9 個按鈕可將選取的項目緊貼畫布邊緣，大小按鈕可切換復古到現行的解析度、自訂大小、我的最愛、整個畫布或點對點。</p>",
		version = "版本", build_date = "建置日期", author = "製作者",
		language = "語言", lang_auto = "自動 (OBS)",
		debug_on = "偵錯模式：ON", debug_off = "偵錯模式：OFF",
		dock_url = "Dock 網址",
		dock_howto = "1. 複製 Dock 網址。\n2. 在 OBS 中：停駐視窗 → 自訂瀏覽器停駐視窗… → 輸入名稱並貼上網址。\n3. Dock 透過 WebSocket（工具 → WebSocket 伺服器設定）與 OBS 通訊，請在下方輸入相同的連接埠與密碼。",
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
	local d = obs.obs_data_create_from_json_file_safe(script_dir() .. PREFS_FILE, "bak")
	if d then
		local l = obs.obs_data_get_string(d, "language")
		if l == "auto" or I18N[l] then lang_setting = l end
		for i = #favorites, 1, -1 do favorites[i] = nil end
		for f in obs.obs_data_get_string(d, "favorites"):gmatch("%d+x%d+") do
			if #favorites < MAX_FAVORITES then favorites[#favorites + 1] = f end
		end
		obs.obs_data_release(d)
	end
end

local function save_prefs()
	local d = obs.obs_data_create()
	obs.obs_data_set_string(d, "language", lang_setting)
	obs.obs_data_set_string(d, "favorites", table.concat(favorites, ","))
	obs.obs_data_save_json_safe(d, script_dir() .. PREFS_FILE, "tmp", "bak")
	obs.obs_data_release(d)
end

local last_state = nil

-- The dock has no connection fields, so it reads these from here, like OBS's own WebSocket settings.
local ws_json = '{"host":"localhost","port":4455,"password":""}'

local function set_ws(settings)
	local function quoted(s)
		return '"' .. (s:gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end)) .. '"'
	end
	local host = obs.obs_data_get_string(settings, "ws_host")
	ws_json = string.format('{"host":%s,"port":%d,"password":%s}', quoted(host ~= "" and host or "localhost"),
		obs.obs_data_get_int(settings, "ws_port"), quoted(obs.obs_data_get_string(settings, "ws_password")))
end

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
		'srState({"lang":"%s","name":"%s","version":"%s","buildDate":"%s","author":"%s","count":%d,"w":%d,"h":%d,"favs":[%s],"ws":%s});',
		current_lang, SCRIPT_NAME, VERSION, format_date(BUILD_DATE, current_lang), AUTHOR,
		count, w, h, table.concat(favs, ","), ws_json)
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
	if add and #favorites < MAX_FAVORITES then
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

local UNINSTALL_FILES = "obs_source_resizer.lua<br>obs_source_resizer_dock.html<br>obs_source_resizer_prefs.json<br>obs_source_resizer_state.js"
local BACKUP_SKIP = { "dock_url", "ws_password", "backup_export_file", "backup_import_file" }

local DEBUG_LABELS = {
	backup_export_file = "backup_export_file", backup_export = "backup_export",
	backup_import_file = "backup_import_file", backup_import = "backup_import",
}

local dock_shown = false

local function apply_debug_props(props)
	for _, name in ipairs({ "ws_host", "ws_port", "ws_password" }) do
		obs.obs_property_set_description(obs.obs_properties_get(props, name), T(name))
	end
	for _, name in ipairs({ "dock_url", "dock_info", "ws_host", "ws_port", "ws_password" }) do
		obs.obs_property_set_visible(obs.obs_properties_get(props, name), dock_shown or debug_mode)
	end
	obs.obs_property_set_description(obs.obs_properties_get(props, "dock_toggle"), T(dock_shown and "dock_hide" or "dock_show"))
	for name, key in pairs(DEBUG_LABELS) do
		local p = obs.obs_properties_get(props, name)
		if p then
			obs.obs_property_set_description(p, T(key))
			obs.obs_property_set_visible(p, debug_mode)
		end
	end
	local info = obs.obs_properties_get(props, "uninstall_info")
	if info then
		-- The folder can reveal a user name, so this stays behind Debug Mode.
		obs.obs_property_set_description(info, string.format(T("uninstall_info"), script_dir(), UNINSTALL_FILES))
		obs.obs_property_set_visible(info, debug_mode)
	end
	local status = obs.obs_properties_get(props, "backup_status")
	if status then obs.obs_property_set_visible(status, debug_mode) end
end

local function apply_script_props(props)
	for _, k in ipairs({ { "language", "language" }, { "dock_url", "dock_url" }, { "dock_info", "dock_howto" } }) do
		obs.obs_property_set_description(obs.obs_properties_get(props, k[1]), T(k[2]))
	end
	obs.obs_property_set_description(obs.obs_properties_get(props, "debug_toggle"),
		debug_mode and T("debug_on") or T("debug_off"))
	apply_debug_props(props)
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

local function set_backup_status(props, text)
	obs.obs_property_set_description(obs.obs_properties_get(props, "backup_status"), text)
	log(obs.LOG_INFO, text)
end

local function backup_path(key)
	return script_settings and obs.obs_data_get_string(script_settings, key) or ""
end

-- One readable JSON file, so a setting can still be copied by hand on another PC.
local function on_backup_export(props, _)
	local path = backup_path("backup_export_file")
	if path == "" then set_backup_status(props, T("backup_no_file")); return true end
	if script_save then script_save(script_settings) end
	local data = obs.obs_data_create()
	local settings = obs.obs_data_create_from_json(obs.obs_data_get_json(script_settings))
	for _, key in ipairs(BACKUP_SKIP) do obs.obs_data_erase(settings, key) end
	obs.obs_data_set_string(data, "app", SCRIPT_NAME)
	obs.obs_data_set_string(data, "version", VERSION)
	obs.obs_data_set_obj(data, "settings", settings)
	local prefs = obs.obs_data_create_from_json_file(script_dir() .. PREFS_FILE)
	if prefs then
		obs.obs_data_set_obj(data, "prefs", prefs)
		obs.obs_data_release(prefs)
	end
	local save = obs.obs_data_save_json_pretty or obs.obs_data_save_json
	local ok = save(data, path)
	obs.obs_data_release(settings)
	obs.obs_data_release(data)
	set_backup_status(props, ok and T("backup_exported") or T("backup_failed"))
	return true
end

local function on_backup_import(props, _)
	local path = backup_path("backup_import_file")
	if path == "" then set_backup_status(props, T("backup_no_file")); return true end
	local data = obs.obs_data_create_from_json_file(path)
	if not data then set_backup_status(props, T("backup_failed")); return true end
	if obs.obs_data_get_string(data, "app") ~= SCRIPT_NAME then
		obs.obs_data_release(data)
		set_backup_status(props, T("backup_wrong_app"))
		return true
	end
	local settings = obs.obs_data_get_obj(data, "settings")
	if settings then
		for _, key in ipairs(BACKUP_SKIP) do obs.obs_data_erase(settings, key) end
		obs.obs_data_erase(settings, "debug_mode")
		obs.obs_data_apply(script_settings, settings)
		obs.obs_data_release(settings)
	end
	local prefs = obs.obs_data_get_obj(data, "prefs")
	if prefs then
		obs.obs_data_save_json_safe(prefs, script_dir() .. PREFS_FILE, "tmp", "bak")
		obs.obs_data_release(prefs)
		load_prefs()
		resolve_lang()
	end
	obs.obs_data_release(data)
	obs.obs_data_set_string(script_settings, "language", lang_setting)
	if script_update then script_update(script_settings) end
	write_dock_state()
	apply_script_props(props)
	set_backup_status(props, T("backup_imported"))
	return true
end

local function on_dock_toggle(props, _)
	dock_shown = not dock_shown
	apply_script_props(props)
	return true
end

local function add_debug_props(props)
	obs.obs_properties_add_text(props, "uninstall_info", "", obs.OBS_TEXT_INFO)
	obs.obs_properties_add_path(props, "backup_export_file", "", obs.OBS_PATH_FILE_SAVE, "JSON (*.json)", nil)
	obs.obs_properties_add_button(props, "backup_export", "", on_backup_export)
	obs.obs_properties_add_path(props, "backup_import_file", "", obs.OBS_PATH_FILE, "JSON (*.json)", nil)
	obs.obs_properties_add_button(props, "backup_import", "", on_backup_import)
	obs.obs_properties_add_text(props, "backup_status", " ", obs.OBS_TEXT_INFO)
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
	obs.obs_properties_add_button(props, "dock_toggle", T("dock_show"), on_dock_toggle)
	obs.obs_properties_add_text(props, "dock_url", T("dock_url"), obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "dock_info", T("dock_howto"), obs.OBS_TEXT_INFO)
	obs.obs_properties_add_text(props, "ws_host", T("ws_host"), obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_int(props, "ws_port", T("ws_port"), 1, 65535, 1)
	obs.obs_properties_add_text(props, "ws_password", T("ws_password"), obs.OBS_TEXT_PASSWORD)
	obs.obs_properties_add_button(props, "debug_toggle", T("debug_off"), on_debug_toggle)
	add_debug_props(props)
	apply_script_props(props)
	return props
end

function script_defaults(settings)
	obs.obs_data_set_default_string(settings, "language", "auto")
	obs.obs_data_set_default_bool(settings, "debug_mode", false)
	obs.obs_data_set_default_string(settings, "ws_host", "localhost")
	obs.obs_data_set_default_int(settings, "ws_port", 4455)
	obs.obs_data_set_default_string(settings, "ws_password", "")
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

function script_update(settings)
	set_ws(settings)
	write_dock_state()
end

function script_load(settings)
	script_settings = settings
	obs.obs_data_set_string(settings, "language", lang_setting)
	obs.obs_data_set_string(settings, "dock_url", file_url(script_dir() .. DOCK_HTML))
	debug_mode = obs.obs_data_get_bool(settings, "debug_mode")
	set_ws(settings)
	register_hotkeys(settings)
	write_dock_state()
	obs.timer_add(write_dock_state, POLL_MS)
	log(obs.LOG_INFO, string.format("%s %s loaded (lang=%s, debug=%s)",
		SCRIPT_NAME, VERSION, current_lang, tostring(debug_mode)))
end

function script_unload()
	obs.timer_remove(write_dock_state)
end
