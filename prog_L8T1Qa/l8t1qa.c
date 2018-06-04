#include<stdio.h>
#include "gdal.h"
#include<omp.h>

/* L8 Qa bits [4] Cloud
 * 0 -> class 0: Not Cloud
 * 1 -> class 1: Cloud
 */

unsigned int L8QA_cloud(unsigned int pixel) {
    unsigned int qa;
    pixel >>= 4; 	/*bits [4] become [0]*/
    qa = (unsigned int) (pixel & 0x01);
    return qa;
}

/* L8 Qa bits [5-6] Cloud confidence
 * 00 -> class 0: Not determined
 * 01 -> class 1: No Cloud (0-33% probability)
 * 10 -> class 2: Maybe Cloud (34-66% probability)
 * 11 -> class 3: Cloud (66-100% probability)
 */

unsigned int L8QA_cloud_confidence(unsigned int pixel) {
    unsigned int qa;
    pixel >>= 5; 	/*bits [5-6] become [0-1]*/
    qa = (unsigned int) (pixel & 0x03);
    return qa;
}

/* L8 Qa bits [7-8] Cloud shadow confidence
 * 00 -> class 0: Not determined
 * 01 -> class 1: No Cloud shadow (0-33% probability)
 * 10 -> class 2: Maybe Cloud shadow (34-66% probability)
 * 11 -> class 3: Cloud shadow (66-100% probability)
 */

unsigned int L8QA_cloud_shadow(unsigned int pixel) {
    unsigned int qa;
    pixel >>= 7; 	/*bits [7-8] become [0-1]*/
    qa = (unsigned int) (pixel & 0x03);
    return qa;
}

/* L8 Qa bits [11-12] Cirrus confidence
 * 00 -> class 0: Not determined
 * 01 -> class 1: No Cirrus (0-33% probability)
 * 10 -> class 2: Maybe Cirrus (34-66% probability)
 * 11 -> class 3: Cirrus (66-100% probability)
 */

unsigned int L8QA_cirrus_confidence(unsigned int pixel) {
    unsigned int qa;
    pixel >>= 11; 	/*bits [11-12] become [0-1]*/
    qa = (unsigned int) (pixel & 0x03);
    return qa;
}

void usage()
{
	printf( "-----------------------------------------\n");
	printf( "--L8 Processing chain--OpenMP code----\n");
	printf( "-----------------------------------------\n");
	printf( "./L8 inL8 inL8_QA\n");
	printf( "\toutL8\n");
	printf( "-----------------------------------------\n");
	printf( "inL8\t\tL8 Band x (one band per .tif file)\n");
	printf( "inL8_QA\t\tL8_Qa\n");
	printf( "outL8\tCloud removed L8 band output [-]\n");
	return;
}

int main( int argc, char *argv[] )
{
	if( argc < 4 ) {
		usage();
		return 1;
	}
	char	*inB2	= argv[1]; //L8 band x
	char	*inB3 	= argv[2]; //L8_QA
	char	*L8F 	= argv[3];
	GDALAllRegister();
	GDALDatasetH hD2 = GDALOpen(inB2,GA_ReadOnly);//L8 band x
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

	unsigned int *l2 = (unsigned int *) malloc(sizeof(unsigned int)*N);
	unsigned int *l3 = (unsigned int *) malloc(sizeof(unsigned int)*N);
	unsigned int *lOut = (unsigned int *) malloc(sizeof(unsigned int)*N);
	int rc, qac, qacc, qacs, qaci;

	//L8 
	GDALRasterIO(hB2,GF_Read,0,0,nX,nY,l2,nX,nY,GDT_UInt32,0,0);
	//L8_QA 
	GDALRasterIO(hB3,GF_Read,0,0,nX,nY,l3,nX,nY,GDT_UInt32,0,0);
	//Get the number of threads available
	int n = omp_get_num_threads();
	//Do not stall the computer
	omp_set_num_threads(n-1);
	#pragma omp parallel for default(none) \
		private (rc, qac, qacc, qacs, qaci) shared (N, l2, l3, lOut)
	for(rc=0;rc<N;rc++){
		/*process QAs*/
		/*QA cloud: bit 4*/
		qac=L8QA_cloud(l3[rc]);
		/*QA cloud confidence: bits 5-6*/
		qacc=L8QA_cloud_confidence(l3[rc]);
		/*QA cloud shadow: bits 7-8*/
		qacs=L8QA_cloud_shadow(l3[rc]);
		/*QA cirrus confidence: bits 11-12*/
		qaci=L8QA_cirrus_confidence(l3[rc]);
		/*No Data in this pixel: [UInt16 val == 1] => -32768*/
		if(l3[rc]==1){ 
			lOut[rc] = 32768;
		/*If clouds, or cloud[shadow][cirrus] confidence QA==[00,01]->[0,1] then mask the pixel*/
		}else if(qac == 1 || qacc > 2 || qacs > 2 || qaci > 2){
			lOut[rc] = 32767; 
		/*Finally, all sufficiently less cloud confident or not cloud for sure, use the band pixel value*/
		}else{
			lOut[rc] = l2[rc];
		}
	}
	#pragma omp barrier
	GDALRasterIO(hBOut,GF_Write,0,0,nX,nY,lOut,nX,nY,GDT_UInt32,0,0);
	if( l2 != NULL ) free( l2 );
	if( l3 != NULL ) free( l3 );
	GDALClose(hD2);
	GDALClose(hD3);
	GDALClose(hDOut);
	return(EXIT_SUCCESS);
}

