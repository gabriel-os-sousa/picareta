#Requires AutoHotkey v2.0

/**
 * Janela flutuante do PW Controller.
 *
 * A janela pertence ao próprio controller, e não a um cliente do jogo.
 * Por isso, continua visível ao alternar entre os personagens.
 */
class FloatingPanel
{
    static Window := false

    /**
     * Cria e exibe a janela flutuante.
     *
     * A barra de título padrão permite mover a janela livremente.
     * +AlwaysOnTop mantém a janela acima dos clientes do jogo.
     * +ToolWindow evita criar outro botão na barra de tarefas.
     */
    static Show(hotkeys)
    {
        if this.Window
        {
            this.Window.Show("NoActivate")
            return
        }

        panel := Gui(
            "+AlwaysOnTop +ToolWindow",
            "PW Controller"
        )

        panel.MarginX := 12
        panel.MarginY := 10
        panel.SetFont("s10", "Segoe UI")

        panel.AddText(
            "xm w270 Center",
            "ATALHOS CONFIGURADOS"
        )

        panel.SetFont("s9", "Segoe UI")

        panel.AddText(
            "xm y+10 w270",
            this.BuildHotkeyText(hotkeys)
        )

        panel.AddText(
            "xm y+10 w270 Center cGray",
            "Arraste pela barra de título para mover"
        )

        ; Ao clicar no X, apenas oculta a janela.
        ; O controller continua funcionando.
        panel.OnEvent("Close", (guiObject, *) => guiObject.Hide())

        this.Window := panel

        panel.Show("AutoSize NoActivate")
    }

    /**
     * Monta o conteúdo inicial da janela.
     */
    static BuildHotkeyText(hotkeys)
    {
        text := "Cadastrar principal: " this.FormatHotkey(hotkeys.RegisterLeader)
        text .= "`nCadastrar mula: " this.FormatHotkey(hotkeys.RegisterMule)
        text .= "`nAlternar janela: " this.FormatHotkey(hotkeys.NextWindow)
        text .= "`nMostrar status: " this.FormatHotkey(hotkeys.ShowStatus)
        text .= "`nMontar PT: " this.FormatHotkey(hotkeys.BuildParty)
        text .= "`nRemontar PT: " this.FormatHotkey(hotkeys.RebuildParty)
        text .= "`nEspelhamento: " this.FormatHotkey(hotkeys.ToggleMirror)
        text .= "`nLimpar cadastros: " this.FormatHotkey(hotkeys.ClearRegistrations)
        text .= "`nFechar controller: " this.FormatHotkey(hotkeys.ExitController)

        return text
    }

    static FormatHotkey(hotkey)
    {
        hk := hotkey

        ; Modificadores
        hk := StrReplace(hk, "^", "Ctrl + ")
        hk := StrReplace(hk, "!", "Alt + ")
        hk := StrReplace(hk, "+", "Shift + ")
        hk := StrReplace(hk, "#", "Win + ")

        ; Mouse
        hk := StrReplace(hk, "XButton1", "Botão lateral - frente")
        hk := StrReplace(hk, "XButton2", "Botão lateral - trás")
        hk := StrReplace(hk, "MButton", "Botão do meio")
        hk := StrReplace(hk, "LButton", "Botão esquerdo")
        hk := StrReplace(hk, "RButton", "Botão direito")
        hk := StrReplace(hk, "WheelUp", "Roda ↑")
        hk := StrReplace(hk, "WheelDown", "Roda ↓")

        ; Teclas especiais
        hk := StrReplace(hk, "SC029", "'")
        hk := StrReplace(hk, "Esc", "Escape")
        hk := StrReplace(hk, "Del", "Delete")
        hk := StrReplace(hk, "PgUp", "Page Up")
        hk := StrReplace(hk, "PgDn", "Page Down")

        return hk
    }
}