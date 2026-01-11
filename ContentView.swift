import SwiftUI

struct ContentView: View {
    
    // Variable & arrary initialization
    @State var storeArray: [String] = ["", "", "", "", ""]
    @State private var store1: String = ""
    @State private var store2: String = ""
    @State private var store3: String = ""
    @State private var store4: String = ""
    @State private var store5: String = ""
    @State private var showStoreAlert = false
    @State private var showItemSheet = false
    @State private var items: [ListItem] = []
    @State private var showButton: Bool = false
    @State private var selectedGroc = Set<UUID>()
    @State private var selectedStoreFilter: String? = nil
    @State private var animate = false
    @State private var showOnlySelected = false
    @State private var showShoppingCompleteAlert = false
    let bundleID = Bundle.main.bundleIdentifier
    
    // Displays current store filter
    var storePreview: String {
        selectedStoreFilter ?? "All Stores"
    }
    
    // JSON encoding for complicated save items
    private let itemsKey = "savedListItems"
    func saveItems(){
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: itemsKey)
        } catch {
            print("Failed to save items", error)
        }
    }
    private let selectedKey = "selectedGrocIDs"
    func saveSelection(){
        do {
            let data = try JSONEncoder().encode(Array(selectedGroc))
            UserDefaults.standard.set(data, forKey: selectedKey)
        } catch {
            print("Failed to save items:", error)
        }
    }
    
    // JSON decoding for complicated save items
    func loadItems(){
        guard let data = UserDefaults.standard.data(forKey: itemsKey) else { return }
        do {
            items = try JSONDecoder().decode([ListItem].self, from: data)
        } catch {
            print("Failed to save items:", error)
        }
    }
    func loadSelection(){
        do{
            let data = try JSONEncoder().encode(Array(selectedGroc))
            UserDefaults.standard.set(data, forKey: selectedKey)
        } catch {
            print("Failed to save items:", error)
        }
    }
    
    // Filtering the main grocery list using the store filter, selected items filter for shopping, and sorting items by ABC
    var visibleItems: [ListItem]{
        items
            .filter { item in
                guard let store = selectedStoreFilter else{
                    return true
                }
                return item.selectedStoreValue.contains(store)
            }
        
            .filter{ item in 
                guard showOnlySelected else {
                    return true
                }
                guard !selectedGroc.isEmpty else {return true}
                return selectedGroc.contains(item.id)
            }
            .sorted{
                $0.gItemValue.localizedCaseInsensitiveCompare($1.gItemValue) == .orderedAscending
            }
    }
    
    // Separated out shopping button for less burdonsome compiling
    @ViewBuilder
    private var shoppingToggleSelection: some View {
        if !selectedGroc.isEmpty{
            Section{
                Button{
                    showOnlySelected.toggle()
                } label: {
                    Text(showOnlySelected ? "Go Back" : "Begin Shopping")
                        .frame(maxWidth: .infinity)
                        .bold()
                        .scaleEffect(animate ? 1.2 : 1.0)
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 6)
                        .animation(.easeOut(duration: 0.35), value: animate)
                }
                .onAppear {
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.35)) {
                            animate = true
                        }
                    }
                }
            }
        }
    }
    
    // Main view holding toolbar, grocery list, store input using alert, etc.
    var body: some View {
        NavigationStack{
            VStack{
                 GroupBox(){
                     Text(storePreview)
                         .id(storePreview)
                         .frame(maxWidth: .infinity, alignment: .leading)
                         .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                         ))
                         .bold()
                         .animation(.easeInOut(duration: 0.12), value: storePreview)
                 }
                 .padding(8)
                List(selection: $selectedGroc){
                    shoppingToggleSelection
                    ForEach(visibleItems){ item in 
                        GroceryRow(item: item)
                            .tag(item.id)
                    }
                    .onDelete(perform: deleteItem)
                    if !showOnlySelected{
                        Button("+ Add new item"){
                            showItemSheet = true
                        }
                    }
                }
                .sheet(isPresented: $showItemSheet){
                    SheetView(storeArray: storeArray, items: $items, selectedStoreFilter: $selectedStoreFilter, showOnlySelected: $showOnlySelected, selectedGroc: $selectedGroc)
                        .presentationDetents([.medium, .large])
                }
                .environment(\.editMode, .constant(.active))  
            }
            .alert("Shopping complete", isPresented: $showShoppingCompleteAlert){
                Button("OK", role: .cancel){}
            }
            .onAppear{
                storeArray = UserDefaults.standard.stringArray(forKey: "savedStoreArray") ?? ["", "", "", "", ""]
                store1 = storeArray[0]
                store2 = storeArray[1]
                store3 = storeArray[2]
                store4 = storeArray[3]
                store5 = storeArray[4]
                
                loadItems()
                loadSelection()
            }
            .onChange(of: items){ _, _ in saveItems()}
            .onChange(of: selectedGroc){ _, newValue in saveSelection()
                if newValue.isEmpty {
                    animate = false
                }
                if newValue.isEmpty && showOnlySelected{
                    showOnlySelected = false
                    showShoppingCompleteAlert = true
                }
            }
            
            // Toolbar holding edit and store filter buttons
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading){
                    Button("edit", systemImage: "pencil"){
                        showStoreAlert = true
                    }
                    .alert("Edit store name", isPresented: $showStoreAlert){
                        TextField("Edit Store 1", text: $store1)
                        TextField("Edit Store 2", text: $store2)
                        TextField("Edit Store 3", text: $store3)
                        TextField("Edit Store 4", text: $store4)
                        TextField("Edit Store 5", text: $store5)
                        Button("Save"){
                            storeArray[0] = store1
                            storeArray[1] = store2
                            storeArray[2] = store3
                            storeArray[3] = store4
                            storeArray[4] = store5
                            UserDefaults.standard.set(storeArray, forKey: "savedStoreArray")
                        } 
                    }
                    Button("All"){
                        withAnimation{
                            selectedStoreFilter = nil
                        }
                    }
                        .foregroundColor(.red)
                        .buttonStyle(PrimaryButtonStyle())
                    ForEach(storeArray.indices, id: \.self){ index in
                        let store = storeArray[index]
                        
                        if !store.isEmpty{
                            Button(String(store.prefix(3))){
                                withAnimation{
                                    selectedStoreFilter = selectedStoreFilter == store ? nil : store
                                }
                            }
                            .foregroundColor(storeColor(index))
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    }
                }
        }
            
    }

                             func storeColor(_ index: Int) -> Color {
                                switch index {
                                case 0: return .orange
                                case 1: return .yellow
                                case 2: return .green
                                case 3: return .blue               
                                case 4: return .purple
                                default: return .gray
                                }
                            }
                        
    func deleteItem(at offsets: IndexSet){
        items.remove(atOffsets: offsets)
    }
}

// Button style for store filtering buttons
struct PrimaryButtonStyle: ButtonStyle{
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .bold()
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white)
                    .shadow(color: .gray, radius: 2, x:0, y: 2)
            )
    }
}

// Safeguard applied to all the arrays to ensure the indices are within valid ranges
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// Display of the grocery list items
    struct GroceryRow: View{
        let item: ListItem
        
        var body: some View {
            HStack {
                Text(item.gItemValue)
                    .bold()
                Text("(" + item.selectedFoodTypeValue + ")")
                Text("\(item.selectedStoreValue.joined(separator: ", "))")
                    .foregroundColor(.secondary)
            }
        }
    }

// View for the add new item page
struct SheetView: View{
    @Environment(\.dismiss) var dismiss
    @State private var gItem: String = ""
    @State private var selectedFoodType = "1"
    @State private var selectedStore = Set<String>()
    let foodType = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    let storeArray: [String]
    @Binding var items: [ListItem]
    @Binding var selectedStoreFilter: String?
    @Binding var showOnlySelected: Bool
    @Binding var selectedGroc: Set<UUID>
    
    var body: some View{
        NavigationView{
            VStack(alignment: .leading){
                Text("1) Input grocery item")
                TextField("Input grocery item", text: $gItem)
                Text("2) Scroll and select food type")
                Picker("Select a food type", selection: $selectedFoodType) {
                    ForEach(foodType, id: \.self) {Text($0)}
                }
                .pickerStyle(.wheel)
                .frame(height: 80)
                Text("3) Select store(s) where the product is available")
                List(storeArray, id: \.self, selection: $selectedStore){
                    store in Text(store)
                }
                .environment(\.editMode, .constant(.active))
                .frame(height: 150)
                Button("submit"){
                    let newItem = ListItem(
                        gItemValue: gItem,
                        selectedFoodTypeValue: selectedFoodType, selectedStoreValue: selectedStore
                    )
                    items.append(newItem)
                    selectedStoreFilter = nil
                    showOnlySelected = false
                    dismiss()
                }
                .padding(.top)
            }
            .padding()
        }
    }
}

// Variables & arrays initialized for the main grocery items list allowing new items to be created, oranized, and saved/retrieved using JSON
struct ListItem: Identifiable, Hashable, Codable{
    let id: UUID
    var gItemValue: String
    var selectedFoodTypeValue: String
    var selectedStoreValue: Set<String>
    
    init(
        id: UUID = UUID(),
        gItemValue: String,
        selectedFoodTypeValue: String,
        selectedStoreValue: Set<String>
        )
    {
        self.id = id
        self.gItemValue = gItemValue
        self.selectedFoodTypeValue = selectedFoodTypeValue
        self.selectedStoreValue = selectedStoreValue
    }
}
