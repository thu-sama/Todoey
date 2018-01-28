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
import SwipeCellKit
import EFColorPicker

class CategoryViewController: SwipeTableViewController {
    
    let realm = try! Realm()
    var categoryArray: Results<Category>?
    var colorChangingIndex = 0

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
    
    //MARK: - Color Picker Override
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        var actions = super.tableView(tableView, editActionsForRowAt: indexPath, for: orientation)
        
        let colorSelectAction = SwipeAction(style: .default, title: "Color") { action, indexPath in
            self.colorChangingIndex = indexPath.row
            
            // start color picker
            let colorSelectionController = EFColorSelectionViewController()

            let navCtrl = UINavigationController(rootViewController: colorSelectionController)
            navCtrl.navigationBar.backgroundColor = UIColor.white
            navCtrl.navigationBar.isTranslucent = false
            navCtrl.modalPresentationStyle = UIModalPresentationStyle.popover
            //        navCtrl.popoverPresentationController?.delegate = self
            //        navCtrl.popoverPresentationController?.sourceView = sender
            //        navCtrl.popoverPresentationController?.sourceRect = sender.bounds
            navCtrl.preferredContentSize = colorSelectionController.view.systemLayoutSizeFitting(
                UILayoutFittingCompressedSize
            )

            colorSelectionController.isColorTextFieldHidden = true
            colorSelectionController.delegate = self
            
            if let categoryColorHex = self.categoryArray?[indexPath.row].color {
                colorSelectionController.color = UIColor(hexString: categoryColorHex) ?? UIColor.white
                self.efSelectedColor = colorSelectionController.color
            }

            if UIUserInterfaceSizeClass.compact == self.traitCollection.horizontalSizeClass {
                let doneBtn: UIBarButtonItem = UIBarButtonItem(
                    title: NSLocalizedString("Done", comment: ""),
                    style: UIBarButtonItemStyle.done,
                    target: self,
                    action: #selector(self.ef_dismissViewController(sender:))
                )
                
                let cancelBtn: UIBarButtonItem = UIBarButtonItem(
                    title: NSLocalizedString("Cancel", comment: ""),
                    style: UIBarButtonItemStyle.plain,
                    target: self,
                    action: #selector(self.ef_cancelViewController(sender:))
                )
                
                colorSelectionController.navigationItem.rightBarButtonItem = doneBtn
                colorSelectionController.navigationItem.leftBarButtonItem = cancelBtn
            }
            self.present(navCtrl, animated: true, completion: nil)
        }
        // customize the action appearance
        colorSelectAction.image = UIImage(named: "color-picker")
        
        if let colorHex = categoryArray?[indexPath.row].color {
            colorSelectAction.backgroundColor = ComplementaryFlatColorOf(UIColor(hexString: colorHex) ?? FlatBlue())
        }

        actions?.append(colorSelectAction)

        return actions
    }
    
    override func colorPickerCompleted(isChosen: Bool) {
        if isChosen {
            guard let category = categoryArray?[colorChangingIndex] else { return print("No Category Selected") }
            do{
                try realm.write {
                    category.color = efSelectedColor.hexValue()
                }
            }
            catch{
                print("Error saving color.\(error)")
            }
            tableView.reloadData()
        }
    }
}
