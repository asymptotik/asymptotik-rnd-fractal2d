//
//  Fractal.swift
//  Atk_Rnd_Fractal2d
//
//  Created by Rick Boykin on 11/23/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Foundation
import AppKit
import AtkCocoaShared

typealias MandelbrotCompletionBlock = (sender:Fractal) -> Void
typealias FractalIterator = (Double, Double, FractalParams) -> Double?

protocol FractalProtocol: class {
    func fractalDidStart(fractal:Fractal)
    func fractalDidDidDetermineWorkload(fractal:Fractal, workload:Int64)
    func fractalDidDidCompleteWorkItem(fractal:Fractal, item:Int64)
    func fractalDidComplete(fractal:Fractal)
}

public class Fractal
{
    var maxColor = 255
    var isAsync = true
    var params:FractalParams? = nil
    
    weak var delegate:FractalProtocol? = nil
    
    func colorForIteration(iterations: Double?) -> Color {
        
        func colorComponent(iteration: Double) -> UInt8 {
            //return UInt8( Double(maxColor) * (sin(iteration / 20.0) + 1.0) / 2.0)
            var s = (sin(iteration / 20.0) + 1.0) / 2.0
            s *= s
            return UInt8( Double(maxColor) * s)
        }
        
        if let iterationCount = iterations {
            return Color(colorComponent(iterationCount),
                colorComponent(iterationCount),
                colorComponent(iterationCount))
        } else {
            return Color()
        }
    }

    func generate(buffer:UnsafeMutablePointer<UInt8>, params:FractalParams, block:MandelbrotCompletionBlock?) -> UnsafeMutablePointer<UInt8>
    {
        
        let timer = ElapsedTimer()
        timer.start()
        
        self.params = params.copy;
        self.params!.calcEpsilon()
        
        // NSLog("Fractal Generation started")
        
        if(isAsync) {
            self.generateConcurrent(buffer, params:self.params!) {
                (sender:Fractal) in
                NSLog("Fractal Generation took: \(timer.elapsed) seconds")
                block!(sender:sender)
            }
        }
        else {
            self.generateSerial(buffer, params:self.params!) {
                (sender:Fractal) in
                NSLog("Fractal Generation took: \(timer.elapsed) seconds")
                block!(sender:sender)
            }
        }

        return buffer
    }
    
    func generateSerial(buffer:UnsafeMutablePointer<UInt8>, params:FractalParams, block:MandelbrotCompletionBlock?) {
        
        var x:Int
        var y:Int
        
        for x = 0; x < params.width; x++ {
            for y = 0; y < params.height; y++ {
                self.generatePoint(buffer, x:x, y:y, params:params)
            }
        }
        
        block?(sender:self)
    }

    func generateConcurrent(buffer:UnsafeMutablePointer<UInt8>, params:FractalParams, block:MandelbrotCompletionBlock?) {

        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        let semaphore = dispatch_semaphore_create(4);
        let group = dispatch_group_create()
        let main = dispatch_get_main_queue()
        
        NSLog("Generating");
        
        self.delegate?.fractalDidStart(self)
        self.delegate?.fractalDidDidDetermineWorkload(self, workload: Int64(params.height / 100))
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        dispatch_group_async(group, queue) {
            var y:Int
            for y = 0; y < params.height; y++ {
            
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                dispatch_group_async(group, queue) {
                    [y] in
                    
                    for var x = 0; x < params.width; x++ {
                        self.generatePoint(buffer, x:x, y:y, params:params)
                    }
                    
                    if(y % 100 == 0) {
                        dispatch_async(main) {
                            [y]
                            self.delegate?.fractalDidDidCompleteWorkItem(self, item: Int64(y / 100))
                        }
                    }
                    dispatch_semaphore_signal(semaphore)
                }
            }
            dispatch_semaphore_signal(semaphore)
        }

        NSLog("Distributed");
        
        dispatch_group_notify(group, queue) {
            NSLog("Generated");
            dispatch_async(main) {
                self.delegate?.fractalDidComplete(self)
                if block != nil  {
                    block!(sender:self)
                }
            }
        }

        
        NSLog("Generating Returned");
    }
    
    var sxd = -20.0
    
    func generatePoint(buffer:UnsafeMutablePointer<UInt8>, x:Int, y:Int, params:FractalParams) {
        let xd = Double(x) * params.epsilonX + params.rect.startx
        let yd = Double(params.height - 1 - y) * params.epsilonY + params.rect.starty
        
        let iterations = params.iterator?(xd, yd, params)
        //let iterations = iterateMandelbrot(xd, y:yd, params:params)
        
        let color = self.colorForIteration(iterations);
        
        var ptr = buffer.advancedBy((y * 4 * params.width) + (x * 4))
        
        ptr.memory = color.r; ptr = ptr.successor();
        ptr.memory = color.g; ptr = ptr.successor();
        ptr.memory = color.b; ptr = ptr.successor();
        ptr.memory = color.a; ptr = ptr.successor();
    }
    
    func iterateMandelbrot(x:Double, y:Double, params:FractalParams) -> Double? {
        
        var iterations = 0
        let C = Complex(x, y)
        var Z = Complex()
        
        while Z.norm < params.cutoff && iterations < params.iterations {
            Z = Z * Z + C
            iterations++
        }

        if iterations >= params.iterations { return nil }
        
        if params.normalizedEscape {
            Z = Z * Z + C; iterations++    // a couple of extra iterations helps
            Z = Z * Z + C; iterations++    // decrease the size of the error term.
            var modulus = Z.norm
            var mu = Double(iterations) - (log(log(modulus))) / log(2.0)
            if(mu.isNaN)
            {
                mu = 0;
            }
            return mu
        }
        else {
            return  iterations < params.iterations ? Double(iterations) : nil
        }
    }
    
    func iterateJulia(x:Double, y:Double, params:FractalParams) -> Double? {
        
        var iterations = 0
        let C = params.juliaParams
        var Z = Complex(x, y)
        
        while Z.norm < params.cutoff && iterations < params.iterations {
            Z = Z * Z + C
            iterations++
        }
        
        if iterations >= params.iterations { return nil }
        
        if params.normalizedEscape {
            Z = Z * Z + C; iterations++    // a couple of extra iterations helps
            Z = Z * Z + C; iterations++    // decrease the size of the error term.
            var modulus = Z.norm
            var mu = Double(iterations) - (log(log(modulus))) / log(2.0)
            if(mu.isNaN)
            {
                mu = 0;
            }
            return mu
        }
        else {
            return  iterations < params.iterations ? Double(iterations) : nil
        }
    }
}
