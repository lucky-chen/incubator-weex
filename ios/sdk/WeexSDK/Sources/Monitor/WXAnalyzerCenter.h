
#import <Foundation/Foundation.h>
#import "WXAnalyzerProtocol.h"

@interface WXAnalyzerCenter : NSObject

+(NSMutableArray<WXAnalyzerProtocol> *) getAnalyzerList;

+(void) addWxAnalyzer:(id<WXAnalyzerProtocol>)handler;

+(void) rmWxAnalyzer:(id<WXAnalyzerProtocol>)handler;

@end
