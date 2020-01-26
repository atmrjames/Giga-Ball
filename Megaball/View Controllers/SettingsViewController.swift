//
//  SettingsViewController.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    @IBOutlet weak var settingsTableView: UITableView!
    
    @IBAction func backButton(_ sender: Any) {
        mediumHaptic.impactOccurred()
        navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        // Setup table view delegates
        
        settingsTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        settingsTableView.separatorStyle = .none
        // Setup custom cell
        
        settingsTableView.rowHeight = 80.0
        
    }

    var descriptionArray = ["Sounds", "Music", "Haptics", "Parallax", "Paddle Control", "Paddle Sensitivity", "", ""]
    var stateArray = ["on", "on", "on", "on", "touch", "high", "", ""]
    var centreArray = ["", "", "", "", "", "", "Reset Game Data", "Restore Purchases"]
    // Define table view content
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return descriptionArray.count
    }
    // Set number of cells in table view
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
        if indexPath.row <= 5 {
            cell.settingDescription.text = descriptionArray[indexPath.row]
            cell.settingState.text = stateArray[indexPath.row]
            cell.centreLabel.text = ""
        } else if indexPath.row > 5 {
            cell.settingDescription.text = ""
            cell.settingState.text = ""
            cell.centreLabel.text = centreArray[indexPath.row]
        }
        
        
        
        return cell
    }
    // Add content to cells
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        
        print ([indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
}
