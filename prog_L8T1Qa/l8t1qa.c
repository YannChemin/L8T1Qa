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
	printf( "./L8 inL8b4 inL8b5 inL8b6 inL8_QA\n");
	printf( "\toutL8\n");
	printf( "-----------------------------------------\n");
	printf( "inL8b4\t\tL8 Band 4 UInt16\n");
	printf( "inL8b5\t\tL8 Band 5 UInt16\n");
	printf( "inL8b6\t\tL8 Band 6 UInt16\n");
	printf( "inL8_QA\t\tL8_Qa UInt16\n");
	printf( "outL8vi\tCloud removed L8 NDVI output [0-10000]\n");
	printf( "outL8wi\tCloud removed L8 NDWI output [0-10000]\n");
	return;
}

int main( int argc, char *argv[] )
{
	if( argc < 4 ) {
		usage();
		return 1;
	}
	char	*inB4	= argv[1]; //L8 band 4
	char	*inB5	= argv[2]; //L8 band 5
	char	*inB6	= argv[3]; //L8 band 6
	char	*inB7 	= argv[4]; //L8_QA
	char	*L8viF 	= argv[5]; //OUT NDVI
	char	*L8wiF 	= argv[6]; //OUT NDWI
	GDALAllRegister();
	GDALDatasetH hD4 = GDALOpen(inB4,GA_ReadOnly);//L8 band 4
	GDALDatasetH hD5 = GDALOpen(inB5,GA_ReadOnly);//L8 band 5
	GDALDatasetH hD6 = GDALOpen(inB6,GA_ReadOnly);//L8 band 6
	GDALDatasetH hD7 = GDALOpen(inB7,GA_ReadOnly);//L8_QA
	if(hD4==NULL||hD5==NULL||hD6==NULL||hD7==NULL){
		printf("One or more input files ");
		printf("could not be loaded\n");
		exit(1);
	}
	GDALDriverH hDr4 = GDALGetDatasetDriver(hD4);
	GDALDatasetH hDOutVI = GDALCreateCopy(hDr4,L8viF,hD4,FALSE,NULL,NULL,NULL);
	GDALDatasetH hDOutWI = GDALCreateCopy(hDr4,L8wiF,hD4,FALSE,NULL,NULL,NULL);
	GDALRasterBandH hBOutVI = GDALGetRasterBand(hDOutVI,1);
	GDALRasterBandH hBOutWI = GDALGetRasterBand(hDOutWI,1);
	GDALRasterBandH hB4 = GDALGetRasterBand(hD4,1);//L8 band 4
	GDALRasterBandH hB5 = GDALGetRasterBand(hD5,1);//L8 band 5
	GDALRasterBandH hB6 = GDALGetRasterBand(hD6,1);//L8 band 6
	GDALRasterBandH hB7 = GDALGetRasterBand(hD7,1);//L8_QA

	int nX = GDALGetRasterBandXSize(hB4);
	int nY = GDALGetRasterBandYSize(hB4);
	int N=nX*nY;

	unsigned int *l4 = (unsigned int *) malloc(sizeof(unsigned int)*N);
	unsigned int *l5 = (unsigned int *) malloc(sizeof(unsigned int)*N);
	unsigned int *l6 = (unsigned int *) malloc(sizeof(unsigned int)*N);
	unsigned int *l7 = (unsigned int *) malloc(sizeof(unsigned int)*N);
	unsigned int *lOutVI = (unsigned int *) malloc(sizeof(unsigned int)*N);
	unsigned int *lOutWI = (unsigned int *) malloc(sizeof(unsigned int)*N);
	int rc, qac, qacc, qacs, qaci;
	float vi=0.0, wi=0.0;

	//L8 band 4/5/6 
	GDALRasterIO(hB4,GF_Read,0,0,nX,nY,l4,nX,nY,GDT_UInt32,0,0);
	GDALRasterIO(hB5,GF_Read,0,0,nX,nY,l5,nX,nY,GDT_UInt32,0,0);
	GDALRasterIO(hB6,GF_Read,0,0,nX,nY,l6,nX,nY,GDT_UInt32,0,0);
	//L8_QA 
	GDALRasterIO(hB7,GF_Read,0,0,nX,nY,l7,nX,nY,GDT_UInt32,0,0);
	//Get the number of threads available
	int n = omp_get_num_threads();
	//Do not stall the computer
	omp_set_num_threads(n-1);
	#pragma omp parallel for default(none) \
		private (rc, vi, wi, qac, qacc, qacs, qaci) \
		shared (N, l4, l5, l6, l7, lOutVI, lOutWI)
	for(rc=0;rc<N;rc++){
		/*process VI*/
		if(l5[rc]+l4[rc]!=0){
			vi=(1.0+(l5[rc]-l4[rc])/(l5[rc]+l4[rc]))*10000;
		}else{
			vi=32768;
		}
		/*process WI*/
		if(l6[rc]+l5[rc]!=0){
			wi=(1.0+(l6[rc]-l5[rc])/(l6[rc]+l5[rc]))*10000;
		}else{
			wi=32768;
		}
		/*process QAs*/
		/*QA cloud: bit 4*/
		qac=L8QA_cloud(l7[rc]);
		/*QA cloud confidence: bits 5-6*/
		qacc=L8QA_cloud_confidence(l7[rc]);
		/*QA cloud shadow: bits 7-8*/
		qacs=L8QA_cloud_shadow(l7[rc]);
		/*QA cirrus confidence: bits 11-12*/
		qaci=L8QA_cirrus_confidence(l7[rc]);
		/*No Data in this pixel: [UInt16 val == 1] => -32768*/
		if(l7[rc]==1){ 
			lOutVI[rc] = 32768;
			lOutWI[rc] = 32768;
		/*If clouds, or cloud[shadow][cirrus] confidence QA==[00,01]->[0,1] then mask the pixel*/
		}else if(qac == 1 || qacc > 2 || qacs > 2 || qaci > 2){
			lOutVI[rc] = 32767; 
			lOutWI[rc] = 32767; 
		/*Finally, all sufficiently less cloud confident or not cloud for sure, use the band pixel value*/
		}else{
			lOutVI[rc] = vi;
			lOutWI[rc] = wi;
		}
	}
	#pragma omp barrier
	GDALRasterIO(hBOutVI,GF_Write,0,0,nX,nY,lOutVI,nX,nY,GDT_UInt32,0,0);
	GDALRasterIO(hBOutWI,GF_Write,0,0,nX,nY,lOutWI,nX,nY,GDT_UInt32,0,0);
	if( l4 != NULL ) free( l4 );
	if( l5 != NULL ) free( l5 );
	if( l6 != NULL ) free( l6 );
	if( l7 != NULL ) free( l7 );
	GDALClose(hD4);
	GDALClose(hD5);
	GDALClose(hD6);
	GDALClose(hD7);
	GDALClose(hDOutVI);
	GDALClose(hDOutWI);
	return(EXIT_SUCCESS);
}

