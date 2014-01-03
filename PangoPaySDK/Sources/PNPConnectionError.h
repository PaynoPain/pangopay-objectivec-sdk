//
//  PNPConnectionError.h
//  PaynoPain
//
//  Created by Christian Bongardt on 21/11/13.
//  Copyright (c) 2013 PaynoPain. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface PNPError: NSError

@end


@interface PNPConnectionError : PNPError

@end



@interface PNPCertificateError : PNPConnectionError

@end


@interface PNPDeviceOfflineError : PNPConnectionError

@end

@interface PNPBadUrlError : PNPConnectionError

@end

@interface PNPBadRequest : PNPConnectionError

@end

@interface PNPMissingParametersError : PNPBadRequest

@end

@interface PNPServerError : PNPConnectionError

@end

@interface PNPTimedOutError : PNPConnectionError

@end

@interface PNPUnuthorizedAccessError : PNPConnectionError

@end

@interface PNPUnknownError : PNPConnectionError

@end


@interface PNPNotAJsonError : PNPConnectionError

@end

@interface PNPMalformedJsonError : PNPConnectionError

@end






