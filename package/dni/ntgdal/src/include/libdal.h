/*************
 *
 *  Id:		   Data Access Layer
 *
 *  Name:      libdal.h
 *
 *  Purpose:   Define an interface to read/write system parameters,
 *             as well as to get notified of system parameter changes.
 *
 *  Note:      These are external definitions
 *
 * Copyright: (c) 2017 Netgear, Inc.
 *            All rights reserved
 *
 **************/

#ifndef LIBDAL_H_
#define LIBDAL_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>
#include <stdbool.h>

/*
 * Define version of the dallib interface for future use.
 *
 * current version: 1.0
 */
#define LIBDAL_VERSION_MAJOR 1
#define LIBDAL_VERSION_MINOR 0

/*
 * Define max. supported symbol length
 *
 * (In certain cases when static buffers need to be allocated to
 *  hold symbol names)
 */
#define LIBDAL_MAX_SYMBOL_LEN 64

/*
 * Define max. supported value length
 *
 * ! Value length must be < LIBDAL_MAX_VALUE_LEN !
 */
#define LIBDAL_MAX_VALUE_LEN 2048


/*
 * DAL error codes:
 */
enum DALerror
{
	ODM_DAL_NO_ERROR,				/* NO error */

	ODM_DAL_NOT_INITIALIZED,		/* DAL not initialized yet */
	ODM_DAL_INVALID_PARAM,			/* API parameter invalid */

	ODM_DAL_NO_SUCH_SYMBOL,			/* Attempt to access an item that doesn't exist */

	ODM_DAL_INVALID_VALUE_ENCODING, /* NO UTF8 */
	ODM_DAL_INVALID_VALUE_FORMAT,

	ODM_DAL_VALUE_TOO_LONG,         /* Attempt to write  value longer than allowed max */
	ODM_DAL_BUFFER_TOO_SMALL,		/* Attempt to read value longer than supplied buffer */

	ODM_DAL_ITEM_NOT_READABLE,		/* Item cannot be read */
	ODM_DAL_ITEM_NOT_WRITEABLE,		/* Item cannot be written to */

	ODM_DAL_IO_ERROR,				/* I/O error reading/writing item */
	ODM_DAL_SYSTEM_ERROR,			/* System error  */
};

const void * DAL_init( void );
void DAL_destroy( const void * hndl );

enum DALerror DAL_write( const void * hndl, const char * item, const char * value );
enum DALerror DAL_read( const void * hndl, const char * item, char * value, size_t maxlen );
enum DALerror DAL_onchange( const void * hndl, void (*onchange)( const void * hndl, const char * item, void *up ), void * up );


bool DAL_symbol_exists( const void * hndl, const char * item );
const char * DAL_error_str( enum DALerror err );

#ifdef __cplusplus
}
#endif


#endif
