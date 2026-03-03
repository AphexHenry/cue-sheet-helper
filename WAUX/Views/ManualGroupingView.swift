//
//  ManualGroupingView.swift
//  Vaux Cue Sheet
//
//  Created by AI Assistant on 03/10/2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Catalog Item

struct CatalogItem: Identifiable, Hashable {
    let id: String
    let title: String
}

// MARK: - Manual Grouping View

struct ManualGroupingView: View {
    let parsingResult: CueParsingResult
    let onApply: (CueParsingResult) -> Void
    let onCancel: () -> Void
    
    @State private var manualGrouping: ManualGrouping
    @State private var draggedItem: String?
    @State private var targetGroup: String?
    @State private var selectedItems: Set<String> = []
    @State private var groupColors: [String: Color] = [:]
    @State private var showingGroupNameDialog = false
    @State private var suggestedGroupName = ""
    @State private var catalogSortOrder: [KeyPathComparator<CatalogItem>] = [KeyPathComparator(\CatalogItem.id)]
    @State private var catalogFilterText: String = ""
    
    // Get unique catalog IDs from layer 1 (raw events)
    private var uniqueCatalogIDs: [String] {
        let allCatalogIDs = parsingResult.layer1.map { $0.catalogID }
        let catalogIDSet = Set(allCatalogIDs)
        
        let filteredCatalogIDs = catalogIDSet.filter { catalogID in
            catalogID != "FADE_IN" && catalogID != "FADE_OUT" && catalogID != "CROSS_FADE" &&
            catalogID != "FADE IN" && catalogID != "FADE OUT" && catalogID != "CROSS FADE"
        }
        
        return Array(filteredCatalogIDs).sorted()
    }
    
    private var sortedCatalogItems: [CatalogItem] {
        var items = uniqueCatalogIDs.map { id in
            CatalogItem(id: id, title: titlesByCatalogID[id] ?? "")
        }
        if !catalogFilterText.isEmpty {
            let search = catalogFilterText.lowercased()
            items = items.filter {
                $0.id.lowercased().contains(search) || $0.title.lowercased().contains(search)
            }
        }
        return items.sorted(using: catalogSortOrder)
    }
    
    private var titlesByCatalogID: [String: String] {
        var result: [String: String] = [:]
        for event in parsingResult.layer1 {
            if result[event.catalogID] == nil && !event.title.isEmpty {
                result[event.catalogID] = event.title
            }
        }
        return result
    }
    
    private func displayName(for catalogID: String) -> String {
        if let title = titlesByCatalogID[catalogID], !title.isEmpty {
            return "\(catalogID)  —  \(title)"
        }
        return catalogID
    }
    
    // Get current groups (either manual or automatic)
    private var currentGroups: [String: [String]] {
        var groups: [String: [String]] = [:]
        
        for catalogID in uniqueCatalogIDs {
            let groupID: String
            if manualGrouping.hasManualAssociation(for: catalogID) {
                groupID = manualGrouping.getGroupID(for: catalogID)!
            } else {
                groupID = catalogID  // Use catalogID as default group
            }
            
            if groups[groupID] == nil {
                groups[groupID] = []
            }
            groups[groupID]!.append(catalogID)
        }
        
        return groups
    }
    
    init(parsingResult: CueParsingResult, onApply: @escaping (CueParsingResult) -> Void, onCancel: @escaping () -> Void) {
        self.parsingResult = parsingResult
        self.onApply = onApply
        self.onCancel = onCancel
        self._manualGrouping = State(initialValue: parsingResult.manualGrouping)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            HStack(spacing: 0) {
                // Left panel - Available items
                leftPanel
                
                Divider()
                
                // Right panel - Groups
                rightPanel
            }
            
            Divider()
            
            // Bottom controls
            bottomControlsView
        }
        .frame(width: 1100, height: 700)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text("Manual File Grouping")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("Drag items between groups to create custom associations")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Left Panel
    
    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Available Files")
                    .font(.headline)
                
                Spacer()
                
                if !selectedItems.isEmpty {
                    Text("\(selectedItems.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Filter by catalog ID or title...", text: $catalogFilterText)
                    .textFieldStyle(.plain)
                
                if !catalogFilterText.isEmpty {
                    Button(action: { catalogFilterText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            .padding(.horizontal)
            .padding(.vertical, 6)
            
            Table(sortedCatalogItems, selection: $selectedItems, sortOrder: $catalogSortOrder) {
                TableColumn("Catalog ID", value: \.id) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(getColorForCatalogID(item.id))
                            .frame(width: 10, height: 10)
                        
                        Text(item.id)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                    }
                }
                .width(min: 120, ideal: 180)
                
                TableColumn("Title", value: \.title) { item in
                    Text(item.title)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .width(min: 120, ideal: 180)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .frame(height: 400)
            .contextMenu {
                if !selectedItems.isEmpty {
                    Button("Group") {
                        groupSelectedItems()
                    }
                    
                    Divider()
                    
                    Button("Remove from Groups") {
                        removeSelectedItemsFromGroups()
                    }
                }
            }
        }
        .frame(width: 500)
        .onAppear {
            generateGroupColors()
        }
        .onChange(of: currentGroups) { _ in
            generateGroupColors()
        }
        .alert("Enter Group Name", isPresented: $showingGroupNameDialog) {
            TextField("Group Name", text: $suggestedGroupName)
            Button("Create Group") {
                moveSelectedItemsToGroup(suggestedGroupName)
            }
            Button("Cancel", role: .cancel) {
                // Do nothing, just cancel
            }
        } message: {
            Text("Enter a name for the new group containing \(selectedItems.count) item(s).")
        }
    }
    
    // MARK: - Right Panel
    
    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Groups")
                .font(.headline)
                .padding()
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(currentGroups.keys.sorted()), id: \.self) { groupID in
                        GroupView(
                            groupID: groupID,
                            items: currentGroups[groupID] ?? [],
                            titlesByCatalogID: titlesByCatalogID,
                            isTarget: targetGroup == groupID,
                            groupColor: groupColors[groupID] ?? .gray,
                            onDrop: { catalogID in
                                moveItemToGroup(catalogID: catalogID, targetGroup: groupID)
                            },
                            onRemove: { catalogID in
                                removeFromGroup(catalogID: catalogID)
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .frame(width: 500)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControlsView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(manualGrouping.associations.count) manual associations")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !selectedItems.isEmpty {
                    Text("• \(selectedItems.count) items selected")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                if !selectedItems.isEmpty {
                    Button("Clear Selection") {
                        selectedItems.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
            
            HStack {
                Spacer()
                
                Button("Reset All") {
                    manualGrouping = ManualGrouping()
                    selectedItems.removeAll()
                }
                .buttonStyle(.bordered)
                
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)
                
                Button("Apply Changes") {
                    applyChanges()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Helper Functions
    
    private func moveItemToGroup(catalogID: String, targetGroup: String) {
        manualGrouping.associate(catalogID: catalogID, with: targetGroup)
    }
    
    private func removeFromGroup(catalogID: String) {
        manualGrouping.removeAssociation(for: catalogID)
    }
    
    private func moveSelectedItemsToGroup(_ targetGroup: String) {
        for catalogID in selectedItems {
            manualGrouping.associate(catalogID: catalogID, with: targetGroup)
        }
        selectedItems.removeAll()
    }
    
    private func groupSelectedItems() {
        // Find common string in selected items
        let commonString = findCommonString(in: Array(selectedItems))
        
        if !commonString.isEmpty {
            // Use the common string as group name
            moveSelectedItemsToGroup(commonString)
        } else {
            // No common string found, ask user for group name
            suggestedGroupName = generateSuggestedGroupName()
            showingGroupNameDialog = true
        }
    }
    
    private func findCommonString(in items: [String]) -> String {
        guard !items.isEmpty else { return "" }
        
        if items.count == 1 {
            return items[0]
        }
        
        let firstItem = items[0]
        var commonPrefix = ""
        
        // Find the longest common prefix
        for i in 0..<firstItem.count {
            let index = firstItem.index(firstItem.startIndex, offsetBy: i)
            let char = firstItem[index]
            
            var allMatch = true
            for item in items.dropFirst() {
                if i >= item.count || item[item.index(item.startIndex, offsetBy: i)] != char {
                    allMatch = false
                    break
                }
            }
            
            if allMatch {
                commonPrefix.append(char)
            } else {
                break
            }
        }
        
        // Only return if the common prefix is meaningful (at least 3 characters)
        return commonPrefix.count >= 3 ? commonPrefix : ""
    }
    
    private func generateSuggestedGroupName() -> String {
        let baseName = "Group"
        var groupName = baseName
        var counter = 1
        
        while currentGroups.keys.contains(groupName) {
            groupName = "\(baseName) \(counter)"
            counter += 1
        }
        
        return groupName
    }
    
    private func createNewGroupForSelectedItems() {
        // Generate a unique group name
        let baseName = "Group"
        var groupName = baseName
        var counter = 1
        
        while currentGroups.keys.contains(groupName) {
            groupName = "\(baseName) \(counter)"
            counter += 1
        }
        
        // Move selected items to the new group
        moveSelectedItemsToGroup(groupName)
    }
    
    private func removeSelectedItemsFromGroups() {
        for catalogID in selectedItems {
            manualGrouping.removeAssociation(for: catalogID)
        }
        selectedItems.removeAll()
    }
    
    private func applyChanges() {
        var updatedResult = parsingResult
        updatedResult.manualGrouping = manualGrouping
        
        // Recalculate layers 2, 3, and 4
        let parsingService = CueFileParsingService()
        let recalculatedResult = parsingService.recalculateWithManualGrouping(updatedResult)
        
        onApply(recalculatedResult)
    }
    
    // Generate distinct colors for groups
    private func generateGroupColors() {
        let predefinedColors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .red, .yellow, .cyan,
            .mint, .indigo, .brown, .teal, .gray
        ]
        
        // Shuffle the colors to get random assignment
        let shuffledColors = predefinedColors.shuffled()
        var colorIndex = 0
        
        for groupID in currentGroups.keys.sorted() {
            if groupColors[groupID] == nil {
                groupColors[groupID] = shuffledColors[colorIndex % shuffledColors.count]
                colorIndex += 1
            }
        }
    }
    
    // Get color for a catalog ID based on its group
    private func getColorForCatalogID(_ catalogID: String) -> Color {
        let groupID = manualGrouping.hasManualAssociation(for: catalogID) 
            ? manualGrouping.getGroupID(for: catalogID)! 
            : catalogID
        return groupColors[groupID] ?? .gray
    }
}

// MARK: - Group View

struct GroupView: View {
    let groupID: String
    let items: [String]
    let titlesByCatalogID: [String: String]
    let isTarget: Bool
    let groupColor: Color
    let onDrop: (String) -> Void
    let onRemove: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Color indicator
                Circle()
                    .fill(groupColor)
                    .frame(width: 16, height: 16)
                
                Text(groupID)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(items.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if items.isEmpty {
                Text("No items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.secondary)
                            
                            Text(item)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                                .frame(minWidth: 100, alignment: .leading)
                            
                            if let title = titlesByCatalogID[item], !title.isEmpty {
                                Text(title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                onRemove(item)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .onDrop(of: [.text], isTargeted: .constant(true)) { providers in
            guard let provider = providers.first else { return false }
            
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (data, error) in
                if let data = data as? Data,
                   let catalogID = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        onDrop(catalogID)
                    }
                }
            }
            
            return true
        }
    }
    
    private var backgroundFill: Color {
        if isTarget {
            return Color.accentColor.opacity(0.1)
        } else {
            return groupColor.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        if isTarget {
            return Color.accentColor
        } else {
            return groupColor.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        if isTarget {
            return 2
        } else {
            return 1
        }
    }
}
