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

#ifndef bridge_impl_ios_h
#define bridge_impl_ios_h

#include <core/bridge/bridge.h>
#include <stdio.h>

namespace WeexCore {
    class Bridge_Impl_iOS : public Bridge {
    private:
    public:
        static Bridge_Impl_iOS *m_instance;
        
        //just to release singleton object
        class Garbo {
        public:
            ~Garbo() {
                if (Bridge_Impl_iOS::m_instance) {
                    delete Bridge_Impl_iOS::m_instance;
                }
            }
        };
        
        Bridge_Impl_iOS();
        ~Bridge_Impl_iOS();
        
        static Bridge_Impl_iOS *getInstance() {
            if (m_instance == nullptr) {
                m_instance = new Bridge_Impl_iOS();
            }
            return m_instance;
        }
        
        void setJSVersion(const char* version) = 0;
        
        void reportException(const char* pageId, const char *func, const char *exception_string) = 0;
        
        int callNative(const char* pageId, const char *task, const char *callback) = 0;
        
        void* callNativeModule(const char* pageId, const char *module, const char *method,
                                       const char *argString, const char *optString) = 0;
        
        void callNativeComponent(const char* pageId, const char* ref, const char *method,
                                         const char *argString, const char *optString) = 0;
        
        void setTimeout(const char* callbackID, const char* time) = 0;
        
        void callNativeLog(const char* str_array) = 0;
        
        int callUpdateFinish(const char* pageId, const char *task, const char *callback) = 0;
        
        int callRefreshFinish(const char* pageId, const char *task, const char *callback) = 0;
        
        int callAddEvent(const char* pageId, const char* ref, const char *event) = 0;
        
        int callRemoveEvent(const char* pageId, const char* ref, const char *event) = 0;
        
        int callCreateBody(const char* pageId, const char *componentType, const char* ref,
                                   std::map<std::string, std::string> *styles,
                                   std::map<std::string, std::string> *attributes,
                                   std::set<std::string> *events,
                                   const WXCoreMargin &margins,
                                   const WXCorePadding &paddings,
                                   const WXCoreBorderWidth &borders) = 0;
        
        int callAddElement(const char* pageId, const char *componentType, const char* ref,
                                   int &index, const char* parentRef,
                                   std::map<std::string, std::string> *styles,
                                   std::map<std::string, std::string> *attributes,
                                   std::set<std::string> *events,
                                   const WXCoreMargin &margins,
                                   const WXCorePadding &paddings,
                                   const WXCoreBorderWidth &borders,
                                   bool willLayout= true) = 0;
        
        int callLayout(const char* pageId, const char* ref,
                               int top, int bottom, int left, int right,
                               int height, int width, int index) = 0;
        
        int callUpdateStyle(const char* pageId, const char* ref,
                                    std::vector<std::pair<std::string, std::string>> *style,
                                    std::vector<std::pair<std::string, std::string>> *margin,
                                    std::vector<std::pair<std::string, std::string>> *padding,
                                    std::vector<std::pair<std::string, std::string>> *border) = 0;
        
        int callUpdateAttr(const char* pageId, const char* ref,
                                   std::vector<std::pair<std::string, std::string>> *attrs) = 0;
        
        int callCreateFinish(const char* pageId) = 0;
        
        int callRemoveElement(const char* pageId, const char* ref) = 0;
        
        int callMoveElement(const char* pageId, const char* ref, const char* parentRef, int index) = 0;
        
        int callAppendTreeCreateFinish(const char* pageId, const char* ref) = 0;
    };
}

#endif /* bridge_impl_ios_h */
