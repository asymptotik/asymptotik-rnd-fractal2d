//
//  FractalParams.swift
//  Atk_Rnd_Fractal2d
//
//  Created by Rick Boykin on 11/26/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import AtkCocoaShared

public class FractalParams
{
    public var rect:Rect = Rect()
    public var width:Int
    public var height:Int
    public var iterations:Int
    public var cutoff:Double
    public var normalizedEscape:Bool = true
    
    var epsilonX:Double = 0.0
    var epsilonY:Double = 0.0
    
    var iterator:FractalIterator? = nil
    
    public var juliaParams:Complex = Complex()
    
    public init() {
        self.rect = Rect(-2.0, 2.0, -2.0, 2.0)
        self.iterations = 1000
        self.cutoff = 2.0
        self.width = 256
        self.height = 256
        
        self.calcEpsilon()
    }
    
    public func calcEpsilon() {
        epsilonX = (self.rect.endx - self.rect.startx) / Double(self.width)
        epsilonY = (self.rect.endy - self.rect.starty) / Double(self.height)
    }
    
    var copy:FractalParams {
        var ret = FractalParams()
        ret.rect = Rect(rect:self.rect)
        ret.width = self.width
        ret.height = self.height
        ret.iterations = self.iterations
        ret.cutoff = self.cutoff
        ret.normalizedEscape = self.normalizedEscape
        ret.epsilonX = self.epsilonX
        ret.epsilonY = self.epsilonY
        ret.iterator = self.iterator
        ret.juliaParams = Complex(self.juliaParams)
        return ret;
    }
}