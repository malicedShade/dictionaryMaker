//
//  DMParser.m
//  Dictionary Maker
//
//  Created by Alice on 8/14/16.
//

#import "DMParser.h"

@implementation DMParser

- (NSArray *)elementsByParsingString:(NSString *)stringToParse usingMode:(DMParsingMode)mode
{
	NSMutableArray *newElements = [[NSMutableArray alloc] init];
	DMDataType type;
	
	if(mode == DMPronunciationParsing)
	{
		type = DMPronunciationType;
	}
	else if(mode == DMSearchTermsParsing)
	{
		type = DMSearchTermsType;
	}
	else if(mode == DMAddendumsParsing)
	{
		type = DMAddendumsType;
	}
	else if(mode == DMDefinitionsParsing)
	{
		type = DMDefinitionsType;
	}
	
	BOOL stringIsProper = [self checkDataStringSymantics:stringToParse ofType:type error:nil];
	
	if(stringIsProper == YES)
	{
		switch(mode)
		{
			case DMPronunciationParsing:
			{
				
				break;
			}
			case DMSearchTermsParsing:
			{
				NSArray *separatedComponents = [stringToParse componentsSeparatedByString:@"\n"];
				
				for(NSInteger i = 0; i < separatedComponents.count; i++)
				{
					NSXMLElement *index = [NSXMLElement elementWithName:@"d:index"];
					NSXMLNode *valueAttribute = [NSXMLNode attributeWithName:@"d:value" stringValue:[separatedComponents objectAtIndex:i]];
					
					[index addAttribute:valueAttribute];
					[newElements addObject:index];
				}
				
				break;
			}
			case DMAddendumsParsing:
			{
				break;
			}
			case DMDefinitionsParsing:
			{
				NSMutableArray *definitions = (NSMutableArray *)[stringToParse componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
				NSXMLElement *div = [NSXMLElement elementWithName:@"div"];
				NSXMLElement *orderedList = [NSXMLElement elementWithName:@"ol"];
				
				// The first object will always end up being empty.
				[definitions removeObjectAtIndex:0];
	
				for(NSInteger i = 0; i < definitions.count; i++)
				{
					NSMutableString *currentDefinition = [[NSMutableString alloc] initWithString:[definitions objectAtIndex:i]];
					NSMutableString *xmlString = [[NSMutableString alloc] initWithString:@"<li>"];
					
					// There's a period we need to remove.
					[currentDefinition replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
	
					NSArray *definitionAndExamples = [currentDefinition componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
					
					// The first object will always be a definition, all subsequent objects will be examples.
					
					for(NSInteger x = 0; x < definitionAndExamples.count; x++)
					{
						NSMutableString *currentComponent = [[NSMutableString alloc] initWithString:[definitionAndExamples objectAtIndex:x]];
						BOOL escaping = NO;
						
						for(NSInteger y = 0; y < currentComponent.length; y++)
						{
							unichar currentChar = [currentComponent characterAtIndex:y];
							
							if(escaping == NO)
							{
								if(currentChar == '\\')
								{
									escaping = YES;
								}
								
								if(currentChar == '{')
								{
									[currentComponent replaceCharactersInRange:NSMakeRange(y, 1) withString:@"<i>"];
								}
								
								if(currentChar == '}')
								{
									[currentComponent replaceCharactersInRange:NSMakeRange(y, 1) withString:@"</i>"];
								}
								
								if(currentChar == '[')
								{
									[currentComponent replaceCharactersInRange:NSMakeRange(y, 1) withString:@"<b>"];
								}
								
								if(currentChar == ']')
								{
									[currentComponent replaceCharactersInRange:NSMakeRange(y, 1) withString:@"</b>"];
								}
							}
							else
							{
								if(currentChar == '\\')
								{
									[currentComponent replaceCharactersInRange:NSMakeRange((y - 1), 2) withString:@"\\"];
								}
								
								if(currentChar == '{')
								{
									[currentComponent replaceCharactersInRange:NSMakeRange((y - 1), 2) withString:@"{"];
								}
								
								if(currentChar == '}')
								{
									[currentComponent replaceCharactersInRange:NSMakeRange((y - 1), 2) withString:@"}"];
								}
								
								if(currentChar == '[')
								{
									[currentComponent replaceCharactersInRange:NSMakeRange((y - 1), 2) withString:@"["];
								}
								
								if(currentChar == ']')
								{
									[currentComponent replaceCharactersInRange:NSMakeRange((y - 1), 2) withString:@"]"];
								}
								
								if(currentChar == '.')
								{
									[currentComponent replaceCharactersInRange:NSMakeRange((y - 1), 2) withString:@"."];
								}
								
								escaping = NO;
							}
						}
						
						[xmlString appendString:currentComponent];
						
						if(i != definitionAndExamples.count)
						{
							[xmlString appendString:@"<br />"];
						}
					}
					
					[xmlString appendString:@"</li>"];
					
					NSXMLElement *listItem = [[NSXMLElement alloc] initWithXMLString:xmlString error:nil];
					
					[orderedList addChild:listItem];
				}
				
				[div addChild:orderedList];
				[newElements addObject:div];
				
				break;
			}
			default:
			{
				break;
			}
		}
	}
	
	return (NSArray *)newElements;
}

- (NSString *)renderedStringFromElementTree:(NSXMLElement *)elementTree ofType:(DMDataType)type
{
	switch(type)
	{
		case DMPronunciationType:
			
			break;
			
		case DMSearchTermsType:
			
			break;
			
		case DMAddendumsType:
			
			break;
			
		case DMDefinitionsType:
			
			break;
			
		default:
			
			break;
	}
	
	return @"NEED OVERRIDE.";
}

- (BOOL)checkDataStringSymantics:(NSString *)string ofType:(DMDataType)type error:(NSError *__autoreleasing *)parsingError
{
	BOOL stringIsCorrect = NO;
	
	typedef NS_ENUM(NSInteger, DMCurrentlyParsingType)
	{
		DMDeclaration,
		DMDefinition,
		DMExample
	};
	
	switch(type)
	{
		case DMPronunciationType:
		{
			break;
		}
		case DMSearchTermsType:
		{
			stringIsCorrect = YES;
			break;
		}
		case DMAddendumsType:
		{
			break;
		}
		case DMDefinitionsType:
		{
			BOOL expectsSeparator = NO;
			BOOL expectsExampleOrNextDefinition = NO;
			BOOL expectsEscapedChar = NO;
			BOOL ranIntoError = NO;
			BOOL expectsClosingGroupCharBRACE = NO;
			BOOL expectsOpeningGroupCharBRACE = NO;
			BOOL expectsClosingGroupCharBRACKET = NO;
			BOOL expectsOpeningGroupCharBRACKET = NO;
			DMCurrentlyParsingType currentlyParsing = DMDeclaration;
			
			for(NSInteger i = 0; i < string.length; i++)
			{
				unichar currentChar = [string characterAtIndex:i];
				NSCharacterSet *escapeCharSet = [NSCharacterSet characterSetWithCharactersInString:@"{}[]\\.1234567890"];
				
				if(i == 0)
				{
					if(![[NSCharacterSet decimalDigitCharacterSet] characterIsMember:currentChar])
					{
						ranIntoError = YES;
						break;
					}
					else
					{
						expectsSeparator = YES;
						currentlyParsing = DMDeclaration;
					}
				}
				else if(i < string.length)
				{
					if(expectsSeparator == YES)
					{
						if(currentChar != '.')
						{
							ranIntoError = YES;
							break;
						}
						else
						{
							expectsSeparator = NO;
						}
					}
					else
					{
						currentlyParsing = DMDefinition;
						
						if(currentChar == '.' && expectsEscapedChar == NO)
						{
							ranIntoError = YES;
							break;
						}
					}
					
					if(expectsExampleOrNextDefinition == YES)
					{
						if([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:currentChar])
						{
							currentlyParsing = DMDeclaration;
							expectsSeparator = YES;
						}
						else if([[NSCharacterSet letterCharacterSet] characterIsMember:currentChar])
						{
							currentlyParsing = DMExample;
						}
						
						expectsExampleOrNextDefinition = NO;
					}
					
					if(expectsEscapedChar == YES)
					{
						if(![escapeCharSet characterIsMember:currentChar])
						{
							ranIntoError = YES;
							break;
						}
						
						expectsEscapedChar = NO;
					}
					else
					{
						if(currentlyParsing != DMDeclaration)
						{
							if([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:currentChar])
							{
								ranIntoError = YES;
								break;
							}
						}
						
						if(currentChar == '{')
						{
							expectsClosingGroupCharBRACE = YES;
						}
						
						if(currentChar == '[')
						{
							expectsClosingGroupCharBRACKET = YES;
						}
						
						if(currentChar == '}')
						{
							if(expectsClosingGroupCharBRACE == YES)
							{
								expectsClosingGroupCharBRACE = NO;
							}
							else
							{
								expectsOpeningGroupCharBRACE = YES;
							}
						}
						
						if(currentChar == ']')
						{
							if(expectsClosingGroupCharBRACKET == YES)
							{
								expectsClosingGroupCharBRACKET = NO;
							}
							else
							{
								expectsOpeningGroupCharBRACKET = YES;
							}
						}
					}
					if(currentChar == '\n')
					{
						expectsExampleOrNextDefinition = YES;
					}
					
					if(currentChar == '\\')
					{
						if(i == string.length)
						{
							ranIntoError = YES;
							break;
						}
						else
						{
							expectsEscapedChar = YES;
						}
					}
				}
			}
			
			if(ranIntoError == NO)
			{
				stringIsCorrect = YES;
			}
			
			if(expectsClosingGroupCharBRACE == YES)
			{
				stringIsCorrect = NO;
			}
			
			if(expectsOpeningGroupCharBRACE == YES)
			{
				stringIsCorrect = NO;
			}
			
			if(expectsClosingGroupCharBRACKET == YES)
			{
				stringIsCorrect = NO;
			}
			
			if(expectsOpeningGroupCharBRACKET == YES)
			{
				stringIsCorrect = NO;
			}
			
			break;
		}
		default:
		{
			break;
		}
	}
	
	if(stringIsCorrect == NO)
	{
		// Set error stuff.
	}
	
	return stringIsCorrect;
}

@end
