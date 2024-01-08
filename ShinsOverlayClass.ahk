;Direct2d overlay class by Spawnova (5/27/2022)
;https://github.com/Spawnova/ShinsOverlayClass
;
;I'm not a professional programmer, I do this for fun, if it doesn't work for you I can try and help
;but I can't promise I will be able to solve the issue
;
;Special thanks to teadrinker for helping me understand some 64bit param structures! -> https://www.autohotkey.com/boards/viewtopic.php?f=76&t=105420

#Requires AutoHotkey v1.1.27+

class ShinsOverlayClass {

	;x_orTitle					:		x pos of overlay OR title of window to attach to
	;y_orClient					:		y pos of overlay OR attach to client instead of window (default window)
	;width_orForeground			:		width of overlay OR overlay is only drawn when the attached window is in the foreground (default 1)
	;height						:		height of overlay
	;alwaysOnTop				:		If enabled, the window will always appear over other windows
	;vsync						:		If enabled vsync will cause the overlay to update no more than the monitors refresh rate, useful when looping without sleeps
	;clickThrough				:		If enabled, mouse clicks will pass through the window onto the window beneath
	;taskBarIcon				:		If enabled, the window will have a taskbar icon
	;guiID						:		name of the ahk gui id for the overlay window, if 0 defaults to "ShinsOverlayClass_TICKCOUNT"
	;
	;notes						:		if planning to attach to window these parameters can all be left blank
	
	__New(x_orTitle:=0,y_orClient:=1,width_orForeground:=1,height:=0,alwaysOnTop:=1,vsync:=0,clickThrough:=1,taskBarIcon:=0,guiID:=0) {
	
	
		;[input variables] you can change these to affect the way the script behaves
		
		this.interpolationMode := 0 ;0 = nearestNeighbor, 1 = linear ;affects DrawImage() scaling 
		this.data := []				;reserved name for general data storage
	
	
		;[output variables] you can read these to get extra info, DO NOT MODIFY THESE
		
		this.x := x_orTitle					;overlay x position OR title of window to attach to
		this.y := y_orClient				;overlay y position OR attach to client area
		this.width := width_orForeground	;overlay width OR attached overlay only drawn when window is in foreground
		this.height := height				;overlay height
		this.x2 := x_orTitle+width_orForeground
		this.y2 := y_orClient+height
		this.attachHWND := 0				;HWND of the attached window, 0 if not attached
		this.attachClient := 0				;1 if using client space, 0 otherwise
		this.attachForeground := 0			;1 if overlay is only drawn when the attached window is the active window; 0 otherwise
		
		;Generally with windows there are invisible borders that allow
		;the window to be resized, but it makes the window larger
		;these values should contain the window x, y offset and width, height for actual postion and size
		this.realX := 0
		this.realY := 0
		this.realWidth := 0
		this.realHeight := 0
		this.realX2 := 0
		this.realY2 := 0
		
		this.callbacks := {"Size":0,"Position":0,"Active":0}
		;Size 		: 		[this]
		;Position:	:		[this]
		;Active		:		[this,state]
	
	
	
	
	
		;#############################
		;	Setup internal stuff
		;#############################
		this.bits := (a_ptrsize == 8)
		this.imageCache := []
		this.fonts := []
		this.lastPos := 0
		this.offX := -x_orTitle
		this.offY := -y_orClient
		this.lastCol := 0
		this.drawing := -1
		this.guiID := guiID := (guiID = 0 ? "ShinsOverlayClass_" a_tickcount : guiID)
		this.owned := 0
		this.alwaysontop := alwaysontop
		
		
		this._cacheImage := this.mcode("VVdWMfZTg+wMi0QkLA+vRCQoi1QkMMHgAoXAfmSLTCQki1wkIA+26gHIiUQkCGaQD7Z5A4PDBIPBBIn4D7bwD7ZB/g+vxpn3/YkEJA+2Qf0Pr8aZ9/2JRCQED7ZB/A+vxpn3/Q+2FCSIU/wPtlQkBIhT/YhD/on4iEP/OUwkCHWvg8QMifBbXl9dw5CQkJCQ|V1ZTRTHbRItUJEBFD6/BRo0MhQAAAABFhcl+YUGD6QFFD7bSSYnQQcHpAkqNdIoERQ+2WANBD7ZAAkmDwARIg8EEQQ+vw5lB9/qJx0EPtkD9QQ+vw5lB9/pBicFBD7ZA/ECIefxEiEn9QQ+vw0SIWf+ZQff6iEH+TDnGdbNEidhbXl/DkJCQkJCQkJCQkJCQ")
		
		this.LoadLib("d2d1","dwrite","dwmapi","gdiplus")
		VarSetCapacity(gsi, 24, 0)
		NumPut(1,gsi,0,"uint")
		DllCall("gdiplus\GdiplusStartup", "Ptr*", token, "Ptr", &gsi, "Ptr", 0)
		this.gdiplusToken := token
		this._guid("{06152247-6f50-465a-9245-118bfd3b6007}",clsidFactory)
		this._guid("{b859ee5a-d838-4b5b-a2e8-1adc7d93db48}",clsidwFactory)
		
		if (clickThrough)
			gui %guiID%: +hwndhwnd -Caption +E0x80000 +E0x20
		else
			gui %guiID%: +hwndhwnd -Caption +E0x80000
		if (alwaysOnTop)
			gui %guiID%: +AlwaysOnTop
		if (!taskBarIcon)
			gui %guiID%: +ToolWindow
		
		this.hwnd := hwnd
		DllCall("ShowWindow","Uptr",this.hwnd,"uint",(clickThrough ? 8 : 1))

		this.tBufferPtr := this.SetVarCapacity("ttBuffer",4096)
		this.rect1Ptr := this.SetVarCapacity("_rect1",64)
		this.rect2Ptr := this.SetVarCapacity("_rect2",64)
		this.rtPtr := this.SetVarCapacity("_rtPtr",64)
		this.hrtPtr := this.SetVarCapacity("_hrtPtr",64)
		this.matrixPtr := this.SetVarCapacity("_matrix",64)
		this.colPtr := this.SetVarCapacity("_colPtr",64)
		this.clrPtr := this.SetVarCapacity("_clrPtr",64)
		VarSetCapacity(margins,16)
		NumPut(-1,margins,0,"int"), NumPut(-1,margins,4,"int"), NumPut(-1,margins,8,"int"), NumPut(-1,margins,12,"int")
		ext := DllCall("dwmapi\DwmExtendFrameIntoClientArea","Uptr",hwnd,"ptr",&margins,"uint")
		if (ext != 0) {
			this.Err("Problem with DwmExtendFrameIntoClientArea","overlay will not function`n`nReloading the script usually fixes this`n`nError: " DllCall("GetLastError","uint") " / " ext)
			return
		}
		DllCall("SetLayeredWindowAttributes","Uptr",hwnd,"Uint",0,"char",255,"uint",2)
		if (DllCall("d2d1\D2D1CreateFactory","uint",1,"Ptr",&clsidFactory,"uint*",0,"Ptr*",factory) != 0) {
			this.Err("Problem creating factory","overlay will not function`n`nError: " DllCall("GetLastError","uint"))
			return
		}
		this.factory := factory
		NumPut(255,this.tBufferPtr,16,"float")
		if (DllCall(this.vTable(this.factory,11),"ptr",this.factory,"ptr",this.tBufferPtr,"ptr",0,"uint",0,"ptr*",stroke) != 0) {
			this.Err("Problem creating stroke","overlay will not function`n`nError: " DllCall("GetLastError","uint"))
			return
		}
		this.stroke := stroke
		NumPut(2,this.tBufferPtr,0,"uint")
		NumPut(2,this.tBufferPtr,4,"uint")
		NumPut(2,this.tBufferPtr,12,"uint")
		NumPut(255,this.tBufferPtr,16,"float")
		if (DllCall(this.vTable(this.factory,11),"ptr",this.factory,"ptr",this.tBufferPtr,"ptr",0,"uint",0,"ptr*",stroke) != 0) {
			this.Err("Problem creating rounded stroke","overlay will not function`n`nError: " DllCall("GetLastError","uint"))
			return
		}
		this.strokeRounded := stroke
		NumPut(1,this.rtPtr,8,"uint")
		NumPut(96,this.rtPtr,12,"float")
		NumPut(96,this.rtPtr,16,"float")
		NumPut(hwnd,this.hrtPtr,0,"Uptr")
		NumPut(width_orForeground,this.hrtPtr,a_ptrsize,"uint")
		NumPut(height,this.hrtPtr,a_ptrsize+4,"uint")
		NumPut((vsync?0:2),this.hrtPtr,a_ptrsize+8,"uint")
		if (DllCall(this.vTable(this.factory,14),"Ptr",this.factory,"Ptr",this.rtPtr,"ptr",this.hrtPtr,"Ptr*",renderTarget) != 0) {
			this.Err("Problem creating renderTarget","overlay will not function`n`nError: " DllCall("GetLastError","uint"))
			return
		}
		this.renderTarget := renderTarget
		NumPut(1,this.matrixPtr,0,"float")
		this.SetIdentity(4)
		if (DllCall(this.vTable(this.renderTarget,8),"Ptr",this.renderTarget,"Ptr",this.colPtr,"Ptr",this.matrixPtr,"Ptr*",brush) != 0) {
			this.Err("Problem creating brush","overlay will not function`n`nError: " DllCall("GetLastError","uint"))
			return
		}
		this.brush := brush
		DllCall(this.vTable(this.renderTarget,32),"Ptr",this.renderTarget,"Uint",1)
		if (DllCall("dwrite\DWriteCreateFactory","uint",0,"Ptr",&clsidwFactory,"Ptr*",wFactory) != 0) {
			this.Err("Problem creating writeFactory","overlay will not function`n`nError: " DllCall("GetLastError","uint"))
			return
		}
		this.wFactory := wFactory
		
		if (x_orTitle != 0 and winexist(x_orTitle))
			this.AttachToWindow(x_orTitle,y_orClient,width_orForeground)
		 else
			this.SetPosition(x_orTitle,y_orClient)
		
		DllCall(this.vTable(this.renderTarget,48),"Ptr",this.renderTarget)
		DllCall(this.vTable(this.renderTarget,47),"Ptr",this.renderTarget,"Ptr",this.clrPtr)
		DllCall(this.vTable(this.renderTarget,49),"Ptr",this.renderTarget,"int64*",tag1,"int64*",tag2)
	}
	
	
	;####################################################################################################################################################################################################################################
	;AttachToWindow
	;
	;title				:				Title of the window (or other type of identifier such as 'ahk_exe notepad.exe' etc..
	;attachToClientArea	:				Whether or not to attach the overlay to the client area, window area is used otherwise
	;foreground			:				Whether or not to only draw the overlay if attached window is active in the foreground, otherwise always draws
	;setOwner			:				Sets the ownership of the overlay window to the target window
	;
	;return				;				Returns 1 if either attached window is active in the foreground or no window is attached; 0 otherwise
	;
	;Notes				;				Does not actually 'attach', but rather every BeginDraw() fuction will check to ensure it's 
	;									updated to the attached windows position/size
	;									Could use SetParent but it introduces other issues, I'll explore further later
	
	AttachToWindow(title,AttachToClientArea:=0,foreground:=1,setOwner:=0) {
		if (title = "") {
			this.Err("AttachToWindow: Error","Expected title string, but empty variable was supplied!")
			return 0
		}
		if (!this.attachHWND := winexist(title)) {
			this.Err("AttachToWindow: Error","Could not find window - " title)
			return 0
		}
		numput(this.attachHwnd,this.tbufferptr,0,"UPtr")
		this.attachHWND := numget(this.tbufferptr,0,"Uptr")
		if (!DllCall("GetWindowRect","Uptr",this.attachHWND,"ptr",this.tBufferPtr)) {
			this.Err("AttachToWindow: Error","Problem getting window rect, is window minimized?`n`nError: " DllCall("GetLastError","uint"))
			return 0
		}
		x := NumGet(this.tBufferPtr,0,"int")
		y := NumGet(this.tBufferPtr,4,"int")
		w := NumGet(this.tBufferPtr,8,"int")-x
		h := NumGet(this.tBufferPtr,12,"int")-y
		this.attachClient := AttachToClientArea
		this.attachForeground := foreground
		this.AdjustWindow(x,y,w,h)
		
		VarSetCapacity(newSize,16)
		NumPut(this.width,newSize,0,"uint")
		NumPut(this.height,newSize,4,"uint")
		DllCall(this.vTable(this.renderTarget,58),"Ptr",this.renderTarget,"ptr",&newsize)
		this.SetPosition(x,y,this.width,this.height)
		if (setOwner) {
			this.alwaysontop := 0
			WinSet, AlwaysOnTop, off, % "ahk_id " this.hwnd
			this.owned := 1
			dllcall("SetWindowLongPtr","Uptr",this.hwnd,"int",-8,"Uptr",this.attachHWND)
			this.SetPosition(this.x,this.y)
		} else {
			this.owned := 0
		}
	}
	
	
	;####################################################################################################################################################################################################################################
	;BeginDraw
	;
	;return				;				Returns 1 if either attached window is active in the foreground or no window is attached; 0 otherwise
	;
	;Notes				;				Must always call EndDraw to finish drawing and update the overlay
	
	BeginDraw() {
		if (this.attachHWND) {
			if (!DllCall("GetWindowRect","Uptr",this.attachHWND,"ptr",this.tBufferPtr) or (this.attachForeground and DllCall("GetForegroundWindow","cdecl Ptr") != this.attachHWND)) {
				if (this.drawing) {
					if (this.callbacks["active"])
						this.callbacks["active"].call(this,0)
					this.Clear()
					this.drawing := 0
				}
				return 0
			}
			x := NumGet(this.tBufferPtr,0,"int")
			y := NumGet(this.tBufferPtr,4,"int")
			w := NumGet(this.tBufferPtr,8,"int")-x
			h := NumGet(this.tBufferPtr,12,"int")-y
			if ((w<<16)+h != this.lastSize) {
				this.AdjustWindow(x,y,w,h)
				VarSetCapacity(newSize,16,0)
				NumPut(this.width,newSize,0,"uint")
				NumPut(this.height,newSize,4,"uint")
				DllCall(this.vTable(this.renderTarget,58),"Ptr",this.renderTarget,"ptr",&newsize)
				this.SetPosition(x,y)
				if (this.callbacks["size"])
					this.callbacks["size"].call(this)
			} else if ((x<<16)+y != this.lastPos) {
				this.AdjustWindow(x,y,w,h)
				this.SetPosition(x,y)
				if (this.callbacks["position"])
					this.callbacks["position"].call(this)
			}
			if (!this.drawing and this.alwaysontop) {
				winset,alwaysontop,on,% "ahk_id " this.hwnd
			}
			
		} else {
			if (!DllCall("GetWindowRect","Uptr",this.hwnd,"ptr",this.tBufferPtr)) {
				if (this.drawing) {
					if (this.callbacks["active"])
						this.callbacks["active"].call(this,0)
					this.Clear()
					this.drawing := 0
				}
				return 0
			}
			x := NumGet(this.tBufferPtr,0,"int")
			y := NumGet(this.tBufferPtr,4,"int")
			w := NumGet(this.tBufferPtr,8,"int")-x
			h := NumGet(this.tBufferPtr,12,"int")-y
			if ((w<<16)+h != this.lastSize) {
				this.AdjustWindow(x,y,w,h)
				VarSetCapacity(newSize,16)
				NumPut(this.width,newSize,0,"uint")
				NumPut(this.height,newSize,4,"uint")
				DllCall(this.vTable(this.renderTarget,58),"Ptr",this.renderTarget,"ptr",&newsize)
				this.SetPosition(x,y)
				if (this.callbacks["size"])
					this.callbacks["size"].call(this)
			} else if ((x<<16)+y != this.lastPos) {
				this.AdjustWindow(x,y,w,h)
				this.SetPosition(x,y)
				if (this.callbacks["position"])
					this.callbacks["position"].call(this)
			}
		}
		if (this.drawing = 0) {
			if (this.callbacks["active"])
				this.callbacks["active"].call(this,1)
		}
		this.drawing := 1
		DllCall(this.vTable(this.renderTarget,48),"Ptr",this.renderTarget)
		DllCall(this.vTable(this.renderTarget,47),"Ptr",this.renderTarget,"Ptr",this.clrPtr)
		return 1
	}
	
	
	;####################################################################################################################################################################################################################################
	;EndDraw
	;
	;return				;				Void
	;
	;Notes				;				Must always call EndDraw to finish drawing and update the overlay
	
	EndDraw() {
		if (this.drawing)
			DllCall(this.vTable(this.renderTarget,49),"Ptr",this.renderTarget,"int64*",tag1,"int64*",tag2)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawImage
	;
	;dstX				:				X position to draw to
	;dstY				:				Y position to draw to
	;dstW				:				Width of image to draw to
	;dstH				:				Height of image to draw to
	;srcX				:				X position to draw from
	;srcY				:				Y position to draw from
	;srcW				:				Width of image to draw from
	;srcH				:				Height of image to draw from
	;alpha				:				Image transparency, float between 0 and 1
	;drawCentered		:				Draw the image centered on dstX/dstY, otherwise dstX/dstY will be the top left of the image
	;rotation			:				Image rotation in degrees (0-360)
	;rotationOffsetX	:				X offset to base rotations on (defaults to center x)
	;rotationOffsetY	:				Y offset to base rotations on (defaults to center y)
	;
	;return				;				Void
	
	DrawImage(image,dstX,dstY,dstW:=0,dstH:=0,srcX:=0,srcY:=0,srcW:=0,srcH:=0,alpha:=1,drawCentered:=0,rotation:=0,rotOffX:=0,rotOffY:=0) {
		if (!i := this.imageCache[image]) {
			i := this.cacheImage(image)
		}
		if (dstW <= 0)
			dstW := i.w
		if (dstH <= 0)
			dstH := i.h
		x := dstX-(drawCentered?dstW/2:0)
		y := dstY-(drawCentered?dstH/2:0)
		NumPut(x,this.rect1Ptr,0,"float")
		NumPut(y,this.rect1Ptr,4,"float")
		NumPut(x + dstW,this.rect1Ptr,8,"float")
		NumPut(y + dstH,this.rect1Ptr,12,"float")
		NumPut(srcX,this.rect2Ptr,0,"float")
		NumPut(srcY,this.rect2Ptr,4,"float")
		NumPut(srcX + (srcW=0?i.w:srcW),this.rect2Ptr,8,"float")
		NumPut(srcY + (srcH=0?i.h:srcH),this.rect2Ptr,12,"float")
		
		if (rotation != 0) {
			if (this.bits) {
				if (rotOffX or rotOffY) {
					NumPut(dstX+rotOffX,this.tBufferPtr,0,"float")
					NumPut(dstY+rotOffY,this.tBufferPtr,4,"float")
					tooltip k
				} else {
					NumPut(dstX+(drawCentered?0:dstW/2),this.tBufferPtr,0,"float")
					NumPut(dstY+(drawCentered?0:dstH/2),this.tBufferPtr,4,"float")
				}
				DllCall("d2d1\D2D1MakeRotateMatrix","float",rotation,"double",NumGet(this.tBufferPtr,"double"),"ptr",this.matrixPtr)
			} else {
				DllCall("d2d1\D2D1MakeRotateMatrix","float",rotation,"float",dstX+(drawCentered?0:dstW/2),"float",dstY+(drawCentered?0:dstH/2),"ptr",this.matrixPtr)
			}
			DllCall(this.vTable(this.renderTarget,30),"ptr",this.renderTarget,"ptr",this.matrixPtr)
			DllCall(this.vTable(this.renderTarget,26),"ptr",this.renderTarget,"ptr",i.p,"ptr",this.rect1Ptr,"float",alpha,"uint",this.interpolationMode,"ptr",this.rect2Ptr)
			this.SetIdentity()
			DllCall(this.vTable(this.renderTarget,30),"ptr",this.renderTarget,"ptr",this.matrixPtr)
		} else {
			DllCall(this.vTable(this.renderTarget,26),"ptr",this.renderTarget,"ptr",i.p,"ptr",this.rect1Ptr,"float",alpha,"uint",this.interpolationMode,"ptr",this.rect2Ptr)
		}
	}
	
	
	;####################################################################################################################################################################################################################################
	;GetTextMetrics
	;
	;text				:				The text to get the metrics of
	;size				:				Font size to measure with
	;fontName			:				Name of the font to use
	;maxWidth			:				Max width (smaller width may cause wrapping)
	;maxHeight			:				Max Height
	;
	;return				;				An array containing width, height and line count of the string
	;
	;Notes				;				Used to measure a string before drawing it
	
	GetTextMetrics(text,size,fontName,maxWidth:=5000,maxHeight:=5000) {
		local
		if (!p := this.fonts[fontName size]) {
			p := this.CacheFont(fontName,size)
		}
		varsetcapacity(bf,64)
		DllCall(this.vTable(this.wFactory,18),"ptr",this.wFactory,"WStr",text,"uint",strlen(text),"Ptr",p,"float",maxWidth,"float",maxHeight,"Ptr*",layout)
		DllCall(this.vTable(layout,60),"ptr",layout,"ptr",&bf,"uint")
		
		w := numget(bf,8,"float")
		wTrailing := numget(bf,12,"float")
		h := numget(bf,16,"float")
		
		DllCall(this.vTable(layout,2),"ptr",layout)
		
		return {w:w,width:w,h:h,height:h,wt:wTrailing,widthTrailing:w,lines:numget(bf,32,"uint")}
		
	}
	
	
	;####################################################################################################################################################################################################################################
	;SetTextRenderParams
	;
	;gamma				:				Gamma value ................. (1 > 256)
	;contrast			:				Contrast value .............. (0.0 > 1.0)
	;clearType			:				Clear type level ............ (0.0 > 1.0)
	;pixelGeom			:				
	;									0 - DWRITE_PIXEL_GEOMETRY_FLAT
    ;									1 - DWRITE_PIXEL_GEOMETRY_RGB
    ;									2 - DWRITE_PIXEL_GEOMETRY_BGR
	;
	;renderMode			:				
    ; 									0 - DWRITE_RENDERING_MODE_DEFAULT
    ; 									1 - DWRITE_RENDERING_MODE_ALIASED
    ; 									2 - DWRITE_RENDERING_MODE_GDI_CLASSIC
    ; 									3 - DWRITE_RENDERING_MODE_GDI_NATURAL
    ; 									4 - DWRITE_RENDERING_MODE_NATURAL
    ; 									5 - DWRITE_RENDERING_MODE_NATURAL_SYMMETRIC
    ; 									6 - DWRITE_RENDERING_MODE_OUTLINE
	;									7 - DWRITE_RENDERING_MODE_CLEARTYPE_GDI_CLASSIC
	;									8 - DWRITE_RENDERING_MODE_CLEARTYPE_GDI_NATURAL
	;									9 - DWRITE_RENDERING_MODE_CLEARTYPE_NATURAL
	;									10 - DWRITE_RENDERING_MODE_CLEARTYPE_NATURAL_SYMMETRIC
	;
	;return				;				Void
	;
	;Notes				;				Used to affect how text is rendered
	
	SetTextRenderParams(gamma:=1,contrast:=0,cleartype:=1,pixelGeom:=0,renderMode:=0) {
		local
		DllCall(this.vTable(this.wFactory,12),"ptr",this.wFactory,"Float",gamma,"Float",contrast,"Float",cleartype,"Uint",pixelGeom,"Uint",renderMode,"Ptr*",params) "`n" params
		DllCall(this.vTable(this.renderTarget,36),"Ptr",this.renderTarget,"Ptr",params)
	}
	
	
	
	
	;####################################################################################################################################################################################################################################
	;DrawText
	;
	;text				:				The text to be drawn
	;x					:				X position
	;y					:				Y position
	;size				:				Size of font
	;color				:				Color of font
	;fontName			:				Font name (must be installed)
	;extraOptions		:				Additonal options which may contain any of the following seperated by spaces:
	;									Width .............	w[number]				: Example > w200			(Default: this.width)
	;									Height ............	h[number]				: Example > h200			(Default: this.height)
	;									Alignment ......... a[Left/Right/Center]	: Example > aCenter			(Default: Left)
	;									DropShadow ........	ds[hex color]			: Example > dsFF000000		(Default: DISABLED)
	;									DropShadowXOffset . dsx[number]				: Example > dsx2			(Default: 1)
	;									DropShadowYOffset . dsy[number]				: Example > dsy2			(Default: 1)
	;									Outline ........... ol[hex color]			: Example > olFF000000		(Default: DISABLED)
	;
	;return				;				Void
	
	DrawText(text,x,y,size:=18,color:=0xFFFFFFFF,fontName:="Arial",extraOptions:="") {
		local
		if (!RegExMatch(extraOptions,"w([\d\.]+)",w))
			w1 := this.width
		if (!RegExMatch(extraOptions,"h([\d\.]+)",h))
			h1 := this.height
		
		if (!p := this.fonts[fontName size]) {
			p := this.CacheFont(fontName,size)
		}
		
		DllCall(this.vTable(p,3),"ptr",p,"uint",(InStr(extraOptions,"aRight") ? 1 : InStr(extraOptions,"aCenter") ? 2 : 0))
		
		if (RegExMatch(extraOptions,"ds([a-fA-F\d]+)",ds)) {
			if (!RegExMatch(extraOptions,"dsx([\d\.]+)",dsx))
				dsx1 := 1
			if (!RegExMatch(extraOptions,"dsy([\d\.]+)",dsy))
				dsy1 := 1
			this.DrawTextShadow(p,text,x+dsx1,y+dsy1,w1,h1,"0x" ds1)
		} else if (RegExMatch(extraOptions,"ol([a-fA-F\d]+)",ol)) {
			this.DrawTextOutline(p,text,x,y,w1,h1,"0x" ol1)
		}
		
		this.SetBrushColor(color)
		NumPut(x,this.tBufferPtr,0,"float")
		NumPut(y,this.tBufferPtr,4,"float")
		NumPut(x+w1,this.tBufferPtr,8,"float")
		NumPut(y+h1,this.tBufferPtr,12,"float")
		
		DllCall(this.vTable(this.renderTarget,27),"ptr",this.renderTarget,"wstr",text,"uint",strlen(text),"ptr",p,"ptr",this.tBufferPtr,"ptr",this.brush,"uint",0,"uint",0)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawEllipse
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of ellipse
	;h					:				Height of ellipse
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawEllipse(x, y, w, h, color, thickness:=1) {
		this.SetBrushColor(color)
		NumPut(x,this.tBufferPtr,0,"float")
		NumPut(y,this.tBufferPtr,4,"float")
		NumPut(w,this.tBufferPtr,8,"float")
		NumPut(h,this.tBufferPtr,12,"float")
		DllCall(this.vTable(this.renderTarget,20),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush,"float",thickness,"ptr",this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillEllipse
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of ellipse
	;h					:				Height of ellipse
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillEllipse(x, y, w, h, color) {
		this.SetBrushColor(color)
		NumPut(x,this.tBufferPtr,0,"float")
		NumPut(y,this.tBufferPtr,4,"float")
		NumPut(w,this.tBufferPtr,8,"float")
		NumPut(h,this.tBufferPtr,12,"float")
		DllCall(this.vTable(this.renderTarget,21),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawCircle
	;
	;x					:				X position
	;y					:				Y position
	;radius				:				Radius of circle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawCircle(x, y, radius, color, thickness:=1) {
		this.SetBrushColor(color)
		NumPut(x,this.tBufferPtr,0,"float")
		NumPut(y,this.tBufferPtr,4,"float")
		NumPut(radius,this.tBufferPtr,8,"float")
		NumPut(radius,this.tBufferPtr,12,"float")
		DllCall(this.vTable(this.renderTarget,20),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush,"float",thickness,"ptr",this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillCircle
	;
	;x					:				X position
	;y					:				Y position
	;radius				:				Radius of circle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillCircle(x, y, radius, color) {
		this.SetBrushColor(color)
		NumPut(x,this.tBufferPtr,0,"float")
		NumPut(y,this.tBufferPtr,4,"float")
		NumPut(radius,this.tBufferPtr,8,"float")
		NumPut(radius,this.tBufferPtr,12,"float")
		DllCall(this.vTable(this.renderTarget,21),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawRectangle(x, y, w, h, color, thickness:=1) {
		this.SetBrushColor(color)
		NumPut(x,this.tBufferPtr,0,"float")
		NumPut(y,this.tBufferPtr,4,"float")
		NumPut(x+w,this.tBufferPtr,8,"float")
		NumPut(y+h,this.tBufferPtr,12,"float")
		DllCall(this.vTable(this.renderTarget,16),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush,"float",thickness,"ptr",this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillRectangle(x, y, w, h, color) {
		this.SetBrushColor(color)
		NumPut(x,this.tBufferPtr,0,"float")
		NumPut(y,this.tBufferPtr,4,"float")
		NumPut(x+w,this.tBufferPtr,8,"float")
		NumPut(y+h,this.tBufferPtr,12,"float")
		DllCall(this.vTable(this.renderTarget,17),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawRoundedRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;radiusX			:				The x-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;radiusY			:				The y-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawRoundedRectangle(x, y, w, h, radiusX, radiusY, color, thickness:=1) {
		this.SetBrushColor(color)
		NumPut(x,this.tBufferPtr,0,"float")
		NumPut(y,this.tBufferPtr,4,"float")
		NumPut(x+w,this.tBufferPtr,8,"float")
		NumPut(y+h,this.tBufferPtr,12,"float")
		NumPut(radiusX,this.tBufferPtr,16,"float")
		NumPut(radiusY,this.tBufferPtr,20,"float")
		DllCall(this.vTable(this.renderTarget,18),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush,"float",thickness,"ptr",this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;radiusX			:				The x-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;radiusY			:				The y-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillRoundedRectangle(x, y, w, h, radiusX, radiusY, color) {
		this.SetBrushColor(color)
		NumPut(x,this.tBufferPtr,0,"float")
		NumPut(y,this.tBufferPtr,4,"float")
		NumPut(x+w,this.tBufferPtr,8,"float")
		NumPut(y+h,this.tBufferPtr,12,"float")
		NumPut(radiusX,this.tBufferPtr,16,"float")
		NumPut(radiusY,this.tBufferPtr,20,"float")
		DllCall(this.vTable(this.renderTarget,19),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawLine
	;
	;x1					:				X position for line start
	;y1					:				Y position for line start
	;x2					:				X position for line end
	;y2					:				Y position for line end
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void

	DrawLine(x1,y1,x2,y2,color:=0xFFFFFFFF,thickness:=1,rounded:=0) {
		this.SetBrushColor(color)
		if (this.bits) {
			NumPut(x1,this.tBufferPtr,0,"float")  ;Special thanks to teadrinker for helping me
			NumPut(y1,this.tBufferPtr,4,"float")  ;with these params!
			NumPut(x2,this.tBufferPtr,8,"float")
			NumPut(y2,this.tBufferPtr,12,"float")
			DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"Double",NumGet(this.tBufferPtr,0,"double"),"Double",NumGet(this.tBufferPtr,8,"double"),"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
		} else {
			DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"float",x1,"float",y1,"float",x2,"float",y2,"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
		}
		
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawLines
	;
	;lines				:				An array of 2d points, example: [[0,0],[5,0],[0,5]]
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;connect			:				If 1 then connect the start and end together
	;thickness			:				Thickness of the line
	;
	;return				;				1 on success; 0 otherwise

	DrawLines(points,color,connect:=0,thickness:=1,rounded:=0) {
		if (points.length() < 2)
			return 0
		lx := sx := points[1][1]
		ly := sy := points[1][2]
		this.SetBrushColor(color)
		if (this.bits) {
			loop % points.length()-1 {
				NumPut(lx,this.tBufferPtr,0,"float"), NumPut(ly,this.tBufferPtr,4,"float"), NumPut(lx:=points[a_index+1][1],this.tBufferPtr,8,"float"), NumPut(ly:=points[a_index+1][2],this.tBufferPtr,12,"float")
				DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"Double",NumGet(this.tBufferPtr,0,"double"),"Double",NumGet(this.tBufferPtr,8,"double"),"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
			}
			if (connect) {
				NumPut(sx,this.tBufferPtr,0,"float"), NumPut(sy,this.tBufferPtr,4,"float"), NumPut(lx,this.tBufferPtr,8,"float"), NumPut(ly,this.tBufferPtr,12,"float")
				DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"Double",NumGet(this.tBufferPtr,0,"double"),"Double",NumGet(this.tBufferPtr,8,"double"),"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
			}
		} else {
			loop % points.length()-1 {
				x1 := lx
				y1 := ly
				x2 := lx := points[a_index+1][1]
				y2 := ly := points[a_index+1][2]
				DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"float",x1,"float",y1,"float",x2,"float",y2,"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
			}
			if (connect)
				DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"float",sx,"float",sy,"float",lx,"float",ly,"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
		}
		return 1
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawPolygon
	;
	;points				:				An array of 2d points, example: [[0,0],[5,0],[0,5]]
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;xOffset			:				X offset to draw the polygon array
	;yOffset			:				Y offset to draw the polygon array
	;
	;return				;				1 on success; 0 otherwise

	DrawPolygon(points,color,thickness:=1,rounded:=0,xOffset:=0,yOffset:=0) {
		if (points.length() < 3)
			return 0
		
		if (DllCall(this.vTable(this.factory,10),"Ptr",this.factory,"Ptr*",pGeom) = 0) {
			if (DllCall(this.vTable(pGeom,17),"Ptr",pGeom,"ptr*",sink) = 0) {
				this.SetBrushColor(color)
				if (this.bits) {
					numput(points[1][1]+xOffset,this.tBufferPtr,0,"float")
					numput(points[1][2]+yOffset,this.tBufferPtr,4,"float")
					DllCall(this.vTable(sink,5),"ptr",sink,"double",numget(this.tBufferPtr,0,"double"),"uint",1)
					loop % points.length()-1
					{
						numput(points[a_index+1][1]+xOffset,this.tBufferPtr,0,"float")
						numput(points[a_index+1][2]+yOffset,this.tBufferPtr,4,"float")
						DllCall(this.vTable(sink,10),"ptr",sink,"double",numget(this.tBufferPtr,0,"double"))
					}
					DllCall(this.vTable(sink,8),"ptr",sink,"uint",1)
					DllCall(this.vTable(sink,9),"ptr",sink)
				} else {
					DllCall(this.vTable(sink,5),"ptr",sink,"float",points[1][1]+xOffset,"float",points[1][2]+yOffset,"uint",1)
					loop % points.length()-1
						DllCall(this.vTable(sink,10),"ptr",sink,"float",points[a_index+1][1]+xOffset,"float",points[a_index+1][2]+yOffset)
					DllCall(this.vTable(sink,8),"ptr",sink,"uint",1)
					DllCall(this.vTable(sink,9),"ptr",sink)
				}
				
				if (DllCall(this.vTable(this.renderTarget,22),"Ptr",this.renderTarget,"Ptr",pGeom,"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke)) = 0) {
					DllCall(this.vTable(sink,2),"ptr",sink)
					DllCall(this.vTable(pGeom,2),"Ptr",pGeom)
					return 1
				}
				DllCall(this.vTable(sink,2),"ptr",sink)
				DllCall(this.vTable(pGeom,2),"Ptr",pGeom)
			}
		}
		
		
		return 0
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillPolygon
	;
	;points				:				An array of 2d points, example: [[0,0],[5,0],[0,5]]
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;xOffset			:				X offset to draw the filled polygon array
	;yOffset			:				Y offset to draw the filled polygon array
	;
	;return				;				1 on success; 0 otherwise

	FillPolygon(points,color,xoffset:=0,yoffset:=0) {
		if (points.length() < 3)
			return 0
		
		if (DllCall(this.vTable(this.factory,10),"Ptr",this.factory,"Ptr*",pGeom) = 0) {
			if (DllCall(this.vTable(pGeom,17),"Ptr",pGeom,"ptr*",sink) = 0) {
				this.SetBrushColor(color)
				if (this.bits) {
					numput(points[1][1]+xoffset,this.tBufferPtr,0,"float")
					numput(points[1][2]+yoffset,this.tBufferPtr,4,"float")
					DllCall(this.vTable(sink,5),"ptr",sink,"double",numget(this.tBufferPtr,0,"double"),"uint",0)
					loop % points.length()-1
					{
						numput(points[a_index+1][1]+xoffset,this.tBufferPtr,0,"float")
						numput(points[a_index+1][2]+yoffset,this.tBufferPtr,4,"float")
						DllCall(this.vTable(sink,10),"ptr",sink,"double",numget(this.tBufferPtr,0,"double"))
					}
					DllCall(this.vTable(sink,8),"ptr",sink,"uint",1)
					DllCall(this.vTable(sink,9),"ptr",sink)
				} else {
					DllCall(this.vTable(sink,5),"ptr",sink,"float",points[1][1]+xoffset,"float",points[1][2]+yoffset,"uint",0)
					loop % points.length()-1
						DllCall(this.vTable(sink,10),"ptr",sink,"float",points[a_index+1][1]+xoffset,"float",points[a_index+1][2]+yoffset)
					DllCall(this.vTable(sink,8),"ptr",sink,"uint",1)
					DllCall(this.vTable(sink,9),"ptr",sink)
				}
				
				if (DllCall(this.vTable(this.renderTarget,23),"Ptr",this.renderTarget,"Ptr",pGeom,"ptr",this.brush,"ptr",0) = 0) {
					DllCall(this.vTable(sink,2),"ptr",sink)
					DllCall(this.vTable(pGeom,2),"Ptr",pGeom)
					return 1
				}
				DllCall(this.vTable(sink,2),"ptr",sink)
				DllCall(this.vTable(pGeom,2),"Ptr",pGeom)
				
			}
		}
		
		
		return 0
	}
	
	
	;####################################################################################################################################################################################################################################
	;SetPosition
	;
	;x					:				X position to move the window to (screen space)
	;y					:				Y position to move the window to (screen space)
	;w					:				New Width (only applies when not attached)
	;h					:				New Height (only applies when not attached)
	;
	;return				;				Void
	;
	;notes				:				Only used when not attached to a window
	
	SetPosition(x,y,w:=0,h:=0) {
		this.x := x
		this.y := y
		if (!this.attachHWND and w != 0 and h != 0) {
			VarSetCapacity(newSize,16)
			NumPut(this.width := w,newSize,0,"uint")
			NumPut(this.height := h,newSize,4,"uint")
			DllCall(this.vTable(this.renderTarget,58),"Ptr",this.renderTarget,"ptr",&newsize)
		}
		DllCall("MoveWindow","Uptr",this.hwnd,"int",x,"int",y,"int",this.width,"int",this.height,"char",1)
	}
	
	
	;####################################################################################################################################################################################################################################
	;GetImageDimensions
	;
	;image				:				Image file name
	;&w					:				Width of image
	;&h					:				Height of image
	;
	;return				;				Void
	
	GetImageDimensions(image,byref w, byref h) {
		if (!i := this.imageCache[image]) {
			i := this.cacheImage(image)
		}
		w := i.w
		h := i.h
	}
	
	
	;####################################################################################################################################################################################################################################
	;GetMousePos
	;
	;&x					:				X position of mouse to return
	;&y					:				Y position of mouse to return
	;realRegionOnly		:				Return 1 only if in the real region, which does not include the invisible borders, (client area does not have borders)
	;
	;return				;				Returns 1 if mouse within window/client region; 0 otherwise
	
	GetMousePos(byref x, byref y, realRegionOnly:=0) {
		DllCall("GetCursorPos","ptr",this.tBufferPtr)
		x := NumGet(this.tBufferPtr,0,"int")
		y := NumGet(this.tBufferPtr,4,"int")
		if (!realRegionOnly) {
			inside := (x >= this.x and y >= this.y and x <= this.x2 and y <= this.y2)
			x += this.offX
			y += this.offY
			return inside
		}
		x += this.offX
		y += this.offY
		return (x >= this.realX and y >= this.realY and x <= this.realX2 and y <= this.realY2)
		
	}
	
	
	;####################################################################################################################################################################################################################################
	;Clear
	;
	;notes						:			Clears the overlay, essentially the same as running BegindDraw followed by EndDraw
	
	Clear() {
		DllCall(this.vTable(this.renderTarget,48),"Ptr",this.renderTarget)
		DllCall(this.vTable(this.renderTarget,47),"Ptr",this.renderTarget,"Ptr",this.clrPtr)
		DllCall(this.vTable(this.renderTarget,49),"Ptr",this.renderTarget,"int64*",tag1,"int64*",tag2)
	}
	
	
	;####################################################################################################################################################################################################################################
	;RegCallback
	;
	;&func						:			Function object to call
	;&callback					:			Name of the callback to assign the function to
	;
	;notes						:			Example: overlay.RegCallback(Func("funcName"),"Size"); See top for param info
	
	RegCallback(func,callback) {
		if (this.callbacks.haskey(callback))
			this.callbacks[callback] := func
	}
	
	
	;####################################################################################################################################################################################################################################
	;ClearCallback
	;
	;&callback					:			Name of the callback to clear functions of
	;
	;notes						:			Clears callback
	
	ClearCallback(callback) {
		if (this.callbacks.haskey(callback))
			this.callbacks[callback] := 0
	}
	
	
	
	
	
	;########################################## 
	;  internal functions used by the class
	;########################################## 
	AdjustWindow(byref x,byref y,byref w,byref h) {
		local
		this.lastPos := (x<<16)+y
		this.lastSize := (w<<16)+h
		DllCall("GetWindowInfo","Uptr",(this.attachHWND ? this.attachHWND : this.hwnd),"ptr",this.tBufferPtr)
		pp := (this.attachClient ? 20 : 4)
		x1 := NumGet(this.tBufferPtr,pp,"int")
		y1 := NumGet(this.tBufferPtr,pp+4,"int")
		x2 := NumGet(this.tBufferPtr,pp+8,"int")
		y2 := NumGet(this.tBufferPtr,pp+12,"int")
		this.width := w := x2-x1
		this.height := h := y2-y1
		this.x := x := x1
		this.y := y := y1
		this.x2 := x + w
		this.y2 := y + h
		
		hBorders := (this.attachClient ? 0 : NumGet(this.tBufferPtr,48,"int"))
		vBorders := (this.attachClient ? 0 : NumGet(this.tBufferPtr,52,"int"))
		this.realX := hBorders
		this.realY := 0
		this.realWidth := w - (hBorders*2)
		this.realHeight := h - vBorders
		this.realX2 := this.realX + this.realWidth
		this.realY2 := this.realY + this.realHeight
		this.offX := -x1 ;- hBorders
		this.offY := -y1
	}
	SetIdentity(o:=0) {
		NumPut(1,this.matrixPtr,o+0,"float")
		NumPut(0,this.matrixPtr,o+4,"float")
		NumPut(0,this.matrixPtr,o+8,"float")
		NumPut(1,this.matrixPtr,o+12,"float")
		NumPut(0,this.matrixPtr,o+16,"float")
		NumPut(0,this.matrixPtr,o+20,"float")
	}
	DrawTextShadow(p,text,x,y,w,h,color) {
		this.SetBrushColor(color)
		NumPut(x,this.tBufferPtr,0,"float")
		NumPut(y,this.tBufferPtr,4,"float")
		NumPut(x+w,this.tBufferPtr,8,"float")
		NumPut(y+h,this.tBufferPtr,12,"float")
		DllCall(this.vTable(this.renderTarget,27),"ptr",this.renderTarget,"wstr",text,"uint",strlen(text),"ptr",p,"ptr",this.tBufferPtr,"ptr",this.brush,"uint",0,"uint",0)
	}
	DrawTextOutline(p,text,x,y,w,h,color) {
		static o := [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1],[1,-1]]
		this.SetBrushColor(color)
		for k,v in o
		{
			NumPut(x+v[1],this.tBufferPtr,0,"float")
			NumPut(y+v[2],this.tBufferPtr,4,"float")
			NumPut(x+w+v[1],this.tBufferPtr,8,"float")
			NumPut(y+h+v[2],this.tBufferPtr,12,"float")
			DllCall(this.vTable(this.renderTarget,27),"ptr",this.renderTarget,"wstr",text,"uint",strlen(text),"ptr",p,"ptr",this.tBufferPtr,"ptr",this.brush,"uint",0,"uint",0)
		}
	}
	Err(str*) {
		local
		s := ""
		for k,v in str
			s .= (s = "" ? "" : "`n`n") v
		msgbox,% 0x30 | 0x1000,% "Problem!",% s
	}
	LoadLib(lib*) {
		for k,v in lib
			if (!DllCall("GetModuleHandle", "str", v, "Ptr"))
				DllCall("LoadLibrary", "Str", v) 
	}
	SetBrushColor(col) {
		if (col <= 0xFFFFFF)
			col += 0xFF000000
		if (col != this.lastCol) {
			NumPut(((col & 0xFF0000)>>16)/255,this.colPtr,0,"float")
			NumPut(((col & 0xFF00)>>8)/255,this.colPtr,4,"float")
			NumPut(((col & 0xFF))/255,this.colPtr,8,"float")
			NumPut((col > 0xFFFFFF ? ((col & 0xFF000000)>>24)/255 : 1),this.colPtr,12,"float")
			DllCall(this.vTable(this.brush,8),"Ptr",this.brush,"Ptr",this.colPtr)
			this.lastCol := col
			return 1
		}
		return 0
	}
	vTable(a,p) {
		return NumGet(NumGet(a+0,0,"ptr"),p*a_ptrsize,"Ptr")
	}
	_guid(guidStr,byref clsid) {
		VarSetCapacity(clsid,16)
		DllCall("ole32\CLSIDFromString", "WStr", guidStr, "Ptr", &clsid)
	}
	SetVarCapacity(key,size,fill=0) {
		this.SetCapacity(key,size)
		DllCall("RtlFillMemory","Ptr",this.GetAddress(key),"Ptr",size,"uchar",fill)
		return this.GetAddress(key)
	}
	CacheImage(image) {
		local
		if (this.imageCache.haskey(image))
			return 1
		if (image = "") {
			this.Err("Error, expected resource image path but empty variable was supplied!")
			return 0
		}
		if (!FileExist(image)) {
			this.Err("Error finding resource image","'" image "' does not exist!")
			return 0
		}
		DllCall("gdiplus\GdipCreateBitmapFromFile", "Ptr", &image, "Ptr*", bm)
		DllCall("gdiplus\GdipGetImageWidth", "Ptr", bm, "Uint*", w)
		DllCall("gdiplus\GdipGetImageHeight", "Ptr", bm, "Uint*", h)
		VarSetCapacity(r,16,0)
		NumPut(w,r,8,"uint")
		NumPut(h,r,12,"uint")
		VarSetCapacity(bmdata, 32, 0)
		DllCall("Gdiplus\GdipBitmapLockBits", "Ptr", bm, "Ptr", &r, "uint", 3, "int", 0x26200A, "Ptr", &bmdata)
		scan := NumGet(bmdata, 16, "Ptr")
		p := DllCall("GlobalAlloc", "uint", 0x40, "ptr", 16+((w*h)*4), "ptr")
		DllCall(this._cacheImage,"Ptr",p,"Ptr",scan,"int",w,"int",h,"uchar",255)
		DllCall("Gdiplus\GdipBitmapUnlockBits", "Ptr", bm, "Ptr", &bmdata)
		DllCall("gdiplus\GdipDisposeImage", "ptr", bm)
		VarSetCapacity(props,64,0)
		NumPut(28,props,0,"uint")
		NumPut(1,props,4,"uint")
		if (this.bits) {
			NumPut(w,this.tBufferPtr,0,"uint")
			NumPut(h,this.tBufferPtr,4,"uint")
			if (v := DllCall(this.vTable(this.renderTarget,4),"ptr",this.renderTarget,"int64",NumGet(this.tBufferPtr,"int64"),"ptr",p,"uint",4 * w,"ptr",&props,"ptr*",bitmap) != 0) {
				this.Err("Problem creating D2D bitmap for image '" image "'")
				return 0
			}
		} else {
			if (v := DllCall(this.vTable(this.renderTarget,4),"ptr",this.renderTarget,"uint",w,"uint",h,"ptr",p,"uint",4 * w,"ptr",&props,"ptr*",bitmap) != 0) {
				this.Err("Problem creating D2D bitmap for image '" image "'")
				return 0
			}
		}
		return this.imageCache[image] := {p:bitmap,w:w,h:h}
	}
	CacheFont(name,size) {
		if (DllCall(this.vTable(this.wFactory,15),"ptr",this.wFactory,"wstr",name,"ptr",0,"uint",400,"uint",0,"uint",5,"float",size,"wstr","en-us","ptr*",textFormat) != 0) {
			this.Err("Unable to create font: " name " (size: " size ")","Try a different font or check to see if " name " is a valid font!")
			return 0
		}
		return this.fonts[name size] := textFormat
	}
	__Delete() {
		DllCall("gdiplus\GdiplusShutdown", "Ptr*", this.gdiplusToken)
		DllCall(this.vTable(this.factory,2),"ptr",this.factory)
		DllCall(this.vTable(this.stroke,2),"ptr",this.stroke)
		DllCall(this.vTable(this.strokeRounded,2),"ptr",this.strokeRounded)
		DllCall(this.vTable(this.renderTarget,2),"ptr",this.renderTarget)
		DllCall(this.vTable(this.brush,2),"ptr",this.brush)
		DllCall(this.vTable(this.wfactory,2),"ptr",this.wfactory)
		guiID := this.guiID
		gui %guiID%:destroy
	}
	Mcode(str) {
		local
		s := strsplit(str,"|")
		if (s.length() != 2)
			return
		if (!DllCall("crypt32\CryptStringToBinary", "str", s[this.bits+1], "uint", 0, "uint", 1, "ptr", 0, "uint*", pp, "ptr", 0, "ptr", 0))
			return
		p := DllCall("GlobalAlloc", "uint", 0, "ptr", pp, "ptr")
		if (this.bits)
			DllCall("VirtualProtect", "ptr", p, "ptr", pp, "uint", 0x40, "uint*", op)
		if (DllCall("crypt32\CryptStringToBinary", "str", s[this.bits+1], "uint", 0, "uint", 1, "ptr", p, "uint*", pp, "ptr", 0, "ptr", 0))
			return p
		DllCall("GlobalFree", "ptr", p)
	}
}
