#import "MyTextView.h"

// added by mitsu --(A) TeXChar filtering
#import "EncodingSupport.h"
#import "globals.h"
#import "MyDocument.h" // mitsu 1.29 (T2-4)
#import "TSWindowManager.h" // mitsu 1.29 (T2)
#import "EncodingSupport.h"
#import "TSPreferences.h"

#define SUD [NSUserDefaults standardUserDefaults]

// end addition

@implementation MyTextView


// drag & drop support --- added by zenitani, Feb 13, 2003
- (unsigned int) dragOperationForDraggingInfo : (id <NSDraggingInfo>) sender
{
    NSPasteboard *pb = [sender draggingPasteboard];
    NSString *type = [pb availableTypeFromArray:
        [NSArray arrayWithObjects: NSStringPboardType, NSFilenamesPboardType, nil] ];
    if( type && [(MyDocument *)[[[self window] windowController] document] fileIsTex] ) {
        if( [type isEqualToString:NSStringPboardType] ||
            [type isEqualToString:NSFilenamesPboardType] ){
            NSPoint location = [self convertPoint:[sender draggingLocation] fromView:nil];
            NSLayoutManager *layoutManager = [self layoutManager];
            NSTextContainer *textContainer = [self textContainer];
            float fraction;
            int glyphIndex = [layoutManager glyphIndexForPoint:location 
                inTextContainer:textContainer fractionOfDistanceThroughGlyph:&fraction];	
            int characterIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
            NSRange selRange = [self selectedRange];
            // moves cursor's position if necessary
            if(( selRange.location != characterIndex ) || ( selRange.length != 0 )){
                [self setSelectedRange: NSMakeRange( characterIndex, 0 ) ];
            }
            return NSDragOperationGeneric;
        }
    }
    return NSDragOperationNone;
}
- (unsigned int) draggingEntered : (id <NSDraggingInfo>) sender
{
    return [self dragOperationForDraggingInfo:sender];
}
- (unsigned int) draggingUpdated : (id <NSDraggingInfo>) sender
{
    return [self dragOperationForDraggingInfo:sender];
}
- (void) draggingExited : (id <NSDraggingInfo>) sender
{
    return;
}
- (BOOL) prepareForDragOperation : (id <NSDraggingInfo>) sender
{
    return YES;
}
- (BOOL) performDragOperation : (id <NSDraggingInfo>) sender
{
    return YES;
}
- (void) concludeDragOperation : (id <NSDraggingInfo>) sender {
    NSPasteboard *pb = [ sender draggingPasteboard ];
    NSString *type = [ pb availableTypeFromArray:
        [NSArray arrayWithObjects: NSStringPboardType, NSFilenamesPboardType, nil]];
    if( type ){

        if ([type isEqualToString: NSStringPboardType]) {
            NSString *str = [ pb stringForType : NSStringPboardType ];
            [ self insertText: str ];
        } else if ([type isEqualToString: NSFilenamesPboardType]) {
            NSArray *ar = [pb propertyListForType:NSFilenamesPboardType];
            unsigned cnt = [ar count];
            if( cnt == 0 ) return;
            NSString *thisFile = [[[[self window] windowController] document] fileName];
            unsigned i;
            for( i=0; i<cnt; i++ ){
                // The below code will soon be modified.
                // A user will be able to customize these strings by .plist file.
                NSString *fPath = [ar objectAtIndex:i];
                NSString *bPath = [[fPath lastPathComponent] stringByDeletingPathExtension];
                NSString *fExt  = [[fPath pathExtension] lowercaseString];
                NSString *rPath = [[TSPreferences sharedInstance] relativePath: fPath fromFile: thisFile ];
                if( [fExt isEqualToString: @"cls"] ){
                    [ self insertText:
                        [NSString stringWithFormat: @"%cdocumentclass{%@}\n", texChar, bPath ]];
                }else if( [fExt isEqualToString: @"sty"] ){
                    [ self insertText:
                        [NSString stringWithFormat: @"%cusepackage{%@}\n", texChar, bPath ]];
                }else if( [fExt isEqualToString: @"bib"] ){
                    [ self insertText:
                        [NSString stringWithFormat: @"%cbibliography{%@}\n", texChar, bPath ]];
                }else if( [fExt isEqualToString: @"bst"] ){
                    [ self insertText:
                        [NSString stringWithFormat: @"%cbibliographystyle{%@}\n", texChar, bPath ]];
                }else if( ([fExt isEqualToString: @"pdf"] ) ||
                    ([fExt isEqualToString: @"jpeg"]) || ([fExt isEqualToString: @"jpg"]) ||
                    ([fExt isEqualToString: @"tiff"]) || ([fExt isEqualToString: @"tif"]) ||
                    ([fExt isEqualToString: @"eps"] ) || ([fExt isEqualToString: @"ps"] ) ){
                    [ self insertText:
                        [NSString stringWithFormat: @"%cincludegraphics[]{%@}\n", texChar, rPath ]];
                }else{
                    [ self insertText:
                        [NSString stringWithFormat: @"%cinput{%@}\n", texChar, rPath ]];
                }
            }
        }
    }
    [ self display ];
    return;
}
// end addition


- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
{
    NSRange	replacementRange;
    NSString	*textString;
    int		length, i, j;
    BOOL	done;
    int		leftpar, rightpar, count, uchar;

    replacementRange = [super selectionRangeForProposedRange: proposedSelRange granularity: granularity];
    if ((proposedSelRange.length != 0) || (granularity != 2)) 
        return replacementRange;
    textString = [self string];
    if (textString == nil) return replacementRange;
    length = [textString length];
    i = proposedSelRange.location;
    if (i >= length) return replacementRange;
    rightpar = [textString characterAtIndex: i];
    
    if ((rightpar == 0x007D) || (rightpar == 0x0029) || (rightpar == 0x005D)) {
           j = i;
            if (rightpar == 0x007D) 
                leftpar = 0x007B;
            else if (rightpar == 0x0029) 
                leftpar = 0x0028;
            else 
                leftpar = 0x005B;
            count = 1;
            done = NO;
            while ((i > 0) && (! done)) {
                i--;
                uchar = [textString characterAtIndex:i];
                if (uchar == rightpar)
                    count++;
                else if (uchar == leftpar)
                    count--;
                if (count == 0) {
                    done = YES;
                    replacementRange.location = i;
                    replacementRange.length = j - i + 1;
                    return replacementRange;
                    }
                }
            return replacementRange;
            }
            
    else if ((rightpar == 0x007B) || (rightpar == 0x0028) || (rightpar == 0x005B)) {
            j = i;
            leftpar = rightpar;
            if (leftpar == 0x007B) 
                rightpar = 0x007D;
            else if (leftpar == 0x0028) 
                rightpar = 0x0029;
            else 
                rightpar = 0x005D;
            count = 1;
            done = NO;
            while ((i < (length - 1)) && (! done)) {
                i++;
                uchar = [textString characterAtIndex:i];
                if (uchar == leftpar)
                    count++;
                else if (uchar == rightpar)
                    count--;
                if (count == 0) {
                    done = YES;
                    replacementRange.location = j;
                    replacementRange.length = i - j + 1;
                    return replacementRange;
                    }
                }
            return replacementRange;
            }

    else return replacementRange;
}

// added by mitsu --(A) TeXChar filtering
- (void)insertText:(id)aString
{
// old code was: 
/*
	if (shouldFilter == filterMacJ)
	{
		aString = filterBackslashToYen(aString);
	}
	else if (shouldFilter == filterNSSJIS)
	{
		aString = filterYenToBackslash(aString);
	}
	[super insertText: aString];*/
// 


// mitsu 1.29 (T4)
	NSString *newString = aString;

#define AUTOCOMPLETE_IN_INSERTTEXT
#ifdef AUTOCOMPLETE_IN_INSERTTEXT
	// AutoCompletion
    // Code added by Greg Landweber for auto-completions of '^', '_', etc.
    // First, avoid completing \^, \_, \"
	if ([(NSString *)aString length]==1 && 
		document && [(MyDocument *)document isDoAutoCompleteEnabled]) 
	{
        if ( [aString characterAtIndex:0] >= 128 ||
            [self selectedRange].location == 0 ||
            [[self string] characterAtIndex:[self selectedRange].location - 1 ] != texChar ) 
		{
			NSString *completionString = [autocompletionDictionary objectForKey:aString];
			if ( completionString && 
				(!shouldFilter || [aString characterAtIndex:0]!=0x00a5)) // avoid completing yen
			{
#define ALLOW_UNDO_AUTOCOMPLETION
#ifdef ALLOW_UNDO_AUTOCOMPLETION
				[(MyDocument *)document insertSpecialNonStandard:completionString 
						undoKey: NSLocalizedString(@"Autocompletion", @"Autocompletion")];
				//[self insertSpecialNonStandard:completionString 
				//		undoKey: NSLocalizedString(@"Autocompletion", @"Autocompletion")];
				return;
#else
				newString = completionString;
#endif //ALLOW_UNDO_AUTOCOMPLETION
			}
		}
	}
    // End of code added by Greg Landweber
#endif //AUTOCOMPLETE_IN_INSERTTEXT

	// Filtering for Japanese
	if (shouldFilter == filterMacJ)
	{
		newString = filterBackslashToYen(newString);
	}
	else if (shouldFilter == filterNSSJIS)
	{
		newString = filterYenToBackslash(newString);
	}
	[super insertText: newString];
	
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
	NSMutableString *newString;
	
	BOOL returnValue = [super writeSelectionToPasteboard:pboard type:type];
	if ((shouldFilter == filterMacJ) && returnValue && 
			[SUD boolForKey:@"ConvertToBackslash"] && [type isEqualToString: NSStringPboardType])
	{
		newString = filterYenToBackslash([pboard stringForType: NSStringPboardType]);
		returnValue = [pboard setString: newString forType: NSStringPboardType];
	}
	else if ((shouldFilter == filterNSSJIS) && returnValue && 
			[SUD boolForKey:@"ConvertToYen"] && [type isEqualToString: NSStringPboardType])
	{
		newString = filterBackslashToYen([pboard stringForType: NSStringPboardType]);
		returnValue = [pboard setString: newString forType: NSStringPboardType];
	}
	return returnValue;
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
	if(shouldFilter && [type isEqualToString: NSStringPboardType])
	{
		NSString *string = [pboard stringForType: NSStringPboardType];
		if (string)
		{
		// mitsu 1.29 (T1)-- in order to enable "Undo Paste"
			// Filtering for Japanese
			if (shouldFilter == filterMacJ)
				string = filterBackslashToYen(string);
			else if (shouldFilter == filterNSSJIS)
				string = filterYenToBackslash(string);
		
			// Replace the text--imitate what happens in ordinary editing
			NSRange	selectedRange = [self selectedRange];
			if ([self shouldChangeTextInRange:selectedRange replacementString:string]) 
			{
				[self replaceCharactersInRange:selectedRange withString:string];
				[self didChangeText];
			}
			// by returning YES, "Undo Paste" menu item will be set up by system
		// original was:
		//	[self insertText: string];
		// end mitsu 1.29
			return YES; 
		}
		else
			return NO; 
	}
	return [super readSelectionFromPasteboard: pboard type: type];
}

// end addition

// mitsu 1.29 (T2-4)

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame: frameRect];
        [ self registerForDraggedTypes:
            [NSArray arrayWithObjects: NSStringPboardType, NSFilenamesPboardType, nil] ];
	document = nil; 
    return self;
}

- (void)setDocument: (NSDocument *)doc
{
	document = doc;
}


// Command Completion!!

// mitsu 1.29 (P)

// Trap "keyDown:" for command completion:
// most of command completion function is concentrated here.  
// two types of completions are activated on escape or commandCompletionChar: 
// (1) ordinary: staring from the insertion point search backward for word boundary,  
// which are defined by space, tab, linefeed, period, comma, colon, semicolon, {. }, (, ),  
// and TeX character.  the string up to the boundary (TeX character and "{" are inclusive 
// and others are not) is compared with the completion list.  the line whose beginning 
// matches with the string will be inserted.  further escape(commandCompletionChar) 
// will cycle through the candidates.  it cycles backward with shift key.  
// special treatments: in the candiate, 
//     #RET# will be replaced by linefeed (new line)
//     #INS# will be removed and the insertion point will be placed there
//     if there is ":=", the string after it (the first one) will be inserted
// (2) LaTeX special: if the insertion point is right after "\begin{...}" 
// where ... conatins no word boundary characters, then "\end{...}" together with 
// linefeeds is completed, and the insertion point will be placed after "\begin{...}".  
// these two types can be combined:  if after type (1) completion the situation matches 
// with type (2) then the next candidate will be type (2).  
// you only need to supply commandCompletionChar(unichar) and commandCompletionList
// (a string which starts and ends with line feeds).  
// so the code can be reused in other applications???  
- (void)keyDown:(NSEvent *)theEvent
{
	static BOOL wasCompleted = NO; // was completed on last keyDown
	static BOOL latexSpecial = NO; // was last time LaTeX Special?  \begin{...}
	static NSString *originalString = nil; // string before completion, starts at replaceLocation
	static NSString *currentString = nil; // completed string
	static unsigned replaceLocation = NSNotFound; // completion started here
	static unsigned int completionListLocation = 0; // location to start search in the list
	static unsigned textLocation = NSNotFound; // location of insertion point
	BOOL foundCandidate;
	NSString *textString, *foundString, *latexString;
	NSMutableString *newString;
	unsigned selectedLocation, currentLength, from, to;
	NSRange foundRange, searchRange, spaceRange, insRange, replaceRange;
	NSCharacterSet *charSet;
	unichar c;
	
	if ([[theEvent characters] isEqualToString: commandCompletionChar] && 
			([theEvent modifierFlags] & ~NSShiftKeyMask) == 0 && 
			![self hasMarkedText] && commandCompletionList)
	{
		textString = [self string]; // this will change during operations (such as undo)
		selectedLocation = [self selectedRange].location;
		// check for LaTeX \begin{...}
		if (selectedLocation > 0 && [textString characterAtIndex: selectedLocation-1] == '}' 
					&& !latexSpecial)
		{
			charSet = [NSCharacterSet characterSetWithCharactersInString: 
						[NSString stringWithFormat: @"\n \t.,;;{}()%C", texChar]]; //should be global?
			foundRange = [textString rangeOfCharacterFromSet:charSet 
						options:NSBackwardsSearch range:NSMakeRange(0,selectedLocation-1)];
			if (foundRange.location != NSNotFound  &&  foundRange.location >= 6  &&
				[textString characterAtIndex: foundRange.location-6] == texChar  &&
				[[textString substringWithRange: NSMakeRange(foundRange.location-5, 6)] 
															isEqualToString: @"begin{"])
			{
				latexSpecial = YES;
				latexString = [textString substringWithRange: 
							NSMakeRange(foundRange.location, selectedLocation-foundRange.location)];
				if (wasCompleted)
					[currentString retain]; // extend life time
			}
		}
		else
			latexSpecial = NO;
			
		// if it was completed last time, revert to the uncompleted stage
		if (wasCompleted) 
		{
			currentLength = (currentString)?[currentString length]:0;
			// make sure that it was really completed last time
			// check: insertion point, string before insertion point, undo title
			if ( selectedLocation == textLocation && 
				[textString length]>= replaceLocation+currentLength && // this shouldn't be necessary
				[[textString substringWithRange: 
						NSMakeRange(replaceLocation, currentLength)] 
						isEqualToString: currentString] && 
				[[[self undoManager] undoActionName] isEqualToString: 
						NSLocalizedString(@"Completion", @"Completion")])
			{
				// revert the completion:
				// by doing this, even after showing several completion candidates
				// you can get back to the uncompleted string by one undo.  
				[[self undoManager] undo];
				selectedLocation = [self selectedRange].location;
				if (selectedLocation >= replaceLocation && 
					[[textString substringWithRange: 
						NSMakeRange(replaceLocation, selectedLocation-replaceLocation)] 
						isEqualToString: originalString]) // still checking
				{
					// this is supposed to happen
					if (completionListLocation == NSNotFound)
					{	// this happens if last one was LaTeX Special without previous completion
						[originalString release];
						[currentString release];
						wasCompleted = NO;
						return; // no other completion is possible
					}
				}
				else // this shouldn't happen
				{
					[[self undoManager] redo];
					selectedLocation = [self selectedRange].location;
					[originalString release];
					wasCompleted = NO;
				}
			}
			else // probably there were other operations such as cut/paste/Macros which changed text
			{
				[originalString release];
				wasCompleted = NO;
			}
			[currentString release];
		}
		
		if (!wasCompleted && !latexSpecial)
		{
			// determine the word to complete--search for word boundary
			charSet = [NSCharacterSet characterSetWithCharactersInString: 
						[NSString stringWithFormat: @"\n \t.,;;{}()%C", texChar]];
			foundRange = [textString rangeOfCharacterFromSet:charSet 
						options:NSBackwardsSearch range:NSMakeRange(0,selectedLocation)];
			if (foundRange.location != NSNotFound)
			{
				if (foundRange.location + 1 == selectedLocation)
					return; // no string to match
				c = [textString characterAtIndex: foundRange.location];
				if (c == texChar || c == '{') // special characters
					replaceLocation = foundRange.location; // include these characters for search
				else
					replaceLocation = foundRange.location + 1;
			}
			else
			{
				if (selectedLocation == 0)
					return; // no string to match
				replaceLocation = 0; // start from the beginning
			}
			originalString = [textString substringWithRange: 
						NSMakeRange(replaceLocation, selectedLocation-replaceLocation)];
			//if (shouldFilter == filterMacJ)// we now use current encoding, so this isn't necessary
			//	originalString = filterYenToBackslash(originalString);
			[originalString retain];
			completionListLocation = 0;
		}
		
		// try to find a completion candidate
		if (!latexSpecial) // ordinary case -- find from the list
		{
			while (YES) // look for a candidate which is not equal to originalString
			{
				if ([theEvent modifierFlags] && wasCompleted)
				{	// backward
					searchRange.location = 0;
					searchRange.length = completionListLocation-1;
				}
				else
				{	// forward
					searchRange.location = completionListLocation;
					searchRange.length = [commandCompletionList length] - completionListLocation;
				}
				// search the string in the completion list
				foundRange = [commandCompletionList rangeOfString: 
						[@"\n" stringByAppendingString: originalString] 
						options: ([theEvent modifierFlags]?NSBackwardsSearch:0)
						range: searchRange];
				
				if (foundRange.location == NSNotFound) // a completion candidate was not found
				{
					foundCandidate = NO;
					break;
				}
				else // found a completion candidate-- create replacement string
				{
                                        foundCandidate = YES;
					// get the whole line
					foundRange.location ++; // eliminate first LF
					foundRange.length--;
					foundRange = [commandCompletionList lineRangeForRange: foundRange];
					foundRange.length--; // eliminate last LF
					foundString = [commandCompletionList substringWithRange: foundRange];
					completionListLocation = foundRange.location; // remember this location
					// check if there is ":="
					spaceRange = [foundString rangeOfString: @":="
								options: 0 range: NSMakeRange(0, [foundString length])];
					if (spaceRange.location != NSNotFound)
					{
						spaceRange.location += 2;
						spaceRange.length = [foundString length]-spaceRange.location;
						foundString = [foundString substringWithRange: spaceRange]; //string after first space
					}
					newString = [NSMutableString stringWithString: foundString];
					// replace #RET# by linefeed -- this could be tab -> \n
					[newString replaceOccurrencesOfString: @"#RET#" withString: @"\n"
								options: 0 range: NSMakeRange(0, [newString length])];
					// search for #INS#
					insRange = [newString rangeOfString:@"#INS#" options:0];
					if (insRange.location != NSNotFound)
						[newString replaceCharactersInRange:insRange withString:@""];
					// Filtering for Japanese
					//if (shouldFilter == filterMacJ)//we use current encoding, so this isn't necessary
					//	newString = filterBackslashToYen(newString);
					if (![newString isEqualToString: originalString])
						break;		// continue search if newString is equal to originalString
				}
			}
		}
		else // LaTeX Special -- just add \end and copy of {...}
		{
			foundCandidate = YES;
			if (!wasCompleted)
			{
				originalString = [[NSString stringWithString: @""] retain];
				replaceLocation = selectedLocation;
				newString = [NSMutableString stringWithFormat: @"\n%Cend%@\n", 
									texChar, latexString];
				insRange.location = 0;
				completionListLocation = NSNotFound; // just to remember that it wasn't completed
			}
			else
			{	// reuse the current string
				newString = [NSMutableString stringWithFormat: @"%@\n%Cend%@\n", 
									currentString, texChar, latexString];
				insRange.location = [currentString length];
				[currentString release];
			}
		}
		
		if (foundCandidate) // found a completion candidate
		{
			// replace the text
			replaceRange.location = replaceLocation;
			replaceRange.length = selectedLocation-replaceLocation;
			
			[self replaceCharactersInRange:replaceRange withString: newString];
			// register undo
			if (document)
				[(MyDocument *)document registerUndoWithString:originalString location:replaceLocation 
					length:[newString length] 
					key:NSLocalizedString(@"Completion", @"Completion")];
			//[self registerUndoWithString:originalString location:replaceLocation 
			//		length:[newString length] 
			//		key:NSLocalizedString(@"Completion", @"Completion")];
			// clean up
			if (document)
			{
				from = replaceLocation;
				to = from + [newString length];
				[(MyDocument *)document fixColor:from :to];
				[(MyDocument *)document setupTags];
			}
			currentString = [newString retain];
			wasCompleted = YES;
			// flash the new string
            [self setSelectedRange: NSMakeRange(replaceLocation, [newString length])];
            [self display];
            NSDate *myDate = [NSDate date];
            while ([myDate timeIntervalSinceNow] > - 0.050) ;
			// set the insertion point
			if (insRange.location != NSNotFound) // position of #INS#
				textLocation = replaceLocation+insRange.location;
			else
				textLocation = replaceLocation+[newString length];
			[self setSelectedRange: NSMakeRange(textLocation,0)];
		}
		else // candidate was not found
		{
			[originalString release];
			originalString = currentString = nil;
			wasCompleted = NO;
		}
		return;
	}
	else if (wasCompleted) // we are not doing the completion
	{
		[originalString release];
		[currentString release];
		originalString = currentString = nil;
		wasCompleted = NO;
	}
	
	[super keyDown: theEvent];
}

// mitsu 1.29 (P)
- (void)registerForCommandCompletion: (id)sender
{
        NSString		*initialWord, *aWord, *completionPath, *backupPath;
	NSData 			*myData;
        int			theTag;
        NSStringEncoding	theEncoding;
    
	if (!commandCompletionList) return;
	// get the word(s) to register
	initialWord = [[self string] substringWithRange: [self selectedRange]];
        aWord = [initialWord stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
	//if (shouldFilter == filterMacJ)// we now use current encoding, so this isn't necessary
	//	aWord = filterYenToBackslash(aWord);
	// add to the list-- it will be ideal if one can check redundancy
	[commandCompletionList deleteCharactersInRange:NSMakeRange(0,1)]; // remove first LF
	[commandCompletionList appendString: aWord];
	if ([commandCompletionList characterAtIndex: [commandCompletionList length]-1] != '\n')
		[commandCompletionList appendString: @"\n"];
	
    completionPath = [CommandCompletionPathKey stringByStandardizingPath];
	// back up old list
	backupPath = [completionPath stringByDeletingPathExtension];
	backupPath = [backupPath stringByAppendingString:@"~"];
	backupPath = [backupPath stringByAppendingPathExtension:@"plist"];
	NS_DURING
		[[NSFileManager defaultManager] removeFileAtPath:backupPath handler:nil];
		[[NSFileManager defaultManager] copyPath:completionPath toPath:backupPath handler:nil];
	NS_HANDLER
	NS_ENDHANDLER
	// save the new list to file
	//myData = [commandCompletionList dataUsingEncoding: NSUTF8StringEncoding]; // not used
        theTag = [[EncodingSupport sharedInstance] tagForEncodingPreference];
        theEncoding = [[EncodingSupport sharedInstance] stringEncodingForTag: theTag];
        myData = [commandCompletionList dataUsingEncoding: theEncoding allowLossyConversion:YES];
        
        /*
	if([[SUD stringForKey:EncodingKey] isEqualToString:@"MacOSRoman"])
		myData = [commandCompletionList dataUsingEncoding: NSMacOSRomanStringEncoding allowLossyConversion:YES];
	else if([[SUD stringForKey:EncodingKey] isEqualToString:@"IsoLatin"])
		myData = [commandCompletionList dataUsingEncoding: NSISOLatin1StringEncoding allowLossyConversion:YES];
	else if([[SUD stringForKey:EncodingKey] isEqualToString:@"IsoLatin2"])
		myData = [commandCompletionList dataUsingEncoding: NSISOLatin2StringEncoding allowLossyConversion:YES];
	else if([[SUD stringForKey:EncodingKey] isEqualToString:@"MacJapanese"]) 
		myData = [commandCompletionList dataUsingEncoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacJapanese) allowLossyConversion:YES];
	else if([[SUD stringForKey:EncodingKey] isEqualToString:@"DOSJapanese"]) 
		myData = [commandCompletionList dataUsingEncoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese) allowLossyConversion:YES];
	else if([[SUD stringForKey:EncodingKey] isEqualToString:@"EUC_JP"]) 
		myData = [commandCompletionList dataUsingEncoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_JP) allowLossyConversion:YES];
	else if([[SUD stringForKey:EncodingKey] isEqualToString:@"JISJapanese"]) 
		myData = [commandCompletionList dataUsingEncoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP) allowLossyConversion:YES];
	else if([[SUD stringForKey:EncodingKey] isEqualToString:@"MacKorean"]) 
		myData = [commandCompletionList dataUsingEncoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacKorean) allowLossyConversion:YES];
	else if([[SUD stringForKey:EncodingKey] isEqualToString:@"UTF-8 Unicode"]) 
		myData = [commandCompletionList dataUsingEncoding: NSUTF8StringEncoding allowLossyConversion:YES];
	else if([[SUD stringForKey:EncodingKey] isEqualToString:@"Standard Unicode"])
		myData = [commandCompletionList dataUsingEncoding: NSUnicodeStringEncoding allowLossyConversion:YES];
	else 
		myData = [commandCompletionList dataUsingEncoding: NSMacOSRomanStringEncoding allowLossyConversion:YES];
*/
	
	if (myData)
	{
		NS_DURING
			[myData writeToFile:completionPath atomically:YES];
		NS_HANDLER
		NS_ENDHANDLER
	}
	[commandCompletionList insertString: @"\n" atIndex: 0];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem {

    if ([anItem action] == @selector(registerForCommandCompletion:))
		return (canRegisterCommandCompletion && ([self selectedRange].length > 0));
	
	return [super validateMenuItem: anItem];
}

// end mitsu 1.29
 
        
@end
