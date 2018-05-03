// just-font.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

#include "CImg.h"

using namespace cimg_library;

static CImg<unsigned char> src;

int main(int argc, char **argv)
{
	cimg_usage("Just font convertor.\n\nUsage : just-font [options]");
	const char *input_name = cimg_option("-i", (char*)0, "Input filename");
	const char *output_name = cimg_option("-o", (char*)0, "Output filename");
	const char *const geom = cimg_option("-g", "16x16", "Sprite input size (when extracting from font/sprite sheet)");

	if (cimg_option("-h", false, 0)) std::exit(0);
	if (input_name == NULL)  std::exit(0);
	if (output_name == NULL)  std::exit(0);

    return 0;
}

