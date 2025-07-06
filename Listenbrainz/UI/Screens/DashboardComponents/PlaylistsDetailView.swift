//
//  PlaylistsDetailView.swift
//  Listenbrainz
//
//  Created by Gaurav Bhardwaj on 24/08/24.
//

import SwiftUI


struct PlaylistDetailsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    var playlistId: String
    var playlistName: String
    @State private var uiState: UiState<PlaylistDetails> = .loading
    @State private var selectedTrack: PlaylistTrack?
    @State private var showPinTrackView = false
    @State private var showWriteReview = false
    @State private var showingRecommendToUsersPersonallyView = false
    @Environment(\.colorScheme) var colorScheme
    //@Environment(\.dismiss) var dismiss

    @AppStorage(Strings.AppStorageKeys.userToken) private var userToken: String = ""
    @AppStorage(Strings.AppStorageKeys.userName) private var userName: String = ""

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.backgroundColor : Color.white).ignoresSafeArea()
            
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    switch uiState {
                    case .loading:
                        ProgressView("Loading playlist details...")
                            .padding()
                    case .failure(let error):
                        Text("Error loading playlist details :(")
                            .padding()
                    case .success(let details) :
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 5){
                                Text(playlistName)
                                    .font(.largeTitle)
                                    
                                Text(
                                    "Public Playlist by \(viewModel.userName)"
                                )
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.lightPink)
                            }
                                
                            ForEach(details.track, id: \.id) { track in
                                ListenCardView(
                                    item: track,
                                    onPinTrack: { track in
                                        selectedTrack = track
                                        showPinTrackView = true
                                    },
                                    onRecommendPersonally: { track in
                                        selectedTrack = track
                                        showingRecommendToUsersPersonallyView = true
                                    },
                                    onWriteReview: { track in
                                        selectedTrack = track
                                        showWriteReview = true
                                    }
                                )
                                .frame(
                                    width:  UIScreen.main.bounds.width * 0.9,
                                    alignment: .leading
                                )
                            }
                        }
                }
            }
        }
        .ignoresSafeArea(edges: .horizontal)
        .onAppear {
            fetchPlaylistDetails()
        }
        .centeredModal(isPresented: $showPinTrackView) {
            if let track = selectedTrack {
                PinTrackView(
                    isPresented: $showPinTrackView,
                    item: track,
                    userToken: userToken,
                    dismissAction: {
                        showPinTrackView = false
                    }
                )
                .environmentObject(viewModel)
            }
        }
        .centeredModal(isPresented: $showWriteReview) {
            if let track = selectedTrack {
                WriteAReviewView(
                    isPresented: $showWriteReview,
                    item: track,
                    userToken: userToken,
                    userName: userName
                ) {
                    showWriteReview = false
                }
                .environmentObject(viewModel)
            }
        }
        .centeredModal(isPresented: $showingRecommendToUsersPersonallyView) {
            if let track = selectedTrack {
                RecommendToUsersPersonallyView(
                    item: track,
                    userName: userName,
                    userToken: userToken,
                    dismissAction: {
                        showingRecommendToUsersPersonallyView = false
                    }
                )
                .environmentObject(viewModel)
            }
        }
    }

    private func fetchPlaylistDetails() {
        Task {
            await asyncToStream {
                try await viewModel
                    .getCreatedForYouPlaylist(playlistId: playlistId)
            }.collect { uiState in
                self.uiState = uiState
            }
        }
    }
}

