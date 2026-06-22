using Unity.Burst;
using Unity.Collections;
using Unity.Jobs;
using Unity.Mathematics;
using UnityEngine;

[BurstCompile(CompileSynchronously = true)]
public struct FrustumCullingJob : IJobParallelFor
{
    [ReadOnly] public NativeArray<Matrix4x4> SourceMatrices;
    [ReadOnly] public NativeArray<Plane> FrustumPlanes;
    [ReadOnly] public float3 BoundsSize;
    [ReadOnly] public float3 CameraPosition;
    [ReadOnly] public float CaptureRadiusSqr;

    [WriteOnly] public NativeQueue<Matrix4x4>.ParallelWriter VisibleMatricesQueue;

    public void Execute(int index)
    {
        Matrix4x4 mat = SourceMatrices[index];

        float3 position = new float3(mat.m03, mat.m13, mat.m23);
        float2 objXZ = new float2(position.x, position.z);
        float2 camXZ = new float2(CameraPosition.x, CameraPosition.z);

        float flatDistSqr = math.distancesq(objXZ, camXZ);

        if (flatDistSqr < CaptureRadiusSqr)
        {
            VisibleMatricesQueue.Enqueue(mat);
            return;
        }

        Bounds bounds = new Bounds(position, BoundsSize);
        bool isVisible = true;

        for (int i = 0; i < 6; i++)
        {
            Plane plane = FrustumPlanes[i];
            Vector3 normal = plane.normal;
            float distance = plane.distance;

            Vector3 positivePoint = position;
            if (normal.x >= 0) positivePoint.x += bounds.extents.x; else positivePoint.x -= bounds.extents.x;
            if (normal.y >= 0) positivePoint.y += bounds.extents.y; else positivePoint.y -= bounds.extents.y;
            if (normal.z >= 0) positivePoint.z += bounds.extents.z; else positivePoint.z -= bounds.extents.z;

            if (Vector3.Dot(normal, positivePoint) + distance < 0)
            {
                isVisible = false;
                break;
            }
        }

        if (isVisible)
        {
            VisibleMatricesQueue.Enqueue(mat);
        }
    }
}