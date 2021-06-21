//
//  ViewController.swift
//  BGWorldCupApp
//
//  Created by bhavesh on 20/06/21.
//  Copyright © 2021 Bhavesh. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    // MARK: - Properties
    fileprivate let teamCellIdentifier = "teamCellReuseIdentifier"
    lazy var  coreDataStack = CoreDataStack(modelName: "BGWorldCupApp")

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!


    lazy var fetchResultController: NSFetchedResultsController<Team> = {

        let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()

        let sortTeamNameDescriptor = NSSortDescriptor(key: #keyPath(Team.teamName), ascending: true)
        let sortZoneDescriptor = NSSortDescriptor(key: #keyPath(Team.qualifyingZone), ascending: true)
        let sortScoreDescriptor = NSSortDescriptor(key: #keyPath(Team.wins), ascending: false)

        fetchRequest.sortDescriptors = [sortZoneDescriptor, sortScoreDescriptor, sortTeamNameDescriptor]

        let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.managedContext, sectionNameKeyPath: #keyPath(Team.qualifyingZone), cacheName: "worldCup")
        fetchResultController.delegate = self
        return fetchResultController

    }()

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        importJSONSeedDataIfNeeded()

        do {
            try fetchResultController.performFetch()
        } catch {
            print(error.localizedDescription)
        }
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            addButton.isEnabled = true
        }
    }

    @IBAction func addTeam(_ sender: UIButton) {
        let alert = UIAlertController(title: "Add team", message: "Add Secret Team", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.placeholder = "Team Name"
        }

        alert.addTextField { (textField) in
            textField.placeholder = "Zone"
        }

        let actionAdd = UIAlertAction(title: "Add", style: .default) { [unowned self] (action) in

            if let teamNameTextField = alert.textFields?.first,
                let zoneTextField = alert.textFields?.last {
                let team = Team(context: self.coreDataStack.managedContext)
                team.teamName = teamNameTextField.text
                team.qualifyingZone = zoneTextField.text
                self.coreDataStack.saveContext()
            }
        }

        let actionCancel = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)

        alert.addAction(actionCancel)
        alert.addAction(actionAdd)

        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Internal
extension ViewController {

    func configure(cell: UITableViewCell, for indexPath: IndexPath) {

        guard let cell = cell as? TeamCell else {
            return
        }

        let team = fetchResultController.object(at: indexPath)

        cell.flagImageView.backgroundColor = .blue
        cell.teamLabel.text = team.teamName
        cell.scoreLabel.text = "Wins: \(team.wins)"
        if let imageName = team.imageName {
            cell.flagImageView.image = UIImage(named: imageName)
        } else {
            cell.flagImageView.image = nil
        }
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchResultController.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchResultController.sections?[section] else {
            return 0
        }
        return sectionInfo.numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: teamCellIdentifier, for: indexPath)

        configure(cell: cell, for: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let team = fetchResultController.object(at: indexPath)
        team.wins += 1
        coreDataStack.saveContext()
//        DispatchQueue.main.async { [weak self] in
//            guard let `self` = self else { return }
//            self.tableView.reloadData()
//        }

    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchResultController.sections?[section]
        return sectionInfo?.name
    }
}


// MARK: - Helper methods
extension ViewController {

    func importJSONSeedDataIfNeeded() {

        let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
        let count = try? coreDataStack.managedContext.count(for: fetchRequest)

        guard let teamCount = count,
            teamCount == 0 else {
                return
        }

        importJSONSeedData()
    }

    func importJSONSeedData() {

        let jsonURL = Bundle.main.url(forResource: "seed", withExtension: "json")!
        let jsonData = try! Data(contentsOf: jsonURL)

        do {
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData, options: [.allowFragments]) as! [[String: Any]]

            for jsonDictionary in jsonArray {
                let teamName = jsonDictionary["teamName"] as! String
                let zone = jsonDictionary["qualifyingZone"] as! String
                let imageName = jsonDictionary["imageName"] as! String
                let wins = jsonDictionary["wins"] as! NSNumber

                let team = Team(context: coreDataStack.managedContext)
                team.teamName = teamName
                team.imageName = imageName
                team.qualifyingZone = zone
                team.wins = wins.int32Value
            }

            coreDataStack.saveContext()
            print("Imported \(jsonArray.count) teams")

        } catch let error as NSError {
            print("Error importing teams: \(error)")
        }
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {


    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }


    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .update:
            let cell = tableView.cellForRow(at: indexPath!) as! TeamCell
            configure(cell: cell, for: indexPath!)
        @unknown default:
            print("unknown case")
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {

        let indexSet = IndexSet(integer: sectionIndex)

        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
        default:
            break
        }
    }


    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

}
