//
//  ViewController.swift
//  FilterOperation
//
//  Created by Ömer Faruk Öztürk on 2.12.2017.
//  Copyright © 2017 omerfarukozturk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var filterManager : FilterOperationManager?
    
    @IBOutlet weak var tableVC: UITableView!
    
    @IBOutlet weak var searchTextField: UITextField!
    var userDataList : [UserDataModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        self.tableVC.delegate = self
        self.tableVC.dataSource = self
        
        self.searchTextField.delegate = self
        
        
        let dataList = self.loadData()
        
        self.userDataList = dataList
        self.tableVC.reloadData()
        
        self.filterManager = FilterOperationManager(allItems: dataList)
        self.filterManager?.searchCompleted = { [weak self] filteredList in
            self?.userDataList = filteredList as! [UserDataModel]
            self?.tableVC.reloadData()
        }
    }

    private func loadData() -> [UserDataModel] {
        
        /*
         Read from MockData.json file.
         Generated from: http://www.databasetestdata.com/generated-data
         */
        
        do {
            if let file = Bundle.main.url(forResource: "MockData", withExtension: "json") {
                let data = try Data(contentsOf: file)

                let decodedData = try JSONDecoder().decode([UserDataModel].self, from: data)
                
                return decodedData
                
            } else {
                print("file not found.")
                return []
            }
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
}

//MARK: - UITableView delegates

extension ViewController: UITableViewDelegate, UITableViewDataSource  {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserDataTableViewCell", for: indexPath) as! UserDataTableViewCell
        
        let cellData = self.userDataList[indexPath.row]
        cell.setupCell(data: cellData)
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userDataList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

//MARK: - UITextField delegates
extension ViewController : UITextFieldDelegate{
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        self.searchTextField! setIntelliKeyboardType(string)
        
        if string == "\n" {
            self.filterManager?.searchKeyword = nil
            self.searchTextField!.resignFirstResponder()
            return false
        }
        let searchText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        self.searchTextField!.text = searchText
        
        self.filterManager?.filter(searchText)
        
        return false
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.filterManager?.searchKeyword = nil
        self.searchTextField!.text = ""
        self.filterManager?.filter("")
        return false
    }
}


class UserDataModel : Codable, Searchable {
    var Id : Int
    var Name : String
    var Country : String
    var Email : String
    
    var searchText : String?
    func getSearchText() -> String {
        if self.searchText != nil {
            return self.searchText!
        }
        
        // set keywords.
        self.searchText = Name + "@" + Country + "@" + Email
        
        return self.searchText!
    }
}

class UserDataTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    
    func setupCell(data: UserDataModel) {
        self.nameLabel.text = data.Name
        self.countryLabel.text = data.Country
        self.emailLabel.text = data.Email
    }
}
