/*
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

#import "WXComponent.h"
#import "WXSDKInstance.h"
#import "WXUtility.h"
#import "WXLayoutDefine.h"
#import "WXCoreLayout.h"

#define FlexUndefined NAN
#define USE_FLEX

#ifdef DEBUG
#define LOG_PERFORMANCE
#endif


#ifdef __cplusplus 
extern "C" {
#endif
    bool flexIsUndefined(float value);
#ifdef __cplusplus
}
#endif

@interface WXComponent ()
{
    @package
    /**
     *  Layout
     */
#ifndef USE_FLEX
    css_node_t *_cssNode;
#else
#ifdef __cplusplus
    WeexCore::WXCoreLayoutNode *_flexCssNode;
#endif // __cplusplus
#endif //USE_FLEX
    BOOL _isLayoutDirty;
    CGRect _calculatedFrame;
    CGPoint _absolutePosition;
    WXPositionType _positionType;
}

#ifndef USE_FLEX
/**
 * @abstract Return the css node used to layout.
 *
 * @warning Subclasses must not override this.
 */
@property(nonatomic, readonly, assign) css_node_t *cssNode;
#else
#ifdef __cplusplus
@property(nonatomic, readonly, assign) WeexCore::WXCoreLayoutNode *flexCssNode;
#endif
#endif

@end

@interface WXComponent (Layout)
#ifndef USE_FLEX
#else
- (void)_insertChildCssNode:(WXComponent*)subcomponent atIndex:(NSInteger)index;
- (void)_rmChildCssNode:(WXComponent*)subcomponent;
- (NSInteger) getActualNodeIndex:(WXComponent*)subcomponent atIndex:(NSInteger) index;
#endif
@end
