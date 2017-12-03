//
//  FilterOperationManager.swift
//  FilterOperation
//
//  Created by Ömer Faruk Öztürk on 2.12.2017.
//  Copyright © 2017 omerfarukozturk. All rights reserved.
//

import Foundation

// A protocol that items should conform to be filterable.
protocol Searchable {
    func getSearchText() -> String
}

class FilterOperationManager: NSObject {
    
    private var allItems : Array<Searchable>
    
    init(allItems: Array<Searchable>) {
        
        let searchableList = allItems
        
        self.allItems = searchableList
    }
    
    private var filterQueue = OperationQueue()
    
    private var filterOperation = BlockOperation()
    
    
    //MARK: - Filtered items data
    
    private var filteredItemsLookup = Dictionary<String,Array<Searchable>>()
    
    private var filteredItems = Array<Searchable>()
    
    var searchKeyword: String?
    
    //MARK: - Public Properties & Functions
    var searchCompleted: ((Array<Searchable>) -> Void)?
    
    // Filter via search keyword.
    func filter(_ searchKeyword: String) {
        
        let start = NSDate().timeIntervalSince1970
        
        self.searchKeyword = searchKeyword
        
        let searchText = searchKeyword.lowercased()
        
        // Cancel currently running search operation.
        self.filterOperation.cancel()
        
        if searchText != "" {
            
            var cachedItemsFound = false
            
            // If related search result cached before, use it.
            if let previousFilteredList = self.filteredItemsLookup[searchText] {
                
                cachedItemsFound = true
                self.filteredItems = previousFilteredList
                
                print("Previously cached list is used: keyword:\(searchText)")
            }
            
            // If keyword cached before, use it.
            if cachedItemsFound {
                self.searchCompleted?(self.filteredItems)
                return
            } else {
                
                var currentItemList = self.allItems
                
                // Find closest filtered account list.
                for (keyword,list) in self.filteredItemsLookup {
                    if searchText.lowercased().contains(keyword.lowercased()) && list.count < currentItemList.count {
                        currentItemList = list
                        // print("Better cache keyword used : \(keyword)")
                    }
                }
                
                self.filterOperation = BlockOperation()
                self.filterOperation.addExecutionBlock({
                    
                    let filteredArray = self.filterSearchable(currentItemList, searchString: searchText)
                    
                    // Cache filtered list.
                    self.filteredItemsLookup[searchText] = filteredArray
                    
                    self.filteredItems = filteredArray
                    
                    
                    let duration = NSDate().timeIntervalSince1970 - start
                    print("Filter completed. Duration: \(duration)")
                })
                
                self.filterOperation.completionBlock = {
                    
                    // print("FilterOperation completed.  isCancelled: \(self.filterOperation.isCancelled)")
                    
                    if !self.filterOperation.isCancelled {
                        OperationQueue.main.addOperation({
                            self.searchCompleted?(self.filteredItems)
                        })
                    }
                }
                
                // Add to operation queue.
                filterQueue.addOperation(self.filterOperation)
            }
            
        } else {
            self.filteredItems = self.allItems
            self.searchCompleted?(self.filteredItems)
        }
    }
    
    
    // Filter list of data that is a type of Searchable.
    func filterSearchable<T>(_ array: Array<T>, searchString: String) -> Array<T> {
        
        var returnArray = Array<T>()
        
        // Check if array is a list of Searchable item
        if let item = array.first , item is Searchable {
            
            let searchKeyword = searchString.lowercased()
            
            returnArray = array.filter { (x) -> Bool in
                let searchableString = (x as! Searchable).getSearchText()
                return searchableString.localizedCaseInsensitiveContains(searchKeyword)
            }
        }
        
        return returnArray
    }
}
