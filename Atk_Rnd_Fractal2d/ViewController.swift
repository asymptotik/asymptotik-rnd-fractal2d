//
//  ViewController.swift
//  Atk_Rnd_Fractal2d
//
//  Created by Rick Boykin on 11/22/14.
//  Copyright (c) 2014 Asymptotik Limited. All rights reserved.
//

import Cocoa
import AtkCocoaShared

class ViewController: NSViewController, FractalViewProtocol, FractalProtocol, NSControlTextEditingDelegate {

    @IBOutlet weak var txtStartX: NSTextField!
    @IBOutlet weak var txtEndX: NSTextField!
    @IBOutlet weak var txtStartY: NSTextField!
    @IBOutlet weak var txtEndY: NSTextField!
    @IBOutlet weak var txtIterations: NSTextField!
    @IBOutlet weak var txtCutoff: NSTextField!
    @IBOutlet weak var fractalView: FractalView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var chkNormailized: NSButton!
    
    @IBOutlet weak var txtOutputFileWidth: NSTextField!
    @IBOutlet weak var txtOutputFileHeight: NSTextField!
    @IBOutlet weak var chkOutputFileSizeRatio: NSButton!
    
    @IBOutlet weak var cmbFractalType: NSComboBox!
    
    @IBOutlet weak var viewFractalParamsContainer: NSBox!
    
    var fractalTypes:[String] = [ "Mandelbrot Set", "Julia Set (-0.4, 0.6)", "Julia Set (-0.8, 0.156)", "Julia Set (-0.70176, 0.3842)"]
    
    dynamic var outputWidth:Int = 2048 {
        didSet {
            NSLog("outputWidth: \(outputWidth)")
        }
    }
    
    dynamic var outputHeight:Int = 2048 {
        didSet {
            NSLog("outputHeight: \(outputHeight)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fractalView.fractalDelegate = self;
        var rect = self.fractalView.fractalParams.rect
        self.setFractalCoordinates(rect)
        self.txtIterations.integerValue = self.fractalView.fractalParams.iterations
        self.txtCutoff.doubleValue = self.fractalView.fractalParams.cutoff
        self.fractalView.fractal.delegate = self
        self.fractalView.fractalParams.iterator = self.fractalView.fractal.iterateMandelbrot
        self.fractalView.generate()
        // Do any additional setup after loading the view.
        self.cmbFractalType.addItemsWithObjectValues(self.fractalTypes)
        self.cmbFractalType.selectItemAtIndex(0)
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func fractalViewDidChangeSelection(rect:Rect) {
        self.setFractalCoordinates(rect)
    }

    func fractalViewDidSelectRegion(rect:Rect) {
        self.setFractalCoordinates(rect)
        self.recalculate()
    }
    
    func setFractalCoordinates(rect:Rect) {
        self.txtStartX.doubleValue = rect.startx
        self.txtEndX.doubleValue = rect.endx
        self.txtStartY.doubleValue = rect.starty
        self.txtEndY.doubleValue = rect.endy
    }
    
    func recalculate() {
        let rect = Rect(self.txtStartX.doubleValue,
            self.txtEndX.doubleValue,
            self.txtStartY.doubleValue,
            self.txtEndY.doubleValue)
        self.fractalView.fractalParams.rect = rect
        var iterationsString = txtIterations.stringValue
        var iterations = iterationsString.stringByReplacingOccurrencesOfString(",", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        self.fractalView.fractalParams.iterations = iterations.toInt()!
        self.fractalView.fractalParams.cutoff = txtCutoff.doubleValue
        self.fractalView.fractalParams.normalizedEscape = (chkNormailized.state == NSOnState)
        self.fractalView.shouldRefreshFractal = true
        self.fractalView.generate()
    }
    
    func reset() {
        let rect = Rect(-2, 2, -2, 2)
        self.fractalView.fractalParams.rect = rect
        self.fractalView.shouldRefreshFractal = true
        self.fractalView.generate()
        
        self.setFractalCoordinates(rect)
    }
    
    func saveDocument(name:String, typeUTI:String) {
        
        var window = self.view.window;
        var something = UTTypeCopyPreferredTagWithClass(typeUTI, kUTTagClassFilenameExtension)
        var newExtension = something.takeUnretainedValue() as String
        var newName = name.stringByDeletingPathExtension.stringByAppendingPathExtension(newExtension)
        var panel:NSSavePanel = NSSavePanel()
        panel.nameFieldStringValue = newName!
        panel.beginSheetModalForWindow(window!) {
            (result:Int) -> Void in
            if (result == NSFileHandlingPanelOKButton)
            {
                var theFile:NSURL = panel.URL!
                NSLog("Save to \(theFile)")
                self.saveTo(theFile)
                // Write the contents in the new format.
            }
        };
    }
    
    func saveTo(url:NSURL) {
        
        let width  = Int(self.outputWidth)
        let height = Int(self.outputHeight)
        let bytesPerPixel = 4 // RGBA
        let dataSize = width * height * bytesPerPixel
        var ptr = UnsafeMutablePointer<UInt8>.alloc(dataSize)
        
        var fractal = self.fractalView.fractal
        var fractalParams = self.fractalView.fractalParams.copy
        
        fractalParams.width = width
        fractalParams.height = height
        
        fractal.generate(ptr, params:fractalParams) {
            (sender:Fractal) in
            
            var imageRep = NSBitmapImageRep(bitmapDataPlanes: &ptr, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSDeviceRGBColorSpace, bytesPerRow: width * bytesPerPixel, bitsPerPixel: 32)!
            
            var dict:[NSObject : AnyObject] = [:]
            var imageData = imageRep.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties:dict)
            imageData!.writeToURL(url, atomically:false);
            ptr.dealloc(dataSize)
        }
    }
    
    @IBAction func recalculatePressed(sender: NSButton) {
        self.recalculate()
    }
    
    @IBAction func resetPressed(sender: NSButton) {
        self.reset()
    }
    
    @IBAction func savePressed(sender: NSButton) {
        self.saveDocument("fractal.png", typeUTI:kUTTypePNG)
    }

    @IBAction func parameterTextAction(sender: NSTextField) {
        self.recalculate()
    }
    
    @IBAction func normalizedChanged(sender: NSButton) {
        self.recalculate()
    }
    
    @IBAction func outputFileRatioToggleChanged(sender: AnyObject) {
    }
    
    @IBAction func redrawPressed(sender: NSButton) {
        self.fractalView.needsDisplay = true
    }
    
    @IBAction func fractalTypeChanged(sender: NSComboBox) {
        var itemIndex = sender.indexOfSelectedItem;
        if(itemIndex == 0) {
            self.fractalView.fractalParams.iterator = self.fractalView.fractal.iterateMandelbrot
            self.recalculate()
        } else if(itemIndex == 1) {
            self.fractalView.fractalParams.iterator = self.fractalView.fractal.iterateJulia
            self.fractalView.fractalParams.juliaParams = Complex(-0.4, 0.6)
            self.recalculate()
        } else if(itemIndex == 2) {
            self.fractalView.fractalParams.iterator = self.fractalView.fractal.iterateJulia
            self.fractalView.fractalParams.juliaParams = Complex(-0.8, 0.156)
            self.recalculate()
        } else if(itemIndex == 3) {
            self.fractalView.fractalParams.iterator = self.fractalView.fractal.iterateJulia
            self.fractalView.fractalParams.juliaParams = Complex(-0.70176, 0.3842)
            self.recalculate()
        } else if(itemIndex == 4) {
            self.fractalView.fractalParams.iterator = self.fractalView.fractal.iterateJulia
            self.fractalView.fractalParams.juliaParams = Complex(-0.4, 0.6)
            self.recalculate()
        }
    }
    
    func fractalDidStart(fractal:Fractal) {

    }

    func fractalDidDidDetermineWorkload(fractal:Fractal, workload:Int64) {
        self.progressIndicator.maxValue = Double(workload)
    }

    func fractalDidDidCompleteWorkItem(fractal:Fractal, item:Int64) {
        self.progressIndicator.doubleValue += 1.0
    }

    func fractalDidComplete(fractal:Fractal) {
        self.progressIndicator.maxValue = 100.0
        self.progressIndicator.doubleValue = 0.0
    }
    
    //
    // NSControlTextEditingDelegate
    //
    
    func control(control: NSControl, isValidObject object: AnyObject) -> Bool {
        NSLog("isValid: \(object)")
        return true
    }
    
    func textDidChange(notification:NSNotification) {
        NSLog("textDidChange: \(notification)")
    }
}

