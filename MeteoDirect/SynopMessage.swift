//
//  SynopMessage.swift
//  MeteoDirect
//
//  Created by Bruno ARENE on 18/12/2018.
//  Copyright © 2018 Bruno ARENE. All rights reserved.
//

import Foundation
import UIKit

class Synop {
    var rawdata: String
    var arrSynop: [String]
    var sRawSynop: String
    var stationId: Int
    var sTime: String
    var iTime: Int
    var iTimeUTC: Int
    var outString: String

    var dTemperature: Double?
    var dDewPointTemperature: Double?
    var dRelativeHumidity: Double?
    var dSeaLevelPressure: Double?
    var dBioMeteo: Double?
    var dWindAngle: Double?
    var dWindMeanSpeed: Double?
    var dWindMaxSpeed: Double?
    var sCloudHeightCode: String = ""
    var sCloudHeightLabel: String = ""
    var sHorizontalVisibility: String = ""
    var fHorizontalVisibility: Float = 0
    var sCloudCoverage: String?
    var sWeather: String?
    var sRainMM: String?
    var iSunMinutes: Int?
    var iSunRadiation: Int?

    var sMinTemperature: String = ""
    var sMinTemperaturePeriod: String = ""
    var sMaxTemperature: String = ""
    var sMaxTemperaturePeriod: String = ""
    var sGroundState: String = ""
    var sGroundStateSnow: String = ""
    var sRainMM_sec3: String = ""
    var fRainMM_sec3: Float = 0.0 // Pas de pluie ou non défini= 0.0, Traces = 0.01, ensuite 0.1, 0.2....

    init(rawdata: String) {
        self.rawdata = rawdata
        
        let arrRawData = self.rawdata.components(separatedBy: ",")
        self.stationId = Int(arrRawData[0])!
        self.sRawSynop = String(arrRawData[6])
        self.sTime = String(Int(arrRawData[4])!+1)+"h"
        self.iTime = Int(arrRawData[4])!+1
        self.iTimeUTC = Int(arrRawData[4])!
        self.arrSynop = arrRawData[6].components(separatedBy: " ")

        self.outString = ""
    }
    
    // rawdata example: 07149,2018,12,26,12,00,AAXX 26121 07149 04120 70901 11007 21013 30209 40324 58010 60001 71011 876//
    // 333 34/// 55301 20577 59040 60007 87703 91003 90710 91103 555 60005 90760 91103==
    
    func parse() {
        print ("Parsing SYNOP:\n\(self.rawdata)")
        
        
        // iRiXhVV - Precipitation Inclusion-Exclusion / Type operation / Cloud height / Visibility Group
        //-----------------------------------------------------------------------------------------------
        // Cloud height
        self.sCloudHeightCode = String(String(self.arrSynop[3]).dropLast(2).dropFirst(2))
        if (self.sCloudHeightCode.count == 1 && self.sCloudHeightCode != "/") {
            self.sCloudHeightLabel = self.arrLowestCloudBaseHeight[Int(self.sCloudHeightCode)!]!
        }
        
        // Visibility Group
        let visi = String(String(self.arrSynop[3]).dropFirst(3))
        if (visi != "//") {
            let iVisi = Int(visi)!
            if (iVisi <= 50) {
                self.fHorizontalVisibility = Float(iVisi) / 10
            } else if (iVisi <= 80) {
                self.fHorizontalVisibility = Float(iVisi) - 30
            } else {
                switch iVisi {
                case 81: self.fHorizontalVisibility = 35
                case 82: self.fHorizontalVisibility = 40
                case 83: self.fHorizontalVisibility = 45
                case 84: self.fHorizontalVisibility = 50
                case 85: self.fHorizontalVisibility = 55
                case 86: self.fHorizontalVisibility = 60
                case 87: self.fHorizontalVisibility = 65
                case 88: self.fHorizontalVisibility = 70
                case 89: self.fHorizontalVisibility = 80
                case 90: self.fHorizontalVisibility = 0.0
                case 91: self.fHorizontalVisibility = 0.1
                case 92: self.fHorizontalVisibility = 0.2
                case 93: self.fHorizontalVisibility = 0.5
                case 94: self.fHorizontalVisibility = 1
                case 95: self.fHorizontalVisibility = 2
                case 96: self.fHorizontalVisibility = 4
                case 97: self.fHorizontalVisibility = 10
                case 98: self.fHorizontalVisibility = 20
                case 99: self.fHorizontalVisibility = 50
                default: self.fHorizontalVisibility = 0
                }
            }
        }

        
        // Nddff - Total Cloud Cover and Wind Group
        //------------------------------------------
        self.sCloudCoverage = String(String(self.arrSynop[4]).dropLast(4))
        
        let valueWindAngle = String(self.arrSynop[4]).dropLast(2).dropFirst(1)
        if (!valueWindAngle.contains("/")) {
            self.dWindAngle = Double(valueWindAngle)! * 10
        }
        
        let valueWindSpeed = String(self.arrSynop[4].dropFirst(3))
        if (!valueWindSpeed.contains("/")) {
            self.dWindMeanSpeed = Double(valueWindSpeed)! * 3.6
        }

        // 1snTTT - Air ground temperature
        //--------------------------------
        var group = self.getGroups(groupId:1, sectionId:1)
        if (group.count >= 1) {
            let sign = String(group[0].dropLast(3).dropFirst())
            let sTemp = String(group[0].dropFirst(2))
            if (sign == "1") {
                self.dTemperature = -1*Double(sTemp)!/10.0
            } else {
                self.dTemperature = Double(sTemp)!/10.0
            }
        }
        
        // 2snTdTdTd - Dew Point Temperature
        //--------------------------------
        group = self.getGroups(groupId:2, sectionId:1)
        if (group.count >= 1) {
            let sign = String(group[0].dropLast(3).dropFirst())
            let sTemp = String(group[0].dropFirst(2))
            if (sign == "1") {
                self.dDewPointTemperature = -1*Double(sTemp)!/10.0
            } else {
                self.dDewPointTemperature = Double(sTemp)!/10.0
            }
        }
        
        // Relative humidity calculation
        if (self.dTemperature != nil && self.dDewPointTemperature != nil) {
            self.dRelativeHumidity = self.calculateHumidity(T: self.dTemperature!, Tr: self.dDewPointTemperature!)
        }
        
        // Windchill calculation
        if (self.dTemperature != nil && self.dWindMeanSpeed != nil && self.dTemperature! < 10) {
            self.dBioMeteo = self.calculateWindChill(T:self.dTemperature!, WindMean:self.dWindMeanSpeed!)
        } else if (self.dTemperature != nil && self.dWindMeanSpeed != nil && self.dTemperature! > 20) {
            self.dBioMeteo = self.calculateHumidex(T:self.dTemperature!, Tr:self.dDewPointTemperature!)
        }
        
        // 3PoPoPoPo - Station Pressure Group
        //--------------------------------

        // 4PPPP - Sea Level Pressure Group
        //--------------------------------
        group = self.getGroups(groupId:4, sectionId:1)
        if (group.count >= 1) {
            let dTemp = Double(group[0].dropFirst())!
            if (dTemp > 900.0) {
                self.dSeaLevelPressure = dTemp / 10.0
            } else {
                self.dSeaLevelPressure = dTemp / 10.0 + 1000
            }
        }
        
        // 5appp - 3-Hour Pressure Tendency Group
        //--------------------------------
        
        // 6RRRtR - Amount of Precipitation Group
        //--------------------------------
        group = self.getGroups(groupId:6, sectionId:1)
        if (group.count >= 1) {
            let value = Int(group[0].dropLast().dropFirst())!
            if (value < 989) {
                self.sRainMM = String(value) + " mm"
            } else if (value == 990) {
                self.sRainMM = "Traces"
            } else if (value > 990) {
                self.sRainMM = "0,\(value % 990) mm"
            }
            
            let period = Int(group[0].dropFirst(4))!
            let sPeriod = arrPeriodRain[period]
            self.sRainMM = self.sRainMM! + " (\(sPeriod!))"
        }
        
        // 7wwW1W2 - Present and Past Weather Group
        //--------------------------------
        group = self.getGroups(groupId:7, sectionId:1)
        if (group.count >= 1) {
            let code = Int(group[0].dropLast(2).dropFirst())!
            self.sWeather = arrWeather[code]
        }
        
        // 8NhCLCMCH - Cloud Type Group
        //--------------------------------
        // TODO

        //--------------------------------
        // Section 3
        //--------------------------------

        // 1snTxTxTx - Maximum Temperature Group
        //--------------------------------------
        group = self.getGroups(groupId:1, sectionId:3)
        if (group.count >= 1) {
            let sign = String(group[0].dropLast(3).dropFirst())
            let sTemp = String(group[0].dropFirst(2))
            var fTemp = Float(0.0)
            if (sign == "1") {
                fTemp = -1*Float(sTemp)!/10.0
            } else {
                fTemp = Float(sTemp)!/10.0
            }
            self.sMaxTemperature = String(format:"%2.1f°", fTemp)
            
            // 0000Z Report maximum temperature during past 12 hours.
            // 0600Z Report maximum temperature during past 24 hours.
            // 1200Z Report maximum temperature during previous calendar day ending at midnight time.
            // 1800Z Report maximum temperature during past 12 hours.
            switch self.iTimeUTC {
            case 0:
                self.sMaxTemperaturePeriod = "/12h"
            case 6:
                self.sMaxTemperaturePeriod = "/24h"
            case 12:
                self.sMaxTemperaturePeriod = "/hier"
            case 18:
                self.sMaxTemperaturePeriod = "/12h"
            default:
                self.sMaxTemperaturePeriod = "/??"
            }
        }
        
        // 2snTxTxTx - Minimum Temperature Group
        //--------------------------------------
        group = self.getGroups(groupId:2, sectionId:3)
        if (group.count >= 1) {
            let sign = String(group[0].dropLast(3).dropFirst())
            let sTemp = String(group[0].dropFirst(2))
            var fTemp = Float(0.0)
            if (sign == "1") {
                fTemp = -1*Float(sTemp)!/10.0
            } else {
                fTemp = Float(sTemp)!/10.0
            }
            self.sMinTemperature = String(format:"%2.1f°", fTemp)
            // TODO
            // 0000Z Report minimum temperature for past 18 hours.
            // 0600Z Report minimum temperature for past 24 hours.
            // 1200Z Report minimum temperature for past 12 hours.
            // 1800Z Report minimum temperature for past 24 hours.
            switch self.iTimeUTC {
            case 0:
                self.sMinTemperaturePeriod = "/18h"
            case 6:
                self.sMinTemperaturePeriod = "/24h"
            case 12:
                self.sMinTemperaturePeriod = "/12h"
            case 18:
                self.sMinTemperaturePeriod = "/24h"
            default:
                self.sMinTemperaturePeriod = "/??"
            }
            
        }
        
        // 3E/// - State of the ground without snow or measurable ice cover
        //--------------------------------------
        // E = Use code table 0901.
        group = self.getGroups(groupId:3, sectionId:3)
        if (group.count >= 1) {
            let code = String(group[0].dropLast(3).dropFirst())
            self.sGroundState = arrGroundState[Int(code)!]!
            //TODO add table for code
        }
        
        // 4ESSS - State of the ground with snow or ice cover
        //--------------------------------------
        group = self.getGroups(groupId:4, sectionId:3)
        if (group.count >= 1) {
            let code = String(group[0].dropLast(3).dropFirst())
            self.sGroundStateSnow = code
            //TODO add table for code
        }
        
        // 5 - Ensoleillement
        //--------------------------------------
        group = self.getGroups(groupId:5, sectionId:3)
        if (group.count >= 1) {
            if (group[0].dropLast(2) == "553") {
                self.iSunMinutes = Int(group[0].dropFirst(3))!*6
            }
            if (group.count >= 2) {
                if (group[1].dropLast(4) == "2") {
                    self.iSunRadiation = Int(group[1].dropFirst())!
                }
            }
        }
        
        // 6 Pluie
        //--------
        group = self.getGroups(groupId:6, sectionId:3)
        if (group.count >= 1) {
            let value = Int(group[0].dropLast().dropFirst())!
            if (value < 989) {
                self.sRainMM_sec3 = String(value) + " mm"
                self.fRainMM_sec3 = Float(value)
            } else if (value == 990) {
                self.sRainMM_sec3 = "Traces"
                self.fRainMM_sec3 = 0.01
            } else if (value > 990) {
                self.sRainMM_sec3 = "0,\(value % 990) mm"
                self.fRainMM_sec3 = Float(value - 990)/10.0
            }
        }
        
        // 911ff - Rafale le plus élevée
        //------------------------------
        group = self.getGroups(groupId:911, sectionId:3)
        if (group.count >= 1) {
            let value = Int(group[0].dropFirst(3))!
            self.dWindMaxSpeed = Double(value) * 3.6
        }
    }
    
    func getGroups(groupId:Int, sectionId:Int) -> Array<String> {
        print("getGroups(id:\(groupId), section:\(sectionId)")
        let id3 = arrSynop.index(of: "333")
        let id5 = arrSynop.index(of: "555")
        var ret:Array<String> = []
        if (sectionId == 1) {
            var endSection = self.arrSynop.count
            if (id3 != nil) {
                endSection = id3!
            } else if (id5 != nil) {
                endSection = id5!
            }
            // Starting at index 5 : temperature
            for i in 5 ..< endSection {
                let p = self.arrSynop[i]
                if (p.count == 5 && p.dropLast(4) == String(groupId)) {
                    ret.append(p)
                }
            }
        } else if (sectionId == 3) {
            let startSection = id3! + 1
            var endSection = self.arrSynop.count
            if (id5 != nil) {
                endSection = id5!
            }
            // 333 (0CsDLDMDH) 1snTxTxTx 2snTnTnTn 3Ejjj 4E'sss 5j1j2j3j4 (j5j6j7j8j9) 6xxxx 7R24R24R24R24 8NsChshs 9SpSpspsp
            var previous55xxx = ""
            for i in startSection  ..< endSection {
                let p = self.arrSynop[i]
                if (p.dropLast(3) == "55") {
                    previous55xxx = p
                    // Do nothing, wait for next value
                }
                else {
                    if (previous55xxx.count > 0) {
                        if (groupId == 5) {
                            ret.append(previous55xxx)
                            ret.append(p)
                        }
                    }
                    else if (p.count == 5 && p.dropLast(5 - String(groupId).count) == String(groupId)) {
                        // specific case for group 55xxx > followed by (j5j6j7j8j9)
                        ret.append(p)
                    }
                    previous55xxx = ""
                }

            }
        }
        print("returned : id:\(ret)")

        return ret
    }
    
    // Code table 1600 h — Height above surface of the base of the lowest cloud seen
    let arrLowestCloudBaseHeight: [Int:String] = [
        0: "50m",
        1: "100m",
        2: "200m",
        3: "300m",
        4: "600m",
        5: "1000m",
        6: "1500m",
        7: "2000m",
        8: "2500m",
        9: ">2500m"]

    // Code table 0901 - State of the ground without snow
    let arrGroundState: [Int:String] = [
        0: "sec", //Surface of ground dry (without cracks and no appreciable amount of dust or loose sand)
        1: "humide", //Surface of ground moist
        2: "mouillé", //Surface of ground wet (standing water in small or large pools on surface)
        3: "inondé", //Flooded
        4: "gelé", //Surface of ground frozen
        5: "glacé", //Glaze on ground
        6: "poussiéreux", //Loose dry dust or sand not covering ground completely
        7: "poussiéreux", //Thin cover of loose dry dust or sand covering ground completely
        8: "poussiéreux", //Moderate or thick cover of loose dry dust or sand covering ground completely
        9: "très sec"] //Extremely dry with cracks
    
    // Code table 4019 Duration of period of precipitation
    let arrPeriodRain: [Int:String] = [
        1: "6h",
        2: "12h",
        3: "18",
        4: "24",
        5: "1",
        6: "2",
        7: "3",
        8: "9",
        9: "15"]
    
    let arrWeather: [Int:String] = [
    
        // ww = 00–19 Pas de précipitations, de brouillard, de brouillard glacé (exception faite pour 11 et 12), de tempête de poussière, de tempête de sable,
        // de chasse-neige basse ou élevée à la station* au moment de l’observation ou, exception faite pour 09 et 17, durant l’heure précédente
        00: "Pas d'évolution observée des nuages",
        01: "Nuages se dissipant ou devenant moins épais",
        02: "État du ciel inchangé dans l’ensemble",
        03: "Nuages en formation ou en train de se développer",
        04: "Visibilité réduite par de la fumée",
        05: "Brume sèche",
        06: "Poussières en suspension dans l’air d’une manière généralisée",
        07: "Poussières ou sable brassés par le vent",
        08: "Tourbillon(s) de poussière ou de sable caractérisé(s)",
        09: "Tempête de poussière ou de sable en vue de la station",
        10: "Brume",
        11: "Mince couche de brouillard en bancs",
        12: "Mince couche de brouillard plus ou moins continue",
        13: "Éclairs visibles, tonnerre non perceptible",
        14: "Précipitations en vue, n’atteignant pas le sol ou la surface de la mer",
        15: "Précipitations en vue, atteignant le sol, mais distantes",
        16: "Précipitations en vue, atteignant le sol, près de la station",
        17: "Orage, mais pas de précipitations au moment de l’observation",
        18: "Grains à la station ou en vue de celle-ci",
        19: "Trombe(s) à la station ou en vue de celle-ci",

        // ww = 20–29 Précipitations, brouillard, brouillard glacé ou orage à la station au cours de l’heure précédente, mais non au moment de l’observation
        20: "Bruine ou neige en grains",
        21: "Pluie",
        22: "Neige",
        23: "Pluie et neige mêlées ou granules de glace",
        24: "Bruine ou pluie se congelant",
        25: "Averse(s) de pluie",
        26: "Averse(s) de neige, ou de pluie et de neige",
        27: "Averse(s) de grêle, ou de pluie et de grêle",
        28: "Brouillard ou brouillard glacé",
        29: "Orage (avec ou sans précipitations)",
    
        // ww = 30–39 Tempête de poussière, tempête de sable, chasse-neige basse ou élevée
        30: "Tempête de poussière ou de sable faible ou modérée",
        31: "Tempête de poussière ou de sable faible ou modérée",
        32: "Tempête de poussière ou de sable faible ou modérée",
        33: "Violente tempête de poussière ou de sable",
        34: "Violente tempête de poussière ou de sable",
        35: "Violente tempête de poussière ou de sable",
        36: "Chasse-neige faible ou modérée",
        37: "Forte chasse-neige",
        38: "Chasse-neige faible ou modérée",
        39: "Forte chasse-neige",
    
        // ww = 40–49 Brouillard ou brouillard glacé au moment de l’observation
        40: "Brouillard à distance au moment de l’observation",
        41: "Brouillard en bancs",
        42: "Brouillard, ciel visible s’est aminci",
        43: "Brouillard, ciel invisible s’est aminci",
        44: "Brouillard, ciel visible sans changement",
        45: "Brouillard, ciel invisible sans changement ",
        46: "Brouillard, ciel visible a débuté ou est devenu plus épais",
        47: "Brouillard, ciel invisible a débuté ou est devenu plus épais",
        48: "Brouillard, déposant du givre, ciel visible",
        49: "Brouillard, déposant du givre, ciel invisible",
    
        // ww = 50–99 Précipitations à la station au moment de l’observation
        // ww = 50–59 Bruine
        50: "Bruine, intermittente faible",
        51: "Bruine, continue faible",
        52: "Bruine, intermittente modérée",
        53: "Bruine, continue modérée",
        54: "Bruine, intermittente forte",
        55: "Bruine, continue forte",
        56: "Bruine, se congelant, faible",
        57: "Bruine, se congelant, modérée ou forte (dense)",
        58: "Bruine et pluie, faibles",
        59: "Bruine et pluie, modérées ou fortes",
        
        // ww = 60–69 Pluie
        60: "Pluie, intermittente faible",
        61: "Pluie, continue faible",
        62: "Pluie, intermittente modérée",
        63: "Pluie, continue modérée",
        64: "Pluie, intermittente forte",
        65: "Pluie, continue forte",
        66: "Pluie, se congelant, faible",
        67: "Pluie, se congelant, modérée ou forte",
        68: "Pluie et neige, faibles",
        69: "Pluie et neige, modérées ou fortes",
    
        // ww = 70–79 Précipitations solides non sous forme d’averses
        70: "Chute intermittente de flocons de neige faible",
        71: "Chute continue de flocons de neige faible",
        72: "Chute intermittente de flocons de neige modérée",
        73: "Chute continue de flocons de neige modérée",
        74: "Chute intermittente de flocons de neige forte",
        75: "Chute continue de flocons de neige forte",
        76: "Poudrin de glace (avec ou sans brouillard)",
        77: "Neige en grains (avec ou sans brouillard)",
        78: "Étoiles de neige isolées (avec ou sans brouillard)",
        79: "Granules de glace",
        
        // ww = 80–99 Précipitations sous forme d’averses, ou précipitations avec orage ou après un orage
        80: "Averse(s) de pluie, faible(s)",
        81: "Averse(s) de pluie, modérée(s) ou forte(s)",
        82: "Averse(s) de pluie, violente(s)",
        83: "Averse(s) de pluie et neige mêlées, faible(s)",
        84: "Averse(s) de pluie et neige mêlées, modérée(s) ou forte(s)",
        85: "Averse(s) de neige, faible(s)",
        86: "Averse(s) de neige, modérée(s) ou forte(s)",
        87: "Averse(s) de grésil ou neige roulée avec ou sans pluie",
        88: "Averse(s) de grésil ou neige roulée avec ou sans pluie",
        89: "Averse(s) de grêle avec ou sans pluie, sans tonnerre",
        90: "Averse(s) de grêle avec ou sans pluie, sans tonnerre",
        91: "Pluie faible au moment de l’observation",
        92: "Pluie modérée ou forte au moment de l’observation",
        93: "Faible chute de neige, ou pluie et neige mêlées ou grêle",
        94: "Chute modérée ou forte de neige, ou pluie et neige mêlées ou grêle",
        95: "Orage faible ou modéré, sans grêle, mais avec pluie ou neige ou pluie et neige mêlées",
        96: "Orage faible ou modéré, avec grêle",
        97: "Orage fort, sans grêle, mais avec pluie ou neige ou pluie et neige mêlées",
        98: "Orage avec tempête de poussière ou de sable",
        99: "Orage fort, avec grêle"]
    
    func calculateHumidity(T: Double, Tr: Double) -> Double {
        func e(T: Double) -> Double {
            let a = [6.107799961, 4.436518521e-1, 1.428945805e-2, 2.650648471e-4, 3.031240396e-6, 2.034080948e-8, 6.136820929e-11]
            return a[0]+T*(a[1]+T*(a[2]+T*(a[3]+T*(a[4]+T*(a[5]+T*a[6])))))
        }
        let eT = e(T:T)
        let eTr = e(T:Tr)
        return eTr/eT
    }
    
    func calculateHumidex(T: Double, Tr: Double) -> Double {
        let diff = 1/273.16 - 1/(273.15+Tr)
        let expdiff = 6.11 * exp (5417.753*diff)
        let h = T + 0.5555 * ( expdiff - 10)
        return h
    }

    // Wind Chill in Watts per meter squared​ (mW )​, it can be calculated using an air temperature in degrees Celsius (°C)
    // and a wind speed in meters per second ( ms )
    func calculateWindChill(T: Double, WindMean: Double) -> Double {
        return (13.12 + 0.6215 * T + (0.3965 * T - 11.37) * pow(WindMean, 0.16))
    }
}
