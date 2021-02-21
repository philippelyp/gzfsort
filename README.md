# gzfsort
Copyright 2019 Philippe Paquet

---

### Description

gzfsort is a bash script to sort very large gzipped text files (billions of lines, hundreds of gigabytes).

gzfsort will:
1. Unpack the input file and split it in chunks
2. Sort the chunks using parallel processing
3. Perform a sort merge and pack the output file
4. Clean up

By default, gzfsort will remove duplicate lines.  This can be modified by changing the script.

If you need a script that handle non compressed files, check out fsort.

---

### Usage
gzfsort.sh <input_file> <output_file> <temporary_directory> <lines_per_chunk> <sort_buffer_size> <number_of_processes>

##### <input_file>
Input file.  Compressed with gzip.

##### <output_file>
Output file.  Can be the same as input file.  Will be compressed using gzip.

##### <temporary_directory>
Directory for the temporary files.  Temporary files will consume 2 to 3 time the size of the uncompressed input file.  For example, if your uncompressed input file is 100GB, you should plan for 300GB to be available.

##### <lines_per_chunk>
Number of lines per chunk.  To sort in memory you should plan for your chunks to be smaller than <sort_buffer_size>.

##### <sort_buffer_size>
Memory used per sort process.  For example, if you are using 8 sort processes and <sort_buffer_size> is 100M, you should have at least 800M of memory available.

##### <number_of_processes>
Number of sort processes to run in parallel.  This is an optional parameter.  By default, gzfsort will use one process per logical core available.

---

### Examples
./gzfsort.sh file.gz file.sort.gz /var/temp/ 1000000 256M  
./gzfsort.sh file.gz file.sort.gz /var/temp/ 2000000 512M 8

---

### Performance

It is possible to sort a 120 Gb (uncompressed) / 3.5 B lines file in less than 2 hours on the following machine:  
Processor: Intel Core i9, 3.6 GHz, 8 cores (8 sort processes used)  
Memory: 2667 MHz DDR4 (40 Gb used / 5192 Mb per sort process)  
Source: 7200 rpm SATA disk  
target: 7200 rpm SATA disk  
Temporary drive: NVMe disk

Your mileage may vary as many factors affect performance. 

For the best performance, make sure that chunks fit in <sort_buffer_size> and use the fastest drive you have for temporary files.

It is usually best to set the number of sort processes to the number of physical cores rather than use the number of logical cores.

---

### Contributing

Bug reports and suggestions for improvements are most welcome.

---

### Contact

If you have any questions, comments or suggestions, do not hesitate to contact me at philippe@paquet.email
