//
//  DMParser.h
//  Dictionary Maker
//
//  Created by Alice on 8/14/16.
//

#import <Foundation/Foundation.h>

@interface DMParser : NSObject

typedef NS_ENUM(NSInteger, DMParsingMode)
{
	DMPronunciationParsing,
	DMSearchTermsParsing,
	DMAddendumsParsing,
	DMDefinitionsParsing
};

typedef NS_ENUM(NSInteger, DMDataType)
{
	DMPronunciationType,
	DMSearchTermsType,
	DMAddendumsType,
	DMDefinitionsType
};

typedef NS_ENUM(NSInteger, DMParserError)
{
	DMMissingSeparator
};

/**
 Creates an NSXMLElement that includes attributes and child elements based upon a data string given to it. Returns nil
 if the string is not parsable.
 */
- (NSArray * _Nonnull)elementsByParsingString:(NSString * _Nonnull)stringToParse usingMode:(DMParsingMode)mode;

/**
 Creates an NSString with formatting created by using data from an NSXMLElement tree.
 */
- (NSString * _Nonnull)renderedStringFromElementTree:(NSXMLElement * _Nonnull)elementTree ofType:(DMDataType)type;

/**
 Checks whether a data string is parsable to a certain type. Useful when you want to check a string before
 sending it to the parser.
 
 @return YES if the string is parsable, NO if otherwise.
 */
- (BOOL)checkDataStringSymantics:(NSString * _Nonnull)string ofType:(DMDataType)type error:(NSError * _Null_unspecified * _Nullable)parsingError;

@end
