#Requires AutoHotkey v2.0

/**
 * Painel principal do Picareta.
 *
 * No modo compacto, mostra apenas os comandos de uso frequente.
 * No modo expandido, exibe as configurações do sistema.
 */
class FloatingPanel
{
    static Window := false
    static Expanded := false
    static ConfigPath := ""
    static Hotkeys := false

    static ToggleMirrorCallback := false
    static FollowLeaderCallback := false
    static BuildPartyCallback := false
    static RebuildPartyCallback := false
    static ClearRegistrationsCallback := false
    static GetMulesCallback := false
    static GetLeaderCallback := false
    static ApplyHotkeysCallback := false
    static ReloadSettingsCallback := false

    static MirrorStatusText := false
    static MirrorToggleButton := false
    static ExpandButton := false

    static ConfigTabs := false
    static ConfigStatusText := false

    static HotkeyEdits := Map()
    static HotkeySetupNotice := false
    static HotkeySpecialLabels := [
        "Nenhum",
        "Botão do meio",
        "Lateral traseiro",
        "Lateral dianteiro",
        "Roda para cima",
        "Roda para baixo"
    ]
    static HotkeySpecialCodes := [
        "",
        "MButton",
        "XButton1",
        "XButton2",
        "WheelUp",
        "WheelDown"
    ]
    static GeneralEdits := Map()
    static ConfigStatusTexts := []

    static MuleSlotDDL := false
    static MuleNameEdit := false
    static MuleEdits := Map()
    static MuleConfigStatusText := false
    static LeaderRegistrationText := false
    static RegisteredMulesList := false

    static PartyPositionList := false
    static PartyPositionXEdit := false
    static PartyPositionYEdit := false
    static SelectedPartyPosition := 0

    static FollowActions := []
    static FollowList := false
    static EditingActionIndex := 0
    static ActionEnabledCheck := false
    static ActionMuleDDL := false
    static ActionTypeDDL := false
    static ActionButtonDDL := false
    static ActionXEdit := false
    static ActionYEdit := false
    static ActionKeyEdit := false
    static ActionDelayEdit := false
    static CaptureButton := false
    static FollowEditorStatus := false

    static HelpMouseMoveCallback := false
    static LastHelpHwnd := 0
    static PositionInitialized := false

    static Show(
        configPath,
        hotkeys,
        toggleMirrorCallback,
        followLeaderCallback,
        buildPartyCallback,
        rebuildPartyCallback,
        clearRegistrationsCallback,
        getMulesCallback,
        getLeaderCallback,
        applyHotkeysCallback,
        reloadSettingsCallback,
        mirrorEnabled := false
    )
    {
        this.ConfigPath := configPath
        this.Hotkeys := hotkeys
        this.ToggleMirrorCallback := toggleMirrorCallback
        this.FollowLeaderCallback := followLeaderCallback
        this.BuildPartyCallback := buildPartyCallback
        this.RebuildPartyCallback := rebuildPartyCallback
        this.ClearRegistrationsCallback := clearRegistrationsCallback
        this.GetMulesCallback := getMulesCallback
        this.GetLeaderCallback := getLeaderCallback
        this.ApplyHotkeysCallback := applyHotkeysCallback
        this.ReloadSettingsCallback := reloadSettingsCallback

        if this.Window
        {
            this.UpdateMirrorStatus(mirrorEnabled)
            this.RefreshRegistrationStatus()
            this.Window.Show("NoActivate")
            return
        }

        panel := Gui(
            "+AlwaysOnTop +ToolWindow",
            "Picareta"
        )

        panel.BackColor := "EEF4FA"
        panel.MarginX := 10
        panel.MarginY := 10
        panel.SetFont("s9", "Segoe UI")

        ; =====================================================
        ; ÁREA COMPACTA
        ; =====================================================

        panel.SetFont("s12 bold", "Segoe UI")
        panel.AddText(
            "x10 y10 w290 h34 Center 0x200 Background173B57 cFFFFFF",
            "PICARETA"
        )

        panel.SetFont("s9", "Segoe UI")
        this.ExpandButton := panel.AddButton(
            "x10 y52 w290 h30 -Wrap",
            "Abrir configurações  »"
        )
        this.ExpandButton.OnEvent(
            "Click",
            (*) => FloatingPanel.ToggleExpanded()
        )

        panel.SetFont("s9 bold", "Segoe UI")

        ; Static com SS_NOTIFY permite cor dinâmica e funciona como botão.
        this.MirrorToggleButton := panel.AddText(
            "x10 y94 w290 h34 Center 0x200 0x100 Border "
            . "BackgroundCBD5E1 c1E293B",
            "Espelhamento OFF"
        )
        this.MirrorToggleButton.OnEvent(
            "Click",
            (*) => FloatingPanel.ToggleMirrorCallback.Call()
        )

        mountButton := panel.AddText(
            "x10 y138 w142 h34 Center 0x200 0x100 Border "
            . "Background15803D cFFFFFF",
            "Montar PT"
        )
        mountButton.OnEvent(
            "Click",
            (*) => FloatingPanel.BuildPartyCallback.Call()
        )

        rebuildButton := panel.AddText(
            "x158 y138 w142 h34 Center 0x200 0x100 Border "
            . "BackgroundB45309 cFFFFFF",
            "Remontar PT"
        )
        rebuildButton.OnEvent(
            "Click",
            (*) => FloatingPanel.RebuildPartyCallback.Call()
        )

        followButton := panel.AddText(
            "x10 y182 w290 h36 Center 0x200 0x100 Border "
            . "Background0F766E cFFFFFF",
            "Seguir Lider"
        )
        followButton.OnEvent(
            "Click",
            (*) => FloatingPanel.FollowLeaderCallback.Call()
        )

        panel.SetFont("s8", "Segoe UI")
        panel.AddText(
            "x10 y230 w290 Center c64748B",
            "Arraste pela barra de título para mover"
        )

        ; =====================================================
        ; ÁREA EXPANDIDA
        ; =====================================================

        panel.SetFont("s9", "Segoe UI")
        this.ConfigTabs := panel.AddTab3(
            "x320 y10 w660 h625 -Wrap",
            ["Seguir líder", "Atalhos", "Montar PT", "Remontar PT", "Mulas"]
        )

        this.BuildFollowTab(panel)
        this.BuildHotkeysTab(panel)
        this.BuildPartySettingsTab(panel)
        this.BuildRebuildSettingsTab(panel)
        this.BuildMulesTab(panel)

        this.ConfigTabs.UseTab()

        panel.OnEvent(
            "Close",
            (guiObject, *) => guiObject.Hide()
        )

        this.Window := panel

        if !this.HelpMouseMoveCallback
        {
            this.HelpMouseMoveCallback := (
                wParam,
                lParam,
                msg,
                hwnd
            ) => FloatingPanel.HandleHelpMouseMove(
                wParam,
                lParam,
                msg,
                hwnd
            )
            OnMessage(0x0200, this.HelpMouseMoveCallback)
        }

        this.FollowActions := Configuration.LoadFollowActions(configPath)
        this.LoadHotkeyControls(hotkeys)
        this.LoadGeneralControls()
        this.LoadMuleControls(1)
        this.RefreshMuleChoices()
        this.RefreshActionList()
        this.RefreshRegistrationStatus()
        this.UpdateMirrorStatus(mirrorEnabled)

        if !Configuration.HasConfiguredHotkeys(configPath)
        {
            this.SetExpanded(true)
            this.ConfigTabs.Choose(2)
            this.HotkeySetupNotice.Text := "PRIMEIRA INICIALIZAÇÃO: escolha pelo menos um atalho e salve."
            this.HotkeySetupNotice.Opt("BackgroundFFF4CC c8A5700")
        }
        else
        {
            this.SetExpanded(false)
        }
    }

    static BuildFollowTab(panel)
    {
        this.ConfigTabs.UseTab("Seguir líder")

        panel.SetFont("s9", "Segoe UI")
        panel.AddText(
            "x340 y48 w610",
            "Configure a sequência executada pelo botão Seguir líder. "
            . "Cada item pertence a uma mula específica."
        )

        this.FollowList := panel.AddListView(
            "x340 y75 w620 h275 Grid -Multi",
            ["#", "Mula", "Tipo", "Ação", "X", "Y", "Tecla", "Delay", "Ativo"]
        )

        this.FollowList.ModifyCol(1, 32)
        this.FollowList.ModifyCol(2, 90)
        this.FollowList.ModifyCol(3, 58)
        this.FollowList.ModifyCol(4, 72)
        this.FollowList.ModifyCol(5, 45)
        this.FollowList.ModifyCol(6, 45)
        this.FollowList.ModifyCol(7, 85)
        this.FollowList.ModifyCol(8, 58)
        this.FollowList.ModifyCol(9, 50)

        this.FollowList.OnEvent(
            "ItemSelect",
            (ctrl, row, selected) => FloatingPanel.OnActionSelected(
                ctrl,
                row,
                selected
            )
        )

        newClickButton := panel.AddButton(
            "x340 y360 w105 h28",
            "Novo clique"
        )
        newClickButton.OnEvent(
            "Click",
            (*) => FloatingPanel.NewAction("Click")
        )

        newKeyButton := panel.AddButton(
            "x450 y360 w105 h28",
            "Nova tecla"
        )
        newKeyButton.OnEvent(
            "Click",
            (*) => FloatingPanel.NewAction("Key")
        )

        removeButton := panel.AddButton(
            "x560 y360 w90 h28",
            "Excluir"
        )
        removeButton.OnEvent(
            "Click",
            (*) => FloatingPanel.RemoveSelectedAction()
        )

        upButton := panel.AddButton(
            "x655 y360 w65 h28",
            "Subir"
        )
        upButton.OnEvent(
            "Click",
            (*) => FloatingPanel.MoveSelectedAction(-1)
        )

        downButton := panel.AddButton(
            "x725 y360 w65 h28",
            "Descer"
        )
        downButton.OnEvent(
            "Click",
            (*) => FloatingPanel.MoveSelectedAction(1)
        )

        generateButton := panel.AddButton(
            "x795 y360 w165 h28",
            "Gerar padrão das mulas"
        )
        generateButton.OnEvent(
            "Click",
            (*) => FloatingPanel.GenerateDefaultFollowActions()
        )

        panel.AddGroupBox(
            "x340 y400 w620 h170",
            "Editor do item"
        )

        this.ActionEnabledCheck := panel.AddCheckBox(
            "x355 y425 w80",
            "Ativo"
        )
        this.ActionEnabledCheck.Value := 1

        panel.AddText("x445 y428 w40", "Mula:")
        this.ActionMuleDDL := panel.AddDropDownList(
            "x485 y423 w135",
            Configuration.GetMuleChoices(this.ConfigPath)
        )
        this.ActionMuleDDL.Choose(1)

        panel.AddText("x630 y428 w35", "Tipo:")
        this.ActionTypeDDL := panel.AddDropDownList(
            "x668 y423 w95",
            ["Clique", "Tecla"]
        )
        this.ActionTypeDDL.Choose(1)
        this.ActionTypeDDL.OnEvent(
            "Change",
            (*) => FloatingPanel.UpdateActionTypeControls()
        )

        panel.AddText("x775 y428 w42", "Delay:")
        this.ActionDelayEdit := panel.AddEdit(
            "x820 y423 w70 Number",
            "150"
        )
        panel.AddText("x895 y428 w25", "ms")

        panel.AddText("x355 y468 w45", "Clique:")
        this.ActionButtonDDL := panel.AddDropDownList(
            "x402 y463 w105",
            ["Esquerdo", "Direito"]
        )
        this.ActionButtonDDL.Choose(1)

        panel.AddText("x520 y468 w15", "X:")
        this.ActionXEdit := panel.AddEdit(
            "x540 y463 w55 Number",
            "0"
        )

        panel.AddText("x605 y468 w15", "Y:")
        this.ActionYEdit := panel.AddEdit(
            "x625 y463 w55 Number",
            "0"
        )

        this.CaptureButton := panel.AddButton(
            "x690 y462 w125 h27",
            "Capturar posição"
        )
        this.CaptureButton.OnEvent(
            "Click",
            (*) => FloatingPanel.StartCoordinateCapture()
        )

        panel.AddText("x355 y510 w45", "Tecla:")
        this.ActionKeyEdit := panel.AddEdit(
            "x402 y505 w180",
            ""
        )
        panel.AddText(
            "x402 y535 w250 cGray",
            "Ex.: {F1}, 1, Tab ou Space"
        )

        saveItemButton := panel.AddButton(
            "x690 y503 w125 h30 Default",
            "Salvar item"
        )
        saveItemButton.OnEvent(
            "Click",
            (*) => FloatingPanel.SaveActionEditor()
        )

        this.FollowEditorStatus := panel.AddText(
            "x340 y582 w620 Center cGray",
            "Selecione um item para editar ou crie um novo."
        )
    }

    static BuildHotkeysTab(panel)
    {
        this.ConfigTabs.UseTab("Atalhos")

        panel.AddText(
            "x340 y45 w620 h28 Center 0x200 BackgroundDCEBFA c173B57",
            "ATALHOS DA PICARETA"
        )

        this.HotkeySetupNotice := panel.AddText(
            "x350 y80 w600 h34 Center 0x200 BackgroundE8F1FB c173B57",
            "Clique em um campo e pressione a combinação desejada."
        )

        fields := [
            ["RegisterLeader", "Cadastrar principal"],
            ["RegisterMule", "Cadastrar mula"],
            ["NextWindow", "Alternar janela"],
            ["ShowStatus", "Mostrar status"],
            ["BuildParty", "Montar PT"],
            ["RebuildParty", "Remontar PT"],
            ["ToggleMirror", "Alternar espelhamento"],
            ["ClearRegistrations", "Limpar cadastros"],
            ["ExitController", "Fechar Picareta"]
        ]

        for index, field in fields
        {
            column := index <= 5 ? 0 : 1
            row := column = 0 ? index - 1 : index - 6
            x := column = 0 ? 350 : 660
            fieldY := 125 + (row * 58)
            propertyName := field[1]

            panel.AddText(
                "x" x " y" fieldY " w285 c334155",
                field[2]
            )

            keyboard := panel.AddHotkey(
                "x" x " y" (fieldY + 20) " w130",
                ""
            )

            special := panel.AddDropDownList(
                "x" (x + 135) " y" (fieldY + 19) " w110",
                this.HotkeySpecialLabels
            )
            special.Choose(1)

            winCheck := panel.AddCheckBox(
                "x" (x + 250) " y" (fieldY + 22) " w45",
                "Win"
            )

            keyboard.OnEvent(
                "Change",
                this.CreateKeyboardHotkeyCallback(propertyName)
            )
            special.OnEvent(
                "Change",
                this.CreateSpecialHotkeyCallback(propertyName)
            )

            this.HotkeyEdits[propertyName] := {
                Keyboard: keyboard,
                Special: special,
                Win: winCheck
            }
        }

        saveButton := panel.AddButton(
            "x700 y375 w210 h34 Default -Wrap",
            "Salvar e aplicar atalhos"
        )
        saveButton.OnEvent(
            "Click",
            (*) => FloatingPanel.SaveHotkeys()
        )

        panel.AddText(
            "x350 y430 w590 h105 0x200 BackgroundF8FAFC c334155",
            "COMO CONFIGURAR:`n"
            . "• Teclado: clique no campo branco e pressione a tecla ou combinação.`n"
            . "• Mouse/roda: selecione a opção na caixa ao lado.`n"
            . "• Tecla Windows: marque Win e escolha a tecla ou botão.`n"
            . "• Para remover um atalho, apague o campo e selecione Nenhum."
        )

        status := panel.AddText(
            "x350 y565 w590 Center c15803D",
            ""
        )
        this.ConfigStatusTexts.Push(status)
    }

    static BuildPartySettingsTab(panel)
    {
        this.ConfigTabs.UseTab("Montar PT")

        panel.AddText(
            "x340 y45 w620 h28 Center 0x200 BackgroundDCFCE7 c166534",
            "CONFIGURAÇÃO DA MONTAGEM DE PT — CAPTURA NO PERSONAGEM PRINCIPAL"
        )

        panel.AddGroupBox(
            "x365 y90 w570 h445",
            "Convites e aceites"
        )

        this.AddGeneralCoordinatePair(
            panel,
            390,
            125,
            "Notificação para aceitar convite",
            "NotificationX",
            "NotificationY",
            "Capture o local do aviso de convite. A mesma posição é usada nas janelas das mulas.",
            500
        )

        this.AddGeneralNumberField(
            panel,
            390,
            225,
            "Delay entre convites",
            "InviteDelay",
            "Tempo de espera entre convidar uma mula e a próxima.",
            "ms",
            500
        )

        this.AddGeneralNumberField(
            panel,
            390,
            310,
            "Espera antes dos aceites",
            "BeforeAcceptDelay",
            "Tempo após o último convite antes de começar a aceitar nas mulas.",
            "ms",
            500
        )

        this.AddGeneralNumberField(
            panel,
            390,
            395,
            "Delay entre aceites",
            "AcceptDelay",
            "Tempo entre aceitar o convite de uma mula e o da próxima.",
            "ms",
            500
        )

        saveButton := panel.AddButton(
            "x535 y555 w230 h34 Default -Wrap",
            "Salvar configuração de montagem"
        )
        saveButton.OnEvent(
            "Click",
            (*) => FloatingPanel.SaveGeneralSettings()
        )

        status := panel.AddText(
            "x350 y603 w600 Center c15803D",
            ""
        )
        this.ConfigStatusTexts.Push(status)
    }

    static BuildRebuildSettingsTab(panel)
    {
        this.ConfigTabs.UseTab("Remontar PT")

        panel.AddText(
            "x340 y45 w620 h28 Center 0x200 BackgroundFFEDD5 c9A3412",
            "CONFIGURAÇÃO DA REMONTAGEM DE PT — CAPTURA NO PERSONAGEM PRINCIPAL"
        )

        panel.AddGroupBox(
            "x340 y82 w300 h475",
            "Botões e delays"
        )

        this.AddGeneralCoordinatePair(
            panel,
            355,
            112,
            "Botão Expulsar",
            "KickX",
            "KickY",
            "Selecione um membro na lista da PT e capture o botão usado para expulsá-lo.",
            260
        )

        this.AddGeneralCoordinatePair(
            panel,
            355,
            182,
            "Botão Transferir liderança",
            "TransferLeaderX",
            "TransferLeaderY",
            "Selecione um membro e capture o botão que transfere a liderança.",
            260
        )

        this.AddGeneralCoordinatePair(
            panel,
            355,
            252,
            "Botão Sair da PT",
            "LeavePartyX",
            "LeavePartyY",
            "Capture o botão usado pelo personagem principal para sair da PT.",
            260
        )

        this.AddGeneralNumberField(
            panel, 355, 330, "Selecionar membro", "PartySelectDelay",
            "Tempo entre selecionar a posição na PT e clicar no botão da ação.", "ms", 125
        )
        this.AddGeneralNumberField(
            panel, 495, 330, "Após expulsar", "PartyKickDelay",
            "Tempo para o jogo processar a expulsão.", "ms", 125
        )
        this.AddGeneralNumberField(
            panel, 355, 405, "Após transferir", "PartyTransferDelay",
            "Tempo após transferir a liderança.", "ms", 125
        )
        this.AddGeneralNumberField(
            panel, 495, 405, "Antes de sair", "PartyBeforeLeaveDelay",
            "Espera antes de o principal sair da PT.", "ms", 125
        )
        this.AddGeneralNumberField(
            panel, 355, 480, "Após sair", "PartyLeaveDelay",
            "Tempo após clicar em Sair da PT.", "ms", 125
        )

        panel.AddGroupBox(
            "x650 y82 w305 h475",
            "Posições fixas da lista da PT"
        )

        helpPositions := panel.AddButton(
            "x915 y90 w26 h24",
            "?"
        )
        this.RegisterHelpControl(
            helpPositions,
            "As posições pertencem às linhas da lista da PT, não aos nomes das mulas. "
            . "A Mula 1 usa a posição 1, a Mula 2 usa a posição 2 e assim por diante. "
            . "A remontagem continua expulsando da última posição usada para a primeira."
        )

        this.PartyPositionList := panel.AddListView(
            "x665 y118 w275 h270 Grid -Multi",
            ["Posição", "X", "Y", "Situação"]
        )
        this.PartyPositionList.ModifyCol(1, 58)
        this.PartyPositionList.ModifyCol(2, 55)
        this.PartyPositionList.ModifyCol(3, 55)
        this.PartyPositionList.ModifyCol(4, 90)
        this.PartyPositionList.OnEvent(
            "ItemSelect",
            (ctrl, row, selected) => FloatingPanel.OnPartyPositionSelected(
                ctrl,
                row,
                selected
            )
        )

        ; Controles ocultos mantêm os dez pares dentro do mesmo fluxo de salvamento.
        Loop 10
        {
            xKey := "PartyPosition" A_Index "X"
            yKey := "PartyPosition" A_Index "Y"
            this.GeneralEdits[xKey] := panel.AddEdit("Hidden", "0")
            this.GeneralEdits[yKey] := panel.AddEdit("Hidden", "0")
        }

        panel.AddText("x665 y405 w18", "X:")
        this.PartyPositionXEdit := panel.AddEdit(
            "x685 y400 w65 Number",
            "0"
        )
        panel.AddText("x760 y405 w18", "Y:")
        this.PartyPositionYEdit := panel.AddEdit(
            "x780 y400 w65 Number",
            "0"
        )

        capturePosition := panel.AddButton(
            "x855 y399 w85 h28 -Wrap",
            "Capturar"
        )
        capturePosition.OnEvent(
            "Click",
            (*) => FloatingPanel.StartPartyPositionCapture()
        )

        applyPosition := panel.AddButton(
            "x665 y440 w275 h30 -Wrap",
            "Aplicar valores à posição selecionada"
        )
        applyPosition.OnEvent(
            "Click",
            (*) => FloatingPanel.SavePartyPositionEditor(true)
        )

        saveButton := panel.AddButton(
            "x680 y505 w245 h34 Default -Wrap",
            "Salvar configuração de remontagem"
        )
        saveButton.OnEvent(
            "Click",
            (*) => FloatingPanel.SaveGeneralSettings()
        )

        status := panel.AddText(
            "x350 y603 w600 Center c15803D",
            ""
        )
        this.ConfigStatusTexts.Push(status)
    }

    static BuildMulesTab(panel)
    {
        this.ConfigTabs.UseTab("Mulas")

        panel.AddText(
            "x340 y45 w620 h28 Center 0x200 BackgroundE0E7FF c3730A3",
            "CONFIGURAÇÃO DAS MULAS — CAPTURAS FEITAS NO PERSONAGEM PRINCIPAL"
        )

        panel.AddText("x340 y84 w110", "Mula configurada:")
        this.MuleSlotDDL := panel.AddDropDownList(
            "x455 y79 w260",
            Configuration.GetMuleChoices(this.ConfigPath)
        )
        this.MuleSlotDDL.Choose(1)
        this.MuleSlotDDL.OnEvent(
            "Change",
            (*) => FloatingPanel.LoadMuleControls(
                FloatingPanel.MuleSlotDDL.Value
            )
        )

        this.MuleConfigStatusText := panel.AddText(
            "x735 y84 w210 Center",
            ""
        )

        panel.AddGroupBox(
            "x340 y115 w390 h365",
            "Dados e coordenadas"
        )

        panel.AddText("x365 y150 w80", "Nome:")
        this.MuleNameEdit := panel.AddEdit(
            "x450 y145 w220",
            ""
        )
        helpName := panel.AddButton("x685 y144 w28 h25", "?")
        this.RegisterHelpControl(
            helpName,
            "Informe o nome do personagem correspondente a esta posição. "
            . "As mulas devem ser configuradas e cadastradas na mesma ordem."
        )

        this.AddMuleCoordinatePair(
            panel,
            365,
            205,
            "Posição na lista de amigos",
            "FriendX",
            "FriendY",
            "Capture em cima do nome desta mula na lista de amigos do personagem principal."
        )

        this.AddMuleCoordinatePair(
            panel,
            365,
            300,
            "Opção Convidar do menu",
            "InviteX",
            "InviteY",
            "Abra o menu com o botão direito no nome da mula e capture a opção Convidar."
        )

        saveButton := panel.AddButton(
            "x440 y425 w230 h34 Default -Wrap",
            "Salvar dados da mula"
        )
        saveButton.OnEvent(
            "Click",
            (*) => FloatingPanel.SaveMuleSettings()
        )

        panel.AddGroupBox(
            "x745 y115 w210 h365",
            "Janelas desta sessão"
        )

        this.LeaderRegistrationText := panel.AddText(
            "x760 y145 w180 Center c64748B",
            "Principal: não cadastrado"
        )

        this.RegisteredMulesList := panel.AddListView(
            "x758 y180 w184 h210 Grid -Multi",
            ["#", "Nome", "Janela"]
        )
        this.RegisteredMulesList.ModifyCol(1, 28)
        this.RegisteredMulesList.ModifyCol(2, 90)
        this.RegisteredMulesList.ModifyCol(3, 60)

        panel.SetFont("s8", "Segoe UI")
        refreshButton := panel.AddButton(
            "x758 y405 w88 h32 -Wrap",
            "Atualizar"
        )
        refreshButton.OnEvent(
            "Click",
            (*) => FloatingPanel.RefreshRegistrationStatus()
        )

        clearButton := panel.AddButton(
            "x852 y405 w90 h32 -Wrap",
            "Limpar cadastros"
        )
        clearButton.OnEvent(
            "Click",
            (*) => FloatingPanel.ClearSessionRegistrations()
        )
        panel.SetFont("s9", "Segoe UI")

        panel.AddText(
            "x340 y510 w610 c64748B",
            "Nome e coordenadas ficam salvos no Characters.ini. As janelas cadastradas "
            . "valem somente enquanto a Picareta estiver aberta."
        )

        status := panel.AddText(
            "x350 y565 w590 Center c15803D",
            ""
        )
        this.ConfigStatusTexts.Push(status)
    }

    static ToggleExpanded()
    {
        this.SetExpanded(!this.Expanded)
    }

    static SetExpanded(expanded)
    {
        compactWidth := 310
        compactHeight := 262
        expandedWidth := 990
        expandedHeight := 650

        targetWidth := expanded ? expandedWidth : compactWidth
        targetHeight := expanded ? expandedHeight : compactHeight

        if !this.PositionInitialized
        {
            try
            {
                primary := MonitorGetPrimary()
                MonitorGetWorkArea(primary, &left, &top, &right, &bottom)
            }
            catch
            {
                left := 0
                top := 0
                right := A_ScreenWidth
                bottom := A_ScreenHeight
            }

            rightEdge := right - 20
            currentY := top + 50
            this.PositionInitialized := true
        }
        else
        {
            this.Window.GetPos(&currentX, &currentY, &currentWidth, &currentHeight)
            rightEdge := currentX + currentWidth
            this.GetWorkAreaForPoint(
                currentX + (currentWidth / 2),
                currentY + 20,
                &left,
                &top,
                &right,
                &bottom
            )
        }

        targetX := rightEdge - targetWidth

        if targetX < left
            targetX := left

        if targetX + targetWidth > right
            targetX := right - targetWidth

        if currentY < top
            currentY := top

        if currentY + targetHeight > bottom
            currentY := Max(top, bottom - targetHeight)

        this.Expanded := expanded
        this.ExpandButton.Text := expanded
            ? "Recolher configurações  «"
            : "Abrir configurações  »"

        this.Window.Show(
            "x" targetX
            . " y" currentY
            . " w" targetWidth
            . " h" targetHeight
        )
    }

    static UpdateMirrorStatus(enabled)
    {
        if !this.MirrorToggleButton
            return

        if enabled
        {
            this.MirrorToggleButton.Text := "Espelhamento ON"
            this.MirrorToggleButton.Opt(
                "Background2563EB cFFFFFF"
            )
        }
        else
        {
            this.MirrorToggleButton.Text := "Espelhamento OFF"
            this.MirrorToggleButton.Opt(
                "BackgroundCBD5E1 c1E293B"
            )
        }
    }

    static LoadHotkeyControls(hotkeys)
    {
        for propertyName, controls in this.HotkeyEdits
        {
            value := Trim(hotkeys.%propertyName%)
            hasWin := InStr(value, "#") > 0
            value := StrReplace(value, "#")

            controls.Win.Value := hasWin ? 1 : 0
            specialIndex := this.FindSpecialHotkeyIndex(value)

            if specialIndex > 1
            {
                controls.Keyboard.Value := ""
                controls.Special.Choose(specialIndex)
            }
            else
            {
                controls.Special.Choose(1)
                try
                    controls.Keyboard.Value := value
                catch
                    controls.Keyboard.Value := ""
            }
        }
    }

    static SaveHotkeys()
    {
        hotkeys := {
            RegisterLeader: this.GetHotkeyControlValue("RegisterLeader"),
            RegisterMule: this.GetHotkeyControlValue("RegisterMule"),
            NextWindow: this.GetHotkeyControlValue("NextWindow"),
            ShowStatus: this.GetHotkeyControlValue("ShowStatus"),
            BuildParty: this.GetHotkeyControlValue("BuildParty"),
            RebuildParty: this.GetHotkeyControlValue("RebuildParty"),
            ToggleMirror: this.GetHotkeyControlValue("ToggleMirror"),
            ClearRegistrations: this.GetHotkeyControlValue("ClearRegistrations"),
            ExitController: this.GetHotkeyControlValue("ExitController")
        }

        if !Configuration.SaveHotkeys(this.ConfigPath, hotkeys)
            return

        if this.ApplyHotkeysCallback
        {
            if !this.ApplyHotkeysCallback.Call(hotkeys)
                return
        }

        this.Hotkeys := hotkeys
        this.HotkeySetupNotice.Text := "Atalhos salvos e aplicados nesta sessão."
        this.HotkeySetupNotice.Opt("BackgroundDCFCE7 c15803D")
        this.ShowConfigStatus("Atalhos salvos e aplicados.")
    }

    static LoadGeneralControls()
    {
        values := Configuration.LoadGeneralEditor(this.ConfigPath)

        for propertyName, edit in this.GeneralEdits
            edit.Value := values.%propertyName%

        this.RefreshPartyPositionList(1)
        this.LoadPartyPositionEditor(1)
    }

    static SaveGeneralSettings()
    {
        if this.SelectedPartyPosition > 0
        {
            if !this.SavePartyPositionEditor(false)
                return
        }

        values := {}

        for propertyName, edit in this.GeneralEdits
            values.%propertyName% := Trim(edit.Value)

        if !Configuration.SaveGeneralEditor(this.ConfigPath, values)
            return

        if this.ReloadSettingsCallback
            this.ReloadSettingsCallback.Call()

        this.RefreshPartyPositionList(this.SelectedPartyPosition)
        this.ShowConfigStatus("Configurações salvas e aplicadas.")
    }

    static LoadMuleControls(slot)
    {
        if slot < 1
            slot := 1

        values := Configuration.LoadMuleEditor(
            this.ConfigPath,
            slot
        )

        this.MuleNameEdit.Value := values.Name

        for propertyName, edit in this.MuleEdits
            edit.Value := values.%propertyName%

        if this.MuleConfigStatusText
        {
            if Configuration.IsMuleConfigured(this.ConfigPath, slot)
            {
                this.MuleConfigStatusText.Text := "Configuração completa"
                this.MuleConfigStatusText.Opt("c15803D")
            }
            else
            {
                this.MuleConfigStatusText.Text := "Configuração pendente"
                this.MuleConfigStatusText.Opt("cB45309")
            }
        }
    }

    static SaveMuleSettings()
    {
        slot := this.MuleSlotDDL.Value
        values := {Name: Trim(this.MuleNameEdit.Value)}

        for propertyName, edit in this.MuleEdits
            values.%propertyName% := Trim(edit.Value)

        if !Configuration.SaveMuleEditor(
            this.ConfigPath,
            slot,
            values
        )
        {
            return
        }

        this.RefreshMuleChoices(slot)
        this.LoadMuleControls(slot)
        this.RefreshActionList()
        this.RefreshRegistrationStatus()
        this.ShowConfigStatus(
            "Dados da Mula " slot " salvos."
        )
    }

    static RefreshMuleChoices(selectedSlot := 1)
    {
        choices := Configuration.GetMuleChoices(this.ConfigPath)

        if this.MuleSlotDDL
        {
            this.MuleSlotDDL.Delete()
            this.MuleSlotDDL.Add(choices)
            this.MuleSlotDDL.Choose(selectedSlot)
        }

        if this.ActionMuleDDL
        {
            actionSlot := this.ActionMuleDDL.Value

            if actionSlot < 1
                actionSlot := 1

            this.ActionMuleDDL.Delete()
            this.ActionMuleDDL.Add(choices)
            this.ActionMuleDDL.Choose(actionSlot)
        }
    }

    static NewAction(type)
    {
        this.EditingActionIndex := 0
        this.ActionEnabledCheck.Value := 1
        this.ActionTypeDDL.Choose(type = "Key" ? 2 : 1)
        this.ActionButtonDDL.Choose(type = "Click" ? 1 : 1)
        this.ActionXEdit.Value := 0
        this.ActionYEdit.Value := 0
        this.ActionKeyEdit.Value := ""
        this.ActionDelayEdit.Value := 150
        this.UpdateActionTypeControls()
        this.FollowEditorStatus.Text := "Novo item: preencha os campos e clique em Salvar item."
    }

    static OnActionSelected(ctrl, row, selected)
    {
        if !selected || row < 1 || row > this.FollowActions.Length
            return

        this.LoadActionIntoEditor(row)
    }

    static LoadActionIntoEditor(index)
    {
        action := this.FollowActions[index]
        this.EditingActionIndex := index
        this.ActionEnabledCheck.Value := action.Enabled ? 1 : 0
        this.ActionMuleDDL.Choose(action.MuleSlot)
        this.ActionTypeDDL.Choose(
            StrLower(action.Type) = "key" ? 2 : 1
        )
        this.ActionButtonDDL.Choose(
            StrLower(action.Button) = "right" ? 2 : 1
        )
        this.ActionXEdit.Value := action.X
        this.ActionYEdit.Value := action.Y
        this.ActionKeyEdit.Value := action.Key
        this.ActionDelayEdit.Value := action.Delay
        this.UpdateActionTypeControls()
        this.FollowEditorStatus.Text := "Editando o item " index "."
    }

    static UpdateActionTypeControls()
    {
        isClick := this.ActionTypeDDL.Value = 1

        this.ActionButtonDDL.Enabled := isClick
        this.ActionXEdit.Enabled := isClick
        this.ActionYEdit.Enabled := isClick
        this.CaptureButton.Enabled := isClick
        this.ActionKeyEdit.Enabled := !isClick
    }

    static SaveActionEditor()
    {
        muleSlot := this.ActionMuleDDL.Value
        actionType := this.ActionTypeDDL.Value = 2
            ? "Key"
            : "Click"
        button := this.ActionButtonDDL.Value = 2
            ? "Right"
            : "Left"
        delay := Trim(this.ActionDelayEdit.Value)

        if muleSlot < 1 || muleSlot > 9
        {
            PicaretaDialog("Selecione uma mula válida.", "Picareta")
            return
        }

        if !IsNumber(delay) || Integer(delay) < 0
        {
            PicaretaDialog(
                "O delay deve ser um número inteiro maior ou igual a zero.",
                "Picareta"
            )
            return
        }

        x := Trim(this.ActionXEdit.Value)
        y := Trim(this.ActionYEdit.Value)
        key := Trim(this.ActionKeyEdit.Value)

        if actionType = "Click"
        {
            if !IsNumber(x) || !IsNumber(y)
            {
                PicaretaDialog(
                    "As coordenadas X e Y devem ser números inteiros.",
                    "Picareta"
                )
                return
            }
        }
        else if key = ""
        {
            PicaretaDialog(
                "Informe a tecla que será enviada.",
                "Picareta"
            )
            return
        }

        action := {
            Enabled: this.ActionEnabledCheck.Value = 1,
            MuleSlot: muleSlot,
            Type: actionType,
            Button: button,
            X: IsNumber(x) ? Integer(x) : 0,
            Y: IsNumber(y) ? Integer(y) : 0,
            Key: key,
            Delay: Integer(delay)
        }

        if this.EditingActionIndex > 0
        {
            savedIndex := this.EditingActionIndex
            this.FollowActions[savedIndex] := action
        }
        else
        {
            this.FollowActions.Push(action)
            savedIndex := this.FollowActions.Length
        }

        Configuration.SaveFollowActions(
            this.ConfigPath,
            this.FollowActions
        )

        this.RefreshActionList(savedIndex)
        this.LoadActionIntoEditor(savedIndex)
        this.FollowEditorStatus.Text := "Item salvo e aplicado à sequência."
    }

    static RemoveSelectedAction()
    {
        row := this.FollowList.GetNext(0)

        if row = 0
        {
            PicaretaDialog(
                "Selecione um item para excluir.",
                "Picareta"
            )
            return
        }

        this.FollowActions.RemoveAt(row)
        Configuration.SaveFollowActions(
            this.ConfigPath,
            this.FollowActions
        )

        this.EditingActionIndex := 0
        this.RefreshActionList()
        this.NewAction("Click")
        this.FollowEditorStatus.Text := "Item excluído da sequência."
    }

    static MoveSelectedAction(direction)
    {
        row := this.FollowList.GetNext(0)

        if row = 0
            return

        target := row + direction

        if target < 1 || target > this.FollowActions.Length
            return

        temporary := this.FollowActions[row]
        this.FollowActions[row] := this.FollowActions[target]
        this.FollowActions[target] := temporary

        Configuration.SaveFollowActions(
            this.ConfigPath,
            this.FollowActions
        )

        this.RefreshActionList(target)
        this.LoadActionIntoEditor(target)
    }

    static RefreshActionList(selectedIndex := 0)
    {
        if !this.FollowList
            return

        this.FollowList.Delete()
        muleChoices := Configuration.GetMuleChoices(this.ConfigPath)

        for index, action in this.FollowActions
        {
            muleName := action.MuleSlot >= 1
                && action.MuleSlot <= muleChoices.Length
                ? muleChoices[action.MuleSlot]
                : "Mula " action.MuleSlot

            typeText := StrLower(action.Type) = "key"
                ? "Tecla"
                : "Clique"

            actionText := ""

            if typeText = "Clique"
            {
                actionText := StrLower(action.Button) = "right"
                    ? "Direito"
                    : "Esquerdo"
            }

            this.FollowList.Add(
                "",
                index,
                muleName,
                typeText,
                actionText,
                action.X,
                action.Y,
                action.Key,
                action.Delay,
                action.Enabled ? "Sim" : "Não"
            )
        }

        if selectedIndex > 0
            this.FollowList.Modify(
                selectedIndex,
                "Select Focus Vis"
            )
    }

    static StartCoordinateCapture()
    {
        if this.ActionTypeDDL.Value != 1
        {
            PicaretaDialog(
                "A captura de posição está disponível apenas para cliques.",
                "Picareta"
            )
            return
        }

        muleSlot := this.ActionMuleDDL.Value
        mules := this.GetMulesCallback.Call()

        if muleSlot < 1 || muleSlot > mules.Length
        {
            PicaretaDialog(
                "A Mula " muleSlot " ainda não está cadastrada nesta sessão.`n`n"
                . "Cadastre a mula antes de capturar a coordenada.",
                "Picareta"
            )
            return
        }

        targetHwnd := mules[muleSlot].Hwnd
        this.Window.Hide()

        started := CoordinateCapture.Start(
            targetHwnd,
            (x, y) => FloatingPanel.ApplyCapturedCoordinates(x, y),
            (*) => FloatingPanel.RestoreAfterCapture()
        )

        if !started
            this.RestoreAfterCapture()
    }

    static ApplyCapturedCoordinates(x, y)
    {
        this.ActionXEdit.Value := x
        this.ActionYEdit.Value := y
        this.RestoreAfterCapture()
        this.FollowEditorStatus.Text := "Coordenada capturada: X=" x " Y=" y "."
    }

    static RestoreAfterCapture()
    {
        this.SetExpanded(true)
    }

    static GenerateDefaultFollowActions()
    {
        if this.Window
            this.Window.Opt("+OwnDialogs")

        mules := this.GetMulesCallback.Call()

        if mules.Length = 0
        {
            PicaretaDialog(
                "Cadastre as mulas antes de gerar a sequência padrão.",
                "Picareta"
            )
            return
        }

        if !this.Confirm(
            "Isso substituirá a sequência atual por dois cliques para cada "
            . "mula cadastrada.`n`nDeseja continuar?",
            "Gerar sequência padrão"
        )
        {
            return
        }

        menuX := IniRead(this.ConfigPath, "General", "FollowMenuX", 20)
        menuY := IniRead(this.ConfigPath, "General", "FollowMenuY", 205)
        optionX := IniRead(this.ConfigPath, "General", "FollowOptionX", 60)
        optionY := IniRead(this.ConfigPath, "General", "FollowOptionY", 245)
        menuDelay := IniRead(this.ConfigPath, "General", "FollowMenuDelay", 150)
        muleDelay := IniRead(this.ConfigPath, "General", "FollowMuleDelay", 150)

        this.FollowActions := PartyFollow.BuildLegacyActions(
            mules,
            menuX,
            menuY,
            optionX,
            optionY,
            menuDelay,
            muleDelay
        )

        Configuration.SaveFollowActions(
            this.ConfigPath,
            this.FollowActions
        )

        this.RefreshActionList(1)
        this.LoadActionIntoEditor(1)
        this.FollowEditorStatus.Text := "Sequência padrão criada para " mules.Length " mula(s)."
    }

    static AddGeneralCoordinatePair(
        panel,
        x,
        y,
        title,
        xKey,
        yKey,
        helpText,
        width
    )
    {
        panel.AddText(
            "x" x " y" y " w" (width - 35) " c334155",
            title
        )

        helpButton := panel.AddButton(
            "x" (x + width - 28) " y" (y - 3) " w26 h24",
            "?"
        )
        this.RegisterHelpControl(helpButton, helpText)

        panel.AddText("x" x " y" (y + 31) " w15", "X:")
        xEdit := panel.AddEdit(
            "x" (x + 20) " y" (y + 26) " w55 Number",
            "0"
        )
        this.GeneralEdits[xKey] := xEdit

        panel.AddText("x" (x + 82) " y" (y + 31) " w15", "Y:")
        yEdit := panel.AddEdit(
            "x" (x + 102) " y" (y + 26) " w55 Number",
            "0"
        )
        this.GeneralEdits[yKey] := yEdit

        captureWidth := Max(78, width - 165)
        captureButton := panel.AddButton(
            "x" (x + 165) " y" (y + 25) " w" captureWidth " h27 -Wrap",
            "Capturar"
        )
        captureButton.OnEvent(
            "Click",
            (*) => FloatingPanel.StartLeaderCoordinateCapture(
                xEdit,
                yEdit,
                title
            )
        )
    }

    static AddGeneralNumberField(
        panel,
        x,
        y,
        title,
        key,
        helpText,
        unit,
        width
    )
    {
        panel.SetFont(width <= 130 ? "s8" : "s9", "Segoe UI")
        panel.AddText(
            "x" x " y" y " w" (width - 35) " c334155",
            title
        )

        helpButton := panel.AddButton(
            "x" (x + width - 28) " y" (y - 3) " w26 h24",
            "?"
        )
        this.RegisterHelpControl(helpButton, helpText)

        edit := panel.AddEdit(
            "x" x " y" (y + 23) " w75 Number",
            "0"
        )
        this.GeneralEdits[key] := edit
        panel.AddText(
            "x" (x + 82) " y" (y + 28) " w35",
            unit
        )
        panel.SetFont("s9", "Segoe UI")
    }

    static AddMuleCoordinatePair(
        panel,
        x,
        y,
        title,
        xKey,
        yKey,
        helpText
    )
    {
        panel.AddText(
            "x" x " y" y " w285 c334155",
            title
        )

        helpButton := panel.AddButton(
            "x685 y" (y - 3) " w28 h25",
            "?"
        )
        this.RegisterHelpControl(helpButton, helpText)

        panel.AddText("x" x " y" (y + 34) " w15", "X:")
        xEdit := panel.AddEdit(
            "x" (x + 20) " y" (y + 29) " w65 Number",
            "0"
        )
        this.MuleEdits[xKey] := xEdit

        panel.AddText("x" (x + 98) " y" (y + 34) " w15", "Y:")
        yEdit := panel.AddEdit(
            "x" (x + 118) " y" (y + 29) " w65 Number",
            "0"
        )
        this.MuleEdits[yKey] := yEdit

        captureButton := panel.AddButton(
            "x" (x + 195) " y" (y + 28) " w125 h28 -Wrap",
            "Capturar no principal"
        )
        captureButton.OnEvent(
            "Click",
            (*) => FloatingPanel.StartLeaderCoordinateCapture(
                xEdit,
                yEdit,
                title
            )
        )
    }

    static StartLeaderCoordinateCapture(
        xEdit,
        yEdit,
        description,
        *
    )
    {
        if !this.GetLeaderCallback
        {
            PicaretaDialog(
                "O acesso ao personagem principal não está disponível.",
                "Picareta"
            )
            return
        }

        leaderHwnd := this.GetLeaderCallback.Call()

        if !leaderHwnd || !PWWindows.IsOpen(leaderHwnd)
        {
            PicaretaDialog(
                "Cadastre e mantenha aberta a janela do personagem principal "
                . "antes de capturar coordenadas.",
                "Picareta"
            )
            return
        }

        this.Window.Hide()

        captureCallback := (capturedX, capturedY) => FloatingPanel.ApplyLeaderCapturedCoordinates(
            xEdit,
            yEdit,
            description,
            capturedX,
            capturedY
        )

        started := CoordinateCapture.Start(
            leaderHwnd,
            captureCallback,
            (*) => FloatingPanel.RestoreAfterCapture()
        )

        if !started
            this.RestoreAfterCapture()
    }

    static ApplyLeaderCapturedCoordinates(
        xEdit,
        yEdit,
        description,
        x,
        y
    )
    {
        xEdit.Value := x
        yEdit.Value := y
        this.RestoreAfterCapture()
        this.ShowConfigStatus(
            description ": X=" x " Y=" y "."
        )
    }

    static RefreshRegistrationStatus()
    {
        if this.LeaderRegistrationText && this.GetLeaderCallback
        {
            leaderHwnd := this.GetLeaderCallback.Call()

            if leaderHwnd && PWWindows.IsOpen(leaderHwnd)
            {
                this.LeaderRegistrationText.Text := "Principal: cadastrado"
                this.LeaderRegistrationText.Opt("c15803D")
            }
            else if leaderHwnd
            {
                this.LeaderRegistrationText.Text := "Principal: janela fechada"
                this.LeaderRegistrationText.Opt("cB91C1C")
            }
            else
            {
                this.LeaderRegistrationText.Text := "Principal: não cadastrado"
                this.LeaderRegistrationText.Opt("c64748B")
            }
        }

        if !this.RegisteredMulesList || !this.GetMulesCallback
            return

        this.RegisteredMulesList.Delete()
        mules := this.GetMulesCallback.Call()

        if mules.Length = 0
        {
            this.RegisteredMulesList.Add("", "-", "Nenhuma", "-")
            return
        }

        for index, mule in mules
        {
            status := PWWindows.IsOpen(mule.Hwnd)
                ? "Aberta"
                : "Fechada"

            this.RegisteredMulesList.Add(
                "",
                mule.HasOwnProp("Slot") ? mule.Slot : index,
                mule.Name,
                status
            )
        }
    }

    static OpenMulesTab(slot := 1)
    {
        if !this.Window
            return

        if slot < 1 || slot > 9
            slot := 1

        this.SetExpanded(true)
        this.ConfigTabs.Choose(5)
        this.MuleSlotDDL.Choose(slot)
        this.LoadMuleControls(slot)
        this.RefreshRegistrationStatus()
        this.Window.Show()
    }

    static OpenHotkeysTab()
    {
        if !this.Window
            return

        this.SetExpanded(true)
        this.ConfigTabs.Choose(2)
        this.Window.Show()
    }

    static ShowDialog(message, title := "Picareta", options := "")
    {
        temporaryOwner := false
        restoreHidden := false

        try
        {
            if this.Window
            {
                restoreHidden := !DllCall(
                    "IsWindowVisible",
                    "Ptr",
                    this.Window.Hwnd,
                    "Int"
                )
                this.Window.Opt("+OwnDialogs")
                this.Window.Show()
                WinActivate("ahk_id " this.Window.Hwnd)
                return MsgBox(message, title, options)
            }

            temporaryOwner := Gui(
                "+AlwaysOnTop +ToolWindow -Caption",
                title
            )
            temporaryOwner.Opt("+OwnDialogs")
            temporaryOwner.Show("xCenter yCenter w1 h1")
            return MsgBox(message, title, options)
        }
        finally
        {
            if temporaryOwner
                temporaryOwner.Destroy()

            if restoreHidden && this.Window
                this.Window.Hide()
        }
    }

    static ShowHelp(title, message)
    {
        ToolTip(title ":`n" message, , , 20)
        SetTimer(() => ToolTip(, , , 20), -6000)
    }

    static Confirm(message, title)
    {
        return this.ShowDialog(
            message,
            title,
            "YesNo Icon?"
        ) = "Yes"
    }

    static ShowConfigStatus(message)
    {
        for statusText in this.ConfigStatusTexts
            statusText.Text := message

        ToolTip(message)
        SetTimer(() => ToolTip(), -2200)
    }

    static CreateKeyboardHotkeyCallback(propertyName)
    {
        return (*) => FloatingPanel.OnKeyboardHotkeyChanged(propertyName)
    }

    static CreateSpecialHotkeyCallback(propertyName)
    {
        return (*) => FloatingPanel.OnSpecialHotkeyChanged(propertyName)
    }

    static OnKeyboardHotkeyChanged(propertyName)
    {
        if !this.HotkeyEdits.Has(propertyName)
            return

        controls := this.HotkeyEdits[propertyName]

        if Trim(controls.Keyboard.Value) != ""
            controls.Special.Choose(1)
    }

    static OnSpecialHotkeyChanged(propertyName)
    {
        if !this.HotkeyEdits.Has(propertyName)
            return

        controls := this.HotkeyEdits[propertyName]

        if controls.Special.Value > 1
            controls.Keyboard.Value := ""
    }

    static FindSpecialHotkeyIndex(value)
    {
        for index, code in this.HotkeySpecialCodes
        {
            if StrLower(code) = StrLower(value)
                return index
        }

        return 1
    }

    static GetHotkeyControlValue(propertyName)
    {
        controls := this.HotkeyEdits[propertyName]
        specialIndex := controls.Special.Value
        value := specialIndex > 1
            ? this.HotkeySpecialCodes[specialIndex]
            : Trim(controls.Keyboard.Value)

        if value != "" && controls.Win.Value = 1
            value := "#" value

        return value
    }

    static RegisterHelpControl(control, helpText)
    {
        control.HelpText := helpText
        control.OnEvent(
            "Click",
            (ctrl, *) => FloatingPanel.ShowHelpTooltip(ctrl)
        )
    }

    static HandleHelpMouseMove(wParam, lParam, msg, hwnd)
    {
        if hwnd = this.LastHelpHwnd
            return

        this.LastHelpHwnd := hwnd
        ToolTip(, , , 20)

        try control := GuiCtrlFromHwnd(hwnd)
        catch
            return

        if control && control.HasOwnProp("HelpText")
            this.ShowHelpTooltip(control)
    }

    static ShowHelpTooltip(control)
    {
        if !control || !control.HasOwnProp("HelpText")
            return

        if this.Window
            this.Window.Opt("+OwnDialogs")

        ToolTip(control.HelpText, , , 20)
        SetTimer(() => ToolTip(, , , 20), -7000)
    }

    static GetWorkAreaForPoint(x, y, &left, &top, &right, &bottom)
    {
        try
        {
            count := MonitorGetCount()

            Loop count
            {
                MonitorGetWorkArea(A_Index, &testLeft, &testTop, &testRight, &testBottom)

                if x >= testLeft && x < testRight && y >= testTop && y < testBottom
                {
                    left := testLeft
                    top := testTop
                    right := testRight
                    bottom := testBottom
                    return
                }
            }

            primary := MonitorGetPrimary()
            MonitorGetWorkArea(primary, &left, &top, &right, &bottom)
        }
        catch
        {
            left := 0
            top := 0
            right := A_ScreenWidth
            bottom := A_ScreenHeight
        }
    }

    static OnPartyPositionSelected(ctrl, row, selected)
    {
        if !selected || row < 1 || row > 10
            return

        if this.SelectedPartyPosition > 0
            && this.SelectedPartyPosition != row
        {
            if !this.SavePartyPositionEditor(false)
                return
        }

        this.LoadPartyPositionEditor(row)
    }

    static LoadPartyPositionEditor(position)
    {
        if position < 1 || position > 10
            return

        this.SelectedPartyPosition := position
        xKey := "PartyPosition" position "X"
        yKey := "PartyPosition" position "Y"
        this.PartyPositionXEdit.Value := this.GeneralEdits[xKey].Value
        this.PartyPositionYEdit.Value := this.GeneralEdits[yKey].Value

        if this.PartyPositionList
            this.PartyPositionList.Modify(position, "Select Focus Vis")
    }

    static SavePartyPositionEditor(showMessage := false)
    {
        position := this.SelectedPartyPosition

        if position < 1 || position > 10
            return true

        x := Trim(this.PartyPositionXEdit.Value)
        y := Trim(this.PartyPositionYEdit.Value)

        if !IsNumber(x) || !IsNumber(y)
            || Integer(x) < 0 || Integer(y) < 0
        {
            PicaretaDialog(
                "As coordenadas da posição devem ser números inteiros maiores ou iguais a zero.",
                "Picareta"
            )
            return false
        }

        xKey := "PartyPosition" position "X"
        yKey := "PartyPosition" position "Y"
        this.GeneralEdits[xKey].Value := Integer(x)
        this.GeneralEdits[yKey].Value := Integer(y)
        this.RefreshPartyPositionList(position)

        if showMessage
            this.ShowConfigStatus("Posição " position " atualizada. Clique em Salvar para gravar no arquivo.")

        return true
    }

    static RefreshPartyPositionList(selectedPosition := 1)
    {
        if !this.PartyPositionList
            return

        this.PartyPositionList.Delete()

        Loop 10
        {
            xKey := "PartyPosition" A_Index "X"
            yKey := "PartyPosition" A_Index "Y"
            x := this.GeneralEdits.Has(xKey) ? this.GeneralEdits[xKey].Value : 0
            y := this.GeneralEdits.Has(yKey) ? this.GeneralEdits[yKey].Value : 0
            situation := x > 0 && y > 0 ? "Configurada" : "Pendente"
            this.PartyPositionList.Add("", A_Index, x, y, situation)
        }

        if selectedPosition >= 1 && selectedPosition <= 10
            this.PartyPositionList.Modify(selectedPosition, "Select Focus Vis")
    }

    static StartPartyPositionCapture()
    {
        if this.SelectedPartyPosition < 1
        {
            PicaretaDialog(
                "Selecione uma posição da lista antes de capturar.",
                "Picareta"
            )
            return
        }

        this.StartLeaderCoordinateCapture(
            this.PartyPositionXEdit,
            this.PartyPositionYEdit,
            "Posição " this.SelectedPartyPosition " da lista da PT"
        )
    }

    static ClearSessionRegistrations()
    {
        if !this.ClearRegistrationsCallback
            return

        if !this.Confirm(
            "Deseja limpar o personagem principal e todas as mulas cadastradas nesta sessão?`n`n"
            . "As configurações salvas no arquivo não serão apagadas.",
            "Limpar cadastros"
        )
        {
            return
        }

        this.ClearRegistrationsCallback.Call()
        this.RefreshRegistrationStatus()
        this.ShowConfigStatus("Cadastros da sessão limpos.")
    }

    static FormatHotkey(hotkey)
    {
        hk := Trim(hotkey)

        if hk = ""
            return "Não configurado"

        hk := StrReplace(hk, "^", "Ctrl + ")
        hk := StrReplace(hk, "!", "Alt + ")
        hk := StrReplace(hk, "+", "Shift + ")
        hk := StrReplace(hk, "#", "Win + ")
        hk := StrReplace(hk, "XButton1", "Botão lateral traseiro")
        hk := StrReplace(hk, "XButton2", "Botão lateral dianteiro")
        hk := StrReplace(hk, "MButton", "Botão do meio")
        hk := StrReplace(hk, "LButton", "Botão esquerdo")
        hk := StrReplace(hk, "RButton", "Botão direito")
        hk := StrReplace(hk, "WheelUp", "Roda ↑")
        hk := StrReplace(hk, "WheelDown", "Roda ↓")
        hk := StrReplace(hk, "SC029", "'")
        hk := StrReplace(hk, "Esc", "Escape")
        hk := StrReplace(hk, "Del", "Delete")
        hk := StrReplace(hk, "PgUp", "Page Up")
        hk := StrReplace(hk, "PgDn", "Page Down")

        return hk
    }
}
