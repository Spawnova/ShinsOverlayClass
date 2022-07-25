# ShinsOverlayClass
A direct2d overlay for <ins>AutoHotkey **V1.1**</ins>, made to be user friendly and fast.
Supports 32bit and 64bit for systems running windows 7+ including the newest windows 11.

# YouTube simple overview and examples

[![Video](https://img.youtube.com/vi/L2Cb1UCJDEg/default.jpg)](https://www.youtube.com/watch?v=L2Cb1UCJDEg)

## Functions
```ruby
#AttachToWindow...........Attach the overlay to a window
AttachToWindow(title,AttachToClientArea:=0,foreground:=1)

#BeginDraw................Begins the drawing process, MUST ALWAYS start with BeginDraw(), if attached to window returns 1 if window is available, 0 otherwise
BeginDraw()

#EndDraw..................End the drawing process,  MUST ALWAYS end with EndDraw()
EndDraw()

#DrawImage................Draw an image
DrawImage(image,dstX,dstY,dstW:=0,dstH:=0,srcX:=0,srcY:=0,srcW:=0,srcH:=0,alpha:=1,drawCentered:=0,rotation:=0)

#DrawText.................Draws text, supports a dropshadow if a valid color is supplied
DrawText(text,x,y,size:=18,color:=0xFF000000,fontName:="Arial",extraOptions:="") #see the comments above the function in the class file for more info

#DrawEllipse..............Draws an ellipse
DrawEllipse(x, y, w, h, color, thickness:=1)

#FillEllipse..............Fills an ellipse
FillEllipse(x, y, w, h, color)

#DrawCircle...............Draw a circle
DrawCircle(x, y, radius, color, thickness:=1)

#FillCircle...............Fill a circle
FillCircle(x, y, radius, color)

#DrawRectangle............Draws a rectangle
DrawRectangle(x, y, w, h, color, thickness:=1)

#FillRectangle............Fills a rectangle
FillRectangle(x, y, w, h, color)

#DrawRoundedRectangle.....Draw a rectangle with rounded corners
DrawRoundedRectangle(x, y, w, h, radiusX, radiusY, color, thickness:=1)

#FillRoundedRectangle.....Fill a rectangle with rounded corners
FillRoundedRectangle(x, y, w, h, radiusX, radiusY, color)

#DrawLine.................Draws a line from 2 positions
DrawLine(x1,y1,x2,y2,color,thickness:=1,rounded:=0)

#DrawLines................Draws an array of lines, points must be in an array [[x,y],[x,y]] etc.
DrawLines(points,color,connect:=0,thickness:=1,rounded:=0)

#DrawPolygon..............Draws a polygon outline, points must be in an array [[x,y],[x,y]] etc.
DrawPolygon(points,color,thickness:=1,rounded:=0)

#FillPolygon..............Fill a polygon, points must be in an array [[x,y],[x,y]] etc.
FillPolygon(points,color)

#SetPosition..............Sets the overlay position, only when not attached
SetPosition(x,y,w:=0,h:=0)

#GetImageDimensions.......Gets the width and height of a cached image
GetImageDimensions(image,byref w, byref h)

#GetMousePosition.........Gets the mouse position relative to the overlay, additionally returns true if the mouse is inside the overlay, 0 otherwise
GetMousePos(byref x, byref y, realRegionOnly:=0)
```

## Notes

* **Only for AHK V1.1, V2 is not supported.**
*
* I've only tested on my end and can confirm it works for me using 32/64 bit AHK_L (AHK V1.1) on Windows 10.
* If it doesn't work for you let me know, I may be able to help, or maybe not, just depends.

### Donations

Thanks for stopping by! If you really enjoy my code and want to make a <ins>small</ins> donation, then here's a link! https://www.buymeacoffee.com/Spawnova

**I will continue to provide code, and support released classes regardless of any monetary support**, and I'd rather none is given if you are not comfortably in a position to do so!
