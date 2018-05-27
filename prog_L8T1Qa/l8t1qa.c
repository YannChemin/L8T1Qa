#include<stdio.h>
#include "gdal.h"
#include<omp.h>

/* mcd15A3 MODLAND_QC bits [0-1]
 * 0 -> class 0: L8 produced, Good quality (main algorithm with or without saturation)
 * 1 -> class 1: L8 produced, Other Quality (back-up algorithm or fill values)
 */

int L8_random_QA(int pixel) {
    return (pixel & 0x01);
}

void usage()
{
	printf( "-----------------------------------------\n");
	printf( "--L8 Processing chain--OpenMP code----\n");
	printf( "-----------------------------------------\n");
	printf( "./L8 inL8 inL8_QA\n");
	printf( "\toutL8\n");
	printf( "-----------------------------------------\n");
	printf( "inL8\t\tL8 Band x\n");
	printf( "inL8_QA\t\tL8_Qa\n");
	printf( "outL8\tQA corrected L8 output [-]\n");
	return;
}

int main( int argc, char *argv[] )
{
	if( argc < 4 ) {
		usage();
		return 1;
	}
	char	*inB2	= argv[1]; //L8
	char	*inB3 	= argv[2]; //L8_QA
	char	*L8F 	= argv[3];
	GDALAllRegister();
	GDALDatasetH hD2 = GDALOpen(inB2,GA_ReadOnly);//L8
	GDALDatasetH hD3 = GDALOpen(inB3,GA_ReadOnly);//L8_QA
	if(hD2==NULL||hD3==NULL){
		printf("One or more input files ");
		printf("could not be loaded\n");
		exit(1);
	}
	GDALDriverH hDr2 = GDALGetDatasetDriver(hD2);
	GDALDatasetH hDOut = GDALCreateCopy(hDr2,L8F,hD2,FALSE,NULL,NULL,NULL);
	GDALRasterBandH hBOut = GDALGetRasterBand(hDOut,1);
	GDALRasterBandH hB2 = GDALGetRasterBand(hD2,1);//L8
	GDALRasterBandH hB3 = GDALGetRasterBand(hD3,1);//L8_QA

	int nX = GDALGetRasterBandXSize(hB2);
	int nY = GDALGetRasterBandYSize(hB2);
	int N=nX*nY;

	float *l2 = (float *) malloc(sizeof(float)*N);
	float *l3 = (float *) malloc(sizeof(float)*N);
	float *lOut = (float *) malloc(sizeof(float)*N);
	int rc, qa;

	//L8 1Km
	GDALRasterIO(hB2,GF_Read,0,0,nX,nY,l2,nX,nY,GDT_Float32,0,0);
	//L8_QA 1Km
	GDALRasterIO(hB3,GF_Read,0,0,nX,nY,l3,nX,nY,GDT_Float32,0,0);
	#pragma omp parallel for default(none) \
		private (rc, qa) shared (N, l2, l3, lOut)
	for(rc=0;rc<N;rc++){
		qa=L8_random_QA(l3[rc]);
		if( qa != 0) lOut[rc] = -28768; // Check NULL value in L8 product
		else lOut[rc] = l2[rc];
	}
	#pragma omp barrier
	GDALRasterIO(hBOut,GF_Write,0,0,nX,nY,lOut,nX,nY,GDT_Float32,0,0);
	if( l2 != NULL ) free( l2 );
	if( l3 != NULL ) free( l3 );
	GDALClose(hD2);
	GDALClose(hD3);
	GDALClose(hDOut);
	return(EXIT_SUCCESS);
}

