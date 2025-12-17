#ifndef _SAMPLING_RANDOM_HLSL_
#define _SAMPLING_RANDOM_HLSL_

#include "Common.hlsl"
#include "Hashes.hlsl"

// Low discrepancy sequence generator with various implementations available

/* One of the following must be defined by the file that includes QuasiRandom.hlsl to select an implementation:
- QRNG_METHOD_SOBOL (Sobol sampler with Owen scrambling, from paper: Practical Hash-based Owen Scrambling by Burley)
    infinite dims, 2097151 max samples, pixel tiling wraps at 65536
    define QRNG_SOBOL_GENERATIVE_DIMS <multipleOf2> to control how many source dimensions are used, Default value 1024

- QRNG_METHOD_SOBOL_BLUE_NOISE (from paper: "A Low-Discrepancy Sampler that Distributes Monte Carlo Errors as a Blue Noise in Screen Space" by Heitz and Belcour)
    256 max dims, 256 max samples (beyond 256, the sequence keeps going with another set of 256 samples belonging to another dim, and so on every 256 samples), pixel tiling wraps at 128

- QRNG_METHOD_GLOBAL_SOBOL_BLUE_NOISE (from paper: "Screen-Space Blue-Noise Diffusion of Monte Carlo Sampling Error via Hierarchical Ordering of Pixels" by Ahmed and Wonka)
    infinite dims and samples, pixel tiling depends on target sample count. The more samples, the smaller the tile (ex: for 256 samples, tiling size is 4096)
    define QRNG_GLOBAL_SOBOL_ENHANCED_TILING to get tiling to always wrap at 65536
    define QRNG_SOBOL_GENERATIVE_DIMS <multipleOf2> to control how many source dimensions are used, Default value 1024

- QRNG_METHOD_KRONECKER (Kronecker sequence from paper "Optimizing Kronecker Sequences for Multidimensional Sampling")
    fast but lower quality than Sobol, infinite dims and samples, pixel tiling wraps at 65536
    define QRNG_KRONECKER_ENHANCED_QUALITY to add small scale jitter

These last 2 aren't low discrepancy sequences but traditional Pseudorandom number generators
- QRNG_METHOD_RANDOM_XOR_SHIFT Xor shift PRNG
- QRNG_METHOD_RANDOM_PCG_4D (from paper: "Hash Functions for GPU Rendering" by Jarzynski & Olano)
*/

#if defined(QRNG_METHOD_SOBOL) || defined(QRNG_METHOD_GLOBAL_SOBOL_BLUE_NOISE)
#include "SobolSampling.hlsl"

#ifndef QRNG_SOBOL_GENERATIVE_DIMS
#define QRNG_SOBOL_GENERATIVE_DIMS SOBOL_MATRICES_COUNT
#endif
static const uint kMaxSobolDim = QRNG_SOBOL_GENERATIVE_DIMS;
#endif

uint PixelHash(uint2 pixelCoord, uint seed = 0)
{
    return LowBiasHash32((pixelCoord.x & 0xFFFF) | (pixelCoord.y << 16), seed);
}

#if defined(QRNG_METHOD_SOBOL)

struct QuasiRandomGenerator
{
    uint pixelSeed;
    uint sampleIndex;

    void Init(uint2 pixelCoord, uint startSampleIndex)
    {
        pixelSeed = PixelHash(pixelCoord);
        sampleIndex = startSampleIndex;
    }

    float GetFloat(uint dimension)
    {
        uint scrambleSeed = LowBiasHash32(pixelSeed, dimension);
        uint shuffleSeed = pixelSeed;
        return GetOwenScrambledSobolSample(sampleIndex ^ shuffleSeed, dimension % kMaxSobolDim, scrambleSeed);
    }

    void NextSample()
    {
        sampleIndex++;
    }
};

#elif defined(QRNG_METHOD_SOBOL_BLUE_NOISE)
#include "SobolBluenoiseSampling.hlsl"

struct QuasiRandomGenerator
{
    uint2 pixelCoord;
    uint sampleIndex;

    void Init(uint2 pixelCoord_, uint startSampleIndex)
    {
        pixelCoord = pixelCoord_;
        sampleIndex = startSampleIndex;
    }

    float GetFloat(uint dimension)
    {
        // If we go past the number of stored samples per dim, just shift all to the next pair of dimensions
        dimension += (sampleIndex / 256) * 2;
        return GetBNDSequenceSample(pixelCoord, sampleIndex, dimension);
    }

    void NextSample()
    {
        sampleIndex++;
    }
};

#elif defined(QRNG_METHOD_GLOBAL_SOBOL_BLUE_NOISE)

struct QuasiRandomGenerator
{
    uint pixelMortonCode;
    uint log2SamplesPerPixel;
    uint sampleIndex;

    void Init(uint2 pixelCoord, uint startSampleIndex, uint perPixelSampleCount = 256)
    {
        pixelMortonCode = EncodeMorton2D(pixelCoord);
        log2SamplesPerPixel = Log2IntUp(perPixelSampleCount);
        sampleIndex = startSampleIndex;
    }

    float GetFloat(uint dimension)
    {
        return GetOwenScrambledZShuffledSobolSample(sampleIndex, dimension, kMaxSobolDim, pixelMortonCode, log2SamplesPerPixel);
    }

    void NextSample()
    {
        sampleIndex++;
    }
};

#elif defined(QRNG_METHOD_KRONECKER)

struct QuasiRandomGenerator
{
    uint cranleyPattersonSeed;
    uint shuffledSampleIndex;
#ifdef QRNG_KRONECKER_ENHANCED_QUALITY
    int sampleIndex;
#endif

    void Init(uint2 pixelCoord, uint startSampleIndex)
    {
        uint hash = PixelHash(pixelCoord);
        cranleyPattersonSeed = hash;
        uint shuffledStartIndex = (startSampleIndex + hash) % (1 << 20);
        shuffledSampleIndex = shuffledStartIndex;
#ifdef QRNG_KRONECKER_ENHANCED_QUALITY
        sampleIndex = startSampleIndex+1;
#endif
    }

    float GetFloat(uint dimension)
    {
        const uint alphas[]= { // values are stored multiplied by (1 << 32)
            // R2 from http://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/
            3242174889, 2447445414,
            // K21_2 from Optimizing Kronecker Sequences for Multidimensional Sampling
            3316612456, 1538627358,
        };

        // compute random offset to apply to the sequence (using another Kronecker sequence)
        uint cranleyPattersonRot = cranleyPattersonSeed + 3646589397 * (dimension / 4);

#ifdef QRNG_KRONECKER_ENHANCED_QUALITY // add small scale jitter as explained in paper
        const float alphaJitter[] = { 2681146017, 685201898 };

        uint jitter = alphaJitter[dimension % 2] * shuffledSampleIndex;
        float amplitude = 0.05 * 0.78 / sqrt(2) * rsqrt(float(sampleIndex));
        cranleyPattersonRot += jitter * uint(amplitude);
#endif
        // Kronecker sequence evaluation
        return UintToFloat01(cranleyPattersonRot + alphas[dimension % 4] * shuffledSampleIndex);
    }

    void NextSample()
    {
        // shuffledSampleIndex modulo 1048576 to avoid numerical precision issues when evaluating the Kronecker sequence
        shuffledSampleIndex = (shuffledSampleIndex + 1) % (1 << 20);
#ifdef QRNG_KRONECKER_ENHANCED_QUALITY
        sampleIndex++;
#endif
    }
};

#elif defined(QRNG_METHOD_RANDOM_XOR_SHIFT)

struct QuasiRandomGenerator
{
    uint state;

    void Init(uint2 pixelCoord, uint startSampleIndex)
    {
        state = PixelHash(pixelCoord, startSampleIndex);
    }

    float GetFloat(uint dimension)
    {
        state = XorShift32(state);
        return UintToFloat01(state);
    }

    void NextSample()
    {
    }
};

#elif defined(QRNG_METHOD_RANDOM_PCG_4D)

struct QuasiRandomGenerator
{
    uint4 state;

    void Init(uint2 pixelCoord, uint startSampleIndex)
    {
        // Seed for PCG uses a sequential sample number in 4th channel, which increments on every RNG call and starts from 0
        state = uint4(pixelCoord, startSampleIndex, 0);
    }

    float GetFloat(int dimension)
    {
        state.w++;
        return UintToFloat01(Pcg4d(state).x);
    }

    void NextSample()
    {
        state.z++;
    }
};
#endif


// global dimension offset (could be used to alter the noise pattern)
#ifndef QRNG_OFFSET
#define QRNG_OFFSET 0
#endif

#ifndef QRNG_SAMPLES_PER_BOUNCE
#define QRNG_SAMPLES_PER_BOUNCE 64
#endif

struct PathTracingSampler
{
    QuasiRandomGenerator generator;
    int bounceIndex;

    void Init(uint2 pixelCoord, uint startPathIndex, uint perPixelPathCount = 256)
    {
        #if defined(QRNG_METHOD_GLOBAL_SOBOL_BLUE_NOISE)
            generator.Init(pixelCoord, startPathIndex, perPixelPathCount);
        #else
            generator.Init(pixelCoord, startPathIndex);
        #endif
        bounceIndex = 0;
    }

    float GetFloatSample(int dimension)
    {
        uint actualDimension = QRNG_OFFSET + QRNG_SAMPLES_PER_BOUNCE * bounceIndex + dimension;
        return generator.GetFloat(actualDimension);
    }

    void NextBounce()
    {
        bounceIndex++;
    }

    void NextPath()
    {
        generator.NextSample();
        bounceIndex = 0;
    }
};

#endif // _SAMPLING_RANDOM_HLSL_
