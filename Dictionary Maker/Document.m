//
//  Document.m
//  Dictionary Maker
//
//  Created by Alice on 8/11/16.
//

#import "Document.h"

@interface Document()

@property (strong) NSXMLNode *namespace;
@property (strong) NSXMLNode *namespaceDTD;
@property NSInteger selectionIndex;

@end

@implementation Document

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
	
    if (self)
	{
		// Add your subclass-specific initialization here.
		_parser = [[DMParser alloc] init];
		_namespace = [NSXMLNode namespaceWithName:@"" stringValue:@"http://www.w3.org/1999/xhtml"];
		_namespaceDTD = [NSXMLNode namespaceWithName:@"d" stringValue:@"http://www.apple.com/DTDs/DictionaryService-1.0.rng"];
		//NSString *dictionaryName = [NSString stringWithFormat:@"%@:dictionary", _namespaceDTD.URI];
		NSXMLElement *root = [[NSXMLElement alloc] initWithName:@"d:dictionary"];
		
		[root addNamespace:_namespace];
		[root addNamespace:_namespaceDTD];
		
		_theXMLDocument = [[NSXMLDocument alloc] initWithRootElement:root];
		
		[_theXMLDocument setVersion:@"1.0"];
		[_theXMLDocument setCharacterEncoding:@"UTF-8"];
		[self setSelectionIndex:-1];
		NSLog(@"%@", [_theXMLDocument XMLStringWithOptions:NSXMLNodePrettyPrint]);
    }
	
    return self;
}

#pragma mark - NSDocument

+ (BOOL)autosavesInPlace
{
	return YES;
}

- (NSString *)windowNibName
{
	// Override returning the nib file name of the document
	// If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
	return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
	[_entryTable setDelegate:self];
	[_entryTable setDataSource:self];
	[_wordField setDelegate:self];
	[_pronunciationTextView setDelegate:self];
	[_searchTermsTextView setDelegate:self];
	[_addendumsTextView setDelegate:self];
	[_definitionsTextView setDelegate:self];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	// Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
	// You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
	
	NSData *saveFile = [[NSData alloc] initWithData:[_theXMLDocument XMLDataWithOptions:NSXMLNodePrettyPrint|NSXMLNodePreserveAll]];
	
	[_entryTable reloadData];
	
	// Disable undo registration.
	
	if(!saveFile && outError)
	{
		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
	}
	
	return saveFile;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	// Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
	// You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
	// If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
	
	BOOL readSuccess = NO;
	NSXMLDocument *fileContents = [[NSXMLDocument alloc] initWithData:data options:NSXMLNodePreserveAll	error:outError];
	
	if(![fileContents.rootElement.name isEqualToString:@"d:dictionary"])
	{
		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
	}
	
	if(!fileContents && outError)
	{
		*outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
	}
	
	if(fileContents)
	{
		readSuccess = YES;
		[self setTheXMLDocument:fileContents];
		[self applyXMLToUI];
	}
	
	return readSuccess;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSTableCellView *cellView = [_entryTable makeViewWithIdentifier:@"entryView" owner:self];
	NSXMLElement *currentElement = [[_theXMLDocument.rootElement elementsForName:@"d:entry"] objectAtIndex:row];
	NSString *entryString = [currentElement attributeForName:@"d:title"].stringValue;
	
	[cellView.textField setStringValue:entryString];
	
	return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self setSelectionIndex:_entryTable.selectedRow];
	[self applyXMLToUI];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [_theXMLDocument.rootElement elementsForName:@"d:entry"].count;
}

#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	BOOL shouldEnd = NO;
	
	if(control == _wordField)
	{
		if(![_wordField.stringValue isEqualToString:@""])
		{
			NSArray *entries = [_theXMLDocument.rootElement elementsForName:@"d:entry"];
			NSMutableArray *words = [[NSMutableArray alloc] init];
			BOOL duplicatesExist = NO;
			
			for(NSInteger i = 0; i < entries.count; i++)
			{
				NSXMLElement *currentEntry = [entries objectAtIndex:i];
				
				[words addObject:[currentEntry attributeForName:@"id"].stringValue];
			}
			
			for(NSInteger i = 0; i < words.count; i++)
			{
				NSString *currentWord = [words objectAtIndex:i];
				
				if([currentWord isEqualToString:_wordField.stringValue])
				{
					duplicatesExist = YES;
				}
			}
			
			if(duplicatesExist == NO)
			{
				shouldEnd = YES;
			}
		}
		else
		{
			shouldEnd = NO;
			NSAlert *emptyWordAlert = [[NSAlert alloc] init];
			
			[emptyWordAlert addButtonWithTitle:@"OK"];
			[emptyWordAlert setMessageText:@"Words cannot be empty."];
			[emptyWordAlert setInformativeText:@"Please provide a value for this word."];
			[emptyWordAlert setAlertStyle:NSWarningAlertStyle];
			[emptyWordAlert runModal];
		}
	}
	
	return shouldEnd;
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
	[self.undoManager registerUndoWithTarget:self selector:@selector(updateDocument:) object:[_theXMLDocument copy]];
	[self.undoManager setActionName:@"Edit"];
	
	NSArray *entries = [_theXMLDocument.rootElement elementsForName:@"d:entry"];
	
	if(entries.count > 0)
	{
		if(_wordField == [obj object])
		{
			NSXMLElement *currentEntry = [entries objectAtIndex:_selectionIndex];
			NSXMLNode *idAttribute = [currentEntry attributeForName:@"id"];
			NSXMLNode *title = [currentEntry attributeForName:@"d:title"];
			
			[idAttribute setStringValue:_wordField.stringValue];
			[title setStringValue:_wordField.stringValue];
			[_entryTable reloadData];
		}
	}
}

# pragma mark - NSTextDelegate

- (void)textDidChange:(NSNotification *)notification
{
	[self.undoManager registerUndoWithTarget:self selector:@selector(updateDocument:) object:[_theXMLDocument copy]];
	[self.undoManager setActionName:@"Edit"];
	
	if([notification object] == _pronunciationTextView)
	{
		BOOL isCorrect = [_parser checkDataStringSymantics:_pronunciationTextView.textStorage.string ofType:DMPronunciationType error:nil];
		
		if(isCorrect == YES)
		{
			[_pronunciationTextView setTextColor:[NSColor blackColor] range:NSMakeRange(0, _pronunciationTextView.textStorage.length)];
			
			//NSArray *newSpans = [_parser elementsByParsingString:_pronunciationTextView.textStorage.string usingMode:DMPronunciationParsing];
		}
		else
		{
			[_pronunciationTextView setTextColor:[NSColor redColor] range:NSMakeRange(0, _pronunciationTextView.textStorage.length)];
		}
	}
	else if([notification object] == _searchTermsTextView)
	{
		BOOL isCorrect = [_parser checkDataStringSymantics:_searchTermsTextView.textStorage.string ofType:DMSearchTermsType error:nil];
		
		if(isCorrect == YES)
		{
			[_searchTermsTextView setTextColor:[NSColor blackColor] range:NSMakeRange(0, _searchTermsTextView.textStorage.length)];
			
			NSArray *newIndecies = [_parser elementsByParsingString:[_searchTermsTextView.textStorage.string copy]
														  usingMode:DMSearchTermsParsing];
			NSXMLElement *currentEntry = [[_theXMLDocument.rootElement elementsForName:@"d:entry"] objectAtIndex:_selectionIndex];
			NSArray *oldIndecies = [currentEntry elementsForName:@"d:index"];
			
			if(oldIndecies.count > 0)
			{
				for(NSInteger i = 0; i < oldIndecies.count; i++)
				{
					NSUInteger oldIndexIndex = [[oldIndecies objectAtIndex:i] index];
					
					[currentEntry removeChildAtIndex:oldIndexIndex];
				}
			}
			
			if(newIndecies.count != 0)
			{
				[currentEntry insertChildren:newIndecies atIndex:0];
			}
		}
		else
		{
			[_searchTermsTextView setTextColor:[NSColor redColor] range:NSMakeRange(0, _searchTermsTextView.textStorage.length)];
		}
	}
	else if([notification object] == _addendumsTextView)
	{
		BOOL isCorrect = [_parser checkDataStringSymantics:_addendumsTextView.textStorage.string ofType:DMAddendumsType error:nil];
		
		if(isCorrect == YES)
		{
			[_addendumsTextView setTextColor:[NSColor blackColor] range:NSMakeRange(0, _addendumsTextView.textStorage.length)];
			
			//NSArray *newSpans = [_parser elementsByParsingString:_addendumsTextView.textStorage.string usingMode:DMAddendumsParsing];
		}
		else
		{
			[_addendumsTextView setTextColor:[NSColor redColor] range:NSMakeRange(0, _addendumsTextView.textStorage.length)];
		}
	}
	else if([notification object] == _definitionsTextView)
	{
		BOOL isCorrect = [_parser checkDataStringSymantics:_definitionsTextView.textStorage.string ofType:DMDefinitionsType error:nil];
		
		if(isCorrect == YES)
		{
			[_definitionsTextView setTextColor:[NSColor blackColor] range:NSMakeRange(0, _definitionsTextView.textStorage.length)];
			
			NSArray *elements = [_parser elementsByParsingString:_definitionsTextView.textStorage.string usingMode:DMDefinitionsParsing];
			NSXMLElement *newDiv = elements.firstObject;
			NSXMLElement *currentEntry = [[_theXMLDocument.rootElement elementsForName:@"d:entry"] objectAtIndex:_selectionIndex];
			NSInteger oldDivIndex = [[currentEntry elementsForName:@"div"].firstObject index];
			
			[currentEntry replaceChildAtIndex:oldDivIndex withNode:newDiv];
		}
		else
		{
			[_definitionsTextView setTextColor:[NSColor redColor] range:NSMakeRange(0, _definitionsTextView.textStorage.length)];
		}
	}
	
	NSLog(@"%@", [_theXMLDocument XMLStringWithOptions:NSXMLNodePrettyPrint]);
}

#pragma mark - Actions

/// Gets values from the XML and updates the interface.
- (void)applyXMLToUI
{
	NSArray *entries = [_theXMLDocument.rootElement elementsForName:@"d:entry"];
	
	if(entries.count > 0 && _selectionIndex >= 0)
	{
		NSXMLElement *currentEntry = [entries objectAtIndex:_selectionIndex];
		NSString *word = [currentEntry attributeForName:@"d:title"].stringValue;
		NSArray *indexArray = [currentEntry elementsForName:@"d:index"];
		NSMutableString *searchTerms = [[NSMutableString alloc] init];
		NSXMLElement *definitionsDiv = [currentEntry elementsForName:@"div"].firstObject;
		NSXMLElement *definitionsOrderedList = [definitionsDiv elementsForName:@"ol"].firstObject;
		NSArray *definitions = [definitionsOrderedList elementsForName:@"li"];
		NSMutableArray *spans = (NSMutableArray *)[currentEntry elementsForName:@"spans"];
		NSMutableString *definitionsString = [[NSMutableString alloc] init];
		
		// Set the word field.
		[_wordField setStringValue:word];
		
		// Set the search terms.
		for(NSInteger i = 0; i < indexArray.count; i++)
		{
			NSString *indexString = [[indexArray objectAtIndex:i] attributeForName:@"d:value"].stringValue;
			NSString *appendedString = [NSString stringWithFormat:@"%@", indexString];
			
			if(![appendedString isEqualToString:@""] || ![appendedString isEqualToString:@"(null)"])
			{
				[searchTerms appendString:appendedString];
				
				if(i != indexArray.count)
				{
					[searchTerms appendString:@"\n"];
				}
			}
		}
		
		NSAttributedString *searchTermsText = [[NSAttributedString alloc] initWithString:searchTerms];
		
		[_searchTermsTextView.textStorage setAttributedString:searchTermsText];
		
		// Set the pronunciation symbols.
		NSXMLElement *pronunciationSpan;
		
		for(NSInteger i = 0; i < spans.count; i++)
		{
			NSXMLElement *currentSpan = [spans objectAtIndex:i];
			NSXMLNode *classElement = [currentSpan attributeForName:@"class"];
			
			if(classElement != nil)
			{
				pronunciationSpan = currentSpan;
				break;
			}
		}
		
		// Set the addendums.
		
		// Here you'll need to scan the entries to see if propsed addendums are already present. If they're not then create them here.
		
		// Set the definitions.
		
		for(NSInteger i = 0; i < definitions.count; i++)
		{
			NSXMLElement *currentDefinition = [definitions objectAtIndex:i];
			NSArray *strungOutDefinition = [currentDefinition.stringValue componentsSeparatedByString:@"\n"];
			NSString *currentNumber = [NSString stringWithFormat:@"%li.", (i + 1)];
			
			[definitionsString appendString:currentNumber];
			
			for(NSInteger x = 0; x < strungOutDefinition.count; x++)
			{
				NSString *currentPartOfDefinition = [NSString stringWithFormat:@"%@", [strungOutDefinition objectAtIndex:x]];
				
				[definitionsString appendString:currentPartOfDefinition];
				
				if(x != strungOutDefinition.count)
				{
					[definitionsString appendString:@"\n"];
				}
			}
			
			if(i != definitions.count)
			{
				[definitionsString appendString:@"\n"];
			}
		}
		
		NSAttributedString *definitionsText = [[NSAttributedString alloc] initWithString:(NSString *)definitionsString];
		
		[_definitionsTextView.textStorage setAttributedString:definitionsText];
	}
	else
	{
		NSAttributedString *emptyAttributedString = [[NSAttributedString alloc] initWithString:@""];
		
		[_wordField setStringValue:@""];
		[_searchTermsTextView.textStorage setAttributedString:emptyAttributedString];
		[_pronunciationTextView.textStorage setAttributedString:emptyAttributedString];
		[_addendumsTextView.textStorage setAttributedString:emptyAttributedString];
		[_definitionsTextView.textStorage setAttributedString:emptyAttributedString];
	}
}

- (IBAction)removeCurrentEntry:(id)sender
{
	[self.undoManager registerUndoWithTarget:self selector:@selector(updateDocument:) object:[_theXMLDocument copy]];
	[self.undoManager setActionName:@"Edit"];
	
	if(_selectionIndex == -1)
	{
		NSBeep();
	}
	else
	{
		[_theXMLDocument.rootElement removeChildAtIndex:_selectionIndex];
	}
	
	NSLog(@"%@", [_theXMLDocument XMLStringWithOptions:NSXMLNodePrettyPrint]);
	[_entryTable reloadData];
}

- (IBAction)addNewEntry:(id)sender
{
	[self createNewEntry:@""];
}

- (IBAction)insertAddendums:(id)sender
{
	[self.undoManager registerUndoWithTarget:self selector:@selector(updateDocument:) object:[_theXMLDocument copy]];
	[self.undoManager setActionName:@"Edit"];
	
	NSString *word = _wordField.stringValue;
	
	if(![word isEqualToString:@""])
	{
		NSArray *suffixes = [_addendumsTextView.textStorage.string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		NSArray *entries = [_theXMLDocument.rootElement elementsForName:@"d:entry"];
		NSMutableArray *words = [[NSMutableArray alloc] init];
		NSMutableArray *newWords = [[NSMutableArray alloc] init];
		
		// Create the wordlist.
		for(NSInteger i = 0; i < entries.count; i++)
		{
			NSXMLElement *currentEntry = [entries objectAtIndex:i];
			
			[words addObject:[currentEntry attributeForName:@"id"].stringValue];
		}
		
		// Assemble the new words.
		for(NSInteger i = 0; i < suffixes.count; i++)
		{
			NSMutableString *newWord = [[NSMutableString alloc] init];
			NSString *currentSuffix = [suffixes objectAtIndex:i];
			
			if(![currentSuffix isEqualToString:@""])
			{
				[newWord appendString:word];
				[newWord appendString:currentSuffix];
			}
			
			if(![newWord isEqualToString:@""])
			{
				[newWords addObject:newWord];
			}
		}
		
		// Search for the words; If they don't exist then add them to the document.
		for(NSInteger i = 0; i < newWords.count; i++)
		{
			NSString *currentNewWord = [newWords objectAtIndex:i];
			NSInteger copies = 0;
			
			for(NSInteger x = 0; x < words.count; x++)
			{
				NSString *currentOldWord = [words objectAtIndex:x];
				
				if([currentNewWord isEqualToString:currentOldWord])
				{
					copies++;
				}
			}
			
			if(copies == 0)
			{
				[self createNewEntry:currentNewWord];
			}
		}
	}
}

- (IBAction)importFile:(id)sender
{
	[self.undoManager registerUndoWithTarget:self selector:@selector(updateDocument:) object:[_theXMLDocument copy]];
	[self.undoManager setActionName:@"Edit"];
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSArray *allowedFileTypes = [[NSArray alloc] initWithObjects:@"public.text", nil];
	
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setAllowedFileTypes:allowedFileTypes];
	
	if([openPanel runModal] == NSFileHandlingPanelOKButton)
	{
		NSURL *selectedFile = openPanel.URLs.firstObject;
		
		NSString *file = [NSString stringWithContentsOfURL:selectedFile
												  encoding:NSUTF8StringEncoding
													 error:nil];
		NSArray *splitContents = [file componentsSeparatedByString:@"\n"];
		
		for(NSInteger i = 0; i < splitContents.count; i++)
		{
			NSString *currentWord = [splitContents objectAtIndex:i];
			NSXMLElement *entry = [NSXMLElement elementWithName:@"d:entry"];
			NSXMLNode *idAtt = [NSXMLNode attributeWithName:@"id" stringValue:currentWord];
			NSXMLNode *title = [NSXMLNode attributeWithName:@"d:title" stringValue:currentWord];
			NSXMLElement *index = [NSXMLElement elementWithName:@"d:index"];
			NSXMLNode *indexValue = [NSXMLNode attributeWithName:@"d:value" stringValue:currentWord];
			NSXMLElement *pronunciationSpan = [NSXMLElement elementWithName:@"span"];
			NSXMLNode *classSpan = [NSXMLNode attributeWithName:@"class" stringValue:@"syntax"];
			NSXMLElement *div = [NSXMLElement elementWithName:@"div"];
			NSXMLElement *orderedList = [NSXMLElement elementWithName:@"ol"];
			NSXMLElement *listItem = [NSXMLElement elementWithName:@"li"];
			
			[entry addAttribute:idAtt];
			[entry addAttribute:title];
			[index addAttribute:indexValue];
			[entry addChild:index];
			[pronunciationSpan addAttribute:classSpan];
			[entry addChild:pronunciationSpan];
			[orderedList addChild:listItem];
			[div addChild:orderedList];
			[entry addChild:div];
			
			if(_selectionIndex == -1)
			{
				[_theXMLDocument.rootElement addChild:entry];
			}
			else
			{
				[_theXMLDocument.rootElement insertChild:entry atIndex:(_selectionIndex + 1)];
			}
			
			[_entryTable reloadData];
		}
	}
	
	NSLog(@"%@", [_theXMLDocument XMLStringWithOptions:NSXMLNodePrettyPrint]);
}

- (void)createNewEntry:(NSString *)word
{
	[self.undoManager registerUndoWithTarget:self selector:@selector(updateDocument:) object:[_theXMLDocument copy]];
	[self.undoManager setActionName:@"Edit"];
	
	NSString *tempIDValue;
	
	if([word isEqualToString:@""])
	{
		tempIDValue = [NSString stringWithFormat:@"%li", (long)[_theXMLDocument.rootElement elementsForName:@"d:entry"].count];
	}
	else
	{
		tempIDValue = word;
	}
	
	NSXMLElement *entry = [NSXMLElement elementWithName:@"d:entry"];
	NSXMLNode *tempID = [NSXMLNode attributeWithName:@"id" stringValue:tempIDValue];
	NSXMLNode *tempTitle = [NSXMLNode attributeWithName:@"d:title" stringValue:tempIDValue];
	NSXMLElement *index = [NSXMLElement elementWithName:@"d:index"];
	NSXMLNode *indexValue = [NSXMLNode attributeWithName:@"d:value" stringValue:tempIDValue];
	NSXMLElement *pronunciationSpan = [NSXMLElement elementWithName:@"span"];
	NSXMLNode *classSpan = [NSXMLNode attributeWithName:@"class" stringValue:@"syntax"];
	NSXMLElement *div = [NSXMLElement elementWithName:@"div"];
	NSXMLElement *orderedList = [NSXMLElement elementWithName:@"ol"];
	NSXMLElement *listItem = [NSXMLElement elementWithName:@"li"];
	
	[entry addAttribute:tempID];
	[entry addAttribute:tempTitle];
	[index addAttribute:indexValue];
	[entry addChild:index];
	[pronunciationSpan addAttribute:classSpan];
	[entry addChild:pronunciationSpan];
	[orderedList addChild:listItem];
	[div addChild:orderedList];
	[entry addChild:div];
	
	if(_selectionIndex == -1)
	{
		[_theXMLDocument.rootElement addChild:entry];
	}
	else
	{
		[_theXMLDocument.rootElement insertChild:entry atIndex:(_selectionIndex + 1)];
	}
	
	NSLog(@"%@", [_theXMLDocument XMLStringWithOptions:NSXMLNodePrettyPrint]);
	[_entryTable reloadData];
}

- (void)updateDocument:(NSXMLDocument *)xml
{
	[self.undoManager registerUndoWithTarget:self selector:@selector(updateDocument:) object:[_theXMLDocument copy]];
	[self.undoManager setActionName:@"Edit"];
	[self setTheXMLDocument:xml];
	[_entryTable reloadData];
	[self applyXMLToUI];
}

@end
