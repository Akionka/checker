script_name('Checker')
script_author('akionka')
script_version('2.2.5')
script_version_number(21)
script_moonloader(27)

require 'deps' {
  'fyp:samp-lua',
  'fyp:moon-imgui',
  'Akionka:lua-semver',
}


local sampev           = require 'lib.samp.events'
local encoding         = require 'encoding'
local imgui            = require 'imgui'
local v                = require 'semver'
local rkeys            = require 'rkeys'
imgui.HotKey           = require 'imgui_addons'.HotKey

local updatesAvaliable = false
local lastTagAvaliable = '1.0'

encoding.default       = 'cp1251'
local u8               = encoding.UTF8

local prefix           = 'Checker'
local bindID           = 0

local loadedUsers      = {}
local onlineUsers      = {}
local data             = {
  settings  = {
    alwaysAutoCheckUpdates          = true,
    notificationsAboutJoinsAndQuits = true,
    renderOnScreen                  = true,
    hideOnScreenshot                = false,
    hideOnOpenChat                  = false,
    listFontName                    = 'Arial',
    listFontSize                    = 9,
    listFontFlags                   = 5,
    headerFontName                  = 'Arial',
    headerFontSize                  = 9,
    headerFontColor                 = 0xFFFFFFFF,
    headerFontFlags                 = 5,
    headerText                      = 'Users online',
    headerPosX                      = 450,
    headerPosY                      = 450,
    renderHotKey                    = {v={0x71}},
    renderHotKeyType                = false,
    renderTime                      = 3000,
    renderID                        = true,
    renderLevel                     = true,
  },
  lists     = {
    {
      isbuiltin = true,
      title     = 'Common',
      ip        = '127.0.0.1',
      port      = 7777,
      color     = 0xFFFFFFFF,
      users     = {'West_Side', 'Drop_Table'},
    },
  },
}

local tempBuffers = {}


function applyCustomStyle()
  imgui.SwitchContext()
  local style  = imgui.GetStyle()
  local colors = style.Colors
  local clr    = imgui.Col
  local function ImVec4(color)
    local r = bit.band(bit.rshift(color, 24), 0xFF)
    local g = bit.band(bit.rshift(color, 16), 0xFF)
    local b = bit.band(bit.rshift(color, 8), 0xFF)
    local a = bit.band(color, 0xFF)
    return imgui.ImVec4(r/255, g/255, b/255, a/255)
  end

  style['WindowRounding']      = 10.0
  style['WindowTitleAlign']    = imgui.ImVec2(0.5, 0.5)
  style['ChildWindowRounding'] = 5.0
  style['FrameRounding']       = 5.0
  style['ItemSpacing']         = imgui.ImVec2(5.0, 5.0)
  style['ScrollbarSize']       = 13.0
  style['ScrollbarRounding']   = 5

  colors[clr['Text']]                 = ImVec4(0xFFFFFFFF)
  colors[clr['TextDisabled']]         = ImVec4(0x212121FF)
  colors[clr['WindowBg']]             = ImVec4(0x212121FF)
  colors[clr['ChildWindowBg']]        = ImVec4(0x21212180)
  colors[clr['PopupBg']]              = ImVec4(0x212121FF)
  colors[clr['Border']]               = ImVec4(0xFFFFFF10)
  colors[clr['BorderShadow']]         = ImVec4(0x21212100)
  colors[clr['FrameBg']]              = ImVec4(0xC3E88D90)
  colors[clr['FrameBgHovered']]       = ImVec4(0xC3E88DFF)
  colors[clr['FrameBgActive']]        = ImVec4(0x61616150)
  colors[clr['TitleBg']]              = ImVec4(0x212121FF)
  colors[clr['TitleBgActive']]        = ImVec4(0x212121FF)
  colors[clr['TitleBgCollapsed']]     = ImVec4(0x212121FF)
  colors[clr['MenuBarBg']]            = ImVec4(0x21212180)
  colors[clr['ScrollbarBg']]          = ImVec4(0x212121FF)
  colors[clr['ScrollbarGrab']]        = ImVec4(0xEEFFFF20)
  colors[clr['ScrollbarGrabHovered']] = ImVec4(0xEEFFFF10)
  colors[clr['ScrollbarGrabActive']]  = ImVec4(0x80CBC4FF)
  colors[clr['ComboBg']]              = colors[clr['PopupBg']]
  colors[clr['CheckMark']]            = ImVec4(0x212121FF)
  colors[clr['SliderGrab']]           = ImVec4(0x212121FF)
  colors[clr['SliderGrabActive']]     = ImVec4(0x80CBC4FF)
  colors[clr['Button']]               = ImVec4(0xC3E88D90)
  colors[clr['ButtonHovered']]        = ImVec4(0xC3E88DFF)
  colors[clr['ButtonActive']]         = ImVec4(0x61616150)
  colors[clr['Header']]               = ImVec4(0x151515FF)
  colors[clr['HeaderHovered']]        = ImVec4(0x252525FF)
  colors[clr['HeaderActive']]         = ImVec4(0x303030FF)
  colors[clr['Separator']]            = colors[clr['Border']]
  colors[clr['SeparatorHovered']]     = ImVec4(0x212121FF)
  colors[clr['SeparatorActive']]      = ImVec4(0x212121FF)
  colors[clr['ResizeGrip']]           = ImVec4(0x212121FF)
  colors[clr['ResizeGripHovered']]    = ImVec4(0x212121FF)
  colors[clr['ResizeGripActive']]     = ImVec4(0x212121FF)
  colors[clr['CloseButton']]          = ImVec4(0x212121FF)
  colors[clr['CloseButtonHovered']]   = ImVec4(0xD41223FF)
  colors[clr['CloseButtonActive']]    = ImVec4(0xD41223FF)
  colors[clr['PlotLines']]            = ImVec4(0x212121FF)
  colors[clr['PlotLinesHovered']]     = ImVec4(0x212121FF)
  colors[clr['PlotHistogram']]        = ImVec4(0x212121FF)
  colors[clr['PlotHistogramHovered']] = ImVec4(0x212121FF)
  colors[clr['TextSelectedBg']]       = ImVec4(0x212121FF)
  colors[clr['ModalWindowDarkening']] = ImVec4(0x21212180)
end


function sampev.onSendClientJoin()
  --[[
    Обнуление онлайн пользователей, загруженных пользователей после (ре)коннекта.
  ]]

  loadUsers()
end


function sampev.onPlayerJoin(id, color, isNPC, nickname)
  --[[
    Полная перезагрузка всех пользователей при каждом подключении нового.
    Слава богу луа достаточно шустрый и почти не лагает.
  ]]

  addUser(id, nickname)
end


function sampev.onPlayerQuit(id, reason)
  --[[
    Исключение из списка онлайн пользователей покинувшего сервер пользователя.
  ]]

  removeUser(id)
end

function addUser(id, nickname)
  for i, v in ipairs(loadedUsers) do
    if v['nickname'] == nickname then
      if data['settings']['notificationsAboutJoinsAndQuits'] then
        alert('Пользователь {9932cc}'..v['nickname']..'  ['..id..']{FFFFFF} присоединился к серверу.')
      end
      table.insert(onlineUsers, {
        nickname = u8:decode(v['nickname']),
        id = id,
        listid = v['listid'],
      })
    end
  end
end

function removeUser(id)
  for i, v in ipairs(onlineUsers) do
    if v['id'] == id then
      if data['settings']['notificationsAboutJoinsAndQuits'] then
        alert('Пользователь {9932cc}'..v['nickname']..'  ['..id..']{FFFFFF} покинул сервер.')
      end
      table.remove(onlineUsers, i)
      break
    end
  end
end


local mainWindowState       = imgui.ImBool(false)
local listFontNameBuffer    = imgui.ImBuffer('Arial', 256)
local listFontSizeBuffer    = imgui.ImInt(9)
local listFontFlags         = 5
local headerFontNameBuffer  = imgui.ImBuffer('Arial', 256)
local headerFontSizeBuffer  = imgui.ImInt(9)
local headerFontFlags       = 5
local headerFontColorBuffer = imgui.ImFloat3(0, 0, 0)
local headerTextBuffer      = imgui.ImBuffer('Users online', 32)
local headerPosXBuffer      = imgui.ImInt(450)
local headerPosYBuffer      = imgui.ImInt(450)
local headerFont            = renderCreateFont('Arial', 9, 5)
local listFont              = renderCreateFont('Arial', 9, 5)
local renderTimeBuffer      = imgui.ImInt(3000)


local selectedTab           = 0
local selectedList          = 0
local movingInProgress      = false

function imgui.OnDrawFrame()
  local tLastKeys = {}
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
          if imgui.Button('Добавить', imgui.ImVec2((selectedList == 0 or data['lists'][selectedList]['isbuiltin']) and 145 or 70, 0)) then
            local name               = sampGetCurrentServerName()
            local ip, port           = sampGetCurrentServerAddress()
            tempBuffers['listTitle'] = imgui.ImBuffer(u8:encode(name), 128)
            tempBuffers['listIp']    = imgui.ImBuffer(ip, 16)
            tempBuffers['listPort']  = imgui.ImInt(port)
            tempBuffers['listColor'] = imgui.ImFloat3(0, 0, 0)
            imgui.OpenPopup('Добавление списка')
          end
          imgui.SameLine()

          if selectedList ~= 0 and not data['lists'][selectedList]['isbuiltin'] and imgui.Button('Удалить', imgui.ImVec2(70, 0)) then
            imgui.OpenPopup('Удаление списка')
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
            imgui.PushItemWidth(100)
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
            if not data['settings']['renderOnScreen'] then
              if imgui.HotKey('##renderhotkey', data['settings']['renderHotKey'], tLastKeys, 100) then
                rkeys.changeHotKey(bindID, data['settings']['renderHotKey'].v)
                saveData()
              end
              imgui.SameLine()
              imgui.Text('Хоткей рендера на экране')
              if imgui.Button(data['settings']['renderHotKeyType'] and 'Нажатие' or 'Удержание', imgui.ImVec2(100, 0)) then
                data['settings']['renderHotKeyType'] = not data['settings']['renderHotKeyType']
                saveData()
              end
              if data['settings']['renderHotKeyType'] then
                if imgui.InputInt('Время рендера (в мс, 1000 мс = 1 сек)', renderTimeBuffer, 1, 100) then
                  data['settings']['renderTime'] = renderTimeBuffer.v
                  saveData()
                end
              end
            end
            if imgui.Checkbox('Прятать на скриншотах', imgui.ImBool(data['settings']['hideOnScreenshot'])) then
              data['settings']['hideOnScreenshot'] = not data['settings']['hideOnScreenshot']
              saveData()
            end
            if imgui.Checkbox('Прятать при открытии чата', imgui.ImBool(data['settings']['hideOnOpenChat']))then
              data['settings']['hideOnOpenChat'] = not data['settings']['hideOnOpenChat']
              saveData()
            end
            if imgui.Checkbox('Показывать ID', imgui.ImBool(data['settings']['renderID'])) then
              data['settings']['renderID'] = not data['settings']['renderID']
              saveData()
            end
            if imgui.Checkbox('Показывать Level', imgui.ImBool(data['settings']['renderLevel'])) then
              data['settings']['renderLevel'] = not data['settings']['renderLevel']
              saveData()
            end
            if imgui.InputText('Название шрифта списка', listFontNameBuffer) then
              data['settings']['listFontName'] = listFontNameBuffer.v
              saveData()
              rebuildFonts()
            end
            if imgui.InputInt('Размер шрифта спика', listFontSizeBuffer, 1, 3) then
              data['settings']['listFontSize'] = listFontSizeBuffer.v
              saveData()
              rebuildFonts()
            end
            imgui.Text('Флаги шрифта списка:')
            if imgui.RadioButton('Полужирный##list', bit.band(0x1, listFontFlags) == 0x1) then
              listFontFlags = bit.bxor(0x1, listFontFlags)
              data['settings']['listFontFlags'] = listFontFlags
              saveData()
              rebuildFonts()
            end
            imgui.SameLine()
            if imgui.RadioButton('Курсив##list', bit.band(0x2, listFontFlags) == 0x2) then
              listFontFlags = bit.bxor(0x2, listFontFlags)
              data['settings']['listFontFlags'] = listFontFlags
              saveData()
              rebuildFonts()
            end
            imgui.SameLine()
            if imgui.RadioButton('Контур##list', bit.band(0x4, listFontFlags) == 0x4) then
              listFontFlags = bit.bxor(0x4, listFontFlags)
              data['settings']['listFontFlags'] = listFontFlags
              saveData()
              rebuildFonts()
            end
            imgui.SameLine()
            if imgui.RadioButton('Тень##list', bit.band(0x8, listFontFlags) == 0x8) then
              listFontFlags = bit.bxor(0x8, listFontFlags)
              data['settings']['listFontFlags'] = listFontFlags
              saveData()
              rebuildFonts()
            end
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
            imgui.Text('Флаги шрифта шапки:')
            if imgui.RadioButton('Полужирный##header', bit.band(0x1, headerFontFlags) == 0x1) then
              headerFontFlags = bit.bxor(0x1, headerFontFlags)
              data['settings']['headerFontFlags'] = headerFontFlags
              saveData()
              rebuildFonts()
            end
            imgui.SameLine()
            if imgui.RadioButton('Курсив##header', bit.band(0x2, headerFontFlags) == 0x2) then
              headerFontFlags = bit.bxor(0x2, headerFontFlags)
              data['settings']['headerFontFlags'] = headerFontFlags
              saveData()
              rebuildFonts()
            end
            imgui.SameLine()
            if imgui.RadioButton('Контур##header', bit.band(0x4, headerFontFlags) == 0x4) then
              headerFontFlags = bit.bxor(0x4, headerFontFlags)
              data['settings']['headerFontFlags'] = headerFontFlags
              saveData()
              rebuildFonts()
            end
            imgui.SameLine()
            if imgui.RadioButton('Тень##header', bit.band(0x8, headerFontFlags) == 0x8) then
              headerFontFlags = bit.bxor(0x8, headerFontFlags)
              data['settings']['headerFontFlags'] = headerFontFlags
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
            imgui.Text('Версия: '..thisScript()['version_num']..' ('..thisScript()['version']..')')
            imgui.Text('Команды: /checker, /users')
            if updatesAvaliable then
              if imgui.Button('Скачать обновление', imgui.ImVec2(150, 0)) then
                update()
                mainWindowState.v = false
              end
            else
              if imgui.Button('Проверить обновления', imgui.ImVec2(150, 0)) then
                checkUpdates()
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

  loadData()
  rebuildFonts()
  rebuildUsers()
  applyCustomStyle()

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

  bindID = rkeys.registerHotKey(data['settings']['renderHotKey'].v, data['settings']['renderHotKeyType'], function ()
    if data['settings']['renderHotKeyType'] then
      local startTime = os.clock()
      while(os.clock() - startTime < data['settings']['renderTime']/1000) do
        renderList(data['settings']['headerPosX'], data['settings']['headerPosY'])
        wait(0)
      end
    else
      renderList(data['settings']['headerPosX'], data['settings']['headerPosY'])
    end
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


function checkUpdates()
  local fpath = os.tmpname()
  if doesFileExist(fpath) then os.remove(fpath) end
  downloadUrlToFile('https://api.github.com/repos/akionka/'..thisScript()['name']..'/releases', fpath, function(_, status, _, _)
    if status == 58 then
      if doesFileExist(fpath) then
        local f = io.open(fpath, 'r')
        if f then
          local info = decodeJson(f: read('*a'))
          f:close()
          os.remove(fpath)
          if v(info[1]['tag_name']) > v(thisScript()['version']) then
            updatesAvaliable = true
            lastTagAvaliable = info[1]['tag_name']
            alert('Найдено объявление. Текущая версия: {9932cc}'..thisScript()['version']..'{FFFFFF}, новая версия: {9932cc}'..info[1]['tag_name']..'{FFFFFF}')
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

function update()
  downloadUrlToFile('https://github.com/akionka/'..thisScript()['name']..'/releases/download/'..lastTagAvaliable..'/checker.lua', thisScript()['path'], function(_, status, _, _)
    if status == 6 then
      alert('Новая версия установлена! Чтобы скрипт обновился нужно либо перезайти в игру, либо ...')
      alert('... если у вас есть автоперезагрузка скриптов, то новая версия уже готова и снизу вы увидите приветственное сообщение.')
      alert('Если что-то пошло не так, то сообщите мне об этом в VK или Telegram > {2980b0}vk.com/akionka teleg.run/akionka{FFFFFF}.')
      thisScript()['reload']()
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
  local function loadSettings(table, dest)
    for k, v in pairs(table) do
      if type(v) == 'table' then
        loadSettings(v, dest[k])
      end
      dest[k] = v
    end
  end

  if not doesFileExist(getWorkingDirectory()..'\\config\\checker.json') then
    local configFile = io.open(getWorkingDirectory()..'\\config\\checker.json', 'w+')
    configFile:write(encodeJson(data))
    configFile:close()
    return
  end

  local configFile = io.open(getWorkingDirectory()..'\\config\\checker.json', 'r')
  local tempData = decodeJson(configFile:read('*a'))
  loadSettings(tempData['settings'], data['settings'])
  data['lists'] = tempData['lists'] or data['list']
  configFile:close()

  local a, r, g, b        = explode_argb(data['settings']['headerFontColor'])
  listFontNameBuffer.v    = data['settings']['listFontName'] or 'Arial'
  listFontSizeBuffer.v    = data['settings']['listFontSize'] or 9
  listFontFlags           = data['settings']['listFontFlags'] or 5
  headerFontNameBuffer.v  = data['settings']['headerFontName'] or 'Arial'
  headerFontSizeBuffer.v  = data['settings']['headerFontSize'] or 9
  headerFontFlags         = data['settings']['headerFontFlags'] or 5
  headerPosXBuffer.v      = data['settings']['headerPosX'] or 450
  headerPosYBuffer.v      = data['settings']['headerPosY'] or 450
  headerTextBuffer.v      = data['settings']['headerText'] or 'Users online'
  renderTimeBuffer.v      = data['settings']['renderTime'] or 3000
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
  fontHeader = renderCreateFont(data['settings']['headerFontName'], data['settings']['headerFontSize'], data['settings']['headerFontFlags'])
  fontList = renderCreateFont(data['settings']['listFontName'], data['settings']['listFontSize'], data['settings']['listFontFlags'])
end


function rebuildUsers()
  loadUsers()
  for i, v in ipairs(loadedUsers) do
    for i = 0, sampGetMaxPlayerId(false) do
      if sampIsPlayerConnected(i) then
        if sampGetPlayerNickname(i) == u8:decode(v['nickname']) then
          table.insert(onlineUsers, {
            nickname = u8:decode(v['nickname']),
            id = i,
            listid = v['listid'],
          })
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
    renderPosY = renderPosY + data['settings']['listFontSize'] * 2
    local nicknameText, idText, lvlText = v['nickname'], data['settings']['renderID'] and '['..v['id']..']' or '', data['settings']['renderLevel'] and ' LVL: '..sampGetPlayerScore(v['id']) or ''
    renderFontDrawText(fontList, nicknameText..idText..lvlText, x, renderPosY, data['lists'][v['listid']]['color'])
  end
end


function parseText(text)
  local tempTable = {}
  for user in text:gmatch('([%w+%d+%[%]_@$]+)') do table.insert(tempTable, user) end
  return tempTable
end
