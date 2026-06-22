using System;
using UnityEngine;

public class InstanceBufferGPU : IDisposable
{
    public ComputeBuffer MatrixBuffer { get; private set; }
    public ComputeBuffer ArgsBuffer { get; private set; }
    public Matrix4x4[] CpuMatrices { get; private set; }

    public int Count;
    public bool IsDirty;
    public bool IsArgsInitialized { get; private set; }

    private uint[] _argsCache = new uint[5];

    public void Initialize(int maxSize)
    {
        CpuMatrices = new Matrix4x4[maxSize];
        MatrixBuffer = new ComputeBuffer(maxSize, sizeof(float) * 16, ComputeBufferType.Structured);
        Count = 0;
        IsDirty = false;
        IsArgsInitialized = false;
    }

    public void InitializeArgs(Mesh mesh, int subMeshIndex)
    {
        if (IsArgsInitialized || subMeshIndex >= mesh.subMeshCount) return;

        ArgsBuffer = new ComputeBuffer(1, 5 * sizeof(uint), ComputeBufferType.IndirectArguments);

        _argsCache[0] = mesh.GetIndexCount(subMeshIndex);
        _argsCache[1] = (uint)Count;
        _argsCache[2] = mesh.GetIndexStart(subMeshIndex);
        _argsCache[3] = mesh.GetBaseVertex(subMeshIndex);
        _argsCache[4] = 0;

        ArgsBuffer.SetData(_argsCache, 0, 0, 5);
        IsArgsInitialized = true;
    }

    public void UpdateGpuData()
    {
        if (!IsDirty) return;

        if (Count > 0)
        {
            MatrixBuffer.SetData(CpuMatrices, 0, 0, Count);
        }

        if (IsArgsInitialized && ArgsBuffer != null)
        {
            _argsCache[1] = (uint)Count;
            ArgsBuffer.SetData(_argsCache, 0, 0, 5);
        }

        IsDirty = false;
    }

    public void Dispose()
    {
        MatrixBuffer?.Release();
        MatrixBuffer = null;
        ArgsBuffer?.Release();
        ArgsBuffer = null;
        IsArgsInitialized = false;
    }
}
