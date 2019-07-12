script_name('Checker')
script_author('akionka')
script_version('2.0.0')
script_version_number(21)

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
      color = 0xFFFFFFFF,
      users = {'West_Side', 'Drop_Table'}
    },
  },
}
tempBuffers = {}


function applyCustomStyle()
  imgui.SwitchContext()
  local style  = imgui.GetStyle()
  local colors = style.Colors
  local clr    = imgui.Col
  local ImVec4 = imgui.ImVec4

  style.WindowRounding      = 0.0
  style.WindowTitleAlign    = imgui.ImVec2(0.5, 0.5)
  style.ChildWindowRounding = 0.0
  style.FrameRounding       = 0.0
  style.ItemSpacing         = imgui.ImVec2(5.0, 5.0)
  style.ScrollbarSize       = 13.0
  style.ScrollbarRounding   = 0
  style.GrabMinSize         = 8.0
  style.GrabRounding        = 0.0

  colors[clr.FrameBg]             = ImVec4(0.00, 0.00, 0.00, 0.00)
  colors[clr.FrameBgHovered]      = ImVec4(0.00, 0.00, 0.00, 0.00)
  colors[clr.FrameBgActive]       = ImVec4(0.00, 0.00, 0.00, 0.00)
  colors[clr.TitleBg]             = ImVec4(0.60, 0.20, 0.80, 1.00)
  colors[clr.TitleBgActive]       = ImVec4(0.60, 0.20, 0.80, 1.00)
  colors[clr.TitleBgCollapsed]    = ImVec4(0.60, 0.20, 0.80, 1.00)
  colors[clr.CheckMark]           = ImVec4(0.60, 0.20, 0.80, 1.00)
  -- colors[clr.SliderGrab]       = ImVec4(0.60, 0.20, 0.80, 1.00)
  -- colors[clr.SliderGrabActive] = ImVec4(0.60, 0.20, 0.80, 1.00)
  colors[clr.Button]              = ImVec4(0.60, 0.20, 0.80, 1.00)
  colors[clr.ButtonHovered]       = ImVec4(0.60, 0.20, 0.80, 1.00)
  colors[clr.ButtonActive]        = ImVec4(0.60, 0.20, 0.80, 1.00)
  colors[clr.Header]              = ImVec4(0.60, 0.20, 0.80, 1.00)
  colors[clr.HeaderHovered]       = ImVec4(0.60, 0.20, 0.80, 1.00)
  colors[clr.HeaderActive]        = ImVec4(0.60, 0.20, 0.80, 1.00)
  colors[clr.Separator]           = colors[clr.Border]
  colors[clr.SeparatorHovered]    = ImVec4(0.75, 0.10, 0.10, 0.78)
  colors[clr.SeparatorActive]     = ImVec4(0.75, 0.10, 0.10, 1.00)
  colors[clr.ResizeGrip]          = ImVec4(0.15, 0.68, 0.38, 1.00)
  colors[clr.ResizeGripHovered]   = ImVec4(0.15, 0.68, 0.38, 1.00)
  colors[clr.ResizeGripActive]    = ImVec4(0.15, 0.68, 0.38, 0.95)
  colors[clr.TextSelectedBg]      = ImVec4(0.98, 0.26, 0.26, 0.35)
  colors[clr.Text]                = ImVec4(1.00, 1.00, 1.00, 1.00)
  colors[clr.TextDisabled]        = ImVec4(0.50, 0.50, 0.50, 1.00)
  colors[clr.WindowBg]            = ImVec4(0.13, 0.13, 0.13, 1.00)
  colors[clr.ChildWindowBg]       = ImVec4(0.13, 0.13, 0.13, 1.00)
  colors[clr.PopupBg]             = ImVec4(0.13, 0.13, 0.13, 1.00)
  colors[clr.ComboBg]             = colors[clr.PopupBg]
  colors[clr.Border]              = ImVec4(0.43, 0.43, 0.50, 0.00)
  colors[clr.BorderShadow]        = ImVec4(0.00, 0.00, 0.00, 0.00)
  colors[clr.CloseButton]         = ImVec4(0.60, 0.20, 0.80, 0.50)
  colors[clr.CloseButtonHovered]  = ImVec4(0.60, 0.20, 0.80, 0.50)
  colors[clr.CloseButtonActive]   = ImVec4(0.60, 0.20, 0.80, 0.50)
end


function sampev.onSendClientJoin(version, mod, nickname, challengeResponse, joinAuthKey, clientVer, unknown)
  --[[
    Обнуление онлайн пользователей, загруженных пользователей после (ре)коннекта.
  ]]

  loadedUsers    = {}
  onlineUsers    = {}
end


function sampev.onPlayerJoin(id, color, isNPC, nickname)
  --[[
    Полная перезагрузка всех пользователей при каждом подключении нового.
    Слава богу луа достаточно шустрый и почти не лагает.
  ]]

  rebuildUsers()
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


local mainWindowState       = imgui.ImBool(false)
local headerFontNameBuffer  = imgui.ImBuffer('Arial', 256)
local headerFontSizeBuffer  = imgui.ImInt(9)
local headerFontColorBuffer = imgui.ImFloat3(0, 0, 0)
local headerTextBuffer      = imgui.ImBuffer('Users online', 32)
local headerPosXBuffer      = imgui.ImInt(450)
local headerPosYBuffer      = imgui.ImInt(450)
local headerFont            = renderCreateFont('Arial', 9, 5)


local selectedTab           = 0
local selectedList          = 0
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
      if selectedTab == 1 then
        imgui.BeginGroup()
          imgui.BeginChild('Center panel', imgui.ImVec2(145, -imgui.GetItemsLineHeightWithSpacing()), true)
            for i, v in ipairs(data['lists']) do
              if imgui.Selectable(v['title']..'##'..i, selectedList == i, imgui.SelectableFlags.AllowDoubleClick) then
                selectedList = i
                if imgui.IsMouseDoubleClicked(0) then
                  local a, r, g, b = explode_argb(data['lists'][selectedList]['color'])
                  tempBuffers['listTitle'] = imgui.ImBuffer(data['lists'][selectedList]['title'], 128)
                  tempBuffers['listIp']    = imgui.ImBuffer(data['lists'][selectedList]['ip'], 16)
                  tempBuffers['listPort']  = imgui.ImInt(data['lists'][selectedList]['port'])
                  tempBuffers['listColor'] = imgui.ImFloat3(r/255, g/255, b/255)
                  imgui.OpenPopup('Изменить настройки списка##'..i)
                end
              end
              if imgui.BeginPopupModal('Изменить настройки списка##'..i, nil, 64) then
                imgui.InputText('Название', tempBuffers['listTitle'])
                imgui.InputText('IP', tempBuffers['listIp'])
                imgui.InputInt('Port', tempBuffers['listPort'])
                imgui.ColorEdit3('Цвет', tempBuffers['listColor'])
                imgui.Separator()
                imgui.SetCursorPosX((imgui.GetWindowWidth() - 240 + imgui.GetStyle().ItemSpacing.x) / 2)
                if imgui.Button('Готово', imgui.ImVec2(120, 0)) then
                  data['lists'][selectedList] = {
                    isbuiltin = data['lists'][selectedList]['isbuiltin'],
                    title     = tempBuffers['listTitle'].v,
                    ip        = tempBuffers['listIp'].v,
                    port      = tempBuffers['listPort'].v,
                    color     = join_argb(255, tempBuffers['listColor'].v[1]*255, tempBuffers['listColor'].v[2]*255, tempBuffers['listColor'].v[3]*255),
                    users     = data['lists'][selectedList]['users']
                  }
                  saveData()
                  imgui.CloseCurrentPopup()
                end
                imgui.SameLine()
                if imgui.Button('Отмена', imgui.ImVec2(120, 0)) then imgui.CloseCurrentPopup() end
                    imgui.EndPopup()
                  end
                end
          imgui.EndChild()
          if imgui.Button('Добавить', imgui.ImVec2(70, 0)) then
            local name               = sampGetCurrentServerName()
            local ip, port           = sampGetCurrentServerAddress()
            tempBuffers['listTitle'] = imgui.ImBuffer(u8:encode(name), 128)
            tempBuffers['listIp']    = imgui.ImBuffer(ip, 16)
            tempBuffers['listPort']  = imgui.ImInt(port)
            tempBuffers['listColor'] = imgui.ImFloat3(0, 0, 0)
            imgui.OpenPopup('Добавление списка')
          end
          imgui.SameLine()
          if selectedList ~= 0 then
            if imgui.Button('Удалить', imgui.ImVec2(70, 0)) and not data['lists'][selectedList]['isbuiltin'] then
              imgui.OpenPopup('Удаление списка')
            end
          end

          if imgui.BeginPopupModal('Добавление списка', nil, 64) then
            imgui.InputText('Название', tempBuffers['listTitle'])
            imgui.InputText('IP', tempBuffers['listIp'])
            imgui.InputInt('Port', tempBuffers['listPort'])
            imgui.ColorEdit3('Цвет', tempBuffers['listColor'])
            imgui.Separator()
            imgui.SetCursorPosX((imgui.GetWindowWidth() - 240 + imgui.GetStyle().ItemSpacing.x) / 2)
            if imgui.Button('Готово', imgui.ImVec2(120, 0)) then
              table.insert(data['lists'], {
                isbuiltin = false,
                title     = tempBuffers['listTitle'].v,
                ip        = tempBuffers['listIp'].v,
                port      = tempBuffers['listPort'].v,
                color     = join_argb(255, tempBuffers['listColor'].v[1]*255, tempBuffers['listColor'].v[2]*255, tempBuffers['listColor'].v[3]*255),
                users     = {''}
              })
              saveData()
              imgui.CloseCurrentPopup()
            end
            imgui.SameLine()
            if imgui.Button('Отмена', imgui.ImVec2(120, 0)) then imgui.CloseCurrentPopup() end
            imgui.EndPopup()
          end

          if imgui.BeginPopupModal('Удаление списка', nil, 2) then
            imgui.Text('Удаление списка приведет к полной потере всех данных.\nЖелаете продолжить?')
            imgui.Separator()
            imgui.SetCursorPosX((imgui.GetWindowWidth() - 240 + imgui.GetStyle().ItemSpacing.x) / 2)
            if imgui.Button('Да', imgui.ImVec2(120, 0)) then table.remove(data['lists'], selectedList) selectedList = 0 saveData() imgui.CloseCurrentPopup() end
            imgui.SameLine()
            if imgui.Button('Нет', imgui.ImVec2(120, 0)) then imgui.CloseCurrentPopup() end
            imgui.EndPopup()
          end
        imgui.EndGroup()
        imgui.SameLine()
        imgui.BeginGroup()
          imgui.BeginChild('Right', imgui.ImVec2(150, 0), true)
            if selectedList ~= 0 then
              tempBuffers['usersListTextBuffer'] = imgui.ImBuffer(table.concat(data['lists'][selectedList]['users'], '\n'), 0xFFFF)
              if imgui.InputTextMultiline('##userslist', tempBuffers['usersListTextBuffer'], imgui.ImVec2(150, -1)) then
                local tempTable = parseText(tempBuffers['usersListTextBuffer'].v)
                data['lists'][selectedList]['users'] = #tempTable > 0 and tempTable or {''}
                saveData()
                rebuildUsers()
              end
            end
          imgui.EndChild()
          imgui.SameLine()
          imgui.BeginChild('Users list', imgui.ImVec2(150, 0), true)
            if selectedList ~= 0 then
              imgui.Text(table.concat(data['lists'][selectedList]['users'], '\n'))
            end
          imgui.EndChild()
        imgui.EndGroup()

      end
      if selectedTab == 2 then
        imgui.BeginGroup()
          imgui.BeginChild('Center panel')
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
          imgui.EndChild()
        imgui.EndGroup()
      end
      if selectedTab == 3 then
        imgui.BeginGroup()
          imgui.BeginChild('Center panel')
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
            imgui.SameLine()
            if imgui.Button('Группа ВКонтакте', imgui.ImVec2(150, 0)) then os.execute('explorer "https://vk.com/akionkamods"') end
            if imgui.Button('Bug report [VK]', imgui.ImVec2(150, 0)) then os.execute('explorer "https://vk.com/akionka"') end
            imgui.SameLine()
            if imgui.Button('Bug report [Telegram]', imgui.ImVec2(150, 0)) then os.execute('explorer "https://teleg.run/akionka"') end
          imgui.EndChild()
        imgui.EndGroup()
      end
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
  rebuildUsers()

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


function loadUsers()
  loadedUsers    = {}
  onlineUsers    = {}
  local ip, port = sampGetCurrentServerAddress()

  for i, v in ipairs(data['lists']) do
    if v['isbuiltin'] or (v['ip'] == ip and v['port'] == port) and type(v['users']) == 'table' then
      for _, v in pairs(v['users']) do
        table.insert(loadedUsers, {nickname = v, listid = i})
      end
    end
  end
end


function rebuildFonts()
  fontHeader = renderCreateFont(data['settings']['headerFontName'], data['settings']['headerFontSize'], 5)
end


function rebuildUsers()
  loadUsers()
  for i, v in ipairs(loadedUsers) do
    for i = 0, sampGetMaxPlayerId(false) do
      if sampIsPlayerConnected(i) then
        if sampGetPlayerNickname(i) == u8:decode(v['nickname']) then
          table.insert(onlineUsers, {nickname = u8:decode(v['nickname']), id = i, listid = v['listid']})
        end
      end
    end
  end
end


function renderList(x, y)
  local renderPosY = y
  renderFontDrawText(fontHeader, u8:decode(data['settings']['headerText'])..' ['..#onlineUsers..']:', x, y, data['settings']['headerFontColor'])
  renderPosY = renderPosY + data['settings']['headerFontSize']
  for i, v in ipairs(onlineUsers) do
    renderPosY = renderPosY + data['settings']['headerFontSize'] * 2
    renderFontDrawText(fontHeader, v['nickname']..' ['..v['id']..']', x, renderPosY, data['lists'][v['listid']]['color'])
  end
end


function parseText(text)
  local tempTable = {}
  for user in text:gmatch('(%S+)') do table.insert(tempTable, user) end
  return tempTable
end
