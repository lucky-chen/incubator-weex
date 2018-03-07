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

#import "WXComponent+Layout.h"
#import "WXComponent_internal.h"
#import "WXTransform.h"
#import "WXAssert.h"
#import "WXSDKInstance_private.h"
#import "WXComponent+BoxShadow.h"

bool flexIsUndefined(float value) {
    return isnan(value);
}

@implementation WXComponent (Layout)

#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

#pragma mark Public

- (void)setNeedsLayout
{
    _isLayoutDirty = YES;
#ifdef USE_FLEX
    self.flexCssNode->markDirty();
#endif 
    WXComponent *supercomponent = [self supercomponent];
    if(supercomponent){
        [supercomponent setNeedsLayout];
    }
}

- (BOOL)needsLayout
{
    return _isLayoutDirty;
}

- (CGSize (^)(CGSize))measureBlock
{
    return nil;
}

- (void)layoutDidFinish
{
    WXAssertMainThread();
}

#pragma mark Private

- (void)_initCSSNodeWithStyles:(NSDictionary *)styles
{
#ifndef USE_FLEX
    _cssNode = new_css_node();
    
    _cssNode->print = cssNodePrint;
    _cssNode->get_child = cssNodeGetChild;
    _cssNode->is_dirty = cssNodeIsDirty;
    if ([self measureBlock]) {
        _cssNode->measure = cssNodeMeasure;
    }
    _cssNode->context = (__bridge void *)self;
    
    [self _recomputeCSSNodeChildren];
    [self _fillCSSNode:styles];
    
    // To be in conformity with Android/Web, hopefully remove this in the future.
    if ([self.ref isEqualToString:WX_SDK_ROOT_REF]) {
        if (isUndefined(_cssNode->style.dimensions[CSS_HEIGHT]) && self.weexInstance.frame.size.height) {
            _cssNode->style.dimensions[CSS_HEIGHT] = self.weexInstance.frame.size.height;
        }
        
        if (isUndefined(_cssNode->style.dimensions[CSS_WIDTH]) && self.weexInstance.frame.size.width) {
            _cssNode->style.dimensions[CSS_WIDTH] = self.weexInstance.frame.size.width;
        }
    }
#else
    _flexCssNode = new WeexCore::WXCoreLayoutNode();
    if ([self measureBlock]) {
        _flexCssNode->setMeasureFunc(flexCssNodeMeasure);
    }
    _flexCssNode->setContext((__bridge void *)self);
    [self _recomputeCSSNodeChildren];
    [self _fillCSSNode:styles];
    
    if ([self.ref isEqualToString:WX_SDK_ROOT_REF]) {
        if (flexIsUndefined(_flexCssNode->getStyleHeight()) && self.weexInstance.frame.size.height) {
            _flexCssNode->setStyleHeight(self.weexInstance.frame.size.height);
        }
        
        if (flexIsUndefined(_flexCssNode->getStyleWidth()) && self.weexInstance.frame.size.width) {
            _flexCssNode->setStyleWidth(self.weexInstance.frame.size.width);
        }
    }
#endif
}

- (void)_updateCSSNodeStyles:(NSDictionary *)styles
{
    [self _fillCSSNode:styles];
}

-(void)_resetCSSNodeStyles:(NSArray *)styles
{
    [self _resetCSSNode:styles];
}

- (void)_recomputeCSSNodeChildren
{
#ifndef USE_FLEX
    _cssNode->children_count = (int)[self _childrenCountForLayout];
#else
    
#endif
}

- (NSUInteger)_childrenCountForLayout
{
    NSArray *subcomponents = _subcomponents;
    NSUInteger count = subcomponents.count;
    for (WXComponent *component in subcomponents) {
        if (!component->_isNeedJoinLayoutSystem) {
            count--;
        }
    }
    return (int)(count);
}


- (void)_frameDidCalculated:(BOOL)isChanged
{
    WXAssertComponentThread();
    
    if ([self isViewLoaded] && isChanged && [self isViewFrameSyncWithCalculated]) {
        
        __weak typeof(self) weakSelf = self;
        [self.weexInstance.componentManager _addUITask:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf->_transform && !CATransform3DEqualToTransform(strongSelf.layer.transform, CATransform3DIdentity)) {
                // From the UIView's frame documentation:
                // https://developer.apple.com/reference/uikit/uiview#//apple_ref/occ/instp/UIView/frame
                // Warning : If the transform property is not the identity transform, the value of this property is undefined and therefore should be ignored.
                // So layer's transform must be reset to CATransform3DIdentity before setFrame, otherwise frame will be incorrect
                strongSelf.layer.transform = CATransform3DIdentity;
            }
            
            if (!CGRectEqualToRect(strongSelf.view.frame,strongSelf.calculatedFrame)) {
                strongSelf.view.frame = strongSelf.calculatedFrame;
                strongSelf->_absolutePosition = CGPointMake(NAN, NAN);
                [strongSelf configBoxShadow:_boxShadow];
            } else {
                if (![strongSelf equalBoxShadow:_boxShadow withBoxShadow:_lastBoxShadow]) {
                    [strongSelf configBoxShadow:_boxShadow];
                }
            }
            
            [self _resetNativeBorderRadius];
            
            if (strongSelf->_transform) {
                [strongSelf->_transform applyTransformForView:strongSelf.view];
            }
            
            if (strongSelf->_backgroundImage) {
                [strongSelf setGradientLayer];
            }
            [strongSelf setNeedsDisplay];
        }];
    }
}

- (void)_calculateFrameWithSuperAbsolutePosition:(CGPoint)superAbsolutePosition
                           gatherDirtyComponents:(NSMutableSet<WXComponent *> *)dirtyComponents
{
    WXAssertComponentThread();
    

#ifndef USE_FLEX
    if (!_cssNode->layout.should_update) {
        return;
    }
    _cssNode->layout.should_update = false;
    _isLayoutDirty = NO;
    
    CGRect newFrame = CGRectMake(isnan(WXRoundPixelValue(_cssNode->layout.position[CSS_LEFT]))?0:WXRoundPixelValue(_cssNode->layout.position[CSS_LEFT]),
                                 isnan(WXRoundPixelValue(_cssNode->layout.position[CSS_TOP]))?0:WXRoundPixelValue(_cssNode->layout.position[CSS_TOP]),
                                 isnan(WXRoundPixelValue(_cssNode->layout.dimensions[CSS_WIDTH]))?0:WXRoundPixelValue(_cssNode->layout.dimensions[CSS_WIDTH]),
                                 isnan(WXRoundPixelValue(_cssNode->layout.dimensions[CSS_HEIGHT]))?0:WXRoundPixelValue(_cssNode->layout.dimensions[CSS_HEIGHT]));
    
    BOOL isFrameChanged = NO;
    if (!CGRectEqualToRect(newFrame, _calculatedFrame)) {
        isFrameChanged = YES;
        _calculatedFrame = newFrame;
        [dirtyComponents addObject:self];
    }
    
    CGPoint newAbsolutePosition = [self computeNewAbsolutePosition:superAbsolutePosition];
    
    _cssNode->layout.dimensions[CSS_WIDTH] = CSS_UNDEFINED;
    _cssNode->layout.dimensions[CSS_HEIGHT] = CSS_UNDEFINED;
    _cssNode->layout.position[CSS_LEFT] = 0;
    _cssNode->layout.position[CSS_TOP] = 0;

    [self _frameDidCalculated:isFrameChanged];
    NSArray * subcomponents = [_subcomponents copy];
    for (WXComponent *subcomponent in subcomponents) {
        [subcomponent _calculateFrameWithSuperAbsolutePosition:newAbsolutePosition gatherDirtyComponents:dirtyComponents];
    }
#else
    _isLayoutDirty = NO;
    CGRect newFrame = CGRectMake(WXRoundPixelValue(_flexCssNode->getLayoutPositionLeft()),
                                 WXRoundPixelValue(_flexCssNode->getLayoutPositionTop()),
                                 WXRoundPixelValue(_flexCssNode->getLayoutWidth()),
                                 WXRoundPixelValue(_flexCssNode->getLayoutHeight()));
    BOOL isFrameChanged = NO;
    
    if (!CGRectEqualToRect(newFrame, _calculatedFrame)) {
        
        isFrameChanged = YES;
        _calculatedFrame = newFrame;
        [dirtyComponents addObject:self];
    }
    
    CGPoint newAbsolutePosition = [self computeNewAbsolutePosition:superAbsolutePosition];
    
    //_flexCssNode->resetLayolsutResult();

    [self _frameDidCalculated:isFrameChanged];
    NSArray * subcomponents = [_subcomponents copy];
    for (WXComponent *subcomponent in subcomponents) {
        [subcomponent _calculateFrameWithSuperAbsolutePosition:newAbsolutePosition gatherDirtyComponents:dirtyComponents];
    }
#endif
    NSLog(@"test -> newFrame ,type:%@,ref:%@, parentRef:%@,size :%@ ,instance:%@",self.type,self.ref,self.supercomponent.ref,NSStringFromCGRect(newFrame),self.weexInstance.instanceId);
    
    

}

- (CGPoint)computeNewAbsolutePosition:(CGPoint)superAbsolutePosition
{
    // Not need absolutePosition any more
    return superAbsolutePosition;
}

- (void)_layoutDidFinish
{
    WXAssertMainThread();

    if (_positionType == WXPositionTypeSticky) {
        [self.ancestorScroller adjustSticky];
    }
    [self layoutDidFinish];
}

#ifndef USE_FLEX

#define WX_STYLE_FILL_CSS_NODE(key, cssProp, type)\
do {\
    id value = styles[@#key];\
    if (value) {\
        typeof(_cssNode->style.cssProp) convertedValue = (typeof(_cssNode->style.cssProp))[WXConvert type:value];\
        _cssNode->style.cssProp = convertedValue;\
        [self setNeedsLayout];\
    }\
} while(0);

#define WX_STYLE_FILL_CSS_NODE_PIXEL(key, cssProp)\
do {\
    id value = styles[@#key];\
    if (value) {\
        CGFloat pixel = [self WXPixelType:value];\
        if (isnan(pixel)) {\
            WXLogError(@"Invalid NaN value for style:%@, ref:%@", @#key, self.ref);\
        } else {\
            _cssNode->style.cssProp = pixel;\
            [self setNeedsLayout];\
        }\
    }\
} while(0);

#define WX_STYLE_FILL_CSS_NODE_ALL_DIRECTION(key, cssProp)\
do {\
    WX_STYLE_FILL_CSS_NODE_PIXEL(key, cssProp[CSS_TOP])\
    WX_STYLE_FILL_CSS_NODE_PIXEL(key, cssProp[CSS_LEFT])\
    WX_STYLE_FILL_CSS_NODE_PIXEL(key, cssProp[CSS_RIGHT])\
    WX_STYLE_FILL_CSS_NODE_PIXEL(key, cssProp[CSS_BOTTOM])\
} while(0);

#else
#endif

- (CGFloat)WXPixelType:(id)value
{
    return [WXConvert WXPixelType:value scaleFactor:self.weexInstance.pixelScaleFactor];
}

- (void)_fillCSSNode:(NSDictionary *)styles
{
#ifndef USE_FLEX
    // flex
    WX_STYLE_FILL_CSS_NODE(flex, flex, CGFloat)
    WX_STYLE_FILL_CSS_NODE(flexDirection, flex_direction, css_flex_direction_t)
    WX_STYLE_FILL_CSS_NODE(alignItems, align_items, css_align_t)
    WX_STYLE_FILL_CSS_NODE(alignSelf, align_self, css_align_t)
    WX_STYLE_FILL_CSS_NODE(flexWrap, flex_wrap, css_wrap_type_t)
    WX_STYLE_FILL_CSS_NODE(justifyContent, justify_content, css_justify_t)
    
    // position
    WX_STYLE_FILL_CSS_NODE(position, position_type, css_position_type_t)
    WX_STYLE_FILL_CSS_NODE_PIXEL(top, position[CSS_TOP])
    WX_STYLE_FILL_CSS_NODE_PIXEL(left, position[CSS_LEFT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(right, position[CSS_RIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(bottom, position[CSS_BOTTOM])
    
    // dimension
    WX_STYLE_FILL_CSS_NODE_PIXEL(width, dimensions[CSS_WIDTH])
    WX_STYLE_FILL_CSS_NODE_PIXEL(height, dimensions[CSS_HEIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(minWidth, minDimensions[CSS_WIDTH])
    WX_STYLE_FILL_CSS_NODE_PIXEL(minHeight, minDimensions[CSS_HEIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(maxWidth, maxDimensions[CSS_WIDTH])
    WX_STYLE_FILL_CSS_NODE_PIXEL(maxHeight, maxDimensions[CSS_HEIGHT])
    
    // margin
    WX_STYLE_FILL_CSS_NODE_ALL_DIRECTION(margin, margin)
    WX_STYLE_FILL_CSS_NODE_PIXEL(marginTop, margin[CSS_TOP])
    WX_STYLE_FILL_CSS_NODE_PIXEL(marginLeft, margin[CSS_LEFT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(marginRight, margin[CSS_RIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(marginBottom, margin[CSS_BOTTOM])
    
    // border
    WX_STYLE_FILL_CSS_NODE_ALL_DIRECTION(borderWidth, border)
    WX_STYLE_FILL_CSS_NODE_PIXEL(borderTopWidth, border[CSS_TOP])
    WX_STYLE_FILL_CSS_NODE_PIXEL(borderLeftWidth, border[CSS_LEFT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(borderRightWidth, border[CSS_RIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(borderBottomWidth, border[CSS_BOTTOM])
    
    // padding
    WX_STYLE_FILL_CSS_NODE_ALL_DIRECTION(padding, padding)
    WX_STYLE_FILL_CSS_NODE_PIXEL(paddingTop, padding[CSS_TOP])
    WX_STYLE_FILL_CSS_NODE_PIXEL(paddingLeft, padding[CSS_LEFT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(paddingRight, padding[CSS_RIGHT])
    WX_STYLE_FILL_CSS_NODE_PIXEL(paddingBottom, padding[CSS_BOTTOM])
#else
    // flex
    if (styles[@"flex"]) {
        _flexCssNode->setFlex([WXConvert CGFloat:styles[@"flex"]]);
    } else {
        // to make the default flex value is zero, yoga is nan, maybe this can configured by yoga config
        _flexCssNode->setFlex(0);
    }
    if (styles[@"flexDirection"]) {
        _flexCssNode->setFlexDirection([self fxFlexDirection:styles[@"flexDirection"]]);
    }
    if (styles[@"alignItems"]) {
        _flexCssNode->setAlignItems([self fxAlign:styles[@"alignItems"]]);
    }
    if (styles[@"alignSelf"]) {
        _flexCssNode->setAlignSelf([self fxAlignSelf:styles[@"alignSelf"]]);
    }
    if (styles[@"flexWrap"]) {
        _flexCssNode->setFlexWrap([self fxWrap:styles[@"flexWrap"]]);
    }
    if (styles[@"justifyContent"]) {
        _flexCssNode->setJustifyContent([self fxJustify:styles[@"justifyContent"]]);
    }
    
    // position
    if (styles[@"position"]) {
        _flexCssNode->setStylePositionType([self fxPositionType:styles[@"position"]]);
    }
    if (styles[@"top"]) {
        _flexCssNode->setStylePosition(WeexCore::kPositionEdgeTop, [WXConvert WXPixelType:styles[@"top"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"left"]) {
        _flexCssNode->setStylePosition(WeexCore::kPositionEdgeLeft, [WXConvert WXPixelType:styles[@"left"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if(styles[@"right"]) {
        _flexCssNode->setStylePosition(WeexCore::kPositionEdgeRight, [WXConvert WXPixelType:styles[@"right"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"bottom"]) {
        _flexCssNode->setStylePosition(WeexCore::kPositionEdgeBottom, [WXConvert WXPixelType:styles[@"bottom"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    // dimension
    if (styles[@"width"]) {
        _flexCssNode->setStyleWidth([WXConvert WXPixelType:styles[@"width"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"height"]) {
        _flexCssNode->setStyleHeight([WXConvert WXPixelType:styles[@"height"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"minWidth"]) {
        _flexCssNode->setMinWidth([WXConvert WXPixelType:styles[@"minWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"minHeight"]) {
        _flexCssNode->setMinHeight([WXConvert WXPixelType:styles[@"minHeight"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"maxWidth"]) {
        _flexCssNode->setMaxWidth([WXConvert WXPixelType:styles[@"maxWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"maxHeight"]) {
        _flexCssNode->setMaxHeight([WXConvert WXPixelType:styles[@"maxHeight"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    // margin
    if (styles[@"margin"]) {
        _flexCssNode->setMargin(WeexCore::kMarginALL, [WXConvert WXPixelType:styles[@"margin"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"marginTop"]) {
        _flexCssNode->setMargin(WeexCore::kMarginTop, [WXConvert WXPixelType:styles[@"marginTop"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"marginBottom"]) {
        _flexCssNode->setMargin(WeexCore::kMarginBottom, [WXConvert WXPixelType:styles[@"marginBottom"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"marginRight"]) {
        _flexCssNode->setMargin(WeexCore::kMarginRight, [WXConvert WXPixelType:styles[@"marginRight"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"marginLeft"]) {
        _flexCssNode->setMargin(WeexCore::kMarginLeft, [WXConvert WXPixelType:styles[@"marginLeft"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    // border
    if (styles[@"border"]) {
        _flexCssNode->setBorderWidth(WeexCore::kBorderWidthALL, [WXConvert WXPixelType:styles[@"border"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"borderTopWidth"]) {
        _flexCssNode->setBorderWidth(WeexCore::kBorderWidthTop, [WXConvert WXPixelType:styles[@"borderTopWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    if (styles[@"borderLeftWidth"]) {
        _flexCssNode->setBorderWidth(WeexCore::kBorderWidthLeft, [WXConvert WXPixelType:styles[@"borderLeftWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    if (styles[@"borderBottomWidth"]) {
        _flexCssNode->setBorderWidth(WeexCore::kBorderWidthBottom, [WXConvert WXPixelType:styles[@"borderBottomWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"borderRightWidth"]) {
        _flexCssNode->setBorderWidth(WeexCore::kBorderWidthRight, [WXConvert WXPixelType:styles[@"borderRightWidth"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    // padding
    if (styles[@"padding"]) {
        _flexCssNode->setPadding(WeexCore::kPaddingALL, [WXConvert WXPixelType:styles[@"padding"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"paddingTop"]) {
        _flexCssNode->setPadding(WeexCore::kPaddingTop, [WXConvert WXPixelType:styles[@"paddingTop"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"paddingLeft"]) {
        _flexCssNode->setPadding(WeexCore::kPaddingLeft, [WXConvert WXPixelType:styles[@"paddingLeft"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"paddingBottom"]) {
        _flexCssNode->setPadding(WeexCore::kPaddingBottom, [WXConvert WXPixelType:styles[@"paddingBottom"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    if (styles[@"paddingRight"]) {
        _flexCssNode->setPadding(WeexCore::kPaddingRight, [WXConvert WXPixelType:styles[@"paddingRight"] scaleFactor:self.weexInstance.pixelScaleFactor]);
    }
    
    [self setNeedsLayout];
#endif
}

#ifndef USE_FLEX

#define WX_STYLE_RESET_CSS_NODE(key, cssProp, defaultValue)\
do {\
    if (styles && [styles containsObject:@#key]) {\
        _cssNode->style.cssProp = defaultValue;\
        [self setNeedsLayout];\
    }\
} while(0);

#define WX_STYLE_RESET_CSS_NODE_ALL_DIRECTION(key, cssProp, defaultValue)\
do {\
    WX_STYLE_RESET_CSS_NODE(key, cssProp[CSS_TOP], defaultValue)\
    WX_STYLE_RESET_CSS_NODE(key, cssProp[CSS_LEFT], defaultValue)\
    WX_STYLE_RESET_CSS_NODE(key, cssProp[CSS_RIGHT], defaultValue)\
    WX_STYLE_RESET_CSS_NODE(key, cssProp[CSS_BOTTOM], defaultValue)\
} while(0);

#else

#define WX_FLEX_STYLE_RESET_CSS_NODE(key, defaultValue)\
do {\
    WX_FLEX_STYLE_RESET_CSS_NODE_GIVEN_KEY(key,key,defaultValue)\
} while(0);

#define WX_FLEX_STYLE_RESET_CSS_NODE_GIVEN_KEY(judgeKey, propKey, defaultValue)\
do {\
    if (styles && [styles containsObject:@#judgeKey]) {\
        NSMutableDictionary *resetStyleDic = [[NSMutableDictionary alloc] init];\
        [resetStyleDic setValue:defaultValue forKey:@#propKey];\
        [self _updateCSSNodeStyles:resetStyleDic];\
        [self setNeedsLayout];\
    }\
} while(0);

#define WX_FLEX_STYLE_RESET_CSS_NODE_GIVEN_DIRECTION_KEY(judgeKey, propTopKey,propLeftKey,propRightKey,propBottomKey, defaultValue)\
do {\
    if (styles && [styles containsObject:@#judgeKey]) {\
        NSMutableDictionary *resetStyleDic = [[NSMutableDictionary alloc] init];\
        [resetStyleDic setValue:defaultValue forKey:@#propTopKey];\
        [resetStyleDic setValue:defaultValue forKey:@#propLeftKey];\
        [resetStyleDic setValue:defaultValue forKey:@#propRightKey];\
        [resetStyleDic setValue:defaultValue forKey:@#propBottomKey];\
        [self _updateCSSNodeStyles:resetStyleDic];\
        [self setNeedsLayout];\
    }\
} while(0);

#endif


- (void)_resetCSSNode:(NSArray *)styles
{
#ifndef USE_FLEX
    // flex
    WX_STYLE_RESET_CSS_NODE(flex, flex, 0.0)
    WX_STYLE_RESET_CSS_NODE(flexDirection, flex_direction, CSS_FLEX_DIRECTION_COLUMN)
    WX_STYLE_RESET_CSS_NODE(alignItems, align_items, CSS_ALIGN_STRETCH)
    WX_STYLE_RESET_CSS_NODE(alignSelf, align_self, CSS_ALIGN_AUTO)
    WX_STYLE_RESET_CSS_NODE(flexWrap, flex_wrap, CSS_NOWRAP)
    WX_STYLE_RESET_CSS_NODE(justifyContent, justify_content, CSS_JUSTIFY_FLEX_START)

    // position
    WX_STYLE_RESET_CSS_NODE(position, position_type, CSS_POSITION_RELATIVE)
    WX_STYLE_RESET_CSS_NODE(top, position[CSS_TOP], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(left, position[CSS_LEFT], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(right, position[CSS_RIGHT], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(bottom, position[CSS_BOTTOM], CSS_UNDEFINED)
    
    // dimension
    WX_STYLE_RESET_CSS_NODE(width, dimensions[CSS_WIDTH], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(height, dimensions[CSS_HEIGHT], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(minWidth, minDimensions[CSS_WIDTH], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(minHeight, minDimensions[CSS_HEIGHT], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(maxWidth, maxDimensions[CSS_WIDTH], CSS_UNDEFINED)
    WX_STYLE_RESET_CSS_NODE(maxHeight, maxDimensions[CSS_HEIGHT], CSS_UNDEFINED)
    
    // margin
    WX_STYLE_RESET_CSS_NODE_ALL_DIRECTION(margin, margin, 0.0)
    WX_STYLE_RESET_CSS_NODE(marginTop, margin[CSS_TOP], 0.0)
    WX_STYLE_RESET_CSS_NODE(marginLeft, margin[CSS_LEFT], 0.0)
    WX_STYLE_RESET_CSS_NODE(marginRight, margin[CSS_RIGHT], 0.0)
    WX_STYLE_RESET_CSS_NODE(marginBottom, margin[CSS_BOTTOM], 0.0)
    
    // border
    WX_STYLE_RESET_CSS_NODE_ALL_DIRECTION(borderWidth, border, 0.0)
    WX_STYLE_RESET_CSS_NODE(borderTopWidth, border[CSS_TOP], 0.0)
    WX_STYLE_RESET_CSS_NODE(borderLeftWidth, border[CSS_LEFT], 0.0)
    WX_STYLE_RESET_CSS_NODE(borderRightWidth, border[CSS_RIGHT], 0.0)
    WX_STYLE_RESET_CSS_NODE(borderBottomWidth, border[CSS_BOTTOM], 0.0)
    
    // padding
    WX_STYLE_RESET_CSS_NODE_ALL_DIRECTION(padding, padding, 0.0)
    WX_STYLE_RESET_CSS_NODE(paddingTop, padding[CSS_TOP], 0.0)
    WX_STYLE_RESET_CSS_NODE(paddingLeft, padding[CSS_LEFT], 0.0)
    WX_STYLE_RESET_CSS_NODE(paddingRight, padding[CSS_RIGHT], 0.0)
    WX_STYLE_RESET_CSS_NODE(paddingBottom, padding[CSS_BOTTOM], 0.0)
#else

    if (styles.count<=0) {
        return;
    }
    
    WX_FLEX_STYLE_RESET_CSS_NODE(flex, @0.0)
    WX_FLEX_STYLE_RESET_CSS_NODE(flexDirection, @(CSS_FLEX_DIRECTION_COLUMN))
    WX_FLEX_STYLE_RESET_CSS_NODE(alignItems, @(CSS_ALIGN_STRETCH))
    WX_FLEX_STYLE_RESET_CSS_NODE(alignSelf, @(CSS_ALIGN_AUTO))
    WX_FLEX_STYLE_RESET_CSS_NODE(flexWrap, @(CSS_NOWRAP))
    WX_FLEX_STYLE_RESET_CSS_NODE(justifyContent, @(CSS_JUSTIFY_FLEX_START))
    
    // position
    WX_FLEX_STYLE_RESET_CSS_NODE(position, @(CSS_POSITION_RELATIVE))
    WX_FLEX_STYLE_RESET_CSS_NODE(top, @(CSS_UNDEFINED))
    WX_FLEX_STYLE_RESET_CSS_NODE(left, @(CSS_UNDEFINED))
    WX_FLEX_STYLE_RESET_CSS_NODE(right, @(CSS_UNDEFINED))
    WX_FLEX_STYLE_RESET_CSS_NODE(bottom, @(CSS_UNDEFINED))
    
    // dimension
    WX_FLEX_STYLE_RESET_CSS_NODE(width, @(CSS_UNDEFINED))
    WX_FLEX_STYLE_RESET_CSS_NODE(height, @(CSS_UNDEFINED))
    WX_FLEX_STYLE_RESET_CSS_NODE(minWidth, @(CSS_UNDEFINED))
    WX_FLEX_STYLE_RESET_CSS_NODE(minHeight, @(CSS_UNDEFINED))
    WX_FLEX_STYLE_RESET_CSS_NODE(maxWidth, @(CSS_UNDEFINED))
    WX_FLEX_STYLE_RESET_CSS_NODE(maxHeight, @(CSS_UNDEFINED))
    
    // margin
    WX_FLEX_STYLE_RESET_CSS_NODE_GIVEN_DIRECTION_KEY(margin
                                                     ,marginTop
                                                     ,marginLeft
                                                     ,marginRight
                                                     ,marginBottom
                                                     , @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(marginTop, @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(marginLeft, @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(marginRight, @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(marginBottom, @(0.0))
    
    // border
    WX_FLEX_STYLE_RESET_CSS_NODE_GIVEN_DIRECTION_KEY(borderWidth
                                                     , borderTopWidth
                                                     , borderLeftWidth
                                                     , borderRightWidth
                                                     , borderBottomWidth
                                                     , @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(borderTopWidth, @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(borderLeftWidth, @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(borderRightWidth, @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(borderBottomWidth, @(0.0))
    
    // padding
    WX_FLEX_STYLE_RESET_CSS_NODE_GIVEN_DIRECTION_KEY(padding
                                                     , paddingTop
                                                     , paddingLeft
                                                     , paddingRight
                                                     , paddingBottom
                                                     , @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(paddingTop, @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(paddingLeft, @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(paddingRight, @(0.0))
    WX_FLEX_STYLE_RESET_CSS_NODE(paddingBottom, @(0.0))
    
#endif
}

#pragma mark CSS Node Override

#ifndef USE_FLEX
#if defined __cplusplus
extern "C" {
#endif
static void cssNodePrint(void *context)
{
    WXComponent *component = (__bridge WXComponent *)context;
    // TODO:
    printf("%s:%s ", component.ref.UTF8String, component->_type.UTF8String);
}

static css_node_t * cssNodeGetChild(void *context, int i)
{
    WXComponent *component = (__bridge WXComponent *)context;
    NSArray *subcomponents = component->_subcomponents;
    for (int j = 0; j <= i && j < subcomponents.count; j++) {
        WXComponent *child = subcomponents[j];
        if (!child->_isNeedJoinLayoutSystem) {
            i++;
        }
    }
    
    if(i >= 0 && i < subcomponents.count){
        WXComponent *child = subcomponents[i];
//        WXLogInfo(@"FlexLayout -- P:%@ -> C:%@",component,(__bridge WXComponent *)child->_cssNode->context);
        return child->_cssNode;
    }
    
    WXAssert(NO, @"Can not find component:%@'s css node child at index: %ld, totalCount:%ld", component, i, subcomponents.count);
    return NULL;
}

static bool cssNodeIsDirty(void *context)
{
    WXAssertComponentThread();
    
    WXComponent *component = (__bridge WXComponent *)context;
    BOOL needsLayout = [component needsLayout];
    
    return needsLayout;
}
    
static css_dim_t cssNodeMeasure(void *context, float width, css_measure_mode_t widthMode, float height, css_measure_mode_t heightMode)
{
    WXComponent *component = (__bridge WXComponent *)context;
    CGSize (^measureBlock)(CGSize) = [component measureBlock];
    
    if (!measureBlock) {
        return (css_dim_t){NAN, NAN};
    }
    
    CGSize constrainedSize = CGSizeMake(width, height);
    CGSize resultSize = measureBlock(constrainedSize);
    
    NSLog(@"test -> measureblock %@, resultSize:%@",
          component.type,
          NSStringFromCGSize(resultSize)
          );
    
    return (css_dim_t){(float)resultSize.width, (float)resultSize.height};
}
#if defined __cplusplus
};
#endif

#else

static WeexCore::WXCoreSize flexCssNodeMeasure(WeexCore::WXCoreLayoutNode *node, float width, WeexCore::MeasureMode widthMeasureMode,float height, WeexCore::MeasureMode heightMeasureMode){
    WXComponent *component = (__bridge WXComponent *)(node->getContext());
    
//    if ([component objectForKey:@"_text"]) {
//        NSLog(@"test -> measure Text ref:%@ text->%@, flexCssNodeMeasure start",component.ref,[component objectForKey:@"_text"]);
//    }
    
    CGSize (^measureBlock)(CGSize) = [component measureBlock];
    
    if (!measureBlock) {
        return WeexCore::WXCoreSize();
    }
    
    CGSize constrainedSize = CGSizeMake(width, height);
    CGSize resultSize = measureBlock(constrainedSize);
    
    NSLog(@"test -> measureblock %@, resultSize:%@",
          component.type,
          NSStringFromCGSize(resultSize)
          );
    WeexCore::WXCoreSize size;
    size.height=(float)resultSize.height;
    size.width=(float)resultSize.width;
    return size;
}

-(WeexCore::WXCorePositionType)fxPositionType:(id)value
{
    if([value isKindOfClass:[NSString class]]){
        if ([value isEqualToString:@"absolute"]) {
            return WeexCore::kAbsolute;
        } else if ([value isEqualToString:@"relative"]) {
            return WeexCore::kRelative;
        } else if ([value isEqualToString:@"fixed"]) {
            return WeexCore::kFixed;
        } else if ([value isEqualToString:@"sticky"]) {
            return WeexCore::kRelative;
        }
    }
    return WeexCore::kRelative;
}

- (WeexCore::WXCoreFlexDirection)fxFlexDirection:(id)value
{
    if([value isKindOfClass:[NSString class]]){
        if ([value isEqualToString:@"column"]) {
            return WeexCore::kFlexDirectionColumn;
        } else if ([value isEqualToString:@"column-reverse"]) {
            return WeexCore::kFlexDirectionColumnReverse;
        } else if ([value isEqualToString:@"row"]) {
            return WeexCore::kFlexDirectionRow;
        } else if ([value isEqualToString:@"row-reverse"]) {
            return WeexCore::kFlexDirectionRowReverse;
        }
    }
    return WeexCore::kFlexDirectionColumn;
}

//TODO
- (WeexCore::WXCoreAlignItems)fxAlign:(id)value
{
    if([value isKindOfClass:[NSString class]]){
        if ([value isEqualToString:@"stretch"]) {
            return WeexCore::kAlignItemsStretch;
        } else if ([value isEqualToString:@"flex-start"]) {
            return WeexCore::kAlignItemsFlexStart;
        } else if ([value isEqualToString:@"flex-end"]) {
            return WeexCore::kAlignItemsFlexEnd;
        } else if ([value isEqualToString:@"center"]) {
            return WeexCore::kAlignItemsCenter;
            //return WXCoreFlexLayout::WXCore_AlignItems_Center;
        } else if ([value isEqualToString:@"auto"]) {
//            return YGAlignAuto;
        } else if ([value isEqualToString:@"baseline"]) {
//            return YGAlignBaseline;
        }
    }
    
    return WeexCore::kAlignItemsStretch;
}

- (WeexCore::WXCoreAlignSelf)fxAlignSelf:(id)value
{
    if([value isKindOfClass:[NSString class]]){
        if ([value isEqualToString:@"stretch"]) {
            return WeexCore::kAlignSelfStretch;
        } else if ([value isEqualToString:@"flex-start"]) {
            return WeexCore::kAlignSelfFlexStart;
        } else if ([value isEqualToString:@"flex-end"]) {
            return WeexCore::kAlignSelfFlexEnd;
        } else if ([value isEqualToString:@"center"]) {
            return WeexCore::kAlignSelfCenter;
        } else if ([value isEqualToString:@"auto"]) {
            return WeexCore::kAlignSelfAuto;
        } else if ([value isEqualToString:@"baseline"]) {
            //            return YGAlignBaseline;
        }
    }
    
    return WeexCore::kAlignSelfStretch;
}

- (WeexCore::WXCoreFlexWrap)fxWrap:(id)value
{
    if([value isKindOfClass:[NSString class]]) {
        if ([value isEqualToString:@"nowrap"]) {
            return WeexCore::kNoWrap;
        } else if ([value isEqualToString:@"wrap"]) {
            return WeexCore::kWrap;
        } else if ([value isEqualToString:@"wrap-reverse"]) {
            return WeexCore::kWrapReverse;
        }
    }
    return WeexCore::kNoWrap;
}

- (WeexCore::WXCoreJustifyContent)fxJustify:(id)value
{
    if([value isKindOfClass:[NSString class]]){
        if ([value isEqualToString:@"flex-start"]) {
            return WeexCore::kJustifyFlexStart;
        } else if ([value isEqualToString:@"center"]) {
            return WeexCore::kJustifyCenter;
        } else if ([value isEqualToString:@"flex-end"]) {
            return WeexCore::kJustifyFlexEnd;
        } else if ([value isEqualToString:@"space-between"]) {
            return WeexCore::kJustifySpaceBetween;
        } else if ([value isEqualToString:@"space-around"]) {
            return WeexCore::kJustifySpaceAround;
        }
    }
    return WeexCore::kJustifyFlexStart;
}


- (NSInteger) getActualNodeIndex:(WXComponent*)subcomponent atIndex:(NSInteger) index
{
    NSInteger actualIndex = 0; //实际除去不需要布局的subComponent，此时所在的正确位置
    for (WXComponent *child in _subcomponents) {
        if ([child.ref isEqualToString:subcomponent.ref]) {
            break;
        }
        if (child->_isNeedJoinLayoutSystem) {
            actualIndex ++;
        }
    }
    return actualIndex;
}

- (void)_insertChildCssNode:(WXComponent*)subcomponent atIndex:(NSInteger)index
{
    self.flexCssNode->addChildAt(subcomponent.flexCssNode, (uint32_t)index);
}

- (void)_rmChildCssNode:(WXComponent *)subcomponent
{
    self.flexCssNode->removeChild(subcomponent->_flexCssNode);
    NSLog(@"test -> ref:%@ ,flexCssNode->removeChild ,childRef:%@",self.ref,subcomponent.ref);
}

#endif

@end
