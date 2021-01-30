# -*- coding: utf-8 -*-

"""
Description :
-------------
    Extracts the bits from a bitflag and prints it out in a binary format

Usage :
-------
    The tool can be used in 2 ways :

    1) by specifying the first bit position and the flag width

            python get_bitflag <flag-word> <1st-bit-index> <width>

       where :

        <flag-word>  : the value that contains the bits to extract
        <first_bit>  : the position of the first significant bit ( starting from 0 )
        <flag_width> : the number of bits of the flag to read


    2) by specifying explicitly the bit selection mask

            python get_bitflag <flag-word> <bitmask>

       where :

        <flag-word> : the value that contains the bits to extract
        <mask>      : the bits selection mask

    All input values can be specified either in decimal ( by default ), hexadecimal or binary format.
    For using hexadecimal values, preceed the values by "0x" and for binary by "0b"

Example :
---------

    REM : All the following forms are exactly equivalent and leads to 3. Only the base of the input values differs,
          and how the bits are selected

    --- flag selection by mask ---

        python get_bitflag.py 59 48
        python get_bitflag.py 0x3b 0x30
        python get_bitflag.py 0b111011 0b110000

    All will print out 3 : it selects the values the bits number 4 and 5  ( starting from 0 )

    --- flag selection by first bit and width ---

        python get_bitflag.py 59 4 2
        python get_bitflag.py 0x3b 4 2
        python get_bitflag.py 0b111011 4 2

    All will print out 3 : it constructs the mask for selecting the 2 bits starting from index 4, ie 110000

Prerequisites :
---------------
    python >= 2.5 ; not tested but probably all versions

Author :
--------
    CGTD-ICARE/UDEV Nicolas PASCAL ( nicolas.pascal-at-icare.univ-lille1.fr  )

License :
---------
    This file must be used under the terms of the CeCILL.
    This source file is licensed as described in the file COPYING, which
    you should have received as part of this distribution.  The terms
    are also available at
    http://www.cecill.info/licences/Licence_CeCILL_V2-en.txt

History :
---------
    v1.0.0 : 2009/12/07
        - Add comments, bad values checking, hexadecimal and binary inputs support

    v0.1.0 : 2009/12/04
        - creation
"""

import sys

# if set to true, print detailled intermediate results
__DEBUG__=False

def get_bitflag_by_range ( flag_word, first_bit, flag_width ) :
    """
    @brief read the bit flag values by specifying the first bit position and the flag width
    @warning if flag_width is null, an exception is raised
    @param flag_word flag word where are stored the bits to extract
    @param flag_width the number of bits of the flag
    @return the bit flag value
    """
    if flag_width <= 0 :
        raise ValueError ( "Invalid width value %d. Must be a strictly positive integer"%flag_width )

    # construct the bitflag selection mask
    mask = get_mask ( first_bit, flag_width )
    return get_bitflag_by_mask ( flag_word, mask )

def get_bitflag_by_mask ( flag_word, mask ) :
    """
    @brief read the bit flag values by an explicit specification of the mask
    @param flag_word flag word where are stored the bits to extract
    @param mask the bits selection mask, specified as an integer
    @return the bit flag value
    """
    # find the position of the first not null bit of the mask
    first_bit_pos = get_first_bit_pos ( mask )
    # apply a binary AND between value and mask, then shift result ot first significant bit
    return ( ( flag_word & mask ) >> first_bit_pos )

def get_first_bit_pos ( v ):
    """
    @brief return the position of the first significant ( ie not null ) bit of a value, by increasing weight
    @param v an integer value
    """
    if v == 0 :
        return 0

    bit_pos = 0
    while ( ( v & 1 ) == 0 ) :
        bit_pos = bit_pos + 1
        v = v >> 1
    return bit_pos

def get_mask ( first_bit, flag_width ) :
    """
    @brief construct the mask of a bitfield specified by the position of the first significant bit
    and the width, in number of bits, of the flag to read
    @param first_bit position of the first significant bit
    @param flag_width number of bits, of the flag to read
    @return the mask value, as an integer matching the binary : "flag_width" number of 1 + " first_bit" number of 0"
    """
    mask = 0
    for exp in xrange( flag_width ):
        mask += 2 ** ( first_bit + exp )
    return mask

def to_bin_str ( v ):
    """
    @brief return the binary representation of v as a string
    @param v an integer value
    @return the binary representation of v as a string
    """
    if v :
        return to_bin_str (  v >> 1 ) + str ( v & 1 )
    else :
        return ""

def usage ():
    """
    @brief build the script usage string
    @return the script usage as a string
    """
    s  = ""
    s += "Usage :\n"
    s += "\tpython get_bitflag <flag-word> <1st-bit-index> <width>\n\n"
    s += "where :\n"
    s += "\t<flag-word>  : the value that contains the bits to extract\n"
    s += "\t<first_bit>  : the position of the first significant bit ( starting from 0 )\n"
    s += "\t<flag_width> : the number of bits of the flag to read\n"
    s += "\nOr\n"
    s += "\tpython get_bitflag <flag-word> <bitmask>\n\n"
    s += "where :\n"
    s += "\t<flag-word>  : the value that contains the bits to extract\n"
    s += "\t<bitmask>  : the bits selection mask\n\n"
    s += "All input values can be specified either in decimal ( by default ), hexadecimal or binary format.\n"
    s += "For using hexadecimal values, preceed the values by \"0x\" and for binary by \"0b\"\n"
    return s

def main () :
    """
    @brief program entry point
    """
    if   len ( sys.argv ) == 3 :
        # --- read bits using an explicit mask --- #
        val  = int ( sys.argv[1], 0 )
        mask = int ( sys.argv[2], 0 )
        flag = get_bitflag_by_mask ( val, mask )
        if __DEBUG__ :
            # print all the details of the operation
            print "val  = %16s\t => %d"%( to_bin_str ( val ), val )
            print "mask = %16s\t => %d"%( to_bin_str ( mask), mask )
            print "res  = %16s\t => %d"%( to_bin_str ( flag ),  flag )
        else :
            # just print the result
            print flag

    elif len ( sys.argv ) == 4 :
        # --- read bits by specifying the 1st bit position and the flag width --- #
        val        = int ( sys.argv[1], 0 )
        first_bit  = int ( sys.argv[2], 0 )
        flag_width = int ( sys.argv[3], 0 )
        flag = get_bitflag_by_range ( val, first_bit, flag_width )
        if __DEBUG__ :
            # print all the details of the operation
            print "val  = %16s\t => %d"%( to_bin_str ( val ), val )
            print "bit_pos = %d width = %d"%( first_bit, flag_width )
            mask = get_mask ( first_bit, flag_width )
            print "mask = %16s\t => %d"%( to_bin_str ( mask), mask )
            print "res  = %16s\t => %d"%( to_bin_str ( flag ),  flag )
        else :
            # just print the result
            print flag
    else :
        print "Invalid Number of Arguments"
        print usage()

if __name__ == "__main__":
  main()
