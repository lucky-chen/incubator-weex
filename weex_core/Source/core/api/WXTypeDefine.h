/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
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
        char*            methodName;
        WXTypeDefine    returnType;
        WXTypeDefine   *argsType;
        uint8_t         argsLength;
        void*           fucnAddr;
    };
}


#endif /* WXTypeDefine_h */
