#import <Foundation/Foundation.h>
#import "WXAnalyzerDataTransfer.h"
#import "WXAnalyzerProtocol.h"
#import "WXAppMonitorProtocol.h"
#import "WXSDKManager.h"

@implementation WXAnalyzerDataTransfer


+ (void) transData:(NSString *)instanceId data:(NSDictionary *)data
{
    WXSDKInstance *instance = [WXSDKManager instanceForID:instanceId];
    if (!instance) {
        return;
    }

    if(![self needTransfer])
    {
        return;
    }
    static NSSet *commitDimenKeys;
    static NSSet *commitMeasureKeys;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        // non-standard perf commit names, remove this hopefully.
        commitDimenKeys =[NSSet setWithObjects:
                          BIZTYPE,
                          PAGENAME,
                          WXSDKVERSION,
                          JSLIBVERSION,
                          JSLIBSIZE,
                          WXREQUESTTYPE,
                          WXCONNECTIONTYPE,
                          NETWORKTYPE,
                          CACHETYPE,
                          WXCUSTOMMONITORINFO,
                          nil
                        ];
        commitMeasureKeys =[NSSet setWithObjects:
                            SDKINITTIME,
                            SDKINITINVOKETIME,
                            JSLIBINITTIME,
                            JSTEMPLATESIZE,
                            NETWORKTIME,
                            COMMUNICATETIME,
                            SCREENRENDERTIME,
                            TOTALTIME,
                            FIRSETSCREENJSFEXECUTETIME,
                            CALLCREATEINSTANCETIME,
                            COMMUNICATETOTALTIME,
                            FSRENDERTIME,
                            COMPONENTCOUNT,
                            CACHEPROCESSTIME,
                            CACHERATIO,
                            M_FS_CALL_JS_TIME,
                            M_FS_CALL_JS_NUM,
                            M_FS_CALL_NATIVE_TIME,
                            M_FS_CALL_NATIVE_NUM,
                            M_FS_CALL_EVENT_NUM,
                            M_CELL_EXCEED_NUM,
                            M_MAX_DEEP_VDOM,
                            M_IMG_WRONG_SIZE_NUM,
                            M_TIMER_NUM,
                            nil
                        ];
      
    });
    
    for (NSString *key in data) {
        if (nil == key) {
            continue;
        }
        if ([commitDimenKeys containsObject:key]) {
            [self _transDimenValueWithInstanceId:instance withData:@{key:[data objectForKey:key]}];
        }else if([commitMeasureKeys containsObject:key]){
            [self _transMeasureValueWithInstanceId:instance withData:@{key:[data objectForKey:key]}];
        }else{
            //...
        }
    }
}


+ (void) _transMeasureValueWithInstanceId:(WXSDKInstance *)instance withData:(NSDictionary *)data
{
    [self _transDataToAnaylzer:instance
                        withModule:MODULE_PERFORMANCE
                        withType:TYPE_MEASURE_REAL
                        withData:data
     ];
}

+ (void) _transDimenValueWithInstanceId:(WXSDKInstance *)instance withData:(NSDictionary *)data
{
    [self _transDataToAnaylzer:instance
                        withModule:MODULE_PERFORMANCE
                        withType:TYPE_DIMEN_REAL
                        withData:data
     ];
}


+(void) _transDataToAnaylzer:(WXSDKInstance *)instance withModule:(NSString *)module  withType:(NSString *)type withData:(NSDictionary *)data
{
    
    //    NSString *jsonData =[WXUtility JSONString:dic];
    //    jsonData = [jsonData stringByReplacingOccurrencesOfString:@"\n" withString:@""];\\
    
    NSMutableDictionary *wrapDic = [data mutableCopy];
    [wrapDic setObject:instance.instanceId forKey:@"instanceId"];
    [wrapDic setObject:[instance.scriptURL absoluteString] forKey:@"url"];
    NSLog(@"test -> val:%@",wrapDic);
}



+(BOOL) needTransfer
{
    return true;
}


+(void)transErrorInfo:(WXJSExceptionInfo *)errorInfo
{
    if (!errorInfo) {
        return;
    }
    WXSDKInstance *instance = [WXSDKManager instanceForID:errorInfo.instanceId];
    if (!instance) {
        return;
    }
    NSDictionary *dic= @{
                         @"errorCode":errorInfo.errorCode,
                         @"errorGroup":@"",
                         @"errorMsg":errorInfo.exception
                         };
    
    [self _transDataToAnaylzer:instance
                    withModule:MODULE_ERROR
                      withType:TYPE_JS_ERROR
                      withData:dic
     ];
}

@end
