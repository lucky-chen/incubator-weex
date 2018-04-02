#import <Foundation/Foundation.h>
#import "WXAnalyzerCenter.h"
#import "WXAnalyzerProtocol.h"
#import "WXAppMonitorProtocol.h"
#import "WXSDKManager.h"
#import "WXLog.h"
#import "WXTracingManager.h"
#import "WXAnalyzerCenter.h"
#import "WXAnalyzerCenter+Transfer.h"

//@interface WXAnalyzerCenter ()
//@property (nonatomic, strong) NSMutableArray<WXAnalyzerProtocol> *analyzerList;
//@end

@implementation WXAnalyzerCenter

//+ (instancetype) sharedInstance{
//
//    static WXAnalyzerCenter *instance = nil;
//    static dispatch_once_t once;
//
//    dispatch_once(&once, ^{
//        instance = [[WXAnalyzerCenter alloc] init];
//
//    });
//
//    return instance;
//}


+ (void) transDataOnState:(CommitState) timeState withInstaneId:(NSString *)instanceId data:(NSDictionary *)data
{
    if(![self needTransfer] || !instanceId){
        return;
    }
    WXSDKInstance * instance = [WXSDKManager instanceForID:instanceId];
    if (!instance) {
        return;
    }

    WXLogDebug(@"test --> transDataOnState :%ld",timeState);

    NSDictionary *commitDimenKeys = [self getKeys:TRUE];
    NSDictionary *commitMeasureKeys = [self getKeys:FALSE];
    for(id key in data){
       if([self checkDataWithSate:timeState checkKey:key limitDic:commitMeasureKeys]){
           [self _transMeasureValue:instance key:key withVal:[data valueForKey:key]];
       }else if([self checkDataWithSate:timeState checkKey:key limitDic:commitDimenKeys]){
           [self _transDimenValue:instance key:key withVal:[data valueForKey:key]];
       }else{
           WXLogDebug(@"WXAnalyzerDataTransfer -> unKnowPerformanceKey :%@",key);
       }
    }
}

+(BOOL) checkDataWithSate:(CommitState)timeState checkKey:(id)key limitDic:(NSDictionary *)limitDic
{
    if (!key || ![key isKindOfClass:[NSString class]]) {
        return FALSE;
    }
   
    if (![limitDic objectForKey:key]) {
        return FALSE;
    }
    CommitState limitSate = [[limitDic objectForKey:key] intValue];
    if (timeState != limitSate) {
        return FALSE;
    }
    return TRUE;
}



+ (NSDictionary *) getKeys:(BOOL) measureOrDimen
{
    static NSDictionary *commitDimenKeys;
    static NSDictionary *commitMeasureKeys;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        // non-standard perf commit names, remove this hopefully.
        
        commitDimenKeys =@{
                           BIZTYPE:             [NSNumber numberWithInt:AfterFirstSreenFinish],
                           PAGENAME:            [NSNumber numberWithInt:AfterRequest],
                           WXSDKVERSION:        [NSNumber numberWithInt:AfterRequest],
                           JSLIBVERSION:        [NSNumber numberWithInt:AfterRequest],
                           JSLIBSIZE:           [NSNumber numberWithInt:AfterRequest],
                           WXREQUESTTYPE:       [NSNumber numberWithInt:AfterRequest],
                           WXCONNECTIONTYPE:    [NSNumber numberWithInt:AfterRequest],
                           NETWORKTYPE:         [NSNumber numberWithInt:AfterRequest],
                           CACHETYPE:           [NSNumber numberWithInt:AfterRequest],
                           WXCUSTOMMONITORINFO: [NSNumber numberWithInt:AfterRequest]
        };
        commitMeasureKeys =@{
                             SDKINITTIME:                   [NSNumber numberWithInt:AfterFirstSreenFinish],
                             SDKINITINVOKETIME:             [NSNumber numberWithInt:AfterFirstSreenFinish],
                             JSLIBINITTIME:                 [NSNumber numberWithInt:AfterFirstSreenFinish],
                             JSTEMPLATESIZE:                [NSNumber numberWithInt:AfterRequest],
                             NETWORKTIME:                   [NSNumber numberWithInt:AfterRequest],
                             COMMUNICATETIME:               [NSNumber numberWithInt:AfterExist],
                             SCREENRENDERTIME:              [NSNumber numberWithInt:AfterExist],
                             TOTALTIME:                     [NSNumber numberWithInt:AfterExist],
                             FIRSETSCREENJSFEXECUTETIME:    [NSNumber numberWithInt:AfterFirstSreenFinish],
                             CALLCREATEINSTANCETIME:        [NSNumber numberWithInt:AfterFirstSreenFinish],
                             COMMUNICATETOTALTIME:          [NSNumber numberWithInt:AfterExist],
                             FSRENDERTIME:                  [NSNumber numberWithInt:AfterExist],
                             COMPONENTCOUNT:                [NSNumber numberWithInt:AfterExist],
                             CACHEPROCESSTIME:              [NSNumber numberWithInt:AfterRequest],
                             CACHERATIO:                    [NSNumber numberWithInt:AfterRequest],
                             M_FS_CALL_JS_TIME:             [NSNumber numberWithInt:AfterFirstSreenFinish],
                             M_FS_CALL_JS_NUM:              [NSNumber numberWithInt:AfterFirstSreenFinish],
                             M_FS_CALL_NATIVE_TIME:         [NSNumber numberWithInt:AfterFirstSreenFinish],
                             M_FS_CALL_NATIVE_NUM:          [NSNumber numberWithInt:AfterFirstSreenFinish],
                             M_FS_CALL_EVENT_NUM:           [NSNumber numberWithInt:AfterFirstSreenFinish],
                             M_CELL_EXCEED_NUM:             [NSNumber numberWithInt:AfterFirstSreenFinish],
                             M_MAX_DEEP_VDOM:               [NSNumber numberWithInt:AfterExist],
                             M_IMG_WRONG_SIZE_NUM:          [NSNumber numberWithInt:AfterExist],
                             M_TIMER_NUM:                   [NSNumber numberWithInt:AfterFirstSreenFinish]
                             };
        
    });
    return measureOrDimen?commitMeasureKeys:commitDimenKeys;
}



+ (void) _transMeasureValue:(WXSDKInstance *)instance key:(NSString *)commitKey withVal:(id)commitVal
{
    [self _transDataToAnaylzer:instance
                        withModule:MODULE_PERFORMANCE
                        withType:TYPE_MEASURE_REAL
                        withData:@{commitKey:commitVal}
     ];
}

+ (void) _transDimenValue:(WXSDKInstance *)instance key:(NSString *)commitKey withVal:(id)commitVal
{
    [self _transDataToAnaylzer:instance
                        withModule:MODULE_PERFORMANCE
                        withType:TYPE_DIMEN_REAL
                        withData:@{commitKey:commitVal}
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
    
    
    NSMutableArray* analyzerList = [self getAnalyzerList];
    if (nil == analyzerList || analyzerList.count <= 0) {
        return;
    }
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:GROUP_ANALYZER forKey:@"group"];
    [dic setValue:module forKey:@"module"];
    [dic setValue:type forKey:@"type"];
    [dic setValue:data forKey:@"data"];

    
    for (id analyzer in analyzerList) {
        if ( [analyzer respondsToSelector:(@selector(transfer:))])
        {
            [analyzer performSelector:@selector(transfer:) withObject:dic];
        }
    }
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

+ (void) addWxAnalyzer:(id<WXAnalyzerProtocol>)handler
{
    if (!handler) {
        return;
    }
    //[[self ].analyzerList addObject:handler];
}

+ (void) rmWxAnalyzer:(id<WXAnalyzerProtocol>)handler
{
    if (!handler) {
        return;
    }
    //[[WXTracingManager sharedInstance].analyzerList removeObject:handler];
}

+ (NSMutableArray<WXAnalyzerProtocol> *)getAnalyzerList
{
    return nil;
}


+(BOOL) needTransfer
{
    NSMutableArray* analyzerList = [self getAnalyzerList];
    if (nil == analyzerList || analyzerList.count <= 0) {
        return FALSE;
    }
    return TRUE;
}

@end
