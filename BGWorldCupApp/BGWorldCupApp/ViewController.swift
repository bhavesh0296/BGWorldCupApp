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

        fetchRequest.sortDescriptors = [sortTeamNameDescriptor]

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.managedContext, sectionNameKeyPath: nil, cacheName: nil)

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
