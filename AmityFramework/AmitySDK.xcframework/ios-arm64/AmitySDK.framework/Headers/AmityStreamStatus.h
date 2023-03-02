//
//  AmityStreamStatus.h
//  AmitySDK
//
//  Created by Nutchaphon Rewik on 2/2/2564 BE.
//  Copyright © 2564 amity. All rights reserved.
//

#ifndef AmityStreamStatus_h
#define AmityStreamStatus_h

/// Status for LiveStream
typedef NS_ENUM(NSUInteger, AmityStreamStatus) {
    /// Stream has not yet started
    AmityStreamStatusIdle,
    
    /// Stream is currently live
    AmityStreamStatusLive,
    
    /// Stream is now ended
    AmityStreamStatusEnded,
    
    /// Stream is complete and videos of the stream is now recorded.
    AmityStreamStatusRecorded
};

#endif /* AmityStreamStatus_h */
