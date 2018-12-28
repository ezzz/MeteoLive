//
//  TabBarViewController.swift
//  MeteoDirect
//
//  Created by Bruno ARENE on 20/12/2018.
//  Copyright © 2018 Bruno ARENE. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //self.tabBar.items?[0].selectedImage = UIImage(named: "first")?.withRenderingMode(.alwaysTemplate)
        //self.tabBar.items?[0].image = UIImage(named: "first")?.withRenderingMode(.alwaysTemplate)
        self.tabBar.items?[0].selectedImage = UIImage(named: "weather")?.withRenderingMode(.alwaysOriginal)
        self.tabBar.items?[0].image = UIImage(named: "weather")?.withRenderingMode(.alwaysTemplate)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
