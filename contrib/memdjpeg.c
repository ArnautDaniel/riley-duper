// memdjpeg - A super simple example of how to decode a jpeg in memory
// Kenneth Finnegan, 2012
// blog.thelifeofkenneth.com
// Modified for Riley-Duper by Arnaut Daniel to return a structure instead
// After installing jpeglib, compile with:
// cc memdjpeg.c -ljpeg -o memdjpeg
// For share lib
// gcc -c -Wall -Werror -fpic memdjpeg.c
// gcc -shared -o  librileyj.so memdjpeg.o -ljpeg



#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <jpeglib.h>

struct bmp {
  unsigned long bmp_size;
  int width ;
  int height ;
  unsigned char *bmp_buffer;
} bmp ;

extern struct bmp* riley_decode_jpeg (char* path) {
  
  int rc, i;

  // Variables for the source jpg
  struct stat file_info;
  unsigned long jpg_size;
  unsigned char *jpg_buffer;

  // Variables for the decompressor itself
  struct jpeg_decompress_struct cinfo;
  struct jpeg_error_mgr jerr;

  // Variables for the output buffer, and how long each row is
  int row_stride, width, height, pixel_size;

  rc = stat(path, &file_info);

  jpg_size = file_info.st_size;
  jpg_buffer = (unsigned char*) malloc(jpg_size + 100);

  int fd = open(path, O_RDONLY);
  i = 0;
  while (i < jpg_size) {
    rc = read(fd, jpg_buffer + i, jpg_size - i);
    i += rc;
  }
  close(fd);

  cinfo.err = jpeg_std_error(&jerr);	
  jpeg_create_decompress(&cinfo);

  jpeg_mem_src(&cinfo, jpg_buffer, jpg_size);

  rc = jpeg_read_header(&cinfo, TRUE);
	
  jpeg_start_decompress(&cinfo);
	
  width = cinfo.output_width;
  height = cinfo.output_height;
  pixel_size = cinfo.output_components;
  
  struct bmp *bmptr = (struct bmp*)malloc(sizeof(struct bmp));
  
  bmptr->bmp_size = width * height * pixel_size ;
  bmptr->bmp_buffer = (unsigned char*) malloc(bmptr->bmp_size);
  bmptr->width = width ;
  bmptr->height = height ;
  
  row_stride = width * pixel_size;

  while (cinfo.output_scanline < cinfo.output_height) {
    unsigned char *buffer_array[1];
    buffer_array[0] = bmptr->bmp_buffer + \
      (cinfo.output_scanline) * row_stride;

    jpeg_read_scanlines(&cinfo, buffer_array, 1);

  }

  jpeg_finish_decompress(&cinfo);
  jpeg_destroy_decompress(&cinfo);
  free(jpg_buffer);
  close(fd);
	
  return bmptr ;

}
