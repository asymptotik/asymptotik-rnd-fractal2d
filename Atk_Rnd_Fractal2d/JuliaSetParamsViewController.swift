//
//  JuliaSetParamsViewController.swift
//  Atk_Rnd_Fractal2d
//
//  Created by Rick Boykin on 12/9/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Cocoa

class JuliaSetParamsViewController: NSViewController {
    
    @IBOutlet weak var txtRealPart: NSTextField!
    @IBOutlet weak var txtImaginaryPart: NSTextField!
    
    dynamic var realPart:Float = -0.8 {
        didSet {
            NSLog("realPart: \(realPart)")
        }
    }
    
    dynamic var imaginaryPart:Float = -0.0342 {
        didSet {
            NSLog("imaginaryPart: \(imaginaryPart)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
}
