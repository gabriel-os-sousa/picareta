#Requires AutoHotkey v2.0

#Include Windows.ahk

class Party
{
    static InviteMember(
        leaderHwnd,
        friendX,
        friendY,
        inviteX,
        inviteY
    )
    {
        if !PWWindows.IsOpen(leaderHwnd)
            throw Error("A janela do líder não existe mais.")

        BlockInput "MouseMove"

        try
        {
            PWWindows.RightClick(
                leaderHwnd,
                friendX,
                friendY,
                120
            )

            PWWindows.LeftClick(
                leaderHwnd,
                inviteX,
                inviteY,
                120
            )
        }
        finally
        {
            BlockInput "MouseMoveOff"
        }

        return true
    }

    static AcceptInvite(
        muleHwnd,
        notificationX,
        notificationY
    )
    {
        if !PWWindows.IsOpen(muleHwnd)
            throw Error("A janela da mula não existe mais.")

        ; Usa explicitamente o método validado para segundo plano.
        PWWindows.BackgroundLeftClick(
            muleHwnd,
            notificationX,
            notificationY,
            100
        )

        Sleep 100

        ; O Y já foi validado para caixas de confirmação.
        PWWindows.SendKey(
            muleHwnd,
            "y",
            80
        )

        return true
    }

    static InviteAndAccept(
        leaderHwnd,
        muleHwnd,
        friendX,
        friendY,
        inviteX,
        inviteY,
        notificationX,
        notificationY
    )
    {
        this.InviteMember(
            leaderHwnd,
            friendX,
            friendY,
            inviteX,
            inviteY
        )

        Sleep 250

        this.AcceptInvite(
            muleHwnd,
            notificationX,
            notificationY
        )

        return true
    }
}