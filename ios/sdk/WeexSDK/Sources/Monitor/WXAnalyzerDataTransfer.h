
#import <Foundation/Foundation.h>
#import "WXSDKInstance.h"


@interface WXAnalyzerDataTransfer :NSObject

+ (void) transData:(NSString *)instanceId data:(NSDictionary *)data;

//+ (void) transMeasureValueWithInstanceId:(NSString*)instansId data:(NSDictionary *)data;
//
//+ (void) transDimenValueWithInstanceId:(NSString*)instansId data:(NSDictionary *)data;

+ (void) transErrorInfo:(WXJSExceptionInfo *)errorInfo;

+ (BOOL) needTransfer;

@end
