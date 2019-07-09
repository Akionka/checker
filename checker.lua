script_name('Checker')
script_author('akionka')
script_version('1.10.2')
script_version_number(20)

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
local updatesAvaliable = false
encoding.default       = 'cp1251'
local u8               = encoding.UTF8
local prefix           = 'Checker'
local loadedUsers    = {}
local onlineUsers    = {}
local data             = {
  settings  = {
    alwaysAutoCheckUpdates          = true,
    notificationsAboutJoinsAndQuits = true,
    renderOnScreen                  = true,
    hideOnScreenshot                = false,
    hideOnOpenChat                  = false,
    headerFontName                  = 'Arial',
    headerFontSize                  = 9,
    headerFontColor                 = 0xFFFFFFFF,
    headerText                      = 'Users online',
    headerPosX                      = 450,
    headerPosY                      = 450,
  },
  lists     = {
    {
      isbuiltin = true,
      title = 'Common',
      ip    = '127.0.0.1',
      port  = 7777,
      color = {
        r = 255,
        g = 255,
        b = 255,
      },
      users = {'West_Side', 'Drop_Table'}
    },
  },
}
tempBuffers = {}

function applyCustomStyle()imgui.SwitchContext()local a=imgui.GetStyle()local b=a.Colors;local c=imgui.Col;local d=imgui.ImVec4;a.WindowRounding=0.0;a.WindowTitleAlign=imgui.ImVec2(0.5,0.5)a.ChildWindowRounding=0.0;a.FrameRounding=0.0;a.ItemSpacing=imgui.ImVec2(5.0,5.0)a.ScrollbarSize=13.0;a.ScrollbarRounding=0;a.GrabMinSize=8.0;a.GrabRounding=0.0;b[c.TitleBg]=d(0.60,0.20,0.80,1.00)b[c.TitleBgActive]=d(0.60,0.20,0.80,1.00)b[c.TitleBgCollapsed]=d(0.60,0.20,0.80,1.00)b[c.CheckMark]=d(0.60,0.20,0.80,1.00)b[c.Button]=d(0.60,0.20,0.80,0.31)b[c.ButtonHovered]=d(0.60,0.20,0.80,0.80)b[c.ButtonActive]=d(0.60,0.20,0.80,1.00)b[c.WindowBg]=d(0.13,0.13,0.13,1.00)b[c.Header]=d(0.60,0.20,0.80,0.31)b[c.HeaderHovered]=d(0.60,0.20,0.80,0.80)b[c.HeaderActive]=d(0.60,0.20,0.80,1.00)b[c.FrameBg]=d(0.60,0.20,0.80,0.31)b[c.FrameBgHovered]=d(0.60,0.20,0.80,0.80)b[c.FrameBgActive]=d(0.60,0.20,0.80,1.00)b[c.ScrollbarBg]=d(0.60,0.20,0.80,0.31)b[c.ScrollbarGrab]=d(0.60,0.20,0.80,0.31)b[c.ScrollbarGrabHovered]=d(0.60,0.20,0.80,0.80)b[c.ScrollbarGrabActive]=d(0.60,0.20,0.80,1.00)b[c.Text]=d(1.00,1.00,1.00,1.00)b[c.Border]=d(0.60,0.20,0.80,0.00)b[c.BorderShadow]=d(0.00,0.00,0.00,0.00)b[c.CloseButton]=d(0.60,0.20,0.80,0.31)b[c.CloseButtonHovered]=d(0.60,0.20,0.80,0.80)b[c.CloseButtonActive]=d(0.60,0.20,0.80,1.00)end


function sampev.onSendClientJoin(version, mod, nickname, challengeResponse, joinAuthKey, clientVer, unknown)
  --[[
    Обнуление онлайн пользователей, загруженных пользователей после (ре)коннекта.
    Также, загрузка новых пользователей, если, допустим, пользователь скрипта
    переподключился к новому серверу.
  ]]

  -- loadUsers()
end


function sampev.onPlayerJoin(id, color, isNPC, nickname)
  --[[
    Добавление нового пользователя в список онлайн, когда тот подключается.
    Также вызывается много-много раз когда сам пользователь подключается к серверу.
  ]]

  for i, v in ipairs(loadedUsers) do
    if v == nickname then
      table.insert(onlineUsers, {nickname = nickname, id = id})
      break
    end
  end
end


function sampev.onPlayerQuit(id, reason)
  --[[
    Исключение из списка онлайн пользователей покинувшего сервер пользователя.
  ]]

  for i, v in ipairs(onlineUsers) do
    if v['id'] == id then
      table.remove(onlineUsers, i)
      break
    end
  end
end


local mainWindowState       = imgui.ImBool(true)
local headerFontNameBuffer  = imgui.ImBuffer('Arial', 256)
local headerFontSizeBuffer  = imgui.ImInt(9)
local headerFontColorBuffer = imgui.ImFloat3(0, 0, 0)
local headerTextBuffer      = imgui.ImBuffer('Users online', 32)
local headerPosXBuffer      = imgui.ImInt(450)
local headerPosYBuffer      = imgui.ImInt(450)
local headerFont            = renderCreateFont('Arial', 9, 5)


local selectedTab           = 1
local movingInProgress      = false

function imgui.OnDrawFrame()
  if mainWindowState.v then
    local resX, resY = getScreenResolution()
    imgui.SetNextWindowSize(imgui.ImVec2(576, 350), 2)
    imgui.SetNextWindowPos(imgui.ImVec2(resX/2, resY/2), 2, imgui.ImVec2(0.5, 0.5))
    imgui.Begin('Checker v'..thisScript()['version'], mainWindowState, imgui.WindowFlags.NoResize)
      imgui.BeginGroup()
        imgui.BeginChild('Left panel', imgui.ImVec2(100, 0), true)
          if imgui.Selectable('Списки', selectedTab == 1) then selectedTab = 1 end
          if imgui.Selectable('Настройки', selectedTab == 2) then selectedTab = 2 end
          if imgui.Selectable('Информация', selectedTab == 3) then selectedTab = 3 end
        imgui.EndChild()
      imgui.EndGroup()

      imgui.SameLine()

      imgui.BeginGroup()
        imgui.BeginChild('Center panel')
          if selectedTab == 1 then
            --
          end
          if selectedTab == 2 then
            if imgui.Checkbox('Всегда автоматически проверять обновления', imgui.ImBool(data['settings']['alwaysAutoCheckUpdates'])) then
              data['settings']['alwaysAutoCheckUpdates'] = not data['settings']['alwaysAutoCheckUpdates']
              saveData()
            end
            if imgui.Checkbox('Сообщения о входе/выходе отслеживаемых пользователей', imgui.ImBool(data['settings']['notificationsAboutJoinsAndQuits'])) then
              data['settings']['notificationsAboutJoinsAndQuits'] = not data['settings']['notificationsAboutJoinsAndQuits']
              saveData()
            end
            if imgui.Checkbox('Рендер на экране', imgui.ImBool(data['settings']['renderOnScreen'])) then
              data['settings']['renderOnScreen'] = not data['settings']['renderOnScreen']
              saveData()
            end
            if imgui.Checkbox('Прятать на скриншотах', imgui.ImBool(data['settings']['hideOnScreenshot'])) then
              data['settings']['hideOnScreenshot'] = not data['settings']['hideOnScreenshot']
              saveData()
            end
            if imgui.Checkbox('Прятать при открытии чата', imgui.ImBool(data['settings']['hideOnOpenChat']))then
              data['settings']['hideOnOpenChat'] = not data['settings']['hideOnOpenChat']
              saveData()
            end
            imgui.PushItemWidth(100)
            if imgui.InputText('Текст шапки', headerTextBuffer) then
              data['settings']['headerText'] = headerTextBuffer.v
              saveData()
              rebuildFonts()
            end
            if imgui.InputText('Название шрифта шапки', headerFontNameBuffer) then
              data['settings']['headerFontName'] = headerFontNameBuffer.v
              saveData()
              rebuildFonts()
            end
            if imgui.InputInt('Размер шрифта шапки', headerFontSizeBuffer, 1, 3) then
              data['settings']['headerFontSize'] = headerFontSizeBuffer.v
              saveData()
              rebuildFonts()
            end
            if imgui.ColorEdit3('Цвет шрифта шапки', headerFontColorBuffer) then
              data['settings']['headerFontColor'] = join_argb(255, headerFontColorBuffer.v[1]*255, headerFontColorBuffer.v[2]*255, headerFontColorBuffer.v[3]*255)
              saveData()
              rebuildFonts()
            end
            if imgui.DragInt('Позиция списка по оси X', headerPosXBuffer, 1, 0, resX) then
              data['settings']['headerPosX'] = headerPosXBuffer.v
              saveData()
            end
            if imgui.DragInt('Позиция списка по оси Y', headerPosYBuffer, 1, 0, resY) then
              data['settings']['headerPosY'] = headerPosYBuffer.v
              saveData()
            end
            if imgui.Button('Указать позицию списка с помощью курсора') then
              movingInProgress  = true
              mainWindowState.v = false
              alert('Нажмите {9932cc}ЛКМ{FFFFFF}, чтобы завершить. Нажмите {9932cc}ПКМ{FFFFFF}, чтобы отменить.')
            end
            imgui.PopItemWidth()

          end
          if selectedTab == 3 then
            imgui.Text('Название: Checker')
            imgui.Text('Автор: Akionka')
            imgui.Text('Версия: '..thisScript().version_num..' ('..thisScript().version..')')
            imgui.Text('Команды: /checker, /users')
            if updatesavaliable then
              if imgui.Button('Скачать обновление', imgui.ImVec2(150, 0)) then
                update('https://raw.githubusercontent.com/Akionka/checker/master/checker.lua')
                mainWindowState.v = false
              end
            else
              if imgui.Button('Проверить обновления', imgui.ImVec2(150, 0)) then
                checkUpdates('https://raw.githubusercontent.com/Akionka/checker/master/version.json')
              end
            end
            if imgui.Button('Bug report [VK]', imgui.ImVec2(150, 0)) then os.execute('explorer "https://vk.com/akionka"') end
            imgui.SameLine()
            if imgui.Button('Bug report [Telegram]', imgui.ImVec2(150, 0)) then os.execute('explorer "https://teleg.run/akionka"') end
          end
        imgui.EndChild()
      imgui.EndGroup()

      imgui.SameLine()

      imgui.BeginGroup()
        imgui.BeginChild('Right panel')
        imgui.EndChild()
      imgui.EndGroup()
    imgui.End()
  end
end


function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(0) end
  if not doesDirectoryExist(getWorkingDirectory()..'\\config') then createDirectory(getWorkingDirectory()..'\\config') end

  applyCustomStyle()
  loadData()
  rebuildFonts()
  loadUsers()

  print(u8:decode('{FFFFFF}Скрипт успешно загружен.'))
  print(u8:decode('{FFFFFF}Версия: {9932cc}'..thisScript()['version']..'{FFFFFF}. Автор: {9932cc}Akionka{FFFFFF}.'))
  print(u8:decode('{FFFFFF}Приятного использования! :)'))

  if data['settings']['alwaysAutoCheckUpdates'] then checkUpdates('https://raw.githubusercontent.com/Akionka/checker/master/version.json') end

  sampRegisterChatCommand('checker', function()
    mainWindowState.v = not mainWindowState.v
  end)

  sampRegisterChatCommand('users', function()
    if #onlineUsers == 0 then return alert('В данный момент никто не подключен к серверу из тех пользователей, кто есть у вас в списках.') end

    alert('В данный момент на сервере находится {9932cc}'..#onlineUsers..' {FFFFFF}пользователь(-я, -ей) из ваших списков:')

    for i, v in ipairs(onlineUsers) do
      alert(v['nickname']..'['..v['id']..']')
    end

    if #onlineUsers > 10 then alert('В данный момент на сервере находится {9932cc}'..#onlineUsers..' {FFFFFF}пользователь(-я, -ей) из ваших списков.') end
  end)

  while true do
    wait(0)
    if movingInProgress then
      showCursor(true, true)
      renderPosX, renderPosY = getCursorPos()
      renderList(renderPosX, renderPosY)
      if isKeyJustPressed(0x02) then
        mainWindowState.v = true
        showCursor(false, false)
        movingInProgress = false
        alert('Отменено.')
      end
      if isKeyJustPressed(0x01) then
        data['settings']['headerPosX'], data['settings']['headerPosY'] = getCursorPos()
        headerPosXBuffer.v = data['settings']['headerPosX']
        headerPosYBuffer.v = data['settings']['headerPosY']
        mainWindowState.v = true
        showCursor(false, false)
        movingInProgress = false
        alert('Новые координаты установлены.')
        saveData()
      end

    end
    if not movingInProgress and data['settings']['renderOnScreen'] and (not isKeyDown(0x77) or not data['settings']['hideOnScreenshot']) and (not sampIsChatInputActive() or not data['settings']['hideOnOpenChat']) then
      renderList(data['settings']['headerPosX'], data['settings']['headerPosY'])
    end
    imgui.Process = mainWindowState.v
  end
end

function checkUpdates(json)
  local fpath = os.tmpname()
  if doesFileExist(fpath) then os.remove(fpath) end
  downloadUrlToFile(json, fpath, function(_, status, _, _)
    if status == 58 then
      if doesFileExist(fpath) then
        local f = io.open(fpath, 'r')
        if f then
          local info = decodeJson(f: read('*a'))
          f:close()
          os.remove(fpath)
          if info['version_num'] > thisScript()['version_num'] then
            updatesAvaliable = true
            alert('Найдено объявление. Текущая версия: {9932cc}'..thisScript()['version']..'{FFFFFF}, новая версия: {9932cc}'..info['version']..'{FFFFFF}.')
            return true
          else
            updatesAvaliable = false
            alert('У вас установлена самая свежая версия скрипта.')
          end
        else
          updatesAvaliable = false
          alert('Что-то пошло не так, упс. Попробуйте позже.')
        end
      end
    end
  end)
end

function update(url)
  downloadUrlToFile(url, thisScript().path, function(_, status, _, _)
    if status == 6 then
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

function explode_argb(argb)
  local a = bit.band(bit.rshift(argb, 24), 0xFF)
  local r = bit.band(bit.rshift(argb, 16), 0xFF)
  local g = bit.band(bit.rshift(argb, 8), 0xFF)
  local b = bit.band(argb, 0xFF)
  return a, r, g, b
end

function argb_to_rgba(argb)
  local a, r, g, b = explode_argb(argb)
  return join_argb(r, g, b, a)
end

function alert(text)
  sampAddChatMessage(u8:decode('['..prefix..']: '..text), -1)
end

function saveData()
  local configFile = io.open(getWorkingDirectory()..'\\config\\checker.json', 'w+')
  configFile:write(encodeJson(data))
  configFile:close()
end

function loadData()
  if not doesFileExist(getWorkingDirectory()..'\\config\\checker.json') then
    local configFile = io.open(getWorkingDirectory()..'\\config\\checker.json', 'w+')
    configFile:write(encodeJson(data))
    configFile:close()
    return
  end

  local configFile = io.open(getWorkingDirectory()..'\\config\\checker.json', 'r')
  data = decodeJson(configFile:read('*a'))
  configFile:close()

  local a, r, g, b        = explode_argb(data['settings']['headerFontColor'])
  headerFontNameBuffer.v  = data['settings']['headerFontName']
  headerFontSizeBuffer.v  = data['settings']['headerFontSize']
  headerPosXBuffer.v      = data['settings']['headerPosX']
  headerPosYBuffer.v      = data['settings']['headerPosY']
  headerTextBuffer.v      = data['settings']['headerText']
  headerFontColorBuffer   = imgui.ImFloat3(r/255, g/255, b/255)
end

function rebuildFonts()
  fontHeader = renderCreateFont(data['settings']['headerFontName'], data['settings']['headerFontSize'], 5)
end

function loadUsers()
  loadedUsers    = {}
  onlineUsers    = {}
  local ip, port = sampGetCurrentServerAddress()

  for i, v in ipairs(data['lists']) do
    if v['isbuiltin'] or v['ip'] == ip and v['port'] == port then
      for i, v in pairs(v['users']) do
        table.insert(loadedUsers, v)
      end
    end
  end
end

 function renderList(x, y)
  renderFontDrawText(fontHeader, u8:decode(data['settings']['headerText'])..' ['..#onlineUsers..']:', x, y, data['settings']['headerFontColor'])
  for i, v in ipairs(onlineUsers) do
    renderFontDrawText(fontHeader, v['nickname']..' ['..v['id']..']', data['settings']['headerPosY'], renderPosY, bit.bor(join_argb(255, color2.v[1] * 255, color2.v[2] * 255, color2.v[3] * 255), 0xFF000000))
    y = y + data['settings']['headerFontSize']
  end
 end