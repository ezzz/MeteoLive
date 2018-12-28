//
//  DirectTableViewController.swift
//  MeteoDirect
//
//  Created by Bruno ARENE on 17/12/2018.
//  Copyright © 2018 Bruno ARENE. All rights reserved.
//

import UIKit

class SynopCell : UITableViewCell {

    @IBOutlet weak var synopTime: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var rawLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var various: UILabel!
    @IBOutlet weak var textWeather: UILabel!
}

class DirectTableViewController: UITableViewController {
    var synopArray:Array<Synop> = []
    var bShowDetails = false
    
    @objc func refresh() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let sToday = formatter.string(from: Date()) // string purpose I add here
        let url = URL(string: "http://www.ogimet.com/cgi-bin/getsynop?begin=\(sToday)0000&end=\(sToday)2359&state=Fra")!
        //let url = URL(string: "http://www.ogimet.com/cgi-bin/getsynop?begin=201812150000&end=201812152359&state=Fra")!
        
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            let sData = String(bytes: data, encoding: .utf8)
            self.synopArray.removeAll()
            sData!.enumerateLines { line, _ in
                let sStationId = line.prefix(5)
                if (sStationId == "07149") {
                    let syn = Synop(rawdata:line)
                    syn.parse()
                    self.synopArray.append(syn)
                }
            }

            self.synopArray = self.synopArray.sorted(by: self.sortTimeDESC)
            
            //self.synopArray = self.synopArray.sorted(by: <#T##(Synop, Synop) throws -> Bool#>)(by: {$0.iTime > $1.iTime})
            
            
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

        
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
        self.navigationItem.rightBarButtonItem = refreshButton
        let showDetailshButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(showDetails))
        self.navigationItem.leftBarButtonItem = showDetailshButton

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.refresh()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        print("Array size:\(self.synopArray.count)")
        return self.synopArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellDirectId", for: indexPath) as! SynopCell

        let synop =  self.synopArray[indexPath.row]
        cell.synopTime?.text = synop.sTime
        cell.temperatureLabel?.text = synop.sTemperature
        cell.various?.text = synop.outString
        cell.textWeather?.text = synop.sWeather
        cell.rawLabel?.text = synop.sRawSynop
        cell.rawLabel?.numberOfLines = 0
        cell.rawLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.rawLabel?.sizeToFit()
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Orly - Athis-Mons (91) - 07149"
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (self.bShowDetails) {
            return 130.0
        }
        return 80.0
    }
 
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
