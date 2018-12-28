//
//  SynopMessage.swift
//  MeteoDirect
//
//  Created by Bruno ARENE on 18/12/2018.
//  Copyright © 2018 Bruno ARENE. All rights reserved.
//

import Foundation

class Synop {
    var rawdata: String
    var arrSynop: [String]
    var sRawSynop: String
    var stationId: Int
    var sTime: String
    var iTime: Int
    var outString: String

    var sTemperature: String?
    var sDewPointTemperature: String?
    var sWindAngle: String?
    var sWindSpeed: String?
    var sCloudCoverage: String?
    var sWeather: String?
    var sRainMM: String?

    init(rawdata: String) {
        self.rawdata = rawdata
        
        let arrRawData = self.rawdata.components(separatedBy: ",")
        self.stationId = Int(arrRawData[0])!
        self.sRawSynop = String(arrRawData[6])
        self.sTime = String(Int(arrRawData[4])!+1)+"h"
        self.iTime = Int(arrRawData[4])!+1
        self.arrSynop = arrRawData[6].components(separatedBy: " ")

        self.outString = ""
    }
    
    // rawdata example: 07149,2018,12,26,12,00,AAXX 26121 07149 04120 70901 11007 21013 30209 40324 58010 60001 71011 876//
    // 333 34/// 55301 20577 59040 60007 87703 91003 90710 91103 555 60005 90760 91103==
    
    func parse() {
        print ("Parsing SYNOP:\n\(self.rawdata)")
        
        // Nddff - Total Cloud Cover and Wind Group
        //------------------------------------------
        self.sCloudCoverage = String(self.arrSynop[4]).dropLast(4) + "/8"
        let sub = String(self.arrSynop[4]).dropLast(2).dropFirst(1)
        self.sWindAngle = String(sub)
        
        var slWindAngle = String(self.arrSynop[4]).dropFirst(3) + "0°"
        if (slWindAngle.dropLast(3) == "0") {
            slWindAngle = String(slWindAngle).dropFirst()
        }
        self.sWindAngle = String(slWindAngle)
        
        // 1snTTT - Air ground temperature
        //--------------------------------
        var group = self.getGroup(groupId:1, sectionId:1)
        if (group == nil) {
            print ("No 1snTTT - Air ground temperature")
        }
        else {
            let sign = String(group!.dropLast(3).dropFirst())
            let sTemp = String(group!.dropFirst(2))
            var fTemp = Float(0.0)
            if (sign == "1") {
                fTemp = -1*Float(sTemp)!/10.0
            } else {
                fTemp = Float(sTemp)!/10.0
            }
            self.sTemperature = String(format:"%2.1f°", fTemp)
        }
        
        // 2snTdTdTd - Dew Point Temperature
        //--------------------------------
        group = self.getGroup(groupId:2, sectionId:1)
        if (group == nil) {
            print ("No 2snTdTdTd - Dew Point Temperature")
        }
        else {
            let sign = String(group!.dropLast(3).dropFirst())
            let sTemp = String(group!.dropFirst(2))
            var fTemp = Float(0.0)
            if (sign == "1") {
                fTemp = -1*Float(sTemp)!/10.0
            } else {
                fTemp = Float(sTemp)!/10.0
            }
            self.sDewPointTemperature = String(format:"%2.1f°", fTemp)
        }
        
        // 3PoPoPoPo - Station Pressure Group
        //--------------------------------

        // 4PPPP - Sea Level Pressure Group
        //--------------------------------

        // 5appp - 3-Hour Pressure Tendency Group
        //--------------------------------
        
        // 6RRRtR - Amount of Precipitation Group
        //--------------------------------
        group = self.getGroup(groupId:6, sectionId:1)
        if (group == nil) {
            print ("No 6RRRtR - Amount of Precipitation Group")
        }
        else {
            let value = Int(group!.dropLast().dropFirst())!
            if (value < 989) {
                self.sRainMM = String(value) + " mm"
            } else if (value == 990) {
                self.sRainMM = "Traces"
            } else if (value < 990) {
                self.sRainMM = "0,\(value % 990) mm"
            }
            
            let period = Int(group!.dropFirst(4))!
            let sPeriod = arrPeriodRain[period]
            self.sRainMM = self.sRainMM! + " (\(sPeriod!))"
        }
        
        // 7wwW1W2 - Present and Past Weather Group
        //--------------------------------
        group = self.getGroup(groupId:7, sectionId:1)
        if (group == nil) {
            print ("No 7wwW1W2 - Present and Past Weather Group")
        }
        else {
            let code = Int(group!.dropLast(2).dropFirst())!
            self.sWeather = arrWeather[code]
        }
        
        // 8NhCLCMCH - Cloud Type Group
        //--------------------------------
        // TODO

        // Outstring
        //self.outString   =  "\((String(Int(arrRawData[4])!+1)+"h").padding(toLength: 3, withPad: " ", startingAt: 0)) "
        self.outString = "Neb.: \(sCloudCoverage!) "
        if (self.sDewPointTemperature != nil) {
            self.outString += " Tr:\(self.sDewPointTemperature!)"
        }
        if (self.sRainMM != nil) {
            self.outString += " Pluie: \(self.sRainMM!)"
        }
    }
    
    func getGroup(groupId:Int, sectionId:Int) -> String? {
        let id3 = arrSynop.index(of: "333")
        let id5 = arrSynop.index(of: "555")
        
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
                    return p
                }
                
            }
        } else if (sectionId == 3) {
            // Todo...
        }
        return nil
    }
    
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
        00: "On n’a pas observé d’évolution des nuages ou on n’a pas pu suivre cette évolution",
        01: "Dans l’ensemble, nuages se dissipant ou devenant moins épais",
        02: "État du ciel inchangé dans l’ensemble",
        03: "Nuages en formation ou en train de se développer",
        04: "Visibilité réduite par de la fumée",
        05: "Brume sèche",
        06: "Poussières en suspension dans l’air d’une manière généralisée",
        07: "Poussières ou sable brassés par le vent",
        08: "Tourbillon(s) de poussière ou de sable caractérisé(s)",
        09: "Tempête de poussière ou de sable en vue de la station",
        10: "Brume",
        11: "Mince couche de brouillard ou de brouillard glacé en bancs",
        12: "Mince couche de brouillard ou de brouillard glacé plus ou moins continue",
        13: "Éclairs visibles, tonnerre non perceptible",
        14: "Précipitations en vue, n’atteignant pas le sol ou la surface de la mer",
        15: "Précipitations en vue, atteignant le sol ou la surface de la mer, mais distantes",
        16: "Précipitations en vue, atteignant le sol ou la surface de la mer, près de la station",
        17: "Orage, mais pas de précipitations au moment de l’observation",
        18: "Grains à la station ou en vue de celle-ci",
        19: "Trombe(s) à la station ou en vue de celle-ci",

        // ww = 20–29 Précipitations, brouillard, brouillard glacé ou orage à la station au cours de l’heure précédente, mais non au moment de l’observation
        20: "Bruine (ne se congelant pas) ou neige en grains",
        21: "Pluie (ne se congelant pas)",
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
        40: "Brouillard ou brouillard glacé à distance au moment de l’observation",
        41: "Brouillard ou brouillard glacé en bancs",
        42: "Brouillard ou brouillard glacé, ciel visible s’est aminci",
        43: "Brouillard ou brouillard glacé, ciel invisible s’est aminci",
        44: "Brouillard ou brouillard glacé, ciel visible sans changement",
        45: "Brouillard ou brouillard glacé, ciel invisible sans changement ",
        46: "Brouillard ou brouillard glacé, ciel visible a débuté ou est devenu plus épais",
        47: "Brouillard ou brouillard glacé, ciel invisible a débuté ou est devenu plus épais",
        48: "Brouillard, déposant du givre, ciel visible",
        49: "Brouillard, déposant du givre, ciel invisible",
    
        // ww = 50–99 Précipitations à la station au moment de l’observation
        // ww = 50–59 Bruine
        50: "Bruine, sans congélation, intermittente faible",
        51: "Bruine, sans congélation, continue faible",
        52: "Bruine, sans congélation, intermittente modérée",
        53: "Bruine, sans congélation, continue modérée",
        54: "Bruine, sans congélation, intermittente forte",
        55: "Bruine, sans congélation, continue forte",
        56: "Bruine, se congelant, faible",
        57: "Bruine, se congelant, modérée ou forte (dense)",
        58: "Bruine et pluie, faibles",
        59: "Bruine et pluie, modérées ou fortes",
        
        // ww = 60–69 Pluie
        60: "Pluie, sans congélation, intermittente faible",
        61: "Pluie, sans congélation, continue faible",
        62: "Pluie, sans congélation, intermittente modérée",
        63: "Pluie, sans congélation, continue modérée",
        64: "Pluie, sans congélation, intermittente forte",
        65: "Pluie, sans congélation, continue forte",
        66: "Pluie, se congelant, faible",
        67: "Pluie, se congelant, modérée ou forte",
        68: "Pluie (ou bruine) et neige, faibles",
        69: "Pluie (ou bruine) et neige, modérées ou fortes",
    
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
}
