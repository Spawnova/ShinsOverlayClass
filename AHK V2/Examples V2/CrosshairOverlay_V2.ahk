#Requires Autohotkey v2.0
#SingleInstance force
#Include ..\ShinsOverlayClass.ahk

cx := IniRead("crosshair.ini", "pos", "x", 600)
cy := IniRead("crosshair.ini", "pos", "y", 600)
cs := IniRead("crosshair.ini", "pos", "s", 8)

;some variables for setting the position
setPos := 0
setPosBlink := 0
setPosColor := 0

;crosshair settings
crossHairSize := cs
crossHairColor := 0xFF00FF00
crossHairBorderColor := 0xFF000000
crossHairBorderSize := 1 ;if set to 0 then there will be no border

;max reticle size, default 16x16, increase if you need very large crosshair
maxSize := 16
halfSize := floor(maxSize/2)

o := ShinsOverlayClass(cx,cy,maxSize,maxSize)

update() ;draw initially
return


; press F1 to enable positioning mode
f1::
{
	global
	setPos := !setPos
	if (!setPos) {
		IniWrite(cx, "crosshair.ini", "pos", "x")
		IniWrite(cy, "crosshair.ini", "pos", "y")
		IniWrite(crossHairSize, "crosshair.ini", "pos", "s")
		SetTimer(update,0)
		update()
	} else {
		SetTimer(update,50)
	}
	return
}


#HotIf setPos

; if setting position use arrows keys to move, holding shift will move more
; page up and page down affects crosshair size

pgup::
{
	global
	crossHairSize++
	return
}
pgdn::
{
	global
	crossHairSize--
	if (crossHairSize <= 0)
		crossHairSize := 1
	return
}

right::
{
	global
	cx+=1
	o.SetPosition(cx,cy)
	return
}
+right::
{
	global
	cx+=10
	o.SetPosition(cx,cy)
	return
}

left::
{
	global
	cx-=1
	o.SetPosition(cx,cy)
	return
}
+left::
{
	global
	cx-=10
	o.SetPosition(cx,cy)
	return
}

down::
{
	global
	cy+=1
	o.SetPosition(cx,cy)
	return
}
+down::
{
	global
	cy+=10
	o.SetPosition(cx,cy)
	return
}

up::
{
	global
	cy-=1
	o.SetPosition(cx,cy)
	return
}
+up::
{
	global
	cy-=10
	o.SetPosition(cx,cy)
	return
}

#HotIf

update(){
	global
	if (o.BeginDraw()) {

		if (crossHairBorderSize > 0) {
			o.FillEllipse(halfSize,halfSize,crossHairSize,crossHairSize,crossHairBorderColor)
			o.FillEllipse(halfSize,halfSize,crossHairSize-crossHairBorderSize,crossHairSize-crossHairBorderSize,crossHairColor)
		} else {
			o.FillEllipse(halfSize,halfSize,crossHairSize,crossHairSize,crossHairColor)
		}

		if (setPos) {
			if (a_tickcount > setPosBlink) {
				setPosColor := !setPosColor
				setPosBlink := a_tickcount + 500
			}
			o.DrawRectangle(1,1,maxSize-1,maxSize-1,(setPosColor?0xFFFFFFFF:0xFF000000))
		}

		o.EndDraw()
	}
	return
}


f9::Reload()
