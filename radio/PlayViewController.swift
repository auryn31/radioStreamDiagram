//
//  PlayViewController.swift
//  radio
//
//  Created by Mac on 27.11.15.
//  Copyright © 2015 target. All rights reserved.
//

import UIKit
import AVFoundation
import Charts
import ifaddrs

class PlayViewController: UIViewController, ChartViewDelegate {
    
    var senderName = String()
    var senderURL = String()
    
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var sliderVolume: UISlider!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var wifiLabel: UILabel!
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var wwanLabel: UILabel!
    @IBOutlet weak var dataUsageLabel: UILabel!
    
    
    private var player = AVQueuePlayer()
    private var startData = UInt32()
    private var isApper:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //print(senderName)
        
        startData = getDataUsage()[1]
        lineChartView.delegate = self
        senderLabel.text = senderName
        
        let playItem = AVPlayerItem( URL: NSURL(string: senderURL)!)
        player = AVQueuePlayer(playerItem: playItem)
        //player.
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true, withOptions: .NotifyOthersOnDeactivation)
        } catch {
            
        }
        let theSession = AVAudioSession.sharedInstance()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playInterrupt", name: AVAudioSessionInterruptionNotification, object: theSession)
        player.rate = 1.0
        
        lineChartView.noDataText = "wait for data"
        lineChartView.descriptionText = ""
        
        lineChartView.setVisibleXRangeMaximum(10)
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            // do some task
            //wifi
            var dataEntriesWifi: [ChartDataEntry] = []
            var dataPointsWifi : [Int] = []
            var lineChartData = LineChartData()
            
            //cellular
            var dataEntriesWWAN: [ChartDataEntry] = []
            var dataPointsWWAN : [Int] = []
            
            //cpu
            var dataEntriesCPU: [ChartDataEntry] = []
            var dataPointsCPU : [Int] = []
            
            //memory
            var dataEntriesMemory: [ChartDataEntry] = []
            var dataPointsMemory : [Int] = []
            
            var i = 0
            while true {
                if (!self.isApper){
                    break
                }
                dispatch_sync(dispatch_get_global_queue(priority, 0)) {
                    let startValueWifi = self.getDataUsage()[1]
                    let startValueWWAN = self.getDataUsage()[3]
                    //wait 1/4 second
                    usleep(250000)
                    let endValueWifi = self.getDataUsage()[1]
                    let endValueWWAN = self.getDataUsage()[3]
                    
                    //calculate transfer into kbit/s wlan
                    let calcValueWifi = Double((endValueWifi-startValueWifi)/250)
                    let dataEntryWifi = ChartDataEntry(value: (calcValueWifi), xIndex: i)
                    dataEntriesWifi.append(dataEntryWifi)
                    
                    //calculate transfer into kbit/s wwan
                    let calcValueWWAN = Double((endValueWWAN-startValueWWAN)/250)
                    let dataEntryWWAN = ChartDataEntry(value: (calcValueWWAN), xIndex: i)
                    dataEntriesWWAN.append(dataEntryWWAN)
                    
                    //memoryusage
                    let dataEntryMemory = ChartDataEntry(value: ((Double(self.report_memory())/1000000)), xIndex: i)
                    dataEntriesMemory.append(dataEntryMemory)
                    
                    //only last 20 values will shown
                    if (i>20){
                        var tempWifi: [ChartDataEntry] = []
                        var tempWWAN: [ChartDataEntry] = []
                        var tempMemory: [ChartDataEntry] = []
                        for j in 0...20{
                            tempWifi.append(dataEntriesWifi[i-20+j])
                            tempWifi[j].xIndex = j
                            
                            tempWWAN.append(dataEntriesWWAN[i-20+j])
                            tempWWAN[j].xIndex = j
                            
                            tempMemory.append(dataEntriesMemory[i-20+j])
                            tempMemory[j].xIndex = j
                        }
                        dataEntriesWifi = tempWifi
                        dataEntriesWWAN = tempWWAN
                        dataEntriesMemory = tempMemory
                        i=20
                    } else {
                        dataPointsMemory.append(i)
                        dataPointsWifi.append(i)
                        dataPointsWWAN.append(i)
                    }
                    
                   // var c = Ins
                    
                    //var x = CPU_STATE_USER
                    //print("\(c)")
                    //print("\(x)")
                    //self.report_memory()
                    
                    //wifi dataset
                    let lineChartDataSetWifi = LineChartDataSet(yVals: dataEntriesWifi, label: "Downloaded Data in KBit/s WLAN")
                    lineChartDataSetWifi.drawCirclesEnabled = false
                    lineChartDataSetWifi.setColor(UIColor.redColor())
                    lineChartData = LineChartData(xVals: dataPointsWifi, dataSet: lineChartDataSetWifi)
                    
                    //wifi dataset
                    let lineChartDataSetWWAN = LineChartDataSet(yVals: dataEntriesWWAN, label: "Downloaded Data in KBit/s WWAN")
                    lineChartDataSetWWAN.drawCirclesEnabled = false
                    lineChartDataSetWWAN.setColor(UIColor.blueColor())
                    
                    //memory
                    let lineChartDataSetMemory = LineChartDataSet(yVals: dataEntriesMemory, label: "Memory Usage in MB")
                    lineChartDataSetMemory.drawCirclesEnabled = false
                    lineChartDataSetMemory.setColor(UIColor.greenColor())
                    
                    lineChartData.addDataSet(lineChartDataSetMemory)
                    lineChartData.addDataSet(lineChartDataSetWWAN)
                }
                dispatch_sync(dispatch_get_main_queue()) {
                    self.lineChartView.data = lineChartData
                    self.lineChartView.setVisibleXRangeMaximum(20)
                    let averageOutput = self.average(dataEntriesWifi)
                    (self.wifiLabel).text = ("WIFI: \(averageOutput) KBit/s")
                    (self.wwanLabel).text = ("WWAN: \(self.average(dataEntriesWWAN)) KBit/s")
                    (self.dataUsageLabel).text = "\(dataEntriesMemory[dataEntriesMemory.count-1].value) MB"
                    //self.lineChartView.setVisibleXRangeMaximum(10)
                }
                i++
            }
            dispatch_async(dispatch_get_main_queue()) {
                
            }
        }
        
    }
    
    
    func resumeNow(timer : NSTimer)
    {
        player.play()
        print("attempted restart")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    func initPlayer(){
        let playItem = AVPlayerItem( URL: NSURL(string: senderURL)!)
        player = AVPlayer(playerItem: playItem)
        player.rate = 1.0
    }
    */
    

    @IBAction func setVolume(sender: AnyObject) {
        player.volume = sliderVolume.value
        //print(sliderVolume.value)
    }
    @IBAction func pause(sender: AnyObject) {
        player.pause()
    }
    @IBAction func play(sender: AnyObject) {
            player.play()
    }

    @IBAction func stop(sender: AnyObject) {

        player.pause()
    }
    
    override func viewWillDisappear(animated: Bool) {
        isApper = false
    }
    
    
    func average(values:[ChartDataEntry])->Double{
        var av = Double()
        
        for i in values {
            av += i.value
        }
        av = av/Double(values.count)
        av = Double(round(1000*av)/1000)
        return av
    }
    
    func getDataUsage() -> [UInt32] {
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        var networkData: UnsafeMutablePointer<if_data>! = nil
        
        var wifiDataSent:UInt32 = 0
        var wifiDataReceived:UInt32 = 0
        var wwanDataSent:UInt32 = 0
        var wwanDataReceived:UInt32 = 0
        
        if getifaddrs(&ifaddr) == 0 {
            for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
                
                let name = String.fromCString(ptr.memory.ifa_name)
                let flags = Int32(ptr.memory.ifa_flags)
                var addr = ptr.memory.ifa_addr.memory
                
                if addr.sa_family == UInt8(AF_LINK) {
                    if name?.hasPrefix("en") == true {
                        networkData = unsafeBitCast(ptr.memory.ifa_data, UnsafeMutablePointer<if_data>.self)
                        wifiDataSent += networkData.memory.ifi_obytes
                        wifiDataReceived += networkData.memory.ifi_ibytes
                    }
                    
                    if name?.hasPrefix("pdp_ip") == true {
                        networkData = unsafeBitCast(ptr.memory.ifa_data, UnsafeMutablePointer<if_data>.self)
                        wwanDataSent += networkData.memory.ifi_obytes
                        wwanDataReceived += networkData.memory.ifi_ibytes
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return [wifiDataSent, wifiDataReceived, wwanDataSent, wwanDataReceived]
    }
    
    func report_memory() -> UInt{
        var info = task_basic_info()
        var count = mach_msg_type_number_t(sizeofValue(info))/4
        let kerr: kern_return_t = withUnsafeMutablePointer(&info) {
            task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), task_info_t($0), &count)
        }
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        else {
            return 0
        }
    }
}
