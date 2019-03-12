script_name('Admin Checker')
script_author('akionka')
script_version('1.8')
script_version_number(12)

local sampev = require 'lib.samp.events'
local encoding = require 'encoding'
local inicfg = require 'inicfg'
local imgui = require 'imgui'
local dlstatus = require 'moonloader'.download_status
local updatesavaliable = false
encoding.default = 'cp1251'
u8 = encoding.UTF8

local admins = {}
local admins_online = {}

local ini = inicfg.load({
	settings = {
		shownotif = true,
		showonscreen = false,
		posX = 40,
		posY = 460,
		color = 0xFF0000,
		font = "Arial",
		startmsg = true
	},
	color = {
		r = 255,
		g = 255,
		b = 255,
	},
}, "admins")

function sampev.onPlayerQuit(id, reason)
	for i, v in ipairs(admins_online) do
		if v["id"] == id then
			if ini.settings.shownotif then
				sampAddChatMessage(u8:decode("[Checker]: Администратор {2980b9}"..v["nick"].."{FFFFFF} покинул сервер."), -1)
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
			if ini.settings.shownotif then
				sampAddChatMessage(u8:decode("[Checker]: Администратор {2980b9}"..nick.."{FFFFFF} зашел на сервер."), -1)
			end
			break
		end
	end
end
local main_window_state = imgui.ImBool(false)
local onscreen = imgui.ImBool(ini.settings.showonscreen)
local startmsg = imgui.ImBool(ini.settings.startmsg)
local shownotif = imgui.ImBool(ini.settings.shownotif)
local posX = imgui.ImInt(0)
local posY = imgui.ImInt(0)
local pos = imgui.ImVec2(0, 0)
local fontA = imgui.ImBuffer(ini.settings.font, 256)

local r, g, b = imgui.ImColor(ini.color.r, ini.color.g, ini.color.b):GetFloat4()
local color = imgui.ImFloat3(r, g, b)
function imgui.OnDrawFrame()
  if main_window_state.v then
		imgui.Begin(thisScript().name.." v"..thisScript().version, main_window_state, imgui.WindowFlags.AlwaysAutoResize)
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
		if imgui.Checkbox("Оповещения о входе/выходе администраторов", shownotif) then
			ini.settings.shownotif = shownotif.v
			inicfg.save(ini, "admins")
		end
		if imgui.Checkbox("Стартовое сообщение", startmsg) then
			ini.settings.startmsg = startmsg.v
			inicfg.save(ini, "admins")
		end
		if imgui.Button("Перезагрузить админов") then
	    	rebuildadmins()
		end
		if updatesavaliable then
			if imgui.Button('Скачать обновление') then
				update('https://raw.githubusercontent.com/Akionka/checker/master/checker.lua')
				main_window_state.v = false
			end
		else
			if imgui.Button('Проверить обновление') then
				checkupdates('https://raw.githubusercontent.com/Akionka/checker/master/version.json')
			end
		end
		imgui.End()
  end
end

function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(0) end

	checkupdates('https://raw.githubusercontent.com/Akionka/checker/master/version.json')
	rebuildadmins()

	if ini.settings.startmsg then
		sampAddChatMessage(u8:decode("[Checker]: Скрипт {00FF00}успешно{FFFFFF} загружен. Версия: {2980b9}"..thisScript().version.."{FFFFFF}."), -1)
		sampAddChatMessage(u8:decode("[Checker]: Автор - {2980b9}Akionka{FFFFFF}. Выключить данное сообщение можно в {2980b9}/checker{FFFFFF}."), -1)
		sampAddChatMessage(u8:decode("[Checker]: Кстати, чтобы посмотреть список администраторов он-лайн введи {2980b9}/admins{FFFFFF}."), -1)
	end

	sampRegisterChatCommand("admins", function()
		if #admins_online == 0 then sampAddChatMessage(u8:decode("[Checker]: Администраторов он-лайн нет."), -1) return true end
		sampAddChatMessage(u8:decode("[Checker]: В данный момент на сервере находится {2980b9}"..#admins_online.."{FFFFFF} администратор (-а, -ов):"), -1)
		for i, v in ipairs(admins_online) do
			sampAddChatMessage(u8:decode("[Checker]: {2980b9}"..v["nick"].." ["..v["id"].."]{FFFFFF}."), -1)
		end
		sampAddChatMessage(u8:decode("[Checker]: В данный момент на сервере находится {2980b9}"..#admins_online.."{FFFFFF} администратор (-а, -ов)."), -1)
	end)

	sampRegisterChatCommand("checker", function()
		imgui.SetNextWindowPos(imgui.ImVec2(200, 500), imgui.Cond.Always)
		main_window_state.v = not main_window_state.v
	end)

	font = renderCreateFont(ini.settings.font, 9, 5)

	while true do
		wait(0)
		if isGoUpdate then goupdate() break end
		if ini.settings.showonscreen then
			local renderPosY = ini.settings.posY
			renderFontDrawText(font, "Admins Online ["..#admins_online.."]:", ini.settings.posX, ini.settings.posY, bit.bor(ini.settings.color, 0xFF000000))
			renderPosY = renderPosY + 30
			for _, v in ipairs(admins_online) do
				renderFontDrawText(font, v["nick"].." ["..v["id"].."]", ini.settings.posX, renderPosY, bit.bor(ini.settings.color, 0xFF000000))
				renderPosY = renderPosY + 15
			end
		end
		imgui.Process = main_window_state.v
	end
end

function loadadmins()
	admins = {}
	if doesFileExist("moonloader/config/adminlist.txt") then
		for admin in io.lines("moonloader/config/adminlist.txt") do
			table.insert(admins, admin:match("(%S+)"))
		end
		print(u8:decode('Загрузка закончена. Загружено: '..#admins..' админов.'))
	else
		print(u8:decode('Файла с админами в директории <moonloader/config/adminlist.txt> не обнаружено, создан автоматически'))
		io.close(io.open("moonloader/config/adminlist.txt", "w"))
	end
end

function rebuildadmins()
	loadadmins()
	admins_online = {}
	for id = 0, 1000 do
		for i, v in ipairs(admins) do
			if sampIsPlayerConnected(id) then
				if sampGetPlayerNickname(id) == v then
					table.insert(admins_online, {nick = v, id = id})
				end
			end
		end
	end
	sampAddChatMessage(u8:decode("[Checker]: Список админов онлайн перезагружен."), -1)
end

function checkupdates(json)
	local fpath = os.getenv('TEMP')..'\\'..thisScript().name..'-version.json'
	if doesFileExist(fpath) then os.remove(fpath) end
	downloadUrlToFile(json, fpath, function(_, status, _, _)
		if status == dlstatus.STATUSEX_ENDDOWNLOAD then
			if doesFileExist(fpath) then
				local f = io.open(fpath, 'r')
				if f then
					local info = decodeJson(f:read('*a'))
					local updateversion = info.version_num
					f:close()
					os.remove(fpath)
					if updateversion > thisScript().version_num then
						updatesavaliable = true
						sampAddChatMessage(u8:decode("[Checker]: Найдено объявление. Текущая версия: {2980b9}"..thisScript().version.."{FFFFFF}, новая версия: {2980b9}"..updateversion.."{FFFFFF}."), -1)
						return true
					else
						updatesavaliable = false
						sampAddChatMessage(u8:decode("[Checker]: У вас установлена самая свежая версия скрипта."), -1)
					end
				else
					updatesavaliable = false
					sampAddChatMessage(u8:decode("[Checker]: Что-то пошло не так, упс. Попробуйте позже."), -1)
				end
			end
		end
	end)
end

function update(url)
	downloadUrlToFile(url, thisScript().path, function(_, status1, _, _)
		if status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
			sampAddChatMessage(u8:decode('[Checker]: Новая версия установлена! Чтобы скрипт обновился нужно либо перезайти в игру, либо ...'), -1)
			sampAddChatMessage(u8:decode('[Checker]: ... если у вас есть автоперезагрузка скриптов, то новая версия уже готова и снизу вы увидите приветственное сообщение.'), -1)
			sampAddChatMessage(u8:decode('[Checker]: Если что-то пошло не так, то сообщите мне об этом в VK или Telegram > {2980b0}vk.com/akionka teleg.run/akionka{FFFFFF}.'), -1)
			thisScript():reload()
		end
	end)
end

function join_argb(a, r, g, b)
   local argb = b
   argb = bit.bor(argb, bit.lshift(g, 8))
   argb = bit.bor(argb, bit.lshift(r, 16))
   argb = bit.bor(argb, bit.lshift(a, 24))
   return argb
end
