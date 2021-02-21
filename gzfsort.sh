#!/bin/bash

#
#
#  gzfsort v1.1
#
#  Copyright 2019 Philippe Paquet
#
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#


# Sort flags
# Keep -u to remove duplicates
sort_default_flags='-u'

# gzfsort_sub is used to sort chunks in parallel
function gzfsort_sub
{
    filename=$1
    filename_sort=$1'.sort'
    LC_ALL=C sort $sort_flags ${filename} > ${filename_sort}
    rm ${filename}
}
export -f gzfsort_sub

# check the parameters
if [ "$#" -ne 5  -a "$#" -ne 6 ]; then
	echo ""
	echo "gzfsort v1.1"
	echo "Copyright 2019 Philippe Paquet"
	echo ""
	echo "Usage:	gzfsort.sh <input_file> <output_file> <temporary_directory> <lines_per_chunk> <sort_buffer_size> <number_of_processes>"
	echo ""
	echo "			<input_file>				Input file"
	echo "										Compressed with gzip"
	echo ""
	echo "			<output_file>				Output file"
	echo "										Can be the same as input file"
	echo "										Will be compressed using gzip"
	echo ""
	echo "			<temporary_directory>		Directory for the temporary files"
	echo "										Temporary files will consume 2 to 3 time the size of the uncompressed input file"
	echo "										For example, if your uncompressed input file is 100GB you should plan for 300GB to be available"
	echo ""
	echo "			<lines_per_chunk>			Number of lines per chunk"
	echo "										To sort in memory you should plan for your chunks to be smaller than <sort_buffer_size>"
	echo ""
	echo "			<sort_buffer_size>			Memory used per sort process"
	echo "										For example, if you are using 8 sort processes and <sort_buffer_size> is 100M, you should have at least 800M of memory available"
	echo ""
	echo "			<number_of_processes>		Number of sort processes to run in parallel"
	echo "										This is an optional parameter"
	echo "										By default, gzfsort will use one process per logical core available"
	echo ""
	echo "Examples:	./gzfsort.sh file.gz file.sort.gz /var/temp/ 1000000 256M"
	echo "			./gzfsort.sh file.gz file.sort.gz /var/temp/ 2000000 512M 8"
	echo ""
	exit
fi

# Get parameters from command line
input_file=$1
output_file=$2
temporary_directory=$3
lines_per_chunk=$4
sort_buffer_size=$5

# Number of processes to run in parallel
if [ "$#" -eq 5 ]; then
	# By default we match the number of cores online
	processes=`getconf _NPROCESSORS_ONLN`
else
	processes=$6
fi

# Add trailing slash to temporary_directory if necessary
temporary_directory_length=${#temporary_directory}
temporary_directory_last_char=${temporary_directory:temporary_directory_length-1:1}
if [ $temporary_directory_last_char != '/' ]; then
	temporary_directory=${temporary_directory}'/'
fi

# Create sort and merge flags
sort_flags=${sort_default_flags}' --temporary-directory='${temporary_directory}' --buffer-size='${sort_buffer_size}
merge_flags=${sort_default_flags}' --temporary-directory='${temporary_directory}

# Create chunks prefix
chunk_prefix='_gzfs_'

# Create chunk filter
chunk_filter=${chunk_prefix}'*'

# Go to the temporary directory
pushd ${temporary_directory}

# Split input in chunks of x lines
LC_ALL=C gunzip -c -d ${input_file} | split -a 4 -l${lines_per_chunk} - ${chunk_prefix};

# Sort chunks
ls ${chunk_filter} | xargs -P ${processes} -n 1 -I % bash -c 'gzfsort_sub %' _ {}

# Merge resulting chunks
LC_ALL=C sort $merge_flags -m  ${chunk_filter} | gzip > ${output_file}

# Cleanup
rm ${chunk_filter}

# Go back
popd
