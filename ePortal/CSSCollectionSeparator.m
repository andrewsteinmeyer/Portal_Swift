//
//  CSSCollectionSeparator.m
//  ePortal
//
//  Created by Andrew Steinmeyer on 10/17/15.
//  Copyright © 2015 Andrew Steinmeyer. All rights reserved.
//

#import "CSSCollectionSeparator.h"

@implementation CSSCollectionSeparator

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor lightGrayColor];
  }
  
  return self;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
  [super applyLayoutAttributes:layoutAttributes];
  
  self.frame = layoutAttributes.frame;
  
}

@end