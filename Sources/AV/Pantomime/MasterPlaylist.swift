//
//  MasterPlaylist.swift
//  Pantomime
//
//  Created by Thomas Christensen on 25/08/16.
//  Copyright © 2016 Sebastian Kreutzberger. All rights reserved.
//

import Foundation

class MasterPlaylist {
    var playlists = [MediaPlaylist]()
    var path: String?

    init() {}

    func addPlaylist(_ playlist: MediaPlaylist) {
        playlists.append(playlist)
    }

    func getPlaylist(_ index: Int) -> MediaPlaylist? {
        if index >= playlists.count {
            return nil
        }
        return playlists[index]
    }

    func getPlaylistCount() -> Int {
        return playlists.count
    }
}
