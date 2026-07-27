#Requires AutoHotkey v2.0

class PWWindows
{
    static IsOpen(hwnd)
    {
        return hwnd && WinExist("ahk_id " hwnd)
    }

    static GetTarget(hwnd)
    {
        if !hwnd
            throw Error("Nenhuma janela foi informada.")

        if !this.IsOpen(hwnd)
            throw Error("A janela informada não existe mais.")

        return "ahk_id " hwnd
    }

    ; Envia teclas para diálogos e controles que aceitam entrada em segundo plano.
    ; Atalhos normais de gameplay podem exigir outro método e devem ser testados.
    static SendKey(hwnd, key, delayAfter := 100)
    {
        target := this.GetTarget(hwnd)

        ControlSend key, , target

        if delayAfter > 0
            Sleep delayAfter

        return true
    }

    static SendText(hwnd, text, delayAfter := 100)
    {
        target := this.GetTarget(hwnd)

        ControlSendText text, , target

        if delayAfter > 0
            Sleep delayAfter

        return true
    }

    static LeftClick(hwnd, x, y, delayAfter := 100)
    {
        target := this.GetTarget(hwnd)

        ControlClick(
            "x" x " y" y,
            target,
            ,
            "Left",
            1,
            "NA Pos"
        )

        if delayAfter > 0
            Sleep delayAfter

        return true
    }

    static RightClick(hwnd, x, y, delayAfter := 100)
    {
        target := this.GetTarget(hwnd)

        ControlClick(
            "x" x " y" y,
            target,
            ,
            "Right",
            1,
            "NA Pos"
        )

        if delayAfter > 0
            Sleep delayAfter

        return true
    }

    static BackgroundLeftClick(hwnd, x, y, delayAfter := 100)
    {
        this.GetTarget(hwnd)

        lParam := (y << 16) | (x & 0xFFFF)
        target := "ahk_id " hwnd

        ; WM_MOUSEMOVE
        PostMessage 0x0200, 0, lParam, , target
        Sleep 30

        ; WM_LBUTTONDOWN
        PostMessage 0x0201, 1, lParam, , target
        Sleep 30

        ; WM_LBUTTONUP
        PostMessage 0x0202, 0, lParam, , target

        if delayAfter > 0
            Sleep delayAfter

        return true
    }

    static BackgroundRightClick(hwnd, x, y, delayAfter := 100)
    {
        this.GetTarget(hwnd)

        lParam := (y << 16) | (x & 0xFFFF)
        target := "ahk_id " hwnd

        ; WM_MOUSEMOVE
        PostMessage 0x0200, 0, lParam, , target
        Sleep 30

        ; WM_RBUTTONDOWN
        PostMessage 0x0204, 2, lParam, , target
        Sleep 30

        ; WM_RBUTTONUP
        PostMessage 0x0205, 0, lParam, , target

        if delayAfter > 0
            Sleep delayAfter

        return true
    }

    ; Envia um clique completo sem pausas internas.
    ; Usado pelo espelhamento para alcançar todas as janelas rapidamente.
    static FastBackgroundLeftClick(hwnd, x, y)
    {
        this.GetTarget(hwnd)

        lParam := (y << 16) | (x & 0xFFFF)
        target := "ahk_id " hwnd

        ; Posiciona virtualmente o mouse na janela.
        PostMessage 0x0200, 0, lParam, , target

        ; Pequena pausa para o cliente processar a posição.
        Sleep 10

        ; Pressiona o botão esquerdo.
        PostMessage 0x0201, 1, lParam, , target

        ; Evita que o jogo ignore um clique rápido demais.
        Sleep 5

        ; Solta o botão esquerdo.
        PostMessage 0x0202, 0, lParam, , target

        return true
    }

}