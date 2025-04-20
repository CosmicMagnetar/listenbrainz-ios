//
//  TrackInfoView.swift
//  Listenbrainz
//
//  Created by Gaurav Bhardwaj on 05/09/23.
//


import SwiftUI

struct TrackInfoView<T: TrackMetadataProvider>: View {
    let item: T
    let onPinTrack: (T) -> Void
    let onRecommendPersonally: (T) -> Void
    let onWriteReview: (T) -> Void
    @StateObject private var imageLoader = ImageLoader.shared
    @AppStorage(Strings.AppStorageKeys.userToken) private var userToken: String = ""
    @AppStorage(Strings.AppStorageKeys.userName) private var userName: String = ""
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    @EnvironmentObject var theme: Theme
    
    
    
    private var isCritiqueBrainzReview: Bool {
        return (item as? Event)?.eventType == "critiquebrainz_review"
    }
    
    var body: some View {
        HStack {
            if let coverArtURL = item.coverArtURL {
                AsyncImage(
                    url: coverArtURL,
                    scale: 0.1,
                    transaction: Transaction(animation: nil),
                    content: { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .onAppear {
                                    imageLoader.loadImage(url: coverArtURL) { loadedImage in
                                        if let uiImage = loadedImage {
                                            ImageCache.shared.insertImage(uiImage, for: coverArtURL)
                                        }
                                    }
                                }
                        default:
                            if let cachedImage = ImageCache.shared.image(for: coverArtURL) {
                                Image(uiImage: cachedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                            } else {
                                Image("caa_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                )
                .frame(width: 60, height: 60)
            } else {
                Image("caa_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            }
            
            VStack(alignment: .leading) {
                if isCritiqueBrainzReview {
                    Text(item.entityName ?? "Unknown Entity")
                        .lineLimit(1)
                        .font(.system(size: 14, weight: .bold))
                } else {
                    Text(item.trackName ?? "Unknown Track")
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                        .foregroundStyle(theme.colorScheme.listenText)
                    Text(item.artistName ?? "Unknown Artist")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .foregroundStyle(theme.colorScheme.listenText.opacity(0.7))
                }
            }
            .padding(.leading, 3)
            
            Spacer()
            
            Menu {
                if let originURL = item.originURL {
                    Button("Open in Spotify") {
                        if let url = URL(string: originURL) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if let recordingMbid = item.recordingMbid {
                    Button("Open in MusicBrainz") {
                        if let url = URL(string: "https://musicbrainz.org/recording/\(recordingMbid)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Button("Pin this track") {
                    onPinTrack(item)
                }
                Button("Recommend to my followers") {
                    feedViewModel.recommendToFollowers(userName: userName, item: item, userToken: userToken)
                }
                Button("Personally recommend") {
                    onRecommendPersonally(item)
                }
                Button("Write a review") {
                    onWriteReview(item)
                }
                
            } label: {
                Image(systemName: "ellipsis")
                    .padding(.horizontal, 10)
                    .rotationEffect(.degrees(90))
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
        }
    }
}


#Preview {
    TrackInfoView(
        item: Listen(
            recordingMsid: "",
            trackMetadata: ListensTrackMetadata(
                additionalInfo: ListensAdditionalInfo(originURL: ":"),
                artistName: "Artist name",
                trackName: "Track name",
                mbidMapping: ListensMbidMapping(caaID: nil, caaReleaseMbid: nil, recordingMbid: nil),
                entityName: "Entity name"
            )
        ),
        onPinTrack: { listen in },
        onRecommendPersonally: { listen in },
        onWriteReview: { listen in }
    )
    .environmentObject(FeedViewModel(repository: FeedRepositoryImpl()))
    .environmentObject(DashboardViewModel(repository: DashboardRepositoryImpl()))
    .environmentObject(Theme())
}







