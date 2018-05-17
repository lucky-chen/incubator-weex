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
//  PlatformBridge.hpp
//  Pods-WeexDemo
//
//  Created by 陈佩翰 on 2018/5/17.
//

#ifndef PlatformBridge_hpp
#define PlatformBridge_hpp

#include <core/bridge/PlatformBridge.h>
#include <core/bridge/RenderBridge.h>

namespace WeexCore {
    class PlatformBridge{
    protected:
        PlatformBridge(){}
    public:
        void callInitWeexCore(char* frameWork,WeexCore::RenderBridge *renderBridge,std::map<char*,char*> params);
        void callRegisterCoreEnv(char *instanceId,char* key,char* value);
        
        
        
        
        
    };
}

#endif /* PlatformBridge_hpp */
