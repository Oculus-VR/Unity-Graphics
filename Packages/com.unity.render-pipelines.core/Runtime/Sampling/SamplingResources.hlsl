#ifndef _SAMPLING_SAMPLINGRESOURCES_HLSL_
#define _SAMPLING_SAMPLINGRESOURCES_HLSL_

#ifdef QRNG_METHOD_SOBOL_BLUE_NOISE
Texture2D<float>                _SobolScramblingTile;
Texture2D<float>                _SobolRankingTile;
Texture2D<float2>               _SobolOwenScrambledSequence;
#endif
#if defined(QRNG_METHOD_SOBOL) || defined(QRNG_METHOD_GLOBAL_SOBOL_BLUE_NOISE)
StructuredBuffer<uint>          _SobolMatricesBuffer;
#endif

#endif

