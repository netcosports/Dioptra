//
// Created by Thomas Christensen on 24/08/16.
// Copyright (c) 2016 Nordija A/S. All rights reserved.
//

import Foundation

class MediaPlaylist {
    var masterPlaylist: MasterPlaylist?

    var programId: Int = 0
    var bandwidth: Double = 0
    var width: Int = 0
    var height: Int = 0
    var path: String?
    var version: Int?
    var targetDuration: Int?
    var mediaSequence: Int?
    var segments = [MediaSegment]()

    init() {

    }

    func addSegment(_ segment: MediaSegment) {
        segments.append(segment)
    }

    func getSegment(_ index: Int) -> MediaSegment? {
        if index >= segments.count {
            return nil
        }
        return segments[index]
    }

    func getSegmentCount() -> Int {
        return segments.count
    }

    func duration() -> Float {
        var dur: Float = 0.0
        for item in segments {
            dur += item.duration!
        }
        return dur
    }

    func getMaster() -> MasterPlaylist? {
        return self.masterPlaylist
    }
}
