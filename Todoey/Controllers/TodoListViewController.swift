//
//  ViewController.swift
//  Todoey
//
//  Created by Tun Lin Thu on 2018/01/14.
//  Copyright © 2018 Tun Lin Thu. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {
    
    let realm = try! Realm()
    
    @IBOutlet weak var searchBar: UISearchBar!
    var todoItems : Results<Item>?
    var selectedCategory : Category? {
        didSet{
            loadItems()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        title = selectedCategory?.name
        guard let colorHex = selectedCategory?.color else { fatalError() }
        updateNavBar(withHex: colorHex)
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        updateNavBar(withHex: "1D9BF6")
    }
    
    //MARK: - Nav Bar Setup Methods
    func updateNavBar(withHex colorHex: String){
        guard let navBar = navigationController?.navigationBar else {
            fatalError("Navigation bar does not exist")
        }
        
        guard let navBarColor = UIColor(hexString: colorHex) else { fatalError() }
        let contrastColor = ContrastColorOf(navBarColor, returnFlat: true)
        navBar.barTintColor = navBarColor
        navBar.tintColor = contrastColor
        navBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor : contrastColor]
        searchBar.barTintColor = navBarColor
        
        //Remove Borders of Search Bar
//        navBar.backgroundImage(for: .any, barMetrics: .default)
//        navBar.shadowImage = UIImage()
        searchBar.isTranslucent = true
        searchBar.backgroundImage = UIImage()
        
    }
    
    //MARK: - Tableview Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableDataSourceEmpty ? 1 : todoItems?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if tableDataSourceEmpty {
            return cell
        }
        
        if let item = todoItems?[indexPath.row] {
            cell.textLabel?.text = item.title
            cell.accessoryType = item.done ? .checkmark : .none

            if let color = UIColor(hexString: selectedCategory!.color)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(todoItems!.count*3)){
                cell.backgroundColor = color
                
                let contrastColor = ContrastColorOf(color, returnFlat: true)
                cell.textLabel?.textColor = contrastColor
                cell.tintColor = contrastColor
            }
        }
        
        return cell
    }
    
    //MARK: - Tableview Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableDataSourceEmpty {
            addButtonPressed(navigationItem.rightBarButtonItem!)
        }
        else{
            guard let item = todoItems?[indexPath.row] else { fatalError("Error saving. No Item in todoItems.") }
            do{
                try realm.write {
                    item.done = !item.done
                }
            }
            catch{
                print("Error saving done status.\(error)")
            }
            tableView.reloadData()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add New Items
    @IBAction func addButtonPressed(_ sender: Any) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        
        //Add alert textfield
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create New Item"
            alertTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
            textField = alertTextField
        }
        
        //Add alert Action
        let alertAction = UIAlertAction(title: "Add Item", style: .default) { (action) in
            //what will happen when the user click add button
            guard let currentCategory = self.selectedCategory else { fatalError("Error, no selectedCategory.") }
            do{
                try self.realm.write {
                    let newItem = Item()
                    newItem.title = textField.text!
                    currentCategory.items.append(newItem)
                }
                self.tableDataSourceEmpty = self.todoItems!.isEmpty
            }
            catch{
                print("Error saving items.\(error)")
            }
            
            self.tableView.reloadData()
        }
        alert.addAction(alertAction)
        alertAction.isEnabled = false
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField){
        var responder : UIResponder! = textField
        while !(responder is UIAlertController) {
            responder = responder.next
        }
        //Enable or disable AlertTextField
        let alert = responder as! UIAlertController
        alert.actions[0].isEnabled = (textField.text != "")
    }
    
    //MARK: - Model Manipulation Data
    func loadItems(){
        todoItems = selectedCategory?.items.sorted(byKeyPath: "dateCreated", ascending: true)
        tableDataSourceEmpty = todoItems!.isEmpty
        tableView.reloadData()
    }
    
    //MARK: - Delete Data From Swipe
    override func updateModal(at indexPath: IndexPath) {
        guard let item = self.todoItems?[indexPath.row] else { fatalError("Error, no todoItems index.") }
        do{
            try self.realm.write {
                self.realm.delete(item)
            }
            
            tableDataSourceEmpty = todoItems!.isEmpty
        }
        catch{
            print("Error deleting category.\(error)")
        }
    }
}

//MARK: - Searchbar Methods
extension TodoListViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count==0 {
            loadItems()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
        else{
            //Refresh todoItems first
            todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
            
            todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
            tableDataSourceEmpty = todoItems!.isEmpty
            tableView.reloadData()
        }
    }
    
}
