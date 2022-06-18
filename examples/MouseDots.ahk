#singleinstance,force
setbatchlines,-1
settitlematchmode,2


#include ..\shinsoverlayclass.ahk

if (!WinExist("Untitled - Notepad")) {
	msgbox % "Please open a notepad window and press OK to reload"
	reload
}
WinActivate, Notepad

overlay := new ShinsOverlayClass("Untitled - Notepad")

dots := []
dotRate := 0
dotIndex := 0

lastX := 0
lastY := 0
toggle := 1 ;start on
settimer,main,10
return

f2::
toggle := !toggle
if (toggle) {
	settimer,main,10
} else {
	settimer,main,off
	overlay.BeginDraw()
	overlay.EndDraw()
}
return

main:
if (overlay.BeginDraw()) {  ;must always call BeginDraw() to start, it returns true if window is valid
	
	overlay.FillRectangle(overlay.realX,overlay.realY,300,100,0xAA000000)
	overlay.DrawText("Press ESC to exit`nPress F2 to toggle overlay",10,10,0xFFFFFFFF,24)
	
	if (overlay.GetMousePos(mx,my)) { ;if mouse is within overlay area
		if (lastX != mx or lastY != my) { ;only draw when moving the mouse
			strength := 1.0 + ((abs(lastX-mx) + abs(lasty-my)) / 20)
			dotIndex := dotRate
			loop 3
				dots.push(new _dot(mx,my,random(3,15),random(0xFF505050,0xFFFFFFFF),random(0,360),random(0.50,1.00)*strength,random(0.92,0.99),random(-0.32,-0.13),random(-5.0,-1.7)))
			lastX := mx
			lastY := my
		}
	}
	
	;draw the dots and remove the ones that expired
	i := 1
	while(i < dots.length()) {
		if (!dots[i].draw(overlay)) {
			dots.removeat(i)
		} else {
			i++
		}
	}
			
	overlay.EndDraw() ;must always call EndDraw() to finish drawing
}
return

random(min,max) {
	random,result,min,max
	return result
}

esc::exitapp

;simple class to handle dot behaviours
class _dot {
	
	__New(x,y,size,col,dir,speed,friction,growDir,growCol) {
		this.x := x
		this.y := y
		this.size := size
		this.speed := speed
		this.friction := friction
		this.rgb := (col & 0xFFFFFF)
		this.alpha := (col&0xFF000000)>>24
		this.dir := dir
		this.growDir := growDir
		this.growCol := growCol
	}
	
	Draw(overlay) {
		this.size += this.growDir
		if (this.size < 0.1)
			return 0
			
		this.x += cos(this.dir) * this.speed
		this.y += sin(this.dir) * this.speed

		this.speed *= this.friction
		
		this.alpha += this.growCol
		
		if (this.alpha < 1)
			return 0

		overlay.fillellipse(this.x,this.y,this.size,this.size,(floor(this.alpha)<<24)+this.rgb)
		return 1
	}
}


