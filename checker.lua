script_name('Admin Checker')
script_author('akionka')
script_version('1.0')
script_version_number(1)

local sampev = require 'lib.samp.events'
local encoding = require 'encoding'
local inicfg = require('inicfg')
local dlstatus = require('moonloader').download_status
encoding.default = 'cp1251'
u8 = encoding.UTF8

admins = {}
admins_online = {}
ini = inicfg.load({settings = {shownofit = true, showonscreen = false}}, "admins")
function sampev.onPlayerQuit(id, reason)
	for i, v in ipairs(admins_online) do
		if v["id"] == id then
			if ini.settings.shownofit then
				sampAddChatMessage(u8:decode("[ADMINS]: Администратор {2980b9}"..v["nick"].."{FFFFFF} покинул сервер."), -1)
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
				sampAddChatMessage(u8:decode("[ADMINS]: Администратор {2980b9}"..nick.."{FFFFFF} зашел на сервер."), -1)
			end
			break
		end
	end
end

function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(0) end
	loadadmins()
	sampRegisterChatCommand("admins", function()
		if #admins_online == 0 then sampAddChatMessage(u8:decode("[ADMINS]: Администраторов он-лайн нет."), -1) return true end
		sampAddChatMessage(u8:decode("[ADMINS]: В данный момент на сервере находится {2980b9}"..#admins_online.."{FFFFFF} администратор (-а, -ов):"), -1)
		for i, v in ipairs(admins_online) do
			sampAddChatMessage(u8:decode("[ADMINS]: {2980b9}"..v["nick"].."{FFFFFF}."), -1)
		end
		sampAddChatMessage(u8:decode("[ADMINS]: В данный момент на сервере находится {2980b9}"..#admins_online.."{FFFFFF} администратор (-а, -ов)."), -1)
	end)
	sampRegisterChatCommand("adminstog", function()
		ini.settings.shownofit = not ini.settings.shownofit
		inicfg.save(ini, "admins")
		sampAddChatMessage(ini.settings.shownofit and u8:decode("[ADMINS]: Теперь оповещения о входе/выходе администратора {00FF00}будут{FFFFFF} показываться в чате.") or u8:decode("[ADMINS]: Теперь оповещения о входе/выходе администратора {FF0000}не будут{FFFFFF} показываться в чате."), -1)
	end)
	while true do
		wait(0)
		local renderPosY = 100
		for _, v in ipairs(admins_online) do
			renderFontDrawText(renderCreateFont("Arial", 9, 9), v, 100, renderPosY, bit.bor(rgb, 0xFF000000))
			renderPosY = renderPosY + 15
		end
	end
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

function trim(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1")) end
