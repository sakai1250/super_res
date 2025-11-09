import SwiftUI
import PhotosUI

// 元Flutter: lib/screens/home_screen.dart
// - BottomNavigationBar -> TabView
// - メモタブ: MemoListView (検索/一覧/ギャラリー・カメラ追加/FAB)
// - フォルダタブ: FolderListView (一覧/右下FABでフォルダ追加)

struct Memo: Identifiable, Hashable {
    let id: UUID
    var title: String
    var text: String?
    var image: UIImage?
    var folderId: UUID?
}

struct FolderItem: Identifiable, Hashable {
    let id: UUID
    var name: String
}

struct HomeView: View {
    @State private var selectedTab = 0
    @State private var memos: [Memo] = []
    @State private var folders: [FolderItem] = []

    @State private var showAddFolderSheet = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                TabView(selection: $selectedTab) {
                    MemoListView(memos: $memos, folders: $folders)
                        .tabItem {
                            Image(systemName: "note.text")
                            Text("メモ")
                        }
                        .tag(0)

                    FolderListView(folders: $folders, memos: $memos)
                        .tabItem {
                            Image(systemName: "folder")
                            Text("フォルダ")
                        }
                        .tag(1)
                }

                // 元Flutter: FloatingActionButton on folder tab
                if selectedTab == 1 {
                    Button(action: { showAddFolderSheet = true }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                            .padding(16)
                            .background(.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 2)
                    }
                    .padding(20)
                    .sheet(isPresented: $showAddFolderSheet) {
                        NavigationStack {
                            VStack(spacing: 16) {
                                Text("Add Folder").font(.headline)
                                TextField("Folder Name", text: $newFolderName)
                                    .textFieldStyle(.roundedBorder)
                                HStack {
                                    Button("キャンセル") { newFolderName = ""; showAddFolderSheet = false }
                                    Spacer()
                                    Button("OK") {
                                        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !name.isEmpty {
                                            folders.append(FolderItem(id: UUID(), name: name))
                                        }
                                        newFolderName = ""; showAddFolderSheet = false
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding()
                            .navigationTitle("新規フォルダ")
                            .navigationBarTitleDisplayMode(.inline)
                        }
                        .presentationDetents([.fraction(0.35)])
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "メモ一覧" : "フォルダ")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Memo List (元: lib/screens/memo_list_screen.dart)
struct MemoListView: View {
    @Binding var memos: [Memo]
    @Binding var folders: [FolderItem]

    @State private var searchText = ""
    @State private var galleryItem: PhotosPickerItem?
    @State private var running = false
    @State private var errorMessage: String = ""

    var filteredMemos: [Memo] {
        if searchText.isEmpty { return memos }
        return memos.filter { $0.title.localizedCaseInsensitiveContains(searchText) || ($0.text ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 検索欄
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search text", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(12)
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 12)
            .padding(.top, 8)

            List {
                ForEach(filteredMemos) { memo in
                    NavigationLink(value: memo.id) {
                        HStack(spacing: 12) {
                            if let image = memo.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                Image(systemName: "photo")
                                    .frame(width: 64, height: 64)
                                    .background(Color(uiColor: .systemGray5))
                                    .cornerRadius(8)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(memo.title).font(.headline)
                                Text(memo.text ?? "（メモなし）")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(Color(uiColor: .tertiaryLabel))
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .listStyle(.plain)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.bottom, 6)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    PhotosPicker(
                        selection: $galleryItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Image(systemName: "photo.on.rectangle")
                    }
                    // NOTE: カメラは PhotosPicker 非対応。見た目だけ分け、同一ギャラリーを使う。
                    PhotosPicker(
                        selection: $galleryItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Image(systemName: "camera")
                    }
                }
            }
        }
        .onChange(of: galleryItem) { _, newValue in
            guard let item = newValue else { return }
            running = true
            Task {
                defer { running = false }
                do {
                    if let data = try await item.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                        memos.insert(Memo(id: UUID(), title: "Gallery Memo", text: nil, image: ui, folderId: nil), at: 0)
                        errorMessage = ""
                    }
                } catch {
                    errorMessage = "ギャラリーから追加に失敗しました"
                }
            }
        }
        .navigationDestination(for: UUID.self) { memoId in
            if let _ = memos.first(where: { $0.id == memoId }) {
                PhotoDetailView(memo: binding(for: memoId))
            } else {
                Text("Not found")
            }
        }
    }

    // struct スコープに配置（ViewBuilder 内に置かない）
    private func binding(for id: UUID) -> Binding<Memo> {
        Binding(get: {
            memos.first(where: { $0.id == id }) ?? Memo(id: id, title: "", text: nil, image: nil, folderId: nil)
        }, set: { newValue in
            if let idx = memos.firstIndex(where: { $0.id == id }) {
                memos[idx] = newValue
            }
        })
    }
}

// MARK: - Folder List (元: lib/screens/folder_list_screen.dart)
struct FolderListView: View {
    @Binding var folders: [FolderItem]
    @Binding var memos: [Memo]

    var body: some View {
        List {
            ForEach(folders) { folder in
                NavigationLink(destination: PhotoListView(folder: folder, memos: $memos)) {
                    Text(folder.name)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Photo Grid (元: lib/screens/photo_list_screen.dart)
struct PhotoListView: View {
    let folder: FolderItem
    @Binding var memos: [Memo]

    @State private var galleryItem: PhotosPickerItem?
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var folderMemos: [Memo] {
        memos.filter { $0.folderId == folder.id }
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(folderMemos) { memo in
                    NavigationLink(destination: PhotoDetailView(memo: binding(for: memo.id))) {
                        ZStack {
                            if let ui = memo.image {
                                Image(uiImage: ui)
                                    .resizable().scaledToFill()
                                    .frame(height: 110)
                                    .clipped()
                                    .cornerRadius(10)
                            } else {
                                Rectangle().fill(Color(uiColor: .systemGray5)).frame(height: 110)
                            }
                        }
                    }
                }
            }.padding(8)
        }
        .navigationTitle("フォルダ: \(folder.name)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                PhotosPicker(
                    selection: $galleryItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "photo.on.rectangle")
                }
            }
        }
        .onChange(of: galleryItem) { _, newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                    memos.insert(Memo(id: UUID(), title: "Gallery Memo", text: nil, image: ui, folderId: folder.id), at: 0)
                }
            }
        }
    }

    private func binding(for id: UUID) -> Binding<Memo> {
        Binding(get: {
            memos.first(where: { $0.id == id }) ?? Memo(id: id, title: "", text: nil, image: nil, folderId: folder.id)
        }, set: { newValue in
            if let idx = memos.firstIndex(where: { $0.id == id }) { memos[idx] = newValue }
        })
    }
}

// MARK: - Photo Detail (元: lib/screens/photo_detail_screen.dart)
struct PhotoDetailView: View {
    @Binding var memo: Memo
    @State private var text: String = ""
    @State private var showSRS = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let ui = memo.image {
                ScrollView([.vertical, .horizontal]) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: 300)
            }

            TextField("メモを編集", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)

            Button("超解像") { showSRS = true }
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("写真詳細")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    memo.text = text.isEmpty ? nil : text
                } label: { Image(systemName: "square.and.arrow.down") }
            }
        }
        .onAppear { text = memo.text ?? "未入力" }
        .sheet(isPresented: $showSRS) {
            SuperResolutionView(inputImage: memo.image) { out in
                if let out { memo.image = out }
            }
        }
    }
}
