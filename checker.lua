script_name('Admin Checker')
script_author('akionka')
script_version('1.9.2')
script_version_number(16)

local sampev           = require 'lib.samp.events'
local encoding         = require 'encoding'
local inicfg           = require 'inicfg'
local imgui            = require 'imgui'
local dlstatus         = require 'moonloader'.download_status
local updatesavaliable = false
encoding.default       = 'cp1251'
local u8               = encoding.UTF8
local prefix           = 'Checker'
local doRemove         = false
local admins           = {}
local admins_online    = {}

local ini = inicfg.load({
  settings = {
    shownotif    = true,
    showonscreen = false,
    posX         = 40,
    posY         = 460,
    color        = 0xFF0000,
    font         = 'Arial',
    startmsg     = true,
    sorttype     = 0,
    hideonscreen = true
  },
  color = {
    r = 255,
    g = 255,
    b = 255,
  },
}, 'admins')

function sampev.onPlayerQuit(id, _)
  for i, v in ipairs(admins_online) do
    if v['id'] == id then
      if ini.settings.shownotif then
        sampAddChatMessage(u8:decode('[Checker]: Администратор {9932cc}'..v['nick']..'{FFFFFF} покинул сервер.'), -1)
      end
      table.remove(admins_online, i)
      break
    end
  end
end

function sampev.onPlayerJoin(id, _, _, nick)
  for i, v in ipairs(admins) do
    if nick == v then
      if ini.settings.shownotif then
        sampAddChatMessage(u8:decode('[Checker]: Администратор {9932cc}'..nick..'{FFFFFF} зашел на сервер.'), -1)
      end
      table.insert(admins_online, {nick = nick, id = id})
      if ini.settings.sorttype == 0 then break end
      table.sort(admins_online, function(a, b)
        if ini.settings.sorttype == 1 then return a['id'] > b['id'] end
        if ini.settings.sorttype == 2 then return a['id'] < b['id'] end
        if ini.settings.sorttype == 3 then return a['nick'] > b['nick'] end
        if ini.settings.sorttype == 4 then return a['nick'] < b['nick'] end
      end)
      break
    end
  end
end

local main_window_state = imgui.ImBool(false)
local onscreen          = imgui.ImBool(ini.settings.showonscreen)
local hideonscreen      = imgui.ImBool(ini.settings.hideonscreen)
local startmsg          = imgui.ImBool(ini.settings.startmsg)
local shownotif         = imgui.ImBool(ini.settings.shownotif)
local sorttype          = imgui.ImInt(ini.settings.sorttype)
local tempX             = ini.settings.posX
local tempY             = ini.settings.posY
local posX              = imgui.ImInt(ini.settings.posX)
local posY              = imgui.ImInt(ini.settings.posY)
local pos               = imgui.ImVec2(0, 0)
local fontA             = imgui.ImBuffer(ini.settings.font, 256)

function alert(text)
  sampAddChatMessage(u8:decode('['..prefix..']: '..text), -1)
end

local r, g, b = imgui.ImColor(ini.color.r, ini.color.g, ini.color.b):GetFloat4()
local color = imgui.ImFloat3(r, g, b)
function imgui.OnDrawFrame()
  if main_window_state.v then
    imgui.Begin(thisScript().name..' v'..thisScript().version, main_window_state, imgui.WindowFlags.AlwaysAutoResize)
    if imgui.InputInt('X', posX) then
      ini.settings.posX = posX.v
      inicfg.save(ini, 'admins')
    end
    if imgui.InputInt('Y', posY) then
      ini.settings.posY = posY.v
      inicfg.save(ini, 'admins')
    end
    if imgui.Button('Указать мышкой где должен быть список') then
      alert('Нажмите {9932cc}ЛКМ{FFFFFF}, чтобы завершить. Нажмите {9932cc}ПКМ{FFFFFF}, чтобы отменить.')
      main_window_state.v = false
      doRemove = true
    end
    if imgui.InputText('Шрифт', fontA) then
      ini.settings.font = fontA.v
      font = renderCreateFont(ini.settings.font, 9, 5)
      inicfg.save(ini, 'admins')
    end
    if imgui.ColorEdit3('Цвет текста', color) then
      ini.color = {r = color.v[1] * 255, g = color.v[2] * 255, b = color.v[3] * 255, }
      ini.settings.color = join_argb(255, color.v[1] * 255, color.v[2] * 255, color.v[3] * 255)
      inicfg.save(ini, 'admins')
    end
    if imgui.CollapsingHeader('Способ сортировки') then
      if imgui.ListBox('', sorttype, {'Никак', 'По увеличению ID', 'По уменьшению ID', 'По алфавиту', 'По алфавиту наоборот'}, imgui.ImInt(5)) then
        ini.settings.sorttype = sorttype.v
        if sorttype.v ~= 0 then
          table.sort(admins_online, function(a, b)
            if sorttype.v == 1 then return a['id'] < b['id'] end
            if sorttype.v == 2 then return a['id'] > b['id'] end
            if sorttype.v == 3 then return a['nick'] < b['nick'] end
            if sorttype.v == 4 then return a['nick'] > b['nick'] end
          end)
        end
        inicfg.save(ini, 'admins')
      end
      imgui.Separator()
    end
    if imgui.Checkbox('Рендер на экране', onscreen) then
      ini.settings.showonscreen = onscreen.v
      inicfg.save(ini, 'admins')
    end
    if imgui.Checkbox('Прятать на скриншотах', hideonscreen) then
      ini.settings.hideonscreen = hideonscreen.v
      inicfg.save(ini, 'admins')
    end
    if imgui.Checkbox('Оповещения о входе/выходе администраторов', shownotif) then
      ini.settings.shownotif = shownotif.v
      inicfg.save(ini, 'admins')
    end
    if imgui.Checkbox('Стартовое сообщение', startmsg) then
      ini.settings.startmsg = startmsg.v
      inicfg.save(ini, 'admins')
    end
    if imgui.Button('Перезагрузить админов') then
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

function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowRounding = 0.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ChildWindowRounding = 0.0
    style.FrameRounding = 0.0
    style.ItemSpacing = imgui.ImVec2(5.0, 5.0)
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 0.0

    colors[clr.FrameBg]                = ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[clr.FrameBgActive]          = ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[clr.TitleBg]                = ImVec4(0.15, 0.68, 0.38, 1.00) -- Название окна
    colors[clr.TitleBgActive]          = ImVec4(0.15, 0.68, 0.38, 1.00) -- Название окна
    colors[clr.TitleBgCollapsed]       = ImVec4(0.15, 0.68, 0.38, 1.00) -- Название окна
    colors[clr.CheckMark]              = ImVec4(0.15, 0.68, 0.38, 1.00)
    -- colors[clr.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
    -- colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.Button]                 = ImVec4(0.15, 0.68, 0.38, 0.40) -- Кнопка
    colors[clr.ButtonHovered]          = ImVec4(0.15, 0.68, 0.38, 1.00) -- Кнопка
    colors[clr.ButtonActive]           = ImVec4(0.15, 0.68, 0.38, 1.00) -- Кнопка
		colors[clr.Header]                 = ImVec4(0.15, 0.68, 0.38, 0.31)
    colors[clr.HeaderHovered]          = ImVec4(0.15, 0.68, 0.38, 0.80)
		colors[clr.HeaderActive]           = ImVec4(0.15, 0.68, 0.38, 1.00)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.15, 0.68, 0.38, 1.00)
    colors[clr.ResizeGripHovered]      = ImVec4(0.15, 0.68, 0.38, 1.00)
    colors[clr.ResizeGripActive]       = ImVec4(0.15, 0.68, 0.38, 0.95)
    colors[clr.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.13, 0.13, 0.13, 1.00)
    colors[clr.ChildWindowBg]          = ImVec4(0.13, 0.13, 0.13, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.13, 0.13, 0.13, 1.00)
    colors[clr.ComboBg]                = colors[clr.PopupBg]
    colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.CloseButton]            = ImVec4(0.15, 0.68, 0.38, 1.00)
    colors[clr.CloseButtonHovered]     = ImVec4(0.15, 0.68, 0.38, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.15, 0.68, 0.38, 1.00)
end

function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(0) end

  checkupdates('https://raw.githubusercontent.com/Akionka/checker/master/version.json')
  rebuildadmins()
	apply_custom_style()

  if ini.settings.startmsg then
    sampAddChatMessage(u8:decode('[Checker]: Скрипт {00FF00}успешно{FFFFFF} загружен. Версия: {9932cc}'..thisScript().version..'{FFFFFF}.'), -1)
    sampAddChatMessage(u8:decode('[Checker]: Автор - {9932cc}Akionka{FFFFFF}. Выключить данное сообщение можно в {9932cc}/checker{FFFFFF}.'), -1)
    sampAddChatMessage(u8:decode('[Checker]: Кстати, чтобы посмотреть список администраторов он-лайн введи {9932cc}/admins{FFFFFF}.'), -1)
  end

  sampRegisterChatCommand('admins', function()
    if #admins_online == 0 then sampAddChatMessage(u8:decode('[Checker]: Администраторов он-лайн нет.'), -1) return true end
    sampAddChatMessage(u8:decode('[Checker]: В данный момент на сервере находится {9932cc}'..#admins_online..'{FFFFFF} администратор (-а, -ов):'), -1)
    for i, v in ipairs(admins_online) do
      sampAddChatMessage(u8:decode('[Checker]: {9932cc}'..v['nick']..' ['..v['id']..']{FFFFFF}.'), -1)
    end
    sampAddChatMessage(u8:decode('[Checker]: В данный момент на сервере находится {9932cc}'..#admins_online..'{FFFFFF} администратор (-а, -ов).'), -1)
  end)

  sampRegisterChatCommand('checker', function()
    imgui.SetNextWindowPos(imgui.ImVec2(200, 500), imgui.Cond.Always)
    main_window_state.v = not main_window_state.v
  end)

  font = renderCreateFont(ini.settings.font, 9, 5)
  while true do
    if sampGetChatString(99) == 'The server is restarting..' then admins_online = {} end
    wait(0)
    if doRemove then
      showCursor(true, true)
      renderposX, renderposY = getCursorPos()
      renderFontDrawText(font, 'Admins Online ['..#admins_online..']:', renderposX, renderposY, bit.bor(ini.settings.color, 0xFF000000))
      renderposY = renderposY + 30
      for _, v in ipairs(admins_online) do
        renderFontDrawText(font, v['nick']..' ['..v['id']..']', renderposX, renderposY, bit.bor(ini.settings.color, 0xFF000000))
        renderposY = renderposY + 15
      end
      if isKeyJustPressed(0x02) then
        main_window_state.v = true
        showCursor(false, false)
        doRemove = false
        alert('Отменено.')
      end
      if isKeyJustPressed(0x01) then
        posX.v, posY.v = getCursorPos()
        main_window_state.v = true
        showCursor(false, false)
        doRemove = false
        alert('Новые координаты установлены.')
        ini.settings.posX = posX.v
        ini.settings.posY = posY.v
        inicfg.save(ini, 'admins')
      end
    end
    if not doRemove and ini.settings.showonscreen and (not isKeyDown(0x77) or not ini.settings.hideonscreen)  then
      local renderPosY = ini.settings.posY
      renderFontDrawText(font, 'Admins Online ['..#admins_online..']:', ini.settings.posX, ini.settings.posY, bit.bor(ini.settings.color, 0xFF000000))
      renderPosY = renderPosY + 30
      for _, v in ipairs(admins_online) do
        renderFontDrawText(font, v['nick']..' ['..v['id']..']', ini.settings.posX, renderPosY, bit.bor(ini.settings.color, 0xFF000000))
        renderPosY = renderPosY + 15
      end
    end
    imgui.Process = main_window_state.v
  end
end

function loadadmins()
  admins = {}
  if doesFileExist('moonloader/config/adminlist.txt') then
    for admin in io.lines('moonloader/config/adminlist.txt') do
      table.insert(admins, admin:match('(%S+)'))
    end
    print(u8:decode('Загрузка закончена. Загружено: '..#admins..' админов.'))
    io.open('moonloader/config/adminlist.txt', 'w'):write(table.concat(admins, '\n')):close()
  else
    print(u8:decode('Файла с админами в директории <moonloader/config/adminlist.txt> не обнаружено, создан автоматически'))
    io.close(io.open('moonloader/config/adminlist.txt', 'w'))
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
  if sorttype.v ~= 0 then
    table.sort(admins_online, function(a, b)
      if sorttype.v == 1 then return a['id'] < b['id'] end
      if sorttype.v == 2 then return a['id'] > b['id'] end
      if sorttype.v == 3 then return a['nick'] < b['nick'] end
      if sorttype.v == 4 then return a['nick'] > b['nick'] end
    end)
  end
  sampAddChatMessage(u8:decode('[Checker]: Список админов онлайн перезагружен.'), -1)
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
            sampAddChatMessage(u8:decode('[Checker]: Найдено объявление. Текущая версия: {9932cc}'..thisScript().version..'{FFFFFF}, новая версия: {9932cc}'..info.version..'{FFFFFF}.'), -1)
            return true
          else
            updatesavaliable = false
            sampAddChatMessage(u8:decode('[Checker]: У вас установлена самая свежая версия скрипта.'), -1)
          end
        else
          updatesavaliable = false
          sampAddChatMessage(u8:decode('[Checker]: Что-то пошло не так, упс. Попробуйте позже.'), -1)
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
