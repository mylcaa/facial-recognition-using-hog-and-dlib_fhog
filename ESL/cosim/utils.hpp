#ifndef _UTILS_HPP_
#define _UTILS_HPP_

#include <systemc>
#include <string>
#include <iostream>
#include <string.h>
#include <bitset>
#include <math.h>
#include <stdint.h>
#include "def.hpp"

using namespace std;
using namespace sc_dt;
using namespace sc_core;
using namespace tlm;

static const int DATA_WIDTH = W;
static const int FIXED_POINT_WIDTH = LEN_IN_BYTES;
static const int CHAR_LEN = 8;
static const int CHARS_AMOUNT = DATA_WIDTH / CHAR_LEN;

void to_char (unsigned char *, string);
void to_uchar (unsigned char *buf, output_t d);
//double to_fixed (unsigned char *buf);
double to_fixed (unsigned char *buf, int chars_amount, int int_part);
int to_int (unsigned char *);
int to_int32 (unsigned char *);
//long long int to_int64 (unsigned char *);
int64_t to_int64(unsigned char *);
void int_to_uchar(unsigned char *buf, int num);
void int32_to_uchar(unsigned char *buf, int num);
void int64_to_uchar(unsigned char *buf, long long int num);
void bool_to_uchar(unsigned char *buf, bool num);

void write_txt(double* found_faces, int len, char *name_txt);
void write_golden_out_txt(out_matrix_t& found_faces, char *name_txt);
void write_golden_in_txt(in_matrix_t& found_faces, char *name_txt);
void write_input_txt(out_matrix_t& found_faces, char *name_txt);

double mean_subtract(int len, double *array);
double array_norm(int len, double *array); 
double array_dot(int len, double *array1, double *array2);
void sort(int x, int y, int z, double *array);
//void cast_to_fix(int rows, int cols, matrix_t& dest, orig_array_t& src);
void cast_to_fix(int rows, int cols, out_matrix_t& dest, orig_array_t& src);
void find_max(int rows, int cols, double *matrix);
double min(double num1, double num2);
double max(double num1, double num2);
double box_iou(double box1_x, double box1_y, double box2_x, double box2_y, double boxSize);
void sort_bounded_boxes(int x, int y, int z, double *array);

#endif // _UTILS_HPP_
