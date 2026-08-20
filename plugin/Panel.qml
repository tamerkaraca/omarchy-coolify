import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "community.coolify"
  ipcTarget: "community.coolify"
  manageIpc: false

  property var servers: []
  property var projects: []
  property var counts: ({ servers: 0, projects: 0, applications: 0, services: 0, databases: 0 })
  property string version: ""
  property string dashboard: ""
  property string siteUrl: ""
  property string language: "en"
  property bool configured: false
  property bool configLoaded: false
  property bool editingSettings: false
  property bool shortcutsVisible: false
  property bool revealApiKey: false
  property string errorText: ""
  property bool loading: false
  property int refreshSeconds: 30
  property int cursor: 0
  property string viewMode: "overview"
  property var selectedProject: null
  property string helperPath: Quickshell.env("HOME") + "/.config/omarchy/plugins/community.coolify/coolify_mcp.py"
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool settingsVisible: editingSettings || (configLoaded && !configured)
  readonly property var projectResources: {
    var apps = selectedProject && selectedProject.applications ? selectedProject.applications : []
    var services = selectedProject && selectedProject.services ? selectedProject.services : []
    var databases = selectedProject && selectedProject.databases ? selectedProject.databases : []
    return { apps: apps, services: services, databases: databases }
  }
  readonly property int itemCount: viewMode === "apps"
    ? projectResources.apps.length + projectResources.services.length + projectResources.databases.length
    : servers.length + projects.length

  readonly property var translations: ({
    en: {
      notConfigured: "Coolify not configured",
      appsWord: "apps",
      backTip: "Projects (Esc)",
      refreshTip: "Refresh (r)",
      settingsTip: "Settings (s)",
      openTip: "Open selected (o)",
      appsTitle: "Applications",
      countServer: "Server", countProject: "Project", countApplication: "Application", countService: "Service", countDb: "DB",
      serversHeader: "Servers", projectsHeader: "Projects", appsHeader: "Applications", servicesHeader: "Services", databasesHeader: "Databases",
      serverFallback: "Server", projectFallback: "Project", appFallback: "Application",
      appWord: "app", serviceWord: "service", dbWord: "DB",
      noDomain: "No domain defined",
      footerOverview1: "j/k: select · o/enter: apps · c: copy",
      footerOverview2: "r: refresh · s: settings · esc: close",
      footerApps1: "j/k: select · o/enter: open site · c: copy URL",
      footerApps2: "r: refresh · s: settings · esc: back",
      settingsTitle: "Connection settings",
      shortcutsTitle: "Keyboard shortcuts",
      overviewShortcuts: "j / k    Select server or project\no / Enter    Open selected item\nc    Copy selected value\nr    Refresh data\ns    Open settings\n?    Show shortcuts\nEsc    Close panel",
      appsShortcuts: "j / k    Select application\no / Enter    Open selected application\nc    Copy application URL\nh / Left    Back to projects\nr    Refresh data\ns    Open settings\n?    Show shortcuts\nEsc    Back",
      settingsShortcuts: "Ctrl + S    Save settings\nCtrl + R    Reload settings\nCtrl + O    Open dashboard\nTab / Shift + Tab    Move between fields\nEsc    Back",
      urlLabel: "Coolify panel address",
      apiKeyLabel: "API key",
      apiKeyKeep: "API key (leave blank to keep)",
      apiKeyNew: "Coolify API key",
      refreshLabel: "Refresh (s)",
      revealKey: "Show key",
      saveButton: "Save & Connect",
      cancelButton: "Cancel",
      settingsHint: "Ctrl+S save  •  Ctrl+R reload  •  Ctrl+O dashboard  •  Esc back",
      languageLabel: "Language",
      responseError: "Couldn't read Coolify response",
      connectionFailed: "Coolify connection failed"
    },
    tr: {
      notConfigured: "Coolify ayarlanmadı",
      appsWord: "uygulama",
      backTip: "Projeler (Esc)",
      refreshTip: "Yenile (r)",
      settingsTip: "Ayarlar (s)",
      openTip: "Seçileni aç (o)",
      appsTitle: "Uygulamalar",
      countServer: "Sunucu", countProject: "Proje", countApplication: "Uygulama", countService: "Servis", countDb: "DB",
      serversHeader: "Sunucular", projectsHeader: "Projeler", appsHeader: "Uygulamalar", servicesHeader: "Servisler", databasesHeader: "Veritabanları",
      serverFallback: "Sunucu", projectFallback: "Proje", appFallback: "Uygulama",
      appWord: "app", serviceWord: "servis", dbWord: "DB",
      noDomain: "Alan adı tanımlı değil",
      footerOverview1: "j/k: seç · o/enter: uygulamalar · c: kopyala",
      footerOverview2: "r: yenile · s: ayarlar · esc: kapat",
      footerApps1: "j/k: seç · o/enter: siteyi aç · c: URL kopyala",
      footerApps2: "r: yenile · s: ayarlar · esc: geri",
      settingsTitle: "Bağlantı ayarları",
      shortcutsTitle: "Klavye kısayolları",
      overviewShortcuts: "j / k    Sunucu veya proje seç\no / Enter    Seçileni aç\nc    Seçili değeri kopyala\nr    Verileri yenile\ns    Ayarları aç\n?    Kısayolları göster\nEsc    Paneli kapat",
      appsShortcuts: "j / k    Uygulama seç\no / Enter    Seçili uygulamayı aç\nc    Uygulama URL'sini kopyala\nh / Sol    Projelere dön\nr    Verileri yenile\ns    Ayarları aç\n?    Kısayolları göster\nEsc    Geri dön",
      settingsShortcuts: "Ctrl + S    Ayarları kaydet\nCtrl + R    Ayarları yeniden yükle\nCtrl + O    Dashboard'u aç\nTab / Shift + Tab    Alanlar arasında geç\nEsc    Geri dön",
      urlLabel: "Coolify panel adresi",
      apiKeyLabel: "API key",
      apiKeyKeep: "API key (değişmeyecekse boş bırakın)",
      apiKeyNew: "Coolify API key",
      refreshLabel: "Yenileme (sn)",
      revealKey: "Anahtarı göster",
      saveButton: "Kaydet ve Bağlan",
      cancelButton: "İptal",
      settingsHint: "Ctrl+S kaydet  •  Ctrl+R yeniden yükle  •  Ctrl+O dashboard  •  Esc geri dön",
      languageLabel: "Dil",
      responseError: "Coolify yanıtı okunamadı",
      connectionFailed: "Coolify bağlantısı başarısız"
    }
  })
  readonly property var t: translations[language] || translations.en

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (poll.running) return
    loading = true
    errorText = ""
    poll.command = ["python3", helperPath, "poll"]
    poll.running = true
  }

  function loadConfig() {
    if (configProc.running) return
    configProc.command = ["python3", helperPath, "config"]
    configProc.running = true
  }

  function saveSettings() {
    if (saveProc.running) return
    errorText = ""
    saveProc.payload = JSON.stringify({
      url: endpointField.text.trim(),
      key: apiKeyField.text,
      interval: intervalField.value,
      language: languageField.currentValue
    })
    saveProc.stdinEnabled = true
    saveProc.running = true
  }

  function beginSettings() {
    shortcutsVisible = false
    editingSettings = true
    revealApiKey = false
    endpointField.text = siteUrl
    apiKeyField.text = ""
    if (configured && !keyProc.running) keyProc.running = true
    intervalField.value = refreshSeconds
    languageField.currentIndex = language === "tr" ? 1 : 0
    Qt.callLater(function() { endpointField.forceActiveFocus() })
  }

  function cancelSettings() {
    if (!configured) {
      close()
      return
    }
    editingSettings = false
    revealApiKey = false
    Qt.callLater(function() { keys.forceActiveFocus() })
  }

  function showShortcuts() {
    if (settingsVisible) return
    shortcutsVisible = true
    Qt.callLater(function() { keys.forceActiveFocus() })
  }

  function hideShortcuts() {
    shortcutsVisible = false
    Qt.callLater(function() { keys.forceActiveFocus() })
  }

  function reloadSettings() {
    loadConfig()
    beginSettings()
  }

  function handleSettingsKey(event) {
    if (!settingsVisible) return
    var ctrl = (event.modifiers & Qt.ControlModifier) !== 0
    if (ctrl && event.key === Qt.Key_S) {
      event.accepted = true
      saveSettings()
    } else if (ctrl && event.key === Qt.Key_R) {
      event.accepted = true
      reloadSettings()
    } else if (ctrl && event.key === Qt.Key_O) {
      event.accepted = true
      openDashboard()
    } else if (event.key === Qt.Key_Escape) {
      event.accepted = true
      cancelSettings()
    }
  }

  function applyResult(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"))
      configLoaded = true
      configured = data.configured === true
      siteUrl = String(data.siteUrl || siteUrl)
      dashboard = String(data.dashboard || dashboard)
      refreshSeconds = Number(data.refreshSeconds || refreshSeconds)
      if (data.language) language = String(data.language)
      if (data.error) { errorText = String(data.error); return }
      if (data.servers instanceof Array) servers = data.servers
      if (data.projects instanceof Array) projects = data.projects
      if (data.counts) counts = data.counts
      if (data.coolify_version !== undefined) version = String(data.coolify_version)
      if (viewMode === "apps" && selectedProject) {
        var selectedUuid = String(selectedProject.uuid || "")
        selectedProject = null
        for (var i = 0; i < projects.length; i++) {
          if (String(projects[i].uuid || "") === selectedUuid) { selectedProject = projects[i]; break }
        }
      }
      cursor = Math.max(0, Math.min(cursor, Math.max(0, itemCount - 1)))
    } catch (e) { errorText = root.t.responseError }
    if (root.opened && configLoaded && !configured) Qt.callLater(function() { endpointField.forceActiveFocus() })
  }

  function resourceAt(index) {
    if (viewMode !== "apps" || !selectedProject) return null
    var apps = projectResources.apps
    if (index < apps.length) return apps[index]
    var services = projectResources.services
    var serviceIndex = index - apps.length
    if (serviceIndex < services.length) return services[serviceIndex]
    var databases = projectResources.databases
    var databaseIndex = serviceIndex - services.length
    return databaseIndex >= 0 && databaseIndex < databases.length ? databases[databaseIndex] : null
  }

  function selectedValue() {
    if (viewMode === "apps") {
      var item = resourceAt(cursor)
      return item ? String(item.primary_url || item.fqdn || item.display_name || item.name || "") : ""
    }
    if (cursor < servers.length) {
      var server = servers[cursor]
      return String(server.ip || server.name || "")
    }
    var project = projects[cursor - servers.length]
    return project ? String(project.name || project.uuid || "") : ""
  }

  function copySelected() {
    var value = selectedValue()
    if (value !== "") Quickshell.execDetached(["bash", "-c", "printf %s " + Util.shellQuote(value) + " | wl-copy"])
  }

  function openProject(project) {
    if (!project) return
    selectedProject = project
    viewMode = "apps"
    cursor = 0
    list.contentY = 0
  }

  function goBack() {
    if (viewMode === "apps") {
      var projectUuid = selectedProject ? String(selectedProject.uuid || "") : ""
      viewMode = "overview"
      selectedProject = null
      cursor = 0
      for (var i = 0; i < projects.length; i++) {
        if (String(projects[i].uuid || "") === projectUuid) { cursor = servers.length + i; break }
      }
      list.contentY = 0
    } else root.close()
  }

  function openApplication(app) {
    if (!app) return
    var url = String(app.primary_url || "")
    // Services and databases have no public URL — open their Coolify project page instead.
    if (url === "" && selectedProject && dashboard !== "") url = dashboard + "project/" + selectedProject.uuid
    if (url === "") return
    Quickshell.execDetached(["xdg-open", url])
    close()
  }

  function activateSelected() {
    if (viewMode === "apps") {
      openApplication(resourceAt(cursor))
      return
    }
    if (cursor >= servers.length) openProject(projects[cursor - servers.length])
  }

  function openSelected() {
    if (viewMode === "apps") activateSelected()
    else if (cursor >= servers.length) openProject(projects[cursor - servers.length])
    else openDashboard()
  }

  function openDashboard() {
    if (dashboard !== "") Quickshell.execDetached(["xdg-open", dashboard])
    close()
  }

  onOpenedChanged: if (opened) {
    viewMode = "overview"
    selectedProject = null
    cursor = 0
    shortcutsVisible = false
    refresh()
    Qt.callLater(function() {
      if (root.settingsVisible) endpointField.forceActiveFocus()
      else keys.forceActiveFocus()
    })
  }
  Component.onCompleted: {
    loadConfig()
    refresh()
  }

  Timer {
    interval: Math.max(10, root.refreshSeconds) * 1000
    running: root.configured
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: poll
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyResult(text) }
    stderr: StdioCollector { waitForEnd: true }
    onExited: function(code) { root.loading = false; if (code !== 0 && root.errorText === "") root.errorText = root.t.connectionFailed }
  }

  Process {
    id: configProc
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyResult(text) }
  }

  Process {
    id: saveProc
    property string payload: ""
    command: ["python3", root.helperPath, "configure"]
    stdinEnabled: true
    onStarted: {
      write(payload + "\n")
      payload = ""
      stdinEnabled = false
    }
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyResult(text) }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text).trim() !== "") root.errorText = String(text).trim()
    }
    onExited: function(code) {
      if (code === 0) {
        root.editingSettings = false
        root.servers = []
        root.projects = []
        root.counts = ({ servers: 0, projects: 0, applications: 0, services: 0, databases: 0 })
        root.version = ""
        Qt.callLater(function() { root.refresh(); keys.forceActiveFocus() })
      }
    }
  }

  Process {
    id: keyProc
    command: ["python3", root.helperPath, "key"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { apiKeyField.text = String(text || "").trim() }
    }
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refresh(); return "ok" }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰒋"
    opacity: root.loading ? 0.55 : 1.0
    tooltipText: root.errorText !== "" ? root.errorText
      : (!root.configured ? root.t.notConfigured
      : "Coolify · " + Number(root.counts.applications || 0) + " " + root.t.appsWord)
    onPressed: function(code) {
      if (code === Qt.RightButton) root.refresh()
      else if (code === Qt.MiddleButton) root.openDashboard()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keys
    contentWidth: popup.fittedContentWidth(Style.space(430))
    contentHeight: popup.fittedContentHeight(Style.space(620), Style.space(650))

    Rectangle {
      anchors.fill: parent
      color: Color.background
      clip: true

      ColumnLayout {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: Style.space(14)
      anchors.bottomMargin: Style.space(14)
      spacing: Style.space(10)

      RowLayout {
        Layout.fillWidth: true
        PanelActionButton { visible: root.viewMode === "apps" && !root.shortcutsVisible; iconText: "󰁍"; tooltipText: root.t.backTip; foreground: root.foreground; fontFamily: root.fontFamily; onClicked: root.goBack() }
        PanelActionButton { visible: root.shortcutsVisible; iconText: "󰁍"; tooltipText: root.t.backTip; foreground: root.foreground; fontFamily: root.fontFamily; onClicked: root.hideShortcuts() }
        Text { text: root.shortcutsVisible ? root.t.shortcutsTitle : (root.viewMode === "apps" && root.selectedProject ? String(root.selectedProject.name || root.t.appsTitle) : "Coolify"); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.title; font.bold: true; elide: Text.ElideRight; Layout.maximumWidth: Style.space(230) }
        Item { Layout.fillWidth: true }
        Text { text: root.version === "" ? "" : "v" + root.version; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
        PanelActionButton { iconText: "󰒓"; tooltipText: root.t.settingsTip; foreground: root.foreground; fontFamily: root.fontFamily; onClicked: root.beginSettings() }
        PanelActionButton { iconText: "󰑐"; tooltipText: root.t.refreshTip; foreground: root.foreground; fontFamily: root.fontFamily; onClicked: root.refresh() }
        PanelActionButton { visible: !root.settingsVisible; iconText: "󰖟"; tooltipText: root.t.openTip; foreground: root.foreground; fontFamily: root.fontFamily; onClicked: root.openSelected() }
      }

      RowLayout {
        visible: root.viewMode === "overview" && !root.settingsVisible && !root.shortcutsVisible
        Layout.fillWidth: true
        spacing: Style.space(6)
        Repeater {
          model: [
            { label: root.t.countServer, value: root.counts.servers || 0 },
            { label: root.t.countProject, value: root.counts.projects || 0 },
            { label: root.t.countApplication, value: root.counts.applications || 0 },
            { label: root.t.countService, value: root.counts.services || 0 },
            { label: root.t.countDb, value: root.counts.databases || 0 }
          ]
          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: Style.space(48)
            radius: Style.cornerRadius
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)
            Column { anchors.centerIn: parent; Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: root.foreground; font.family: root.fontFamily; font.bold: true } Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption } }
          }
        }
      }

      Text { visible: root.errorText !== ""; Layout.fillWidth: true; text: root.errorText; color: root.urgent; wrapMode: Text.Wrap }

      ColumnLayout {
        visible: root.settingsVisible
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 0
        spacing: Style.space(8)

        Text { text: root.t.settingsTitle; color: root.foreground; font.family: root.fontFamily; font.bold: true }

        Text { text: root.t.urlLabel; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
        TextField {
          id: endpointField
          Layout.fillWidth: true
          placeholderText: "https://panel.example.com"
          color: root.foreground
          Keys.priority: Keys.BeforeItem
          Keys.onPressed: function(event) { root.handleSettingsKey(event) }
        }

        Text { text: root.t.apiKeyLabel; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
        TextField {
          id: apiKeyField
          Layout.fillWidth: true
          placeholderText: root.configured ? root.t.apiKeyKeep : root.t.apiKeyNew
          echoMode: root.revealApiKey ? TextInput.Normal : TextInput.Password
          color: root.foreground
          Keys.priority: Keys.BeforeItem
          Keys.onPressed: function(event) { root.handleSettingsKey(event) }
        }

        RowLayout {
          Layout.fillWidth: true
          Text { text: root.t.refreshLabel; color: root.foreground; font.family: root.fontFamily }
          SpinBox {
            id: intervalField
            from: 10
            to: 3600
            value: 30
            editable: true
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) { root.handleSettingsKey(event) }
          }
          Item { Layout.fillWidth: true }
          CheckBox {
            text: root.t.revealKey
            checked: root.revealApiKey
            onClicked: {
              root.revealApiKey = checked
              if (apiKeyField.text === "" && root.configured && !keyProc.running)
                keyProc.running = true
            }
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) { root.handleSettingsKey(event) }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Text { text: root.t.languageLabel; color: root.foreground; font.family: root.fontFamily }
          ComboBox {
            id: languageField
            model: [ { code: "en", label: "English" }, { code: "tr", label: "Türkçe" } ]
            textRole: "label"
            valueRole: "code"
            currentIndex: root.language === "tr" ? 1 : 0
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) { root.handleSettingsKey(event) }
          }
          Item { Layout.fillWidth: true }
        }

        RowLayout {
          Layout.fillWidth: true
          Button { text: root.t.saveButton; enabled: !saveProc.running; onClicked: root.saveSettings() }
          Button { visible: root.configured; text: root.t.cancelButton; onClicked: root.cancelSettings() }
        }

        Item { Layout.fillHeight: true }

        Text {
          Layout.fillWidth: true
          text: root.t.settingsHint
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }
      }

      ColumnLayout {
        visible: root.shortcutsVisible
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 0
        spacing: Style.space(12)

        Text {
          text: root.t.shortcutsTitle
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Text {
          visible: root.viewMode === "overview"
          text: root.t.overviewShortcuts
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          lineHeight: Style.space(4)
        }

        Text {
          visible: root.viewMode === "apps"
          text: root.t.appsShortcuts
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          lineHeight: Style.space(4)
        }

        Text {
          text: root.t.settingsShortcuts
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          lineHeight: Style.space(4)
        }

        Item { Layout.fillHeight: true }
      }

      Flickable {
        id: list
        visible: !root.settingsVisible && !root.shortcutsVisible
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 0
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ColumnLayout {
          id: content
          width: list.width
          spacing: Style.space(4)
          Text { visible: root.viewMode === "overview"; text: root.t.serversHeader; color: root.dim; font.family: root.fontFamily; font.bold: true }
          Repeater {
            model: root.viewMode === "overview" ? root.servers : []
            ItemRow { required property var modelData; required property int index; title: String(modelData.name || root.t.serverFallback); detail: String(modelData.ip || ""); healthy: modelData.is_reachable === true; selected: root.cursor === index; onChosen: { root.cursor = index; root.copySelected() } }
          }
          Text { visible: root.viewMode === "overview"; text: root.t.projectsHeader; color: root.dim; font.family: root.fontFamily; font.bold: true; topPadding: Style.space(8) }
          Repeater {
            model: root.viewMode === "overview" ? root.projects : []
            ItemRow { required property var modelData; required property int index; title: String(modelData.name || root.t.projectFallback); detail: Number((modelData.applications || []).length) + " " + root.t.appWord + " · " + Number((modelData.services || []).length || (modelData.counts || {}).services || 0) + " " + root.t.serviceWord + " · " + Number((modelData.databases || []).length || (modelData.counts || {}).databases || 0) + " " + root.t.dbWord; healthy: true; actionIcon: "󰅂"; selected: root.cursor === root.servers.length + index; onChosen: { root.cursor = root.servers.length + index; root.openProject(modelData) } }
          }
          Text { visible: root.viewMode === "apps" && root.projectResources.apps.length > 0; text: root.t.appsHeader; color: root.dim; font.family: root.fontFamily; font.bold: true }
          Repeater {
            model: root.viewMode === "apps" && root.selectedProject ? (root.selectedProject.applications || []) : []
            ItemRow {
              required property var modelData
              required property int index
              title: String(modelData.display_name || modelData.name || root.t.appFallback)
              detail: modelData.urls && modelData.urls.length > 0 ? modelData.urls.join(" · ") : root.t.noDomain
              healthy: String(modelData.status || "").indexOf("running:healthy") !== -1
              actionIcon: modelData.primary_url ? "󰖟" : "󰅙"
              selected: root.cursor === index
              onChosen: { root.cursor = index; root.openApplication(modelData) }
            }
          }
          Text { visible: root.viewMode === "apps" && root.projectResources.services.length > 0; text: root.t.servicesHeader; color: root.dim; font.family: root.fontFamily; font.bold: true; topPadding: Style.space(8) }
          Repeater {
            model: root.viewMode === "apps" && root.selectedProject ? (root.selectedProject.services || []) : []
            ItemRow {
              required property var modelData
              required property int index
              title: String(modelData.display_name || modelData.name || root.t.serviceWord)
              detail: String(modelData.status_label || "")
              healthy: String(modelData.status || "").indexOf("running:healthy") !== -1
              actionIcon: "󰅙"
              selected: root.cursor === root.projectResources.apps.length + index
              onChosen: { root.cursor = root.projectResources.apps.length + index; root.openApplication(modelData) }
            }
          }
          Text { visible: root.viewMode === "apps" && root.projectResources.databases.length > 0; text: root.t.databasesHeader; color: root.dim; font.family: root.fontFamily; font.bold: true; topPadding: Style.space(8) }
          Repeater {
            model: root.viewMode === "apps" && root.selectedProject ? (root.selectedProject.databases || []) : []
            ItemRow {
              required property var modelData
              required property int index
              title: String(modelData.display_name || modelData.name || root.t.dbWord)
              detail: String(modelData.type || modelData.status_label || "")
              healthy: String(modelData.status || "").indexOf("running:healthy") !== -1
              actionIcon: "󰅙"
              selected: root.cursor === root.projectResources.apps.length + root.projectResources.services.length + index
              onChosen: { root.cursor = root.projectResources.apps.length + root.projectResources.services.length + index; root.openApplication(modelData) }
            }
          }

        }
      }

      }

    Item {
      id: keys
      anchors.fill: parent
      focus: true
      Keys.onPressed: function(event) {
        if (root.settingsVisible) { root.handleSettingsKey(event); return }
        if (root.shortcutsVisible) {
          if (event.key === Qt.Key_Escape || event.text === "h" || event.key === Qt.Key_Left || event.text === "?") { root.hideShortcuts(); event.accepted = true }
          return
        }
        if (event.text === "?") { root.showShortcuts(); event.accepted = true }
        else if (event.key === Qt.Key_Escape || event.text === "h" || event.key === Qt.Key_Left) { root.goBack(); event.accepted = true }
        else if (event.text === "j" || event.key === Qt.Key_Down) { root.cursor = Math.min(root.itemCount - 1, root.cursor + 1); event.accepted = true }
        else if (event.text === "k" || event.key === Qt.Key_Up) { root.cursor = Math.max(0, root.cursor - 1); event.accepted = true }
        else if (event.text === "c") { root.copySelected(); event.accepted = true }
        else if (event.text === "r") { root.refresh(); event.accepted = true }
        else if (event.text === "o") { root.openSelected(); event.accepted = true }
        else if (event.text === "s") { root.beginSettings(); event.accepted = true }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Right) { root.activateSelected(); event.accepted = true }
      }
    }
    }
  }

  component ItemRow: Rectangle {
    id: row
    signal chosen()
    property string title: ""
    property string detail: ""
    property bool healthy: false
    property bool selected: false
    property string actionIcon: "󰆏"
    Layout.fillWidth: true
    implicitHeight: Style.space(52)
    radius: Style.cornerRadius
    color: selected ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.13) : (mouse.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07) : "transparent")
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: row.chosen() }
    RowLayout {
      anchors.fill: parent; anchors.leftMargin: Style.space(10); anchors.rightMargin: Style.space(10)
      Rectangle { width: Style.space(8); height: width; radius: width / 2; color: row.healthy ? "#22c55e" : "#ef4444" }
      ColumnLayout { Layout.fillWidth: true; spacing: 0; Text { Layout.fillWidth: true; text: row.title; color: root.foreground; font.family: root.fontFamily; elide: Text.ElideRight } Text { Layout.fillWidth: true; text: row.detail; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption; elide: Text.ElideRight } }
      Text { text: row.actionIcon; color: root.dim; font.family: root.fontFamily }
    }
  }
}
