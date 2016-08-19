//
//  Document.h
//  Dictionary Maker
//
//  Created by Alice on 8/11/16.
//

#import <Cocoa/Cocoa.h>
#import "DMParser.h"

@interface Document : NSDocument <NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, NSTextViewDelegate>

@property (strong) NSXMLDocument *theXMLDocument;
@property (strong) DMParser *parser;

@property (strong) IBOutlet NSButton *toggleFrontBackMatter;
@property (strong) IBOutlet NSTextView *frontBackMatterTextView;

@property (strong) IBOutlet NSTableView *entryTable;
@property (strong) IBOutlet NSTextField *wordField;
@property (strong) IBOutlet NSTextView *pronunciationTextView;
@property (strong) IBOutlet NSTextView *searchTermsTextView;
@property (strong) IBOutlet NSTextView *addendumsTextView;
@property (strong) IBOutlet NSTextView *definitionsTextView;

@property (strong) IBOutlet NSButton *toggleAllowFrontBackMatterSearch;

/// Removes the currently selected entry in the EntryTable.
- (IBAction)removeCurrentEntry:(id)sender;
/// Inserts a new entry into the EntryTable after the currently selected entry.
- (IBAction)addNewEntry:(id)sender;
/// Creates entries in the EntryTable based off of endings listed in the AddendumsTextView.
- (IBAction)insertAddendums:(id)sender;
/// Shows an import window for the user to select a file to fill the table with entries.
- (IBAction)importFile:(id)sender;

@end

