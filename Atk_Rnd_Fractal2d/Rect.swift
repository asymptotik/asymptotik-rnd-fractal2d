//
//  FractalRect.swift
//  Atk_Rnd_Fractal2d
//
//  Created by Rick Boykin on 11/26/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation

public struct Rect
{
    public var startx:Double
    public var endx:Double
    public var starty:Double
    public var endy:Double
    
    public init() {
        startx = 0.0
        endx   = 0.0
        starty = 0.0
        endy   = 0.0
    }
    
    public init(_ startx:Double, _ endx:Double, _ starty:Double, _ endy:Double) {
        self.startx = startx;
        self.endx = endx;
        self.starty = starty;
        self.endy = endy;
    }
    
    public init(rect:Rect) {
        self.startx = rect.startx;
        self.endx = rect.endx;
        self.starty = rect.starty;
        self.endy = rect.endy;
    }
    
    public func getSubRect(width:Double, height:Double, rect:NSRect) -> Rect {
        let w = (endx - startx)
        let h = (endy - starty)
        
        NSLog("getSubRect: \(width) \(height) \(rect.origin.x) \(rect.origin.y) \(rect.size.width) \(rect.size.height)")
        let sx = startx + w * (Double(rect.origin.x) / Double(width))
        let ex = sx + w * (Double(rect.size.width) / Double(width))
        let sy = starty + h * (Double(rect.origin.y) / Double(height))
        let ey = sy + h * (Double(rect.size.height) / Double(height))
        
        return Rect(sx, ex, sy, ey)
    }
    
    mutating func set(rect:Rect) {
        self.startx = rect.startx;
        self.endx = rect.endx;
        self.starty = rect.starty;
        self.endy = rect.endy;
    }
    
    mutating public func setSubRect(width:Double, height:Double, rect:NSRect) {
        self.set(self.getSubRect(width, height:height, rect:rect))
    }
    
    public func copy() -> Rect {
        return Rect(rect:self);
    }
}