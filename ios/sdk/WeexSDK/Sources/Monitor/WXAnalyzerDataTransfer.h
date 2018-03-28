
#import <Foundation/Foundation.h>
#import "WXSDKInstance.h"

@interface WXAnalyzerDataTransfer :NSObject

+ (void) transMeasureValue:(NSString*)instansId withUrl:(NSString *)url withKey:(NSString *)key withValue:(id)value;

+ (void) transDimenValue:(NSString*)instansId withUrl:(NSString *)url withKey:(NSString *)key withValue:(id)value;

+ (void) transErrorInfo:(WXJSExceptionInfo *)errorInfo;

@end
