/*
 *	Copyright 1990, University Corporation for Atmospheric Research
 *      See netcdf/COPYRIGHT file for copying and redistribution conditions.
 */
/* $Id: jackets-apple.c,v 1.4 2005/02/09 03:04:11 epourmal Exp $ */
/*
 * OVERVIEW
 *
 * This file contains jacket routines written in C for interfacing Fortran
 * netCDF function calls to the actual C binding for the NetCDF.  This code
 * is written explicitly for Sun.  In general, these functions handle
 * character-string parameter conventions, convert between
 * column-major-order arrays and row-major-order arrays, and map between
 * array indices beginning at one and array indices beginning at zero.
 *
 */

/* LINTLIBRARY */
#include	<ctype.h>
#include        <string.h>
#include	<stdlib.h>
#include	<stdio.h>
#ifdef HDF
#include        "local_nc.h"
#else /* HDF */
#include	"netcdf.h"
#endif /* HDF */





#if !NC_OLD_FILLVALUES

struct ncfils {			/* This will be a common block from Fortran */
    double dd;
#if defined __alpha || (_MIPS_SZLONG == 64) || defined __ia64 || (defined __sun && defined _LP64) || defined AIX5L64 || defined __x86_64__

    int ll;
#else
    long ll;
#endif
    float ff;
    short ss;
    char cc;
    char bb;
} ncfils_ = {
    FILL_DOUBLE,
    FILL_LONG,
    FILL_FLOAT,
    FILL_SHORT,
    FILL_CHAR,
    FILL_BYTE
};

#else	/* NC_OLD_FILLVALUES below */

/*
 * This section is provided for backward compatibility only.  Using
 * XDR infinities for floating-point fill values has caused more problems
 * than it has solved.  We encourage you to define your own data-specific
 * fill values rather than use default ones.  
 * If, however, you *must* use default fill values, then you should use
 * the above fill values rather than the ones in this section.
 */

struct ncfils {			/* This will be a common block from Fortran */
    double dd;
#if defined __alpha || (_MIPS_SZLONG == 64) || defined __ia64 || (defined __sun && defined _LP64) || defined AIX5L64 || defined __x86_64__

    int ll;
#else
    long ll;
#endif
    float ff;
    short ss;
    char cc;
    char bb;
} ncfils_ = {
    XDR_D_INFINITY,		/* You may have to insert a constant here */
    FILL_LONG,
    XDR_F_INFINITY,		/* You may have to insert a constant here */
    FILL_SHORT,
    FILL_CHAR,
    FILL_BYTE
};

#endif	/* NC_OLD_FILLVALUES above */


/*
 * global integer used for suppressing error messages and determining
 * the fatality of errors.
 */
extern int ncopts;		/* default is (NC_FATAL | NC_VERBOSE) */

/* global integer that contains a netCDF-specific error code */
extern int ncerr;

/* blank fill C string to make FORTRAN string */
static void
fcdcpy (fstring, fslen, sstring)
    char *fstring;		/* output string to be blank-filled */
    int fslen;			/* length of output string */
    char *sstring;		/* input string, null-terminated */
{
    int i, len = strlen(sstring);

    for (i = 0; i < len; i++)
	*(fstring + i) = *(sstring + i);
    for (i = len; i < fslen; i++)
	*(fstring + i) = ' ';
}


static void
reverse (array, length)
    int array[];		/* array to be reversed */
    int length;			/* length of array */
{
    int temp, i, j;

    for (i = 0, j = length - 1; i < j; i++, j--) {
	temp = array[i];
	array[i] = array[j];
	array[j] = temp;
    }
}


static void
revlongs (array, length)
    long array[];		/* array to be reversed */
    int length;			/* length of array */
{
    int i, j;
    long temp;

    for (i = 0, j = length - 1; i < j; i++, j--) {
	temp = array[i];
	array[i] = array[j];
	array[j] = temp;
    }
}


/* error handling function */
static void
handle_err (pname, rcode)
    char *pname;		/* procedure name */
    int rcode;			/* error return */
{
    cdf_routine_name = pname;
    NCadvise(rcode, "string won't fit in CHARACTER variable provided");
}

/* copy function used to copy strings with embedded blanks */
static void
fstrncpy (target, source, maxlen)
    char *target;		/* space to be copied into */
    char *source;		/* string to be copied */
    int maxlen;			/* maximum length of *source */
{
    while (maxlen-- && *source != '\0')
	*target++ = *source++;
    *target = '\0';
}
#ifdef WE_COULDNT_READ_NAMES_WITH_SPACES
/* copy function used to copy strings terminated with blanks */
static void
nstrncpy (target, source, maxlen)
    char *target;		/* space to be copied into */
    char *source;		/* string to be copied */
    int maxlen;			/* maximum length of *source */
{
    while (maxlen-- && *source != ' ')
	*target++ = *source++;
    *target = '\0';
}
#endif

/* copy function used to copy strings with embeded blanks and
   terminated with blanks */
static void
nstrncpy (target, source, maxlen)
    char *target;		/* space to be copied into */
    char *source;		/* string to be copied */
    int maxlen;			/* maximum length of *source */
{
/* Copy all string */
    while (maxlen--) 
        *target++ = *source++;
    *target -- = '\0';
/* Disregard all trailing spaces  */
     while (*target == ' ')
         *target-- = '\0';

}
/*
 * Compute product of dimensions.
 */
static long
dimprod (dims, ndims)
     long *dims;			/* list of dimensions */
     int ndims;			/* number of dimensions in list */
{
    long *ip;
    long prod = 1;

    for (ip = dims; ip < &dims[ndims]; ip++)
      prod *= *ip;
    return prod;
}


#ifdef FORTRAN_HAS_NO_BYTE
/*
 * Convert multi-dimensional array of bytes stored in ints to packed array of
 * bytes, in malloc'ed space.  Returns pointer to bytes or NULL if malloc
 * failed.
 */
static char *
itob(ints, dims, ndims)
     int *ints;			/* multi-dimensional array of integers */
     long *dims;			/* list of dimensions */
     int ndims;			/* number of dimensions in list */
{
    long iocount = dimprod (dims, ndims);	/* product of dimensions */
    char *bytes = (char *) malloc (iocount * sizeof (char));
    int *ip;
    char *bp = bytes;

    if (bytes != NULL)
      for (ip = ints; iocount > 0; iocount--)
	*bp++ = (char) *ip++;
    return bytes;
}

/*
 * Convert a generalized multi-dimensional array of bytes stored in ints to 
 * packed array of bytes, in malloc'ed space.  Returns pointer to bytes or 
 * NULL if malloc failed.
 */
static char *
itobg(ints, dims, basis, ndims)
     int *ints;			/* multi-dimensional array of integers */
     long *dims;			/* list of dimensions */
     long *basis;			/* memory access basis vector */
     int ndims;			/* number of dimensions in list */
{
    long iocount = dimprod (dims, ndims);	/* product of dimensions */
    char *bytes = (char *) malloc (iocount * sizeof (char));

    if (bytes != NULL && iocount > 0) {
	int	idim;
	char	*bp	= bytes;
	char	*ip	= (char*)ints;
	long	length[MAX_NC_DIMS];
	long	coords[MAX_NC_DIMS];

	for (idim = 0; idim < ndims; ++idim) {
	    length[idim]	= dims[idim]*basis[idim];
	    coords[idim]	= 0;
	}

	for (;;) {
	    *bp++	= (char)*(int*)ip;
	    idim	= ndims - 1;
	carry:
	    ip	+= basis[idim];
	    if (++coords[idim] >= dims[idim]) {
		coords[idim]	= 0;
		ip		-= length[idim];
		if (--idim < 0)
		    break;
		goto carry;
	    }
        }
    }

    return bytes;
}

/*
 * Convert a packed array of bytes into a generalized multi-dimensional array
 * of ints.
 */
static void
btoig(bytes, ints, dims, basis, ndims)
     char *bytes;		/* packed array of bytes */
     int *ints;			/* multi-dimensional array of integers */
     long *dims;		/* list of dimensions */
     long *basis;		/* memory access basis vector */
     int ndims;			/* number of dimensions in list */
{
    if (dimprod (dims, ndims) > 0) {
	int	idim;
	char	*bp	= bytes;
	char	*ip	= (char*)ints;
	long	length[MAX_NC_DIMS];
	long	coords[MAX_NC_DIMS];

	for (idim = 0; idim < ndims; ++idim) {
	    length[idim]	= dims[idim]*basis[idim];
	    coords[idim]	= 0;
	}

	for (;;) {
	    *(int*)ip	= *bp++;
	    idim	= ndims - 1;
	carry:
	    ip	+= basis[idim];
	    if (++coords[idim] >= dims[idim]) {
		coords[idim]	= 0;
		ip		-= length[idim];
		if (--idim < 0)
		    break;
		goto carry;
	    }
        }
    }
}
#endif /* FORTRAN_HAS_NO_BYTE */

#ifdef FORTRAN_HAS_NO_SHORT
/*
 * Convert multi-dimensional array of shorts stored in ints to packed array of
 * shorts, in malloc'ed space.  Returns pointer to shorts or NULL if malloc
 * failed.
 */
static short *
itos(ints, dims, ndims)
     int *ints;		/* multi-dimensional array of ints */
     long *dims;			/* list of dimensions */
     int ndims;			/* number of dimensions in list */
{
    long iocount = dimprod (dims, ndims);	/* product of dimensions */
    short *shorts = (short *) malloc (iocount * sizeof (short));
    int *ip;
    short *sp = shorts;

    if (shorts != NULL)
      for (ip = ints; iocount > 0; iocount--)
	*sp++ = (short) *ip++;
    return shorts;
}

/*
 * Convert a generalized multi-dimensional array of shorts stored in ints to 
 * packed array of shorts, in malloc'ed space.  Returns pointer to shorts or 
 * NULL if malloc failed.
 */
static short *
itosg(ints, dims, basis, ndims)
     int *ints;			/* multi-dimensional array of integers */
     long *dims;			/* list of dimensions */
     long *basis;			/* memory access basis vector */
     int ndims;			/* number of dimensions in list */
{
    long iocount = dimprod (dims, ndims);	/* product of dimensions */
    short *shorts = (short *) malloc (iocount * sizeof (short));

    if (shorts != NULL && iocount > 0) {
	int	idim;
	char	*ip	= (char*)ints;
	short	*sp	= shorts;
	long	length[MAX_NC_DIMS];
	long	coords[MAX_NC_DIMS];

	for (idim = 0; idim < ndims; ++idim) {
	    length[idim]	= dims[idim]*basis[idim];
	    coords[idim]	= 0;
	}

	for (;;) {
	    *sp++	= (short)*(int*)ip;
	    idim	= ndims - 1;
	carry:
	    ip	+= basis[idim];
	    if (++coords[idim] >= dims[idim]) {
		coords[idim]	= 0;
		ip		-= length[idim];
		if (--idim < 0)
		    break;
		goto carry;
	    }
        }
    }

    return shorts;
}

/*
 * Convert a packed array of shorts into a generalized multi-dimensional array
 * of ints.
 */
static void
stoig(shorts, ints, dims, basis, ndims)
     short *shorts;		/* packed array of shorts */
     int *ints;			/* multi-dimensional array of integers */
     long *dims;		/* list of dimensions */
     long *basis;		/* memory access basis vector */
     int ndims;			/* number of dimensions in list */
{
    if (dimprod (dims, ndims) > 0) {
	int	idim;
	short	*sp	= shorts;
	char	*ip	= (char*)ints;
	long	length[MAX_NC_DIMS];
	long	coords[MAX_NC_DIMS];

	for (idim = 0; idim < ndims; ++idim) {
	    length[idim]	= dims[idim]*basis[idim];
	    coords[idim]	= 0;
	}

	for (;;) {
	    *(int*)ip	= *sp++;
	    idim	= ndims - 1;
	carry:
	    ip	+= basis[idim];
	    if (++coords[idim] >= dims[idim]) {
		coords[idim]	= 0;
		ip		-= length[idim];
		if (--idim < 0)
		    break;
		goto carry;
	    }
        }
    }
}
#endif /* FORTRAN_HAS_NO_SHORT */

#if defined __alpha || (_MIPS_SZLONG == 64) || defined __ia64 || (defined __sun && defined _LP64) || defined AIX5L64 || defined __x86_64__

/*
 * Convert multi-dimensional array of NCLONGs stored in ints to packed
 * array of longs, in malloc'ed space.  Returns pointer to longs or NULL
 * if malloc failed.
 */
static long *
itol(ints, dims, ndims)
    int		*ints;		/* multi-dimensional array of ints */
    long	*dims;		/* list of dimensions */
    int		ndims;		/* number of dimensions in list */
{
    long	iocount = dimprod (dims, ndims);
    long	*longs = (long *) malloc (iocount * sizeof (long));
    int		*ip;
    long	*lp = longs;

    if (longs != NULL)
	for (ip = ints; iocount > 0; iocount--)
	    *lp++ = (long) *ip++;
    return longs;
}

/*
 * Convert a generalized multi-dimensional array of longs stored in ints to 
 * packed array of longs, in malloc'ed space.  Returns pointer to longs or 
 * NULL if malloc failed.
 */
static long *
itolg(ints, dims, imap, ndims)
    int		*ints;		/* multi-dimensional array of integers */
    long	*dims;		/* list of dimensions */
    long	*imap;		/* memory access index mapping vector */
    int		ndims;		/* number of dimensions in list */
{
    long	iocount = dimprod (dims, ndims);
    long	*longs = (long *) malloc (iocount * sizeof (long));

    if (longs != NULL && iocount > 0) {
	int	idim;
	char	*ip	= (char*)ints;
	long	*lp	= longs;
	long	length[MAX_NC_DIMS];
	long	coords[MAX_NC_DIMS];

	for (idim = 0; idim < ndims; ++idim) {
	    length[idim]	= dims[idim]*imap[idim];
	    coords[idim]	= 0;
	}

	for (;;) {
	    *lp++	= (long)*(int*)ip;
	    idim	= ndims - 1;
	carry:
	    ip	+= imap[idim];
	    if (++coords[idim] >= dims[idim]) {
		coords[idim]	= 0;
		ip		-= length[idim];
		if (--idim < 0)
		    break;
		goto carry;
	    }
        }
    }

    return longs;
}

/*
 * Convert a packed array of longs into a generalized multi-dimensional array
 * of ints.
 */
static void
ltoig(longs, ints, dims, imap, ndims)
    long	*longs;		/* packed array of longs */
    int		*ints;		/* multi-dimensional array of integers */
    long	*dims;		/* list of dimensions */
    long	*imap;		/* memory access index mapping vector */
    int		ndims;		/* number of dimensions in list */
{
    if (dimprod (dims, ndims) > 0) {
	int	idim;
	long	*lp	= longs;
	char	*ip	= (char*)ints;
	long	length[MAX_NC_DIMS];
	long	coords[MAX_NC_DIMS];

	for (idim = 0; idim < ndims; ++idim) {
	    length[idim]	= dims[idim]*imap[idim];
	    coords[idim]	= 0;
	}

	for (;;) {
	    *(int*)ip	= *lp++;
	    idim	= ndims - 1;
	carry:
	    ip	+= imap[idim];
	    if (++coords[idim] >= dims[idim]) {
		coords[idim]	= 0;
		ip		-= length[idim];
		if (--idim < 0)
		    break;
		goto carry;
	    }
        }
    }
}
#endif	/* Alpha platform above */

/* ------------ APPLE FORTRAN jackets for netCDF Functions ------------ */

/* used to set the C global variable ncopts from Fortran */
void
#ifdef H4_ABSOFT
NCPOPT(val)
#else
ncpopt(val)
#endif
    int		*val;	
{
    ncopts = *val;
}


/* used to get the C global variable ncopts from Fortran */
void
#ifdef H4_ABSOFT
NCGOPT(val)
#else
ncgopt(val)
#endif
    int		*val;	
{
    *val = ncopts;
}

/*
 * creates a new netCDF file, returning a netCDF ID.  New netCDF
 * file is placed in define mode.
 */
int
#ifdef H4_ABSOFT
NCCRE(pathname, clobmode, rcode, pathnamelen)
#else
nccre(pathname, clobmode, rcode, pathnamelen)
#endif
    char	*pathname;	
    int		pathnamelen;
    int		*clobmode;	
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];
    int cdfid;

    nstrncpy (name, pathname, pathnamelen);
    if ((cdfid = nccreate (name, *clobmode)) != -1) {
	*rcode = 0;
	return (cdfid);
    }
    *rcode = ncerr;
    return (-1);
}


/* opens an existing netCDF file for access */
int
#ifdef H4_ABSOFT
NCOPN(pathname, rwmode, rcode, pathnamelen)
#else
ncopn(pathname, rwmode, rcode, pathnamelen)
#endif
    char	*pathname;	
    int		pathnamelen;
    int		*rwmode;	
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];
    int cdfid;

    nstrncpy (name, pathname, pathnamelen);
    if ((cdfid = ncopen (name, *rwmode)) != -1) {
	*rcode = 0;
	return (cdfid);
    }
    *rcode = ncerr;
    return (-1);
}


/* adds a new dimension to an open netCDF file in define mode */
int
#ifdef H4_ABSOFT
NCDDEF(cdfid, dimname, dimlen, rcode, dimnamelen)
#else
ncddef(cdfid, dimname, dimlen, rcode, dimnamelen)
#endif
    int		*cdfid;	
    char	*dimname;	
    int		dimnamelen;
    int		*dimlen;	
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];
    int dimid;

    nstrncpy (name, dimname, dimnamelen);
    if ((dimid = ncdimdef (*cdfid, name, (long)*dimlen)) != -1) {
	*rcode = 0;
	return (dimid + 1);
    }
    *rcode = ncerr;
    return (-1);
}


/*
 * returns the ID of a netCDF dimension, given the name of the
 * dimension
 */
int
#ifdef H4_ABSOFT
NCDID(cdfid, dimname, rcode, dimnamelen)
#else
ncdid(cdfid, dimname, rcode, dimnamelen)
#endif
    int		*cdfid;	
    char	*dimname;	
    int		dimnamelen;
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];
    int dimid;

    nstrncpy (name, dimname, dimnamelen);
    if ((dimid = ncdimid (*cdfid, name)) != -1) {
	*rcode = 0;
	return (dimid + 1);
    }
    *rcode = ncerr;
    return (-1);
}


/* adds a new variable to an open netCDF file in define mode */
int
#ifdef H4_ABSOFT
NCVDEF(cdfid, varname, datatype, ndims, dimarray, rcode, varnamelen)
#else
ncvdef(cdfid, varname, datatype, ndims, dimarray, rcode, varnamelen)
#endif
    int		*cdfid;	
    char	*varname;	
    int		varnamelen;
    int		*datatype;	
    int		*ndims;	
    int		*dimarray;	
    int		*rcode;	
{
    int varid, i, dimid[MAX_VAR_DIMS];
    char name[MAX_NC_NAME + 1];

    nstrncpy (name, varname, varnamelen);
    for (i = 0; i < *ndims; i++)
	dimid[i] = dimarray[i] - 1;
    reverse (dimid, *ndims);
    if ((varid = ncvardef (*cdfid, name, (nc_type) *datatype, *ndims,
			   dimid)) != -1) {
	*rcode = 0;
	return (varid + 1);
    }
    *rcode = ncerr;
    return (-1);
}


/* returns the ID of a netCDF variable given its name */
int
#ifdef H4_ABSOFT
NCVID(cdfid, varname, rcode, varnamelen)
#else
ncvid(cdfid, varname, rcode, varnamelen)
#endif
    int		*cdfid;	
    char	*varname;	
    int		varnamelen;
    int		*rcode;	
{
    int varid;
    char name[MAX_NC_NAME + 1];

    nstrncpy (name, varname, varnamelen);
    if ((varid = ncvarid (*cdfid, name)) != -1) {
	*rcode = 0;
	return (varid + 1);
    }
    *rcode = ncerr;
    return (-1);
}


/* returns number of bytes per netCDF data type */
int
#ifdef H4_ABSOFT
NCTLEN(datatype, rcode)
#else
nctlen(datatype, rcode)
#endif
    int		*datatype;	
    int		*rcode;	
{
    int itype;

    if ((itype = nctypelen ((nc_type) *datatype)) != -1) {
	*rcode = 0;
	return (itype);
    }
    *rcode = ncerr;
    return (-1);
}

/* closes an open netCDF file */
void
#ifdef H4_ABSOFT
NCCLOS(cdfid, rcode)
#else
ncclos(cdfid, rcode)
#endif
    int		*cdfid;	
    int		*rcode;	
{
    *rcode = 0;
    if (ncclose (*cdfid) == -1)
	*rcode = ncerr;
}

/* puts an open netCDF into define mode */
void
#ifdef H4_ABSOFT
NCREDF(cdfid, rcode)
#else
ncredf(cdfid, rcode)
#endif
    int		*cdfid;	
    int		*rcode;	
{
    *rcode = 0;
    if (ncredef (*cdfid) == -1)
	*rcode = ncerr;
}

/* takes an open netCDF out of define mode */
void
#ifdef H4_ABSOFT
NCENDF(cdfid, rcode)
#else
ncendf(cdfid, rcode)
#endif
    int		*cdfid;	
    int		*rcode;	
{
    *rcode = 0;
    if (ncendef (*cdfid) == -1)
	*rcode = ncerr;
}

/* returns information about an open netCDF file given its netCDF ID */
void
#ifdef H4_ABSOFT
NCINQ(cdfid, ndims, nvars, natts, recdim, rcode)
#else
ncinq(cdfid, ndims, nvars, natts, recdim, rcode)
#endif
    int		*cdfid;	
    int		*ndims;	
    int		*nvars;	
    int		*natts;	
    int		*recdim;	
    int		*rcode;	
{
    *rcode = 0;
    if (ncinquire (*cdfid, ndims, nvars, natts, recdim) == -1) {
	*rcode = ncerr;
	return;
    }
    if (*recdim != -1)
	(*recdim)++;
}

/*
 * makes sure that the disk copy of a netCDF file open for writing
 * is current
 */
void
#ifdef H4_ABSOFT
NCSNC(cdfid, rcode)
#else
ncsnc(cdfid, rcode)
#endif
    int		*cdfid;	
    int		*rcode;	
{
    *rcode = 0;
    if (ncsync (*cdfid) == -1)
	*rcode = ncerr;
}

/*
 * restores the netCDF to a known consistent state in case anything
 * goes wrong during the definition of new dimensions, variables
 * or attributes
 */
void
#ifdef H4_ABSOFT
NCABOR(cdfid, rcode)
#else
ncabor(cdfid, rcode)
#endif
    int		*cdfid;	
    int		*rcode;	
{
    *rcode = 0;
    if (ncabort (*cdfid) == -1)
	*rcode = ncerr;
}

/* returns the name and size of a dimension, given its ID */
void
#ifdef H4_ABSOFT
NCDINQ(cdfid, dimid, dimname, size, rcode, dimnamelen)
#else
ncdinq(cdfid, dimid, dimname, size, rcode, dimnamelen)
#endif
    int		*cdfid;	
    int		*dimid;	
    char	*dimname;	
    int		dimnamelen;
    int		*size;	
    int		*rcode;	
{
    long siz;
    char name[MAX_NC_NAME + 1];

    *rcode = 0;
    if (ncdiminq (*cdfid, *dimid - 1, name, &siz) == -1) {
	*rcode = ncerr;
	return;
    }
    *size = siz;
    if (strlen (name) > dimnamelen) {
	*rcode = NC_ESTS;
	handle_err ("NCDINQ", *rcode);
	return;
    }
    /* blank fill the input character string */
    fcdcpy (dimname, dimnamelen, name);
}

/* renames an existing dimension in a netCDF open for writing */
void
#ifdef H4_ABSOFT
NCDREN(cdfid, dimid, dimname, rcode, dimnamelen)
#else
ncdren(cdfid, dimid, dimname, rcode, dimnamelen)
#endif
    int		*cdfid;	
    int		*dimid;	
    char	*dimname;	
    int		dimnamelen;
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];

    nstrncpy (name, dimname, dimnamelen);
    *rcode = 0;
    if (ncdimrename (*cdfid, *dimid - 1, name) == -1)
	*rcode = ncerr;
}

/* returns information about a netCDF variable, given its ID */
void
#ifdef H4_ABSOFT
NCVINQ(cdfid, varid, varname, datatype, ndims, dimarray, natts, rcode, varnamelen)
#else
ncvinq(cdfid, varid, varname, datatype, ndims, dimarray, natts, rcode, varnamelen)
#endif
    int		*cdfid;	
    int		*varid;	
    char	*varname;	
    int		varnamelen;
    int		*datatype;	
    int		*ndims;	
    int		*dimarray;	
    int		*natts;	
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];
    int dimid[MAX_VAR_DIMS], i;

    *rcode = 0;
    if (ncvarinq (*cdfid, *varid - 1, name, (nc_type *) datatype, ndims, dimid,
		  natts) == -1) {
	*rcode = ncerr;
	return;
    }
    for (i = 0; i < *ndims; i++)
	dimarray[i] = dimid[i] + 1;
    reverse (dimarray, *ndims);
    if (strlen (name) > varnamelen) {
	*rcode = NC_ESTS;
	handle_err ("NCVINQ", *rcode);
	return;
    }
    fcdcpy (varname, varnamelen, name);
}

/* puts a single numeric data value into a variable of an open netCDF */
void
#ifdef H4_ABSOFT
NCVPT1(cdfid, varid, indices, value, rcode)
#else
ncvpt1(cdfid, varid, indices, value, rcode)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*indices;	
    void	*value;	
    int		*rcode;	
{
    int datatype, ndims, natts, i;
    long nindices[MAX_VAR_DIMS];
    int dimid[MAX_VAR_DIMS];

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0,
		  (nc_type *) & datatype, &ndims, dimid, &natts) == -1) {
	*rcode = ncerr;
	return;
    }
    for (i = 0; i < ndims; i++)
	nindices[i] = indices[i] - 1;
    revlongs (nindices, ndims);
    *rcode = 0;
#ifdef FORTRAN_HAS_NO_BYTE
    if ((nc_type) datatype == NC_BYTE) {	/* pack ints into bytes */
	char           bytes = *(int *) value;
	if (ncvarput1(*cdfid, *varid - 1, nindices,
		      (ncvoid *) &bytes) == -1) {
	    *rcode = ncerr;
	}
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_BYTE */
#ifdef FORTRAN_HAS_NO_SHORT
    if ((nc_type) datatype == NC_SHORT) {	/* pack ints into shorts */
	short          shorts = *(int *)value;
	if (ncvarput1(*cdfid, *varid - 1, nindices, (ncvoid *) &shorts) == -1) {
	    *rcode = ncerr;
	}
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_SHORT */
    if (ncvarput1 (*cdfid, *varid - 1, nindices, value) == -1) {
	*rcode = ncerr;
    }
}

/* puts a single character into an open netCDF file */
void
#ifdef H4_ABSOFT
NCVP1C(cdfid, varid, indices, chval, rcode, chvallen)
#else
ncvp1c(cdfid, varid, indices, chval, rcode, chvallen)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*indices;	
    char	*chval;	
    int		chvallen;
    int		*rcode;	
{
    int datatype, ndims, natts, i;
    long nindices[MAX_VAR_DIMS];
    int dimid[MAX_VAR_DIMS];

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0,
		  (nc_type *) & datatype, &ndims, dimid, &natts) == -1) {
	*rcode = ncerr;
	return;
    }
    for (i = 0; i < ndims; i++)
	nindices[i] = indices[i] - 1;
    revlongs (nindices, ndims);
    *rcode = 0;
    if (ncvarput1 (*cdfid, *varid - 1, nindices, (ncvoid *) chval) == -1) {
	*rcode = ncerr;
    }
}

/*
 * writes a hypercube of numeric values into a netCDF variable of an open
 * netCDF file
 */
void
#ifdef H4_ABSOFT
NCVPT(cdfid, varid, start, count, value, rcode)
#else
ncvpt(cdfid, varid, start, count, value, rcode)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*start;	
    int		*count;	
    void	*value;	
    int		*rcode;	
{
    long ncount[MAX_VAR_DIMS], nstart[MAX_VAR_DIMS], i;
    int ndims, datatype, dimarray[MAX_VAR_DIMS], natts;

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0, (nc_type *) & datatype,
		  &ndims, dimarray, &natts) == -1) {
	*rcode = ncerr;
	return;
    }
    for (i = 0; i < ndims; i++) {
	ncount[i] = count[i];
	nstart[i] = start[i] - 1;
    }
    revlongs (ncount, ndims);
    revlongs (nstart, ndims);

    *rcode = 0;
#ifdef FORTRAN_HAS_NO_BYTE
    if ((nc_type) datatype == NC_BYTE) {	/* pack ints into bytes */
	char *bytes = itob (value, ncount, ndims);
	if (bytes == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	    }
	if (ncvarput (*cdfid, *varid - 1, nstart, ncount,
	              (ncvoid *) bytes) == -1) {
	    *rcode = ncerr;
	}
	free (bytes);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_BYTE */
#ifdef FORTRAN_HAS_NO_SHORT
    if ((nc_type) datatype == NC_SHORT) { /* pack ints into shorts */
	short *shorts = itos (value, ncount, ndims);
	if (shorts == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	    }
	if (ncvarput (*cdfid, *varid - 1, nstart, ncount,
		      (ncvoid *) shorts) == -1) {
	    *rcode = ncerr;
	}
	free (shorts);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_SHORT */
    if (ncvarput (*cdfid, *varid - 1, nstart, ncount, value) == -1) {
	*rcode = ncerr;
    }
}

/* writes a hypercube of character values into an open netCDF file */
void
#ifdef H4_ABSOFT
NCVPTC(cdfid, varid, start, count, string, lenstr, rcode, stringlen)
#else
ncvptc(cdfid, varid, start, count, string, lenstr, rcode, stringlen)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*start;	
    int		*count;	
    char	*string;	
    int		stringlen;
    int		*lenstr;	
    int		*rcode;	
{
    long ncount[MAX_VAR_DIMS], nstart[MAX_VAR_DIMS], i;
    int ndims, datatype, dimarray[MAX_VAR_DIMS], natts;

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0,
		  (nc_type *) & datatype, &ndims, dimarray, &natts) == -1) {
	*rcode = ncerr;
	return;
    }
    for (i = 0; i < ndims; i++) {
	ncount[i] = count[i];
	nstart[i] = start[i] - 1;
    }
    revlongs (ncount, ndims);
    revlongs (nstart, ndims);
    if (dimprod(ncount,ndims) > *lenstr) {
	*rcode = NC_ESTS;
	handle_err ("NCVPTC", *rcode);
	return;
    }
    *rcode = 0;
    if (ncvarput (*cdfid, *varid - 1, nstart, ncount, (ncvoid *) string) == -1) {
	*rcode = ncerr;
    }
}

/*
 * writes a generalized hypercube of numeric values into a netCDF variable of 
 * an open netCDF file
 */
void
#ifdef H4_ABSOFT
NCVPTG(cdfid, varid, start, count, stride, basis, value, rcode)
#else
ncvptg(cdfid, varid, start, count, stride, basis, value, rcode)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*start;	
    int		*count;	
    int		*stride;	
    int		*basis;	
    void	*value;	
    int		*rcode;	
{
    long ncount[MAX_VAR_DIMS], nstart[MAX_VAR_DIMS], i;
    long nstride[MAX_VAR_DIMS], nbasis[MAX_VAR_DIMS];
    long tmpbasis;
    int ndims, datatype, dimarray[MAX_VAR_DIMS], natts;

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0, (nc_type *) & datatype,
		  &ndims, dimarray, &natts) == -1) {
	*rcode = ncerr;
	return;
    }
#ifdef FORTRAN_HAS_NO_BYTE
    if (datatype == NC_CHAR || datatype == NC_BYTE)
	tmpbasis	= nctypelen(NC_LONG);
    else
#endif
#ifdef FORTRAN_HAS_NO_SHORT
    if (datatype == NC_SHORT)
	tmpbasis	= nctypelen(NC_LONG);
    else
#endif
#if defined __alpha || (_MIPS_SZLONG == 64) || defined __ia64 || (defined __sun && defined _LP64) || defined AIX5L64 || defined __x86_64__

    if (datatype == NC_LONG)
	tmpbasis	= sizeof(int);
    else
#endif
	tmpbasis	= nctypelen(datatype);
    for (i = 0; i < ndims; i++) {
	ncount[i] = count[i];
	nstart[i] = start[i] - 1;
	nstride[i] = stride[0] == 0 ? 1 : stride[i];
	nbasis[i] = basis[0] == 0 ? tmpbasis : basis[i];
	tmpbasis *= count[i];
    }
    revlongs (ncount, ndims);
    revlongs (nstart, ndims);
    revlongs (nstride, ndims);
    revlongs (nbasis, ndims);

    *rcode = 0;
#ifdef FORTRAN_HAS_NO_BYTE
    if ((nc_type) datatype == NC_BYTE) {	/* pack ints into bytes */
	/*
	 * Release 2.3.1 had a bug in the following line: it used count
	 * rather than ncount.
	 */
	char *bytes = itobg (value, ncount, nbasis, ndims);
	if (bytes == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	    }
	if (ncvarputg (*cdfid, *varid - 1, nstart, ncount, nstride, 
		       (long*)NULL, (ncvoid *) bytes) == -1) {
	    *rcode = ncerr;
	}
	free (bytes);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_BYTE */
#ifdef FORTRAN_HAS_NO_SHORT
    if ((nc_type) datatype == NC_SHORT) { /* pack ints into shorts */
	/*
	 * Release 2.3.1 had a bug in the following line: it used count
	 * rather than ncount.
	 */
	short *shorts = itosg (value, ncount, nbasis, ndims);
	if (shorts == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	    }
	if (ncvarputg (*cdfid, *varid - 1, nstart, ncount, nstride,
		      (long*)NULL, (ncvoid *) shorts) == -1) {
	    *rcode = ncerr;
	}
	free (shorts);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_SHORT */
    if (ncvarputg (*cdfid, *varid - 1, nstart, ncount, nstride, nbasis,
		   value) == -1) {
	*rcode = ncerr;
    }
}

/*
 * writes a generalized hypercube of character values into a netCDF variable of 
 * an open netCDF file
 */
void
#ifdef H4_ABSOFT
NCVPGC(cdfid, varid, start, count, stride, basis, string, rcode, stringlen)
#else
ncvpgc(cdfid, varid, start, count, stride, basis, string, rcode, stringlen)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*start;	
    int		*count;	
    int		*stride;	
    int		*basis;	
    char	*string;	
    int		stringlen;
    int		*rcode;	
{
    long ncount[MAX_VAR_DIMS], nstart[MAX_VAR_DIMS], i;
    long nstride[MAX_VAR_DIMS], nbasis[MAX_VAR_DIMS];
    long tmpbasis;
    int ndims, datatype, dimarray[MAX_VAR_DIMS], natts;

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0, (nc_type *) & datatype,
		  &ndims, dimarray, &natts) == -1) {
	*rcode = ncerr;
	return;
    }
    tmpbasis	= nctypelen(datatype);
    for (i = 0; i < ndims; i++) {
	ncount[i] = count[i];
	nstart[i] = start[i] - 1;
	nstride[i] = stride[0] == 0 ? 1 : stride[i];
	nbasis[i] = basis[0] == 0 ? tmpbasis : basis[i];
	tmpbasis *= count[i];
    }
    revlongs (ncount, ndims);
    revlongs (nstart, ndims);
    revlongs (nstride, ndims);
    revlongs (nbasis, ndims);

    *rcode = 0;
    if (ncvarputg (*cdfid, *varid - 1, nstart, ncount, nstride, nbasis,
		   (ncvoid*)string) == -1) {
	*rcode = ncerr;
    }
}

/* gets a single numeric value from a variable of an open netCDF file */
void
#ifdef H4_ABSOFT
NCVGT1(cdfid, varid, indices, value, rcode)
#else
ncvgt1(cdfid, varid, indices, value, rcode)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*indices;	
    void	*value;	
    int		*rcode;	
{
    long nindices[MAX_VAR_DIMS], i;
    int datatype, ndims, dimarray[MAX_VAR_DIMS], natts;

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0, (nc_type *) & datatype,
		  &ndims, dimarray, &natts) == -1) {
	*rcode = ncerr;
	return;
    }
    for (i = 0; i < ndims; i++) {
	nindices[i] = indices[i] - 1;
    }
    revlongs (nindices, ndims);
    *rcode = 0;
#ifdef FORTRAN_HAS_NO_BYTE
    if ((nc_type) datatype == NC_BYTE) {
	char           bytes;
	int            *ip = (int *) value;
	char           *bp = &bytes;

	if (ncvarget1(*cdfid, *varid - 1, nindices, (ncvoid *) &bytes) == -1) {
	    *rcode = ncerr;
	    return;
	}
	*ip = *bp;
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_BYTE */
#ifdef FORTRAN_HAS_NO_SHORT
    if ((nc_type) datatype == NC_SHORT) {
	short          shorts;
	int            *ip = (int *) value;
	short          *sp = &shorts;

	if (ncvarget1(*cdfid, *varid - 1, nindices, (ncvoid *) &shorts) == -1) {
	    *rcode = ncerr;
	    return;
	}
	*ip = *sp;
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_SHORT */
    if (ncvarget1 (*cdfid, *varid - 1, nindices, value) == -1) {
	*rcode = ncerr;
    }
}

/*
 * gets a single character data value from a variable of an open
 * netCDF file
 */
void
#ifdef H4_ABSOFT
NCVG1C(cdfid, varid, indices, chval, rcode, chvallen)
#else
ncvg1c(cdfid, varid, indices, chval, rcode, chvallen)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*indices;	
    char	*chval;	
    int		chvallen;
    int		*rcode;	
{
    long nindices[MAX_VAR_DIMS];
    int i, datatype, ndims, dimarray[MAX_VAR_DIMS], natts;

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0,
		  (nc_type *) & datatype, &ndims, dimarray, &natts) == -1) {
	*rcode = ncerr;
	return;
    }

    for (i = 0; i < ndims; i++) {
	nindices[i] = indices[i] - 1;
    }
    revlongs (nindices, ndims);
    *rcode = 0;
    if (ncvarget1 (*cdfid, *varid - 1, nindices, (ncvoid *) chval) == -1) {
	*rcode = ncerr;
    }
}

/*
 * reads a hypercube of numeric values from a netCDF variable of an open
 * netCDF file
 */
void
#ifdef H4_ABSOFT
NCVGT(cdfid, varid, start, count, value, rcode)
#else
ncvgt(cdfid, varid, start, count, value, rcode)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*start;	
    int		*count;	
    void	*value;	
    int		*rcode;	
{
    long ncount[MAX_VAR_DIMS], nstart[MAX_VAR_DIMS];
    int i, ndims, datatype, dimarray[MAX_VAR_DIMS], natts;

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0, (nc_type *) & datatype,
		  &ndims, dimarray, &natts) == -1) {
	*rcode = ncerr;
	return;
    }
    for (i = 0; i < ndims; i++) {
	ncount[i] = count[i];
	nstart[i] = start[i] - 1;
    }
    revlongs (ncount, ndims);
    revlongs (nstart, ndims);

    *rcode = 0;
#ifdef FORTRAN_HAS_NO_BYTE
    if ((nc_type) datatype == NC_BYTE) {
	long iocount = dimprod (ncount, ndims);	/* product of dimensions */
	char *bytes = (char *) malloc (iocount * sizeof (char));
	int *ip;
	char *bp = bytes;

	if (bytes == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	}
	if (ncvarget (*cdfid, *varid - 1, nstart, ncount,
		      (ncvoid *) bytes) == -1) {
	    *rcode = ncerr;
	    free (bytes);
	    return;
	}
	for (ip = (int *) value; iocount > 0; iocount--)
	  *ip++ = *bp++;
	free (bytes);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_BYTE */
#ifdef FORTRAN_HAS_NO_SHORT
    if ((nc_type) datatype == NC_SHORT) {
	long iocount = dimprod (ncount, ndims);	/* product of dimensions */
	short *shorts = (short *) malloc (iocount * sizeof (short));
	int *ip;
	short *sp = shorts;

	if (shorts == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	}
	if (ncvarget (*cdfid, *varid - 1, nstart, ncount,
		      (ncvoid *) shorts) == -1) {
	    *rcode = ncerr;
	    free (shorts);
	    return;
	}
	for (ip = (int *) value; iocount > 0; iocount--)
	    *ip++ = *sp++;
	free (shorts);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_SHORT */
    if (ncvarget (*cdfid, *varid - 1, nstart, ncount, value) == -1) {
	*rcode = ncerr;
    }
}

/* reads a hypercube of character values from a netCDF variable */
void
#ifdef H4_ABSOFT
NCVGTC(cdfid, varid, start, count, string, lenstr, rcode, stringlen)
#else
ncvgtc(cdfid, varid, start, count, string, lenstr, rcode, stringlen)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*start;	
    int		*count;	
    char	*string;	
    int		stringlen;
    int		*lenstr;	
    int		*rcode;	
{
    long ncount[MAX_VAR_DIMS], nstart[MAX_VAR_DIMS];
    int i, ndims, datatype, dimarray[MAX_VAR_DIMS], natts;
    int prod = 1;

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0,
		  (nc_type *) & datatype, &ndims, dimarray, &natts) == -1) {
	*rcode = ncerr;
	return;
    }
    for (i = 0; i < ndims; i++) {
	ncount[i] = count[i];
	nstart[i] = start[i] - 1;
	prod *= count[i];
    }
    if (prod > *lenstr) {
	*rcode = NC_ESTS;
	handle_err ("NCVGTC", *rcode);
	return;
    }
    revlongs (ncount, ndims);
    revlongs (nstart, ndims);
    *rcode = 0;
    if (ncvarget (*cdfid, *varid - 1, nstart, ncount, (ncvoid *) string) == -1) {
	*rcode = ncerr;
	return;
    }

    for (i = prod; i < *lenstr; i++)
	string[i] = ' ';
}

/*
 * reads a generalized hypercube of numeric values from a netCDF variable of an 
 * open netCDF file
 */
void
#ifdef H4_ABSOFT
NCVGTG(cdfid, varid, start, count, stride, basis, value, rcode)
#else
ncvgtg(cdfid, varid, start, count, stride, basis, value, rcode)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*start;	
    int		*count;	
    int		*stride;	
    int		*basis;	
    void	*value;	
    int		*rcode;	
{
    long ncount[MAX_VAR_DIMS], nstart[MAX_VAR_DIMS];
    long nstride[MAX_VAR_DIMS], nbasis[MAX_VAR_DIMS];
    long tmpbasis;
    int i, ndims, datatype, dimarray[MAX_VAR_DIMS], natts;

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0, (nc_type *) & datatype,
		  &ndims, dimarray, &natts) == -1) {
	*rcode = ncerr;
	return;
    }
#ifdef FORTRAN_HAS_NO_BYTE
    if (datatype == NC_CHAR || datatype == NC_BYTE)
	tmpbasis	= nctypelen(NC_LONG);
    else
#endif
#ifdef FORTRAN_HAS_NO_SHORT
    if (datatype == NC_SHORT)
	tmpbasis	= nctypelen(NC_LONG);
    else
#endif
#if defined __alpha || (_MIPS_SZLONG == 64) || defined __ia64 || (defined __sun && defined _LP64) || defined AIX5L64 || defined __x86_64__

    if (datatype == NC_LONG)
	tmpbasis	= sizeof(int);
    else
#endif
	tmpbasis	= nctypelen(datatype);
    for (i = 0; i < ndims; i++) {
	ncount[i] = count[i];
	nstart[i] = start[i] - 1;
	nstride[i] = stride[0] == 0 ? 1 : stride[i];
	nbasis[i] = basis[0] == 0 ? tmpbasis : basis[i];
	tmpbasis *= count[i];
    }
    revlongs (ncount, ndims);
    revlongs (nstart, ndims);
    revlongs (nstride, ndims);
    revlongs (nbasis, ndims);

    *rcode = 0;
#ifdef FORTRAN_HAS_NO_BYTE
    if ((nc_type) datatype == NC_BYTE) {
	long iocount = dimprod (ncount, ndims);	/* product of dimensions */
	char *bytes = (char *) malloc (iocount * sizeof (char));
	int *ip;
	char *bp = bytes;

	if (bytes == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	}
	if (ncvargetg (*cdfid, *varid - 1, nstart, ncount, nstride,
		      (long*)NULL, (ncvoid *) bytes) == -1) {
	    *rcode = ncerr;
	    free (bytes);
	    return;
	}
	/*
	 * Release 2.3.1 had a bug in the following line: it used basis
	 * rather than nbasis.
	 */
	btoig(bytes, (int*)value, ncount, nbasis, ndims);
	free (bytes);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_BYTE */
#ifdef FORTRAN_HAS_NO_SHORT
    if ((nc_type) datatype == NC_SHORT) {
	long iocount = dimprod (ncount, ndims);	/* product of dimensions */
	short *shorts = (short *) malloc (iocount * sizeof (short));
	int *ip;
	short *sp = shorts;

	if (shorts == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	}
	if (ncvargetg (*cdfid, *varid - 1, nstart, ncount, nstride, 
		       (long*)NULL, (ncvoid *) shorts) == -1) {
	    *rcode = ncerr;
	    free (shorts);
	    return;
	}
	/*
	 * Release 2.3.1 had a bug in the following line: it used basis
	 * rather than nbasis.
	 */
	stoig(shorts, (int*)value, ncount, nbasis, ndims);
	free (shorts);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_SHORT */
    if (ncvargetg (*cdfid, *varid - 1, nstart, ncount, nstride,
		   nbasis, value) == -1) {
	*rcode = ncerr;
    }
}

/*
 * reads a generalized hypercube of character values from a netCDF variable 
 * of an open netCDF file
 */
void
#ifdef H4_ABSOFT
NCVGGC(cdfid, varid, start, count, stride, basis, string, rcode, stringlen)
#else
ncvggc(cdfid, varid, start, count, stride, basis, string, rcode, stringlen)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*start;	
    int		*count;	
    int		*stride;	
    int		*basis;	
    char	*string;	
    int		stringlen;
    int		*rcode;	
{
    long ncount[MAX_VAR_DIMS], nstart[MAX_VAR_DIMS];
    long nstride[MAX_VAR_DIMS], nbasis[MAX_VAR_DIMS];
    long tmpbasis;
    int i, ndims, datatype, dimarray[MAX_VAR_DIMS], natts;

    if (ncvarinq (*cdfid, *varid - 1, (char *) 0, (nc_type *) & datatype,
		  &ndims, dimarray, &natts) == -1) {
	*rcode = ncerr;
	return;
    }
    tmpbasis	= nctypelen(datatype);
    for (i = 0; i < ndims; i++) {
	ncount[i] = count[i];
	nstart[i] = start[i] - 1;
	nstride[i] = stride[0] == 0 ? 1 : stride[i];
	nbasis[i] = basis[0] == 0 ? tmpbasis : basis[i];
	tmpbasis *= count[i];
    }
    revlongs (ncount, ndims);
    revlongs (nstart, ndims);
    revlongs (nstride, ndims);
    revlongs (nbasis, ndims);

    *rcode = 0;
    if (ncvargetg (*cdfid, *varid - 1, nstart, ncount, nstride,
		   nbasis, (ncvoid*)string) == -1) {
	*rcode = ncerr;
    }
}

/* changes the name of a netCDF variable in an open netCDF file */
void
#ifdef H4_ABSOFT
NCVREN(cdfid, varid, varname, rcode, varnamelen)
#else
ncvren(cdfid, varid, varname, rcode, varnamelen)
#endif
    int		*cdfid;	
    int		*varid;	
    char	*varname;	
    int		varnamelen;
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];

    nstrncpy (name, varname, varnamelen);
    *rcode = 0;
    if (ncvarrename (*cdfid, *varid - 1, name) == -1) {
	*rcode = ncerr;
    }
}

/*
 * adds or changes a numeric variable or global attribute of an open
 * netCDF file
 */
void
#ifdef H4_ABSOFT
NCAPT(cdfid, varid, attname, datatype, attlen, value, rcode, attnamelen)
#else
ncapt(cdfid, varid, attname, datatype, attlen, value, rcode, attnamelen)
#endif
    int		*cdfid;	
    int		*varid;	
    char	*attname;	
    int		attnamelen;
    int		*datatype;	
    int		*attlen;	
    void	*value;	
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];

    nstrncpy (name, attname, attnamelen);

    *rcode = 0;
#ifdef FORTRAN_HAS_NO_BYTE
    if ((nc_type) *datatype == NC_BYTE) {	/* pack ints into bytes */
	char *bytes = itob (value, attlen, 1);

	if (bytes == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	}
	if (ncattput (*cdfid, *varid - 1, name, (nc_type) *datatype, *attlen,
		      (ncvoid *) bytes) == -1) {
	    *rcode = ncerr;
	}
	free (bytes);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_BYTE */
#ifdef FORTRAN_HAS_NO_SHORT
    if ((nc_type) *datatype == NC_SHORT) {	/* pack ints into shorts */
	short *shorts = itos (value, attlen, 1);

	if (shorts == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	}
	if (ncattput (*cdfid, *varid - 1, name, (nc_type) *datatype, *attlen,
		      (ncvoid *) shorts) == -1) {
	    *rcode = ncerr;
	}
	free (shorts);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_SHORT */
    if (ncattput (*cdfid, *varid - 1, name, (nc_type) *datatype, *attlen,
		  value) == -1) {
	*rcode = ncerr;
    }
}

/*
 * adds or changes a character variable or global attribute
 * of an open netCDF file
 */
void
#ifdef H4_ABSOFT
NCAPTC(cdfid, varid, attname, datatype, lenstr, string, rcode, attnamelen, stringlen)
#else
ncaptc(cdfid, varid, attname, datatype, lenstr, string, rcode, attnamelen, stringlen)
#endif
    int		*cdfid;	
    int		*varid;	
    char	*attname;	
    int		attnamelen;
    int		*datatype;	
    int		*lenstr;	
    char	*string;	
    int		stringlen;
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];
    char *value;

    nstrncpy (name, attname, attnamelen);
    if (((value = malloc ((unsigned) *lenstr + 1)) == NULL) || (*lenstr == 0)) {
	*rcode = NC_ESTS;
	handle_err ("NCAPTC", *rcode);
	return;
    }
    (void) fstrncpy (value, string, *lenstr);
    *rcode = 0;
    if (ncattput (*cdfid, *varid - 1, name, (nc_type) *datatype, *lenstr,
		  (ncvoid *) value) == -1) {
	*rcode = ncerr;
    }
    free (value);
}

/*
 * returns information about a netCDF attribute given its variable
 * ID and name
 */
void
#ifdef H4_ABSOFT
NCAINQ(cdfid, varid, attname, datatype, attlen, rcode, attnamelen)
#else
ncainq(cdfid, varid, attname, datatype, attlen, rcode, attnamelen)
#endif
    int		*cdfid;	
    int		*varid;	
    char	*attname;	
    int		attnamelen;
    int		*datatype;	
    int		*attlen;	
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];

    nstrncpy (name, attname, attnamelen);
    *rcode = 0;
    if (ncattinq (*cdfid, *varid - 1, name, (nc_type *) datatype, attlen) == -1) {
	*rcode = ncerr;
    }
}

/*
 * gets the value of a netCDF attribute given its variable ID
 * and name
 */
void
#ifdef H4_ABSOFT
NCAGT(cdfid, varid, attname, value, rcode, attnamelen)
#else
ncagt(cdfid, varid, attname, value, rcode, attnamelen)
#endif
    int		*cdfid;	
    int		*varid;	
    char	*attname;	
    int		attnamelen;
    void	*value;	
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];
    int datatype;
    int attlen;

    nstrncpy (name, attname, attnamelen);
    *rcode = 0;
    if (ncattinq (*cdfid, *varid - 1, name, (nc_type *) &datatype, &attlen)
	    == -1) {
	*rcode = ncerr;
	return;
    }
#ifdef FORTRAN_HAS_NO_BYTE
    if ((nc_type) datatype == NC_BYTE) {
	char *bytes = (char *) malloc (attlen);
	int *ip;
	char *bp = bytes;

	if (bytes == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	}
	if (ncattget (*cdfid, *varid - 1, name, (ncvoid *) bytes) == -1) {
	    *rcode = ncerr;
	    free (bytes);
	    return;
	}
	for (ip = (int *) value; attlen > 0; attlen--)
	    *ip++ = *bp++;
	free (bytes);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_BYTE */
#ifdef FORTRAN_HAS_NO_SHORT
    if ((nc_type) datatype == NC_SHORT) {
	short *shorts = (short *) malloc (attlen * sizeof (short));
	int *ip;
	short *sp = shorts;

	if (shorts == NULL) {
	    *rcode = NC_SYSERR;
	    return;
	}
	if (ncattget (*cdfid, *varid - 1, name, (ncvoid *) shorts) == -1) {
	    *rcode = ncerr;
	    free (shorts);
	    return;
	}
	for (ip = (int *) value; attlen > 0; attlen--)
	    *ip++ = *sp++;
	free (shorts);
	return;
    }				/* else */
#endif				/* FORTRAN_HAS_NO_SHORT */
    if (ncattget (*cdfid, *varid - 1, name, value) == -1) {
	*rcode = ncerr;
    }
}

/*
 * gets the value of a netCDF character attribute given its variable
 * ID and name
 */
void
#ifdef H4_ABSOFT
NCAGTC(cdfid, varid, attname, string, lenstr, rcode, attnamelen, stringlen)
#else
ncagtc(cdfid, varid, attname, string, lenstr, rcode, attnamelen, stringlen)
#endif
    int		*cdfid;	
    int		*varid;	
    char	*attname;	
    int		attnamelen;
    char	*string;	
    int		stringlen;
    int		*lenstr;	
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];
    int datatype;
    int attlen;
    int i;

    nstrncpy (name, attname, attnamelen);
    *rcode = 0;
    if (ncattinq (*cdfid, *varid - 1, name, (nc_type *) &datatype, &attlen) == -1) {
	*rcode = ncerr;
	return;
    }
    if (attlen > *lenstr) {
	*rcode = NC_ESTS;
	handle_err ("NCAGTC", *rcode);
	return;
    }
    if (ncattget (*cdfid, *varid - 1, name, (ncvoid *) string) == -1) {
	*rcode = ncerr;
	return;
    }

    for (i = attlen; i < *lenstr; i++)
	string[i] = ' ';
}

/* copies an attribute from one open netCDF file to another */
void
#ifdef H4_ABSOFT
NCACPY(incdfid, invarid, attname, outcdfid, outvarid, rcode, attnamelen)
#else
ncacpy(incdfid, invarid, attname, outcdfid, outvarid, rcode, attnamelen)
#endif
    int		*incdfid;	
    int		*invarid;	
    char	*attname;	
    int		attnamelen;
    int		*outcdfid;	
    int		*outvarid;	
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];

    nstrncpy (name, attname, attnamelen);
    *rcode = 0;
    if (ncattcopy (*incdfid, *invarid - 1, name,
		   *outcdfid, *outvarid - 1) == -1) {
	*rcode = ncerr;
    }
}

/*
 * gets the name of an attribute given its variable ID and number
 * as an attribute of that variable
 */
void
#ifdef H4_ABSOFT
NCANAM(cdfid, varid, attnum, attname, rcode, attnamelen)
#else
ncanam(cdfid, varid, attnum, attname, rcode, attnamelen)
#endif
    int		*cdfid;	
    int		*varid;	
    int		*attnum;	
    char	*attname;	
    int		attnamelen;
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];

    *rcode = 0;
    if (ncattname (*cdfid, *varid - 1, *attnum - 1, name) == -1) {
	*rcode = ncerr;
	return;
    }
    if (strlen (name) > attnamelen) {
	*rcode = NC_ESTS;
	handle_err ("NCANAM", *rcode);
	return;
    }
    fcdcpy (attname, attnamelen, name);
}


/* renames an attribute in an open netCDF file */
void
#ifdef H4_ABSOFT
NCAREN(cdfid, varid, attname, newname, rcode, attnamelen, newnamelen)
#else
ncaren(cdfid, varid, attname, newname, rcode, attnamelen, newnamelen)
#endif
    int		*cdfid;	
    int		*varid;	
    char	*attname;	
    int		attnamelen;
    char	*newname;	
    int		newnamelen;
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1], nname[MAX_NC_NAME + 1];

    nstrncpy (name, attname, attnamelen);
    nstrncpy (nname, newname, newnamelen);
    *rcode = 0;
    if (ncattrename (*cdfid, *varid - 1, name, nname) == -1) {
	*rcode = ncerr;
    }
}

/*
 * deletes an attribute from an open netCDF file given the attribute
 * name
 */
void
#ifdef H4_ABSOFT
NCADEL(cdfid, varid, attname, rcode, attnamelen)
#else
ncadel(cdfid, varid, attname, rcode, attnamelen)
#endif
    int		*cdfid;	
    int		*varid;	
    char	*attname;	
    int		attnamelen;
    int		*rcode;	
{
    char name[MAX_NC_NAME + 1];

    nstrncpy (name, attname, attnamelen);
    *rcode = 0;
    if (ncattdel (*cdfid, *varid - 1, name) == -1) {
	*rcode = ncerr;
    }
}


/*
 * sets the fill mode of a netCDF file open for writing
 */
int
#ifdef H4_ABSOFT
NCSFIL(cdfid, fillmode, rcode)
#else
ncsfil(cdfid, fillmode, rcode)
#endif
    int		*cdfid;	
    int		*fillmode;	
    int		*rcode;	
{
    int retval;

    if ((retval = ncsetfill (*cdfid, *fillmode)) != -1) {
	*rcode = 0;
	return retval;
    }
    *rcode = ncerr;
    return (-1);
}
