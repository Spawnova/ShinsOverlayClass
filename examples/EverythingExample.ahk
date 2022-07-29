#singleinstance,force
#include ..\shinsoverlayclass.ahk

x := floor(a_screenwidth * 0.2)
y := floor(a_screenheight * 0.2)
width := floor(a_screenwidth * 0.6)
height := floor(a_screenheight * 0.6)

overlay := new ShinsOverlayClass(x,y,width,height,0,0,1)
opacity := 0xBB


step := 1
stepsText := []
stepsText.push("Welcome to the Everything example!`nHere I will demonstrate all of the functions of the class`nPress Left or Right to progress!`nUse scrollwheel to change window opacity")
stepsText.push("Drawing Lines!`nDrawLine(x1, y1, x2, y2, color, thickness:=1, rounded:=0)`n`n")
stepsText.push("Drawing Lines!`nA bunch of little lines could look like rain!")
stepsText.push("Drawing circles and ellipses!`nDrawEllipse(x, y, w, h, color, thickness:=1)`nFillEllipse(x, y, w, h, color)`nDrawCircle(x, y, radius, color, thickness:=1)`nFillCircle(x, y, radius, color)")
stepsText.push("Drawing circles and ellipses!`nMaybe a moving ball?")
stepsText.push("Drawing rectangles!`nDrawRectangle(x, y, w, h, color, thickness:=1)`nFillRectangle(x, y, w, h, color)`nDrawRoundedRectangle(x, y, w, h, radiusX, radiusY, color, thickness:=1)`nFillRoundedRectangle(x, y, w, h, radiusX, radiusY, color)")
stepsText.push("Drawing rectangles!`nA bouncy block!")
stepsText.push("Drawing images!`nDrawImage(image,dstX,dstY,dstW:=0,dstH:=0,srcX:=0,srcY:=0,srcW:=0,srcH:=0,alpha:=1,drawCentered:=0,rotation:=0)")
stepsText.push("Drawing text!`nDrawText(text,x,y,size:=18,color:=0xFF000000,fontName:=""Arial"",extraOptions:="""")")
stepsText.push("That's all folks!")

overlay.GetImageDimensions("stickman.png",stickW,stickH)

trails := []
trailColor := 0xFF00FF00
lastX := -1
lastY := -1

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
	lastX := lastY := -1
}
if (overlay.BeginDraw()) {
	
	;draw background
	overlay.FillRoundedRectangle(0,0,overlay.width,overlay.height,55,55,(opacity<<24))
	overlay.DrawRoundedRectangle(0,0,overlay.width,overlay.height,55,55,0xFFFFFFFF,2)
	
	;draw examples per step
	if (step = 1) {
	
		overlay.DrawText("Use the left and right arrows to navigate between pages`n`nScrollwheel adjusts window opacity",0,height*0.5,42,0xFF99FF8B,"Courier","aCenter dsFF000000 dsx1 dsy1 w" width " h" height)
	
	} else if (step = 2) {
	
		overlay.DrawText("Thin white line",width*0.11,height*0.2,18,0xFFFFFF00)
		overlay.DrawLine(width*0.1,height*0.2,width*0.1,height*0.9,0xFFFFFFFF)
		
		overlay.DrawText("Now green",width*0.26,height*0.2,18,0xFFFFFF00)
		overlay.DrawLine(width*0.25,height*0.2,width*0.25,height*0.9,0xFF00FF00)
		
		overlay.DrawText("Now thick",width*0.41,height*0.2,18,0xFFFFFF00)
		overlay.DrawLine(width*0.4,height*0.2,width*0.4,height*0.9,0xFF00FF00,15)
		
		overlay.DrawText("Now rounded",width*0.56,height*0.2,18,0xFFFFFF00)
		overlay.DrawLine(width*0.55,height*0.2,width*0.55,height*0.9,0xFF00FF00,15,1)
		
		overlay.DrawText("And a thicker line behind`ncan create a border!",width*0.71,height*0.2,18,0xFFFFFF00)
		overlay.DrawLine(width*0.7,height*0.2,width*0.7,height*0.9,0xFFFFFFFF,21,1)
		overlay.DrawLine(width*0.7,height*0.2,width*0.7,height*0.9,0xFF000000,19,1)
		overlay.DrawLine(width*0.7,height*0.2,width*0.7,height*0.9,0xFF00FF00,15,1)
		
	} else if (step = 3) {
	
		rainDir += rainInc * random(1,10)
		if (rainDir > 2.3) {
			rainInc := -0.001
			rainDir := 2.3
		} else if (rainDir < 0.7) {
			rainDir := 0.7
			rainInc := 0.001
		}
		if (objs.length() < 500)
			loop 1
				objs.push(new rain(-500,overlay.width+500,-100,0,(random(200,255)<<24)+(random(95,230)<<16)+(random(200,250)<<8)+random(222,255),overlay.height))
		for k,v in objs
			v.draw(overlay,rainDir)
			
	} else if (step = 4) {
	
		overlay.DrawText("A red circle",width*0.18,height*0.45,18,0xFFFFFF00)
		overlay.FillCircle(width*0.2,height*0.5,10,0xFFFF0000)
		
		overlay.DrawText("A red ellipse",width*0.23,height*0.50,18,0xFFFFFF00)
		overlay.FillEllipse(width*0.25,height*0.55,30,10,0xFFFF0000)
		
		overlay.DrawText("A green circle outline",width*0.38,height*0.45,18,0xFFFFFF00)
		overlay.DrawCircle(width*0.4,height*0.5,10,0xFF00FF00)
		
		overlay.DrawText("A green ellipse outline",width*0.43,height*0.50,18,0xFFFFFF00)
		overlay.DrawEllipse(width*0.45,height*0.55,30,10,0xFF00FF00)
		
		overlay.DrawText("Both!",width*0.58,height*0.45,18,0xFFFFFF00)
		overlay.FillCircle(width*0.6,height*0.5,10,0xFFFF0000)
		overlay.DrawCircle(width*0.6,height*0.5,10,0xFF00FF00)
		
		overlay.DrawText("Both with thickness!",width*0.63,height*0.50,18,0xFFFFFF00)
		overlay.FillEllipse(width*0.65,height*0.55,30,10,0xFFFF0000)
		overlay.DrawEllipse(width*0.65,height*0.55,30,10,0xFF00FF00,3)
		
		
	} else if (step = 5) {
		ballX += ballInc
		if (ballX > width*0.8) {
			ballInc := -ballInc
			ballX := width*0.8
		} else if (ballX < width*0.2) {
			ballInc := -ballInc
			ballX := width*0.2
		}
		overlay.FillEllipse(width*0.5,height*0.62,width*0.5,height*0.1,0xFF777777)
		overlay.DrawEllipse(width*0.5,height*0.62,width*0.5,height*0.1,0xFFFFFFFF,2)
		
		overlay.FillEllipse(ballX,ballY+30,30,15,0x44000000)
		overlay.FillEllipse(ballX,ballY+30,38,15,0x44000000)
		overlay.FillEllipse(ballX,ballY+30,45,15,0x44000000)
		
		overlay.FillCircle(ballX,ballY,30,0xFFFF0000)
		overlay.FillEllipse(ballX,ballY-20,20,10,0x99FFFFFF)
		overlay.DrawCircle(ballX,ballY,30,0xFF000000)
		
	} else if (step = 6) {
	
		overlay.DrawText("A red outline",width*0.09,height*0.3,18,0xFFFFFFFF)
		overlay.DrawRectangle(width*0.1,height*0.35,width*0.05,height*0.5,0xFFFF4D4D)
		
		overlay.DrawText("blue",width*0.24,height*0.3,18,0xFFFFFFFF)
		overlay.FillRectangle(width*0.25,height*0.35,width*0.05,height*0.5,0xFF38C8BF)
		
		overlay.DrawText("Together",width*0.39,height*0.3,18,0xFFFFFFFF)
		overlay.FillRectangle(width*0.4,height*0.35,width*0.05,height*0.5,0xFF38C8BF)
		overlay.DrawRectangle(width*0.4,height*0.35,width*0.05,height*0.5,0xFFFF4D4D,2)
		
		overlay.DrawText("Now rounded",width*0.54,height*0.3,18,0xFFFFFFFF)
		overlay.FillRoundedRectangle(width*0.55,height*0.35,width*0.05,height*0.5,30,30,0xFF38C8BF)
		overlay.DrawRoundedRectangle(width*0.55,height*0.35,width*0.05,height*0.5,30,30,0xFFFF4D4D,2)
		
		overlay.DrawText("Now thick",width*0.69,height*0.3,18,0xFFFFFFFF)
		overlay.FillRoundedRectangle(width*0.7,height*0.35,width*0.05,height*0.5,30,30,0xFF38C8BF)
		overlay.DrawRoundedRectangle(width*0.7,height*0.35,width*0.05,height*0.5,30,30,0xFFFF4D4D,6)
		
		
	} else if (step = 7) {
		
		if (bouncing > 0) {
			bouncing += blockDir * 10
			if (bouncing > 150) {
				blockDir := -blockDir
				bouncing := 150
			}
			bh := bouncing/2
			overlay.FillRoundedRectangle(blockX-bh,blockY+bh,150+bh*2,150-(bouncing/2),bouncing/2,bouncing/14,0xFF0DC8C0)
			overlay.DrawRoundedRectangle(blockX-bh,blockY+bh,150+bh*2,150-(bouncing/2),bouncing/2,bouncing/14,0xFF00FFF4)
			;overlay.FillRoundedRectangle(blockX,blockY+(bouncing/2),150,150-(bouncing/2),bouncing/2,bouncing/4,0xFF0DC8C0)
			;overlay.DrawRoundedRectangle(blockX,blockY+(bouncing/2),150,150-(bouncing/2),bouncing/2,bouncing/4,0xFF00FFF4)
		} else {
			blockY += blockDir * 10
			if (blockY < blockMin) {
				blockY := blockMin
				blockDir := 1
			} else if (blockY > blockMax) {
				bouncing := 1
			}
			overlay.FillRectangle(blockX,blockY,150,150,0xFF0DC8C0)
			overlay.DrawRectangle(blockX,blockY,150,150,0xFF00FFF4)
		}
		
	} else if (step = 8) {
		
		overlay.DrawText("Draw basic tile sprite",width*0.1,height*0.25,18,0xFFFFFFFF)
		overlay.FillRectangle(width*0.1,height*0.3,stickW,stickH,0x99FFFFFF)
		overlay.DrawImage("stickman.png",width*0.1,height*0.3)
		
		overlay.DrawText("Increase the size",width*0.3,height*0.25,18,0xFFFFFFFF)
		overlay.FillRectangle(width*0.3,height*0.3,128*4,128,0x99FFFFFF)
		overlay.DrawImage("stickman.png",width*0.3,height*0.3,128*4,128)
		
		overlay.DrawText("Now just 1 frame",width*0.1,height*0.45,18,0xFFFFFFFF)
		overlay.FillRectangle(width*0.1,height*0.5,128,128,0x99FFFFFF)
		overlay.DrawImage("stickman.png",width*0.1,height*0.5,128,128,0,0,32,stickH)
		
		stickIndex--
		if (stickIndex = 0) {
			stickIndex := stickSpeed
			stickFrame++
			if (stickFrame = 4)
				stickFrame := 0
		}
		stickRot+=1
		if (stickRot > 360)
			stickRot := 0
		
		overlay.DrawText("Now animate the frames",width*0.3,height*0.55,18,0xFFFFFFFF)
		overlay.FillRectangle(width*0.3,height*0.6,128,128,0x99FFFFFF)
		overlay.DrawImage("stickman.png",width*0.3,height*0.6,128,128,stickFrame*32,0,32,stickH)
		
		overlay.DrawText("Now rotating",width*0.5,height*0.60,18,0xFFFFFFFF)
		overlay.FillRectangle(width*0.5,height*0.65,128,128,0x99FFFFFF)
		overlay.DrawImage("stickman.png",width*0.5,height*0.65,128,128,stickFrame*32,0,32,stickH,1,0,stickRot)
		
	} else if (step = 9) {
	
		overlay.FillRectangle(width*0.1,height*0.3,width*0.3,height*0.3,0xFF999999)
		overlay.DrawText("Font: Arial, Size: 18",width*0.1,height*0.3,18,0xFFFFFFFF,"Arial")
		overlay.DrawText("Now Font = Courier",width*0.1,height*0.33,18,0xFFFFFFFF,"Courier")
		overlay.DrawText("Now aligned on the right",width*0.1,height*0.36,18,0xFFFFFFFF,"Courier","aRight w" width*0.3 " h" height*0.3)
		overlay.DrawText("Now aligned center",width*0.1,height*0.39,18,0xFFFFFFFF,"Courier","aCenter w" width*0.3 " h" height*0.3)
		overlay.DrawText("Now red",width*0.1,height*0.42,18,0xFFFF0000,"Courier","aCenter w" width*0.3 " h" height*0.3)
		overlay.DrawText("Now with a dropshadow",width*0.1,height*0.45,18,0xFFFF2D2D,"Courier","aCenter dsFF000000 dsx1 dsy1 w" width*0.3 " h" height*0.3)
		overlay.DrawText("Now BIG and GREEN",width*0.1,height*0.52,32,0xFF46FF2D,"Courier","aCenter dsFF000000 dsx1 dsy1 w" width*0.3 " h" height*0.3)
	
	} else if (step = 10) {
		
		overlay.DrawText("Check out my github for my latest projects",0,height*0.2,56,0xFF99FF8B,"Courier","aCenter dsFF000000 dsx1 dsy1 w" width " h" height)
		overlay.DrawText("github.com/Spawnova",0,height*0.3,64,0xFF46FF2D,"Courier","aCenter dsFF000000 dsx1 dsy1 w" width " h" height)
		overlay.DrawText("I plan to keep all my projects up to date and to add new features and functions!`n`nPlease let me know if you run into any issues by creating`nan issue/discussion on the github page`nI check there daily and always have time to answer questions and attempt to fix problems!",0,height*0.43,32,0xFFFF8B8B,"Courier","aCenter dsFF000000 dsx1 dsy1 w" width " h" height)
		overlay.DrawText("Thank you for using my class and have fun out there!",0,height*0.8,42,0xFF5BFFF5,"Courier","aCenter dsFF000000 dsx1 dsy1 w" width " h" height)
	}
	
	if (overlay.GetMousePos(mx,my)) {
		if (lastX != -1 and (lastX != mx or lastY != my)) {
			trails.push(new mouseTrail(lastX,lastY,mx,my,trailColor))
		}
		lastX := mx
		lastY := my
	} else {
		lastX := lastY := -1
	}
	
	i := 1
	while(i < trails.length()) {
		if (!trails[i].draw(overlay)) {
			trails.removeat(i)
		} else {
			i++
		}
	}
	
	;draw text elements
	overlay.DrawText(stepsText[step],50,50,24,0xFFFFFFFF,"Arial","dsFF000000")
	overlay.DrawText("Press ESC to close",overlay.width-400,50,32,0xFFCC0000,"Arial","aRight dsFF222222 w" 400-50)
	overlay.DrawText("Page " step " of " stepsText.length(),50,overlay.height-74,24,0xFFFFFFFF,"Arial","dsFF000000")
	overlay.EndDraw()
}
return


WindowMove() {
	global moving
	moving := 1
}


f9::Reload
esc::exitapp


#if WinActive("ahk_id " overlay.hwnd)

left::
if (step > 1) {
	step--
	gosub checkStep
}
return

right::
if (step < stepsText.length()) {
	step++
	gosub checkStep
}
return

wheeldown::
opacity := (opacity-10 < 1 ? 1 : opacity-10)
return

wheelup::
opacity := (opacity+10 > 255 ? 255 : opacity+10)
return

#if

checkStep:
trailColor := 0xFF000000 + (random(128,255)<<16) + (random(128,255)<<8) + random(128,255)
objs := []
if (step = 3) {
	trailColor := 0xFFFFFF00
	rainDir := 1.6
	rainInc := 0.001
} else if (step = 5) {
	ballX := width*0.2
	ballY := height*0.6
	ballInc := 5
} else if (Step = 7) {
	blockX := width*0.45
	blockY := height*0.25
	blockMin := blockY
	blockMax := height*0.8
	blockDir := 1
	bouncing := 0
} else if (step = 8) {
	stickFrame := 0
	stickSpeed := 10
	stickIndex := stickSpeed
	stickRot := 0
}
return


class Rain {
	__New(minx,maxx,miny,maxy,col,maxHeight) {
		 this.minx := minx
		 this.maxx := maxx
		 this.miny := miny
		 this.maxy := maxy
		 this.col := col
		 this.SetRandom()
		 this.maxHeight := maxHeight - Random(0,100)
		 this.puddle := 0
		 this.puddlex := random(0.33,1.00) * (this.speed/2)
		 this.puddley := this.puddlex / 2
	}

	SetRandom() {
		this.speed := random(14.91,32.12)
		this.x := random(this.minx,this.maxx)
		this.y := random(this.miny,this.maxy)
	}
	
	Draw(o,dir) {
		if (this.puddle > 0) {
			this.puddle -= random(1,5)
			if (this.puddle < 1) {
				this.puddle := 0
				this.SetRandom()
			} else {
				o.FillEllipse(this.x,this.y,this.puddlex,this.puddley,(this.puddle<<24) + 0x89E0F1)
			}
		} else {
			x2 := this.x + (cos(dir) * this.speed)
			y2 := this.y + (sin(dir) * this.speed)
			o.DrawLine(this.x,this.y,x2,y2,this.col)
			this.x := x2
			this.y := y2
			if (this.y > this.maxHeight) {
				this.puddle := 255
			}
		}
	}
}

class mouseTrail {
	__New(x1,y1,x2,y2,color) {
		this.x1 := x1
		this.y1 := y1
		this.x2 := x2
		this.y2 := y2
		this.alpha := (color&0xFF000000)>>24
		this.rgb := (color&0xFFFFFF)
	}
	
	Draw(o) {
		this.alpha -= 5
		if (this.alpha < 1)
			return 0
		o.DrawLine(this.x1,this.y1,this.x2,this.y2,(this.alpha<<24)+this.rgb,(this.alpha / 255) * 10,1)
		return 1
	}
}


Random(min,max) {
	random,result,min,max
	return result
}
