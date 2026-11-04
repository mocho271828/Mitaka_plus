#pragma once

#import <Foundation/Foundation.h>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <limits>
#include <string>

namespace mitaka::gui {
inline bool sameSessionSmokeJSONValue(id actual, id expected) {
    if ([actual isKindOfClass:NSNumber.class] && [expected isKindOfClass:NSNumber.class]) {
        const bool actualBoolean = CFGetTypeID((__bridge CFTypeRef)actual) == CFBooleanGetTypeID();
        const bool expectedBoolean = CFGetTypeID((__bridge CFTypeRef)expected) == CFBooleanGetTypeID();
        if (actualBoolean || expectedBoolean)
            return actualBoolean && expectedBoolean && [actual boolValue] == [expected boolValue];
        const double a = [actual doubleValue], b = [expected doubleValue];
        // Foundation の JSON 数値変換は最下位ビットが変わるため、表現だけの差を除く。
        return std::abs(a-b) <= 4 * std::numeric_limits<double>::epsilon() * std::max(std::abs(a), std::abs(b));
    }
    if ([actual isKindOfClass:NSArray.class] && [expected isKindOfClass:NSArray.class]) {
        if ([actual count] != [expected count]) return false;
        for (NSUInteger i = 0; i < [actual count]; ++i)
            if (!sameSessionSmokeJSONValue(actual[i], expected[i])) return false;
        return true;
    }
    if ([actual isKindOfClass:NSDictionary.class] && [expected isKindOfClass:NSDictionary.class]) {
        if ([actual count] != [expected count]) return false;
        for (NSString *key in expected)
            if (!sameSessionSmokeJSONValue(actual[key], expected[key])) return false;
        return true;
    }
    return [actual isEqual:expected];
}
inline bool sameSessionSmokeJSON(const std::string& actual, const std::string& expected) {
    if (actual == expected) return true;
    const auto object = [](const std::string& value) {
        return (NSDictionary *)[NSJSONSerialization JSONObjectWithData:
            [NSData dataWithBytes:value.data() length:value.size()] options:0 error:nil];
    };
    NSDictionary *actualObject = object(actual), *expectedObject = object(expected);
    const bool same = sameSessionSmokeJSONValue(actualObject, expectedObject);
    for (NSString *key in expectedObject)
        if (!sameSessionSmokeJSONValue(actualObject[key], expectedObject[key]))
            std::fprintf(stderr, "Session mismatch %s: expected %s, actual %s\n", key.UTF8String,
                [expectedObject[key] description].UTF8String, [actualObject[key] description].UTF8String);
    return same;
}
} // namespace mitaka::gui
