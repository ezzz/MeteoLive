//
//  SynopTableViewController.swift
//  MeteoDirect
//
//  Created by Bruno ARENE on 30/12/2018.
//  Copyright © 2018 Bruno ARENE. All rights reserved.
//

import UIKit

class SynopCell : UITableViewCell {
    @IBOutlet weak var MeasureTime: UILabel!
    @IBOutlet weak var WeatherIcon: UIImageView!
    @IBOutlet weak var WeatherDetails: UILabel!
    @IBOutlet weak var Temperature: UILabel!
    @IBOutlet weak var RelativeHumidity: UILabel!
    @IBOutlet weak var BioMeteo: UILabel!
    @IBOutlet weak var SeaLevelPressure: UILabel!
    @IBOutlet weak var Neb: UILabel!
    @IBOutlet weak var RawSynop: UILabel!
    @IBOutlet weak var Pluie: UILabel!
    @IBOutlet weak var GroundState: UILabel!
    @IBOutlet weak var MinMaxTemperature: UILabel!
    @IBOutlet weak var CloudHeight: UILabel!
    @IBOutlet weak var Visibility: UILabel!
    @IBOutlet weak var WindMeanSpeed: UILabel!
    @IBOutlet weak var WindMaxSpeed: UILabel!
    @IBOutlet weak var WindDirection: UIImageView!
    @IBOutlet var SunMinutes: UILabel!
    @IBOutlet weak var SunPower: UILabel!
}

enum WeatherType {
    case unknown
    case sun
    case sun_rain
    case clouds1
    case clouds2
    case clouds3
    case rain1
    case rain2
    case rain3
    case fog1
    case fog2
    case fog3
}


class SynopTableViewController: UITableViewController {
    var synopArray:Array<Synop> = []
    var bShowDetails = false
    var stationId:String = ""
    var stationLabel:String = ""
    var arrWeatherImage = Dictionary<WeatherType,UIImage>()
    let WindDirectionImage = UIImage(named: "vent_0")
    let WindDirectionUnknownImage = UIImage(named: "temps_inconnu")

    @objc func refresh() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let sToday = formatter.string(from: Date()) // string purpose I add here
        let url = URL(string: "http://www.ogimet.com/cgi-bin/getsynop?begin=\(sToday)0000&end=\(sToday)2359&state=Fra")!
        
        // Load datas
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            let sData = String(bytes: data, encoding: .utf8)
            self.synopArray.removeAll()
            sData!.enumerateLines { line, _ in
                let sStationId = line.prefix(5)
                if (sStationId == self.stationId) {
                    let syn = Synop(rawdata:line)
                    syn.parse()
                    self.synopArray.append(syn)
                }
            }
            
            // Order by time DESC (newer first)
            self.synopArray = self.synopArray.sorted(by: self.sortTimeDESC)
            
            // Refresh IHM with new values
            DispatchQueue.main.async {
                self.tableView.rowHeight = UITableView.automaticDimension
                self.tableView.estimatedRowHeight = 80
                self.tableView.reloadData()
            }
        }
        
        task.resume()
    }
    
    func sortTimeDESC(this:Synop, that:Synop) -> Bool {
        return this.iTime > that.iTime
    }
    
    @objc func showDetails() {
        self.bShowDetails = !self.bShowDetails
        self.refresh()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let backbutton = UIButton(type: .custom)
        backbutton.setImage(UIImage(named: "Back.png"), for: .normal) // Image can be downloaded from here below link
        backbutton.contentVerticalAlignment = .fill
        backbutton.contentHorizontalAlignment = .fill
        backbutton.imageEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        backbutton.setTitle("Retour", for: .normal)
        backbutton.setTitleColor(backbutton.tintColor, for: .normal) // You can change the TitleColor
        backbutton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backbutton)
        
        let showDetailshButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(showDetails))
        self.navigationItem.rightBarButtonItem = showDetailshButton
        
        tableView.register(UINib(nibName: "SynopCell", bundle: nil), forCellReuseIdentifier: "SynopCellId")
        arrWeatherImage[WeatherType.unknown] = UIImage(named: "temps_inconnu")
        arrWeatherImage[WeatherType.sun] = UIImage(named: "temps_soleil")
        arrWeatherImage[WeatherType.sun_rain] = UIImage(named: "temps_pluie_soleil")
        arrWeatherImage[WeatherType.clouds1] = UIImage(named: "temps_peu_nuageux")
        arrWeatherImage[WeatherType.clouds2] = UIImage(named: "temps_nuageux")
        arrWeatherImage[WeatherType.clouds3] = UIImage(named: "temps_couvert")
        arrWeatherImage[WeatherType.rain1] = UIImage(named: "temps_pluie1")
        arrWeatherImage[WeatherType.rain2] = UIImage(named: "temps_pluie2")
        arrWeatherImage[WeatherType.rain3] = UIImage(named: "temps_pluie")
        arrWeatherImage[WeatherType.fog1] = UIImage(named: "temps_brouillard1")
        arrWeatherImage[WeatherType.fog2] = UIImage(named: "temps_brouillard2")
        arrWeatherImage[WeatherType.fog3] = UIImage(named: "temps_brouillard3")
        self.tableView.layoutMargins = UIEdgeInsets.zero
        self.refresh()
    }

    @IBAction func backAction(_ sender: UIButton) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.synopArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SynopCellId", for: indexPath) as! SynopCell

        let synop =  self.synopArray[indexPath.row]
        
        cell.MeasureTime?.text = synop.sTime
        cell.Temperature?.text = String(format:"%2.1f%", synop.dTemperature!)
        if (synop.sCloudCoverage!.count > 0) {
            cell.Neb?.text = "\(synop.sCloudCoverage!)/8"
        }
        cell.WeatherDetails?.text = synop.sWeather
        cell.RawSynop?.text = synop.sRawSynop
        cell.RawSynop?.numberOfLines = 0
        cell.RawSynop?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.RawSynop?.sizeToFit()
        var sMinMaxTemperature = ""
        if (synop.sMinTemperature.count > 0) {
            sMinMaxTemperature = "min \(synop.sMinTemperaturePeriod): \(synop.sMinTemperature) "
        }
        if (synop.sMaxTemperature.count > 0) {
            sMinMaxTemperature = sMinMaxTemperature + "max \(synop.sMaxTemperaturePeriod): \(synop.sMaxTemperature)"
        }
        cell.MinMaxTemperature?.text = sMinMaxTemperature
        
        // Relative humidity
        if (synop.dRelativeHumidity != nil) {
            cell.RelativeHumidity?.text = String(format:"%2d%%", Int(synop.dRelativeHumidity!*100))
        }
        
        // SeaLevelPressure
        if (synop.dSeaLevelPressure != nil) {
            cell.SeaLevelPressure?.text = String(format:"%4.1f", synop.dSeaLevelPressure!)
        }
        
        // BioMeteo
        if (synop.dBioMeteo != nil) {
            cell.BioMeteo?.text = String(format:"%2.1f", synop.dBioMeteo!)
        }
        
        if (synop.sRainMM_sec3 != "0 mm") {
            cell.Pluie?.text = "\(synop.sRainMM_sec3)"
        } else {
            cell.Pluie?.text = " "
            cell.Pluie?.backgroundColor = UIColor.clear
        }
        if (synop.sGroundState.count > 0) {
            cell.GroundState?.text = "\(synop.sGroundState)"
        } else {
            cell.GroundState?.text = " "
        }
        
        if (synop.fHorizontalVisibility > 0) {
            if (synop.fHorizontalVisibility < 10) {
                cell.Visibility?.text = String(format:"%2.1f km", synop.fHorizontalVisibility)
            }
            else
            {
                cell.Visibility?.text = String(format:"%2.0f km", synop.fHorizontalVisibility)
            }
        }
        else {
            cell.Visibility?.text = "-"
        }
        
        if (synop.sCloudHeightLabel.count > 0) {
            cell.CloudHeight?.text = "\(synop.sCloudHeightLabel)"
        }
        
        // Wind mean speed
        if (synop.dWindMeanSpeed != nil) {
            cell.WindMeanSpeed?.text = String(format:"%2.0f", synop.dWindMeanSpeed!)
        } else {
            cell.WindMeanSpeed?.text = "-"
        }
        
        // Wind max speed
        if (synop.dWindMaxSpeed != nil) {
            cell.WindMaxSpeed?.text = String(format:"%2.0f", synop.dWindMaxSpeed!)
        } else {
            cell.WindMaxSpeed?.text = "-"
        }
        
        // Sun minutes per hour
        if (synop.iSunMinutes != nil && synop.iSunMinutes! > 0) {
            cell.SunMinutes?.text = String(format:"%d min", synop.iSunMinutes!)
        } else {
            cell.SunMinutes?.text = " "
            cell.SunMinutes?.backgroundColor = UIColor.clear
        }

        // Sun power
        if (synop.iSunRadiation != nil && synop.iSunRadiation! > 0) {
            cell.SunPower?.text = String(format:"%d", synop.iSunRadiation!)
        } else {
            cell.SunPower?.text = " "
            cell.SunPower?.backgroundColor = UIColor.clear
        }

        // Setting image
        var icon = arrWeatherImage[WeatherType.unknown]
        if (synop.sCloudCoverage!.count > 0 && synop.sCloudCoverage! != "/") {
            let iCloudCover = Int(synop.sCloudCoverage!)!
           
            if (iCloudCover <= 1) {
                if (synop.fRainMM_sec3 > 0) {
                    icon = arrWeatherImage[WeatherType.sun_rain]
                } else {
                    icon = arrWeatherImage[WeatherType.sun]
                }
            }
            else if (iCloudCover >= 2 && iCloudCover <= 3) {
                if (synop.fRainMM_sec3 > 0) {
                    icon = arrWeatherImage[WeatherType.sun_rain]
                } else {
                    icon = arrWeatherImage[WeatherType.clouds1]
                }
            }
            else if (iCloudCover >= 4 && iCloudCover <= 6) {
                if (synop.fRainMM_sec3 > 0) {
                    icon = arrWeatherImage[WeatherType.sun_rain]
                } else {
                    icon = arrWeatherImage[WeatherType.clouds2]
                }
            }
            else if (iCloudCover >= 7) {
                if (synop.fRainMM_sec3 > 0) {
                    if (synop.fRainMM_sec3 <= 0.2) {
                        icon = arrWeatherImage[WeatherType.rain1]
                    } else if (synop.fRainMM_sec3 < 1.0) {
                        icon = arrWeatherImage[WeatherType.rain2]
                    } else {
                        icon = arrWeatherImage[WeatherType.rain3]
                    }
                } else {
                    icon = arrWeatherImage[WeatherType.clouds3]
                }
            }
        } else if (synop.fRainMM_sec3 > 0) {
            if (synop.fRainMM_sec3 <= 0.2) {
                icon = arrWeatherImage[WeatherType.rain1]
            } else if (synop.fRainMM_sec3 < 1.0) {
                icon = arrWeatherImage[WeatherType.rain2]
            } else {
                icon = arrWeatherImage[WeatherType.rain3]
            }
        }

        cell.WeatherIcon?.image = icon
        
        if (synop.dWindAngle != nil) {
            cell.WindDirection?.image = WindDirectionImage!.rotate(radians: Float(.pi*(1 + 1/180*synop.dWindAngle!)))
        }
        else {
            cell.WindDirection?.image = WindDirectionUnknownImage
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.stationLabel
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (self.bShowDetails) {
            return 103
        }
        return 50
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: size.width/2, y: size.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
//and to use this solution you can do the following

//let image = UIImage(named: "image.png")!
//let newImage = image.rotate(radians: .pi/2) // Rotate 90 degrees
