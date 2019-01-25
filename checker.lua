script_name('Admin Checker')
script_author('akionka')
script_version('1.0')
script_version_number(1)
script_updatelog = [[v1.0 [28.01.2019]
I. Первый релиз. В общем и целом, скрипт работает.]]

local sampev = require 'lib.samp.events'
local encoding = require 'encoding'
local inicfg = require 'inicfg'
local imgui = require 'imgui'
local dlstatus = require 'moonloader'.download_status
encoding.default = 'cp1251'
u8 = encoding.UTF8

admins = {}
admins_online = {}
ini = inicfg.load({
	settings = {
		shownofit = true,
		showonscreen = false,
		posX = 40,
		posY = 460,
		color = 0xFF0000,
		font = "Arial",
		startmsg = true,
		autoupdt = true,
	},
	color = {
		r = 255,
		g = 255,
		b = 255,
	}
}, "admins")

function sampev.onPlayerQuit(id, reason)
	for i, v in ipairs(admins_online) do
		if v["id"] == id then
			if ini.settings.shownofit then
				sampAddChatMessage(u8:decode("[Admins]: Администратор {2980b9}"..v["nick"].."{FFFFFF} покинул сервер."), -1)
			end
			table.remove(admins_online, i)
			break
		end
	end
end

function sampev.onPlayerJoin(id, clist, isNPC, nick)
	for i, v in ipairs(admins) do
		if nick == v then
			table.insert(admins_online, {nick = nick, id = id})
			if ini.settings.shownofit then
				sampAddChatMessage(u8:decode("[Admins]: Администратор {2980b9}"..nick.."{FFFFFF} зашел на сервер."), -1)
			end
			break
		end
	end
end
local settings_window_state = imgui.ImBool(false)
local updtelog_window_state = imgui.ImBool(false)
local onscreen = imgui.ImBool(ini.settings.showonscreen)
local startmsg = imgui.ImBool(ini.settings.startmsg)
local autoupdt = imgui.ImBool(ini.settings.autoupdt)
local posX = imgui.ImInt(0)
local posY = imgui.ImInt(0)
local pos = imgui.ImVec2(0, 0)
local fontA = imgui.ImBuffer(ini.settings.font, 256)

local r, g, b = imgui.ImColor(ini.color.r, ini.color.g, ini.color.b):GetFloat4()
local color = imgui.ImFloat3(r, g, b)
function imgui.OnDrawFrame()
  if settings_window_state.v then
		imgui.Begin("Меню", settings_window_state, 66)
		posX.v = ini.settings.posX
		posY.v = ini.settings.posY
		if imgui.InputInt("X", posX) then
			ini.settings.posX = posX.v
			inicfg.save(ini, "admins")
		end
		if imgui.InputInt("Y", posY) then
			ini.settings.posY = posY.v
			inicfg.save(ini, "admins")
		end
		if imgui.InputText("Шрифт", fontA) then
			ini.settings.font = fontA.v
			font = renderCreateFont(ini.settings.font, 9, 5)
			inicfg.save(ini, "admins")
		end
		if imgui.ColorEdit3('Цвет текста', color) then
			ini.color = {r = color.v[1] * 255, g = color.v[2] * 255, b = color.v[3] * 255, }
			ini.settings.color = join_argb(255, color.v[1] * 255, color.v[2] * 255, color.v[3] * 255)
			inicfg.save(ini, "admins")
		end
		if imgui.Checkbox("Рендер на экране", onscreen) then
			ini.settings.showonscreen = onscreen.v
			inicfg.save(ini, "admins")
		end
		if imgui.Checkbox("Стартовое сообщение", startmsg) then
			ini.settings.startmsg = startmsg.v
			inicfg.save(ini, "admins")
		end
		if imgui.Checkbox("Автообновление", autoupdt) then
			ini.settings.autoupdt = autoupdt.v
			inicfg.save(ini, "admins")
		end
		if imgui.Button("Update Log") then
			updtelog_window_state.v = not updtelog_window_state.v
		end
		if imgui.Button("Проверить обновления") then
			lua_thread.create(update)
		end
		imgui.End()
  end
	if updtelog_window_state.v then
		imgui.Begin("Update Log", updtelog_window_state, 66)
		imgui.Text(script_updatelog)
		imgui.End()
	end
end

function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(0) end

	loadadmins()

	if ini.settings.startmsg then
		sampAddChatMessage(u8:decode("[Admins]: Скрипт {00FF00}успешно{FFFFFF} загружен. Версия: {2980b9}"..thisScript().version.."{FFFFFF}."), -1)
		sampAddChatMessage(u8:decode("[Admins]: Автор - {2980b9}Akionka{FFFFFF}. Выключить данное сообщение можно в {2980b9}/checker{FFFFFF}."), -1)
		sampAddChatMessage(u8:decode("[Admins]: Кстати, чтобы посмотреть список администраторов он-лайн введи {2980b9}/admins{FFFFFF}."), -1)
	end

	sampRegisterChatCommand("admins", function()
		if #admins_online == 0 then sampAddChatMessage(u8:decode("[Admins]: Администраторов он-лайн нет."), -1) return true end
		sampAddChatMessage(u8:decode("[Admins]: В данный момент на сервере находится {2980b9}"..#admins_online.."{FFFFFF} администратор (-а, -ов):"), -1)
		for i, v in ipairs(admins_online) do
			sampAddChatMessage(u8:decode("[Admins]: {2980b9}"..v["nick"].."{FFFFFF}."), -1)
		end
		sampAddChatMessage(u8:decode("[Admins]: В данный момент на сервере находится {2980b9}"..#admins_online.."{FFFFFF} администратор (-а, -ов)."), -1)
	end)
	sampRegisterChatCommand("checker", function()
		settings_window_state.v = not settings_window_state.v
	end)
	font = renderCreateFont(ini.settings.font, 9, 5)
	while true do
		wait(0)
		if ini.settings.showonscreen then
			local renderPosY = ini.settings.posY
			renderFontDrawText(font, "Admins Online ["..#admins_online.."]:", ini.settings.posX, ini.settings.posY, bit.bor(ini.settings.color, 0xFF000000))
			renderPosY = renderPosY + 30
			for _, v in ipairs(admins_online) do
				renderFontDrawText(font, v["nick"].." ["..v["id"].."]", ini.settings.posX, renderPosY, bit.bor(ini.settings.color, 0xFF000000))
				renderPosY = renderPosY + 15
			end
		end
		imgui.Process = settings_window_state.v
	end
end

function update()
	local fpath = os.getenv('TEMP') .. '\\checker-version.json'
	downloadUrlToFile('https://raw.githubusercontent.com/Akionka/checker/master/version.json', fpath, function(id, status, p1, p2)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			local f = io.open(fpath, 'r')
			if f then
				local info = decodeJson(f:read('*a'))
				if info and info.version then
					version = info.version
					version_num = info.version_num
					if version_num > thisScript().version_num then
						sampAddChatMessage(u8:decode("[Admins]: Найдено объявление. Текущая версия: {2980b9}"..thisScript().version.."{FFFFFF}, новая версия: {2980b9}"..version.."{FFFFFF}. Начинаю закачку."), -1)
						lua_thread.create(goupdate)
					else
						sampAddChatMessage(u8:decode("[Admins]: У вас установлена самая свежая версия скрипта."), -1)
						updateinprogess = false
					end
				end
			end
		end
	end)
end

function goupdate()
	downloadUrlToFile("https://raw.githubusercontent.com/Akionka/checker/master/checker.lua", thisScript().path, function(id3, status1, p13, p23)
		if status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
			sampAddChatMessage(u8:decode('[Admins]: Новая версия установлена! Чтобы скрипт обновился нужно либо перезайти в игру, либо ...'), -1)
			sampAddChatMessage(u8:decode('[Admins]: ... если у вас есть автоперезагрузка скриптов, то новая версия уже готова и снизу вы увидите приветственное сообщение.'), -1)
			sampAddChatMessage(u8:decode('[Admins]: Скорее всего прямо сейчас у вас сломался курсор. Введите {2980b9}/checker{FFFFFF}.'), -1)
			sampAddChatMessage(u8:decode('[Admins]: Если что-то пошло не так, то сообщите мне об этом в VK или Telegram > {2980b0}vk.com/akionka tele.run/akionka{FFFFFF}.'), -1)
		end
	end)
end

function loadadmins()
	if doesFileExist("moonloader/config/adminlist.txt") then
		for admin in io.lines("moonloader/config/adminlist.txt") do
			table.insert(admins, admin:match("(%S+)"))
		end
		print(u8:decode('Загрузка закончена. Загружено: '..#admins..' админов.'))
	else
		print(u8:decode('Файла с админами в директории <moonloader/config/adminlist.txt> не обнаружено, создан автоматически'))
	  io.open("moonloader/config/adminlist.txt", "w"):close()
	end
end

function explode_argb(argb)
  local a = bit.band(bit.rshift(argb, 24), 0xFF)
  local r = bit.band(bit.rshift(argb, 16), 0xFF)
  local g = bit.band(bit.rshift(argb, 8), 0xFF)
  local b = bit.band(argb, 0xFF)
  return a, r, g, b
end

function join_argb(a, r, g, b)
   local argb = b
   argb = bit.bor(argb, bit.lshift(g, 8))
   argb = bit.bor(argb, bit.lshift(r, 16))
   argb = bit.bor(argb, bit.lshift(a, 24))
   return argb
end

function ARGBtoRGB(color) return bit32 or require'bit'.band(color, 0xFFFFFF) end

function trim(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1")) end
