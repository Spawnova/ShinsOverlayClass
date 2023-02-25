#singleinstance,force
#include ..\ShinsOverlayClass.ahk


iniread,cx,crosshair.ini,pos,x,600
iniread,cy,crosshair.ini,pos,y,600
iniread,cs,crosshair.ini,pos,s,8

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

o := new ShinsOverlayClass(cx,cy,maxSize,maxSize)

gosub update ;draw initially
return











; press F1 to enable positioning mode
f1::
setPos := !setPos
if (!setPos) {
	iniwrite,%cx%,crosshair.ini,pos,x
	iniwrite,%cy%,crosshair.ini,pos,y
	iniwrite,%crossHairSize%,crosshair.ini,pos,s
	settimer,update,off
	gosub update
} else {
	settimer,update,50
}
return















#if setPos

; if setting position use arrows keys to move, holding shift will move more
; page up and page down affects crosshair size

pgup::
crossHairSize++
return
pgdn::
crossHairSize--
if (crossHairSize <= 0)
	crossHairSize := 1
return

right::
cx+=1
o.SetPosition(cx,cy)
return
+right::
cx+=10
o.SetPosition(cx,cy)
return

left::
cx-=1
o.SetPosition(cx,cy)
return
+left::
cx-=10
o.SetPosition(cx,cy)
return


down::
cy+=1
o.SetPosition(cx,cy)
return
+down::
cy+=10
o.SetPosition(cx,cy)
return

up::
cy-=1
o.SetPosition(cx,cy)
return
+up::
cy-=10
o.SetPosition(cx,cy)
return


#if









update:
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




f9::Reload
