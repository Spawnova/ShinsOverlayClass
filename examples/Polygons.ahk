#singleinstance,force
#include ..\shinsoverlayclass.ahk

x := floor(a_screenwidth * 0.2)
y := floor(a_screenheight * 0.2)
width := floor(a_screenwidth * 0.6)
height := floor(a_screenheight * 0.6)
if (width < height) {
	height := width
} else {
	width := height
}
;create a octagon window
oRad := 0.25 ;octagon corner radius
windowPolygon := [ [2,height*oRad], [width*oRad,2], [width*(1-oRad),2], [width-2,height*oRad], [width-2,height*(1-oRad)], [width*(1-oRad),height-2], [width*oRad,height-2], [2,height*(1-oRad)] ]

drawPoints := [] ;set example polygons to be empty, user will define these
fillPoints := []
bothPoints := []

overlay := new ShinsOverlayClass(x,y,width,height,0,0,1)
opacity := 0xBB

onmessage(0x201,"WindowMove")
moving := false
settimer,draw,10
return


draw:
if (moving) {
	postmessage,0xA1,2,,,% "ahk_id " overlay.hwnd
	while(GetKeyState("lbutton","p")) {
		sleep 100
	}
	moving := false
}
if (overlay.BeginDraw()) {
	
	;draw background window
	overlay.FillPolygon(windowPolygon,(opacity<<24))
	overlay.DrawPolygon(windowPolygon,0xFF000000,2)
	
	
	overlay.FillPolygon(fillPoints,0x6600FF00)
	overlay.DrawPolygon(drawPoints,0xFF0000)
	
	overlay.FillPolygon(bothPoints,0x6622908A)
	overlay.DrawPolygon(bothPoints,0x00FFF1)
	
	overlay.DrawText("Press ESC to close",0,2,32,0xFFFF0000,"Arial","dsFF000000 aCenter w" width " h" height)

	overlay.DrawText("Press F1 to add points for DrawPolygon`nPress F2 to add points for FillPolygon`nPress F3 for both`nYou would only see it form after adding 3+ points!",0,height*0.1,24,0xFFFFFFFF,"Arial","dsFF000000 aCenter w" width " h" height)

	overlay.EndDraw()
}
return


#if WinActive("ahk_id " overlay.hwnd)

f1::
if (overlay.GetMousePos(x,y))
	drawPoints.push([x,y])
return

f2::
if (overlay.GetMousePos(x,y))
	fillPoints.push([x,y])
return

f3::
if (overlay.GetMousePos(x,y))
	bothPoints.push([x,y])
return

wheeldown::
opacity := (opacity-10 < 1 ? 1 : opacity-10)
return

wheelup::
opacity := (opacity+10 > 255 ? 255 : opacity+10)
return

#if


WindowMove() {
	global moving
	moving := 1
}


f9::Reload
esc::exitapp

