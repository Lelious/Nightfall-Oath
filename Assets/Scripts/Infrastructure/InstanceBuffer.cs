using System;
using Unity.Collections;
using UnityEngine;

public struct InstanceBuffer : IDisposable
{
    public NativeArray<Matrix4x4> Matrices;
    public int Count;

    public void Initialize(int maxSize)
    {
        Matrices = new NativeArray<Matrix4x4>(maxSize, Allocator.Persistent, NativeArrayOptions.UninitializedMemory);
        Count = 0;
    }

    public void Dispose()
    {
        if (Matrices.IsCreated)
        {
            Matrices.Dispose();
        }
    }
}
