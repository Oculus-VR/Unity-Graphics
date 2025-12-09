using System;
using Unity.Mathematics;
using UnityEngine.Assertions;
using UnityEngine.Rendering.RadeonRays;

namespace UnityEngine.Rendering.UnifiedRayTracing
{
    internal struct VertexBufferChunk
    {
        public GraphicsBuffer vertices;
        public int verticesStartOffset; // in DWORD
        public uint vertexCount;
        public uint vertexStride; // in DWORD
        public int baseVertex;
    }

    internal sealed class BLASPositionsPool : IDisposable
    {
        public BLASPositionsPool(ComputeShader copyPositionsShader, ComputeShader copyShader)
        {
            m_VerticesBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, intialVertexCount*3, 4);
            m_VerticesAllocator = new BlockAllocator();
            m_VerticesAllocator.Initialize(intialVertexCount);

            m_CopyPositionsShader = copyPositionsShader;
            m_CopyVerticesKernel = m_CopyPositionsShader.FindKernel("CopyVertexBuffer");
            m_CopyShader = copyShader;
        }

        public void Dispose()
        {
            m_VerticesBuffer.Dispose();
            m_VerticesAllocator.Dispose();
        }

        public GraphicsBuffer VertexBuffer { get { return m_VerticesBuffer; } }

        public void Clear()
        {
            m_VerticesBuffer.Dispose();
            m_VerticesBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, intialVertexCount * 3, 4);
            m_VerticesAllocator.Dispose();
            m_VerticesAllocator = new BlockAllocator();
            m_VerticesAllocator.Initialize(intialVertexCount*3);
        }

        const int intialVertexCount = 1000;

        GraphicsBuffer m_VerticesBuffer;
        BlockAllocator m_VerticesAllocator;
        readonly ComputeShader m_CopyPositionsShader;
        readonly int m_CopyVerticesKernel;
        readonly ComputeShader m_CopyShader;
        const uint kItemsPerWorkgroup = 48u * 128u;

        public void Add(VertexBufferChunk info, out BlockAllocator.Allocation verticesAllocation)
        {
            verticesAllocation = m_VerticesAllocator.Allocate((int)info.vertexCount*3);
            if (!verticesAllocation.valid)
            {
                verticesAllocation = m_VerticesAllocator.GrowAndAllocate((int)info.vertexCount * 3, int.MaxValue/4, out int oldCapacity, out int newCapacity);
                if (!verticesAllocation.valid)
                    throw new UnifiedRayTracingException("Can't allocate a GraphicsBuffer bigger than 2GB", UnifiedRayTracingError.OutOfGraphicsBufferMemory);

                var newVertexBuffer = new GraphicsBuffer(GraphicsBuffer.Target.Structured, newCapacity, 4);
                GraphicsHelpers.CopyBuffer(m_CopyShader, m_VerticesBuffer, 0, newVertexBuffer, 0, oldCapacity);
                m_VerticesBuffer.Dispose();
                m_VerticesBuffer = newVertexBuffer;
            }

            var cmd = new CommandBuffer();
            cmd.SetComputeIntParam(m_CopyPositionsShader, "_InputPosBufferCount", (int)info.vertexCount);
            cmd.SetComputeIntParam(m_CopyPositionsShader, "_InputPosBufferOffset", info.verticesStartOffset);
            cmd.SetComputeIntParam(m_CopyPositionsShader, "_InputBaseVertex", info.baseVertex);
            cmd.SetComputeIntParam(m_CopyPositionsShader, "_InputPosBufferStride", (int)info.vertexStride);
            cmd.SetComputeIntParam(m_CopyPositionsShader, "_OutputPosBufferOffset", verticesAllocation.block.offset);
            cmd.SetComputeBufferParam(m_CopyPositionsShader, m_CopyVerticesKernel, "_InputPosBuffer", info.vertices);
            cmd.SetComputeBufferParam(m_CopyPositionsShader, m_CopyVerticesKernel, "_OutputPosBuffer", m_VerticesBuffer);
            cmd.DispatchCompute(m_CopyPositionsShader, m_CopyVerticesKernel, (int)Common.CeilDivide(info.vertexCount, kItemsPerWorkgroup), 1, 1);

            Graphics.ExecuteCommandBuffer(cmd);
        }

        public void Remove(ref BlockAllocator.Allocation verticesAllocation)
        {
            m_VerticesAllocator.FreeAllocation(verticesAllocation);

            verticesAllocation = BlockAllocator.Allocation.Invalid;
        }
    }
}


