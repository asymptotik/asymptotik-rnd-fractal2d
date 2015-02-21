//
//  FractalView.swift
//  Atk_Rnd_Fractal2d
//
//  Created by Rick Boykin on 11/22/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Cocoa
import AppKit
import AtkCocoaShared

protocol FractalViewProtocol: class {
    func fractalViewDidChangeSelection(rect:Rect)
    func fractalViewDidSelectRegion(rect:Rect)
}

class FractalView: NSView {

    var image:NSImage? = nil;
    var fractal = Fractal()
    var boxPointA = NSMakePoint(0.0, 0.0)
    var boxPointB = NSMakePoint(0.0, 0.0)
    var shouldDrawBox = false
    var shouldRefreshFractal = true
    var boxColor = NSColor(calibratedRed:1.0, green:0.0, blue:0.0, alpha:1.0)
    var fractalParams:FractalParams = FractalParams()
    var isGenerating = false
    var isBoxRatioFixed = true
    
    weak var fractalDelegate: FractalViewProtocol?

    func generate()
    {
        if self.isGenerating {
            return;
        }
        
        self.isGenerating = true
        
        let width  = Int(self.frame.width)
        let height = Int(self.frame.height)
        
        let bytesPerPixel = 4 // RGBA
        let dataSize = width * height * bytesPerPixel
        
        self.fractalParams.width = width
        self.fractalParams.height = height

        // Create the image and get a pointer to the bitmap data memory
        let params = self.fractalParams
        let imageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: params.width, pixelsHigh: params.height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSDeviceRGBColorSpace, bytesPerRow: params.width * bytesPerPixel, bitsPerPixel: 32)!
        let ptr = imageRep.bitmapData
        
        fractal.generate(ptr, params:self.fractalParams) {
            (sender:Fractal) in

            let imageSize = NSMakeSize(imageRep.size.width, imageRep.size.height);
            self.image = NSImage(size: imageSize)
            self.image!.addRepresentation(imageRep)
            self.isGenerating = false
            self.needsDisplay = true
        }
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        NSLog("drawing")
        
        var t:CGSize
        
        if(self.image != nil) {
            self.image?.drawInRect(dirtyRect, fromRect: dirtyRect, operation: NSCompositingOperation.CompositeSourceAtop, fraction: 1.0)
        }
        
        if(self.shouldDrawBox) {
            self.boxColor.set()
            NSBezierPath.strokeRect(self.selectedRectangle)
        }
    }
    
    var selectedRectangle:NSRect {
        
        var pointB:NSPoint
        
        if self.isBoxRatioFixed {
            var w = self.boxPointB.x - self.boxPointA.x
            var h = self.boxPointB.y - self.boxPointA.y
            
            var m = max(abs(w), abs(h))
            pointB = NSMakePoint(self.boxPointA.x + m * (w < 0.0 ? -1 : 1), self.boxPointA.y + m * (h < 0.0 ? -1 : 1))
        }
        else {
            pointB = self.boxPointB
        }
        
        var minPoint = NSMakePoint(min(self.boxPointA.x, pointB.x), min(self.boxPointA.y, pointB.y))
        var maxPoint = NSMakePoint(max(self.boxPointA.x, pointB.x), max(self.boxPointA.y, pointB.y))
        var width = maxPoint.x - minPoint.x
        var height = maxPoint.y - minPoint.y

        return NSMakeRect(minPoint.x, minPoint.y, width, height)
    }
    
    override func mouseDown(event:NSEvent) {
        super.mouseDown(event)
        self.boxPointA = self.convertPoint(event.locationInWindow, fromView:nil)
        self.shouldDrawBox = true
    }
    
    override func mouseDragged(event:NSEvent) {
        super.mouseDragged(event)
        self.boxPointB = self.convertPoint(event.locationInWindow, fromView:nil)
        
        let rect = self.fractalParams.rect.getSubRect(
            Double(self.fractalParams.width),
            height:Double(self.fractalParams.height),
            rect:self.selectedRectangle);
        
        self.fractalDelegate?.fractalViewDidChangeSelection(rect)
        self.needsDisplay = true
    }
    
    override func mouseUp(event:NSEvent) {
        super.mouseUp(event)
        self.shouldDrawBox = false
        let rect = self.fractalParams.rect.getSubRect(
            Double(self.fractalParams.width),
            height:Double(self.fractalParams.height),
            rect:self.selectedRectangle);
        
        self.fractalDelegate?.fractalViewDidSelectRegion(rect)
    }
}
