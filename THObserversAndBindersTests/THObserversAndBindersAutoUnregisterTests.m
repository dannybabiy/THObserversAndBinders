//
//  THObserversAndBindersAutoUnregisterTests.m
//  THObserversAndBinders
//
//  Created by Yan Rabovik on 20.07.13.
//  Copyright (c) 2013 James Montgomerie. All rights reserved.
//

#import "THObserver.h"
#import "THObserver_Private.h"
#import "THBinder.h"
#import "THObserversAndBindersAutoUnregisterTests.h"

/*
 We run `p RSDHTestsIncrementKVOLeakCounter()` on `NSKVODeallocateBreak` exception
 to make automatic tests of successfull KVO unregistering.
 */
static NSUInteger KVOLeakCounter = 0;
void RSDHTestsIncrementKVOLeakCounter(){
    ++KVOLeakCounter;
}

@interface THBinder (){
    @public
    THObserver *_observer;
}
@end

@interface NSObjectSubclass : NSObject
@end

@implementation NSObjectSubclass
@end

@implementation THObserversAndBindersAutoUnregisterTests{
}

#pragma mark - KVO leak check
-(void)makeKVOLeak{
    id __attribute__((objc_precise_lifetime)) observer = [NSObject new];
    @autoreleasepool {
        id x = [NSObject new];
        [x addObserver:observer forKeyPath:@"test" options:0 context:NULL];
    }
}

-(void)testKVOLeak{
    KVOLeakCounter = 0;
    [self makeKVOLeak];
    STAssertTrue(1 == KVOLeakCounter, @"Tests must be run with NSKVODeallocateBreak breakpoint.");
}

#pragma mark - Observers

-(void)testStopObservingEnablesObservingStoppedProperty
{
    id __attribute__((objc_precise_lifetime)) object = [NSObject new];
    THObserver *observer = [THObserver observerForObject:object keyPath:@"testKey" block:^{}];
    STAssertFalse(observer.observingStopped, nil);
    [observer stopObserving];
    STAssertTrue(observer.observingStopped, nil);
}

-(void)testStopObservingCalledOnObservedObjectDies
{
    KVOLeakCounter = 0;
    THObserver *observer = nil;
    @autoreleasepool {
        id object = [[NSObject alloc] init];
        observer = [THObserver observerForObject:object keyPath:@"testKey" block:^{}];
        NSLog(@"↓↓↓↓↓↓↓↓↓ There sould be no `KVO leak` statement below ↓↓↓↓↓↓↓↓↓");
    }
    NSLog(@"↑↑↑↑↑↑↑↑↑ There sould be no `KVO leak` statement above ↑↑↑↑↑↑↑↑↑");
    STAssertTrue(0 == KVOLeakCounter, @"There was a KVO leak.");
    STAssertTrue(observer.observingStopped, @"StopObserving was not called");
}

- (void)testPlainChangeReleasingObservedDictionary
{
    KVOLeakCounter = 0;
    THObserver *observer = nil;
    __weak id weakObject;
    @autoreleasepool {
        // We can not use empty dictionary [[NSDictionary alloc] init] in this test,
        // because it acts like a singleton and never deallocated
        id object = [NSDictionary dictionaryWithObject:@"testObject" forKey:@"testKey"];
        weakObject = object;
        observer = [THObserver observerForObject:object keyPath:@"testKey" block:^{}];
        NSLog(@"↓↓↓↓↓↓↓↓↓ There sould be no `KVO leak` statement below ↓↓↓↓↓↓↓↓↓");
    }
    NSLog(@"↑↑↑↑↑↑↑↑↑ There sould be no `KVO leak` statement above ↑↑↑↑↑↑↑↑↑");
    STAssertTrue(0 == KVOLeakCounter, @"There was a KVO leak.");
    STAssertNil(weakObject, @"Dictionary was not deallocated!");
    STAssertTrue(observer.observingStopped, @"StopObserving was not called");
}

- (void)testPlainChangeReleasingObservedNSObjectSubclass
{
    KVOLeakCounter = 0;
    THObserver *observer = nil;
    @autoreleasepool {
        id object = [[NSObjectSubclass alloc] init];
        observer = [THObserver observerForObject:object keyPath:@"testKey" block:^{}];
        NSLog(@"↓↓↓↓↓↓↓↓↓ There sould be no `KVO leak` statement below ↓↓↓↓↓↓↓↓↓");
    }
    NSLog(@"↑↑↑↑↑↑↑↑↑ There sould be no `KVO leak` statement above ↑↑↑↑↑↑↑↑↑");
    STAssertTrue(0 == KVOLeakCounter, @"There was a KVO leak.");
    STAssertTrue(observer.observingStopped, @"StopObserving was not called");
}

-(void)testStopObservingCalledOnTargetDies
{
    THObserver *observer;
    NSObject *observedObject = [NSObject new];
    @autoreleasepool {
        id target = [NSObject new];
        observer = [THObserver observerForObject:observedObject
                                         keyPath:@"testKey"
                                          target:target
                                          action:@selector(testStopObservingCalledOnTargetDies)];
    }
    STAssertTrue(observer.observingStopped, @"StopObserving was not called");
}

-(void)testSameTargetAndObservedObject
{
    KVOLeakCounter = 0;
    THObserver *observer;
    @autoreleasepool {
        id object = [NSObject new];
        observer = [THObserver observerForObject:object
                                         keyPath:@"testKey"
                                          target:object
                                          action:@selector(testSameTargetAndObservedObject)];
        NSLog(@"↓↓↓↓↓↓↓↓↓ There sould be no `KVO leak` statement below ↓↓↓↓↓↓↓↓↓");
    }
    NSLog(@"↑↑↑↑↑↑↑↑↑ There sould be no `KVO leak` statement above ↑↑↑↑↑↑↑↑↑");
    STAssertTrue(0 == KVOLeakCounter, @"There was a KVO leak.");
    STAssertTrue(observer.observingStopped, @"StopObserving was not called");
}

#pragma mark - Bindings

-(void)testStopBindingNilsBlockIvar
{
    THBinder *binder = [THBinder binderFromObject:[NSObject new]
                                          keyPath:@"testKey"
                                         toObject:[NSObject new]
                                          keyPath:@"testKey"];
    THObserver *observer = binder->_observer;
    STAssertNotNil(observer, nil);
    [binder stopBinding];
    STAssertTrue(observer.observingStopped, @"StopObserving was not called");
}

-(void)testStopObservingCalledOnBindFromObjectDies
{
    KVOLeakCounter = 0;
    THBinder *binder;
    THObserver *observer;
    NSObject *testTo = [NSObject new];
    @autoreleasepool {
        NSObject *testFrom = [NSObject new];
        binder = [THBinder binderFromObject:testFrom
                                    keyPath:@"testKey"
                                   toObject:testTo
                                    keyPath:@"testKey"];
        observer = binder->_observer;
        NSLog(@"↓↓↓↓↓↓↓↓↓ There sould be no `KVO leak` statement below ↓↓↓↓↓↓↓↓↓");
    }
    NSLog(@"↑↑↑↑↑↑↑↑↑ There sould be no `KVO leak` statement above ↑↑↑↑↑↑↑↑↑");
    STAssertTrue(0 == KVOLeakCounter, @"There was a KVO leak.");
    STAssertTrue(observer.observingStopped, @"StopObserving was not called");
}

-(void)testStopObservingCalledOnBindToObjectDies
{
    THBinder *binder;
    THObserver *observer;
    NSObject *testFrom = [NSObject new];
    @autoreleasepool {
        NSObject *testTo = [NSObject new];
        binder = [THBinder binderFromObject:testFrom
                                    keyPath:@"testKey"
                                   toObject:testTo
                                    keyPath:@"testKey"];
        observer = binder->_observer;
    }
    STAssertTrue(observer.observingStopped, @"StopObserving was not called");
}

-(void)testSameBindToAndBindFromObjects
{
    KVOLeakCounter = 0;
    THBinder *binder;
    THObserver *observer;
    @autoreleasepool {
        NSObject *testObject = [NSObject new];
        binder = [THBinder binderFromObject:testObject
                                    keyPath:@"testKey1"
                                   toObject:testObject
                                    keyPath:@"testKey2"];
        observer = binder->_observer;
        NSLog(@"↓↓↓↓↓↓↓↓↓ There sould be no `KVO leak` statement below ↓↓↓↓↓↓↓↓↓");
    }
    NSLog(@"↑↑↑↑↑↑↑↑↑ There sould be no `KVO leak` statement above ↑↑↑↑↑↑↑↑↑");
    STAssertTrue(0 == KVOLeakCounter, @"There was a KVO leak.");
    STAssertTrue(observer.observingStopped, @"StopObserving was not called");
}

@end
