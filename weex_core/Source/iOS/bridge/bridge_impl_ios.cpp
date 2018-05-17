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

#include "bridge_impl_ios.h"

namespace WeexCore {
    
    Bridge_Impl_iOS *Bridge_Impl_iOS::m_instance = nullptr;
    
    Bridge_Impl_iOS::Bridge_Impl_iOS() {}
    
    Bridge_Impl_iOS::~Bridge_Impl_iOS() {}
    
    void Bridge_Impl_iOS::setJSVersion(const char* version) {
        
    };
    
    void Bridge_Impl_iOS::reportException(const char* pageId, const char *func, const char *exception_string) {
        
    }
    
    int Bridge_Impl_iOS::callNative(const char* pageId, const char *task, const char *callback) {
        
    }
    
    void* Bridge_Impl_iOS::callNativeModule(const char* pageId, const char *module, const char *method,
                                            const char *argString, const char *optString) {
        
    }
    
    void Bridge_Impl_iOS::callNativeComponent(const char* pageId, const char* ref, const char *method,
                             const char *argString, const char *optString) {
        
    }
    
    void Bridge_Impl_iOS::setTimeout(const char* callbackID, const char* time) {
        
    }
    
    void Bridge_Impl_iOS::callNativeLog(const char* str_array) {
        
    }
    
    int Bridge_Impl_iOS::callUpdateFinish(const char* pageId, const char *task, const char *callback) {
        
    }
    
    int Bridge_Impl_iOS::callRefreshFinish(const char* pageId, const char *task, const char *callback) {
        
    }
    
    int Bridge_Impl_iOS::callAddEvent(const char* pageId, const char* ref, const char *event) {
        
    }
    
    int Bridge_Impl_iOS::callRemoveEvent(const char* pageId, const char* ref, const char *event) {
        
    }
    
    int Bridge_Impl_iOS::callCreateBody(const char* pageId, const char *componentType, const char* ref,
                       std::map<std::string, std::string> *styles,
                       std::map<std::string, std::string> *attributes,
                       std::set<std::string> *events,
                       const WXCoreMargin &margins,
                       const WXCorePadding &paddings,
                       const WXCoreBorderWidth &borders) {
        
    }
    
    int Bridge_Impl_iOS::callAddElement(const char* pageId, const char *componentType, const char* ref,
                       int &index, const char* parentRef,
                       std::map<std::string, std::string> *styles,
                       std::map<std::string, std::string> *attributes,
                       std::set<std::string> *events,
                       const WXCoreMargin &margins,
                       const WXCorePadding &paddings,
                       const WXCoreBorderWidth &borders,
                       bool willLayout) {
        
    }
    
    int Bridge_Impl_iOS::callLayout(const char* pageId, const char* ref,
                   int top, int bottom, int left, int right,
                   int height, int width, int index) {
        
    }
    
    int Bridge_Impl_iOS::callUpdateStyle(const char* pageId, const char* ref,
                        std::vector<std::pair<std::string, std::string>> *style,
                        std::vector<std::pair<std::string, std::string>> *margin,
                        std::vector<std::pair<std::string, std::string>> *padding,
                        std::vector<std::pair<std::string, std::string>> *border) {
        
    }
    
    int Bridge_Impl_iOS::callUpdateAttr(const char* pageId, const char* ref,
                       std::vector<std::pair<std::string, std::string>> *attrs) {
        
    }
    
    int Bridge_Impl_iOS::callCreateFinish(const char* pageId) {
        
    }
    
    int Bridge_Impl_iOS::callRemoveElement(const char* pageId, const char* ref) {
        
    }
    
    int Bridge_Impl_iOS::callMoveElement(const char* pageId, const char* ref, const char* parentRef, int index) {
        
    }
    
    int Bridge_Impl_iOS::callAppendTreeCreateFinish(const char* pageId, const char* ref) {
        
    }
    
}

