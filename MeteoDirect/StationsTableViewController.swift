//
//  DirectTableViewController.swift
//  MeteoDirect
//
//  Created by Bruno ARENE on 17/12/2018.
//  Copyright © 2018 Bruno ARENE. All rights reserved.
//

import UIKit

class WeatherStationCell : UITableViewCell {

    @IBOutlet weak var Localisation: UILabel!
    
}

struct Station {
    let id: String
    let label: String
    let departement: String
}

class StationsTableViewController: UITableViewController {
    var arrStations: Array<Station> = [
        Station(id:"07028", label:"Le Havre - Cap de la Hève", departement:"76"),
        Station(id:"07027", label:"Caen-Carpiquet", departement:"14"),
        Station(id:"07031", label:"Deauville", departement:"14"),
        Station(id:"07149", label:"Orly", departement:"94"),
        Station(id:"07649", label:"Aix Les Milles", departement:"13")
    ]

    
    override func viewDidLoad() {
        super.viewDidLoad()

        /*
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
        self.navigationItem.rightBarButtonItem = refreshButton
        let showDetailshButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(showDetails))
        self.navigationItem.leftBarButtonItem = showDetailshButton
 
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.refresh()*/
        //tableView.register(UINib(nibName: "Main.storyboard", bundle: nil), forCellReuseIdentifier: "WeatherStationCellId")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrStations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherStationCellId", for: indexPath) as! WeatherStationCell
        
        let stationName = arrStations[indexPath.row].label
        let departementNumber = arrStations[indexPath.row].departement
        cell.Localisation?.text = "\(stationName) (\(departementNumber))"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let destination = SynopTableViewController(nibName: "SynopTableView", bundle: nil)
        destination.stationId = arrStations[indexPath.row].id
        destination.stationLabel = "\(arrStations[indexPath.row].label) (\(arrStations[indexPath.row].departement))"
        navigationController?.pushViewController(destination, animated: true)
    }
    /*
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (self.bShowDetails) {
            return 130.0
        }
        return 80.0
    }*/
 
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
