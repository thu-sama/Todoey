//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Tun Lin Thu on 2018/01/27.
//  Copyright © 2018 Tun Lin Thu. All rights reserved.
//

import UIKit
import CoreData
import RealmSwift
import ChameleonFramework

class CategoryViewController: SwipeTableViewController {
    
    let realm = try! Realm()
    var categoryArray: Results<Category>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCategories()
    }
    
    //MARK: - Tableview Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableDataSourceEmpty ? 1 : categoryArray?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        if tableDataSourceEmpty {
            cell.textLabel?.text = "No Categories"
            return cell
        }
        
        if let category = categoryArray?[indexPath.row] {
            cell.textLabel?.text = category.name
            
            guard let categoryColor = UIColor(hexString: category.color) else {fatalError()}
            cell.backgroundColor = categoryColor
            cell.textLabel?.textColor = ContrastColorOf(categoryColor, returnFlat: true)
        }
        
        return cell
    }
    
    //MARK: - Tableview Manipulation Methods
    func loadCategories(){
        categoryArray = realm.objects(Category.self).sorted(byKeyPath: "dateCreated", ascending: true)
        tableDataSourceEmpty = categoryArray!.isEmpty
        tableView.reloadData()
    }
    
    func saveCategories(category: Category){
        do{
            try realm.write {
                realm.add(category)
            }
            tableDataSourceEmpty = categoryArray!.isEmpty
        }
        catch{
            print("Error saving context.\(error)")
        }
        
        tableView.reloadData()
    }
    
    //MARK: - Delete Data From Swipe
    override func updateModal(at indexPath: IndexPath) {
        if let category = self.categoryArray?[indexPath.row] {
            do{
                try self.realm.write {
                    self.realm.delete(category)
                }
                tableDataSourceEmpty = categoryArray!.isEmpty
            }
            catch{
                print("Error deleting category.\(error)")
            }
        }
    }
    
    //MARK: - Add New Category
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Category", message: "", preferredStyle: .alert)
        
        //Add textfield
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create New Category"
            alertTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
            textField = alertTextField
        }
        
        //Add aler actions
        let alertAction = UIAlertAction(title: "Add", style: .default) { (action) in
            //what will happen when the user click add button
            let newCategory = Category()
            newCategory.name = textField.text!
            newCategory.color = UIColor.randomFlat.hexValue()
            self.saveCategories(category: newCategory)
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
    
    //MARK: - Tableview Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableDataSourceEmpty {
            addButtonPressed(navigationItem.rightBarButtonItem!)
        }
        else{
            performSegue(withIdentifier: "goToItems", sender: self)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! TodoListViewController
        
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.selectedCategory = categoryArray?[indexPath.row]
        }
    }
}
