#Requires AutoHotkey v2.0

class MouseMirror
{
    static Enabled := false

    static Toggle()
    {
        this.Enabled := !this.Enabled

        if this.Enabled
        {
            TraySetIcon "shell32.dll", 44
            A_IconTip := "PW Controller — Espelhamento ATIVADO"

            ToolTip "ESPELHAMENTO ATIVADO"
            SetTimer () => ToolTip(), -1200
        }
        else
        {
            TraySetIcon "shell32.dll", 131
            A_IconTip := "PW Controller — Espelhamento desativado"

            ToolTip "Espelhamento desativado"
            SetTimer () => ToolTip(), -1200
        }

        return this.Enabled
    }

    static Disable()
    {
        this.Enabled := false
    }

    static IsEnabled()
    {
        return this.Enabled
    }

    static IsRegisteredWindow(hwnd, leaderHwnd, mules)
    {
        if hwnd = leaderHwnd
            return true

        for mule in mules
        {
            if mule.Hwnd = hwnd
                return true
        }

        return false
    }

    static MirrorClick(sourceHwnd, leaderHwnd, mules, x, y)
    {
        if !this.Enabled
            return 0

        if !sourceHwnd
            return 0

        ; O clique somente é espelhado quando parte de uma janela cadastrada.
        if !this.IsRegisteredWindow(sourceHwnd, leaderHwnd, mules)
            return 0

        targets := []

        if leaderHwnd
            targets.Push(leaderHwnd)

        for mule in mules
            targets.Push(mule.Hwnd)

        sentCount := 0
        processed := Map()

        for targetHwnd in targets
        {
            if !targetHwnd
                continue

            ; Não envia de volta para a janela onde ocorreu o clique original.
            if targetHwnd = sourceHwnd
                continue

            ; Evita processar um HWND duplicado por segurança.
            if processed.Has(targetHwnd)
                continue

            processed[targetHwnd] := true

            if !PWWindows.IsOpen(targetHwnd)
                continue

            try
            {
                PWWindows.FastBackgroundLeftClick(
                    targetHwnd,
                    x,
                    y
                )

                sentCount += 1
            }
            catch
            {
                ; Uma janela fechada durante o clique não interrompe as demais.
                continue
            }
        }

        return sentCount
    }
}
