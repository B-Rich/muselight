#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 

#include <Cocoa/Cocoa.h>

#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format
   supports and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void *		  thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef		  contentTypeUTI,
			   CFStringRef		  pathToFile)
{
  /* Pull any available metadata from the file at the specified path */
  /* Return true if successful, false if there was no data provided */
  NSAutoreleasePool *pool;

  // Don't assume that there is an autorelease pool around the calling of
  // this function.
  pool = [[NSAutoreleasePool alloc] init];

  const char * path = CFStringGetCStringPtr(pathToFile, kCFStringEncodingMacRoman);

  FILE * fp = fopen(path, "r");
  if (fp == NULL)
    return NO;
   
  char linebuf[256];
  while (! feof(fp)) {
    if (fgets(linebuf, 255, fp) == NULL)
      break;
    if (linebuf[0] != '#')
      break;
     
    int len = strlen(linebuf);
    char * p;

#define CLEAN_LINEBUF(buf, l, lenvar)		\
    p = &buf[l];				\
    while (*p && isspace(*p)) p++;		\
    while (isspace(buf[lenvar - 1]))		\
      buf[--lenvar] = '\0'

    if (len > 7 && strncmp(&linebuf[1], "title", 5) == 0 &&
	isspace(linebuf[6]))
    {
      CLEAN_LINEBUF(linebuf, 7, len);
      [(NSMutableDictionary *)attributes
         setObject:[NSString stringWithCString:p]
            forKey:(NSString *)kMDItemTitle];
      [(NSMutableDictionary *)attributes
         setObject:[NSString stringWithCString:p]
            forKey:(NSString *)kMDItemDisplayName];
    }
#if 0
    // jww (2007-07-27): Need to parse out the time here into an NSDate
    else if (len > 9 && strncmp(&linebuf[1], "written", 7) == 0 &&
	isspace(linebuf[8]))
    {
      CLEAN_LINEBUF(linebuf, 9, len);
      [(NSMutableDictionary *)attributes
         setObject:[NSString stringWithCString:p]
            forKey:(NSString *)kMDItemContentCreationDate];
    }
    else if (len > 8 && strncmp(&linebuf[1], "edited", 6) == 0 &&
	isspace(linebuf[7]))
    {
      CLEAN_LINEBUF(linebuf, 8, len);
      [(NSMutableDictionary *)attributes
         setObject:[NSString stringWithCString:p]
            forKey:(NSString *)kMDItemContentModificationDate];
    }
    else if (len > 6 && strncmp(&linebuf[1], "date", 4) == 0 &&
	isspace(linebuf[5]))
    {
      CLEAN_LINEBUF(linebuf, 6, len);
      [(NSMutableDictionary *)attributes
         setObject:[NSString stringWithCString:p]
            forKey:(NSString *)kMDItemDueDate];
    }
#endif
  }

  struct stat info;
  if (stat(path, &info) == -1)
    return NO;

  char * textbuf = (char *)malloc(info.st_size + 1);

  fseek(fp, 0, SEEK_SET);
  fread(textbuf, 1, info.st_size, fp);
  textbuf[info.st_size] = '\0';
   
  [(NSMutableDictionary *)attributes
     setObject:[NSString stringWithCString:textbuf]
        forKey:(NSString *)kMDItemTextContent];

  free(textbuf);
  fclose(fp);

  // release the loaded document
  [pool release];

  return YES;
}
