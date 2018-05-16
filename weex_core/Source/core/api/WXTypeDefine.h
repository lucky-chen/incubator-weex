//
//  WXTypeDefine.h
//  WeexSDK
//
//  Created by 陈佩翰 on 2018/5/16.
//  Copyright © 2018年 taobao. All rights reserved.
//

#ifndef WXTypeDefine_h
#define WXTypeDefine_h

#include <cstdint>

namespace WeexCore {
    
    enum WXTypeDefine {
        INTEGER = 1,
        DOUBLE,
        STRING,
        JSON,
        WSON
    };
    
    union WXValeDefine {
        int64_t intValue;
        double doubleValue;
        char* string;
    };
    
    
    struct WXValue {
        WXTypeDefine type;
        WXValeDefine value;
    };
    
    struct WXFuncSignature {
        char*           methodName;
        WXTypeDefine    returnType;
        WXTypeDefine   *argsType;
        void*           fucnAddr;
    };
}


#endif /* WXTypeDefine_h */
