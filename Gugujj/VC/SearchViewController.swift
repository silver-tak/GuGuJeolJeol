//
//  SearchViewController.swift
//  Gugujj
//
//  Created by Seonju Kim on 2022/05/23.
//

import UIKit
import FirebaseStorage

class SearchViewController: BaseViewController {

    // MARK: - Properties
    private let storage: Storage = Storage.storage()
    private let storagePath: String = "gs://gugujeoljeol-6f201.appspot.com/templeJSONData.json"
    
    private var allTemples: [Temple] = [Temple]()
    private var searchResultTemples: [Temple] = [Temple]()
    private var availableParkingTemples: [Temple] = [Temple]()
    private var availablePetTemples: [Temple] = [Temple]()
    private var isHeritageTemples: [Temple] = [Temple]()
    
    private let userDefaults: UserDefaults = UserDefaults.standard
    
    // MARK: - IBOutlets
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBAction func touchUpBackButton(_ sender: UIButton) {
        CommonNavi.popVC()
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.navigationController = self.navigationController
        }
        
        searchTextField.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isSwipedFlag = false
        
        if let data = userDefaults.value(forKey: "Temples") as? Data {
            allTemples = try! PropertyListDecoder().decode([Temple].self, from: data)
            classifyTemplesByCategory()
        } else {
            downloadJSONData()
        }
    }
    
    // MARK: - IBActions
    @IBAction func touchUpSearchButton(_ sender: UIButton) {
        loadSearchResult()
    }
    
    @IBAction func touchUpCategoryButton(_ sender: UIButton) {
        switch sender.restorationIdentifier {
        case "parkingButton":
            SearchResultViewController.temples = availableParkingTemples
        case "petButton":
            SearchResultViewController.temples = availablePetTemples
        case "heritageButton":
            SearchResultViewController.temples = isHeritageTemples
        default:
            break
        }
        CommonNavi.pushVC(sbName: "Main", vcName: "SearchResultVC")
    }
    
    // MARK: - Privates
    private func loadSearchResult() {
        guard let searchText = searchTextField.text, searchText.count != 0 else {
            showAlert(message: "검색어를 입력해주세요.")
            return
        }
        
        searchResultTemples.removeAll()
        allTemples.forEach { temple in
            if temple.title.contains(searchText) {
                searchResultTemples.append(temple)
            } else if let addr1 = temple.addr1, addr1.contains(searchText) {
                searchResultTemples.append(temple)
            }
        }
        
        if !searchResultTemples.isEmpty {
            SearchResultViewController.temples = searchResultTemples
            CommonNavi.pushVC(sbName: "Main", vcName: "SearchResultVC")
        } else {
            showAlert(message: "검색결과가 없습니다.")
        }
    }
    
    private func downloadJSONData() {
        storage.reference(forURL: storagePath).downloadURL { url, error in
            let data = NSData(contentsOf: url!)! as Data
            do {
                self.allTemples = try JSONDecoder().decode([Temple].self, from: data)
                self.userDefaults.setValue(try? PropertyListEncoder().encode(self.allTemples), forKey: "Temples")
                self.classifyTemplesByCategory()
            } catch {
                print("decodeError: \(error)")
                self.showAlert(message: "오류가 발생했습니다. 다시 시도해주세요.")
            }
        }
    }
    
    private func classifyTemplesByCategory() {
        availableParkingTemples = allTemples.filter { temple in
            temple.parking == 1
        }
        availablePetTemples = allTemples.filter { temple in
            temple.pet == 1
        }
        isHeritageTemples = allTemples.filter { temple in
            temple.heritage == 1
        }
        CustomLoading.hide()
        print("\(allTemples.count)개 로딩 및 분류 완료")
    }
    
    private func showAlert(message: String) {
        let action: UIAlertAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        let alert: UIAlertController = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
}

extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == searchTextField {
            loadSearchResult()
        }
        return true
    }
}
