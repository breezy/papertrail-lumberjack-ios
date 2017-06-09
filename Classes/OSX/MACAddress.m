//
//  MACAddress.m
//  BreezySDK
//
//  Created by Dmitry on 12/05/2017.
//
//

#import "MACAddress.h"

#if TARGET_OS_MAC
#import <IOKit/IOKitLib.h>
#endif

NSData * GetMACAddress( void )
{
#if TARGET_OS_MAC
    kern_return_t           kr          = KERN_SUCCESS;
    CFMutableDictionaryRef  matching    = NULL;
    io_iterator_t           iterator    = IO_OBJECT_NULL;
    io_object_t             service     = IO_OBJECT_NULL;
    CFDataRef               result      = NULL;
    
    matching = IOBSDNameMatching( kIOMasterPortDefault, 0, "en0" );
    if ( matching == NULL )
    {
        fprintf( stderr, "IOBSDNameMatching() returned empty dictionary\n" );
        return ( NULL );
    }
    
    kr = IOServiceGetMatchingServices( kIOMasterPortDefault, matching, &iterator );
    if ( kr != KERN_SUCCESS )
    {
        fprintf( stderr, "IOServiceGetMatchingServices() returned %d\n", kr );
        return ( NULL );
    }
    
    while ( (service = IOIteratorNext(iterator)) != IO_OBJECT_NULL )
    {
        io_object_t parent = IO_OBJECT_NULL;
        
        kr = IORegistryEntryGetParentEntry( service, kIOServicePlane, &parent );
        if ( kr == KERN_SUCCESS )
        {
            if ( result != NULL )
                CFRelease( result );
            
            result = IORegistryEntryCreateCFProperty( parent, CFSTR("IOMACAddress"), kCFAllocatorDefault, 0 );
            IOObjectRelease( parent );
        }
        else
        {
            fprintf( stderr, "IORegistryGetParentEntry returned %d\n", kr );
        }
        
        IOObjectRelease( service );
    }
    
    return ( (__bridge_transfer NSData *)result );
#else
    return nil;
#endif
}

NSString * GetMACAddressDisplayString( void )
{
    NSData * macData = GetMACAddress();
    if ( [macData length] == 0 )
        return ( nil );
    
    const UInt8 *bytes = [macData bytes];
    
    NSMutableString * result = [NSMutableString string];
    for ( NSUInteger i = 0; i < [macData length]; i++ )
    {
        if ( [result length] != 0 )
            [result appendFormat: @":%02hhx", bytes[i]];
        else
            [result appendFormat: @"%02hhx", bytes[i]];
    }
    
    return ( [result copy] );
}
