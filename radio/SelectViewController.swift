//
//  SelectViewController.swift
//  radio
//
//  Created by Mac on 27.11.15.
//  Copyright © 2015 target. All rights reserved.
//

import UIKit

class SelectViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var senderSelect: UIPickerView!
    private var senderName = ["Fritz Radio 1 ca 16kBit", "Fritz Radio 2 ca 17 kBit", "Fritz Radio 3 ca 18 kBit","MDR Info", "NRG Sachsen", "N-JOI", "Deutschlandradio Kultur"]
    private var senderURL = ["http://rbb-mp3-fritz-m.akacast.akamaistream.net/7/799/292093/v1/gnl.akacast.akamaistream.net/rbb_mp3_fritz_m","http://rbb.ic.llnwd.net/stream/rbb_fritz_mp3_m_a", "http://rbb.ic.llnwd.net/stream/rbb_fritz_mp3_m_b","http://c22033-ls.i.core.cdn.streamfarm.net/QpZptC4ta9922033/22033mdr/live/app2128740352/w2128904192/live_de_56.mp3", "http://95.81.155.20/7813/nrj_150857.mp3", "http://c22033-ls.i.core.cdn.streamfarm.net/T3R6XGogC9922033/22033mdr/live/app2128740352/w2128904194/live_de_128.mp3", "http://stream.dradio.de/7/530/142684/v1/gnl.akacast.akamaistream.net/dradio_mp3_dkultur_m"]
    var selectedRow = Int()
    override func viewDidLoad() {
        super.viewDidLoad()
        senderSelect.delegate = self;
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let label = UILabel()
        label.text = senderName[row]
        label.font = UIFont(name: "System", size: 14)
        label.textAlignment = .Center
        return label
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return senderName.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRow = row
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "play" {
            if let destination = segue.destinationViewController as? PlayViewController {
                destination.senderName = senderName[selectedRow]
                destination.senderURL = senderURL[selectedRow]
            }
        }
    }
    
    @IBAction func playButton(sender: AnyObject) {
        self.performSegueWithIdentifier("play", sender: nil)
    }

}

