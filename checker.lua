script_name('Admin Checker')
script_author('akionka')
script_version('1.10.0')
script_version_number(17)


--[[
   _____   _         ____     _____   ______     _____   _______         _____    _        ______               _____   ______
  / ____| | |       / __ \   / ____| |  ____|   |_   _| |__   __|       |  __ \  | |      |  ____|     /\      / ____| |  ____|
 | |      | |      | |  | | | (___   | |__        | |      | |          | |__) | | |      | |__       /  \    | (___   | |__
 | |      | |      | |  | |  \___ \  |  __|       | |      | |          |  ___/  | |      |  __|     / /\ \    \___ \  |  __|
 | |____  | |____  | |__| |  ____) | | |____     _| |_     | |     _    | |      | |____  | |____   / ____ \   ____) | | |____
  \_____| |______|  \____/  |_____/  |______|   |_____|    |_|    ( )   |_|      |______| |______| /_/    \_\ |_____/  |______|
                                                                  |/
]]


local sampev           = require 'lib.samp.events'
local encoding         = require 'encoding'
local imgui            = require 'imgui'
local dlstatus         = require 'moonloader'.download_status
local updatesavaliable = false

encoding.default       = 'cp1251'
local u8               = encoding.UTF8
local prefix           = 'Checker'
local doRemove         = false
local admins           = {}
local admins_online    = {}
local data             = {
  settings = {
    shownotif    = true,
    showonscreen = true,
    posX         = 40,
    posY         = 460,
    startmsg     = true,
    sorttype     = 0,
    hideonscreen = true,
    headerText   = 'Admins Online'
  },
  colors = {
    header = {
      r = 255,
      g = 255,
      b = 255,
    },
    list = {
      r = 255,
      g = 255,
      b = 255,
    },
  },
  fonts = {
    header = {
      name = 'Arial',
      size = 9,
    },
    list = {
      name = 'Arial',
      size = 9,
    },
  },
  list = {
    {
      isbuiltin = true,
      title = 'Common',
      admins = {},
    },
  },
}

local temp_buffers = {}

function sampev.onPlayerQuit(id, _)
  for i, v in ipairs(admins_online) do
    if v['id'] == id then
      if shownotif.v then
        alert('Администратор {9932cc}'..v['nick']..'{FFFFFF} покинул сервер.')
      end
      table.remove(admins_online, i)
      break
    end
  end
end

function sampev.onPlayerJoin(id, _, _, nick)
  for i, v in ipairs(admins) do
    if nick == v then
      if shownotif.v then
        alert('Администратор {9932cc}'..nick..'{FFFFFF} зашел на сервер.')
      end
      table.insert(admins_online, {nick = nick, id = id})
      if ini.settings.sorttype == 0 then break end
      sortAdmins()
      break
    end
  end
end

local main_window_state = imgui.ImBool(true)
local showonscreen      = imgui.ImBool(false)          -- Заглушка до загрузки данных из loadData()
local hideonscreen      = imgui.ImBool(false)          -- Заглушка до загрузки данных из loadData()
local startmsg          = imgui.ImBool(false)          -- Заглушка до загрузки данных из loadData()
local shownotif         = imgui.ImBool(false)          -- Заглушка до загрузки данных из loadData()
local sorttype          = imgui.ImInt(0)               -- Заглушка до загрузки данных из loadData()
local posX              = imgui.ImInt(0)               -- Заглушка до загрузки данных из loadData()
local posY              = imgui.ImInt(0)               -- Заглушка до загрузки данных из loadData()
local fontBufferHeader  = imgui.ImBuffer('Arial', 256) -- Заглушка до загрузки данных из loadData()
local fontSizeHeader    = imgui.ImInt(0)               -- Заглушка до загрузки данных из loadData()
local fontHeader        = renderCreateFont(fontBufferHeader.v, fontSizeHeader.v, 5)
local fontBufferList    = imgui.ImBuffer('Arial', 256) -- Заглушка до загрузки данных из loadData()
local fontSizeList      = imgui.ImInt(0)               -- Заглушка до загрузки данных из loadData()
local fontList          = renderCreateFont(fontBufferList.v, fontSizeList.v, 5)
local headerText        = imgui.ImBuffer('', 1)       -- Заглушка до загрузки данных из loadData()
local selected          = 1
local adminsText        = imgui.ImBuffer('', 0xFFFF)

function alert(text)
  sampAddChatMessage(u8:decode('['..prefix..']: '..text), -1)
end

local r1, g1, b1 = imgui.ImColor(0, 0, 0):GetFloat4()       -- Заглушка до загрузки данных из loadData()
local color1     = imgui.ImFloat3(r1, g1, b1)               -- Заглушка до загрузки данных из loadData()
local r2, g2, b2 = imgui.ImColor(0, 0, 0):GetFloat4()       -- Заглушка до загрузки данных из loadData()
local color2     = imgui.ImFloat3(r2, g2, b2)               -- Заглушка до загрузки данных из loadData()
function imgui.OnDrawFrame()
  if main_window_state.v then
    imgui.Begin(thisScript().name..' v'..thisScript().version, main_window_state, imgui.WindowFlags.AlwaysAutoResize)
    if imgui.InputInt('X', posX) then saveData() end
    if imgui.InputInt('Y', posY) then saveData() end
    if imgui.Button('Указать мышкой где должен быть список') then
      alert('Нажмите {9932cc}ЛКМ{FFFFFF}, чтобы завершить. Нажмите {9932cc}ПКМ{FFFFFF}, чтобы отменить.')
      main_window_state.v = false
      doRemove = true
    end
    if imgui.InputText('Текст шапки', headerText) then saveData() end
    if imgui.InputText('Шрифт шапки', fontBufferHeader) then generateFont() saveData() end
    if imgui.InputInt('Размер шрифта шапки', fontSizeHeader, 1, 4) then generateFont() saveData() end
    if imgui.ColorEdit3('Цвет шапки', color1) then saveData() end
    if imgui.InputText('Шрифт списка', fontBufferList) then generateFont() saveData() end
    if imgui.InputInt('Размер шрифта списка', fontSizeList, 1, 4) then generateFont() saveData() end
    if imgui.ColorEdit3('Цвет списка', color2) then saveData() end
    if imgui.CollapsingHeader('Способ сортировки') then
      if imgui.ListBox('', sorttype, {'Никак', 'По увеличению ID', 'По уменьшению ID', 'По алфавиту', 'По алфавиту наоборот'}, imgui.ImInt(5)) then
        sortAdmins()
        saveData()
      end
      imgui.Separator()
    end
    if imgui.Checkbox('Рендер на экране', showonscreen) then
      saveData()
    end
    if imgui.Checkbox('Прятать на скриншотах', hideonscreen) then saveData()
    end
    if imgui.Checkbox('Оповещения о входе/выходе администраторов', shownotif) then saveData()
    end
    if imgui.Checkbox('Стартовое сообщение', startmsg) then saveData()
    end
    if imgui.Button('Открыть редактор списка администраторов') then
        imgui.OpenPopup('Редактор списка администраторов')
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
    local resX, resY = getScreenResolution()
    imgui.SetNextWindowSize(imgui.ImVec2(434.4, 324), imgui.Cond.Once)
    imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.Once, imgui.ImVec2(.5, .5))
    if imgui.BeginPopupModal('Редактор списка администраторов', nil, imgui.WindowFlags.NoResize) then
      imgui.BeginGroup()
        imgui.BeginChild('Servers list', imgui.ImVec2(134.4, -(imgui.GetItemsLineHeightWithSpacing()*2 - imgui.GetStyle().ItemSpacing.y)), true)
          for i, v in ipairs(data['list']) do
            if imgui.Selectable(v['title']..'##server'..i, selected == i) then selected = i end
          end
        imgui.EndChild()
        if imgui.Button('Добавить', imgui.ImVec2(67.2, 0)) then
          local name = sampGetCurrentServerName()
          local ip, port = sampGetCurrentServerAddress()
          temp_buffers['servername'] = imgui.ImBuffer(name, 64)
          temp_buffers['serverip']   = imgui.ImBuffer(ip, 16)
          temp_buffers['serverport'] = imgui.ImInt(port)
          imgui.OpenPopup('Добавить')
        end
        imgui.SameLine()
        if imgui.Button('Удалить', imgui.ImVec2(67.2, 0)) and not data['list'][selected]['isbuiltin'] then imgui.OpenPopup('Удалить') end
        if imgui.Button('Закрыть', imgui.ImVec2(134.4 + imgui.GetStyle().ItemSpacing.x, 0)) then imgui.CloseCurrentPopup() end
        imgui.SetNextWindowSize(imgui.ImVec2(298, 136), imgui.Cond.Once)
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.Once, imgui.ImVec2(.5, .5))
        if imgui.BeginPopupModal('Добавить', nil, imgui.WindowFlags.NoResize) then
          imgui.InputText('Название', temp_buffers['servername'])
          imgui.InputText('IP', temp_buffers['serverip'] )
          imgui.InputInt('Port', temp_buffers['serverport'])
          imgui.Separator()
          imgui.SetCursorPosX((imgui.GetWindowWidth() - 240 + imgui.GetStyle().ItemSpacing.x) / 2)
          if imgui.Button('OK', imgui.ImVec2(120, 0)) then
            table.insert(data['list'], {
              isbuiltin = false,
              title = temp_buffers['servername'].v,
              ip = temp_buffers['serverip'].v,
              port = temp_buffers['serverport'].v,
              admins = {}
            })
            saveData()
            imgui.CloseCurrentPopup()
          end
          imgui.SameLine()
          if imgui.Button('Отмена', imgui.ImVec2(120, 0)) then imgui.CloseCurrentPopup() end
          imgui.EndPopup()
        end
        if imgui.BeginPopupModal('Удалить', nil, imgui.WindowFlags.NoResize) then
          imgui.Text('Вы действительно хотите удалить этот список?\nУдаление приведет к полной безвозвратной потере списка администраторов для данного сервера.')
          imgui.Separator()
          imgui.SetCursorPosX((imgui.GetWindowWidth() - 240 + imgui.GetStyle().ItemSpacing.x) / 2)
          if imgui.Button('OK', imgui.ImVec2(120, 0)) then
            table.remove(data['list'], selected)
            selected = 1
            saveData()
            imgui.CloseCurrentPopup()
          end
          imgui.SameLine()
          if imgui.Button('Отмена', imgui.ImVec2(120, 0)) then imgui.CloseCurrentPopup() end
          imgui.EndPopup()
        end
      imgui.EndGroup()
      imgui.SameLine()
      imgui.BeginGroup()
        imgui.BeginChild('Admins list', imgui.ImVec2(150, 0), false)
          print(imgui.GetWindowContentRegionWidth())
          adminsText.v = table.concat(data['list'][selected]['admins'], "\n")
          if imgui.InputTextMultiline('##list', adminsText, imgui.ImVec2(150, -imgui.GetStyle().ItemSpacing.x)) then
            parseText(adminsText.v)
            saveData()
            sLoadAdmins()
          end
        imgui.EndChild()
      imgui.EndGroup()
      imgui.SameLine()
      imgui.BeginGroup()
        imgui.BeginChild('Admins list##show', imgui.ImVec2(150, 0), false)
          imgui.Text(table.concat(data['list'][selected]['admins'], "\n"))
          print(table.concat(data['list'][selected]['admins'], "\n"))
        imgui.EndChild()
      imgui.EndGroup()
      imgui.EndPopup()
    end

    imgui.End()
  end
end

function apply_custom_style()imgui.SwitchContext()local a=imgui.GetStyle()local b=a.Colors;local c=imgui.Col;local d=imgui.ImVec4;a.WindowRounding=0.0;a.WindowTitleAlign=imgui.ImVec2(0.5,0.5)a.ChildWindowRounding=0.0;a.FrameRounding=0.0;a.ItemSpacing=imgui.ImVec2(5.0,5.0)a.ScrollbarSize=13.0;a.ScrollbarRounding=0;a.GrabMinSize=8.0;a.GrabRounding=0.0;b[c.TitleBg]=d(0.60,0.20,0.80,1.00)b[c.TitleBgActive]=d(0.60,0.20,0.80,1.00)b[c.TitleBgCollapsed]=d(0.60,0.20,0.80,1.00)b[c.CheckMark]=d(0.60,0.20,0.80,1.00)b[c.Button]=d(0.60,0.20,0.80,0.31)b[c.ButtonHovered]=d(0.60,0.20,0.80,0.80)b[c.ButtonActive]=d(0.60,0.20,0.80,1.00)b[c.WindowBg]=d(0.13,0.13,0.13,1.00)b[c.Header]=d(0.60,0.20,0.80,0.31)b[c.HeaderHovered]=d(0.60,0.20,0.80,0.80)b[c.HeaderActive]=d(0.60,0.20,0.80,1.00)b[c.FrameBg]=d(0.60,0.20,0.80,0.31)b[c.FrameBgHovered]=d(0.60,0.20,0.80,0.80)b[c.FrameBgActive]=d(0.60,0.20,0.80,1.00)b[c.ScrollbarBg]=d(0.60,0.20,0.80,0.31)b[c.ScrollbarGrab]=d(0.60,0.20,0.80,0.31)b[c.ScrollbarGrabHovered]=d(0.60,0.20,0.80,0.80)b[c.ScrollbarGrabActive]=d(0.60,0.20,0.80,1.00)b[c.Text]=d(1.00,1.00,1.00,1.00)b[c.Border]=d(0.60,0.20,0.80,0.00)b[c.BorderShadow]=d(0.00,0.00,0.00,0.00)b[c.CloseButton]=d(0.60,0.20,0.80,0.31)b[c.CloseButtonHovered]=d(0.60,0.20,0.80,0.80)b[c.CloseButtonActive]=d(0.60,0.20,0.80,1.00)end


function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(0) end

  if not doesDirectoryExist(getWorkingDirectory()..'\\config') then createDirectory(getWorkingDirectory()..'\\config') end
  checkupdates('https://raw.githubusercontent.com/Akionka/checker/master/version.json')
  loadData()
  apply_custom_style()

  if data['startmsg'] then
    alert('Скрипт {00FF00}успешно{FFFFFF} загружен. Версия: {9932cc}'..thisScript().version..'{FFFFFF}.')
    alert('Автор - {9932cc}Akionka{FFFFFF}. Выключить данное сообщение можно в {9932cc}/checker{FFFFFF}.')
    alert('Кстати, чтобы посмотреть список администраторов он-лайн введи {9932cc}/admins{FFFFFF}.')
  end

  sampRegisterChatCommand('admins', function()
    if #admins_online == 0 then alert('Администраторов он-лайн нет.') return true end
    alert('В данный момент на сервере находится {9932cc}'..#admins_online..'{FFFFFF} администратор (-а, -ов):')
    for i, v in ipairs(admins_online) do
      alert('{9932cc}'..v['nick']..' ['..v['id']..']{FFFFFF}.')
    end
    alert('В данный момент на сервере находится {9932cc}'..#admins_online..'{FFFFFF} администратор (-а, -ов).')
  end)

  sampRegisterChatCommand('checker', function()
    imgui.SetNextWindowPos(imgui.ImVec2(200, 500), imgui.Cond.Always)
    main_window_state.v = not main_window_state.v
  end)

  while true do
    if sampGetChatString(99) == 'The server is restarting..' then loadData() end
    wait(0)
    if doRemove then
      showCursor(true, true)
      renderposX, renderposY = getCursorPos()
      renderFontDrawText(fontHeader, u8:decode(headerText.v)..' ['..#admins_online..']:', renderposX, renderposY, bit.bor(join_argb(255, color1.v[1] * 255, color1.v[2] * 255, color1.v[3] * 255), 0xFF000000))
      renderposY = renderposY + 30
      for _, v in ipairs(admins_online) do
        renderFontDrawText(fontList, v['nick']..' ['..v['id']..']', renderposX, renderposY, bit.bor(join_argb(255, color2.v[1] * 255, color2.v[2] * 255, color2.v[3] * 255), 0xFF000000))
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
        saveData()
      end
    end
    if not doRemove and showonscreen.v and (not isKeyDown(0x77) or not hideonscreen.v) and not sampIsChatInputActive() then
      local renderPosY = posY.v
      renderFontDrawText(fontHeader, u8:decode(headerText.v)..' ['..#admins_online..']:', posX.v, posY.v, bit.bor(join_argb(255, color1.v[1] * 255, color1.v[2] * 255, color1.v[3] * 255), 0xFF000000))
      renderPosY = renderPosY + 30
      for _, v in ipairs(admins_online) do
        renderFontDrawText(fontList, v['nick']..' ['..v['id']..']', posX.v, renderPosY, bit.bor(join_argb(255, color2.v[1] * 255, color2.v[2] * 255, color2.v[3] * 255), 0xFF000000))
        renderPosY = renderPosY + 15
      end
    end
    imgui.Process = main_window_state.v
  end
end

function sLoadAdmins()
  admins_online = {}
  local ip, port = sampGetCurrentServerAddress()
  for i1, v1 in ipairs(data['list']) do
    if v1['isbuiltin'] or (v1['ip'] == ip and v1['port'] == port) then
      for i2, v2 in ipairs(v1['admins']) do
        for id = 0, sampGetMaxPlayerId(false) do
          if sampIsPlayerConnected(id) then
            if sampGetPlayerNickname(id) == v2 then
              table.insert(admins_online, {nick = v2, id = id})
            end
          end
        end
      end
    end
  end
end

function loadAdmins()
  sLoadAdmins()
  sortAdmins()
  alert('Список админов онлайн перезагружен.')
end

function checkupdates(json)
  local fpath = os.tmpname()
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
            alert('Найдено объявление. Текущая версия: {9932cc}'..thisScript().version..'{FFFFFF}, новая версия: {9932cc}'..info.version..'{FFFFFF}.')
            return true
          else
            updatesavaliable = false
            alert('У вас установлена самая свежая версия скрипта.')
          end
        else
          updatesavaliable = false
          alert('Что-то пошло не так, упс. Попробуйте позже.')
        end
      end
    end
  end)
end

function update(url)
  downloadUrlToFile(url, thisScript().path, function(_, status1, _, _)
    if status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
      alert('Новая версия установлена! Чтобы скрипт обновился нужно либо перезайти в игру, либо ...')
      alert('... если у вас есть автоперезагрузка скриптов, то новая версия уже готова и снизу вы увидите приветственное сообщение.')
      alert('Если что-то пошло не так, то сообщите мне об этом в VK или Telegram > {2980b0}vk.com/akionka teleg.run/akionka{FFFFFF}.')
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

function loadData()
  admins_online = {}
  admins        = {}
  local path = getWorkingDirectory()..'\\config\\adminchecker.json'
  if doesFileExist(path) then
    local file = io.open(path)
    data = decodeJson(file:read('*a'))
    file:close()
    loadAdmins()
  else
    local file = io.open(path, 'w+')
    file:write(encodeJson(data))
    file:close()
  end
  showonscreen     = imgui.ImBool(data['settings']['showonscreen'])
  hideonscreen     = imgui.ImBool(data['settings']['hideonscreen'])
  startmsg         = imgui.ImBool(data['settings']['startmsg'])
  shownotif        = imgui.ImBool(data['settings']['shownotif'])
  sorttype         = imgui.ImInt(data['settings']['sorttype'])
  posX             = imgui.ImInt(data['settings']['posX'])
  posY             = imgui.ImInt(data['settings']['posY'])
  fontBufferHeader = imgui.ImBuffer(data['fonts']['header']['name'], 256)
  fontSizeHeader   = imgui.ImInt(data['fonts']['header']['size'])
  fontBufferList   = imgui.ImBuffer(data['fonts']['list']['name'], 256)
  fontSizeList     = imgui.ImInt(data['fonts']['list']['size'])
  r1, g1, b1       = imgui.ImColor(data['colors']['header']['r'], data['colors']['header']['g'], data['colors']['header']['b']): GetFloat4()
  color1           = imgui.ImFloat3(r1, g1, b1)
  r2, g2, b2       = imgui.ImColor(data['colors']['list']['r'], data['colors']['list']['g'], data['colors']['list']['b'])      : GetFloat4()
  color2           = imgui.ImFloat3(r2, g2, b2)
  headerText       = imgui.ImBuffer(data['settings']['headerText'], 64)
  generateFont()
end

function saveData()
  local path = getWorkingDirectory()..'\\config\\adminchecker.json'
  local file = io.open(path, 'w+')
  file:write(encodeJson({
    settings = {
      shownotif    = shownotif.v,
      showonscreen = showonscreen.v,
      posX         = posX.v,
      posY         = posY.v,
      startmsg     = startmsg.v,
      sorttype     = sorttype.v,
      hideonscreen = hideonscreen.v,
      headerText   = headerText.v
    },
    colors = {
      header = {r = color1.v[1] * 255, g = color1.v[2] * 255, b = color1.v[3] * 255},
      list   = {r = color2.v[1] * 255, g = color2.v[2] * 255, b = color2.v[3] * 255},
    },
    fonts = {
      header = {name = fontBufferHeader.v, size = fontSizeHeader.v},
      list   = {name = fontBufferList.v, size = fontSizeList.v},
    },
    list = data['list'],
  }))
  file:close()
end

function sortAdmins()
  if sorttype.v ~= 0 then
    table.sort(admins_online, function(a, b)
      if sorttype.v == 1 then return a['id'] < b['id'] end
      if sorttype.v == 2 then return a['id'] > b['id'] end
      if sorttype.v == 3 then return a['nick'] < b['nick'] end
      if sorttype.v == 4 then return a['nick'] > b['nick'] end
    end)
  end
end

function parseText(text)
  data['list'][selected]['admins'] = {}
  for admin in text:gmatch('(%S+)') do table.insert(data['list'][selected]['admins'], admin) end
end

function generateFont()
  fontHeader = renderCreateFont(fontBufferHeader.v, fontSizeHeader.v, 5)
  fontList   = renderCreateFont(fontBufferList.v, fontSizeList.v, 5)
end