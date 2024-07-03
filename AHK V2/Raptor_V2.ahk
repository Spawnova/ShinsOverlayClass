
#Requires AutoHotkey v2.0
#SingleInstance force
#Include "shinsoverlayclass.ahk"

A_TickCount_Start := A_TickCount
TickCount_Pause := 0
TickCount_Pause_Start := 0
game_status := 1
x := floor(a_screenwidth * 0.2)
y := floor(a_screenheight * 0.2)
width := floor(a_screenwidth * 0.6)
height := floor(a_screenheight * 0.6)

MyGui := Gui( ,"Raptor_V2")

MyGui.AddButton(,"test")
MyGui.BackColor := "5d691e"
MyGui.Show("w" width " h" height " x" x " y" y)

; overlay := ShinsOverlayClass(x,y,width,height,0,0,0)
overlay := ShinsOverlayClass("Raptor_V2")

opacity := 0x99

step := 1
stepsText := []
stepsText.push("Example of a raptor game!`nPress [Alt] to shoot.`nPress [Space] to pause.")
stepsText.push("Drawing Lines!`nDrawLine(x1, y1, x2, y2, color, thickness:=1, rounded:=0)`n`n")

aBullets := []
aEnemies := []
aEBullets := []
aExplosions := []
aRewards := []
aColors := {}
aColors.shadow := 0x30000000

plane := {x: Width/2, y: overlay.height-100, HP: 100, maxHP: 100, score: 0, firerate:0.3, lastfired:0, width: 40, vx:0, vy:0, ax:0,ay:0,ly:45}

plane.draw := (plane,*)=> (
    (Shadowx := (width/2-plane.x)/10),
    (Shadowy := (height/2-plane.y)/10),
    overlay.FillPolygon(TransformCoord([[0,0],[5,10],[5,20],[20,35],[15,40],[10,40],[10,45],[5,45],[5,40],[-5,40],[-5,45],[-10,45],[-10,40],[-15,40],[-20,35],[-5,20],[-5,10]],(1-0.4*Abs(plane.vx)/10)*.8),color:= aColors.shadow ,plane.x+Shadowx,plane.y+Shadowy)
    overlay.FillPolygon(TransformCoord([[0,0],[5,10],[5,20],[20,35],[15,40],[10,40],[10,45],[5,45],[5,40],[-5,40],[-5,45],[-10,45],[-10,40],[-15,40],[-20,35],[-5,20],[-5,10]],(1-0.4*Abs(plane.vx)/10)),color:=0x808080,plane.x,plane.y)

)

mLevel1 := Map()
mLevel1[1.0] := {xpos:0.8}
mLevel1[2.0] := {xpos:0.6}
mLevel1[3.0] := {xpos:0.4, type:2}
mLevel1[4.0] := {xpos:0.2, type:2}
mLevel1[5.0] := {xpos:0.4, type:2}


loop 500 {
    mLevel1[A_index*1.5+5.0] := {xpos:Random(0.2,0.8), type:Random(1,2)}
}

; OnMessage(0x201, WindowMove)

SetTimer(draw,10)

f9::Reload()
esc::ExitApp()

~Space::
{
global game_status, TickCount_Pause, TickCount_Pause_Start, A_TickCount_Start
game_status := !game_status
if (!game_status){
    ; pause the game
    SetTimer(draw,0)
    TickCount_Pause_Start := A_TickCount
}else{
    SetTimer(draw,10)
    A_TickCount_Start := A_TickCount_Start + A_TickCount-TickCount_Pause_Start
}

}

return


draw(){
	global

	if (overlay.BeginDraw()) {

		;draw background
		; overlay.FillRoundedRectangle(0,0,overlay.width,overlay.height,55,55,(opacity<<24))
		; overlay.DrawRoundedRectangle(0,0,overlay.width,overlay.height,55,55,0xFFFFFFFF,2)
		; overlay.FillRectangle(0,0,overlay.width,overlay.height,(opacity<<24))
		; overlay.DrawRectangle(0,0,overlay.width,overlay.height,0xFFFFFFFF,2)

		;draw examples per step
		if (step = 1) {

            A_TickCount_script := Round((A_TickCount-A_TickCount_Start)/1000,1)

            overlay.GetMousePos(&mx,&my)

            overlay.FillRectangle(overlay.width-20,0,20,overlay.height,0xFF000000)
            loop 100
            {
                if (A_Index > plane.hp){
                    break
                }
                ExplosionOpacity := Format("{:X}", Round(255*(0.5+A_Index/200)))
                overlay.FillRectangle(overlay.width-18,overlay.height*(100-A_Index-1)/100-4,16,4,"0x" ExplosionOpacity "FF0000")
            }
            ; Draw plane
            ; plane.x := mx
            ; plane.y := my

            if (GetKeyState("Left")){
                plane.ax := -1
            } else if (GetKeyState("Right")){
                plane.ax := 1
            } else {
                if (plane.vx > 0){
                    plane.ax := -1
                } else if (plane.vx < 0){
                    plane.ax := 1
                } else {
                    plane.ax := 0
                }
            }

            if (GetKeyState("Up")){
                plane.ay := -1
            } else if (GetKeyState("Down")){
                plane.ay := 1
            } else {
                if (plane.vy > 0){
                    plane.ay := -1
                } else if (plane.vy < 0){
                    plane.ay := 1
                } else {
                    plane.ay := 0
                }
            }


            plane.vx += plane.ax
            plane.vx := max(min(plane.vx,10),-10)
            plane.vy += plane.ay
            plane.vy := max(min(plane.vy,10),-10)

            plane.x += plane.vx
            plane.y += plane.vy
            plane.x := max(min(plane.x,width-plane.width/2),plane.width/2)
            plane.y := max(min(plane.y,Height-plane.ly),plane.ly)



            if (GetKeyState("Alt") and (plane.lastfired + plane.firerate <= A_TickCount_script)){
                level := (plane.score < 500) ? 1 : (plane.score < 1000) ? 2 : 3
                ShootBullet(level)
                plane.lastfired := A_TickCount_script
            }

            if(mLevel1.Has(A_TickCount_script+0)){
                Enemy := mLevel1[A_TickCount_script+0]
                CreateEnemy(20+Enemy.xpos*(overlay.width-40),(Enemy.HasProp("type") ? Enemy.type : 1))
                mLevel1.Delete(A_TickCount_script)
            }

            overlay.DrawText("$" plane.score,0,height*0.03,20,0xFF99FF8B,"Courier","aCenter dsFF000000 dsx1 dsy1 w" width " h" height)

			overlay.DrawText("HP: " plane.HP "`nTime:" A_TickCount_script "`n     [" GetKeyState("Up","P") "]`n[" GetKeyState("Left","P") "] [" GetKeyState("Down","P") "] [" GetKeyState("Right","P") "]",0,height*0.5,20,0xFF99FF8B,"Courier","dsFF000000 dsx1 dsy1 w" width " h" height)
            if (plane.HP <=0){
                overlay.DrawText("GAME OVER" ,0,height*0.5,60,0xFFFF0000,"Courier","aCenter dsFF000000 dsx1 dsy1 w" width " h" height)
            }

            for Index_bullet, bullet in aBullets {
                bullet.y += bullet.vy

                (bullet.HasProp("vx")) ? (bullet.x += bullet.vx) : ""

                if (bullet.y < 0) {
                    aBullets.RemoveAt(Index_bullet)
                } else {
                    bullet.draw(bullet)
                }
            }
            for Index_Rewards, Reward in aRewards {
                Reward.y += Reward.vy + Random(-0.5, 0.5)
                Reward.x += Random(-0.5, 0.5)

                if (Abs(Reward.y-(plane.y+plane.ly/2)) < plane.ly/2) and (Abs(Reward.x-Plane.x) < Plane.width/2){
                    Reward.OnHit()
                    aRewards.RemoveAt(Index_Rewards)
                }
                else if (Reward.y < 0) {
                    aRewards.RemoveAt(Index_Rewards)
                } else {

                    Reward.Draw(Reward)
                }
            }

            for Index_EBullets, EBullet in aEBullets {
                EBullet.y += EBullet.vy
                if (Abs(EBullet.y-(plane.y+plane.ly/2)) < plane.ly/2) and (Abs(EBullet.x-Plane.x) < Plane.width/2){
                    plane.hp -= EBullet.power
                    aExplosions.Push({x: EBullet.x, y: EBullet.y, radius: 1, vr: 1, maxradius: 30})
                    aEBullets.RemoveAt(Index_EBullets)
                }
                else if (EBullet.y < 0) {
                    aEBullets.RemoveAt(Index_EBullets)
                } else {
                    overlay.FillCircle(EBullet.x,EBullet.y,EBullet.radius,0xFF99FF8B)
                }
            }

            for Index_Enemy, Enemy in aEnemies {
                Enemy.y += Enemy.vy + Random(-0.5, 0.5)
                Enemy.x += Enemy.vx + Random(-0.5, 0.5)

                ; Check if the enemy is hit by bullets
                for Index_bullet, bullet in aBullets {
                    if (Abs(bullet.y-Enemy.y) < 5) and (Abs(bullet.x-Enemy.x) < Enemy.width/2) {

                        aExplosions.Push({x: bullet.x, y: bullet.y, radius: 1, vr: 1, maxradius: 30, vy: Enemy.vy})

                        aBullets.RemoveAt(Index_bullet)
                        SoundPlay "*2"
                        Enemy.HP -= bullet.power
                        If (Enemy.HP <= 0 ){
                            plane.score += Enemy.points

                            Rnumber := Random(0,1)
                            if (Rnumber <0.3){
                                aRewards.Push({x: Enemy.x, y: Enemy.y, draw: (Reward,*)=>(overlay.DrawText("$",Reward.x-5,Reward.y,12,0xFF99FF8B,"Courier","dsFF000000 dsx1 dsy1 w" width " h" height)), vy: 1, OnHit: (*)=>(SoundPlay("*-1"), plane.Score += 100)})
                            } else if (Rnumber > 0.6){
                                aRewards.Push({x: Enemy.x, y: Enemy.y, draw: (Reward,*)=>(overlay.DrawText("♥",Reward.x-5,Reward.y,12,0x99FF0000,"Courier","dsFF000000 dsx1 dsy1 w" width " h" height)), vy: 1, OnHit: (*)=>(SoundPlay("*-1"), plane.HP := Min(plane.HP+10, plane.maxHP))})
                            }

                            aEnemies.RemoveAt(Index_Enemy)
                            break
                        }
                    }
                }

                if (Abs(Enemy.y-(plane.y+plane.ly/2)) < plane.ly/2) and (Abs(plane.x-Enemy.x) < plane.width/2){
                    Enemy.OnCollision()
                    aExplosions.Push({x: Enemy.x, y: Enemy.y, radius: 1, vr: 1, maxradius: 40, vy: Enemy.vy})
                    aEnemies.RemoveAt(Index_Enemy)
                } else if (Enemy.y > overlay.height) {
                    aEnemies.RemoveAt(Index_Enemy)
                } else {
                    Enemy.Draw(Enemy)
                }

                if ((Enemy.lastfired + Enemy.firerate <= A_TickCount_script)){
                    Enemy.fire(Enemy)
                    Enemy.lastfired := A_TickCount_script
                }

            }

            for Index_Explosion, Explosion in aExplosions {
                (Explosion.HasProp("vy")) ? Explosion.y += Explosion.vy : ""
                Explosion.radius += Explosion.vr
                if (Explosion.radius >= Explosion.maxradius) {
                    aExplosions.RemoveAt(Index_Explosion)
                } else {
                    ExplosionOpacity := Format("{:X}", Round(255*(1-Explosion.radius/Explosion.maxradius)))
                    overlay.FillCircle(Explosion.x,Explosion.y, Explosion.radius, "0x" ExplosionOpacity "99FF8B")
                }
            }

            plane.draw()

        }

	}

	;draw text elements
	overlay.DrawText(stepsText[step],50,50,24,0xFFFFFFFF,"Arial","dsFF000000")
	overlay.DrawText("Press ESC to close",overlay.width-400,50,32,0xFFCC0000,"Arial","aRight dsFF222222 w" 400-50)
	overlay.EndDraw()
	return
}


ShootBullet(Level := 1){
    global aBullets

    if (Level=1){
        aBullets.Push({x: plane.x, y: plane.y, power: 40, vy: -2, draw: (Bullet,*)=>(overlay.DrawLine(bullet.x,bullet.y,bullet.x,bullet.y+5,0xFF99FF8B,2))})
    } else if (Level = 2){
        aBullets.Push({x: plane.x-10, y: plane.y+20, power: 40, vy: -2, draw: (Bullet,*)=>(overlay.DrawLine(bullet.x,bullet.y,bullet.x,bullet.y+5,0xFF99FF8B,2))})
        aBullets.Push({x: plane.x+10, y: plane.y+20, power: 40, vy: -2, draw: (Bullet,*)=>(overlay.DrawLine(bullet.x,bullet.y,bullet.x,bullet.y+5,0xFF99FF8B,2))})
    } else if (Level = 3){
        aBullets.Push({x: plane.x-10, y: plane.y+20, power: 60, vy: -3, draw: (Bullet,*)=>(overlay.DrawLine(bullet.x,bullet.y,bullet.x,bullet.y+5,0xFF8c7fe3,2))})
        aBullets.Push({x: plane.x+10, y: plane.y+20, power: 60, vy: -3, draw: (Bullet,*)=>(overlay.DrawLine(bullet.x,bullet.y,bullet.x,bullet.y+5,0xFF8c7fe3,2))})
        aBullets.Push({x: plane.x-10, y: plane.y+20, power: 60, vx: -1, vy: -2, draw: (Bullet,*)=>(overlay.DrawLine(bullet.x,bullet.y,bullet.x,bullet.y+5,0xFF8c7fe3,2))})
        aBullets.Push({x: plane.x+10, y: plane.y+20, power: 60, vx: 1, vy: -2, draw: (Bullet,*)=>(overlay.DrawLine(bullet.x,bullet.y,bullet.x,bullet.y+5,0xFF8c7fe3,2))})
    }
}

CreateEnemy(Xpos := Random(20,overlay.width-20), type :=1){
    global aEnemies
    if (Type=1){
        Enemy := {x: Xpos, y: -100, HP: 100, vy: 2, vx:0, width: 20, points: 100, firerate: 1.5, lastfired: 0, bulletpower: 10}
        Enemy.draw := (Enemy,*)=>(
            (Shadowx := (width/2-Enemy.x)/5),
            (Shadowy := (height/2-Enemy.y)/15),
            overlay.FillPolygon(TransformCoord([[0,0],[5,-5],[5,-10],[10,-15],[10,-20],[5,-15],[-5,-15],[-10,-20],[-10,-15],[-5,-10],[-5,-5]],0.8),color:= aColors.shadow ,Enemy.x+Shadowx,Enemy.y+Shadowy),
            overlay.FillPolygon([[0,0],[5,-5],[5,-10],[10,-15],[10,-20],[5,-15],[-5,-15],[-10,-20],[-10,-15],[-5,-10],[-5,-5]],color:=0x808080,Enemy.x,Enemy.y)
        )
        Enemy.fire := (Enemy,*)=>(aEBullets.Push({x: Enemy.x, y: Enemy.y, radius: 2, vy: Enemy.vy+1, power: Enemy.bulletpower}))
        Enemy.OnCollision := (Enemy,*)=>(plane.HP -= Enemy.HP/10)
    } else {
        Enemy := {x: Xpos, y: -100, HP: 100, vy: 2, vx:0, width: 30, points: 100, firerate: 2, lastfired: 0, bulletpower: 10}
        Enemy.draw := (Enemy,*)=>(
            (Shadowx := (width/2-Enemy.x)/5),
            (Shadowy := (height/2-Enemy.y)/5),
            overlay.FillPolygon(TransformCoord([[0,0],[5,0],[10,-5],[15,-15],[15,-20],[10,-20],[10,-25],[5,-25],[5,-20],[-5,-20],[-5,-25],[-10,-25],[-10,-20],[-15,-20],[-15,-15],[-10,-5],[-5,0]],0.8),color:= aColors.shadow ,Enemy.x+Shadowx,Enemy.y+Shadowy),
            overlay.FillPolygon([[0,0],[5,0],[10,-5],[15,-15],[15,-20],[10,-20],[10,-25],[5,-25],[5,-20],[-5,-20],[-5,-25],[-10,-25],[-10,-20],[-15,-20],[-15,-15],[-10,-5],[-5,0]],color:=0x808080,Enemy.x,Enemy.y)
        )
        Enemy.fire := (Enemy,*)=>(aEBullets.Push({x: Enemy.x-5, y: Enemy.y-5, radius: 2, vy: Enemy.vy+1, power: Enemy.bulletpower}), aEBullets.Push({x: Enemy.x+5, y: Enemy.y-5, radius: 2, vy: Enemy.vy+1, power: Enemy.bulletpower}))
        Enemy.OnCollision := (Enemy,*)=>(plane.HP -= Enemy.HP/10)
    }

    aEnemies.Push(Enemy)
}

TransformCoord(aCoord,varx:=1, vary:=1){
    aCoord2:= []
    for index, Coord in aCoord
    {
        aCoord2.Push([Coord[1]*varx,Coord[2]*vary])
    }
    return aCoord2
}