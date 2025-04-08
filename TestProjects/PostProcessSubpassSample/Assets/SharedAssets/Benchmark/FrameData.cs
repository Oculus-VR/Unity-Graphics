using System;
using System.Collections.Generic;
using UnityEngine;

namespace Benchmarking
{

    public struct FrameData
    {
        public float frameTime;
        private float _fpsOverride;
        public float fps => (_fpsOverride > 0f) ? _fpsOverride : 1000f / frameTime;

        public bool advancedFrameTiming;
        public double cpuTime;
        public double cpuRenderTime;
        public double gpuTime;

        public double timeLineTime;

        const int k_timingsCaptureCount = 3;

        public FrameData(float timeMS, float timelineTime = 0)
        {
            frameTime = timeMS;
            this.timeLineTime = timelineTime;
            _fpsOverride = -1f;

            advancedFrameTiming = false;
            cpuTime = cpuRenderTime = gpuTime = timeMS;
        }

        public void CaptureFrameTimings()
        {
            advancedFrameTiming = FrameTimingManager.IsFeatureEnabled();

            if (advancedFrameTiming)
            {
                FrameTimingManager.CaptureFrameTimings();
                FrameTiming[] timings = new FrameTiming[k_timingsCaptureCount];
                uint count = FrameTimingManager.GetLatestTimings(k_timingsCaptureCount, timings);
                if (count > 0)
                {
                    cpuTime = timings[0].cpuFrameTime;
                    cpuRenderTime = timings[0].cpuRenderThreadFrameTime;
                    gpuTime = timings[0].gpuFrameTime;

                    // Sometimes GPU timing is invalid, try to get the previous timing values and average
                    //*
                    if (count > 1)
                    {
                        for (int i = 1; i < count; i++)
                            gpuTime += timings[i].gpuFrameTime;

                        gpuTime /= count;
                    }
                    //*/
                }
            }
        }

        public static FrameData GetCurrentFrameData(float timelineTime = 0)
        {
            return new FrameData(Time.deltaTime * 1000f, timelineTime);
        }

        public void SetFPSOverride(float fpsOverride)
        {
            _fpsOverride = fpsOverride;
        }

        public void ResetFPSOverride() { _fpsOverride = -1f; }

        public static FrameData Min(FrameData a, FrameData b, ref bool bSmaller, bool overrideFPS = false)
        {
            FrameData o = new FrameData();

            bSmaller = b.frameTime < a.frameTime;
            o.frameTime = bSmaller ? b.frameTime : a.frameTime;
            if (overrideFPS)
                o._fpsOverride = Mathf.Min(a.fps, b.fps);
            else
                o._fpsOverride = -1f;

            o.advancedFrameTiming = a.advancedFrameTiming && b.advancedFrameTiming;
            if (o.advancedFrameTiming)
            {
                o.cpuTime = DoubleMin(a.cpuTime, b.cpuTime);
                o.cpuRenderTime = DoubleMin(a.cpuRenderTime, b.cpuRenderTime);
                o.gpuTime = DoubleMin(a.gpuTime, b.gpuTime);
            }

            return o;
        }
        public bool MinWith(FrameData other, bool overrideFPS = false)
        {
            bool o = false;
            this = Min(this, other, ref o, overrideFPS);
            return o;
        }

        public static FrameData Max(FrameData a, FrameData b, ref bool bGreater, bool overrideFPS = false)
        {
            FrameData o = new FrameData();

            bGreater = b.frameTime > a.frameTime;

            o.frameTime = bGreater ? b.frameTime : a.frameTime;
            if (overrideFPS)
                o._fpsOverride = Mathf.Max(a.fps, b.fps);
            else
                o._fpsOverride = -1f;

            o.advancedFrameTiming = a.advancedFrameTiming && b.advancedFrameTiming;
            if (o.advancedFrameTiming)
            {
                o.cpuTime = DoubleMax(a.cpuTime, b.cpuTime);
                o.cpuRenderTime = DoubleMax(a.cpuRenderTime, b.cpuRenderTime);
                o.gpuTime = DoubleMax(a.gpuTime, b.gpuTime);
            }

            return o;
        }

        public bool MaxWith(FrameData other, bool overrideFPS = false)
        {
            bool o = false;
            this = Max(this, other, ref o, overrideFPS);
            return o;
        }

        public static FrameData Average(FrameData a, int countA, FrameData b, int countB, bool overrideFPS = false)
        {
            FrameData o = new FrameData();
            float divider = 1.0f / (countA + countB);
            o.frameTime = (a.frameTime * countA + b.frameTime * countB) * divider;
            if (overrideFPS)
                o._fpsOverride = (a.fps * countA + b.fps * countB) * divider;
            else
                o._fpsOverride = -1f;

            o.advancedFrameTiming = a.advancedFrameTiming && b.advancedFrameTiming;
            if (o.advancedFrameTiming)
            {
                o.cpuTime = (a.cpuTime * countA + b.cpuTime * countB) * divider;
                o.cpuRenderTime = (a.cpuRenderTime * countA + b.cpuRenderTime * countB) * divider;
                o.gpuTime = (a.gpuTime * countA + b.gpuTime * countB) * divider;
            }

            return o;
        }

        public void AverageWith(FrameData other, int count, bool overrideFPS = false)
        {
            this = Average(this, count - 1, other, 1, overrideFPS);
        }

        public static FrameData Lerp(FrameData a, FrameData b, float t)
        {
            FrameData o = new FrameData();
            o.frameTime = Mathf.Lerp(a.frameTime, b.frameTime, t);
            o._fpsOverride = -1f;

            o.advancedFrameTiming = a.advancedFrameTiming && b.advancedFrameTiming;
            if (o.advancedFrameTiming)
            {
                o.cpuTime = DoubleLerp(a.cpuTime, b.cpuTime, t);
                o.cpuRenderTime = DoubleLerp(a.cpuRenderTime, b.cpuRenderTime, t);
                o.gpuTime = DoubleLerp(a.gpuTime, b.gpuTime, t);
            }

            return o;
        }

        public static FrameData MinMultiple(List<FrameData> frameTimes)
        {
            if (frameTimes == null || frameTimes.Count < 1)
                return new FrameData();

            FrameData o = frameTimes[0];
            for (int i = 1; i < frameTimes.Count; i++)
            {
                o.MinWith(frameTimes[i], true);
            }

            return o;
        }

        public static FrameData MaxMultiple(List<FrameData> frameTimes)
        {
            if (frameTimes == null || frameTimes.Count < 1)
                return new FrameData();

            FrameData o = frameTimes[0];
            for (int i = 1; i < frameTimes.Count; i++)
            {
                o.MaxWith(frameTimes[i], true);
            }

            return o;
        }

        private static double DoubleMin(double a, double b)
        {
            return (a < b) ? a : b;
        }
        private static double DoubleMax(double a, double b)
        {
            return (a > b) ? a : b;
        }
        private static double DoubleLerp(double a, double b, double t)
        {
            return a * (1 - t) + b * t;
        }

        override public string ToString()
        {
            return $"FrameData{{frameTime: {frameTime} ms, fps: {fps}, advancedFrameTiming: {advancedFrameTiming}, cpuTime: {cpuTime} ms, cpuRenderTime: {cpuRenderTime} ms, gpuTime: {gpuTime} ms}}";
        }

        public string GetValueString(DataType dataType)
        {
            string format = "F2";
            switch (dataType)
            {
                case DataType.FPS:
                    return fps.ToString(format);
                case DataType.CPUTime:
                    return cpuTime.ToString(format);
                case DataType.CPURenderTime:
                    return cpuRenderTime.ToString(format);
                case DataType.GPUTime:
                    return gpuTime.ToString(format);
                default:
                    return frameTime.ToString(format);
            }
        }

        public float GetValue(DataType dataType)
        {
            switch (dataType)
            {
                case DataType.FPS:
                    return fps;
                case DataType.CPUTime:
                    return (float)cpuTime;
                case DataType.CPURenderTime:
                    return (float)cpuRenderTime;
                case DataType.GPUTime:
                    return (float)gpuTime;
                default:
                    return frameTime;
            }
        }

        public void WriteCSV(string before = null, bool writeTimeLineTime = false)
        {
            string[] strings = new string[5 + (before == null ? 0 : 1) + (writeTimeLineTime ? 1 : 0)];

            int i = 0;

            if (before != null)
            {
                strings[i] = before;
                i++;
            }

            if (writeTimeLineTime)
            {
                strings[i] = timeLineTime.ToString();
                i++;
            }

            strings[i] = frameTime.ToString();
            i++;
            strings[i] = fps.ToString();
            i++;
            strings[i] = cpuTime.ToString();
            i++;
            strings[i] = cpuRenderTime.ToString();
            i++;
            strings[i] = gpuTime.ToString();

            PerformanceTest.CSVWrinteLine(strings);
        }
    }
}
