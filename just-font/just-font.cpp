// just-font.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

#include "CImg.h"

using namespace cimg_library;

int rgb_to_beeb_colour(unsigned char r, unsigned char g, unsigned char b)
{
	return (r > 127 ? 1 : 0) | (g > 127 ? 2 : 0) | (b > 127 ? 4 : 0);
}

unsigned char make_beeb_byte_mode4(int c0, int c1, int c2, int c3, int c4, int c5, int c6, int c7)
{
	return (c0 ? (1 << 7) : 0) | (c1 ? (1 << 6) : 0) | (c2 ? (1 << 5) : 0) | (c3 ? (1 << 4) : 0) | (c4 ? (1 << 3) : 0) | (c5 ? (1 << 2) : 0) | (c6 ? (1 << 1) : 0) | (c7 ? (1 << 0) : 0);
}

unsigned char beeb_mode2_colour_to_screen_pixel[16][2] =		// maps our MODE 2 colour indices to MODE 2 left + right pixel bytes
{
	{ 0x00, 0x00 },		// 0=black
	{ 0x02, 0x01 },		// 1=red
	{ 0x08, 0x04 },		// 2=green
	{ 0x0A, 0x05 },		// 3=yellow
	{ 0x20, 0x10 },		// 4=blue
	{ 0x22, 0x11 },		// 5=magenta
	{ 0x28, 0x14 },		// 6=cyan
	{ 0x2A, 0x15 },		// 7=white

	{ 0x80, 0x40 },		// 8=black
	{ 0x82, 0x41 },		// 9=red
	{ 0x88, 0x44 },		// 10=green
	{ 0x8A, 0x45 },		// 11=yellow
	{ 0xA0, 0x50 },		// 12=blue
	{ 0xA2, 0x51 },		// 13=magenta
	{ 0xA8, 0x54 },		// 14=cyan
	{ 0xAA, 0x55 },		// 15=white

};

int main(int argc, char **argv)
{
	cimg_usage("Just font convertor.\n\nUsage : just-font [options]");
	const char *input_name = cimg_option("-i", (char*)0, "Input filename");
	const char *output_name = cimg_option("-o", (char*)0, "Output filename");
	const char *const geom = cimg_option("-g", "16x16", "Glyph width & height");
	int max_glyphs = cimg_option("-m", 0, "Max glyphs to process");
	int mode = cimg_option("-mode", 4, "Beeb MODE");
	const bool verbose = cimg_option("-v", false, "Verbose");
	int glyph_width, glyph_height;
	unsigned char *beeb_data, *beeb_ptr;

	if (cimg_option("-h", false, 0)) std::exit(0);
	if (input_name == NULL)  std::exit(0);

	std::sscanf(geom, "%d%*c%d", &glyph_width, &glyph_height);

	FILE *output = NULL;

	if (output_name)
	{
		output = fopen(output_name, "wb");
	}

	CImg<unsigned char> font(input_name);

	int num_gylphs = (font._height / glyph_height) * (font._width / glyph_width);

	if (max_glyphs == 0) max_glyphs = num_gylphs;

	printf("Input file: '%s'\n", input_name);
	printf("Image size: %d x %d\n", font._width, font._height);
	printf("Glyph size: %d x %d\n", glyph_width, glyph_height);
	printf("Num gylphs: %d\n", num_gylphs);

	int beeb_glyph_size = glyph_height * glyph_width;

	beeb_data = (unsigned char *)malloc(max_glyphs * beeb_glyph_size);
	beeb_ptr = beeb_data;

	// Process glyphs a row at a time
	int glyph = 0;

	for (int gy = 0; gy < font._height; gy += glyph_height)
	{
		for (int gx = 0; gx < font._width && glyph < max_glyphs; gx += glyph_width, glyph++)
		{
			if (verbose)
			{
				printf("(%d, %d)\n", gx, gy);
			}

			if (mode == 2)
			{
				for (int x = 0; x < glyph_width; x += 2)
				{
					for (int y = 0; y < glyph_height; y++)
					{
						int c0, c1;

						c0 = rgb_to_beeb_colour(font(gx + x + 0, gy + y + 0, 0), font(gx + x + 0, gy + y + 0, 1), font(gx + x + 0, gy + y + 0, 2));
						c1 = rgb_to_beeb_colour(font(gx + x + 1, gy + y + 0, 0), font(gx + x + 1, gy + y + 0, 1), font(gx + x + 1, gy + y + 0, 2));

						unsigned char byte = beeb_mode2_colour_to_screen_pixel[c0][0] | beeb_mode2_colour_to_screen_pixel[c1][1];

						if (verbose)
						{
							printf("0x%x ", byte);
						}
						*beeb_ptr++ = byte;
					}

					if (verbose)
					{
						printf("\n");
					}
				}
			}
			else
			{
				// Output Beeb data in row order as compressed

				for (int y = 0; y < glyph_height; y++)
				{
					for (int x = 0; x < glyph_width; x += 8)
					{
						int c0, c1, c2, c3, c4, c5, c6, c7;
						// MODE 4 only for now

						if (font._depth == 1)
						{
							c0 = rgb_to_beeb_colour(font(gx + x + 0, gy + y + 0, 0), font(gx + x + 0, gy + y + 0, 0), font(gx + x + 0, gy + y + 0, 0));
							c1 = rgb_to_beeb_colour(font(gx + x + 1, gy + y + 0, 0), font(gx + x + 1, gy + y + 0, 0), font(gx + x + 1, gy + y + 0, 0));
							c2 = rgb_to_beeb_colour(font(gx + x + 2, gy + y + 0, 0), font(gx + x + 2, gy + y + 0, 0), font(gx + x + 2, gy + y + 0, 0));
							c3 = rgb_to_beeb_colour(font(gx + x + 3, gy + y + 0, 0), font(gx + x + 3, gy + y + 0, 0), font(gx + x + 3, gy + y + 0, 0));
							c4 = rgb_to_beeb_colour(font(gx + x + 4, gy + y + 0, 0), font(gx + x + 4, gy + y + 0, 0), font(gx + x + 4, gy + y + 0, 0));
							c5 = rgb_to_beeb_colour(font(gx + x + 5, gy + y + 0, 0), font(gx + x + 5, gy + y + 0, 0), font(gx + x + 5, gy + y + 0, 0));
							c6 = rgb_to_beeb_colour(font(gx + x + 6, gy + y + 0, 0), font(gx + x + 6, gy + y + 0, 0), font(gx + x + 6, gy + y + 0, 0));
							c7 = rgb_to_beeb_colour(font(gx + x + 7, gy + y + 0, 0), font(gx + x + 7, gy + y + 0, 0), font(gx + x + 7, gy + y + 0, 0));
						}
						else
						{

							c0 = rgb_to_beeb_colour(font(gx + x + 0, gy + y + 0, 0), font(gx + x + 0, gy + y + 0, 1), font(gx + x + 0, gy + y + 0, 2));
							c1 = rgb_to_beeb_colour(font(gx + x + 1, gy + y + 0, 0), font(gx + x + 1, gy + y + 0, 1), font(gx + x + 1, gy + y + 0, 2));
							c2 = rgb_to_beeb_colour(font(gx + x + 2, gy + y + 0, 0), font(gx + x + 2, gy + y + 0, 1), font(gx + x + 2, gy + y + 0, 2));
							c3 = rgb_to_beeb_colour(font(gx + x + 3, gy + y + 0, 0), font(gx + x + 3, gy + y + 0, 1), font(gx + x + 3, gy + y + 0, 2));
							c4 = rgb_to_beeb_colour(font(gx + x + 4, gy + y + 0, 0), font(gx + x + 4, gy + y + 0, 1), font(gx + x + 4, gy + y + 0, 2));
							c5 = rgb_to_beeb_colour(font(gx + x + 5, gy + y + 0, 0), font(gx + x + 5, gy + y + 0, 1), font(gx + x + 5, gy + y + 0, 2));
							c6 = rgb_to_beeb_colour(font(gx + x + 6, gy + y + 0, 0), font(gx + x + 6, gy + y + 0, 1), font(gx + x + 6, gy + y + 0, 2));
							c7 = rgb_to_beeb_colour(font(gx + x + 7, gy + y + 0, 0), font(gx + x + 7, gy + y + 0, 1), font(gx + x + 7, gy + y + 0, 2));
						}

						unsigned char byte = make_beeb_byte_mode4(c0, c1, c2, c3, c4, c5, c6, c7);

						if (verbose)
						{
							printf("0x%x ", byte);
						}
						*beeb_ptr++ = byte;
					}

					if (verbose)
					{
						printf("\n");
					}
				}
			}
		}
	}

	if (output)
	{
		if (beeb_data)
		{
			fwrite(beeb_data, 1, beeb_ptr - beeb_data, output);
			printf("Wrote %d bytes to '%s'\n", beeb_ptr - beeb_data, output_name);
		}

		fclose(output);
		output = NULL;
	}

    return 0;
}

